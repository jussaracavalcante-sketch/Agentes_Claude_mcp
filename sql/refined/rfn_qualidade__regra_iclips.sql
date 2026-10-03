-- rfn_qualidade__regra_iclips  ·  query-Sh4v  ·  45 regras  ·  L2 INTERNAL
-- Refined / qualidade. Grao: uma REGRA de qualidade em uma execucao. Chave: id_regra
-- (a execucao se le em _extraido_at).
-- Gatilho: evento em query-8nEt + query-9nws + query-tF7c + query-vHzW + query-BzKD,
-- regra "all". Alterado em 30/09 para acrescentar a BzKD -- ver o bloco da Gold.
-- Alerta ligado.
--
-- POR QUE UMA QUARTA SUITE. O motivo e o mesmo da do Gmail: a `rfn_qualidade__regra`
--   esta com 57 KB e 84 regras e `update_transformation` substitui o CODIGO INTEIRO —
--   somar 33 regras exigiria reescrever 57 mil caracteres sem errar um. Esta casa ja
--   registrou o risco ("query grande demais e query que nao se conserta"). O CONTRATO DE
--   COLUNAS E IDENTICO ao das outras tres: um UNION ALL da o painel unico e `familia`
--   diz de onde veio cada linha.
--
-- O QUE FICAVA DE FORA. A suite principal cobria `trs_iclips__peca` e
--   `trs_iclips__peca_tipo` e mais nada do iClips. Ficavam SEM UMA REGRA seis tabelas
--   materializadas somando 595.542 linhas: apontamento 5.580 (query-9nws), etapa 514.909
--   (query-vHzW), projeto 12.106 (query-8nEt), tarefa 8.835 (query-tF7c), peca_atributo
--   54.056 (query-07tG) e peca_categoria 29 (query-Lrtd).
--
-- O GATILHO E O QUE GARANTE A ORDEM, e ele foi escolhido por causa de UMA correcao.
--   A `trs_iclips__projeto` foi corrigida hoje: ate 29/09 ela emitia o CNPJ COM MASCARA
--   e nao juntava com nada. As regras 16 a 18 medem o documento DEPOIS do conserto, e
--   por isso o gatilho e evento nas QUATRO Trusted do `notebook-Rbpo` com regra "all" —
--   a suite so roda depois que as quatro reescreveram. Se a 8nEt falhar, a suite nao
--   roda, que e o certo: melhor nao medir do que medir a tabela velha.
--
-- FRESCOR COM ESCOPO DE FONTE, NAO DE SISTEMA — e aqui isso mudou em relacao ao VJOB.
--   A suite do VJOB compara a carga das 16 tabelas porque as 16 vem da MESMA fonte. No
--   iClips as seis tabelas vem de TRES fontes: quatro do `notebook-Rbpo`, a
--   peca_atributo da `supabase-x0tz` e a peca_categoria da `rest-api-xk4P`. Medido em
--   2026-09-29: as quatro do notebook carregam 2026-09-29 e a peca_atributo carrega
--   2026-09-15 — a `supabase-x0tz` esta parada por senha rejeitada. Uma regra de carga
--   do mesmo dia sobre as seis FALHARIA por desenho, todo dia, e ensinaria a ignorar a
--   suite. Entao o escopo da regra de frescor e a FONTE, e so as quatro entram.
--
-- AS 33 REGRAS, MEDIDAS EM 2026-09-29 SOBRE A TABELA MATERIALIZADA, ANTES DE PUBLICAR.
-- Resultado esperado na primeira execucao: 33 CONFORMES, ZERO FALHAS.
--
-- A REGRA QUE IMPORTA MAIS E A QUARTA IDENTIDADE DESTA CASA, E E A PRIMEIRA QUE VALIDA
--   A ARITMETICA DE UM SISTEMA DE TERCEIRO.
--   `trs_iclips__apontamento.custo_reproduz_hora_vezes_valor_hora` — a Trusted declara,
--   em maiusculas, que NAO recalcula metrica derivada: `custo_estimado` passa como o
--   iClips entrega. Justamente por isso da para TESTAR se o numero do iClips e coerente
--   com os outros dois que ele mesmo entrega. Medido: `custo_estimado` reproduz
--   `tempo_gasto_min / 60 * valor_hora` dentro de UM CENTAVO em 5.580 de 5.580 linhas,
--   ZERO excecoes. As outras tres identidades da casa (`rateio_fecha_no_centavo`,
--   `caixa_reproduz_o_razao`, `itens_batem_com_a_auditoria`) verificam contas da PROPRIA
--   casa; esta verifica a conta da plataforma. Se quebrar, ou o iClips mudou a formula ou
--   uma das tres colunas mudou de significado — e nenhuma contagem de linha denuncia.
--
-- AS OUTRAS QUE GUARDAM PREMISSA DE VERDADE:
--   `apontamento.vinculo_exclusivo_e_declarado` — a Trusted promete que todo apontamento
--     esta OU numa peca OU numa tarefa, nunca nos dois e nunca em nenhum, e emite a
--     coluna `vinculo` para ninguem precisar testar dois NULLs. Se quebrar, quem filtrar
--     por `vinculo` perde linha em silencio. 0 falhas em 5.580.
--   `apontamento.sentinela_nunca_esconde_hora` — a Trusted anula a data sentinela
--     1800-01-01 em 1.177 linhas, e a JUSTIFICATIVA escrita para isso ser seguro e que
--     todas elas tem `tempo_gasto_min` = 0, entao anular a data nao perde hora nenhuma.
--     Isto transforma a justificativa em teste. 0 falhas em 1.177.
--   `apontamento.hora_e_conversao_do_minuto` — `tempo_gasto_horas` e
--     `ROUND(tempo_gasto_min/60, 4)`, conversao de unidade e nao regra de negocio.
--   `etapa.refacao_concorda_com_o_tipo` — a Trusted guarda DUAS colunas de refacao:
--     `refacao_tipo` (texto, so no bronze, distingue "Alteracao Cliente" de "Alteracao
--     Interna") e `refacao` (bool, comparavel entre fontes). Medido: as duas concordam
--     em 514.909 de 514.909. Se divergirem, a leitura por bool e a leitura por texto
--     passam a contar coisas diferentes.
--   `projeto.documento_tem_forma` e `projeto.sem_cnpj_concorda_com_o_documento` sao a
--     guarda da correcao de hoje: a primeira dispara se a mascara voltar, a segunda se
--     a flag deixar de significar "sem documento valido".
--   `peca_atributo.cnpj_valido_concorda` — mesma classe, na tabela que ja guardava
--     digitos e que serviu de referencia para medir o estrago da outra.
--
-- AS QUATRO LINHAS DE BASE, E POR QUE O LIMIAR NAO E 1,00 NELAS:
--   `etapa.fim_nunca_antes_do_inicio` (ALERTA 0,999) — 430 de 489.500 etapas com o par
--     de datas tem fim anterior ao inicio. E DA ORIGEM, e o extremo prova: ha etapa com
--     inicio em 7202 e fim em 1923. 338 dos 430 invertem por menos de um dia.
--   `etapa.data_em_ano_plausivel` (ALERTA 0,9999) — 9 de 497.904 caem fora de 1990-2100.
--     E a regra que encontra o caso acima pela raiz, e o limiar e apertado de proposito
--     porque nove e o numero conhecido.
--   `projeto.documento_presente` (ALERTA 0,94) — 11.567 de 12.106 (95,55%). O buraco e
--     da origem e nao vai se fechar sozinho; a regra existe para detectar PIORA.
--   `peca_categoria.nome_preenchido` (ALERTA 0,95) — 28 de 29. A linha sem nome (id 41)
--     e conhecida e esta declarada na propria Trusted.
--
-- O QUE FICOU DE FORA, COM A MEDICAO QUE SUSTENTA:
--   `apontamento.peca_catalogada` — 1.386 dos 5.477 apontamentos de peca apontam para
--     peca que nao esta na `trs_iclips__peca_atributo` (25,3%), e
--   `etapa.peca_catalogada` — 342.054 de 514.909 (66,4%).
--   Nos dois casos NAO e buraco de cadastro: a peca_atributo e uma FOTOGRAFIA de 54.056
--     pecas vinda da `supabase-x0tz`, enquanto apontamento e etapa carregam historico
--     profundo do bronze e janela movel do notebook. A razao entre os dois muda sozinha
--     a cada carga. Regra que acusa o que e legitimo ensina a ignorar a suite — esta
--     casa ja pagou por isso uma vez, com os 2.555 CPFs da `rfn_operacao__peca`.
--   NADA MAIS. A lacuna que este bloco declarava em 29/09 -- a `rfn_operacao__tarefa_projeto`
--     (query-BzKD), publicada naquele dia e ainda nao materializada -- foi FECHADA em
--     30/09 com 12 regras. Ver o bloco proprio, mais abaixo no codigo.

WITH proj AS (
  SELECT DISTINCT id_projeto FROM `vanguardamartech_trusted`.`trs_iclips__projeto`
  WHERE id_projeto IS NOT NULL
),
tar AS (
  SELECT DISTINCT id_tarefa_job FROM `vanguardamartech_trusted`.`trs_iclips__tarefa`
  WHERE id_tarefa_job IS NOT NULL
),
wf AS (
  SELECT DISTINCT id_workflow FROM `vanguardamartech_trusted`.`trs_iclips__etapa`
  WHERE id_workflow IS NOT NULL
),

-- ---------------------------------------------------------------- APONTAMENTO (9)
r_apont AS (
  SELECT 'trs_iclips__apontamento.id_apontamento_unico' AS id_regra, 'Trusted' AS camada,
         'trs_iclips__apontamento' AS tabela, 'iClips' AS sistema, 'UNICIDADE' AS dimensao,
         'id_apontamento e unico e nunca nulo' AS regra, 'BLOQUEANTE' AS severidade,
         1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_apontamento)
           + COUNTIF(id_apontamento IS NULL) AS linhas_falha
  FROM `vanguardamartech_trusted`.`trs_iclips__apontamento`

  UNION ALL
  -- A promessa da coluna `vinculo`: peca OU tarefa, nunca as duas, nunca nenhuma.
  SELECT 'trs_iclips__apontamento.vinculo_exclusivo_e_declarado', 'Trusted',
         'trs_iclips__apontamento', 'iClips', 'VALIDADE',
         'o vinculo declarado bate com o id preenchido, e so um dos dois existe',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(NOT ((vinculo = 'PECA'   AND id_job_peca   IS NOT NULL AND id_tarefa_job IS NULL)
                   OR (vinculo = 'TAREFA' AND id_tarefa_job IS NOT NULL AND id_job_peca   IS NULL)))
  FROM `vanguardamartech_trusted`.`trs_iclips__apontamento`

  UNION ALL
  -- Unidade, nao regra de negocio: horas e ROUND(minutos/60, 4).
  SELECT 'trs_iclips__apontamento.hora_e_conversao_do_minuto', 'Trusted',
         'trs_iclips__apontamento', 'iClips', 'VALIDADE',
         'tempo_gasto_horas reproduz ROUND(tempo_gasto_min/60, 4)', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(ABS(IFNULL(tempo_gasto_horas, 0) - ROUND(IFNULL(tempo_gasto_min, 0) / 60, 4)) > 0.00001)
  FROM `vanguardamartech_trusted`.`trs_iclips__apontamento`

  UNION ALL
  -- A IDENTIDADE. Ver o bloco no cabecalho: o custo vem do iClips e nao e recalculado
  -- aqui, entao esta regra testa a coerencia da propria plataforma.
  SELECT 'trs_iclips__apontamento.custo_reproduz_hora_vezes_valor_hora', 'Trusted',
         'trs_iclips__apontamento', 'iClips', 'VALIDADE',
         'custo_estimado reproduz tempo_gasto_min/60 * valor_hora dentro de um centavo',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(ABS(IFNULL(custo_estimado, 0)
                     - IFNULL(tempo_gasto_min, 0) / 60 * IFNULL(valor_hora, 0)) > 0.01)
  FROM `vanguardamartech_trusted`.`trs_iclips__apontamento`

  UNION ALL
  -- A justificativa escrita para anular a sentinela vira teste.
  SELECT 'trs_iclips__apontamento.sentinela_nunca_esconde_hora', 'Trusted',
         'trs_iclips__apontamento', 'iClips', 'VALIDADE',
         'linha com data sentinela anulada tem tempo gasto zero', 'BLOQUEANTE', 1.00,
         COUNTIF(sem_data_de_execucao),
         COUNTIF(sem_data_de_execucao AND IFNULL(tempo_gasto_min, 0) <> 0)
  FROM `vanguardamartech_trusted`.`trs_iclips__apontamento`

  UNION ALL
  SELECT 'trs_iclips__apontamento.valor_nao_negativo', 'Trusted',
         'trs_iclips__apontamento', 'iClips', 'VALIDADE',
         'tempo gasto, valor hora e custo nunca sao negativos', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(tempo_gasto_min < 0 OR valor_hora < 0 OR custo_estimado < 0)
  FROM `vanguardamartech_trusted`.`trs_iclips__apontamento`

  UNION ALL
  -- Anti-join com DISTINCT no lado direito. NAO usar NOT EXISTS correlacionado:
  -- esta casa ja registrou que ele nao roda no BigQuery quando a uniao cresce.
  SELECT 'trs_iclips__apontamento.projeto_catalogado', 'Trusted',
         'trs_iclips__apontamento', 'iClips', 'INTEGRIDADE',
         'todo apontamento aponta para projeto que existe', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(p.id_projeto IS NULL)
  FROM `vanguardamartech_trusted`.`trs_iclips__apontamento` a
  LEFT JOIN proj p USING (id_projeto)

  UNION ALL
  SELECT 'trs_iclips__apontamento.tarefa_catalogada', 'Trusted',
         'trs_iclips__apontamento', 'iClips', 'INTEGRIDADE',
         'apontamento de tarefa aponta para tarefa que existe', 'BLOQUEANTE', 1.00,
         COUNTIF(a.vinculo = 'TAREFA'),
         COUNTIF(a.vinculo = 'TAREFA' AND t.id_tarefa_job IS NULL)
  FROM `vanguardamartech_trusted`.`trs_iclips__apontamento` a
  LEFT JOIN tar t USING (id_tarefa_job)
),
r_apont_wf AS (
  SELECT 'trs_iclips__apontamento.workflow_catalogado', 'Trusted',
         'trs_iclips__apontamento', 'iClips', 'INTEGRIDADE',
         'apontamento com workflow aponta para etapa que existe', 'BLOQUEANTE', 1.00,
         COUNTIF(a.id_workflow IS NOT NULL),
         COUNTIF(a.id_workflow IS NOT NULL AND w.id_workflow IS NULL)
  FROM `vanguardamartech_trusted`.`trs_iclips__apontamento` a
  LEFT JOIN wf w USING (id_workflow)
),

