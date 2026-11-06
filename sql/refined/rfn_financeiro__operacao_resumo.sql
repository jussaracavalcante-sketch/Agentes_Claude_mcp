-- rfn_financeiro__operacao_resumo  ·  Refined / financeiro  ·  L2 INTERNAL (cadastro das empresas do grupo e quanto cada codigo de operacao carrega nas tabelas do Conta Azul; so contagens)
-- Grao: um CODIGO DE OPERACAO visto em qualquer tabela financeira (uniao do cadastro trs_financeiro__operacao com os codigos que aparecem em pessoa, contrato, transferencia,
-- item de venda, apoio e razao). Le: trs_financeiro__operacao (query-2774) + trs_contazul__pessoa, __contrato, __transferencia, __venda_item, __apoio, __movimento. Gatilho: evento em query-2774.
-- Identidade (19/10/2026): 3 operacoes cadastradas = 3 (BRM, VD, VBOT) · 4 codigos vistos (mais VGD-BRM) · as contagens por tabela somam o total da Trusted de cada uma:
--    pessoa 2.096 · contrato 390 · transferencia 286 · item de venda 3.454 · apoio 880 (906 menos as 26 CATEGORIA_DRE, que nao tem operacao) · razao vigente 5.504 parcelas.
-- R1 ORFAO E MELHOR QUE FALSO PAR: 'VGD-BRM' aparece em 3.056 itens de venda e 6 vendedores e NAO existe no cadastro -- entra como linha com flag_operacao_nao_catalogada,
--    em vez de ser fundido em BRM por parecer BRM (seria casamento por rotulo, R-003). A decisao de equivaler VGD-BRM a BRM e de quem manda.
-- R2 VBOT esta no cadastro (ERP Conexa) e em NENHUMA tabela do Conta Azul: as contagens dela sao zero real (o Conexa tem as proprias Trusted), nao ausencia.
-- R3 BRM e VD: inicio_erp 2026-06-01 e a virada do razao do iClips para o Conta Azul, a mesma medida no razao. CNPJ nao atravessa (nao e preciso: a chave e o codigo).
-- LIMITACAO -- NAO CONTORNE: e cadastro mais contagem; nao tem valor nenhum (os valores por operacao estao nas Refined de cada entidade). Nao tem VPromo nem Vanguarda Internacional.
WITH dim AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_financeiro__operacao`
),
pes AS (SELECT operacao, COUNT(*) AS n FROM `vanguardamartech_trusted`.`trs_contazul__pessoa` GROUP BY 1),
ctr AS (SELECT operacao, COUNT(*) AS n, COUNTIF(is_ativo) AS n_ativos FROM `vanguardamartech_trusted`.`trs_contazul__contrato` GROUP BY 1),
trf AS (SELECT operacao, COUNT(*) AS n FROM `vanguardamartech_trusted`.`trs_contazul__transferencia` GROUP BY 1),
vit AS (SELECT operacao, COUNT(*) AS n FROM `vanguardamartech_trusted`.`trs_contazul__venda_item` GROUP BY 1),
apo AS (SELECT operacao, COUNT(*) AS n, COUNTIF(origem = 'CONTA_FINANCEIRA') AS n_contas, COUNTIF(origem = 'CENTRO_CUSTO') AS n_cc,
               COUNTIF(origem = 'CATEGORIA') AS n_cat, COUNTIF(origem = 'VENDEDOR') AS n_vend
        FROM `vanguardamartech_trusted`.`trs_contazul__apoio` WHERE operacao IS NOT NULL GROUP BY 1),
mov AS (SELECT operacao, COUNT(*) AS n FROM `vanguardamartech_trusted`.`trs_contazul__movimento` WHERE is_vigente GROUP BY 1),
codigos AS (
  SELECT operacao FROM dim UNION DISTINCT SELECT operacao FROM pes UNION DISTINCT SELECT operacao FROM ctr UNION DISTINCT SELECT operacao FROM trf
  UNION DISTINCT SELECT operacao FROM vit UNION DISTINCT SELECT operacao FROM apo UNION DISTINCT SELECT operacao FROM mov
),
agg AS (
  SELECT
    c.operacao,
    (d.operacao IS NULL)                      AS flag_operacao_nao_catalogada,
    d.nome, d.apelido, d.grupo, d.erp, d.regime_tributario, d.conta_azul_licenca, d.inicio_erp, d.is_ativa, d.faturamento_modo,
    IFNULL(pes.n, 0)                          AS qtd_pessoas,
    IFNULL(ctr.n, 0)                          AS qtd_contratos,
    IFNULL(ctr.n_ativos, 0)                   AS qtd_contratos_ativos,
    IFNULL(trf.n, 0)                          AS qtd_transferencias,
    IFNULL(vit.n, 0)                          AS qtd_itens_venda,
    IFNULL(apo.n, 0)                          AS qtd_cadastros_apoio,
    IFNULL(apo.n_contas, 0)                   AS qtd_contas_financeiras,
    IFNULL(apo.n_cc, 0)                       AS qtd_centros_custo,
    IFNULL(apo.n_cat, 0)                      AS qtd_categorias,
    IFNULL(apo.n_vend, 0)                     AS qtd_vendedores,
    IFNULL(mov.n, 0)                          AS qtd_parcelas_razao_vigentes
  FROM codigos c
  LEFT JOIN dim d ON d.operacao = c.operacao
  LEFT JOIN pes ON pes.operacao = c.operacao
  LEFT JOIN ctr ON ctr.operacao = c.operacao
  LEFT JOIN trf ON trf.operacao = c.operacao
  LEFT JOIN vit ON vit.operacao = c.operacao
  LEFT JOIN apo ON apo.operacao = c.operacao
  LEFT JOIN mov ON mov.operacao = c.operacao
  WHERE c.operacao IS NOT NULL
),
final AS (
  SELECT operacao AS id_operacao, g.*, 'L2_INTERNAL' AS classificacao_dado FROM agg g
)
SELECT f.*, CURRENT_TIMESTAMP() AS _extraido_at, 'supabase-x0tz' AS _fonte,
  'America/Sao_Paulo' AS _fuso, TO_HEX(MD5(TO_JSON_STRING(f))) AS _payload_hash
FROM final f
