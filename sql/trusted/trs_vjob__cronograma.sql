-- trs_vjob__cronograma
-- Trusted do VJOB REAL: um contrato de cronograma por linha. Chave id_cronograma.
-- Fonte: mysql-yIOn, stream `vjob_2024_tbcronograma`.
-- Dimensoes resolvidas aqui: `tbservicoscronograma` e `tbfornecedorescronograma`.
--
-- **ESTA TABELA NAO E ONDE O DINHEIRO SE SOMA.** Ela descreve o contrato; o valor
-- somavel esta na `trs_vjob__cronograma_parcela`. Ver a regra do valor, abaixo.
--
-- VOLUME E UNICIDADE -- medido em 2026-09-23
--   6.754 contratos, 6.754 `id` distintos. 230 clientes, 26 servicos, 6 tipos.
--   Competencia de 01/2024 a 01/2027. Ultimo cadastro 21/09/2026 14:39 (local).
--   **Zero orfaos nas duas dimensoes**: os 26 servicos casam com
--   `tbservicoscronograma` (30 linhas) e os 187 fornecedores com
--   `tbfornecedorescronograma` (212). Nao ha rotulo inventado nesta tabela.
--
-- A REGRA DO VALOR -- O NUMERO MAIS PERIGOSO DESTA FAMILIA.
--   `tbcronograma.valor` **NAO e o valor do contrato**: e o valor de UMA parcela.
--   Somar `valor` entre contratos mistura mensalidades de contratos com duracoes
--   diferentes e nao produz grandeza nenhuma.
--   **Duas provas, medidas em 2026-09-23:**
--   (a) dos 785 contratos em que a soma das parcelas difere do `valor`, **TODOS**
--       tem parcela maior (nenhum menor) e **696 (89%) sao exatamente
--       `valor x numero de parcelas`** -- o valor mensal repetido em cada parcela;
--   (b) os 98 contratos de `tipocronograma = 6` tem **`valor` ZERO em todos**, e
--       suas parcelas somam **R$ 547.783,03**. Quem somar `valor` conclui que esse
--       tipo nao vale nada.
--   Por isso `valor` sai daqui como **`valor_parcela`**, com o nome dizendo o que e,
--   e `valor_contrato_calculado` traz a soma real das parcelas -- medida, nao
--   multiplicada.
--   Nos 5.969 contratos de parcela unica os dois coincidem, e e isso que fazia o
--   defeito passar despercebido.
--
-- FUSO: o VJOB grava hora local -- `DATETIME(ts)` SEM argumento. Verificado em
--   2026-09-23 por dois caminhos (o mesmo registro batendo com o bronze do Supabase,
--   e o almoco visivel na distribuicao horaria das marcacoes de escopo).
--
-- FORNECEDOR SEPARA REPASSE DE HONORARIO, E ISSO E MEDIDO, NAO SUPOSTO.
--   `tipocronograma` 1, 2, 3 e 4 tem fornecedor em **100%** das linhas (6.106 de
--   6.106); os tipos 5 e 6 tem fornecedor em **0%** (648 de 648). Nao ha meio-termo.
--   Pelo conteudo dos servicos, os tipos com fornecedor sao veiculacao de midia,
--   producao e comissao -- ha um terceiro que recebe; os sem fornecedor sao Fee
--   Mensal e manutencao -- a casa entrega.
--   `tem_fornecedor` emite o FATO. A leitura "repasse vs honorario" e hipotese
--   coerente com os rotulos, e esta declarada aqui e nao codificada numa coluna.
--
-- LIMITACOES -- NAO CONTORNE
--   1. **`tipocronograma` nao tem tabela de dominio nesta base.** Sai como codigo
--      (1 a 6). Perfil medido em 2026-09-23, por parcela e valor:
--        2 -- 3.595 contratos / 4.424 parcelas / R$ 66.465.425,67 / com fornecedor /
--             VEICULACAO DE MIDIA OFF, Setup, Producao
--        5 --   550 / 2.695 / R$ 19.205.373,71 / SEM fornecedor / Fee Mensal, sites
--        1 -- 1.508 / 1.613 / R$ 18.284.389,89 / com fornecedor / VEICULACAO ON
--        3 --   516 /   545 / R$  5.441.481,94 / com fornecedor / COMISSAO (varias)
--        4 --   487 /   577 / R$  1.265.042,20 / com fornecedor / Producao, sites
--        6 --    98 /   182 / R$    547.783,03 / SEM fornecedor / comissao, midia
--      Nao rotular os tipos sem confirmar na origem.
--   2. **`status` da parcela e praticamente morto e `faturado` e zero em TODAS as
--      10.036 linhas** -- ver a limitacao 1 da `trs_vjob__cronograma_parcela`.
--      Faturamento nao se mede por estes campos.
--   3. Vigencia e escassa: so **648 contratos** tem `iniciodecontrato` e **647** tem
--      `finaldecontrato`, de 6.754 (10%). Indicador de contrato vigente cobre 10%.
--   4. `comissao` e STRING na origem e `pi`, `os` e `ci` sao identificadores fracos,
--      sem integridade conferida contra a `trs_pi__insercao`. Passam como texto.
--   5. `observacoes` e texto livre digitado -- fica fora, como em toda Trusted desta
--      base.
SELECT
  c.id                                            AS id_cronograma,
  c.cliente                                       AS id_cliente,
  cli.cliente,
  cli.cnpj_digitos                                AS cliente_cnpj,
  cli.is_ativo                                    AS cliente_ativo,
  (cli.id_cliente IS NULL)                        AS flag_cliente_nao_catalogado,

  c.tipocronograma                                AS tipo_cronograma_codigo,

  c.servico                                       AS id_servico,
  s.nomeservico                                   AS servico,

  c.fornecedor                                    AS id_fornecedor,
  f.nomefornecedor                                AS fornecedor,
  (c.fornecedor > 0)                              AS tem_fornecedor,

  -- VER A REGRA DO VALOR NO TOPO. `valor` e a parcela, nao o contrato.
  c.valor                                         AS valor_parcela,
  c.qtdparcelas                                   AS qtd_parcelas_declarada,
  p.qtd_parcelas                                  AS qtd_parcelas_real,
  p.valor_total                                   AS valor_contrato_calculado,
  (p.qtd_parcelas != c.qtdparcelas)               AS flag_parcelas_divergem,
  (ABS(IFNULL(p.valor_total, 0) - c.valor) >= 0.01) AS flag_valor_difere_das_parcelas,

  c.competencia,
  c.vencimentocontrato                            AS dt_vencimento_contrato,
  c.iniciodecontrato                              AS dt_inicio_contrato,
  c.finaldecontrato                               AS dt_fim_contrato,
  c.primeiracobranca                              AS dt_primeira_cobranca,
  (c.iniciodecontrato IS NOT NULL AND c.finaldecontrato IS NOT NULL) AS tem_vigencia,

  c.cs                                            AS id_customer_success,
  c.quemcadastrou                                 AS id_quem_cadastrou,
  c.quemalterou                                   AS id_quem_alterou,

  NULLIF(TRIM(IFNULL(c.comissao,'')), '')         AS comissao_texto,
  NULLIF(TRIM(CAST(c.pi   AS STRING)), '')        AS pi_texto,
  NULLIF(TRIM(CAST(c.os   AS STRING)), '')        AS os_texto,
  NULLIF(TRIM(CAST(c.ci   AS STRING)), '')        AS ci_texto,
  NULLIF(TRIM(IFNULL(c.nfse,'')), '')             AS nfse_contrato,

  -- SEM argumento de fuso, de proposito: o VJOB ja grava local.
  DATETIME(c.datacadastro)                        AS cadastrado_em,
  DATE(DATETIME(c.datacadastro))                  AS dt_cadastro,
  DATETIME(c.dataalteracao)                       AS alterado_em,

  CURRENT_TIMESTAMP()                             AS _extraido_at,
  'mysql-yIOn'                                    AS _fonte,
  'America/Sao_Paulo'                             AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(c)))                  AS _payload_hash
FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbcronograma` c
-- Zero orfaos nas duas dimensoes (medido). LEFT mesmo assim: se um dia entrar
-- servico ou fornecedor novo sem cadastro, a linha fica e o nome vem NULL.
LEFT JOIN `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbservicoscronograma` s
  ON s.id = c.servico
LEFT JOIN `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbfornecedorescronograma` f
  ON f.id = c.fornecedor
LEFT JOIN `vanguardamartech_trusted`.`trs_vjob__cliente` cli
  ON cli.id_cliente = c.cliente
-- A soma real das parcelas, medida. Nunca `valor * qtdparcelas`.
LEFT JOIN (
  SELECT id_cronograma, COUNT(*) AS qtd_parcelas, SUM(valormensal) AS valor_total
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbcronogramadatas`
  GROUP BY id_cronograma
) p ON p.id_cronograma = c.id
