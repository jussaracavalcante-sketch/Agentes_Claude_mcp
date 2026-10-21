-- rfn_operacao__evento_sistema_mensal  ·  Refined / operacao  ·  L2 INTERNAL (a Trusted e L4 por telefone; telefone, etapa e texto NAO atravessam)
-- Grao: um mes do evento x origem x tipo de evento. Le: trs_vjob__evento_sistema. Gatilho: evento em query-4fJW. Identidade (07/10/2026): 73 eventos = 73.
-- R1 SMS e REGISTRADO, nao entregue: nao ha status de operadora. R2 qtd_telefones_distintos e contagem, nunca o numero. R3 O historico e de 2023-05 a 2025-02: modulo parado.
-- R4 Data do evento e DATE(ocorrido_em) sem fuso: o VJOB grava hora local.
WITH e AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_vjob__evento_sistema`
),
agg AS (
  SELECT
    DATE_TRUNC(DATE(ocorrido_em), MONTH) AS mes_evento,
    origem,
    COALESCE(texto_tipo, '(sem tipo)') AS texto_tipo,
    COUNT(*) AS qtd_eventos,
    COUNT(DISTINCT id_usuario) AS qtd_usuarios_distintos,
    COUNTIF(telefone_digitos IS NOT NULL) AS qtd_com_telefone,
    COUNT(DISTINCT telefone_digitos) AS qtd_telefones_distintos,
    COUNTIF(flag_telefone_fora_de_forma) AS qtd_telefone_fora_de_forma,
    COUNT(DISTINCT id_alvo) AS qtd_alvos_distintos,
    COUNTIF(id_quem_marcou IS NOT NULL) AS qtd_com_quem_marcou,
    ROUND(AVG(texto_chars), 1) AS texto_chars_medio
  FROM e
  GROUP BY 1, 2, 3
),
final AS (
  SELECT CONCAT(IFNULL(CAST(mes_evento AS STRING), 'SEM_DATA'), '|', origem, '|', texto_tipo) AS id_evento_mensal, a.*, 'L2_INTERNAL' AS classificacao_dado
  FROM agg a
)
SELECT f.*, CURRENT_TIMESTAMP() AS _extraido_at, 'mysql-yIOn' AS _fonte,
  'America/Sao_Paulo' AS _fuso, TO_HEX(MD5(TO_JSON_STRING(f))) AS _payload_hash
FROM final f
