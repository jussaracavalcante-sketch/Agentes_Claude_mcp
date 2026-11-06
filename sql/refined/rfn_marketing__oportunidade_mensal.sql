-- slug no deploy: query-lFEK (esta linha existe so no arquivo)
-- Refined Marketing - eventos de oportunidade por mes (RD Station). L2 INTERNAL (so contagem; nenhum e-mail/uuid).
-- Grao: mes x _fonte x tipo x familia x funil. Chave id_oportunidade_mensal. Validado 18/10/2026 sobre a Raw: 22 linhas, 363 eventos = Trusted.
WITH o AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_rd_station__oportunidade_evento`
  QUALIFY ROW_NUMBER() OVER (PARTITION BY id_evento_origem ORDER BY _fonte) = 1
),
m AS (
  SELECT
    mes_referencia,
    _fonte,
    cliente,
    IFNULL(tipo_evento, 'SEM_TIPO') AS tipo_evento,
    IFNULL(familia_evento, 'SEM_FAMILIA') AS familia_evento,
    IFNULL(nome_funil, 'SEM_FUNIL') AS nome_funil,
    COUNT(*) AS qtd_eventos,
    COUNT(DISTINCT uuid_contato) AS qtd_contatos_distintos,
    MIN(ocorrido_data) AS primeiro_dia,
    MAX(ocorrido_data) AS ultimo_dia
  FROM o
  GROUP BY mes_referencia, _fonte, cliente, IFNULL(tipo_evento, 'SEM_TIPO'), IFNULL(familia_evento, 'SEM_FAMILIA'), IFNULL(nome_funil, 'SEM_FUNIL')
)
SELECT
  CONCAT(IFNULL(CAST(mes_referencia AS STRING),'sem_data'),'|',_fonte,'|',tipo_evento,'|',familia_evento,'|',nome_funil) AS id_oportunidade_mensal,
  mes_referencia,
  _fonte,
  cliente,
  tipo_evento,
  familia_evento,
  nome_funil,
  qtd_eventos,
  qtd_contatos_distintos,
  primeiro_dia,
  ultimo_dia,
  CURRENT_TIMESTAMP() AS _extraido_at
FROM m
