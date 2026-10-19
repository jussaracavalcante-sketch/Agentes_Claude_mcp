-- rfn_qualidade__regra_vbot_wl_simples  ·  query-ExE6  ·  69 regras  ·  L2 INTERNAL
-- Refined / qualidade. Grao: uma REGRA de qualidade em uma execucao. Chave: id_regra (a execucao se le em _extraido_at).
-- Gatilho: evento "all" em query-VAZA + query-nuwZ + query-xWNR + query-6Y5l + query-hJmB (as cinco Refined da frente H1). Alerta de falha ligado.
-- Familia VBOT white-label e Simples Nacional: 12 Trusted e 5 Refined. Primeira execucao real 19/10/2026 16:13Z: 69 regras, 69 ids, 56 BLOQUEANTE e 13 ALERTA, 69 CONFORME, zero falha.
-- CORRECAO DE REGISTRO: a primeira versao da descricao dizia que trs_custo_wl__*, o mix e o dominio ja tinham regra em outras suites. Conferido: so a fatura (x0tz_silver) e o mix (x0tz_gold) tinham;
-- trs_custo_wl__conta_mensal, trs_custo_wl__instancia_mensal e trs_conexa__dominio nao tinham nenhuma. O bloco r_extra (7 regras) cobre as tres.
-- NOTA: o codigo publicado na Nekt tem a mesma logica deste arquivo com menos comentarios SQL (os comentarios de bloco foram resumidos no deploy).
WITH u AS (SELECT * FROM `vanguardamartech_trusted`.`trs_vbot__uso_wl_conta_mes`),
c AS (SELECT * FROM `vanguardamartech_trusted`.`trs_vbot__consumo_wl_cliente_mes`),
p AS (SELECT * FROM `vanguardamartech_trusted`.`trs_vbot__preco_wl`),
cm AS (SELECT * FROM `vanguardamartech_trusted`.`trs_vbot__conta_mes`),
cw AS (SELECT * FROM `vanguardamartech_trusted`.`trs_custo_wl__conta_mensal`),
fa AS (SELECT * FROM `vanguardamartech_trusted`.`trs_custo_wl__fatura_mensal`),
mc AS (SELECT DISTINCT periodo, cliente_key FROM `vanguardamartech_trusted`.`trs_vbot__margem_cliente`),
fm AS (SELECT * FROM `vanguardamartech_trusted`.`trs_fiscal__simples_vbot_mes`),
fc AS (SELECT * FROM `vanguardamartech_trusted`.`trs_fiscal__simples_vbot_cliente_mes`),
fn AS (SELECT * FROM `vanguardamartech_trusted`.`trs_fiscal__simples_vbot_nf_mes`),
fe AS (SELECT * FROM `vanguardamartech_trusted`.`trs_fiscal__simples_vbot_nf_excecao`),
a3 AS (SELECT * FROM `vanguardamartech_trusted`.`trs_fiscal__simples_anexo3_faixa`),
rd AS (SELECT * FROM `vanguardamartech_trusted`.`trs_fiscal__simples_receita_declarada`),
cb AS (SELECT id_cobranca, is_vigente FROM `vanguardamartech_trusted`.`trs_conexa__cobranca`),
fe_p AS (
  SELECT periodo,
         COUNTIF(tipo_excecao = 'PAGO_SEM_NF') AS n_pago_sem,
         ROUND(SUM(IF(tipo_excecao = 'PAGO_SEM_NF', valor, 0)), 2) AS v_pago_sem,
         COUNTIF(tipo_excecao = 'ABERTO_SEM_NF') AS n_aberto,
         ROUND(SUM(IF(tipo_excecao = 'ABERTO_SEM_NF', valor, 0)), 2) AS v_aberto
  FROM fe GROUP BY periodo
),
rc AS (SELECT * FROM `vanguardamartech_refined`.`rfn_financeiro__custo_wl_mensal`),
rp AS (SELECT * FROM `vanguardamartech_refined`.`rfn_financeiro__preco_wl_resumo`),
rm AS (SELECT * FROM `vanguardamartech_refined`.`rfn_financeiro__mix_produto_vbot_mensal`),
rdm AS (SELECT * FROM `vanguardamartech_refined`.`rfn_operacao__conexa_dominio_resumo`),
rf AS (SELECT * FROM `vanguardamartech_refined`.`rfn_fiscal__simples_vbot_mensal`),
mx AS (SELECT * FROM `vanguardamartech_trusted`.`trs_vbot__mix_produto_mes`),
dm AS (SELECT * FROM `vanguardamartech_trusted`.`trs_conexa__dominio`),
ci AS (SELECT * FROM `vanguardamartech_trusted`.`trs_custo_wl__instancia_mensal`),

