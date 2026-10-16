-- rfn_qualidade__regra_marketing  ·  query-3EQy  ·  24 regras  ·  L2 INTERNAL
-- Refined / qualidade. Grao: uma REGRA de qualidade em uma execucao. Chave: id_regra
-- (a execucao se le em _extraido_at). Gatilho: evento em query-tESg. Alerta ligado.
-- Cadencia DIARIA -- a familia RD roda por cron, 13:10 e 13:20 America/Manaus.
--
-- POR QUE UMA QUINTA SUITE. Mesmo motivo da do Gmail e da do iClips: a
--   `rfn_qualidade__regra` esta com 57 KB e 84 regras e `update_transformation`
--   substitui o CODIGO INTEIRO. O CONTRATO DE COLUNAS E IDENTICO ao das outras cinco --
--   um UNION ALL da o painel unico e `familia` diz de onde veio cada linha.
--
-- O QUE FICAVA DE FORA: a familia RD Station inteira, 229.517 linhas materializadas
--   sem UMA regra -- `trs_rd_station__contato` 108.925 (query-9dz7),
--   `trs_rd_station__conversao` 120.592 (query-ehQc) e `rfn_marketing__conversao`
--   120.592 (query-tESg). E a maior fonte de LEAD da casa.
--
-- ARMADILHA DE CAMADA REGISTRADA NO CODIGO, e ela custou a primeira medicao.
--   `get_relevant_tables_ddl` pedido com `vanguardamartech_trusted.trs_rd_station__*`
--   DEVOLVEU `vanguardamartech_braga_veiculos.trs_rd_station__*` sem avisar da troca --
--   sao as homonimas por cliente, geradas pelas queries antigas (query-Y2zz, 01Je,
--   T9Gl, Zng7 e as de contato). A consolidada e a de `vanguardamartech_trusted`, e
--   apontar para a camada errada devolve UM cliente e parece a base inteira. Mesma
--   armadilha ja registrada nas onze `trs_facebook_ads__insight_diario`. Toda
--   referencia aqui e explicita.
--
-- AS 24 REGRAS, MEDIDAS EM 2026-09-29 SOBRE A TABELA MATERIALIZADA, ANTES DE PUBLICAR.
-- Resultado esperado na primeira execucao: 24 CONFORMES, ZERO FALHAS.
--
-- A REGRA QUE IMPORTA MAIS E A QUINTA IDENTIDADE DESTA CASA, E E A PRIMEIRA ENTRE
--   CAMADAS: `rfn_marketing__conversao.reproduz_a_trusted_linha_a_linha`.
--   A Refined nao agrega nem filtra -- ela classifica a origem de trafego e devolve o
--   MESMO grao da Trusted. Entao a contagem das duas tem de ser identica: 120.592 dos
--   dois lados, medido. Se divergir, ou a Refined perdeu linha num join (e a leitura
--   de marketing passa a subcontar em silencio) ou duplicou. BLOQUEANTE, limiar 1,00.
--   As quatro anteriores -- `rateio_fecha_no_centavo`, `caixa_reproduz_o_razao`,
--   `itens_batem_com_a_auditoria` e `custo_reproduz_hora_vezes_valor_hora` -- comparam
--   VALOR; esta compara CARDINALIDADE entre Silver e Gold.
--
-- A SEGUNDA QUE IMPORTA E UMA DECOMPOSICAO EXATA:
--   `canal_indefinido_decompoe`. A Refined declara que `canal_indefinido` NAO mistura
--   "sem origem" com "origem que nao entendi" -- sao problemas diferentes e so o
--   segundo derruba `registro_confiavel`. Medido: canal_indefinido e exatamente
--   `sem_origem OR formato_nao_reconhecido`, 101.938 = 101.928 + 10, zero divergencia.
--   Se soltar, a distincao que a propria descricao promete deixa de valer e ninguem
--   percebe -- a contagem de linhas nao muda.
--
-- AS OUTRAS QUE GUARDAM PREMISSA DE VERDADE:
--   `contato.tem_detalhe_concorda` -- a Trusted avisa, em maiusculas, para NAO tratar
--     NULL como "nao tem": um contato sem telefone pode ser um contato sem telefone ou
--     um contato de fonte que nao extrai telefone, e `tem_detalhe` e o unico separador.
--     Se a flag deixar de concordar com `origem_contato`, toda taxa de preenchimento
--     desta base sai errada por construcao.
--   `contato.tem_telefone_concorda` -- mesma familia, sobre os dois campos de telefone.
--   `conversao.tem_origem_trafego_concorda` -- a flag e o que decide o denominador de
--     qualquer leitura de atribuicao.
--   `refinada.canal_pago_concorda` -- `canal_pago` tem de ser exatamente os canais que
--     comecam com PAGO. A Refined declara que PAGO exige sinal EXPLICITO de midia paga;
--     se as duas colunas divergirem, a leitura de resultado de midia infla ou desinfla
--     sem aviso. Medido: zero nos dois sentidos.
--   `refinada.canal_conhecido` -- a taxonomia tem 14 valores e sai de um CASE da propria
--     Refined. Valor novo so aparece se o codigo mudar, e e justamente isso que a regra
--     pega: quem consome por canal nao veria o valor novo sumir da sua leitura.
--
-- AS LINHAS DE BASE, E POR QUE O LIMIAR NAO E 1,00 NELAS:
--   `conversao.contato_catalogado` (ALERTA 0,99) -- hoje 120.592 de 120.592 resolvem,
--     mas a propria Trusted declara que "evento antigo pode apontar para contato que
--     saiu da base" e manda usar LEFT JOIN. Exclusao de titular por LGPD produz
--     exatamente esse caso. Limiar 1,00 aqui viraria alarme legitimo -- e regra que
--     acusa o que e legitimo ensina a ignorar a suite.
--   `contato.dominio_email_extraido` (ALERTA 0,999) -- 47 de 108.925 (99,957%).
--   `refinada.escape_tratado` (ALERTA 0,9999) -- 1 de 120.592. O decodificador de
--     percent-encoding e de uso geral; `escape_nao_tratado` existe para escape novo
--     APARECER em vez de virar texto sujo.
--   `refinada.formato_reconhecido` (ALERTA 0,999) -- 10 das 18.664 linhas QUE TEM
--     origem. O denominador exclui `sem_origem` de proposito: medir sobre a base
--     inteira diluiria o defeito por 120 mil linhas e a regra nunca dispararia.
--
-- O QUE FICOU DE FORA, COM A MEDICAO QUE SUSTENTA:
--   `conversao.tipo_evento_conhecido` -- hoje CONVERSION e CDP em 100% das linhas, mas
--     a Trusted declara que "se um dia aparecer outro tipo, ele entra sozinho e a coluna
--     tipo_evento passa a discriminar". Uma regra exigindo CONVERSION transformaria uma
--     melhoria esperada em falha. Aqui a ausencia da regra E a decisao.
--   `refinada.carga_em_lote` -- 92.580 das 120.592 linhas (76,8%) sao importacao de base
--     para dentro da RD, nao conversao. NAO vira regra: carga nova e um evento legitimo
--     do negocio, e a Refined ja a marca. O numero esta aqui porque e a coisa mais
--     importante a saber sobre esta tabela -- QUALQUER leitura de resultado de marketing
--     comeca filtrando `carga_em_lote = FALSE`, e sem isso tres quartos da base sao
--     contato importado.