-- ---------------------------------------------------------------------- ETAPA (6)
r_etapa AS (
  SELECT 'trs_iclips__etapa.id_workflow_unico', 'Trusted',
         'trs_iclips__etapa', 'iClips', 'UNICIDADE',
         'id_workflow e unico e nunca nulo', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNT(*) - COUNT(DISTINCT id_workflow) + COUNTIF(id_workflow IS NULL)
  FROM `vanguardamartech_trusted`.`trs_iclips__etapa`

  UNION ALL
  -- As duas colunas de refacao dizem a mesma coisa em graus diferentes.
  SELECT 'trs_iclips__etapa.refacao_concorda_com_o_tipo', 'Trusted',
         'trs_iclips__etapa', 'iClips', 'VALIDADE',
         'a flag de refacao concorda com a existencia do tipo de refacao',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(IFNULL(refacao, FALSE) <> (refacao_tipo IS NOT NULL))
  FROM `vanguardamartech_trusted`.`trs_iclips__etapa`

  UNION ALL
  SELECT 'trs_iclips__etapa.sem_data_inicio_concorda', 'Trusted',
         'trs_iclips__etapa', 'iClips', 'VALIDADE',
         'a flag sem_data_inicio concorda com o inicio nulo', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(sem_data_inicio <> (inicio IS NULL))
  FROM `vanguardamartech_trusted`.`trs_iclips__etapa`

  UNION ALL
  -- LINHA DE BASE. 430 na medicao de hoje, e o defeito e da origem.
  SELECT 'trs_iclips__etapa.fim_nunca_antes_do_inicio', 'Trusted',
         'trs_iclips__etapa', 'iClips', 'VALIDADE',
         'a etapa nao termina antes de comecar', 'ALERTA', 0.999,
         COUNTIF(inicio IS NOT NULL AND fim IS NOT NULL),
         COUNTIF(inicio IS NOT NULL AND fim IS NOT NULL AND fim < inicio)
  FROM `vanguardamartech_trusted`.`trs_iclips__etapa`

  UNION ALL
  -- LINHA DE BASE. Ha etapa com inicio em 7202 e fim em 1923.
  SELECT 'trs_iclips__etapa.data_em_ano_plausivel', 'Trusted',
         'trs_iclips__etapa', 'iClips', 'VALIDADE',
         'as datas de etapa caem entre 1990 e 2100', 'ALERTA', 0.9999,
         COUNTIF(inicio IS NOT NULL OR fim IS NOT NULL),
         COUNTIF((inicio IS NOT NULL AND (EXTRACT(YEAR FROM inicio) < 1990 OR EXTRACT(YEAR FROM inicio) > 2100))
              OR (fim    IS NOT NULL AND (EXTRACT(YEAR FROM fim)    < 1990 OR EXTRACT(YEAR FROM fim)    > 2100)))
  FROM `vanguardamartech_trusted`.`trs_iclips__etapa`
),
r_etapa_fk AS (
  SELECT 'trs_iclips__etapa.projeto_catalogado', 'Trusted',
         'trs_iclips__etapa', 'iClips', 'INTEGRIDADE',
         'toda etapa aponta para projeto que existe', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(p.id_projeto IS NULL)
  FROM `vanguardamartech_trusted`.`trs_iclips__etapa` e
  LEFT JOIN proj p USING (id_projeto)
),

