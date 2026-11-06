-- rfn_midia__meta_criativo_resumo
-- Refined / dominio Midia. Grao: (id_conta, tipo_objeto, tipo_cta). Chave: id_criativo_resumo = CONCAT(id_conta,'|',tipo_objeto,'|',tipo_cta).
-- Le trs_facebook_ads__criativo, __anuncio, __insight_diario e __conta (camada Trusted Facebook Ads).
-- Gatilho: evento nas 5 Trusted que disparam por cron terca 13:35 (anuncio, conjunto, criativo, campanha, insight), regra all.
-- Nivel L2 INTERNAL: SO contagens, tamanhos e investimento por formato; o TEXTO do criativo (titulo, corpo, nome, URL), L3 na Trusted,
-- NAO atravessa. tipo_objeto e tipo_cta sao enumeracoes da Meta, nao texto livre.
-- Criado em 2026-10-18.
--
-- REGRA 1 (grao e rotulo de ausencia): tipo_objeto ou tipo_cta NULL na origem viram os rotulos '(sem tipo)' e '(sem cta)', que fazem parte da
--   chave; criativo sem CTA e a maioria silenciosa (25,9% dos criativos), nao pode sumir. Anuncio cujo criativo nao esta catalogado entra no
--   rotulo '(criativo nao catalogado)' em tipo_objeto, com qtd_criativos = 0.
-- REGRA 2 (dois universos no mesmo grao, nao se misturam): as colunas qtd_criativos*, qtd_com_* e soma_caracteres_corpo contam CRIATIVOS
--   (uma linha de trs_facebook_ads__criativo); as colunas qtd_anuncios* e de insight contam ANUNCIOS e seu desempenho. Um criativo pode ser usado
--   por varios anuncios: dividir investimento por qtd_criativos NAO e custo por criativo.
-- REGRA 3 (investimento atribuido pelo anuncio): o insight e por anuncio; cada anuncio carrega o investimento para o formato do criativo que
--   usa (trs_facebook_ads__anuncio.id_criativo). Investimento de anuncio sem cadastro NAO e atribuido a nenhum formato (fica em
--   rfn_midia__meta_estrutura_conta.investimento_sem_anuncio_cadastrado_micros). Formato sem NENHUM anuncio com insight tem investimento NULL, nunca zero.
-- REGRA 4 (media recalculada dos totais): media_caracteres_corpo = soma_caracteres_corpo / qtd_com_corpo, calculada da razao de somas, nunca
--   herdada linha a linha nem com AVG.
-- LIMITACOES - nao contorne: (a) a MIDIA do criativo (imagem, video) nao existe nesta extracao: tipo_objeto VIDEO diz o formato, nao o arquivo;
--   (b) investimento e na MOEDA DA CONTA (coluna moeda): nunca somar BRL com USD; (c) a Trusted de insight cobre as contas que ja tem
--   adsinsights materializada e pode estar defasada; (d) o criativo e fotografia da ultima extracao.
-- VALIDACAO 2026-10-18 (query inteira executada reproduzindo as Trusted sobre a Raw; as Trusted novas ainda nao materializaram; insight lido da tabela real,
--   que hoje cobre so as 7 contas antigas): 703 linhas, 703 chaves unicas, 64 contas, 7 tipos de objeto, 28 tipos de CTA, zero sem dimensao de conta.
--   Soma das linhas = Trusted: criativos 21.254, anuncios 24.979. Criativos com titulo 8.825, com corpo 16.382, com CTA 15.745 (5.509 sem CTA = 25,9%).
--   Anuncios com insight 6.263; investimento atribuido R$ 2.313.422,22 = R$ 2.462.188,66 do total do insight MENOS R$ 148.766,44 de anuncio sem cadastro
--   (identidade fecha ao centavo com a rfn_midia__meta_estrutura_conta). Zero anuncio com criativo nao catalogado.
WITH anuncio AS (
  SELECT id_conta, id_anuncio, id_criativo, status_efetivo FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__anuncio`
),

criativo AS (
  SELECT id_conta, id_criativo, tipo_objeto, tipo_cta, tem_titulo, tem_corpo, tem_cta, tem_url, qtd_caracteres_corpo
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__criativo`
),

conta AS (
  SELECT id_conta, conta, moeda FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__conta`
),

ins_ad AS (
  SELECT
    i.id_conta, i.id_anuncio,
    CAST(ROUND(SUM(i.investimento) * 1000000) AS INT64) AS investimento_micros,
    SUM(COALESCE(i.impressoes, 0))                      AS impressoes,
    SUM(COALESCE(i.cliques, 0))                         AS cliques,
    SUM(COALESCE(i.leads, 0))                           AS leads,
    SUM(COALESCE(i.conversas_iniciadas_7d, 0))          AS conversas,
    SUM(COALESCE(i.compras, 0))                         AS compras
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__insight_diario` i
  GROUP BY i.id_conta, i.id_anuncio
),

