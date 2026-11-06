-- trs_iclips__peca_etapa_tempo_padrao
-- Trusted / iClips. Grao: um TIPO de peca x uma ETAPA (grafia crua) com o tempo padrao em minutos. Chave: id_tempo_padrao = id_peca_tipo | MD5(etapa crua).
-- Origem: vanguardamartech_raw.supabase_meta_peca_etapa_tempo_padrao (fonte supabase-x0tz, diaria). Medido em 2026-10-19: 11.942 linhas, 11.942
-- pares (peca_tipo_id, etapa_norm) distintos, 515 tipos de peca (515 de 515 existem em trs_iclips__peca_tipo), 3.476 grafias de etapa.
-- `etapa_norm` NAO ESTA NORMALIZADA: 1.352 linhas tem espaco no fim e, depois de TRIM+UPPER, as 11.942 viram 10.935 pares -- 981 grupos com
-- mais de uma grafia e 946 deles com minutos DIFERENTES entre as grafias. Por isso a chave e a grafia CRUA (hash) e a tabela NAO deduplica:
-- deduplicar escolheria um minuto e descartaria outro. `etapa_normalizada` (UPPER TRIM) e `flag_grafia_duplicada_apos_trim` tornam o caso visivel.
-- SUGERIDO = MEDIDO, HOJE: `origem` e 'sugerido' nas 11.942 e, nas 11.302 com valor, min_padrao e IGUAL a min_medido_ref em 11.302 de 11.302
-- (zero diferentes). O "padrao" e uma copia do medido; `atualizado_por` e NULL nas 11.942 (ninguem editou). Nas outras 640, min_padrao = 0 e
-- min_medido_ref = NULL: zero e sentinela de "sem medicao" e sai NULL (flag_sem_tempo_medido). 11.937 das 11.942 foram regravadas em 2026-10-18.
-- A etapa canonica vem de dim_workflow_normalizado (426 grafias): casa 7.509 de 11.942 linhas (62,9%) e 414 das 3.175 grafias normalizadas.
-- Quartis de minutos_padrao (com valor): 1 / 13 / 30 / 61, maximo 6.155.
-- Nivel: L2 INTERNAL. Fuso: `atualizado_em` e instante UTC do Supabase, sem conversao.
WITH raw AS (
  SELECT peca_tipo_id, peca_tipo_nome, etapa_norm, min_padrao, min_medido_ref, origem, atualizado_por, atualizado_em,
         UPPER(TRIM(etapa_norm))                                                     AS etapa_trim_upper,
         COUNT(*) OVER (PARTITION BY peca_tipo_id, UPPER(TRIM(etapa_norm)))         AS qtd_grafias_apos_trim
  FROM `vanguardamartech_raw`.`supabase_meta_peca_etapa_tempo_padrao`
),
tratado AS (
  SELECT
    CONCAT(CAST(r.peca_tipo_id AS STRING), '|', TO_HEX(MD5(r.etapa_norm)))         AS id_tempo_padrao,
    CAST(r.peca_tipo_id AS STRING)                                                 AS id_peca_tipo,
    NULLIF(TRIM(r.peca_tipo_nome), '')                                             AS nome_peca_tipo,
    r.etapa_norm                                                                   AS etapa_origem,
    r.etapa_trim_upper                                                             AS etapa_normalizada,
    (r.etapa_norm <> TRIM(r.etapa_norm))                                           AS flag_etapa_com_espaco,
    (r.qtd_grafias_apos_trim > 1)                                                  AS flag_grafia_duplicada_apos_trim,
    r.qtd_grafias_apos_trim,
    w.etapa_canonica,
    w.categoria_macro,
    w.confianca                                                                    AS confianca_canonica,
    (w.etapa_original IS NULL)                                                     AS flag_etapa_sem_canonica,
    NULLIF(r.min_padrao, 0)                                                        AS minutos_padrao,
    r.min_medido_ref                                                               AS minutos_medido_ref,
    (r.min_medido_ref IS NULL)                                                     AS flag_sem_tempo_medido,
    (r.min_padrao > 0 AND r.min_padrao = r.min_medido_ref)                         AS flag_padrao_igual_medido,
    r.origem                                                                       AS origem_do_padrao,
    r.atualizado_por,
    r.atualizado_em,
    (pt.id_peca IS NULL)                                                           AS flag_peca_tipo_nao_catalogada
  FROM raw r
  LEFT JOIN `vanguardamartech_raw`.`supabase_public_dim_workflow_normalizado` w ON w.etapa_original = r.etapa_trim_upper
  LEFT JOIN (SELECT DISTINCT id_peca FROM `vanguardamartech_trusted`.`trs_iclips__peca_tipo`) pt ON pt.id_peca = CAST(r.peca_tipo_id AS STRING)
)
SELECT t.*, 'L2_INTERNAL' AS classificacao_dado, CURRENT_TIMESTAMP() AS _extraido_at, 'supabase-x0tz' AS _fonte, 'UTC' AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(t))) AS _payload_hash
FROM tratado t