-- -------------------------------------------------------------------- PROJETO (5)
r_proj AS (
  SELECT 'trs_iclips__projeto.id_projeto_unico', 'Trusted',
         'trs_iclips__projeto', 'iClips', 'UNICIDADE',
         'id_projeto e unico e nunca nulo', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNT(*) - COUNT(DISTINCT id_projeto) + COUNTIF(id_projeto IS NULL)
  FROM `vanguardamartech_trusted`.`trs_iclips__projeto`

  UNION ALL
  -- GUARDA DA CORRECAO DE 29/09: se a mascara voltar, esta regra dispara.
  SELECT 'trs_iclips__projeto.documento_tem_forma', 'Trusted',
         'trs_iclips__projeto', 'iClips', 'VALIDADE',
         'o documento emitido tem 14 digitos (CNPJ) ou 11 (CPF), sem pontuacao',
         'BLOQUEANTE', 1.00,
         COUNTIF(cliente_cnpj IS NOT NULL),
         COUNTIF(cliente_cnpj IS NOT NULL
                 AND (LENGTH(cliente_cnpj) NOT IN (14, 11)
                      OR REGEXP_CONTAINS(cliente_cnpj, r'[^0-9]')))
  FROM `vanguardamartech_trusted`.`trs_iclips__projeto`

  UNION ALL
  SELECT 'trs_iclips__projeto.sem_cnpj_concorda_com_o_documento', 'Trusted',
         'trs_iclips__projeto', 'iClips', 'VALIDADE',
         'a flag sem_cnpj concorda com o documento nulo', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(sem_cnpj <> (cliente_cnpj IS NULL))
  FROM `vanguardamartech_trusted`.`trs_iclips__projeto`

  UNION ALL
  -- LINHA DE BASE. 95,55% na medicao de hoje; o buraco e da origem.
  SELECT 'trs_iclips__projeto.documento_presente', 'Trusted',
         'trs_iclips__projeto', 'iClips', 'COMPLETUDE',
         'o projeto carrega documento de cliente', 'ALERTA', 0.94,
         COUNT(*), COUNTIF(cliente_cnpj IS NULL)
  FROM `vanguardamartech_trusted`.`trs_iclips__projeto`

  UNION ALL
  SELECT 'trs_iclips__projeto.conclusao_nunca_antes_da_entrada', 'Trusted',
         'trs_iclips__projeto', 'iClips', 'VALIDADE',
         'o projeto nao conclui antes de entrar', 'BLOQUEANTE', 1.00,
         COUNTIF(data_entrada IS NOT NULL AND data_conclusao IS NOT NULL),
         COUNTIF(data_entrada IS NOT NULL AND data_conclusao IS NOT NULL
                 AND data_conclusao < data_entrada)
  FROM `vanguardamartech_trusted`.`trs_iclips__projeto`
),

