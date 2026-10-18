-- slug no deploy: query-vOxN (esta linha existe so no arquivo)
-- Refined Marketing - resumo de e-mail das automacoes (RD Station). L2 INTERNAL. Grao: _fonte x automacao (fotografia da ultima janela).
-- Validado 18/10/2026 sobre a Raw em 12 fontes: 87 -> 22 linhas, acoes + duplicatas = 87, entregues 135 = canonico.
WITH w AS (
  SELECT t.*,
    COUNT(*) OVER (PARTITION BY id_acao_origem, nome_email, janela_inicio) AS qtd_linhas_da_acao
  FROM `vanguardamartech_trusted`.`trs_rd_station__automacao_email_desempenho` t
),
c AS (
  SELECT * FROM w
  QUALIFY ROW_NUMBER() OVER (PARTITION BY id_acao_origem, nome_email, janela_inicio ORDER BY qtd_contatos DESC, _fonte) = 1
),
m AS (
  SELECT
    _fonte,
    cliente,
    id_automacao_origem,
    MIN(nome_automacao) AS nome_automacao,
    COUNT(*) AS qtd_acoes_email,
    SUM(qtd_linhas_da_acao - 1) AS qtd_linhas_duplicadas_removidas,
    MIN(janela_inicio) AS janela_inicio,
    MAX(janela_fim) AS janela_fim,
    SUM(qtd_contatos) AS qtd_contatos_alvo,
    SUM(qtd_processados) AS qtd_processados,
    SUM(qtd_entregues) AS qtd_entregues,
    SUM(qtd_rejeitados) AS qtd_rejeitados,
    SUM(qtd_abertos_unicos) AS qtd_abertos_unicos,
    SUM(qtd_cliques_unicos) AS qtd_cliques_unicos,
    SUM(qtd_descadastros) AS qtd_descadastros,
    SUM(qtd_spam) AS qtd_spam,
    COUNTIF(flag_abertos_maior_que_entregues) AS qtd_acoes_abertos_maior_que_entregues
  FROM c
  GROUP BY _fonte, cliente, id_automacao_origem
)
SELECT
  CONCAT(_fonte,'|',id_automacao_origem) AS id_automacao_resumo,
  _fonte,
  cliente,
  id_automacao_origem,
  nome_automacao,
  janela_inicio,
  janela_fim,
  qtd_acoes_email,
  qtd_linhas_duplicadas_removidas,
  qtd_contatos_alvo,
  qtd_processados,
  qtd_entregues,
  qtd_rejeitados,
  qtd_abertos_unicos,
  qtd_cliques_unicos,
  qtd_descadastros,
  qtd_spam,
  SAFE_DIVIDE(qtd_entregues, qtd_processados) AS taxa_entrega_sobre_processados,
  SAFE_DIVIDE(qtd_abertos_unicos, qtd_entregues) AS taxa_abertura_unica,
  SAFE_DIVIDE(qtd_cliques_unicos, qtd_entregues) AS taxa_clique_unico,
  qtd_acoes_abertos_maior_que_entregues,
  CURRENT_TIMESTAMP() AS _extraido_at
FROM m
