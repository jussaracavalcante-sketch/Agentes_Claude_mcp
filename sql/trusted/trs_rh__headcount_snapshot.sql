-- trs_rh__headcount_snapshot
-- Trusted / RH. Grao: um MES de referencia x uma AREA da fotografia de headcount. Chave: id_headcount (mes|area).
-- Origem: vanguardamartech_raw.supabase_gold_headcount_snapshot (fonte supabase-x0tz, diaria). Medido em 2026-10-19: 5 fotografias, uma por mes
-- (2026-06 a 2026-10), cada uma com 5 areas no JSON `por_area` -> 25 linhas aqui. A soma das areas reproduz os totais (colaboradores E ativos) nos
-- 5 meses, zero divergencia; ativos nunca excede colaboradores; `capturado_em` cai no proprio mes em 5 de 5 (2026-06 foi capturado em 16/06, os
-- demais no dia 1 as 03:10 UTC). Serie curta: comeca em 2026-06 porque a fotografia so passou a ser tirada entao.
-- Nivel: L2 INTERNAL -- so contagens por area; nenhuma pessoa. `gestores` existe so no total (o JSON nao traz por area): sai repetido por linha
-- como total_gestores, NAO somar entre areas. "Nao mapeado" e area de verdade na origem (11 a 58 pessoas): sai como area, com flag_area_nao_mapeada.
-- Fuso: `capturado_em` e instante UTC da origem (timestamptz do Supabase); nao se converte, _fuso declara.
WITH base AS (
  SELECT ref_mes, colaboradores, ativos, gestores, capturado_em, por_area,
         ARRAY_LENGTH(JSON_QUERY_ARRAY(por_area)) AS qtd_areas,
         (SELECT SUM(CAST(JSON_VALUE(a, '$.colaboradores') AS INT64)) FROM UNNEST(JSON_QUERY_ARRAY(por_area)) a) AS soma_col_area,
         (SELECT SUM(CAST(JSON_VALUE(a, '$.ativos') AS INT64)) FROM UNNEST(JSON_QUERY_ARRAY(por_area)) a) AS soma_atv_area
  FROM `vanguardamartech_raw`.`supabase_gold_headcount_snapshot`
),
linhas AS (
  SELECT
    CONCAT(CAST(b.ref_mes AS STRING), '|', JSON_VALUE(a, '$.area'))   AS id_headcount,
    b.ref_mes                                                         AS mes_referencia,
    JSON_VALUE(a, '$.area')                                           AS area,
    CAST(JSON_VALUE(a, '$.colaboradores') AS INT64)                   AS qtd_colaboradores_area,
    CAST(JSON_VALUE(a, '$.ativos') AS INT64)                          AS qtd_ativos_area,
    b.colaboradores                                                   AS total_colaboradores,
    b.ativos                                                          AS total_ativos,
    b.gestores                                                        AS total_gestores,
    b.qtd_areas                                                       AS qtd_areas_no_snapshot,
    (b.soma_col_area = b.colaboradores AND b.soma_atv_area = b.ativos) AS flag_soma_area_fecha,
    (JSON_VALUE(a, '$.area') = 'Não mapeado')                          AS flag_area_nao_mapeada,
    b.capturado_em,
    (DATE_TRUNC(DATE(b.capturado_em), MONTH) <> b.ref_mes)             AS flag_captura_fora_do_mes,
    (EXTRACT(DAY FROM DATE(b.capturado_em)) <> 1)                      AS flag_captura_fora_do_dia_1
  FROM base b, UNNEST(JSON_QUERY_ARRAY(b.por_area)) a
)
SELECT l.*, 'L2_INTERNAL' AS classificacao_dado, CURRENT_TIMESTAMP() AS _extraido_at, 'supabase-x0tz' AS _fonte, 'UTC' AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(l))) AS _payload_hash
FROM linhas l
