-- rfn_qualidade__regra_marketing_rd_novas  -  suite de qualidade das 18 fontes de RD Station de 14/10/2026 e da cadeia ampliada
-- Refined / qualidade, L2 INTERNAL. Grao: uma REGRA em uma execucao. Contrato de colunas IDENTICO ao das outras suites
-- (id_regra, camada, tabela, sistema, dimensao, regra, severidade, limiar, linhas_avaliadas, linhas_falha, linhas_conformes,
-- taxa_conformidade, is_conforme, flag_sem_linha_para_avaliar, resultado, familia). Um UNION ALL entre as suites da o painel unico.
-- Gatilho: evento em query-9pcn (rfn_marketing__funil_mensal), o ULTIMO elo da cadeia 9dz7 -> ehQc -> tESg -> 9pcn (NdTU dispara em 9dz7).
-- POR QUE NAO ESTENDEU A SUITE query-3EQy: ela dispara em tESg, EM PARALELO com a funil e a contato_base; esta le a funil e as colunas
-- novas das Trusted, entao precisa rodar DEPOIS de todas. Estender a 3EQy tambem exigiria reescrever 16 KB de codigo que ja roda limpo.
-- As 24 regras de 3EQy continuam valendo e foram conferidas contra a base ampliada (ver descricao).
--
-- ARMADILHA DE CAMADA: a consolidada e `vanguardamartech_trusted`; existem tabelas homonimas nas camadas de cliente. Referencia explicita.
-- Regra sem linha para avaliar NAO passa (SEM_DADO). Nenhuma regra compara flag gravada com o relogio (tudo por _extraido_at ou por dado).
WITH raw_contato AS (
  SELECT 'rd-station-5KKM' AS _fonte, COUNT(DISTINCT uuid) AS n FROM `vanguardamartech_rd_arena_tintas`.`rd_station_arena_tintascontacts_details`
  UNION ALL
  SELECT 'rd-station-YNpj' AS _fonte, COUNT(DISTINCT uuid) AS n FROM `vanguardamartech_rd_bap`.`rd_station_bapcontacts_details`
  UNION ALL
  SELECT 'rd-station-6Ir5' AS _fonte, COUNT(DISTINCT uuid) AS n FROM `vanguardamartech_rd_braga_veiculos`.`rd_station_braga_veiculos__contacts_details`
  UNION ALL
  SELECT 'rd-station-POZB' AS _fonte, COUNT(DISTINCT uuid) AS n FROM `vanguardamartech_rd_caa_aluminio`.`rd_station_caa_aluminiocontacts_details`
  UNION ALL
  SELECT 'rd-station-irou' AS _fonte, COUNT(DISTINCT uuid) AS n FROM `vanguardamartech_rd_station_caa_tintas`.`rd_station_caa_tintascontacts_details`
  UNION ALL
  SELECT 'rd-station-QcKP' AS _fonte, COUNT(DISTINCT uuid) AS n FROM `vanguardamartech_rd_station_charao`.`rd_station_charaocontacts_details`
  UNION ALL
  SELECT 'rd-station-c9jU' AS _fonte, COUNT(DISTINCT uuid) AS n FROM `vanguardamartech_rd_constroi_incorporadora`.`rd_station_constroi_incorporadoracontacts_details`
  UNION ALL
  SELECT 'rd-station-1boX' AS _fonte, COUNT(DISTINCT uuid) AS n FROM `vanguardamartech_rd_distribuidora_pneu_forte`.`rd_station_pneu_fortecontacts_details`
  UNION ALL
  SELECT 'rd-station-Fzvz' AS _fonte, COUNT(DISTINCT uuid) AS n FROM `vanguardamartech_rd_doctor_mais_saude`.`rd_station_doctor_mais_saudecontacts_details`
  UNION ALL
  SELECT 'rd-station-fPd4' AS _fonte, COUNT(DISTINCT uuid) AS n FROM `vanguardamartech_rd_hage_alimentos`.`rd_station_hage_alimentoscontacts_details`
  UNION ALL
  SELECT 'rd-station-mEzQ' AS _fonte, COUNT(DISTINCT uuid) AS n FROM `vanguardamartech_rd_pmz_escola`.`rd_station_pmz_escolacontacts_details`
  UNION ALL
  SELECT 'rd-station-zxA3' AS _fonte, COUNT(DISTINCT uuid) AS n FROM `vanguardamartech_rd_rodrix`.`rd_station_rodrixcontacts_details`
  UNION ALL
  SELECT 'rd-station-ypAe' AS _fonte, COUNT(DISTINCT uuid) AS n FROM `vanguardamartech_rd_station_royal_enfield`.`rd_station_royal_enfieldcontacts_details`
  UNION ALL
  SELECT 'rd-station-f2o9' AS _fonte, COUNT(DISTINCT uuid) AS n FROM `vanguardamartech_rd_station_santo_remedio`.`rd_station_santo_remediocontacts_details`
  UNION ALL
  SELECT 'rd-station-Sys9' AS _fonte, COUNT(DISTINCT uuid) AS n FROM `vanguardamartech_rd_station_shizen`.`rd_station_shizencontacts_details`
  UNION ALL
  SELECT 'rd-station-409D' AS _fonte, COUNT(DISTINCT uuid) AS n FROM `vanguardamartech_rd_unipar`.`rd_station_uniparcontacts_details`
  UNION ALL
  SELECT 'rd-station-IOQX' AS _fonte, COUNT(DISTINCT uuid) AS n FROM `vanguardamartech_rd_braga_veiculos`.`rd_station_braga_veiculossegmentation_contacts`
  UNION ALL
  SELECT 'rd-station-rlmE' AS _fonte, COUNT(DISTINCT uuid) AS n FROM `vanguardamartech_rd_station_braga_motos`.`rd_station_braga_motossegmentation_contacts`
),
raw_evento AS (
  SELECT 'rd-station-5KKM' AS _fonte, COUNT(DISTINCT id) AS n FROM `vanguardamartech_rd_arena_tintas`.`rd_station_arena_tintascontact_events`
  UNION ALL
  SELECT 'rd-station-YNpj' AS _fonte, COUNT(DISTINCT id) AS n FROM `vanguardamartech_rd_bap`.`rd_station_bapcontact_events`
  UNION ALL
  SELECT 'rd-station-6Ir5' AS _fonte, COUNT(DISTINCT id) AS n FROM `vanguardamartech_rd_braga_veiculos`.`rd_station_braga_veiculos__contact_events`
  UNION ALL
  SELECT 'rd-station-POZB' AS _fonte, COUNT(DISTINCT id) AS n FROM `vanguardamartech_rd_caa_aluminio`.`rd_station_caa_aluminiocontact_events`
  UNION ALL
  SELECT 'rd-station-irou' AS _fonte, COUNT(DISTINCT id) AS n FROM `vanguardamartech_rd_station_caa_tintas`.`rd_station_caa_tintascontact_events`
  UNION ALL
  SELECT 'rd-station-QcKP' AS _fonte, COUNT(DISTINCT id) AS n FROM `vanguardamartech_rd_station_charao`.`rd_station_charaocontact_events`
  UNION ALL
  SELECT 'rd-station-c9jU' AS _fonte, COUNT(DISTINCT id) AS n FROM `vanguardamartech_rd_constroi_incorporadora`.`rd_station_constroi_incorporadoracontact_events`
  UNION ALL
  SELECT 'rd-station-1boX' AS _fonte, COUNT(DISTINCT id) AS n FROM `vanguardamartech_rd_distribuidora_pneu_forte`.`rd_station_pneu_fortecontact_events`
  UNION ALL
  SELECT 'rd-station-Fzvz' AS _fonte, COUNT(DISTINCT id) AS n FROM `vanguardamartech_rd_doctor_mais_saude`.`rd_station_doctor_mais_saudecontact_events`
  UNION ALL
  SELECT 'rd-station-fPd4' AS _fonte, COUNT(DISTINCT id) AS n FROM `vanguardamartech_rd_hage_alimentos`.`rd_station_hage_alimentoscontact_events`
  UNION ALL
  SELECT 'rd-station-mEzQ' AS _fonte, COUNT(DISTINCT id) AS n FROM `vanguardamartech_rd_pmz_escola`.`rd_station_pmz_escolacontact_events`
  UNION ALL
  SELECT 'rd-station-zxA3' AS _fonte, COUNT(DISTINCT id) AS n FROM `vanguardamartech_rd_rodrix`.`rd_station_rodrixcontact_events`
  UNION ALL
  SELECT 'rd-station-ypAe' AS _fonte, COUNT(DISTINCT id) AS n FROM `vanguardamartech_rd_station_royal_enfield`.`rd_station_royal_enfieldcontact_events`
  UNION ALL
  SELECT 'rd-station-f2o9' AS _fonte, COUNT(DISTINCT id) AS n FROM `vanguardamartech_rd_station_santo_remedio`.`rd_station_santo_remediocontact_events`
  UNION ALL
  SELECT 'rd-station-Sys9' AS _fonte, COUNT(DISTINCT id) AS n FROM `vanguardamartech_rd_station_shizen`.`rd_station_shizencontact_events`
  UNION ALL
  SELECT 'rd-station-409D' AS _fonte, COUNT(DISTINCT id) AS n FROM `vanguardamartech_rd_unipar`.`rd_station_uniparcontact_events`
  UNION ALL
  SELECT 'rd-station-IOQX' AS _fonte, COUNT(DISTINCT id) AS n FROM `vanguardamartech_rd_braga_veiculos`.`rd_station_braga_veiculoscontact_events`
  UNION ALL
  SELECT 'rd-station-rlmE' AS _fonte, COUNT(DISTINCT id) AS n FROM `vanguardamartech_rd_station_braga_motos`.`rd_station_braga_motoscontact_events`
),
tc AS (
  SELECT _fonte, COUNT(*) AS n FROM `vanguardamartech_trusted`.`trs_rd_station__contato` GROUP BY _fonte
),
tv AS (
  SELECT _fonte, COUNT(*) AS n FROM `vanguardamartech_trusted`.`trs_rd_station__conversao` GROUP BY _fonte
),
uuid_fontes AS (
  SELECT uuid_contato, COUNT(DISTINCT _fonte) AS n_fontes, COUNT(DISTINCT email) AS n_emails
  FROM `vanguardamartech_trusted`.`trs_rd_station__contato` GROUP BY uuid_contato
),
evento_fontes AS (
  SELECT id_evento, COUNT(DISTINCT _fonte) AS n_fontes
  FROM `vanguardamartech_trusted`.`trs_rd_station__conversao` GROUP BY id_evento
),

