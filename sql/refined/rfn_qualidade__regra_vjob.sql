-- rfn_qualidade__regra_vjob  ·  query-Rnff  ·  37 regras  ·  L2 INTERNAL
-- Refined / qualidade. Grao: uma REGRA de qualidade em uma execucao. Chave: id_regra.
-- Gatilho: evento em query-c1x0, o elo mais fundo da cadeia do VJOB. Alerta ligado.
-- Cadencia SEMANAL (a `mysql-yIOn` roda domingo 00:00 America/Manaus).
--
-- POR QUE ESTA SUITE EXISTE
--   A suite principal cobre o nucleo do VJOB (cliente, escopo, job, cronograma), mas as
--   16 Trusted publicadas entre 24 e 25/09 ficaram de fora -- 111 mil linhas: acesso
--   49.434 · cronograma_alteracao 18.955 · sms 11.068 · etapa/checklist 2.748 ·
--   squad 2.346 · municipio 5.570 · comentario 1.333 · anexo 1.007+771 · blog 1.323 ·
--   auditoria_servico 1.387 · ocorrencia 426 · atendimento 310 · ciclo 56 · servico 38 ·
--   recorrencia 30. Suite propria, e nao acrescimo a principal, pelo mesmo motivo ja
--   declarado na do Gmail e na de Midia: a `rfn_qualidade__regra` esta com 57 KB e 84
--   regras e `update_transformation` troca o codigo inteiro.
--   Contrato de colunas IDENTICO as outras -- `familia` diz de onde veio cada linha.
--
-- O GATILHO E UM SO, E A REGRA DE FRESCOR E QUE TORNA ISSO SEGURO.
--   A cadeia do VJOB se abre em varios ramos paralelos depois de `query-MZdN`, entao
--   NENHUM elo unico vem depois de todos os outros. Em vez de amarrar a suite a nove
--   gatilhos com `event_rule = "all"` -- que faria uma falha qualquer num ramo impedir as
--   37 regras de rodar --, ela dispara no elo mais fundo E MEDE a premissa:
--   `carga_do_mesmo_dia` compara `MAX(DATE(_extraido_at))` das 16 tabelas e acusa
--   qualquer uma que tenha ficado numa carga anterior. Medido em 2026-09-29: as 16 em
--   **2026-09-27**, uma unica data. E um tipo de regra novo nesta casa -- nao mede o
--   CONTEUDO de uma tabela, mede se as tabelas foram escritas na MESMA passada.
--
-- A IDENTIDADE: `auditoria_ciclo.itens_batem_com_a_auditoria`. A soma de `qtd_itens`
--   dos 56 ciclos tem de ser exatamente o numero de linhas de `trs_vjob__auditoria_cliente`
--   -- 3.025 dos dois lados, medido. Se divergir, ou um ciclo perdeu itens ou um item
--   perdeu ciclo, e nenhuma contagem isolada denuncia. Grao 1, BLOQUEANTE, limiar 1,00.
--   E a terceira identidade contabil desta casa, depois do `rateio_fecha_no_centavo` e do
--   `caixa_reproduz_o_razao`.
--
-- CORRECAO PUBLICADA HOJE -- A IGUALDADE "TOKEN = SEM-PAI" NAO E LINHA A LINHA NO MODULO
-- APOSENTADO. A descricao da `trs_vjob__comentario_arquivo` afirmava que "85 carregam
--   upload_token e exatamente os mesmos 85 tem comentario_id nulo", e que isso valia
--   dentro de cada origem. Medido hoje sobre as 771 linhas: em TAREFAS e ADVISORY vale
--   **linha a linha, 0 divergencias em 521**; em `tbjobs` vale so **por contagem** --
--   15 com token e 15 sem pai, mas **apenas 6 sao os mesmos**: 9 tem token E tem pai, e
--   9 nao tem token E nao tem pai. A afirmacao anterior era verdadeira sobre os totais e
--   falsa sobre as linhas. Por isso a regra e escrita **so sobre o modulo vivo**, onde a
--   invariante e real; no aposentado o caso fica declarado, nao medido como falha.
--   Na `trs_vjob__job_arquivo` a igualdade vale linha a linha em TODAS as origens --
--   0 divergencias em 1.007 -- e ali a regra e BLOQUEANTE sobre a tabela inteira.
--
-- AS 37 REGRAS, MEDIDAS EM 2026-09-29 SOBRE AS TABELAS MATERIALIZADAS, ANTES DE PUBLICAR.
-- Resultado esperado na primeira execucao: 37 CONFORMES, ZERO FALHAS.
--
-- LINHAS DE BASE (limiar frouxo de proposito, para detectar PIORA e nao reclamar do que a
-- casa ja sabe): `acesso.usuario_presente` 6 de 49.434 · `blog_pauta.escopo_catalogado`
--   1 de 1.183 · `cliente_atendimento.cliente_catalogado` 6 de 310 (a ponte juridica da
--   origem) · `servico.nome_resolvido` 4 de 38 (a tabela de dominio do sistema veio vazia).
--
-- CLASSIFICACAO: L2 INTERNAL. So contagem e taxa.
WITH carga AS (
  SELECT 'acesso' AS t, MAX(DATE(_extraido_at)) AS d FROM `vanguardamartech_trusted`.`trs_vjob__acesso`
  UNION ALL SELECT 'auditoria_ciclo', MAX(DATE(_extraido_at)) FROM `vanguardamartech_trusted`.`trs_vjob__auditoria_ciclo`
  UNION ALL SELECT 'auditoria_servico', MAX(DATE(_extraido_at)) FROM `vanguardamartech_trusted`.`trs_vjob__auditoria_servico`
  UNION ALL SELECT 'blog_pauta', MAX(DATE(_extraido_at)) FROM `vanguardamartech_trusted`.`trs_vjob__blog_pauta`
  UNION ALL SELECT 'checklist_diario', MAX(DATE(_extraido_at)) FROM `vanguardamartech_trusted`.`trs_vjob__checklist_diario`
  UNION ALL SELECT 'cliente_atendimento', MAX(DATE(_extraido_at)) FROM `vanguardamartech_trusted`.`trs_vjob__cliente_atendimento`
  UNION ALL SELECT 'comentario_arquivo', MAX(DATE(_extraido_at)) FROM `vanguardamartech_trusted`.`trs_vjob__comentario_arquivo`
  UNION ALL SELECT 'cronograma_alteracao', MAX(DATE(_extraido_at)) FROM `vanguardamartech_trusted`.`trs_vjob__cronograma_alteracao`
  UNION ALL SELECT 'job_arquivo', MAX(DATE(_extraido_at)) FROM `vanguardamartech_trusted`.`trs_vjob__job_arquivo`
  UNION ALL SELECT 'job_comentario', MAX(DATE(_extraido_at)) FROM `vanguardamartech_trusted`.`trs_vjob__job_comentario`
  UNION ALL SELECT 'job_recorrencia', MAX(DATE(_extraido_at)) FROM `vanguardamartech_trusted`.`trs_vjob__job_recorrencia`
  UNION ALL SELECT 'municipio', MAX(DATE(_extraido_at)) FROM `vanguardamartech_trusted`.`trs_vjob__municipio`
  UNION ALL SELECT 'recorrencia_ocorrencia', MAX(DATE(_extraido_at)) FROM `vanguardamartech_trusted`.`trs_vjob__recorrencia_ocorrencia`
  UNION ALL SELECT 'servico', MAX(DATE(_extraido_at)) FROM `vanguardamartech_trusted`.`trs_vjob__servico`
  UNION ALL SELECT 'sms_notificacao', MAX(DATE(_extraido_at)) FROM `vanguardamartech_trusted`.`trs_vjob__sms_notificacao`
  UNION ALL SELECT 'squad_alteracao', MAX(DATE(_extraido_at)) FROM `vanguardamartech_trusted`.`trs_vjob__squad_alteracao`
),
r_frescor AS (
  SELECT 'vjob.carga_do_mesmo_dia'                          AS id_regra,
         'Trusted'                                          AS camada,
         '(as 16 tabelas do lote)'                          AS tabela,
         'VJOB'                                             AS sistema,
         'VALIDADE'                                         AS dimensao,
         'as 16 tabelas foram escritas na mesma passada da fonte' AS regra,
         'BLOQUEANTE'                                       AS severidade,
         1.00                                               AS limiar,
         COUNT(*)                                           AS linhas_avaliadas,
         COUNTIF(d <> (SELECT MAX(d) FROM carga))           AS linhas_falha
  FROM carga
),
r_acesso AS (
  SELECT 'trs_vjob__acesso.id_acesso_unico', 'Trusted', 'trs_vjob__acesso', 'VJOB',
         'UNICIDADE', 'id_acesso (origem + id) e unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_acesso)
  FROM `vanguardamartech_trusted`.`trs_vjob__acesso`
  UNION ALL
  -- LINHA DE BASE: 6 de 49.434. Acesso sem usuario e da origem.
  SELECT 'trs_vjob__acesso.usuario_presente', 'Trusted', 'trs_vjob__acesso', 'VJOB',
         'COMPLETUDE', 'todo acesso tem usuario', 'ALERTA', 0.999,
         COUNT(*), COUNTIF(flag_usuario_ausente)
  FROM `vanguardamartech_trusted`.`trs_vjob__acesso`
),
r_ciclo AS (
  SELECT 'trs_vjob__auditoria_ciclo.id_auditoria_unico', 'Trusted', 'trs_vjob__auditoria_ciclo',
         'VJOB', 'UNICIDADE', 'id_auditoria e unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_auditoria)
  FROM `vanguardamartech_trusted`.`trs_vjob__auditoria_ciclo`
  UNION ALL
  -- A INVARIANTE QUE FAZ O CICLO SER LEGIVEL: status finalizado e carimbo de data sao a
  -- mesma coisa, nos dois sentidos. Se soltar, "auditoria fechada" vira ambiguo.
  SELECT 'trs_vjob__auditoria_ciclo.status_concorda_com_carimbo', 'Trusted',
         'trs_vjob__auditoria_ciclo', 'VJOB', 'VALIDADE',
         'ciclo finalizado tem data de finalizacao, e vice-versa', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(flag_status_sem_carimbo)
  FROM `vanguardamartech_trusted`.`trs_vjob__auditoria_ciclo`
  UNION ALL
  -- A IDENTIDADE. Grao 1: a soma dos itens dos ciclos e o total da auditoria. Ver o
  -- cabecalho. 3.025 dos dois lados.
  SELECT 'trs_vjob__auditoria_ciclo.itens_batem_com_a_auditoria', 'Trusted',
         'trs_vjob__auditoria_ciclo', 'VJOB', 'INTEGRIDADE',
         'a soma de qtd_itens dos ciclos e o total de itens da auditoria', 'BLOQUEANTE', 1.00,
         1,
         IF((SELECT SUM(qtd_itens) FROM `vanguardamartech_trusted`.`trs_vjob__auditoria_ciclo`)
            = (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_vjob__auditoria_cliente`), 0, 1)
),
r_dimensoes AS (
  SELECT 'trs_vjob__auditoria_servico.id_servico_unico', 'Trusted', 'trs_vjob__auditoria_servico',
         'VJOB', 'UNICIDADE', 'id_servico e unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_servico)
  FROM `vanguardamartech_trusted`.`trs_vjob__auditoria_servico`
  UNION ALL
  SELECT 'trs_vjob__servico.id_servico_unico', 'Trusted', 'trs_vjob__servico', 'VJOB',
         'UNICIDADE', 'id_servico e unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_servico)
  FROM `vanguardamartech_trusted`.`trs_vjob__servico`
  UNION ALL
  -- LINHA DE BASE: 4 de 38 sem nome, porque `tb_servicos_servico` veio VAZIA do sistema
  -- e o nome vem do derivado Supabase. Quando o sistema preencher, isto sobe sozinho.
  SELECT 'trs_vjob__servico.nome_resolvido', 'Trusted', 'trs_vjob__servico', 'VJOB',
         'COMPLETUDE', 'o servico tem nome resolvido', 'ALERTA', 0.85,
         COUNT(*), COUNTIF(flag_nome_nao_resolvido)
  FROM `vanguardamartech_trusted`.`trs_vjob__servico`
  UNION ALL
  SELECT 'trs_vjob__municipio.id_municipio_unico', 'Trusted', 'trs_vjob__municipio', 'VJOB',
         'UNICIDADE', 'id_municipio e unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_municipio)
  FROM `vanguardamartech_trusted`.`trs_vjob__municipio`
  UNION ALL
  -- `codigo_ibge` e a chave universal para fora desta base, e sai como TEXTO de proposito.
  SELECT 'trs_vjob__municipio.codigo_ibge_unico', 'Trusted', 'trs_vjob__municipio', 'VJOB',
         'UNICIDADE', 'codigo_ibge e unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT codigo_ibge)
  FROM `vanguardamartech_trusted`.`trs_vjob__municipio`
  UNION ALL
  SELECT 'trs_vjob__municipio.codigo_ibge_tem_forma', 'Trusted', 'trs_vjob__municipio', 'VJOB',
         'VALIDADE', 'codigo_ibge tem exatamente 7 digitos', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(LENGTH(codigo_ibge) <> 7)
  FROM `vanguardamartech_trusted`.`trs_vjob__municipio`
  UNION ALL
  SELECT 'trs_vjob__municipio.estado_catalogado', 'Trusted', 'trs_vjob__municipio', 'VJOB',
         'INTEGRIDADE', 'todo municipio aponta para estado catalogado', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(flag_estado_nao_catalogado)
  FROM `vanguardamartech_trusted`.`trs_vjob__municipio`
  UNION ALL
  SELECT 'trs_vjob__cliente_atendimento.id_atendimento_unico', 'Trusted',
         'trs_vjob__cliente_atendimento', 'VJOB', 'UNICIDADE', 'id_atendimento e unico',
         'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_atendimento)
  FROM `vanguardamartech_trusted`.`trs_vjob__cliente_atendimento`
  UNION ALL
  -- A ponte para o cadastro juridico esta PREENCHIDA em 310 de 310 -- se soltar, metade
  -- dos modulos do VJOB perde o CNPJ do cliente.
  SELECT 'trs_vjob__cliente_atendimento.ponte_preenchida', 'Trusted',
         'trs_vjob__cliente_atendimento', 'VJOB', 'COMPLETUDE',
         'toda conta declara o cadastro juridico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(flag_sem_ponte_cadastro)
  FROM `vanguardamartech_trusted`.`trs_vjob__cliente_atendimento`
  UNION ALL
  -- LINHA DE BASE: 6 de 310 apontam para cadastro que nao existe mais. E da origem.
  SELECT 'trs_vjob__cliente_atendimento.cliente_catalogado', 'Trusted',
         'trs_vjob__cliente_atendimento', 'VJOB', 'INTEGRIDADE',
         'o cadastro juridico declarado existe', 'ALERTA', 0.97,
         COUNT(*), COUNTIF(flag_cliente_nao_catalogado)
  FROM `vanguardamartech_trusted`.`trs_vjob__cliente_atendimento`
),
r_blog_check AS (
  SELECT 'trs_vjob__blog_pauta.id_pauta_unico', 'Trusted', 'trs_vjob__blog_pauta', 'VJOB',
         'UNICIDADE', 'id_pauta e unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_pauta)
  FROM `vanguardamartech_trusted`.`trs_vjob__blog_pauta`
  UNION ALL
  -- LINHA DE BASE: 1 orfa em 1.183. E a UNICA ponte desta base entre entrega e a linha
  -- de escopo que a pediu -- se ela se degradar, a `rfn_operacao__blog_mensal` perde o
  -- confronto entre os dois registros da mesma entrega.
  SELECT 'trs_vjob__blog_pauta.escopo_catalogado', 'Trusted', 'trs_vjob__blog_pauta', 'VJOB',
         'INTEGRIDADE', 'a pauta que cita escopo aponta para escopo que existe', 'ALERTA', 0.999,
         COUNTIF(id_escopo IS NOT NULL), COUNTIF(flag_escopo_nao_catalogado)
  FROM `vanguardamartech_trusted`.`trs_vjob__blog_pauta`
  UNION ALL
  SELECT 'trs_vjob__checklist_diario.id_check_unico', 'Trusted', 'trs_vjob__checklist_diario',
         'VJOB', 'UNICIDADE', 'id_check e unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_check)
  FROM `vanguardamartech_trusted`.`trs_vjob__checklist_diario`
  UNION ALL
  -- Terceiro instrumento da casa com cobertura total de carimbo: 2.748 de 2.748.
  SELECT 'trs_vjob__checklist_diario.marcado_sempre_carimbado', 'Trusted',
         'trs_vjob__checklist_diario', 'VJOB', 'VALIDADE',
         'item marcado sempre carrega a data da marcacao', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(flag_marcado_sem_carimbo)
  FROM `vanguardamartech_trusted`.`trs_vjob__checklist_diario`
),
r_anexo AS (
  SELECT 'trs_vjob__comentario_arquivo.id_arquivo_unico', 'Trusted',
         'trs_vjob__comentario_arquivo', 'VJOB', 'UNICIDADE',
         'id_arquivo_unico (origem + id) e unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_arquivo_unico)
  FROM `vanguardamartech_trusted`.`trs_vjob__comentario_arquivo`
  UNION ALL
  -- SO NO MODULO VIVO. Ver a correcao no cabecalho: no aposentado a igualdade vale por
  -- contagem e nao linha a linha.
  SELECT 'trs_vjob__comentario_arquivo.token_e_sem_pai_no_modulo_vivo', 'Trusted',
         'trs_vjob__comentario_arquivo', 'VJOB', 'VALIDADE',
         'no modulo vivo, anexo com upload_token e exatamente o anexo sem comentario',
         'BLOQUEANTE', 1.00,
         COUNTIF(origem IN ('TAREFAS','ADVISORY')),
         COUNTIF(origem IN ('TAREFAS','ADVISORY')
                 AND flag_upload_por_token <> flag_anexo_sem_comentario)
  FROM `vanguardamartech_trusted`.`trs_vjob__comentario_arquivo`
  UNION ALL
  SELECT 'trs_vjob__comentario_arquivo.comentario_catalogado', 'Trusted',
         'trs_vjob__comentario_arquivo', 'VJOB', 'INTEGRIDADE',
         'anexo com pai aponta para comentario que existe', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(flag_comentario_nao_catalogado)
  FROM `vanguardamartech_trusted`.`trs_vjob__comentario_arquivo`
  UNION ALL
  SELECT 'trs_vjob__job_arquivo.id_arquivo_unico', 'Trusted', 'trs_vjob__job_arquivo', 'VJOB',
         'UNICIDADE', 'id_arquivo_unico (origem + id) e unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_arquivo_unico)
  FROM `vanguardamartech_trusted`.`trs_vjob__job_arquivo`
  UNION ALL
  -- Aqui a igualdade vale LINHA A LINHA em todas as origens: 0 de 1.007.
  SELECT 'trs_vjob__job_arquivo.token_e_sem_job', 'Trusted', 'trs_vjob__job_arquivo', 'VJOB',
         'VALIDADE', 'anexo com upload_token e exatamente o anexo sem job', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(flag_upload_por_token <> flag_anexo_sem_job)
  FROM `vanguardamartech_trusted`.`trs_vjob__job_arquivo`
  UNION ALL
  SELECT 'trs_vjob__job_comentario.id_comentario_unico', 'Trusted', 'trs_vjob__job_comentario',
         'VJOB', 'UNICIDADE', 'id_comentario_unico (origem + id) e unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_comentario_unico)
  FROM `vanguardamartech_trusted`.`trs_vjob__job_comentario`
  UNION ALL
  -- `editado_em` so existe no modulo de TAREFAS; nas outras origens e AUSENCIA DE COLUNA,
  -- nao comentario nao editado. Comentario marcado como editado fora do rastro seria
  -- sinal de que a distincao se perdeu.
  SELECT 'trs_vjob__job_comentario.edicao_so_onde_ha_rastro', 'Trusted',
         'trs_vjob__job_comentario', 'VJOB', 'VALIDADE',
         'comentario editado so aparece onde a edicao e rastreavel', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(flag_editado AND NOT flag_edicao_rastreavel)
  FROM `vanguardamartech_trusted`.`trs_vjob__job_comentario`
),
r_logs AS (
  SELECT 'trs_vjob__cronograma_alteracao.id_alteracao_unico', 'Trusted',
         'trs_vjob__cronograma_alteracao', 'VJOB', 'UNICIDADE', 'id_alteracao e unico',
         'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_alteracao)
  FROM `vanguardamartech_trusted`.`trs_vjob__cronograma_alteracao`
  UNION ALL
  -- A PREMISSA QUE IMPEDE A DUPLA CONTAGEM. `id_alvo` e indecidivel em 46,4% das linhas
  -- porque as sequencias de contrato e de parcela se sobrepoem; a Trusted so preenche
  -- `id_contrato` OU `id_parcela` quando o alvo e inequivoco, e nunca os dois. Se os dois
  -- aparecerem juntos, um join por alvo duplica a linha entre as duas pontas.
  SELECT 'trs_vjob__cronograma_alteracao.alvo_nunca_ambiguo_preenchido', 'Trusted',
         'trs_vjob__cronograma_alteracao', 'VJOB', 'VALIDADE',
         'nenhuma linha traz contrato e parcela preenchidos ao mesmo tempo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(id_contrato IS NOT NULL AND id_parcela IS NOT NULL)
  FROM `vanguardamartech_trusted`.`trs_vjob__cronograma_alteracao`
  UNION ALL
  SELECT 'trs_vjob__sms_notificacao.id_sms_unico', 'Trusted', 'trs_vjob__sms_notificacao',
         'VJOB', 'UNICIDADE', 'id_sms e unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_sms)
  FROM `vanguardamartech_trusted`.`trs_vjob__sms_notificacao`
  UNION ALL
  SELECT 'trs_vjob__squad_alteracao.id_alteracao_unico', 'Trusted', 'trs_vjob__squad_alteracao',
         'VJOB', 'UNICIDADE', 'id_alteracao e unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_alteracao)
  FROM `vanguardamartech_trusted`.`trs_vjob__squad_alteracao`
  UNION ALL
  -- Corrigida em 24/09 para a FK certa (`tbclientesatedimentos`): eram 923 orfas, hoje 0.
  SELECT 'trs_vjob__squad_alteracao.conta_catalogada', 'Trusted', 'trs_vjob__squad_alteracao',
         'VJOB', 'INTEGRIDADE', 'toda alteracao aponta para conta de atendimento que existe',
         'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(flag_conta_nao_catalogada)
  FROM `vanguardamartech_trusted`.`trs_vjob__squad_alteracao`
),
r_recorrencia AS (
  SELECT 'trs_vjob__job_recorrencia.id_recorrencia_unico', 'Trusted', 'trs_vjob__job_recorrencia',
         'VJOB', 'UNICIDADE', 'id_recorrencia e unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_recorrencia)
  FROM `vanguardamartech_trusted`.`trs_vjob__job_recorrencia`
  UNION ALL
  SELECT 'trs_vjob__job_recorrencia.job_catalogado', 'Trusted', 'trs_vjob__job_recorrencia',
         'VJOB', 'INTEGRIDADE', 'toda regra aponta para job que existe', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(flag_job_nao_catalogado)
  FROM `vanguardamartech_trusted`.`trs_vjob__job_recorrencia`
  UNION ALL
  SELECT 'trs_vjob__recorrencia_ocorrencia.id_ocorrencia_unico', 'Trusted',
         'trs_vjob__recorrencia_ocorrencia', 'VJOB', 'UNICIDADE', 'id_ocorrencia e unico',
         'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_ocorrencia)
  FROM `vanguardamartech_trusted`.`trs_vjob__recorrencia_ocorrencia`
  UNION ALL
  -- A LIGACAO E 1:1: nenhuma ocorrencia divide job com outra. Se soltar, a agenda passa a
  -- contar o mesmo job duas vezes e a `rfn_operacao__recorrencia_mensal` infla.
  SELECT 'trs_vjob__recorrencia_ocorrencia.um_job_por_ocorrencia', 'Trusted',
         'trs_vjob__recorrencia_ocorrencia', 'VJOB', 'UNICIDADE',
         'cada ocorrencia tem um job proprio, nenhum job se repete', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_job_unico)
  FROM `vanguardamartech_trusted`.`trs_vjob__recorrencia_ocorrencia`
  UNION ALL
  SELECT 'trs_vjob__recorrencia_ocorrencia.regra_e_job_catalogados', 'Trusted',
         'trs_vjob__recorrencia_ocorrencia', 'VJOB', 'INTEGRIDADE',
         'a ocorrencia aponta para regra e job que existem', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(flag_regra_nao_catalogada OR flag_job_nao_catalogado)
  FROM `vanguardamartech_trusted`.`trs_vjob__recorrencia_ocorrencia`
),
todas AS (
  SELECT * FROM r_frescor
  UNION ALL SELECT * FROM r_acesso
  UNION ALL SELECT * FROM r_ciclo
  UNION ALL SELECT * FROM r_dimensoes
  UNION ALL SELECT * FROM r_blog_check
  UNION ALL SELECT * FROM r_anexo
  UNION ALL SELECT * FROM r_logs
  UNION ALL SELECT * FROM r_recorrencia
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
  'VJOB lote 24-25/09'                          AS familia,
  CURRENT_TIMESTAMP()                           AS _extraido_at,
  'multiplas'                                   AS _fonte,
  'America/Sao_Paulo'                           AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(a)))                AS _payload_hash
FROM avaliado a
