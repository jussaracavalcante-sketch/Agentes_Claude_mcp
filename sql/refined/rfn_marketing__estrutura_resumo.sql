-- slug no deploy: query-4Yi5 (esta linha existe so no arquivo)
-- Refined Marketing - estrutura da conta RD (e-mails, ativos de captura, segmentacoes). L2 INTERNAL (so contagem de objetos).
-- Grao: _fonte. Colunas *_canonicos somam sem dupla contagem. Validado 18/10/2026 sobre a Raw em 5 contas: 5 linhas, 1.838 e-mails (1.007 canonicos), 406 ativos (235), 566 segmentacoes (326).
WITH em AS (
  SELECT _fonte, cliente, tipo_email, flag_envio_datado,
    (_fonte = MIN(_fonte) OVER (PARTITION BY id_email_origem)) AS is_canonico
  FROM `vanguardamartech_trusted`.`trs_rd_station__email`
),
em_m AS (
  SELECT _fonte, ANY_VALUE(cliente) AS cliente,
    COUNT(*) AS qtd_emails,
    COUNTIF(is_canonico) AS qtd_emails_canonicos,
    COUNTIF(tipo_email = 'email_model') AS qtd_emails_modelo,
    COUNTIF(tipo_email <> 'email_model') AS qtd_emails_campanha,
    COUNTIF(flag_envio_datado) AS qtd_emails_com_envio_datado
  FROM em GROUP BY _fonte
),
cp AS (
  SELECT _fonte, cliente, tipo_ativo, status_ativo,
    (_fonte = MIN(_fonte) OVER (PARTITION BY tipo_ativo, id_ativo_origem)) AS is_canonico
  FROM `vanguardamartech_trusted`.`trs_rd_station__captura`
),
cp_m AS (
  SELECT _fonte, ANY_VALUE(cliente) AS cliente,
    COUNT(*) AS qtd_ativos_captura,
    COUNTIF(is_canonico) AS qtd_ativos_captura_canonicos,
    COUNTIF(tipo_ativo = 'LANDING_PAGE') AS qtd_landing_pages,
    COUNTIF(tipo_ativo = 'POPUP') AS qtd_popups,
    COUNTIF(tipo_ativo = 'FORMULARIO_EMBUTIDO') AS qtd_formularios_embutidos,
    COUNTIF(status_ativo = 'PUBLISHED') AS qtd_ativos_publicados
  FROM cp GROUP BY _fonte
),
sg AS (
  SELECT _fonte, cliente, is_padrao_da_rd,
    (_fonte = MIN(_fonte) OVER (PARTITION BY id_segmentacao_origem)) AS is_canonico
  FROM `vanguardamartech_trusted`.`trs_rd_station__segmentacao`
),
sg_m AS (
  SELECT _fonte, ANY_VALUE(cliente) AS cliente,
    COUNT(*) AS qtd_segmentacoes,
    COUNTIF(is_canonico) AS qtd_segmentacoes_canonicas,
    COUNTIF(is_padrao_da_rd) AS qtd_segmentacoes_padrao
  FROM sg GROUP BY _fonte
),
chaves AS (
  SELECT _fonte, cliente FROM em_m
  UNION DISTINCT SELECT _fonte, cliente FROM cp_m
  UNION DISTINCT SELECT _fonte, cliente FROM sg_m
)
SELECT
  k._fonte AS id_estrutura,
  k._fonte,
  k.cliente,
  e.qtd_emails, e.qtd_emails_canonicos, e.qtd_emails_campanha, e.qtd_emails_modelo, e.qtd_emails_com_envio_datado,
  c.qtd_ativos_captura, c.qtd_ativos_captura_canonicos, c.qtd_landing_pages, c.qtd_popups, c.qtd_formularios_embutidos, c.qtd_ativos_publicados,
  s.qtd_segmentacoes, s.qtd_segmentacoes_canonicas, s.qtd_segmentacoes_padrao,
  (e._fonte IS NULL) AS flag_sem_stream_de_email,
  (c._fonte IS NULL) AS flag_sem_stream_de_captura,
  (s._fonte IS NULL) AS flag_sem_stream_de_segmentacao,
  CURRENT_TIMESTAMP() AS _extraido_at
FROM chaves k
LEFT JOIN em_m e USING (_fonte)
LEFT JOIN cp_m c USING (_fonte)
LEFT JOIN sg_m s USING (_fonte)
