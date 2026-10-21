-- slug no deploy: query-zu69 (esta linha existe so no arquivo)
-- Trusted RD Station - ativos de captura (landing_pages, popups, embeddables). L2 INTERNAL (so metadados, nenhum contato).
-- Grao: um ativo por conta RD (_fonte) e tipo. Chave id_ativo_captura = _fonte|tipo_ativo|id.
-- Medido em 18/10/2026: 1.901 linhas = 1.901 chaves (1.467 landing pages, 314 popups, 120 formularios embutidos).
-- Colunas ausentes em um tipo entram como NULL explicito (o parser da Nekt nao aceita FULL UNION ALL BY NAME).
-- identificador_conversao e a ponte para trs_rd_station__ativo_conversao_dia.identificador_ativo.
WITH cli AS (
  SELECT * FROM UNNEST([
    STRUCT('rd-station-1boX' AS _fonte, 'PNEU FORTE DISTRIBUIDORA' AS cliente),
    STRUCT('rd-station-3k4Z' AS _fonte, 'DMELLO' AS cliente),
    STRUCT('rd-station-409D' AS _fonte, 'UNIPAR' AS cliente),
    STRUCT('rd-station-4b7D' AS _fonte, 'MILLENIUM SHOPPING' AS cliente),
    STRUCT('rd-station-5KKM' AS _fonte, 'ARENA TINTAS' AS cliente),
    STRUCT('rd-station-5RPi' AS _fonte, 'AC DISPLAY' AS cliente),
    STRUCT('rd-station-6Ir5' AS _fonte, 'BRAGA VEICULOS VAREJO' AS cliente),
    STRUCT('rd-station-7K57' AS _fonte, 'PNEU FORTE' AS cliente),
    STRUCT('rd-station-8Fqy' AS _fonte, 'BRAGA ACESSORIOS' AS cliente),
    STRUCT('rd-station-9mbj' AS _fonte, 'AMAZONCOPY' AS cliente),
    STRUCT('rd-station-AqsD' AS _fonte, 'AMAZON OPEN MALL' AS cliente),
    STRUCT('rd-station-Awhd' AS _fonte, 'ACESSO SAUDE' AS cliente),
    STRUCT('rd-station-CSrx' AS _fonte, 'AMZ GERADORES' AS cliente),
    STRUCT('rd-station-CWtQ' AS _fonte, 'MARAVILHA MOTOS' AS cliente),
    STRUCT('rd-station-Fzvz' AS _fonte, 'DOCTOR MAIS SAUDE' AS cliente),
    STRUCT('rd-station-HVbj' AS _fonte, 'STEEL PORT' AS cliente),
    STRUCT('rd-station-HoWi' AS _fonte, 'HOPE BAY' AS cliente),
    STRUCT('rd-station-IOQX' AS _fonte, 'BRAGA VEICULOS VENDA DIRETA' AS cliente),
    STRUCT('rd-station-L2Sl' AS _fonte, 'DR. JOSE CABRAL JR' AS cliente),
    STRUCT('rd-station-MzyH' AS _fonte, 'BA ELETRICA' AS cliente),
    STRUCT('rd-station-Ozim' AS _fonte, 'KL RENT A CAR' AS cliente),
    STRUCT('rd-station-POZB' AS _fonte, 'CAA ALUMINIO' AS cliente),
    STRUCT('rd-station-QcKP' AS _fonte, 'CHARAO' AS cliente),
    STRUCT('rd-station-STKa' AS _fonte, 'HOSPITAL SANTA JULIA' AS cliente),
    STRUCT('rd-station-Sys9' AS _fonte, 'SHIZEN' AS cliente),
    STRUCT('rd-station-VYbu' AS _fonte, 'CONSTRUTORA COLMEIA' AS cliente),
    STRUCT('rd-station-WHAa' AS _fonte, 'BRAGA VEICULOS' AS cliente),
    STRUCT('rd-station-YNpj' AS _fonte, 'BAP' AS cliente),
    STRUCT('rd-station-bdVN' AS _fonte, 'PMZ' AS cliente),
    STRUCT('rd-station-c9jU' AS _fonte, 'CONSTROI INCORPORADORA' AS cliente),
    STRUCT('rd-station-dvZx' AS _fonte, 'DON WATCHES' AS cliente),
    STRUCT('rd-station-f2o9' AS _fonte, 'SANTO REMEDIO' AS cliente),
    STRUCT('rd-station-fPd4' AS _fonte, 'HAGE ALIMENTOS' AS cliente),
    STRUCT('rd-station-h3u2' AS _fonte, 'REI DAS MANGUEIRAS' AS cliente),
    STRUCT('rd-station-iJK3' AS _fonte, 'VBOT' AS cliente),
    STRUCT('rd-station-idF7' AS _fonte, 'BRAGA MOTORS' AS cliente),
    STRUCT('rd-station-irou' AS _fonte, 'CAA TINTAS' AS cliente),
    STRUCT('rd-station-mEzQ' AS _fonte, 'PMZ ESCOLA' AS cliente),
    STRUCT('rd-station-oYKw' AS _fonte, 'RD_station_marketing' AS cliente),
    STRUCT('rd-station-pDLk' AS _fonte, 'RD_clientes_vanguarda' AS cliente),
    STRUCT('rd-station-pG4G' AS _fonte, 'BEST CAR' AS cliente),
    STRUCT('rd-station-rlmE' AS _fonte, 'BRAGA MOTOS YAMAHA POS VENDAS' AS cliente),
    STRUCT('rd-station-sLX1' AS _fonte, 'INFORCELL' AS cliente),
    STRUCT('rd-station-sPoP' AS _fonte, 'MOVE' AS cliente),
    STRUCT('rd-station-uOAA' AS _fonte, 'COMAC' AS cliente),
    STRUCT('rd-station-urW3' AS _fonte, 'BIGAZINE MANAUS' AS cliente),
    STRUCT('rd-station-ypAe' AS _fonte, 'ROYAL ENFIELD' AS cliente),
    STRUCT('rd-station-zxA3' AS _fonte, 'RODRIX' AS cliente)
  ])
),
lp AS (
  SELECT 'LANDING_PAGE' AS tipo_ativo, *, CAST(NULL AS STRING) AS `trigger` FROM (
    SELECT 'rd-station-1boX' AS _fonte, * FROM `vanguardamartech_rd_distribuidora_pneu_forte`.`rd_station_pneu_fortelanding_pages`
    UNION ALL BY NAME SELECT 'rd-station-3k4Z' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_dmello_landing_pages`
    UNION ALL BY NAME SELECT 'rd-station-409D' AS _fonte, * FROM `vanguardamartech_rd_unipar`.`rd_station_uniparlanding_pages`
    UNION ALL BY NAME SELECT 'rd-station-4b7D' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_millennium_shoppinglanding_pages`
    UNION ALL BY NAME SELECT 'rd-station-5KKM' AS _fonte, * FROM `vanguardamartech_rd_arena_tintas`.`rd_station_arena_tintaslanding_pages`
    UNION ALL BY NAME SELECT 'rd-station-5RPi' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_acdisplay_landing_pages`
    UNION ALL BY NAME SELECT 'rd-station-6Ir5' AS _fonte, * FROM `vanguardamartech_rd_braga_veiculos`.`rd_station_braga_veiculos__landing_pages`
    UNION ALL BY NAME SELECT 'rd-station-7K57' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_pneuforte_landing_pages`
    UNION ALL BY NAME SELECT 'rd-station-8Fqy' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_braga_acessorioslanding_pages`
    UNION ALL BY NAME SELECT 'rd-station-9mbj' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_amazoncopy_landing_pages`
    UNION ALL BY NAME SELECT 'rd-station-AqsD' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_openwall_landing_pages`
    UNION ALL BY NAME SELECT 'rd-station-Awhd' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_acesso_saudelanding_pages`
    UNION ALL BY NAME SELECT 'rd-station-CSrx' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_amz_geradoreslanding_pages`
    UNION ALL BY NAME SELECT 'rd-station-CWtQ' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_maravilha_landing_pages`
    UNION ALL BY NAME SELECT 'rd-station-Fzvz' AS _fonte, * FROM `vanguardamartech_rd_doctor_mais_saude`.`rd_station_doctor_mais_saudelanding_pages`
    UNION ALL BY NAME SELECT 'rd-station-HVbj' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_steel_portlanding_pages`
    UNION ALL BY NAME SELECT 'rd-station-HoWi' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_hope_baylanding_pages`
    UNION ALL BY NAME SELECT 'rd-station-IOQX' AS _fonte, * FROM `vanguardamartech_rd_braga_veiculos`.`rd_station_braga_veiculoslanding_pages`
    UNION ALL BY NAME SELECT 'rd-station-L2Sl' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_cabral_landing_pages`
    UNION ALL BY NAME SELECT 'rd-station-MzyH' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_ba_eletricalanding_pages`
    UNION ALL BY NAME SELECT 'rd-station-Ozim' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_kl_rentlanding_pages`
    UNION ALL BY NAME SELECT 'rd-station-POZB' AS _fonte, * FROM `vanguardamartech_rd_caa_aluminio`.`rd_station_caa_aluminiolanding_pages`
    UNION ALL BY NAME SELECT 'rd-station-QcKP' AS _fonte, * FROM `vanguardamartech_rd_station_charao`.`rd_station_charaolanding_pages`
    UNION ALL BY NAME SELECT 'rd-station-STKa' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_hospital_santa_julialanding_pages`
    UNION ALL BY NAME SELECT 'rd-station-Sys9' AS _fonte, * FROM `vanguardamartech_rd_station_shizen`.`rd_station_shizenlanding_pages`
    UNION ALL BY NAME SELECT 'rd-station-VYbu' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_colmeia_landing_pages`
    UNION ALL BY NAME SELECT 'rd-station-WHAa' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_braga_veiculoslanding_pages`
    UNION ALL BY NAME SELECT 'rd-station-YNpj' AS _fonte, * FROM `vanguardamartech_rd_bap`.`rd_station_baplanding_pages`
    UNION ALL BY NAME SELECT 'rd-station-bdVN' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_pmz_landing_pages`
    UNION ALL BY NAME SELECT 'rd-station-c9jU' AS _fonte, * FROM `vanguardamartech_rd_constroi_incorporadora`.`rd_station_constroi_incorporadoralanding_pages`
    UNION ALL BY NAME SELECT 'rd-station-dvZx' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_watches_landing_pages`
    UNION ALL BY NAME SELECT 'rd-station-f2o9' AS _fonte, * FROM `vanguardamartech_rd_station_santo_remedio`.`rd_station_santo_remediolanding_pages`
    UNION ALL BY NAME SELECT 'rd-station-fPd4' AS _fonte, * FROM `vanguardamartech_rd_hage_alimentos`.`rd_station_hage_alimentoslanding_pages`
    UNION ALL BY NAME SELECT 'rd-station-h3u2' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_rei_mangueiraslanding_pages`
    UNION ALL BY NAME SELECT 'rd-station-iJK3' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_vbot_landing_pages`
    UNION ALL BY NAME SELECT 'rd-station-idF7' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_braga_motorslanding_pages`
    UNION ALL BY NAME SELECT 'rd-station-irou' AS _fonte, * FROM `vanguardamartech_rd_station_caa_tintas`.`rd_station_caa_tintaslanding_pages`
    UNION ALL BY NAME SELECT 'rd-station-mEzQ' AS _fonte, * FROM `vanguardamartech_rd_pmz_escola`.`rd_station_pmz_escolalanding_pages`
    UNION ALL BY NAME SELECT 'rd-station-oYKw' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_station_landing_pages`
    UNION ALL BY NAME SELECT 'rd-station-pDLk' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_station_marketinglanding_pages`
    UNION ALL BY NAME SELECT 'rd-station-pG4G' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_best_carlanding_pages`
    UNION ALL BY NAME SELECT 'rd-station-rlmE' AS _fonte, * FROM `vanguardamartech_rd_station_braga_motos`.`rd_station_braga_motoslanding_pages`
    UNION ALL BY NAME SELECT 'rd-station-sLX1' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_infocell_landing_pages`
    UNION ALL BY NAME SELECT 'rd-station-sPoP' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_move_landing_pages`
    UNION ALL BY NAME SELECT 'rd-station-uOAA' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_comac_landing_pages`
    UNION ALL BY NAME SELECT 'rd-station-urW3' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_bigazine_landing_pages`
    UNION ALL BY NAME SELECT 'rd-station-ypAe' AS _fonte, * FROM `vanguardamartech_rd_station_royal_enfield`.`rd_station_royal_enfieldlanding_pages`
    UNION ALL BY NAME SELECT 'rd-station-zxA3' AS _fonte, * FROM `vanguardamartech_rd_rodrix`.`rd_station_rodrixlanding_pages`
  )
),
pp AS (
  SELECT 'POPUP' AS tipo_ativo, *, CAST(NULL AS BOOL) AS has_active_experiment, CAST(NULL AS BOOL) AS had_experiment FROM (
    SELECT 'rd-station-1boX' AS _fonte, * FROM `vanguardamartech_rd_distribuidora_pneu_forte`.`rd_station_pneu_fortepopups`
    UNION ALL BY NAME SELECT 'rd-station-3k4Z' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_dmello_popups`
    UNION ALL BY NAME SELECT 'rd-station-409D' AS _fonte, * FROM `vanguardamartech_rd_unipar`.`rd_station_uniparpopups`
    UNION ALL BY NAME SELECT 'rd-station-4b7D' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_millennium_shoppingpopups`
    UNION ALL BY NAME SELECT 'rd-station-5KKM' AS _fonte, * FROM `vanguardamartech_rd_arena_tintas`.`rd_station_arena_tintaspopups`
    UNION ALL BY NAME SELECT 'rd-station-5RPi' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_acdisplay_popups`
    UNION ALL BY NAME SELECT 'rd-station-6Ir5' AS _fonte, * FROM `vanguardamartech_rd_braga_veiculos`.`rd_station_braga_veiculos__popups`
    UNION ALL BY NAME SELECT 'rd-station-7K57' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_pneuforte_popups`
    UNION ALL BY NAME SELECT 'rd-station-8Fqy' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_braga_acessoriospopups`
    UNION ALL BY NAME SELECT 'rd-station-9mbj' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_amazoncopy_popups`
    UNION ALL BY NAME SELECT 'rd-station-AqsD' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_openwall_popups`
    UNION ALL BY NAME SELECT 'rd-station-Awhd' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_acesso_saudepopups`
    UNION ALL BY NAME SELECT 'rd-station-CSrx' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_amz_geradorespopups`
    UNION ALL BY NAME SELECT 'rd-station-CWtQ' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_maravilha_popups`
    UNION ALL BY NAME SELECT 'rd-station-Fzvz' AS _fonte, * FROM `vanguardamartech_rd_doctor_mais_saude`.`rd_station_doctor_mais_saudepopups`
    UNION ALL BY NAME SELECT 'rd-station-HVbj' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_steel_portpopups`
    UNION ALL BY NAME SELECT 'rd-station-HoWi' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_hope_baypopups`
    UNION ALL BY NAME SELECT 'rd-station-IOQX' AS _fonte, * FROM `vanguardamartech_rd_braga_veiculos`.`rd_station_braga_veiculospopups`
    UNION ALL BY NAME SELECT 'rd-station-L2Sl' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_cabral_popups`
    UNION ALL BY NAME SELECT 'rd-station-MzyH' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_ba_eletricapopups`
    UNION ALL BY NAME SELECT 'rd-station-Ozim' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_kl_rentpopups`
    UNION ALL BY NAME SELECT 'rd-station-POZB' AS _fonte, * FROM `vanguardamartech_rd_caa_aluminio`.`rd_station_caa_aluminiopopups`
    UNION ALL BY NAME SELECT 'rd-station-QcKP' AS _fonte, * FROM `vanguardamartech_rd_station_charao`.`rd_station_charaopopups`
    UNION ALL BY NAME SELECT 'rd-station-STKa' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_hospital_santa_juliapopups`
    UNION ALL BY NAME SELECT 'rd-station-Sys9' AS _fonte, * FROM `vanguardamartech_rd_station_shizen`.`rd_station_shizenpopups`
    UNION ALL BY NAME SELECT 'rd-station-VYbu' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_colmeia_popups`
    UNION ALL BY NAME SELECT 'rd-station-WHAa' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_braga_veiculospopups`
    UNION ALL BY NAME SELECT 'rd-station-YNpj' AS _fonte, * FROM `vanguardamartech_rd_bap`.`rd_station_bappopups`
    UNION ALL BY NAME SELECT 'rd-station-bdVN' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_pmz_popups`
    UNION ALL BY NAME SELECT 'rd-station-c9jU' AS _fonte, * FROM `vanguardamartech_rd_constroi_incorporadora`.`rd_station_constroi_incorporadorapopups`
    UNION ALL BY NAME SELECT 'rd-station-dvZx' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_watches_popups`
    UNION ALL BY NAME SELECT 'rd-station-f2o9' AS _fonte, * FROM `vanguardamartech_rd_station_santo_remedio`.`rd_station_santo_remediopopups`
    UNION ALL BY NAME SELECT 'rd-station-fPd4' AS _fonte, * FROM `vanguardamartech_rd_hage_alimentos`.`rd_station_hage_alimentospopups`
    UNION ALL BY NAME SELECT 'rd-station-h3u2' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_rei_mangueiraspopups`
    UNION ALL BY NAME SELECT 'rd-station-iJK3' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_vbot_popups`
    UNION ALL BY NAME SELECT 'rd-station-idF7' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_braga_motorspopups`
    UNION ALL BY NAME SELECT 'rd-station-irou' AS _fonte, * FROM `vanguardamartech_rd_station_caa_tintas`.`rd_station_caa_tintaspopups`
    UNION ALL BY NAME SELECT 'rd-station-mEzQ' AS _fonte, * FROM `vanguardamartech_rd_pmz_escola`.`rd_station_pmz_escolapopups`
    UNION ALL BY NAME SELECT 'rd-station-oYKw' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_station_popups`
    UNION ALL BY NAME SELECT 'rd-station-pDLk' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_station_marketingpopups`
    UNION ALL BY NAME SELECT 'rd-station-pG4G' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_best_carpopups`
    UNION ALL BY NAME SELECT 'rd-station-rlmE' AS _fonte, * FROM `vanguardamartech_rd_station_braga_motos`.`rd_station_braga_motospopups`
    UNION ALL BY NAME SELECT 'rd-station-sLX1' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_infocell_popups`
    UNION ALL BY NAME SELECT 'rd-station-sPoP' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_move_popups`
    UNION ALL BY NAME SELECT 'rd-station-uOAA' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_comac_popups`
    UNION ALL BY NAME SELECT 'rd-station-urW3' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_bigazine_popups`
    UNION ALL BY NAME SELECT 'rd-station-ypAe' AS _fonte, * FROM `vanguardamartech_rd_station_royal_enfield`.`rd_station_royal_enfieldpopups`
    UNION ALL BY NAME SELECT 'rd-station-zxA3' AS _fonte, * FROM `vanguardamartech_rd_rodrix`.`rd_station_rodrixpopups`
  )
),
eb AS (
  SELECT 'FORMULARIO_EMBUTIDO' AS tipo_ativo, *, CAST(NULL AS STRING) AS `trigger`, CAST(NULL AS BOOL) AS has_active_experiment, CAST(NULL AS BOOL) AS had_experiment FROM (
    SELECT 'rd-station-1boX' AS _fonte, * FROM `vanguardamartech_rd_distribuidora_pneu_forte`.`rd_station_pneu_forteembeddables`
    UNION ALL BY NAME SELECT 'rd-station-3k4Z' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_dmello_embeddables`
    UNION ALL BY NAME SELECT 'rd-station-409D' AS _fonte, * FROM `vanguardamartech_rd_unipar`.`rd_station_uniparembeddables`
    UNION ALL BY NAME SELECT 'rd-station-4b7D' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_millennium_shoppingembeddables`
    UNION ALL BY NAME SELECT 'rd-station-5KKM' AS _fonte, * FROM `vanguardamartech_rd_arena_tintas`.`rd_station_arena_tintasembeddables`
    UNION ALL BY NAME SELECT 'rd-station-5RPi' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_acdisplay_embeddables`
    UNION ALL BY NAME SELECT 'rd-station-6Ir5' AS _fonte, * FROM `vanguardamartech_rd_braga_veiculos`.`rd_station_braga_veiculos__embeddables`
    UNION ALL BY NAME SELECT 'rd-station-7K57' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_pneuforte_embeddables`
    UNION ALL BY NAME SELECT 'rd-station-8Fqy' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_braga_acessoriosembeddables`
    UNION ALL BY NAME SELECT 'rd-station-9mbj' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_amazoncopy_embeddables`
    UNION ALL BY NAME SELECT 'rd-station-AqsD' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_openwall_embeddables`
    UNION ALL BY NAME SELECT 'rd-station-Awhd' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_acesso_saudeembeddables`
    UNION ALL BY NAME SELECT 'rd-station-CSrx' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_amz_geradoresembeddables`
    UNION ALL BY NAME SELECT 'rd-station-CWtQ' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_maravilha_embeddables`
    UNION ALL BY NAME SELECT 'rd-station-Fzvz' AS _fonte, * FROM `vanguardamartech_rd_doctor_mais_saude`.`rd_station_doctor_mais_saudeembeddables`
    UNION ALL BY NAME SELECT 'rd-station-HVbj' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_steel_portembeddables`
    UNION ALL BY NAME SELECT 'rd-station-HoWi' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_hope_bayembeddables`
    UNION ALL BY NAME SELECT 'rd-station-IOQX' AS _fonte, * FROM `vanguardamartech_rd_braga_veiculos`.`rd_station_braga_veiculosembeddables`
    UNION ALL BY NAME SELECT 'rd-station-L2Sl' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_cabral_embeddables`
    UNION ALL BY NAME SELECT 'rd-station-MzyH' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_ba_eletricaembeddables`
    UNION ALL BY NAME SELECT 'rd-station-Ozim' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_kl_rentembeddables`
    UNION ALL BY NAME SELECT 'rd-station-POZB' AS _fonte, * FROM `vanguardamartech_rd_caa_aluminio`.`rd_station_caa_aluminioembeddables`
    UNION ALL BY NAME SELECT 'rd-station-QcKP' AS _fonte, * FROM `vanguardamartech_rd_station_charao`.`rd_station_charaoembeddables`
    UNION ALL BY NAME SELECT 'rd-station-STKa' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_hospital_santa_juliaembeddables`
    UNION ALL BY NAME SELECT 'rd-station-Sys9' AS _fonte, * FROM `vanguardamartech_rd_station_shizen`.`rd_station_shizenembeddables`
    UNION ALL BY NAME SELECT 'rd-station-VYbu' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_colmeia_embeddables`
    UNION ALL BY NAME SELECT 'rd-station-WHAa' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_braga_veiculosembeddables`
    UNION ALL BY NAME SELECT 'rd-station-YNpj' AS _fonte, * FROM `vanguardamartech_rd_bap`.`rd_station_bapembeddables`
    UNION ALL BY NAME SELECT 'rd-station-bdVN' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_pmz_embeddables`
    UNION ALL BY NAME SELECT 'rd-station-c9jU' AS _fonte, * FROM `vanguardamartech_rd_constroi_incorporadora`.`rd_station_constroi_incorporadoraembeddables`
    UNION ALL BY NAME SELECT 'rd-station-dvZx' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_watches_embeddables`
    UNION ALL BY NAME SELECT 'rd-station-f2o9' AS _fonte, * FROM `vanguardamartech_rd_station_santo_remedio`.`rd_station_santo_remedioembeddables`
    UNION ALL BY NAME SELECT 'rd-station-fPd4' AS _fonte, * FROM `vanguardamartech_rd_hage_alimentos`.`rd_station_hage_alimentosembeddables`
    UNION ALL BY NAME SELECT 'rd-station-h3u2' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_rei_mangueirasembeddables`
    UNION ALL BY NAME SELECT 'rd-station-iJK3' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_vbot_embeddables`
    UNION ALL BY NAME SELECT 'rd-station-idF7' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_braga_motorsembeddables`
    UNION ALL BY NAME SELECT 'rd-station-irou' AS _fonte, * FROM `vanguardamartech_rd_station_caa_tintas`.`rd_station_caa_tintasembeddables`
    UNION ALL BY NAME SELECT 'rd-station-mEzQ' AS _fonte, * FROM `vanguardamartech_rd_pmz_escola`.`rd_station_pmz_escolaembeddables`
    UNION ALL BY NAME SELECT 'rd-station-oYKw' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_station_embeddables`
    UNION ALL BY NAME SELECT 'rd-station-pDLk' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_station_marketingembeddables`
    UNION ALL BY NAME SELECT 'rd-station-pG4G' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_best_carembeddables`
    UNION ALL BY NAME SELECT 'rd-station-rlmE' AS _fonte, * FROM `vanguardamartech_rd_station_braga_motos`.`rd_station_braga_motosembeddables`
    UNION ALL BY NAME SELECT 'rd-station-sLX1' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_infocell_embeddables`
    UNION ALL BY NAME SELECT 'rd-station-sPoP' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_move_embeddables`
    UNION ALL BY NAME SELECT 'rd-station-uOAA' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_comac_embeddables`
    UNION ALL BY NAME SELECT 'rd-station-urW3' AS _fonte, * FROM `vanguardamartech_rd_marketing`.`rd_bigazine_embeddables`
    UNION ALL BY NAME SELECT 'rd-station-ypAe' AS _fonte, * FROM `vanguardamartech_rd_station_royal_enfield`.`rd_station_royal_enfieldembeddables`
    UNION ALL BY NAME SELECT 'rd-station-zxA3' AS _fonte, * FROM `vanguardamartech_rd_rodrix`.`rd_station_rodrixembeddables`
  )
),
u AS (
  SELECT * FROM lp
  UNION ALL BY NAME SELECT * FROM pp
  UNION ALL BY NAME SELECT * FROM eb
),
base AS (
  SELECT u.*, c.cliente, TO_HEX(MD5(TO_JSON_STRING(u))) AS _payload_hash
  FROM u LEFT JOIN cli c USING (_fonte)
  QUALIFY ROW_NUMBER() OVER (PARTITION BY _fonte, tipo_ativo, CAST(id AS STRING) ORDER BY updated_at DESC) = 1
),
t AS (
SELECT
  CONCAT(_fonte,'|',tipo_ativo,'|',CAST(id AS STRING)) AS id_ativo_captura,
  _fonte,
  cliente,
  tipo_ativo,
  CAST(id AS STRING) AS id_ativo_origem,
  NULLIF(TRIM(title),'') AS titulo,
  NULLIF(TRIM(conversion_identifier),'') AS identificador_conversao,
  NULLIF(TRIM(status),'') AS status_ativo,
  DATETIME(SAFE_CAST(created_at AS TIMESTAMP),'America/Sao_Paulo') AS criado_em,
  DATETIME(SAFE_CAST(updated_at AS TIMESTAMP),'America/Sao_Paulo') AS atualizado_em,
  NULLIF(TRIM(`trigger`),'') AS gatilho_popup,
  has_active_experiment AS is_experimento_ativo,
  had_experiment AS is_teve_experimento,
  COUNT(DISTINCT _fonte) OVER (PARTITION BY tipo_ativo, CAST(id AS STRING)) AS qtd_fontes_do_ativo,
  (COUNT(DISTINCT _fonte) OVER (PARTITION BY tipo_ativo, CAST(id AS STRING)) > 1) AS flag_ativo_em_mais_de_uma_fonte,
  CURRENT_TIMESTAMP() AS _extraido_at,
  _payload_hash
FROM base
)
SELECT * FROM t
