-- slug no deploy: query-UpTQ (esta linha existe so no arquivo)
-- Refined Marketing - desempenho de e-mail de campanha por mes (RD Station). L2 INTERNAL (so contagem e taxas; nenhum contato).
-- Grao: mes do envio x _fonte. Chave id_email_mensal. Validado 18/10/2026 sobre a Raw em 12 fontes: 214 -> 29 linhas, envios + duplicatas = 214, entregues 2.039.906 = canonico.
WITH e AS (
  SELECT t.*,
    COUNT(*) OVER (PARTITION BY id_campanha_origem, enviado_em) AS qtd_linhas_da_campanha
  FROM `vanguardamartech_trusted`.`trs_rd_station__email_desempenho` t
),
c AS (
  SELECT * FROM e
  QUALIFY ROW_NUMBER() OVER (PARTITION BY id_campanha_origem, enviado_em ORDER BY qtd_contatos DESC, _fonte) = 1
),
m AS (
  SELECT
    mes_referencia,
    _fonte,
    cliente,
    COUNT(*) AS qtd_envios,
    SUM(qtd_linhas_da_campanha - 1) AS qtd_linhas_duplicadas_removidas,
    SUM(qtd_contatos) AS qtd_contatos_alvo,
    SUM(qtd_entregues) AS qtd_entregues,
    SUM(qtd_abertos) AS qtd_abertos,
    SUM(qtd_cliques) AS qtd_cliques,
    SUM(qtd_descadastros) AS qtd_descadastros,
    SUM(qtd_spam) AS qtd_spam,
    SUM(qtd_rejeitados) AS qtd_rejeitados,
    SUM(qtd_descartados) AS qtd_descartados,
    COUNTIF(flag_abertos_maior_que_entregues) AS qtd_envios_abertos_maior_que_entregues
  FROM c
  GROUP BY mes_referencia, _fonte, cliente
)
SELECT
  CONCAT(IFNULL(CAST(mes_referencia AS STRING),'sem_data'),'|',_fonte) AS id_email_mensal,
  mes_referencia,
  (mes_referencia IS NULL) AS flag_sem_data_de_envio,
  _fonte,
  cliente,
  qtd_envios,
  qtd_linhas_duplicadas_removidas,
  qtd_contatos_alvo,
  qtd_entregues,
  qtd_rejeitados,
  qtd_descartados,
  qtd_abertos,
  qtd_cliques,
  qtd_descadastros,
  qtd_spam,
  SAFE_DIVIDE(qtd_entregues, qtd_contatos_alvo) AS taxa_entrega,
  SAFE_DIVIDE(qtd_abertos, qtd_entregues) AS taxa_abertura,
  SAFE_DIVIDE(qtd_cliques, qtd_entregues) AS taxa_clique,
  SAFE_DIVIDE(qtd_descadastros, qtd_entregues) AS taxa_descadastro,
  SAFE_DIVIDE(qtd_spam, qtd_entregues) AS taxa_spam,
  qtd_envios_abertos_maior_que_entregues,
  CURRENT_TIMESTAMP() AS _extraido_at
FROM m
