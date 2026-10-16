-- rfn_qualidade__regra_midia  ·  query-4tgF  ·  43 regras  ·  L2 INTERNAL
-- Refined / qualidade. Grao: uma REGRA de qualidade em uma execucao. Chave: id_regra
-- (a execucao se le em _extraido_at). Gatilho: evento em query-SGbQ, ultimo elo da
-- cadeia do Google Ads. Alerta ligado. Cadencia SEMANAL (a `google-ads-cwt3` roda terca).
--
-- POR QUE ESTA SUITE EXISTE
--   Mídia e o negocio principal da casa e tinha **4,4 milhoes de linhas tratadas sem uma
--   unica regra**: conta 88 · campanha 827 · termo de busca 3.096.346 · faixa etaria
--   296.566 · genero 143.895 · geografico 74.245 · localizacao 827.446 · campanha do
--   Facebook 1.233. A suite principal so cobria as duas de insight diario.
--   Suite propria, e nao acrescimo a principal, pelo mesmo motivo da do Gmail: a
--   `rfn_qualidade__regra` esta com 57 KB e 84 regras e `update_transformation` troca o
--   codigo inteiro. Contrato de colunas IDENTICO nas outras oito -- `familia` diz de onde veio.
--
-- A REGRA QUE IMPORTA MAIS E UMA DESIGUALDADE — a primeira desta casa.
--   Cada breakdown do Google Ads e um recorte do MESMO investimento da campanha, entao a
--   soma dele por (campanha, dia) **nunca pode passar** do total de
--   `trs_google_ads__insight_diario`. Se passar, o grao duplicou — e nada na contagem de
--   linhas denuncia, exatamente como no grao misto ANUNCIO/CAMPANHA.
--   Medido em 2026-09-29: termo, idade, genero e geografico **zero excessos**;
--   localizacao excede em **7 de 42.449 pares (0,016%)**, somando **R$ 3,43** — o maior
--   excesso e de R$ 0,79 sobre R$ 54,06. Os 7 sao de janeiro/2025, 4 campanhas, e todos
--   tem os dois valores de `local_e_alvo`: **e arredondamento do proprio Google na
--   atribuicao por localizacao, nao duplicacao de grao**. Por isso essa unica regra tem
--   limiar 0,999 e severidade ALERTA — linha de base para detectar PIORA, como o 0,78 da
--   origem do PI. As outras quatro sao BLOQUEANTE com limiar 1,00.
--
-- ARMADILHA DE TIPO, REGISTRADA NO CODIGO: `id_campanha` e INT64 na dimensao e STRING
--   nos breakdowns. Todo join aqui CASTA para STRING dos dois lados; sem isso o BigQuery
--   recusa a comparacao — o que e melhor do que casar errado em silencio.
--
-- ARMADILHA DE CAMADA: a consolidada do Facebook e `vanguardamartech_trusted_facebook_ads`,
--   NAO `vanguardamartech_trusted`. Existem onze tabelas com o mesmo nome, uma por camada
--   de cliente — apontar para a errada devolve um cliente so e parece a base inteira.
--
-- AS 43 REGRAS, MEDIDAS SOBRE AS TABELAS MATERIALIZADAS, ANTES DE PUBLICAR.
-- Resultado esperado: 43 CONFORMES, ZERO FALHAS.
--   GOOGLE ADS — conta (2) 88/88 e cliente 0 falhas · campanha (2) 827/827 e conta
--     catalogada 0 orfas · termo de busca (3) · quatro breakdowns (8) · desigualdade (5).
--   FACEBOOK (3) — campanha 1.233/1.233 · conta preenchida 0 · insight com campanha
--     catalogada **2.157 de 142.305 orfas (98,48%)**, limiar 0,98.
--   GEO E AS DUAS GOLD (19) — ver o bloco de 30/09 abaixo.
--
-- POR QUE A ORFANDADE DO FACEBOOK E LINHA DE BASE, E NAO DEFEITO: as 18 campanhas orfas
--   param em **27/03/2026** enquanto as 1.156 saudaveis vao ate hoje. A dimensao e uma
--   FOTOGRAFIA e o fato e HISTORICO — campanha apagada da conta some da dimensao e o
--   insight dela sobrevive. Mesmo mecanismo do gestor deletado no VJOB. Limiar apertado
--   ali so ensinaria a ignorar a suite.
--
-- 30/09 — AS TRES TABELAS QUE FALTAVAM ENTRARAM, E A DIVIDA DECLARADA FOI PAGA.
--   `trs_google_ads__geo_alvo` (270.938), `rfn_midia__localizacao_mensal` (161.613) e
--   `rfn_midia__segmento_mensal` (7.886) materializaram em 29/09 e ganharam 19 regras.
--   A suite vai de 24 para 43. Todas as 19 medidas na tabela materializada antes de
--   publicar, ZERO falhas.
--
-- TRES IDENTIDADES NOVAS, e a terceira e a que guarda a armadilha mais cara desta familia.
--   1. `localizacao_mensal.particao_do_alvo_fecha` — era a candidata declarada com data.
--      `investimento_em_local_alvo + investimento_fora_do_alvo = investimento`, linha a
--      linha. Medido: R$ 1.192.985,77 + R$ 249.564,26 = R$ 1.442.550,03, ZERO quebras em
--      161.613 linhas. `local_e_alvo` PARTICIONA — ao contrario de `tipo_localizacao`, que
--      DUPLICA (presenca mais interesse dao mais que a verba real). Se a particao soltar,
--      a verba por localizacao passa a contar duas vezes e a contagem de linhas nao muda.
--   2. `localizacao_mensal.participacao_soma_um_na_conta_mes` — GRAO = GRUPO (conta, mes),
--      nao linha. 568 grupos, ZERO fora de 1%, desvio maximo 0,0001 (arredondamento).
--      Prova que as localizacoes de uma conta-mes cobrem a conta inteira, sem buraco nem
--      sobreposicao.
--   3. `segmento_mensal.participacao_soma_um_por_tipo` — GRAO = GRUPO (conta, mes, TIPO),
--      e o TIPO no grao E O PONTO INTEIRO. A descricao daquela tabela declara que
--      `tipo_segmento` e FILTRO e nunca group by: a mesma verba aparece em idade, genero e
--      pais, entao somar os quatro tipos da ~4x o investimento real. Esta regra prova que
--      DENTRO de cada tipo a particao e completa — 2.173 grupos, ZERO fora, desvio maximo
--      ZERO EXATO — e e justamente por ser completa dentro de cada um que somar entre eles
--      multiplica. A regra guarda a premissa e explica a armadilha ao mesmo tempo.
--
-- A GUARDA DAS TRES COPIAS. `geo_alvo` e lida de TRES camadas de conta e comparada; a
--   Trusted emite `flag_copias_divergem` (hoje FALSE em 270.938 de 270.938) e
--   `qtd_copias_lidas` (hoje 3 em todas). A segunda virou regra porque e ela que detecta o
--   caso silencioso: se uma fonte cair, a Trusted le 2 copias, a comparacao perde forca e
--   NADA na contagem de linhas muda. E exatamente o que aconteceu com
--   `github_repositories`, que foi de 10 linhas para ZERO enquanto os fatos continuaram la.
--
-- DUAS LINHAS DE BASE NOVAS, as duas de clique maior que impressao, as duas ALERTA:
--   localizacao **273 de 161.613 (0,17%)**, limiar 0,998; segmento **3 de 7.886**, limiar
--   0,999. O numero vem da plataforma e esta camada NAO o recalcula. A taxa da localizacao
--   e ~34x a do desempenho diario (4 de 86.267) porque o Google atribui clique e impressao
--   a localizacao por regras diferentes — e por isso os limiares sao distintos, medidos um
--   a um, e nao um limiar unico aplicado por simetria.
--
-- CLASSIFICACAO: L2 INTERNAL. So contagem e taxa — nenhum termo digitado, nenhum rotulo.
WITH total_campanha_dia AS (
  SELECT CAST(id_campanha AS STRING) AS id_campanha, data,
         SUM(investimento_micros)                             AS micros
  FROM `vanguardamartech_trusted`.`trs_google_ads__insight_diario`
  GROUP BY 1, 2
),
campanhas AS (
  SELECT DISTINCT CAST(id_campanha AS STRING)                 AS id_campanha
  FROM `vanguardamartech_trusted`.`trs_google_ads__campanha`
),
r_conta AS (
  SELECT 'trs_google_ads__conta.id_conta_unico'               AS id_regra,
         'Trusted'                                            AS camada,
         'trs_google_ads__conta'                              AS tabela,
         'Google Ads'                                         AS sistema,
         'UNICIDADE'                                          AS dimensao,
         'id_conta e unico'                                   AS regra,
         'BLOQUEANTE'                                         AS severidade,
         1.00                                                 AS limiar,
         COUNT(*)                                             AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_conta)                  AS linhas_falha
  FROM `vanguardamartech_trusted`.`trs_google_ads__conta`
  UNION ALL
  SELECT 'trs_google_ads__conta.cliente_preenchido', 'Trusted', 'trs_google_ads__conta',
         'Google Ads', 'COMPLETUDE', 'toda conta tem cliente resolvido', 'ALERTA', 1.00,
         COUNT(*), COUNTIF(cliente IS NULL)
  FROM `vanguardamartech_trusted`.`trs_google_ads__conta`
),
r_campanha AS (
  -- A chave e (conta, campanha), nao a campanha sozinha.
  SELECT 'trs_google_ads__campanha.chave_conta_campanha', 'Trusted', 'trs_google_ads__campanha',
         'Google Ads', 'UNICIDADE', 'o par (id_conta, id_campanha) e unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT FORMAT('%s|%d', id_conta, id_campanha))
  FROM `vanguardamartech_trusted`.`trs_google_ads__campanha`
  UNION ALL
  SELECT 'trs_google_ads__campanha.conta_catalogada', 'Trusted', 'trs_google_ads__campanha',
         'Google Ads', 'INTEGRIDADE', 'toda campanha aponta para conta catalogada', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(flag_conta_nao_catalogada)
  FROM `vanguardamartech_trusted`.`trs_google_ads__campanha`
),
r_valor AS (
  SELECT 'trs_google_ads__termo_busca.investimento_nao_negativo', 'Trusted',
         'trs_google_ads__termo_busca', 'Google Ads', 'VALIDADE',
         'investimento nunca negativo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(investimento_micros < 0)
  FROM `vanguardamartech_trusted`.`trs_google_ads__termo_busca`
  UNION ALL
  SELECT 'trs_google_ads__termo_busca.data_nao_futura', 'Trusted',
         'trs_google_ads__termo_busca', 'Google Ads', 'VALIDADE',
         'nenhuma linha com data futura', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(data > CURRENT_DATE('America/Sao_Paulo'))
  FROM `vanguardamartech_trusted`.`trs_google_ads__termo_busca`
  UNION ALL
  SELECT 'trs_google_ads__segmento_faixa_etaria.investimento_nao_negativo', 'Trusted',
         'trs_google_ads__segmento_faixa_etaria', 'Google Ads', 'VALIDADE',
         'investimento nunca negativo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(investimento_micros < 0)
  FROM `vanguardamartech_trusted`.`trs_google_ads__segmento_faixa_etaria`
  UNION ALL
  SELECT 'trs_google_ads__segmento_genero.investimento_nao_negativo', 'Trusted',
         'trs_google_ads__segmento_genero', 'Google Ads', 'VALIDADE',
         'investimento nunca negativo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(investimento_micros < 0)
  FROM `vanguardamartech_trusted`.`trs_google_ads__segmento_genero`
  UNION ALL
  SELECT 'trs_google_ads__segmento_geografico.investimento_nao_negativo', 'Trusted',
         'trs_google_ads__segmento_geografico', 'Google Ads', 'VALIDADE',
         'investimento nunca negativo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(investimento_micros < 0)
  FROM `vanguardamartech_trusted`.`trs_google_ads__segmento_geografico`
  UNION ALL
  SELECT 'trs_google_ads__segmento_localizacao_usuario.investimento_nao_negativo', 'Trusted',
         'trs_google_ads__segmento_localizacao_usuario', 'Google Ads', 'VALIDADE',
         'investimento nunca negativo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(investimento_micros < 0)
  FROM `vanguardamartech_trusted`.`trs_google_ads__segmento_localizacao_usuario`
  UNION ALL
  SELECT 'trs_google_ads__segmento_localizacao_usuario.data_nao_futura', 'Trusted',
         'trs_google_ads__segmento_localizacao_usuario', 'Google Ads', 'VALIDADE',
         'nenhuma linha com data futura', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(data > CURRENT_DATE('America/Sao_Paulo'))
  FROM `vanguardamartech_trusted`.`trs_google_ads__segmento_localizacao_usuario`
),
-- ANTI-JOIN com DISTINCT no lado direito, nunca `NOT EXISTS` correlacionado -- esta base
-- ja registrou que o correlacionado nao roda no BigQuery quando a uniao cresce.
r_fk AS (
  SELECT 'trs_google_ads__termo_busca.campanha_catalogada', 'Trusted',
         'trs_google_ads__termo_busca', 'Google Ads', 'INTEGRIDADE',
         'toda linha aponta para campanha catalogada', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(c.id_campanha IS NULL)
  FROM `vanguardamartech_trusted`.`trs_google_ads__termo_busca` t
  LEFT JOIN campanhas c ON c.id_campanha = CAST(t.id_campanha AS STRING)
  UNION ALL
  SELECT 'trs_google_ads__segmento_faixa_etaria.campanha_catalogada', 'Trusted',
         'trs_google_ads__segmento_faixa_etaria', 'Google Ads', 'INTEGRIDADE',
         'toda linha aponta para campanha catalogada', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(c.id_campanha IS NULL)
  FROM `vanguardamartech_trusted`.`trs_google_ads__segmento_faixa_etaria` t
  LEFT JOIN campanhas c ON c.id_campanha = CAST(t.id_campanha AS STRING)
  UNION ALL
  SELECT 'trs_google_ads__segmento_genero.campanha_catalogada', 'Trusted',
         'trs_google_ads__segmento_genero', 'Google Ads', 'INTEGRIDADE',
         'toda linha aponta para campanha catalogada', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(c.id_campanha IS NULL)
  FROM `vanguardamartech_trusted`.`trs_google_ads__segmento_genero` t
  LEFT JOIN campanhas c ON c.id_campanha = CAST(t.id_campanha AS STRING)
  UNION ALL
  SELECT 'trs_google_ads__segmento_geografico.campanha_catalogada', 'Trusted',
         'trs_google_ads__segmento_geografico', 'Google Ads', 'INTEGRIDADE',
         'toda linha aponta para campanha catalogada', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(c.id_campanha IS NULL)
  FROM `vanguardamartech_trusted`.`trs_google_ads__segmento_geografico` t
  LEFT JOIN campanhas c ON c.id_campanha = CAST(t.id_campanha AS STRING)
  UNION ALL
  SELECT 'trs_google_ads__segmento_localizacao_usuario.campanha_catalogada', 'Trusted',
         'trs_google_ads__segmento_localizacao_usuario', 'Google Ads', 'INTEGRIDADE',
         'toda linha aponta para campanha catalogada', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(c.id_campanha IS NULL)
  FROM `vanguardamartech_trusted`.`trs_google_ads__segmento_localizacao_usuario` t
  LEFT JOIN campanhas c ON c.id_campanha = CAST(t.id_campanha AS STRING)
),
-- A DESIGUALDADE. Grao: (campanha, dia). Ver o cabecalho.
r_desigualdade AS (
  SELECT 'trs_google_ads__termo_busca.nao_excede_o_total', 'Trusted',
         'trs_google_ads__termo_busca', 'Google Ads', 'VALIDADE',
         'a soma por (campanha, dia) nao excede o investimento da campanha', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(b.micros > t.micros)
  FROM (SELECT CAST(id_campanha AS STRING) AS id_campanha, data, SUM(investimento_micros) AS micros
        FROM `vanguardamartech_trusted`.`trs_google_ads__termo_busca` GROUP BY 1,2) b
  JOIN total_campanha_dia t USING (id_campanha, data)
  UNION ALL
  SELECT 'trs_google_ads__segmento_faixa_etaria.nao_excede_o_total', 'Trusted',
         'trs_google_ads__segmento_faixa_etaria', 'Google Ads', 'VALIDADE',
         'a soma por (campanha, dia) nao excede o investimento da campanha', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(b.micros > t.micros)
  FROM (SELECT CAST(id_campanha AS STRING) AS id_campanha, data, SUM(investimento_micros) AS micros
        FROM `vanguardamartech_trusted`.`trs_google_ads__segmento_faixa_etaria` GROUP BY 1,2) b
  JOIN total_campanha_dia t USING (id_campanha, data)
  UNION ALL
  SELECT 'trs_google_ads__segmento_genero.nao_excede_o_total', 'Trusted',
         'trs_google_ads__segmento_genero', 'Google Ads', 'VALIDADE',
         'a soma por (campanha, dia) nao excede o investimento da campanha', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(b.micros > t.micros)
  FROM (SELECT CAST(id_campanha AS STRING) AS id_campanha, data, SUM(investimento_micros) AS micros
        FROM `vanguardamartech_trusted`.`trs_google_ads__segmento_genero` GROUP BY 1,2) b
  JOIN total_campanha_dia t USING (id_campanha, data)
  UNION ALL
  SELECT 'trs_google_ads__segmento_geografico.nao_excede_o_total', 'Trusted',
         'trs_google_ads__segmento_geografico', 'Google Ads', 'VALIDADE',
         'a soma por (campanha, dia) nao excede o investimento da campanha', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(b.micros > t.micros)
  FROM (SELECT CAST(id_campanha AS STRING) AS id_campanha, data, SUM(investimento_micros) AS micros
        FROM `vanguardamartech_trusted`.`trs_google_ads__segmento_geografico` GROUP BY 1,2) b
  JOIN total_campanha_dia t USING (id_campanha, data)
  UNION ALL
  -- LINHA DE BASE: 7 de 42.449 pares excedem, somando R$ 3,43, todos de janeiro/2025 e
  -- todos com os dois valores de `local_e_alvo`. E arredondamento do Google na atribuicao
  -- por localizacao, nao duplicacao de grao. Limiar 0,999 para detectar PIORA.
  SELECT 'trs_google_ads__segmento_localizacao_usuario.nao_excede_o_total', 'Trusted',
         'trs_google_ads__segmento_localizacao_usuario', 'Google Ads', 'VALIDADE',
         'a soma por (campanha, dia) nao excede o investimento da campanha', 'ALERTA', 0.999,
         COUNT(*), COUNTIF(b.micros > t.micros)
  FROM (SELECT CAST(id_campanha AS STRING) AS id_campanha, data, SUM(investimento_micros) AS micros
        FROM `vanguardamartech_trusted`.`trs_google_ads__segmento_localizacao_usuario` GROUP BY 1,2) b
  JOIN total_campanha_dia t USING (id_campanha, data)
),
-- ARMADILHA DE CAMADA: `vanguardamartech_trusted_facebook_ads`, nao `vanguardamartech_trusted`.
r_facebook AS (
  SELECT 'trs_facebook_ads__campanha.id_campanha_unico', 'Trusted',
         'trs_facebook_ads__campanha', 'Facebook Ads', 'UNICIDADE',
         'id_campanha e unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_campanha)
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__campanha`
  UNION ALL
  SELECT 'trs_facebook_ads__campanha.conta_preenchida', 'Trusted',
         'trs_facebook_ads__campanha', 'Facebook Ads', 'COMPLETUDE',
         'toda campanha tem conta e objetivo canonico', 'ALERTA', 1.00,
         COUNT(*), COUNTIF(id_conta IS NULL OR objetivo_canonico IS NULL)
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__campanha`
  UNION ALL
  -- LINHA DE BASE: 2.157 de 142.305 (1,5%). As 18 campanhas orfas param em 27/03/2026 e
  -- as 1.156 saudaveis vao ate hoje -- a dimensao e FOTOGRAFIA, o fato e HISTORICO.
  SELECT 'trs_facebook_ads__insight_diario.campanha_catalogada', 'Trusted',
         'trs_facebook_ads__insight_diario', 'Facebook Ads', 'INTEGRIDADE',
         'o insight aponta para campanha que existe na dimensao', 'ALERTA', 0.98,
         COUNT(*), COUNTIF(c.k IS NULL)
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__insight_diario` i
  LEFT JOIN (SELECT DISTINCT CAST(id_campanha AS STRING) AS k
             FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__campanha`) c
         ON c.k = CAST(i.id_campanha AS STRING)
),
-- ─────────────────── trs_google_ads__geo_alvo (6) — a dimensao geografica ────────────
-- Ela existe em TODA camada de conta, identica: a Trusted le TRES copias e compara.
-- `flag_copias_divergem` e a guarda disso, e `qtd_copias_lidas` prova que as tres foram
-- lidas -- se cair para 1 ou 2, uma fonte parou e a comparacao deixou de valer sem que a
-- contagem de linhas mude. E o mesmo mecanismo que esvaziou `github_repositories`.
r_geo AS (
  SELECT 'trs_google_ads__geo_alvo.id_alvo_geo_unico', 'Trusted',
         'trs_google_ads__geo_alvo', 'Google Ads', 'UNICIDADE',
         'id_alvo_geo e unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_alvo_geo)
  FROM `vanguardamartech_trusted`.`trs_google_ads__geo_alvo`
  UNION ALL
  SELECT 'trs_google_ads__geo_alvo.copias_nunca_divergem', 'Trusted',
         'trs_google_ads__geo_alvo', 'Google Ads', 'INTEGRIDADE',
         'as copias por camada nunca divergem entre si', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(flag_copias_divergem)
  FROM `vanguardamartech_trusted`.`trs_google_ads__geo_alvo`
  UNION ALL
  SELECT 'trs_google_ads__geo_alvo.tres_copias_lidas', 'Trusted',
         'trs_google_ads__geo_alvo', 'Google Ads', 'INTEGRIDADE',
         'as tres copias foram lidas -- se cair, a comparacao deixou de valer',
         'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(qtd_copias_lidas <> 3)
  FROM `vanguardamartech_trusted`.`trs_google_ads__geo_alvo`
  UNION ALL
  SELECT 'trs_google_ads__geo_alvo.nome_preenchido', 'Trusted',
         'trs_google_ads__geo_alvo', 'Google Ads', 'COMPLETUDE',
         'todo alvo geografico tem nome', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(NULLIF(TRIM(nome), '') IS NULL)
  FROM `vanguardamartech_trusted`.`trs_google_ads__geo_alvo`
  UNION ALL
  SELECT 'trs_google_ads__geo_alvo.flag_e_pais_decompoe', 'Trusted',
         'trs_google_ads__geo_alvo', 'Google Ads', 'VALIDADE',
         'flag_e_pais e exatamente tipo_alvo igual a Country', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(flag_e_pais <> (tipo_alvo = 'Country'))
  FROM `vanguardamartech_trusted`.`trs_google_ads__geo_alvo`
  UNION ALL
  SELECT 'trs_google_ads__geo_alvo.codigo_pais_tem_duas_letras', 'Trusted',
         'trs_google_ads__geo_alvo', 'Google Ads', 'VALIDADE',
         'o codigo de pais tem exatamente duas letras', 'BLOQUEANTE', 1.00,
         COUNTIF(NULLIF(TRIM(codigo_pais), '') IS NOT NULL),
         COUNTIF(NULLIF(TRIM(codigo_pais), '') IS NOT NULL AND LENGTH(TRIM(codigo_pais)) <> 2)
  FROM `vanguardamartech_trusted`.`trs_google_ads__geo_alvo`
),

