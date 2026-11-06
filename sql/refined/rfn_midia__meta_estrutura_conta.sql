-- rfn_midia__meta_estrutura_conta
-- Refined / dominio Midia. Grao: UMA CONTA de Facebook Ads (id_conta). Chave: id_conta.
-- Le trs_facebook_ads__anuncio, __conjunto_anuncio, __criativo, __campanha, __conta e __insight_diario (camada Trusted Facebook Ads).
-- Gatilho: evento nas 5 Trusted que disparam por cron terca 13:35 (anuncio, conjunto, criativo, campanha, insight), regra all.
-- A dimensao de conta (cron diario 03:00) NAO entra no gatilho: com regra all misturaria cadencias.
-- Nivel L2 INTERNAL: contagens, ids e valores agregados por conta; NENHUM texto de anuncio, conjunto ou criativo atravessa.
-- Criado em 2026-10-18.
--
-- REGRA 1 (balde de status, decomposicao exata): ATIVO = ACTIVE; PAUSADO = PAUSED (parado pelo proprio objeto); PAUSADO_POR_ANCESTRAL =
--   CAMPAIGN_PAUSED ou ADSET_PAUSED (o objeto esta ligado, quem esta parado e o pai); COM_PROBLEMA = WITH_ISSUES ou DISAPPROVED; OUTRO = o resto
--   (ARCHIVED, DELETED, NULL, status novo). Ativos + pausados + por ancestral + com problema + outros = total, em cada nivel.
-- REGRA 2 (orcamento so em moeda da conta): orcamento_diario_ativo soma os orcamentos DIARIOS dos conjuntos ATIVOS que tem orcamento no
--   conjunto. Conjunto ativo sem orcamento proprio (orcamento no nivel da campanha) e CONTADO a parte e NAO entra na soma. Valor na moeda da
--   conta (coluna moeda, BRL ou USD). NUNCA somar linhas de moedas diferentes.
-- REGRA 3 (cobertura de ligacao): cada contagem *_sem_* e um anti-join explicito entre as Trusted. Campanha sem conjunto = campanha cadastrada
--   que nao tem nenhum conjunto na Trusted. A dimensao de campanha e FOTOGRAFIA e o fato e historico (18 campanhas do Meta ja excluidas somem da
--   dimensao e seguem nos insights): objeto filho sem pai catalogado NAO e erro de tratamento, e uma flag acesa.
-- REGRA 4 (insight): investimento e desempenho vem de trs_facebook_ads__insight_diario por id_anuncio. Conta sem NENHUMA linha de insight tem
--   investimento NULL, nunca zero (ausencia, nao gasto zero). investimento_sem_anuncio_cadastrado_micros e o gasto de anuncio que existe no
--   insight e nao existe na Trusted de anuncio.
-- LIMITACOES - nao contorne: (a) a estrutura e fotografia da ultima extracao semanal (terca); (b) a Trusted de insight pode ter conta
--   defasada (ver trs_facebook_ads__insight_diario.conta_defasada); (c) conta em USD tem orcamento e investimento em dolar; (d) contas fora
--   da uniao (12 com 403 ads_read, bU6W, ex-clientes, Nova Era) nao aparecem; (e) rCHw (Acesso Saude manoa 2) tem a tabela adsets VAZIA: aparece com
--   anuncios e zero conjuntos, o que e ausencia na origem, nao conjunto apagado.
-- VALIDACAO 2026-10-18 (query inteira executada reproduzindo as Trusted sobre a Raw; as Trusted novas ainda nao materializaram; insight e conta lidos das
--   tabelas reais, que hoje cobrem so as 7 contas antigas de insight): 64 linhas, 64 contas, zero sem dimensao de conta, 1 conta em USD. Soma das linhas =
--   Trusted: campanhas 4.262, conjuntos 7.960, anuncios 24.979, criativos 21.254. Baldes de status fecham o total em 64 de 64 contas nos tres niveis.
--   Cobertura: 649 campanhas sem conjunto, 405 conjuntos sem anuncio, 196 conjuntos e 249 anuncios sem campanha catalogada, 354 anuncios sem conjunto
--   catalogado, ZERO anuncio sem criativo catalogado, 21 criativos sem anuncio. Insight em 7 contas (57 sem): investimento R$ 2.462.188,66 = o total da
--   Trusted de insight; R$ 148.766,44 (6,0%) sao de anuncio que nao esta na Trusted de anuncio. Orcamento diario dos conjuntos ativos: R$ 149.974,38 (BRL) e
--   US$ 105,00 (USD); 1.020 conjuntos ativos sem orcamento proprio (orcamento no nivel da campanha). Depois de terca 20/10 o insight cobre as 64 contas.
WITH anuncio AS (
  SELECT id_conta, id_anuncio, id_conjunto, id_campanha, id_criativo, status_efetivo
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__anuncio`
),

conjunto AS (
  SELECT id_conta, id_conjunto, id_campanha, status_efetivo, is_ativo,
         orcamento_diario_unidade_menor, orcamento_total_unidade_menor, tem_orcamento_no_conjunto
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__conjunto_anuncio`
),

