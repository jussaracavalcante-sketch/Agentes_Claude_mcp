-- trs_facebook_ads__video (query Trusted, camada Trusted Facebook Ads) - 2026-10-18
-- Grao: um video da biblioteca de uma conta de anuncio. Chave (_fonte, id_video). Nivel L2.
-- 68 fontes facebook-ads com tabela advideos materializada (56 com linha). Padrao compacto
-- SELECT '<slug>' AS _fonte, * FROM <tabela>. id_conta vem do MAPA fonte->conta: account_id e NULL em 100% da origem.
-- source (URL assinada), embed_html, icon e format (miniaturas) NAO sao emitidos. Colunas mortas na origem ficam fora.
WITH raw AS (
SELECT 'facebook-ads-Si4U' AS _fonte, * FROM `vanguardamartech_acesso_saude`.`facebook_ads__acesso_saudeadvideos` UNION ALL
SELECT 'facebook-ads-kQ2S' AS _fonte, * FROM `vanguardamartech_braga_veiculos`.`facebook_ads_bragaadvideos` UNION ALL
SELECT 'facebook-ads-GWZ2' AS _fonte, * FROM `vanguardamartech_braga_veiculos`.`facebook_ads_braga_advideos` UNION ALL
SELECT 'facebook-ads-x4yO' AS _fonte, * FROM `vanguardamartech_pmz_loja`.`facebook_ads_pmz_lojaadvideos` UNION ALL
SELECT 'facebook-ads-ln1a' AS _fonte, * FROM `vanguardamartech_colmeia`.`facebook_ads_colmeiaadvideos` UNION ALL
SELECT 'facebook-ads-E9RT' AS _fonte, * FROM `vanguardamartech_best_car`.`facebook_ads_best_caradvideos` UNION ALL
SELECT 'facebook-ads-oB7d' AS _fonte, * FROM `vanguardamartech_constroi_incorporadora`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-8RYU' AS _fonte, * FROM `vanguardamartech_ca_braga_veiculos_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-ezGP' AS _fonte, * FROM `vanguardamartech_ca_braga_motos_rey_mao_royal_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-b8KQ' AS _fonte, * FROM `vanguardamartech_neo_vila_adrianopolis_empreendimento_ads_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-rCHw' AS _fonte, * FROM `vanguardamartech_acesso_saude_manoa_2_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-CebU' AS _fonte, * FROM `vanguardamartech_ca_braga_veiculos_venda_direta_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-jZBq' AS _fonte, * FROM `vanguardamartech_parque_das_torres_ads_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-5eAs' AS _fonte, * FROM `vanguardamartech_ca_inforcell_oficial_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-aghZ' AS _fonte, * FROM `vanguardamartech_amazoncopy_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-Vgli' AS _fonte, * FROM `vanguardamartech_pmz_grupo_ecomm_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-WQmP' AS _fonte, * FROM `vanguardamartech_caa_aluminio_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-nCGL' AS _fonte, * FROM `vanguardamartech_amz_geradores_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-K2kh' AS _fonte, * FROM `vanguardamartech_caa_tintas_express_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-TAqE' AS _fonte, * FROM `vanguardamartech_animativ_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-omn8' AS _fonte, * FROM `vanguardamartech_arena_tintas_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-2vvw' AS _fonte, * FROM `vanguardamartech_pneu_express_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-tzO2' AS _fonte, * FROM `vanguardamartech_cabral_v2_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-s8I1' AS _fonte, * FROM `vanguardamartech_pneu_forte_distribuidora_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-oVkz' AS _fonte, * FROM `vanguardamartech_cdl_manaus_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-phtv' AS _fonte, * FROM `vanguardamartech_pneu_forte_varejo_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-rPr1' AS _fonte, * FROM `vanguardamartech_comac_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-p8vg' AS _fonte, * FROM `vanguardamartech_rei_das_mangueiras_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-ofJE' AS _fonte, * FROM `vanguardamartech_consorcio_chevrolet_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-aiXX' AS _fonte, * FROM `vanguardamartech_residencial_boa_vista_ads_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-ZYCB' AS _fonte, * FROM `vanguardamartech_deb_transportes_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-Hr6d' AS _fonte, * FROM `vanguardamartech_ba_eletrica_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-oaSa' AS _fonte, * FROM `vanguardamartech_best_car_2026_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-tWUr' AS _fonte, * FROM `vanguardamartech_bigazine_boleto_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-d1nc' AS _fonte, * FROM `vanguardamartech_rodrix_motos_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-Eo68' AS _fonte, * FROM `vanguardamartech_don_watches_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-SGls' AS _fonte, * FROM `vanguardamartech_braga_motors_carro_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-lDmk' AS _fonte, * FROM `vanguardamartech_dr_cabral_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-Ew4q' AS _fonte, * FROM `vanguardamartech_braga_motors_mini_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-oih2' AS _fonte, * FROM `vanguardamartech_escola_para_mecanicos_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-lk1y' AS _fonte, * FROM `vanguardamartech_braga_motors_motorrad_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-cETo' AS _fonte, * FROM `vanguardamartech_c_a02_cabral_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-mtAO' AS _fonte, * FROM `vanguardamartech_ca1_move_rental_cars_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-pbon' AS _fonte, * FROM `vanguardamartech_grupo_hage_alimentos_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-4Q1U' AS _fonte, * FROM `vanguardamartech_smile_pneus_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-DtiV' AS _fonte, * FROM `vanguardamartech_hospital_santa_julia_ads_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-yFhV' AS _fonte, * FROM `vanguardamartech_steel_port_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-Uu0D' AS _fonte, * FROM `vanguardamartech_kiffer_ads_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-0rrE' AS _fonte, * FROM `vanguardamartech_therezinha_ruiz_eleicao_2026_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-sHYk' AS _fonte, * FROM `vanguardamartech_leapmotor_via_marconi_manaus_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-bIVn' AS _fonte, * FROM `vanguardamartech_therezinha_ruiz_pre_campanha_2026_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-3vys' AS _fonte, * FROM `vanguardamartech_tropical_multiloja_ativo_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-xohe' AS _fonte, * FROM `vanguardamartech_ca_artrin_importadora_02_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-Tqjf' AS _fonte, * FROM `vanguardamartech_ca_braga_acessorios_mao_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-ckhA' AS _fonte, * FROM `vanguardamartech_ca_braga_consorcios_mao_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-smxd' AS _fonte, * FROM `vanguardamartech_ca_braga_motos_pos_vendas_mao_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-elFk' AS _fonte, * FROM `vanguardamartech_leapmotor_vm_i_reserva_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-VJeY' AS _fonte, * FROM `vanguardamartech_unipar_ads_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-AJ09' AS _fonte, * FROM `vanguardamartech_vanguarda_comunicacao_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-KBUT' AS _fonte, * FROM `vanguardamartech_vbot_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-hIaw' AS _fonte, * FROM `vanguardamartech_millennium_ads_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-7NkZ' AS _fonte, * FROM `vanguardamartech_vega_bajaj_manaus_am_anuncios_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-I8ld' AS _fonte, * FROM `vanguardamartech_voike_ads_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-GZtZ' AS _fonte, * FROM `vanguardamartech_japura_pneus_facebook`.`facebook_ads_japura_pneusadvideos` UNION ALL
SELECT 'facebook-ads-T0qp' AS _fonte, * FROM `vanguardamartech_ca2_move_rental_cars_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-fK2P' AS _fonte, * FROM `vanguardamartech_millennium_shopping_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-WOOU' AS _fonte, * FROM `vanguardamartech_acesso_saude_manoa_1_fb_ads`.`facebook_ads_advideos` UNION ALL
SELECT 'facebook-ads-wZuX' AS _fonte, * FROM `vanguardamartech_auto_master_consorcio_fb_ads`.`facebook_ads_advideos`
),

