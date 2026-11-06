-- rfn_qualidade__regra_vjob_refined (query-ro5f) · 28 regras · Refined / qualidade · L2 INTERNAL
-- Grao: uma REGRA em uma execucao. Cobre as 9 Refined do VJOB/IA/intranet publicadas em 06/10:
-- acao_administrativa_mensal, link_publico_escopo, job_prazo_mensal, verba_fornecedor_mensal, ia_uso_mensal,
-- rfn_cliente__contexto_ia, job_colaboracao_mensal, troca_analista_parcela_mensal, intranet_atividade_mensal.
-- Gatilho: evento nas 9 Refined com regra "all" (query-zch1, fDoo, 9pj3, USve, Cb92, 3mM8, x8md, 2MQf, bkJu). Cadencia semanal (mysql-yIOn, domingo). Alerta ligado.
-- Identidades: o que a Refined soma tem de reproduzir a Trusted de que le (a Refined agrega, nao filtra).
WITH r AS (
  SELECT 'rfn_operacao__acao_administrativa_mensal.chave_unica' AS id_regra, 'Refined' AS camada, 'rfn_operacao__acao_administrativa_mensal' AS tabela, 'VJOB' AS sistema, 'UNICIDADE' AS dimensao,
         'id_acao_mensal e unico e nunca nulo' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_acao_mensal) + COUNTIF(id_acao_mensal IS NULL) AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_operacao__acao_administrativa_mensal`
  UNION ALL SELECT 'rfn_operacao__link_publico_escopo.chave_unica', 'Refined', 'rfn_operacao__link_publico_escopo', 'VJOB', 'UNICIDADE',
         'id_conta_atendimento e unico e nunca nulo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_conta_atendimento) + COUNTIF(id_conta_atendimento IS NULL)
  FROM `vanguardamartech_refined`.`rfn_operacao__link_publico_escopo`
  UNION ALL SELECT 'rfn_operacao__job_prazo_mensal.chave_unica', 'Refined', 'rfn_operacao__job_prazo_mensal', 'VJOB', 'UNICIDADE',
         'chave (mes_referencia, origem) e unica', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT TO_JSON_STRING(STRUCT(mes_referencia, origem)))
  FROM `vanguardamartech_refined`.`rfn_operacao__job_prazo_mensal`
  UNION ALL SELECT 'rfn_operacao__verba_fornecedor_mensal.chave_unica', 'Refined', 'rfn_operacao__verba_fornecedor_mensal', 'VJOB', 'UNICIDADE',
         'chave (mes_referencia, id_fornecedor) e unica', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT TO_JSON_STRING(STRUCT(mes_referencia, id_fornecedor)))
  FROM `vanguardamartech_refined`.`rfn_operacao__verba_fornecedor_mensal`
  UNION ALL SELECT 'rfn_operacao__ia_uso_mensal.chave_unica', 'Refined', 'rfn_operacao__ia_uso_mensal', 'VJOB', 'UNICIDADE',
         'chave (mes_referencia, tipo_peca, status) e unica', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT TO_JSON_STRING(STRUCT(mes_referencia, tipo_peca, status)))
  FROM `vanguardamartech_refined`.`rfn_operacao__ia_uso_mensal`
  UNION ALL SELECT 'rfn_cliente__contexto_ia.chave_unica', 'Refined', 'rfn_cliente__contexto_ia', 'VJOB', 'UNICIDADE',
         'id_cliente e unico e nunca nulo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_cliente) + COUNTIF(id_cliente IS NULL)
  FROM `vanguardamartech_refined`.`rfn_cliente__contexto_ia`
  UNION ALL SELECT 'rfn_operacao__job_colaboracao_mensal.chave_unica', 'Refined', 'rfn_operacao__job_colaboracao_mensal', 'VJOB', 'UNICIDADE',
         'mes_referencia e unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT TO_JSON_STRING(mes_referencia))
  FROM `vanguardamartech_refined`.`rfn_operacao__job_colaboracao_mensal`
  UNION ALL SELECT 'rfn_operacao__troca_analista_parcela_mensal.chave_unica', 'Refined', 'rfn_operacao__troca_analista_parcela_mensal', 'VJOB', 'UNICIDADE',
         'mes_referencia e unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT TO_JSON_STRING(mes_referencia))
  FROM `vanguardamartech_refined`.`rfn_operacao__troca_analista_parcela_mensal`
  UNION ALL SELECT 'rfn_operacao__intranet_atividade_mensal.chave_unica', 'Refined', 'rfn_operacao__intranet_atividade_mensal', 'VJOB', 'UNICIDADE',
         'chave (mes_referencia, origem) e unica', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT TO_JSON_STRING(STRUCT(mes_referencia, origem)))
  FROM `vanguardamartech_refined`.`rfn_operacao__intranet_atividade_mensal`
  -- IDENTIDADES entre camadas (grao: a tabela inteira, 1 linha avaliada)
  UNION ALL SELECT 'rfn_operacao__acao_administrativa_mensal.acoes_reproduzem_a_trusted', 'Refined', 'rfn_operacao__acao_administrativa_mensal', 'VJOB', 'VALIDADE',
         'a soma de qtd_acoes reproduz as linhas de trs_vjob__acao_administrativa', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(qtd_acoes) FROM `vanguardamartech_refined`.`rfn_operacao__acao_administrativa_mensal`) <> (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_vjob__acao_administrativa`), 1, 0)
  UNION ALL SELECT 'rfn_operacao__link_publico_escopo.links_reproduzem_a_trusted', 'Refined', 'rfn_operacao__link_publico_escopo', 'VJOB', 'VALIDADE',
         'a soma de qtd_links reproduz as linhas de trs_vjob__escopo_link_publico', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(qtd_links) FROM `vanguardamartech_refined`.`rfn_operacao__link_publico_escopo`) <> (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_vjob__escopo_link_publico`), 1, 0)
  UNION ALL SELECT 'rfn_operacao__job_prazo_mensal.alteracoes_reproduzem_a_trusted', 'Refined', 'rfn_operacao__job_prazo_mensal', 'VJOB', 'VALIDADE',
         'a soma de qtd_alteracoes reproduz as linhas de trs_vjob__job_prazo_alteracao', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(qtd_alteracoes) FROM `vanguardamartech_refined`.`rfn_operacao__job_prazo_mensal`) <> (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_vjob__job_prazo_alteracao`), 1, 0)
  UNION ALL SELECT 'rfn_operacao__verba_fornecedor_mensal.verba_reproduz_a_trusted', 'Refined', 'rfn_operacao__verba_fornecedor_mensal', 'VJOB', 'VALIDADE',
         'a soma de valor_verba reproduz trs_vjob__cronograma_verba dentro de um centavo', 'BLOQUEANTE', 1.00,
         1, IF(ABS((SELECT SUM(valor_verba) FROM `vanguardamartech_refined`.`rfn_operacao__verba_fornecedor_mensal`) - (SELECT SUM(valor_verba) FROM `vanguardamartech_trusted`.`trs_vjob__cronograma_verba`)) > 0.01, 1, 0)
  UNION ALL SELECT 'rfn_operacao__ia_uso_mensal.solicitacoes_reproduzem_a_trusted', 'Refined', 'rfn_operacao__ia_uso_mensal', 'VJOB', 'VALIDADE',
         'a soma de qtd_solicitacoes reproduz as linhas de trs_vjob__ia_solicitacao', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(qtd_solicitacoes) FROM `vanguardamartech_refined`.`rfn_operacao__ia_uso_mensal`) <> (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_vjob__ia_solicitacao`), 1, 0)
  UNION ALL SELECT 'rfn_operacao__ia_uso_mensal.custo_reproduz_a_trusted', 'Refined', 'rfn_operacao__ia_uso_mensal', 'VJOB', 'VALIDADE',
         'a soma de custo_estimado_usd reproduz trs_vjob__ia_geracao dentro de um milionesimo de dolar', 'BLOQUEANTE', 1.00,
         1, IF(ABS((SELECT SUM(custo_estimado_usd) FROM `vanguardamartech_refined`.`rfn_operacao__ia_uso_mensal`) - (SELECT SUM(custo_estimado_usd) FROM `vanguardamartech_trusted`.`trs_vjob__ia_geracao`)) > 0.000001, 1, 0)
  UNION ALL SELECT 'rfn_cliente__contexto_ia.solicitacoes_reproduzem_a_trusted', 'Refined', 'rfn_cliente__contexto_ia', 'VJOB', 'VALIDADE',
         'a soma de qtd_solicitacoes reproduz as linhas de trs_vjob__ia_solicitacao', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(qtd_solicitacoes) FROM `vanguardamartech_refined`.`rfn_cliente__contexto_ia`) <> (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_vjob__ia_solicitacao`), 1, 0)
  UNION ALL SELECT 'rfn_cliente__contexto_ia.documentos_reproduzem_a_trusted', 'Refined', 'rfn_cliente__contexto_ia', 'VJOB', 'VALIDADE',
         'a soma de qtd_documentos reproduz as linhas de trs_vjob__ia_documento', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(qtd_documentos) FROM `vanguardamartech_refined`.`rfn_cliente__contexto_ia`) <> (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_vjob__ia_documento`), 1, 0)
  UNION ALL SELECT 'rfn_operacao__job_colaboracao_mensal.jobs_reproduzem_a_trusted', 'Refined', 'rfn_operacao__job_colaboracao_mensal', 'VJOB', 'VALIDADE',
         'a soma de qtd_jobs reproduz os jobs distintos de trs_vjob__job_responsavel (a Refined conta o job, nao a linha)', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(qtd_jobs) FROM `vanguardamartech_refined`.`rfn_operacao__job_colaboracao_mensal`) <> (SELECT COUNT(DISTINCT id_job_unico) FROM `vanguardamartech_trusted`.`trs_vjob__job_responsavel`), 1, 0)
  UNION ALL SELECT 'rfn_operacao__job_colaboracao_mensal.responsaveis_reproduzem_a_trusted', 'Refined', 'rfn_operacao__job_colaboracao_mensal', 'VJOB', 'VALIDADE',
         'a soma de qtd_responsaveis reproduz as linhas de trs_vjob__job_responsavel', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(qtd_responsaveis) FROM `vanguardamartech_refined`.`rfn_operacao__job_colaboracao_mensal`) <> (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_vjob__job_responsavel`), 1, 0)
  UNION ALL SELECT 'rfn_operacao__troca_analista_parcela_mensal.alteracoes_reproduzem_a_trusted', 'Refined', 'rfn_operacao__troca_analista_parcela_mensal', 'VJOB', 'VALIDADE',
         'a soma de qtd_alteracoes reproduz as linhas de trs_vjob__parcela_analista_alteracao', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(qtd_alteracoes) FROM `vanguardamartech_refined`.`rfn_operacao__troca_analista_parcela_mensal`) <> (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_vjob__parcela_analista_alteracao`), 1, 0)
  UNION ALL SELECT 'rfn_operacao__intranet_atividade_mensal.conteudos_reproduzem_a_trusted', 'Refined', 'rfn_operacao__intranet_atividade_mensal', 'VJOB', 'VALIDADE',
         'a soma de qtd_conteudos reproduz as linhas de trs_vjob__intranet_conteudo', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(qtd_conteudos) FROM `vanguardamartech_refined`.`rfn_operacao__intranet_atividade_mensal`) <> (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_vjob__intranet_conteudo`), 1, 0)
  UNION ALL SELECT 'rfn_operacao__intranet_atividade_mensal.leituras_reproduzem_a_trusted', 'Refined', 'rfn_operacao__intranet_atividade_mensal', 'VJOB', 'VALIDADE',
         'a soma de qtd_leituras reproduz as linhas de trs_vjob__intranet_leitura', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(qtd_leituras) FROM `vanguardamartech_refined`.`rfn_operacao__intranet_atividade_mensal`) <> (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_vjob__intranet_leitura`), 1, 0)
  -- DECOMPOSICOES E INVARIANTES por linha
  UNION ALL SELECT 'rfn_operacao__job_prazo_mensal.deslocamento_decompoe', 'Refined', 'rfn_operacao__job_prazo_mensal', 'VJOB', 'VALIDADE',
         'adiamentos + antecipacoes + sem deslocamento = alteracoes em toda linha', 'BLOQUEANTE', 1.00, COUNT(*),
         COUNTIF(qtd_adiamentos + qtd_antecipacoes + qtd_sem_deslocamento <> qtd_alteracoes)
  FROM `vanguardamartech_refined`.`rfn_operacao__job_prazo_mensal`
  UNION ALL SELECT 'rfn_operacao__link_publico_escopo.funil_de_links_nunca_inverte', 'Refined', 'rfn_operacao__link_publico_escopo', 'VJOB', 'VALIDADE',
         'vigentes na carga <= ativos <= links em toda conta', 'BLOQUEANTE', 1.00, COUNT(*),
         COUNTIF(qtd_vigentes_na_carga > qtd_ativos OR qtd_ativos > qtd_links)
  FROM `vanguardamartech_refined`.`rfn_operacao__link_publico_escopo`
  UNION ALL SELECT 'rfn_operacao__acao_administrativa_mensal.verbos_nao_excedem_o_total', 'Refined', 'rfn_operacao__acao_administrativa_mensal', 'VJOB', 'VALIDADE',
         'ativou + desativou + deletou <= acoes em toda linha', 'BLOQUEANTE', 1.00, COUNT(*),
         COUNTIF(qtd_ativou + qtd_desativou + qtd_deletou > qtd_acoes)
  FROM `vanguardamartech_refined`.`rfn_operacao__acao_administrativa_mensal`
  UNION ALL SELECT 'rfn_cliente__contexto_ia.campos_preenchidos_nao_excedem_os_possiveis', 'Refined', 'rfn_cliente__contexto_ia', 'VJOB', 'VALIDADE',
         'qtd_campos_preenchidos <= qtd_campos_possiveis quando ha configuracao', 'BLOQUEANTE', 1.00, COUNTIF(qtd_campos_possiveis IS NOT NULL),
         COUNTIF(qtd_campos_possiveis IS NOT NULL AND qtd_campos_preenchidos > qtd_campos_possiveis)
  FROM `vanguardamartech_refined`.`rfn_cliente__contexto_ia`
  UNION ALL SELECT 'rfn_operacao__ia_uso_mensal.taxa_de_conclusao_entre_zero_e_um', 'Refined', 'rfn_operacao__ia_uso_mensal', 'VJOB', 'VALIDADE',
         'taxa_conclusao esta entre 0 e 1', 'BLOQUEANTE', 1.00, COUNTIF(taxa_conclusao IS NOT NULL),
         COUNTIF(taxa_conclusao < 0 OR taxa_conclusao > 1)
  FROM `vanguardamartech_refined`.`rfn_operacao__ia_uso_mensal`
  UNION ALL SELECT 'rfn_operacao__job_colaboracao_mensal.todo_job_tem_um_principal', 'Refined', 'rfn_operacao__job_colaboracao_mensal', 'VJOB', 'INTEGRIDADE',
         'nenhum job sem principal unico (invariante da Trusted: exatamente um principal por job)', 'BLOQUEANTE', 1.00, SUM(qtd_jobs),
         SUM(qtd_jobs_sem_principal_unico)
  FROM `vanguardamartech_refined`.`rfn_operacao__job_colaboracao_mensal`
),
avaliado AS (
  SELECT r.*, (r.linhas_avaliadas - r.linhas_falha) AS linhas_conformes,
    SAFE_DIVIDE(r.linhas_avaliadas - r.linhas_falha, NULLIF(r.linhas_avaliadas, 0)) AS taxa_conformidade,
    IF(r.linhas_avaliadas = 0, NULL, SAFE_DIVIDE(r.linhas_avaliadas - r.linhas_falha, r.linhas_avaliadas) >= r.limiar) AS is_conforme,
    (r.linhas_avaliadas = 0) AS flag_sem_linha_para_avaliar
  FROM r
)
SELECT a.*,
  CASE WHEN a.flag_sem_linha_para_avaliar THEN 'SEM_DADO' WHEN a.is_conforme THEN 'CONFORME'
       WHEN a.severidade = 'BLOQUEANTE' THEN 'FALHA_BLOQUEANTE' ELSE 'FALHA_ALERTA' END AS resultado,
  'VJOB_REFINED' AS familia, CURRENT_TIMESTAMP() AS _extraido_at, 'mysql-yIOn' AS _fonte, 'America/Sao_Paulo' AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(a))) AS _payload_hash
FROM avaliado a