-- ------------------------------------------------------- TRUSTED VBOT WHITE-LABEL (16)
r_wl AS (
  SELECT 'trs_vbot__uso_wl_conta_mes.id_conta_mes_unico' AS id_regra, 'Trusted' AS camada, 'trs_vbot__uso_wl_conta_mes' AS tabela, 'VBOT' AS sistema, 'UNICIDADE' AS dimensao,
         'id_conta_mes (periodo|conta_key) e unico e nunca nulo' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_conta_mes) + COUNTIF(id_conta_mes IS NULL) AS linhas_falha
  FROM u
  UNION ALL
  SELECT 'trs_vbot__uso_wl_conta_mes.custo_reproduz_conta_mes', 'Trusted', 'trs_vbot__uso_wl_conta_mes', 'VBOT', 'INTEGRIDADE',
         'o custo_helena de cada conta-mes e o mesmo de trs_vbot__conta_mes (a conta existe e o valor bate ao centavo)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(m.conta_key IS NULL OR ABS(IFNULL(x.custo_helena, 0) - IFNULL(m.custo_helena, 0)) > 0.011)
  FROM u x LEFT JOIN cm m ON m.periodo = x.periodo AND m.conta_key = x.conta_key
  UNION ALL
  SELECT 'trs_vbot__uso_wl_conta_mes.conta_existe_no_custo_wl', 'Trusted', 'trs_vbot__uso_wl_conta_mes', 'VBOT', 'INTEGRIDADE',
         'toda conta-mes de uso existe no detalhe de fatura trs_custo_wl__conta_mensal', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(w.conta_key IS NULL)
  FROM u x LEFT JOIN cw w ON w.periodo = x.periodo AND w.conta_key = x.conta_key
  UNION ALL
  SELECT 'trs_vbot__uso_wl_conta_mes.periodo_tem_fatura', 'Trusted', 'trs_vbot__uso_wl_conta_mes', 'VBOT', 'INTEGRIDADE',
         'todo periodo de uso tem a fatura mensal do parceiro', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(f.periodo IS NULL)
  FROM u x LEFT JOIN fa f ON f.periodo = x.periodo
  UNION ALL
  SELECT 'trs_vbot__uso_wl_conta_mes.flag_sem_instancia_concorda', 'Trusted', 'trs_vbot__uso_wl_conta_mes', 'VBOT', 'VALIDADE',
         'flag_sem_instancia e exatamente instancia_dias = 0', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(IFNULL(flag_sem_instancia, FALSE) <> IFNULL(instancia_dias = 0, FALSE))
  FROM u
  UNION ALL
  SELECT 'trs_vbot__uso_wl_conta_mes.quantidades_nao_negativas', 'Trusted', 'trs_vbot__uso_wl_conta_mes', 'VBOT', 'VALIDADE',
         'usuarios, canais e instancia-dias nunca sao negativos', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(qtd_usuarios < 0 OR qtd_canais < 0 OR instancia_dias < 0)
  FROM u
  UNION ALL
  -- LINHA DE BASE: 569 de 572 (99,48%) trazem dias_de_contrato.
  SELECT 'trs_vbot__uso_wl_conta_mes.dias_de_contrato_preenchido', 'Trusted', 'trs_vbot__uso_wl_conta_mes', 'VBOT', 'COMPLETUDE',
         'a conta-mes carrega dias de contrato (NULL em 3 de 572 na origem)', 'ALERTA', 0.99,
         COUNT(*), COUNTIF(dias_de_contrato IS NULL)
  FROM u

  UNION ALL
  SELECT 'trs_vbot__consumo_wl_cliente_mes.id_cliente_mes_unico', 'Trusted', 'trs_vbot__consumo_wl_cliente_mes', 'VBOT', 'UNICIDADE',
         'id_cliente_mes (periodo|cliente_key) e unico e nunca nulo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_cliente_mes) + COUNTIF(id_cliente_mes IS NULL)
  FROM c
  UNION ALL
  SELECT 'trs_vbot__consumo_wl_cliente_mes.bruto_decompoe', 'Trusted', 'trs_vbot__consumo_wl_cliente_mes', 'VBOT', 'VALIDADE',
         'custo_bruto = licencas + transcricao + asaas + ia + instancias + infra (R$ 0,011)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(ABS(custo_bruto - (custo_licencas + custo_transcricao + custo_asaas + custo_ia + custo_instancias + custo_infra)) > 0.011)
  FROM c
  UNION ALL
  SELECT 'trs_vbot__consumo_wl_cliente_mes.apps_decompoe', 'Trusted', 'trs_vbot__consumo_wl_cliente_mes', 'VBOT', 'VALIDADE',
         'custo_apps = transcricao + asaas + ia', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(ABS(custo_apps - (custo_transcricao + custo_asaas + custo_ia)) > 0.011)
  FROM c
  UNION ALL
  SELECT 'trs_vbot__consumo_wl_cliente_mes.liquido_decompoe', 'Trusted', 'trs_vbot__consumo_wl_cliente_mes', 'VBOT', 'VALIDADE',
         'custo_liquido = custo_bruto + desconto_rateado + dominio_rateado', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(ABS(custo_liquido - (custo_bruto + desconto_rateado + dominio_rateado)) > 0.011)
  FROM c
  UNION ALL
  -- IDENTIDADE, GRAO PERIODO: o custo bruto por cliente fecha com o custo por conta.
  SELECT 'trs_vbot__consumo_wl_cliente_mes.bruto_fecha_com_o_custo_por_conta', 'Trusted', 'trs_vbot__consumo_wl_cliente_mes', 'VBOT', 'INTEGRIDADE',
         'por periodo, SUM(custo_bruto) por cliente = SUM(custo_helena) por conta (trs_vbot__conta_mes)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(ABS(a.b - IFNULL(z.h, -999999)) > 0.02)
  FROM (SELECT periodo, SUM(custo_bruto) AS b FROM c GROUP BY periodo) a
  LEFT JOIN (SELECT periodo, SUM(custo_helena) AS h FROM cm GROUP BY periodo) z USING (periodo)
  UNION ALL
  SELECT 'trs_vbot__consumo_wl_cliente_mes.cliente_existe_na_margem', 'Trusted', 'trs_vbot__consumo_wl_cliente_mes', 'VBOT', 'INTEGRIDADE',
         'todo cliente-mes de consumo existe em trs_vbot__margem_cliente', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(m.cliente_key IS NULL)
  FROM c x LEFT JOIN mc m ON m.periodo = x.periodo AND m.cliente_key = x.cliente_key
  UNION ALL
  SELECT 'trs_vbot__consumo_wl_cliente_mes.licenca_por_usuario_reproduz', 'Trusted', 'trs_vbot__consumo_wl_cliente_mes', 'VBOT', 'VALIDADE',
         'o unitario da origem licenca_por_usuario reproduz custo_licencas / usuarios (a Trusted nao recalcula; testa a coerencia da origem)', 'ALERTA', 0.99,
         COUNTIF(licenca_por_usuario IS NOT NULL), COUNTIF(licenca_por_usuario IS NOT NULL AND ABS(licenca_por_usuario - SAFE_DIVIDE(custo_licencas, qtd_usuarios)) > 0.011)
  FROM c
  UNION ALL
  SELECT 'trs_vbot__consumo_wl_cliente_mes.custo_total_por_atendimento_reproduz', 'Trusted', 'trs_vbot__consumo_wl_cliente_mes', 'VBOT', 'VALIDADE',
         'o unitario da origem custo_total_por_atendimento reproduz custo_liquido / atendimentos', 'ALERTA', 0.99,
         COUNTIF(custo_total_por_atendimento IS NOT NULL), COUNTIF(custo_total_por_atendimento IS NOT NULL AND ABS(custo_total_por_atendimento - SAFE_DIVIDE(custo_liquido, qtd_atendimentos)) > 0.0011)
  FROM c
  UNION ALL
  -- LINHA DE BASE: 527 de 550 (95,8%) tem medicao de atendimentos e MAU.
  SELECT 'trs_vbot__consumo_wl_cliente_mes.atendimentos_medidos', 'Trusted', 'trs_vbot__consumo_wl_cliente_mes', 'VBOT', 'COMPLETUDE',
         'o cliente-mes tem atendimentos e MAU medidos (NULL em 23 de 550 na origem)', 'ALERTA', 0.90,
         COUNT(*), COUNTIF(flag_sem_medicao_uso)
  FROM c
  UNION ALL
  -- LINHA DE BASE: 522 de 550 (94,9%) ligam a cliente (28 SEM MATCH). Ligacao por NOME.
  SELECT 'trs_vbot__consumo_wl_cliente_mes.cliente_com_match', 'Trusted', 'trs_vbot__consumo_wl_cliente_mes', 'VBOT', 'INTEGRIDADE',
         'o cliente-mes liga a um cliente por nome (28 de 550 SEM MATCH na origem)', 'ALERTA', 0.90,
         COUNT(*), COUNTIF(is_sem_match)
  FROM c

  UNION ALL
  SELECT 'trs_vbot__preco_wl.id_preco_unico', 'Trusted', 'trs_vbot__preco_wl', 'VBOT', 'UNICIDADE',
         'id_preco (componente|faixa) e unico e nunca nulo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_preco) + COUNTIF(id_preco IS NULL)
  FROM p
  UNION ALL
  SELECT 'trs_vbot__preco_wl.valor_coerente_com_cortesia', 'Trusted', 'trs_vbot__preco_wl', 'VBOT', 'VALIDADE',
         'preco nunca e negativo e so a faixa 0 (cortesia) pode custar zero', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(valor_unitario < 0 OR (faixa > 0 AND valor_unitario <= 0))
  FROM p
),

