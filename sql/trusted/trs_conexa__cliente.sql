-- trs_conexa__cliente  ·  query-mbpv  ·  133 linhas  ·  L4 PERSONAL_DATA
-- Trusted / Conexa (VBOT). Grao: um cliente. Chave: id_cliente (conexa_id).
-- Origem: supabase-x0tz — public-dim_cliente_vbot (133) + bronze-conexa__customers (384).
-- Gatilho: evento em supabase-x0tz (diaria 01:00->03:29). Primeira Trusted da familia.
--
-- O CONEXA e o sistema de gestao da VBOT — contratos, cobrancas, vendas e despesas do SaaS.
-- Entra pela supabase-x0tz em 88 STREAMS, e nao por fonte propria: nao existe conector
-- "conexa" na Nekt.
--
-- REGRA 1 — O BRONZE DO CONEXA E UM LOG DE VERSOES, NAO UMA COPIA DE ESTADO.
--   384 linhas para 133 clientes (2,89 versoes em media, maximo 5), cada uma com payload_hash
--   e fetched_at proprios. CONTAR LINHA DO BRONZE SUPERCONTA. Vale para a familia inteira:
--   charges 5.197/933 (5,6x) · sales 9.417/3.638 (2,6x) · bills 3.025/1.458 (2,1x) ·
--   contracts 529/139 (3,8x). Esta tabela le a ULTIMA versao por natural_key e emite
--   qtd_versoes, primeira_versao_em e versao_lida_em.
-- REGRA 2 — O DERIVADO DO SUPABASE E FIEL, E ISSO FOI MEDIDO. Ao contrario do VJOB, onde o
--   derivado PERDIA coluna (datahoramarcado), aqui a dim_cliente_vbot reproduz o bronze campo
--   a campo: cidade 131=131, CEP 131=131, CNPJ 128=128, CPF 4=4, e-mail 132=132 — e ACRESCENTA
--   `segmento` (123), que nao existe no payload da API. Por isso a base e o derivado e o
--   bronze entra so para o que ele nao emite: logradouro, numero, bairro, complemento, os
--   arrays de telefone e e-mail, ramo de atividade e as regras de NFSe.
-- REGRA 3 — BRONZE E `raw_conexa_*` SAO A MESMA EXTRACAO, GRAVADA DUAS VEZES. Os 13
--   `bronze-conexa__*` e os 13 `public-raw_conexa_*` tem a mesma contagem em todas as
--   entidades medidas e — a prova que decide — o MESMO payload e o MESMO payload_hash
--   (conferido em plans: 56676e053f2984017881a3855c9adc3b dos dois lados, mesmo fetched_at).
--   Muda so o envelope. A casa extrai 26 streams onde 13 bastariam — achado, nao corrigido
--   (R-002).
-- REGRA 4 — DOCUMENTO = 14 digitos (CNPJ) ou 11 (CPF). 128 CNPJ, 4 CPF, 132 de 133 validos —
--   a cobertura mais alta de qualquer cadastro desta base (VJOB 53%, Conta Azul 58%).
-- REGRA 5 — UMA EMPRESA SO: companyId = 3 nas 384 linhas do bronze. A hipotese de que o
--   bronze traria varias empresas e o derivado filtraria uma foi TESTADA E DESCARTADA.
--
-- CAMPO MORTO: legalPerson.stateInscription e NULL nas 133 e NAO e emitido.
-- FUSO: sem conversao — data_cadastro, fetched_at e processed_at sao carimbo de sistema (UTC).
--
-- LIMITACOES — NAO CONTORNE
--   1. NAO HA `presente_no_origem` AQUI. Os fatos da familia tem, e vale muito (72 cobrancas e
--      240 despesas ja apagadas no Conexa seguem no warehouse). Pela dimensao de cliente NAO
--      da para saber se um cliente foi excluido na origem.
--   2. `tipo_pessoa` vem do derivado e nao foi reconciliado com is_pj/is_pf, que saem do
--      comprimento do documento. Onde discordarem, o documento e a evidencia.
--   3. `segmento` e enriquecimento do derivado, sem equivalente na API — nao auditavel.
--   4. A ligacao com o resto da casa e por DOCUMENTO; o id do Conexa nao aparece em nenhum
--      outro sistema. rfn_cadastro__cliente_sk ja trata o Conexa como sistema proprio.
--
-- L4: 4 clientes PF com CPF, mais e-mail, telefone, endereco completo e login de 133 clientes.
--   Nao publicar em painel sem agregar ou sem remover contato e endereco.

