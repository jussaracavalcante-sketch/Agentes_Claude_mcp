-- trs_vjob__municipio  ·  query-ouMW  ·  5.570 linhas  ·  L2 INTERNAL
-- Trusted / VJOB. Grao: um municipio brasileiro. Chave: id_municipio.
-- Origem: mysql-yIOn, `municipio` (5.570) + `estado` (27). Gatilho: evento em query-MZdN.
--
-- E A LISTA OFICIAL COMPLETA DO IBGE, e isso foi medido: 5.570 linhas, 5.570 ids e
--   5.570 codigos distintos, todos com exatamente 7 digitos. Id contiguo de 1 a 5.570.
--
-- TEM CONSUMIDOR: `trs_vjob__cliente.id_cidade` resolve aqui em 289 dos 317 cadastros,
--   com ZERO UF divergente. Sao 18 municipios distintos para 289 clientes.
--   Os 10 que nao casam sao `id_cidade = 0` -- sentinela, nao orfao. A trs_vjob__cliente
--   passou a aplicar NULLIF(cidade, 0) na mesma sessao.
--
-- A REGIAO FOI PROVADA PELA COMPOSICAO, NAO ASSUMIDA. `estado.Regiao` traz 1 a 5 sem
--   tabela de dominio; o conteudo foi medido e bate com as cinco oficiais:
--     1 Norte (7 UFs) · 2 Nordeste (9) · 3 Sudeste (4) · 4 Sul (3) · 5 Centro-Oeste (4)
--   O id cru fica ao lado do rotulo: se a origem mudar a numeracao, o id e a verdade.
--
-- NOME NAO E CHAVE: 5.570 municipios para 5.297 nomes. 506 (9,1%) tem nome que existe
--   em mais de uma UF. Juntar por rotulo funde cidades de estados diferentes.
--
-- TABELA ESTATICA: nao ha coluna de tempo, entao nao ha fuso a tratar.
WITH m AS (SELECT * FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_municipio`),
e AS (SELECT * FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_estado`),
nomes AS (
  SELECT UPPER(TRIM(Nome)) AS nome_norm, COUNT(*) AS qtd
  FROM m GROUP BY nome_norm
),
tratado AS (
  SELECT
    m.Id                              AS id_municipio,
    -- Codigo, nao quantidade: sai como texto para ninguem somar nem tirar media.
    CAST(m.Codigo AS STRING)          AS codigo_ibge,
    NULLIF(TRIM(m.Nome), '')          AS nome_municipio,
    m.Uf                              AS uf,
    e.Id                              AS id_estado,
    NULLIF(TRIM(e.Nome), '')          AS nome_estado,
    CAST(e.CodigoUf AS STRING)        AS codigo_uf_ibge,
    e.Regiao                          AS id_regiao,
    CASE e.Regiao
      WHEN 1 THEN 'Norte'         -- AC AM AP PA RO RR TO
      WHEN 2 THEN 'Nordeste'      -- AL BA CE MA PB PE PI RN SE
      WHEN 3 THEN 'Sudeste'       -- ES MG RJ SP
      WHEN 4 THEN 'Sul'           -- PR RS SC
      WHEN 5 THEN 'Centro-Oeste'  -- DF GO MS MT
    END                               AS nome_regiao,
    (n.qtd > 1)                       AS flag_nome_repetido_no_brasil,
    n.qtd                             AS qtd_municipios_com_este_nome,
    (e.Id IS NULL)                    AS flag_estado_nao_catalogado
  FROM m
  LEFT JOIN e     ON e.Uf = m.Uf
  LEFT JOIN nomes n ON n.nome_norm = UPPER(TRIM(m.Nome))
)
SELECT t.*, CURRENT_TIMESTAMP() AS _extraido_at, 'mysql-yIOn' AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(t))) AS _payload_hash
FROM tratado t
