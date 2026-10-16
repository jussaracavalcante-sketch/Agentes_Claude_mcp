-- trs_facebook_ads__conta
-- Dimensao de conta do Facebook Ads: moeda, fuso, status e razao social por id_conta.
-- Grao: uma conta. Chave: id_conta.
--
-- 2026-10-16: DUAS ORIGENS, declaradas linha a linha em origem_dimensao.
--  (1) SNAPSHOT_RAW_2026-08-26: `vanguardamartech_raw`.`facebook_ads_adaccounts`, tabela ORFA
--      da fonte facebook-ads-mrJt (excluida em 2026-08-26; nunca mais sera reextraida).
--  (2) GRAPH_API_2026-10-16: COMPLEMENTO para as contas integradas DEPOIS do snapshot (fontes
--      publicadas em 09 e 14/10/2026). As fontes novas desabilitam o stream adaccounts (como as
--      7 antigas) e a R-002 impede ligar stream em fonte publicada sem pedido; entao moeda, fuso
--      e status destas contas foram LIDOS NA GRAPH API da Meta em 2026-10-16 (somente leitura,
--      campos name, currency, timezone_name, account_status) e gravados aqui. E dado estatico:
--      moeda e fuso mudam pouco, status NAO e confiavel com o tempo. O conserto definitivo e
--      uma fonte viva com adaccounts habilitado -- nao remendar esta lista.
--      So entram contas que NAO estao no snapshot (anti-join).
WITH snap AS (
  SELECT
    a.account_id                              AS id_conta,
    NULLIF(TRIM(a.name), '')                  AS conta,
    a.currency                                AS moeda,
    a.timezone_name                           AS fuso_conta,
    SAFE_CAST(a.account_status AS INT64)      AS status_codigo,
    NULLIF(TRIM(a.business_name), '')         AS negocio,
    TO_HEX(MD5(TO_JSON_STRING(a)))            AS _payload_hash,
    'SNAPSHOT_RAW_2026-08-26'                 AS origem_dimensao,
    DATE '2026-08-26'                         AS snapshot_em,
    'facebook-ads-mrJt'                       AS _fonte
  FROM `vanguardamartech_raw`.`facebook_ads_adaccounts` a
  QUALIFY ROW_NUMBER() OVER (PARTITION BY a.account_id ORDER BY a.account_id) = 1
),

