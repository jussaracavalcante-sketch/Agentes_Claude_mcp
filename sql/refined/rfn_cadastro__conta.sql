-- rfn_cadastro__conta
-- Dimensao de conta de midia resolvida por ID, com o gancho de cliente canonico.
-- Grao: uma linha por (plataforma, id_conta_plataforma). Chave: id_conta.
--
-- POR QUE ESTA TABELA E DE CONTA E NAO DE CLIENTE
-- O grao atomico que existe com id real e a CONTA: customer_id no Google Ads,
-- act_id no Facebook. "Cliente" e um conceito de negocio que vive ACIMA da conta
-- e, hoje, nao tem id proprio em lugar nenhum. Entao a tabela e de conta, e o
-- cliente entra como atributo opcional -- nao como grao. Inverter isso obrigaria
-- a inventar o id que falta.
--
-- R-003 RESPEITADA, E E O PONTO CENTRAL DO DESENHO
-- A coluna `cliente` recebe o rotulo DA CONTA, nunca o do grupo. `id_cliente` e
-- coluna SEPARADA e opcional. Cada conta mantem linha e identidade proprias; quem
-- quiser o consolidado agrupa na leitura, por id_cliente ou por id_entidade_legal.
-- A regra proibe FUNDIR contas numa linha so, nao proibe OFERECER a chave de
-- agrupamento ao lado.
--
-- MEDIDO EM 2026-09-15 -- NENHUMA PONTE ENTRE PLATAFORMAS SE SUSTENTA HOJE
--   razao social do Facebook x nome de conta do Google ...... 1 de 61
--   razao social do Facebook x ERP (Conta Azul, com CNPJ) .... 8 de 61
--   razao social do Facebook x rotulo do RD Station .......... 6 de 61
--   rotulo de midia x rotulo de conversao .................... 8 de 42
-- O numero 8 aparecendo tres vezes nao e coincidencia: e o tamanho do conjunto em
-- que alguem escreveu o nome igual nos dois lugares. A causa raiz e estrutural --
-- O GOOGLE ADS NAO PUBLICA ENTIDADE JURIDICA. Nao ha id, CNPJ nem razao social
-- sistematica do lado do Google. O Facebook publica (negocio = razao social do
-- Business Manager), e por isso so ele tem id_entidade_legal preenchido.
--
-- REGRA 1 -- id_entidade_legal agrupa POR EMPRESA, nao por prefixo de nome.
-- E MD5 da razao social normalizada. Isso e evidencia, nao semelhanca: separa
-- corretamente BRAGA MOTORS LTDA (3 contas), BRAGA MOTOS LTDA (5) e BRAGA
-- VEICULOS LTDA (3) como TRES empresas distintas -- exatamente o que a R-003
-- manda respeitar e que o prefixo "BRAGA" faria errado.
--
-- REGRA 2 -- razao_social_normalizada remove sufixo societario de forma
-- deterministica (LTDA, S A, S/A, SA, EIRELI, ME, EPP, SPE LTDA, LIMITADA) e
-- colapsa espaco. Nao e fuzzy matching: e a mesma string sem o sufixo legal.
-- E ela que alcanca 6 rotulos do RD Station.
--
-- REGRA 3 -- id_cliente vem de MAPA CURADO, nunca de calculo.
-- O mapa abaixo comeca com UM par, o unico que eu consigo defender com evidencia
-- alem do rotulo. Todo o resto sai NULL com cliente_canonico_resolvido = FALSE.
-- ISSO E DE PROPOSITO: preencher por semelhanca de nome reintroduziria
-- exatamente o erro que esta tabela existe para eliminar. Cada linha nova do mapa
-- precisa de evidencia declarada na coluna evidencia_do_vinculo.
--
-- LIMITACAO -- NAO CONTORNE
-- Esta tabela NAO resolve "quais contas sao o mesmo cliente" entre plataformas.
-- Ela resolve identidade POR CONTA, agrupamento POR EMPRESA dentro do Facebook, e
-- deixa o vinculo entre plataformas explicitamente em aberto. Quem precisar do
-- consolidado por cliente hoje depende de curadoria humana -- e a flag
-- cliente_canonico_resolvido diz, linha a linha, se ja houve.
--
-- A dimensao de Facebook le uma tabela ORFA (a fonte facebook-ads-mrJt foi
-- excluida em 2026-08-26). dimensao_congelada = TRUE marca isso: e uma foto de
-- 26/08/2026, nao o presente.
WITH mapa_cliente AS (
  SELECT * FROM UNNEST([
    STRUCT('GOOGLE_ADS'   AS plataforma, '1752443056'      AS id_conta_plataforma,
           'ACESSO_SAUDE' AS id_cliente,
           'rotulo identico nas duas plataformas, corroborado pela razao social CLINICA MEDICA ACESSO SAUDE MANAUS LTDA (2026-09-15)' AS evidencia_do_vinculo),
    STRUCT('FACEBOOK_ADS', '261401095311098', 'ACESSO_SAUDE',
           'rotulo identico nas duas plataformas, corroborado pela razao social CLINICA MEDICA ACESSO SAUDE MANAUS LTDA (2026-09-15)')
  ])
),
-- integrada_na_nekt do Facebook e DERIVADA da presenca no fato, nao assumida:
-- a dimensao tem 102 contas do Business Manager e so 7 sao fontes na Nekt.
fb_integradas AS (
  SELECT id_conta, ANY_VALUE(_fonte) AS fonte_nekt
  FROM `vanguardamartech_trusted_facebook_ads.trs_facebook_ads__insight_diario`
  GROUP BY id_conta
),
google AS (
  SELECT
    'GOOGLE_ADS'                       AS plataforma,
    CAST(id_conta AS STRING)           AS id_conta_plataforma,
    conta                              AS conta,
    cliente                            AS cliente,
    CAST(NULL AS STRING)               AS razao_social,
    moeda                              AS moeda,
    CAST(NULL AS STRING)               AS fuso_conta,
    CAST(NULL AS STRING)               AS status_conta,
    CAST(NULL AS BOOL)                 AS ativa_na_plataforma,
    integrada_na_nekt                  AS integrada_na_nekt,
    fonte_nekt                         AS fonte_nekt,
    rotulo_customizado                 AS rotulo_customizado,
    rotulo_diverge_da_plataforma       AS rotulo_diverge_da_plataforma,
    FALSE                              AS dimensao_congelada,
    _extraido_at                       AS _extraido_at,
    _fonte                             AS _fonte
  FROM `vanguardamartech_trusted.trs_google_ads__conta`
),
facebook AS (
  SELECT
    'FACEBOOK_ADS',
    CAST(c.id_conta AS STRING),
    c.conta,
    c.cliente,
    NULLIF(TRIM(c.negocio), ''),
    c.moeda,
    c.fuso_conta,
    c.status_conta,
    c.ativa,
    i.id_conta IS NOT NULL,
    i.fonte_nekt,
    CAST(NULL AS BOOL),
    CAST(NULL AS BOOL),
    c.dimensao_congelada,
    c._extraido_at,
    c._fonte
  FROM `vanguardamartech_trusted_facebook_ads.trs_facebook_ads__conta` c
  LEFT JOIN fb_integradas i ON i.id_conta = c.id_conta
),
uniao AS (SELECT * FROM google UNION ALL SELECT * FROM facebook),
enriquecida AS (
  SELECT
    u.*,
    CASE WHEN u.razao_social IS NULL THEN NULL ELSE
      REGEXP_REPLACE(
        REGEXP_REPLACE(UPPER(u.razao_social),
          r'\s+(LTDA|S\s*A|S/A|SA|EIRELI|ME|EPP|SPE\s+LTDA|LIMITADA)\.?$', ''),
        r'\s+', ' ')
    END AS razao_social_normalizada
  FROM uniao u
)
SELECT
  CONCAT(e.plataforma, ':', e.id_conta_plataforma)                      AS id_conta,
  e.plataforma,
  e.id_conta_plataforma,
  e.conta,
  e.cliente,
  e.razao_social,
  e.razao_social_normalizada,
  IF(e.razao_social_normalizada IS NULL, NULL,
     TO_HEX(MD5(e.razao_social_normalizada)))                           AS id_entidade_legal,
  m.id_cliente                                                          AS id_cliente,
  m.id_cliente IS NOT NULL                                              AS cliente_canonico_resolvido,
  m.evidencia_do_vinculo                                                AS evidencia_do_vinculo,
  e.moeda,
  e.fuso_conta,
  e.status_conta,
  e.ativa_na_plataforma,
  e.integrada_na_nekt,
  e.fonte_nekt,
  e.rotulo_customizado,
  e.rotulo_diverge_da_plataforma,
  e.dimensao_congelada,
  e.razao_social IS NULL                                                AS sem_razao_social,
  e._extraido_at,
  e._fonte,
  TO_HEX(MD5(TO_JSON_STRING(e)))                                        AS _payload_hash
FROM enriquecida e
LEFT JOIN mapa_cliente m
  ON  m.plataforma          = e.plataforma
  AND m.id_conta_plataforma = e.id_conta_plataforma
