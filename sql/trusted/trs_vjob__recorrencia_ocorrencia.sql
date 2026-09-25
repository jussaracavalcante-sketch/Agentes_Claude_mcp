-- trs_vjob__recorrencia_ocorrencia
-- Trusted / VJOB. Grao: uma OCORRENCIA gerada por uma regra de recorrencia.
-- Chave: id_ocorrencia. Origem: mysql-yIOn, `tarefas_tbjobs_recorrencia_ocorrencias`.
-- L2 INTERNAL -- so ids e datas.
--
-- O QUE ELA RESPONDE, e nenhuma outra tabela desta base responde: **quais jobs a
--   maquina criou, a partir de qual regra, e para qual data.** E o elo que faltava entre
--   `trs_vjob__job_recorrencia` (as 30 regras) e `trs_vjob__job_tarefa` (os jobs).
--
-- **A LIGACAO E 1:1 E ISSO E MEDIDO: 410 ocorrencias, 410 `job_id` DISTINTOS.** Nenhuma
--   ocorrencia divide job com outra, nenhum job aparece duas vezes. As 30 regras
--   produziram de **1 a 16** ocorrencias cada, media 13,7. **Zero orfaos nos dois lados**
--   -- toda ocorrencia aponta para regra que existe e para job que existe.
--
-- **O ACHADO QUE MUDA A LEITURA DE PRODUTIVIDADE: 349 DAS 410 SAO DE DATA FUTURA.**
--   O intervalo vai de 04/09/2026 a **23/12/2026**, e apenas 61 ja passaram. Como cada
--   ocorrencia **ja tem um job criado**, isso significa que **410 dos 1.343 jobs do
--   modulo TAREFAS (30,5%) sao gerados por maquina, e 349 deles (26% da tabela) sao
--   trabalho que ainda nao aconteceu**.
--   Quem contar job do modulo vivo como producao esta contando um quarto de tabela que
--   e agenda, nao entrega. `flag_ocorrencia_futura` existe para esse filtro.
--
-- **A OCORRENCIA GUARDA O PRAZO ORIGINAL; O JOB GUARDA O VIGENTE.** Medido:
--   `data_entrega` do job e igual a `data_ocorrencia` em **406 de 410**, e **os 4 que
--   divergem TEM, TODOS OS QUATRO, registro em `tarefas_tbjobs_prazo_hist`**. A
--   divergencia nunca e inexplicada -- ela sempre corresponde a uma alteracao de prazo
--   registrada. `flag_prazo_alterado` torna isso visivel sem exigir join na leitura, e
--   a invariante vira regra da suite de qualidade. **O deslocamento e pequeno: de 1 a 3
--   dias nos quatro** -- nada parecido com os 365 dias do maior adiamento da base.
--
-- **114 DOS 410 JOBS RECORRENTES FORAM CANCELADOS (27,8%)**, 268 estao `A fazer` e 28
--   `Aprovado` -- dos quais **2 sao de data futura e ja estao aprovados**. A recorrencia
--   gera, e mais de um quarto do que ela gera e descartado.
--
-- SO O MODULO DE TAREFAS TEM OCORRENCIA -- conferido no inventario dos 199 streams, nao
--   suposto: nao existe `advisory_*` nem `*_geral` desta tabela, pelo mesmo motivo que
--   nao existe recorrencia neles. A chave **nao** e composta, porque a origem e uma so.
--
-- `flag_ocorrencia_futura` E RELATIVA A DATA DA CARGA, nao a uma data fixa. A tabela e
--   reconstruida inteira a cada execucao, entao a flag acompanha `_extraido_at`. Para
--   analise historica que precise de corte estavel, usar `data_ocorrencia` contra a data
--   escolhida, nao a flag.
--
-- FUSO: `data_ocorrencia` ja e DATE na origem -- nao ha fuso a aplicar. `criado_em` e
--   TIMESTAMP com relogio local da intranet: **nao converter**.
--
-- AS OCORRENCIAS FORAM CRIADAS EM 39 LOTES, de **03/09/2026 11:14:29** a
--   **24/09/2026 09:37:20** (hoje). Nao e uma geracao unica -- o sistema vai criando
--   conforme a regra avanca.
--
-- MEDIDO EM 2026-09-24: 410 linhas · 410 chaves · 410 jobs distintos · 30 regras ·
--   zero orfaos · zero sem job · zero sem regra · 349 futuras e 61 passadas ·
--   4 com prazo alterado (1 a 3 dias), todos com log · 114 jobs cancelados e 28
--   concluidos · zero sem prazo vigente.
WITH base AS (
  SELECT o.id, o.recorrencia_id, o.job_id, o.data_ocorrencia, o.criado_em
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tarefas_tbjobs_recorrencia_ocorrencias` o
),
regras AS (
  SELECT DISTINCT id_recorrencia FROM `vanguardamartech_trusted`.`trs_vjob__job_recorrencia`
),
jobs AS (
  SELECT id_job_unico, data_entrega, status, is_cancelado, is_concluido
  FROM `vanguardamartech_trusted`.`trs_vjob__job_tarefa`
  WHERE origem = 'TAREFAS'
),
tratado AS (
  SELECT
    b.id                                                AS id_ocorrencia,
    b.recorrencia_id                                    AS id_recorrencia,
    b.job_id                                            AS id_job,
    CONCAT('TAREFAS:', CAST(b.job_id AS STRING))        AS id_job_unico,

    -- O prazo ORIGINAL, como a regra o gerou.
    b.data_ocorrencia                                   AS prazo_planejado,
    -- O prazo VIGENTE, do job. Iguais em 406 de 410.
    j.data_entrega                                      AS prazo_vigente,
    (j.data_entrega IS NOT NULL
     AND j.data_entrega <> b.data_ocorrencia)           AS flag_prazo_alterado,
    DATE_DIFF(j.data_entrega, b.data_ocorrencia, DAY)   AS dias_deslocados,

    -- Relativa a data da carga, nao a uma data fixa. Ver o bloco no cabecalho.
    (b.data_ocorrencia > CURRENT_DATE('America/Sao_Paulo'))
                                                        AS flag_ocorrencia_futura,

    -- Estado do job gerado, denormalizado para o filtro nao exigir join.
    j.status                                            AS status_job,
    j.is_cancelado                                      AS flag_job_cancelado,
    j.is_concluido                                      AS flag_job_concluido,

    -- FUSO: relogio local da intranet. Nao converter.
    b.criado_em,

    (r.id_recorrencia IS NULL)                          AS flag_regra_nao_catalogada,
    (j.id_job_unico IS NULL)                            AS flag_job_nao_catalogado
  FROM base b
  LEFT JOIN regras r ON r.id_recorrencia = b.recorrencia_id
  LEFT JOIN jobs   j ON j.id_job_unico   = CONCAT('TAREFAS:', CAST(b.job_id AS STRING))
)
SELECT
  t.*,
  CURRENT_TIMESTAMP()                                   AS _extraido_at,
  'mysql-yIOn'                                          AS _fonte,
  'America/Sao_Paulo'                                   AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(t)))                        AS _payload_hash
FROM tratado t
