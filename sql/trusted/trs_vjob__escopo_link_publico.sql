-- trs_vjob__escopo_link_publico (query-xrav) · Trusted / VJOB · L3 CONFIDENTIAL. Grao: um link publico de escopo. Chave: id_link.
-- Origem: mysql-yIOn, tbescopo_public_links (70). Gatilho: evento em query-MZdN.
-- O TOKEN NAO E EMITIDO (segredo, L5; §31): so `token_presente`. Os filtros (JSON) tambem nao: so o tamanho.
-- As flags *_na_carga sao relativas a data da CARGA (_extraido_at) e congelam; para ler hoje, comparar expira_em com a data de hoje.
WITH base AS (
  SELECT CAST(id AS INT64) AS id_link, CAST(id_cliente AS INT64) AS id_conta_atendimento, CAST(mes AS INT64) AS mes, CAST(ano AS INT64) AS ano,
    NULLIF(CAST(setor AS INT64),0) AS id_setor, NULLIF(CAST(responsavel_id AS INT64),0) AS id_responsavel, NULLIF(CAST(gestor_id AS INT64),0) AS id_gestor,
    NULLIF(CAST(criado_por AS INT64),0) AS id_criador, CAST(criado_em AS TIMESTAMP) AS criado_em, CAST(expira_em AS TIMESTAMP) AS expira_em,
    CAST(ativo AS INT64)=1 AS ativo, (token IS NOT NULL AND token <> '') AS token_presente, LENGTH(filtros_json) AS filtros_chars
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbescopo_public_links`
),
tratado AS (
  SELECT b.*, TIMESTAMP_DIFF(b.expira_em, b.criado_em, DAY) AS dias_de_validade,
    (b.expira_em IS NULL) AS flag_sem_expiracao,
    (b.expira_em IS NOT NULL AND b.expira_em < CURRENT_TIMESTAMP()) AS flag_expirado_na_carga,
    (b.criado_em > CURRENT_TIMESTAMP()) AS flag_criado_no_futuro,
    (b.ativo AND (b.expira_em IS NULL OR b.expira_em >= CURRENT_TIMESTAMP())) AS flag_vigente_na_carga,
    (a.id IS NULL) AS flag_conta_nao_catalogada,
    (b.id_criador IS NOT NULL AND u.id IS NULL) AS flag_criador_nao_catalogado
  FROM base b
  LEFT JOIN `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbclientesatedimentos` a ON a.id = b.id_conta_atendimento
  LEFT JOIN `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbusuariointranet` u ON u.id = b.id_criador
)
SELECT t.*, CURRENT_TIMESTAMP() AS _extraido_at, 'mysql-yIOn' AS _fonte, 'America/Sao_Paulo' AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(t))) AS _payload_hash
FROM tratado t