-- ─────────────── rfn_midia__localizacao_mensal (7) — DUAS identidades ────────────────
r_localizacao AS (
  SELECT 'rfn_midia__localizacao_mensal.id_localizacao_mensal_unico', 'Refined',
         'rfn_midia__localizacao_mensal', 'Google Ads', 'UNICIDADE',
         'id_localizacao_mensal e unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_localizacao_mensal)
  FROM `vanguardamartech_refined`.`rfn_midia__localizacao_mensal`

  UNION ALL
  -- A IDENTIDADE DECLARADA COM DATA. Ver o bloco no cabecalho.
  SELECT 'rfn_midia__localizacao_mensal.particao_do_alvo_fecha', 'Refined',
         'rfn_midia__localizacao_mensal', 'Google Ads', 'VALIDADE',
         'dentro do alvo mais fora do alvo reproduz o investimento', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(ABS(IFNULL(investimento_em_local_alvo, 0)
                     + IFNULL(investimento_fora_do_alvo, 0)
                     - IFNULL(investimento, 0)) > 0.005)
  FROM `vanguardamartech_refined`.`rfn_midia__localizacao_mensal`

  UNION ALL
  -- A SEGUNDA IDENTIDADE, e o GRAO AQUI E O GRUPO (conta, mes), nao a linha.
  SELECT 'rfn_midia__localizacao_mensal.participacao_soma_um_na_conta_mes', 'Refined',
         'rfn_midia__localizacao_mensal', 'Google Ads', 'VALIDADE',
         'a participacao das localizacoes soma 1 em cada conta e mes', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(ABS(soma - 1) > 0.01)
  FROM (SELECT id_conta, mes_referencia,
               SUM(participacao_investimento_na_conta_mes) AS soma
        FROM `vanguardamartech_refined`.`rfn_midia__localizacao_mensal`
        GROUP BY 1, 2)

  UNION ALL
  SELECT 'rfn_midia__localizacao_mensal.participacao_do_alvo_reproduz_a_razao', 'Refined',
         'rfn_midia__localizacao_mensal', 'Google Ads', 'VALIDADE',
         'participacao_local_alvo vezes investimento reproduz o investimento no alvo',
         'BLOQUEANTE', 1.00,
         COUNTIF(investimento > 0),
         COUNTIF(investimento > 0
                 AND ABS(IFNULL(participacao_local_alvo, 0) * investimento
                         - investimento_em_local_alvo) > 0.01)
  FROM `vanguardamartech_refined`.`rfn_midia__localizacao_mensal`

  UNION ALL
  SELECT 'rfn_midia__localizacao_mensal.mes_referencia_e_o_primeiro_dia', 'Refined',
         'rfn_midia__localizacao_mensal', 'Google Ads', 'VALIDADE',
         'mes_referencia e o primeiro dia do mes', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(mes_referencia <> DATE_TRUNC(mes_referencia, MONTH))
  FROM `vanguardamartech_refined`.`rfn_midia__localizacao_mensal`

  UNION ALL
  SELECT 'rfn_midia__localizacao_mensal.metrica_nao_negativa', 'Refined',
         'rfn_midia__localizacao_mensal', 'Google Ads', 'VALIDADE',
         'investimento, impressao, clique e conversao nunca sao negativos',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(investimento < 0 OR impressoes < 0 OR cliques < 0 OR conversoes < 0)
  FROM `vanguardamartech_refined`.`rfn_midia__localizacao_mensal`

  UNION ALL
  -- LINHA DE BASE 0,998 -- 273 de 161.613 (0,17%). O numero vem da plataforma e esta
  -- camada NAO o recalcula; a taxa aqui e ~34x a do desempenho diario (4 de 86.267),
  -- porque o Google atribui clique e impressao a localizacao por regras diferentes.
  SELECT 'rfn_midia__localizacao_mensal.clique_nunca_excede_impressao', 'Refined',
         'rfn_midia__localizacao_mensal', 'Google Ads', 'VALIDADE',
         'o clique nunca passa da impressao', 'ALERTA', 0.998,
         COUNT(*), COUNTIF(cliques > impressoes)
  FROM `vanguardamartech_refined`.`rfn_midia__localizacao_mensal`
),