-- ------------------------------------------------------------------- CONTATO
r_contato AS (
  SELECT 'trs_rd_station__contato.reproduz_a_raw_por_fonte' AS id_regra, 'Trusted' AS camada,
         'trs_rd_station__contato' AS tabela, 'RD Station' AS sistema, 'INTEGRIDADE' AS dimensao,
         'cada fonte nova tem na Trusted exatamente os uuids distintos da tabela de origem' AS regra,
         'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNTIF(IFNULL(tc.n, 0) <> r.n) AS linhas_falha
  FROM raw_contato r LEFT JOIN tc USING (_fonte)

  UNION ALL
  -- O mesmo uuid em duas fontes tem de ser a MESMA pessoa: se o e-mail diverge, a deduplicacao por uuid esta errada.
  SELECT 'trs_rd_station__contato.uuid_multi_fonte_mesmo_email', 'Trusted',
         'trs_rd_station__contato', 'RD Station', 'VALIDADE',
         'uuid que aparece em mais de uma fonte carrega o mesmo e-mail', 'BLOQUEANTE', 1.00,
         COUNTIF(n_fontes > 1), COUNTIF(n_fontes > 1 AND n_emails > 1)
  FROM uuid_fontes

  UNION ALL
  SELECT 'trs_rd_station__contato.qtd_fontes_concorda', 'Trusted',
         'trs_rd_station__contato', 'RD Station', 'VALIDADE',
         'qtd_fontes_do_contato e a flag concordam com a contagem refeita por uuid', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(t.qtd_fontes_do_contato <> u.n_fontes OR t.flag_contato_em_mais_de_uma_fonte <> (u.n_fontes > 1))
  FROM `vanguardamartech_trusted`.`trs_rd_station__contato` t JOIN uuid_fontes u USING (uuid_contato)

  UNION ALL
  -- GUARDA DA LGPD: autorizado = granted E NENHUM declined. A regra so e segura se nenhum contato carregar os dois.
  SELECT 'trs_rd_station__contato.granted_e_declined_nunca_juntos', 'Trusted',
         'trs_rd_station__contato', 'RD Station', 'VALIDADE',
         'nenhum contato carrega base granted e declined ao mesmo tempo', 'BLOQUEANTE', 1.00,
         COUNTIF(tem_detalhe),
         COUNTIF(tem_detalhe AND REGEXP_CONTAINS(IFNULL(bases_legais_json, ''), r'granted')
                 AND REGEXP_CONTAINS(IFNULL(bases_legais_json, ''), r'declined'))
  FROM `vanguardamartech_trusted`.`trs_rd_station__contato`
),

