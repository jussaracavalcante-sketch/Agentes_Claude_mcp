-- trs_iclips__workflow_mapa
-- Trusted / iClips. Grao: um NOME DE ETAPA de workflow como o iClips grava (etapa_original), mapeado para uma
-- etapa canonica. Chave: etapa_original. Nivel: L2 INTERNAL (dicionario, sem dado pessoal).
--
-- ORIGEM. Tres tabelas do Supabase (supabase-x0tz) que se completam:
--   supabase_public_map_workflow_canonico   (426: workflow_raw -> workflow_canonical_id)
--   supabase_public_dim_workflow_normalizado (426: etapa_original -> etapa_canonica, categoria_macro, tipo_operacional,
--                                              confianca, observacao)
--   supabase_public_dim_workflow_canonico   (58 etapas canonicas, com categoria)
-- Medido em 18/10/2026: 426 nomes, 426 chaves; o mapa e a normalizacao concordam em 426 de 426 (workflow_canonical_id =
-- etapa_canonica); os 58 canonicos existem todos na dimensao; confianca ALTA 309, MEDIA 59, BAIXA 2, CANONICA 56.
--
-- COBERTURA SOBRE A trs_iclips__etapa: o iClips grava 3.512 nomes de etapa distintos (a mesma etapa em 605 grafias,
-- ja registrado); o dicionario mapeia 395 deles, que cobrem 353.430 das 515.211 etapas (68,6%). Etapa de nome nao mapeado
-- NAO ganha etapa canonica: nao e erro, e nome fora do dicionario (a normalizacao e mantida a mao).
--
-- LIMITACAO -- NAO CONTORNE: o mapeamento e curadoria de terceiros (confianca BAIXA em 2 e MEDIA em 59 nomes): nao herdar
-- a etapa canonica como fato. A Refined escolhe se usa so ALTA e CANONICA. Esta tabela nao altera trs_iclips__etapa.
WITH uso AS (
  SELECT nome_etapa, COUNT(*) AS qtd FROM `vanguardamartech_trusted`.`trs_iclips__etapa` GROUP BY nome_etapa
)
SELECT
  NULLIF(TRIM(n.etapa_original), '')                          AS etapa_original,
  NULLIF(TRIM(m.workflow_canonical_id), '')                   AS id_etapa_canonica,
  NULLIF(TRIM(n.etapa_canonica), '')                          AS etapa_canonica,
  NULLIF(TRIM(c.workflow_canonical_name), '')                 AS nome_etapa_canonica,
  NULLIF(TRIM(c.categoria), '')                               AS categoria_canonica,
  NULLIF(TRIM(n.categoria_macro), '')                         AS categoria_macro,
  NULLIF(TRIM(n.tipo_operacional), '')                        AS tipo_operacional,
  NULLIF(TRIM(n.confianca), '')                               AS confianca,
  (n.confianca = 'CANÔNICA')                                  AS is_etapa_canonica_propria,
  NULLIF(TRIM(n.observacao), '')                              AS observacao,
  c.ativo                                                     AS canonica_ativa,
  IFNULL(u.qtd, 0)                                            AS qtd_etapas_no_iclips,
  (m.workflow_canonical_id IS DISTINCT FROM n.etapa_canonica) AS flag_mapa_diverge,
  DATE(n.updated_at, 'America/Sao_Paulo')                     AS dicionario_atualizado_em,
  CURRENT_TIMESTAMP()                                         AS _extraido_at,
  'supabase-x0tz'                                             AS _fonte,
  'America/Sao_Paulo'                                         AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(n)))                              AS _payload_hash
FROM `vanguardamartech_raw`.`supabase_public_dim_workflow_normalizado` n
LEFT JOIN `vanguardamartech_raw`.`supabase_public_map_workflow_canonico` m ON m.workflow_raw = n.etapa_original
LEFT JOIN `vanguardamartech_raw`.`supabase_public_dim_workflow_canonico` c ON c.workflow_canonical_id = m.workflow_canonical_id
LEFT JOIN uso u ON u.nome_etapa = n.etapa_original
