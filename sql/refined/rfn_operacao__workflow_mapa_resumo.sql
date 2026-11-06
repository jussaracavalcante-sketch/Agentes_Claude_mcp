-- rfn_operacao__workflow_mapa_resumo  ·  Refined / operacao  ·  L2 INTERNAL
-- Grao: categoria macro x confianca do dicionario de etapas de workflow do iClips (nome gravado -> etapa canonica).
-- Le: trs_iclips__workflow_mapa (query-cl9f, L2). Gatilho: evento em query-cl9f. Cadencia diaria (supabase-x0tz).
-- Identidade (19/10/2026, contra a Trusted materializada): 426 nomes de etapa = 426 · 21 linhas, 21 chaves · 353.432 etapas do
--   iClips cobertas = 353.432 · 31 nomes sem uso · 56 canonicas proprias · zero divergencia mapa x normalizacao · 7 categorias macro.
-- R1 is_confianca_herdavel = confianca IN ('ALTA','CANONICA'): e a escolha que a Trusted deixou para a Refined. Com ela, 365 dos
--    426 nomes e 347.896 das 353.432 etapas (98,4%) sao herdaveis; MEDIA (59) e BAIXA (2) ficam visiveis e marcadas FALSE.
-- R2 participacao_no_uso = etapas do grupo / total de etapas mapeadas (soma 1,0 sobre a tabela). Nao e cobertura sobre o iClips
--    inteiro: o dicionario cobre 68,6% das 515.211 etapas (ver Trusted); o resto nao tem nome no dicionario.
-- R3 Nome de etapa (texto) nao atravessa; e dicionario, nao dado pessoal, mas aqui so contagem.
-- LIMITACAO -- NAO CONTORNE: curadoria de terceiros mantida a mao; categoria_macro e tipo_operacional vem do dicionario, nao do
--   iClips. Esta tabela NAO altera trs_iclips__etapa nem decide etapa de peca.
WITH w AS (SELECT * FROM `vanguardamartech_trusted`.`trs_iclips__workflow_mapa`),
agg AS (
  SELECT
    IFNULL(categoria_macro, '(sem categoria)') AS categoria_macro,
    IFNULL(confianca, '(sem confiança)') AS confianca,
    COUNT(*) AS qtd_nomes_de_etapa,
    COUNT(DISTINCT id_etapa_canonica) AS qtd_etapas_canonicas,
    COUNT(DISTINCT categoria_canonica) AS qtd_categorias_canonicas,
    COUNT(DISTINCT tipo_operacional) AS qtd_tipos_operacionais,
    SUM(qtd_etapas_no_iclips) AS qtd_etapas_no_iclips,
    COUNTIF(qtd_etapas_no_iclips = 0) AS qtd_nomes_sem_uso,
    COUNTIF(flag_mapa_diverge) AS qtd_mapa_diverge,
    COUNTIF(is_etapa_canonica_propria) AS qtd_canonica_propria,
    COUNTIF(canonica_ativa IS FALSE) AS qtd_canonica_inativa,
    MAX(dicionario_atualizado_em) AS dicionario_atualizado_em
  FROM w
  GROUP BY 1, 2
),
final AS (
  SELECT CONCAT(categoria_macro, '|', confianca) AS id_workflow_resumo,
         a.*,
         (confianca IN ('ALTA', 'CANÔNICA')) AS is_confianca_herdavel,
         SAFE_DIVIDE(qtd_etapas_no_iclips, NULLIF(SUM(qtd_etapas_no_iclips) OVER (), 0)) AS participacao_no_uso,
         'L2_INTERNAL' AS classificacao_dado
  FROM agg a
)
SELECT f.*, CURRENT_TIMESTAMP() AS _extraido_at, 'supabase-x0tz' AS _fonte,
  'America/Sao_Paulo' AS _fuso, TO_HEX(MD5(TO_JSON_STRING(f))) AS _payload_hash
FROM final f
