-- trs_vjob__noticia_interacao
-- Trusted / VJOB. Grao: uma INTERACAO de usuario com uma noticia da intranet, em dois tipos: LEITURA (recibo datado) e DESTINATARIO (usuario na lista
-- de distribuicao da noticia, sem data). Chave: id_interacao = tipo | id da origem. Origem: mysql-yIOn (semanal, domingo), tabelas
-- mysql_vjobvjob_2024_tbnoticiasextra (LEITURA, 462) e mysql_vjobvjob_2024_tbnoticiasextra2 (DESTINATARIO, 3.732). Medido em 2026-10-19.
-- POR QUE SAO DUAS ENTIDADES E NAO DUAS VERSOES -- medido, nao suposto: tbnoticiasextra tem (id, idusuario, idnoticia, dataleitura) -- 462 linhas,
-- 462 pares (noticia, usuario) distintos, 40 noticias, 154 usuarios, data em 100%, de 2019-06-26 a 2026-10-15. tbnoticiasextra2 tem (id, idnoticia,
-- idusuarios) SEM DATA -- 3.732 linhas, 3.732 pares distintos, 53 noticias, 407 usuarios -- e 35 noticias carregam a MESMA lista de 58 usuarios
-- (uma unica lista distinta) e 4 noticias a MESMA lista de 203: e a lista de quem devia ver a noticia no momento da publicacao, nao um recibo.
-- 426 das 462 leituras caem em par que esta na lista (92%); 36 leituras sao de quem nao estava na lista (flag_leitura_fora_da_lista).
-- O CLAUDE.md dizia "tbnoticiasextra tem 40 noticias e a 2 tem 53": confere (40 e 53 idnoticia distintos). O sufixo 2 nao e descarte.
-- A NOTICIA QUASE NUNCA EXISTE MAIS: tbnoticias tem 8 linhas (ids 7, 43, 44, 45, 53, 54, 56, 59); 174 das 462 leituras e 2.582 dos 3.732 destinatarios
-- apontam para noticia apagada (flag_noticia_nao_catalogada). O usuario resolve contra tbusuariointranet (278): 135 de 462 leituras e 1.335 de 3.732
-- destinatarios (200 usuarios distintos) -- o resto e usuario que saiu do cadastro; a tabela `usuario` do MySQL NAO e o cadastro (zero casam).
-- FUSO MEDIDO: a hora da leitura tem vale as 13h (11) entre 12h (41) e 14h (30) e pico de fim de tarde (18h 50, 19h 68) -- almoco as 13h local; em
-- UTC o almoco cairia as 10h. VJOB grava hora local: `interagido_em` sai como esta, sem conversao (convencao da casa, confirmada aqui).
-- Nivel: L4 PERSONAL_DATA por linhagem (id_usuario liga a pessoa em trs_vjob__usuario). A Refined (rfn_operacao__noticia_alcance) agrega por noticia.
WITH leitura AS (
  SELECT 'LEITURA' AS tipo_interacao, CAST(id AS INT64) AS id_origem, CAST(idnoticia AS INT64) AS id_noticia, CAST(idusuario AS INT64) AS id_usuario,
         CAST(dataleitura AS TIMESTAMP) AS interagido_em
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbnoticiasextra`
),
destinatario AS (
  SELECT 'DESTINATARIO' AS tipo_interacao, CAST(id AS INT64) AS id_origem, CAST(idnoticia AS INT64) AS id_noticia, CAST(idusuarios AS INT64) AS id_usuario,
         CAST(NULL AS TIMESTAMP) AS interagido_em
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbnoticiasextra2`
),
base AS (SELECT * FROM leitura UNION ALL SELECT * FROM destinatario),
pares_l AS (SELECT DISTINCT id_noticia, id_usuario FROM leitura),
pares_d AS (SELECT DISTINCT id_noticia, id_usuario FROM destinatario),
tratado AS (
  SELECT
    CONCAT(b.tipo_interacao, '|', CAST(b.id_origem AS STRING))         AS id_interacao,
    b.tipo_interacao, b.id_origem, b.id_noticia, b.id_usuario, b.interagido_em,
    (n.id IS NULL)                                                     AS flag_noticia_nao_catalogada,
    (u.id IS NULL)                                                     AS flag_usuario_nao_catalogado,
    (b.tipo_interacao = 'LEITURA' AND d.id_noticia IS NULL)            AS flag_leitura_fora_da_lista,
    (b.tipo_interacao = 'DESTINATARIO' AND l.id_noticia IS NOT NULL)   AS flag_destinatario_leu
  FROM base b
  LEFT JOIN (SELECT DISTINCT CAST(id AS INT64) AS id FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbnoticias`) n ON n.id = b.id_noticia
  LEFT JOIN (SELECT DISTINCT CAST(id AS INT64) AS id FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbusuariointranet`) u ON u.id = b.id_usuario
  LEFT JOIN pares_d d ON b.tipo_interacao = 'LEITURA' AND d.id_noticia = b.id_noticia AND d.id_usuario = b.id_usuario
  LEFT JOIN pares_l l ON b.tipo_interacao = 'DESTINATARIO' AND l.id_noticia = b.id_noticia AND l.id_usuario = b.id_usuario
)
SELECT t.*, 'L4_PERSONAL_DATA' AS classificacao_dado, CURRENT_TIMESTAMP() AS _extraido_at, 'mysql-yIOn' AS _fonte, 'America/Sao_Paulo' AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(t))) AS _payload_hash
FROM tratado t
