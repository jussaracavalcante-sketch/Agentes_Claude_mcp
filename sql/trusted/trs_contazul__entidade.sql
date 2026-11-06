-- trs_contazul__entidade  ·  query-kwIs  ·  1.828 linhas  ·  L4 PERSONAL_DATA
-- Trusted / Conta Azul. Grao: uma ENTIDADE do Conta Azul. Chave: id_entidade (contaazul_id).
-- Origem: mysql-yIOn — contazul_clientes (661) + contazul_fornecedores (1.299) +
--   contazul_vendedores (20) = 1.980 cadastros. Gatilho: evento em query-MZdN.
--
-- POR QUE EXISTE: e a DIMENSAO que falta ao fato financeiro do Conta Azul. O fato
--   (raw.supabase_conta_azul_ca_fato_evento_financeiro) so tem `id_pessoa` como UUID, sem
--   nome nem documento; este espelho tem nome e documento e nenhum valor. Juntos resolvem
--   5.395 dos 6.768 eventos (79,7%) e 4.950 com DOCUMENTO (73,1%) — medido em 2026-09-25.
--
-- REGRA 1 — DEDUPLICACAO PROVADA. 1.980 cadastros -> 1.828 entidades; 152 aparecem em mais
--   de um papel. Entre cadastros do mesmo contaazul_id: ZERO divergencia de documento, de
--   nome e de `ativo`. `flag_cadastros_divergem` guarda a invariante (FALSE em 1.828/1.828).
-- REGRA 2 — 152 sao CLIENTE e FORNECEDOR ao mesmo tempo; somar as tabelas de origem conta
--   essas duas vezes.
-- REGRA 3 — DOCUMENTO = 14 digitos (CNPJ) ou 11 (CPF), nada mais. 912 PJ, 140 PF, 775 sem
--   documento, 1 invalido: `871768534`, NOVE digitos — a mascara `87.176.853/4___-__` pela
--   metade, o MESMO fragmento ja registrado no VJOB (MOVE RENTAL CARS 335/336) e no
--   financeiro (MOVE COMPANY LLC). Quarto sistema com o mesmo formulario incompleto.
--   Nenhum LPAD: o valor corrigido nao existe entre os documentos validos desta base.
-- REGRA 4 — O SISTEMA CHAMA FORNECEDOR DE "VEICULO" E NAO E. O log de sincronizacao nomeia
--   a carga `veiculos` e os numeros batem (1.297, depois 1.299), mas dos 541 documentos de
--   fornecedor apenas 4 casam com os 92 CNPJs de veiculo da trs_pi__insercao.
-- REGRA 5 — 9 cadastros tem o proprio documento como nome (`flag_nome_e_o_documento`).
-- REGRA 6 — UMA EMPRESA SO: empresa_chave constante, resolve para 07.865.616/0001-74,
--   VANGUARDA COMUNICACAO (razao social B R M COSTA DE LIMA). Nao cobre VD nem VBOT.
--
-- FUSO: sem conversao. Timestamps do MySQL `vjob_2024`, que a casa ja mediu gravar hora
--   local. As tabelas do Conta Azul nao tem eventos suficientes para medicao independente —
--   a premissa e herdada do BANCO, nao do sistema, e esta declarada.
--
-- COBERTURA COM A IDENTIDADE DA CASA (625 documentos validos de cliente): 414 em
--   rfn_cadastro__cliente_sk, 381 em trs_financeiro__movimento, 122 em trs_vjob__cliente.
--   Sao 211 documentos que o Conta Azul conhece e a cliente_sk ainda nao.
--
-- LIMITACOES — NAO CONTORNE
--   1. O ESPELHO ESTA CONGELADO: ultima sincronizacao 17/08/2026 (vendedores 19/08),
--      enquanto o fato recebe dado ate 15/09. Por isso 822 eventos apontam para pessoa que
--      este espelho nao tem.
--   2. contazul_sincronizacoes NAO fecha com a tabela: tres cargas de servicos registram
--      `recebidos = 5000` (teto de paginacao) e a tabela tem 403.
--   3. `is_ativo` e o cadastro, nao atividade financeira (1.809 de 1.828 ativas).
--   4. Nao ha telefone, endereco nem inscricao estadual.
--
-- L4: 140 entidades com CPF e 20 vendedores nominais. O documento NAO foi removido porque e
--   a unica chave para o resto da casa — filtrar `is_pf = FALSE` ou agregar antes de expor.

