-- rfn_rh__desligamento_resumo
-- Refined / rh. Grao: um RECORTE do relatorio de desligamento do RH formal -- MES_TIPO (mes do desligamento x tipo), MOTIVO_TIPO (motivo x tipo),
-- FAIXA_TIPO (faixa de tempo de casa x tipo) ou SITUACAO_ORIGEM (situacao x origem da linha). Chave: id_resumo (dimensao | chave_1 | chave_2).
-- Le trs_rh__desligamento (query-9A0L, L4). AGREGA, NAO FILTRA, exceto onde a REGRA 1 diz. Nivel: L3 CONFIDENTIAL -- so contagem e media; nome, e-mail, cargo,
-- gestor, departamento, area e custo por pessoa NAO atravessam.
-- REGRA 1: universo por recorte. MES_TIPO, MOTIVO_TIPO e FAIXA_TIPO contam so quem tem data de desligamento (is_desligado_com_data); SITUACAO_ORIGEM conta as
--          300 linhas do relatorio, inclusive quem esta ativo. Os quatro recortes NAO se somam entre si: cada pessoa esta em todos.
-- REGRA 2: sentinela da origem '(sem informacao)' em tipo e motivo e '(sem data)' em faixa de casa sao mantidos como rotulo (nao sao motivo nem tipo);
--          109 de 300 linhas nao tem tipo e 112 nao tem motivo.
-- REGRA 3: qtd_com_custo conta pessoas com custo_tt > 0; o VALOR nao atravessa, porque a origem nao documenta a unidade (Trusted: nao somar).
-- REGRA 4: flag_celula_pequena marca recorte com menos de 3 pessoas (reidentificavel por quem conhece a casa); a linha fica, marcada, nunca apagada.
-- LIMITACOES - NAO CONTORNE: NAO e taxa de turnover (nao ha denominador aqui; turnover esta em rfn_rh__turnover_mensal, que parte do headcount); o relatorio
--   de desligamento (300) e outro universo do headcount formal (293) e do Qulture (165); departamento nao entra porque a origem escreve o mesmo setor em
--   ate quatro grafias; tempo_casa_medio_meses e da origem e existe so para quem tem admissao.
WITH base AS (
  SELECT
    d.*,
    IFNULL(d.tipo_desligamento, '(sem informacao)') AS tipo_k,
    IFNULL(d.motivo_codigo, '(sem informacao)')     AS motivo_k,
    IFNULL(d.faixa_casa, '(sem data)')              AS faixa_k,
    IFNULL(d.situacao, '(sem informacao)')          AS situacao_k,
    IFNULL(d.origem, '(sem informacao)')            AS origem_k,
    DATE_TRUNC(d.data_desligamento, MONTH)          AS mes_desl
  FROM `vanguardamartech_trusted`.`trs_rh__desligamento` d
),
expandido AS (
  SELECT 'MES_TIPO' AS dimensao, FORMAT_DATE('%Y-%m', mes_desl) AS chave_1, tipo_k AS chave_2, mes_desl AS mes_ref,
    data_admissao, tempo_casa_meses, custo_tt, origem_k, situacao_k, _extraido_at
  FROM base WHERE is_desligado_com_data
  UNION ALL
  SELECT 'MOTIVO_TIPO', motivo_k, tipo_k, CAST(NULL AS DATE),
    data_admissao, tempo_casa_meses, custo_tt, origem_k, situacao_k, _extraido_at
  FROM base WHERE is_desligado_com_data
  UNION ALL
  SELECT 'FAIXA_TIPO', faixa_k, tipo_k, CAST(NULL AS DATE),
    data_admissao, tempo_casa_meses, custo_tt, origem_k, situacao_k, _extraido_at
  FROM base WHERE is_desligado_com_data
  UNION ALL
  SELECT 'SITUACAO_ORIGEM', situacao_k, origem_k, CAST(NULL AS DATE),
    data_admissao, tempo_casa_meses, custo_tt, origem_k, situacao_k, _extraido_at
  FROM base
),
agg AS (
  SELECT
    dimensao, chave_1, chave_2,
    MIN(mes_ref)                                         AS mes_ref,
    COUNT(*)                                             AS qtd_pessoas,
    COUNTIF(data_admissao IS NOT NULL)                   AS qtd_com_admissao,
    COUNTIF(data_admissao IS NULL)                       AS qtd_sem_admissao,
    COUNTIF(tempo_casa_meses IS NOT NULL)                AS qtd_com_tempo_casa,
    ROUND(AVG(tempo_casa_meses), 1)                      AS tempo_casa_medio_meses,
    COUNTIF(custo_tt IS NOT NULL AND custo_tt > 0)       AS qtd_com_custo,
    COUNTIF(origem_k = 'DETECCAO')                       AS qtd_deteccao_sem_relatorio,
    COUNTIF(situacao_k = 'AVISO_PREVIO')                 AS qtd_aviso_previo,
    COUNTIF(situacao_k = 'ATIVO_INCONSISTENTE')          AS qtd_situacao_inconsistente,
    MAX(_extraido_at)                                    AS _extraido_trusted
  FROM expandido
  GROUP BY dimensao, chave_1, chave_2
),
calc AS (
  SELECT
    CONCAT(dimensao, '|', chave_1, '|', chave_2) AS id_resumo,
    a.*,
    (qtd_pessoas < 3)                            AS flag_celula_pequena
  FROM agg a
)
SELECT
  c.*,
  'L3_CONFIDENTIAL'                              AS classificacao_dado,
  CURRENT_TIMESTAMP()                            AS _extraido_at,
  'supabase-x0tz'                                AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(c)))                 AS _payload_hash
FROM calc c