-- ------------------------------------------------------- TRUSTED FISCAL (21)
r_fiscal AS (
  SELECT 'trs_fiscal__simples_vbot_mes.id_periodo_unico' AS id_regra, 'Trusted' AS camada, 'trs_fiscal__simples_vbot_mes' AS tabela, 'Fiscal VBOT' AS sistema, 'UNICIDADE' AS dimensao,
         'id_periodo e unico e nunca nulo' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_periodo) + COUNTIF(id_periodo IS NULL) AS linhas_falha
  FROM fm
  UNION ALL
  SELECT 'trs_fiscal__simples_vbot_cliente_mes.id_cliente_mes_unico', 'Trusted', 'trs_fiscal__simples_vbot_cliente_mes', 'Fiscal VBOT', 'UNICIDADE',
         'id_cliente_mes (periodo|cliente_key) e unico e nunca nulo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_cliente_mes) + COUNTIF(id_cliente_mes IS NULL)
  FROM fc
  UNION ALL
  SELECT 'trs_fiscal__simples_vbot_nf_mes.id_periodo_unico', 'Trusted', 'trs_fiscal__simples_vbot_nf_mes', 'Fiscal VBOT', 'UNICIDADE',
         'id_periodo e unico e nunca nulo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_periodo) + COUNTIF(id_periodo IS NULL)
  FROM fn
  UNION ALL
  SELECT 'trs_fiscal__simples_vbot_nf_excecao.id_excecao_unico', 'Trusted', 'trs_fiscal__simples_vbot_nf_excecao', 'Fiscal VBOT', 'UNICIDADE',
         'id_excecao (periodo|cobranca) e unico, nunca nulo, e nenhuma cobranca repete', 'BLOQUEANTE', 1.00,
         COUNT(*), (COUNT(*) - COUNT(DISTINCT id_excecao)) + (COUNT(*) - COUNT(DISTINCT id_cobranca)) + COUNTIF(id_excecao IS NULL)
  FROM fe
  UNION ALL
  SELECT 'trs_fiscal__simples_anexo3_faixa.faixa_unica', 'Trusted', 'trs_fiscal__simples_anexo3_faixa', 'Fiscal VBOT', 'UNICIDADE',
         'faixa e unica e nunca nula', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT faixa) + COUNTIF(faixa IS NULL)
  FROM a3
  UNION ALL
  SELECT 'trs_fiscal__simples_receita_declarada.id_periodo_unico', 'Trusted', 'trs_fiscal__simples_receita_declarada', 'Fiscal VBOT', 'UNICIDADE',
         'id_periodo e unico e nunca nulo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_periodo) + COUNTIF(id_periodo IS NULL)
  FROM rd
  UNION ALL
  -- GOVERNANCA: simulacao nunca e promovida a apuracao.
  SELECT 'trs_fiscal.natureza_simulacao_declarada', 'Trusted', 'trs_fiscal__simples_vbot_mes + _cliente_mes', 'Fiscal VBOT', 'VALIDADE',
         'toda linha das duas tabelas de simulacao carrega natureza = SIMULACAO_NAO_CONFERIDA', 'BLOQUEANTE', 1.00,
         (SELECT COUNT(*) FROM fm) + (SELECT COUNT(*) FROM fc),
         (SELECT COUNTIF(IFNULL(natureza, '') <> 'SIMULACAO_NAO_CONFERIDA') FROM fm) + (SELECT COUNTIF(IFNULL(natureza, '') <> 'SIMULACAO_NAO_CONFERIDA') FROM fc)
  UNION ALL
  SELECT 'trs_fiscal__simples_anexo3_faixa.particao_soma_100', 'Trusted', 'trs_fiscal__simples_anexo3_faixa', 'Fiscal VBOT', 'VALIDADE',
         'IRPJ + CSLL + COFINS + PIS + CPP + ISS soma 100 em toda faixa', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(ABS(pct_irpj + pct_csll + pct_cofins + pct_pis + pct_cpp + pct_iss - 100) > 0.011)
  FROM a3
  UNION ALL
  SELECT 'trs_fiscal__simples_vbot_mes.aliquota_reproduz_o_anexo3', 'Trusted', 'trs_fiscal__simples_vbot_mes', 'Fiscal VBOT', 'VALIDADE',
         'aliquota_efetiva = (RBT12 x aliquota nominal - parcela a deduzir) / RBT12 pela faixa do Anexo III (reproduz o metodo da origem)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(ABS(m.aliquota_efetiva_pct - SAFE_DIVIDE(m.rbt12 * a.aliquota_nominal_pct / 100 - a.parcela_deduzir, m.rbt12) * 100) > 0.0001)
  FROM fm m JOIN a3 a ON a.faixa = m.faixa_anexo3
  UNION ALL
  SELECT 'trs_fiscal__simples_vbot_mes.pis_cofins_e_iss_reproduzem', 'Trusted', 'trs_fiscal__simples_vbot_mes', 'Fiscal VBOT', 'VALIDADE',
         'aliq_pis_cofins e aliq_iss reproduzem a particao da faixa aplicada a aliquota efetiva', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(ABS(m.aliq_pis_cofins_pct - m.aliquota_efetiva_pct * (a.pct_pis + a.pct_cofins) / 100) > 0.0001 OR ABS(m.aliq_iss_pct - m.aliquota_efetiva_pct * a.pct_iss / 100) > 0.0001)
  FROM fm m JOIN a3 a ON a.faixa = m.faixa_anexo3
  UNION ALL
  SELECT 'trs_fiscal__simples_vbot_mes.das_conexa_reproduz', 'Trusted', 'trs_fiscal__simples_vbot_mes', 'Fiscal VBOT', 'VALIDADE',
         'das_simulado_conexa = receita_conexa x aliquota sem PIS/COFINS (suspensao ZFM na receita inteira)', 'BLOQUEANTE', 1.00,
         COUNTIF(das_simulado_conexa IS NOT NULL AND receita_conexa IS NOT NULL),
         COUNTIF(das_simulado_conexa IS NOT NULL AND receita_conexa IS NOT NULL AND ABS(das_simulado_conexa - ROUND(receita_conexa * aliq_sem_pis_cofins_pct / 100, 2)) > 0.011)
  FROM fm
  UNION ALL
  SELECT 'trs_fiscal__simples_vbot_mes.das_declarada_reproduz', 'Trusted', 'trs_fiscal__simples_vbot_mes', 'Fiscal VBOT', 'VALIDADE',
         'das_simulado_declarada = receita declarada x aliquota sem PIS/COFINS - ISS retido x aliquota de ISS', 'BLOQUEANTE', 1.00,
         COUNTIF(das_simulado_declarada IS NOT NULL),
         COUNTIF(das_simulado_declarada IS NOT NULL AND ABS(das_simulado_declarada - ROUND(receita_declarada * aliq_sem_pis_cofins_pct / 100 - IFNULL(receita_iss_retido, 0) * aliq_iss_pct / 100, 2)) > 0.011)
  FROM fm
  UNION ALL
  SELECT 'trs_fiscal__simples_vbot_cliente_mes.das_reproduz', 'Trusted', 'trs_fiscal__simples_vbot_cliente_mes', 'Fiscal VBOT', 'VALIDADE',
         'simples_simulado = receita_conexa x aliquota aplicada (sem PIS/COFINS para cliente ZFM)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(ABS(simples_simulado - ROUND(receita_conexa * aliquota_aplicada_pct / 100, 2)) > 0.011)
  FROM fc
  UNION ALL
  SELECT 'trs_fiscal__simples_vbot_cliente_mes.margem_pos_tributo_reproduz', 'Trusted', 'trs_fiscal__simples_vbot_cliente_mes', 'Fiscal VBOT', 'VALIDADE',
         'margem_pos_tributo = margem_liquida - simples_simulado', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(ABS(margem_pos_tributo - (margem_liquida - simples_simulado)) > 0.011)
  FROM fc
  UNION ALL
  SELECT 'trs_fiscal__simples_vbot_cliente_mes.aliquota_igual_a_do_mes', 'Trusted', 'trs_fiscal__simples_vbot_cliente_mes', 'Fiscal VBOT', 'INTEGRIDADE',
         'a aliquota efetiva do cliente-mes e a do mes (e o periodo existe na simulacao do mes)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(m.periodo IS NULL OR ABS(x.aliquota_efetiva_pct - IFNULL(m.aliquota_efetiva_pct, -1)) > 0.0001)
  FROM fc x LEFT JOIN fm m ON m.periodo = x.periodo
  UNION ALL
  SELECT 'trs_fiscal__simples_vbot_cliente_mes.cliente_existe_na_margem', 'Trusted', 'trs_fiscal__simples_vbot_cliente_mes', 'Fiscal VBOT', 'INTEGRIDADE',
         'todo cliente-mes da simulacao existe em trs_vbot__margem_cliente', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(m.cliente_key IS NULL)
  FROM fc x LEFT JOIN mc m ON m.periodo = x.periodo AND m.cliente_key = x.cliente_key
  UNION ALL
  SELECT 'trs_fiscal__simples_receita_declarada.bate_com_a_simulacao', 'Trusted', 'trs_fiscal__simples_receita_declarada', 'Fiscal VBOT', 'INTEGRIDADE',
         'a receita declarada e o ISS retido transcritos batem com os da simulacao do mes (duas views da origem sobre a mesma tabela de parametro)', 'ALERTA', 0.99,
         COUNT(*), COUNTIF(m.periodo IS NULL OR ABS(r.receita_declarada - IFNULL(m.receita_declarada, -1)) > 0.011 OR ABS(r.receita_iss_retido - IFNULL(m.receita_iss_retido, -1)) > 0.011)
  FROM rd r LEFT JOIN fm m ON m.periodo = r.periodo
  UNION ALL
  SELECT 'trs_fiscal__simples_vbot_nf_mes.pagos_decompoem', 'Trusted', 'trs_fiscal__simples_vbot_nf_mes', 'Fiscal VBOT', 'VALIDADE',
         'qtd_pago = qtd_pago_com_nf + qtd_pago_sem_nf', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(qtd_pago <> qtd_pago_com_nf + qtd_pago_sem_nf)
  FROM fn
  UNION ALL
  SELECT 'trs_fiscal__simples_vbot_nf_excecao.tipo_conhecido', 'Trusted', 'trs_fiscal__simples_vbot_nf_excecao', 'Fiscal VBOT', 'VALIDADE',
         'todo tipo de excecao e PAGO_SEM_NF ou ABERTO_SEM_NF (zero OUTRO)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(tipo_excecao NOT IN ('PAGO_SEM_NF', 'ABERTO_SEM_NF'))
  FROM fe
  UNION ALL
  -- ALERTA: duas views da origem; a identidade vale hoje nos 11 periodos com excecao.
  SELECT 'trs_fiscal__simples_vbot_nf_mes.pago_sem_nf_bate_com_a_excecao', 'Trusted', 'trs_fiscal__simples_vbot_nf_mes', 'Fiscal VBOT', 'INTEGRIDADE',
         'por periodo com excecao listada, quantidade e valor de pago sem NF batem com a lista de excecoes', 'ALERTA', 0.90,
         COUNT(*), COUNTIF(n.qtd_pago_sem_nf <> e.n_pago_sem OR ABS(n.valor_pago_sem_nf - e.v_pago_sem) > 0.011)
  FROM fn n JOIN fe_p e USING (periodo)
  UNION ALL
  SELECT 'trs_fiscal__simples_vbot_nf_mes.backlog_origem_inclui_cancelada', 'Trusted', 'trs_fiscal__simples_vbot_nf_mes', 'Fiscal VBOT', 'INTEGRIDADE',
         'por periodo com excecao listada, o backlog da origem = TODAS as cobrancas ABERTO SEM NF (inclusive cancelada), em quantidade e valor', 'ALERTA', 0.90,
         COUNT(*), COUNTIF(n.qtd_backlog_origem <> e.n_aberto OR ABS(n.backlog_a_emitir_origem - e.v_aberto) > 0.011)
  FROM fn n JOIN fe_p e USING (periodo)
  UNION ALL
  -- ALERTA 0,98: cobranca apagada na origem do Conexa e evento legitimo.
  SELECT 'trs_fiscal__simples_vbot_nf_excecao.cobranca_existe_e_vigente', 'Trusted', 'trs_fiscal__simples_vbot_nf_excecao', 'Fiscal VBOT', 'INTEGRIDADE',
         'toda cobranca em excecao existe e esta vigente em trs_conexa__cobranca', 'ALERTA', 0.98,
         COUNT(*), COUNTIF(c.id_cobranca IS NULL OR NOT c.is_vigente)
  FROM fe x LEFT JOIN cb c ON CAST(c.id_cobranca AS STRING) = x.id_cobranca
),

