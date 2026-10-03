-- trs_vjob__auditoria_servico  ·  query-TkGA  ·  1.387 linhas  ·  L2 INTERNAL
-- Trusted / VJOB. Grao: um item do catalogo de auditoria. Chave: id_servico.
-- Origem: tbservicoauditoria (1.387) + tbsetoresauditoria (5) + tbservicosauditoria (27)
-- + tbcategoriasauditoria (4). Gatilho: evento em query-BuYc.
--
-- E A DIMENSAO QUE A trs_vjob__auditoria_cliente DECLAROU NAO EXISTIR: resolve
--   3.025 de 3.025 itens e 1.339 de 1.339 ids, ZERO orfaos.
-- ARMADILHA: a coluna `categoria` aponta para tbservicosauditoria (SUBSERVICO), nao
--   para tbcategoriasauditoria. Contra a primeira 0 orfaos; contra a segunda, 699.
-- Zero e sentinela: 318 itens sem subservico. Nome nao e chave: 1.316 nomes / 1.387 itens.
WITH s AS (
  SELECT * FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbservicoauditoria`
),
sub AS (
  SELECT id, id_categoria, NULLIF(TRIM(nomeservico), '') AS nome
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbservicosauditoria`
),
cat AS (
  SELECT id, NULLIF(TRIM(nomecategoria), '') AS nome
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbcategoriasauditoria`
),
st AS (
  SELECT id, NULLIF(TRIM(REPLACE(REPLACE(nome, '\r', ''), '\n', '')), '') AS nome
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbsetoresauditoria`
),
tratado AS (
  SELECT
    s.id                              AS id_servico,
    NULLIF(TRIM(s.nomeservico), '')   AS nome_servico,
    s.setor                           AS id_setor,
    st.nome                           AS nome_setor,
    NULLIF(s.categoria, 0)            AS id_subservico,
    sub.nome                          AS nome_subservico,
    sub.id_categoria                  AS id_categoria,
    cat.nome                          AS nome_categoria,
    NULLIF(s.dmais, 0)                AS prazo_dias,
    (NULLIF(s.categoria, 0) IS NULL)  AS flag_sem_subservico,
    (st.id IS NULL)                   AS flag_setor_nao_catalogado
  FROM s
  LEFT JOIN st  ON st.id  = s.setor
  LEFT JOIN sub ON sub.id = NULLIF(s.categoria, 0)
  LEFT JOIN cat ON cat.id = sub.id_categoria
)
SELECT t.*, CURRENT_TIMESTAMP() AS _extraido_at, 'mysql-yIOn' AS _fonte,
  'America/Sao_Paulo' AS _fuso, TO_HEX(MD5(TO_JSON_STRING(t))) AS _payload_hash
FROM tratado t