criativo AS (
  SELECT id_conta, id_criativo FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__criativo`
),

campanha AS (
  SELECT id_conta, id_campanha, status_efetivo FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__campanha`
),

conta AS (
  SELECT id_conta, conta, moeda, fuso_conta, status_conta, ativa AS conta_ativa FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__conta`
),

contas AS (
  SELECT id_conta FROM anuncio UNION DISTINCT
  SELECT id_conta FROM conjunto UNION DISTINCT
  SELECT id_conta FROM criativo UNION DISTINCT
  SELECT id_conta FROM campanha
),

ins_ad AS (
  SELECT
    i.id_conta, i.id_anuncio,
    CAST(ROUND(SUM(i.investimento) * 1000000) AS INT64) AS investimento_micros,
    SUM(COALESCE(i.impressoes, 0))                      AS impressoes,
    SUM(COALESCE(i.cliques, 0))                         AS cliques,
    MAX(i.data)                                         AS ultima_data
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__insight_diario` i
  GROUP BY i.id_conta, i.id_anuncio
),

ins_conta AS (
  SELECT
    a.id_conta,
    COUNT(*)                                              AS qtd_anuncios_com_insight,
    SUM(a.investimento_micros)                            AS investimento_micros,
    SUM(a.impressoes)                                     AS impressoes,
    SUM(a.cliques)                                        AS cliques,
    MAX(a.ultima_data)                                    AS ultima_data_insight,
    SUM(IF(x.id_anuncio IS NULL, a.investimento_micros, 0)) AS investimento_sem_anuncio_cadastrado_micros,
    COUNTIF(x.id_anuncio IS NULL)                         AS qtd_anuncios_do_insight_sem_cadastro
  FROM ins_ad a
  LEFT JOIN (SELECT DISTINCT id_conta, id_anuncio FROM anuncio) x USING (id_conta, id_anuncio)
  GROUP BY a.id_conta
),

agg_campanha AS (
  SELECT
    c.id_conta,
    COUNT(*)                                                                              AS qtd_campanhas,
    COUNTIF(c.status_efetivo = 'ACTIVE')                                                  AS qtd_campanhas_ativas,
    COUNTIF(c.status_efetivo = 'PAUSED')                                                  AS qtd_campanhas_pausadas,
    COUNTIF(c.status_efetivo IN ('WITH_ISSUES','DISAPPROVED'))                            AS qtd_campanhas_com_problema,
    COUNTIF(c.status_efetivo IS NULL OR c.status_efetivo NOT IN ('ACTIVE','PAUSED','WITH_ISSUES','DISAPPROVED')) AS qtd_campanhas_outro_status,
    COUNTIF(cj.id_campanha IS NULL)                                                       AS qtd_campanhas_sem_conjunto
  FROM campanha c
  LEFT JOIN (SELECT DISTINCT id_conta, id_campanha FROM conjunto) cj USING (id_conta, id_campanha)
  GROUP BY c.id_conta
),

