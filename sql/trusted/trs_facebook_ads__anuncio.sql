-- trs_facebook_ads__anuncio
-- Trusted Facebook Ads. Grao: um ANUNCIO (objeto de estrutura, nao desempenho). Chave: (id_conta, id_anuncio).
-- Fonte: stream `ads` das 66 fontes facebook-ads-*. Nivel L2 INTERNAL (estrutura, estado e ids; nenhum texto de terceiros, nenhum token).
-- Criado em 2026-10-18.
-- 2026-10-29: ESTENDIDA DE 64 PARA 66 FONTES: entram tWIP (FARMABEM) e bU6W (CA Braga Motos 2), que recuperaram em 27/10
-- (antes 403/400); saem da lista de fora. Esquema identico verificado por execucao da uniao.
-- FONTES (66, as mesmas da trs_facebook_ads__insight_diario / __campanha): 7 antigas + 59 novas, camada por conta (R-001).
-- Prefixo de tabela e camada vem do CATALOGO, nunca deduzido (kQ2S/GWZ2 dividem a camada vanguardamartech_braga_veiculos com prefixos
-- facebook_ads_braga* e facebook_ads_braga_*; a Japura GZtZ usa camada vanguardamartech_japura_pneus_facebook e prefixo facebook_ads_japura_pneus).
-- Padrao compacto: SELECT '<slug>' AS _fonte, * por ramo; colunas nomeadas UMA vez na CTE base (query grande demais nao se conserta).
-- Esquema identico nas 64 tabelas verificado por execucao da uniao em 2026-10-18 (66 em 2026-10-29).
-- Gatilho: cron terca 13:35 America/Manaus, o mesmo das Trusted Meta (query-QXqC / query-7aLj). Le so Raw: pode rodar em paralelo com elas.
--
-- DEDUPLICACAO OBRIGATORIA: a chave do stream e [id, updated_time]; a origem guarda mais de uma versao do mesmo anuncio
-- (medido 2026-10-18: 25.258 linhas para 24.979 anuncios, 249 ids repetidos, todos DENTRO da mesma fonte e com updated_time diferente).
-- Fica a versao de maior updated_time, comparada como TIMESTAMP (os offsets variam: +0000 e -0700 no mesmo campo, ordenar texto erra).
-- Fuso: os timestamps da origem trazem offset explicito (instante UTC); DATETIME(ts,'America/Sao_Paulo') apenas muda a representacao.
-- Campos mortos NAO emitidos (medidos nulos em 6.447 anuncios de 5 contas): ad_acive_time, ad_schedule_start_time, ad_schedule_end_time,
-- preview_shareable_link. Emitir NULL convidaria a somar zero.
-- id_anuncio_origem (source_ad_id) vem preenchido em 100% dos anuncios e e DIFERENTE do proprio id em 100% (medido 2026-10-18, 24.979 de 24.979):
-- nao prova que o anuncio seja copia de outro; fica cru, sem flag derivada.
-- Esta tabela NAO tem investimento: desempenho esta em trs_facebook_ads__insight_diario (join por id_anuncio).
WITH uniao_raw AS (
  SELECT 'facebook-ads-Si4U' AS _fonte, * FROM `vanguardamartech_acesso_saude`.`facebook_ads__acesso_saudeads` UNION ALL
  SELECT 'facebook-ads-kQ2S' AS _fonte, * FROM `vanguardamartech_braga_veiculos`.`facebook_ads_bragaads` UNION ALL
  SELECT 'facebook-ads-GWZ2' AS _fonte, * FROM `vanguardamartech_braga_veiculos`.`facebook_ads_braga_ads` UNION ALL
  SELECT 'facebook-ads-x4yO' AS _fonte, * FROM `vanguardamartech_pmz_loja`.`facebook_ads_pmz_lojaads` UNION ALL
  SELECT 'facebook-ads-ln1a' AS _fonte, * FROM `vanguardamartech_colmeia`.`facebook_ads_colmeiaads` UNION ALL
  SELECT 'facebook-ads-E9RT' AS _fonte, * FROM `vanguardamartech_best_car`.`facebook_ads_best_carads` UNION ALL
  SELECT 'facebook-ads-oB7d' AS _fonte, * FROM `vanguardamartech_constroi_incorporadora`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-8RYU' AS _fonte, * FROM `vanguardamartech_ca_braga_veiculos_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-ezGP' AS _fonte, * FROM `vanguardamartech_ca_braga_motos_rey_mao_royal_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-b8KQ' AS _fonte, * FROM `vanguardamartech_neo_vila_adrianopolis_empreendimento_ads_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-rCHw' AS _fonte, * FROM `vanguardamartech_acesso_saude_manoa_2_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-CebU' AS _fonte, * FROM `vanguardamartech_ca_braga_veiculos_venda_direta_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-jZBq' AS _fonte, * FROM `vanguardamartech_parque_das_torres_ads_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-5eAs' AS _fonte, * FROM `vanguardamartech_ca_inforcell_oficial_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-aghZ' AS _fonte, * FROM `vanguardamartech_amazoncopy_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-Vgli' AS _fonte, * FROM `vanguardamartech_pmz_grupo_ecomm_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-WQmP' AS _fonte, * FROM `vanguardamartech_caa_aluminio_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-nCGL' AS _fonte, * FROM `vanguardamartech_amz_geradores_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-K2kh' AS _fonte, * FROM `vanguardamartech_caa_tintas_express_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-TAqE' AS _fonte, * FROM `vanguardamartech_animativ_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-omn8' AS _fonte, * FROM `vanguardamartech_arena_tintas_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-2vvw' AS _fonte, * FROM `vanguardamartech_pneu_express_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-tzO2' AS _fonte, * FROM `vanguardamartech_cabral_v2_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-s8I1' AS _fonte, * FROM `vanguardamartech_pneu_forte_distribuidora_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-oVkz' AS _fonte, * FROM `vanguardamartech_cdl_manaus_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-phtv' AS _fonte, * FROM `vanguardamartech_pneu_forte_varejo_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-rPr1' AS _fonte, * FROM `vanguardamartech_comac_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-p8vg' AS _fonte, * FROM `vanguardamartech_rei_das_mangueiras_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-ofJE' AS _fonte, * FROM `vanguardamartech_consorcio_chevrolet_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-aiXX' AS _fonte, * FROM `vanguardamartech_residencial_boa_vista_ads_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-ZYCB' AS _fonte, * FROM `vanguardamartech_deb_transportes_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-Hr6d' AS _fonte, * FROM `vanguardamartech_ba_eletrica_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-oaSa' AS _fonte, * FROM `vanguardamartech_best_car_2026_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-tWUr' AS _fonte, * FROM `vanguardamartech_bigazine_boleto_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-d1nc' AS _fonte, * FROM `vanguardamartech_rodrix_motos_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-Eo68' AS _fonte, * FROM `vanguardamartech_don_watches_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-SGls' AS _fonte, * FROM `vanguardamartech_braga_motors_carro_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-lDmk' AS _fonte, * FROM `vanguardamartech_dr_cabral_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-Ew4q' AS _fonte, * FROM `vanguardamartech_braga_motors_mini_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-oih2' AS _fonte, * FROM `vanguardamartech_escola_para_mecanicos_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-lk1y' AS _fonte, * FROM `vanguardamartech_braga_motors_motorrad_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-cETo' AS _fonte, * FROM `vanguardamartech_c_a02_cabral_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-mtAO' AS _fonte, * FROM `vanguardamartech_ca1_move_rental_cars_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-pbon' AS _fonte, * FROM `vanguardamartech_grupo_hage_alimentos_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-4Q1U' AS _fonte, * FROM `vanguardamartech_smile_pneus_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-DtiV' AS _fonte, * FROM `vanguardamartech_hospital_santa_julia_ads_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-yFhV' AS _fonte, * FROM `vanguardamartech_steel_port_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-Uu0D' AS _fonte, * FROM `vanguardamartech_kiffer_ads_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-0rrE' AS _fonte, * FROM `vanguardamartech_therezinha_ruiz_eleicao_2026_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-sHYk' AS _fonte, * FROM `vanguardamartech_leapmotor_via_marconi_manaus_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-bIVn' AS _fonte, * FROM `vanguardamartech_therezinha_ruiz_pre_campanha_2026_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-3vys' AS _fonte, * FROM `vanguardamartech_tropical_multiloja_ativo_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-xohe' AS _fonte, * FROM `vanguardamartech_ca_artrin_importadora_02_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-Tqjf' AS _fonte, * FROM `vanguardamartech_ca_braga_acessorios_mao_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-ckhA' AS _fonte, * FROM `vanguardamartech_ca_braga_consorcios_mao_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-smxd' AS _fonte, * FROM `vanguardamartech_ca_braga_motos_pos_vendas_mao_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-elFk' AS _fonte, * FROM `vanguardamartech_leapmotor_vm_i_reserva_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-VJeY' AS _fonte, * FROM `vanguardamartech_unipar_ads_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-AJ09' AS _fonte, * FROM `vanguardamartech_vanguarda_comunicacao_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-KBUT' AS _fonte, * FROM `vanguardamartech_vbot_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-hIaw' AS _fonte, * FROM `vanguardamartech_millennium_ads_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-7NkZ' AS _fonte, * FROM `vanguardamartech_vega_bajaj_manaus_am_anuncios_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-I8ld' AS _fonte, * FROM `vanguardamartech_voike_ads_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-GZtZ' AS _fonte, * FROM `vanguardamartech_japura_pneus_facebook`.`facebook_ads_japura_pneusads` UNION ALL
  SELECT 'facebook-ads-tWIP' AS _fonte, * FROM `vanguardamartech_farmabem_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT 'facebook-ads-bU6W' AS _fonte, * FROM `vanguardamartech_ca_braga_motos_2_fb_ads`.`facebook_ads_ads`
),