WITH ct AS (
  SELECT DISTINCT id_contato FROM `vanguardamartech_trusted`.`trs_rd_station__contato`
  WHERE id_contato IS NOT NULL
),
cv AS (
  SELECT DISTINCT id_conversao FROM `vanguardamartech_trusted`.`trs_rd_station__conversao`
  WHERE id_conversao IS NOT NULL
),

-- ------------------------------------------------------------------- CONTATO (7)
r_contato AS (
  SELECT 'trs_rd_station__contato.id_contato_unico' AS id_regra, 'Trusted' AS camada,
         'trs_rd_station__contato' AS tabela, 'RD Station' AS sistema,
         'UNICIDADE' AS dimensao,
         'id_contato e unico e nunca nulo' AS regra, 'BLOQUEANTE' AS severidade,
         1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_contato) + COUNTIF(id_contato IS NULL) AS linhas_falha
  FROM `vanguardamartech_trusted`.`trs_rd_station__contato`

  UNION ALL
  SELECT 'trs_rd_station__contato.email_preenchido', 'Trusted',
         'trs_rd_station__contato', 'RD Station', 'COMPLETUDE',
         'todo contato carrega email', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(email IS NULL)
  FROM `vanguardamartech_trusted`.`trs_rd_station__contato`

  UNION ALL
  SELECT 'trs_rd_station__contato.atualizado_em_preenchido', 'Trusted',
         'trs_rd_station__contato', 'RD Station', 'COMPLETUDE',
         'todo contato carrega data de atualizacao', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(atualizado_em IS NULL)
  FROM `vanguardamartech_trusted`.`trs_rd_station__contato`

  UNION ALL
  -- A flag que separa grao completo de grao minimo. Ver o cabecalho.
  SELECT 'trs_rd_station__contato.tem_detalhe_concorda', 'Trusted',
         'trs_rd_station__contato', 'RD Station', 'VALIDADE',
         'a flag tem_detalhe concorda com a origem do contato', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(tem_detalhe <> (origem_contato = 'contacts_details'))
  FROM `vanguardamartech_trusted`.`trs_rd_station__contato`

  UNION ALL
  SELECT 'trs_rd_station__contato.tem_telefone_concorda', 'Trusted',
         'trs_rd_station__contato', 'RD Station', 'VALIDADE',
         'a flag tem_telefone concorda com os dois campos de telefone',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(tem_telefone <> (telefone_movel IS NOT NULL OR telefone_pessoal IS NOT NULL))
  FROM `vanguardamartech_trusted`.`trs_rd_station__contato`

  UNION ALL
  SELECT 'trs_rd_station__contato.origem_contato_conhecida', 'Trusted',
         'trs_rd_station__contato', 'RD Station', 'VALIDADE',
         'origem_contato e contacts_details ou segmentation_contacts',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(origem_contato NOT IN ('contacts_details', 'segmentation_contacts'))
  FROM `vanguardamartech_trusted`.`trs_rd_station__contato`

  UNION ALL
  -- LINHA DE BASE. 47 emails sem parte de dominio.
  SELECT 'trs_rd_station__contato.dominio_email_extraido', 'Trusted',
         'trs_rd_station__contato', 'RD Station', 'VALIDADE',
         'o dominio sai extraido do email', 'ALERTA', 0.999,
         COUNTIF(email IS NOT NULL),
         COUNTIF(email IS NOT NULL AND dominio_email IS NULL)
  FROM `vanguardamartech_trusted`.`trs_rd_station__contato`
),

