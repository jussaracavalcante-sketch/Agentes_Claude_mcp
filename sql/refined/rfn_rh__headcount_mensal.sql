-- rfn_rh__headcount_mensal
-- Refined / rh. Grao: um MES de referencia da fotografia de headcount. Chave: id_headcount_mensal (mes). Le trs_rh__headcount_snapshot (mes x area).
-- Nivel: L2 INTERNAL -- contagens; nenhuma pessoa atravessa.
-- REGRA 1: os totais (colaboradores, ativos, gestores) vem da fotografia, nao da soma das areas; a soma das areas e emitida ao lado e
--          flag_soma_area_fecha diz se as duas concordam (TRUE nos 5 meses medidos em 2026-10-19).
-- REGRA 2: qtd_inativos = colaboradores - ativos (zero em 2026-06 e 2026-07, 17/32/36 em 08/09/10: a fotografia passou a contar quem saiu).
-- REGRA 3: variacao_*_vs_mes_anterior e a diferenca contra o MES ANTERIOR PRESENTE na tabela (LAG), NULL no primeiro mes; nao e contra o
--          mes-calendario anterior quando ha buraco na serie.
-- REGRA 4: pct_nao_mapeado e a fatia da area 'Nao mapeado' sobre colaboradores: 11 de 114 (9,6%) em 2026-06 a 58 de 165 (35,2%) em 2026-10 --
--          a fotografia esta classificando cada vez menos gente por area; sem isso, "headcount por area" mede o mapeamento, nao a area.
-- LIMITACOES - NAO CONTORNE: serie comeca em 2026-06 (5 meses); nao soma nem se compara linha a linha com rfn_rh__turnover_mensal (outra base:
--   quem teve evidencia desde 2024-01, piso) nem com trs_rh__pessoa (Qulture, 165); o que e "colaborador" e "ativo" e definicao da fotografia no
--   Supabase, nao desta casa. gestores so existe no total.
-- VALIDACAO 2026-10-19 (query inteira rodada sobre a Trusted materializada): 5 linhas, 5 chaves e hashes, soma de qtd_areas = 25, total_colaboradores
--   114/137/151/162/165, qtd_inativos 0/0/17/32/36, pct_nao_mapeado 9,6%/24,1%/29,8%/34,0%/35,2%, variacao NULL/23/14/11/3.
WITH agg AS (
  SELECT
    mes_referencia,
    ANY_VALUE(total_colaboradores)                                   AS total_colaboradores,
    ANY_VALUE(total_ativos)                                          AS total_ativos,
    ANY_VALUE(total_gestores)                                        AS total_gestores,
    COUNT(*)                                                         AS qtd_areas,
    SUM(qtd_colaboradores_area)                                      AS soma_colaboradores_areas,
    SUM(qtd_ativos_area)                                             AS soma_ativos_areas,
    SUM(IF(flag_area_nao_mapeada, qtd_colaboradores_area, 0))        AS colaboradores_nao_mapeados,
    SUM(IF(flag_area_nao_mapeada, qtd_ativos_area, 0))               AS ativos_nao_mapeados,
    SUM(IF(area = 'Operação', qtd_colaboradores_area, 0))            AS colaboradores_operacao,
    SUM(IF(area = 'Operação', qtd_ativos_area, 0))                   AS ativos_operacao,
    LOGICAL_AND(flag_soma_area_fecha)                                AS flag_soma_area_fecha,
    ANY_VALUE(capturado_em)                                          AS capturado_em,
    MAX(_extraido_at)                                                AS _extraido_trusted
  FROM `vanguardamartech_trusted`.`trs_rh__headcount_snapshot`
  GROUP BY mes_referencia
),
calc AS (
  SELECT
    CAST(a.mes_referencia AS STRING)                                 AS id_headcount_mensal,
    a.*,
    a.total_colaboradores - a.total_ativos                           AS qtd_inativos,
    SAFE_DIVIDE(a.total_ativos, NULLIF(a.total_colaboradores, 0))    AS pct_ativos,
    SAFE_DIVIDE(a.colaboradores_nao_mapeados, NULLIF(a.total_colaboradores, 0)) AS pct_nao_mapeado,
    SAFE_DIVIDE(a.total_gestores, NULLIF(a.total_ativos, 0))         AS gestores_por_ativo,
    a.total_colaboradores - LAG(a.total_colaboradores) OVER (ORDER BY a.mes_referencia) AS variacao_colaboradores_vs_mes_anterior,
    a.total_ativos - LAG(a.total_ativos) OVER (ORDER BY a.mes_referencia)               AS variacao_ativos_vs_mes_anterior
  FROM agg a
)
SELECT c.*, 'L2_INTERNAL' AS classificacao_dado, CURRENT_TIMESTAMP() AS _extraido_at, 'supabase-x0tz' AS _fonte, 'UTC' AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(c))) AS _payload_hash
FROM calc c
