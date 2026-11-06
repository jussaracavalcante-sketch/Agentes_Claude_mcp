-- rfn_operacao__anexo_diverso_mensal  ·  Refined / operacao  ·  L2 INTERNAL
-- Grao: um mes de criacao do anexo x origem (IA_SOLICITACAO / PARCELA) x categoria do arquivo. Le: trs_vjob__anexo_diverso. Gatilho: evento em query-A0Fz.
-- Identidade (07/10/2026): 21 anexos = 21 · 1 com pai nao catalogado. Nome do arquivo, caminho e usuario NAO atravessam (so contagem).
-- R1 Sao anexos SOLTOS (briefing de IA e parcela de contrato), nao o anexo de job nem o de comentario (esses estao em job_interacao).
-- R2 O pai e (tabela_pai, id_pai): ids de tabelas diferentes colidem. R3 Categoria vem do MIME quando bem formado e da extensao quando nao.
WITH a AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_vjob__anexo_diverso`
),
agg AS (
  SELECT
    DATE_TRUNC(DATE(criado_em), MONTH) AS mes_criacao,
    origem,
    COALESCE(categoria_arquivo, '(sem categoria)') AS categoria_arquivo,
    COUNT(*) AS qtd_anexos,
    COUNT(DISTINCT CONCAT(tabela_pai, ':', CAST(id_pai AS STRING))) AS qtd_pais_distintos,
    COUNTIF(flag_pai_nao_catalogado) AS qtd_pai_nao_catalogado,
    COUNTIF(id_usuario IS NOT NULL) AS qtd_com_usuario
  FROM a
  GROUP BY 1, 2, 3
),
final AS (
  SELECT CONCAT(IFNULL(CAST(mes_criacao AS STRING), 'SEM_DATA'), '|', origem, '|', categoria_arquivo) AS id_anexo_mensal, a.*, 'L2_INTERNAL' AS classificacao_dado
  FROM agg a
)
SELECT f.*, CURRENT_TIMESTAMP() AS _extraido_at, 'mysql-yIOn' AS _fonte,
  'America/Sao_Paulo' AS _fuso, TO_HEX(MD5(TO_JSON_STRING(f))) AS _payload_hash
FROM final f