agg_conjunto AS (
  SELECT
    j.id_conta,
    COUNT(*)                                                                              AS qtd_conjuntos,
    COUNTIF(j.status_efetivo = 'ACTIVE')                                                  AS qtd_conjuntos_ativos,
    COUNTIF(j.status_efetivo = 'PAUSED')                                                  AS qtd_conjuntos_pausados,
    COUNTIF(j.status_efetivo IN ('CAMPAIGN_PAUSED','ADSET_PAUSED'))                       AS qtd_conjuntos_pausados_por_ancestral,
    COUNTIF(j.status_efetivo IN ('WITH_ISSUES','DISAPPROVED'))                            AS qtd_conjuntos_com_problema,
    COUNTIF(j.status_efetivo IS NULL OR j.status_efetivo NOT IN ('ACTIVE','PAUSED','CAMPAIGN_PAUSED','ADSET_PAUSED','WITH_ISSUES','DISAPPROVED')) AS qtd_conjuntos_outro_status,
    COUNTIF(j.is_ativo AND j.tem_orcamento_no_conjunto)                                   AS qtd_conjuntos_ativos_com_orcamento_proprio,
    COUNTIF(j.is_ativo AND NOT j.tem_orcamento_no_conjunto)                               AS qtd_conjuntos_ativos_sem_orcamento_proprio,
    SUM(IF(j.is_ativo, j.orcamento_diario_unidade_menor, NULL))                           AS orcamento_diario_ativo_unidade_menor,
    SUM(IF(j.is_ativo, j.orcamento_total_unidade_menor, NULL))                            AS orcamento_total_ativo_unidade_menor,
    COUNTIF(a.id_conjunto IS NULL)                                                        AS qtd_conjuntos_sem_anuncio,
    COUNTIF(c.id_campanha IS NULL)                                                        AS qtd_conjuntos_sem_campanha_catalogada
  FROM conjunto j
  LEFT JOIN (SELECT DISTINCT id_conta, id_conjunto FROM anuncio) a USING (id_conta, id_conjunto)
  LEFT JOIN (SELECT DISTINCT id_conta, id_campanha FROM campanha) c USING (id_conta, id_campanha)
  GROUP BY j.id_conta
),

agg_anuncio AS (
  SELECT
    n.id_conta,
    COUNT(*)                                                                              AS qtd_anuncios,
    COUNTIF(n.status_efetivo = 'ACTIVE')                                                  AS qtd_anuncios_ativos,
    COUNTIF(n.status_efetivo = 'PAUSED')                                                  AS qtd_anuncios_pausados,
    COUNTIF(n.status_efetivo IN ('CAMPAIGN_PAUSED','ADSET_PAUSED'))                       AS qtd_anuncios_pausados_por_ancestral,
    COUNTIF(n.status_efetivo IN ('WITH_ISSUES','DISAPPROVED'))                            AS qtd_anuncios_com_problema,
    COUNTIF(n.status_efetivo IS NULL OR n.status_efetivo NOT IN ('ACTIVE','PAUSED','CAMPAIGN_PAUSED','ADSET_PAUSED','WITH_ISSUES','DISAPPROVED')) AS qtd_anuncios_outro_status,
    COUNT(DISTINCT n.id_criativo)                                                         AS qtd_criativos_usados,
    COUNTIF(j.id_conjunto IS NULL)                                                        AS qtd_anuncios_sem_conjunto_catalogado,
    COUNTIF(k.id_criativo IS NULL)                                                        AS qtd_anuncios_sem_criativo_catalogado,
    COUNTIF(c.id_campanha IS NULL)                                                        AS qtd_anuncios_sem_campanha_catalogada
  FROM anuncio n
  LEFT JOIN (SELECT DISTINCT id_conta, id_conjunto FROM conjunto) j USING (id_conta, id_conjunto)
  LEFT JOIN (SELECT DISTINCT id_conta, id_criativo FROM criativo) k USING (id_conta, id_criativo)
  LEFT JOIN (SELECT DISTINCT id_conta, id_campanha FROM campanha) c USING (id_conta, id_campanha)
  GROUP BY n.id_conta
),

agg_criativo AS (
  SELECT
    k.id_conta,
    COUNT(*)                              AS qtd_criativos,
    COUNTIF(a.id_criativo IS NULL)        AS qtd_criativos_sem_anuncio
  FROM criativo k
  LEFT JOIN (SELECT DISTINCT id_conta, id_criativo FROM anuncio) a USING (id_conta, id_criativo)
  GROUP BY k.id_conta
)