-- ----------------------------------------------------------------- CONVERSAO (6)
r_conv AS (
  SELECT 'trs_rd_station__conversao.id_conversao_unico', 'Trusted',
         'trs_rd_station__conversao', 'RD Station', 'UNICIDADE',
         'id_conversao e unico e nunca nulo', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNT(*) - COUNT(DISTINCT id_conversao) + COUNTIF(id_conversao IS NULL)
  FROM `vanguardamartech_trusted`.`trs_rd_station__conversao`

  UNION ALL
  SELECT 'trs_rd_station__conversao.evento_sempre_datado', 'Trusted',
         'trs_rd_station__conversao', 'RD Station', 'COMPLETUDE',
         'todo evento carrega data', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(ocorrido_data IS NULL)
  FROM `vanguardamartech_trusted`.`trs_rd_station__conversao`

  UNION ALL
  -- Guarda o fuso: a origem devolve UTC e a Trusted converte para America/Sao_Paulo.
  SELECT 'trs_rd_station__conversao.data_nao_futura', 'Trusted',
         'trs_rd_station__conversao', 'RD Station', 'VALIDADE',
         'nenhum evento tem data no futuro', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(ocorrido_data > CURRENT_DATE('America/Sao_Paulo'))
  FROM `vanguardamartech_trusted`.`trs_rd_station__conversao`

  UNION ALL
  SELECT 'trs_rd_station__conversao.tem_origem_trafego_concorda', 'Trusted',
         'trs_rd_station__conversao', 'RD Station', 'VALIDADE',
         'a flag tem_origem_trafego concorda com a fonte de trafego bruta',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(tem_origem_trafego <> (fonte_trafego_bruta IS NOT NULL))
  FROM `vanguardamartech_trusted`.`trs_rd_station__conversao`

  UNION ALL
  SELECT 'trs_rd_station__conversao.contato_preenchido', 'Trusted',
         'trs_rd_station__conversao', 'RD Station', 'COMPLETUDE',
         'todo evento aponta para um contato', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(id_contato IS NULL)
  FROM `vanguardamartech_trusted`.`trs_rd_station__conversao`
),
r_conv_fk AS (
  -- LINHA DE BASE, 100% hoje. Anti-join com DISTINCT no lado direito -- NAO usar
  -- NOT EXISTS correlacionado: esta casa ja registrou que ele nao roda no BigQuery
  -- quando a uniao cresce.
  SELECT 'trs_rd_station__conversao.contato_catalogado', 'Trusted',
         'trs_rd_station__conversao', 'RD Station', 'INTEGRIDADE',
         'o contato do evento existe na tabela de contato', 'ALERTA', 0.99,
         COUNT(*), COUNTIF(ct.id_contato IS NULL)
  FROM `vanguardamartech_trusted`.`trs_rd_station__conversao` v
  LEFT JOIN ct USING (id_contato)
),