-- ------------------------------------------------------- TRUSTED JA PUBLICADAS SEM REGRA ATE 19/10 (7)
-- trs_custo_wl__conta_mensal, trs_custo_wl__instancia_mensal e trs_conexa__dominio nao tinham NENHUMA regra
-- em nenhuma suite (conferido por busca no repositorio em 19/10). Medidas na tabela materializada: zero falhas.
r_extra AS (
  SELECT 'trs_custo_wl__conta_mensal.chave_unica' AS id_regra, 'Trusted' AS camada, 'trs_custo_wl__conta_mensal' AS tabela, 'Custo WL' AS sistema, 'UNICIDADE' AS dimensao,
         '(periodo, conta_key) e unica e nunca nula' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT CONCAT(periodo, '|', conta_key)) + COUNTIF(periodo IS NULL OR conta_key IS NULL) AS linhas_falha
  FROM cw
  UNION ALL
  SELECT 'trs_custo_wl__conta_mensal.total_decompoe', 'Trusted', 'trs_custo_wl__conta_mensal', 'Custo WL', 'VALIDADE',
         'valor_total_conta = valor_contas + valor_infra', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(ABS(IFNULL(valor_total_conta, 0) - (IFNULL(valor_contas, 0) + IFNULL(valor_infra, 0))) > 0.011)
  FROM cw
  UNION ALL
  SELECT 'trs_custo_wl__instancia_mensal.id_linha_unico', 'Trusted', 'trs_custo_wl__instancia_mensal', 'Custo WL', 'UNICIDADE',
         'id_linha (periodo|conta|instancia|n) e unico e nunca nulo; a chave repetida da origem e desempatada por n, nao apagada', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_linha) + COUNTIF(id_linha IS NULL)
  FROM ci
  UNION ALL
  SELECT 'trs_custo_wl__instancia_mensal.conta_existe_no_detalhe_de_conta', 'Trusted', 'trs_custo_wl__instancia_mensal', 'Custo WL', 'INTEGRIDADE',
         'toda instancia cobrada pertence a uma conta com detalhe de fatura no mesmo periodo (duas tabelas silver da origem)', 'ALERTA', 0.99,
         COUNT(*), COUNTIF(w.conta_key IS NULL)
  FROM ci x LEFT JOIN (SELECT DISTINCT periodo, conta_key FROM cw) w ON w.periodo = x.periodo AND w.conta_key = x.conta_key
  UNION ALL
  SELECT 'trs_conexa__dominio.id_chave_unico', 'Trusted', 'trs_conexa__dominio', 'Conexa', 'UNICIDADE',
         'id_chave (dominio:id_origem) e unico e nunca nulo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_chave) + COUNTIF(id_chave IS NULL)
  FROM dm
  UNION ALL
  SELECT 'trs_conexa__dominio.documento_com_forma', 'Trusted', 'trs_conexa__dominio', 'Conexa', 'VALIDADE',
         'todo documento emitido tem so digitos e 11 ou 14 deles (fragmento de CNPJ nao vira documento)', 'BLOQUEANTE', 1.00,
         COUNTIF(documento IS NOT NULL), COUNTIF(documento IS NOT NULL AND (LENGTH(documento) NOT IN (11, 14) OR NOT REGEXP_CONTAINS(documento, r'^[0-9]+$')))
  FROM dm
  UNION ALL
  SELECT 'trs_conexa__dominio.dominio_conhecido', 'Trusted', 'trs_conexa__dominio', 'Conexa', 'VALIDADE',
         'todo item pertence a um dos 8 dominios conhecidos (dominio novo da origem acende para o resumo nao esconde-lo)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(dominio NOT IN ('CATEGORIA_RECEITA', 'CONTA_FINANCEIRA', 'FORNECEDOR', 'MOTIVO_CHURN', 'PLANO', 'PRODUTO', 'SUBCATEGORIA_DESPESA', 'USUARIO'))
  FROM dm
),

