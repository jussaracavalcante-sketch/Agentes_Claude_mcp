-- rfn_qualidade__regra_refined_vjob_contazul (query-NO4O) · 48 regras · Refined / qualidade · L2 INTERNAL
-- Grao: uma REGRA em uma execucao. Cobre as 13 Refined publicadas em 07/10/2026 e materializadas na passada manual da
-- mysql-yIOn (07/10 11:23-12:18): Conta Azul (contazul_categoria_mensal, contazul_entidade_resumo, contazul_vinculo_resumo)
-- e VJOB (checklist_mensal, auditoria_ciclo_mensal, anexo_diverso_mensal, biblioteca_mensal, compromisso_mensal,
-- config_cliente_resumo, dominio_resumo, escopo_data_extra_mensal, evento_sistema_mensal, job_aprovacao_inicial_mensal).
-- Fora, de proposito: rfn_operacao__email_rotulo_resumo (Gmail, ainda nao materializou) e rfn_operacao__peca_categoria_resumo (iClips,
-- entra na suite do iClips). Referenciar tabela nao materializada derruba a suite inteira.
-- Gatilho: evento nas 13 Refined com regra "all". Cadencia semanal (mysql-yIOn, domingo). Alerta ligado.
-- Contrato de colunas identico ao das outras suites; familia = REFINED_VJOB_CONTAZUL.
-- Identidades: a Refined agrega e nao filtra, entao o que ela soma reproduz a Trusted de que le.
WITH r AS (
  -- UNICIDADE da chave de cada Refined
  SELECT 'rfn_financeiro__contazul_categoria_mensal.chave_unica' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__contazul_categoria_mensal' AS tabela, 'CONTA_AZUL' AS sistema, 'UNICIDADE' AS dimensao,
         'id_categoria_mensal e unico e nunca nulo' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_categoria_mensal) + COUNTIF(id_categoria_mensal IS NULL) AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_categoria_mensal`
  UNION ALL SELECT 'rfn_financeiro__contazul_entidade_resumo.chave_unica', 'Refined', 'rfn_financeiro__contazul_entidade_resumo', 'CONTA_AZUL', 'UNICIDADE',
         'id_entidade_resumo e unico e nunca nulo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_entidade_resumo) + COUNTIF(id_entidade_resumo IS NULL)
  FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_entidade_resumo`
  UNION ALL SELECT 'rfn_financeiro__contazul_vinculo_resumo.chave_unica', 'Refined', 'rfn_financeiro__contazul_vinculo_resumo', 'CONTA_AZUL', 'UNICIDADE',
         'id_vinculo_resumo e unico e nunca nulo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_vinculo_resumo) + COUNTIF(id_vinculo_resumo IS NULL)
  FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_vinculo_resumo`
  UNION ALL SELECT 'rfn_operacao__checklist_mensal.chave_unica', 'Refined', 'rfn_operacao__checklist_mensal', 'VJOB', 'UNICIDADE',
         'id_checklist_mensal e unico e nunca nulo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_checklist_mensal) + COUNTIF(id_checklist_mensal IS NULL)
  FROM `vanguardamartech_refined`.`rfn_operacao__checklist_mensal`
  UNION ALL SELECT 'rfn_operacao__auditoria_ciclo_mensal.chave_unica', 'Refined', 'rfn_operacao__auditoria_ciclo_mensal', 'VJOB', 'UNICIDADE',
         'id_ciclo_mensal e unico e nunca nulo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_ciclo_mensal) + COUNTIF(id_ciclo_mensal IS NULL)
  FROM `vanguardamartech_refined`.`rfn_operacao__auditoria_ciclo_mensal`
  UNION ALL SELECT 'rfn_operacao__anexo_diverso_mensal.chave_unica', 'Refined', 'rfn_operacao__anexo_diverso_mensal', 'VJOB', 'UNICIDADE',
         'id_anexo_mensal e unico e nunca nulo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_anexo_mensal) + COUNTIF(id_anexo_mensal IS NULL)
  FROM `vanguardamartech_refined`.`rfn_operacao__anexo_diverso_mensal`
  UNION ALL SELECT 'rfn_operacao__biblioteca_mensal.chave_unica', 'Refined', 'rfn_operacao__biblioteca_mensal', 'VJOB', 'UNICIDADE',
         'id_biblioteca_mensal e unico e nunca nulo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_biblioteca_mensal) + COUNTIF(id_biblioteca_mensal IS NULL)
  FROM `vanguardamartech_refined`.`rfn_operacao__biblioteca_mensal`
  UNION ALL SELECT 'rfn_operacao__compromisso_mensal.chave_unica', 'Refined', 'rfn_operacao__compromisso_mensal', 'VJOB', 'UNICIDADE',
         'id_compromisso_mensal e unico e nunca nulo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_compromisso_mensal) + COUNTIF(id_compromisso_mensal IS NULL)
  FROM `vanguardamartech_refined`.`rfn_operacao__compromisso_mensal`
  UNION ALL SELECT 'rfn_operacao__config_cliente_resumo.chave_unica', 'Refined', 'rfn_operacao__config_cliente_resumo', 'VJOB', 'UNICIDADE',
         'id_config_resumo e unico e nunca nulo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_config_resumo) + COUNTIF(id_config_resumo IS NULL)
  FROM `vanguardamartech_refined`.`rfn_operacao__config_cliente_resumo`
  UNION ALL SELECT 'rfn_operacao__dominio_resumo.chave_unica', 'Refined', 'rfn_operacao__dominio_resumo', 'VJOB', 'UNICIDADE',
         'id_dominio e unico e nunca nulo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_dominio) + COUNTIF(id_dominio IS NULL)
  FROM `vanguardamartech_refined`.`rfn_operacao__dominio_resumo`
  UNION ALL SELECT 'rfn_operacao__escopo_data_extra_mensal.chave_unica', 'Refined', 'rfn_operacao__escopo_data_extra_mensal', 'VJOB', 'UNICIDADE',
         'id_data_extra_mensal e unico e nunca nulo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_data_extra_mensal) + COUNTIF(id_data_extra_mensal IS NULL)
  FROM `vanguardamartech_refined`.`rfn_operacao__escopo_data_extra_mensal`
  UNION ALL SELECT 'rfn_operacao__evento_sistema_mensal.chave_unica', 'Refined', 'rfn_operacao__evento_sistema_mensal', 'VJOB', 'UNICIDADE',
         'id_evento_mensal e unico e nunca nulo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_evento_mensal) + COUNTIF(id_evento_mensal IS NULL)
  FROM `vanguardamartech_refined`.`rfn_operacao__evento_sistema_mensal`
  UNION ALL SELECT 'rfn_operacao__job_aprovacao_inicial_mensal.chave_unica', 'Refined', 'rfn_operacao__job_aprovacao_inicial_mensal', 'VJOB', 'UNICIDADE',
         'id_aprovacao_mensal e unico e nunca nulo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_aprovacao_mensal) + COUNTIF(id_aprovacao_mensal IS NULL)
  FROM `vanguardamartech_refined`.`rfn_operacao__job_aprovacao_inicial_mensal`
  -- IDENTIDADES entre camadas (grao: a tabela inteira, 1 linha avaliada)
  UNION ALL SELECT 'rfn_financeiro__contazul_categoria_mensal.parcelas_reproduzem_a_trusted', 'Refined', 'rfn_financeiro__contazul_categoria_mensal', 'CONTA_AZUL', 'VALIDADE',
         'a soma de qtd_parcelas_total reproduz as linhas de trs_contazul__movimento', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(qtd_parcelas_total) FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_categoria_mensal`) <> (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_contazul__movimento`), 1, 0)
  UNION ALL SELECT 'rfn_financeiro__contazul_categoria_mensal.valor_vigente_reproduz_a_trusted', 'Refined', 'rfn_financeiro__contazul_categoria_mensal', 'CONTA_AZUL', 'VALIDADE',
         'a soma de valor_vigente reproduz o valor das parcelas vigentes de trs_contazul__movimento dentro de um centavo', 'BLOQUEANTE', 1.00,
         1, IF(ABS((SELECT SUM(valor_vigente) FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_categoria_mensal`) - (SELECT SUM(IF(is_vigente, valor, 0)) FROM `vanguardamartech_trusted`.`trs_contazul__movimento`)) > 0.01, 1, 0)
  UNION ALL SELECT 'rfn_financeiro__contazul_categoria_mensal.valor_removido_reproduz_a_trusted', 'Refined', 'rfn_financeiro__contazul_categoria_mensal', 'CONTA_AZUL', 'VALIDADE',
         'a soma de valor_removido reproduz o valor das parcelas removidas de trs_contazul__movimento dentro de um centavo (nao entra em valor_vigente)', 'BLOQUEANTE', 1.00,
         1, IF(ABS((SELECT SUM(valor_removido) FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_categoria_mensal`) - (SELECT SUM(IF(is_removido, valor, 0)) FROM `vanguardamartech_trusted`.`trs_contazul__movimento`)) > 0.01, 1, 0)
  UNION ALL SELECT 'rfn_financeiro__contazul_categoria_mensal.pago_e_nao_pago_reproduzem_a_trusted', 'Refined', 'rfn_financeiro__contazul_categoria_mensal', 'CONTA_AZUL', 'VALIDADE',
         'a soma de valor_pago_vigente e de valor_nao_pago_vigente reproduz as parcelas vigentes de trs_contazul__movimento dentro de um centavo, cada uma', 'BLOQUEANTE', 1.00,
         1, IF(ABS((SELECT SUM(valor_pago_vigente) FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_categoria_mensal`) - (SELECT SUM(IF(is_vigente, valor_pago, 0)) FROM `vanguardamartech_trusted`.`trs_contazul__movimento`)) > 0.01
              OR ABS((SELECT SUM(valor_nao_pago_vigente) FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_categoria_mensal`) - (SELECT SUM(IF(is_vigente, valor_nao_pago, 0)) FROM `vanguardamartech_trusted`.`trs_contazul__movimento`)) > 0.01, 1, 0)
  UNION ALL SELECT 'rfn_financeiro__contazul_entidade_resumo.entidades_reproduzem_a_trusted', 'Refined', 'rfn_financeiro__contazul_entidade_resumo', 'CONTA_AZUL', 'VALIDADE',
         'a soma de qtd_entidades reproduz as linhas de trs_contazul__entidade', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(qtd_entidades) FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_entidade_resumo`) <> (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_contazul__entidade`), 1, 0)
  UNION ALL SELECT 'rfn_financeiro__contazul_entidade_resumo.cadastros_reproduzem_a_trusted', 'Refined', 'rfn_financeiro__contazul_entidade_resumo', 'CONTA_AZUL', 'VALIDADE',
         'a soma de qtd_cadastros reproduz a soma de qtd_cadastros de trs_contazul__entidade', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(qtd_cadastros) FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_entidade_resumo`) <> (SELECT SUM(qtd_cadastros) FROM `vanguardamartech_trusted`.`trs_contazul__entidade`), 1, 0)
  UNION ALL SELECT 'rfn_financeiro__contazul_vinculo_resumo.vinculos_reproduzem_a_trusted', 'Refined', 'rfn_financeiro__contazul_vinculo_resumo', 'CONTA_AZUL', 'VALIDADE',
         'a soma de qtd_vinculos reproduz as linhas de trs_contazul__vinculo', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(qtd_vinculos) FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_vinculo_resumo`) <> (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_contazul__vinculo`), 1, 0)
  UNION ALL SELECT 'rfn_operacao__checklist_mensal.itens_reproduzem_a_trusted', 'Refined', 'rfn_operacao__checklist_mensal', 'VJOB', 'VALIDADE',
         'a soma de qtd_itens reproduz as linhas de trs_vjob__checklist_diario', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(qtd_itens) FROM `vanguardamartech_refined`.`rfn_operacao__checklist_mensal`) <> (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_vjob__checklist_diario`), 1, 0)
  UNION ALL SELECT 'rfn_operacao__checklist_mensal.marcados_reproduzem_a_trusted', 'Refined', 'rfn_operacao__checklist_mensal', 'VJOB', 'VALIDADE',
         'a soma de qtd_marcados reproduz os itens com is_marcado de trs_vjob__checklist_diario', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(qtd_marcados) FROM `vanguardamartech_refined`.`rfn_operacao__checklist_mensal`) <> (SELECT COUNTIF(is_marcado) FROM `vanguardamartech_trusted`.`trs_vjob__checklist_diario`), 1, 0)
  UNION ALL SELECT 'rfn_operacao__auditoria_ciclo_mensal.ciclos_reproduzem_a_trusted', 'Refined', 'rfn_operacao__auditoria_ciclo_mensal', 'VJOB', 'VALIDADE',
         'a soma de qtd_ciclos reproduz as linhas de trs_vjob__auditoria_ciclo', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(qtd_ciclos) FROM `vanguardamartech_refined`.`rfn_operacao__auditoria_ciclo_mensal`) <> (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_vjob__auditoria_ciclo`), 1, 0)
  UNION ALL SELECT 'rfn_operacao__auditoria_ciclo_mensal.itens_e_feitos_reproduzem_a_trusted', 'Refined', 'rfn_operacao__auditoria_ciclo_mensal', 'VJOB', 'VALIDADE',
         'a soma de qtd_itens e de qtd_itens_feitos reproduz trs_vjob__auditoria_ciclo, cada uma', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(qtd_itens) FROM `vanguardamartech_refined`.`rfn_operacao__auditoria_ciclo_mensal`) <> (SELECT SUM(qtd_itens) FROM `vanguardamartech_trusted`.`trs_vjob__auditoria_ciclo`)
              OR (SELECT SUM(qtd_itens_feitos) FROM `vanguardamartech_refined`.`rfn_operacao__auditoria_ciclo_mensal`) <> (SELECT SUM(qtd_itens_feitos) FROM `vanguardamartech_trusted`.`trs_vjob__auditoria_ciclo`), 1, 0)
  UNION ALL SELECT 'rfn_operacao__anexo_diverso_mensal.anexos_reproduzem_a_trusted', 'Refined', 'rfn_operacao__anexo_diverso_mensal', 'VJOB', 'VALIDADE',
         'a soma de qtd_anexos reproduz as linhas de trs_vjob__anexo_diverso', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(qtd_anexos) FROM `vanguardamartech_refined`.`rfn_operacao__anexo_diverso_mensal`) <> (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_vjob__anexo_diverso`), 1, 0)
  UNION ALL SELECT 'rfn_operacao__biblioteca_mensal.itens_reproduzem_a_trusted', 'Refined', 'rfn_operacao__biblioteca_mensal', 'VJOB', 'VALIDADE',
         'a soma de qtd_itens reproduz as linhas de trs_vjob__biblioteca_item', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(qtd_itens) FROM `vanguardamartech_refined`.`rfn_operacao__biblioteca_mensal`) <> (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_vjob__biblioteca_item`), 1, 0)
  UNION ALL SELECT 'rfn_operacao__compromisso_mensal.compromissos_reproduzem_a_trusted', 'Refined', 'rfn_operacao__compromisso_mensal', 'VJOB', 'VALIDADE',
         'a soma de qtd_compromissos reproduz as linhas de trs_vjob__compromisso', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(qtd_compromissos) FROM `vanguardamartech_refined`.`rfn_operacao__compromisso_mensal`) <> (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_vjob__compromisso`), 1, 0)
  UNION ALL SELECT 'rfn_operacao__config_cliente_resumo.registros_reproduzem_a_trusted', 'Refined', 'rfn_operacao__config_cliente_resumo', 'VJOB', 'VALIDADE',
         'a soma de qtd_registros reproduz as linhas de trs_vjob__config_cliente', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(qtd_registros) FROM `vanguardamartech_refined`.`rfn_operacao__config_cliente_resumo`) <> (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_vjob__config_cliente`), 1, 0)
  UNION ALL SELECT 'rfn_operacao__dominio_resumo.itens_reproduzem_a_trusted', 'Refined', 'rfn_operacao__dominio_resumo', 'VJOB', 'VALIDADE',
         'a soma de qtd_itens reproduz as linhas de trs_vjob__dominio', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(qtd_itens) FROM `vanguardamartech_refined`.`rfn_operacao__dominio_resumo`) <> (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_vjob__dominio`), 1, 0)
  UNION ALL SELECT 'rfn_operacao__escopo_data_extra_mensal.datas_reproduzem_a_trusted', 'Refined', 'rfn_operacao__escopo_data_extra_mensal', 'VJOB', 'VALIDADE',
         'a soma de qtd_datas_extras reproduz as linhas de trs_vjob__escopo_data_extra', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(qtd_datas_extras) FROM `vanguardamartech_refined`.`rfn_operacao__escopo_data_extra_mensal`) <> (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_vjob__escopo_data_extra`), 1, 0)
  UNION ALL SELECT 'rfn_operacao__evento_sistema_mensal.eventos_reproduzem_a_trusted', 'Refined', 'rfn_operacao__evento_sistema_mensal', 'VJOB', 'VALIDADE',
         'a soma de qtd_eventos reproduz as linhas de trs_vjob__evento_sistema', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(qtd_eventos) FROM `vanguardamartech_refined`.`rfn_operacao__evento_sistema_mensal`) <> (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_vjob__evento_sistema`), 1, 0)
  UNION ALL SELECT 'rfn_operacao__job_aprovacao_inicial_mensal.aprovacoes_reproduzem_a_trusted', 'Refined', 'rfn_operacao__job_aprovacao_inicial_mensal', 'VJOB', 'VALIDADE',
         'a soma de qtd_aprovacoes reproduz as linhas de trs_vjob__job_aprovacao_inicial', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(qtd_aprovacoes) FROM `vanguardamartech_refined`.`rfn_operacao__job_aprovacao_inicial_mensal`) <> (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_vjob__job_aprovacao_inicial`), 1, 0)
  -- DECOMPOSICOES E INVARIANTES por linha
  UNION ALL SELECT 'rfn_financeiro__contazul_categoria_mensal.vigentes_mais_removidas_e_o_total', 'Refined', 'rfn_financeiro__contazul_categoria_mensal', 'CONTA_AZUL', 'VALIDADE',
         'parcelas vigentes + removidas = total em toda linha (vigente e removida nao se sobrepoem)', 'BLOQUEANTE', 1.00, COUNT(*),
         COUNTIF(qtd_parcelas_vigentes + qtd_removidas <> qtd_parcelas_total)
  FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_categoria_mensal`
  UNION ALL SELECT 'rfn_financeiro__contazul_categoria_mensal.valores_nunca_negativos', 'Refined', 'rfn_financeiro__contazul_categoria_mensal', 'CONTA_AZUL', 'VALIDADE',
         'valor_vigente e valor_removido nunca sao negativos (o sinal esta so em valor_vigente_com_sinal)', 'BLOQUEANTE', 1.00, COUNT(*),
         COUNTIF(valor_vigente < 0 OR valor_removido < 0)
  FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_categoria_mensal`
  UNION ALL SELECT 'rfn_financeiro__contazul_entidade_resumo.documento_valido_nao_excede_as_entidades', 'Refined', 'rfn_financeiro__contazul_entidade_resumo', 'CONTA_AZUL', 'VALIDADE',
         'qtd_com_documento_valido <= qtd_entidades em toda linha', 'BLOQUEANTE', 1.00, COUNT(*),
         COUNTIF(qtd_com_documento_valido > qtd_entidades)
  FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_entidade_resumo`
  UNION ALL SELECT 'rfn_financeiro__contazul_vinculo_resumo.manuais_e_resolvidos_nao_excedem_os_vinculos', 'Refined', 'rfn_financeiro__contazul_vinculo_resumo', 'CONTA_AZUL', 'VALIDADE',
         'qtd_manuais e qtd_resolvidos_nos_dois_lados <= qtd_vinculos em toda linha', 'BLOQUEANTE', 1.00, COUNT(*),
         COUNTIF(qtd_manuais > qtd_vinculos OR qtd_resolvidos_nos_dois_lados > qtd_vinculos)
  FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_vinculo_resumo`
  UNION ALL SELECT 'rfn_operacao__checklist_mensal.momento_da_marcacao_decompoe', 'Refined', 'rfn_operacao__checklist_mensal', 'VJOB', 'VALIDADE',
         'marcados no dia + depois + antes = marcados em toda linha', 'BLOQUEANTE', 1.00, COUNT(*),
         COUNTIF(qtd_marcados_no_dia + qtd_marcados_depois + qtd_marcados_antes <> qtd_marcados)
  FROM `vanguardamartech_refined`.`rfn_operacao__checklist_mensal`
  UNION ALL SELECT 'rfn_operacao__checklist_mensal.taxas_entre_zero_e_um', 'Refined', 'rfn_operacao__checklist_mensal', 'VJOB', 'VALIDADE',
         'taxa_marcacao e taxa_pontualidade estao entre 0 e 1 quando existem', 'BLOQUEANTE', 1.00, COUNT(*),
         COUNTIF(taxa_marcacao < 0 OR taxa_marcacao > 1 OR taxa_pontualidade < 0 OR taxa_pontualidade > 1)
  FROM `vanguardamartech_refined`.`rfn_operacao__checklist_mensal`
  UNION ALL SELECT 'rfn_operacao__auditoria_ciclo_mensal.taxa_acima_de_um_so_com_marcacao_em_item_inativo', 'Refined', 'rfn_operacao__auditoria_ciclo_mensal', 'VJOB', 'VALIDADE',
         'taxa_conclusao so passa de 1 em linha com ciclo de feitos acima dos ativos (marcacao sobre item inativo); sem isso a taxa nunca passa de 1', 'BLOQUEANTE', 1.00, COUNT(*),
         COUNTIF(taxa_conclusao > 1 AND qtd_ciclos_feitos_acima_dos_ativos = 0)
  FROM `vanguardamartech_refined`.`rfn_operacao__auditoria_ciclo_mensal`
  UNION ALL SELECT 'rfn_operacao__biblioteca_mensal.sem_destino_reproduz_a_trusted', 'Refined', 'rfn_operacao__biblioteca_mensal', 'VJOB', 'VALIDADE',
         'a soma de qtd_sem_destino reproduz os itens com flag_sem_destino da Trusted (item sem URL e sem arquivo)', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(qtd_sem_destino) FROM `vanguardamartech_refined`.`rfn_operacao__biblioteca_mensal`) <> (SELECT COUNTIF(flag_sem_destino) FROM `vanguardamartech_trusted`.`trs_vjob__biblioteca_item`), 1, 0)
  UNION ALL SELECT 'rfn_operacao__dominio_resumo.estado_ativo_decompoe', 'Refined', 'rfn_operacao__dominio_resumo', 'VJOB', 'VALIDADE',
         'ativos + inativos + sem flag ativo = itens em todo dominio (NULO nao e inativo)', 'BLOQUEANTE', 1.00, COUNT(*),
         COUNTIF(qtd_ativos + qtd_inativos + qtd_sem_flag_ativo <> qtd_itens)
  FROM `vanguardamartech_refined`.`rfn_operacao__dominio_resumo`
  UNION ALL SELECT 'rfn_operacao__evento_sistema_mensal.telefone_nao_excede_o_total', 'Refined', 'rfn_operacao__evento_sistema_mensal', 'VJOB', 'VALIDADE',
         'telefones fora de forma <= eventos com telefone <= eventos em toda linha (a Refined conta telefone, nunca o emite)', 'BLOQUEANTE', 1.00, COUNT(*),
         COUNTIF(qtd_telefone_fora_de_forma > qtd_com_telefone OR qtd_com_telefone > qtd_eventos)
  FROM `vanguardamartech_refined`.`rfn_operacao__evento_sistema_mensal`
  UNION ALL SELECT 'rfn_operacao__job_aprovacao_inicial_mensal.decisao_decompoe', 'Refined', 'rfn_operacao__job_aprovacao_inicial_mensal', 'VJOB', 'VALIDADE',
         'aprovadas + recusadas + pendentes = aprovacoes em toda linha', 'BLOQUEANTE', 1.00, COUNT(*),
         COUNTIF(qtd_aprovadas + qtd_recusadas + qtd_pendentes <> qtd_aprovacoes)
  FROM `vanguardamartech_refined`.`rfn_operacao__job_aprovacao_inicial_mensal`
  UNION ALL SELECT 'rfn_operacao__job_aprovacao_inicial_mensal.taxa_entre_zero_e_um', 'Refined', 'rfn_operacao__job_aprovacao_inicial_mensal', 'VJOB', 'VALIDADE',
         'taxa_aprovacao esta entre 0 e 1 quando existe', 'BLOQUEANTE', 1.00, COUNTIF(taxa_aprovacao IS NOT NULL),
         COUNTIF(taxa_aprovacao < 0 OR taxa_aprovacao > 1)
  FROM `vanguardamartech_refined`.`rfn_operacao__job_aprovacao_inicial_mensal`
  -- LINHAS DE BASE (ALERTA): buraco de origem ja conhecido; o limiar existe para detectar PIORA
  UNION ALL SELECT 'rfn_financeiro__contazul_categoria_mensal.categoria_no_cadastro', 'Refined', 'rfn_financeiro__contazul_categoria_mensal', 'CONTA_AZUL', 'INTEGRIDADE',
         'parcelas cuja categoria existe no cadastro de categoria (linha de base: o movimento carrega id que o cadastro nao tem)', 'ALERTA', 0.78,
         SUM(qtd_parcelas_total), SUM(IF(flag_id_fora_do_cadastro, qtd_parcelas_total, 0))
  FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_categoria_mensal`
  UNION ALL SELECT 'rfn_operacao__dominio_resumo.pai_no_dominio', 'Refined', 'rfn_operacao__dominio_resumo', 'VJOB', 'INTEGRIDADE',
         'itens com pai cujo pai existe no dominio (linha de base: ha itens com pai fora do dominio de origem)', 'ALERTA', 0.75,
         SUM(qtd_com_pai), SUM(qtd_pai_nao_catalogado)
  FROM `vanguardamartech_refined`.`rfn_operacao__dominio_resumo`
  UNION ALL SELECT 'rfn_operacao__job_aprovacao_inicial_mensal.job_catalogado', 'Refined', 'rfn_operacao__job_aprovacao_inicial_mensal', 'VJOB', 'INTEGRIDADE',
         'aprovacoes cujo job existe nas Trusted de job (linha de base: ha aprovacao apontando para job nao catalogado)', 'ALERTA', 0.85,
         SUM(qtd_aprovacoes), SUM(qtd_job_nao_catalogado)
  FROM `vanguardamartech_refined`.`rfn_operacao__job_aprovacao_inicial_mensal`
  -- FRESCOR: as 13 foram reescritas na mesma passada
  UNION ALL SELECT 'refined_vjob_contazul.carga_do_mesmo_dia', 'Refined', '(as 13 Refined do lote)', 'VJOB', 'INTEGRIDADE',
         'as 13 Refined do lote foram escritas na mesma data de carga (DATE(_extraido_at))', 'BLOQUEANTE', 1.00, 1,
         IF(COUNT(DISTINCT d) > 1, 1, 0)
  FROM (
    SELECT DATE(MAX(_extraido_at)) AS d FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_categoria_mensal`
    UNION ALL SELECT DATE(MAX(_extraido_at)) FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_entidade_resumo`
    UNION ALL SELECT DATE(MAX(_extraido_at)) FROM `vanguardamartech_refined`.`rfn_financeiro__contazul_vinculo_resumo`
    UNION ALL SELECT DATE(MAX(_extraido_at)) FROM `vanguardamartech_refined`.`rfn_operacao__checklist_mensal`
    UNION ALL SELECT DATE(MAX(_extraido_at)) FROM `vanguardamartech_refined`.`rfn_operacao__auditoria_ciclo_mensal`
    UNION ALL SELECT DATE(MAX(_extraido_at)) FROM `vanguardamartech_refined`.`rfn_operacao__anexo_diverso_mensal`
    UNION ALL SELECT DATE(MAX(_extraido_at)) FROM `vanguardamartech_refined`.`rfn_operacao__biblioteca_mensal`
    UNION ALL SELECT DATE(MAX(_extraido_at)) FROM `vanguardamartech_refined`.`rfn_operacao__compromisso_mensal`
    UNION ALL SELECT DATE(MAX(_extraido_at)) FROM `vanguardamartech_refined`.`rfn_operacao__config_cliente_resumo`
    UNION ALL SELECT DATE(MAX(_extraido_at)) FROM `vanguardamartech_refined`.`rfn_operacao__dominio_resumo`
    UNION ALL SELECT DATE(MAX(_extraido_at)) FROM `vanguardamartech_refined`.`rfn_operacao__escopo_data_extra_mensal`
    UNION ALL SELECT DATE(MAX(_extraido_at)) FROM `vanguardamartech_refined`.`rfn_operacao__evento_sistema_mensal`
    UNION ALL SELECT DATE(MAX(_extraido_at)) FROM `vanguardamartech_refined`.`rfn_operacao__job_aprovacao_inicial_mensal`
  )
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
  'REFINED_VJOB_CONTAZUL' AS familia, CURRENT_TIMESTAMP() AS _extraido_at, 'mysql-yIOn' AS _fonte, 'America/Sao_Paulo' AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(a))) AS _payload_hash
FROM avaliado a
