-- rfn_operacao__peca
-- Refined / dominio Operacao. Grao: uma peca de job do iClips. Chave: id_job_peca.
-- Le trs_iclips__peca, __etapa, __apontamento, __projeto e __peca_atributo.

WITH
-- Data implausivel nao e excluida: e sinalizada e neutralizada nos derivados.
etapa AS (
  SELECT
    e.*,
    (DATE(e.inicio) < '2015-01-01' OR DATE(e.inicio) > CURRENT_DATE('America/Sao_Paulo')) AS inicio_implausivel,
    (e.fim IS NOT NULL AND e.fim < e.inicio)                                              AS fim_antes_do_inicio,
    -- REGRA 2, passos 1 e 2 do algoritmo da Criacao: sem acento, maiusculas,
    -- espacos colapsados, e o typo do proprio iClips corrigido.
    TRIM(REPLACE(
      REGEXP_REPLACE(
        UPPER(REGEXP_REPLACE(NORMALIZE(IFNULL(e.nome_etapa, ''), NFD), r'\p{Mn}', '')),
        r'\s+', ' '),
      'CLIETE', 'CLIENTE'))                                                               AS etapa_norm
  FROM `vanguardamartech_trusted.trs_iclips__etapa` e
),
-- REGRA 2, passos 3 a 7: aprovacao nunca e retrabalho; ALTERA fica de fora.
etapa_cls AS (
  SELECT
    c.*,
    (c.etapa_norm NOT LIKE '%APROVACAO%'
     AND (c.etapa_norm LIKE '%AJUSTE%' OR c.etapa_norm LIKE '%REFAC%'))                   AS eh_retrabalho,
    (c.etapa_norm NOT LIKE '%APROVACAO%' AND c.etapa_norm LIKE '%ALTERA%'
     AND c.etapa_norm NOT LIKE '%AJUSTE%' AND c.etapa_norm NOT LIKE '%REFAC%')            AS eh_altera_nao_contado
  FROM etapa c
),
etapa_ok AS (
  SELECT * FROM etapa_cls WHERE inicio IS NOT NULL AND NOT inicio_implausivel
),
-- REGRA 2: retrabalho contado por ETAPA, nunca por hora.
por_peca_etapa AS (
  SELECT
    id_job_peca,
    COUNT(*)                                                      AS qtd_etapas,
    -- classificacao pelo TEXTO (autoritativa, algoritmo da Criacao)
    COUNTIF(eh_retrabalho)                                        AS qtd_retrabalho,
    COUNTIF(eh_retrabalho AND etapa_norm LIKE '%CLIENTE%')        AS qtd_retrabalho_cliente,
    COUNTIF(eh_retrabalho AND etapa_norm NOT LIKE '%CLIENTE%'
            AND etapa_norm LIKE '%INTERN%')                       AS qtd_retrabalho_interno,
    COUNTIF(eh_retrabalho AND etapa_norm NOT LIKE '%CLIENTE%'
            AND etapa_norm NOT LIKE '%INTERN%')                   AS qtd_retrabalho_sem_classificacao,
    COUNTIF(eh_retrabalho AND etapa_norm LIKE '%REFAC%')          AS qtd_refacao,
    COUNTIF(eh_retrabalho AND etapa_norm NOT LIKE '%REFAC%')      AS qtd_ajuste,
    COUNTIF(eh_altera_nao_contado)                                AS qtd_altera_nao_contado,
    -- campo estruturado do payload, mantido so para auditoria (subconta)
    COUNTIF(refacao)                                              AS qtd_refacoes_campo,
    SUM(tempo_estimado_min)                                       AS tempo_estimado_min,
    COUNTIF(inicio_implausivel)                                   AS qtd_etapas_data_implausivel,
    COUNTIF(fim_antes_do_inicio)                                  AS qtd_etapas_fim_invertido,
    SUM(qtd_apontamentos)                                         AS qtd_apontamentos_declarados
  FROM etapa_cls
  GROUP BY id_job_peca
),
janela AS (
  SELECT id_job_peca, MIN(inicio) AS iniciada_em, MAX(COALESCE(fim, inicio)) AS encerrada_em
  FROM etapa_ok GROUP BY id_job_peca
),
-- REGRA 5: hora real cobre so a janela viva do apontamento.
por_peca_apont AS (
  SELECT
    id_job_peca,
    COUNT(*)                                     AS qtd_apontamentos_medidos,
    SUM(tempo_gasto_min)                         AS tempo_real_min,
    SUM(IF(sem_custo_hora, tempo_gasto_min, 0))  AS tempo_real_sem_custo_min,
    SUM(custo_estimado)                          AS custo_apontado,
    COUNT(DISTINCT executor_id)                  AS qtd_executores
  FROM `vanguardamartech_trusted.trs_iclips__apontamento`
  WHERE id_job_peca IS NOT NULL
  GROUP BY id_job_peca
),
atributo AS (
  SELECT id_job_peca, ANY_VALUE(id_executor) AS id_executor,
         ANY_VALUE(executor_nome) AS executor_nome,
         ANY_VALUE(executor_departamento) AS executor_departamento,
         ANY_VALUE(cnpj_valido) AS tem_cnpj_no_atributo,
         ANY_VALUE(cliente_cnpj) AS cnpj_do_atributo
  FROM `vanguardamartech_trusted.trs_iclips__peca_atributo`
  GROUP BY id_job_peca
),
base AS (
  SELECT
    p.id_job_peca,
    p.id_projeto,
    p.nome_peca,
    p.titulo_atividade,
    COALESCE(p.status_peca_rotulo, CAST(p.status_peca_codigo AS STRING)) AS status_peca,
    pr.nome_projeto,
    pr.status_projeto_raw                                          AS status_projeto,
    -- REGRA 1: cliente resolvido por CNPJ quando existe.
    pr.cliente_nome,
    COALESCE(REGEXP_REPLACE(pr.cliente_cnpj, r'[^0-9]', ''), a.cnpj_do_atributo) AS cliente_cnpj,
    pr.grupo_cliente_nome                                          AS cliente_grupo,
    a.id_executor, a.executor_nome, a.executor_departamento,
    j.iniciada_em, j.encerrada_em,
    pe.qtd_etapas, pe.qtd_retrabalho, pe.qtd_retrabalho_cliente, pe.qtd_retrabalho_interno,
    pe.qtd_retrabalho_sem_classificacao, pe.qtd_refacao, pe.qtd_ajuste,
    pe.qtd_altera_nao_contado, pe.qtd_refacoes_campo,
    pe.tempo_estimado_min, pe.qtd_etapas_data_implausivel, pe.qtd_etapas_fim_invertido,
    pe.qtd_apontamentos_declarados,
    ap.qtd_apontamentos_medidos, ap.tempo_real_min, ap.tempo_real_sem_custo_min,
    ap.custo_apontado, ap.qtd_executores,
    p.origem_do_registro, p._extraido_at
  FROM `vanguardamartech_trusted.trs_iclips__peca` p
  LEFT JOIN `vanguardamartech_trusted.trs_iclips__projeto` pr USING (id_projeto)
  LEFT JOIN por_peca_etapa pe USING (id_job_peca)
  LEFT JOIN janela         j  USING (id_job_peca)
  LEFT JOIN por_peca_apont ap USING (id_job_peca)
  LEFT JOIN atributo       a  USING (id_job_peca)
)
SELECT
  b.id_job_peca,
  b.id_projeto,
  b.nome_projeto,
  b.nome_peca,
  b.titulo_atividade,
  b.status_peca,
  b.status_projeto,

  -- cliente
  b.cliente_nome,
  b.cliente_cnpj,
  b.cliente_cnpj IS NOT NULL AND LENGTH(b.cliente_cnpj) = 14       AS cliente_identificado,
  b.cliente_grupo,

  -- execucao
  b.id_executor,
  b.executor_nome,
  b.executor_departamento,

  -- eixo temporal (REGRA 4: derivado de data implausivel vira NULL)
  b.iniciada_em,
  b.encerrada_em,
  DATE(b.iniciada_em)                                              AS data_inicio,
  DATE_TRUNC(DATE(b.iniciada_em), MONTH)                           AS mes_referencia,
  IF(b.encerrada_em IS NULL OR b.iniciada_em IS NULL, NULL,
     TIMESTAMP_DIFF(b.encerrada_em, b.iniciada_em, DAY))           AS dias_em_producao,

  -- esforco estimado: cobre 2020+ no tempo, mas so 2,8% das etapas tem o campo
  -- preenchido (14.485 de 515.443). Profundo em periodo, ESPARSO em linha.
  IFNULL(b.qtd_etapas, 0)                                          AS qtd_etapas,
  b.tempo_estimado_min,
  ROUND(b.tempo_estimado_min / 60, 4)                              AS tempo_estimado_horas,

  -- REGRA 2 e 3: retrabalho lido do TEXTO da etapa, com origem declarada
  IFNULL(b.qtd_retrabalho, 0)                                      AS qtd_retrabalho,
  IFNULL(b.qtd_retrabalho_cliente, 0)                              AS qtd_retrabalho_cliente,
  IFNULL(b.qtd_retrabalho_interno, 0)                              AS qtd_retrabalho_interno,
  IFNULL(b.qtd_retrabalho_sem_classificacao, 0)                    AS qtd_retrabalho_sem_classificacao,
  IFNULL(b.qtd_refacao, 0)                                         AS qtd_refacao,
  IFNULL(b.qtd_ajuste, 0)                                          AS qtd_ajuste,
  IFNULL(b.qtd_retrabalho, 0) > 0                                  AS teve_retrabalho,
  IFNULL(b.qtd_retrabalho_sem_classificacao, 0) > 0                AS tem_retrabalho_sem_classificacao,
  CASE
    WHEN IFNULL(b.qtd_retrabalho, 0) = 0 THEN 'SEM_RETRABALHO'
    WHEN IFNULL(b.qtd_retrabalho_cliente,0) > 0 AND IFNULL(b.qtd_retrabalho_interno,0) > 0 THEN 'AMBOS'
    WHEN IFNULL(b.qtd_retrabalho_cliente,0) > 0 THEN 'SOMENTE_CLIENTE'
    WHEN IFNULL(b.qtd_retrabalho_interno,0) > 0 THEN 'SOMENTE_INTERNO'
    ELSE 'SEM_CLASSIFICACAO'
  END                                                              AS origem_do_retrabalho,
  SAFE_DIVIDE(b.qtd_retrabalho, b.qtd_etapas)                      AS proporcao_etapas_em_retrabalho,
  -- REGRA 6: a regra 5 do algoritmo (ALTERA so no Audiovisual) NAO foi aplicada.
  IFNULL(b.qtd_altera_nao_contado, 0)                              AS qtd_altera_nao_contado,
  -- auditoria: o campo estruturado do payload, que SUBCONTA. Nao usar em indicador.
  IFNULL(b.qtd_refacoes_campo, 0)                                  AS qtd_refacoes_campo_auditoria,

  -- REGRA 5: esforco real, cobertura rasa e declarada
  b.tempo_real_min,
  ROUND(b.tempo_real_min / 60, 4)                                  AS tempo_real_horas,
  b.qtd_apontamentos_medidos,
  b.qtd_apontamentos_declarados,
  b.qtd_executores,
  b.custo_apontado,
  b.tempo_real_min IS NOT NULL                                     AS tem_esforco_medido,
  ROUND(b.tempo_real_sem_custo_min / 60, 4)                        AS tempo_real_sem_custo_horas,
  IFNULL(b.tempo_real_sem_custo_min, 0) > 0                        AS custo_incompleto,
  IF(b.tempo_real_min IS NULL OR b.tempo_estimado_min IS NULL OR b.tempo_estimado_min = 0,
     NULL, ROUND(b.tempo_real_min / b.tempo_estimado_min, 4))      AS razao_real_sobre_estimado,

  -- REGRA 4: confiabilidade declarada linha a linha
  IFNULL(b.qtd_etapas_data_implausivel, 0)                         AS qtd_etapas_data_implausivel,
  IFNULL(b.qtd_etapas_fim_invertido, 0)                            AS qtd_etapas_fim_invertido,
  (IFNULL(b.qtd_etapas_data_implausivel, 0) = 0
   AND IFNULL(b.qtd_etapas_fim_invertido, 0) = 0
   AND b.iniciada_em IS NOT NULL)                                  AS registro_confiavel,

  b.origem_do_registro,
  b._extraido_at,
  'America/Sao_Paulo'                                              AS _fuso,
  'trs_iclips__peca + __etapa + __apontamento + __projeto + __peca_atributo' AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(b)))                                   AS _payload_hash
FROM base b
