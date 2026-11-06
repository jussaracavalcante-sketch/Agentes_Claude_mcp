-- trs_vjob__cronograma_parcela
-- Trusted do VJOB REAL: uma parcela de cronograma por linha. Chave id_parcela.
-- Fonte: mysql-yIOn, stream `vjob_2024_tbcronogramadatas`.
--
-- **E AQUI QUE O DINHEIRO SE SOMA.** `valor_parcela` e a unica grandeza aditiva
-- desta familia. A `trs_vjob__cronograma` descreve o contrato e o `valor` de la e o
-- valor de UMA parcela -- somar aquele campo entre contratos nao produz grandeza
-- nenhuma. Ver a regra do valor na descricao daquela tabela.
--
-- VOLUME E UNICIDADE -- medido em 2026-09-23
--   10.036 parcelas, 10.036 `id` distintos, para 6.754 contratos (1,49 por contrato).
--   Soma: **R$ 111.209.496,44**. Referencia de 01/2024 a 12/2027.
--   Zero parcela orfa: todo `id_cronograma` casa com a `trs_vjob__cronograma`.
--   47 parcelas com valor zero, **nenhuma negativa**.
--
-- FUSO: o VJOB grava hora local -- `DATETIME(ts)` SEM argumento.
--
-- LIMITACOES -- NAO CONTORNE
--   1. **NAO EXISTE FLAG DE FATURAMENTO CONFIAVEL NESTA TABELA.**
--      `faturado = 1` em **ZERO das 10.036 linhas**, e `status` esta **vazio em
--      10.007** -- so 29 linhas tem valor (18 `FATURADO`, 8 `BOLETO EMITIDO`,
--      3 `A FATURA`). Medir faturamento por esses campos devolve praticamente zero e
--      parece um resultado.
--      O unico sinal com cobertura real e a **NFSe: 9.146 das 10.036 (91%)**.
--      `tem_nfse` existe para isso, e e o mais proximo de "faturado" que esta base
--      oferece -- **nao e a mesma coisa**, e quem usar declara a escolha.
--   2. **A NFSe NAO E CHAVE.** 9.146 preenchidas para apenas **7.977 distintas** --
--      1.169 repeticoes. Uma nota cobre mais de uma parcela. Contar parcela por NFSe
--      distinta subconta; contar NFSe por parcela superconta.
--   3. **`mesanoreferencia` nao e competencia limpa.** 327 das 10.036 nao caem no
--      dia 1 do mes. `competencia` aqui e `DATE_TRUNC(..., MONTH)`; a data original
--      fica em `dt_referencia_origem` para quem precisar do valor cru.
--   4. Campos mortos ou quase, fora da tabela: `email_enviado` (**zero** em todas),
--      `email_enviado_em`, `email_enviado_por`, `email_destinatario`, `email_cc`,
--      `arquivo` (1 linha), `arquivo_pdf`, `nfseterceiro` (2), `databoleto` (2),
--      `dataemissao` (24).
--   5. **A integracao Conta Azul mal comecou**: 126 parcelas com `contaazul_venda_id`,
--      75 com NF emitida, **5 com venda recebida**, de 10.036. As colunas ficam, mas
--      nao sustentam indicador de recebimento.
--   6. `data_faturamento` esta preenchida em **119** linhas (1,2%). Nao serve para
--      datar faturamento; a referencia util e `competencia`.
SELECT
  d.id                                            AS id_parcela,
  d.id_cronograma,

  -- A GRANDEZA ADITIVA DESTA FAMILIA. Ver o cabecalho.
  d.valormensal                                   AS valor_parcela,
  (d.valormensal = 0)                             AS flag_valor_zero,

  -- 327 referencias nao caem no dia 1; a competencia trunca e o cru fica ao lado.
  DATE_TRUNC(d.mesanoreferencia, MONTH)           AS competencia,
  d.mesanoreferencia                              AS dt_referencia_origem,
  (EXTRACT(DAY FROM d.mesanoreferencia) != 1)     AS flag_referencia_fora_do_dia_1,
  EXTRACT(YEAR  FROM d.mesanoreferencia)          AS ano,
  EXTRACT(MONTH FROM d.mesanoreferencia)          AS mes,

  NULLIF(TRIM(IFNULL(d.parcelanumero,'')), '')    AS numero_parcela,
  d.vencimentocontrato                            AS dt_vencimento,

  -- Ver limitacoes 1 e 2: a NFSe e o unico sinal com cobertura, e nao e chave.
  NULLIF(TRIM(IFNULL(d.nfse,'')), '')             AS nfse,
  (NULLIF(TRIM(IFNULL(d.nfse,'')), '') IS NOT NULL) AS tem_nfse,
  NULLIF(TRIM(IFNULL(d.status,'')), '')           AS status_origem,
  d.faturado                                      AS faturado_codigo,

  -- Conta Azul: existe, e quase nao foi usada. Ver limitacao 5.
  NULLIF(TRIM(IFNULL(d.contaazul_venda_id,'')), '') AS contaazul_venda_id,
  NULLIF(TRIM(IFNULL(d.codigo_conta_azul,'')), '')  AS contaazul_codigo,
  (d.contaazul_nf_emitida = 1)                    AS contaazul_nf_emitida,
  (d.contaazul_boleto_emitido = 1)                AS contaazul_boleto_emitido,
  (d.contaazul_venda_recebida = 1)                AS contaazul_venda_recebida,
  NULLIF(TRIM(IFNULL(d.contaazul_status_erro,'')), '') AS contaazul_erro,

  d.analista_id                                   AS id_analista,
  d.idquemalterou                                 AS id_quem_alterou,

  -- SEM argumento de fuso, de proposito: o VJOB ja grava local.
  DATETIME(d.data_faturamento)                    AS faturado_em,
  DATETIME(d.contaazul_status_sincronizado_em)    AS contaazul_sincronizado_em,

  CURRENT_TIMESTAMP()                             AS _extraido_at,
  'mysql-yIOn'                                    AS _fonte,
  'America/Sao_Paulo'                             AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(d)))                  AS _payload_hash
FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbcronogramadatas` d