-- --------------------------------------------------------------------- TAREFA (4)
r_tar AS (
  SELECT 'trs_iclips__tarefa.id_tarefa_job_unico', 'Trusted',
         'trs_iclips__tarefa', 'iClips', 'UNICIDADE',
         'id_tarefa_job e unico e nunca nulo', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNT(*) - COUNT(DISTINCT id_tarefa_job) + COUNTIF(id_tarefa_job IS NULL)
  FROM `vanguardamartech_trusted`.`trs_iclips__tarefa`

  UNION ALL
  SELECT 'trs_iclips__tarefa.sem_data_planejada_concorda', 'Trusted',
         'trs_iclips__tarefa', 'iClips', 'VALIDADE',
         'a flag sem_data_planejada concorda com o inicio planejado nulo',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(sem_data_planejada <> (inicio_planejado IS NULL))
  FROM `vanguardamartech_trusted`.`trs_iclips__tarefa`

  UNION ALL
  SELECT 'trs_iclips__tarefa.tempo_estimado_nao_negativo', 'Trusted',
         'trs_iclips__tarefa', 'iClips', 'VALIDADE',
         'o tempo estimado nunca e negativo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(tempo_estimado_min < 0)
  FROM `vanguardamartech_trusted`.`trs_iclips__tarefa`
),
r_tar_fk AS (
  -- A `rfn_operacao__tarefa_projeto` declara 8.835 de 8.835 sem orfa. Isto guarda a
  -- afirmacao: se ela soltar, aquela Refined perde o cliente de linhas inteiras.
  SELECT 'trs_iclips__tarefa.projeto_catalogado', 'Trusted',
         'trs_iclips__tarefa', 'iClips', 'INTEGRIDADE',
         'toda tarefa aponta para projeto que existe', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(p.id_projeto IS NULL)
  FROM `vanguardamartech_trusted`.`trs_iclips__tarefa` t
  LEFT JOIN proj p USING (id_projeto)
),

