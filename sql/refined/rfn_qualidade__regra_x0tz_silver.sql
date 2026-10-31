-- rfn_qualidade__regra_x0tz_silver (query-IczE) · 22 regras · L2 INTERNAL
-- Refined / qualidade. Grao: uma REGRA em uma execucao. Gatilho: evento nas 5 Refined novas de 18/10 com regra "all"
-- (query-0V6z, query-cUo0, query-nCYr, query-eZXu, query-I2PH). Alerta ligado. Cadencia DIARIA (a supabase-x0tz roda ~01:00).
-- Cobre as Trusted e Refined criadas em 18/10/2026 sobre as tabelas silver/bronze/public da supabase-x0tz: extrato bancario, NFS-e,
-- recebimento de PI, custo WL, Quickin (vaga e aplicacao), Qulture (colaborador) e as 5 Refined.
-- VALIDACAO (18/10/2026): as regras foram medidas reproduzindo as Trusted sobre a Raw (nenhuma materializou ainda). Resultado:
-- 22 regras, 22 conformes esperadas (a do saldo do extrato conforma com 19 de 20 = 95% contra limiar 0,90; a falha medida e itau_brm 2026-07). Limiares de
-- ALERTA sao linha de base, para detectar piora: saldo 0,90 (95% medido), PI catalogado 0,85 (91,3%), vaga da aplicacao 0,99 (100%).
-- Contrato de colunas identico ao das demais suites (UNION ALL entre elas da o painel unico; familia diz de onde veio).
-- NAO ENTRAM, DE PROPOSITO: o detalhe de INSTANCIAS do custo WL (nao fecha: diferenca de R$ 2,25 a 18,00 em 6 de 8 periodos);
-- qualquer regra sobre flag gravada comparada ao relogio (fabrica falha com o tempo).
WITH r AS (
  SELECT 'trs_extrato__lancamento.id_linha_unico' AS id_regra, 'Trusted' AS camada, 'trs_extrato__lancamento' AS tabela, 'Extrato' AS sistema, 'UNICIDADE' AS dimensao,
         'id_linha e unico e nunca nulo (4.648 na medicao)' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_linha) + COUNTIF(id_linha IS NULL) AS linhas_falha FROM `vanguardamartech_trusted`.`trs_extrato__lancamento`
  UNION ALL
  SELECT 'trs_extrato__lancamento.data_nao_futura', 'Trusted', 'trs_extrato__lancamento', 'Extrato', 'VALIDADE',
         'data do movimento nunca depois do dia de hoje (regra sobre o DADO, nao sobre flag gravada)', 'BLOQUEANTE', 1.00,
         COUNTIF(data_movimento IS NOT NULL), COUNTIF(data_movimento > CURRENT_DATE('America/Sao_Paulo')) FROM `vanguardamartech_trusted`.`trs_extrato__lancamento`
  UNION ALL
  SELECT 'trs_extrato__lancamento.sentido_concorda_com_o_sinal', 'Trusted', 'trs_extrato__lancamento', 'Extrato', 'VALIDADE',
         'sentido ENTRADA exatamente quando valor > 0, SAIDA quando valor < 0', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(sentido <> IF(valor > 0, 'ENTRADA', IF(valor < 0, 'SAIDA', 'ZERO'))) FROM `vanguardamartech_trusted`.`trs_extrato__lancamento`
  UNION ALL
  SELECT 'trs_extrato__saldo_mensal.id_chave_unico', 'Trusted', 'trs_extrato__saldo_mensal', 'Extrato', 'UNICIDADE',
         'id_chave (conta e periodo) e unico e nunca nulo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_chave) + COUNTIF(id_chave IS NULL) FROM `vanguardamartech_trusted`.`trs_extrato__saldo_mensal`
  UNION ALL
  -- LINHA DE BASE. A identidade saldo anterior + movimento = saldo final fecha em 19 dos 20 pares avaliaveis; a falha medida
  -- e itau_brm 2026-07 (-765,46). Limiar 0,90: detecta piora, nao cobra o que o arquivo de origem ja traz.
  SELECT 'trs_extrato__saldo_mensal.identidade_fecha', 'Trusted', 'trs_extrato__saldo_mensal', 'Extrato', 'INTEGRIDADE',
         'saldo anterior + movimento = saldo final nos pares avaliaveis (19 de 20 na medicao)', 'ALERTA', 0.90,
         COUNTIF(diferenca_identidade IS NOT NULL), COUNTIF(flag_nao_fecha) FROM `vanguardamartech_trusted`.`trs_extrato__saldo_mensal`
  UNION ALL
  SELECT 'trs_iclips__nfse.id_nfse_unico', 'Trusted', 'trs_iclips__nfse', 'iClips', 'UNICIDADE',
         'id_nfse e unico e nunca nulo (1.323 na medicao)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_nfse) + COUNTIF(id_nfse IS NULL) FROM `vanguardamartech_trusted`.`trs_iclips__nfse`
  UNION ALL
  SELECT 'trs_iclips__nfse.valor_vigente_so_emitida', 'Trusted', 'trs_iclips__nfse', 'iClips', 'VALIDADE',
         'valor_vigente so existe em nota emitida (cancelada nunca entra no valor vigente)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF((valor_vigente IS NOT NULL) <> is_emitida) FROM `vanguardamartech_trusted`.`trs_iclips__nfse`
  UNION ALL
  SELECT 'trs_pi__recebimento.id_pi_unico', 'Trusted', 'trs_pi__recebimento', 'PI', 'UNICIDADE',
         'id_pi e unico e nunca nulo (1.696 na medicao)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_pi) + COUNTIF(id_pi IS NULL) FROM `vanguardamartech_trusted`.`trs_pi__recebimento`
  UNION ALL
  SELECT 'trs_pi__recebimento.valor_positivo', 'Trusted', 'trs_pi__recebimento', 'PI', 'VALIDADE',
         'valor_recebido maior que zero e parcelas maiores que zero', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(valor_recebido IS NULL OR valor_recebido <= 0 OR qtd_parcelas IS NULL OR qtd_parcelas <= 0) FROM `vanguardamartech_trusted`.`trs_pi__recebimento`
  UNION ALL
  -- LINHA DE BASE. 148 de 1.696 PIs recebidos nao estao em trs_pi__insercao (91,3% catalogados); a regra detecta piora.
  SELECT 'trs_pi__recebimento.pi_catalogado', 'Trusted', 'trs_pi__recebimento', 'PI', 'INTEGRIDADE',
         'PI recebido existe em trs_pi__insercao (1.548 de 1.696 na medicao)', 'ALERTA', 0.85,
         COUNT(*), COUNTIF(flag_pi_nao_catalogado) FROM `vanguardamartech_trusted`.`trs_pi__recebimento`
  UNION ALL
  SELECT 'trs_custo_wl__fatura_mensal.periodo_unico', 'Trusted', 'trs_custo_wl__fatura_mensal', 'Custo WL', 'UNICIDADE',
         'periodo da fatura e unico e nunca nulo (8 na medicao)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT periodo) + COUNTIF(periodo IS NULL) FROM `vanguardamartech_trusted`.`trs_custo_wl__fatura_mensal`
  UNION ALL
  -- Identidade: a soma do detalhe de contas e do detalhe de infraestrutura reproduz o consolidado da fatura em todos os periodos medidos.
  -- O detalhe de INSTANCIAS nao fecha (diferenca de R$ 2,25 a 18,00 em 6 de 8) e por isso NAO entra como regra.
  SELECT 'trs_custo_wl__fatura_mensal.contas_e_infra_fecham', 'Trusted', 'trs_custo_wl__fatura_mensal', 'Custo WL', 'INTEGRIDADE',
         'detalhe de contas e detalhe de infraestrutura reproduzem o consolidado da fatura dentro de um centavo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(ABS(IFNULL(diff_contas, 0)) > 0.01 OR ABS(IFNULL(diff_infra, 0)) > 0.01) FROM `vanguardamartech_trusted`.`trs_custo_wl__fatura_mensal`
  UNION ALL
  SELECT 'trs_quickin__vaga.id_vaga_unico', 'Trusted', 'trs_quickin__vaga', 'Quickin', 'UNICIDADE',
         'id_vaga e unico e nunca nulo (217 na medicao)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_vaga) + COUNTIF(id_vaga IS NULL) FROM `vanguardamartech_trusted`.`trs_quickin__vaga`
  UNION ALL
  SELECT 'trs_quickin__aplicacao.id_aplicacao_unico', 'Trusted', 'trs_quickin__aplicacao', 'Quickin', 'UNICIDADE',
         'id_aplicacao e unico e nunca nulo (4.013 na medicao)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_aplicacao) + COUNTIF(id_aplicacao IS NULL) FROM `vanguardamartech_trusted`.`trs_quickin__aplicacao`
  UNION ALL
  SELECT 'trs_quickin__aplicacao.vaga_existe', 'Trusted', 'trs_quickin__aplicacao', 'Quickin', 'INTEGRIDADE',
         'toda aplicacao aponta para vaga que existe em trs_quickin__vaga', 'ALERTA', 0.99,
         COUNT(*), COUNTIF(id_vaga NOT IN (SELECT id_vaga FROM `vanguardamartech_trusted`.`trs_quickin__vaga`)) FROM `vanguardamartech_trusted`.`trs_quickin__aplicacao`
  UNION ALL
  SELECT 'trs_qulture__colaborador.email_chave_unico', 'Trusted', 'trs_qulture__colaborador', 'Qulture', 'UNICIDADE',
         'email_chave e unico e nunca nulo (317 na medicao)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT email_chave) + COUNTIF(email_chave IS NULL) FROM `vanguardamartech_trusted`.`trs_qulture__colaborador`
  UNION ALL
  -- IDENTIDADES ENTRE CAMADAS (grao de 1 linha: soma da Refined contra o total da Trusted). A Refined agrega e nao filtra o que declara:
  -- se divergir, perdeu linha num join ou duplicou, e a contagem de linhas da Refined nao denuncia.
  SELECT 'rfn_financeiro__extrato_mensal.reproduz_a_trusted', 'Refined', 'rfn_financeiro__extrato_mensal', 'Extrato', 'INTEGRIDADE',
         'soma de qtd_lancamentos = total de trs_extrato__lancamento e liquido reproduz a soma de valor (4.648 e -112.748,38 na medicao)', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(qtd_lancamentos) FROM `vanguardamartech_refined`.`rfn_financeiro__extrato_mensal`) = (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_extrato__lancamento`)
               AND ABS((SELECT SUM(valor_liquido) FROM `vanguardamartech_refined`.`rfn_financeiro__extrato_mensal`) - (SELECT SUM(valor) FROM `vanguardamartech_trusted`.`trs_extrato__lancamento`)) <= 0.01, 0, 1) FROM UNNEST([1])
  UNION ALL
  SELECT 'rfn_financeiro__nfse_mensal.reproduz_a_trusted', 'Refined', 'rfn_financeiro__nfse_mensal', 'iClips', 'INTEGRIDADE',
         'soma de qtd_notas = total de trs_iclips__nfse e valor_vigente reproduz a soma da Trusted (1.323 e R$ 5.603.000,47 na medicao)', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(qtd_notas) FROM `vanguardamartech_refined`.`rfn_financeiro__nfse_mensal`) = (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_iclips__nfse`)
               AND ABS((SELECT SUM(valor_vigente) FROM `vanguardamartech_refined`.`rfn_financeiro__nfse_mensal`) - (SELECT SUM(valor_vigente) FROM `vanguardamartech_trusted`.`trs_iclips__nfse`)) <= 0.01, 0, 1) FROM UNNEST([1])
  UNION ALL
  SELECT 'rfn_financeiro__recebimento_pi_mensal.reproduz_a_trusted', 'Refined', 'rfn_financeiro__recebimento_pi_mensal', 'PI', 'INTEGRIDADE',
         'soma de qtd_pis = total de trs_pi__recebimento e valor_recebido reproduz a soma da Trusted (1.696 e R$ 5.956.386,00 na medicao)', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(qtd_pis) FROM `vanguardamartech_refined`.`rfn_financeiro__recebimento_pi_mensal`) = (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_pi__recebimento`)
               AND ABS((SELECT SUM(valor_recebido) FROM `vanguardamartech_refined`.`rfn_financeiro__recebimento_pi_mensal`) - (SELECT SUM(valor_recebido) FROM `vanguardamartech_trusted`.`trs_pi__recebimento`)) <= 0.01, 0, 1) FROM UNNEST([1])
  UNION ALL
  SELECT 'rfn_rh__recrutamento_mensal.vagas_reproduzem_a_trusted', 'Refined', 'rfn_rh__recrutamento_mensal', 'Quickin', 'INTEGRIDADE',
         'soma de qtd_vagas_abertas = vagas com data de abertura em trs_quickin__vaga (217 na medicao)', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(qtd_vagas_abertas) FROM `vanguardamartech_refined`.`rfn_rh__recrutamento_mensal`) = (SELECT COUNTIF(aberta_em IS NOT NULL) FROM `vanguardamartech_trusted`.`trs_quickin__vaga`), 0, 1) FROM UNNEST([1])
  UNION ALL
  SELECT 'rfn_rh__recrutamento_mensal.contratacoes_reproduzem_a_trusted', 'Refined', 'rfn_rh__recrutamento_mensal', 'Quickin', 'INTEGRIDADE',
         'soma de qtd_contratacoes = aplicacoes contratadas com data em trs_quickin__aplicacao (150 na medicao)', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(qtd_contratacoes) FROM `vanguardamartech_refined`.`rfn_rh__recrutamento_mensal`) = (SELECT COUNTIF(is_contratado AND contratado_em IS NOT NULL) FROM `vanguardamartech_trusted`.`trs_quickin__aplicacao`), 0, 1) FROM UNNEST([1])
  UNION ALL
  SELECT 'rfn_rh__desligamento_mensal.reproduz_a_trusted', 'Refined', 'rfn_rh__desligamento_mensal', 'Qulture', 'INTEGRIDADE',
         'soma de qtd_desligados = pessoas com data de inativacao em trs_qulture__colaborador (191 na medicao)', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(qtd_desligados) FROM `vanguardamartech_refined`.`rfn_rh__desligamento_mensal`) = (SELECT COUNTIF(inativado_em IS NOT NULL AND NOT IFNULL(flag_nao_pessoa, FALSE)) FROM `vanguardamartech_trusted`.`trs_qulture__colaborador`), 0, 1) FROM UNNEST([1])
  -- Sem LIMIT: no ultimo ramo de um UNION ALL ele vale para a uniao inteira e deixaria uma unica regra.
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
  'X0TZ_SILVER' AS familia, CURRENT_TIMESTAMP() AS _extraido_at, 'supabase-x0tz' AS _fonte, 'America/Sao_Paulo' AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(a))) AS _payload_hash
FROM avaliado a