WITH bruto AS (
  SELECT id, empresa_chave, contaazul_id, id_legado, nome, nome_fantasia, razao_social,
         codigo, documento, email, ativo, sincronizado_em, criado_em, atualizado_em,
         'CLIENTE' AS papel
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_contazul_clientes`
  UNION ALL
  SELECT id, empresa_chave, contaazul_id, id_legado, nome, nome_fantasia, razao_social,
         codigo, documento, email, ativo, sincronizado_em, criado_em, atualizado_em,
         'FORNECEDOR'
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_contazul_fornecedores`
  UNION ALL
  SELECT id, empresa_chave, contaazul_id, id_legado, nome, CAST(NULL AS STRING), CAST(NULL AS STRING),
         codigo, documento, email, ativo, sincronizado_em, criado_em, atualizado_em,
         'VENDEDOR'
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_contazul_vendedores`
),
digitos AS (
  SELECT b.*,
    NULLIF(REGEXP_REPLACE(COALESCE(b.documento, ''), r'[^0-9]', ''), '') AS doc_digitos
  FROM bruto b
),
agrupado AS (
  SELECT
    contaazul_id,
    COUNT(*)                                            AS qtd_cadastros,
    LOGICAL_OR(papel = 'CLIENTE')                       AS is_cliente,
    LOGICAL_OR(papel = 'FORNECEDOR')                    AS is_fornecedor,
    LOGICAL_OR(papel = 'VENDEDOR')                      AS is_vendedor,
    STRING_AGG(DISTINCT papel, '+' ORDER BY papel)      AS papeis,
    MAX(nome)                                           AS nome,
    MAX(nome_fantasia)                                  AS nome_fantasia,
    MAX(razao_social)                                   AS razao_social,
    MAX(codigo)                                         AS codigo,
    MAX(email)                                          AS email,
    MAX(documento)                                      AS documento_na_origem,
    MAX(doc_digitos)                                    AS doc_digitos,
    MAX(id_legado)                                      AS id_legado,
    MAX(empresa_chave)                                  AS empresa_chave,
    LOGICAL_OR(ativo = 1)                               AS is_ativo,
    MAX(sincronizado_em)                                AS sincronizado_em,
    MIN(criado_em)                                      AS criado_em,
    MAX(atualizado_em)                                  AS atualizado_em,
    (COUNT(DISTINCT IFNULL(documento, '~')) > 1
      OR COUNT(DISTINCT IFNULL(nome, '~')) > 1
      OR COUNT(DISTINCT ativo) > 1)                     AS flag_cadastros_divergem,
    STRING_AGG(CAST(id AS STRING) || ':' || papel, ' | ' ORDER BY papel) AS ids_na_origem
  FROM digitos
  GROUP BY contaazul_id
),
final AS (
  SELECT
    a.contaazul_id                                      AS id_entidade,
    a.papeis,
    a.is_cliente, a.is_fornecedor, a.is_vendedor,
    (a.is_cliente AND a.is_fornecedor)                  AS is_cliente_e_fornecedor,
    a.qtd_cadastros,
    a.flag_cadastros_divergem,
    a.ids_na_origem,
    CAST(a.id_legado AS STRING)                         AS id_legado,

    a.nome, a.nome_fantasia, a.razao_social, a.codigo, a.email,

    IF(LENGTH(a.doc_digitos) IN (11, 14), a.doc_digitos, NULL)      AS documento,
    a.doc_digitos                                                    AS documento_digitos_origem,
    a.documento_na_origem,
    (a.doc_digitos IS NOT NULL AND LENGTH(a.doc_digitos) NOT IN (11, 14))
                                                                     AS flag_documento_invalido,
    (LENGTH(a.doc_digitos) = 14)                                     AS is_pj,
    (LENGTH(a.doc_digitos) = 11)                                     AS is_pf,
    (a.doc_digitos IS NULL)                                          AS flag_sem_documento,
    (a.nome IS NOT NULL
      AND REGEXP_REPLACE(a.nome, r'[^0-9]', '') != ''
      AND REGEXP_REPLACE(a.nome, r'[^0-9]', '') = a.doc_digitos)     AS flag_nome_e_o_documento,

    a.is_ativo,
    a.empresa_chave,
    e.documento                                          AS empresa_documento,
    e.nome_fantasia                                      AS empresa_nome_fantasia,

    a.criado_em, a.atualizado_em, a.sincronizado_em
  FROM agrupado a
  LEFT JOIN `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_contazul_empresas` e
    ON e.chave = a.empresa_chave
)
SELECT
  f.*,
  'L4_PERSONAL_DATA'                            AS classificacao_dado,
  CURRENT_TIMESTAMP()                           AS _extraido_at,
  'mysql-yIOn'                                  AS _fonte,
  'America/Sao_Paulo'                           AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(f)))                AS _payload_hash
FROM final f
