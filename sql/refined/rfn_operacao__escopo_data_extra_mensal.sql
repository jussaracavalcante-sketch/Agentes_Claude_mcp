-- rfn_operacao__escopo_data_extra_mensal  ·  Refined / operacao  ·  L2 INTERNAL
-- Grao: um mes da data extra x status da data extra. Le: trs_vjob__escopo_data_extra. Gatilho: evento em query-syQh. Identidade (07/10/2026): 7 datas extras = 7.
-- R1 E excecao de prazo de escopo (data adicional marcada pelo usuario), nao entrega. R2 Link e evidencia nao atravessam; so se sao iguais ou ausentes (5 de 7 iguais).
-- R3 Status e codigo sem tabela de dominio: sai cru (todos 4 hoje). R4 7 linhas em 2026-05 a 2026-06: contagem, nao tendencia.
WITH x AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_vjob__escopo_data_extra`
),
agg AS (
  SELECT
    DATE_TRUNC(data_extra, MONTH) AS mes_data_extra,
    status_extra,
    COUNT(*) AS qtd_datas_extras,
    COUNT(DISTINCT id_escopo) AS qtd_escopos_distintos,
    COUNT(DISTINCT id_usuario) AS qtd_usuarios_distintos,
    COUNTIF(flag_links_iguais) AS qtd_links_iguais,
    COUNTIF(link_evidencia IS NULL) AS qtd_sem_evidencia,
    COUNTIF(flag_escopo_nao_catalogado) AS qtd_escopo_nao_catalogado,
    MIN(data_extra) AS primeira_data,
    MAX(data_extra) AS ultima_data
  FROM x
  GROUP BY 1, 2
),
final AS (
  SELECT CONCAT(IFNULL(CAST(mes_data_extra AS STRING), 'SEM_DATA'), '|', IFNULL(CAST(status_extra AS STRING), 'NULO')) AS id_data_extra_mensal, a.*, 'L2_INTERNAL' AS classificacao_dado
  FROM agg a
)
SELECT f.*, CURRENT_TIMESTAMP() AS _extraido_at, 'mysql-yIOn' AS _fonte,
  'America/Sao_Paulo' AS _fuso, TO_HEX(MD5(TO_JSON_STRING(f))) AS _payload_hash
FROM final f
