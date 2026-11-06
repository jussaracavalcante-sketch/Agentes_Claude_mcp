-- rfn_operacao__escopo_mensal
-- Refined / dominio Operacao. Grao: um cliente, uma competencia, um servico.
-- Chave: id_cliente + competencia + id_servico.
-- Le trs_vjob__escopo, trs_vjob__cliente e trs_vjob__servico.
--
-- PARA QUE SERVE: e a camada onde "taxa de conclusao do escopo" pode ser lida sem
-- produzir numero falso. A Trusted responde quantos escopos existem e quantos estao
-- marcados; ela nao sabe quando um zero significa "nao fez" e quando significa
-- "ninguem registrou". Essa distincao e regra de negocio, e esta declarada abaixo.
--
-- REGRAS DE NEGOCIO
--
-- R1 -- COMPETENCIA FUTURA FICA MARCADA, NAO REMOVIDA.
--   A base planeja com meses de antecedencia: ha escopo cadastrado ate 09/2027.
--   `is_competencia_futura` acende para competencia maior que o mes corrente.
--   Somar sem esse filtro conta mes que ainda nao aconteceu como se fosse atraso.
--   A linha NAO e descartada -- planejamento futuro e informacao, so nao entra em
--   indicador de execucao.
--
-- R2 -- CONCLUSAO E `status = 1` DO SISTEMA, e so isso.
--   O derivado Supabase marca 82 linhas como concluidas que o sistema marca 0, com
--   `status2..status7` todos nulos. A divergencia nao se explica por coluna nenhuma.
--   Aqui vale o sistema.
--
-- R3 -- CLIENTE SEM NENHUMA CONCLUSAO NA JANELA NAO RECEBE TAXA.
--   Esta e a regra que existe por causa de um erro de leitura real. Medido em
--   2026-09-23 sobre o sistema: dos 251 clientes com escopo de 2025 em diante,
--   **86 nao tem UMA conclusao sequer**, e eles carregam **71.210 escopos**.
--   Para esses, "0% de conclusao" nao e desempenho -- e ausencia de registro.
--   `is_cliente_sem_registro` acende, e `taxa_conclusao` sai **NULL**, nao zero.
--   Zero e um numero e seria somado; NULL obriga quem le a decidir.
--
-- R4 -- 62 DESSES 86 TEM DATA DE PARADA, E E A MESMA.
--   Eles concluiam no quarto trimestre de 2024 e nao concluem nada desde entao.
--   `is_parou_q4_2024` marca. Isso muda a leitura do problema: nao sao 86 historias
--   separadas de cliente inativo, e um evento unico no fim de 2024 que 62 operacoes
--   atravessaram juntas. Os outros 24: 21 nunca concluiram nada em tempo algum e 3
--   pararam antes do Q4/2024.
--
-- R5 -- A COBERTURA DO CARIMBO VIAJA COM O NUMERO.
--   16% das conclusoes do sistema (10.926 de 68.016) nao tem `datahoramarcado`.
--   `qtd_concluidos_com_carimbo` e `cobertura_carimbo` estao na linha para que
--   qualquer serie temporal declare sobre quanto ela fala. Quem datar conclusao usa
--   `marcado_em`; contar pelo mes de CADASTRO inverte o sinal (foi o que aconteceu
--   em 21/09/2026, quando so havia o derivado).
--
-- R6 -- CLIENTE E O CADASTRO, NUNCA O GRUPO (R-003).
--   `cliente` recebe o nome do cadastro do VJOB. Nada de consolidar BRAGA, PMZ ou
--   UNIPAR aqui. Quem quiser o grupo agrupa na leitura.
--
-- R7 -- CLIENTE SEM CADASTRO PERMANECE, MARCADO.
--   96 dos 251 clientes do escopo (38%) nao existem em `tbclientes`, carregando
--   44.356 escopos. `flag_cliente_nao_catalogado` acende e a linha fica. Descartar
--   sumiria com 23% da base sem sinal.
--
-- LIMITACOES -- NAO CONTORNE
--   1. `taxa_conclusao` NULL nao e zero e nao se soma. Ao agregar varias linhas,
--      recalcule da razao de somas (`SUM(concluidos)/SUM(planejado)`) e exclua os
--      clientes com `is_cliente_sem_registro`, senao o denominador carrega 71 mil
--      escopos que ninguem marcou.
--   2. O nome do servico e rotulo de segunda mao -- a tabela de dominio do sistema
--      esta vazia. 4 dos 38 servicos nao tem nome (7.980 escopos). Ver
--      `trs_vjob__servico`.
--   3. `dias_prazo_vs_marcacao` so existe onde ha carimbo E prazo. A media por si
--      nao mede atraso de processo: mede a distancia entre o prazo cadastrado e o
--      momento em que alguem clicou.
--   4. Esta tabela NAO carrega dinheiro. Escopo e planejamento de entrega; receita
--      esta em `tbcronograma`/`tbcronogramadatas`, que ainda nao tem Trusted.
WITH janela AS (
  -- Mes corrente em hora local. E o unico parametro da tabela e fica numa CTE
  -- propria para que a regra R1 seja legivel, nao escondida num WHERE.
  SELECT DATE_TRUNC(CURRENT_DATE('America/Sao_Paulo'), MONTH) AS mes_corrente
),
-- Perfil por cliente: e aqui que R3 e R4 se decidem, e sempre sobre a janela
-- "2025 em diante", que e a janela em que a base esta viva.
perfil_cliente AS (
  SELECT
    e.id_cliente,
    SUM(IF(e.competencia >= '2025-01-01' AND e.is_concluido, 1, 0))                    AS concl_2025_em_diante,
    SUM(IF(e.competencia BETWEEN '2024-10-01' AND '2024-12-01' AND e.is_concluido, 1, 0)) AS concl_q4_2024,
    SUM(IF(e.competencia >= '2025-01-01', 1, 0))                                       AS plan_2025_em_diante,
    MAX(IF(e.is_concluido, e.competencia, NULL))                                       AS ultima_competencia_concluida,
    MAX(e.marcado_em)                                                                  AS ultima_marcacao
  FROM `vanguardamartech_trusted`.`trs_vjob__escopo` e
  GROUP BY e.id_cliente
),
agregado AS (
  SELECT
    e.id_cliente,
    e.competencia,
    e.id_servico,
    ANY_VALUE(e.cliente)                            AS cliente,
    ANY_VALUE(e.cliente_cnpj)                       AS cliente_cnpj,
    LOGICAL_OR(e.cliente_ativo)                     AS cliente_ativo,
    LOGICAL_OR(e.flag_cliente_nao_catalogado)       AS flag_cliente_nao_catalogado,
    COUNT(*)                                        AS qtd_planejado,
    COUNTIF(e.is_concluido)                         AS qtd_concluido,
    COUNTIF(e.is_concluido AND e.marcado_em IS NOT NULL) AS qtd_concluido_com_carimbo,
    COUNTIF(e.flag_prazo_alterado)                  AS qtd_prazo_alterado,
    COUNT(DISTINCT e.id_marcado_por)                AS qtd_pessoas_marcaram,
    MIN(e.dt_prazo)                                 AS primeiro_prazo,
    MAX(e.dt_prazo)                                 AS ultimo_prazo,
    MAX(e.marcado_em)                               AS ultima_marcacao_na_linha,
    AVG(e.dias_prazo_vs_marcacao)                   AS media_dias_prazo_vs_marcacao
  FROM `vanguardamartech_trusted`.`trs_vjob__escopo` e
  GROUP BY e.id_cliente, e.competencia, e.id_servico
)
SELECT
  CONCAT(CAST(a.id_cliente AS STRING), '|',
         FORMAT_DATE('%Y-%m', a.competencia), '|',
         CAST(a.id_servico AS STRING))              AS id_escopo_mensal,
  a.id_cliente,
  a.cliente,
  a.cliente_cnpj,
  a.cliente_ativo,
  a.flag_cliente_nao_catalogado,

  a.competencia,
  EXTRACT(YEAR  FROM a.competencia)                 AS ano,
  EXTRACT(MONTH FROM a.competencia)                 AS mes,
  -- R1
  (a.competencia > j.mes_corrente)                  AS is_competencia_futura,
  (a.competencia = j.mes_corrente)                  AS is_competencia_corrente,

  a.id_servico,
  s.servico,
  s.flag_nome_nao_resolvido                         AS flag_servico_sem_nome,

  a.qtd_planejado,
  a.qtd_concluido,
  a.qtd_concluido_com_carimbo,
  a.qtd_prazo_alterado,
  a.qtd_pessoas_marcaram,

  -- R3: taxa NULL, nunca zero, para cliente que nao registra.
  IF(p.concl_2025_em_diante = 0 AND p.plan_2025_em_diante > 0,
     NULL,
     SAFE_DIVIDE(a.qtd_concluido, a.qtd_planejado))  AS taxa_conclusao,
  (p.concl_2025_em_diante = 0 AND p.plan_2025_em_diante > 0) AS is_cliente_sem_registro,
  -- R4
  (p.concl_2025_em_diante = 0 AND p.concl_q4_2024 > 0)       AS is_parou_q4_2024,
  p.ultima_competencia_concluida,
  DATE(p.ultima_marcacao)                            AS dt_ultima_marcacao_do_cliente,

  -- R5
  SAFE_DIVIDE(a.qtd_concluido_com_carimbo, NULLIF(a.qtd_concluido, 0)) AS cobertura_carimbo,

  a.primeiro_prazo,
  a.ultimo_prazo,
  DATE(a.ultima_marcacao_na_linha)                  AS dt_ultima_marcacao,
  ROUND(a.media_dias_prazo_vs_marcacao, 2)          AS media_dias_prazo_vs_marcacao,

  CURRENT_TIMESTAMP()                               AS _extraido_at,
  'mysql-yIOn'                                      AS _fonte,
  'America/Sao_Paulo'                               AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(a)))                    AS _payload_hash
FROM agregado a
CROSS JOIN janela j
LEFT JOIN perfil_cliente p ON p.id_cliente = a.id_cliente
-- LEFT: servico sem linha na dimensao nao derruba o escopo.
LEFT JOIN `vanguardamartech_trusted`.`trs_vjob__servico` s ON s.id_servico = a.id_servico