graph AS (
  SELECT
    c.id_conta,
    NULLIF(TRIM(c.nome), '')                  AS conta,
    c.moeda,
    c.fuso                                    AS fuso_conta,
    c.status                                  AS status_codigo,
    CAST(NULL AS STRING)                      AS negocio,
    TO_HEX(MD5(TO_JSON_STRING(c)))            AS _payload_hash,
    'GRAPH_API_2026-10-16'                    AS origem_dimensao,
    DATE '2026-10-16'                         AS snapshot_em,
    'graph-api-leitura-2026-10-16'            AS _fonte
  FROM UNNEST([
    STRUCT<id_conta STRING, nome STRING, moeda STRING, fuso STRING, status INT64>
    ('100906227323525', 'Hospital Santa Júlia Ads', 'BRL', 'America/Noronha', 1),
    ('1123326336575814', 'Leapmotor Via Marconi Manaus', 'BRL', 'America/Belem', 1),
    ('1158280847839524', 'BA Elétrica', 'BRL', 'America/Noronha', 1),
    ('118981485594379', 'Vanguarda Comunicação', 'BRL', 'America/Noronha', 1),
    ('1238815311536448', 'Vbot', 'BRL', 'America/Manaus', 1),
    ('1322682162728929', 'VEGA Bajaj Manaus (AM) - Anúncios', 'BRL', 'America/Manaus', 1),
    ('1380362517366530', 'Leapmotor VM I Reserva', 'BRL', 'America/Manaus', 1),
    ('1397293557166269', 'Millennium Ads', 'BRL', 'America/Los_Angeles', 1),
    ('1439421523351648', 'CAA | TINTAS EXPRESS', 'BRL', 'America/Sao_Paulo', 1),
    ('180454263287280', 'Comac', 'BRL', 'America/Manaus', 1),
    ('202711331653880', 'Animativ', 'BRL', 'America/Manaus', 1),
    ('206891331753918', 'BIGAZINE - BOLETO', 'BRL', 'America/Campo_Grande', 1),
    ('225015789229106', 'Unipar Ads', 'BRL', 'America/Manaus', 1),
    ('233965209271674', 'Amazoncopy', 'BRL', 'America/Campo_Grande', 1),
    ('2368278856934990', 'Kiffer - ADS', 'BRL', 'America/Manaus', 1),
    ('237569707262055', 'Rei das Mangueiras', 'BRL', 'America/Boa_Vista', 1),
    ('2515845012216186', 'THEREZINHA RUIZ - ELEIÇÃO 2026', 'BRL', 'America/Manaus', 1),
    ('291639228868958', 'Consórcio Chevrolet', 'BRL', 'America/Manaus', 1),
    ('3384094671807625', 'CAA | ALUMÍNIO', 'BRL', 'America/La_Paz', 1),
    ('352441942346792', 'Dr. Cabral', 'BRL', 'America/Noronha', 2),
    ('3540348596114929', 'Pneu Express', 'BRL', 'America/Manaus', 1),
    ('474967098302512', 'CDL MANAUS', 'BRL', 'America/Los_Angeles', 1),
    ('541763807067071', 'CA1 - Move Rental Cars', 'USD', 'America/New_York', 1),
    ('747929494239769', 'AMZ GERADORES', 'BRL', 'America/Manaus', 1),
    ('816285708835072', 'Arena Tintas', 'BRL', 'America/Manaus', 1),
    ('832836096530236', 'DEB TRANSPORTES', 'BRL', 'America/Manaus', 1),
    ('895774876249896', 'Voiké - ADS', 'BRL', 'America/Manaus', 1),
    ('896593304615891', 'Acesso Saúde Manoa', 'BRL', 'America/Manaus', 1),
    ('898300194464871', 'BEST CAR 2026', 'BRL', 'America/La_Paz', 1),
    ('971212355687773', 'Grupo Hage Alimentos', 'BRL', 'America/Manaus', 1),
    ('1519882549713331', 'ADS KL 2026', 'BRL', 'America/Manaus', 1),
    ('598457556599382', 'AMZ IMPORTS', 'BRL', 'America/Sao_Paulo', 1),
    ('1305469349867466', 'Auto Master Consórcio', 'BRL', 'America/Manaus', 1),
    ('621150572624160', 'CA2 - Move Rental Cars', 'USD', 'America/New_York', 1),
    ('157551716528324', 'Acesso Saúde manôa', 'BRL', 'America/Boa_Vista', 1),
    ('2273026959377962', 'Millennium Shopping', 'BRL', 'America/La_Paz', 2)
  ]) c
  LEFT JOIN (SELECT DISTINCT id_conta FROM snap) s ON s.id_conta = c.id_conta
  WHERE s.id_conta IS NULL
),

base AS (
  SELECT * FROM snap
  UNION ALL
  SELECT * FROM graph
)

SELECT
  b.id_conta,
  b.conta,
  -- R-003: cliente recebe o nome DA CONTA, nunca o do grupo.
  b.conta                                                       AS cliente,
  b.moeda,

  -- O date_start dos insights do Facebook vem NESTE fuso, nao num fuso fixo.
  b.fuso_conta,
  (b.fuso_conta IN ('America/Sao_Paulo'))                       AS conta_em_utc_menos_3,

  b.status_codigo                                               AS status_conta_codigo,
  CASE b.status_codigo
    WHEN 1   THEN 'ATIVA'
    WHEN 2   THEN 'DESATIVADA'
    WHEN 3   THEN 'PENDENCIA_FINANCEIRA'
    WHEN 101 THEN 'ENCERRADA'
    WHEN NULL THEN NULL
    ELSE 'OUTRO'
  END                                                           AS status_conta,
  (b.status_codigo = 1)                                         AS ativa,

  -- Razao social do Business Manager. NAO e o nome comercial do cliente e nao
  -- serve para agrupar cliente (R-003). NULL nas contas do complemento Graph.
  b.negocio,

  b.snapshot_em,
  TRUE                                                          AS dimensao_congelada,

  CURRENT_TIMESTAMP()                                           AS _extraido_at,
  b._fonte,
  b._payload_hash,
  b.origem_dimensao
FROM base b