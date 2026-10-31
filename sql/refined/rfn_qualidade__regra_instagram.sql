-- rfn_qualidade__regra_instagram  ·  Refined / qualidade  ·  L2 INTERNAL
-- Grao: uma REGRA de qualidade em uma execucao. Chave: id_regra (a execucao se le em
-- _extraido_at). Gatilho: evento (regra all) nas CINCO Refined de social, que so disparam
-- depois das seis Trusted de Instagram: quando esta suite roda, toda tabela lida ja foi
-- reescrita na mesma passada. Alerta de falha ligado.
--
-- CONTRATO DE COLUNAS IDENTICO ao das outras suites (id_regra, camada, tabela, sistema,
-- dimensao, regra, severidade, limiar, linhas_avaliadas, linhas_falha, linhas_conformes,
-- taxa_conformidade, is_conforme, flag_sem_linha_para_avaliar, resultado): um UNION ALL
-- entre as suites da o painel unico e `familia` diz de onde veio cada linha.
--
-- POR QUE SUITE PROPRIA: a suite principal esta em 57 KB e update_transformation substitui o
-- codigo inteiro; somar regras la e o risco que a casa ja registrou. Esta familia nasceu em
-- 16/10/2026, com gatilho e cadencia (terca) proprios.
--
-- ATUALIZACAO 29/10/2026: (a) o dominio de produto ganhou PROFILE_PIC (1 linha, instagram-8tL4, 25/10, 1 visualizacao),
--   alem de LIVE (21/10) e DEFAULT_DO_NOT_USE (22/10) -- o arquivo estava defasado em relacao ao deploy nesses dois;
--   (b) as duas identidades de VISUALIZACOES (soma por produto = janela DIA da conta; produto_mensal = conta_mensal)
--   aceitam diferenca relativa de ate 0,5%. Unico caso medido: Arena Tintas (instagram-yHk3), dia 21/10, 6.404 contra
--   6.415 (0,17%); a Raw ja traz os dois numeros divergentes. Interacoes, curtidas e compartilhamentos seguem exatos.
--   Duplicacao de grao daria muito mais que 0,5%. A alternativa nao tomada era restringir a dias fechados pela data
--   da extracao, mas o _extraido_at da Trusted e o da carga da propria Trusted, nao o da fonte.
--
-- TRES TIPOS DE REGRA, todas medidas na lógica reproduzida sobre a Raw antes de publicar:
--  (1) CHAVE E INTEGRIDADE: id unico, conta catalogada (anti-join com DISTINCT, nunca
--      NOT EXISTS correlacionado), dominio conhecido.
--  (2) IDENTIDADES ENTRE CAMADAS: a Refined agrega e nao filtra, entao a soma reproduz a
--      Trusted; e uma identidade ENTRE Trusted: a soma por produto reproduz o DIA da conta.
--  (3) LINHAS DE BASE com limiar medido, para detectar piora e nao reclamar do que a casa
--      ja sabe. Datas se medem contra DATE(_extraido_at), nunca contra o relogio.
-- Zero de zero nao passa: regra sem linha para avaliar sai SEM_DADO.
WITH
-- ───────────────────────── Trusted · conta ─────────────────────────
r_conta AS (
  SELECT 'trs_instagram__conta.id_conta_unico' AS id_regra, 'Trusted' AS camada,
         'trs_instagram__conta' AS tabela, 'Instagram' AS sistema, 'UNICIDADE' AS dimensao,
         'id_conta e unico' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_conta) AS linhas_falha
  FROM `vanguardamartech_trusted`.`trs_instagram__conta`
  UNION ALL
  -- R-001: uma camada por fonte, uma conta por fonte. Duas contas na mesma fonte = a
  -- camada deixou de ser exclusiva.
  SELECT 'trs_instagram__conta.uma_conta_por_fonte', 'Trusted', 'trs_instagram__conta',
         'Instagram', 'UNICIDADE', 'cada fonte instagram-* traz exatamente uma conta',
         'BLOQUEANTE', 1.00, COUNT(*), COUNT(*) - COUNT(DISTINCT _fonte)
  FROM `vanguardamartech_trusted`.`trs_instagram__conta`
  UNION ALL
  SELECT 'trs_instagram__conta.contagens_nao_negativas', 'Trusted', 'trs_instagram__conta',
         'Instagram', 'VALIDADE', 'seguidores, seguindo e qtd_midias_na_conta nunca negativos',
         'BLOQUEANTE', 1.00, COUNT(*),
         COUNTIF(seguidores < 0 OR seguindo < 0 OR qtd_midias_na_conta < 0)
  FROM `vanguardamartech_trusted`.`trs_instagram__conta`
  UNION ALL
  -- Data contra _extraido_at, nunca contra o relogio.
  SELECT 'trs_instagram__conta.snapshot_datado_e_nao_futuro', 'Trusted', 'trs_instagram__conta',
         'Instagram', 'VALIDADE', 'a fotografia tem data e ela nao e posterior a execucao',
         'ALERTA', 1.00, COUNT(*),
         COUNTIF(data_snapshot_seguidores IS NULL OR data_snapshot_seguidores > DATE(_extraido_at))
  FROM `vanguardamartech_trusted`.`trs_instagram__conta`
),
-- ───────────────────────── Trusted · midia ─────────────────────────
r_midia AS (
  SELECT 'trs_instagram__midia.id_midia_unico', 'Trusted', 'trs_instagram__midia', 'Instagram',
         'UNICIDADE', 'id_midia e unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_midia)
  FROM `vanguardamartech_trusted`.`trs_instagram__midia`
  UNION ALL
  SELECT 'trs_instagram__midia.conta_catalogada', 'Trusted', 'trs_instagram__midia', 'Instagram',
         'INTEGRIDADE', 'toda midia aponta para uma conta de trs_instagram__conta',
         'BLOQUEANTE', 1.00, COUNT(*), COUNTIF(c.id_conta IS NULL)
  FROM `vanguardamartech_trusted`.`trs_instagram__midia` m
  LEFT JOIN (SELECT DISTINCT id_conta FROM `vanguardamartech_trusted`.`trs_instagram__conta`) c
         ON c.id_conta = m.id_conta
  UNION ALL
  -- A premissa R3 da Trusted: story nao tem curtida nem comentario. A API devolve 0 e o
  -- zero e sentinela; a Trusted o anula. Se voltar a sair numero, o zero virou "medida".
  SELECT 'trs_instagram__midia.story_sem_curtida_nem_comentario', 'Trusted',
         'trs_instagram__midia', 'Instagram', 'VALIDADE',
         'curtidas e comentarios de STORY sao NULL, nunca zero', 'BLOQUEANTE', 1.00,
         COUNTIF(is_story), COUNTIF(is_story AND (curtidas IS NOT NULL OR comentarios IS NOT NULL))
  FROM `vanguardamartech_trusted`.`trs_instagram__midia`
  UNION ALL
  SELECT 'trs_instagram__midia.produto_conhecido', 'Trusted', 'trs_instagram__midia', 'Instagram',
         'VALIDADE', 'produto e FEED, REELS ou STORY', 'ALERTA', 1.00,
         COUNT(*), COUNTIF(produto NOT IN ('FEED', 'REELS', 'STORY'))
  FROM `vanguardamartech_trusted`.`trs_instagram__midia`
  UNION ALL
  -- Guarda do fuso: `timestamp` e UTC e a data local sai de DATETIME(ts,'America/Sao_Paulo').
  -- Se alguem trocar por DATE(ts) (UTC) ou por TIMESTAMP(dt,tz), a data local diverge.
  SELECT 'trs_instagram__midia.data_local_reproduz_o_fuso', 'Trusted', 'trs_instagram__midia',
         'Instagram', 'VALIDADE', 'data_local e a data de publicado_em em America/Sao_Paulo',
         'BLOQUEANTE', 1.00, COUNT(*),
         COUNTIF(data_local <> DATE(DATETIME(publicado_em, 'America/Sao_Paulo')))
  FROM `vanguardamartech_trusted`.`trs_instagram__midia`
  UNION ALL
  SELECT 'trs_instagram__midia.publicado_nao_futuro', 'Trusted', 'trs_instagram__midia',
         'Instagram', 'VALIDADE', 'publicado_em nao e posterior a execucao', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(publicado_em > _extraido_at)
  FROM `vanguardamartech_trusted`.`trs_instagram__midia`
  UNION ALL
  SELECT 'trs_instagram__midia.derivadas_da_legenda_coerentes', 'Trusted',
         'trs_instagram__midia', 'Instagram', 'VALIDADE',
         'hashtag ou mencao so existe em legenda com texto', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF((qtd_hashtags > 0 OR qtd_mencoes > 0) AND legenda_caracteres = 0)
  FROM `vanguardamartech_trusted`.`trs_instagram__midia`
  UNION ALL
  -- LINHA DE BASE: o insight e 1:1 com a midia hoje. Cai quando uma fonte com media mas sem
  -- media_insights materializada entrar (a uniao de insights omite a fonte).
  SELECT 'trs_instagram__midia.tem_insight', 'Trusted', 'trs_instagram__midia', 'Instagram',
         'COMPLETUDE', 'toda midia tem insight', 'ALERTA', 0.95,
         COUNT(*), COUNTIF(NOT tem_insight)
  FROM `vanguardamartech_trusted`.`trs_instagram__midia`
  UNION ALL
  SELECT 'trs_instagram__midia.alcance_nao_excede_visualizacoes', 'Trusted',
         'trs_instagram__midia', 'Instagram', 'VALIDADE',
         'alcance (contas unicas) nao passa de visualizacoes', 'ALERTA', 0.98,
         COUNTIF(alcance IS NOT NULL AND visualizacoes IS NOT NULL),
         COUNTIF(alcance IS NOT NULL AND visualizacoes IS NOT NULL AND alcance > visualizacoes)
  FROM `vanguardamartech_trusted`.`trs_instagram__midia`
),
-- ───────────────────────── Trusted · insight_conta ─────────────────────────
r_ic AS (
  SELECT 'trs_instagram__insight_conta.id_insight_conta_unico', 'Trusted',
         'trs_instagram__insight_conta', 'Instagram', 'UNICIDADE',
         'id_insight_conta (conta + janela + data) e unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_insight_conta)
  FROM `vanguardamartech_trusted`.`trs_instagram__insight_conta`
  UNION ALL
  SELECT 'trs_instagram__insight_conta.janela_conhecida', 'Trusted',
         'trs_instagram__insight_conta', 'Instagram', 'VALIDADE',
         'janela e DIA, SEMANA ou 28_DIAS', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(janela NOT IN ('DIA', 'SEMANA', '28_DIAS'))
  FROM `vanguardamartech_trusted`.`trs_instagram__insight_conta`
  UNION ALL
  SELECT 'trs_instagram__insight_conta.conta_catalogada', 'Trusted',
         'trs_instagram__insight_conta', 'Instagram', 'INTEGRIDADE',
         'todo insight aponta para uma conta de trs_instagram__conta', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(c.id_conta IS NULL)
  FROM `vanguardamartech_trusted`.`trs_instagram__insight_conta` i
  LEFT JOIN (SELECT DISTINCT id_conta FROM `vanguardamartech_trusted`.`trs_instagram__conta`) c
         ON c.id_conta = i.id_conta
  UNION ALL
  -- `date` da Raw e data disfarcada de timestamp (00:00 UTC): DATE() sem fuso. Contra
  -- DATE(_extraido_at), nunca contra o relogio.
  SELECT 'trs_instagram__insight_conta.data_nao_futura', 'Trusted',
         'trs_instagram__insight_conta', 'Instagram', 'VALIDADE',
         'data_fim_janela nao e posterior a execucao', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(data_fim_janela > DATE(_extraido_at))
  FROM `vanguardamartech_trusted`.`trs_instagram__insight_conta`
  UNION ALL
  SELECT 'trs_instagram__insight_conta.contagens_nao_negativas', 'Trusted',
         'trs_instagram__insight_conta', 'Instagram', 'VALIDADE',
         'alcance, visualizacoes e interacoes nunca negativos', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(alcance < 0 OR visualizacoes < 0 OR interacoes_totais < 0 OR contas_engajadas < 0)
  FROM `vanguardamartech_trusted`.`trs_instagram__insight_conta`
  UNION ALL
  -- Aritmetica da propria plataforma: seguimentos liquidos = seguimentos - deixaram de seguir.
  -- Medido 51 de 51 na Raw.
  SELECT 'trs_instagram__insight_conta.seguimento_liquido_reproduz_a_diferenca', 'Trusted',
         'trs_instagram__insight_conta', 'Instagram', 'VALIDADE',
         'seguimentos_liquidos = seguimentos - deixaram_de_seguir', 'ALERTA', 1.00,
         COUNTIF(seguimentos_liquidos IS NOT NULL AND seguimentos IS NOT NULL AND deixaram_de_seguir IS NOT NULL),
         COUNTIF(seguimentos_liquidos IS NOT NULL AND seguimentos IS NOT NULL AND deixaram_de_seguir IS NOT NULL
                 AND seguimentos_liquidos <> seguimentos - deixaram_de_seguir)
  FROM `vanguardamartech_trusted`.`trs_instagram__insight_conta`
  UNION ALL
  SELECT 'trs_instagram__insight_conta.contas_engajadas_nao_excede_alcance', 'Trusted',
         'trs_instagram__insight_conta', 'Instagram', 'VALIDADE',
         'contas engajadas (unicas) nao passam do alcance (unicas)', 'ALERTA', 0.98,
         COUNTIF(contas_engajadas IS NOT NULL AND alcance IS NOT NULL),
         COUNTIF(contas_engajadas IS NOT NULL AND alcance IS NOT NULL AND contas_engajadas > alcance)
  FROM `vanguardamartech_trusted`.`trs_instagram__insight_conta`
),
-- ───────────────────────── Trusted · insight_produto_dia ─────────────────────────
r_ip AS (
  SELECT 'trs_instagram__insight_produto_dia.id_insight_produto_unico', 'Trusted',
         'trs_instagram__insight_produto_dia', 'Instagram', 'UNICIDADE',
         'id_insight_produto (conta + dia + produto) e unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_insight_produto)
  FROM `vanguardamartech_trusted`.`trs_instagram__insight_produto_dia`
  UNION ALL
  SELECT 'trs_instagram__insight_produto_dia.conta_catalogada', 'Trusted',
         'trs_instagram__insight_produto_dia', 'Instagram', 'INTEGRIDADE',
         'todo insight por produto aponta para uma conta de trs_instagram__conta',
         'BLOQUEANTE', 1.00, COUNT(*), COUNTIF(c.id_conta IS NULL)
  FROM `vanguardamartech_trusted`.`trs_instagram__insight_produto_dia` p
  LEFT JOIN (SELECT DISTINCT id_conta FROM `vanguardamartech_trusted`.`trs_instagram__conta`) c
         ON c.id_conta = p.id_conta
  UNION ALL
  SELECT 'trs_instagram__insight_produto_dia.produto_conhecido', 'Trusted',
         'trs_instagram__insight_produto_dia', 'Instagram', 'VALIDADE',
         'produto e AD, CAROUSEL_CONTAINER, DEFAULT_DO_NOT_USE, IGTV, LIVE, POST, PROFILE_PIC, REEL ou STORY', 'ALERTA', 1.00,
         COUNT(*), COUNTIF(produto NOT IN ('AD', 'CAROUSEL_CONTAINER', 'DEFAULT_DO_NOT_USE', 'IGTV', 'LIVE', 'POST', 'PROFILE_PIC', 'REEL', 'STORY'))
  FROM `vanguardamartech_trusted`.`trs_instagram__insight_produto_dia`
  UNION ALL
  -- IDENTIDADE ENTRE DUAS TRUSTED, no grao (conta, dia): a soma por produto de visualizacoes,
  -- interacoes, curtidas e compartilhamentos reproduz o DIA da conta. Medido 17 de 17.
  -- Alcance fica de fora de proposito: nao e aditivo e a soma por produto passa do dia.
  SELECT 'trs_instagram__insight_produto_dia.soma_por_produto_reproduz_o_dia_da_conta', 'Trusted',
         'trs_instagram__insight_produto_dia', 'Instagram', 'INTEGRIDADE',
         'visualizacoes (tolerancia relativa de 0,5%), interacoes, curtidas e compartilhamentos somados por produto = janela DIA da conta',
         'BLOQUEANTE', 1.00, COUNT(*),
         COUNTIF(ABS(p.v - d.visualizacoes) > 0.005 * GREATEST(d.visualizacoes, 1) OR p.i <> d.interacoes_totais
                 OR p.l <> d.curtidas OR p.s <> d.compartilhamentos)
  FROM (SELECT id_conta, data, SUM(visualizacoes) v, SUM(interacoes_totais) i,
               SUM(curtidas) l, SUM(compartilhamentos) s
        FROM `vanguardamartech_trusted`.`trs_instagram__insight_produto_dia`
        GROUP BY id_conta, data) p
  JOIN (SELECT id_conta, data_fim_janela AS data, visualizacoes, interacoes_totais, curtidas, compartilhamentos
        FROM `vanguardamartech_trusted`.`trs_instagram__insight_conta`
        WHERE janela = 'DIA') d
    ON d.id_conta = p.id_conta AND d.data = p.data
  UNION ALL
  -- LINHA DE BASE: saves negativo e ajuste da plataforma (2 de 81 na Raw). Detecta piora.
  SELECT 'trs_instagram__insight_produto_dia.salvamentos_negativo', 'Trusted',
         'trs_instagram__insight_produto_dia', 'Instagram', 'VALIDADE',
         'salvamentos negativo e raro (ajuste da plataforma)', 'ALERTA', 0.95,
         COUNT(*), COUNTIF(flag_salvamentos_negativo)
  FROM `vanguardamartech_trusted`.`trs_instagram__insight_produto_dia`
),
-- ───────────────────────── Trusted · audiencia ─────────────────────────
r_aud AS (
  SELECT 'trs_instagram__audiencia_seguidor.id_audiencia_unico', 'Trusted',
         'trs_instagram__audiencia_seguidor', 'Instagram', 'UNICIDADE',
         'id_audiencia (conta + dimensao + valor) e unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_audiencia)
  FROM `vanguardamartech_trusted`.`trs_instagram__audiencia_seguidor`
  UNION ALL
  SELECT 'trs_instagram__audiencia_seguidor.conta_catalogada', 'Trusted',
         'trs_instagram__audiencia_seguidor', 'Instagram', 'INTEGRIDADE',
         'toda linha de audiencia aponta para uma conta de trs_instagram__conta',
         'BLOQUEANTE', 1.00, COUNT(*), COUNTIF(c.id_conta IS NULL)
  FROM `vanguardamartech_trusted`.`trs_instagram__audiencia_seguidor` a
  LEFT JOIN (SELECT DISTINCT id_conta FROM `vanguardamartech_trusted`.`trs_instagram__conta`) c
         ON c.id_conta = a.id_conta
  UNION ALL
  SELECT 'trs_instagram__audiencia_seguidor.dimensao_conhecida', 'Trusted',
         'trs_instagram__audiencia_seguidor', 'Instagram', 'VALIDADE',
         'dimensao e IDADE, GENERO, PAIS ou CIDADE', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(dimensao NOT IN ('IDADE', 'GENERO', 'PAIS', 'CIDADE'))
  FROM `vanguardamartech_trusted`.`trs_instagram__audiencia_seguidor`
  UNION ALL
  SELECT 'trs_instagram__audiencia_seguidor.qtd_positiva', 'Trusted',
         'trs_instagram__audiencia_seguidor', 'Instagram', 'VALIDADE',
         'qtd_seguidores e sempre positiva', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(qtd_seguidores IS NULL OR qtd_seguidores <= 0)
  FROM `vanguardamartech_trusted`.`trs_instagram__audiencia_seguidor`
  UNION ALL
  -- Grao conta: IDADE e GENERO particionam a mesma base. Medido 12 de 12.
  SELECT 'trs_instagram__audiencia_seguidor.idade_e_genero_fecham', 'Trusted',
         'trs_instagram__audiencia_seguidor', 'Instagram', 'INTEGRIDADE',
         'a soma por conta de IDADE e igual a de GENERO', 'ALERTA', 1.00,
         COUNT(*), COUNTIF(idade <> genero)
  FROM (SELECT id_conta,
               SUM(IF(dimensao = 'IDADE', qtd_seguidores, 0)) AS idade,
               SUM(IF(dimensao = 'GENERO', qtd_seguidores, 0)) AS genero
        FROM `vanguardamartech_trusted`.`trs_instagram__audiencia_seguidor`
        GROUP BY id_conta)
  UNION ALL
  SELECT 'trs_instagram__audiencia_seguidor.demografia_nao_excede_seguidores', 'Trusted',
         'trs_instagram__audiencia_seguidor', 'Instagram', 'INTEGRIDADE',
         'quem tem idade informada nao passa dos seguidores da conta', 'ALERTA', 1.00,
         COUNT(*), COUNTIF(a.idade > c.seguidores)
  FROM (SELECT id_conta, SUM(IF(dimensao = 'IDADE', qtd_seguidores, 0)) AS idade
        FROM `vanguardamartech_trusted`.`trs_instagram__audiencia_seguidor`
        GROUP BY id_conta) a
  JOIN `vanguardamartech_trusted`.`trs_instagram__conta` c ON c.id_conta = a.id_conta
),
-- ───────────────────────── Trusted · seguidores_dia ─────────────────────────
r_seg AS (
  SELECT 'trs_instagram__seguidores_dia.id_seguidores_dia_unico', 'Trusted',
         'trs_instagram__seguidores_dia', 'Instagram', 'UNICIDADE',
         'id_seguidores_dia (conta + data) e unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_seguidores_dia)
  FROM `vanguardamartech_trusted`.`trs_instagram__seguidores_dia`
  UNION ALL
  SELECT 'trs_instagram__seguidores_dia.conta_catalogada', 'Trusted',
         'trs_instagram__seguidores_dia', 'Instagram', 'INTEGRIDADE',
         'todo ponto aponta para uma conta de trs_instagram__conta', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(c.id_conta IS NULL)
  FROM `vanguardamartech_trusted`.`trs_instagram__seguidores_dia` s
  LEFT JOIN (SELECT DISTINCT id_conta FROM `vanguardamartech_trusted`.`trs_instagram__conta`) c
         ON c.id_conta = s.id_conta
  UNION ALL
  SELECT 'trs_instagram__seguidores_dia.seguidores_nao_negativo', 'Trusted',
         'trs_instagram__seguidores_dia', 'Instagram', 'VALIDADE',
         'seguidores nunca negativo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(seguidores IS NULL OR seguidores < 0)
  FROM `vanguardamartech_trusted`.`trs_instagram__seguidores_dia`
  UNION ALL
  -- LINHA DE BASE: o ultimo ponto da serie e o followers_count do perfil (12 de 12 hoje).
  -- Pode divergir se perfil e serie forem lidos em momentos diferentes.
  SELECT 'trs_instagram__seguidores_dia.ultimo_ponto_concorda_com_a_conta', 'Trusted',
         'trs_instagram__seguidores_dia', 'Instagram', 'INTEGRIDADE',
         'o ultimo ponto de seguidores de cada conta e o seguidores de trs_instagram__conta',
         'ALERTA', 0.90, COUNT(*), COUNTIF(u.seguidores <> c.seguidores)
  FROM (SELECT id_conta, ARRAY_AGG(seguidores ORDER BY data DESC LIMIT 1)[OFFSET(0)] AS seguidores
        FROM `vanguardamartech_trusted`.`trs_instagram__seguidores_dia`
        GROUP BY id_conta) u
  JOIN `vanguardamartech_trusted`.`trs_instagram__conta` c ON c.id_conta = u.id_conta
  UNION ALL
  -- FRESCOR: as seis Trusted rodam na mesma passada (terca 14:00 America/Manaus). Uma que
  -- ficou numa carga anterior faz a leitura misturar dois momentos sem a contagem mudar.
  SELECT 'instagram.carga_do_mesmo_dia', 'Trusted', 'trs_instagram__*', 'Instagram',
         'COMPLETUDE', 'as seis Trusted de Instagram foram escritas no mesmo dia', 'ALERTA', 1.00,
         COUNT(*), COUNTIF(d <> mx)
  FROM (
    SELECT d, MAX(d) OVER () AS mx FROM (
      SELECT MAX(DATE(_extraido_at)) AS d FROM `vanguardamartech_trusted`.`trs_instagram__conta`
      UNION ALL SELECT MAX(DATE(_extraido_at)) FROM `vanguardamartech_trusted`.`trs_instagram__midia`
      UNION ALL SELECT MAX(DATE(_extraido_at)) FROM `vanguardamartech_trusted`.`trs_instagram__insight_conta`
      UNION ALL SELECT MAX(DATE(_extraido_at)) FROM `vanguardamartech_trusted`.`trs_instagram__insight_produto_dia`
      UNION ALL SELECT MAX(DATE(_extraido_at)) FROM `vanguardamartech_trusted`.`trs_instagram__audiencia_seguidor`
      UNION ALL SELECT MAX(DATE(_extraido_at)) FROM `vanguardamartech_trusted`.`trs_instagram__seguidores_dia`
    )
  )
),
-- ───────────────────────── Refined ─────────────────────────
r_cm AS (
  SELECT 'rfn_social__conta_mensal.id_conta_mes_unico', 'Refined', 'rfn_social__conta_mensal',
         'Instagram', 'UNICIDADE', 'id_conta_mes e unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_conta_mes)
  FROM `vanguardamartech_refined`.`rfn_social__conta_mensal`
  UNION ALL
  -- IDENTIDADE ENTRE CAMADAS: a Refined agrega a janela DIA e nao filtra; a soma reproduz a
  -- Trusted. 113.213 visualizacoes e 822 interacoes na validacao.
  SELECT 'rfn_social__conta_mensal.visualizacoes_reproduzem_a_trusted', 'Refined',
         'rfn_social__conta_mensal', 'Instagram', 'INTEGRIDADE',
         'a soma de visualizacoes reproduz a janela DIA de trs_instagram__insight_conta',
         'BLOQUEANTE', 1.00, 1,
         IF(IFNULL((SELECT SUM(visualizacoes) FROM `vanguardamartech_refined`.`rfn_social__conta_mensal`), 0)
            = IFNULL((SELECT SUM(visualizacoes) FROM `vanguardamartech_trusted`.`trs_instagram__insight_conta`
                      WHERE janela = 'DIA'), 0), 0, 1)
  UNION ALL
  SELECT 'rfn_social__conta_mensal.interacoes_reproduzem_a_trusted', 'Refined',
         'rfn_social__conta_mensal', 'Instagram', 'INTEGRIDADE',
         'a soma de interacoes_totais reproduz a janela DIA de trs_instagram__insight_conta',
         'BLOQUEANTE', 1.00, 1,
         IF(IFNULL((SELECT SUM(interacoes_totais) FROM `vanguardamartech_refined`.`rfn_social__conta_mensal`), 0)
            = IFNULL((SELECT SUM(interacoes_totais) FROM `vanguardamartech_trusted`.`trs_instagram__insight_conta`
                      WHERE janela = 'DIA'), 0), 0, 1)
  UNION ALL
  SELECT 'rfn_social__conta_mensal.midias_reproduzem_a_trusted', 'Refined',
         'rfn_social__conta_mensal', 'Instagram', 'INTEGRIDADE',
         'a soma de qtd_midias_extraidas reproduz as linhas de trs_instagram__midia',
         'BLOQUEANTE', 1.00, 1,
         IF(IFNULL((SELECT SUM(qtd_midias_extraidas) FROM `vanguardamartech_refined`.`rfn_social__conta_mensal`), 0)
            = (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_instagram__midia`), 0, 1)
  UNION ALL
  SELECT 'rfn_social__conta_mensal.dias_cabem_no_mes', 'Refined', 'rfn_social__conta_mensal',
         'Instagram', 'VALIDADE', 'dias com dado nunca passam dos dias do mes e a cobertura fica entre 0 e 1',
         'BLOQUEANTE', 1.00, COUNT(*),
         COUNTIF(qtd_dias_com_dado > qtd_dias_no_mes OR cobertura_dias_no_mes < 0 OR cobertura_dias_no_mes > 1)
  FROM `vanguardamartech_refined`.`rfn_social__conta_mensal`
  UNION ALL
  SELECT 'rfn_social__conta_mensal.flag_mes_parcial_concorda', 'Refined', 'rfn_social__conta_mensal',
         'Instagram', 'VALIDADE', 'flag_mes_parcial e exatamente dias com dado < dias do mes',
         'BLOQUEANTE', 1.00, COUNT(*),
         COUNTIF(flag_mes_parcial <> (qtd_dias_com_dado < qtd_dias_no_mes))
  FROM `vanguardamartech_refined`.`rfn_social__conta_mensal`
  UNION ALL
  -- Regra R7: variacao so com dois pontos; com um ponto e NULL, nunca zero.
  SELECT 'rfn_social__conta_mensal.variacao_so_com_dois_pontos', 'Refined',
         'rfn_social__conta_mensal', 'Instagram', 'VALIDADE',
         'variacao_de_seguidores_no_mes existe se e somente se ha 2 ou mais pontos',
         'BLOQUEANTE', 1.00, COUNT(*),
         COUNTIF((variacao_de_seguidores_no_mes IS NOT NULL) <> (qtd_pontos_de_seguidores_no_mes >= 2))
  FROM `vanguardamartech_refined`.`rfn_social__conta_mensal`
),
r_mm AS (
  SELECT 'rfn_social__midia_mensal.id_midia_mensal_unico', 'Refined', 'rfn_social__midia_mensal',
         'Instagram', 'UNICIDADE', 'id_midia_mensal e unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_midia_mensal)
  FROM `vanguardamartech_refined`.`rfn_social__midia_mensal`
  UNION ALL
  SELECT 'rfn_social__midia_mensal.midias_reproduzem_a_trusted', 'Refined',
         'rfn_social__midia_mensal', 'Instagram', 'INTEGRIDADE',
         'a soma de qtd_midias reproduz as linhas de trs_instagram__midia', 'BLOQUEANTE', 1.00, 1,
         IF(IFNULL((SELECT SUM(qtd_midias) FROM `vanguardamartech_refined`.`rfn_social__midia_mensal`), 0)
            = (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_instagram__midia`), 0, 1)
  UNION ALL
  SELECT 'rfn_social__midia_mensal.visualizacoes_reproduzem_a_trusted', 'Refined',
         'rfn_social__midia_mensal', 'Instagram', 'INTEGRIDADE',
         'a soma de visualizacoes reproduz trs_instagram__midia', 'BLOQUEANTE', 1.00, 1,
         IF(IFNULL((SELECT SUM(visualizacoes) FROM `vanguardamartech_refined`.`rfn_social__midia_mensal`), 0)
            = IFNULL((SELECT SUM(visualizacoes) FROM `vanguardamartech_trusted`.`trs_instagram__midia`), 0), 0, 1)
  UNION ALL
  -- R3 atravessando a camada: curtida de story continua NULL na Refined.
  SELECT 'rfn_social__midia_mensal.story_sem_curtida', 'Refined', 'rfn_social__midia_mensal',
         'Instagram', 'VALIDADE', 'linhas STORY tem curtidas e comentarios NULL', 'BLOQUEANTE', 1.00,
         COUNTIF(produto = 'STORY'),
         COUNTIF(produto = 'STORY' AND (curtidas IS NOT NULL OR comentarios IS NOT NULL))
  FROM `vanguardamartech_refined`.`rfn_social__midia_mensal`
  UNION ALL
  SELECT 'rfn_social__midia_mensal.com_insight_nao_passa_do_total', 'Refined',
         'rfn_social__midia_mensal', 'Instagram', 'VALIDADE',
         'midias com insight nunca passam das midias do grupo', 'BLOQUEANTE', 1.00, COUNT(*),
         COUNTIF(qtd_midias_com_insight > qtd_midias OR qtd_midias <= 0)
  FROM `vanguardamartech_refined`.`rfn_social__midia_mensal`
),
r_pm AS (
  SELECT 'rfn_social__produto_mensal.id_produto_mensal_unico', 'Refined',
         'rfn_social__produto_mensal', 'Instagram', 'UNICIDADE', 'id_produto_mensal e unico',
         'BLOQUEANTE', 1.00, COUNT(*), COUNT(*) - COUNT(DISTINCT id_produto_mensal)
  FROM `vanguardamartech_refined`.`rfn_social__produto_mensal`
  UNION ALL
  SELECT 'rfn_social__produto_mensal.visualizacoes_reproduzem_a_trusted', 'Refined',
         'rfn_social__produto_mensal', 'Instagram', 'INTEGRIDADE',
         'a soma de visualizacoes reproduz trs_instagram__insight_produto_dia', 'BLOQUEANTE', 1.00, 1,
         IF(IFNULL((SELECT SUM(visualizacoes) FROM `vanguardamartech_refined`.`rfn_social__produto_mensal`), 0)
            = IFNULL((SELECT SUM(visualizacoes) FROM `vanguardamartech_trusted`.`trs_instagram__insight_produto_dia`), 0), 0, 1)
  UNION ALL
  -- Grao (conta, mes): as participacoes somam 1 (tolerancia 0,001 pelo ROUND em 4 casas).
  SELECT 'rfn_social__produto_mensal.participacao_soma_um', 'Refined',
         'rfn_social__produto_mensal', 'Instagram', 'VALIDADE',
         'as participacoes nas visualizacoes somam 1 por conta e mes', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(ABS(s - 1) > 0.001)
  FROM (SELECT id_conta, mes_referencia, SUM(participacao_nas_visualizacoes_da_conta) AS s
        FROM `vanguardamartech_refined`.`rfn_social__produto_mensal`
        WHERE visualizacoes_da_conta_no_mes > 0
        GROUP BY id_conta, mes_referencia)
  UNION ALL
  -- IDENTIDADE ENTRE REFINED: a soma por produto de uma conta-mes e as visualizacoes da
  -- conta-mes em rfn_social__conta_mensal. Medido 12 de 12.
  SELECT 'rfn_social__produto_mensal.visualizacoes_batem_a_conta_mensal', 'Refined',
         'rfn_social__produto_mensal', 'Instagram', 'INTEGRIDADE',
         'visualizacoes somadas por produto = visualizacoes de rfn_social__conta_mensal (tolerancia relativa de 0,5%)',
         'BLOQUEANTE', 1.00, COUNT(*), COUNTIF(ABS(p.v - c.visualizacoes) > 0.005 * GREATEST(c.visualizacoes, 1))
  FROM (SELECT id_conta, mes_referencia, SUM(visualizacoes) AS v
        FROM `vanguardamartech_refined`.`rfn_social__produto_mensal`
        GROUP BY id_conta, mes_referencia) p
  JOIN `vanguardamartech_refined`.`rfn_social__conta_mensal` c
    ON c.id_conta = p.id_conta AND c.mes_referencia = p.mes_referencia
),
r_ac AS (
  SELECT 'rfn_social__audiencia_conta.id_audiencia_conta_unico', 'Refined',
         'rfn_social__audiencia_conta', 'Instagram', 'UNICIDADE', 'id_audiencia_conta e unico',
         'BLOQUEANTE', 1.00, COUNT(*), COUNT(*) - COUNT(DISTINCT id_audiencia_conta)
  FROM `vanguardamartech_refined`.`rfn_social__audiencia_conta`
  UNION ALL
  SELECT 'rfn_social__audiencia_conta.linhas_reproduzem_a_trusted', 'Refined',
         'rfn_social__audiencia_conta', 'Instagram', 'INTEGRIDADE',
         'o numero de linhas reproduz trs_instagram__audiencia_seguidor', 'BLOQUEANTE', 1.00, 1,
         IF((SELECT COUNT(*) FROM `vanguardamartech_refined`.`rfn_social__audiencia_conta`)
            = (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_instagram__audiencia_seguidor`), 0, 1)
  UNION ALL
  -- Grao (conta, dimensao): a participacao dentro da dimensao soma 1. Tolerancia 0,003:
  -- ate 45 valores arredondados em 4 casas (45 x 0,00005 = 0,00225).
  SELECT 'rfn_social__audiencia_conta.participacao_soma_um_por_dimensao', 'Refined',
         'rfn_social__audiencia_conta', 'Instagram', 'VALIDADE',
         'a participacao dentro da dimensao soma 1 por conta e dimensao', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(ABS(s - 1) > 0.003)
  FROM (SELECT id_conta, dimensao, SUM(participacao_na_dimensao) AS s
        FROM `vanguardamartech_refined`.`rfn_social__audiencia_conta`
        WHERE soma_da_dimensao > 0
        GROUP BY id_conta, dimensao)
  UNION ALL
  SELECT 'rfn_social__audiencia_conta.participacoes_entre_zero_e_um', 'Refined',
         'rfn_social__audiencia_conta', 'Instagram', 'VALIDADE',
         'participacao_na_dimensao e participacao_nos_seguidores ficam entre 0 e 1', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(participacao_na_dimensao < 0 OR participacao_na_dimensao > 1
                 OR participacao_nos_seguidores < 0 OR participacao_nos_seguidores > 1)
  FROM `vanguardamartech_refined`.`rfn_social__audiencia_conta`
),
r_ce AS (
  SELECT 'rfn_social__cobertura_extracao.id_conta_unico', 'Refined',
         'rfn_social__cobertura_extracao', 'Instagram', 'UNICIDADE', 'id_conta e unico',
         'BLOQUEANTE', 1.00, COUNT(*), COUNT(*) - COUNT(DISTINCT id_conta)
  FROM `vanguardamartech_refined`.`rfn_social__cobertura_extracao`
  UNION ALL
  SELECT 'rfn_social__cobertura_extracao.uma_linha_por_conta', 'Refined',
         'rfn_social__cobertura_extracao', 'Instagram', 'INTEGRIDADE',
         'ha exatamente uma linha por conta de trs_instagram__conta', 'BLOQUEANTE', 1.00, 1,
         IF((SELECT COUNT(*) FROM `vanguardamartech_refined`.`rfn_social__cobertura_extracao`)
            = (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_instagram__conta`), 0, 1)
  UNION ALL
  SELECT 'rfn_social__cobertura_extracao.extraidas_reproduzem_a_trusted', 'Refined',
         'rfn_social__cobertura_extracao', 'Instagram', 'INTEGRIDADE',
         'a soma de qtd_midias_extraidas reproduz as linhas de trs_instagram__midia',
         'BLOQUEANTE', 1.00, 1,
         IF(IFNULL((SELECT SUM(qtd_midias_extraidas) FROM `vanguardamartech_refined`.`rfn_social__cobertura_extracao`), 0)
            = (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_instagram__midia`), 0, 1)
  UNION ALL
  SELECT 'rfn_social__cobertura_extracao.feed_reels_mais_stories_decompoe', 'Refined',
         'rfn_social__cobertura_extracao', 'Instagram', 'VALIDADE',
         'feed_reels + stories = midias extraidas', 'BLOQUEANTE', 1.00, COUNT(*),
         COUNTIF(qtd_feed_reels_extraidos + qtd_stories_extraidos <> qtd_midias_extraidas)
  FROM `vanguardamartech_refined`.`rfn_social__cobertura_extracao`
  UNION ALL
  -- LINHA DE BASE: media_count e o total historico. Se a extracao passar dele, media_count
  -- nao e o total (ou conta com story contado la) e a razao deixa de ser cobertura.
  SELECT 'rfn_social__cobertura_extracao.razao_nao_passa_de_um', 'Refined',
         'rfn_social__cobertura_extracao', 'Instagram', 'VALIDADE',
         'FEED+REELS extraidos nunca passam de media_count', 'ALERTA', 1.00,
         COUNTIF(razao_feed_reels_extraidos_sobre_historico IS NOT NULL),
         COUNTIF(razao_feed_reels_extraidos_sobre_historico > 1)
  FROM `vanguardamartech_refined`.`rfn_social__cobertura_extracao`
),

todas AS (
  SELECT * FROM r_conta
  UNION ALL SELECT * FROM r_midia
  UNION ALL SELECT * FROM r_ic
  UNION ALL SELECT * FROM r_ip
  UNION ALL SELECT * FROM r_aud
  UNION ALL SELECT * FROM r_seg
  UNION ALL SELECT * FROM r_cm
  UNION ALL SELECT * FROM r_mm
  UNION ALL SELECT * FROM r_pm
  UNION ALL SELECT * FROM r_ac
  UNION ALL SELECT * FROM r_ce
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
  'Instagram'                                   AS familia,
  CURRENT_TIMESTAMP()                           AS _extraido_at,
  'instagram-*'                                 AS _fonte,
  'America/Sao_Paulo'                           AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(a)))                AS _payload_hash
FROM avaliado a