mapa AS (
  SELECT _fonte, id_conta FROM UNNEST([STRUCT<_fonte STRING, id_conta STRING>
    ('facebook-ads-Si4U','261401095311098'),
    ('facebook-ads-kQ2S','1966625676863140'),
    ('facebook-ads-GWZ2','1172209193972759'),
    ('facebook-ads-x4yO','839811160322414'),
    ('facebook-ads-ln1a','781268383219049'),
    ('facebook-ads-E9RT','235333404360431'),
    ('facebook-ads-oB7d','526683429550109'),
    ('facebook-ads-8RYU','283877416196277'),
    ('facebook-ads-ezGP','448596103793051'),
    ('facebook-ads-b8KQ','961762058045583'),
    ('facebook-ads-rCHw','896593304615891'),
    ('facebook-ads-CebU','1578951605973326'),
    ('facebook-ads-jZBq','1284883625966129'),
    ('facebook-ads-5eAs','1880827672299516'),
    ('facebook-ads-aghZ','233965209271674'),
    ('facebook-ads-Vgli','143457285456847'),
    ('facebook-ads-WQmP','3384094671807625'),
    ('facebook-ads-nCGL','747929494239769'),
    ('facebook-ads-K2kh','1439421523351648'),
    ('facebook-ads-TAqE','202711331653880'),
    ('facebook-ads-omn8','816285708835072'),
    ('facebook-ads-2vvw','3540348596114929'),
    ('facebook-ads-tzO2','1487130863198154'),
    ('facebook-ads-s8I1','1725052584888400'),
    ('facebook-ads-oVkz','474967098302512'),
    ('facebook-ads-phtv','1813722919392589'),
    ('facebook-ads-rPr1','180454263287280'),
    ('facebook-ads-p8vg','237569707262055'),
    ('facebook-ads-ofJE','291639228868958'),
    ('facebook-ads-aiXX','564917637883768'),
    ('facebook-ads-ZYCB','832836096530236'),
    ('facebook-ads-Hr6d','1158280847839524'),
    ('facebook-ads-oaSa','898300194464871'),
    ('facebook-ads-tWUr','206891331753918'),
    ('facebook-ads-d1nc','662144331563252'),
    ('facebook-ads-Eo68','994469323496741'),
    ('facebook-ads-SGls','566562488446148'),
    ('facebook-ads-lDmk','352441942346792'),
    ('facebook-ads-Ew4q','1882475891963192'),
    ('facebook-ads-oih2','479374257875979'),
    ('facebook-ads-lk1y','463307521829322'),
    ('facebook-ads-cETo','2308478406292886'),
    ('facebook-ads-mtAO','541763807067071'),
    ('facebook-ads-pbon','971212355687773'),
    ('facebook-ads-4Q1U','677441165029092'),
    ('facebook-ads-DtiV','100906227323525'),
    ('facebook-ads-yFhV','4405131369708792'),
    ('facebook-ads-Uu0D','2368278856934990'),
    ('facebook-ads-0rrE','2515845012216186'),
    ('facebook-ads-sHYk','1123326336575814'),
    ('facebook-ads-bIVn','27237448115886959'),
    ('facebook-ads-3vys','344479402907345'),
    ('facebook-ads-xohe','3407674766139167'),
    ('facebook-ads-Tqjf','1899695863819525'),
    ('facebook-ads-ckhA','903840726905396'),
    ('facebook-ads-smxd','809512766265620'),
    ('facebook-ads-elFk','1380362517366530'),
    ('facebook-ads-VJeY','225015789229106'),
    ('facebook-ads-AJ09','118981485594379'),
    ('facebook-ads-KBUT','1238815311536448'),
    ('facebook-ads-hIaw','1397293557166269'),
    ('facebook-ads-7NkZ','1322682162728929'),
    ('facebook-ads-I8ld','895774876249896'),
    ('facebook-ads-GZtZ','728255493211287'),
    ('facebook-ads-T0qp','621150572624160'),
    ('facebook-ads-fK2P','2273026959377962'),
    ('facebook-ads-WOOU','157551716528324'),
    ('facebook-ads-wZuX','1305469349867466')
  ])
),

