-- rfn_qualidade__regra_midia_gold  ·  30 regras  ·  L2 INTERNAL
-- Refined / qualidade. Grao: uma REGRA de qualidade em uma execucao. Chave: id_regra
-- (a execucao se le em _extraido_at). Alerta ligado.
-- Gatilho: evento em query-skPU (rfn_midia__desempenho_diario), regra any.
--
-- POR QUE UMA NONA SUITE, E POR QUE NAO ENTROU NA DE MIDIA.
--   A `rfn_qualidade__regra_midia` (query-4tgF) cobre as TRUSTED de Google e Facebook
--   Ads -- conta, campanha, insight diario e os quatro breakdowns. Estas duas sao GOLD,
--   e somar 30 regras la exigiria reescrever a query inteira, que e o caso declarado de
--   "query grande demais e query que nao se conserta". A principal, pelo mesmo motivo,
--   esta fora de questao: 57 KB e 84 regras.
--   O CONTRATO DE COLUNAS E IDENTICO ao das outras oito -- um UNION ALL da o painel
--   unico e `familia` diz de onde veio cada linha. A casa passa a ter 294 regras em NOVE
--   tabelas: 84 na principal, 19 no Conta Azul, 9 no Gmail, 24 em Midia, 37 no VJOB,
--   33 no iClips, 24 em Marketing, 34 em Cadastro e 30 aqui.
--
-- O QUE FICAVA DE FORA: as duas Gold de midia, 89.586 linhas materializadas sem UMA
--   regra -- `rfn_midia__desempenho_diario` 86.267 (query-skPU) e `rfn_midia_off__pi`
--   3.319 (query-SguJ). A primeira e o data product de midia paga da casa; a segunda
--   espelha o Dashboard de Midia OFF do VJOB.
--
-- O GATILHO E UM SO, E AS DUAS VEM DE CADEIAS DIFERENTES.
--   `query-skPU` dispara em `query-tL4g` + `query-zF8L` com regra "all" (a cadeia do
--   Google Ads); `query-SguJ` dispara em `query-iX2P` (trs_pi__insercao, cadeia do PI).
--   Amarrar as duas com "all" faria uma falha em qualquer ramo impedir as 30 regras de
--   rodar -- a armadilha ja declarada na suite do VJOB. O gatilho e a Gold maior, e a do
--   PI e medida como estiver materializada. Pelo mesmo motivo NAO ha regra de frescor
--   aqui: as duas tabelas nao compartilham fonte, e uma regra de "carga do mesmo dia"
--   falharia POR DESENHO.
--
-- AS 30 REGRAS, MEDIDAS EM 2026-09-29 SOBRE A TABELA MATERIALIZADA, ANTES DE PUBLICAR.
-- Resultado esperado na primeira execucao: 28 CONFORMES e 2 ALERTAS CONFORMES por
-- limiar -- ZERO falhas.
--
-- AS QUATRO QUE GUARDAM PREMISSA DECLARADA NA PROPRIA DESCRICAO DA GOLD DE MIDIA PAGA:
--
--   1. `desempenho_diario.grao_misto_nunca_acende`. A descricao daquela tabela diz, com
--      todas as letras, que `flag_grao_misto` "marca o caso que NAO deve existir -- se
--      aparecer, a premissa da Trusted caiu e ha dupla contagem". Era afirmacao medida
--      uma vez (zero em 03/09/2026); agora e teste. Medido hoje: ZERO em 86.267.
--      BLOQUEANTE, limiar 1,00.
--
--   2. `desempenho_diario.investimento_reproduz_os_micros`. A regra 3 daquela tabela diz
--      que o investimento e somado em micros INT64 e dividido por 1e6 so na saida --
--      "somar o FLOAT64 acumula erro" -- e que o spend do Facebook e multiplicado por
--      1e6 para somar igual. Se a divisao ou a conversao de unidade escorregar, a
--      verba inteira muda de ordem de grandeza e a contagem de linhas nao muda.
--      Medido: 86.267 avaliadas, ZERO fora de meio centavo, NAS DUAS PLATAFORMAS.
--
--   3. `desempenho_diario.ctr_reproduz_a_razao_dos_totais`. A regra 4 diz que CTR, CPC,
--      CPM, CPA e as taxas sao RECALCULADOS DOS TOTAIS e nunca herdados linha a linha,
--      porque media de medias esta errada. O CTR e o unico dos derivados que reproduz a
--      razao ao centesimo em 100% das linhas com impressao (80.232, ZERO falhas) -- e
--      por isso e ele que vira regra. CPC e CPM NAO entraram: divergem em 372 e 12.210
--      linhas por arredondamento de duas casas sobre valores pequenos, e regra que
--      acusa o que e legitimo ensina a ignorar a suite.
--
--   4. `desempenho_diario.conversao_do_facebook_decompoe`. A regra 8 declara que
--      conversao no Facebook e leads + compras + conversas iniciadas em 7 dias -- uma
--      ESCOLHA que muda o CPA de R$ 8,39 para R$ 90,57, uma ordem de grandeza. As tres
--      parcelas ficam expostas justamente para quem quiser refazer a conta; a regra
--      garante que elas continuam somando o total. Medido: 39.843 avaliadas, ZERO.
--
-- E UMA QUINTA, DO LADO DO PI:
--   `midia_off__pi.toda_linha_tem_causa`. A regra 4 daquela tabela termina com
--   "VALIDADO ... e ZERO em 'sem causa identificada'. Toda linha tem causa". Era
--   validacao de um dia; agora e teste. Medido: 3.319 com motivo, ZERO sem.
--
-- AS OUTRAS QUE GUARDAM MECANISMO MEDIDO:
--   `desempenho_diario.registro_confiavel_nunca_convive_com_flag` -- a porta de entrada
--     para consumo. Escrita como IMPLICACAO (confiavel => nenhuma flag acesa) e nao como
--     igualdade, de proposito: a formula exata da coluna nao e observavel hoje porque
--     `flag_grao_misto` e FALSE em todas as linhas, e uma igualdade chutada viraria falso
--     positivo no dia em que a flag acender. A implicacao vale sob as duas leituras.
--   `desempenho_diario.conta_defasada_decompoe` -- o limiar de 9 dias e escolha declarada
--     e ligada a cadencia semanal das 46 fontes de midia. Se a cadencia mudar, este
--     numero muda com ela, e a regra e o lugar onde isso aparece. Hoje: 3.931 defasadas,
--     zero divergencia.
--   `desempenho_diario.pacing_nulo_em_orcamento_compartilhado` -- a regra 5 daquela
--     tabela: o teto vale para o conjunto de campanhas, entao o consumo nao se calcula.
--   `midia_off__pi.escopo_exclui_internet` -- a regra 1 usa LISTA NEGRA de um item
--     justamente para que tipo novo apareca. A regra guarda o unico item da lista.
--   `midia_off__pi.venda_conta_azul_implica_a_flag` -- tambem implicacao, nao igualdade:
--     `tem_conta_azul` esta TRUE em 3.063 linhas e `ca_n_vendas > 0` em 440, entao a
--     flag significa outra coisa. O que se pode afirmar, e se afirma, e que venda
--     registrada nunca aparece sem a flag. Medido: ZERO violacoes.
--
-- AS DUAS LINHAS DE BASE, DE PROPOSITO:
--   `midia_off__pi.liquido_mais_comissao_e_o_negociado`, ALERTA 0,999. Seria a SETIMA
--     identidade desta casa e a segunda a validar a aritmetica de um sistema de
--     terceiro (depois de `custo_reproduz_hora_vezes_valor_hora`, do iClips) -- mas ela
--     NAO fecha: 1 PI em 3.319 diverge, o 22236, com comissao R$ 1.000,01 contra
--     R$ 1.000,00. E UM CENTAVO, e ele e da ORIGEM: a descricao da Gold declara que a
--     comissao vem como `valor_comissao_veiculo` e nao e recalculada. Por isso ALERTA e
--     nao BLOQUEANTE -- o que se quer detectar e a divergencia CRESCER. Medido:
--     R$ 37.570.784,98 + R$ 9.387.156,88 = R$ 46.957.941,86 contra R$ 46.957.941,85.
--   `desempenho_diario.campanha_catalogada`, ALERTA 0,98 contra 99,67% (281 de 86.267).
--     A regra 7 daquela tabela declara que os joins sao LEFT de proposito e que os 281
--     pares campanha-dia vem de 18 campanhas EXCLUIDAS no Meta -- o endpoint devolve so
--     as atuais, o insight guarda o historico. E R$ 94.646,41 que com INNER sumiriam.
--     Nao e defeito; e o mecanismo dimensao-fotografia contra fato-historico, ja
--     registrado no gestor deletado do VJOB.
--   `desempenho_diario.clique_nunca_excede_impressao`, ALERTA 0,999 contra 4 linhas de
--     86.267. Os numeros vem da plataforma e esta camada NAO os recalcula; quatro linhas
--     em oitenta e seis mil e ruido da origem, e o limiar existe para detectar quando
--     deixar de ser.
--
-- O QUE NAO ENTROU, E A AUSENCIA E A DECISAO:
--   `desempenho_diario.conta_catalogada` -- ZERO orfas hoje, mas a dimensao de conta do
--     Facebook e um SNAPSHOT CONGELADO de 26/08/2026, de uma fonte excluida. A regra
--     seria correta e inutil: a dimensao nunca mais muda por conta propria.
--   `midia_off__pi.tem_acompanhamento_financeiro` a 1,00 -- a Gold ja explica linha a
--     linha por que 32 PIs vivos nao tem acompanhamento (tipo fora da lista fixa da view
--     do Supabase, cliente de teste, sem data). A regra entra como ALERTA 0,95 sobre os
--     PIs VIVOS, nunca sobre a tabela inteira: cancelado sem acompanhamento e o
--     comportamento correto da view.

