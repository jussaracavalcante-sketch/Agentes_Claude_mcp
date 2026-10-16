-- rfn_operacao__link_publico_escopo  (query-fDoo)
-- Refined / operacao, L3, gatilho de evento em query-xrav (trs_vjob__escopo_link_publico).
-- Grao: uma conta de atendimento do VJOB. Resume os links publicos de escopo (70 links,
-- 17 contas na medicao de 06/10/2026): quantos estao ativos, sem expiracao e vigentes na carga.
-- O token do link NAO e emitido (secret e L5, ver ADR-0010 par.31).
-- As flags *_na_carga congelam na carga: para ler hoje, comparar expira_em com a data de hoje.
-- Medido antes de publicar: links 70, vigentes 40, sem expiracao 29, contas desativadas
-- com link vigente 2.
SELECT
  l.id_conta_atendimento,
  ARRAY_AGG(c.nome_conta IGNORE NULLS LIMIT 1)[SAFE_OFFSET(0)] AS nome_conta,
  LOGICAL_AND(IFNULL(c.is_ativo, FALSE) = FALSE) AS conta_desativada_no_cadastro,
  LOGICAL_OR(c.id_atendimento IS NULL) AS flag_conta_nao_catalogada,
  COUNT(*) AS qtd_links, COUNTIF(l.ativo) AS qtd_ativos,
  COUNTIF(l.flag_sem_expiracao) AS qtd_sem_expiracao,
  COUNTIF(l.ativo AND (l.flag_sem_expiracao OR l.expira_em > l._extraido_at)) AS qtd_vigentes_na_carga,
  COUNTIF(l.ativo AND l.flag_sem_expiracao) AS qtd_vigentes_sem_expiracao,
  COUNTIF(l.flag_criado_no_futuro) AS qtd_criados_no_futuro,
  COUNT(DISTINCT l.id_criador) AS qtd_criadores_distintos,
  MIN(l.criado_em) AS primeiro_link_em, MAX(l.criado_em) AS ultimo_link_em,
  MAX(l.expira_em) AS expira_mais_tarde_em, AVG(l.dias_de_validade) AS validade_media_dias,
  (LOGICAL_AND(IFNULL(c.is_ativo, FALSE) = FALSE)
   AND COUNTIF(l.ativo AND (l.flag_sem_expiracao OR l.expira_em > l._extraido_at)) > 0) AS flag_conta_desativada_com_link_vigente,
  CURRENT_TIMESTAMP() AS _extraido_at, MAX(l._extraido_at) AS _extraido_trusted
FROM `vanguardamartech_trusted`.`trs_vjob__escopo_link_publico` l
LEFT JOIN `vanguardamartech_trusted`.`trs_vjob__cliente_atendimento` c ON c.id_atendimento = l.id_conta_atendimento
GROUP BY l.id_conta_atendimento
