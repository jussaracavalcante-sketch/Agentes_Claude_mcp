-- slug no deploy: query-TRSi (esta linha existe so no arquivo)
-- Refined Marketing - contatos por estagio do funil (RD Station). L2 INTERNAL (so contagem; nenhum e-mail/uuid).
-- Grao: conta RD (_fonte) x estagio. Chave id_funil_estagio. Validado 18/10/2026 sobre a Raw: 3 linhas, 4.344 contatos = Trusted, 362 oportunidades, 2.500 com detalhe.
WITH f AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_rd_station__funil_contato`
  QUALIFY ROW_NUMBER() OVER (PARTITION BY uuid_contato ORDER BY tem_contato_detalhado DESC, _fonte) = 1
),
m AS (
  SELECT
    _fonte,
    cliente,
    IFNULL(estagio_funil, 'SEM_ESTAGIO') AS estagio_funil,
    COUNT(*) AS qtd_contatos,
    COUNTIF(is_oportunidade) AS qtd_oportunidades,
    COUNTIF(tem_contato_detalhado) AS qtd_com_contato_detalhado,
    COUNTIF(interesse IS NOT NULL) AS qtd_com_interesse
  FROM f
  GROUP BY _fonte, cliente, IFNULL(estagio_funil, 'SEM_ESTAGIO')
)
SELECT
  CONCAT(_fonte,'|',estagio_funil) AS id_funil_estagio,
  _fonte,
  cliente,
  estagio_funil,
  qtd_contatos,
  qtd_oportunidades,
  SAFE_DIVIDE(qtd_oportunidades, qtd_contatos) AS taxa_oportunidade,
  qtd_com_contato_detalhado,
  qtd_com_interesse,
  CURRENT_TIMESTAMP() AS _extraido_at
FROM m
