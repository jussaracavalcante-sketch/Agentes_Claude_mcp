-- rfn_qualidade__regra_financeiro_dimensoes  ·  Refined / qualidade  ·  L2 INTERNAL (so contagem e taxa)
-- Grao: uma REGRA de qualidade em uma execucao. Chave: id_regra (a execucao se le em _extraido_at).
-- Cobre as 11 Refined financeiras de 19/10/2026 (rfn_financeiro__contazul_apoio_resumo, __contrato_mensal, __pessoa_resumo, __saldo_posicao_mensal,
-- __transferencia_mensal, __venda_item_mensal, rfn_financeiro__extrato_saldo_mensal, __cliente_risco_resumo, __dicionario_resumo, __extrato_sweep_mensal,
-- __operacao_resumo), que agregam 11 Trusted que antes nao tinham nenhuma Refined lendo.
-- Contrato de colunas IDENTICO ao das outras suites: um UNION ALL da o painel unico e `familia` diz de onde veio cada linha.
-- POR QUE SUITE PROPRIA: a principal esta em 57 KB e update_transformation substitui o codigo inteiro (precedente Gmail, iClips, Marketing).
-- Gatilho: evento "all" nas 11 Refined; a regra de frescor mede a premissa que o "all" deveria garantir (o "all" ja travou em pending_events em 18/10).
-- TIPOS DE REGRA: (1) chave unica por Refined; (2) IDENTIDADE entre camadas -- a soma da Refined reproduz a Trusted (contagem e valor, dentro de um centavo);
--    (3) invariantes por linha; (4) linhas de base de ALERTA com limiar medido em 19/10, para detectar PIORA e nao reclamar do que a origem ja traz.
-- NAO ENTRAM, DE PROPOSITO: regra comparando flag gravada contra o relogio (a flag congela na carga); chave unica das Trusted (ja cobertas por rfn_qualidade__regra_x0tz_gold).

