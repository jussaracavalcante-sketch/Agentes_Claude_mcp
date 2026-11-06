-- trs_vjob__acao_administrativa
-- O unico log de acao ADMINISTRATIVA do VJOB: quem ativou, desativou ou deletou
-- cadastro, e quando. Origem: mysql_vjobvjob_2024_tbrelatorioacoes (430).
--
-- ELA PROVA A ARQUITETURA DOS DOIS CADASTROS. O sistema escreve
-- "Desativou o cliente 105 (atendimento 338)" -- distingue as duas identidades
-- sozinho. Nas 59 linhas com o par: 59 de 59 conferem contra a ponte da conta,
-- ZERO divergem, e zero tem os dois ids iguais.
--
-- CUIDADO COM A PALAVRA: aqui "cliente" e o CADASTRO JURIDICO e "atendimento" e a
-- CONTA. Em tbgestoresclientes a coluna CHAMADA id_cliente e a CONTA. Mesma
-- palavra, sentido oposto, no mesmo sistema.
--
-- FUSO: o VJOB grava relogio local. `ocorrido_em` vem TIMESTAMP do MySQL e NADA SE CONVERTE.
WITH origem AS (
  SELECT
    id                                                          AS id_acao,
    NULLIF(id_usuario, 0)                                       AS id_usuario,
    acao                                                        AS acao_na_origem,
    data                                                        AS ocorrido_em
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbrelatorioacoes`
),
parseado AS (
  SELECT
    o.*,
    -- REGRA 1 - a ordem importa: "o cliente N de auditoria" ANTES de "o cliente N",
    -- senao o caso especifico cai no generico. Cinco padroes cobrem 430 de 430.
    CASE
      WHEN REGEXP_CONTAINS(o.acao_na_origem, r'(?i)o cliente [0-9]+ de auditoria')
                                                                      THEN 'CLIENTE_AUDITORIA'
      WHEN REGEXP_CONTAINS(o.acao_na_origem, r'(?i)na tabela [a-z_0-9]+ o registro [0-9]+')
                                                                      THEN 'REGISTRO_EM_TABELA'
      WHEN REGEXP_CONTAINS(o.acao_na_origem, r'(?i)o gestor [0-9]+')  THEN 'GESTOR'
      WHEN REGEXP_CONTAINS(o.acao_na_origem, r'(?i)o cliente [0-9]+') THEN 'CLIENTE'
      ELSE 'NAO_RECONHECIDO'
    END                                                         AS alvo_tipo,
    REGEXP_EXTRACT(o.acao_na_origem, r'^([A-Za-zÀ-ú]+)')        AS verbo_na_origem,
    -- REGRA 3 - grafia mista e cosmetica: canoniza aqui, preserva a crua ao lado.
    UPPER(REGEXP_EXTRACT(o.acao_na_origem, r'^([A-Za-zÀ-ú]+)')) AS verbo_canonico,
    SAFE_CAST(REGEXP_EXTRACT(o.acao_na_origem, r'(?i)o cliente ([0-9]+)') AS INT64)
                                                                AS id_cliente_juridico,
    SAFE_CAST(REGEXP_EXTRACT(o.acao_na_origem, r'(?i)\(atendimento ([0-9]+)\)') AS INT64)
                                                                AS id_atendimento,
    LOWER(REGEXP_EXTRACT(o.acao_na_origem, r'(?i)na tabela ([a-z_0-9]+) o registro'))
                                                                AS tabela_alvo,
    SAFE_CAST(REGEXP_EXTRACT(o.acao_na_origem, r'(?i)o registro ([0-9]+)') AS INT64)
                                                                AS id_registro_alvo,
    SAFE_CAST(REGEXP_EXTRACT(o.acao_na_origem, r'(?i)o gestor ([0-9]+)') AS INT64)
                                                                AS id_gestor_alvo
  FROM origem o
),
usuarios AS (
  SELECT DISTINCT id_usuario, NULLIF(TRIM(nome), '') AS nome
  FROM `vanguardamartech_trusted`.`trs_vjob__usuario`
),
juridico AS (
  SELECT DISTINCT id_cliente, razao_social
  FROM `vanguardamartech_trusted`.`trs_vjob__cliente`
),
conta AS (
  SELECT DISTINCT id_atendimento, nome_conta, id_cliente AS ponte_juridica
  FROM `vanguardamartech_trusted`.`trs_vjob__cliente_atendimento`
),
tratado AS (
  SELECT
    p.id_acao,

    p.id_usuario,
    u.nome                                                      AS usuario_nome,
    (p.id_usuario IS NOT NULL AND u.id_usuario IS NULL)         AS flag_autor_nao_catalogado,

    -- REGRA 4 - o texto cru sai inteiro. O parser acrescenta, nunca substitui.
    p.acao_na_origem,
    p.verbo_na_origem,
    p.verbo_canonico,
    p.alvo_tipo,
    -- REGRA 2 - gatilho de manutencao do parser. Hoje ZERO.
    (p.alvo_tipo = 'NAO_RECONHECIDO')                           AS flag_padrao_nao_reconhecido,

    p.id_cliente_juridico,
    j.razao_social                                              AS cliente_razao_social,
    (p.id_cliente_juridico IS NOT NULL AND j.id_cliente IS NULL) AS flag_cliente_nao_catalogado,

    p.id_atendimento,
    c.nome_conta,
    -- A PROVA, guardada como coluna: 59 de 59 conferem, zero divergem.
    (p.id_atendimento IS NOT NULL
      AND c.ponte_juridica IS NOT NULL
      AND c.ponte_juridica <> p.id_cliente_juridico)            AS flag_par_cliente_conta_diverge,
    (p.id_atendimento IS NOT NULL AND c.id_atendimento IS NULL) AS flag_conta_nao_catalogada,

    -- Emitido cru, sem join: o id so faz sentido dentro da tabela citada.
    p.tabela_alvo,
    p.id_registro_alvo,
    p.id_gestor_alvo,

    -- FUSO: relogio local. Nao converter.
    p.ocorrido_em
  FROM parseado p
  -- ANTI-JOIN por CTE DISTINCT, nao `NOT EXISTS` correlacionado.
  LEFT JOIN usuarios u ON u.id_usuario     = p.id_usuario
  LEFT JOIN juridico j ON j.id_cliente     = p.id_cliente_juridico
  LEFT JOIN conta    c ON c.id_atendimento = p.id_atendimento
)
SELECT
  t.*,
  CURRENT_TIMESTAMP()                                           AS _extraido_at,
  'mysql-yIOn'                                                  AS _fonte,
  'America/Sao_Paulo'                                           AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(t)))                                AS _payload_hash
FROM tratado t
