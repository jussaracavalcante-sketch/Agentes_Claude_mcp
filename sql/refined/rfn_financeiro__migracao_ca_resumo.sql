-- rfn_financeiro__migracao_ca_resumo  ·  Refined / financeiro  ·  L3 CONFIDENTIAL (a Trusted e L4; razao social e documento NAO atravessam)
-- Grao: origem (DUPLICIDADE_CA / LACUNA_MIGRACAO) x populacao x situacao x tipo de documento x balde sem pessoa. Le: trs_financeiro__migracao_ca (query-a7Ea).
-- Gatilho: evento em query-a7Ea. Cadencia herdada: semanal (segunda 07:05 America/Manaus).
-- VALIDACAO (2026-10-19): 12 linhas, 12 chaves; 616 registros (324 de duplicidade e 292 de lacuna), 748 parcelas, valor da parcela R$ 3.388.558,63 (so identidade: duplicidade R$ 2.596.087,69 + lacuna R$ 792.470,94, que NAO se somam), excedente R$ 3.558.048,19, 133 migrados, 66 grupos com parcela migrada, 26 sem pessoa (= Trusted).
-- REGRA 1 - AGREGA, NAO FILTRA: 616 registros (324 grupos de duplicidade e 292 lancamentos avaliados em 19/10/2026); as duas origens tem graos diferentes e NAO SE SOMAM em valor.
-- REGRA 2 - DUPLICIDADE: `valor_excedente` = valor da parcela x (parcelas do grupo - 1), o que estaria contado a mais se cada grupo fosse uma parcela so (R$ 3.558.048,19); o valor da parcela
--   (R$ 2.596.087,69 em 748 parcelas) e o de UMA parcela do grupo, nao o total do grupo. Grupo sem pessoa (26) fica no balde SEM_PESSOA.
-- REGRA 3 - LACUNA: situacao e populacao sao do Supabase (OK_MIGRADO, NAO_MIGRADO_CLIENTE_EXISTE, NAO_MIGRADO_CLIENTE_AUSENTE, OK_MIGRADO_VENC_AJUSTADO, PROVAVEL_CADASTRO_DIVERGENTE) e nao sao
--   reavaliadas; `qtd_migrado` conta as duas situacoes OK_MIGRADO*.
-- LIMITACOES - NAO CONTORNE: duplicidade e lacuna sao JULGAMENTO do Supabase sobre a migracao iClips -> Conta Azul, nao fato do razao; nao ha tabela de dominio para `nivel` (0 a 4);
--   a linha de DUPLICIDADE nao tem populacao nem situacao (NULL, nunca texto inventado).
WITH t AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_financeiro__migracao_ca`
),
k AS (
  SELECT
    t.*,
    CASE WHEN flag_sem_pessoa THEN 'SEM_PESSOA' WHEN is_pj THEN 'PJ' WHEN is_pf THEN 'PF' WHEN flag_documento_invalido THEN 'DOCUMENTO_INVALIDO' ELSE 'SEM_DOCUMENTO' END AS tipo_documento
  FROM t
),
g AS (
  SELECT
    origem,
    populacao,
    situacao,
    tipo_documento,
    COUNT(*)                                       AS qtd_registros,
    SUM(qtd_parcelas)                              AS qtd_parcelas,
    ROUND(SUM(valor_parcela), 2)                   AS valor_parcela,
    ROUND(SUM(valor_excedente), 2)                 AS valor_excedente,
    COUNTIF(is_migrado)                            AS qtd_migrado,
    COUNTIF(flag_grupo_com_parcela_migrada)        AS qtd_grupos_com_parcela_migrada,
    MIN(data_vencimento)                           AS primeiro_vencimento,
    MAX(data_vencimento)                           AS ultimo_vencimento,
    MAX(DATE(_extraido_at, 'America/Sao_Paulo'))   AS data_carga_trusted
  FROM k
  GROUP BY origem, populacao, situacao, tipo_documento
),
final AS (
  SELECT
    CONCAT(origem, '|', IFNULL(populacao, '~'), '|', IFNULL(situacao, '~'), '|', tipo_documento) AS id_migracao_resumo,
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