-- ------------------------------------------------------- REFINED (21)
r_ref AS (
  SELECT 'rfn_financeiro__custo_wl_mensal.id_periodo_unico' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__custo_wl_mensal' AS tabela, 'VBOT' AS sistema, 'UNICIDADE' AS dimensao,
         'id_periodo e unico e nunca nulo' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_periodo) + COUNTIF(id_periodo IS NULL) AS linhas_falha
  FROM rc
  UNION ALL
  SELECT 'rfn_financeiro__custo_wl_mensal.contas_e_infra_fecham_com_a_fatura', 'Refined', 'rfn_financeiro__custo_wl_mensal', 'VBOT', 'INTEGRIDADE',
         'por periodo, o detalhe por conta reproduz a fatura em contas e em infraestrutura', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(ABS(IFNULL(dif_contas_detalhe, 999)) > 0.011 OR ABS(IFNULL(dif_infra_detalhe, 999)) > 0.011)
  FROM rc
  UNION ALL
  SELECT 'rfn_financeiro__custo_wl_mensal.liquido_por_cliente_igual_fatura_mais_dif_instancias', 'Refined', 'rfn_financeiro__custo_wl_mensal', 'VBOT', 'INTEGRIDADE',
         'por periodo, custo liquido por cliente - fatura = diferenca do detalhe por instancia (o rateio parte do detalhe, nao do consolidado)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(NOT IFNULL(flag_identidade_fecha, FALSE))
  FROM rc
  UNION ALL
  SELECT 'rfn_financeiro__custo_wl_mensal.reproduz_as_trusted', 'Refined', 'rfn_financeiro__custo_wl_mensal', 'VBOT', 'INTEGRIDADE',
         'periodos, fatura total, custo liquido por cliente e custo helena das contas reproduzem as Trusted', 'BLOQUEANTE', 1.00,
         1,
         IF((SELECT COUNT(*) FROM rc) = (SELECT COUNT(*) FROM fa)
            AND ABS((SELECT SUM(valor_total_fatura) FROM rc) - (SELECT SUM(valor_total_fatura) FROM fa)) <= 0.05
            AND ABS((SELECT SUM(custo_liquido_clientes) FROM rc) - (SELECT SUM(custo_liquido) FROM c)) <= 0.05
            AND ABS((SELECT SUM(custo_helena_contas_com_uso) FROM rc) - (SELECT SUM(custo_helena) FROM u)) <= 0.05, 0, 1)
  UNION ALL
  -- ALERTA: premissa entre origens diferentes (silver x gold): os apps estao dentro de valor_contas.
  SELECT 'rfn_financeiro__custo_wl_mensal.licencas_mais_apps_igual_contas', 'Refined', 'rfn_financeiro__custo_wl_mensal', 'VBOT', 'VALIDADE',
         'custo_licencas + custo_apps (por cliente) = valor_contas (detalhe por conta): os apps estao dentro das contas', 'ALERTA', 0.99,
         COUNT(*), COUNTIF(ABS(IFNULL(custo_licencas, 0) + IFNULL(custo_apps, 0) - IFNULL(valor_contas_detalhe, 999)) > 0.02)
  FROM rc

  UNION ALL
  SELECT 'rfn_financeiro__preco_wl_resumo.id_componente_unico', 'Refined', 'rfn_financeiro__preco_wl_resumo', 'VBOT', 'UNICIDADE',
         'id_componente e unico e nunca nulo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_componente) + COUNTIF(id_componente IS NULL)
  FROM rp
  UNION ALL
  SELECT 'rfn_financeiro__preco_wl_resumo.reproduz_a_trusted', 'Refined', 'rfn_financeiro__preco_wl_resumo', 'VBOT', 'INTEGRIDADE',
         'a soma das faixas por componente = linhas de trs_vbot__preco_wl e o numero de componentes bate', 'BLOQUEANTE', 1.00,
         1,
         IF((SELECT SUM(qtd_faixas) FROM rp) = (SELECT COUNT(*) FROM p) AND (SELECT COUNT(*) FROM rp) = (SELECT COUNT(DISTINCT componente) FROM p), 0, 1)

  UNION ALL
  SELECT 'rfn_financeiro__mix_produto_vbot_mensal.id_mix_mensal_unico', 'Refined', 'rfn_financeiro__mix_produto_vbot_mensal', 'VBOT', 'UNICIDADE',
         'id_mix_mensal (periodo|familia|tipo) e unico e nunca nulo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_mix_mensal) + COUNTIF(id_mix_mensal IS NULL)
  FROM rm
  UNION ALL
  SELECT 'rfn_financeiro__mix_produto_vbot_mensal.reproduz_a_trusted', 'Refined', 'rfn_financeiro__mix_produto_vbot_mensal', 'VBOT', 'INTEGRIDADE',
         'linhas, MRR e receita pontual somados reproduzem trs_vbot__mix_produto_mes (R$ 0,10 de arredondamento por grupo)', 'BLOQUEANTE', 1.00,
         1,
         IF((SELECT SUM(qtd_linhas) FROM rm) = (SELECT COUNT(*) FROM mx)
            AND ABS(IFNULL((SELECT SUM(mrr) FROM rm), 0) - IFNULL((SELECT SUM(mrr) FROM mx), 0)) <= 0.10
            AND ABS(IFNULL((SELECT SUM(receita_pontual) FROM rm), 0) - IFNULL((SELECT SUM(receita_pontual) FROM mx), 0)) <= 0.10, 0, 1)
  UNION ALL
  SELECT 'rfn_financeiro__mix_produto_vbot_mensal.participacao_soma_um_por_periodo', 'Refined', 'rfn_financeiro__mix_produto_vbot_mensal', 'VBOT', 'VALIDADE',
         'por periodo, a participacao das familias no MRR soma 1', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(ABS(s - 1) > 0.0001)
  FROM (SELECT periodo, SUM(IFNULL(participacao_mrr_no_periodo, 0)) AS s FROM rm GROUP BY periodo)

  UNION ALL
  SELECT 'rfn_operacao__conexa_dominio_resumo.id_dominio_unico', 'Refined', 'rfn_operacao__conexa_dominio_resumo', 'Conexa', 'UNICIDADE',
         'id_dominio e unico e nunca nulo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_dominio) + COUNTIF(id_dominio IS NULL)
  FROM rdm
  UNION ALL
  SELECT 'rfn_operacao__conexa_dominio_resumo.reproduz_a_trusted', 'Refined', 'rfn_operacao__conexa_dominio_resumo', 'Conexa', 'INTEGRIDADE',
         'a soma dos itens por dominio = linhas de trs_conexa__dominio e o numero de dominios bate', 'BLOQUEANTE', 1.00,
         1,
         IF((SELECT SUM(qtd_itens) FROM rdm) = (SELECT COUNT(*) FROM dm) AND (SELECT COUNT(*) FROM rdm) = (SELECT COUNT(DISTINCT dominio) FROM dm), 0, 1)
  UNION ALL
  SELECT 'rfn_operacao__conexa_dominio_resumo.ativos_decompoem', 'Refined', 'rfn_operacao__conexa_dominio_resumo', 'Conexa', 'VALIDADE',
         'ativos + inativos + sem flag = itens em todo dominio', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(qtd_ativos + qtd_inativos + qtd_sem_flag_ativo <> qtd_itens)
  FROM rdm

  UNION ALL
  SELECT 'rfn_fiscal__simples_vbot_mensal.id_periodo_unico', 'Refined', 'rfn_fiscal__simples_vbot_mensal', 'Fiscal VBOT', 'UNICIDADE',
         'id_periodo e unico e nunca nulo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_periodo) + COUNTIF(id_periodo IS NULL)
  FROM rf
  UNION ALL
  SELECT 'rfn_fiscal__simples_vbot_mensal.reproduz_as_trusted', 'Refined', 'rfn_fiscal__simples_vbot_mensal', 'Fiscal VBOT', 'INTEGRIDADE',
         'periodos, clientes, DAS somado dos clientes e excecoes reproduzem as Trusted fiscais', 'BLOQUEANTE', 1.00,
         1,
         IF((SELECT COUNT(*) FROM rf) = (SELECT COUNT(*) FROM fm)
            AND (SELECT SUM(qtd_clientes) FROM rf) = (SELECT COUNT(*) FROM fc)
            AND ABS(IFNULL((SELECT SUM(das_simulado_soma_clientes) FROM rf), 0) - (SELECT SUM(simples_simulado) FROM fc)) <= 0.10
            AND (SELECT SUM(qtd_excecoes) FROM rf) = (SELECT COUNT(*) FROM fe), 0, 1)
  UNION ALL
  SELECT 'rfn_fiscal__simples_vbot_mensal.natureza_simulacao_declarada', 'Refined', 'rfn_fiscal__simples_vbot_mensal', 'Fiscal VBOT', 'VALIDADE',
         'toda linha carrega natureza = SIMULACAO_NAO_CONFERIDA e nao ha tributo apresentado como apuracao', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(IFNULL(natureza, '') <> 'SIMULACAO_NAO_CONFERIDA')
  FROM rf
  UNION ALL
  SELECT 'rfn_fiscal__simples_vbot_mensal.backlog_vigente_mais_cancelado_igual_origem', 'Refined', 'rfn_fiscal__simples_vbot_mensal', 'Fiscal VBOT', 'VALIDADE',
         'por periodo com excecao, backlog vigente + backlog cancelado = backlog da origem (que inclui cancelada)', 'BLOQUEANTE', 1.00,
         COUNTIF(qtd_excecoes IS NOT NULL),
         COUNTIF(qtd_excecoes IS NOT NULL AND ABS(IFNULL(valor_backlog_vigente, 0) + IFNULL(valor_backlog_cancelado, 0) - IFNULL(backlog_a_emitir_origem, 0)) > 0.011)
  FROM rf
  UNION ALL
  -- ALERTA 1,00: se a diferenca ficar POSITIVA, o metodo do mes e o por cliente mudaram.
  SELECT 'rfn_fiscal__simples_vbot_mensal.mes_nunca_maior_que_a_soma_dos_clientes', 'Refined', 'rfn_fiscal__simples_vbot_mensal', 'Fiscal VBOT', 'VALIDADE',
         'o DAS do mes (suspensao na receita inteira) nunca excede a soma por cliente (suspensao so nos ZFM); positivo = metodo mudou', 'ALERTA', 1.00,
         COUNTIF(dif_das_mes_menos_clientes IS NOT NULL), COUNTIF(dif_das_mes_menos_clientes > 0.011)
  FROM rf
  UNION ALL
  SELECT 'rfn_fiscal__simples_vbot_mensal.faixa_resolve_no_anexo3', 'Refined', 'rfn_fiscal__simples_vbot_mensal', 'Fiscal VBOT', 'INTEGRIDADE',
         'todo periodo com faixa resolve a aliquota nominal do Anexo III', 'BLOQUEANTE', 1.00,
         COUNTIF(faixa_anexo3 IS NOT NULL), COUNTIF(faixa_anexo3 IS NOT NULL AND aliquota_nominal_pct IS NULL)
  FROM rf
  UNION ALL
  SELECT 'rfn_fiscal__simples_vbot_mensal.receita_dos_clientes_fecha_com_a_do_mes', 'Refined', 'rfn_fiscal__simples_vbot_mensal', 'Fiscal VBOT', 'INTEGRIDADE',
         'por periodo com clientes, a receita somada dos clientes = receita do Conexa do mes (duas views da origem)', 'ALERTA', 0.99,
         COUNTIF(receita_conexa_clientes IS NOT NULL),
         COUNTIF(receita_conexa_clientes IS NOT NULL AND ABS(receita_conexa_clientes - IFNULL(receita_conexa, -999999)) > 0.02)
  FROM rf
),

