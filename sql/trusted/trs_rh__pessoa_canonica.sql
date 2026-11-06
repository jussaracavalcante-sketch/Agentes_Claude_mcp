-- trs_rh__pessoa_canonica
-- Trusted / RH. Grao: um ALIAS de pessoa (match_tipo, chave) com a pessoa canonica desaninhada na linha. Chave: id_alias = match_tipo | chave.
-- Origem: vanguardamartech_raw.supabase_meta_pessoa (294) + supabase_meta_pessoa_alias (1.272), fonte supabase-x0tz, diaria. Medido em 2026-10-19:
-- 1.272 aliases, 1.272 chaves distintas (a chave e unica mesmo sem o tipo), 294 pessoas, zero alias orfao; todas as 294 pessoas tem ao menos um
-- alias (NOME_NORM 305 cobre as 294). As 294 pessoas tem id, nome e pessoa_norm unicos, tipo 'pessoa' em todas, obs 'seed F1 - roster RH' em todas,
-- atualizado_em 2026-08-10 13:41:42 em todas (semente unica, nunca editada; atualizado_por NULL em 100%).
-- CINCO TIPOS DE ALIAS, medidos: NOME_NORM 305 (294 pessoas) · QULTURE_EMAIL 294 (294) · ICLIPS_EXECUTOR_ID 288 (256 pessoas: ha pessoa com mais de
-- um id de executor no iClips) · FIN_CPF_CNPJ 241 (176 pessoas; 161 CPF de 11 digitos + 80 CNPJ de 14, zero fora de forma) · QULTURE_CONTRACT 144.
-- E a tabela de identidade de PESSOA da casa: resolve o mesmo colaborador entre Qulture (e-mail/contrato), iClips (id de executor) e financeiro
-- (CPF ou CNPJ de quem recebe). Nao confundir com rfn_cadastro__cliente_sk, que resolve CLIENTE por documento.
-- Nivel: L4 PERSONAL_DATA -- nome, e-mail, CPF. A Refined (rfn_rh__pessoa_canonica_resumo) so conta por tipo de alias; nenhuma chave atravessa.
-- Fuso: `atualizado_em` e instante UTC do Supabase, sem conversao.
WITH p AS (
  SELECT pessoa_id, nome_canonico, pessoa_norm, tipo, obs AS obs_pessoa
  FROM `vanguardamartech_raw`.`supabase_meta_pessoa`
),
a AS (
  SELECT match_tipo, chave, pessoa_id, origem, obs, atualizado_em, atualizado_por,
         COUNT(*) OVER (PARTITION BY pessoa_id)             AS qtd_aliases_da_pessoa,
         COUNT(*) OVER (PARTITION BY pessoa_id, match_tipo) AS qtd_aliases_do_tipo_na_pessoa
  FROM `vanguardamartech_raw`.`supabase_meta_pessoa_alias`
),
tratado AS (
  SELECT
    CONCAT(a.match_tipo, '|', a.chave)                                             AS id_alias,
    CAST(a.pessoa_id AS STRING)                                                    AS id_pessoa,
    NULLIF(TRIM(p.nome_canonico), '')                                              AS nome_canonico,
    p.pessoa_norm,
    p.tipo                                                                         AS tipo_pessoa,
    a.match_tipo,
    a.chave,
    CASE WHEN a.match_tipo = 'FIN_CPF_CNPJ' AND REGEXP_CONTAINS(a.chave, r'^\d{11}$') THEN 'CPF'
         WHEN a.match_tipo = 'FIN_CPF_CNPJ' AND REGEXP_CONTAINS(a.chave, r'^\d{14}$') THEN 'CNPJ'
         WHEN a.match_tipo = 'FIN_CPF_CNPJ'                                            THEN 'INVALIDO'
         ELSE NULL END                                                             AS tipo_documento,
    (a.match_tipo = 'NOME_NORM' AND a.chave = p.pessoa_norm)                       AS flag_alias_e_o_nome_canonico,
    a.qtd_aliases_da_pessoa,
    a.qtd_aliases_do_tipo_na_pessoa,
    a.origem                                                                       AS origem_do_alias,
    NULLIF(TRIM(a.obs), '')                                                        AS obs,
    NULLIF(TRIM(p.obs_pessoa), '')                                                 AS obs_pessoa,
    a.atualizado_em,
    a.atualizado_por,
    (p.pessoa_id IS NULL)                                                          AS flag_pessoa_nao_catalogada
  FROM a
  LEFT JOIN p ON p.pessoa_id = a.pessoa_id
)
SELECT t.*, 'L4_PERSONAL_DATA' AS classificacao_dado, CURRENT_TIMESTAMP() AS _extraido_at, 'supabase-x0tz' AS _fonte, 'UTC' AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(t))) AS _payload_hash
FROM tratado t
