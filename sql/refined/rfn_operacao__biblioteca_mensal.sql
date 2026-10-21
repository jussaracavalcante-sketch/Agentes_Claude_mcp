-- rfn_operacao__biblioteca_mensal  ·  Refined / operacao  ·  L2 INTERNAL
-- Grao: um mes de cadastro x origem (LINK/LINK_2/LINK_3/DOWNLOAD/ATA/SGI). Le: trs_vjob__biblioteca_item. Gatilho: evento em query-Bfgi.
-- Identidade (07/10/2026): 251 itens = 251. Titulo, URL e arquivo NAO atravessam (so contagem e host nao e emitido).
-- R1 LINK, LINK_2 e LINK_3 sao tres tabelas de origem do mesmo tipo de item; a familia vem em familia_origem e a origem crua fica no grao.
-- R2 qtd_url_http e o link sem TLS (140 de 251). R3 qtd_sem_destino e item sem URL e sem arquivo. R4 Cadastro, nao uso: nao ha leitura aqui.
WITH b AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_vjob__biblioteca_item`
),
agg AS (
  SELECT
    DATE_TRUNC(DATE(cadastrado_em), MONTH) AS mes_cadastro,
    origem,
    REGEXP_REPLACE(origem, r'_[0-9]+$', '') AS familia_origem,
    COUNT(*) AS qtd_itens,
    COUNTIF(flag_sem_destino) AS qtd_sem_destino,
    COUNTIF(flag_url_http) AS qtd_url_http,
    COUNTIF(url IS NOT NULL) AS qtd_com_url,
    COUNTIF(arquivo IS NOT NULL) AS qtd_com_arquivo,
    COUNTIF(id_conta_atendimento IS NOT NULL) AS qtd_com_conta,
    COUNT(DISTINCT id_conta_atendimento) AS qtd_contas_distintas,
    COUNT(DISTINCT id_usuario) AS qtd_usuarios_distintos,
    COUNTIF(flag_conta_nao_catalogada) AS qtd_conta_nao_catalogada
  FROM b
  GROUP BY 1, 2, 3
),
final AS (
  SELECT CONCAT(IFNULL(CAST(mes_cadastro AS STRING), 'SEM_DATA'), '|', origem) AS id_biblioteca_mensal, a.*, 'L2_INTERNAL' AS classificacao_dado
  FROM agg a
)
SELECT f.*, CURRENT_TIMESTAMP() AS _extraido_at, 'mysql-yIOn' AS _fonte,
  'America/Sao_Paulo' AS _fuso, TO_HEX(MD5(TO_JSON_STRING(f))) AS _payload_hash
FROM final f
