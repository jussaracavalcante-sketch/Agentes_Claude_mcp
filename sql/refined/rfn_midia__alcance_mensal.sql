-- rfn_midia__alcance_mensal (query-O7Qi)
-- Refined / MIDIA. Grao: conta, campanha, mes. Origem: alcance_frequencia_campanha + conta.
-- Regras numeradas, limitacoes e medicao: na descricao da transformacao na Nekt.
WITH diario AS (
  SELECT
    id_conta, id_campanha,
    DATE_TRUNC(data, MONTH)                                        AS mes_referencia,
    ARRAY_AGG(campanha ORDER BY data DESC LIMIT 1)[SAFE_OFFSET(0)] AS campanha,
    ARRAY_AGG(status_campanha ORDER BY data DESC LIMIT 1)[SAFE_OFFSET(0)] AS status_campanha,
    COUNT(DISTINCT data)                                           AS dias_com_dado,
    SUM(impressoes)                                                AS impressoes,
    SUM(usuarios_unicos_no_dia)                                    AS soma_usuarios_unicos_diarios,
    AVG(usuarios_unicos_no_dia)                                    AS usuarios_unicos_dia_medio,
    MAX(usuarios_unicos_no_dia)                                    AS usuarios_unicos_dia_pico,
    COUNTIF(frequencia_media_por_usuario IS NOT NULL)              AS dias_com_frequencia_da_plataforma,
    MAX(_extraido_at)                                              AS _extraido_trusted
  FROM `vanguardamartech_trusted`.`trs_google_ads__alcance_frequencia_campanha`
  GROUP BY id_conta, id_campanha, mes_referencia
)
SELECT
  CONCAT(d.id_conta, '|', d.id_campanha, '|', FORMAT_DATE('%Y-%m', d.mes_referencia)) AS id_alcance_mensal,
  d.id_conta, k.cliente, k.moeda, d.id_campanha, d.campanha, d.status_campanha,
  d.mes_referencia,
  d.dias_com_dado,
  d.impressoes,
  d.usuarios_unicos_dia_medio,
  d.usuarios_unicos_dia_pico,
  SAFE_DIVIDE(d.impressoes, d.soma_usuarios_unicos_diarios)        AS frequencia_media_diaria,
  d.dias_com_frequencia_da_plataforma,
  (SAFE_DIVIDE(d.impressoes, d.soma_usuarios_unicos_diarios) < 1)  AS flag_frequencia_menor_que_um,
  (SAFE_DIVIDE(d.impressoes, d.soma_usuarios_unicos_diarios) > 50) AS flag_frequencia_extrema,
  (k.id_conta IS NULL)                                             AS flag_conta_nao_catalogada,
  CURRENT_TIMESTAMP()                                              AS _extraido_at,
  d._extraido_trusted
FROM diario d
LEFT JOIN `vanguardamartech_trusted`.`trs_google_ads__conta` k ON k.id_conta = d.id_conta
