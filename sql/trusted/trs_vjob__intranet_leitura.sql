-- trs_vjob__intranet_leitura (query-ZT0h) · Trusted / VJOB · L4 PERSONAL_DATA. Grao: um usuario e um conteudo (leitura ou participacao). Chave: (origem, id_origem).
-- Origem: mysql-yIOn, tbvideoextra, tbmalaextras, tbenqueteextras, tbagendaextra. Gatilho: evento em query-MZdN.
-- Videos nao tem tabela-pai no catalogo: flag_conteudo_nao_catalogado fica NULL ali (ausencia de dimensao, nao orfao).
-- L4 porque liga usuario identificado a um conteudo e a um instante. Datas: hora local, sem conversao.
WITH base AS (
SELECT 'VIDEO' AS origem, CAST(id AS INT64) AS id_origem, CAST(idvideo AS INT64) AS id_conteudo, CAST(NULL AS STRING) AS tabela_conteudo, CAST(idusuario AS INT64) AS id_usuario, CAST(NULL AS INT64) AS status_origem, CAST(dataleitura AS TIMESTAMP) AS lido_em FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbvideoextra`
UNION ALL SELECT 'MALA_DIRETA', CAST(id AS INT64), CAST(idmala AS INT64), 'tbmaladireta', CAST(idusuarios AS INT64), CAST(status AS INT64), NULL FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbmalaextras`
UNION ALL SELECT 'ENQUETE', CAST(id AS INT64), CAST(idenquete AS INT64), 'tbenquete', CAST(idusuarios AS INT64), CAST(status AS INT64), NULL FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbenqueteextras`
UNION ALL SELECT 'AGENDA', CAST(id AS INT64), CAST(idagenda AS INT64), 'tbagenda', CAST(idusuarios AS INT64), CAST(status AS INT64), NULL FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbagendaextra`
),
pais AS (
  SELECT 'tbmaladireta' AS tabela_conteudo, id FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbmaladireta`
  UNION ALL SELECT 'tbenquete' AS tabela_conteudo, id FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbenquete`
  UNION ALL SELECT 'tbagenda' AS tabela_conteudo, id FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbagenda`
),
tratado AS (
  SELECT b.*,
    IF(b.tabela_conteudo IS NULL, CAST(NULL AS BOOL), p.id IS NULL) AS flag_conteudo_nao_catalogado,
    (u.id IS NULL) AS flag_usuario_nao_catalogado
  FROM base b
  LEFT JOIN pais p ON p.tabela_conteudo = b.tabela_conteudo AND p.id = b.id_conteudo
  LEFT JOIN `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbusuariointranet` u ON u.id = b.id_usuario
)
SELECT t.*, CURRENT_TIMESTAMP() AS _extraido_at, 'mysql-yIOn' AS _fonte, 'America/Sao_Paulo' AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(t))) AS _payload_hash
FROM tratado t
