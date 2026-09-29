-- rfn_qualidade__regra_gmail  ·  query-dWvx  ·  9 regras  ·  L2 INTERNAL
-- Refined / qualidade. Grao: uma REGRA de qualidade em uma execucao. Chave: id_regra
-- (a execucao se le em _extraido_at). Gatilho: evento em query-TXoY. Alerta ligado.
--
-- POR QUE UMA TERCEIRA TABELA DE QUALIDADE, E POR QUE O MOTIVO AQUI E OUTRO
--   A segunda suite (`rfn_qualidade__regra_contazul`) nasceu porque as tabelas do Conta
--   Azul ainda nao existiam e a cadencia era outra. NENHUM DOS DOIS motivos vale aqui: a
--   familia Gmail JA MATERIALIZOU (32 rotulos e 32.911 mensagens, conferido com COUNT(*))
--   e roda DIARIA, igual a suite principal.
--   O motivo e o TAMANHO. A `rfn_qualidade__regra` esta com 57 KB e 84 regras, e
--   `update_transformation` substitui o CODIGO INTEIRO — somar 9 regras exigiria
--   reescrever 57 mil caracteres sem errar um. Esta casa ja registrou exatamente esse
--   risco nas duas Trusted de Google Ads ("query grande demais e query que nao se
--   conserta", 76 mil e 45 mil caracteres, o que manteve a Unipar fora por meses).
--   A suite principal ATINGIU esse tamanho. Entao a escolha e deliberada, e a
--   ALTERNATIVA NAO TOMADA esta declarada: reescrever a suite principal inteira.
--   O CONTRATO DE COLUNAS E IDENTICO ao das outras duas, de proposito — um UNION ALL das
--   tres da o painel unico e `familia` diz de onde veio cada linha.
--
-- AS 9 REGRAS, MEDIDAS EM 2026-09-29 SOBRE A TABELA MATERIALIZADA, ANTES DE PUBLICAR.
-- Resultado esperado na primeira execucao: 9 CONFORMES, ZERO FALHAS.
--   ROTULO (2) — id_rotulo_unico 32/32 · nome_preenchido 0 falhas.
--   MENSAGEM (7) — id_mensagem_unico 32.911/32.911 · sempre_tem_rotulo 0 falhas ·
--     remetente_preenchido 0 · email_tem_forma 0 de 32.911 · data_nao_futura 0 ·
--     caixa_catalogada 0 orfas · migracao_nao_reabre 0.
--
-- AS DUAS QUE GUARDAM PREMISSA DE VERDADE:
--   `sempre_tem_rotulo` — os flags `is_inbox`, `is_enviada`, `is_spam`, `is_lixeira`,
--     `flag_nao_lida_na_extracao` e `categoria_gmail` saem TODOS do array de rotulos.
--     Mensagem sem rotulo sairia com os seis em FALSE — "nao esta em lugar nenhum e foi
--     lida" — e a contagem de linhas nao mudaria.
--   `migracao_nao_reabre` — 63,7% das mensagens vieram de migracao de caixa, e a
--     migracao PRESERVA a data original: as migradas param em 09/2025 e de 10/2025 em
--     diante e 100% nativo. Toda serie desta base depende desse corte para nao comparar
--     "o que a migracao trouxe" com "o que chegou".
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
todas AS (
  SELECT * FROM r_rotulo
  UNION ALL SELECT * FROM r_mensagem
  UNION ALL SELECT * FROM r_mensagem_fk
  UNION ALL SELECT * FROM r_regime
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
