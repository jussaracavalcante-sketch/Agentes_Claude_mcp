-- trs_contazul__pessoa
-- Trusted / Conta Azul. Grao: uma pessoa (cliente, fornecedor ou transportadora) do razao Conta Azul.
-- Chave: id_pessoa (2.096 distintos em 2.096 linhas, medido em 2026-10-18).
-- Origem: vanguardamartech_raw.supabase_conta_azul_ca_dim_pessoa (fonte supabase-x0tz).
-- Nivel: L4 PERSONAL_DATA (nome e documento; ha CPF). E-mail, telefone e endereco NAO sao emitidos: so flags.
--
-- POR QUE EXISTE: o razao (trs_contazul__movimento) so trazia id_pessoa e dependia do espelho do MySQL
-- (parado em 17/08/2026) para dar nome e documento. Medido: esta dimensao resolve 4.937 das 4.950 parcelas
-- vigentes com id de entidade; a Trusted de movimento marca 623 como contraparte nao catalogada.
-- DOCUMENTO: so e documento o que tem 14 (CNPJ) ou 11 (CPF) digitos. 13 digitos so e repadronizado
-- (LPAD) quando o valor corrigido JA existe entre os de 14 digitos desta tabela; o fragmento fica fora da chave.
-- id_legado '0' e uuid_legado de zeros sao sentinela e saem NULL.
WITH origem AS (
  SELECT
    id_pessoa,
    operacao,
    NULLIF(TRIM(nome), '')                                       AS nome,
    tipo_pessoa,
    tipo_perfil,
    perfis,
    NULLIF(REGEXP_REPLACE(IFNULL(documento, ''), r'[^0-9]', ''), '') AS documento_digitos_origem,
    NULLIF(NULLIF(TRIM(id_legado), '0'), '')                     AS id_legado_iclips,
    NULLIF(NULLIF(TRIM(uuid_legado), ''), '00000000-0000-0000-0000-000000000000') AS uuid_legado,
    (email IS NOT NULL AND TRIM(email) <> '')                    AS tem_email,
    (telefone IS NOT NULL AND TRIM(telefone) <> '')              AS tem_telefone,
    (endereco IS NOT NULL AND TRIM(endereco) <> '')              AS tem_endereco,
    ativo                                                        AS is_ativo,
    data_criacao,
    ca_updated_at,
    processed_at
  FROM vanguardamartech_raw.supabase_conta_azul_ca_dim_pessoa
),
docs14 AS (
  SELECT DISTINCT documento_digitos_origem AS d FROM origem WHERE LENGTH(documento_digitos_origem) = 14
),
final AS (
  SELECT
    o.*,
    (LENGTH(o.documento_digitos_origem) = 13 AND d.d IS NOT NULL)  AS flag_documento_repadronizado,
    CASE
      WHEN LENGTH(o.documento_digitos_origem) = 13 AND d.d IS NOT NULL THEN d.d
      WHEN LENGTH(o.documento_digitos_origem) IN (11, 14) THEN o.documento_digitos_origem
    END                                                            AS documento
  FROM origem o
  LEFT JOIN docs14 d ON LENGTH(o.documento_digitos_origem) = 13 AND d.d = LPAD(o.documento_digitos_origem, 14, '0')
)
SELECT
  id_pessoa,
  operacao,
  nome,
  tipo_pessoa,
  tipo_perfil,
  REGEXP_CONTAINS(IFNULL(perfis, ''), r'Cliente')         AS is_cliente,
  REGEXP_CONTAINS(IFNULL(perfis, ''), r'Fornecedor')      AS is_fornecedor,
  REGEXP_CONTAINS(IFNULL(perfis, ''), r'Transportadora')  AS is_transportadora,
  documento,
  documento_digitos_origem,
  (LENGTH(IFNULL(documento, '')) = 14)                    AS is_pj,
  (LENGTH(IFNULL(documento, '')) = 11)                    AS is_pf,
  (documento IS NULL AND documento_digitos_origem IS NOT NULL) AS flag_documento_invalido,
  flag_documento_repadronizado,
  (documento IS NULL AND documento_digitos_origem IS NULL) AS flag_sem_documento,
  id_legado_iclips,
  uuid_legado,
  tem_email,
  tem_telefone,
  tem_endereco,
  is_ativo,
  data_criacao,
  ca_updated_at,
  processed_at,
  'L4_PERSONAL_DATA'                                      AS classificacao_dado,
  CURRENT_TIMESTAMP()                                     AS _extraido_at,
  'supabase-x0tz'                                         AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(final)))                      AS _payload_hash
FROM final
