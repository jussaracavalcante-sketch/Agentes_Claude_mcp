-- rfn_qualidade__regra_vjob_residuos  ·  8 regras  ·  L2 INTERNAL
-- Refined / qualidade. Grao: uma REGRA em uma execucao. Chave: id_regra (a execucao se le em _extraido_at).
-- Cobre a trs_vjob__orcamento_item (query-bzyG), unica Trusted nova da varredura de residuos de 2026-10-18 no
-- mysql-yIOn. Gatilho: evento em query-bzyG; alerta ligado. Cadencia semanal (a mysql-yIOn roda domingo 00:00 America/Manaus).
-- Suite propria pelo mesmo motivo das demais familias: nao ha suite do VJOB que seja dona de uma tabela publicada hoje, e
-- somar 8 regras a uma suite existente exigiria reescrever o codigo inteiro dela.
--
-- VALIDACAO (2026-10-18): a tabela AINDA NAO MATERIALIZOU (primeira carga e a agendada); a query foi validada
-- reproduzindo a logica da Trusted sobre a Raw `mysql_vjobvjob_2024_tborcamento`. Esperado na primeira execucao real:
-- 8 regras, 8 ids, CONFORME 8, zero falhas.
--
-- O QUE GUARDA PREMISSA: `linhas_reproduzem_a_origem` e `precos_reproduzem_a_origem` (frescor e perda de precisao
-- do cast para NUMERIC: R$ 21.042,43 dos dois lados) e `subtotal_residual_e_o_produto` (o residuo de edicao so e
-- inofensivo enquanto subtotal = quantidade x valor: 2 de 2).
-- O QUE NAO ENTROU: frescor de dado (a tabela esta parada desde 03/2025 por natureza; regra de "dado recente"
-- acusaria todo dia um fato conhecido) e unicidade de preco entre descricoes.
-- CLASSIFICACAO: L2 INTERNAL. Contagem, taxa e nome de regra; nenhum preco atravessa.
WITH
tbl AS (SELECT * FROM `vanguardamartech_trusted`.`trs_vjob__orcamento_item`),
ori AS (SELECT * FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tborcamento`),
r AS (
  SELECT 'trs_vjob__orcamento_item.id_unico' AS id_regra, 'Trusted' AS camada, 'trs_vjob__orcamento_item' AS tabela,
         'VJOB' AS sistema, 'UNICIDADE' AS dimensao, 'id_orcamento_item e unico e nunca nulo' AS regra,
         'BLOQUEANTE' AS severidade, 1.00 AS limiar, COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_orcamento_item) + COUNTIF(id_orcamento_item IS NULL) AS linhas_falha
  FROM tbl
  UNION ALL
  SELECT 'trs_vjob__orcamento_item.descricao_preenchida', 'Trusted', 'trs_vjob__orcamento_item', 'VJOB', 'COMPLETUDE',
         'toda linha tem descricao do servico', 'BLOQUEANTE', 1.00, COUNT(*), COUNTIF(descricao IS NULL)
  FROM tbl
  UNION ALL
  SELECT 'trs_vjob__orcamento_item.valor_positivo', 'Trusted', 'trs_vjob__orcamento_item', 'VJOB', 'VALIDADE',
         'valor_unitario e preenchido e maior que zero', 'BLOQUEANTE', 1.00, COUNT(*),
         COUNTIF(valor_unitario IS NULL OR valor_unitario <= 0)
  FROM tbl
  UNION ALL
  SELECT 'trs_vjob__orcamento_item.flag_residual_concorda', 'Trusted', 'trs_vjob__orcamento_item', 'VJOB', 'VALIDADE',
         'flag_tem_calculo_residual acende exatamente quando subtotal_residual ou quantidade_residual existe',
         'BLOQUEANTE', 1.00, COUNT(*),
         COUNTIF(flag_tem_calculo_residual <> (subtotal_residual IS NOT NULL OR quantidade_residual IS NOT NULL))
  FROM tbl
  UNION ALL
  -- LINHA DE BASE: hoje 2 de 2 batem (5 x 152,47 = 762,35 e 3 x 323,69 = 971,07).
  SELECT 'trs_vjob__orcamento_item.subtotal_residual_e_o_produto', 'Trusted', 'trs_vjob__orcamento_item', 'VJOB',
         'VALIDADE', 'quando subtotal_residual e quantidade_residual existem, subtotal = quantidade x valor_unitario (linha de base)',
         'ALERTA', 1.00, COUNTIF(subtotal_residual IS NOT NULL AND quantidade_residual IS NOT NULL),
         COUNTIF(subtotal_residual IS NOT NULL AND quantidade_residual IS NOT NULL
                 AND ABS(subtotal_residual - quantidade_residual * valor_unitario) > 0.01)
  FROM tbl
  UNION ALL
  -- Data do DADO nunca e futura: o tempo passando so faz a regra passar mais (nao compara flag gravada com relogio).
  SELECT 'trs_vjob__orcamento_item.criado_em_nao_futuro', 'Trusted', 'trs_vjob__orcamento_item', 'VJOB', 'VALIDADE',
         'criado_em nao esta no futuro', 'BLOQUEANTE', 1.00, COUNT(*),
         COUNTIF(criado_em IS NULL OR criado_em > CURRENT_DATETIME())
  FROM tbl
  UNION ALL
  SELECT 'trs_vjob__orcamento_item.linhas_reproduzem_a_origem', 'Trusted', 'trs_vjob__orcamento_item', 'VJOB',
         'INTEGRIDADE', 'a Trusted tem exatamente as linhas da origem tborcamento', 'BLOQUEANTE', 1.00, 1,
         IF((SELECT COUNT(*) FROM tbl) = (SELECT COUNT(*) FROM ori), 0, 1)
  UNION ALL
  SELECT 'trs_vjob__orcamento_item.precos_reproduzem_a_origem', 'Trusted', 'trs_vjob__orcamento_item', 'VJOB',
         'INTEGRIDADE', 'a soma de valor_unitario reproduz a soma de `valor` da origem (sem perda no cast para NUMERIC)',
         'BLOQUEANTE', 1.00, 1,
         IF(ABS((SELECT IFNULL(SUM(valor_unitario), 0) FROM tbl)
                - (SELECT IFNULL(SUM(SAFE_CAST(valor AS NUMERIC)), 0) FROM ori)) < 0.005, 0, 1)
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
  FROM r t
)
SELECT
  a.*,
  CASE
    WHEN a.flag_sem_linha_para_avaliar          THEN 'SEM_DADO'
    WHEN a.is_conforme                          THEN 'CONFORME'
    WHEN a.severidade = 'BLOQUEANTE'            THEN 'FALHA_BLOQUEANTE'
    ELSE                                             'FALHA_ALERTA'
  END                                           AS resultado,
  'VjobResiduos'                                AS familia,
  CURRENT_TIMESTAMP()                           AS _extraido_at,
  'mysql-yIOn'                                  AS _fonte,
  'America/Sao_Paulo'                           AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(a)))                AS _payload_hash
FROM avaliado a
