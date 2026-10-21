-- trs_facebook_ads__criativo
-- Trusted Facebook Ads. Grao: um CRIATIVO. Chave: (id_conta, id_criativo). O elo criativo -> anuncios esta em trs_facebook_ads__anuncio.id_criativo.
-- Fonte: stream `creatives` das 64 fontes facebook-ads-*. Nivel L3 CONFIDENTIAL: titulo, corpo e nome do criativo sao TEXTO DE MARCA/TERCEIROS
-- e a URL de destino pode carregar parametros de campanha. NADA disso atravessa para a Refined.
-- Criado em 2026-10-18.
-- FONTES (64, as mesmas da trs_facebook_ads__insight_diario / __campanha): 7 antigas + 57 novas, camada por conta (R-001).
-- Prefixo de tabela e camada vem do CATALOGO, nunca deduzido (kQ2S/GWZ2 dividem a camada vanguardamartech_braga_veiculos com prefixos
-- facebook_ads_braga* e facebook_ads_braga_*; a Japura GZtZ usa camada vanguardamartech_japura_pneus_facebook e prefixo facebook_ads_japura_pneus).
-- Padrao compacto: SELECT '<slug>' AS _fonte, * por ramo; colunas nomeadas UMA vez na CTE base (query grande demais nao se conserta).
-- Esquema identico nas 64 tabelas verificado por execucao da uniao em 2026-10-18.
-- Gatilho: cron terca 13:35 America/Manaus, o mesmo das Trusted Meta (query-QXqC / query-7aLj). Le so Raw: pode rodar em paralelo com elas.
--
-- id_anuncio_origem e o `ad_id` que o conector anexa ao criativo (o anuncio por onde ele foi lido), NAO a lista de anuncios que o usam:
-- varios anuncios podem apontar para o mesmo criativo (ads.creative.id), e o conjunto fiel esta em trs_facebook_ads__anuncio.
-- DEDUPLICACAO: fica a versao de maior ad_updated_time (TIMESTAMP).
-- Campos mortos NAO emitidos (medidos nulos em 5.524 criativos de 5 contas): image_url, thumbnail_url, video_id, object_story_id,
-- effective_object_story_id, instagram_permalink_url, url_tags, image_hash. A midia do criativo NAO esta nesta extracao.
-- Sentinela: titulo " " (um espaco) existe na origem -> NULL via NULLIF(TRIM()).
WITH uniao_raw AS (
  SELECT 'facebook-ads-Si4U' AS _fonte, * FROM `vanguardamartech_acesso_saude`.`facebook_ads__acesso_saudecreatives` UNION ALL
  SELECT 'facebook-ads-kQ2S' AS _fonte, * FROM `vanguardamartech_braga_veiculos`.`facebook_ads_bragacreatives` UNION ALL
  SELECT 'facebook-ads-GWZ2' AS _fonte, * FROM `vanguardamartech_braga_veiculos`.`facebook_ads_braga_creatives` UNION ALL
  SELECT 'facebook-ads-x4yO' AS _fonte, * FROM `vanguardamartech_pmz_loja`.`facebook_ads_pmz_lojacreatives` UNION ALL
  SELECT 'facebook-ads-ln1a' AS _fonte, * FROM `vanguardamartech_colmeia`.`facebook_ads_colmeiacreatives` UNION ALL
  SELECT 'facebook-ads-E9RT' AS _fonte, * FROM `vanguardamartech_best_car`.`facebook_ads_best_carcreatives` UNION ALL
  SELECT 'facebook-ads-oB7d' AS _fonte, * FROM `vanguardamartech_constroi_incorporadora`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-8RYU' AS _fonte, * FROM `vanguardamartech_ca_braga_veiculos_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-ezGP' AS _fonte, * FROM `vanguardamartech_ca_braga_motos_rey_mao_royal_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-b8KQ' AS _fonte, * FROM `vanguardamartech_neo_vila_adrianopolis_empreendimento_ads_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-rCHw' AS _fonte, * FROM `vanguardamartech_acesso_saude_manoa_2_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-CebU' AS _fonte, * FROM `vanguardamartech_ca_braga_veiculos_venda_direta_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-jZBq' AS _fonte, * FROM `vanguardamartech_parque_das_torres_ads_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-5eAs' AS _fonte, * FROM `vanguardamartech_ca_inforcell_oficial_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-aghZ' AS _fonte, * FROM `vanguardamartech_amazoncopy_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-Vgli' AS _fonte, * FROM `vanguardamartech_pmz_grupo_ecomm_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-WQmP' AS _fonte, * FROM `vanguardamartech_caa_aluminio_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-nCGL' AS _fonte, * FROM `vanguardamartech_amz_geradores_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-K2kh' AS _fonte, * FROM `vanguardamartech_caa_tintas_express_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-TAqE' AS _fonte, * FROM `vanguardamartech_animativ_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-omn8' AS _fonte, * FROM `vanguardamartech_arena_tintas_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-2vvw' AS _fonte, * FROM `vanguardamartech_pneu_express_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-tzO2' AS _fonte, * FROM `vanguardamartech_cabral_v2_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-s8I1' AS _fonte, * FROM `vanguardamartech_pneu_forte_distribuidora_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-oVkz' AS _fonte, * FROM `vanguardamartech_cdl_manaus_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-phtv' AS _fonte, * FROM `vanguardamartech_pneu_forte_varejo_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-rPr1' AS _fonte, * FROM `vanguardamartech_comac_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-p8vg' AS _fonte, * FROM `vanguardamartech_rei_das_mangueiras_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-ofJE' AS _fonte, * FROM `vanguardamartech_consorcio_chevrolet_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-aiXX' AS _fonte, * FROM `vanguardamartech_residencial_boa_vista_ads_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-ZYCB' AS _fonte, * FROM `vanguardamartech_deb_transportes_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-Hr6d' AS _fonte, * FROM `vanguardamartech_ba_eletrica_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-oaSa' AS _fonte, * FROM `vanguardamartech_best_car_2026_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-tWUr' AS _fonte, * FROM `vanguardamartech_bigazine_boleto_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-d1nc' AS _fonte, * FROM `vanguardamartech_rodrix_motos_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-Eo68' AS _fonte, * FROM `vanguardamartech_don_watches_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-SGls' AS _fonte, * FROM `vanguardamartech_braga_motors_carro_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-lDmk' AS _fonte, * FROM `vanguardamartech_dr_cabral_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-Ew4q' AS _fonte, * FROM `vanguardamartech_braga_motors_mini_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-oih2' AS _fonte, * FROM `vanguardamartech_escola_para_mecanicos_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-lk1y' AS _fonte, * FROM `vanguardamartech_braga_motors_motorrad_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-cETo' AS _fonte, * FROM `vanguardamartech_c_a02_cabral_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-mtAO' AS _fonte, * FROM `vanguardamartech_ca1_move_rental_cars_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-pbon' AS _fonte, * FROM `vanguardamartech_grupo_hage_alimentos_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-4Q1U' AS _fonte, * FROM `vanguardamartech_smile_pneus_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-DtiV' AS _fonte, * FROM `vanguardamartech_hospital_santa_julia_ads_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-yFhV' AS _fonte, * FROM `vanguardamartech_steel_port_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-Uu0D' AS _fonte, * FROM `vanguardamartech_kiffer_ads_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-0rrE' AS _fonte, * FROM `vanguardamartech_therezinha_ruiz_eleicao_2026_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-sHYk' AS _fonte, * FROM `vanguardamartech_leapmotor_via_marconi_manaus_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-bIVn' AS _fonte, * FROM `vanguardamartech_therezinha_ruiz_pre_campanha_2026_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-3vys' AS _fonte, * FROM `vanguardamartech_tropical_multiloja_ativo_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-xohe' AS _fonte, * FROM `vanguardamartech_ca_artrin_importadora_02_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-Tqjf' AS _fonte, * FROM `vanguardamartech_ca_braga_acessorios_mao_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-ckhA' AS _fonte, * FROM `vanguardamartech_ca_braga_consorcios_mao_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-smxd' AS _fonte, * FROM `vanguardamartech_ca_braga_motos_pos_vendas_mao_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-elFk' AS _fonte, * FROM `vanguardamartech_leapmotor_vm_i_reserva_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-VJeY' AS _fonte, * FROM `vanguardamartech_unipar_ads_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-AJ09' AS _fonte, * FROM `vanguardamartech_vanguarda_comunicacao_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-KBUT' AS _fonte, * FROM `vanguardamartech_vbot_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-hIaw' AS _fonte, * FROM `vanguardamartech_millennium_ads_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-7NkZ' AS _fonte, * FROM `vanguardamartech_vega_bajaj_manaus_am_anuncios_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-I8ld' AS _fonte, * FROM `vanguardamartech_voike_ads_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT 'facebook-ads-GZtZ' AS _fonte, * FROM `vanguardamartech_japura_pneus_facebook`.`facebook_ads_japura_pneuscreatives`
),

base AS (
  SELECT
    u._fonte,
    u.id                                              AS id_criativo,
    u.account_id                                      AS id_conta,
    u.ad_id                                           AS id_anuncio_origem,
    u.actor_id                                        AS id_pagina,
    NULLIF(TRIM(u.name), '')                          AS nome_criativo,
    u.object_type                                     AS tipo_objeto,
    u.status,
    NULLIF(TRIM(u.title), '')                         AS titulo,
    NULLIF(TRIM(u.body), '')                          AS corpo,
    u.call_to_action_type                             AS tipo_cta,
    NULLIF(TRIM(u.destination_url), '')               AS url_destino,
    NULLIF(TRIM(u.link_url), '')                      AS url_link,
    u.destination_type                                AS tipo_destino,
    u.ad_updated_time                                 AS atualizado_utc,
    TO_HEX(MD5(TO_JSON_STRING((SELECT AS STRUCT u.* EXCEPT (_fonte))))) AS _payload_hash,
    COUNT(*) OVER (PARTITION BY u.account_id, u.id)   AS qtd_versoes_na_origem
  FROM uniao_raw u
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY u.account_id, u.id
    ORDER BY u.ad_updated_time DESC, u._fonte
  ) = 1
)

SELECT
  b.id_criativo,
  b.id_conta,
  b.id_anuncio_origem,
  b.id_pagina,
  b.nome_criativo,
  b.tipo_objeto,
  b.status,
  b.titulo,
  b.corpo,
  b.tipo_cta,
  b.url_destino,
  b.url_link,
  b.tipo_destino,
  (b.titulo IS NOT NULL)                              AS tem_titulo,
  (b.corpo IS NOT NULL)                               AS tem_corpo,
  (b.tipo_cta IS NOT NULL)                            AS tem_cta,
  (b.url_destino IS NOT NULL OR b.url_link IS NOT NULL) AS tem_url,
  CHAR_LENGTH(b.corpo)                                AS qtd_caracteres_corpo,
  CHAR_LENGTH(b.titulo)                               AS qtd_caracteres_titulo,
  DATETIME(b.atualizado_utc, 'America/Sao_Paulo')     AS atualizado_em,
  b.qtd_versoes_na_origem,
  CURRENT_TIMESTAMP()                                 AS _extraido_at,
  b._fonte,
  b._payload_hash
FROM base b
