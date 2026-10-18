-- query-xas5 | rfn_qualidade__regra_marketing_rd_streams | Refined / qualidade | L2 INTERNAL
-- Grao: uma regra. 43 regras (16 unicidades, 12 identidades Trusted-Refined, 5 NULL, 4 mes=dia 1, 5 linhas de base ALERTA, 1 frescor).
-- Gatilho: evento nas 7 Refined de streams RD (query-TRSi, lFEK, UpTQ, vOxN, e19u, QYE9, 4Yi5) com regra "all". Alerta de falha ligado.
-- Validacao 18/10/2026: Raw de 5 contas (5KKM, POZB, irou, iJK3, pDLk); regras das 7 Refined e o frescor OK; unicidades das Trusted e 2 linhas de base NAO foram rodadas por grupo (ver descricao). Nada materializado ainda.
-- Identidades em CROSS JOIN de duas agregacoes: a forma IF((SELECT..)<>(SELECT..)) deu "Correlated subqueries" no BigQuery.
-- O codigo implantado e o abaixo sem estas linhas de comentario.
WITH tF AS (SELECT * FROM `vanguardamartech_trusted`.`trs_rd_station__funil_contato`),
tOP AS (SELECT * FROM `vanguardamartech_trusted`.`trs_rd_station__oportunidade_evento`),
tES AS (SELECT * FROM `vanguardamartech_trusted`.`trs_rd_station__email_desempenho`),
tWS AS (SELECT * FROM `vanguardamartech_trusted`.`trs_rd_station__automacao_email_desempenho`),
tCA AS (SELECT * FROM `vanguardamartech_trusted`.`trs_rd_station__ativo_conversao_dia`),
tAF AS (SELECT * FROM `vanguardamartech_trusted`.`trs_rd_station__funil_dia`),
tEM AS (SELECT * FROM `vanguardamartech_trusted`.`trs_rd_station__email`),
tCAP AS (SELECT * FROM `vanguardamartech_trusted`.`trs_rd_station__captura`),
tSG AS (SELECT * FROM `vanguardamartech_trusted`.`trs_rd_station__segmentacao`),
rF AS (SELECT * FROM `vanguardamartech_refined`.`rfn_marketing__funil_contato_estagio`),
rOP AS (SELECT * FROM `vanguardamartech_refined`.`rfn_marketing__oportunidade_mensal`),
rES AS (SELECT * FROM `vanguardamartech_refined`.`rfn_marketing__email_desempenho_mensal`),
rWS AS (SELECT * FROM `vanguardamartech_refined`.`rfn_marketing__automacao_email_resumo`),
rCA AS (SELECT * FROM `vanguardamartech_refined`.`rfn_marketing__ativo_conversao_mensal`),
rAF AS (SELECT * FROM `vanguardamartech_refined`.`rfn_marketing__funil_analytics_mensal`),
rEM AS (SELECT * FROM `vanguardamartech_refined`.`rfn_marketing__estrutura_resumo`),
r AS (
  SELECT 'trs_rd_station__funil_contato.id_contato_unico' AS id_regra, 'Trusted' AS camada, 'trs_rd_station__funil_contato' AS tabela, 'RD Station' AS sistema, 'UNICIDADE' AS dimensao,
         'id_contato e unico e nunca nulo' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_contato) + COUNTIF(id_contato IS NULL) AS linhas_falha FROM tF
  UNION ALL
  SELECT 'trs_rd_station__oportunidade_evento.id_oportunidade_evento_unico' AS id_regra, 'Trusted' AS camada, 'trs_rd_station__oportunidade_evento' AS tabela, 'RD Station' AS sistema, 'UNICIDADE' AS dimensao,
         'id_oportunidade_evento e unico e nunca nulo' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_oportunidade_evento) + COUNTIF(id_oportunidade_evento IS NULL) AS linhas_falha FROM tOP
  UNION ALL
  SELECT 'trs_rd_station__email_desempenho.id_email_desempenho_unico' AS id_regra, 'Trusted' AS camada, 'trs_rd_station__email_desempenho' AS tabela, 'RD Station' AS sistema, 'UNICIDADE' AS dimensao,
         'id_email_desempenho e unico e nunca nulo' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_email_desempenho) + COUNTIF(id_email_desempenho IS NULL) AS linhas_falha FROM tES
  UNION ALL
  SELECT 'trs_rd_station__automacao_email_desempenho.id_automacao_email_unico' AS id_regra, 'Trusted' AS camada, 'trs_rd_station__automacao_email_desempenho' AS tabela, 'RD Station' AS sistema, 'UNICIDADE' AS dimensao,
         'id_automacao_email e unico e nunca nulo' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_automacao_email) + COUNTIF(id_automacao_email IS NULL) AS linhas_falha FROM tWS
  UNION ALL
  SELECT 'trs_rd_station__ativo_conversao_dia.id_ativo_dia_unico' AS id_regra, 'Trusted' AS camada, 'trs_rd_station__ativo_conversao_dia' AS tabela, 'RD Station' AS sistema, 'UNICIDADE' AS dimensao,
         'id_ativo_dia e unico e nunca nulo' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_ativo_dia) + COUNTIF(id_ativo_dia IS NULL) AS linhas_falha FROM tCA
  UNION ALL
  SELECT 'trs_rd_station__funil_dia.id_funil_dia_unico' AS id_regra, 'Trusted' AS camada, 'trs_rd_station__funil_dia' AS tabela, 'RD Station' AS sistema, 'UNICIDADE' AS dimensao,
         'id_funil_dia e unico e nunca nulo' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_funil_dia) + COUNTIF(id_funil_dia IS NULL) AS linhas_falha FROM tAF
  UNION ALL
  SELECT 'trs_rd_station__email.id_email_unico' AS id_regra, 'Trusted' AS camada, 'trs_rd_station__email' AS tabela, 'RD Station' AS sistema, 'UNICIDADE' AS dimensao,
         'id_email e unico e nunca nulo' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_email) + COUNTIF(id_email IS NULL) AS linhas_falha FROM tEM
  UNION ALL
  SELECT 'trs_rd_station__captura.id_ativo_captura_unico' AS id_regra, 'Trusted' AS camada, 'trs_rd_station__captura' AS tabela, 'RD Station' AS sistema, 'UNICIDADE' AS dimensao,
         'id_ativo_captura e unico e nunca nulo' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_ativo_captura) + COUNTIF(id_ativo_captura IS NULL) AS linhas_falha FROM tCAP
  UNION ALL
  SELECT 'trs_rd_station__segmentacao.id_segmentacao_unico' AS id_regra, 'Trusted' AS camada, 'trs_rd_station__segmentacao' AS tabela, 'RD Station' AS sistema, 'UNICIDADE' AS dimensao,
         'id_segmentacao e unico e nunca nulo' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_segmentacao) + COUNTIF(id_segmentacao IS NULL) AS linhas_falha FROM tSG
  UNION ALL
  SELECT 'rfn_marketing__funil_contato_estagio.id_funil_estagio_unico' AS id_regra, 'Refined' AS camada, 'rfn_marketing__funil_contato_estagio' AS tabela, 'RD Station' AS sistema, 'UNICIDADE' AS dimensao,
         'id_funil_estagio e unico e nunca nulo' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_funil_estagio) + COUNTIF(id_funil_estagio IS NULL) AS linhas_falha FROM rF
  UNION ALL
  SELECT 'rfn_marketing__oportunidade_mensal.id_oportunidade_mensal_unico' AS id_regra, 'Refined' AS camada, 'rfn_marketing__oportunidade_mensal' AS tabela, 'RD Station' AS sistema, 'UNICIDADE' AS dimensao,
         'id_oportunidade_mensal e unico e nunca nulo' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_oportunidade_mensal) + COUNTIF(id_oportunidade_mensal IS NULL) AS linhas_falha FROM rOP
  UNION ALL
  SELECT 'rfn_marketing__email_desempenho_mensal.id_email_mensal_unico' AS id_regra, 'Refined' AS camada, 'rfn_marketing__email_desempenho_mensal' AS tabela, 'RD Station' AS sistema, 'UNICIDADE' AS dimensao,
         'id_email_mensal e unico e nunca nulo' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_email_mensal) + COUNTIF(id_email_mensal IS NULL) AS linhas_falha FROM rES
  UNION ALL
  SELECT 'rfn_marketing__automacao_email_resumo.id_automacao_resumo_unico' AS id_regra, 'Refined' AS camada, 'rfn_marketing__automacao_email_resumo' AS tabela, 'RD Station' AS sistema, 'UNICIDADE' AS dimensao,
         'id_automacao_resumo e unico e nunca nulo' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_automacao_resumo) + COUNTIF(id_automacao_resumo IS NULL) AS linhas_falha FROM rWS
  UNION ALL
  SELECT 'rfn_marketing__ativo_conversao_mensal.id_ativo_mensal_unico' AS id_regra, 'Refined' AS camada, 'rfn_marketing__ativo_conversao_mensal' AS tabela, 'RD Station' AS sistema, 'UNICIDADE' AS dimensao,
         'id_ativo_mensal e unico e nunca nulo' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_ativo_mensal) + COUNTIF(id_ativo_mensal IS NULL) AS linhas_falha FROM rCA
  UNION ALL
  SELECT 'rfn_marketing__funil_analytics_mensal.id_funil_mensal_unico' AS id_regra, 'Refined' AS camada, 'rfn_marketing__funil_analytics_mensal' AS tabela, 'RD Station' AS sistema, 'UNICIDADE' AS dimensao,
         'id_funil_mensal e unico e nunca nulo' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_funil_mensal) + COUNTIF(id_funil_mensal IS NULL) AS linhas_falha FROM rAF
  UNION ALL
  SELECT 'rfn_marketing__estrutura_resumo.id_estrutura_unico' AS id_regra, 'Refined' AS camada, 'rfn_marketing__estrutura_resumo' AS tabela, 'RD Station' AS sistema, 'UNICIDADE' AS dimensao,
         'id_estrutura e unico e nunca nulo' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_estrutura) + COUNTIF(id_estrutura IS NULL) AS linhas_falha FROM rEM
  UNION ALL
  SELECT 'rfn_marketing__funil_contato_estagio.contatos_reproduzem_a_trusted' AS id_regra, 'Refined' AS camada, 'rfn_marketing__funil_contato_estagio' AS tabela, 'RD Station' AS sistema, 'INTEGRIDADE' AS dimensao,
         'soma de qtd_contatos = contatos distintos (uuid) da Trusted de funil por contato' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         1 AS linhas_avaliadas, IF(x.v <> y.v,1,0) AS linhas_falha FROM (SELECT SUM(qtd_contatos) AS v FROM rF) x CROSS JOIN (SELECT COUNT(DISTINCT uuid_contato) AS v FROM tF) y
  UNION ALL
  SELECT 'rfn_marketing__oportunidade_mensal.eventos_reproduzem_a_trusted' AS id_regra, 'Refined' AS camada, 'rfn_marketing__oportunidade_mensal' AS tabela, 'RD Station' AS sistema, 'INTEGRIDADE' AS dimensao,
         'soma de qtd_eventos = eventos distintos (id) da Trusted de oportunidade' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         1 AS linhas_avaliadas, IF(x.v <> y.v,1,0) AS linhas_falha FROM (SELECT SUM(qtd_eventos) AS v FROM rOP) x CROSS JOIN (SELECT COUNT(DISTINCT id_evento_origem) AS v FROM tOP) y
  UNION ALL
  SELECT 'rfn_marketing__email_desempenho_mensal.envios_mais_duplicatas_reproduzem_a_trusted' AS id_regra, 'Refined' AS camada, 'rfn_marketing__email_desempenho_mensal' AS tabela, 'RD Station' AS sistema, 'INTEGRIDADE' AS dimensao,
         'envios + linhas duplicadas removidas = linhas da Trusted de desempenho de e-mail' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         1 AS linhas_avaliadas, IF(x.v <> y.v,1,0) AS linhas_falha FROM (SELECT SUM(qtd_envios)+SUM(qtd_linhas_duplicadas_removidas) AS v FROM rES) x CROSS JOIN (SELECT COUNT(*) AS v FROM tES) y
  UNION ALL
  SELECT 'rfn_marketing__email_desempenho_mensal.entregues_reproduzem_o_canonico' AS id_regra, 'Refined' AS camada, 'rfn_marketing__email_desempenho_mensal' AS tabela, 'RD Station' AS sistema, 'INTEGRIDADE' AS dimensao,
         'soma de entregues = soma de entregues da Trusted so das linhas canonicas (campanha + instante de envio)' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         1 AS linhas_avaliadas, IF(x.v <> y.v,1,0) AS linhas_falha FROM (SELECT SUM(qtd_entregues) AS v FROM rES) x CROSS JOIN (SELECT SUM(qtd_entregues) AS v FROM (SELECT * FROM tES QUALIFY ROW_NUMBER() OVER (PARTITION BY id_campanha_origem, enviado_em ORDER BY qtd_contatos DESC, _fonte) = 1)) y
  UNION ALL
  SELECT 'rfn_marketing__automacao_email_resumo.acoes_mais_duplicatas_reproduzem_a_trusted' AS id_regra, 'Refined' AS camada, 'rfn_marketing__automacao_email_resumo' AS tabela, 'RD Station' AS sistema, 'INTEGRIDADE' AS dimensao,
         'acoes + linhas duplicadas removidas = linhas da Trusted de e-mail das automacoes' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         1 AS linhas_avaliadas, IF(x.v <> y.v,1,0) AS linhas_falha FROM (SELECT SUM(qtd_acoes_email)+SUM(qtd_linhas_duplicadas_removidas) AS v FROM rWS) x CROSS JOIN (SELECT COUNT(*) AS v FROM tWS) y
  UNION ALL
  SELECT 'rfn_marketing__ativo_conversao_mensal.visitas_reproduzem_o_canonico' AS id_regra, 'Refined' AS camada, 'rfn_marketing__ativo_conversao_mensal' AS tabela, 'RD Station' AS sistema, 'INTEGRIDADE' AS dimensao,
         'soma de visitas = soma de visitas da Trusted so das linhas canonicas (ativo + dia)' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         1 AS linhas_avaliadas, IF(x.v <> y.v,1,0) AS linhas_falha FROM (SELECT SUM(qtd_visitas) AS v FROM rCA) x CROSS JOIN (SELECT SUM(qtd_visitas) AS v FROM (SELECT * FROM tCA QUALIFY ROW_NUMBER() OVER (PARTITION BY id_ativo_origem, data_referencia ORDER BY qtd_visitas DESC, qtd_conversoes DESC, _fonte) = 1)) y
  UNION ALL
  SELECT 'rfn_marketing__ativo_conversao_mensal.conversoes_reproduzem_o_canonico' AS id_regra, 'Refined' AS camada, 'rfn_marketing__ativo_conversao_mensal' AS tabela, 'RD Station' AS sistema, 'INTEGRIDADE' AS dimensao,
         'soma de conversoes = soma de conversoes da Trusted so das linhas canonicas (ativo + dia)' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         1 AS linhas_avaliadas, IF(x.v <> y.v,1,0) AS linhas_falha FROM (SELECT SUM(qtd_conversoes) AS v FROM rCA) x CROSS JOIN (SELECT SUM(qtd_conversoes) AS v FROM (SELECT * FROM tCA QUALIFY ROW_NUMBER() OVER (PARTITION BY id_ativo_origem, data_referencia ORDER BY qtd_visitas DESC, qtd_conversoes DESC, _fonte) = 1)) y
  UNION ALL
  SELECT 'rfn_marketing__funil_analytics_mensal.dias_mais_duplicatas_reproduzem_a_trusted' AS id_regra, 'Refined' AS camada, 'rfn_marketing__funil_analytics_mensal' AS tabela, 'RD Station' AS sistema, 'INTEGRIDADE' AS dimensao,
         'dias + retratos duplicados removidos = linhas da Trusted de funil por dia' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         1 AS linhas_avaliadas, IF(x.v <> y.v,1,0) AS linhas_falha FROM (SELECT SUM(qtd_dias)+SUM(qtd_retratos_duplicados_removidos) AS v FROM rAF) x CROSS JOIN (SELECT COUNT(*) AS v FROM tAF) y
  UNION ALL
  SELECT 'rfn_marketing__estrutura_resumo.emails_reproduzem_a_trusted' AS id_regra, 'Refined' AS camada, 'rfn_marketing__estrutura_resumo' AS tabela, 'RD Station' AS sistema, 'INTEGRIDADE' AS dimensao,
         'soma de qtd_emails = linhas da Trusted de e-mails' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         1 AS linhas_avaliadas, IF(x.v <> y.v,1,0) AS linhas_falha FROM (SELECT SUM(qtd_emails) AS v FROM rEM) x CROSS JOIN (SELECT COUNT(*) AS v FROM tEM) y
  UNION ALL
  SELECT 'rfn_marketing__estrutura_resumo.emails_canonicos_sao_os_ids_distintos' AS id_regra, 'Refined' AS camada, 'rfn_marketing__estrutura_resumo' AS tabela, 'RD Station' AS sistema, 'INTEGRIDADE' AS dimensao,
         'soma de qtd_emails_canonicos = ids de e-mail distintos da Trusted (sem dupla contagem entre contas)' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         1 AS linhas_avaliadas, IF(x.v <> y.v,1,0) AS linhas_falha FROM (SELECT SUM(qtd_emails_canonicos) AS v FROM rEM) x CROSS JOIN (SELECT COUNT(DISTINCT id_email_origem) AS v FROM tEM) y
  UNION ALL
  SELECT 'rfn_marketing__estrutura_resumo.ativos_canonicos_sao_os_ids_distintos' AS id_regra, 'Refined' AS camada, 'rfn_marketing__estrutura_resumo' AS tabela, 'RD Station' AS sistema, 'INTEGRIDADE' AS dimensao,
         'soma de qtd_ativos_captura_canonicos = (tipo + id) distintos da Trusted de captura' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         1 AS linhas_avaliadas, IF(x.v <> y.v,1,0) AS linhas_falha FROM (SELECT SUM(qtd_ativos_captura_canonicos) AS v FROM rEM) x CROSS JOIN (SELECT COUNT(DISTINCT CONCAT(tipo_ativo,'|',id_ativo_origem)) AS v FROM tCAP) y
  UNION ALL
  SELECT 'rfn_marketing__estrutura_resumo.segmentacoes_canonicas_sao_os_ids_distintos' AS id_regra, 'Refined' AS camada, 'rfn_marketing__estrutura_resumo' AS tabela, 'RD Station' AS sistema, 'INTEGRIDADE' AS dimensao,
         'soma de qtd_segmentacoes_canonicas = ids de segmentacao distintos da Trusted' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         1 AS linhas_avaliadas, IF(x.v <> y.v,1,0) AS linhas_falha FROM (SELECT SUM(qtd_segmentacoes_canonicas) AS v FROM rEM) x CROSS JOIN (SELECT COUNT(DISTINCT id_segmentacao_origem) AS v FROM tSG) y
  UNION ALL
  SELECT 'rfn_marketing__email_desempenho_mensal.taxa_abertura_nulo_quando_sem_denominador' AS id_regra, 'Refined' AS camada, 'rfn_marketing__email_desempenho_mensal' AS tabela, 'RD Station' AS sistema, 'VALIDADE' AS dimensao,
         'taxa_abertura e NULL exatamente quando entregues e zero ou ausente (zero de denominador nunca vira taxa zero)' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNTIF((taxa_abertura IS NULL) <> (IFNULL(qtd_entregues,0) = 0)) AS linhas_falha FROM rES
  UNION ALL
  SELECT 'rfn_marketing__automacao_email_resumo.taxa_abertura_unica_nulo_quando_sem_denominador' AS id_regra, 'Refined' AS camada, 'rfn_marketing__automacao_email_resumo' AS tabela, 'RD Station' AS sistema, 'VALIDADE' AS dimensao,
         'taxa_abertura_unica e NULL exatamente quando entregues e zero ou ausente (zero de denominador nunca vira taxa zero)' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNTIF((taxa_abertura_unica IS NULL) <> (IFNULL(qtd_entregues,0) = 0)) AS linhas_falha FROM rWS
  UNION ALL
  SELECT 'rfn_marketing__ativo_conversao_mensal.taxa_conversao_nulo_quando_sem_denominador' AS id_regra, 'Refined' AS camada, 'rfn_marketing__ativo_conversao_mensal' AS tabela, 'RD Station' AS sistema, 'VALIDADE' AS dimensao,
         'taxa_conversao e NULL exatamente quando visitas e zero ou ausente (zero de denominador nunca vira taxa zero)' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNTIF((taxa_conversao IS NULL) <> (IFNULL(qtd_visitas,0) = 0)) AS linhas_falha FROM rCA
  UNION ALL
  SELECT 'rfn_marketing__funil_analytics_mensal.taxa_visitante_para_lead_nulo_quando_sem_denominador' AS id_regra, 'Refined' AS camada, 'rfn_marketing__funil_analytics_mensal' AS tabela, 'RD Station' AS sistema, 'VALIDADE' AS dimensao,
         'taxa_visitante_para_lead e NULL exatamente quando visitantes e zero ou ausente (zero de denominador nunca vira taxa zero)' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNTIF((taxa_visitante_para_lead IS NULL) <> (IFNULL(qtd_visitantes,0) = 0)) AS linhas_falha FROM rAF
  UNION ALL
  SELECT 'rfn_marketing__funil_contato_estagio.taxa_oportunidade_nulo_quando_sem_denominador' AS id_regra, 'Refined' AS camada, 'rfn_marketing__funil_contato_estagio' AS tabela, 'RD Station' AS sistema, 'VALIDADE' AS dimensao,
         'taxa_oportunidade e NULL exatamente quando contatos e zero ou ausente (zero de denominador nunca vira taxa zero)' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNTIF((taxa_oportunidade IS NULL) <> (IFNULL(qtd_contatos,0) = 0)) AS linhas_falha FROM rF
  UNION ALL
  SELECT 'rfn_marketing__email_desempenho_mensal.mes_e_primeiro_dia' AS id_regra, 'Refined' AS camada, 'rfn_marketing__email_desempenho_mensal' AS tabela, 'RD Station' AS sistema, 'VALIDADE' AS dimensao,
         'mes_referencia, quando existe, e o primeiro dia do mes' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         COUNTIF(mes_referencia IS NOT NULL) AS linhas_avaliadas, COUNTIF(mes_referencia IS NOT NULL AND EXTRACT(DAY FROM mes_referencia) <> 1) AS linhas_falha FROM rES
  UNION ALL
  SELECT 'rfn_marketing__ativo_conversao_mensal.mes_e_primeiro_dia' AS id_regra, 'Refined' AS camada, 'rfn_marketing__ativo_conversao_mensal' AS tabela, 'RD Station' AS sistema, 'VALIDADE' AS dimensao,
         'mes_referencia, quando existe, e o primeiro dia do mes' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         COUNTIF(mes_referencia IS NOT NULL) AS linhas_avaliadas, COUNTIF(mes_referencia IS NOT NULL AND EXTRACT(DAY FROM mes_referencia) <> 1) AS linhas_falha FROM rCA
  UNION ALL
  SELECT 'rfn_marketing__funil_analytics_mensal.mes_e_primeiro_dia' AS id_regra, 'Refined' AS camada, 'rfn_marketing__funil_analytics_mensal' AS tabela, 'RD Station' AS sistema, 'VALIDADE' AS dimensao,
         'mes_referencia, quando existe, e o primeiro dia do mes' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         COUNTIF(mes_referencia IS NOT NULL) AS linhas_avaliadas, COUNTIF(mes_referencia IS NOT NULL AND EXTRACT(DAY FROM mes_referencia) <> 1) AS linhas_falha FROM rAF
  UNION ALL
  SELECT 'rfn_marketing__oportunidade_mensal.mes_e_primeiro_dia' AS id_regra, 'Refined' AS camada, 'rfn_marketing__oportunidade_mensal' AS tabela, 'RD Station' AS sistema, 'VALIDADE' AS dimensao,
         'mes_referencia, quando existe, e o primeiro dia do mes' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         COUNTIF(mes_referencia IS NOT NULL) AS linhas_avaliadas, COUNTIF(mes_referencia IS NOT NULL AND EXTRACT(DAY FROM mes_referencia) <> 1) AS linhas_falha FROM rOP
  UNION ALL
  SELECT 'rfn_marketing__ativo_conversao_mensal.tipo_catalogado' AS id_regra, 'Refined' AS camada, 'rfn_marketing__ativo_conversao_mensal' AS tabela, 'RD Station' AS sistema, 'INTEGRIDADE' AS dimensao,
         'linhas mensais com o tipo do ativo resolvido pelo catalogo de captura (LINHA DE BASE: 30 de 33 linhas mensais resolvem em 5 contas, 91%; limiar provisorio, revisar na primeira carga completa das 39 contas)' AS regra, 'ALERTA' AS severidade, 0.800 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNTIF(tipo_ativo = 'NAO_CATALOGADO') AS linhas_falha FROM rCA
  UNION ALL
  SELECT 'trs_rd_station__ativo_conversao_dia.conversoes_nao_excedem_visitas' AS id_regra, 'Trusted' AS camada, 'trs_rd_station__ativo_conversao_dia' AS tabela, 'RD Station' AS sistema, 'VALIDADE' AS dimensao,
         'linhas diarias em que conversoes nao passam de visitas (LINHA DE BASE: 516 de 94.785 na medicao de 18/10 sobre as 39 contas; a origem nao explica a causa)' AS regra, 'ALERTA' AS severidade, 0.990 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNTIF(flag_conversoes_maior_que_visitas) AS linhas_falha FROM tCA
  UNION ALL
  SELECT 'trs_rd_station__email_desempenho.abertos_nao_excedem_entregues' AS id_regra, 'Trusted' AS camada, 'trs_rd_station__email_desempenho' AS tabela, 'RD Station' AS sistema, 'VALIDADE' AS dimensao,
         'envios em que abertos nao passam de entregues (LINHA DE BASE: 0 de 327 na medicao de 18/10 sobre as 38 contas com dado)' AS regra, 'ALERTA' AS severidade, 0.990 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNTIF(flag_abertos_maior_que_entregues) AS linhas_falha FROM tES
  UNION ALL
  SELECT 'trs_rd_station__funil_dia.qualificados_nao_excedem_leads' AS id_regra, 'Trusted' AS camada, 'trs_rd_station__funil_dia' AS tabela, 'RD Station' AS sistema, 'VALIDADE' AS dimensao,
         'dias em que qualificados nao passam de leads (LINHA DE BASE: 35 de 1.538 na medicao de 18/10; o funil da RD nao e monotonico)' AS regra, 'ALERTA' AS severidade, 0.950 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNTIF(flag_qualificados_maior_que_leads) AS linhas_falha FROM tAF
  UNION ALL
  SELECT 'trs_rd_station__funil_dia.oportunidades_nao_excedem_qualificados' AS id_regra, 'Trusted' AS camada, 'trs_rd_station__funil_dia' AS tabela, 'RD Station' AS sistema, 'VALIDADE' AS dimensao,
         'dias em que oportunidades nao passam de qualificados (LINHA DE BASE: 344 de 1.538 na medicao de 18/10; o funil da RD nao e monotonico)' AS regra, 'ALERTA' AS severidade, 0.700 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNTIF(flag_oportunidades_maior_que_qualificados) AS linhas_falha FROM tAF
  UNION ALL
  SELECT 'trs_rd_station__streams.carga_do_mesmo_dia' AS id_regra, 'Trusted' AS camada, '9 Trusted de streams RD' AS tabela, 'RD Station' AS sistema, 'FRESCOR' AS dimensao,
         'as nove Trusted de streams RD foram escritas na MESMA data de carga (o cron e o mesmo, terca 13:30 America/Manaus); se uma ficou para tras, a Refined misturaria semanas' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         1 AS linhas_avaliadas, IF((SELECT COUNT(DISTINCT d) FROM (SELECT MAX(DATE(_extraido_at)) d FROM tF UNION ALL SELECT MAX(DATE(_extraido_at)) FROM tOP UNION ALL SELECT MAX(DATE(_extraido_at)) FROM tES UNION ALL SELECT MAX(DATE(_extraido_at)) FROM tWS UNION ALL SELECT MAX(DATE(_extraido_at)) FROM tCA UNION ALL SELECT MAX(DATE(_extraido_at)) FROM tAF UNION ALL SELECT MAX(DATE(_extraido_at)) FROM tEM UNION ALL SELECT MAX(DATE(_extraido_at)) FROM tCAP UNION ALL SELECT MAX(DATE(_extraido_at)) FROM tSG)) > 1, 1, 0) AS linhas_falha FROM UNNEST([1])
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
  'MARKETING_RD_STREAMS' AS familia, CURRENT_TIMESTAMP() AS _extraido_at, 'nekt' AS _fonte, 'America/Sao_Paulo' AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(a))) AS _payload_hash
FROM avaliado a