base AS (
  SELECT
    u._fonte,
    u.id                                              AS id_anuncio,
    u.account_id                                      AS id_conta,
    u.campaign_id                                     AS id_campanha,
    u.adset_id                                        AS id_conjunto,
    u.creative.id                                     AS id_criativo,
    u.source_ad_id                                    AS id_anuncio_origem,
    NULLIF(TRIM(u.name), '')                          AS anuncio,
    u.status,
    u.effective_status                                AS status_efetivo,
    u.configured_status                               AS status_configurado,
    u.bid_type                                        AS tipo_lance,
    SAFE_CAST(u.bid_amount AS INT64)                  AS lance_unidade_menor,
    u.conversion_domain                               AS dominio_conversao,
    ARRAY_LENGTH(u.recommendations)                   AS qtd_recomendacoes,
    ARRAY_LENGTH(u.tracking_specs)                    AS qtd_regras_rastreio,
    ARRAY_LENGTH(u.conversion_specs)                  AS qtd_regras_conversao,
    ARRAY_TO_STRING(ARRAY(
      SELECT DISTINCT act FROM UNNEST(u.tracking_specs) ts, UNNEST(ts.action_type) act WHERE act IS NOT NULL ORDER BY act
    ), ',')                                           AS tipos_acao_rastreada,
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
  b.id_anuncio,
  b.id_conta,
  b.id_campanha,
  b.id_conjunto,
  b.id_criativo,
  b.id_anuncio_origem,
  b.anuncio,
  b.status,
  b.status_efetivo,
  b.status_configurado,
  (b.status_efetivo = 'ACTIVE')                       AS is_ativo,
  (b.status_efetivo IN ('CAMPAIGN_PAUSED','ADSET_PAUSED') AND b.status_configurado = 'ACTIVE') AS is_pausado_por_ancestral,
  b.tipo_lance,
  b.lance_unidade_menor,
  b.dominio_conversao,
  b.qtd_recomendacoes,
  b.qtd_regras_rastreio,
  b.qtd_regras_conversao,
  NULLIF(b.tipos_acao_rastreada, '')                  AS tipos_acao_rastreada,
  DATETIME(b.criado_utc,     'America/Sao_Paulo')     AS criado_em,
  DATETIME(b.atualizado_utc, 'America/Sao_Paulo')     AS atualizado_em,
  b.qtd_versoes_na_origem,
  CURRENT_TIMESTAMP()                                 AS _extraido_at,
  b._fonte,
  b._payload_hash
FROM base b
