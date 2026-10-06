-- rfn_cliente__contexto_ia  (query-3mM8)
-- Refined / cliente, L2, gatilho "all" em query-vqwG (ia_cliente_config), query-cAhw (ia_documento) e query-GbCw (ia_solicitacao).
-- Grao: um cliente do VJOB (cadastro juridico) que apareca na configuracao, nos documentos ou nas solicitacoes de IA. Nenhum texto atravessa.
-- Medido em 06/10/2026: 3 clientes, 3 configuracoes (1 vazia), 21 documentos (4 sem conteudo, 48.022 caracteres), 87 solicitacoes.
WITH c AS (
  SELECT
    id_cliente,
    ANY_VALUE(cliente_nome) AS cliente_nome,
    COUNT(*) AS qtd_configuracoes,
    MAX(qtd_campos_preenchidos) AS qtd_campos_preenchidos,
    MAX(qtd_campos_possiveis) AS qtd_campos_possiveis,
    SUM(chars_contexto) AS chars_contexto,
    LOGICAL_OR(flag_config_vazia) AS flag_config_vazia,
    LOGICAL_OR(is_ativo) AS is_ativo,
    MAX(atualizado_em) AS config_atualizada_em,
    MAX(_extraido_at) AS _extraido_c
  FROM `vanguardamartech_trusted`.`trs_vjob__ia_cliente_config`
  GROUP BY id_cliente
),
d AS (
  SELECT
    id_cliente,
    ANY_VALUE(cliente_nome) AS cliente_nome_doc,
    COUNT(*) AS qtd_documentos,
    COUNTIF(flag_sem_conteudo) AS qtd_documentos_sem_conteudo,
    SUM(chars_conteudo) AS chars_documentos,
    MAX(criado_em) AS ultimo_documento_em,
    MAX(_extraido_at) AS _extraido_d
  FROM `vanguardamartech_trusted`.`trs_vjob__ia_documento`
  GROUP BY id_cliente
),
s AS (
  SELECT
    id_cliente,
    ANY_VALUE(cliente_nome) AS cliente_nome_sol,
    COUNT(*) AS qtd_solicitacoes,
    COUNTIF(is_concluido) AS qtd_solicitacoes_concluidas,
    COUNTIF(is_erro) AS qtd_solicitacoes_erro,
    MAX(criado_em) AS ultima_solicitacao_em,
    MAX(_extraido_at) AS _extraido_s
  FROM `vanguardamartech_trusted`.`trs_vjob__ia_solicitacao`
  GROUP BY id_cliente
)
SELECT
  COALESCE(c.id_cliente, d.id_cliente, s.id_cliente) AS id_cliente,
  COALESCE(c.cliente_nome, d.cliente_nome_doc, s.cliente_nome_sol) AS cliente_nome,
  (c.id_cliente IS NOT NULL) AS tem_configuracao,
  IFNULL(c.qtd_campos_preenchidos, 0) AS qtd_campos_preenchidos,
  c.qtd_campos_possiveis AS qtd_campos_possiveis,
  IFNULL(c.chars_contexto, 0) AS chars_contexto,
  IFNULL(c.flag_config_vazia, FALSE) AS flag_config_vazia,
  c.is_ativo AS config_ativa,
  c.config_atualizada_em,
  IFNULL(d.qtd_documentos, 0) AS qtd_documentos,
  IFNULL(d.qtd_documentos_sem_conteudo, 0) AS qtd_documentos_sem_conteudo,
  IFNULL(d.chars_documentos, 0) AS chars_documentos,
  d.ultimo_documento_em,
  IFNULL(s.qtd_solicitacoes, 0) AS qtd_solicitacoes,
  IFNULL(s.qtd_solicitacoes_concluidas, 0) AS qtd_solicitacoes_concluidas,
  IFNULL(s.qtd_solicitacoes_erro, 0) AS qtd_solicitacoes_erro,
  s.ultima_solicitacao_em,
  (c.id_cliente IS NULL AND s.id_cliente IS NOT NULL) AS flag_usa_ia_sem_configuracao,
  (c.id_cliente IS NOT NULL AND IFNULL(s.qtd_solicitacoes, 0) = 0) AS flag_configurado_sem_uso,
  CURRENT_TIMESTAMP() AS _extraido_at,
  GREATEST(IFNULL(c._extraido_c, TIMESTAMP '1970-01-01'), IFNULL(d._extraido_d, TIMESTAMP '1970-01-01'), IFNULL(s._extraido_s, TIMESTAMP '1970-01-01')) AS _extraido_trusted
FROM c
FULL OUTER JOIN d USING (id_cliente)
FULL OUTER JOIN s USING (id_cliente)
