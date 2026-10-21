-- trs_google_ads__geo_alvo
-- PUBLICADA em 2026-09-28 como query-Jn5l, camada Trusted, folder google_ads.
-- Grao: um alvo geografico do Google (geoTargetConstant). 270.938 linhas, 270.938 ids.
-- Origem: o stream `geo_target_constant`, presente em TODA camada de conta Google Ads.
--
-- E A DIMENSAO QUE FALTAVA PARA LER A trs_google_ads__segmento_localizacao_usuario.
-- Aquela tabela (827.446 linhas) carrega SO ID NUMERICO -- 9.965 cidades e 1.467
-- regioes, nenhum nome. Sem esta dimensao, o maior breakdown geografico da casa e
-- ilegivel.
--
-- POR QUE LER TRES COPIAS E NAO AS 40 -- MEDIDO, NAO SUPOSTO. O Google devolve a
-- lista global inteira para cada conta, entao as 40 camadas guardam a MESMA tabela
-- (~10,8 milhoes de linhas duplicadas). Medido em 2026-09-28 em tres contas
-- (dr_cabral_conta_1, acesso_saude, braga_varejo): 270.938 linhas nas tres E o MESMO
-- hash agregado da tabela inteira (557640a956c05678bce0c32d6d5f1516) -- identicas
-- byte a byte. Ler uma so bastaria pelo conteudo.
-- LEMOS TRES POR RESILIENCIA, e a razao tem precedente nesta base: a `github-s0VO`
-- caiu com 401 e a extracao ESVAZIOU a dimensao `github_repositories` (10 -> 0 linhas)
-- enquanto os fatos continuaram la. Com tres copias, uma fonte que esvazie nao apaga
-- a dimensao. `qtd_copias_lidas` e `flag_copias_divergem` tornam o caso visivel:
-- hoje 270.938 ids com 3 copias e ZERO divergencia. Se um id passar a divergir, a
-- flag acende em vez de a query escolher em silencio.
--
-- COBERTURA CONTRA QUEM CONSOME, medida em 2026-09-28:
--   trs_google_ads__segmento_localizacao_usuario -- paises 152 de 152 (zero orfaos),
--   regioes 1.461 de 1.467 (6 orfas, 328 linhas), cidades 9.928 de 9.965 (37 orfas,
--   829 linhas). Orfao aqui e 0,1% das linhas e NAO e sentinela -- sao ids de alvo
--   que a constante extraida nao traz (alvo criado ou retirado depois da carga).
--   trs_google_ads__segmento_geografico -- paises 197 de 199 (2 orfaos).
-- O join de quem consome tem de ser LEFT, com flag. Com INNER as linhas somem sem sinal.
--
-- COLUNAS NAO EMITIDAS, de proposito:
--   `status` -- constante 'ENABLED' nas 270.938 linhas. Campo morto: emitido,
--     convidaria a filtrar por algo que nao varia.
--   `resource_name` -- e literalmente 'geoTargetConstants/<id>', redundante com a chave.
--
-- NOME DO PAIS TEM DUAS ROTAS, declaradas linha a linha em `origem_do_nome_pais`.
-- A autoridade e a linha de tipo 'Country' casada por `country_code`: 219 codigos a
-- tem. Os outros 28 codigos (PR, HK, TW, GL, MO, PS, XK, territorios em geral) nao
-- tem linha propria de pais, e para eles o nome sai do ULTIMO elemento de
-- `canonical_name` -- 1.569 linhas, 0,6%. O fallback e declarado porque `canonical_name`
-- e texto separado por virgula: um toponimo com virgula quebraria o corte, e e por
-- isso que ele e a segunda rota e nunca a primeira.
--
-- L2 INTERNAL. E catalogo publico do Google, sem dado de cliente nem pessoa.
WITH bruto AS (
  SELECT 'dr_cabral_conta_1' AS _copia, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.*
    FROM `vanguardamartech_dr_cabral_conta_1`.`google_ads_dr_cabral_1geo_target_constant` x
  UNION ALL
  SELECT 'acesso_saude', TO_HEX(MD5(TO_JSON_STRING(x))), x.*
    FROM `vanguardamartech_acesso_saude_google_ads`.`google_ads_acesso_saudegeo_target_constant` x
  UNION ALL
  SELECT 'braga_varejo', TO_HEX(MD5(TO_JSON_STRING(x))), x.*
    FROM `vanguardamartech_braga_varejo`.`google_ads_braga_varejogeo_target_constant` x
),
-- Quantas copias trouxeram este id, e quantas VERSOES distintas. Divergencia entre
-- copias vira flag, nunca escolha silenciosa.
por_id AS (
  SELECT
    CAST(id AS STRING)            AS id_alvo_geo,
    COUNT(*)                      AS qtd_copias_lidas,
    COUNT(DISTINCT _payload_hash) AS qtd_versoes_distintas
  FROM bruto
  GROUP BY 1
),
escolhida AS (
  SELECT * FROM (
    SELECT b.*, ROW_NUMBER() OVER (
      PARTITION BY CAST(b.id AS STRING) ORDER BY b._copia
    ) AS rn
    FROM bruto b
  ) WHERE rn = 1
),
-- Rota 1 do nome do pais: a propria linha de tipo 'Country'. 219 de 247 codigos.
pais AS (
  SELECT country_code AS cc, ANY_VALUE(name) AS nome_pais
  FROM escolhida
  WHERE target_type = 'Country'
  GROUP BY 1
)
SELECT
  CAST(e.id AS STRING)                                        AS id_alvo_geo,
  NULLIF(TRIM(e.name), '')                                    AS nome,
  NULLIF(TRIM(e.canonical_name), '')                          AS nome_canonico,
  NULLIF(TRIM(e.target_type), '')                             AS tipo_alvo,
  NULLIF(TRIM(e.country_code), '')                            AS codigo_pais,
  COALESCE(
    p.nome_pais,
    NULLIF(TRIM(SPLIT(e.canonical_name, ',')[
      SAFE_OFFSET(ARRAY_LENGTH(SPLIT(e.canonical_name, ',')) - 1)]), '')
  )                                                           AS nome_pais,
  CASE WHEN p.nome_pais IS NOT NULL THEN 'LINHA_COUNTRY'
       ELSE 'ULTIMO_ELEMENTO_DO_CANONICO' END                 AS origem_do_nome_pais,
  (e.target_type = 'Country')                                 AS flag_e_pais,
  i.qtd_copias_lidas,
  (i.qtd_versoes_distintas > 1)                               AS flag_copias_divergem,

  CURRENT_TIMESTAMP()                                         AS _extraido_at,
  e._copia                                                    AS _fonte,
  e._payload_hash
FROM escolhida e
JOIN por_id i ON i.id_alvo_geo = CAST(e.id AS STRING)
LEFT JOIN pais p ON p.cc = e.country_code