WITH carga AS (
  SELECT 'contazul_apoio_resumo' AS t, MAX(DATE(_extraido_at)) AS d FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_apoio_resumo`
  UNION ALL SELECT 'contazul_contrato_mensal' AS t, MAX(DATE(_extraido_at)) AS d FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_contrato_mensal`
  UNION ALL SELECT 'contazul_pessoa_resumo' AS t, MAX(DATE(_extraido_at)) AS d FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_pessoa_resumo`
  UNION ALL SELECT 'contazul_saldo_posicao_mensal' AS t, MAX(DATE(_extraido_at)) AS d FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_saldo_posicao_mensal`
  UNION ALL SELECT 'contazul_transferencia_mensal' AS t, MAX(DATE(_extraido_at)) AS d FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_transferencia_mensal`
  UNION ALL SELECT 'contazul_venda_item_mensal' AS t, MAX(DATE(_extraido_at)) AS d FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_venda_item_mensal`
  UNION ALL SELECT 'extrato_saldo_mensal' AS t, MAX(DATE(_extraido_at)) AS d FROM `vanguardamartech_refined`.`rfn_financeiro__extrato_saldo_mensal`
  UNION ALL SELECT 'cliente_risco_resumo' AS t, MAX(DATE(_extraido_at)) AS d FROM `vanguardamartech_refined`.`rfn_financeiro__cliente_risco_resumo`
  UNION ALL SELECT 'dicionario_resumo' AS t, MAX(DATE(_extraido_at)) AS d FROM `vanguardamartech_refined`.`rfn_financeiro__dicionario_resumo`
  UNION ALL SELECT 'extrato_sweep_mensal' AS t, MAX(DATE(_extraido_at)) AS d FROM `vanguardamartech_refined`.`rfn_financeiro__extrato_sweep_mensal`
  UNION ALL SELECT 'operacao_resumo' AS t, MAX(DATE(_extraido_at)) AS d FROM `vanguardamartech_refined`.`rfn_financeiro__operacao_resumo`
),
todas AS (
  SELECT 'rfn_financeiro__contazul_apoio_resumo.id_unico' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__contazul_apoio_resumo' AS tabela, 'Conta Azul' AS sistema,
         'UNICIDADE' AS dimensao, 'id_apoio_resumo e unico e nunca nulo' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_apoio_resumo) + COUNTIF(id_apoio_resumo IS NULL) AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_apoio_resumo`
  UNION ALL
  SELECT 'rfn_financeiro__contazul_apoio_resumo.itens_reproduzem_a_trusted' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__contazul_apoio_resumo' AS tabela, 'Conta Azul' AS sistema,
         'INTEGRIDADE' AS dimensao, 'soma de qtd_itens reproduz as linhas de trs_contazul__apoio' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         1 AS linhas_avaliadas, IF(IFNULL(a,-1e18) = IFNULL(b,-1e18), 0, 1) AS linhas_falha
  FROM (SELECT (SELECT SUM(qtd_itens) FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_apoio_resumo`) AS a, (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_contazul__apoio`) AS b)
  UNION ALL
  SELECT 'rfn_financeiro__contazul_apoio_resumo.saldo_reproduz_a_trusted' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__contazul_apoio_resumo' AS tabela, 'Conta Azul' AS sistema,
         'INTEGRIDADE' AS dimensao, 'soma de valor_num_total reproduz a soma de valor_num da Trusted (dentro de um centavo)' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         1 AS linhas_avaliadas, IF(ABS(IFNULL(a,-1e18) - IFNULL(b,-1e18)) <= 0.01, 0, 1) AS linhas_falha
  FROM (SELECT (SELECT SUM(valor_num_total) FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_apoio_resumo`) AS a, (SELECT SUM(valor_num) FROM `vanguardamartech_trusted`.`trs_contazul__apoio`) AS b)
  UNION ALL
  SELECT 'rfn_financeiro__contazul_apoio_resumo.pai_da_categoria_resolve' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__contazul_apoio_resumo' AS tabela, 'Conta Azul' AS sistema,
         'INTEGRIDADE' AS dimensao, 'pai da categoria resolve dentro da propria origem (linha de base: 8 de 353 em 19/10)' AS regra, 'ALERTA' AS severidade, 0.020 AS limiar,
         SUM(qtd_com_pai) AS linhas_avaliadas, SUM(qtd_pai_nao_catalogado) AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_apoio_resumo`
  UNION ALL
  SELECT 'rfn_financeiro__contazul_contrato_mensal.id_unico' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__contazul_contrato_mensal' AS tabela, 'Conta Azul' AS sistema,
         'UNICIDADE' AS dimensao, 'id_contrato_mensal e unico e nunca nulo' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_contrato_mensal) + COUNTIF(id_contrato_mensal IS NULL) AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_contrato_mensal`
  UNION ALL
  SELECT 'rfn_financeiro__contazul_contrato_mensal.contratos_reproduzem_a_trusted' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__contazul_contrato_mensal' AS tabela, 'Conta Azul' AS sistema,
         'INTEGRIDADE' AS dimensao, 'soma de qtd_contratos reproduz as linhas de trs_contazul__contrato' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         1 AS linhas_avaliadas, IF(IFNULL(a,-1e18) = IFNULL(b,-1e18), 0, 1) AS linhas_falha
  FROM (SELECT (SELECT SUM(qtd_contratos) FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_contrato_mensal`) AS a, (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_contazul__contrato`) AS b)
  UNION ALL
  SELECT 'rfn_financeiro__contazul_contrato_mensal.valor_reproduz_a_trusted' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__contazul_contrato_mensal' AS tabela, 'Conta Azul' AS sistema,
         'INTEGRIDADE' AS dimensao, 'soma de valor_total reproduz a soma de valor_total da Trusted (dentro de um centavo)' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         1 AS linhas_avaliadas, IF(ABS(IFNULL(a,-1e18) - IFNULL(b,-1e18)) <= 0.01, 0, 1) AS linhas_falha
  FROM (SELECT (SELECT SUM(valor_total) FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_contrato_mensal`) AS a, (SELECT SUM(valor_total) FROM `vanguardamartech_trusted`.`trs_contazul__contrato`) AS b)
  UNION ALL
  SELECT 'rfn_financeiro__contazul_contrato_mensal.ativos_reproduzem_a_trusted' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__contazul_contrato_mensal' AS tabela, 'Conta Azul' AS sistema,
         'INTEGRIDADE' AS dimensao, 'soma de qtd_ativos reproduz os contratos is_ativo da Trusted' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         1 AS linhas_avaliadas, IF(IFNULL(a,-1e18) = IFNULL(b,-1e18), 0, 1) AS linhas_falha
  FROM (SELECT (SELECT SUM(qtd_ativos) FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_contrato_mensal`) AS a, (SELECT COUNTIF(is_ativo) FROM `vanguardamartech_trusted`.`trs_contazul__contrato`) AS b)
  UNION ALL
  SELECT 'rfn_financeiro__contazul_contrato_mensal.ativo_concorda_com_o_status' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__contazul_contrato_mensal' AS tabela, 'Conta Azul' AS sistema,
         'VALIDADE' AS dimensao, 'status ATIVO tem todos os contratos ativos e qualquer outro status tem zero' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNTIF((status_origem = 'ATIVO' AND qtd_ativos <> qtd_contratos) OR (status_origem <> 'ATIVO' AND qtd_ativos <> 0)) AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_contrato_mensal`
  UNION ALL
  SELECT 'rfn_financeiro__contazul_pessoa_resumo.id_unico' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__contazul_pessoa_resumo' AS tabela, 'Conta Azul' AS sistema,
         'UNICIDADE' AS dimensao, 'id_pessoa_resumo e unico e nunca nulo' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_pessoa_resumo) + COUNTIF(id_pessoa_resumo IS NULL) AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_pessoa_resumo`
  UNION ALL
  SELECT 'rfn_financeiro__contazul_pessoa_resumo.pessoas_reproduzem_a_trusted' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__contazul_pessoa_resumo' AS tabela, 'Conta Azul' AS sistema,
         'INTEGRIDADE' AS dimensao, 'soma de qtd_pessoas reproduz as linhas de trs_contazul__pessoa' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         1 AS linhas_avaliadas, IF(IFNULL(a,-1e18) = IFNULL(b,-1e18), 0, 1) AS linhas_falha
  FROM (SELECT (SELECT SUM(qtd_pessoas) FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_pessoa_resumo`) AS a, (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_contazul__pessoa`) AS b)
  UNION ALL
  SELECT 'rfn_financeiro__contazul_pessoa_resumo.parcelas_reproduzem_o_razao' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__contazul_pessoa_resumo' AS tabela, 'Conta Azul' AS sistema,
         'INTEGRIDADE' AS dimensao, 'soma de qtd_parcelas_vigentes reproduz as parcelas vigentes do razao ligadas a uma pessoa' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         1 AS linhas_avaliadas, IF(IFNULL(a,-1e18) = IFNULL(b,-1e18), 0, 1) AS linhas_falha
  FROM (SELECT (SELECT SUM(qtd_parcelas_vigentes) FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_pessoa_resumo`) AS a, (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_contazul__movimento` m JOIN `vanguardamartech_trusted`.`trs_contazul__pessoa` p ON p.id_pessoa = m.id_entidade_contaazul WHERE m.is_vigente) AS b)
  UNION ALL
  SELECT 'rfn_financeiro__contazul_pessoa_resumo.valor_reproduz_o_razao' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__contazul_pessoa_resumo' AS tabela, 'Conta Azul' AS sistema,
         'INTEGRIDADE' AS dimensao, 'soma de valor_vigente reproduz o valor vigente do razao ligado a uma pessoa (dentro de um centavo)' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         1 AS linhas_avaliadas, IF(ABS(IFNULL(a,-1e18) - IFNULL(b,-1e18)) <= 0.01, 0, 1) AS linhas_falha
  FROM (SELECT (SELECT SUM(valor_vigente) FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_pessoa_resumo`) AS a, (SELECT SUM(m.valor) FROM `vanguardamartech_trusted`.`trs_contazul__movimento` m JOIN `vanguardamartech_trusted`.`trs_contazul__pessoa` p ON p.id_pessoa = m.id_entidade_contaazul WHERE m.is_vigente) AS b)
  UNION ALL
  SELECT 'rfn_financeiro__contazul_pessoa_resumo.papel_preenchido' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__contazul_pessoa_resumo' AS tabela, 'Conta Azul' AS sistema,
         'COMPLETUDE' AS dimensao, 'toda linha carrega papel (C, F, CF, T ou FT)' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNTIF(papel IS NULL) AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_pessoa_resumo`
  UNION ALL
  SELECT 'rfn_financeiro__contazul_pessoa_resumo.pessoa_com_documento' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__contazul_pessoa_resumo' AS tabela, 'Conta Azul' AS sistema,
         'COMPLETUDE' AS dimensao, 'pessoas com documento valido (PJ ou PF); linha de base: 1.307 de 2.096 = 62,4% em 19/10' AS regra, 'ALERTA' AS severidade, 0.550 AS limiar,
         SUM(qtd_pessoas) AS linhas_avaliadas, SUM(IF(tipo_documento IN ('SEM_DOCUMENTO','DOCUMENTO_INVALIDO'), qtd_pessoas, 0)) AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_pessoa_resumo`
  UNION ALL
  SELECT 'rfn_financeiro__contazul_saldo_posicao_mensal.id_unico' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__contazul_saldo_posicao_mensal' AS tabela, 'Conta Azul' AS sistema,
         'UNICIDADE' AS dimensao, 'id_saldo_posicao_mensal e unico e nunca nulo' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_saldo_posicao_mensal) + COUNTIF(id_saldo_posicao_mensal IS NULL) AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_saldo_posicao_mensal`
  UNION ALL
  SELECT 'rfn_financeiro__contazul_saldo_posicao_mensal.linhas_reproduzem_a_trusted' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__contazul_saldo_posicao_mensal' AS tabela, 'Conta Azul' AS sistema,
         'INTEGRIDADE' AS dimensao, 'soma de qtd_linhas reproduz as linhas de trs_contazul__saldo_posicao' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         1 AS linhas_avaliadas, IF(IFNULL(a,-1e18) = IFNULL(b,-1e18), 0, 1) AS linhas_falha
  FROM (SELECT (SELECT SUM(qtd_linhas) FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_saldo_posicao_mensal`) AS a, (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_contazul__saldo_posicao`) AS b)
  UNION ALL
  SELECT 'rfn_financeiro__contazul_saldo_posicao_mensal.saldo_reproduz_a_trusted' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__contazul_saldo_posicao_mensal' AS tabela, 'Conta Azul' AS sistema,
         'INTEGRIDADE' AS dimensao, 'soma de saldo reproduz a soma de saldo da Trusted (dentro de um centavo)' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         1 AS linhas_avaliadas, IF(ABS(IFNULL(a,-1e18) - IFNULL(b,-1e18)) <= 0.01, 0, 1) AS linhas_falha
  FROM (SELECT (SELECT SUM(saldo) FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_saldo_posicao_mensal`) AS a, (SELECT SUM(saldo) FROM `vanguardamartech_trusted`.`trs_contazul__saldo_posicao`) AS b)
  UNION ALL
  SELECT 'rfn_financeiro__contazul_saldo_posicao_mensal.vencido_mais_a_vencer_e_o_saldo' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__contazul_saldo_posicao_mensal' AS tabela, 'Conta Azul' AS sistema,
         'VALIDADE' AS dimensao, 'na posicao a receber/pagar, vencido + a_vencer = saldo em todas as linhas de origem' AS regra, 'ALERTA' AS severidade, 1.000 AS limiar,
         SUM(IF(origem = 'POSICAO_SNAPSHOT', qtd_linhas, 0)) AS linhas_avaliadas, SUM(qtd_identidade_quebrada) AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_saldo_posicao_mensal`
  UNION ALL
  SELECT 'rfn_financeiro__contazul_transferencia_mensal.id_unico' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__contazul_transferencia_mensal' AS tabela, 'Conta Azul' AS sistema,
         'UNICIDADE' AS dimensao, 'id_transferencia_mensal e unico e nunca nulo' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_transferencia_mensal) + COUNTIF(id_transferencia_mensal IS NULL) AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_transferencia_mensal`
  UNION ALL
  SELECT 'rfn_financeiro__contazul_transferencia_mensal.fato_reproduz_a_trusted' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__contazul_transferencia_mensal' AS tabela, 'Conta Azul' AS sistema,
         'INTEGRIDADE' AS dimensao, 'soma de qtd_transferencias reproduz as linhas de trs_contazul__transferencia' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         1 AS linhas_avaliadas, IF(IFNULL(a,-1e18) = IFNULL(b,-1e18), 0, 1) AS linhas_falha
  FROM (SELECT (SELECT SUM(qtd_transferencias) FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_transferencia_mensal`) AS a, (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_contazul__transferencia`) AS b)
  UNION ALL
  SELECT 'rfn_financeiro__contazul_transferencia_mensal.valor_do_fato_reproduz_a_trusted' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__contazul_transferencia_mensal' AS tabela, 'Conta Azul' AS sistema,
         'INTEGRIDADE' AS dimensao, 'soma de valor_transferido reproduz a soma de valor da Trusted (dentro de um centavo)' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         1 AS linhas_avaliadas, IF(ABS(IFNULL(a,-1e18) - IFNULL(b,-1e18)) <= 0.01, 0, 1) AS linhas_falha
  FROM (SELECT (SELECT SUM(valor_transferido) FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_transferencia_mensal`) AS a, (SELECT SUM(valor) FROM `vanguardamartech_trusted`.`trs_contazul__transferencia`) AS b)
  UNION ALL
  SELECT 'rfn_financeiro__contazul_transferencia_mensal.razao_entrada_reproduz_o_razao' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__contazul_transferencia_mensal' AS tabela, 'Conta Azul' AS sistema,
         'INTEGRIDADE' AS dimensao, 'soma de qtd_razao_entrada reproduz as transferencias vigentes de entrada do razao' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         1 AS linhas_avaliadas, IF(IFNULL(a,-1e18) = IFNULL(b,-1e18), 0, 1) AS linhas_falha
  FROM (SELECT (SELECT SUM(qtd_razao_entrada) FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_transferencia_mensal`) AS a, (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_contazul__movimento` WHERE classe_financeira = 'TRANSFERENCIA' AND is_vigente AND sentido = 'ENTRADA') AS b)
  UNION ALL
  SELECT 'rfn_financeiro__contazul_transferencia_mensal.razao_saida_reproduz_o_razao' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__contazul_transferencia_mensal' AS tabela, 'Conta Azul' AS sistema,
         'INTEGRIDADE' AS dimensao, 'soma de valor_razao_saida reproduz o valor vigente de saida do razao (dentro de um centavo)' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         1 AS linhas_avaliadas, IF(ABS(IFNULL(a,-1e18) - IFNULL(b,-1e18)) <= 0.01, 0, 1) AS linhas_falha
  FROM (SELECT (SELECT SUM(valor_razao_saida) FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_transferencia_mensal`) AS a, (SELECT SUM(valor) FROM `vanguardamartech_trusted`.`trs_contazul__movimento` WHERE classe_financeira = 'TRANSFERENCIA' AND is_vigente AND sentido = 'SAIDA') AS b)
  UNION ALL
  SELECT 'rfn_financeiro__contazul_venda_item_mensal.id_unico' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__contazul_venda_item_mensal' AS tabela, 'Conta Azul' AS sistema,
         'UNICIDADE' AS dimensao, 'id_venda_item_mensal e unico e nunca nulo' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_venda_item_mensal) + COUNTIF(id_venda_item_mensal IS NULL) AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_venda_item_mensal`
  UNION ALL
  SELECT 'rfn_financeiro__contazul_venda_item_mensal.itens_reproduzem_a_trusted' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__contazul_venda_item_mensal' AS tabela, 'Conta Azul' AS sistema,
         'INTEGRIDADE' AS dimensao, 'soma de qtd_itens reproduz as linhas de trs_contazul__venda_item' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         1 AS linhas_avaliadas, IF(IFNULL(a,-1e18) = IFNULL(b,-1e18), 0, 1) AS linhas_falha
  FROM (SELECT (SELECT SUM(qtd_itens) FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_venda_item_mensal`) AS a, (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_contazul__venda_item`) AS b)
  UNION ALL
  SELECT 'rfn_financeiro__contazul_venda_item_mensal.valor_reproduz_a_trusted' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__contazul_venda_item_mensal' AS tabela, 'Conta Azul' AS sistema,
         'INTEGRIDADE' AS dimensao, 'soma de valor_total reproduz a soma de valor_total da Trusted (dentro de um centavo)' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         1 AS linhas_avaliadas, IF(ABS(IFNULL(a,-1e18) - IFNULL(b,-1e18)) <= 0.01, 0, 1) AS linhas_falha
  FROM (SELECT (SELECT SUM(valor_total) FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_venda_item_mensal`) AS a, (SELECT SUM(valor_total) FROM `vanguardamartech_trusted`.`trs_contazul__venda_item`) AS b)
  UNION ALL
  SELECT 'rfn_financeiro__contazul_venda_item_mensal.valor_vigente_reproduz_a_venda' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__contazul_venda_item_mensal' AS tabela, 'Conta Azul' AS sistema,
         'INTEGRIDADE' AS dimensao, 'valor dos itens de venda vigente reproduz o join item x venda vigente (dentro de um centavo)' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         1 AS linhas_avaliadas, IF(ABS(IFNULL(a,-1e18) - IFNULL(b,-1e18)) <= 0.01, 0, 1) AS linhas_falha
  FROM (SELECT (SELECT SUM(IF(is_venda_vigente, valor_total, 0)) FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_venda_item_mensal`) AS a, (SELECT SUM(i.valor_total) FROM `vanguardamartech_trusted`.`trs_contazul__venda_item` i JOIN `vanguardamartech_trusted`.`trs_contazul__venda` v ON v.id_venda = i.id_venda WHERE v.is_vigente) AS b)
  UNION ALL
  SELECT 'rfn_financeiro__contazul_venda_item_mensal.venda_catalogada' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__contazul_venda_item_mensal' AS tabela, 'Conta Azul' AS sistema,
         'INTEGRIDADE' AS dimensao, 'todo item encontra a venda (3.454 de 3.454 em 19/10)' AS regra, 'ALERTA' AS severidade, 0.999 AS limiar,
         SUM(qtd_itens) AS linhas_avaliadas, SUM(qtd_venda_nao_catalogada) AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_venda_item_mensal`
  UNION ALL
  SELECT 'rfn_financeiro__extrato_saldo_mensal.id_unico' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__extrato_saldo_mensal' AS tabela, 'Financeiro' AS sistema,
         'UNICIDADE' AS dimensao, 'id_extrato_mensal e unico e nunca nulo' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_extrato_mensal) + COUNTIF(id_extrato_mensal IS NULL) AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_financeiro__extrato_saldo_mensal`
  UNION ALL
  SELECT 'rfn_financeiro__extrato_saldo_mensal.contas_reproduzem_a_trusted' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__extrato_saldo_mensal' AS tabela, 'Financeiro' AS sistema,
         'INTEGRIDADE' AS dimensao, 'soma de qtd_contas reproduz as linhas de trs_extrato__saldo_mensal' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         1 AS linhas_avaliadas, IF(IFNULL(a,-1e18) = IFNULL(b,-1e18), 0, 1) AS linhas_falha
  FROM (SELECT (SELECT SUM(qtd_contas) FROM `vanguardamartech_refined`.`rfn_financeiro__extrato_saldo_mensal`) AS a, (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_extrato__saldo_mensal`) AS b)
  UNION ALL
  SELECT 'rfn_financeiro__extrato_saldo_mensal.movimento_reproduz_a_trusted' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__extrato_saldo_mensal' AS tabela, 'Financeiro' AS sistema,
         'INTEGRIDADE' AS dimensao, 'soma de movimento reproduz a soma de movimento da Trusted (dentro de um centavo)' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         1 AS linhas_avaliadas, IF(ABS(IFNULL(a,-1e18) - IFNULL(b,-1e18)) <= 0.01, 0, 1) AS linhas_falha
  FROM (SELECT (SELECT SUM(movimento) FROM `vanguardamartech_refined`.`rfn_financeiro__extrato_saldo_mensal`) AS a, (SELECT SUM(movimento) FROM `vanguardamartech_trusted`.`trs_extrato__saldo_mensal`) AS b)
  UNION ALL
  SELECT 'rfn_financeiro__extrato_saldo_mensal.lancamentos_reproduzem_a_trusted' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__extrato_saldo_mensal' AS tabela, 'Financeiro' AS sistema,
         'INTEGRIDADE' AS dimensao, 'soma de qtd_lancamentos reproduz a soma de qtd_lancamentos da Trusted' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         1 AS linhas_avaliadas, IF(IFNULL(a,-1e18) = IFNULL(b,-1e18), 0, 1) AS linhas_falha
  FROM (SELECT (SELECT SUM(qtd_lancamentos) FROM `vanguardamartech_refined`.`rfn_financeiro__extrato_saldo_mensal`) AS a, (SELECT SUM(qtd_lancamentos) FROM `vanguardamartech_trusted`.`trs_extrato__saldo_mensal`) AS b)
  UNION ALL
  SELECT 'rfn_financeiro__extrato_saldo_mensal.pares_avaliaveis_fecham' AS id_regra, 'Trusted' AS camada, 'trs_extrato__saldo_mensal' AS tabela, 'Financeiro' AS sistema,
         'VALIDADE' AS dimensao, 'saldo_anterior + movimento = saldo_final nos pares avaliaveis (linha de base: 19 de 20 em 19/10; falha conhecida itau_brm 2026-07)' AS regra, 'ALERTA' AS severidade, 0.900 AS limiar,
         COUNTIF(diferenca_identidade IS NOT NULL) AS linhas_avaliadas, COUNTIF(flag_nao_fecha) AS linhas_falha
  FROM `vanguardamartech_trusted`.`trs_extrato__saldo_mensal`
  UNION ALL
  SELECT 'rfn_financeiro__cliente_risco_resumo.id_unico' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__cliente_risco_resumo' AS tabela, 'Financeiro' AS sistema,
         'UNICIDADE' AS dimensao, 'id_cliente_risco_resumo e unico e nunca nulo' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_cliente_risco_resumo) + COUNTIF(id_cliente_risco_resumo IS NULL) AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_financeiro__cliente_risco_resumo`
  UNION ALL
  SELECT 'rfn_financeiro__cliente_risco_resumo.clientes_reproduzem_a_trusted' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__cliente_risco_resumo' AS tabela, 'Financeiro' AS sistema,
         'INTEGRIDADE' AS dimensao, 'soma de qtd_clientes reproduz as linhas de trs_financeiro__cliente_risco' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         1 AS linhas_avaliadas, IF(IFNULL(a,-1e18) = IFNULL(b,-1e18), 0, 1) AS linhas_falha
  FROM (SELECT (SELECT SUM(qtd_clientes) FROM `vanguardamartech_refined`.`rfn_financeiro__cliente_risco_resumo`) AS a, (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_financeiro__cliente_risco`) AS b)
  UNION ALL
  SELECT 'rfn_financeiro__cliente_risco_resumo.cronico_tem_score' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__cliente_risco_resumo' AS tabela, 'Financeiro' AS sistema,
         'COMPLETUDE' AS dimensao, 'todo pagador cronico carrega score (flag_cronico_sem_score zero)' AS regra, 'ALERTA' AS severidade, 1.000 AS limiar,
         SUM(qtd_pagador_cronico) AS linhas_avaliadas, SUM(qtd_cronico_sem_score) AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_financeiro__cliente_risco_resumo`
  UNION ALL
  SELECT 'rfn_financeiro__cliente_risco_resumo.cliente_com_movimento' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__cliente_risco_resumo' AS tabela, 'Financeiro' AS sistema,
         'INTEGRIDADE' AS dimensao, 'cliente de risco aparece como contraparte do movimento financeiro (14 de 14 em 19/10)' AS regra, 'ALERTA' AS severidade, 0.900 AS limiar,
         SUM(qtd_clientes) AS linhas_avaliadas, SUM(qtd_clientes) - SUM(qtd_com_movimento_financeiro) AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_financeiro__cliente_risco_resumo`
  UNION ALL
  SELECT 'rfn_financeiro__dicionario_resumo.id_unico' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__dicionario_resumo' AS tabela, 'Financeiro' AS sistema,
         'UNICIDADE' AS dimensao, 'id_dicionario_resumo e unico e nunca nulo' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_dicionario_resumo) + COUNTIF(id_dicionario_resumo IS NULL) AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_financeiro__dicionario_resumo`
  UNION ALL
  SELECT 'rfn_financeiro__dicionario_resumo.entradas_reproduzem_a_trusted' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__dicionario_resumo' AS tabela, 'Financeiro' AS sistema,
         'INTEGRIDADE' AS dimensao, 'soma de qtd_entradas reproduz as linhas de trs_financeiro__dicionario' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         1 AS linhas_avaliadas, IF(IFNULL(a,-1e18) = IFNULL(b,-1e18), 0, 1) AS linhas_falha
  FROM (SELECT (SELECT SUM(qtd_entradas) FROM `vanguardamartech_refined`.`rfn_financeiro__dicionario_resumo`) AS a, (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_financeiro__dicionario`) AS b)
  UNION ALL
  SELECT 'rfn_financeiro__dicionario_resumo.origens_reproduzem_a_trusted' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__dicionario_resumo' AS tabela, 'Financeiro' AS sistema,
         'INTEGRIDADE' AS dimensao, 'numero de linhas reproduz as origens distintas da Trusted' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         1 AS linhas_avaliadas, IF(IFNULL(a,-1e18) = IFNULL(b,-1e18), 0, 1) AS linhas_falha
  FROM (SELECT (SELECT COUNT(*) FROM `vanguardamartech_refined`.`rfn_financeiro__dicionario_resumo`) AS a, (SELECT COUNT(DISTINCT origem) FROM `vanguardamartech_trusted`.`trs_financeiro__dicionario`) AS b)
  UNION ALL
  SELECT 'rfn_financeiro__dicionario_resumo.sem_chave_reproduz_a_trusted' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__dicionario_resumo' AS tabela, 'Financeiro' AS sistema,
         'INTEGRIDADE' AS dimensao, 'soma de qtd_sem_chave reproduz as entradas sem chave da Trusted' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         1 AS linhas_avaliadas, IF(IFNULL(a,-1e18) = IFNULL(b,-1e18), 0, 1) AS linhas_falha
  FROM (SELECT (SELECT SUM(qtd_sem_chave) FROM `vanguardamartech_refined`.`rfn_financeiro__dicionario_resumo`) AS a, (SELECT COUNTIF(chave IS NULL) FROM `vanguardamartech_trusted`.`trs_financeiro__dicionario`) AS b)
  UNION ALL
  SELECT 'rfn_financeiro__extrato_sweep_mensal.id_unico' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__extrato_sweep_mensal' AS tabela, 'Financeiro' AS sistema,
         'UNICIDADE' AS dimensao, 'id_sweep_mensal e unico e nunca nulo' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_sweep_mensal) + COUNTIF(id_sweep_mensal IS NULL) AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_financeiro__extrato_sweep_mensal`
  UNION ALL
  SELECT 'rfn_financeiro__extrato_sweep_mensal.sweeps_reproduzem_a_trusted' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__extrato_sweep_mensal' AS tabela, 'Financeiro' AS sistema,
         'INTEGRIDADE' AS dimensao, 'soma de qtd_sweeps reproduz as linhas de trs_financeiro__extrato_sweep' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         1 AS linhas_avaliadas, IF(IFNULL(a,-1e18) = IFNULL(b,-1e18), 0, 1) AS linhas_falha
  FROM (SELECT (SELECT SUM(qtd_sweeps) FROM `vanguardamartech_refined`.`rfn_financeiro__extrato_sweep_mensal`) AS a, (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_financeiro__extrato_sweep`) AS b)
  UNION ALL
  SELECT 'rfn_financeiro__extrato_sweep_mensal.valor_reproduz_a_trusted' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__extrato_sweep_mensal' AS tabela, 'Financeiro' AS sistema,
         'INTEGRIDADE' AS dimensao, 'soma de valor_sweep reproduz a soma de valor da Trusted (dentro de um centavo)' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         1 AS linhas_avaliadas, IF(ABS(IFNULL(a,-1e18) - IFNULL(b,-1e18)) <= 0.01, 0, 1) AS linhas_falha
  FROM (SELECT (SELECT SUM(valor_sweep) FROM `vanguardamartech_refined`.`rfn_financeiro__extrato_sweep_mensal`) AS a, (SELECT SUM(valor) FROM `vanguardamartech_trusted`.`trs_financeiro__extrato_sweep`) AS b)
  UNION ALL
  SELECT 'rfn_financeiro__extrato_sweep_mensal.casados_reproduzem_a_trusted' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__extrato_sweep_mensal' AS tabela, 'Financeiro' AS sistema,
         'INTEGRIDADE' AS dimensao, 'sweeps CASOU reproduzem is_casou da Trusted' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         1 AS linhas_avaliadas, IF(IFNULL(a,-1e18) = IFNULL(b,-1e18), 0, 1) AS linhas_falha
  FROM (SELECT (SELECT SUM(IF(status_casamento = 'CASOU', qtd_sweeps, 0)) FROM `vanguardamartech_refined`.`rfn_financeiro__extrato_sweep_mensal`) AS a, (SELECT COUNTIF(is_casou) FROM `vanguardamartech_trusted`.`trs_financeiro__extrato_sweep`) AS b)
  UNION ALL
  SELECT 'rfn_financeiro__operacao_resumo.id_unico' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__operacao_resumo' AS tabela, 'Financeiro' AS sistema,
         'UNICIDADE' AS dimensao, 'id_operacao e unico e nunca nulo' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_operacao) + COUNTIF(id_operacao IS NULL) AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_financeiro__operacao_resumo`
  UNION ALL
  SELECT 'rfn_financeiro__operacao_resumo.catalogadas_reproduzem_a_trusted' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__operacao_resumo' AS tabela, 'Financeiro' AS sistema,
         'INTEGRIDADE' AS dimensao, 'operacoes catalogadas reproduzem as linhas de trs_financeiro__operacao' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         1 AS linhas_avaliadas, IF(IFNULL(a,-1e18) = IFNULL(b,-1e18), 0, 1) AS linhas_falha
  FROM (SELECT (SELECT COUNTIF(NOT flag_operacao_nao_catalogada) FROM `vanguardamartech_refined`.`rfn_financeiro__operacao_resumo`) AS a, (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_financeiro__operacao`) AS b)
  UNION ALL
  SELECT 'rfn_financeiro__operacao_resumo.pessoas_reproduzem_a_trusted' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__operacao_resumo' AS tabela, 'Financeiro' AS sistema,
         'INTEGRIDADE' AS dimensao, 'soma de qtd_pessoas reproduz as linhas de trs_contazul__pessoa' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         1 AS linhas_avaliadas, IF(IFNULL(a,-1e18) = IFNULL(b,-1e18), 0, 1) AS linhas_falha
  FROM (SELECT (SELECT SUM(qtd_pessoas) FROM `vanguardamartech_refined`.`rfn_financeiro__operacao_resumo`) AS a, (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_contazul__pessoa`) AS b)
  UNION ALL
  SELECT 'rfn_financeiro__operacao_resumo.itens_de_venda_reproduzem_a_trusted' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__operacao_resumo' AS tabela, 'Financeiro' AS sistema,
         'INTEGRIDADE' AS dimensao, 'soma de qtd_itens_venda reproduz as linhas de trs_contazul__venda_item' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         1 AS linhas_avaliadas, IF(IFNULL(a,-1e18) = IFNULL(b,-1e18), 0, 1) AS linhas_falha
  FROM (SELECT (SELECT SUM(qtd_itens_venda) FROM `vanguardamartech_refined`.`rfn_financeiro__operacao_resumo`) AS a, (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_contazul__venda_item`) AS b)
  UNION ALL
  SELECT 'rfn_financeiro__operacao_resumo.razao_reproduz_o_movimento' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__operacao_resumo' AS tabela, 'Financeiro' AS sistema,
         'INTEGRIDADE' AS dimensao, 'soma de qtd_parcelas_razao_vigentes reproduz as parcelas vigentes de trs_contazul__movimento' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         1 AS linhas_avaliadas, IF(IFNULL(a,-1e18) = IFNULL(b,-1e18), 0, 1) AS linhas_falha
  FROM (SELECT (SELECT SUM(qtd_parcelas_razao_vigentes) FROM `vanguardamartech_refined`.`rfn_financeiro__operacao_resumo`) AS a, (SELECT COUNTIF(is_vigente) FROM `vanguardamartech_trusted`.`trs_contazul__movimento`) AS b)
  UNION ALL
  SELECT 'rfn_financeiro__operacao_resumo.operacao_vista_esta_no_cadastro' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__operacao_resumo' AS tabela, 'Financeiro' AS sistema,
         'INTEGRIDADE' AS dimensao, 'todo codigo de operacao visto nas tabelas esta no cadastro (linha de base: 3 de 4 em 19/10; VGD-BRM fora)' AS regra, 'ALERTA' AS severidade, 0.700 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNTIF(flag_operacao_nao_catalogada) AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_financeiro__operacao_resumo`
  UNION ALL
  SELECT 'financeiro_dimensoes.carga_do_mesmo_dia' AS id_regra, 'Refined' AS camada, '(as 11 Refined da familia)' AS tabela, 'Financeiro' AS sistema,
         'VALIDADE' AS dimensao, 'as 11 Refined foram escritas na mesma passada' AS regra, 'BLOQUEANTE' AS severidade, 1.000 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNTIF(d <> (SELECT MAX(d) FROM carga)) AS linhas_falha
  FROM carga
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
  'Financeiro (dimensoes)'                      AS familia,
  CURRENT_TIMESTAMP()                           AS _extraido_at,
  'multiplas'                                   AS _fonte,
  'America/Sao_Paulo'                           AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(a)))                AS _payload_hash
FROM avaliado a
