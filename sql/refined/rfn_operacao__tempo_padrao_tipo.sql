-- rfn_operacao__tempo_padrao_tipo
-- Refined / operacao. Grao: um TIPO de peca do iClips com o resumo dos tempos padrao por etapa. Chave: id_peca_tipo. Le trs_iclips__peca_etapa_tempo_padrao.
-- Nivel: L2 INTERNAL.
-- REGRA 1: qtd_linhas_etapa conta GRAFIAS (a Trusted nao deduplica); qtd_etapas_normalizadas conta etapas apos TRIM+UPPER. A diferenca sao as grafias
--          duplicadas (981 grupos em 2026-10-19, 946 com minutos diferentes entre si).
-- REGRA 2: soma_minutos_padrao_grafias soma toda linha com tempo (duplica etapa com duas grafias); soma_minutos_padrao_etapas soma UMA vez por etapa
--          normalizada, tomando o MAIOR minuto entre as grafias (escolha declarada: o maior e o conservador para prazo; a alternativa, a media,
--          inventaria um numero que nenhuma grafia tem). As duas convivem para a diferenca ficar visivel.
-- REGRA 3: zero e sentinela de "sem medicao" e ja saiu NULL na Trusted: soma, maximo e mediana ignoram as etapas sem tempo (qtd_etapas_sem_tempo).
--          Tipo sem nenhuma etapa com tempo tem soma, maximo e mediana NULL, nunca zero.
-- REGRA 4: flag_padrao_e_copia_do_medido e TRUE quando toda etapa com tempo tem min_padrao = min_medido_ref: 505 de 505 tipos COM tempo em 2026-10-19
--          (os outros 10 tipos nao tem nenhuma etapa com tempo e saem FALSE, nao "diferentes"): o "padrao sugerido" ainda e uma copia do medido;
--          quando alguem editar um padrao a flag cai e a leitura muda de sentido.
-- LIMITACOES - NAO CONTORNE: nao e SLA (a view vw_peca_sla_total tem todas as metricas zeradas e nao foi tratada); nao e tempo REAL (o apontado esta
--   em rfn_operacao__peca); a etapa canonica cobre 62,9% das linhas (qtd_linhas_sem_canonica).
-- VALIDACAO 2026-10-19 (query inteira rodada sobre a Trusted materializada): 515 linhas, 515 chaves e hashes, soma de qtd_linhas_etapa = 11.942,
--   soma de qtd_etapas_com_tempo = 11.302 e de qtd_etapas_sem_tempo = 640, 10 tipos sem soma (NULL), soma de minutos 721.970 por grafia e 687.624 por etapa.
WITH por_etapa AS (
  SELECT id_peca_tipo, etapa_normalizada, MAX(minutos_padrao) AS max_minutos_etapa
  FROM `vanguardamartech_trusted`.`trs_iclips__peca_etapa_tempo_padrao`
  GROUP BY 1, 2
),
etapas AS (
  SELECT id_peca_tipo, SUM(max_minutos_etapa) AS soma_minutos_padrao_etapas
  FROM por_etapa GROUP BY 1
),
agg AS (
  SELECT
    t.id_peca_tipo,
    ANY_VALUE(t.nome_peca_tipo)                                      AS nome_peca_tipo,
    COUNT(*)                                                         AS qtd_linhas_etapa,
    COUNT(DISTINCT t.etapa_normalizada)                              AS qtd_etapas_normalizadas,
    COUNTIF(t.flag_etapa_com_espaco)                                 AS qtd_grafias_com_espaco,
    COUNTIF(t.flag_grafia_duplicada_apos_trim)                       AS qtd_linhas_grafia_duplicada,
    COUNTIF(t.flag_etapa_sem_canonica)                               AS qtd_linhas_sem_canonica,
    COUNT(DISTINCT t.categoria_macro)                                AS qtd_categorias_macro,
    COUNTIF(t.minutos_padrao IS NOT NULL)                            AS qtd_etapas_com_tempo,
    COUNTIF(t.flag_sem_tempo_medido)                                 AS qtd_etapas_sem_tempo,
    SUM(t.minutos_padrao)                                            AS soma_minutos_padrao_grafias,
    MAX(t.minutos_padrao)                                            AS max_minutos_padrao,
    APPROX_QUANTILES(t.minutos_padrao, 2)[SAFE_OFFSET(1)]            AS mediana_minutos_padrao,
    (COUNTIF(t.minutos_padrao IS NOT NULL AND NOT t.flag_padrao_igual_medido) = 0
     AND COUNTIF(t.minutos_padrao IS NOT NULL) > 0)                  AS flag_padrao_e_copia_do_medido,
    LOGICAL_OR(t.flag_peca_tipo_nao_catalogada)                      AS flag_peca_tipo_nao_catalogada,
    MAX(t.atualizado_em)                                             AS ultima_atualizacao_em,
    MAX(t._extraido_at)                                              AS _extraido_trusted
  FROM `vanguardamartech_trusted`.`trs_iclips__peca_etapa_tempo_padrao` t
  GROUP BY t.id_peca_tipo
),
calc AS (
  SELECT a.*, e.soma_minutos_padrao_etapas,
    ROUND(a.soma_minutos_padrao_grafias / 60, 2)                     AS soma_horas_padrao_grafias,
    ROUND(e.soma_minutos_padrao_etapas / 60, 2)                      AS soma_horas_padrao_etapas,
    SAFE_DIVIDE(a.qtd_linhas_sem_canonica, a.qtd_linhas_etapa)       AS pct_linhas_sem_canonica
  FROM agg a
  LEFT JOIN etapas e USING (id_peca_tipo)
)
SELECT c.*, 'L2_INTERNAL' AS classificacao_dado, CURRENT_TIMESTAMP() AS _extraido_at, 'supabase-x0tz' AS _fonte, 'UTC' AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(c))) AS _payload_hash
FROM calc c
