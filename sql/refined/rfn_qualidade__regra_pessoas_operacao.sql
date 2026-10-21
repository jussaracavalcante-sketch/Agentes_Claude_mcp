-- rfn_qualidade__regra_pessoas_operacao · 55 regras · L2 INTERNAL
-- Refined / qualidade. Grao: uma REGRA em uma execucao. Gatilho: evento com regra "all" nas 4 Refined do supabase-x0tz
-- (query-FWn0 headcount, query-CzUs peca_grupo, query-e7sq tempo_padrao, query-WEBt pessoa_canonica_resumo). Alerta ligado. Cadencia DIARIA.
-- A Refined de noticias (query-Ov5C, MySQL semanal) NAO entra no gatilho de proposito: um "all" com cadencias diferentes faria a suite rodar so
-- semanalmente. Ela e medida como estiver materializada, como a suite de cadastro faz com as cadeias de cadencia diferente.
-- Cobre as 6 Trusted e as 5 Refined criadas em 19/10/2026 sobre supabase_gold_headcount_snapshot, supabase_gold_vw_peca_cliente_ponte,
-- supabase_meta_peca_etapa_tempo_padrao, supabase_meta_pessoa(_alias/_house) e tbnoticiasextra(2) do VJOB.
-- VALIDACAO (19/10/2026): query inteira rodada nas tabelas materializadas: 55 regras, 55 ids, 55 hashes, 55 CONFORME. Sete regras de ALERTA carregam falha
-- de linha como linha de base, todas medidas: mes sentinela 1.300/52.342 (limiar 0,97), peca nao catalogada 7.908/52.342 (0,80), executor fora da pessoa
-- canonica 5.562/52.342 (0,85), etapa sem canonica 4.433/11.942 (0,55), leitura fora da lista 36/462 (0,85), noticia nao catalogada 2.756/4.194 (0,25),
-- usuario nao catalogado 2.724/4.194 (0,25).
-- NAO ENTRAM, DE PROPOSITO: "padrao igual ao medido" no tempo padrao (hoje 11.302 de 11.302, mas o dia em que alguem editar um padrao e a melhoria esperada,
-- nao falha); qualquer regra sobre flag gravada comparada ao relogio; freshness entre x0tz e MySQL (cadencias diferentes).
WITH r AS (
  SELECT 'trs_rh__headcount_snapshot.id_headcount_unico' AS id_regra, 'Trusted' AS camada, 'trs_rh__headcount_snapshot' AS tabela, 'Pessoas' AS sistema, 'UNICIDADE' AS dimensao,
    'id_headcount (mes e area) e unico e nunca nulo (25 na medicao)' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
    COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_headcount) + COUNTIF(id_headcount IS NULL) AS linhas_falha FROM `vanguardamartech_trusted`.`trs_rh__headcount_snapshot`
  UNION ALL
  SELECT 'trs_rh__headcount_snapshot.soma_das_areas_fecha', 'Trusted', 'trs_rh__headcount_snapshot', 'Pessoas', 'INTEGRIDADE',
    'a soma das areas reproduz o total de colaboradores E de ativos da fotografia em todos os meses (25 de 25 na medicao)', 'BLOQUEANTE', 1.00,
    COUNT(*), COUNTIF(NOT flag_soma_area_fecha) FROM `vanguardamartech_trusted`.`trs_rh__headcount_snapshot`
  UNION ALL
  SELECT 'trs_rh__headcount_snapshot.ativos_nao_excedem_colaboradores', 'Trusted', 'trs_rh__headcount_snapshot', 'Pessoas', 'VALIDADE',
    'ativos nunca excede colaboradores, na area e no total', 'BLOQUEANTE', 1.00,
    COUNT(*), COUNTIF(qtd_ativos_area > qtd_colaboradores_area OR total_ativos > total_colaboradores) FROM `vanguardamartech_trusted`.`trs_rh__headcount_snapshot`
  UNION ALL
  SELECT 'trs_rh__headcount_snapshot.mes_e_primeiro_dia_e_nao_futuro', 'Trusted', 'trs_rh__headcount_snapshot', 'Pessoas', 'VALIDADE',
    'mes de referencia cai no dia 1 e nunca depois do mes da carga (regra sobre o DADO, com DATE(_extraido_at), nao sobre o relogio de quem le)', 'BLOQUEANTE', 1.00,
    COUNT(*), COUNTIF(EXTRACT(DAY FROM mes_referencia) <> 1 OR mes_referencia > DATE_TRUNC(DATE(_extraido_at), MONTH)) FROM `vanguardamartech_trusted`.`trs_rh__headcount_snapshot`
  UNION ALL
  SELECT 'trs_iclips__peca_grupo_cliente.id_job_peca_unico', 'Trusted', 'trs_iclips__peca_grupo_cliente', 'iClips', 'UNICIDADE',
    'id_job_peca e unico e nunca nulo: uma linha por peca (52.342 na medicao)', 'BLOQUEANTE', 1.00,
    COUNT(*), COUNT(*) - COUNT(DISTINCT id_job_peca) + COUNTIF(id_job_peca IS NULL) FROM `vanguardamartech_trusted`.`trs_iclips__peca_grupo_cliente`
  UNION ALL
  SELECT 'trs_iclips__peca_grupo_cliente.atribuivel_concorda_com_a_chave', 'Trusted', 'trs_iclips__peca_grupo_cliente', 'iClips', 'VALIDADE',
    'atribuivel e exatamente NOT sentinela (zero divergencias na medicao)', 'BLOQUEANTE', 1.00,
    COUNT(*), COUNTIF(flag_atribuivel_diverge_da_chave) FROM `vanguardamartech_trusted`.`trs_iclips__peca_grupo_cliente`
  UNION ALL
  SELECT 'trs_iclips__peca_grupo_cliente.chave_de_grupo_reconhecida', 'Trusted', 'trs_iclips__peca_grupo_cliente', 'iClips', 'VALIDADE',
    'toda chave de grupo cai numa das cinco formas conhecidas (GRUPO, NOME, CNPJ_RAIZ, CPF, SENTINELA): forma nova some da leitura sem a contagem mudar', 'BLOQUEANTE', 1.00,
    COUNT(*), COUNTIF(tipo_chave_grupo = 'OUTRO') FROM `vanguardamartech_trusted`.`trs_iclips__peca_grupo_cliente`
  UNION ALL
  SELECT 'trs_iclips__peca_grupo_cliente.mes_nulo_so_na_sentinela', 'Trusted', 'trs_iclips__peca_grupo_cliente', 'iClips', 'VALIDADE',
    'mes_referencia e NULL exatamente quando o ano e sentinela (1799): nunca data inventada, nunca sentinela vazada como data', 'BLOQUEANTE', 1.00,
    COUNT(*), COUNTIF((mes_referencia IS NULL) <> flag_mes_sentinela) FROM `vanguardamartech_trusted`.`trs_iclips__peca_grupo_cliente`
  UNION ALL
  SELECT 'trs_iclips__peca_grupo_cliente.mes_nao_sentinela', 'Trusted', 'trs_iclips__peca_grupo_cliente', 'iClips', 'COMPLETUDE',
    'LINHA DE BASE: pecas com mes valido (1.300 de 52.342 carregam o ano 1799 na origem, 97,5% validas)', 'ALERTA', 0.97,
    COUNT(*), COUNTIF(flag_mes_sentinela) FROM `vanguardamartech_trusted`.`trs_iclips__peca_grupo_cliente`
  UNION ALL
  SELECT 'trs_iclips__peca_grupo_cliente.peca_catalogada', 'Trusted', 'trs_iclips__peca_grupo_cliente', 'iClips', 'INTEGRIDADE',
    'LINHA DE BASE: peca da ponte existe em trs_iclips__peca (44.434 de 52.342, 84,9%); a Trusted de peca vem de outra fonte e outra cadencia', 'ALERTA', 0.80,
    COUNT(*), COUNTIF(flag_peca_nao_catalogada) FROM `vanguardamartech_trusted`.`trs_iclips__peca_grupo_cliente`
  UNION ALL
  SELECT 'trs_iclips__peca_grupo_cliente.tipo_de_peca_catalogado', 'Trusted', 'trs_iclips__peca_grupo_cliente', 'iClips', 'INTEGRIDADE',
    'tipo de peca da ponte existe em trs_iclips__peca_tipo (52.342 de 52.342 na medicao)', 'ALERTA', 0.99,
    COUNT(*), COUNTIF(flag_peca_tipo_nao_catalogada) FROM `vanguardamartech_trusted`.`trs_iclips__peca_grupo_cliente`
  UNION ALL
  SELECT 'trs_iclips__peca_grupo_cliente.executor_na_pessoa_canonica', 'Trusted', 'trs_iclips__peca_grupo_cliente', 'iClips', 'INTEGRIDADE',
    'LINHA DE BASE: executor da ponte existe na pessoa canonica (46.780 de 52.342, 89,4%); o resto pode ser a mesma pessoa com outra grafia', 'ALERTA', 0.85,
    COUNT(*), COUNTIF(flag_executor_fora_da_pessoa_canonica) FROM `vanguardamartech_trusted`.`trs_iclips__peca_grupo_cliente`
  UNION ALL
  SELECT 'trs_iclips__peca_etapa_tempo_padrao.id_tempo_padrao_unico', 'Trusted', 'trs_iclips__peca_etapa_tempo_padrao', 'iClips', 'UNICIDADE',
    'id_tempo_padrao (tipo e grafia crua da etapa) e unico e nunca nulo (11.942 na medicao)', 'BLOQUEANTE', 1.00,
    COUNT(*), COUNT(*) - COUNT(DISTINCT id_tempo_padrao) + COUNTIF(id_tempo_padrao IS NULL) FROM `vanguardamartech_trusted`.`trs_iclips__peca_etapa_tempo_padrao`
  UNION ALL
  SELECT 'trs_iclips__peca_etapa_tempo_padrao.zero_e_sentinela_virou_null', 'Trusted', 'trs_iclips__peca_etapa_tempo_padrao', 'iClips', 'VALIDADE',
    'minutos_padrao e NULL exatamente quando nao ha tempo medido, e quando existe e maior que zero (640 NULL e 11.302 positivos na medicao)', 'BLOQUEANTE', 1.00,
    COUNT(*), COUNTIF((minutos_padrao IS NULL) <> flag_sem_tempo_medido OR minutos_padrao <= 0) FROM `vanguardamartech_trusted`.`trs_iclips__peca_etapa_tempo_padrao`
  UNION ALL
  SELECT 'trs_iclips__peca_etapa_tempo_padrao.tipo_de_peca_catalogado', 'Trusted', 'trs_iclips__peca_etapa_tempo_padrao', 'iClips', 'INTEGRIDADE',
    'tipo de peca existe em trs_iclips__peca_tipo (515 de 515 tipos na medicao)', 'ALERTA', 0.99,
    COUNT(*), COUNTIF(flag_peca_tipo_nao_catalogada) FROM `vanguardamartech_trusted`.`trs_iclips__peca_etapa_tempo_padrao`
  UNION ALL
  SELECT 'trs_iclips__peca_etapa_tempo_padrao.etapa_com_canonica', 'Trusted', 'trs_iclips__peca_etapa_tempo_padrao', 'iClips', 'INTEGRIDADE',
    'LINHA DE BASE: etapa casa com dim_workflow_normalizado (7.509 de 11.942, 62,9%); a grafia crua e da origem', 'ALERTA', 0.55,
    COUNT(*), COUNTIF(flag_etapa_sem_canonica) FROM `vanguardamartech_trusted`.`trs_iclips__peca_etapa_tempo_padrao`
  UNION ALL
  SELECT 'trs_rh__pessoa_canonica.id_alias_unico', 'Trusted', 'trs_rh__pessoa_canonica', 'Pessoas', 'UNICIDADE',
    'id_alias (tipo e chave) e unico e nunca nulo (1.272 na medicao)', 'BLOQUEANTE', 1.00,
    COUNT(*), COUNT(*) - COUNT(DISTINCT id_alias) + COUNTIF(id_alias IS NULL) FROM `vanguardamartech_trusted`.`trs_rh__pessoa_canonica`
  UNION ALL
  SELECT 'trs_rh__pessoa_canonica.chave_unica_mesmo_sem_o_tipo', 'Trusted', 'trs_rh__pessoa_canonica', 'Pessoas', 'UNICIDADE',
    'a chave do alias e unica ate sem o tipo (1.272 distintas na medicao): se duas pessoas dividirem uma chave, a identidade resolve duas vezes', 'BLOQUEANTE', 1.00,
    COUNT(*), COUNT(*) - COUNT(DISTINCT chave) FROM `vanguardamartech_trusted`.`trs_rh__pessoa_canonica`
  UNION ALL
  SELECT 'trs_rh__pessoa_canonica.alias_aponta_para_pessoa', 'Trusted', 'trs_rh__pessoa_canonica', 'Pessoas', 'INTEGRIDADE',
    'todo alias aponta para pessoa existente (zero orfaos na medicao)', 'BLOQUEANTE', 1.00,
    COUNT(*), COUNTIF(flag_pessoa_nao_catalogada) FROM `vanguardamartech_trusted`.`trs_rh__pessoa_canonica`
  UNION ALL
  SELECT 'trs_rh__pessoa_canonica.documento_tem_forma', 'Trusted', 'trs_rh__pessoa_canonica', 'Pessoas', 'VALIDADE',
    'alias financeiro e CPF de 11 ou CNPJ de 14 digitos (241 na medicao, 161 CPF e 80 CNPJ, zero fora de forma)', 'BLOQUEANTE', 1.00,
    COUNTIF(match_tipo = 'FIN_CPF_CNPJ'), COUNTIF(tipo_documento = 'INVALIDO') FROM `vanguardamartech_trusted`.`trs_rh__pessoa_canonica`
  UNION ALL
  SELECT 'trs_rh__pessoa_canonica.toda_pessoa_tem_o_alias_do_nome', 'Trusted', 'trs_rh__pessoa_canonica', 'Pessoas', 'COMPLETUDE',
    'toda pessoa tem um alias NOME_NORM igual ao proprio nome canonico (294 de 294 na medicao); grao PESSOA, nao linha', 'BLOQUEANTE', 1.00,
    COUNT(*), COUNTIF(NOT ok) FROM (SELECT id_pessoa, LOGICAL_OR(flag_alias_e_o_nome_canonico) AS ok FROM `vanguardamartech_trusted`.`trs_rh__pessoa_canonica` GROUP BY id_pessoa)
  UNION ALL
  SELECT 'trs_rh__pessoa_house.id_house_unico', 'Trusted', 'trs_rh__pessoa_house', 'Pessoas', 'UNICIDADE',
    'id_house (pessoa e setor) e unico e nunca nulo (68 na medicao)', 'BLOQUEANTE', 1.00,
    COUNT(*), COUNT(*) - COUNT(DISTINCT id_house) + COUNTIF(id_house IS NULL) FROM `vanguardamartech_trusted`.`trs_rh__pessoa_house`
  UNION ALL
  SELECT 'trs_rh__pessoa_house.ninguem_em_dois_setores', 'Trusted', 'trs_rh__pessoa_house', 'Pessoas', 'UNICIDADE',
    'cada pessoa esta em um unico setor de housing (68 pessoas distintas em 68 linhas na medicao)', 'BLOQUEANTE', 1.00,
    COUNT(*), COUNT(*) - COUNT(DISTINCT pessoa_norm) FROM `vanguardamartech_trusted`.`trs_rh__pessoa_house`
  UNION ALL
  SELECT 'trs_rh__pessoa_house.setor_catalogado', 'Trusted', 'trs_rh__pessoa_house', 'Pessoas', 'INTEGRIDADE',
    'setor de housing existe em supabase_meta_param_no (18 de 18 na medicao)', 'ALERTA', 0.98,
    COUNT(*), COUNTIF(flag_setor_nao_catalogado) FROM `vanguardamartech_trusted`.`trs_rh__pessoa_house`
  UNION ALL
  SELECT 'trs_vjob__noticia_interacao.id_interacao_unico', 'Trusted', 'trs_vjob__noticia_interacao', 'VJOB', 'UNICIDADE',
    'id_interacao (tipo e id da origem) e unico e nunca nulo (4.194 na medicao)', 'BLOQUEANTE', 1.00,
    COUNT(*), COUNT(*) - COUNT(DISTINCT id_interacao) + COUNTIF(id_interacao IS NULL) FROM `vanguardamartech_trusted`.`trs_vjob__noticia_interacao`
  UNION ALL
  SELECT 'trs_vjob__noticia_interacao.so_a_leitura_tem_data', 'Trusted', 'trs_vjob__noticia_interacao', 'VJOB', 'VALIDADE',
    'LEITURA tem data e DESTINATARIO nunca tem: a lista de distribuicao nao e recibo (462 datadas e 3.732 sem data na medicao)', 'BLOQUEANTE', 1.00,
    COUNT(*), COUNTIF((tipo_interacao = 'LEITURA') <> (interagido_em IS NOT NULL)) FROM `vanguardamartech_trusted`.`trs_vjob__noticia_interacao`
  UNION ALL
  SELECT 'trs_vjob__noticia_interacao.leitura_nao_futura', 'Trusted', 'trs_vjob__noticia_interacao', 'VJOB', 'VALIDADE',
    'nenhuma leitura datada depois de agora (regra sobre o DADO; hora local gravada como UTC fica ate 3h no passado, nunca no futuro)', 'BLOQUEANTE', 1.00,
    COUNTIF(interagido_em IS NOT NULL), COUNTIF(interagido_em > CURRENT_TIMESTAMP()) FROM `vanguardamartech_trusted`.`trs_vjob__noticia_interacao`
  UNION ALL
  SELECT 'trs_vjob__noticia_interacao.flags_so_no_tipo_certo', 'Trusted', 'trs_vjob__noticia_interacao', 'VJOB', 'VALIDADE',
    'flag_leitura_fora_da_lista so acende em LEITURA e flag_destinatario_leu so em DESTINATARIO', 'BLOQUEANTE', 1.00,
    COUNT(*), COUNTIF((flag_leitura_fora_da_lista AND tipo_interacao <> 'LEITURA') OR (flag_destinatario_leu AND tipo_interacao <> 'DESTINATARIO')) FROM `vanguardamartech_trusted`.`trs_vjob__noticia_interacao`
  UNION ALL
  SELECT 'trs_vjob__noticia_interacao.leitura_dentro_da_lista', 'Trusted', 'trs_vjob__noticia_interacao', 'VJOB', 'INTEGRIDADE',
    'LINHA DE BASE: leitura de quem estava na lista de distribuicao (426 de 462, 92,2%); 36 leituras fora da lista sao da origem', 'ALERTA', 0.85,
    COUNTIF(tipo_interacao = 'LEITURA'), COUNTIF(flag_leitura_fora_da_lista) FROM `vanguardamartech_trusted`.`trs_vjob__noticia_interacao`
  UNION ALL
  SELECT 'trs_vjob__noticia_interacao.noticia_catalogada', 'Trusted', 'trs_vjob__noticia_interacao', 'VJOB', 'INTEGRIDADE',
    'LINHA DE BASE: interacao cuja noticia ainda existe em tbnoticias (1.438 de 4.194, 34,3%); so 8 noticias vivas de 54, o resto foi apagado na origem', 'ALERTA', 0.25,
    COUNT(*), COUNTIF(flag_noticia_nao_catalogada) FROM `vanguardamartech_trusted`.`trs_vjob__noticia_interacao`
  UNION ALL
  SELECT 'trs_vjob__noticia_interacao.usuario_catalogado', 'Trusted', 'trs_vjob__noticia_interacao', 'VJOB', 'INTEGRIDADE',
    'LINHA DE BASE: interacao cujo usuario existe em tbusuariointranet (1.470 de 4.194, 35,1%); o resto e gente que saiu do cadastro', 'ALERTA', 0.25,
    COUNT(*), COUNTIF(flag_usuario_nao_catalogado) FROM `vanguardamartech_trusted`.`trs_vjob__noticia_interacao`
  UNION ALL
  SELECT 'rfn_rh__headcount_mensal.id_headcount_mensal_unico', 'Refined', 'rfn_rh__headcount_mensal', 'Pessoas', 'UNICIDADE',
    'id_headcount_mensal (mes) e unico e nunca nulo (5 na medicao)', 'BLOQUEANTE', 1.00,
    COUNT(*), COUNT(*) - COUNT(DISTINCT id_headcount_mensal) + COUNTIF(id_headcount_mensal IS NULL) FROM `vanguardamartech_refined`.`rfn_rh__headcount_mensal`
  UNION ALL
  SELECT 'rfn_rh__headcount_mensal.reproduz_a_trusted', 'Refined', 'rfn_rh__headcount_mensal', 'Pessoas', 'INTEGRIDADE',
    'meses = meses distintos da Trusted, soma de qtd_areas = linhas da Trusted e soma de colaboradores das areas = soma da Trusted (5, 25 e 729 na medicao)', 'BLOQUEANTE', 1.00,
    1, IF((SELECT COUNT(*) FROM `vanguardamartech_refined`.`rfn_rh__headcount_mensal`) = (SELECT COUNT(DISTINCT mes_referencia) FROM `vanguardamartech_trusted`.`trs_rh__headcount_snapshot`) AND (SELECT SUM(qtd_areas) FROM `vanguardamartech_refined`.`rfn_rh__headcount_mensal`) = (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_rh__headcount_snapshot`) AND (SELECT SUM(soma_colaboradores_areas) FROM `vanguardamartech_refined`.`rfn_rh__headcount_mensal`) = (SELECT SUM(qtd_colaboradores_area) FROM `vanguardamartech_trusted`.`trs_rh__headcount_snapshot`), 0, 1) FROM UNNEST([1])
  UNION ALL
  SELECT 'rfn_rh__headcount_mensal.total_bate_com_as_areas', 'Refined', 'rfn_rh__headcount_mensal', 'Pessoas', 'INTEGRIDADE',
    'o total da fotografia (colaboradores e ativos) e igual a soma das areas em todo mes', 'BLOQUEANTE', 1.00,
    COUNT(*), COUNTIF(total_colaboradores <> soma_colaboradores_areas OR total_ativos <> soma_ativos_areas OR NOT flag_soma_area_fecha) FROM `vanguardamartech_refined`.`rfn_rh__headcount_mensal`
  UNION ALL
  SELECT 'rfn_rh__headcount_mensal.inativos_nunca_negativo', 'Refined', 'rfn_rh__headcount_mensal', 'Pessoas', 'VALIDADE',
    'qtd_inativos (colaboradores menos ativos) nunca e negativo e pct_ativos fica entre 0 e 1', 'BLOQUEANTE', 1.00,
    COUNT(*), COUNTIF(qtd_inativos < 0 OR pct_ativos < 0 OR pct_ativos > 1) FROM `vanguardamartech_refined`.`rfn_rh__headcount_mensal`
  UNION ALL
  SELECT 'rfn_operacao__peca_grupo_mensal.id_peca_grupo_mensal_unico', 'Refined', 'rfn_operacao__peca_grupo_mensal', 'iClips', 'UNICIDADE',
    'id_peca_grupo_mensal (mes e grupo) e unico e nunca nulo (1.341 na medicao)', 'BLOQUEANTE', 1.00,
    COUNT(*), COUNT(*) - COUNT(DISTINCT id_peca_grupo_mensal) + COUNTIF(id_peca_grupo_mensal IS NULL) FROM `vanguardamartech_refined`.`rfn_operacao__peca_grupo_mensal`
  UNION ALL
  SELECT 'rfn_operacao__peca_grupo_mensal.reproduz_a_trusted', 'Refined', 'rfn_operacao__peca_grupo_mensal', 'iClips', 'INTEGRIDADE',
    'soma de qtd_pecas = pecas da Trusted, pecas em SEM_MES = pecas de mes sentinela, pecas nao atribuiveis preservadas e mesmos grupos (52.342, 1.300, 2.272 e 116 na medicao)', 'BLOQUEANTE', 1.00,
    1, IF((SELECT SUM(qtd_pecas) FROM `vanguardamartech_refined`.`rfn_operacao__peca_grupo_mensal`) = (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_iclips__peca_grupo_cliente`) AND (SELECT SUM(IF(flag_sem_mes, qtd_pecas, 0)) FROM `vanguardamartech_refined`.`rfn_operacao__peca_grupo_mensal`) = (SELECT COUNTIF(flag_mes_sentinela) FROM `vanguardamartech_trusted`.`trs_iclips__peca_grupo_cliente`) AND (SELECT SUM(IF(NOT atribuivel, qtd_pecas, 0)) FROM `vanguardamartech_refined`.`rfn_operacao__peca_grupo_mensal`) = (SELECT COUNTIF(NOT atribuivel) FROM `vanguardamartech_trusted`.`trs_iclips__peca_grupo_cliente`) AND (SELECT COUNT(DISTINCT grupo_key) FROM `vanguardamartech_refined`.`rfn_operacao__peca_grupo_mensal`) = (SELECT COUNT(DISTINCT grupo_key) FROM `vanguardamartech_trusted`.`trs_iclips__peca_grupo_cliente`), 0, 1) FROM UNNEST([1])
  UNION ALL
  SELECT 'rfn_operacao__peca_grupo_mensal.participacao_soma_um_no_mes', 'Refined', 'rfn_operacao__peca_grupo_mensal', 'iClips', 'INTEGRIDADE',
    'a participacao dos grupos soma 1 dentro de cada mes (grao MES, nao linha; desvio maximo 8e-16 na medicao)', 'BLOQUEANTE', 1.00,
    COUNT(*), COUNTIF(ABS(s - 1) > 0.000000001) FROM (SELECT mes_referencia, SUM(participacao_no_mes) AS s FROM `vanguardamartech_refined`.`rfn_operacao__peca_grupo_mensal` GROUP BY mes_referencia)
  UNION ALL
  SELECT 'rfn_operacao__peca_grupo_mensal.mes_nulo_so_na_chave_sem_mes', 'Refined', 'rfn_operacao__peca_grupo_mensal', 'iClips', 'VALIDADE',
    'mes NULL so existe com flag_sem_mes e a chave SEM_MES, e vice-versa (64 linhas na medicao)', 'BLOQUEANTE', 1.00,
    COUNT(*), COUNTIF((mes_referencia IS NULL) <> flag_sem_mes OR (STARTS_WITH(id_peca_grupo_mensal, 'SEM_MES|') <> flag_sem_mes)) FROM `vanguardamartech_refined`.`rfn_operacao__peca_grupo_mensal`
  UNION ALL
  SELECT 'rfn_operacao__tempo_padrao_tipo.id_peca_tipo_unico', 'Refined', 'rfn_operacao__tempo_padrao_tipo', 'iClips', 'UNICIDADE',
    'id_peca_tipo e unico e nunca nulo (515 na medicao)', 'BLOQUEANTE', 1.00,
    COUNT(*), COUNT(*) - COUNT(DISTINCT id_peca_tipo) + COUNTIF(id_peca_tipo IS NULL) FROM `vanguardamartech_refined`.`rfn_operacao__tempo_padrao_tipo`
  UNION ALL
  SELECT 'rfn_operacao__tempo_padrao_tipo.reproduz_a_trusted', 'Refined', 'rfn_operacao__tempo_padrao_tipo', 'iClips', 'INTEGRIDADE',
    'soma de linhas, de etapas com tempo e de minutos por grafia reproduz a Trusted, e os tipos sao os mesmos (11.942, 11.302, 721.970 e 515 na medicao)', 'BLOQUEANTE', 1.00,
    1, IF((SELECT SUM(qtd_linhas_etapa) FROM `vanguardamartech_refined`.`rfn_operacao__tempo_padrao_tipo`) = (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_iclips__peca_etapa_tempo_padrao`) AND (SELECT SUM(qtd_etapas_com_tempo) FROM `vanguardamartech_refined`.`rfn_operacao__tempo_padrao_tipo`) = (SELECT COUNTIF(minutos_padrao IS NOT NULL) FROM `vanguardamartech_trusted`.`trs_iclips__peca_etapa_tempo_padrao`) AND (SELECT SUM(soma_minutos_padrao_grafias) FROM `vanguardamartech_refined`.`rfn_operacao__tempo_padrao_tipo`) = (SELECT SUM(minutos_padrao) FROM `vanguardamartech_trusted`.`trs_iclips__peca_etapa_tempo_padrao`) AND (SELECT COUNT(*) FROM `vanguardamartech_refined`.`rfn_operacao__tempo_padrao_tipo`) = (SELECT COUNT(DISTINCT id_peca_tipo) FROM `vanguardamartech_trusted`.`trs_iclips__peca_etapa_tempo_padrao`), 0, 1) FROM UNNEST([1])
  UNION ALL
  SELECT 'rfn_operacao__tempo_padrao_tipo.soma_por_etapa_nunca_excede_a_por_grafia', 'Refined', 'rfn_operacao__tempo_padrao_tipo', 'iClips', 'INTEGRIDADE',
    'a soma por etapa normalizada (maior minuto entre grafias) nunca passa a soma por grafia: se passar, a deduplicacao inventou minutos', 'BLOQUEANTE', 1.00,
    COUNTIF(soma_minutos_padrao_etapas IS NOT NULL), COUNTIF(soma_minutos_padrao_etapas > soma_minutos_padrao_grafias) FROM `vanguardamartech_refined`.`rfn_operacao__tempo_padrao_tipo`
  UNION ALL
  SELECT 'rfn_operacao__tempo_padrao_tipo.tipo_sem_tempo_tem_soma_nula', 'Refined', 'rfn_operacao__tempo_padrao_tipo', 'iClips', 'VALIDADE',
    'tipo sem nenhuma etapa com tempo tem soma e mediana NULL, nunca zero (10 tipos na medicao)', 'BLOQUEANTE', 1.00,
    COUNT(*), COUNTIF(qtd_etapas_com_tempo = 0 AND (soma_minutos_padrao_grafias IS NOT NULL OR soma_minutos_padrao_etapas IS NOT NULL OR mediana_minutos_padrao IS NOT NULL)) FROM `vanguardamartech_refined`.`rfn_operacao__tempo_padrao_tipo`
  UNION ALL
  SELECT 'rfn_operacao__tempo_padrao_tipo.etapas_decompoem_as_linhas', 'Refined', 'rfn_operacao__tempo_padrao_tipo', 'iClips', 'VALIDADE',
    'etapas com tempo mais etapas sem tempo = linhas do tipo, e etapas normalizadas nunca excedem as linhas', 'BLOQUEANTE', 1.00,
    COUNT(*), COUNTIF(qtd_etapas_com_tempo + qtd_etapas_sem_tempo <> qtd_linhas_etapa OR qtd_etapas_normalizadas > qtd_linhas_etapa) FROM `vanguardamartech_refined`.`rfn_operacao__tempo_padrao_tipo`
  UNION ALL
  SELECT 'rfn_rh__pessoa_canonica_resumo.id_resumo_unico', 'Refined', 'rfn_rh__pessoa_canonica_resumo', 'Pessoas', 'UNICIDADE',
    'id_resumo (dimensao e chave) e unico e nunca nulo (23 na medicao)', 'BLOQUEANTE', 1.00,
    COUNT(*), COUNT(*) - COUNT(DISTINCT id_resumo) + COUNTIF(id_resumo IS NULL) FROM `vanguardamartech_refined`.`rfn_rh__pessoa_canonica_resumo`
  UNION ALL
  SELECT 'rfn_rh__pessoa_canonica_resumo.aliases_reproduzem_a_trusted', 'Refined', 'rfn_rh__pessoa_canonica_resumo', 'Pessoas', 'INTEGRIDADE',
    'soma dos aliases por tipo = linhas de trs_rh__pessoa_canonica (1.272 na medicao)', 'BLOQUEANTE', 1.00,
    1, IF((SELECT SUM(qtd_linhas) FROM `vanguardamartech_refined`.`rfn_rh__pessoa_canonica_resumo` WHERE dimensao = 'ALIAS_POR_TIPO') = (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_rh__pessoa_canonica`), 0, 1) FROM UNNEST([1])
  UNION ALL
  SELECT 'rfn_rh__pessoa_canonica_resumo.house_reproduz_a_trusted', 'Refined', 'rfn_rh__pessoa_canonica_resumo', 'Pessoas', 'INTEGRIDADE',
    'soma dos vinculos por setor = linhas de trs_rh__pessoa_house (68 na medicao)', 'BLOQUEANTE', 1.00,
    1, IF((SELECT SUM(qtd_linhas) FROM `vanguardamartech_refined`.`rfn_rh__pessoa_canonica_resumo` WHERE dimensao = 'HOUSE_POR_SETOR') = (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_rh__pessoa_house`), 0, 1) FROM UNNEST([1])
  UNION ALL
  SELECT 'rfn_rh__pessoa_canonica_resumo.todas_as_pessoas_tem_nome_norm', 'Refined', 'rfn_rh__pessoa_canonica_resumo', 'Pessoas', 'COMPLETUDE',
    'a cobertura NOME_NORM e igual ao total de pessoas canonicas da Trusted (294 de 294 na medicao)', 'BLOQUEANTE', 1.00,
    1, IF((SELECT qtd_pessoas_distintas FROM `vanguardamartech_refined`.`rfn_rh__pessoa_canonica_resumo` WHERE id_resumo = 'ALIAS_POR_TIPO|NOME_NORM') = (SELECT COUNT(DISTINCT id_pessoa) FROM `vanguardamartech_trusted`.`trs_rh__pessoa_canonica`) AND (SELECT MAX(total_pessoas_canonicas) FROM `vanguardamartech_refined`.`rfn_rh__pessoa_canonica_resumo`) = (SELECT COUNT(DISTINCT id_pessoa) FROM `vanguardamartech_trusted`.`trs_rh__pessoa_canonica`), 0, 1) FROM UNNEST([1])
  UNION ALL
  SELECT 'rfn_rh__pessoa_canonica_resumo.cobertura_entre_zero_e_um', 'Refined', 'rfn_rh__pessoa_canonica_resumo', 'Pessoas', 'VALIDADE',
    'cobertura da identidade por tipo de alias fica entre 0 e 1 e so existe na dimensao ALIAS_POR_TIPO', 'BLOQUEANTE', 1.00,
    COUNT(*), COUNTIF((dimensao = 'ALIAS_POR_TIPO' AND (cobertura_da_identidade IS NULL OR cobertura_da_identidade < 0 OR cobertura_da_identidade > 1)) OR (dimensao <> 'ALIAS_POR_TIPO' AND cobertura_da_identidade IS NOT NULL)) FROM `vanguardamartech_refined`.`rfn_rh__pessoa_canonica_resumo`
  UNION ALL
  SELECT 'rfn_operacao__noticia_alcance.id_noticia_alcance_unico', 'Refined', 'rfn_operacao__noticia_alcance', 'VJOB', 'UNICIDADE',
    'id_noticia_alcance e unico e nunca nulo (54 na medicao)', 'BLOQUEANTE', 1.00,
    COUNT(*), COUNT(*) - COUNT(DISTINCT id_noticia_alcance) + COUNTIF(id_noticia_alcance IS NULL) FROM `vanguardamartech_refined`.`rfn_operacao__noticia_alcance`
  UNION ALL
  SELECT 'rfn_operacao__noticia_alcance.leituras_reproduzem_a_trusted', 'Refined', 'rfn_operacao__noticia_alcance', 'VJOB', 'INTEGRIDADE',
    'soma de qtd_leituras = leituras da Trusted e noticias = noticias distintas da Trusted (462 e 54 na medicao)', 'BLOQUEANTE', 1.00,
    1, IF((SELECT SUM(qtd_leituras) FROM `vanguardamartech_refined`.`rfn_operacao__noticia_alcance`) = (SELECT COUNTIF(tipo_interacao = 'LEITURA') FROM `vanguardamartech_trusted`.`trs_vjob__noticia_interacao`) AND (SELECT COUNT(*) FROM `vanguardamartech_refined`.`rfn_operacao__noticia_alcance`) = (SELECT COUNT(DISTINCT id_noticia) FROM `vanguardamartech_trusted`.`trs_vjob__noticia_interacao`), 0, 1) FROM UNNEST([1])
  UNION ALL
  SELECT 'rfn_operacao__noticia_alcance.destinatarios_reproduzem_a_trusted', 'Refined', 'rfn_operacao__noticia_alcance', 'VJOB', 'INTEGRIDADE',
    'soma de qtd_destinatarios e de destinatarios que leram reproduz a Trusted (3.732 e 426 na medicao)', 'BLOQUEANTE', 1.00,
    1, IF((SELECT SUM(qtd_destinatarios) FROM `vanguardamartech_refined`.`rfn_operacao__noticia_alcance`) = (SELECT COUNTIF(tipo_interacao = 'DESTINATARIO') FROM `vanguardamartech_trusted`.`trs_vjob__noticia_interacao`) AND (SELECT SUM(qtd_destinatarios_que_leram) FROM `vanguardamartech_refined`.`rfn_operacao__noticia_alcance`) = (SELECT COUNTIF(flag_destinatario_leu) FROM `vanguardamartech_trusted`.`trs_vjob__noticia_interacao`), 0, 1) FROM UNNEST([1])
  UNION ALL
  SELECT 'rfn_operacao__noticia_alcance.leitura_se_decompoe', 'Refined', 'rfn_operacao__noticia_alcance', 'VJOB', 'INTEGRIDADE',
    'leituras = leituras de destinatario + leituras fora da lista em toda noticia', 'BLOQUEANTE', 1.00,
    COUNT(*), COUNTIF(qtd_leituras <> qtd_leituras_de_destinatario + qtd_leituras_fora_da_lista) FROM `vanguardamartech_refined`.`rfn_operacao__noticia_alcance`
  UNION ALL
  SELECT 'rfn_operacao__noticia_alcance.taxa_coerente_com_a_lista', 'Refined', 'rfn_operacao__noticia_alcance', 'VJOB', 'VALIDADE',
    'taxa_leitura_da_lista e NULL exatamente sem lista, nunca zero, e fica entre 0 e 1 (1 noticia sem lista na medicao)', 'BLOQUEANTE', 1.00,
    COUNT(*), COUNTIF((taxa_leitura_da_lista IS NULL) <> flag_sem_lista OR taxa_leitura_da_lista < 0 OR taxa_leitura_da_lista > 1) FROM `vanguardamartech_refined`.`rfn_operacao__noticia_alcance`
  UNION ALL
  SELECT 'pessoas_operacao.x0tz_carga_do_mesmo_dia', 'Trusted', '(as 5 Trusted do supabase-x0tz)', 'Pessoas', 'VALIDADE',
    'as 5 Trusted que vem do supabase-x0tz foram escritas na mesma passada (a trs_vjob__noticia_interacao vem do MySQL semanal e fica de fora: cadencia diferente)', 'BLOQUEANTE', 1.00,
    1, IF(COUNT(DISTINCT d) = 1, 0, 1) FROM (SELECT MAX(DATE(_extraido_at)) AS d FROM `vanguardamartech_trusted`.`trs_rh__headcount_snapshot` UNION ALL SELECT MAX(DATE(_extraido_at)) AS d FROM `vanguardamartech_trusted`.`trs_iclips__peca_grupo_cliente` UNION ALL SELECT MAX(DATE(_extraido_at)) AS d FROM `vanguardamartech_trusted`.`trs_iclips__peca_etapa_tempo_padrao` UNION ALL SELECT MAX(DATE(_extraido_at)) AS d FROM `vanguardamartech_trusted`.`trs_rh__pessoa_canonica` UNION ALL SELECT MAX(DATE(_extraido_at)) AS d FROM `vanguardamartech_trusted`.`trs_rh__pessoa_house`)
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
  'PESSOAS_OPERACAO' AS familia, CURRENT_TIMESTAMP() AS _extraido_at, 'multiplas' AS _fonte, 'America/Sao_Paulo' AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(a))) AS _payload_hash
FROM avaliado a
