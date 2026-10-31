-- rfn_financeiro__lancamento_destino_resumo  ·  Refined / financeiro  ·  L3 CONFIDENTIAL (a Trusted e L4; nome e documento do destino NAO atravessam)
-- Grao: tipo do lancamento na origem x tipo de documento do destino (PJ / PF / SEM_DOCUMENTO) x folha de pessoal x lancamento catalogado. Le: trs_financeiro__lancamento_destino (query-PD22)
--   e trs_financeiro__movimento (so o valor e a marca de folha; o destino nunca e emitido). Gatilho: evento em query-PD22. Cadencia herdada: semanal (segunda 07:00 America/Manaus).
-- VALIDACAO (2026-10-19): 16 linhas, 16 chaves; 44.142 lancamentos (108 nao catalogados, sem valor), valor absoluto do movimento casado R$ 98.537.161,90, 4.943 em folha de pessoal, 6.484 PF, 32.627 PJ, 5.031 sem documento e 2.767 sem nome do destino (= Trusted).
-- REGRA 1 - AGREGA, NAO FILTRA: soma de qtd_lancamentos = Trusted (44.142 lancamentos em 19/10/2026), dos quais 44.034 casam com o movimento e 108 (todos A Receber) nao.
-- REGRA 2 - VALOR SO EXISTE ONDE HA MOVIMENTO: `valor_abs_movimento` soma o valor absoluto do movimento casado; para os 108 nao catalogados fica NULL, nunca zero.
-- REGRA 3 - FOLHA E A MARCA DO MOVIMENTO (`is_folha_pessoal`), nao do tipo de documento: CPF nao e folha por si (35 CPFs sao cliente PF); NULL quando o lancamento nao casa com o movimento.
-- REGRA 4 - `qtd_destinos_distintos` e distinta DENTRO de cada linha e NAO e aditiva entre linhas (o mesmo destino aparece em mais de um tipo de lancamento).
-- LIMITACOES - NAO CONTORNE: nao e o custo operacional da casa (isso e trs_financeiro__movimento com classe OPERACIONAL e rfn_operacao__custo_peca); o destino e o cadastro do iClips na extracao;
--   o valor e o do movimento (competencia), nao caixa; PF aqui mistura folha, socios e cliente pessoa fisica.
WITH d AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_financeiro__lancamento_destino`
),
m AS (
  SELECT id_movimento, valor_abs, is_folha_pessoal FROM `vanguardamartech_trusted`.`trs_financeiro__movimento`
),
j AS (
  SELECT
    d.tipo_origem,
    CASE WHEN d.is_pj THEN 'PJ' WHEN d.is_pf THEN 'PF' WHEN d.flag_documento_invalido THEN 'DOCUMENTO_INVALIDO' ELSE 'SEM_DOCUMENTO' END AS tipo_documento_destino,
    m.is_folha_pessoal,
    d.flag_lancamento_nao_catalogado,
    d.id_destino,
    d.destino_nome,
    m.valor_abs,
    DATE(d._extraido_at, 'America/Sao_Paulo') AS data_carga
  FROM d
  LEFT JOIN m ON m.id_movimento = d.id_lancamento
),
g AS (
  SELECT
    tipo_origem,
    tipo_documento_destino,
    is_folha_pessoal,
    flag_lancamento_nao_catalogado,
    COUNT(*)                                       AS qtd_lancamentos,
    COUNT(DISTINCT id_destino)                     AS qtd_destinos_distintos,
    COUNTIF(destino_nome IS NULL)                  AS qtd_sem_nome_destino,
    ROUND(SUM(valor_abs), 2)                       AS valor_abs_movimento,
    MAX(data_carga)                                AS data_carga_trusted
  FROM j
  GROUP BY tipo_origem, tipo_documento_destino, is_folha_pessoal, flag_lancamento_nao_catalogado
),
final AS (
  SELECT
    CONCAT(tipo_origem, '|', tipo_documento_destino, '|', IFNULL(CAST(is_folha_pessoal AS STRING), '~'), '|', IF(flag_lancamento_nao_catalogado, 'NAO_CATALOGADO', 'CATALOGADO')) AS id_lancamento_destino_resumo,
    g.*,
    'L3_CONFIDENTIAL' AS classificacao_dado
  FROM g
)
SELECT
  f.*,
  CURRENT_TIMESTAMP()                AS _extraido_at,
  'supabase-x0tz'                    AS _fonte,
  'America/Sao_Paulo'                AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(f)))     AS _payload_hash
FROM final f
