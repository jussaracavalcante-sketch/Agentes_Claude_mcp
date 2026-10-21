-- rfn_operacao__email_remetente_mensal  ·  Refined / operacao  ·  1.596 linhas  ·  L2
-- Grao: um MES, uma CAIXA, um DOMINIO de remetente.
-- Chave: id_email_mensal = <mes>:<caixa>:<dominio>.
-- Origem: trs_gmail__mensagem (32.911). Gatilho: evento em query-TXoY. Cadencia DIARIA.
-- As regras numeradas, os numeros da validacao e o bloco de limitacoes estao na
-- descricao da transformacao, que e parte da entrega.
--
-- O ACHADO: DOIS TERCOS DO E-MAIL DA CASA E MAQUINA, E A FLAG DE LISTA NAO PEGA O MAIOR
--   DELES. **258 dos 342 dominios tem UM unico remetente** e carregam **21.512 das
--   32.911 (65,4%)**. O maior e o `iclips-mail.com.br`: **12.657 (38,5% da base), de UM
--   remetente, em 3 meses** -- e **zero delas tem `List-Unsubscribe`**. A flag de lista
--   cobre 6.151 (18,7%) e **nao inclui nenhuma do iClips**. A tabela emite os numeros e
--   **nao decide por ninguem**.
--
-- R1 a serie tem DOIS REGIMES, corte em 10/2025: 20.955 (63,7%) vieram de MIGRACAO, e a
--   migracao preserva a data original (migradas 02/2024-09/2025, nativas a partir de
--   08/2025) · R2 `mensagens_por_dia_ativo` divide pelo DIA COM MENSAGEM, nunca pelo mes
--   · R3 `flag_dominio_interno` e REGRA (`%vanguarda%`), nao lista fixa · R4 isto e
--   CAIXA DE ENTRADA, 64 SENT em 32.911 -- nao medir resposta · R5 `nao_lida` e a
--   fotografia da CHEGADA, nao leitura.
--
-- CLASSIFICACAO L2, COM A PROVA: a Trusted e L4 por endereco, nome e assunto.
--   **Nenhum dos tres atravessa** -- o grao e o DOMINIO, remetente vira contagem, e
--   assunto, corpo e nome de arquivo ficam de fora.
--
-- FUSO: a Trusted JA CONVERTE de UTC para America/Sao_Paulo. NAO converter de novo.
WITH m AS (
  SELECT
    caixa, mes_referencia, data_local, remetente_dominio, remetente_email,
    flag_lista_de_email, flag_veio_da_migracao, flag_e_resposta_de_alguem,
    flag_assunto_vazio, flag_varios_destinatarios, flag_nao_lida_na_extracao,
    is_enviada, is_marcada_importante, is_com_estrela, is_spam, is_lixeira,
    tem_arquivo, qtd_arquivos, tamanho_bytes, recebido_em
  FROM `vanguardamartech_trusted`.`trs_gmail__mensagem`
),
-- Quem manda de verdade se mede por dominio, nao por endereco: 258 dos 342 dominios tem
-- um remetente so e carregam 65,4% da base.
por_dominio AS (
  SELECT
    remetente_dominio,
    COUNT(DISTINCT remetente_email) AS qtd_remetentes_no_dominio
  FROM m GROUP BY 1
),
agregado AS (
  SELECT
    x.mes_referencia,
    x.caixa,
    x.remetente_dominio,

    COUNT(*)                                          AS qtd_mensagens,
    COUNT(DISTINCT x.remetente_email)                 AS qtd_remetentes_distintos,
    COUNT(DISTINCT x.data_local)                      AS qtd_dias_com_mensagem,

    -- R1 - os dois regimes da serie, em toda linha.
    COUNTIF(x.flag_veio_da_migracao)                  AS qtd_migradas,
    COUNTIF(NOT x.flag_veio_da_migracao)              AS qtd_nativas,

    -- O ACHADO: a flag de lista NAO cobre o maior remetente automatico da base.
    COUNTIF(x.flag_lista_de_email)                    AS qtd_de_lista,
    COUNTIF(NOT x.flag_lista_de_email)                AS qtd_sem_lista,

    COUNTIF(x.flag_e_resposta_de_alguem)              AS qtd_resposta_de_alguem,
    COUNTIF(x.flag_varios_destinatarios)              AS qtd_varios_destinatarios,
    COUNTIF(x.flag_assunto_vazio)                     AS qtd_sem_assunto,

    COUNTIF(x.tem_arquivo)                            AS qtd_com_arquivo,
    SUM(x.qtd_arquivos)                               AS qtd_arquivos_total,

    -- R4 - existe para ficar visivel, nunca como denominador.
    COUNTIF(x.is_enviada)                             AS qtd_enviadas,
    COUNTIF(x.is_spam)                                AS qtd_spam,
    COUNTIF(x.is_lixeira)                             AS qtd_lixeira,
    COUNTIF(x.is_marcada_importante)                  AS qtd_marcada_importante,
    COUNTIF(x.is_com_estrela)                         AS qtd_com_estrela,
    -- R5 - fotografia da CHEGADA, nao comportamento de leitura.
    COUNTIF(x.flag_nao_lida_na_extracao)              AS qtd_nao_lida_na_extracao,

    SUM(x.tamanho_bytes)                              AS bytes_total,
    MIN(x.recebido_em)                                AS primeira_em,
    MAX(x.recebido_em)                                AS ultima_em
  FROM m x
  GROUP BY 1, 2, 3
)
SELECT
  CONCAT(CAST(a.mes_referencia AS STRING), ':', a.caixa, ':', a.remetente_dominio)
                                                      AS id_email_mensal,
  a.mes_referencia,
  a.caixa,
  a.remetente_dominio,
  -- R3 - regra, nao lista fixa. Nao prova que o dominio e da casa.
  (a.remetente_dominio LIKE '%vanguarda%')            AS flag_dominio_interno,

  a.qtd_mensagens,
  a.qtd_remetentes_distintos,
  a.qtd_dias_com_mensagem,
  -- R2 - o denominador e o dia com mensagem, nunca o mes inteiro.
  ROUND(SAFE_DIVIDE(a.qtd_mensagens, NULLIF(a.qtd_dias_com_mensagem, 0)), 2)
                                                      AS mensagens_por_dia_ativo,

  -- Um dominio com um remetente so e centenas de mensagens e robo, e a tabela mostra
  -- isso sem decidir: o numero fica, o rotulo nao.
  d.qtd_remetentes_no_dominio,
  (d.qtd_remetentes_no_dominio = 1)                   AS flag_remetente_unico_no_dominio,

  a.qtd_migradas,
  a.qtd_nativas,
  (a.qtd_migradas > 0 AND a.qtd_nativas > 0)          AS flag_mes_de_transicao,
  (a.qtd_migradas > 0 AND a.qtd_nativas = 0)          AS flag_so_migrada,

  a.qtd_de_lista,
  a.qtd_sem_lista,
  a.qtd_resposta_de_alguem,
  a.qtd_varios_destinatarios,
  a.qtd_sem_assunto,

  a.qtd_com_arquivo,
  a.qtd_arquivos_total,

  a.qtd_enviadas,
  a.qtd_spam,
  a.qtd_lixeira,
  a.qtd_marcada_importante,
  a.qtd_com_estrela,
  a.qtd_nao_lida_na_extracao,

  a.bytes_total,
  ROUND(SAFE_DIVIDE(a.bytes_total, NULLIF(a.qtd_mensagens, 0)), 0)
                                                      AS bytes_medio_por_mensagem,
  a.primeira_em,
  a.ultima_em,

  CURRENT_TIMESTAMP()                                 AS _extraido_at,
  'gmail'                                             AS _fonte,
  'America/Sao_Paulo'                                 AS _fuso
FROM agregado a
LEFT JOIN por_dominio d ON d.remetente_dominio = a.remetente_dominio
