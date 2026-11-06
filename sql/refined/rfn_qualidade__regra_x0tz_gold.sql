-- rfn_qualidade__regra_x0tz_gold  ·  64 regras  ·  L2 INTERNAL
-- Refined / qualidade. Grao: uma REGRA de qualidade em uma execucao. Chave: id_regra (a execucao se le em _extraido_at).
-- Cobre as 24 Trusted e as 11 Refined do lote x0tz gold/meta/conta_azul de 18/10/2026 (trs_contazul__*, trs_financeiro__*, trs_rh__*, trs_vbot__*,
-- rfn_financeiro__{funil_faturamento,contazul_vendas_mensal,contazul_mrr_mensal,programacao_diaria,dre_gerencial_mensal,mov_classif_mensal,
-- dre_cliente_janela,caixa_bancario_mensal,margem_vbot_mensal}, rfn_rh__{turnover_mensal,recrutamento_vaga}).
-- Gatilho: cron semanal segunda 08:00 America/Manaus, DEPOIS das Trusted (segunda 06:00) e das Refined em cadeia de evento: a suite e um gate de pos-carga
--   e a regra de frescor acusa Refined que ficou na passada anterior. Nao usa evento 'all' sobre 11 ramos: uma falha num ramo impediria as 64 regras.
-- Contrato de colunas identico ao das outras suites (UNION ALL dá o painel unico; `familia` = X0TZ_GOLD).
-- 35 chaves unicas (24 Trusted + 11 Refined) · 20 identidades Trusted x Refined (a Refined agrega e nao filtra: soma reproduz a Trusted) · 7 regras de validade/integridade
-- · 1 linha de base de ALERTA (funil: parcela com pessoa encontra a pessoa, 1.809 de 1.809 em 18/10, limiar 0,98) · 1 frescor.
-- VALIDACAO (18/10/2026): as tabelas novas ainda nao materializaram, entao cada familia foi rodada com o codigo de cada Trusted e Refined INLINE sobre a Raw
--   (mesma logica dos arquivos de sql/trusted e sql/refined): Conta Azul 22 de 22 CONFORME · Financeiro 23 de 23 · RH 10 de 10 · VBOT 8 de 8; frescor testado com datas
--   sinteticas (1 falha em 3, como esperado). A suite inteira so roda de fato depois da primeira passada agendada; esperado: 64 conformes.
-- LIMITES: nao mede conteudo de negocio (so chave, identidade e forma); o grao de cada Refined esta na descricao da propria transformacao.
WITH
c AS (SELECT MAX(DATE(_extraido_at)) AS d FROM `vanguardamartech_refined`.`rfn_financeiro__funil_faturamento` UNION ALL SELECT MAX(DATE(_extraido_at)) AS d FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_vendas_mensal` UNION ALL SELECT MAX(DATE(_extraido_at)) AS d FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_mrr_mensal` UNION ALL SELECT MAX(DATE(_extraido_at)) AS d FROM `vanguardamartech_refined`.`rfn_financeiro__programacao_diaria` UNION ALL SELECT MAX(DATE(_extraido_at)) AS d FROM `vanguardamartech_refined`.`rfn_financeiro__dre_gerencial_mensal` UNION ALL SELECT MAX(DATE(_extraido_at)) AS d FROM `vanguardamartech_refined`.`rfn_financeiro__mov_classif_mensal` UNION ALL SELECT MAX(DATE(_extraido_at)) AS d FROM `vanguardamartech_refined`.`rfn_financeiro__dre_cliente_janela` UNION ALL SELECT MAX(DATE(_extraido_at)) AS d FROM `vanguardamartech_refined`.`rfn_financeiro__caixa_bancario_mensal` UNION ALL SELECT MAX(DATE(_extraido_at)) AS d FROM `vanguardamartech_refined`.`rfn_rh__turnover_mensal` UNION ALL SELECT MAX(DATE(_extraido_at)) AS d FROM `vanguardamartech_refined`.`rfn_rh__recrutamento_vaga` UNION ALL SELECT MAX(DATE(_extraido_at)) AS d FROM `vanguardamartech_refined`.`rfn_financeiro__margem_vbot_mensal`),
r_ca AS (
-- CONTA AZUL (10 Trusted + 3 Refined)
  SELECT 'trs_contazul__pessoa.chave_unica' AS id_regra, 'Trusted' AS camada, 'trs_contazul__pessoa' AS tabela, 'Conta Azul' AS sistema, 'UNICIDADE' AS dimensao,
         'a chave (id_pessoa) e unica e nunca nula' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_pessoa) + COUNTIF(id_pessoa IS NULL) AS linhas_falha
  FROM `vanguardamartech_trusted`.`trs_contazul__pessoa`

  UNION ALL
  SELECT 'trs_contazul__funil_faturamento.chave_unica' AS id_regra, 'Trusted' AS camada, 'trs_contazul__funil_faturamento' AS tabela, 'Conta Azul' AS sistema, 'UNICIDADE' AS dimensao,
         'a chave (id_parcela) e unica e nunca nula' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_parcela) + COUNTIF(id_parcela IS NULL) AS linhas_falha
  FROM `vanguardamartech_trusted`.`trs_contazul__funil_faturamento`

  UNION ALL
  SELECT 'trs_contazul__venda.chave_unica' AS id_regra, 'Trusted' AS camada, 'trs_contazul__venda' AS tabela, 'Conta Azul' AS sistema, 'UNICIDADE' AS dimensao,
         'a chave (id_venda) e unica e nunca nula' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_venda) + COUNTIF(id_venda IS NULL) AS linhas_falha
  FROM `vanguardamartech_trusted`.`trs_contazul__venda`

  UNION ALL
  SELECT 'trs_contazul__venda_item.chave_unica' AS id_regra, 'Trusted' AS camada, 'trs_contazul__venda_item' AS tabela, 'Conta Azul' AS sistema, 'UNICIDADE' AS dimensao,
         'a chave (id_venda_item) e unica e nunca nula' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_venda_item) + COUNTIF(id_venda_item IS NULL) AS linhas_falha
  FROM `vanguardamartech_trusted`.`trs_contazul__venda_item`

  UNION ALL
  SELECT 'trs_contazul__nota_fiscal.chave_unica' AS id_regra, 'Trusted' AS camada, 'trs_contazul__nota_fiscal' AS tabela, 'Conta Azul' AS sistema, 'UNICIDADE' AS dimensao,
         'a chave (id_nota) e unica e nunca nula' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_nota) + COUNTIF(id_nota IS NULL) AS linhas_falha
  FROM `vanguardamartech_trusted`.`trs_contazul__nota_fiscal`

  UNION ALL
  SELECT 'trs_contazul__contrato.chave_unica' AS id_regra, 'Trusted' AS camada, 'trs_contazul__contrato' AS tabela, 'Conta Azul' AS sistema, 'UNICIDADE' AS dimensao,
         'a chave (id_contrato) e unica e nunca nula' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_contrato) + COUNTIF(id_contrato IS NULL) AS linhas_falha
  FROM `vanguardamartech_trusted`.`trs_contazul__contrato`

  UNION ALL
  SELECT 'trs_contazul__mrr_snapshot.chave_unica' AS id_regra, 'Trusted' AS camada, 'trs_contazul__mrr_snapshot' AS tabela, 'Conta Azul' AS sistema, 'UNICIDADE' AS dimensao,
         'a chave (id_snapshot) e unica e nunca nula' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_snapshot) + COUNTIF(id_snapshot IS NULL) AS linhas_falha
  FROM `vanguardamartech_trusted`.`trs_contazul__mrr_snapshot`

  UNION ALL
  SELECT 'trs_contazul__transferencia.chave_unica' AS id_regra, 'Trusted' AS camada, 'trs_contazul__transferencia' AS tabela, 'Conta Azul' AS sistema, 'UNICIDADE' AS dimensao,
         'a chave (id_transferencia) e unica e nunca nula' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_transferencia) + COUNTIF(id_transferencia IS NULL) AS linhas_falha
  FROM `vanguardamartech_trusted`.`trs_contazul__transferencia`

  UNION ALL
  SELECT 'trs_contazul__apoio.chave_unica' AS id_regra, 'Trusted' AS camada, 'trs_contazul__apoio' AS tabela, 'Conta Azul' AS sistema, 'UNICIDADE' AS dimensao,
         'a chave (origem e id_apoio) e unica e nunca nula' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT CONCAT(origem, '|', CAST(id_apoio AS STRING))) + COUNTIF(CONCAT(origem, '|', CAST(id_apoio AS STRING)) IS NULL) AS linhas_falha
  FROM `vanguardamartech_trusted`.`trs_contazul__apoio`

  UNION ALL
  SELECT 'trs_contazul__saldo_posicao.chave_unica' AS id_regra, 'Trusted' AS camada, 'trs_contazul__saldo_posicao' AS tabela, 'Conta Azul' AS sistema, 'UNICIDADE' AS dimensao,
         'a chave (id_linha) e unica e nunca nula' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_linha) + COUNTIF(id_linha IS NULL) AS linhas_falha
  FROM `vanguardamartech_trusted`.`trs_contazul__saldo_posicao`

  UNION ALL
  SELECT 'rfn_financeiro__funil_faturamento.chave_unica' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__funil_faturamento' AS tabela, 'Conta Azul' AS sistema, 'UNICIDADE' AS dimensao,
         'a chave (id_funil_mensal) e unica e nunca nula' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_funil_mensal) + COUNTIF(id_funil_mensal IS NULL) AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_financeiro__funil_faturamento`

  UNION ALL
  SELECT 'rfn_financeiro__contazul_vendas_mensal.chave_unica' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__contazul_vendas_mensal' AS tabela, 'Conta Azul' AS sistema, 'UNICIDADE' AS dimensao,
         'a chave (id_vendas_mensal) e unica e nunca nula' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_vendas_mensal) + COUNTIF(id_vendas_mensal IS NULL) AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_vendas_mensal`

  UNION ALL
  SELECT 'rfn_financeiro__contazul_mrr_mensal.chave_unica' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__contazul_mrr_mensal' AS tabela, 'Conta Azul' AS sistema, 'UNICIDADE' AS dimensao,
         'a chave (id_mrr_mensal) e unica e nunca nula' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_mrr_mensal) + COUNTIF(id_mrr_mensal IS NULL) AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_mrr_mensal`

  UNION ALL
  SELECT 'rfn_financeiro__funil_faturamento.parcelas_reproduzem_a_trusted', 'Refined', 'rfn_financeiro__funil_faturamento', 'Conta Azul', 'VALIDADE',
         'a soma de qtd_parcelas reproduz as parcelas da Trusted', 'BLOQUEANTE', 1.00,
         1,
         IF(ABS(IFNULL((SELECT SUM(qtd_parcelas) FROM `vanguardamartech_refined`.`rfn_financeiro__funil_faturamento`), 0) - IFNULL((SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_contazul__funil_faturamento`), 0)) <= 0, 0, 1)

  UNION ALL
  SELECT 'rfn_financeiro__funil_faturamento.valor_reproduz_a_trusted', 'Refined', 'rfn_financeiro__funil_faturamento', 'Conta Azul', 'VALIDADE',
         'a soma de valor reproduz o valor da Trusted (um centavo)', 'BLOQUEANTE', 1.00,
         1,
         IF(ABS(IFNULL((SELECT SUM(valor) FROM `vanguardamartech_refined`.`rfn_financeiro__funil_faturamento`), 0) - IFNULL((SELECT SUM(valor) FROM `vanguardamartech_trusted`.`trs_contazul__funil_faturamento`), 0)) <= 0.01, 0, 1)

  UNION ALL
  SELECT 'rfn_financeiro__contazul_vendas_mensal.registros_reproduzem_a_trusted', 'Refined', 'rfn_financeiro__contazul_vendas_mensal', 'Conta Azul', 'VALIDADE',
         'a soma de qtd_registros reproduz vendas mais notas da Trusted', 'BLOQUEANTE', 1.00,
         1,
         IF(ABS(IFNULL((SELECT SUM(qtd_registros) FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_vendas_mensal`), 0) - IFNULL((SELECT (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_contazul__venda`) + (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_contazul__nota_fiscal`)), 0)) <= 0, 0, 1)

  UNION ALL
  SELECT 'rfn_financeiro__contazul_vendas_mensal.valor_reproduz_a_trusted', 'Refined', 'rfn_financeiro__contazul_vendas_mensal', 'Conta Azul', 'VALIDADE',
         'a soma de valor reproduz venda mais nota fiscal da Trusted (um centavo)', 'BLOQUEANTE', 1.00,
         1,
         IF(ABS(IFNULL((SELECT SUM(valor) FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_vendas_mensal`), 0) - IFNULL((SELECT (SELECT SUM(valor_total) FROM `vanguardamartech_trusted`.`trs_contazul__venda`) + (SELECT SUM(valor) FROM `vanguardamartech_trusted`.`trs_contazul__nota_fiscal`)), 0)) <= 0.01, 0, 1)

  UNION ALL
  SELECT 'rfn_financeiro__contazul_mrr_mensal.contratos_reproduzem_a_trusted', 'Refined', 'rfn_financeiro__contazul_mrr_mensal', 'Conta Azul', 'VALIDADE',
         'a soma de qtd_contratos reproduz os contratos ativos do snapshot', 'BLOQUEANTE', 1.00,
         1,
         IF(ABS(IFNULL((SELECT SUM(qtd_contratos) FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_mrr_mensal`), 0) - IFNULL((SELECT COUNTIF(is_ativo) FROM `vanguardamartech_trusted`.`trs_contazul__mrr_snapshot`), 0)) <= 0, 0, 1)

  UNION ALL
  SELECT 'rfn_financeiro__contazul_mrr_mensal.mrr_reproduz_a_trusted', 'Refined', 'rfn_financeiro__contazul_mrr_mensal', 'Conta Azul', 'VALIDADE',
         'a soma de mrr reproduz o MRR dos contratos ativos (um centavo)', 'BLOQUEANTE', 1.00,
         1,
         IF(ABS(IFNULL((SELECT SUM(mrr) FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_mrr_mensal`), 0) - IFNULL((SELECT SUM(IF(is_ativo, mrr, 0)) FROM `vanguardamartech_trusted`.`trs_contazul__mrr_snapshot`), 0)) <= 0.01, 0, 1)

  UNION ALL
  SELECT 'trs_contazul__venda_item.venda_existe', 'Trusted', 'trs_contazul__venda_item', 'Conta Azul', 'INTEGRIDADE',
         'todo item de venda encontra a venda', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(v.id_venda IS NULL)
  FROM `vanguardamartech_trusted`.`trs_contazul__venda_item` i LEFT JOIN (SELECT DISTINCT id_venda FROM `vanguardamartech_trusted`.`trs_contazul__venda`) v ON v.id_venda = i.id_venda

  UNION ALL
  SELECT 'trs_contazul__venda.vigente_e_o_oposto_de_removida', 'Trusted', 'trs_contazul__venda', 'Conta Azul', 'VALIDADE',
         'is_vigente e exatamente o oposto de is_removido', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(IFNULL(is_vigente, FALSE) = IFNULL(is_removido, FALSE))
  FROM `vanguardamartech_trusted`.`trs_contazul__venda`

  UNION ALL
  SELECT 'trs_contazul__funil_faturamento.pessoa_catalogada', 'Trusted', 'trs_contazul__funil_faturamento', 'Conta Azul', 'INTEGRIDADE',
         'parcela com pessoa encontra a pessoa no cadastro (linha de base: 1.809 de 1.809 em 18/10)', 'ALERTA', 0.98,
         COUNTIF(f.id_pessoa IS NOT NULL),
         COUNTIF(f.id_pessoa IS NOT NULL AND p.id_pessoa IS NULL)
  FROM `vanguardamartech_trusted`.`trs_contazul__funil_faturamento` f LEFT JOIN (SELECT DISTINCT id_pessoa FROM `vanguardamartech_trusted`.`trs_contazul__pessoa`) p ON p.id_pessoa = f.id_pessoa
),
r_fi AS (
-- FINANCEIRO (7 Trusted + 5 Refined)
  SELECT 'trs_financeiro__programacao_snapshot.chave_unica' AS id_regra, 'Trusted' AS camada, 'trs_financeiro__programacao_snapshot' AS tabela, 'Financeiro' AS sistema, 'UNICIDADE' AS dimensao,
         'a chave (id_snapshot_parcela) e unica e nunca nula' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_snapshot_parcela) + COUNTIF(id_snapshot_parcela IS NULL) AS linhas_falha
  FROM `vanguardamartech_trusted`.`trs_financeiro__programacao_snapshot`

  UNION ALL
  SELECT 'trs_financeiro__mov_classif.chave_unica' AS id_regra, 'Trusted' AS camada, 'trs_financeiro__mov_classif' AS tabela, 'Financeiro' AS sistema, 'UNICIDADE' AS dimensao,
         'a chave (id_linha) e unica e nunca nula' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_linha) + COUNTIF(id_linha IS NULL) AS linhas_falha
  FROM `vanguardamartech_trusted`.`trs_financeiro__mov_classif`

  UNION ALL
  SELECT 'trs_financeiro__dre_lancamento.chave_unica' AS id_regra, 'Trusted' AS camada, 'trs_financeiro__dre_lancamento' AS tabela, 'Financeiro' AS sistema, 'UNICIDADE' AS dimensao,
         'a chave (id_linha) e unica e nunca nula' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_linha) + COUNTIF(id_linha IS NULL) AS linhas_falha
  FROM `vanguardamartech_trusted`.`trs_financeiro__dre_lancamento`

  UNION ALL
  SELECT 'trs_financeiro__dre_cliente.chave_unica' AS id_regra, 'Trusted' AS camada, 'trs_financeiro__dre_cliente' AS tabela, 'Financeiro' AS sistema, 'UNICIDADE' AS dimensao,
         'a chave (id_linha) e unica e nunca nula' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_linha) + COUNTIF(id_linha IS NULL) AS linhas_falha
  FROM `vanguardamartech_trusted`.`trs_financeiro__dre_cliente`

  UNION ALL
  SELECT 'trs_financeiro__extrato_conta_mes.chave_unica' AS id_regra, 'Trusted' AS camada, 'trs_financeiro__extrato_conta_mes' AS tabela, 'Financeiro' AS sistema, 'UNICIDADE' AS dimensao,
         'a chave (id_conta_periodo) e unica e nunca nula' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_conta_periodo) + COUNTIF(id_conta_periodo IS NULL) AS linhas_falha
  FROM `vanguardamartech_trusted`.`trs_financeiro__extrato_conta_mes`

  UNION ALL
  SELECT 'trs_financeiro__extrato_sweep.chave_unica' AS id_regra, 'Trusted' AS camada, 'trs_financeiro__extrato_sweep' AS tabela, 'Financeiro' AS sistema, 'UNICIDADE' AS dimensao,
         'a chave (id_linha) e unica e nunca nula' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_linha) + COUNTIF(id_linha IS NULL) AS linhas_falha
  FROM `vanguardamartech_trusted`.`trs_financeiro__extrato_sweep`

  UNION ALL
  SELECT 'trs_financeiro__dicionario.chave_unica' AS id_regra, 'Trusted' AS camada, 'trs_financeiro__dicionario' AS tabela, 'Financeiro' AS sistema, 'UNICIDADE' AS dimensao,
         'a chave (id_linha) e unica e nunca nula' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_linha) + COUNTIF(id_linha IS NULL) AS linhas_falha
  FROM `vanguardamartech_trusted`.`trs_financeiro__dicionario`

  UNION ALL
  SELECT 'rfn_financeiro__programacao_diaria.chave_unica' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__programacao_diaria' AS tabela, 'Financeiro' AS sistema, 'UNICIDADE' AS dimensao,
         'a chave (id_programacao_diaria) e unica e nunca nula' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_programacao_diaria) + COUNTIF(id_programacao_diaria IS NULL) AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_financeiro__programacao_diaria`

  UNION ALL
  SELECT 'rfn_financeiro__dre_gerencial_mensal.chave_unica' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__dre_gerencial_mensal' AS tabela, 'Financeiro' AS sistema, 'UNICIDADE' AS dimensao,
         'a chave (id_dre_mensal) e unica e nunca nula' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_dre_mensal) + COUNTIF(id_dre_mensal IS NULL) AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_financeiro__dre_gerencial_mensal`

  UNION ALL
  SELECT 'rfn_financeiro__mov_classif_mensal.chave_unica' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__mov_classif_mensal' AS tabela, 'Financeiro' AS sistema, 'UNICIDADE' AS dimensao,
         'a chave (id_mov_mensal) e unica e nunca nula' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_mov_mensal) + COUNTIF(id_mov_mensal IS NULL) AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_financeiro__mov_classif_mensal`

  UNION ALL
  SELECT 'rfn_financeiro__dre_cliente_janela.chave_unica' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__dre_cliente_janela' AS tabela, 'Financeiro' AS sistema, 'UNICIDADE' AS dimensao,
         'a chave (id_dre_janela) e unica e nunca nula' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_dre_janela) + COUNTIF(id_dre_janela IS NULL) AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_financeiro__dre_cliente_janela`

  UNION ALL
  SELECT 'rfn_financeiro__caixa_bancario_mensal.chave_unica' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__caixa_bancario_mensal' AS tabela, 'Financeiro' AS sistema, 'UNICIDADE' AS dimensao,
         'a chave (id_caixa_mensal) e unica e nunca nula' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_caixa_mensal) + COUNTIF(id_caixa_mensal IS NULL) AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_financeiro__caixa_bancario_mensal`

  UNION ALL
  SELECT 'rfn_financeiro__programacao_diaria.linhas_reproduzem_a_trusted', 'Refined', 'rfn_financeiro__programacao_diaria', 'Financeiro', 'VALIDADE',
         'a soma de qtd_parcelas reproduz as linhas da Trusted', 'BLOQUEANTE', 1.00,
         1,
         IF(ABS(IFNULL((SELECT SUM(qtd_parcelas) FROM `vanguardamartech_refined`.`rfn_financeiro__programacao_diaria`), 0) - IFNULL((SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_financeiro__programacao_snapshot`), 0)) <= 0, 0, 1)

  UNION ALL
  SELECT 'rfn_financeiro__programacao_diaria.valor_reproduz_a_trusted', 'Refined', 'rfn_financeiro__programacao_diaria', 'Financeiro', 'VALIDADE',
         'a soma de valor reproduz o valor da Trusted (um centavo)', 'BLOQUEANTE', 1.00,
         1,
         IF(ABS(IFNULL((SELECT SUM(valor) FROM `vanguardamartech_refined`.`rfn_financeiro__programacao_diaria`), 0) - IFNULL((SELECT SUM(valor) FROM `vanguardamartech_trusted`.`trs_financeiro__programacao_snapshot`), 0)) <= 0.01, 0, 1)

  UNION ALL
  SELECT 'rfn_financeiro__dre_gerencial_mensal.linhas_reproduzem_a_trusted', 'Refined', 'rfn_financeiro__dre_gerencial_mensal', 'Financeiro', 'VALIDADE',
         'a soma de qtd_lancamentos reproduz as linhas da Trusted', 'BLOQUEANTE', 1.00,
         1,
         IF(ABS(IFNULL((SELECT SUM(qtd_lancamentos) FROM `vanguardamartech_refined`.`rfn_financeiro__dre_gerencial_mensal`), 0) - IFNULL((SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_financeiro__dre_lancamento`), 0)) <= 0, 0, 1)

  UNION ALL
  SELECT 'rfn_financeiro__dre_gerencial_mensal.valor_reproduz_a_trusted', 'Refined', 'rfn_financeiro__dre_gerencial_mensal', 'Financeiro', 'VALIDADE',
         'a soma de valor reproduz o valor da Trusted (um centavo)', 'BLOQUEANTE', 1.00,
         1,
         IF(ABS(IFNULL((SELECT SUM(valor) FROM `vanguardamartech_refined`.`rfn_financeiro__dre_gerencial_mensal`), 0) - IFNULL((SELECT SUM(valor) FROM `vanguardamartech_trusted`.`trs_financeiro__dre_lancamento`), 0)) <= 0.01, 0, 1)

  UNION ALL
  SELECT 'rfn_financeiro__mov_classif_mensal.linhas_reproduzem_a_trusted', 'Refined', 'rfn_financeiro__mov_classif_mensal', 'Financeiro', 'VALIDADE',
         'a soma de qtd_lancamentos reproduz as linhas da Trusted', 'BLOQUEANTE', 1.00,
         1,
         IF(ABS(IFNULL((SELECT SUM(qtd_lancamentos) FROM `vanguardamartech_refined`.`rfn_financeiro__mov_classif_mensal`), 0) - IFNULL((SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_financeiro__mov_classif`), 0)) <= 0, 0, 1)

  UNION ALL
  SELECT 'rfn_financeiro__mov_classif_mensal.valor_reproduz_a_trusted', 'Refined', 'rfn_financeiro__mov_classif_mensal', 'Financeiro', 'VALIDADE',
         'a soma de valor reproduz o valor da Trusted (um centavo)', 'BLOQUEANTE', 1.00,
         1,
         IF(ABS(IFNULL((SELECT SUM(valor) FROM `vanguardamartech_refined`.`rfn_financeiro__mov_classif_mensal`), 0) - IFNULL((SELECT SUM(valor) FROM `vanguardamartech_trusted`.`trs_financeiro__mov_classif`), 0)) <= 0.01, 0, 1)

  UNION ALL
  SELECT 'rfn_financeiro__dre_cliente_janela.meses_reproduzem_a_trusted', 'Refined', 'rfn_financeiro__dre_cliente_janela', 'Financeiro', 'VALIDADE',
         'meses na janela mais meses futuros excluidos reproduzem as linhas da Trusted', 'BLOQUEANTE', 1.00,
         1,
         IF(ABS(IFNULL((SELECT SUM(qtd_meses_na_janela) + SUM(qtd_meses_futuros_excluidos) FROM `vanguardamartech_refined`.`rfn_financeiro__dre_cliente_janela`), 0) - IFNULL((SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_financeiro__dre_cliente`), 0)) <= 0, 0, 1)

  UNION ALL
  SELECT 'rfn_financeiro__dre_cliente_janela.receita_reproduz_a_trusted', 'Refined', 'rfn_financeiro__dre_cliente_janela', 'Financeiro', 'VALIDADE',
         'a soma de receita_total na janela reproduz a Trusted ate o mes da carga (um centavo)', 'BLOQUEANTE', 1.00,
         1,
         IF(ABS(IFNULL((SELECT SUM(receita_total) FROM `vanguardamartech_refined`.`rfn_financeiro__dre_cliente_janela`), 0) - IFNULL((SELECT SUM(IF(mes_referencia <= DATE_TRUNC(DATE(_extraido_at), MONTH), receita_total, NULL)) FROM `vanguardamartech_trusted`.`trs_financeiro__dre_cliente`), 0)) <= 0.01, 0, 1)

  UNION ALL
  SELECT 'rfn_financeiro__caixa_bancario_mensal.contas_reproduzem_a_trusted', 'Refined', 'rfn_financeiro__caixa_bancario_mensal', 'Financeiro', 'VALIDADE',
         'a soma de qtd_contas reproduz as linhas conta-mes da Trusted', 'BLOQUEANTE', 1.00,
         1,
         IF(ABS(IFNULL((SELECT SUM(qtd_contas) FROM `vanguardamartech_refined`.`rfn_financeiro__caixa_bancario_mensal`), 0) - IFNULL((SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_financeiro__extrato_conta_mes`), 0)) <= 0, 0, 1)

  UNION ALL
  SELECT 'rfn_financeiro__caixa_bancario_mensal.lancamentos_reproduzem_a_trusted', 'Refined', 'rfn_financeiro__caixa_bancario_mensal', 'Financeiro', 'VALIDADE',
         'a soma de n_lancamentos reproduz a Trusted', 'BLOQUEANTE', 1.00,
         1,
         IF(ABS(IFNULL((SELECT SUM(n_lancamentos) FROM `vanguardamartech_refined`.`rfn_financeiro__caixa_bancario_mensal`), 0) - IFNULL((SELECT SUM(n_lancamentos) FROM `vanguardamartech_trusted`.`trs_financeiro__extrato_conta_mes`), 0)) <= 0, 0, 1)

  UNION ALL
  SELECT 'trs_financeiro__programacao_snapshot.dia_conta_todas_as_parcelas', 'Trusted', 'trs_financeiro__programacao_snapshot', 'Financeiro', 'VALIDADE',
         'em cada dia do snapshot as linhas lidas reproduzem qtd_parcelas_no_snapshot', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(n <> q)
  FROM (SELECT snapshot_date, COUNT(*) AS n, ANY_VALUE(qtd_parcelas_no_snapshot) AS q FROM `vanguardamartech_trusted`.`trs_financeiro__programacao_snapshot` GROUP BY snapshot_date)
),
r_rh AS (
-- RH (4 Trusted + 2 Refined)
  SELECT 'trs_rh__colaborador_mes.chave_unica' AS id_regra, 'Trusted' AS camada, 'trs_rh__colaborador_mes' AS tabela, 'RH' AS sistema, 'UNICIDADE' AS dimensao,
         'a chave (id_pessoa_mes) e unica e nunca nula' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_pessoa_mes) + COUNTIF(id_pessoa_mes IS NULL) AS linhas_falha
  FROM `vanguardamartech_trusted`.`trs_rh__colaborador_mes`

  UNION ALL
  SELECT 'trs_rh__pessoa.chave_unica' AS id_regra, 'Trusted' AS camada, 'trs_rh__pessoa' AS tabela, 'RH' AS sistema, 'UNICIDADE' AS dimensao,
         'a chave (email) e unica e nunca nula' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT email) + COUNTIF(email IS NULL) AS linhas_falha
  FROM `vanguardamartech_trusted`.`trs_rh__pessoa`

  UNION ALL
  SELECT 'trs_rh__desligamento.chave_unica' AS id_regra, 'Trusted' AS camada, 'trs_rh__desligamento' AS tabela, 'RH' AS sistema, 'UNICIDADE' AS dimensao,
         'a chave (email) e unica e nunca nula' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT email) + COUNTIF(email IS NULL) AS linhas_falha
  FROM `vanguardamartech_trusted`.`trs_rh__desligamento`

  UNION ALL
  SELECT 'trs_rh__recrutamento.chave_unica' AS id_regra, 'Trusted' AS camada, 'trs_rh__recrutamento' AS tabela, 'RH' AS sistema, 'UNICIDADE' AS dimensao,
         'a chave (id_linha) e unica e nunca nula' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_linha) + COUNTIF(id_linha IS NULL) AS linhas_falha
  FROM `vanguardamartech_trusted`.`trs_rh__recrutamento`

  UNION ALL
  SELECT 'rfn_rh__turnover_mensal.chave_unica' AS id_regra, 'Refined' AS camada, 'rfn_rh__turnover_mensal' AS tabela, 'RH' AS sistema, 'UNICIDADE' AS dimensao,
         'a chave (id_turnover_mensal) e unica e nunca nula' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_turnover_mensal) + COUNTIF(id_turnover_mensal IS NULL) AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_rh__turnover_mensal`

  UNION ALL
  SELECT 'rfn_rh__recrutamento_vaga.chave_unica' AS id_regra, 'Refined' AS camada, 'rfn_rh__recrutamento_vaga' AS tabela, 'RH' AS sistema, 'UNICIDADE' AS dimensao,
         'a chave (job_id) e unica e nunca nula' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT job_id) + COUNTIF(job_id IS NULL) AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_rh__recrutamento_vaga`

  UNION ALL
  SELECT 'rfn_rh__recrutamento_vaga.aplicacoes_reproduzem_a_trusted', 'Refined', 'rfn_rh__recrutamento_vaga', 'RH', 'VALIDADE',
         'a soma de aplicacoes reproduz o recorte FUNIL_ETAPA da Trusted', 'BLOQUEANTE', 1.00,
         1,
         IF(ABS(IFNULL((SELECT SUM(aplicacoes) FROM `vanguardamartech_refined`.`rfn_rh__recrutamento_vaga`), 0) - IFNULL((SELECT SUM(qtd_aplicacoes) FROM `vanguardamartech_trusted`.`trs_rh__recrutamento` WHERE origem = 'FUNIL_ETAPA'), 0)) <= 0, 0, 1)

  UNION ALL
  SELECT 'rfn_rh__recrutamento_vaga.vagas_reproduzem_a_trusted', 'Refined', 'rfn_rh__recrutamento_vaga', 'RH', 'VALIDADE',
         'uma linha por vaga: as vagas distintas da Trusted', 'BLOQUEANTE', 1.00,
         1,
         IF(ABS(IFNULL((SELECT COUNT(*) FROM `vanguardamartech_refined`.`rfn_rh__recrutamento_vaga`), 0) - IFNULL((SELECT COUNT(DISTINCT job_id) FROM `vanguardamartech_trusted`.`trs_rh__recrutamento`), 0)) <= 0, 0, 1)

  UNION ALL
  SELECT 'rfn_rh__turnover_mensal.headcount_fecha', 'Refined', 'rfn_rh__turnover_mensal', 'RH', 'VALIDADE',
         'headcount de fim calculado reproduz o headcount de fim medido na base', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(headcount_fim <> headcount_fim_medido)
  FROM `vanguardamartech_refined`.`rfn_rh__turnover_mensal`

  UNION ALL
  SELECT 'trs_rh__recrutamento.origem_conhecida', 'Trusted', 'trs_rh__recrutamento', 'RH', 'VALIDADE',
         'a origem e um dos quatro recortes (FUNIL_ETAPA, TEMPO_CONTRATACAO, CANDIDATURA_ABERTA, CONTRATACAO)', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(origem IS NULL OR origem NOT IN ('FUNIL_ETAPA', 'TEMPO_CONTRATACAO', 'CANDIDATURA_ABERTA', 'CONTRATACAO'))
  FROM `vanguardamartech_trusted`.`trs_rh__recrutamento`
),
r_vb AS (
-- VBOT (3 Trusted + 1 Refined)
  SELECT 'trs_vbot__margem_cliente.chave_unica' AS id_regra, 'Trusted' AS camada, 'trs_vbot__margem_cliente' AS tabela, 'VBOT' AS sistema, 'UNICIDADE' AS dimensao,
         'a chave (id_linha) e unica e nunca nula' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_linha) + COUNTIF(id_linha IS NULL) AS linhas_falha
  FROM `vanguardamartech_trusted`.`trs_vbot__margem_cliente`

  UNION ALL
  SELECT 'trs_vbot__conta_mes.chave_unica' AS id_regra, 'Trusted' AS camada, 'trs_vbot__conta_mes' AS tabela, 'VBOT' AS sistema, 'UNICIDADE' AS dimensao,
         'a chave (id_conta_mes) e unica e nunca nula' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_conta_mes) + COUNTIF(id_conta_mes IS NULL) AS linhas_falha
  FROM `vanguardamartech_trusted`.`trs_vbot__conta_mes`

  UNION ALL
  SELECT 'trs_vbot__mix_produto_mes.chave_unica' AS id_regra, 'Trusted' AS camada, 'trs_vbot__mix_produto_mes' AS tabela, 'VBOT' AS sistema, 'UNICIDADE' AS dimensao,
         'a chave (id_linha) e unica e nunca nula' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_linha) + COUNTIF(id_linha IS NULL) AS linhas_falha
  FROM `vanguardamartech_trusted`.`trs_vbot__mix_produto_mes`

  UNION ALL
  SELECT 'rfn_financeiro__margem_vbot_mensal.chave_unica' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__margem_vbot_mensal' AS tabela, 'VBOT' AS sistema, 'UNICIDADE' AS dimensao,
         'a chave (id_margem_mensal) e unica e nunca nula' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_margem_mensal) + COUNTIF(id_margem_mensal IS NULL) AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_financeiro__margem_vbot_mensal`

  UNION ALL
  SELECT 'rfn_financeiro__margem_vbot_mensal.receita_reproduz_a_trusted', 'Refined', 'rfn_financeiro__margem_vbot_mensal', 'VBOT', 'VALIDADE',
         'a soma de receita_conexa reproduz a Trusted (um centavo)', 'BLOQUEANTE', 1.00,
         1,
         IF(ABS(IFNULL((SELECT SUM(receita_conexa) FROM `vanguardamartech_refined`.`rfn_financeiro__margem_vbot_mensal`), 0) - IFNULL((SELECT SUM(receita_conexa) FROM `vanguardamartech_trusted`.`trs_vbot__margem_cliente`), 0)) <= 0.01, 0, 1)

  UNION ALL
  SELECT 'rfn_financeiro__margem_vbot_mensal.custo_reproduz_a_trusted', 'Refined', 'rfn_financeiro__margem_vbot_mensal', 'VBOT', 'VALIDADE',
         'a soma de custo_helena reproduz a Trusted (um centavo)', 'BLOQUEANTE', 1.00,
         1,
         IF(ABS(IFNULL((SELECT SUM(custo_helena) FROM `vanguardamartech_refined`.`rfn_financeiro__margem_vbot_mensal`), 0) - IFNULL((SELECT SUM(custo_helena) FROM `vanguardamartech_trusted`.`trs_vbot__margem_cliente`), 0)) <= 0.01, 0, 1)

  UNION ALL
  SELECT 'trs_vbot__margem_cliente.origem_match_conhecida', 'Trusted', 'trs_vbot__margem_cliente', 'VBOT', 'VALIDADE',
         'origem_match e uma das seis ligacoes conhecidas (a ligacao e por nome)', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(origem_match IS NULL OR origem_match NOT IN ('RAZAO', 'CURADORIA', 'FANTASIA', 'INTERNA', 'SEM MATCH', 'SO RECEITA'))
  FROM `vanguardamartech_trusted`.`trs_vbot__margem_cliente`

  UNION ALL
  SELECT 'trs_vbot__mix_produto_mes.tipo_conhecido', 'Trusted', 'trs_vbot__mix_produto_mes', 'VBOT', 'VALIDADE',
         'tipo e plano ou servico (entra na chave)', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(tipo IS NULL OR tipo NOT IN ('plano', 'servico'))
  FROM `vanguardamartech_trusted`.`trs_vbot__mix_produto_mes`
),
r_fr AS (
-- FRESCOR
  SELECT 'x0tz_gold.carga_do_mesmo_dia', 'Refined', 'rfn_x0tz_gold (11 tabelas)', 'supabase-x0tz', 'FRESCOR',
         'as 11 Refined foram escritas na mesma passada (mesma data de carga)', 'ALERTA', 1.00,
         COUNT(*),
         COUNTIF(d <> (SELECT MAX(d) FROM c))
  FROM (SELECT d FROM c)
),
todas AS (
  SELECT * FROM r_ca
  UNION ALL SELECT * FROM r_fi
  UNION ALL SELECT * FROM r_rh
  UNION ALL SELECT * FROM r_vb
  UNION ALL SELECT * FROM r_fr
),
avaliado AS (
  SELECT
    t.*,
    (t.linhas_avaliadas - t.linhas_falha)                       AS linhas_conformes,
    SAFE_DIVIDE(t.linhas_avaliadas - t.linhas_falha, NULLIF(t.linhas_avaliadas, 0))
                                                                AS taxa_conformidade,
    IF(t.linhas_avaliadas = 0, NULL,
       SAFE_DIVIDE(t.linhas_avaliadas - t.linhas_falha, t.linhas_avaliadas) >= t.limiar)
                                                                AS is_conforme,
    (t.linhas_avaliadas = 0)                                    AS flag_sem_linha_para_avaliar
  FROM todas t
),
final AS (
  SELECT
    a.*,
    CASE
      WHEN a.flag_sem_linha_para_avaliar          THEN 'SEM_DADO'
      WHEN a.is_conforme                          THEN 'CONFORME'
      WHEN a.severidade = 'BLOQUEANTE'            THEN 'FALHA_BLOQUEANTE'
      ELSE                                             'FALHA_ALERTA'
    END                                           AS resultado,
    'X0TZ_GOLD'                                   AS familia,
    CURRENT_TIMESTAMP()                           AS _extraido_at,
    'multiplas'                                   AS _fonte,
    'America/Sao_Paulo'                           AS _fuso,
    TO_HEX(MD5(TO_JSON_STRING(a)))                AS _payload_hash
  FROM avaliado a
)
SELECT * FROM final