WITH

-- ─────────────────── rfn_midia__desempenho_diario (17) ───────────────────────────────
r_desempenho AS (
  SELECT 'rfn_midia__desempenho_diario.id_desempenho_unico' AS id_regra,
         'Refined' AS camada, 'rfn_midia__desempenho_diario' AS tabela,
         'Midia' AS sistema, 'UNICIDADE' AS dimensao,
         'id_desempenho e unico' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_desempenho) AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_midia__desempenho_diario`

  UNION ALL
  SELECT 'rfn_midia__desempenho_diario.chave_e_conta_campanha_dia', 'Refined',
         'rfn_midia__desempenho_diario', 'Midia', 'INTEGRIDADE',
         'id_desempenho e conta, campanha e dia', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(id_desempenho <> CONCAT(CAST(id_conta AS STRING), '|',
                                         CAST(id_campanha AS STRING), '|',
                                         FORMAT_DATE('%Y%m%d', data))
                 OR id_conta IS NULL OR id_campanha IS NULL)
  FROM `vanguardamartech_refined`.`rfn_midia__desempenho_diario`

  UNION ALL
  SELECT 'rfn_midia__desempenho_diario.plataforma_conhecida', 'Refined',
         'rfn_midia__desempenho_diario', 'Midia', 'VALIDADE',
         'plataforma e GOOGLE_ADS ou FACEBOOK_ADS', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(plataforma IS NULL OR plataforma NOT IN ('GOOGLE_ADS', 'FACEBOOK_ADS'))
  FROM `vanguardamartech_refined`.`rfn_midia__desempenho_diario`

  UNION ALL
  SELECT 'rfn_midia__desempenho_diario.grao_origem_conhecido', 'Refined',
         'rfn_midia__desempenho_diario', 'Midia', 'VALIDADE',
         'grao_origem e ANUNCIO ou CAMPANHA', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(grao_origem IS NULL OR grao_origem NOT IN ('ANUNCIO', 'CAMPANHA'))
  FROM `vanguardamartech_refined`.`rfn_midia__desempenho_diario`

  UNION ALL
  -- A PREMISSA QUE, SE CAIR, PRODUZ DUPLA CONTAGEM. Ver o bloco no cabecalho.
  SELECT 'rfn_midia__desempenho_diario.grao_misto_nunca_acende', 'Refined',
         'rfn_midia__desempenho_diario', 'Midia', 'INTEGRIDADE',
         'flag_grao_misto e FALSE em toda linha -- se acender, ha dupla contagem',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(flag_grao_misto)
  FROM `vanguardamartech_refined`.`rfn_midia__desempenho_diario`

  UNION ALL
  -- A UNIDADE DA VERBA. Ver o bloco no cabecalho.
  SELECT 'rfn_midia__desempenho_diario.investimento_reproduz_os_micros', 'Refined',
         'rfn_midia__desempenho_diario', 'Midia', 'VALIDADE',
         'investimento reproduz investimento_micros dividido por um milhao',
         'BLOQUEANTE', 1.00,
         COUNTIF(investimento_micros IS NOT NULL),
         COUNTIF(investimento_micros IS NOT NULL
                 AND ABS(investimento - ROUND(investimento_micros / 1000000, 2)) > 0.005)
  FROM `vanguardamartech_refined`.`rfn_midia__desempenho_diario`

  UNION ALL
  -- A REGRA 4 DAQUELA TABELA. Ver o bloco no cabecalho.
  SELECT 'rfn_midia__desempenho_diario.ctr_reproduz_a_razao_dos_totais', 'Refined',
         'rfn_midia__desempenho_diario', 'Midia', 'VALIDADE',
         'ctr_pct reproduz cliques sobre impressoes -- derivado vem do total, nao herdado',
         'BLOQUEANTE', 1.00,
         COUNTIF(impressoes > 0),
         COUNTIF(impressoes > 0
                 AND ABS(IFNULL(ctr_pct, 0) - ROUND(cliques / impressoes * 100, 2)) > 0.01)
  FROM `vanguardamartech_refined`.`rfn_midia__desempenho_diario`

  UNION ALL
  -- A REGRA 8 DAQUELA TABELA -- a escolha que muda o CPA em uma ordem de grandeza.
  SELECT 'rfn_midia__desempenho_diario.conversao_do_facebook_decompoe', 'Refined',
         'rfn_midia__desempenho_diario', 'Midia', 'VALIDADE',
         'no Facebook, conversoes e exatamente leads mais compras mais conversas',
         'BLOQUEANTE', 1.00,
         COUNTIF(plataforma = 'FACEBOOK_ADS'),
         COUNTIF(plataforma = 'FACEBOOK_ADS'
                 AND ABS(IFNULL(conversoes, 0)
                         - (IFNULL(conversoes_leads, 0) + IFNULL(conversoes_compras, 0)
                            + IFNULL(conversoes_conversas, 0))) > 0.001)
  FROM `vanguardamartech_refined`.`rfn_midia__desempenho_diario`

  UNION ALL
  -- IMPLICACAO, NAO IGUALDADE. Ver o bloco no cabecalho.
  SELECT 'rfn_midia__desempenho_diario.registro_confiavel_nunca_convive_com_flag', 'Refined',
         'rfn_midia__desempenho_diario', 'Midia', 'INTEGRIDADE',
         'registro_confiavel nunca convive com flag de defeito acesa', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(registro_confiavel AND (flag_campanha_nao_catalogada
                                         OR flag_conta_nao_catalogada
                                         OR flag_moeda_divergente
                                         OR flag_grao_misto))
  FROM `vanguardamartech_refined`.`rfn_midia__desempenho_diario`

  UNION ALL
  SELECT 'rfn_midia__desempenho_diario.sem_entrega_decompoe', 'Refined',
         'rfn_midia__desempenho_diario', 'Midia', 'VALIDADE',
         'sem_entrega e exatamente impressao zero', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(sem_entrega <> (impressoes = 0))
  FROM `vanguardamartech_refined`.`rfn_midia__desempenho_diario`

  UNION ALL
  -- O limiar de 9 dias e escolha ligada a cadencia semanal. Ver o cabecalho.
  SELECT 'rfn_midia__desempenho_diario.conta_defasada_decompoe', 'Refined',
         'rfn_midia__desempenho_diario', 'Midia', 'VALIDADE',
         'conta_defasada e exatamente mais de 9 dias sem entrega', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(conta_defasada <> (dias_sem_entrega > 9))
  FROM `vanguardamartech_refined`.`rfn_midia__desempenho_diario`

  UNION ALL
  SELECT 'rfn_midia__desempenho_diario.pacing_nulo_em_orcamento_compartilhado', 'Refined',
         'rfn_midia__desempenho_diario', 'Midia', 'VALIDADE',
         'orcamento compartilhado nunca carrega consumo diario', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(orcamento_compartilhado AND consumo_orcamento_diario_pct IS NOT NULL)
  FROM `vanguardamartech_refined`.`rfn_midia__desempenho_diario`

  UNION ALL
  SELECT 'rfn_midia__desempenho_diario.mes_referencia_e_o_mes_do_dia', 'Refined',
         'rfn_midia__desempenho_diario', 'Midia', 'VALIDADE',
         'mes_referencia e o primeiro dia do mes da propria data', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(mes_referencia <> DATE_TRUNC(data, MONTH))
  FROM `vanguardamartech_refined`.`rfn_midia__desempenho_diario`

  UNION ALL
  SELECT 'rfn_midia__desempenho_diario.data_nao_futura', 'Refined',
         'rfn_midia__desempenho_diario', 'Midia', 'VALIDADE',
         'nenhum dia de entrega e futuro', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(data > CURRENT_DATE('America/Sao_Paulo'))
  FROM `vanguardamartech_refined`.`rfn_midia__desempenho_diario`

  UNION ALL
  SELECT 'rfn_midia__desempenho_diario.metrica_nao_negativa', 'Refined',
         'rfn_midia__desempenho_diario', 'Midia', 'VALIDADE',
         'investimento, impressao, clique e conversao nunca sao negativos',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(investimento < 0 OR impressoes < 0 OR cliques < 0 OR conversoes < 0)
  FROM `vanguardamartech_refined`.`rfn_midia__desempenho_diario`

  UNION ALL
  -- LINHA DE BASE 0,98. Dimensao-fotografia contra fato-historico. Ver o cabecalho.
  SELECT 'rfn_midia__desempenho_diario.campanha_catalogada', 'Refined',
         'rfn_midia__desempenho_diario', 'Midia', 'INTEGRIDADE',
         'a campanha do fato existe na dimensao', 'ALERTA', 0.98,
         COUNT(*),
         COUNTIF(flag_campanha_nao_catalogada)
  FROM `vanguardamartech_refined`.`rfn_midia__desempenho_diario`

  UNION ALL
  -- LINHA DE BASE 0,999. O numero vem da plataforma e nao e recalculado aqui.
  SELECT 'rfn_midia__desempenho_diario.clique_nunca_excede_impressao', 'Refined',
         'rfn_midia__desempenho_diario', 'Midia', 'VALIDADE',
         'o clique nunca passa da impressao', 'ALERTA', 0.999,
         COUNT(*),
         COUNTIF(cliques > impressoes)
  FROM `vanguardamartech_refined`.`rfn_midia__desempenho_diario`
),

-- ─────────────────────────── rfn_midia_off__pi (13) ──────────────────────────────────
r_pi AS (
  SELECT 'rfn_midia_off__pi.id_pi_unico' AS id_regra, 'Refined' AS camada,
         'rfn_midia_off__pi' AS tabela, 'PI' AS sistema, 'UNICIDADE' AS dimensao,
         'id_pi e unico' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_pi) AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_midia_off__pi`

  UNION ALL
  -- LINHA DE BASE 0,999 -- seria a setima identidade e ela nao fecha. Ver o cabecalho.
  SELECT 'rfn_midia_off__pi.liquido_mais_comissao_e_o_negociado', 'Refined',
         'rfn_midia_off__pi', 'PI', 'VALIDADE',
         'valor liquido mais comissao reproduz o valor negociado', 'ALERTA', 0.999,
         COUNT(*),
         COUNTIF(ABS(IFNULL(valor_liquido, 0) + IFNULL(comissao_estimada, 0)
                     - IFNULL(valor_negociado, 0)) > 0.005)
  FROM `vanguardamartech_refined`.`rfn_midia_off__pi`

  UNION ALL
  SELECT 'rfn_midia_off__pi.cnpj_veiculo_tem_14_digitos', 'Refined',
         'rfn_midia_off__pi', 'PI', 'VALIDADE',
         'o CNPJ de veiculo que existe tem 14 digitos', 'BLOQUEANTE', 1.00,
         COUNTIF(NULLIF(TRIM(cnpj_veiculo), '') IS NOT NULL),
         COUNTIF(NULLIF(TRIM(cnpj_veiculo), '') IS NOT NULL
                 AND LENGTH(REGEXP_REPLACE(cnpj_veiculo, r'[^0-9]', '')) <> 14)
  FROM `vanguardamartech_refined`.`rfn_midia_off__pi`

  UNION ALL
  SELECT 'rfn_midia_off__pi.mes_referencia_e_a_competencia', 'Refined',
         'rfn_midia_off__pi', 'PI', 'VALIDADE',
         'mes_referencia e o primeiro dia da propria competencia', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(mes_referencia <> DATE(CONCAT(mes_competencia, '-01')))
  FROM `vanguardamartech_refined`.`rfn_midia_off__pi`

  UNION ALL
  SELECT 'rfn_midia_off__pi.vigente_decompoe', 'Refined',
         'rfn_midia_off__pi', 'PI', 'VALIDADE',
         'eh_vigente e exatamente nao cancelado', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(eh_vigente <> (NOT is_cancelado))
  FROM `vanguardamartech_refined`.`rfn_midia_off__pi`

  UNION ALL
  SELECT 'rfn_midia_off__pi.sem_periodo_decompoe', 'Refined',
         'rfn_midia_off__pi', 'PI', 'VALIDADE',
         'sem_periodo_completo e exatamente faltar inicio ou fim', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(sem_periodo_completo <> (data_inicio IS NULL OR data_fim IS NULL))
  FROM `vanguardamartech_refined`.`rfn_midia_off__pi`

  UNION ALL
  SELECT 'rfn_midia_off__pi.janela_nao_inverte', 'Refined',
         'rfn_midia_off__pi', 'PI', 'VALIDADE',
         'a data de fim nunca e anterior a de inicio', 'BLOQUEANTE', 1.00,
         COUNTIF(data_inicio IS NOT NULL AND data_fim IS NOT NULL),
         COUNTIF(data_inicio IS NOT NULL AND data_fim IS NOT NULL AND data_fim < data_inicio)
  FROM `vanguardamartech_refined`.`rfn_midia_off__pi`

  UNION ALL
  SELECT 'rfn_midia_off__pi.valor_nao_negativo', 'Refined',
         'rfn_midia_off__pi', 'PI', 'VALIDADE',
         'nenhum valor nem a insercao e negativo', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(valor_negociado < 0 OR valor_liquido < 0 OR comissao_estimada < 0
                 OR insercoes < 0)
  FROM `vanguardamartech_refined`.`rfn_midia_off__pi`

  UNION ALL
  -- A REGRA 1 daquela tabela e LISTA NEGRA de um item. Ver o cabecalho.
  SELECT 'rfn_midia_off__pi.escopo_exclui_internet', 'Refined',
         'rfn_midia_off__pi', 'PI', 'INTEGRIDADE',
         'nenhum PI de Internet entra na midia OFF', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(LOWER(TRIM(IFNULL(tipo_midia, ''))) = 'internet'
                 OR LOWER(TRIM(IFNULL(tipo_midia_origem, ''))) = 'internet')
  FROM `vanguardamartech_refined`.`rfn_midia_off__pi`

  UNION ALL
  -- A REGRA 4 daquela tabela: "toda linha tem causa". Ver o cabecalho.
  SELECT 'rfn_midia_off__pi.toda_linha_tem_causa', 'Refined',
         'rfn_midia_off__pi', 'PI', 'COMPLETUDE',
         'toda linha declara o motivo de ter ou nao acompanhamento', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(NULLIF(TRIM(IFNULL(motivo_sem_acompanhamento, '')), '') IS NULL)
  FROM `vanguardamartech_refined`.`rfn_midia_off__pi`

  UNION ALL
  -- IMPLICACAO, NAO IGUALDADE. Ver o cabecalho.
  SELECT 'rfn_midia_off__pi.venda_conta_azul_implica_a_flag', 'Refined',
         'rfn_midia_off__pi', 'PI', 'INTEGRIDADE',
         'venda registrada no Conta Azul nunca aparece sem a flag', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(IFNULL(ca_n_vendas, 0) > 0 AND NOT tem_conta_azul)
  FROM `vanguardamartech_refined`.`rfn_midia_off__pi`

  UNION ALL
  SELECT 'rfn_midia_off__pi.aberto_nunca_excede_o_valor', 'Refined',
         'rfn_midia_off__pi', 'PI', 'VALIDADE',
         'o valor em aberto no Conta Azul nunca passa do valor da venda',
         'BLOQUEANTE', 1.00,
         COUNTIF(tem_conta_azul),
         COUNTIF(tem_conta_azul AND IFNULL(ca_valor_aberto, 0) > IFNULL(ca_valor, 0))
  FROM `vanguardamartech_refined`.`rfn_midia_off__pi`

  UNION ALL
  -- LINHA DE BASE 0,95 SOBRE OS PIs VIVOS. Ver o cabecalho.
  SELECT 'rfn_midia_off__pi.acompanhamento_financeiro_no_pi_vivo', 'Refined',
         'rfn_midia_off__pi', 'PI', 'INTEGRIDADE',
         'o PI nao cancelado aparece no acompanhamento financeiro', 'ALERTA', 0.95,
         COUNTIF(NOT is_cancelado),
         COUNTIF(NOT is_cancelado AND NOT tem_acompanhamento_financeiro)
  FROM `vanguardamartech_refined`.`rfn_midia_off__pi`
),

todas AS (
  SELECT * FROM r_desempenho
  UNION ALL SELECT * FROM r_pi
),
avaliado AS (
  SELECT
    t.*,
    (t.linhas_avaliadas - t.linhas_falha)                       AS linhas_conformes,
    SAFE_DIVIDE(t.linhas_avaliadas - t.linhas_falha, NULLIF(t.linhas_avaliadas, 0))
                                                                AS taxa_conformidade,
    -- Regra sem linha para avaliar NAO passa: sai NULL, nunca TRUE.
    IF(t.linhas_avaliadas = 0, NULL,
       SAFE_DIVIDE(t.linhas_avaliadas - t.linhas_falha, t.linhas_avaliadas) >= t.limiar)
                                                                AS is_conforme,
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
  'Midia Gold'                                  AS familia,
  CURRENT_TIMESTAMP()                           AS _extraido_at,
  'multiplas'                                   AS _fonte,
  'America/Sao_Paulo'                           AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(a)))                AS _payload_hash
FROM avaliado a