base AS (
  SELECT
    r._fonte,
    r.id                                          AS id_video,
    m.id_conta,
    NULLIF(TRIM(r.title), '')                     AS titulo,
    SAFE_CAST(r.created_time AS TIMESTAMP)        AS criado_utc,
    SAFE_CAST(r.updated_time AS TIMESTAMP)        AS atualizado_utc,
    r.length                                      AS duracao_seg,
    r.views                                       AS visualizacoes,
    r.post_views                                  AS visualizacoes_post,
    r.embeddable                                  AS is_incorporavel,
    r.is_crosspost_video                          AS is_crosspost,
    r.is_crossposting_eligible                    AS is_elegivel_crosspost,
    r.is_episode                                  AS is_episodio,
    r.is_instagram_eligible                       AS is_elegivel_instagram,
    r.permalink_url                               AS permalink_relativo,
    ARRAY_LENGTH(r.format)                        AS qtd_formatos,
    (SELECT f.width  FROM UNNEST(r.format) f WHERE f.filter = 'native' LIMIT 1) AS largura_nativa,
    (SELECT f.height FROM UNNEST(r.format) f WHERE f.filter = 'native' LIMIT 1) AS altura_nativa,
    TO_HEX(MD5(TO_JSON_STRING((SELECT AS STRUCT r.* EXCEPT (_fonte, `source`, embed_html, icon, `format`))))) AS _payload_hash
  FROM raw r
  LEFT JOIN mapa m USING (_fonte)
),

final AS (
  SELECT
    b._fonte, b.id_video, b.id_conta,
    b.titulo,
    b.criado_utc, b.atualizado_utc,
    DATETIME(b.criado_utc,     'America/Sao_Paulo') AS criado_em,
    DATETIME(b.atualizado_utc, 'America/Sao_Paulo') AS atualizado_em,
    b.duracao_seg, b.visualizacoes, b.visualizacoes_post,
    b.is_incorporavel, b.is_crosspost, b.is_elegivel_crosspost, b.is_episodio, b.is_elegivel_instagram,
    b.permalink_relativo,
    b.qtd_formatos, b.largura_nativa, b.altura_nativa,
    COUNT(*) OVER (PARTITION BY b._fonte, b.id_video) AS qtd_linhas_na_origem,
    CURRENT_TIMESTAMP()                             AS _extraido_at,
    b._payload_hash
  FROM base b
  QUALIFY ROW_NUMBER() OVER (PARTITION BY b._fonte, b.id_video ORDER BY b.atualizado_utc DESC, b._payload_hash) = 1
)

SELECT * FROM final