-- -------------------------------------------------------------- PECA_ATRIBUTO (5)
r_pat AS (
  SELECT 'trs_iclips__peca_atributo.id_job_peca_unico', 'Trusted',
         'trs_iclips__peca_atributo', 'iClips', 'UNICIDADE',
         'id_job_peca e unico e nunca nulo', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNT(*) - COUNT(DISTINCT id_job_peca) + COUNTIF(id_job_peca IS NULL)
  FROM `vanguardamartech_trusted`.`trs_iclips__peca_atributo`

  UNION ALL
  SELECT 'trs_iclips__peca_atributo.documento_tem_forma', 'Trusted',
         'trs_iclips__peca_atributo', 'iClips', 'VALIDADE',
         'o documento emitido tem 14 digitos (CNPJ) ou 11 (CPF), sem pontuacao',
         'BLOQUEANTE', 1.00,
         COUNTIF(cliente_cnpj IS NOT NULL),
         COUNTIF(cliente_cnpj IS NOT NULL
                 AND (LENGTH(cliente_cnpj) NOT IN (14, 11)
                      OR REGEXP_CONTAINS(cliente_cnpj, r'[^0-9]')))
  FROM `vanguardamartech_trusted`.`trs_iclips__peca_atributo`

  UNION ALL
  SELECT 'trs_iclips__peca_atributo.cnpj_valido_concorda', 'Trusted',
         'trs_iclips__peca_atributo', 'iClips', 'VALIDADE',
         'a flag cnpj_valido concorda com o documento de 14 digitos', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(cnpj_valido <> (cliente_cnpj IS NOT NULL AND LENGTH(cliente_cnpj) = 14))
  FROM `vanguardamartech_trusted`.`trs_iclips__peca_atributo`

  UNION ALL
  SELECT 'trs_iclips__peca_atributo.sem_custo_hora_concorda', 'Trusted',
         'trs_iclips__peca_atributo', 'iClips', 'VALIDADE',
         'a flag sem_custo_hora concorda com o valor hora zero ou ausente',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(sem_custo_hora <> (IFNULL(executor_valor_hora, 0) = 0))
  FROM `vanguardamartech_trusted`.`trs_iclips__peca_atributo`

  UNION ALL
  SELECT 'trs_iclips__peca_atributo.play_nunca_invertido', 'Trusted',
         'trs_iclips__peca_atributo', 'iClips', 'VALIDADE',
         'a etapa amostrada nao termina antes de comecar', 'BLOQUEANTE', 1.00,
         COUNTIF(etapa_amostrada_play_inicio IS NOT NULL AND etapa_amostrada_play_fim IS NOT NULL),
         COUNTIF(etapa_amostrada_play_fim < etapa_amostrada_play_inicio)
  FROM `vanguardamartech_trusted`.`trs_iclips__peca_atributo`
),