-- ------------------------------------------------------------------ REFINED (9)
r_ref AS (
  SELECT 'rfn_marketing__conversao.id_conversao_unico', 'Refined',
         'rfn_marketing__conversao', 'RD Station', 'UNICIDADE',
         'id_conversao e unico e nunca nulo', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNT(*) - COUNT(DISTINCT id_conversao) + COUNTIF(id_conversao IS NULL)
  FROM `vanguardamartech_refined`.`rfn_marketing__conversao`

  UNION ALL
  -- A DECOMPOSICAO EXATA. Ver o cabecalho.
  SELECT 'rfn_marketing__conversao.canal_indefinido_decompoe', 'Refined',
         'rfn_marketing__conversao', 'RD Station', 'VALIDADE',
         'canal indefinido e exatamente sem origem ou formato nao reconhecido',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(canal_indefinido <> (sem_origem OR formato_nao_reconhecido))
  FROM `vanguardamartech_refined`.`rfn_marketing__conversao`

  UNION ALL
  SELECT 'rfn_marketing__conversao.canal_indefinido_concorda', 'Refined',
         'rfn_marketing__conversao', 'RD Station', 'VALIDADE',
         'a flag canal_indefinido concorda com o canal DESCONHECIDO',
         'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(canal_indefinido <> (canal = 'DESCONHECIDO'))
  FROM `vanguardamartech_refined`.`rfn_marketing__conversao`

  UNION ALL
  SELECT 'rfn_marketing__conversao.canal_pago_concorda', 'Refined',
         'rfn_marketing__conversao', 'RD Station', 'VALIDADE',
         'a flag canal_pago e exatamente os canais que comecam com PAGO',
         'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(canal_pago <> STARTS_WITH(canal, 'PAGO'))
  FROM `vanguardamartech_refined`.`rfn_marketing__conversao`

  UNION ALL
  SELECT 'rfn_marketing__conversao.canal_conhecido', 'Refined',
         'rfn_marketing__conversao', 'RD Station', 'VALIDADE',
         'o canal esta na taxonomia de 14 valores declarada', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(canal NOT IN ('DESCONHECIDO','PAGO_SOCIAL','PAGO_BUSCA','PAGO_OUTRO',
                               'ORGANICO_BUSCA','ORGANICO_SOCIAL','DIRETO','REFERENCIA',
                               'RD_PROPRIO','GOOGLE_MEU_NEGOCIO','WHATSAPP','EMAIL',
                               'MENSAGEIRO','OUTRO'))
  FROM `vanguardamartech_refined`.`rfn_marketing__conversao`

  UNION ALL
  SELECT 'rfn_marketing__conversao.data_preenchida', 'Refined',
         'rfn_marketing__conversao', 'RD Station', 'COMPLETUDE',
         'toda conversao carrega data e mes de referencia', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(data IS NULL OR mes_referencia IS NULL)
  FROM `vanguardamartech_refined`.`rfn_marketing__conversao`

  UNION ALL
  -- LINHA DE BASE. 1 escape sobrevivente.
  SELECT 'rfn_marketing__conversao.escape_tratado', 'Refined',
         'rfn_marketing__conversao', 'RD Station', 'VALIDADE',
         'o decodificador de percent-encoding nao deixa escape para tras',
         'ALERTA', 0.9999,
         COUNT(*), COUNTIF(escape_nao_tratado)
  FROM `vanguardamartech_refined`.`rfn_marketing__conversao`

  UNION ALL
  -- LINHA DE BASE. Denominador = linhas QUE TEM origem, de proposito.
  SELECT 'rfn_marketing__conversao.formato_reconhecido', 'Refined',
         'rfn_marketing__conversao', 'RD Station', 'VALIDADE',
         'a origem que existe e reconhecida pelo parser', 'ALERTA', 0.999,
         COUNTIF(NOT sem_origem),
         COUNTIF(NOT sem_origem AND formato_nao_reconhecido)
  FROM `vanguardamartech_refined`.`rfn_marketing__conversao`
),
r_ref_fk AS (
  SELECT 'rfn_marketing__conversao.conversao_existe_na_trusted', 'Refined',
         'rfn_marketing__conversao', 'RD Station', 'INTEGRIDADE',
         'toda linha da Refined existe na Trusted de conversao', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(cv.id_conversao IS NULL)
  FROM `vanguardamartech_refined`.`rfn_marketing__conversao` r
  LEFT JOIN cv USING (id_conversao)
),

