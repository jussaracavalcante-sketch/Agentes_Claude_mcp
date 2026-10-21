-- trs_vjob__escopo_data_extra (query-syQh) · Trusted / VJOB · L2 INTERNAL. Grao: uma data extra registrada sobre uma linha de escopo. Chave: id_data_extra.
-- Origem: mysql-yIOn, tbescopofinal_datas (7). Gatilho: evento em query-MZdN. Datas: hora local, sem conversao.
SELECT t.*, CURRENT_TIMESTAMP() AS _extraido_at, 'mysql-yIOn' AS _fonte, 'America/Sao_Paulo' AS _fuso, TO_HEX(MD5(TO_JSON_STRING(t))) AS _payload_hash
FROM (
  SELECT CAST(d.id AS INT64) AS id_data_extra, CAST(d.id_escopo AS INT64) AS id_escopo, CAST(d.id_servico AS INT64) AS id_servico,
    CAST(d.mes AS INT64) AS mes, CAST(d.ano AS INT64) AS ano, CAST(d.status_extra AS INT64) AS status_extra, CAST(d.data_extra AS DATE) AS data_extra,
    CAST(d.id_usuario AS INT64) AS id_usuario, NULLIF(TRIM(d.link_iclip),'') AS link_iclip, NULLIF(TRIM(d.link_evidencia),'') AS link_evidencia,
    (NULLIF(TRIM(d.link_iclip),'') = NULLIF(TRIM(d.link_evidencia),'')) AS flag_links_iguais,
    CAST(d.created_at AS TIMESTAMP) AS criado_em,
    (e.id IS NULL) AS flag_escopo_nao_catalogado
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbescopofinal_datas` d
  LEFT JOIN `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbescopofinal` e ON e.id = d.id_escopo
) t
