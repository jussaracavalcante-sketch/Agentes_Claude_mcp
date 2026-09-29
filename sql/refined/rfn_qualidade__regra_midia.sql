-- rfn_qualidade__regra_midia  ·  query-4tgF  ·  24 regras  ·  L2 INTERNAL
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
--   codigo inteiro. Contrato de colunas IDENTICO nas quatro — `familia` diz de onde veio.
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
-- AS 24 REGRAS, MEDIDAS EM 2026-09-29 SOBRE AS TABELAS MATERIALIZADAS, ANTES DE PUBLICAR.
-- Resultado esperado na primeira execucao: 24 CONFORMES, ZERO FALHAS.
--   GOOGLE ADS — conta (2) 88/88 e cliente 0 falhas · campanha (2) 827/827 e conta
--     catalogada 0 orfas · termo de busca (3) · quatro breakdowns (8) · desigualdade (5).
--   FACEBOOK (3) — campanha 1.233/1.233 · conta preenchida 0 · insight com campanha
--     catalogada **2.157 de 142.305 orfas (98,48%)**, limiar 0,98.
--
-- POR QUE A ORFANDADE DO FACEBOOK E LINHA DE BASE, E NAO DEFEITO: as 18 campanhas orfas
--   param em **27/03/2026** enquanto as 1.156 saudaveis vao ate hoje. A dimensao e uma
--   FOTOGRAFIA e o fato e HISTORICO — campanha apagada da conta some da dimensao e o
--   insight dela sobrevive. Mesmo mecanismo do gestor deletado no VJOB. Limiar apertado
--   ali so ensinaria a ignorar a suite.
--
-- FICA DE FORA, COM A CAUSA CONFERIDA: `trs_google_ads__geo_alvo`,
--   `rfn_midia__segmento_mensal` e `rfn_midia__localizacao_mensal` foram publicadas em
--   28/09 e ainda NAO MATERIALIZARAM — entram na passada de terca. Referenciar tabela nao
--   materializada derruba a query inteira.
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
todas AS (
  SELECT * FROM r_conta
  UNION ALL SELECT * FROM r_campanha
  UNION ALL SELECT * FROM r_valor
  UNION ALL SELECT * FROM r_fk
  UNION ALL SELECT * FROM r_desigualdade
  UNION ALL SELECT * FROM r_facebook
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
