-- rfn_rh__qulture_dominio_resumo  ·  Refined / rh (Qulture)  ·  L2 INTERNAL
-- Grao: um dominio do Qulture (COMPETENCIA, CICLO_AVALIACAO, CICLO_PDI, MODELO_FEEDBACK, TAG, TIME, PESQUISA, TOPICO_PESQUISA,
--   PERGUNTA_PULSE, PULSE_SURVEY).
-- Le: trs_qulture__dominio (query-Wc5X, L2). Gatilho: evento em query-Wc5X. Cadencia diaria (supabase-x0tz).
-- Identidade (19/10/2026, contra a Trusted materializada): 433 itens = 433 · 10 linhas, 10 chaves · PERGUNTA_PULSE 326 (18 sem nome) ·
--   TIME 36 · TAG 21 · TOPICO_PESQUISA 13 (13 com pai, 6 pesquisas) · PULSE_SURVEY 10 · CICLO_PDI 9 · COMPETENCIA 7 · PESQUISA 6 ·
--   MODELO_FEEDBACK 3 · CICLO_AVALIACAO 2.
-- R1 Descreve o CATALOGO (quantas competencias, ciclos, perguntas existem), nao o uso nem as respostas. Nome do item nao atravessa.
-- R2 estado so existe em CICLO_AVALIACAO (ATUAL/ANTERIOR), CICLO_PDI (ACTIVE/DRAFT) e PULSE_SURVEY (ACTIVE): nos demais e ausencia,
--    nao inativo. estados lista os valores distintos presentes.
-- R3 id_pai so existe em TOPICO_PESQUISA (aponta para a PESQUISA); qtd_pais_distintos e o numero de pesquisas com topico.
-- LIMITACAO -- NAO CONTORNE: nao ha resposta de pesquisa nem de pulse nesta base, so a estrutura; clima nao se mede daqui.
WITH d AS (SELECT * FROM `vanguardamartech_trusted`.`trs_qulture__dominio`),
agg AS (
  SELECT
    dominio,
    COUNT(*) AS qtd_itens,
    COUNT(DISTINCT id_origem) AS qtd_ids_distintos,
    COUNTIF(nome IS NULL) AS qtd_sem_nome,
    COUNTIF(descricao IS NOT NULL) AS qtd_com_descricao,
    COUNTIF(estado IS NOT NULL) AS qtd_com_estado,
    COUNT(DISTINCT estado) AS qtd_estados_distintos,
    STRING_AGG(DISTINCT estado, ',' ORDER BY estado) AS estados,
    COUNTIF(id_pai IS NOT NULL) AS qtd_com_pai,
    COUNT(DISTINCT id_pai) AS qtd_pais_distintos,
    MAX(versao_lida_em) AS versao_lida_em
  FROM d
  GROUP BY 1
),
final AS (
  SELECT dominio AS id_dominio, a.*, 'L2_INTERNAL' AS classificacao_dado FROM agg a
)
SELECT f.*, CURRENT_TIMESTAMP() AS _extraido_at, 'supabase-x0tz' AS _fonte,
  'America/Sao_Paulo' AS _fuso, TO_HEX(MD5(TO_JSON_STRING(f))) AS _payload_hash
FROM final f
