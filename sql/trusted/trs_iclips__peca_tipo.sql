-- trs_iclips__peca_tipo
-- Trusted / iClips. Grao: um TIPO de peca do catalogo do iClips. Chave: id_peca.
-- Origem: vanguardamartech_raw.supabase_silver_iclips_peca (fonte supabase-x0tz),
--         enriquecida com o catalogo canonico (map_peca_canonica + dim_peca_canonica).
--
-- POR QUE ESTA TABELA EXISTE
--   Ela e a unica dimensao da base que carrega VALOR UNITARIO por tipo de peca.
--   Ate aqui, custo de peca so existia por hora apontada -- que cobre 1,2% das
--   pecas (ver rfn_operacao__peca, limitacao 1). O valor de tabela cobre 43,3%.
--
-- ATENCAO AO SUJEITO -- `valor_tabela` E PRECO, NAO CUSTO.
--   E o valor do tipo de peca no catalogo do iClips: o que a peca VALE na tabela
--   da casa, nao o que ela CUSTA para produzir. Quem somar esta coluna esperando
--   custo vai somar receita potencial. O custo rateado fica na Refined
--   rfn_operacao__custo_peca, que usa este valor apenas como PESO de rateio.
--
-- EQUIVALENCIA PROVADA COM O CATALOGO CANONICO (medido em 2026-09-23)
--   dim_peca_canonica.valor_referencia e copia deste valor, nao fonte alternativa:
--   dos 65 tipos com valor nos dois lados, **65 batem ao centavo e ZERO divergem**.
--   E o iClips cobre mais: 147 tipos com valor contra 65 do canonico. Por isso o
--   valor sai do iClips e o canonico entra so como rotulo (id, nome, grupo, prefixo).
--   No grao da entrega a mesma prova se repete: 13.720 de 13.720 iguais.
--
-- ZERO E SENTINELA, NAO VALOR. 902 dos 1.049 tipos tem `valor = 0` na origem e
--   nenhum tem NULL. Zero aqui significa "nao precificado", e vira NULL --
--   senao qualquer media de valor por peca desaba contra 902 zeros falsos.
--
-- CAMPOS MORTOS, MEDIDOS: `template_id` vazio em 1.049 de 1.049 e
--   `workflow_customizado` FALSE em 1.049 de 1.049. Ficam FORA desta tabela --
--   emiti-los convidaria a filtrar por eles e receber a base inteira.
--
-- CATEGORIA TEM DUPLICATA DE CAIXA, E ELA NAO E COSMETICA (R-004 nao se aplica):
--   22 rotulos distintos viram 21 em UPPER -- o par e `Off` e `OFF`. E os dois NAO
--   sao a mesma geracao de catalogo: `Off` tem 95% dos tipos precificados e `OFF`
--   tem ZERO. A coluna crua FICA (`categoria`) e a normalizada entra ao lado
--   (`categoria_normalizada`), porque agrupar pela normalizada mistura precificado
--   com nao precificado e agrupar pela crua esconde que sao o mesmo grupo.
--
-- FUSO: `atualizado_em` tem hora <> 00:00 nos 1.049 registros -- e instante de
--   verdade, e o iClips ja grava America/Sao_Paulo. NAO converter.
WITH catalogo AS (
  SELECT
    CAST(peca_id AS STRING)                                   AS id_peca,
    NULLIF(TRIM(nome), '')                                    AS nome_peca,
    NULLIF(TRIM(categoria), '')                               AS categoria,
    -- sentinela 0 -> NULL
    IF(valor > 0, valor, NULL)                                AS valor_tabela,
    ativo                                                     AS is_ativo,
    qtd_etapas,
    checklist_done,
    checklist_total,
    atualizado_em
  FROM `vanguardamartech_raw`.`supabase_silver_iclips_peca`
),
-- O mapa liga NOME cru -> id canonico. E o unico caminho: o catalogo do iClips
-- nao carrega o id canonico. Cobre 273 dos 1.049 tipos (26%).
canonico AS (
  SELECT
    m.piece_name_raw,
    k.piece_canonical_id,
    k.piece_canonical_name,
    NULLIF(TRIM(k.prefixo), '')  AS prefixo,
    NULLIF(TRIM(k.grupo), '')    AS grupo,
    IF(k.valor_referencia > 0, k.valor_referencia, NULL) AS valor_referencia_canonico,
    k.ativo AS canonico_ativo
  FROM `vanguardamartech_raw`.`supabase_public_map_peca_canonica` m
  LEFT JOIN `vanguardamartech_raw`.`supabase_public_dim_peca_canonica` k
         ON k.piece_canonical_id = m.piece_canonical_id
),
juntado AS (
  SELECT
    c.id_peca,
    c.nome_peca,
    c.categoria,
    UPPER(c.categoria)                                        AS categoria_normalizada,
    c.valor_tabela,
    (c.valor_tabela IS NULL)                                  AS flag_sem_valor,
    c.is_ativo,
    c.qtd_etapas,
    c.checklist_done,
    c.checklist_total,

    n.piece_canonical_id                                      AS id_peca_canonica,
    n.piece_canonical_name                                    AS peca_canonica,
    n.prefixo                                                 AS prefixo_canonico,
    n.grupo                                                   AS grupo_canonico,
    n.canonico_ativo                                          AS is_ativo_no_canonico,
    (n.piece_canonical_id IS NOT NULL)                        AS flag_canonizada,
    n.valor_referencia_canonico,
    -- auditoria da equivalencia: TRUE so quando os dois existem e divergem
    (c.valor_tabela IS NOT NULL
      AND n.valor_referencia_canonico IS NOT NULL
      AND ABS(c.valor_tabela - n.valor_referencia_canonico) >= 0.01) AS flag_valor_diverge_do_canonico,

    c.atualizado_em                                           AS atualizado_em
  FROM catalogo c
  LEFT JOIN canonico n ON n.piece_name_raw = c.nome_peca
)
SELECT
  j.*,
  CURRENT_TIMESTAMP()                                         AS _extraido_at,
  'supabase-x0tz'                                             AS _fonte,
  'America/Sao_Paulo'                                         AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(j)))                              AS _payload_hash
FROM juntado j
