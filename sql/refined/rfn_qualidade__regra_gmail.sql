-- rfn_qualidade__regra_gmail  ·  query-dWvx  ·  22 regras  ·  L2 INTERNAL
-- Refined / qualidade. Grao: uma REGRA de qualidade em uma execucao. Chave: id_regra
-- (a execucao se le em _extraido_at). Gatilho: evento em query-TXoY. Alerta ligado.
--
-- POR QUE UMA SUITE PROPRIA, E POR QUE O MOTIVO AQUI E O TAMANHO
--   Nao e porque a tabela nao existia nem por cadencia: a familia Gmail JA MATERIALIZOU e
--   roda DIARIA, igual a suite principal. O motivo e o TAMANHO. A `rfn_qualidade__regra`
--   esta com 57 KB e 84 regras, e `update_transformation` substitui o CODIGO INTEIRO —
--   somar regras la exigiria reescrever 57 mil caracteres sem errar um. Esta casa ja
--   registrou esse risco nas duas Trusted de Google Ads ("query grande demais e query que
--   nao se conserta", 76 mil e 45 mil caracteres, o que manteve a Unipar fora por meses).
--   O CONTRATO DE COLUNAS E IDENTICO ao das outras oito — um UNION ALL da o painel unico
--   e `familia` diz de onde veio cada linha.
--
-- 30/09 — A GOLD ENTROU E A FAMILIA GMAIL FICA 100% COBERTA.
--   `rfn_operacao__email_remetente_mensal` (query-n0hh, 1.596 linhas) foi publicada em
--   29/09 DEPOIS da carga, respondia `table_not_materialized` e ficou de fora, declarado.
--   Materializou hoje 08:04 e ganhou 13 regras. A suite vai de 9 para 22.
--
-- DUAS IDENTIDADES NOVAS, e as duas guardam decomposicoes que a Gold declara:
--   1. `regime_decompoe` — migradas + nativas = mensagens. 63,7% da base veio de MIGRACAO
--      de caixa, e toda serie desta familia depende de separar "o que a migracao trouxe"
--      de "o que chegou". Se a decomposicao soltar, mensagem sem regime some das duas
--      contagens e o total continua batendo.
--   2. `lista_decompoe` — de_lista + sem_lista = mensagens. E o separador entre robo e
--      humano, e a Gold ja avisa que ele NAO pega o maior robo da base: `iclips-mail.com.br`
--      sao 12.657 mensagens (38,5%) de um remetente so e ZERO com `List-Unsubscribe`.
--
-- A REGRA QUE PEGUEI ERRANDO ANTES DE PUBLICAR.
--   `janela_cai_dentro_do_mes` mede se a primeira e a ultima mensagem do grupo caem no
--   mes. Escrita com `DATE(ts)` — leitura em UTC — ela acusa 18 de 1.596. Lida em
--   `America/Sao_Paulo`, acusa ZERO. As 18 sao mensagens de virada de mes: o erro era da
--   REGRA, nao da tabela. A regra ficou com o FUSO EXPLICITO, e assim ela guarda a
--   convencao: `internalDate` e UTC e `DATETIME(ts,'America/Sao_Paulo')` esta CERTO aqui e
--   errado no VJOB e no iClips. Se alguem reescrever a Gold agrupando por UTC, isso acende.
--
-- `media_por_dia_ativo_reproduz_a_razao` guarda a regra declarada de que
--   `mensagens_por_dia_ativo` divide pelo DIA COM MENSAGEM, nunca pelo mes — 400 e-mails
--   em 2 dias e 400 em 30 sao coisas opostas, e dividir por 30 nos dois apaga a diferenca.
--
-- `dominio_interno_e_regra_nao_lista` guarda que `flag_dominio_interno` e REGRA
--   (`%vanguarda%`) e nao lista fixa — lista fixa e o erro do `tipo_midia` do PI, que tirou
--   R$ 363 mil do acompanhamento financeiro.
--
-- AS 13 FORAM MEDIDAS NA TABELA MATERIALIZADA E A MONTAGEM FOI VALIDADA rodando as 13
-- novas unidas a uma CTE antiga — o que testa o alinhamento do UNION entre bloco novo e
-- antigo: 14 regras, 14 ids distintos, CONFORME 14, zero falhas.
--
-- AS DUAS DA TRUSTED QUE GUARDAM PREMISSA DE VERDADE:
--   `sempre_tem_rotulo` — os flags `is_inbox`, `is_enviada`, `is_spam`, `is_lixeira`,
--     `flag_nao_lida_na_extracao` e `categoria_gmail` saem TODOS do array de rotulos.
--     Mensagem sem rotulo sairia com os seis em FALSE — "nao esta em lugar nenhum e foi
--     lida" — e a contagem de linhas nao mudaria.
--   `migracao_nao_reabre` — as migradas param em 09/2025 e de 10/2025 em diante e 100%
--     nativo. Se acender, houve nova migracao e o corte mudou de lugar.
--
-- CLASSIFICACAO: L2 INTERNAL. So contagem e taxa — nenhum endereco, assunto ou nome.
WITH r_rotulo AS (
  SELECT 'trs_gmail__rotulo.id_rotulo_unico'                AS id_regra,
         'Trusted'                                          AS camada,
         'trs_gmail__rotulo'                                AS tabela,
         'Gmail'                                            AS sistema,
         'UNICIDADE'                                        AS dimensao,
         'id_rotulo_unico (caixa + id) e unico'             AS regra,
         'BLOQUEANTE'                                       AS severidade,
         1.00                                               AS limiar,
         COUNT(*)                                           AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_rotulo_unico)         AS linhas_falha
  FROM `vanguardamartech_trusted`.`trs_gmail__rotulo`
  UNION ALL
  -- A CHAVE E COMPOSTA POR OBRIGACAO, NAO POR PREVENCAO: 32 linhas para 17 ids crus.
  -- Os rotulos de sistema do Gmail tem id fixo e igual em toda conta, e o de usuario
  -- troca de significado — `Label_1` e "Migrated All Mail" numa caixa e "YELLOW_STAR"
  -- na outra. Se esta regra acender, o de-para id -> nome atribui o nome errado.
  SELECT 'trs_gmail__rotulo.nome_preenchido', 'Trusted', 'trs_gmail__rotulo', 'Gmail',
         'COMPLETUDE', 'todo rotulo tem nome', 'ALERTA', 1.00,
         COUNT(*), COUNTIF(nome IS NULL)
  FROM `vanguardamartech_trusted`.`trs_gmail__rotulo`
),
r_mensagem AS (
  SELECT 'trs_gmail__mensagem.id_mensagem_unico', 'Trusted', 'trs_gmail__mensagem', 'Gmail',
         'UNICIDADE', 'id_mensagem_unico (caixa + id) e unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_mensagem_unico)
  FROM `vanguardamartech_trusted`.`trs_gmail__mensagem`
  UNION ALL
  -- A INVARIANTE QUE SUSTENTA TODA A DERIVACAO DE PASTA E DE LEITURA. Ver o cabecalho.
  SELECT 'trs_gmail__mensagem.sempre_tem_rotulo', 'Trusted', 'trs_gmail__mensagem', 'Gmail',
         'COMPLETUDE', 'toda mensagem carrega ao menos um rotulo do Gmail', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(ARRAY_LENGTH(rotulos) = 0)
  FROM `vanguardamartech_trusted`.`trs_gmail__mensagem`
  UNION ALL
  SELECT 'trs_gmail__mensagem.remetente_preenchido', 'Trusted', 'trs_gmail__mensagem', 'Gmail',
         'COMPLETUDE', 'toda mensagem tem remetente e dominio extraidos', 'ALERTA', 1.00,
         COUNT(*), COUNTIF(remetente_email IS NULL OR remetente_dominio IS NULL)
  FROM `vanguardamartech_trusted`.`trs_gmail__mensagem`
  UNION ALL
  -- O cabecalho `From` chega em ate quatro grafias de caixa e a extracao depende de
  -- `LOWER()`. Tirar o `LOWER()` faz o endereco sair vazio ou malformado nas linhas
  -- cuja grafia mudou — e o remetente vira lixo sem a contagem de linhas mudar.
  SELECT 'trs_gmail__mensagem.email_tem_forma', 'Trusted', 'trs_gmail__mensagem', 'Gmail',
         'VALIDADE', 'remetente_email tem forma de endereco', 'ALERTA', 1.00,
         COUNTIF(remetente_email IS NOT NULL),
         COUNTIF(remetente_email IS NOT NULL
                 AND NOT REGEXP_CONTAINS(remetente_email, r'^[^@]+@[^@]+[.][^@]+$'))
  FROM `vanguardamartech_trusted`.`trs_gmail__mensagem`
  UNION ALL
  -- `internalDate` e UTC e a Trusted converte com DATETIME(ts,'America/Sao_Paulo'), que
  -- e o certo AQUI e o errado no VJOB e no iClips. Data futura seria o sinal de que a
  -- conversao foi trocada por uma que SOMA fuso.
  SELECT 'trs_gmail__mensagem.data_nao_futura', 'Trusted', 'trs_gmail__mensagem', 'Gmail',
         'VALIDADE', 'nenhuma mensagem recebida no futuro', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(recebido_em > CURRENT_TIMESTAMP())
  FROM `vanguardamartech_trusted`.`trs_gmail__mensagem`
),
-- ANTI-JOIN com DISTINCT no lado direito, nunca `NOT EXISTS` correlacionado.
r_mensagem_fk AS (
  SELECT 'trs_gmail__mensagem.caixa_catalogada', 'Trusted', 'trs_gmail__mensagem', 'Gmail',
         'INTEGRIDADE', 'a caixa da mensagem existe na dimensao de rotulos', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(d.caixa IS NULL)
  FROM `vanguardamartech_trusted`.`trs_gmail__mensagem` m
  LEFT JOIN (SELECT DISTINCT caixa FROM `vanguardamartech_trusted`.`trs_gmail__rotulo`) d
         ON d.caixa = m.caixa
),
-- LINHA DE BASE DO CORTE DE REGIME. Se acender, houve nova migracao e o corte mudou de
-- lugar — nao e defeito, e aviso de que a serie mudou de sujeito.
r_regime AS (
  SELECT 'trs_gmail__mensagem.migracao_nao_reabre', 'Trusted', 'trs_gmail__mensagem', 'Gmail',
         'VALIDADE', 'nenhuma mensagem migrada com competencia a partir de 2025-10', 'ALERTA', 1.00,
         COUNT(*), COUNTIF(flag_veio_da_migracao AND mes_referencia >= DATE '2025-10-01')
  FROM `vanguardamartech_trusted`.`trs_gmail__mensagem`
),
-- ──────────── rfn_operacao__email_remetente_mensal (13) — a Gold, 30/09 ──────────────
r_gold AS (
  SELECT 'rfn_operacao__email_remetente_mensal.id_email_mensal_unico', 'Refined',
         'rfn_operacao__email_remetente_mensal', 'Gmail', 'UNICIDADE',
         'id_email_mensal e unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_email_mensal)
  FROM `vanguardamartech_refined`.`rfn_operacao__email_remetente_mensal`

  UNION ALL
  SELECT 'rfn_operacao__email_remetente_mensal.chave_e_mes_caixa_dominio', 'Refined',
         'rfn_operacao__email_remetente_mensal', 'Gmail', 'INTEGRIDADE',
         'id_email_mensal e mes, caixa e dominio do remetente', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(id_email_mensal <> CONCAT(FORMAT_DATE('%Y-%m-%d', mes_referencia), ':',
                                           caixa, ':', remetente_dominio))
  FROM `vanguardamartech_refined`.`rfn_operacao__email_remetente_mensal`

  UNION ALL
  -- IDENTIDADE 1: o corte de regime. Ver o cabecalho.
  SELECT 'rfn_operacao__email_remetente_mensal.regime_decompoe', 'Refined',
         'rfn_operacao__email_remetente_mensal', 'Gmail', 'VALIDADE',
         'migradas mais nativas reproduz o total de mensagens', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(qtd_migradas + qtd_nativas <> qtd_mensagens)
  FROM `vanguardamartech_refined`.`rfn_operacao__email_remetente_mensal`

  UNION ALL
  -- IDENTIDADE 2: robo e humano. Ver o cabecalho.
  SELECT 'rfn_operacao__email_remetente_mensal.lista_decompoe', 'Refined',
         'rfn_operacao__email_remetente_mensal', 'Gmail', 'VALIDADE',
         'de lista mais sem lista reproduz o total de mensagens', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(qtd_de_lista + qtd_sem_lista <> qtd_mensagens)
  FROM `vanguardamartech_refined`.`rfn_operacao__email_remetente_mensal`

  UNION ALL
  SELECT 'rfn_operacao__email_remetente_mensal.media_por_dia_ativo_reproduz_a_razao', 'Refined',
         'rfn_operacao__email_remetente_mensal', 'Gmail', 'VALIDADE',
         'mensagens_por_dia_ativo divide pelo DIA COM MENSAGEM, nunca pelo mes',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(ABS(IFNULL(mensagens_por_dia_ativo, 0)
                     - ROUND(qtd_mensagens / NULLIF(qtd_dias_com_mensagem, 0), 2)) > 0.01)
  FROM `vanguardamartech_refined`.`rfn_operacao__email_remetente_mensal`

  UNION ALL
  -- O FUSO E EXPLICITO DE PROPOSITO. Escrita com DATE(ts) — UTC — esta regra acusa 18 de
  -- 1.596, que sao mensagens de virada de mes. Lida em America/Sao_Paulo, acusa ZERO.
  SELECT 'rfn_operacao__email_remetente_mensal.janela_cai_dentro_do_mes', 'Refined',
         'rfn_operacao__email_remetente_mensal', 'Gmail', 'VALIDADE',
         'a primeira e a ultima mensagem caem dentro do mes, lidas em America/Sao_Paulo',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(DATE(DATETIME(ultima_em, 'America/Sao_Paulo')) > LAST_DAY(mes_referencia)
              OR DATE(DATETIME(primeira_em, 'America/Sao_Paulo')) < mes_referencia)
  FROM `vanguardamartech_refined`.`rfn_operacao__email_remetente_mensal`

  UNION ALL
  SELECT 'rfn_operacao__email_remetente_mensal.flag_remetente_unico_decompoe', 'Refined',
         'rfn_operacao__email_remetente_mensal', 'Gmail', 'VALIDADE',
         'flag_remetente_unico_no_dominio e exatamente um remetente no dominio',
         'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(flag_remetente_unico_no_dominio <> (qtd_remetentes_no_dominio = 1))
  FROM `vanguardamartech_refined`.`rfn_operacao__email_remetente_mensal`

  UNION ALL
  SELECT 'rfn_operacao__email_remetente_mensal.flag_mes_de_transicao_decompoe', 'Refined',
         'rfn_operacao__email_remetente_mensal', 'Gmail', 'VALIDADE',
         'mes de transicao e exatamente ter migrada E nativa', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(flag_mes_de_transicao <> (qtd_migradas > 0 AND qtd_nativas > 0))
  FROM `vanguardamartech_refined`.`rfn_operacao__email_remetente_mensal`

  UNION ALL
  SELECT 'rfn_operacao__email_remetente_mensal.flag_so_migrada_decompoe', 'Refined',
         'rfn_operacao__email_remetente_mensal', 'Gmail', 'VALIDADE',
         'so migrada e exatamente ter migrada e nenhuma nativa', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(flag_so_migrada <> (qtd_migradas > 0 AND qtd_nativas = 0))
  FROM `vanguardamartech_refined`.`rfn_operacao__email_remetente_mensal`

  UNION ALL
  -- REGRA, NAO LISTA FIXA. Ver o cabecalho.
  SELECT 'rfn_operacao__email_remetente_mensal.dominio_interno_e_regra_nao_lista', 'Refined',
         'rfn_operacao__email_remetente_mensal', 'Gmail', 'VALIDADE',
         'flag_dominio_interno e exatamente o dominio conter vanguarda', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(flag_dominio_interno <> (LOWER(remetente_dominio) LIKE '%vanguarda%'))
  FROM `vanguardamartech_refined`.`rfn_operacao__email_remetente_mensal`

  UNION ALL
  SELECT 'rfn_operacao__email_remetente_mensal.caixa_conhecida', 'Refined',
         'rfn_operacao__email_remetente_mensal', 'Gmail', 'VALIDADE',
         'caixa e VTECH ou CONTATO', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(caixa IS NULL OR caixa NOT IN ('VTECH', 'CONTATO'))
  FROM `vanguardamartech_refined`.`rfn_operacao__email_remetente_mensal`

  UNION ALL
  SELECT 'rfn_operacao__email_remetente_mensal.parte_nunca_excede_o_total', 'Refined',
         'rfn_operacao__email_remetente_mensal', 'Gmail', 'VALIDADE',
         'nenhum recorte passa do total de mensagens do grupo', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(qtd_com_arquivo > qtd_mensagens OR qtd_enviadas > qtd_mensagens
                 OR qtd_nao_lida_na_extracao > qtd_mensagens OR qtd_de_lista > qtd_mensagens
                 OR qtd_spam > qtd_mensagens OR qtd_lixeira > qtd_mensagens)
  FROM `vanguardamartech_refined`.`rfn_operacao__email_remetente_mensal`

  UNION ALL
  SELECT 'rfn_operacao__email_remetente_mensal.dias_ativos_cabem_no_mes', 'Refined',
         'rfn_operacao__email_remetente_mensal', 'Gmail', 'VALIDADE',
         'o dia com mensagem nunca passa do numero de dias do mes', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(qtd_dias_com_mensagem > EXTRACT(DAY FROM LAST_DAY(mes_referencia))
                 OR qtd_dias_com_mensagem <= 0 OR qtd_mensagens <= 0)
  FROM `vanguardamartech_refined`.`rfn_operacao__email_remetente_mensal`
),

