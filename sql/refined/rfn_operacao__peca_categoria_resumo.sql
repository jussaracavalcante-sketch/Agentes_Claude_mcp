-- rfn_operacao__peca_categoria_resumo  ·  Refined / operacao  ·  L2 INTERNAL
-- Grao: um nome de categoria de peca do iClips NORMALIZADO (sem caixa/acento). Le: trs_iclips__peca_categoria. Gatilho: evento em query-Lrtd.
-- Identidade (07/10/2026): 29 ids = 29 · 25 linhas · 309 tipos de peca com categoria · 97 com valor · 5 ids sem uso.
-- R1 Off e OFF sao categorias DIFERENTES por id (OFF sao tres cadastros); aqui entram numa linha so, e qtd_nomes_exatos mostra quantas grafias ha.
-- R2 qtd_tipos_de_peca soma por NOME EXATO (cada tipo uma vez); somar por id contaria os tipos de OFF tres vezes (413 contra 309).
-- R3 Categoria sem nome vai para o balde '(sem nome)', nunca descartada.
-- LIMITE: so 309 dos 1.049 tipos de peca (29,5%) tem categoria — o buraco e de preenchimento na origem.
WITH c AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_iclips__peca_categoria`
),
ids AS (
  SELECT
    COALESCE(nome_normalizado, '(sem nome)') AS chave,
    COUNT(*) AS qtd_ids,
    COUNTIF(flag_categoria_sem_uso) AS qtd_ids_sem_uso,
    COUNT(DISTINCT nome) AS qtd_nomes_exatos
  FROM c
  GROUP BY 1
),
por_nome AS (
  SELECT
    COALESCE(nome_normalizado, '(sem nome)') AS chave,
    nome,
    ANY_VALUE(qtd_tipos_de_peca_com_este_nome) AS tp,
    ANY_VALUE(qtd_tipos_com_valor_com_este_nome) AS tv
  FROM c
  GROUP BY 1, nome
),
tip AS (
  SELECT chave, SUM(tp) AS qtd_tipos_de_peca, SUM(tv) AS qtd_tipos_com_valor
  FROM por_nome
  GROUP BY 1
),
final AS (
  SELECT i.chave AS id_categoria_normalizada, i.qtd_ids, i.qtd_nomes_exatos, i.qtd_ids_sem_uso, t.qtd_tipos_de_peca, t.qtd_tipos_com_valor,
    (i.chave = '(sem nome)') AS flag_sem_nome, 'L2_INTERNAL' AS classificacao_dado
  FROM ids i
  JOIN tip t USING (chave)
)
SELECT f.*, CURRENT_TIMESTAMP() AS _extraido_at, 'rest-api-xk4P' AS _fonte,
  'America/Sao_Paulo' AS _fuso, TO_HEX(MD5(TO_JSON_STRING(f))) AS _payload_hash
FROM final f
