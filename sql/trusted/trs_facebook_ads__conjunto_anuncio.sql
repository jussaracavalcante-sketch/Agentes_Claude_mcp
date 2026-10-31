-- trs_facebook_ads__conjunto_anuncio
-- Trusted Facebook Ads. Grao: um CONJUNTO DE ANUNCIOS. Chave: (id_conta, id_conjunto).
-- Fonte: stream `adsets` das 65 fontes facebook-ads-* com linhas (a rCHw, Acesso Saude manoa 2, tem a tabela com ZERO linhas em 2026-10-18 e fica de fora).
-- Nivel L2 INTERNAL: segmentacao agregada em contagens e ids; NOMES de publicos personalizados e de interesses NAO sao emitidos.
-- Criado em 2026-10-18.
-- 2026-10-29: somadas facebook-ads-tWIP (FARMABEM) e facebook-ads-bU6W (CA Braga Motos 2), que recuperaram em 2026-10-27 (estavam fora por 403/400). 63 -> 65 fontes.
-- FONTES (65, as da trs_facebook_ads__insight_diario / __campanha menos a rCHw): 7 antigas + 58 novas, camada por conta (R-001).
-- Prefixo de tabela e camada vem do CATALOGO, nunca deduzido (kQ2S/GWZ2 dividem a camada vanguardamartech_braga_veiculos com prefixos
-- facebook_ads_braga* e facebook_ads_braga_*; a Japura GZtZ usa camada vanguardamartech_japura_pneus_facebook e prefixo facebook_ads_japura_pneus).
-- Padrao compacto: SELECT '<slug>' AS _fonte, * por ramo; colunas nomeadas UMA vez na CTE base (query grande demais nao se conserta).
-- Esquema identico nas 65 tabelas verificado por execucao da uniao (63 em 2026-10-18; tWIP e bU6W somadas em 2026-10-29).
-- Gatilho: cron terca 13:35 America/Manaus, o mesmo das Trusted Meta (query-QXqC / query-7aLj). Le so Raw: pode rodar em paralelo com elas.
--
-- DEDUPLICACAO OBRIGATORIA: chave do stream [id, updated_time]; fica a versao de maior updated_time (TIMESTAMP, nao texto).
-- ORCAMENTO: a origem entrega na MENOR UNIDADE DA MOEDA (centavos). Verificado em 2026-10-18 na conta CA Braga Veiculos (BRL): 10 conjuntos
-- ATIVOS com daily_budget 2000 a 8000 gastam em media R$ 15,9 a R$ 122,3 por dia (ex.: 4000 -> media R$ 44,64); lidos como reais seriam
-- 100x o gasto real. As colunas *_unidade_menor ficam CRUAS e as colunas sem sufixo dividem por 100. A MOEDA nao esta nesta tabela: ela vem de
-- trs_facebook_ads__conta (BRL e USD). NUNCA somar orcamento entre contas de moedas diferentes.
-- GENERO: Meta codifica 1=masculino, 2=feminino e 0 (ou lista vazia, ou 1,2) = todos. Medido: o codigo 0 aparece (41 de 427 conjuntos na camada Braga GWZ2).
-- Zero e SENTINELA de "sem orcamento neste nivel" (campanha com orcamento no nivel da campanha): daily_budget/lifetime_budget 0 -> NULL.
WITH uniao_raw AS (
  SELECT 'facebook-ads-Si4U' AS _fonte, * FROM `vanguardamartech_acesso_saude`.`facebook_ads__acesso_saudeadsets` UNION ALL
  SELECT 'facebook-ads-kQ2S' AS _fonte, * FROM `vanguardamartech_braga_veiculos`.`facebook_ads_bragaadsets` UNION ALL
  SELECT 'facebook-ads-GWZ2' AS _fonte, * FROM `vanguardamartech_braga_veiculos`.`facebook_ads_braga_adsets` UNION ALL
  SELECT 'facebook-ads-x4yO' AS _fonte, * FROM `vanguardamartech_pmz_loja`.`facebook_ads_pmz_lojaadsets` UNION ALL
  SELECT 'facebook-ads-ln1a' AS _fonte, * FROM `vanguardamartech_colmeia`.`facebook_ads_colmeiaadsets` UNION ALL
  SELECT 'facebook-ads-E9RT' AS _fonte, * FROM `vanguardamartech_best_car`.`facebook_ads_best_caradsets` UNION ALL
  SELECT 'facebook-ads-oB7d' AS _fonte, * FROM `vanguardamartech_constroi_incorporadora`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-8RYU' AS _fonte, * FROM `vanguardamartech_ca_braga_veiculos_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-ezGP' AS _fonte, * FROM `vanguardamartech_ca_braga_motos_rey_mao_royal_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-b8KQ' AS _fonte, * FROM `vanguardamartech_neo_vila_adrianopolis_empreendimento_ads_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-CebU' AS _fonte, * FROM `vanguardamartech_ca_braga_veiculos_venda_direta_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-jZBq' AS _fonte, * FROM `vanguardamartech_parque_das_torres_ads_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-5eAs' AS _fonte, * FROM `vanguardamartech_ca_inforcell_oficial_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-aghZ' AS _fonte, * FROM `vanguardamartech_amazoncopy_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-Vgli' AS _fonte, * FROM `vanguardamartech_pmz_grupo_ecomm_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-WQmP' AS _fonte, * FROM `vanguardamartech_caa_aluminio_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-nCGL' AS _fonte, * FROM `vanguardamartech_amz_geradores_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-K2kh' AS _fonte, * FROM `vanguardamartech_caa_tintas_express_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-TAqE' AS _fonte, * FROM `vanguardamartech_animativ_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-omn8' AS _fonte, * FROM `vanguardamartech_arena_tintas_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-2vvw' AS _fonte, * FROM `vanguardamartech_pneu_express_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-tzO2' AS _fonte, * FROM `vanguardamartech_cabral_v2_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-s8I1' AS _fonte, * FROM `vanguardamartech_pneu_forte_distribuidora_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-oVkz' AS _fonte, * FROM `vanguardamartech_cdl_manaus_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-phtv' AS _fonte, * FROM `vanguardamartech_pneu_forte_varejo_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-rPr1' AS _fonte, * FROM `vanguardamartech_comac_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-p8vg' AS _fonte, * FROM `vanguardamartech_rei_das_mangueiras_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-ofJE' AS _fonte, * FROM `vanguardamartech_consorcio_chevrolet_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-aiXX' AS _fonte, * FROM `vanguardamartech_residencial_boa_vista_ads_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-ZYCB' AS _fonte, * FROM `vanguardamartech_deb_transportes_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-Hr6d' AS _fonte, * FROM `vanguardamartech_ba_eletrica_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-oaSa' AS _fonte, * FROM `vanguardamartech_best_car_2026_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-tWUr' AS _fonte, * FROM `vanguardamartech_bigazine_boleto_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-d1nc' AS _fonte, * FROM `vanguardamartech_rodrix_motos_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-Eo68' AS _fonte, * FROM `vanguardamartech_don_watches_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-SGls' AS _fonte, * FROM `vanguardamartech_braga_motors_carro_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-lDmk' AS _fonte, * FROM `vanguardamartech_dr_cabral_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-Ew4q' AS _fonte, * FROM `vanguardamartech_braga_motors_mini_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-oih2' AS _fonte, * FROM `vanguardamartech_escola_para_mecanicos_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-lk1y' AS _fonte, * FROM `vanguardamartech_braga_motors_motorrad_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-cETo' AS _fonte, * FROM `vanguardamartech_c_a02_cabral_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-mtAO' AS _fonte, * FROM `vanguardamartech_ca1_move_rental_cars_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-pbon' AS _fonte, * FROM `vanguardamartech_grupo_hage_alimentos_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-4Q1U' AS _fonte, * FROM `vanguardamartech_smile_pneus_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-DtiV' AS _fonte, * FROM `vanguardamartech_hospital_santa_julia_ads_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-yFhV' AS _fonte, * FROM `vanguardamartech_steel_port_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-Uu0D' AS _fonte, * FROM `vanguardamartech_kiffer_ads_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-0rrE' AS _fonte, * FROM `vanguardamartech_therezinha_ruiz_eleicao_2026_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-sHYk' AS _fonte, * FROM `vanguardamartech_leapmotor_via_marconi_manaus_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-bIVn' AS _fonte, * FROM `vanguardamartech_therezinha_ruiz_pre_campanha_2026_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-3vys' AS _fonte, * FROM `vanguardamartech_tropical_multiloja_ativo_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-xohe' AS _fonte, * FROM `vanguardamartech_ca_artrin_importadora_02_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-Tqjf' AS _fonte, * FROM `vanguardamartech_ca_braga_acessorios_mao_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-ckhA' AS _fonte, * FROM `vanguardamartech_ca_braga_consorcios_mao_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-smxd' AS _fonte, * FROM `vanguardamartech_ca_braga_motos_pos_vendas_mao_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-elFk' AS _fonte, * FROM `vanguardamartech_leapmotor_vm_i_reserva_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-VJeY' AS _fonte, * FROM `vanguardamartech_unipar_ads_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-AJ09' AS _fonte, * FROM `vanguardamartech_vanguarda_comunicacao_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-KBUT' AS _fonte, * FROM `vanguardamartech_vbot_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-hIaw' AS _fonte, * FROM `vanguardamartech_millennium_ads_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-7NkZ' AS _fonte, * FROM `vanguardamartech_vega_bajaj_manaus_am_anuncios_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-I8ld' AS _fonte, * FROM `vanguardamartech_voike_ads_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-tWIP' AS _fonte, * FROM `vanguardamartech_farmabem_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-bU6W' AS _fonte, * FROM `vanguardamartech_ca_braga_motos_2_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT 'facebook-ads-GZtZ' AS _fonte, * FROM `vanguardamartech_japura_pneus_facebook`.`facebook_ads_japura_pneusadsets`
),

