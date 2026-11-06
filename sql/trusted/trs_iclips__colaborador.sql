-- trs_iclips__colaborador (query-Zelv)
-- Trusted / iClips. Grao: um COLABORADOR (executor) do iClips. Chave: id_colaborador_iclips.
-- Nivel: L4 PERSONAL_DATA (custo por hora individual, nome, atividade por pessoa). NAO atravessa nominal para a Refined.
--
-- ORIGEM. supabase_public_dim_colaborador (850), da supabase-x0tz, com o departamento de
-- supabase_public_map_colaborador_departamento (197) ligado por NOME. Medido em 18/10/2026: 850 linhas, 850 ids;
-- 800 vem do 'iClips Export' e 50 so existem na fato_atividade (fonte = 'fato_atividade only'); 185 ativos.
--
-- O ID NAO E O MESMO ENTRE AS DUAS TABELAS: casando map.responsible_id com dim.id so 2 de 197 batem; por nome batem
-- 200. O responsible_id do mapa parece outro universo de ids (causa nao verificada), por isso a ligacao e POR NOME e e
-- HIPOTESE declarada (flag_departamento_por_nome, 190 linhas), nunca prova. So entra quando o nome casa com UMA unica linha do
-- mapa (2 nomes repetidos no mapa ficam sem departamento_mapa) e com uma unica linha da dimensao.
--
-- NOME REPETIDO: 827 nomes distintos para 850 ids (23 ids excedentes; 44 linhas marcadas em flag_nome_repetido). Nome nao e chave.
--
-- CUSTO HORA: preenchido em 128 de 850 (722 NULL). Tres valores sao implausiveis como R$/hora (R$ 1.600, R$ 1.621 e
-- R$ 4.000: parecem salario mensal digitado no campo de hora): flag_custo_hora_implausivel (> R$ 500). Nao corrigidos.
-- 38 colaboradores inativos ainda carregam custo_hora: flag_custo_em_inativo.
--
-- FUSO: primeira_atividade e ultima_atividade sao DATE; updated_at e carimbo de sistema.
--
-- LIMITACAO -- NAO CONTORNE: custo_hora aqui nao e o custo da casa (esta em rfn_operacao__custo_peca) e cobre 15% da base;
-- nao multiplicar por horas apontadas (a casa decidiu custo por peca).
WITH mapa AS (
  SELECT UPPER(TRIM(responsible_name)) AS nome_chave, ANY_VALUE(departamento) AS departamento, COUNT(*) AS q
  FROM `vanguardamartech_raw`.`supabase_public_map_colaborador_departamento`
  GROUP BY 1
),
dim AS (
  SELECT d.*, UPPER(TRIM(d.nome)) AS nome_chave,
         COUNT(*) OVER (PARTITION BY UPPER(TRIM(d.nome))) AS qtd_mesmo_nome
  FROM `vanguardamartech_raw`.`supabase_public_dim_colaborador` d
)
SELECT
  CAST(d.id AS STRING)                                         AS id_colaborador_iclips,
  NULLIF(TRIM(d.nome), '')                                     AS nome,
  d.nome_chave,
  NULLIF(TRIM(d.departamento_cadastro), '')                    AS departamento_cadastro,
  NULLIF(TRIM(d.departamento_operacional), '')                 AS departamento_operacional,
  IF(m.q = 1 AND d.qtd_mesmo_nome = 1, NULLIF(TRIM(m.departamento), ''), NULL) AS departamento_mapa,
  (m.q = 1 AND d.qtd_mesmo_nome = 1)                           AS flag_departamento_por_nome,
  d.ativo                                                      AS is_ativo,
  d.custo_hora,
  (d.custo_hora > 500)                                         AS flag_custo_hora_implausivel,
  (d.custo_hora > 0 AND NOT d.ativo)                           AS flag_custo_em_inativo,
  d.total_atividades,
  d.primeira_atividade,
  d.ultima_atividade,
  NULLIF(TRIM(d.fonte), '')                                    AS fonte_cadastro,
  (d.qtd_mesmo_nome > 1)                                       AS flag_nome_repetido,
  DATE(d.updated_at, 'America/Sao_Paulo')                      AS derivado_atualizado_em,
  CURRENT_TIMESTAMP()                                          AS _extraido_at,
  'supabase-x0tz'                                              AS _fonte,
  'America/Sao_Paulo'                                          AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING((SELECT AS STRUCT d.id, d.nome, d.custo_hora, d.ativo, d.total_atividades)))) AS _payload_hash
FROM dim d
LEFT JOIN mapa m ON m.nome_chave = d.nome_chave