WITH bronze AS (
  SELECT
    SAFE_CAST(natural_key AS INT64)                 AS conexa_id,
    payload,
    fetched_at,
    ROW_NUMBER() OVER (PARTITION BY natural_key ORDER BY fetched_at DESC) AS rn,
    COUNT(*)     OVER (PARTITION BY natural_key)    AS qtd_versoes,
    MIN(fetched_at) OVER (PARTITION BY natural_key) AS primeira_versao_em
  FROM `vanguardamartech_raw`.`supabase_bronze_conexa__customers`
),
b AS (
  SELECT * FROM bronze WHERE rn = 1
),
final AS (
  SELECT
    d.conexa_id                                     AS id_cliente,
    d.company_id                                    AS id_empresa,
    d.nome,
    d.nome_fantasia,
    d.primeiro_nome,
    d.tipo                                          AS tipo_pessoa,

    IF(LENGTH(REGEXP_REPLACE(COALESCE(d.cnpj, d.cpf, ''), r'[^0-9]', '')) IN (11, 14),
       REGEXP_REPLACE(COALESCE(d.cnpj, d.cpf, ''), r'[^0-9]', ''), NULL)
                                                    AS documento,
    NULLIF(REGEXP_REPLACE(COALESCE(d.cnpj, d.cpf, ''), r'[^0-9]', ''), '')
                                                    AS documento_digitos_origem,
    (LENGTH(REGEXP_REPLACE(COALESCE(d.cnpj, ''), r'[^0-9]', '')) = 14)  AS is_pj,
    (LENGTH(REGEXP_REPLACE(COALESCE(d.cpf,  ''), r'[^0-9]', '')) = 11)  AS is_pf,
    (NULLIF(REGEXP_REPLACE(COALESCE(d.cnpj, d.cpf, ''), r'[^0-9]', ''), '') IS NOT NULL
      AND LENGTH(REGEXP_REPLACE(COALESCE(d.cnpj, d.cpf, ''), r'[^0-9]', '')) NOT IN (11, 14))
                                                    AS flag_documento_invalido,

    d.is_ativo,
    d.is_bloqueado,
    d.data_fundacao,
    d.segmento,
    d.plano_raw,
    d.login,
    d.data_cadastro,

    d.telefone                                      AS telefone_principal,
    d.email_financeiro,
    JSON_VALUE_ARRAY(b.payload, '$.phones')                     AS telefones,
    JSON_VALUE_ARRAY(b.payload, '$.emailsFinancialMessages')    AS emails_financeiros,
    JSON_VALUE_ARRAY(b.payload, '$.emailsMessage')              AS emails_gerais,

    d.cidade,
    d.estado                                        AS uf,
    d.cep,
    JSON_VALUE(b.payload, '$.address.street')       AS logradouro,
    JSON_VALUE(b.payload, '$.address.number')       AS numero,
    JSON_VALUE(b.payload, '$.address.neighborhood') AS bairro,
    JSON_VALUE(b.payload, '$.address.additionalDetails') AS complemento,

    JSON_VALUE(b.payload, '$.fieldOfActivity')      AS ramo_de_atividade,
    (JSON_VALUE(b.payload, '$.isForeign') = 'true') AS is_estrangeiro,
    (JSON_VALUE(b.payload, '$.hasLoginAccess') = 'true') AS tem_acesso_login,
    JSON_VALUE(b.payload, '$.automaticallyIssueNfse')    AS regra_emissao_nfse,
    JSON_VALUE(b.payload, '$.legalPerson.municipalInscription') AS inscricao_municipal,

    d.tags_id,

    b.qtd_versoes,
    b.primeira_versao_em,
    b.fetched_at                                    AS versao_lida_em,
    (b.conexa_id IS NULL)                           AS flag_sem_bronze,

    d.processed_at
  FROM `vanguardamartech_raw`.`supabase_public_dim_cliente_vbot` d
  LEFT JOIN b ON b.conexa_id = d.conexa_id
)
SELECT
  f.*,
  'L4_PERSONAL_DATA'                            AS classificacao_dado,
  CURRENT_TIMESTAMP()                           AS _extraido_at,
  'supabase-x0tz'                               AS _fonte,
  'America/Sao_Paulo'                           AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(f)))                AS _payload_hash
FROM final f
