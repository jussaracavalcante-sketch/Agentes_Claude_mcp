-- rfn_qualidade__regra_rh_operacao_dimensoes  ·  57 regras  ·  L2 INTERNAL
-- Refined / qualidade. Grao: uma REGRA de qualidade em uma execucao. Chave: id_regra (a execucao se le em _extraido_at).
-- Cobre as 13 Refined publicadas em 19/10/2026 sobre 15 Trusted de dimensao e catalogo: iClips (colaborador, horas por job, mapa de
--   workflow), Linear (equipe, rotulo, usuario), Quickin (candidato, dominio, funil, requisicao), Qulture (dominio, interacao, objetivo,
--   organograma) e VJOB (item da tabela de precos de orcamento).
-- Gatilho: evento com regra "all" nas 12 Refined diarias (as 11 do supabase-x0tz mais a do Linear). A do VJOB (orcamento) NAO entra no
--   gatilho porque roda so no domingo e prenderia a suite inteira a cadencia semanal; ela e MEDIDA na suite (tabela materializada) e a
--   identidade dela so se renova quando a mysql-yIOn roda. Alerta de falha ligado. Cadencia diaria.
-- POR QUE SUITE PROPRIA: a rfn_qualidade__regra principal esta em 57 KB e update_transformation substitui o codigo inteiro.
-- O QUE A SUITE FAZ: 15 unicidades de chave (BLOQUEANTE), as identidades Trusted -> Refined (a Refined agrega e nao filtra, entao a soma
--   reproduz a Trusted: contagem, horas, score, valor), invariantes por linha (NULL e ausencia, nao zero) e linhas de base de ALERTA com
--   limiar medido em 19/10/2026 (projeto catalogado 81,8%, custo/hora implausivel 3 de 128, pai de objetivo, cargo no organograma).
-- LIMITE DE COBERTURA: so tabelas materializadas. Regra sem linha para avaliar NAO passa (SEM_DADO), nunca CONFORME.
-- FRESCOR: carga_do_mesmo_dia compara MAX(DATE(_extraido_at)) so entre as 11 Refined do supabase-x0tz (mesma fonte, mesma passada);
--   nao inclui Linear nem VJOB (outras fontes e cadencias: uma regra entre elas falharia por desenho).
-- QUALIFICACAO: nada pessoal atravessa estas Refined; a unica regra de dado pessoal (email_so_no_avaliador) guarda que o e-mail do
--   Quickin nao saia do dominio AVALIADOR.
WITH r_regras AS (
  SELECT 'rfn_operacao__colaborador_iclips_resumo.id_unico' AS id_regra, 'Refined' AS camada, 'rfn_operacao__colaborador_iclips_resumo' AS tabela, 'iClips' AS sistema, 'UNICIDADE' AS dimensao,
         "id_colaborador_resumo e unico e nunca nulo" AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         CAST(COUNT(*) AS INT64) AS linhas_avaliadas, CAST(COUNT(*) - COUNT(DISTINCT id_colaborador_resumo) + COUNTIF(id_colaborador_resumo IS NULL) AS INT64) AS linhas_falha FROM `vanguardamartech_refined`.`rfn_operacao__colaborador_iclips_resumo`
  UNION ALL
  SELECT 'rfn_operacao__colaborador_iclips_resumo.colaboradores_reproduzem_a_trusted', 'Refined', 'rfn_operacao__colaborador_iclips_resumo', 'iClips', 'INTEGRIDADE',
         "a soma de colaboradores da Refined e o total da Trusted", 'BLOQUEANTE', 1.00,
         CAST(1 AS INT64), CAST(IF((SELECT SUM(qtd_colaboradores) FROM `vanguardamartech_refined`.`rfn_operacao__colaborador_iclips_resumo`) = (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_iclips__colaborador`), 0, 1) AS INT64) AS linhas_falha
  UNION ALL
  SELECT 'rfn_operacao__colaborador_iclips_resumo.custo_reproduz_a_trusted', 'Refined', 'rfn_operacao__colaborador_iclips_resumo', 'iClips', 'INTEGRIDADE',
         "a soma de colaboradores com custo/hora reproduz a Trusted", 'BLOQUEANTE', 1.00,
         CAST(1 AS INT64), CAST(IF((SELECT SUM(qtd_com_custo_hora) FROM `vanguardamartech_refined`.`rfn_operacao__colaborador_iclips_resumo`) = (SELECT COUNTIF(custo_hora IS NOT NULL) FROM `vanguardamartech_trusted`.`trs_iclips__colaborador`), 0, 1) AS INT64) AS linhas_falha
  UNION ALL
  SELECT 'rfn_operacao__colaborador_iclips_resumo.custo_em_inativo_dentro_do_custo', 'Refined', 'rfn_operacao__colaborador_iclips_resumo', 'iClips', 'VALIDADE',
         "colaborador inativo com custo nunca excede os que tem custo", 'BLOQUEANTE', 1.00,
         CAST(COUNT(*) AS INT64), CAST(COUNTIF(qtd_custo_em_inativo > qtd_com_custo_hora) AS INT64) FROM `vanguardamartech_refined`.`rfn_operacao__colaborador_iclips_resumo`
  UNION ALL
  SELECT 'rfn_operacao__colaborador_iclips_resumo.custo_hora_plausivel', 'Refined', 'rfn_operacao__colaborador_iclips_resumo', 'iClips', 'VALIDADE',
         "custo/hora acima de R$ 500 e marca de origem (3 de 128 em 19/10/2026); linha de base para detectar piora", 'ALERTA', 0.95,
         CAST(IFNULL(SUM(qtd_com_custo_hora),0) AS INT64), CAST(IFNULL(SUM(qtd_custo_hora_implausivel),0) AS INT64) FROM `vanguardamartech_refined`.`rfn_operacao__colaborador_iclips_resumo`
  UNION ALL
  SELECT 'rfn_operacao__job_horas_mensal.id_unico', 'Refined', 'rfn_operacao__job_horas_mensal', 'iClips', 'UNICIDADE',
         "id_job_horas_mensal e unico e nunca nulo", 'BLOQUEANTE', 1.00,
         CAST(COUNT(*) AS INT64), CAST(COUNT(*) - COUNT(DISTINCT id_job_horas_mensal) + COUNTIF(id_job_horas_mensal IS NULL) AS INT64) FROM `vanguardamartech_refined`.`rfn_operacao__job_horas_mensal`
  UNION ALL
  SELECT 'rfn_operacao__job_horas_mensal.jobs_reproduzem_a_trusted', 'Refined', 'rfn_operacao__job_horas_mensal', 'iClips', 'INTEGRIDADE',
         "a soma de jobs da Refined e o total da Trusted", 'BLOQUEANTE', 1.00,
         CAST(1 AS INT64), CAST(IF((SELECT SUM(qtd_jobs) FROM `vanguardamartech_refined`.`rfn_operacao__job_horas_mensal`) = (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_iclips__job_horas`), 0, 1) AS INT64) AS linhas_falha
  UNION ALL
  SELECT 'rfn_operacao__job_horas_mensal.horas_realizadas_reproduzem', 'Refined', 'rfn_operacao__job_horas_mensal', 'iClips', 'INTEGRIDADE',
         "a soma de horas realizadas reproduz a Trusted dentro de 0,01 h", 'BLOQUEANTE', 1.00,
         CAST(1 AS INT64), CAST(IF(ABS(IFNULL((SELECT SUM(horas_realizadas) FROM `vanguardamartech_refined`.`rfn_operacao__job_horas_mensal`),0) - IFNULL((SELECT SUM(horas_realizadas) FROM `vanguardamartech_trusted`.`trs_iclips__job_horas`),0)) <= 0.01, 0, 1) AS INT64) AS linhas_falha
  UNION ALL
  SELECT 'rfn_operacao__job_horas_mensal.horas_estimadas_reproduzem', 'Refined', 'rfn_operacao__job_horas_mensal', 'iClips', 'INTEGRIDADE',
         "a soma de horas estimadas reproduz a Trusted dentro de 0,01 h", 'BLOQUEANTE', 1.00,
         CAST(1 AS INT64), CAST(IF(ABS(IFNULL((SELECT SUM(horas_estimadas) FROM `vanguardamartech_refined`.`rfn_operacao__job_horas_mensal`),0) - IFNULL((SELECT SUM(IF(tem_horas_estimadas, horas_estimadas, NULL)) FROM `vanguardamartech_trusted`.`trs_iclips__job_horas`),0)) <= 0.01, 0, 1) AS INT64) AS linhas_falha
  UNION ALL
  SELECT 'rfn_operacao__job_horas_mensal.estimada_null_concorda', 'Refined', 'rfn_operacao__job_horas_mensal', 'iClips', 'VALIDADE',
         "horas_estimadas e NULL exatamente quando nenhum job do grupo tem estimativa", 'BLOQUEANTE', 1.00,
         CAST(COUNT(*) AS INT64), CAST(COUNTIF((horas_estimadas IS NULL) <> (qtd_com_horas_estimadas = 0)) AS INT64) FROM `vanguardamartech_refined`.`rfn_operacao__job_horas_mensal`
  UNION ALL
  SELECT 'rfn_operacao__job_horas_mensal.projeto_catalogado', 'Refined', 'rfn_operacao__job_horas_mensal', 'iClips', 'INTEGRIDADE',
         "jobs com projeto na trs_iclips__projeto: 2.372 de 2.899 (81,8%) em 19/10/2026; linha de base, a causa dos 527 nao foi verificada", 'ALERTA', 0.75,
         CAST(IFNULL(SUM(qtd_jobs),0) AS INT64), CAST(IFNULL(SUM(qtd_projeto_nao_catalogado),0) AS INT64) FROM `vanguardamartech_refined`.`rfn_operacao__job_horas_mensal`
  UNION ALL
  SELECT 'rfn_operacao__workflow_mapa_resumo.id_unico', 'Refined', 'rfn_operacao__workflow_mapa_resumo', 'iClips', 'UNICIDADE',
         "id_workflow_resumo e unico e nunca nulo", 'BLOQUEANTE', 1.00,
         CAST(COUNT(*) AS INT64), CAST(COUNT(*) - COUNT(DISTINCT id_workflow_resumo) + COUNTIF(id_workflow_resumo IS NULL) AS INT64) FROM `vanguardamartech_refined`.`rfn_operacao__workflow_mapa_resumo`
  UNION ALL
  SELECT 'rfn_operacao__workflow_mapa_resumo.nomes_reproduzem_a_trusted', 'Refined', 'rfn_operacao__workflow_mapa_resumo', 'iClips', 'INTEGRIDADE',
         "a soma de nomes de etapa da Refined e o total da Trusted", 'BLOQUEANTE', 1.00,
         CAST(1 AS INT64), CAST(IF((SELECT SUM(qtd_nomes_de_etapa) FROM `vanguardamartech_refined`.`rfn_operacao__workflow_mapa_resumo`) = (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_iclips__workflow_mapa`), 0, 1) AS INT64) AS linhas_falha
  UNION ALL
  SELECT 'rfn_operacao__workflow_mapa_resumo.uso_reproduz_a_trusted', 'Refined', 'rfn_operacao__workflow_mapa_resumo', 'iClips', 'INTEGRIDADE',
         "a soma de etapas do iClips cobertas reproduz a Trusted", 'BLOQUEANTE', 1.00,
         CAST(1 AS INT64), CAST(IF((SELECT SUM(qtd_etapas_no_iclips) FROM `vanguardamartech_refined`.`rfn_operacao__workflow_mapa_resumo`) = (SELECT SUM(qtd_etapas_no_iclips) FROM `vanguardamartech_trusted`.`trs_iclips__workflow_mapa`), 0, 1) AS INT64) AS linhas_falha
  UNION ALL
  SELECT 'rfn_operacao__workflow_mapa_resumo.participacao_soma_um', 'Refined', 'rfn_operacao__workflow_mapa_resumo', 'iClips', 'VALIDADE',
         "a participacao no uso soma 1 sobre a tabela inteira", 'BLOQUEANTE', 1.00,
         CAST(1 AS INT64), CAST(IF((SELECT ROUND(SUM(participacao_no_uso), 6) FROM `vanguardamartech_refined`.`rfn_operacao__workflow_mapa_resumo`) = (SELECT 1.0), 0, 1) AS INT64) AS linhas_falha
  UNION ALL
  SELECT 'rfn_operacao__workflow_mapa_resumo.herdavel_concorda', 'Refined', 'rfn_operacao__workflow_mapa_resumo', 'iClips', 'VALIDADE',
         "is_confianca_herdavel e exatamente confianca ALTA ou CANONICA", 'BLOQUEANTE', 1.00,
         CAST(COUNT(*) AS INT64), CAST(COUNTIF(is_confianca_herdavel <> (confianca IN ('ALTA', 'CANÔNICA'))) AS INT64) FROM `vanguardamartech_refined`.`rfn_operacao__workflow_mapa_resumo`
  UNION ALL
  SELECT 'rfn_operacao__linear_estrutura_resumo.id_unico', 'Refined', 'rfn_operacao__linear_estrutura_resumo', 'Linear', 'UNICIDADE',
         "id_linear_estrutura e unico e nunca nulo", 'BLOQUEANTE', 1.00,
         CAST(COUNT(*) AS INT64), CAST(COUNT(*) - COUNT(DISTINCT id_linear_estrutura) + COUNTIF(id_linear_estrutura IS NULL) AS INT64) FROM `vanguardamartech_refined`.`rfn_operacao__linear_estrutura_resumo`
  UNION ALL
  SELECT 'rfn_operacao__linear_estrutura_resumo.itens_reproduzem_as_tres_trusted', 'Refined', 'rfn_operacao__linear_estrutura_resumo', 'Linear', 'INTEGRIDADE',
         "equipes + rotulos + usuarios da Refined reproduzem as tres Trusted", 'BLOQUEANTE', 1.00,
         CAST(1 AS INT64), CAST(IF((SELECT SUM(qtd_itens) FROM `vanguardamartech_refined`.`rfn_operacao__linear_estrutura_resumo`) = (SELECT (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_linear__equipe`) + (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_linear__rotulo`) + (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_linear__usuario`)), 0, 1) AS INT64) AS linhas_falha
  UNION ALL
  SELECT 'rfn_operacao__linear_estrutura_resumo.aplicacoes_de_rotulo_reproduzem_a_issue', 'Refined', 'rfn_operacao__linear_estrutura_resumo', 'Linear', 'INTEGRIDADE',
         "as aplicacoes de rotulo reproduzem a soma de qtd_rotulos das issues", 'BLOQUEANTE', 1.00,
         CAST(1 AS INT64), CAST(IF((SELECT SUM(qtd_aplicacoes_em_issues) FROM `vanguardamartech_refined`.`rfn_operacao__linear_estrutura_resumo`) = (SELECT SUM(qtd_rotulos) FROM `vanguardamartech_trusted`.`trs_linear__issue`), 0, 1) AS INT64) AS linhas_falha
  UNION ALL
  SELECT 'rfn_operacao__linear_estrutura_resumo.issues_criadas_reproduzem_o_usuario', 'Refined', 'rfn_operacao__linear_estrutura_resumo', 'Linear', 'INTEGRIDADE',
         "a soma de issues criadas reproduz a Trusted de usuario", 'BLOQUEANTE', 1.00,
         CAST(1 AS INT64), CAST(IF((SELECT SUM(qtd_issues_criadas) FROM `vanguardamartech_refined`.`rfn_operacao__linear_estrutura_resumo`) = (SELECT SUM(qtd_issues_criadas) FROM `vanguardamartech_trusted`.`trs_linear__usuario`), 0, 1) AS INT64) AS linhas_falha
  UNION ALL
  SELECT 'rfn_operacao__linear_estrutura_resumo.ids_unicos_dentro_do_grupo', 'Refined', 'rfn_operacao__linear_estrutura_resumo', 'Linear', 'UNICIDADE',
         "dentro de cada grupo nao ha id repetido (itens = ids distintos)", 'BLOQUEANTE', 1.00,
         CAST(COUNT(*) AS INT64), CAST(COUNTIF(qtd_ids_distintos <> qtd_itens) AS INT64) FROM `vanguardamartech_refined`.`rfn_operacao__linear_estrutura_resumo`
  UNION ALL
  SELECT 'rfn_operacao__linear_estrutura_resumo.aplicacao_so_em_rotulo', 'Refined', 'rfn_operacao__linear_estrutura_resumo', 'Linear', 'VALIDADE',
         "qtd_aplicacoes_em_issues so existe na entidade ROTULO (nas outras e NULL, nao zero)", 'BLOQUEANTE', 1.00,
         CAST(COUNT(*) AS INT64), CAST(COUNTIF(entidade <> 'ROTULO' AND qtd_aplicacoes_em_issues IS NOT NULL) AS INT64) FROM `vanguardamartech_refined`.`rfn_operacao__linear_estrutura_resumo`
  UNION ALL
  SELECT 'rfn_rh__candidato_mensal.id_unico', 'Refined', 'rfn_rh__candidato_mensal', 'Quickin', 'UNICIDADE',
         "id_candidato_mensal e unico e nunca nulo", 'BLOQUEANTE', 1.00,
         CAST(COUNT(*) AS INT64), CAST(COUNT(*) - COUNT(DISTINCT id_candidato_mensal) + COUNTIF(id_candidato_mensal IS NULL) AS INT64) FROM `vanguardamartech_refined`.`rfn_rh__candidato_mensal`
  UNION ALL
  SELECT 'rfn_rh__candidato_mensal.candidatos_reproduzem_a_trusted', 'Refined', 'rfn_rh__candidato_mensal', 'Quickin', 'INTEGRIDADE',
         "a soma de candidatos da Refined e o total da Trusted", 'BLOQUEANTE', 1.00,
         CAST(1 AS INT64), CAST(IF((SELECT SUM(qtd_candidatos) FROM `vanguardamartech_refined`.`rfn_rh__candidato_mensal`) = (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_quickin__candidato`), 0, 1) AS INT64) AS linhas_falha
  UNION ALL
  SELECT 'rfn_rh__candidato_mensal.email_repetido_reproduz', 'Refined', 'rfn_rh__candidato_mensal', 'Quickin', 'INTEGRIDADE',
         "os candidatos com e-mail repetido reproduzem a Trusted", 'BLOQUEANTE', 1.00,
         CAST(1 AS INT64), CAST(IF((SELECT SUM(qtd_email_repetido) FROM `vanguardamartech_refined`.`rfn_rh__candidato_mensal`) = (SELECT COUNTIF(flag_email_repetido) FROM `vanguardamartech_trusted`.`trs_quickin__candidato`), 0, 1) AS INT64) AS linhas_falha
  UNION ALL
  SELECT 'rfn_rh__candidato_mensal.consentimento_conhecido', 'Refined', 'rfn_rh__candidato_mensal', 'Quickin', 'VALIDADE',
         "o status de consentimento esta entre needs, consented, declined, expired ou (sem registro)", 'ALERTA', 1.00,
         CAST(IFNULL(SUM(qtd_candidatos),0) AS INT64), CAST(IFNULL(SUM(IF(consentimento_status IN ('needs','consented','declined','expired','(sem registro)'), 0, qtd_candidatos)),0) AS INT64) FROM `vanguardamartech_refined`.`rfn_rh__candidato_mensal`
  UNION ALL
  SELECT 'rfn_rh__quickin_dominio_resumo.id_unico', 'Refined', 'rfn_rh__quickin_dominio_resumo', 'Quickin', 'UNICIDADE',
         "id_dominio e unico e nunca nulo", 'BLOQUEANTE', 1.00,
         CAST(COUNT(*) AS INT64), CAST(COUNT(*) - COUNT(DISTINCT id_dominio) + COUNTIF(id_dominio IS NULL) AS INT64) FROM `vanguardamartech_refined`.`rfn_rh__quickin_dominio_resumo`
  UNION ALL
  SELECT 'rfn_rh__quickin_dominio_resumo.itens_reproduzem_a_trusted', 'Refined', 'rfn_rh__quickin_dominio_resumo', 'Quickin', 'INTEGRIDADE',
         "a soma de itens da Refined e o total da Trusted", 'BLOQUEANTE', 1.00,
         CAST(1 AS INT64), CAST(IF((SELECT SUM(qtd_itens) FROM `vanguardamartech_refined`.`rfn_rh__quickin_dominio_resumo`) = (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_quickin__dominio`), 0, 1) AS INT64) AS linhas_falha
  UNION ALL
  SELECT 'rfn_rh__quickin_dominio_resumo.email_so_no_avaliador', 'Refined', 'rfn_rh__quickin_dominio_resumo', 'Quickin', 'VALIDADE',
         "e-mail so existe no dominio AVALIADOR (guarda do dado pessoal L4)", 'BLOQUEANTE', 1.00,
         CAST(COUNT(*) AS INT64), CAST(COUNTIF(id_dominio <> 'AVALIADOR' AND qtd_com_email > 0) AS INT64) FROM `vanguardamartech_refined`.`rfn_rh__quickin_dominio_resumo`
  UNION ALL
  SELECT 'rfn_rh__funil_mensal.id_unico', 'Refined', 'rfn_rh__funil_mensal', 'Quickin', 'UNICIDADE',
         "id_funil_mensal e unico e nunca nulo", 'BLOQUEANTE', 1.00,
         CAST(COUNT(*) AS INT64), CAST(COUNT(*) - COUNT(DISTINCT id_funil_mensal) + COUNTIF(id_funil_mensal IS NULL) AS INT64) FROM `vanguardamartech_refined`.`rfn_rh__funil_mensal`
  UNION ALL
  SELECT 'rfn_rh__funil_mensal.eventos_reproduzem_a_trusted', 'Refined', 'rfn_rh__funil_mensal', 'Quickin', 'INTEGRIDADE',
         "a soma de eventos da Refined e o total da Trusted", 'BLOQUEANTE', 1.00,
         CAST(1 AS INT64), CAST(IF((SELECT SUM(qtd_eventos) FROM `vanguardamartech_refined`.`rfn_rh__funil_mensal`) = (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_quickin__funil_evento`), 0, 1) AS INT64) AS linhas_falha
  UNION ALL
  SELECT 'rfn_rh__funil_mensal.sentido_determinado', 'Refined', 'rfn_rh__funil_mensal', 'Quickin', 'VALIDADE',
         "toda transicao tem as duas etapas no dominio (nenhuma INDETERMINADO); hoje 149 de 149", 'ALERTA', 1.00,
         CAST(IFNULL(SUM(qtd_eventos),0) AS INT64), CAST(IFNULL(SUM(IF(sentido = 'INDETERMINADO', qtd_eventos, 0)),0) AS INT64) FROM `vanguardamartech_refined`.`rfn_rh__funil_mensal`
  UNION ALL
  SELECT 'rfn_rh__funil_mensal.aplicacoes_nao_excedem_eventos', 'Refined', 'rfn_rh__funil_mensal', 'Quickin', 'VALIDADE',
         "aplicacoes distintas nunca passam dos eventos da linha", 'BLOQUEANTE', 1.00,
         CAST(COUNT(*) AS INT64), CAST(COUNTIF(qtd_aplicacoes_distintas > qtd_eventos) AS INT64) FROM `vanguardamartech_refined`.`rfn_rh__funil_mensal`
  UNION ALL
  SELECT 'rfn_rh__requisicao_mensal.id_unico', 'Refined', 'rfn_rh__requisicao_mensal', 'Quickin', 'UNICIDADE',
         "id_requisicao_mensal e unico e nunca nulo", 'BLOQUEANTE', 1.00,
         CAST(COUNT(*) AS INT64), CAST(COUNT(*) - COUNT(DISTINCT id_requisicao_mensal) + COUNTIF(id_requisicao_mensal IS NULL) AS INT64) FROM `vanguardamartech_refined`.`rfn_rh__requisicao_mensal`
  UNION ALL
  SELECT 'rfn_rh__requisicao_mensal.requisicoes_reproduzem_a_trusted', 'Refined', 'rfn_rh__requisicao_mensal', 'Quickin', 'INTEGRIDADE',
         "a soma de requisicoes da Refined e o total da Trusted", 'BLOQUEANTE', 1.00,
         CAST(1 AS INT64), CAST(IF((SELECT SUM(qtd_requisicoes) FROM `vanguardamartech_refined`.`rfn_rh__requisicao_mensal`) = (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_quickin__requisicao`), 0, 1) AS INT64) AS linhas_falha
  UNION ALL
  SELECT 'rfn_rh__requisicao_mensal.posicoes_reproduzem_a_trusted', 'Refined', 'rfn_rh__requisicao_mensal', 'Quickin', 'INTEGRIDADE',
         "a soma de posicoes reproduz a Trusted", 'BLOQUEANTE', 1.00,
         CAST(1 AS INT64), CAST(IF((SELECT SUM(qtd_posicoes) FROM `vanguardamartech_refined`.`rfn_rh__requisicao_mensal`) = (SELECT SUM(qtd_posicoes) FROM `vanguardamartech_trusted`.`trs_quickin__requisicao`), 0, 1) AS INT64) AS linhas_falha
  UNION ALL
  SELECT 'rfn_rh__requisicao_mensal.remuneracao_dentro_do_total', 'Refined', 'rfn_rh__requisicao_mensal', 'Quickin', 'VALIDADE',
         "requisicoes com remuneracao nunca excedem as requisicoes da linha", 'BLOQUEANTE', 1.00,
         CAST(COUNT(*) AS INT64), CAST(COUNTIF(qtd_com_remuneracao > qtd_requisicoes) AS INT64) FROM `vanguardamartech_refined`.`rfn_rh__requisicao_mensal`
  UNION ALL
  SELECT 'rfn_rh__qulture_dominio_resumo.id_unico', 'Refined', 'rfn_rh__qulture_dominio_resumo', 'Qulture', 'UNICIDADE',
         "id_dominio e unico e nunca nulo", 'BLOQUEANTE', 1.00,
         CAST(COUNT(*) AS INT64), CAST(COUNT(*) - COUNT(DISTINCT id_dominio) + COUNTIF(id_dominio IS NULL) AS INT64) FROM `vanguardamartech_refined`.`rfn_rh__qulture_dominio_resumo`
  UNION ALL
  SELECT 'rfn_rh__qulture_dominio_resumo.itens_reproduzem_a_trusted', 'Refined', 'rfn_rh__qulture_dominio_resumo', 'Qulture', 'INTEGRIDADE',
         "a soma de itens da Refined e o total da Trusted", 'BLOQUEANTE', 1.00,
         CAST(1 AS INT64), CAST(IF((SELECT SUM(qtd_itens) FROM `vanguardamartech_refined`.`rfn_rh__qulture_dominio_resumo`) = (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_qulture__dominio`), 0, 1) AS INT64) AS linhas_falha
  UNION ALL
  SELECT 'rfn_rh__qulture_dominio_resumo.ids_unicos_dentro_do_dominio', 'Refined', 'rfn_rh__qulture_dominio_resumo', 'Qulture', 'UNICIDADE',
         "dentro de cada dominio nao ha id repetido (a deduplicacao de versoes do bronze nao quebrou)", 'BLOQUEANTE', 1.00,
         CAST(COUNT(*) AS INT64), CAST(COUNTIF(qtd_ids_distintos <> qtd_itens) AS INT64) FROM `vanguardamartech_refined`.`rfn_rh__qulture_dominio_resumo`
  UNION ALL
  SELECT 'rfn_rh__interacao_resumo.id_unico', 'Refined', 'rfn_rh__interacao_resumo', 'Qulture', 'UNICIDADE',
         "id_interacao_resumo e unico e nunca nulo", 'BLOQUEANTE', 1.00,
         CAST(COUNT(*) AS INT64), CAST(COUNT(*) - COUNT(DISTINCT id_interacao_resumo) + COUNTIF(id_interacao_resumo IS NULL) AS INT64) FROM `vanguardamartech_refined`.`rfn_rh__interacao_resumo`
  UNION ALL
  SELECT 'rfn_rh__interacao_resumo.linhas_reproduzem_a_trusted', 'Refined', 'rfn_rh__interacao_resumo', 'Qulture', 'INTEGRIDADE',
         "a soma de linhas da Refined e o total da Trusted", 'BLOQUEANTE', 1.00,
         CAST(1 AS INT64), CAST(IF((SELECT SUM(qtd_linhas) FROM `vanguardamartech_refined`.`rfn_rh__interacao_resumo`) = (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_qulture__interacao`), 0, 1) AS INT64) AS linhas_falha
  UNION ALL
  SELECT 'rfn_rh__interacao_resumo.concluidas_so_em_tarefa', 'Refined', 'rfn_rh__interacao_resumo', 'Qulture', 'VALIDADE',
         "qtd_concluidas so existe na origem TAREFA_REUNIAO (nas outras e NULL, nao zero)", 'BLOQUEANTE', 1.00,
         CAST(COUNT(*) AS INT64), CAST(COUNTIF(origem <> 'TAREFA_REUNIAO' AND qtd_concluidas IS NOT NULL) AS INT64) FROM `vanguardamartech_refined`.`rfn_rh__interacao_resumo`
  UNION ALL
  SELECT 'rfn_rh__interacao_resumo.eventos_nao_excedem_linhas', 'Refined', 'rfn_rh__interacao_resumo', 'Qulture', 'VALIDADE',
         "eventos distintos nunca passam das linhas do grupo", 'BLOQUEANTE', 1.00,
         CAST(COUNT(*) AS INT64), CAST(COUNTIF(qtd_eventos_distintos > qtd_linhas) AS INT64) FROM `vanguardamartech_refined`.`rfn_rh__interacao_resumo`
  UNION ALL
  SELECT 'rfn_rh__objetivo_resumo.id_unico', 'Refined', 'rfn_rh__objetivo_resumo', 'Qulture', 'UNICIDADE',
         "id_objetivo_resumo e unico e nunca nulo", 'BLOQUEANTE', 1.00,
         CAST(COUNT(*) AS INT64), CAST(COUNT(*) - COUNT(DISTINCT id_objetivo_resumo) + COUNTIF(id_objetivo_resumo IS NULL) AS INT64) FROM `vanguardamartech_refined`.`rfn_rh__objetivo_resumo`
  UNION ALL
  SELECT 'rfn_rh__objetivo_resumo.objetivos_reproduzem_a_trusted', 'Refined', 'rfn_rh__objetivo_resumo', 'Qulture', 'INTEGRIDADE',
         "a soma de objetivos da Refined e o total da Trusted", 'BLOQUEANTE', 1.00,
         CAST(1 AS INT64), CAST(IF((SELECT SUM(qtd_objetivos) FROM `vanguardamartech_refined`.`rfn_rh__objetivo_resumo`) = (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_qulture__objetivo`), 0, 1) AS INT64) AS linhas_falha
  UNION ALL
  SELECT 'rfn_rh__objetivo_resumo.score_reproduz_a_trusted', 'Refined', 'rfn_rh__objetivo_resumo', 'Qulture', 'INTEGRIDADE',
         "a soma de score reproduz a Trusted dentro de 0,01", 'BLOQUEANTE', 1.00,
         CAST(1 AS INT64), CAST(IF(ABS(IFNULL((SELECT SUM(soma_score_pct) FROM `vanguardamartech_refined`.`rfn_rh__objetivo_resumo`),0) - IFNULL((SELECT SUM(score_pct) FROM `vanguardamartech_trusted`.`trs_qulture__objetivo`),0)) <= 0.01, 0, 1) AS INT64) AS linhas_falha
  UNION ALL
  SELECT 'rfn_rh__objetivo_resumo.pai_catalogado', 'Refined', 'rfn_rh__objetivo_resumo', 'Qulture', 'INTEGRIDADE',
         "objetivo cujo pai existe na propria tabela; hoje 28 de 28 (zero orfao)", 'ALERTA', 0.95,
         CAST(IFNULL(SUM(qtd_objetivos),0) AS INT64), CAST(IFNULL(SUM(qtd_pai_nao_catalogado),0) AS INT64) FROM `vanguardamartech_refined`.`rfn_rh__objetivo_resumo`
  UNION ALL
  SELECT 'rfn_rh__organograma_resumo.id_unico', 'Refined', 'rfn_rh__organograma_resumo', 'Qulture', 'UNICIDADE',
         "id_organograma_resumo e unico e nunca nulo", 'BLOQUEANTE', 1.00,
         CAST(COUNT(*) AS INT64), CAST(COUNT(*) - COUNT(DISTINCT id_organograma_resumo) + COUNTIF(id_organograma_resumo IS NULL) AS INT64) FROM `vanguardamartech_refined`.`rfn_rh__organograma_resumo`
  UNION ALL
  SELECT 'rfn_rh__organograma_resumo.setores_reproduzem_a_trusted', 'Refined', 'rfn_rh__organograma_resumo', 'Qulture', 'INTEGRIDADE',
         "a soma de setores da Refined e os setores do organograma na Trusted", 'BLOQUEANTE', 1.00,
         CAST(1 AS INT64), CAST(IF((SELECT SUM(qtd_setores) FROM `vanguardamartech_refined`.`rfn_rh__organograma_resumo`) = (SELECT COUNTIF(origem = 'ORGANOGRAMA') FROM `vanguardamartech_trusted`.`trs_qulture__organograma`), 0, 1) AS INT64) AS linhas_falha
  UNION ALL
  SELECT 'rfn_rh__organograma_resumo.cargos_reproduzem_a_trusted', 'Refined', 'rfn_rh__organograma_resumo', 'Qulture', 'INTEGRIDADE',
         "a soma de cargos mapeados reproduz o mapa cargo-setor da Trusted", 'BLOQUEANTE', 1.00,
         CAST(1 AS INT64), CAST(IF((SELECT IFNULL(SUM(qtd_cargos_mapeados),0) FROM `vanguardamartech_refined`.`rfn_rh__organograma_resumo`) = (SELECT COUNTIF(origem = 'CARGO_SETOR') FROM `vanguardamartech_trusted`.`trs_qulture__organograma`), 0, 1) AS INT64) AS linhas_falha
  UNION ALL
  SELECT 'rfn_rh__organograma_resumo.cargo_no_organograma', 'Refined', 'rfn_rh__organograma_resumo', 'Qulture', 'INTEGRIDADE',
         "cargo cujo setor existe no organograma; hoje 37 de 37", 'ALERTA', 0.95,
         CAST(IFNULL(SUM(qtd_cargos_mapeados),0) AS INT64), CAST(IFNULL(SUM(qtd_cargos_fora_do_organograma),0) AS INT64) FROM `vanguardamartech_refined`.`rfn_rh__organograma_resumo`
  UNION ALL
  SELECT 'rfn_operacao__orcamento_item_resumo.id_unico', 'Refined', 'rfn_operacao__orcamento_item_resumo', 'VJOB', 'UNICIDADE',
         "id_orcamento_resumo e unico e nunca nulo", 'BLOQUEANTE', 1.00,
         CAST(COUNT(*) AS INT64), CAST(COUNT(*) - COUNT(DISTINCT id_orcamento_resumo) + COUNTIF(id_orcamento_resumo IS NULL) AS INT64) FROM `vanguardamartech_refined`.`rfn_operacao__orcamento_item_resumo`
  UNION ALL
  SELECT 'rfn_operacao__orcamento_item_resumo.itens_reproduzem_a_trusted', 'Refined', 'rfn_operacao__orcamento_item_resumo', 'VJOB', 'INTEGRIDADE',
         "a soma de itens da Refined e o total da Trusted", 'BLOQUEANTE', 1.00,
         CAST(1 AS INT64), CAST(IF((SELECT SUM(qtd_itens) FROM `vanguardamartech_refined`.`rfn_operacao__orcamento_item_resumo`) = (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_vjob__orcamento_item`), 0, 1) AS INT64) AS linhas_falha
  UNION ALL
  SELECT 'rfn_operacao__orcamento_item_resumo.valor_reproduz_a_trusted', 'Refined', 'rfn_operacao__orcamento_item_resumo', 'VJOB', 'INTEGRIDADE',
         "a soma dos precos reproduz a Trusted dentro de R$ 0,01", 'BLOQUEANTE', 1.00,
         CAST(1 AS INT64), CAST(IF(ABS(IFNULL((SELECT SUM(soma_valor_unitario) FROM `vanguardamartech_refined`.`rfn_operacao__orcamento_item_resumo`),0) - IFNULL((SELECT SUM(valor_unitario) FROM `vanguardamartech_trusted`.`trs_vjob__orcamento_item`),0)) <= 0.01, 0, 1) AS INT64) AS linhas_falha
  UNION ALL
  SELECT 'rfn_operacao__orcamento_item_resumo.residual_dentro_dos_itens', 'Refined', 'rfn_operacao__orcamento_item_resumo', 'VJOB', 'VALIDADE',
         "itens com calculo residual nunca excedem os itens do ano", 'BLOQUEANTE', 1.00,
         CAST(COUNT(*) AS INT64), CAST(COUNTIF(qtd_com_calculo_residual > qtd_itens) AS INT64) FROM `vanguardamartech_refined`.`rfn_operacao__orcamento_item_resumo`
),
carga AS (
  SELECT 'rfn_operacao__colaborador_iclips_resumo' AS t, MAX(DATE(_extraido_at)) AS d FROM `vanguardamartech_refined`.`rfn_operacao__colaborador_iclips_resumo`
  UNION ALL SELECT 'rfn_operacao__job_horas_mensal' AS t, MAX(DATE(_extraido_at)) AS d FROM `vanguardamartech_refined`.`rfn_operacao__job_horas_mensal`
  UNION ALL SELECT 'rfn_operacao__workflow_mapa_resumo' AS t, MAX(DATE(_extraido_at)) AS d FROM `vanguardamartech_refined`.`rfn_operacao__workflow_mapa_resumo`
  UNION ALL SELECT 'rfn_rh__candidato_mensal' AS t, MAX(DATE(_extraido_at)) AS d FROM `vanguardamartech_refined`.`rfn_rh__candidato_mensal`
  UNION ALL SELECT 'rfn_rh__quickin_dominio_resumo' AS t, MAX(DATE(_extraido_at)) AS d FROM `vanguardamartech_refined`.`rfn_rh__quickin_dominio_resumo`
  UNION ALL SELECT 'rfn_rh__funil_mensal' AS t, MAX(DATE(_extraido_at)) AS d FROM `vanguardamartech_refined`.`rfn_rh__funil_mensal`
  UNION ALL SELECT 'rfn_rh__requisicao_mensal' AS t, MAX(DATE(_extraido_at)) AS d FROM `vanguardamartech_refined`.`rfn_rh__requisicao_mensal`
  UNION ALL SELECT 'rfn_rh__qulture_dominio_resumo' AS t, MAX(DATE(_extraido_at)) AS d FROM `vanguardamartech_refined`.`rfn_rh__qulture_dominio_resumo`
  UNION ALL SELECT 'rfn_rh__interacao_resumo' AS t, MAX(DATE(_extraido_at)) AS d FROM `vanguardamartech_refined`.`rfn_rh__interacao_resumo`
  UNION ALL SELECT 'rfn_rh__objetivo_resumo' AS t, MAX(DATE(_extraido_at)) AS d FROM `vanguardamartech_refined`.`rfn_rh__objetivo_resumo`
  UNION ALL SELECT 'rfn_rh__organograma_resumo' AS t, MAX(DATE(_extraido_at)) AS d FROM `vanguardamartech_refined`.`rfn_rh__organograma_resumo`
),
r_frescor AS (
  SELECT 'rh_operacao_dimensoes.carga_do_mesmo_dia' AS id_regra, 'Refined' AS camada,
         '(as 11 Refined do supabase-x0tz)' AS tabela, 'supabase-x0tz' AS sistema, 'VALIDADE' AS dimensao,
         "as 11 Refined do supabase-x0tz foram escritas na mesma passada" AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNTIF(d <> (SELECT MAX(d) FROM carga)) AS linhas_falha
  FROM carga
),
todas AS (
  SELECT * FROM r_regras
  UNION ALL SELECT * FROM r_frescor
),
avaliado AS (
  SELECT
    t.*,
    (t.linhas_avaliadas - t.linhas_falha)                       AS linhas_conformes,
    SAFE_DIVIDE(t.linhas_avaliadas - t.linhas_falha, NULLIF(t.linhas_avaliadas, 0)) AS taxa_conformidade,
    -- Regra sem linha para avaliar NAO passa: sai NULL, nunca TRUE.
    IF(t.linhas_avaliadas = 0, NULL,
       SAFE_DIVIDE(t.linhas_avaliadas - t.linhas_falha, t.linhas_avaliadas) >= t.limiar) AS is_conforme,
    (t.linhas_avaliadas = 0)                                    AS flag_sem_linha_para_avaliar
  FROM todas t
)
SELECT
  a.*,
  CASE
    WHEN a.flag_sem_linha_para_avaliar          THEN 'SEM_DADO'
    WHEN a.is_conforme                          THEN 'CONFORME'
    WHEN a.severidade = 'BLOQUEANTE'            THEN 'FALHA_BLOQUEANTE'
    ELSE                                             'FALHA_ALERTA'
  END                                           AS resultado,
  'RH e Operacao - dimensoes'                   AS familia,
  CURRENT_TIMESTAMP()                           AS _extraido_at,
  'multiplas'                                   AS _fonte,
  'America/Sao_Paulo'                           AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(a)))                AS _payload_hash
FROM avaliado a