-- ──────── rfn_midia__segmento_mensal (6) — a identidade que guarda a armadilha ───────
r_segmento AS (
  SELECT 'rfn_midia__segmento_mensal.id_segmento_mensal_unico', 'Refined',
         'rfn_midia__segmento_mensal', 'Google Ads', 'UNICIDADE',
         'id_segmento_mensal e unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_segmento_mensal)
  FROM `vanguardamartech_refined`.`rfn_midia__segmento_mensal`

  UNION ALL
  -- A IDENTIDADE QUE GUARDA A ARMADILHA DO tipo_segmento. Ver o bloco no cabecalho.
  -- O GRAO E O GRUPO (conta, mes, TIPO) -- e o TIPO no grao e o ponto inteiro da regra.
  SELECT 'rfn_midia__segmento_mensal.participacao_soma_um_por_tipo', 'Refined',
         'rfn_midia__segmento_mensal', 'Google Ads', 'VALIDADE',
         'a participacao soma 1 dentro de cada conta, mes e TIPO de segmento',
         'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(ABS(soma - 1) > 0.01)
  FROM (SELECT id_conta, mes_referencia, tipo_segmento,
               SUM(participacao_investimento) AS soma
        FROM `vanguardamartech_refined`.`rfn_midia__segmento_mensal`
        GROUP BY 1, 2, 3)

  UNION ALL
  SELECT 'rfn_midia__segmento_mensal.tipo_segmento_conhecido', 'Refined',
         'rfn_midia__segmento_mensal', 'Google Ads', 'VALIDADE',
         'tipo_segmento e um dos quatro conhecidos', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(tipo_segmento IS NULL
                 OR tipo_segmento NOT IN ('FAIXA_ETARIA', 'GENERO',
                                          'PAIS_PRESENCA', 'PAIS_INTERESSE'))
  FROM `vanguardamartech_refined`.`rfn_midia__segmento_mensal`

  UNION ALL
  SELECT 'rfn_midia__segmento_mensal.flag_e_geografico_decompoe', 'Refined',
         'rfn_midia__segmento_mensal', 'Google Ads', 'VALIDADE',
         'flag_e_geografico e exatamente o tipo comecar por PAIS', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(flag_e_geografico <> STARTS_WITH(tipo_segmento, 'PAIS'))
  FROM `vanguardamartech_refined`.`rfn_midia__segmento_mensal`

  UNION ALL
  SELECT 'rfn_midia__segmento_mensal.metrica_nao_negativa', 'Refined',
         'rfn_midia__segmento_mensal', 'Google Ads', 'VALIDADE',
         'investimento, impressao, clique e conversao nunca sao negativos',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(investimento < 0 OR impressoes < 0 OR cliques < 0 OR conversoes < 0)
  FROM `vanguardamartech_refined`.`rfn_midia__segmento_mensal`

  UNION ALL
  -- LINHA DE BASE 0,999 -- 3 de 7.886. Mesma causa da linha de base da localizacao.
  SELECT 'rfn_midia__segmento_mensal.clique_nunca_excede_impressao', 'Refined',
         'rfn_midia__segmento_mensal', 'Google Ads', 'VALIDADE',
         'o clique nunca passa da impressao', 'ALERTA', 0.999,
         COUNT(*), COUNTIF(cliques > impressoes)
  FROM `vanguardamartech_refined`.`rfn_midia__segmento_mensal`
),

todas AS (
  SELECT * FROM r_conta
  UNION ALL SELECT * FROM r_campanha
  UNION ALL SELECT * FROM r_valor
  UNION ALL SELECT * FROM r_fk
  UNION ALL SELECT * FROM r_desigualdade
  UNION ALL SELECT * FROM r_facebook
  UNION ALL SELECT * FROM r_geo
  UNION ALL SELECT * FROM r_localizacao
  UNION ALL SELECT * FROM r_segmento
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
  'Midia'                                       AS familia,
  CURRENT_TIMESTAMP()                           AS _extraido_at,
  'multiplas'                                   AS _fonte,
  'America/Sao_Paulo'                           AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(a)))                AS _payload_hash
FROM avaliado a