-- ------------------------------------------------------------- PECA_CATEGORIA (3)
r_cat AS (
  SELECT 'trs_iclips__peca_categoria.id_categoria_unico', 'Trusted',
         'trs_iclips__peca_categoria', 'iClips', 'UNICIDADE',
         'id_categoria e unico e nunca nulo', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNT(*) - COUNT(DISTINCT id_categoria) + COUNTIF(id_categoria IS NULL)
  FROM `vanguardamartech_trusted`.`trs_iclips__peca_categoria`

  UNION ALL
  SELECT 'trs_iclips__peca_categoria.flag_sem_nome_concorda', 'Trusted',
         'trs_iclips__peca_categoria', 'iClips', 'VALIDADE',
         'a flag flag_sem_nome concorda com o nome nulo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(flag_sem_nome <> (nome IS NULL))
  FROM `vanguardamartech_trusted`.`trs_iclips__peca_categoria`

  UNION ALL
  -- LINHA DE BASE. A categoria 41 nao tem nome, e isso ja esta declarado na Trusted.
  SELECT 'trs_iclips__peca_categoria.nome_preenchido', 'Trusted',
         'trs_iclips__peca_categoria', 'iClips', 'COMPLETUDE',
         'a categoria carrega nome', 'ALERTA', 0.95,
         COUNT(*), COUNTIF(nome IS NULL)
  FROM `vanguardamartech_trusted`.`trs_iclips__peca_categoria`
),

