-- trs_vjob__anexo_diverso (query-A0Fz) · Trusted / VJOB · L3 CONFIDENTIAL. Grao: um arquivo anexado. Chave: (origem, id_origem).
-- Origem: mysql-yIOn, ia_solicitacao_anexos (briefing de geracao por IA) e tbcronogramadatas_arquivos (anexo de parcela).
-- Gatilho: evento em query-MZdN. Datas: hora local, sem conversao. O arquivo em si nao e lido; so o nome e o caminho.
WITH base AS (
SELECT 'IA_SOLICITACAO' AS origem, CAST(id AS INT64) AS id_origem, CAST(solicitacao_id AS INT64) AS id_pai, 'ia_solicitacoes' AS tabela_pai, NULLIF(TRIM(nome_original),'') AS nome_original, NULLIF(TRIM(caminho),'') AS caminho, NULLIF(LOWER(TRIM(mime_type)),'') AS tipo_mime, CAST(NULL AS INT64) AS id_usuario, CAST(criado_em AS TIMESTAMP) AS criado_em FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_ia_solicitacao_anexos`
UNION ALL SELECT 'PARCELA', CAST(id AS INT64), CAST(id_cronogramadata AS INT64), 'tbcronogramadatas', NULLIF(TRIM(nome_original),''), NULLIF(TRIM(arquivo),''), NULL, CAST(usuario_upload AS INT64), CAST(data_upload AS TIMESTAMP) FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbcronogramadatas_arquivos`
),
pais AS (
  SELECT 'ia_solicitacoes' AS tabela_pai, id FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_ia_solicitacoes`
  UNION ALL SELECT 'tbcronogramadatas', id FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbcronogramadatas`
),
tratado AS (
  SELECT b.*, LOWER(REGEXP_EXTRACT(b.nome_original, r'\.([A-Za-z0-9]+)$')) AS extensao,
    CASE WHEN b.tipo_mime LIKE 'image/%' THEN 'IMAGEM' WHEN b.tipo_mime = 'application/pdf' THEN 'PDF'
         WHEN LOWER(REGEXP_EXTRACT(b.nome_original, r'\.([A-Za-z0-9]+)$')) IN ('jpg','jpeg','png','gif','webp','svg') THEN 'IMAGEM'
         WHEN LOWER(REGEXP_EXTRACT(b.nome_original, r'\.([A-Za-z0-9]+)$')) = 'pdf' THEN 'PDF' ELSE 'OUTRO' END AS categoria_arquivo,
    (p.id IS NULL) AS flag_pai_nao_catalogado
  FROM base b LEFT JOIN pais p ON p.tabela_pai = b.tabela_pai AND p.id = b.id_pai
)
SELECT t.*, CURRENT_TIMESTAMP() AS _extraido_at, 'mysql-yIOn' AS _fonte, 'America/Sao_Paulo' AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(t))) AS _payload_hash
FROM tratado t
