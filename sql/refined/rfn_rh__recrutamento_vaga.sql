-- rfn_rh__recrutamento_vaga
-- Refined / rh. Grao: uma vaga (job_id) do ATS Quickin, com funil, tempo de contratacao, candidaturas em aberto e pareamento das contratacoes.
-- Le trs_rh__recrutamento (quatro recortes por origem, que aqui viram colunas). Nivel: L3 CONFIDENTIAL (agregado por vaga; nenhum candidato nominal atravessa).
-- REGRA 1: cada bloco vem de UMA origem e nao se soma com os outros: aplicacoes, qualificados, desclassificados e contratados_funil vem do FUNIL_ETAPA;
--          contratacoes_tempo e dias_medio_contratacao do TEMPO_CONTRATACAO; candidaturas_abertas e dias_max_na_etapa da CANDIDATURA_ABERTA;
--          contratacoes_ponte, com_par_rh e seletivas da CONTRATACAO. Para o total de contratacoes use UMA delas (as tres somam 150 hoje).
-- REGRA 2: taxa_qualificacao = qualificados / aplicacoes e taxa_contratacao = contratados_funil / aplicacoes; NULL sem aplicacao, nunca zero.
-- REGRA 3: dias_medio_contratacao e por vaga; NAO se faz media entre vagas aqui (ponderar por contratacoes_tempo se for agregar).
-- REGRA 4: a vaga entra se aparecer em QUALQUER origem; flag_sem_funil marca vaga com contratacao ou candidatura e sem funil.
-- LIMITACOES - NAO CONTORNE: dias_na_etapa e dias_medio vem da origem, calculados na data da carga; 46 de 150 contratacoes sem par no RH formal;
--   nao ha custo nem canal de captacao (roi_canal e 100% 'desconhecido'); aplicacao em aberto nao e candidato unico (a mesma pessoa pode estar em varias).
WITH r AS (
  SELECT * FROM vanguardamartech_trusted.trs_rh__recrutamento
),
jobs AS (
  SELECT DISTINCT job_id FROM r
),
funil AS (
  SELECT job_id, ANY_VALUE(vaga) AS vaga, COUNT(*) AS qtd_etapas, SUM(qtd_aplicacoes) AS aplicacoes, SUM(qtd_qualificados) AS qualificados,
         SUM(qtd_desclassificados) AS desclassificados, SUM(qtd_contratados) AS contratados_funil
  FROM r WHERE origem = 'FUNIL_ETAPA' GROUP BY job_id
),
tempo AS (
  SELECT job_id, ANY_VALUE(vaga) AS vaga, SUM(qtd_contratados) AS contratacoes_tempo, AVG(dias_medio) AS dias_medio_contratacao, ANY_VALUE(cargo_categoria) AS cargo_categoria
  FROM r WHERE origem = 'TEMPO_CONTRATACAO' GROUP BY job_id
),
aberta AS (
  SELECT job_id, ANY_VALUE(vaga) AS vaga, COUNT(*) AS candidaturas_abertas, MAX(dias_na_etapa) AS dias_max_na_etapa
  FROM r WHERE origem = 'CANDIDATURA_ABERTA' GROUP BY job_id
),
ponte AS (
  SELECT job_id, COUNT(*) AS contratacoes_ponte, COUNTIF(tem_par_rh) AS com_par_rh, COUNTIF(is_seletivo) AS seletivas, MIN(data_contratacao) AS primeira_contratacao, MAX(data_contratacao) AS ultima_contratacao
  FROM r WHERE origem = 'CONTRATACAO' GROUP BY job_id
)
SELECT
  j.job_id,
  COALESCE(f.vaga, t.vaga, a.vaga)                                AS vaga,
  t.cargo_categoria,
  f.qtd_etapas,
  f.aplicacoes,
  f.qualificados,
  f.desclassificados,
  f.contratados_funil,
  SAFE_DIVIDE(f.qualificados, NULLIF(f.aplicacoes, 0))            AS taxa_qualificacao,
  SAFE_DIVIDE(f.contratados_funil, NULLIF(f.aplicacoes, 0))       AS taxa_contratacao,
  t.contratacoes_tempo,
  t.dias_medio_contratacao,
  a.candidaturas_abertas,
  a.dias_max_na_etapa,
  p.contratacoes_ponte,
  p.com_par_rh,
  p.seletivas,
  p.primeira_contratacao,
  p.ultima_contratacao,
  (f.job_id IS NULL)                                              AS flag_sem_funil,
  'L3_CONFIDENTIAL'                                               AS classificacao_dado,
  CURRENT_TIMESTAMP()                                             AS _extraido_at,
  'supabase-x0tz'                                                 AS _fonte
FROM jobs j
LEFT JOIN funil f ON f.job_id = j.job_id
LEFT JOIN tempo t ON t.job_id = j.job_id
LEFT JOIN aberta a ON a.job_id = j.job_id
LEFT JOIN ponte p ON p.job_id = j.job_id