-- ----------------------------------------------------------------- CONVERSAO
r_conv AS (
  SELECT 'trs_rd_station__conversao.reproduz_a_raw_por_fonte' AS id_regra, 'Trusted' AS camada,
         'trs_rd_station__conversao' AS tabela, 'RD Station' AS sistema, 'INTEGRIDADE' AS dimensao,
         'cada fonte nova tem na Trusted exatamente os eventos distintos da tabela de origem' AS regra,
         'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNTIF(IFNULL(tv.n, 0) <> r.n) AS linhas_falha
  FROM raw_evento r LEFT JOIN tv USING (_fonte)

  UNION ALL
  SELECT 'trs_rd_station__conversao.id_conversao_confere_com_id_evento', 'Trusted',
         'trs_rd_station__conversao', 'RD Station', 'VALIDADE',
         'id_conversao e exatamente _fonte|id_evento', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(id_conversao <> CONCAT(_fonte, '|', id_evento))
  FROM `vanguardamartech_trusted`.`trs_rd_station__conversao`

  UNION ALL
  SELECT 'trs_rd_station__conversao.qtd_fontes_concorda', 'Trusted',
         'trs_rd_station__conversao', 'RD Station', 'VALIDADE',
         'qtd_fontes_do_evento e a flag concordam com a contagem refeita por id de evento', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(t.qtd_fontes_do_evento <> e.n_fontes OR t.flag_evento_em_mais_de_uma_fonte <> (e.n_fontes > 1))
  FROM `vanguardamartech_trusted`.`trs_rd_station__conversao` t JOIN evento_fontes e USING (id_evento)
),

