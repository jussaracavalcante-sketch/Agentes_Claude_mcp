-- rfn_financeiro__contazul_pessoa_resumo  ·  Refined / financeiro  ·  L3 CONFIDENTIAL (a Trusted e L4; nome, documento, e-mail e telefone NAO atravessam -- so contagens e valor agregado)
-- Grao: operacao x papel (C/F/CF/T/FT, do array de perfis) x tipo_pessoa (Juridica/Fisica/Estrangeira) x tipo_documento (PJ/PF/DOCUMENTO_INVALIDO/SEM_DOCUMENTO).
-- Le: trs_contazul__pessoa (query-AAAT) + trs_contazul__movimento (parcelas vigentes por id_entidade_contaazul). Gatilho: evento em query-AAAT.
-- Identidade (19/10/2026): 2.096 pessoas = 2.096 · 617 com movimento vigente · 4.937 parcelas · R$ 23.394.795,75 (= o que a Trusted de movimento resolve por pessoa).
-- R1 Agrega, nao filtra. R2 Papel vem de perfis: C 693, F 1.246, CF 154, T 2, FT 1 -- a mesma pessoa pode ser cliente e fornecedor; a tabela nao escolhe.
-- R3 tipo_pessoa e tipo_documento sao eixos DIFERENTES: 'Fisica' com CNPJ e 'Juridica' sem documento existem na origem; a tabela mostra o cruzamento, nao corrige.
-- R4 Documento: 1.160 PJ, 147 PF, 1 invalido (fragmento), 788 sem documento (37,6%) -- ligacao por nome e hipotese (R-003), por isso nenhum nome sai daqui.
-- R5 So parcela VIGENTE entra; valor_vigente e soma de `valor` (positivo nos dois sentidos) -- NAO e saldo nem receita.
-- LIMITACAO -- NAO CONTORNE: 1.479 pessoas sem movimento vigente nao sao inativas; 1.937 estao is_ativo na origem. data_criacao e instante real (1.655 de 2.096 com hora).
WITH p AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_contazul__pessoa`
),
mv AS (
  SELECT id_entidade_contaazul AS id, COUNT(*) AS qtd_parcelas, SUM(valor) AS valor
  FROM `vanguardamartech_trusted`.`trs_contazul__movimento`
  WHERE is_vigente AND id_entidade_contaazul IS NOT NULL
  GROUP BY 1
),
j AS (
  SELECT p.*, (mv.id IS NOT NULL) AS tem_mov, IFNULL(mv.qtd_parcelas, 0) AS qp, IFNULL(mv.valor, 0) AS vv,
    CONCAT(IF(p.is_cliente, 'C', ''), IF(p.is_fornecedor, 'F', ''), IF(p.is_transportadora, 'T', '')) AS papel,
    CASE WHEN p.is_pj THEN 'PJ' WHEN p.is_pf THEN 'PF' WHEN p.flag_documento_invalido THEN 'DOCUMENTO_INVALIDO' ELSE 'SEM_DOCUMENTO' END AS tipo_documento
  FROM p LEFT JOIN mv ON mv.id = p.id_pessoa
),
agg AS (
  SELECT
    operacao,
    NULLIF(papel, '')                        AS papel,
    IFNULL(tipo_pessoa, '(sem tipo)')        AS tipo_pessoa,
    tipo_documento,
    COUNT(*)                                 AS qtd_pessoas,
    COUNTIF(is_ativo)                        AS qtd_ativas,
    COUNTIF(tem_email)                       AS qtd_com_email,
    COUNTIF(tem_telefone)                    AS qtd_com_telefone,
    COUNTIF(id_legado_iclips IS NOT NULL)    AS qtd_com_legado_iclips,
    COUNTIF(flag_documento_repadronizado)    AS qtd_documento_repadronizado,
    COUNTIF(tem_mov)                         AS qtd_com_movimento_vigente,
    SUM(qp)                                  AS qtd_parcelas_vigentes,
    ROUND(SUM(vv), 2)                        AS valor_vigente,
    MIN(DATE(data_criacao, 'America/Sao_Paulo')) AS primeira_criacao,
    MAX(DATE(data_criacao, 'America/Sao_Paulo')) AS ultima_criacao
  FROM j
  GROUP BY operacao, NULLIF(papel, ''), IFNULL(tipo_pessoa, '(sem tipo)'), tipo_documento
),
final AS (
  SELECT CONCAT(operacao, '|', IFNULL(papel, '-'), '|', tipo_pessoa, '|', tipo_documento) AS id_pessoa_resumo, g.*, 'L3_CONFIDENTIAL' AS classificacao_dado FROM agg g
)
SELECT f.*, CURRENT_TIMESTAMP() AS _extraido_at, 'supabase-x0tz' AS _fonte,
  'America/Sao_Paulo' AS _fuso, TO_HEX(MD5(TO_JSON_STRING(f))) AS _payload_hash
FROM final f