SELECT
  s.id_conta,
  c.conta,
  c.moeda,
  c.fuso_conta,
  c.status_conta,
  c.conta_ativa,
  (c.id_conta IS NULL)                                                  AS flag_sem_dimensao_conta,
  (c.moeda IS NOT NULL AND c.moeda <> 'BRL')                            AS flag_moeda_nao_brl,

  COALESCE(cp.qtd_campanhas, 0)                                         AS qtd_campanhas,
  COALESCE(cp.qtd_campanhas_ativas, 0)                                  AS qtd_campanhas_ativas,
  COALESCE(cp.qtd_campanhas_pausadas, 0)                                AS qtd_campanhas_pausadas,
  COALESCE(cp.qtd_campanhas_com_problema, 0)                            AS qtd_campanhas_com_problema,
  COALESCE(cp.qtd_campanhas_outro_status, 0)                            AS qtd_campanhas_outro_status,
  COALESCE(cp.qtd_campanhas_sem_conjunto, 0)                            AS qtd_campanhas_sem_conjunto,

  COALESCE(cj.qtd_conjuntos, 0)                                         AS qtd_conjuntos,
  COALESCE(cj.qtd_conjuntos_ativos, 0)                                  AS qtd_conjuntos_ativos,
  COALESCE(cj.qtd_conjuntos_pausados, 0)                                AS qtd_conjuntos_pausados,
  COALESCE(cj.qtd_conjuntos_pausados_por_ancestral, 0)                  AS qtd_conjuntos_pausados_por_ancestral,
  COALESCE(cj.qtd_conjuntos_com_problema, 0)                            AS qtd_conjuntos_com_problema,
  COALESCE(cj.qtd_conjuntos_outro_status, 0)                            AS qtd_conjuntos_outro_status,
  COALESCE(cj.qtd_conjuntos_ativos_com_orcamento_proprio, 0)            AS qtd_conjuntos_ativos_com_orcamento_proprio,
  COALESCE(cj.qtd_conjuntos_ativos_sem_orcamento_proprio, 0)            AS qtd_conjuntos_ativos_sem_orcamento_proprio,
  cj.orcamento_diario_ativo_unidade_menor,
  cj.orcamento_diario_ativo_unidade_menor / 100                         AS orcamento_diario_ativo,
  cj.orcamento_total_ativo_unidade_menor / 100                          AS orcamento_total_ativo,
  COALESCE(cj.qtd_conjuntos_sem_anuncio, 0)                             AS qtd_conjuntos_sem_anuncio,
  COALESCE(cj.qtd_conjuntos_sem_campanha_catalogada, 0)                 AS qtd_conjuntos_sem_campanha_catalogada,

  COALESCE(an.qtd_anuncios, 0)                                          AS qtd_anuncios,
  COALESCE(an.qtd_anuncios_ativos, 0)                                   AS qtd_anuncios_ativos,
  COALESCE(an.qtd_anuncios_pausados, 0)                                 AS qtd_anuncios_pausados,
  COALESCE(an.qtd_anuncios_pausados_por_ancestral, 0)                   AS qtd_anuncios_pausados_por_ancestral,
  COALESCE(an.qtd_anuncios_com_problema, 0)                             AS qtd_anuncios_com_problema,
  COALESCE(an.qtd_anuncios_outro_status, 0)                             AS qtd_anuncios_outro_status,
  COALESCE(an.qtd_criativos_usados, 0)                                  AS qtd_criativos_usados,
  COALESCE(an.qtd_anuncios_sem_conjunto_catalogado, 0)                  AS qtd_anuncios_sem_conjunto_catalogado,
  COALESCE(an.qtd_anuncios_sem_criativo_catalogado, 0)                  AS qtd_anuncios_sem_criativo_catalogado,
  COALESCE(an.qtd_anuncios_sem_campanha_catalogada, 0)                  AS qtd_anuncios_sem_campanha_catalogada,

  COALESCE(cr.qtd_criativos, 0)                                         AS qtd_criativos,
  COALESCE(cr.qtd_criativos_sem_anuncio, 0)                             AS qtd_criativos_sem_anuncio,

  (ic.id_conta IS NULL)                                                 AS flag_sem_insight,
  ic.qtd_anuncios_com_insight,
  ic.qtd_anuncios_do_insight_sem_cadastro,
  ic.investimento_micros,
  ic.investimento_micros / 1000000                                      AS investimento,
  ic.investimento_sem_anuncio_cadastrado_micros,
  ic.impressoes,
  ic.cliques,
  ic.ultima_data_insight,

  CURRENT_TIMESTAMP()                                                   AS _extraido_at
FROM contas s
LEFT JOIN conta c          ON c.id_conta  = s.id_conta
LEFT JOIN agg_campanha cp  ON cp.id_conta = s.id_conta
LEFT JOIN agg_conjunto cj  ON cj.id_conta = s.id_conta
LEFT JOIN agg_anuncio an   ON an.id_conta = s.id_conta
LEFT JOIN agg_criativo cr  ON cr.id_conta = s.id_conta
LEFT JOIN ins_conta ic     ON ic.id_conta = s.id_conta