-- --------------------------------------------------------------- A IDENTIDADE (1)
r_identidade AS (
  SELECT 'rfn_marketing__conversao.reproduz_a_trusted_linha_a_linha' AS id_regra,
         'Refined' AS camada, 'rfn_marketing__conversao' AS tabela,
         'RD Station' AS sistema, 'INTEGRIDADE' AS dimensao,
         'a Refined tem exatamente as mesmas linhas que a Trusted' AS regra,
         'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         1 AS linhas_avaliadas,
         IF((SELECT COUNT(*) FROM `vanguardamartech_refined`.`rfn_marketing__conversao`)
            = (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_rd_station__conversao`),
            0, 1) AS linhas_falha
),

-- ------------------------------------------------------------------- FRESCOR (1)
-- Escopo de FONTE: as tres tabelas vem da mesma familia RD e rodam no mesmo ciclo
-- diario (9dz7 13:10 -> ehQc 13:20 -> tESg por evento).
carga AS (
  SELECT 'contato'  AS t, MAX(DATE(_extraido_at)) AS d FROM `vanguardamartech_trusted`.`trs_rd_station__contato`
  UNION ALL SELECT 'conversao', MAX(DATE(_extraido_at)) FROM `vanguardamartech_trusted`.`trs_rd_station__conversao`
  UNION ALL SELECT 'refinada',  MAX(DATE(_extraido_at)) FROM `vanguardamartech_refined`.`rfn_marketing__conversao`
),
r_frescor AS (
  SELECT 'rd_station.carga_do_mesmo_dia' AS id_regra, 'Trusted' AS camada,
         '(as 3 tabelas da familia RD)' AS tabela, 'RD Station' AS sistema,
         'VALIDADE' AS dimensao,
         'as 3 tabelas da familia RD foram escritas na mesma passada' AS regra,
         'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNTIF(d <> (SELECT MAX(d) FROM carga)) AS linhas_falha
  FROM carga
),

todas AS (
  SELECT * FROM r_contato
  UNION ALL SELECT * FROM r_conv
  UNION ALL SELECT * FROM r_conv_fk
  UNION ALL SELECT * FROM r_ref
  UNION ALL SELECT * FROM r_ref_fk
  UNION ALL SELECT * FROM r_identidade
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
  'Marketing'                                   AS familia,
  CURRENT_TIMESTAMP()                           AS _extraido_at,
  'multiplas'                                   AS _fonte,
  'America/Sao_Paulo'                           AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(a)))                AS _payload_hash
FROM avaliado a