base AS (
  SELECT
    u._fonte,
    u.id                                              AS id_conjunto,
    u.account_id                                      AS id_conta,
    u.campaign_id                                     AS id_campanha,
    NULLIF(TRIM(u.name), '')                          AS conjunto,
    u.status,
    u.effective_status                                AS status_efetivo,
    u.configured_status                               AS status_configurado,
    u.optimization_goal                               AS objetivo_otimizacao,
    u.billing_event                                   AS evento_cobranca,
    u.bid_strategy                                    AS estrategia_lance,
    SAFE_CAST(u.bid_amount AS INT64)                  AS lance_unidade_menor,
    u.destination_type                                AS tipo_destino,
    u.campaign_attribution                            AS atribuicao_campanha,
    u.is_dynamic_creative                             AS is_criativo_dinamico,
    ARRAY_TO_STRING(u.pacing_type, ',')               AS ritmo,
    NULLIF(SAFE_CAST(u.daily_budget AS INT64), 0)     AS orc_diario,
    NULLIF(SAFE_CAST(u.lifetime_budget AS INT64), 0)  AS orc_total,
    SAFE_CAST(u.budget_remaining AS INT64)            AS orc_restante,
    u.promoted_object.page_id                         AS id_pagina,
    u.promoted_object.pixel_id                        AS id_pixel,
    u.promoted_object.custom_event_type               AS evento_personalizado,
    u.promoted_object.custom_conversion_id            AS id_conversao_personalizada,
    u.learning_stage_info.status                      AS fase_aprendizado,
    ARRAY_TO_STRING(ARRAY(
      SELECT CONCAT(a.event_type, ':', CAST(a.window_days AS STRING)) FROM UNNEST(u.attribution_spec) a ORDER BY 1
    ), ',')                                           AS janela_atribuicao,
    u.targeting.age_min                               AS idade_min,
    u.targeting.age_max                               AS idade_max,
    ARRAY_TO_STRING(ARRAY(SELECT CAST(g AS STRING) FROM UNNEST(u.targeting.genders) g ORDER BY 1), ',') AS generos_codigo,
    ARRAY_TO_STRING(u.targeting.geo_locations.countries, ',')   AS paises,
    ARRAY_LENGTH(u.targeting.geo_locations.cities)              AS qtd_cidades,
    ARRAY_TO_STRING(ARRAY(
      SELECT c.name FROM UNNEST(u.targeting.geo_locations.cities) c WHERE c.name IS NOT NULL ORDER BY c.name LIMIT 10
    ), '; ')                                                    AS cidades,
    ARRAY_LENGTH(u.targeting.geo_locations.regions)             AS qtd_regioes,
    ARRAY_LENGTH(u.targeting.geo_locations.custom_locations)    AS qtd_locais_personalizados,
    ARRAY_LENGTH(u.targeting.geo_locations.zips)                AS qtd_cep,
    ARRAY_LENGTH(u.targeting.excluded_geo_locations.countries)
      + ARRAY_LENGTH(u.targeting.excluded_geo_locations.regions)
      + ARRAY_LENGTH(u.targeting.excluded_geo_locations.cities) AS qtd_locais_excluidos,
    ARRAY_TO_STRING(u.targeting.publisher_platforms, ',')       AS plataformas,
    ARRAY_LENGTH(u.targeting.facebook_positions)                AS qtd_posicoes_facebook,
    ARRAY_LENGTH(u.targeting.instagram_positions)               AS qtd_posicoes_instagram,
    ARRAY_TO_STRING(u.targeting.device_platforms, ',')          AS dispositivos,
    ARRAY_LENGTH(u.targeting.custom_audiences)                  AS qtd_publicos_personalizados,
    ARRAY_LENGTH(u.targeting.excluded_custom_audiences)         AS qtd_publicos_excluidos,
    ARRAY_LENGTH(u.targeting.interests)                         AS qtd_interesses,
    ARRAY_LENGTH(u.targeting.behaviors)                         AS qtd_comportamentos,
    SAFE_CAST(u.start_time   AS TIMESTAMP)            AS inicio_utc,
    SAFE_CAST(u.end_time     AS TIMESTAMP)            AS fim_utc,
    SAFE_CAST(u.created_time AS TIMESTAMP)            AS criado_utc,
    SAFE_CAST(u.updated_time AS TIMESTAMP)            AS atualizado_utc,
    TO_HEX(MD5(TO_JSON_STRING((SELECT AS STRUCT u.* EXCEPT (_fonte))))) AS _payload_hash,
    COUNT(*) OVER (PARTITION BY u.account_id, u.id)   AS qtd_versoes_na_origem
  FROM uniao_raw u
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY u.account_id, u.id
    ORDER BY SAFE_CAST(u.updated_time AS TIMESTAMP) DESC, u._fonte
  ) = 1
)

