-- trs_vjob__squad_alteracao
-- Trusted / VJOB. Grao: uma troca de responsavel de squad num cliente.
-- Chave: id_alteracao. Origem: mysql-yIOn, `tb_logs_squad` (2.332). L2 INTERNAL.
--
-- O QUE ELA RESPONDE, e nenhuma outra tabela desta base responde: **quem atendeu qual
--   cliente, em qual papel, e quando isso mudou.** E a historia do time por cliente.
--   Periodo: **06/11/2024 12:10:03** a **22/09/2026 19:26:53**.
--
-- QUINZE PAPEIS DE SQUAD, todos medidos: `customersuccess`, `analistamkt`,
--   `analistamktgoogle`, `analistamktmeta`, `analistaseo`, `analistasocial`,
--   `assistente`, `redacao`, `redacao2`, `redacao3`, `criacao`, `criacao2`, `criacao3`,
--   `storymaker`, `sac`. Sao nomes fisicos de coluna na origem, **sem tabela de
--   dominio** -- saem crus, e os sufixos numericos sao posicoes do mesmo papel, nao
--   papeis diferentes. 187 clientes e 36 pessoas alterando.
--
-- **ZERO E SENTINELA DE "SEM RESPONSAVEL", NAO UM ID.** `valor_antigo` e `valor_novo`
--   guardam id de colaborador, e **zero significa vazio** -- 572 anteriores e 125 novos.
--   Saem como NULL (`NULLIF(...,0)`), nunca como zero: zero juntaria com o colaborador
--   de id zero, que nao existe, e seria contado como pessoa.
--
-- **O EVENTO TEM TRES FORMAS E ELAS NAO SE SOMAM:** `tipo_evento` separa
--   **ATRIBUICAO** (520 -- ninguem antes, alguem depois) · **TROCA** (1.687 -- pessoa
--   por pessoa) · **REMOCAO** (73 -- alguem antes, ninguem depois) · **SEM_EFEITO**
--   (52 -- nenhum dos dois lados). Contar "trocas de responsavel" sem separar mistura
--   entrada de gente nova com saida, que sao movimentos opostos.
--
-- O BURACO DE CADASTRO APARECE AQUI TAMBEM: **923 de 2.332 (39,6%)** apontam para
--   cliente que nao existe em `trs_vjob__cliente` -- consistente com os 45,4% da
--   auditoria e os 22,2% do escopo. Join LEFT com flag; com INNER, 40% da historia do
--   time sumiria sem sinal.
--   **O autor, ao contrario, resolve 100%:** os 36 `user_id` existem todos em
--   `trs_vjob__usuario`. Quem alterou se sabe sempre; para quem foi alterado, nem sempre.
--
-- **O RESPONSAVEL NAO RESOLVE INTEIRO, e isso e da origem:** 131 dos ids anteriores e
--   42 dos novos nao existem no cadastro de usuario -- pessoas que sairam e cujo
--   cadastro nao esta mais la. Ficam com flag, nunca apagadas.
--
-- ISTO E UM LOG, NAO UM ESTADO. A tabela nao diz quem e o responsavel VIGENTE de um
--   cliente hoje; diz que mudou de X para Y naquele instante. O estado atual esta nas
--   colunas de squad do proprio cadastro de cliente, que esta fora desta tabela.
--
-- FUSO: relogio local da intranet. **NAO CONVERTER.**
--
-- MEDIDO EM 2026-09-24: 2.332 linhas · 2.332 chaves · 187 clientes · 36 autores, zero
--   orfao · 15 papeis · 923 clientes nao catalogados · 520 atribuicoes, 1.687 trocas,
--   73 remocoes, 52 sem efeito.
WITH base AS (
  SELECT id, user_id, cliente_id, coluna, valor_antigo, valor_novo, data_hora
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tb_logs_squad`
),
clientes AS (SELECT DISTINCT id_cliente FROM `vanguardamartech_trusted`.`trs_vjob__cliente`),
usuarios AS (SELECT DISTINCT id_usuario FROM `vanguardamartech_trusted`.`trs_vjob__usuario`),
prep AS (
  SELECT
    b.id                                                        AS id_alteracao,
    b.cliente_id                                                AS id_cliente,
    NULLIF(b.user_id, 0)                                        AS id_alterado_por,
    NULLIF(TRIM(b.coluna), '')                                  AS papel,
    -- ZERO E SENTINELA DE VAZIO, nao id de pessoa.
    NULLIF(SAFE_CAST(NULLIF(TRIM(b.valor_antigo), '') AS INT64), 0) AS id_responsavel_anterior,
    NULLIF(SAFE_CAST(NULLIF(TRIM(b.valor_novo), '')   AS INT64), 0) AS id_responsavel_novo,
    b.data_hora                                                 AS alterado_em,
    c.id_cliente                                                AS cli_ok,
    u.id_usuario                                                AS usr_ok
  FROM base b
  LEFT JOIN clientes c ON c.id_cliente = b.cliente_id
  LEFT JOIN usuarios u ON u.id_usuario = b.user_id
),
tratado AS (
  SELECT
    p.id_alteracao,
    p.id_cliente,
    p.id_alterado_por,
    p.papel,
    p.id_responsavel_anterior,
    p.id_responsavel_novo,

    -- Tres movimentos diferentes que nao se somam. Ver o bloco do cabecalho.
    CASE
      WHEN p.id_responsavel_anterior IS NULL AND p.id_responsavel_novo IS NOT NULL THEN 'ATRIBUICAO'
      WHEN p.id_responsavel_anterior IS NOT NULL AND p.id_responsavel_novo IS NULL THEN 'REMOCAO'
      WHEN p.id_responsavel_anterior IS NOT NULL AND p.id_responsavel_novo IS NOT NULL THEN 'TROCA'
      ELSE 'SEM_EFEITO'
    END                                                         AS tipo_evento,

    -- FUSO: relogio local. Nao converter.
    p.alterado_em,

    (p.cli_ok IS NULL)                                          AS flag_cliente_nao_catalogado,
    (p.id_alterado_por IS NOT NULL AND p.usr_ok IS NULL)        AS flag_autor_nao_catalogado,
    -- ANTI-JOIN, nao `NOT EXISTS` correlacionado: esta base ja registrou que o
    -- correlacionado nao roda no BigQuery quando o lado direito cresce. O `DISTINCT`
    -- nas CTEs e obrigatorio, senao o join multiplica a linha da esquerda.
    (p.id_responsavel_anterior IS NOT NULL AND ua.id_usuario IS NULL)
                                                                AS flag_anterior_nao_catalogado,
    (p.id_responsavel_novo IS NOT NULL AND un.id_usuario IS NULL)
                                                                AS flag_novo_nao_catalogado
  FROM prep p
  LEFT JOIN usuarios ua ON ua.id_usuario = p.id_responsavel_anterior
  LEFT JOIN usuarios un ON un.id_usuario = p.id_responsavel_novo
)
SELECT
  t.*,
  CURRENT_TIMESTAMP()                                           AS _extraido_at,
  'mysql-yIOn'                                                  AS _fonte,
  'America/Sao_Paulo'                                           AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(t)))                                AS _payload_hash
FROM tratado t