-- ------------------------------------------------------------- CONTATO_BASE
r_base AS (
  SELECT 'rfn_marketing__contato_base.reproduz_a_trusted' AS id_regra, 'Refined' AS camada,
         'rfn_marketing__contato_base' AS tabela, 'RD Station' AS sistema, 'INTEGRIDADE' AS dimensao,
         'a soma de qtd_contatos e exatamente o numero de linhas da Trusted de contato' AS regra,
         'BLOQUEANTE' AS severidade, 1.00 AS limiar, 1 AS linhas_avaliadas,
         IF((SELECT SUM(qtd_contatos) FROM `vanguardamartech_refined`.`rfn_marketing__contato_base`)
            = (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_rd_station__contato`), 0, 1) AS linhas_falha

  UNION ALL
  SELECT 'rfn_marketing__contato_base.decomposicao_lgpd_fecha', 'Refined',
         'rfn_marketing__contato_base', 'RD Station', 'VALIDADE',
         'autorizados + recusaram + sem registro fecham em qtd_com_detalhe, por cliente', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(qtd_autorizados + qtd_recusaram + qtd_sem_registro <> qtd_com_detalhe)
  FROM `vanguardamartech_refined`.`rfn_marketing__contato_base`

  UNION ALL
  SELECT 'rfn_marketing__contato_base.exclusivos_mais_multi_fecha', 'Refined',
         'rfn_marketing__contato_base', 'RD Station', 'VALIDADE',
         'exclusivos + em mais de uma fonte fecham em qtd_contatos, por cliente', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(qtd_contatos_exclusivos + qtd_contatos_em_mais_de_uma_fonte <> qtd_contatos)
  FROM `vanguardamartech_refined`.`rfn_marketing__contato_base`

  UNION ALL
  -- A canonica e UMA linha por uuid: a soma dos canonicos e os uuids distintos da Trusted.
  SELECT 'rfn_marketing__contato_base.canonicos_batem_uuid_distinto', 'Refined',
         'rfn_marketing__contato_base', 'RD Station', 'INTEGRIDADE',
         'a soma de qtd_contatos_canonicos e o numero de uuids distintos da Trusted', 'BLOQUEANTE', 1.00, 1,
         IF((SELECT SUM(qtd_contatos_canonicos) FROM `vanguardamartech_refined`.`rfn_marketing__contato_base`)
            = (SELECT COUNT(DISTINCT uuid_contato) FROM `vanguardamartech_trusted`.`trs_rd_station__contato`), 0, 1)
),

-- ------------------------------------------------------- CONVERSAO REFINED
r_ref AS (
  SELECT 'rfn_marketing__conversao.canonica_uma_por_evento' AS id_regra, 'Refined' AS camada,
         'rfn_marketing__conversao' AS tabela, 'RD Station' AS sistema, 'INTEGRIDADE' AS dimensao,
         'existe exatamente uma linha canonica por id de evento' AS regra,
         'BLOQUEANTE' AS severidade, 1.00 AS limiar, 1 AS linhas_avaliadas,
         IF((SELECT COUNTIF(is_registro_canonico) FROM `vanguardamartech_refined`.`rfn_marketing__conversao`)
            = (SELECT COUNT(DISTINCT id_evento) FROM `vanguardamartech_refined`.`rfn_marketing__conversao`), 0, 1) AS linhas_falha
),

-- ------------------------------------------------------------------- FUNIL
r_funil AS (
  SELECT 'rfn_marketing__funil_mensal.id_funil_unico' AS id_regra, 'Refined' AS camada,
         'rfn_marketing__funil_mensal' AS tabela, 'RD Station' AS sistema, 'UNICIDADE' AS dimensao,
         'id_funil_mensal e unico e nunca nulo' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_funil_mensal) + COUNTIF(id_funil_mensal IS NULL) AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_marketing__funil_mensal`

  UNION ALL
  -- A identidade: o funil agrega e nao filtra, entao a soma das conversoes e as linhas da Refined de origem.
  SELECT 'rfn_marketing__funil_mensal.reproduz_a_refined', 'Refined',
         'rfn_marketing__funil_mensal', 'RD Station', 'INTEGRIDADE',
         'a soma de qtd_conversoes e exatamente o numero de linhas de rfn_marketing__conversao', 'BLOQUEANTE', 1.00, 1,
         IF((SELECT SUM(qtd_conversoes) FROM `vanguardamartech_refined`.`rfn_marketing__funil_mensal`)
            = (SELECT COUNT(*) FROM `vanguardamartech_refined`.`rfn_marketing__conversao`), 0, 1)

  UNION ALL
  SELECT 'rfn_marketing__funil_mensal.lote_e_grao', 'Refined',
         'rfn_marketing__funil_mensal', 'RD Station', 'VALIDADE',
         'a marca LOTE do id concorda com carga_em_lote (lote nunca se mistura com conversao)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(carga_em_lote <> ENDS_WITH(id_funil_mensal, '|LOTE'))
  FROM `vanguardamartech_refined`.`rfn_marketing__funil_mensal`

  UNION ALL
  SELECT 'rfn_marketing__funil_mensal.canal_pago_concorda', 'Refined',
         'rfn_marketing__funil_mensal', 'RD Station', 'VALIDADE',
         'canal_pago e exatamente os canais que comecam com PAGO', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(canal_pago <> STARTS_WITH(canal, 'PAGO'))
  FROM `vanguardamartech_refined`.`rfn_marketing__funil_mensal`

  UNION ALL
  SELECT 'rfn_marketing__funil_mensal.contatos_nao_excedem_conversoes', 'Refined',
         'rfn_marketing__funil_mensal', 'RD Station', 'VALIDADE',
         'contatos distintos nunca excedem as conversoes da linha', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(qtd_contatos_distintos > qtd_conversoes)
  FROM `vanguardamartech_refined`.`rfn_marketing__funil_mensal`
),

-- ------------------------------------------------------------------- FRESCOR
carga AS (
  SELECT 'contato' AS t, MAX(DATE(_extraido_at)) AS d FROM `vanguardamartech_trusted`.`trs_rd_station__contato`
  UNION ALL SELECT 'conversao', MAX(DATE(_extraido_at)) FROM `vanguardamartech_trusted`.`trs_rd_station__conversao`
  UNION ALL SELECT 'contato_base', MAX(DATE(_extraido_at)) FROM `vanguardamartech_refined`.`rfn_marketing__contato_base`
  UNION ALL SELECT 'conversao_refined', MAX(DATE(_extraido_at)) FROM `vanguardamartech_refined`.`rfn_marketing__conversao`
  UNION ALL SELECT 'funil', MAX(DATE(_extraido_at)) FROM `vanguardamartech_refined`.`rfn_marketing__funil_mensal`
),
r_frescor AS (
  SELECT 'rd_novas.carga_do_mesmo_dia' AS id_regra, 'Refined' AS camada,
         '(as 5 tabelas da cadeia RD)' AS tabela, 'RD Station' AS sistema, 'VALIDADE' AS dimensao,
         'as 5 tabelas da cadeia RD foram escritas na mesma passada' AS regra,
         'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNTIF(d <> (SELECT MAX(d) FROM carga)) AS linhas_falha
  FROM carga
),

todas AS (
  SELECT * FROM r_contato
  UNION ALL SELECT * FROM r_conv
  UNION ALL SELECT * FROM r_base
  UNION ALL SELECT * FROM r_ref
  UNION ALL SELECT * FROM r_funil
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
  'Marketing RD novas'                          AS familia,
  CURRENT_TIMESTAMP()                           AS _extraido_at,
  'multiplas'                                   AS _fonte,
  'America/Sao_Paulo'                           AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(a)))                AS _payload_hash
FROM avaliado a