SELECT
  b.id_conjunto,
  b.id_conta,
  b.id_campanha,
  b.conjunto,
  b.status,
  b.status_efetivo,
  b.status_configurado,
  (b.status_efetivo = 'ACTIVE')                       AS is_ativo,
  b.objetivo_otimizacao,
  b.evento_cobranca,
  b.estrategia_lance,
  b.lance_unidade_menor,
  b.tipo_destino,
  b.atribuicao_campanha,
  b.is_criativo_dinamico,
  NULLIF(b.ritmo, '')                                 AS ritmo,
  b.orc_diario                                        AS orcamento_diario_unidade_menor,
  b.orc_total                                         AS orcamento_total_unidade_menor,
  b.orc_restante                                      AS orcamento_restante_unidade_menor,
  b.orc_diario / 100                                  AS orcamento_diario,
  b.orc_total / 100                                   AS orcamento_total,
  (b.orc_diario IS NOT NULL OR b.orc_total IS NOT NULL) AS tem_orcamento_no_conjunto,
  b.id_pagina,
  b.id_pixel,
  b.evento_personalizado,
  b.id_conversao_personalizada,
  b.fase_aprendizado,
  NULLIF(b.janela_atribuicao, '')                     AS janela_atribuicao,
  b.idade_min,
  b.idade_max,
  CASE
    WHEN b.generos_codigo IS NULL OR b.generos_codigo IN ('', '0', '1,2') THEN 'todos'
    WHEN b.generos_codigo = '1' THEN 'masculino'
    WHEN b.generos_codigo = '2' THEN 'feminino'
    ELSE 'outro'
  END                                                 AS genero_alvo,
  NULLIF(b.generos_codigo, '')                        AS generos_codigo,
  NULLIF(b.paises, '')                                AS paises,
  b.qtd_cidades,
  NULLIF(b.cidades, '')                               AS cidades,
  b.qtd_regioes,
  b.qtd_locais_personalizados,
  b.qtd_cep,
  b.qtd_locais_excluidos,
  NULLIF(b.plataformas, '')                           AS plataformas,
  b.qtd_posicoes_facebook,
  b.qtd_posicoes_instagram,
  NULLIF(b.dispositivos, '')                          AS dispositivos,
  b.qtd_publicos_personalizados,
  b.qtd_publicos_excluidos,
  b.qtd_interesses,
  b.qtd_comportamentos,
  DATETIME(b.inicio_utc,     'America/Sao_Paulo')     AS inicio,
  DATETIME(b.fim_utc,        'America/Sao_Paulo')     AS fim,
  DATETIME(b.criado_utc,     'America/Sao_Paulo')     AS criado_em,
  DATETIME(b.atualizado_utc, 'America/Sao_Paulo')     AS atualizado_em,
  b.qtd_versoes_na_origem,
  CURRENT_TIMESTAMP()                                 AS _extraido_at,
  b._fonte,
  b._payload_hash
FROM base b