-- ------------------------------------------ rfn_operacao__tarefa_projeto (12)
-- A GOLD MATERIALIZOU, E A LACUNA DECLARADA NO CABECALHO FOI FECHADA. Em 29/09 esta
--   suite deixou a `rfn_operacao__tarefa_projeto` (query-BzKD) de fora com a causa
--   escrita: publicada naquele dia, ainda nao materializada, e referenciar tabela nao
--   materializada derruba a query inteira. Ela materializou em 30/09 com 8.854 linhas
--   (eram 8.835 na medicao de 29/09 -- a base andou, nao o tratamento).
--
-- A ORDEM PASSOU A SER GARANTIDA PELO GATILHO, e isso exigiu ACRESCENTAR a query-BzKD
--   ao conjunto "all". Antes desta mudanca a suite e a Gold eram IRMAS: as duas
--   disparavam nas Trusted do `notebook-Rbpo` em paralelo, entao a suite mediria a
--   Gold da passada ANTERIOR -- mediria certo e mediria velho, que e o pior tipo de
--   medicao porque nada denuncia. Com a BzKD no conjunto, a suite so roda depois que a
--   Gold reescreveu. O custo esta declarado e e o mesmo ja aceito para a query-8nEt:
--   se a Gold falhar, a suite inteira nao roda. Melhor nao medir do que medir velho.
r_gold AS (
  SELECT 'rfn_operacao__tarefa_projeto.id_tarefa_job_unico' AS id_regra, 'Refined' AS camada,
         'rfn_operacao__tarefa_projeto' AS tabela, 'iClips' AS sistema, 'UNICIDADE' AS dimensao,
         'id_tarefa_job e unico e nunca nulo' AS regra, 'BLOQUEANTE' AS severidade,
         1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_tarefa_job) + COUNTIF(id_tarefa_job IS NULL) AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_operacao__tarefa_projeto`

  UNION ALL
  -- A GUARDA DA CORRECAO DE 29/09, NA CAMADA DE CONSUMO. A `trs_iclips__projeto` emitia
  -- o CNPJ COM MASCARA e nao juntava com nada; esta Gold herda o documento dela. A regra
  -- irma na Trusted dispara se a mascara voltar na origem; esta dispara se ela voltar a
  -- ATRAVESSAR ate o consumo. Sao duas porque a Gold pode ganhar tratamento proprio.
  SELECT 'rfn_operacao__tarefa_projeto.documento_tem_forma', 'Refined',
         'rfn_operacao__tarefa_projeto', 'iClips', 'VALIDADE',
         'o documento herdado do projeto tem 14 digitos (CNPJ) ou 11 (CPF), sem pontuacao',
         'BLOQUEANTE', 1.00,
         COUNTIF(cliente_cnpj IS NOT NULL),
         COUNTIF(cliente_cnpj IS NOT NULL
                 AND (LENGTH(cliente_cnpj) NOT IN (14, 11)
                      OR REGEXP_CONTAINS(cliente_cnpj, r'[^0-9]')))
  FROM `vanguardamartech_refined`.`rfn_operacao__tarefa_projeto`

  UNION ALL
  SELECT 'rfn_operacao__tarefa_projeto.flag_sem_cnpj_concorda', 'Refined',
         'rfn_operacao__tarefa_projeto', 'iClips', 'VALIDADE',
         'a flag flag_sem_cnpj concorda com o documento nulo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(flag_sem_cnpj <> (cliente_cnpj IS NULL))
  FROM `vanguardamartech_refined`.`rfn_operacao__tarefa_projeto`

  UNION ALL
  -- ZERO E SENTINELA, NAO MEDIDA: 8.496 das 8.854 tarefas tem `tempo_estimado_min` = 0 e
  -- isso quer dizer SEM ESTIMATIVA, nunca "estimado em zero". A flag e o que separa os
  -- dois, e se ela deixar de concordar, toda media de estimativa passa a dividir por um
  -- denominador que inclui quem nunca foi estimado.
  SELECT 'rfn_operacao__tarefa_projeto.flag_sem_estimativa_concorda', 'Refined',
         'rfn_operacao__tarefa_projeto', 'iClips', 'VALIDADE',
         'a flag flag_sem_estimativa concorda com o tempo estimado zero ou ausente',
         'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(flag_sem_estimativa <> (IFNULL(tempo_estimado_min, 0) = 0))
  FROM `vanguardamartech_refined`.`rfn_operacao__tarefa_projeto`

  UNION ALL
  -- A FLAG CONTA APONTAMENTO, E ISSO NAO E DETALHE. Medido: 70 tarefas tem apontamento
  -- real e `tempo_gasto_min` = 0 -- o apontamento existe e nao registrou minuto (a
  -- Trusted ja declara que 69 dos 83 pares nem data de play tem). Se alguem reescrever a
  -- flag como "minuto zero", essas 70 mudam de lado em silencio: passam a contar como
  -- "sem tempo apontado" quando o apontamento existe. A regra fixa a definicao.
  SELECT 'rfn_operacao__tarefa_projeto.flag_sem_tempo_conta_apontamento', 'Refined',
         'rfn_operacao__tarefa_projeto', 'iClips', 'VALIDADE',
         'a flag flag_sem_tempo_apontado conta APONTAMENTO, nunca minuto', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(flag_sem_tempo_apontado <> (qtd_apontamentos_reais = 0))
  FROM `vanguardamartech_refined`.`rfn_operacao__tarefa_projeto`

  UNION ALL
  -- IMPLICACAO, NAO IGUALDADE -- e a escolha e o ponto. Hoje `razao_gasto_sobre_estimado`
  -- e NULL em 8.854 de 8.854, porque os dois conjuntos sao DISJUNTOS: as 358 tarefas com
  -- estimativa e as 83 com tempo apontado nao tem uma unica em comum. Uma regra exigindo
  -- "sempre NULL" transformaria a MELHORIA ESPERADA -- o dia em que uma tarefa tiver os
  -- dois lados -- em falha. O que se pode afirmar sem prender o futuro e o outro lado:
  -- a razao nunca existe sem os dois lados. Mesma doutrina da
  -- `venda_conta_azul_implica_a_flag` na suite de Midia Gold.
  SELECT 'rfn_operacao__tarefa_projeto.razao_so_existe_com_os_dois_lados', 'Refined',
         'rfn_operacao__tarefa_projeto', 'iClips', 'VALIDADE',
         'a razao gasto/estimado so existe onde ha estimativa E tempo apontado',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(razao_gasto_sobre_estimado IS NOT NULL
                 AND (IFNULL(tempo_estimado_min, 0) = 0 OR IFNULL(tempo_gasto_min, 0) = 0))
  FROM `vanguardamartech_refined`.`rfn_operacao__tarefa_projeto`

  UNION ALL
  -- Guarda a familia `DATE(MAX(ano), MAX(mes), 1)` e o acoplamento com a data: as 740
  -- tarefas sem inicio planejado sao exatamente as 740 sem mes de referencia.
  SELECT 'rfn_operacao__tarefa_projeto.mes_referencia_e_o_primeiro_dia', 'Refined',
         'rfn_operacao__tarefa_projeto', 'iClips', 'VALIDADE',
         'mes_referencia e o primeiro dia do mes do inicio planejado, e nulo com ele',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF((mes_referencia IS NULL) <> (data_inicio_planejado IS NULL)
              OR (mes_referencia IS NOT NULL
                  AND mes_referencia <> DATE_TRUNC(data_inicio_planejado, MONTH)))
  FROM `vanguardamartech_refined`.`rfn_operacao__tarefa_projeto`

  UNION ALL
  -- O `DATE()` DOS DOIS LADOS E OBRIGATORIO, e eu errei isso ao medir. Comparando no
  -- nivel do TIMESTAMP a regra acusa 46 de 7.829; com as datas, ZERO. A duracao e em
  -- DIAS DE CALENDARIO, entao a hora nao entra -- e 46 falsos positivos bastariam para
  -- ensinar a ignorar a suite.
  SELECT 'rfn_operacao__tarefa_projeto.duracao_reproduz_as_datas', 'Refined',
         'rfn_operacao__tarefa_projeto', 'iClips', 'VALIDADE',
         'duracao_planejada_dias reproduz a diferenca entre as DATAS planejadas',
         'BLOQUEANTE', 1.00,
         COUNTIF(inicio_planejado IS NOT NULL AND fim_planejado IS NOT NULL),
         COUNTIF(inicio_planejado IS NOT NULL AND fim_planejado IS NOT NULL
                 AND IFNULL(duracao_planejada_dias, -1)
                     <> DATE_DIFF(DATE(fim_planejado), DATE(inicio_planejado), DAY))
  FROM `vanguardamartech_refined`.`rfn_operacao__tarefa_projeto`

  UNION ALL
  -- Unidade, nao regra de negocio -- irma da `apontamento.hora_e_conversao_do_minuto`.
  -- Se a unidade escorregar, toda leitura de hora muda de ordem de grandeza e a contagem
  -- de linhas nao muda.
  SELECT 'rfn_operacao__tarefa_projeto.horas_reproduzem_os_minutos', 'Refined',
         'rfn_operacao__tarefa_projeto', 'iClips', 'VALIDADE',
         'tempo estimado e gasto em horas reproduzem os respectivos minutos',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(ABS(IFNULL(tempo_estimado_horas, 0) - IFNULL(tempo_estimado_min, 0) / 60) > 0.005
              OR ABS(IFNULL(tempo_gasto_horas, 0)    - IFNULL(tempo_gasto_min, 0)    / 60) > 0.005)
  FROM `vanguardamartech_refined`.`rfn_operacao__tarefa_projeto`

  UNION ALL
  SELECT 'rfn_operacao__tarefa_projeto.metrica_nao_negativa', 'Refined',
         'rfn_operacao__tarefa_projeto', 'iClips', 'VALIDADE',
         'tempo, apontamento, executor, custo e duracao nunca sao negativos',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(tempo_estimado_min < 0 OR tempo_gasto_min < 0 OR qtd_apontamentos_reais < 0
              OR qtd_executores < 0 OR custo_apontado < 0 OR duracao_planejada_dias < 0
              OR qtd_atividades_no_payload < 0)
  FROM `vanguardamartech_refined`.`rfn_operacao__tarefa_projeto`

  UNION ALL
  -- 8.712 das 8.854 linhas sao BRONZE_HISTORICO -- a Gold declara que o historico nao
  -- avanca sozinho e depende da `supabase-x0tz`. Se aparecer um terceiro valor, o eixo
  -- que separa historico de vivo passa a ter uma fatia que nenhuma leitura enxerga, e a
  -- contagem de linhas nao muda.
  SELECT 'rfn_operacao__tarefa_projeto.origem_do_registro_conhecida', 'Refined',
         'rfn_operacao__tarefa_projeto', 'iClips', 'VALIDADE',
         'origem_do_registro e BRONZE_HISTORICO ou NOTEBOOK_VIVO, e a flag concorda',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(origem_do_registro NOT IN ('BRONZE_HISTORICO', 'NOTEBOOK_VIVO')
              OR origem_do_registro IS NULL
              OR flag_registro_historico <> (origem_do_registro = 'BRONZE_HISTORICO'))
  FROM `vanguardamartech_refined`.`rfn_operacao__tarefa_projeto`
),
r_gold_fk AS (
  -- Mede a orfandade E a flag no mesmo passo. A flag existe porque uma DIMENSAO PODE
  -- ESVAZIAR: a `github_repositories` foi de 10 linhas para ZERO quando a fonte caiu,
  -- enquanto os fatos continuaram la. Se isso acontecer com o projeto do iClips, a
  -- contagem de tarefas nao muda e o cliente some de linhas inteiras.
  SELECT 'rfn_operacao__tarefa_projeto.projeto_catalogado', 'Refined',
         'rfn_operacao__tarefa_projeto', 'iClips', 'INTEGRIDADE',
         'toda tarefa aponta para projeto que existe, e a flag concorda', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(p.id_projeto IS NULL
                 OR g.flag_projeto_nao_catalogado <> (p.id_projeto IS NULL))
  FROM `vanguardamartech_refined`.`rfn_operacao__tarefa_projeto` g
  LEFT JOIN proj p USING (id_projeto)
),

-- --------------------------------------------------------------------- FRESCOR (1)
-- Escopo de FONTE, nao de sistema: so as quatro do notebook-Rbpo. Ver o cabecalho.
carga AS (
  SELECT 'apontamento' AS t, MAX(DATE(_extraido_at)) AS d FROM `vanguardamartech_trusted`.`trs_iclips__apontamento`
  UNION ALL SELECT 'etapa',   MAX(DATE(_extraido_at)) FROM `vanguardamartech_trusted`.`trs_iclips__etapa`
  UNION ALL SELECT 'projeto', MAX(DATE(_extraido_at)) FROM `vanguardamartech_trusted`.`trs_iclips__projeto`
  UNION ALL SELECT 'tarefa',  MAX(DATE(_extraido_at)) FROM `vanguardamartech_trusted`.`trs_iclips__tarefa`
),
r_frescor AS (
  SELECT 'iclips.carga_do_mesmo_dia' AS id_regra, 'Trusted' AS camada,
         '(as 4 tabelas do notebook-Rbpo)' AS tabela, 'iClips' AS sistema,
         'VALIDADE' AS dimensao,
         'as 4 Trusted do notebook-Rbpo foram escritas na mesma passada' AS regra,
         'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNTIF(d <> (SELECT MAX(d) FROM carga)) AS linhas_falha
  FROM carga
),

todas AS (
  SELECT * FROM r_apont
  UNION ALL SELECT * FROM r_apont_wf
  UNION ALL SELECT * FROM r_etapa
  UNION ALL SELECT * FROM r_etapa_fk
  UNION ALL SELECT * FROM r_proj
  UNION ALL SELECT * FROM r_tar
  UNION ALL SELECT * FROM r_tar_fk
  UNION ALL SELECT * FROM r_pat
  UNION ALL SELECT * FROM r_cat
  UNION ALL SELECT * FROM r_gold
  UNION ALL SELECT * FROM r_gold_fk
  UNION ALL SELECT * FROM r_frescor
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
  'iClips'                                      AS familia,
  CURRENT_TIMESTAMP()                           AS _extraido_at,
  'multiplas'                                   AS _fonte,
  'America/Sao_Paulo'                           AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(a)))                AS _payload_hash
FROM avaliado a