-- ------------------------------------------------------- FRESCOR (1)
-- Escopo: as 9 Trusted e as 4 Refined desta frente que rodam semanalmente (segunda 06:00). A
-- rfn_operacao__conexa_dominio_resumo e DIARIA (evento na supabase-x0tz) e fica de fora de proposito.
carga AS (
  SELECT 'uso' AS t, MAX(DATE(_extraido_at)) AS d FROM u
  UNION ALL SELECT 'consumo', MAX(DATE(_extraido_at)) FROM c
  UNION ALL SELECT 'preco', MAX(DATE(_extraido_at)) FROM p
  UNION ALL SELECT 'fiscal_mes', MAX(DATE(_extraido_at)) FROM fm
  UNION ALL SELECT 'fiscal_cliente', MAX(DATE(_extraido_at)) FROM fc
  UNION ALL SELECT 'fiscal_nf_mes', MAX(DATE(_extraido_at)) FROM fn
  UNION ALL SELECT 'fiscal_excecao', MAX(DATE(_extraido_at)) FROM fe
  UNION ALL SELECT 'fiscal_anexo3', MAX(DATE(_extraido_at)) FROM a3
  UNION ALL SELECT 'fiscal_rpa', MAX(DATE(_extraido_at)) FROM rd
  UNION ALL SELECT 'ref_custo_wl', MAX(DATE(_extraido_at)) FROM rc
  UNION ALL SELECT 'ref_preco', MAX(DATE(_extraido_at)) FROM rp
  UNION ALL SELECT 'ref_mix', MAX(DATE(_extraido_at)) FROM rm
  UNION ALL SELECT 'ref_fiscal', MAX(DATE(_extraido_at)) FROM rf
),
r_frescor AS (
  SELECT 'vbot_wl_simples.carga_do_mesmo_dia' AS id_regra, 'Trusted' AS camada,
         '(9 Trusted e 4 Refined semanais desta frente)' AS tabela, 'VBOT' AS sistema, 'VALIDADE' AS dimensao,
         'as 13 tabelas semanais foram escritas na mesma passada' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNTIF(d <> (SELECT MAX(d) FROM carga)) AS linhas_falha
  FROM carga
),

todas AS (
  SELECT * FROM r_wl
  UNION ALL SELECT * FROM r_fiscal
  UNION ALL SELECT * FROM r_extra
  UNION ALL SELECT * FROM r_ref
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
  'VBOT white-label e Simples'                  AS familia,
  CURRENT_TIMESTAMP()                           AS _extraido_at,
  'supabase-x0tz'                               AS _fonte,
  'America/Sao_Paulo'                           AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(a)))                AS _payload_hash
FROM avaliado a