lado_criativo AS (
  SELECT
    k.id_conta,
    COALESCE(k.tipo_objeto, '(sem tipo)')                 AS tipo_objeto,
    COALESCE(k.tipo_cta, '(sem cta)')                     AS tipo_cta,
    COUNT(*)                                              AS qtd_criativos,
    COUNTIF(k.tem_titulo)                                 AS qtd_com_titulo,
    COUNTIF(k.tem_corpo)                                  AS qtd_com_corpo,
    COUNTIF(k.tem_cta)                                    AS qtd_com_cta,
    COUNTIF(k.tem_url)                                    AS qtd_com_url,
    SUM(COALESCE(k.qtd_caracteres_corpo, 0))              AS soma_caracteres_corpo,
    COUNTIF(u.id_criativo IS NULL)                        AS qtd_criativos_sem_anuncio
  FROM criativo k
  LEFT JOIN (SELECT DISTINCT id_conta, id_criativo FROM anuncio) u USING (id_conta, id_criativo)
  GROUP BY 1, 2, 3
),

lado_anuncio AS (
  SELECT
    n.id_conta,
    COALESCE(k.tipo_objeto, IF(k.id_criativo IS NULL, '(criativo nao catalogado)', '(sem tipo)')) AS tipo_objeto,
    IF(k.id_criativo IS NULL, '(sem cta)', COALESCE(k.tipo_cta, '(sem cta)'))                   AS tipo_cta,
    COUNT(*)                                              AS qtd_anuncios,
    COUNTIF(n.status_efetivo = 'ACTIVE')                  AS qtd_anuncios_ativos,
    COUNT(i.id_anuncio)                                   AS qtd_anuncios_com_insight,
    SUM(i.investimento_micros)                            AS investimento_micros,
    SUM(i.impressoes)                                     AS impressoes,
    SUM(i.cliques)                                        AS cliques,
    SUM(i.leads)                                          AS leads,
    SUM(i.conversas)                                      AS conversas,
    SUM(i.compras)                                        AS compras
  FROM anuncio n
  LEFT JOIN (SELECT DISTINCT id_conta, id_criativo, tipo_objeto, tipo_cta FROM criativo) k USING (id_conta, id_criativo)
  LEFT JOIN ins_ad i USING (id_conta, id_anuncio)
  GROUP BY 1, 2, 3
),

juntos AS (
  SELECT
    COALESCE(c.id_conta, a.id_conta)        AS id_conta,
    COALESCE(c.tipo_objeto, a.tipo_objeto)  AS tipo_objeto,
    COALESCE(c.tipo_cta, a.tipo_cta)        AS tipo_cta,
    c.qtd_criativos, c.qtd_com_titulo, c.qtd_com_corpo, c.qtd_com_cta, c.qtd_com_url,
    c.soma_caracteres_corpo, c.qtd_criativos_sem_anuncio,
    a.qtd_anuncios, a.qtd_anuncios_ativos, a.qtd_anuncios_com_insight,
    a.investimento_micros, a.impressoes, a.cliques, a.leads, a.conversas, a.compras
  FROM lado_criativo c
  FULL OUTER JOIN lado_anuncio a
    ON a.id_conta = c.id_conta AND a.tipo_objeto = c.tipo_objeto AND a.tipo_cta = c.tipo_cta
)

SELECT
  CONCAT(j.id_conta, '|', j.tipo_objeto, '|', j.tipo_cta)                AS id_criativo_resumo,
  j.id_conta,
  t.conta,
  t.moeda,
  (t.id_conta IS NULL)                                                   AS flag_sem_dimensao_conta,
  j.tipo_objeto,
  j.tipo_cta,
  COALESCE(j.qtd_criativos, 0)                                           AS qtd_criativos,
  COALESCE(j.qtd_com_titulo, 0)                                          AS qtd_com_titulo,
  COALESCE(j.qtd_com_corpo, 0)                                           AS qtd_com_corpo,
  COALESCE(j.qtd_com_cta, 0)                                             AS qtd_com_cta,
  COALESCE(j.qtd_com_url, 0)                                             AS qtd_com_url,
  COALESCE(j.soma_caracteres_corpo, 0)                                   AS soma_caracteres_corpo,
  SAFE_DIVIDE(j.soma_caracteres_corpo, NULLIF(j.qtd_com_corpo, 0))       AS media_caracteres_corpo,
  COALESCE(j.qtd_criativos_sem_anuncio, 0)                               AS qtd_criativos_sem_anuncio,
  COALESCE(j.qtd_anuncios, 0)                                            AS qtd_anuncios,
  COALESCE(j.qtd_anuncios_ativos, 0)                                     AS qtd_anuncios_ativos,
  COALESCE(j.qtd_anuncios_com_insight, 0)                                AS qtd_anuncios_com_insight,
  (COALESCE(j.qtd_anuncios_com_insight, 0) = 0)                          AS flag_sem_insight,
  j.investimento_micros,
  j.investimento_micros / 1000000                                        AS investimento,
  j.impressoes,
  j.cliques,
  j.leads                                                                AS conversoes_leads,
  j.conversas                                                            AS conversoes_conversas,
  j.compras                                                              AS conversoes_compras,
  CURRENT_TIMESTAMP()                                                    AS _extraido_at
FROM juntos j
LEFT JOIN conta t ON t.id_conta = j.id_conta