todas AS (
  SELECT * FROM r_rotulo
  UNION ALL SELECT * FROM r_mensagem
  UNION ALL SELECT * FROM r_mensagem_fk
  UNION ALL SELECT * FROM r_regime
  UNION ALL SELECT * FROM r_gold
),
avaliado AS (
  SELECT
    t.*,
    (t.linhas_avaliadas - t.linhas_falha)                       AS linhas_conformes,
    SAFE_DIVIDE(t.linhas_avaliadas - t.linhas_falha, NULLIF(t.linhas_avaliadas, 0))
                                                                AS taxa_conformidade,
    -- Regra sem linha para avaliar NAO passa: sai NULL, nunca TRUE.
    IF(t.linhas_avaliadas = 0, NULL,
       SAFE_DIVIDE(t.linhas_avaliadas - t.linhas_falha, t.linhas_avaliadas) >= t.limiar)
                                                                AS is_conforme,
    (t.linhas_avaliadas = 0)                                    AS flag_sem_linha_para_avaliar
  FROM todas t
)
SELECT
  a.*,
  CASE
    WHEN a.flag_sem_linha_para_avaliar          THEN 'SEM_DADO'
    WHEN a.is_conforme                          THEN 'CONFORME'
    WHEN a.severidade = 'BLOQUEANTE'            THEN 'FALHA_BLOQUEANTE'
    ELSE                                             'FALHA_ALERTA'
  END                                           AS resultado,
  'Gmail'                                       AS familia,
  CURRENT_TIMESTAMP()                           AS _extraido_at,
  'multiplas'                                   AS _fonte,
  'America/Sao_Paulo'                           AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(a)))                AS _payload_hash
FROM avaliado a
