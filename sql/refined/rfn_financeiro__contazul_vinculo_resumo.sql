-- rfn_financeiro__contazul_vinculo_resumo  ·  Refined / financeiro  ·  L2 INTERNAL
-- Grao: tipo de vinculo (cliente/servico/vendedor/impulsionamento) x origem do vinculo x is_ativo. Le: trs_contazul__vinculo. Gatilho: evento em query-PdzT.
-- Identidade (07/10/2026): 10 vinculos = 10 · 4 linhas · 10 de 10 resolvem nos dois lados · 7 com rotulo divergente entre VJOB e Conta Azul.
-- R1 O de-para e manual (10 de 10): serve para MEDIR o que a integracao liga, nunca para inferir ligacao por nome.
-- R2 Rotulo divergente nao e erro: o mesmo cliente chama-se diferente nos dois sistemas; por isso casar por nome acharia menos que o de-para.
-- R3 Os vinculos do tipo cliente apontam para a CONTA DE ATENDIMENTO (tbclientesatedimentos), nao para o cadastro juridico.
WITH v AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_contazul__vinculo`
),
agg AS (
  SELECT
    tipo_vinculo,
    origem_vinculo,
    IFNULL(is_ativo, FALSE) AS is_ativo,
    COUNT(*) AS qtd_vinculos,
    COUNTIF(is_vinculo_manual) AS qtd_manuais,
    COUNTIF(NOT flag_vjob_nao_resolvido AND NOT flag_contaazul_nao_resolvido) AS qtd_resolvidos_nos_dois_lados,
    COUNTIF(flag_vjob_nao_resolvido) AS qtd_vjob_nao_resolvido,
    COUNTIF(flag_contaazul_nao_resolvido) AS qtd_contaazul_nao_resolvido,
    COUNTIF(flag_rotulos_divergem) AS qtd_rotulos_divergem,
    COUNTIF(documento_contaazul IS NOT NULL) AS qtd_com_documento_contaazul,
    COUNT(DISTINCT vjob_tabela) AS qtd_tabelas_vjob
  FROM v
  GROUP BY 1, 2, 3
),
final AS (
  SELECT CONCAT(tipo_vinculo, '|', origem_vinculo, '|', CAST(is_ativo AS STRING)) AS id_vinculo_resumo, a.*, 'L2_INTERNAL' AS classificacao_dado
  FROM agg a
)
SELECT f.*, CURRENT_TIMESTAMP() AS _extraido_at, 'mysql-yIOn' AS _fonte,
  'America/Sao_Paulo' AS _fuso, TO_HEX(MD5(TO_JSON_STRING(f))) AS _payload_hash
FROM final f
