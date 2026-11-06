-- rfn_operacao__acesso_mensal
-- PUBLICADA em 2026-09-28 como query-yGBh, camada Refined, folder operacao.
-- Grao: um USUARIO, um MES. 2.109 linhas, 305 usuarios, 85 meses (2019-05 a 2026-09).
-- L4 PERSONAL_DATA -- e comportamento individual de pessoa identificada.
-- Responde: QUEM de fato usa o VJOB, com que frequencia, e desde quando.
-- Origem: trs_vjob__acesso (49.434 acessos) e trs_vjob__usuario (nome).
--
-- O ACHADO: O USO DO VJOB NAO CAIU NO Q4/2024 -- ELE TRIPLICOU.
-- Esta casa mediu em 2026-09-23 que **62 dos 86 clientes sem conclusao pararam no
-- MESMO trimestre**, o quarto de 2024, e registrou que aquilo era "um evento unico
-- que 62 operacoes atravessaram juntas (mudanca de processo, de ferramenta ou de
-- equipe)". A hipotese mais simples -- o sistema foi abandonado -- **esta descartada
-- por medicao**: 486 acessos em 2024-08, 955 em 09, **1.628 em 2024-10**, e a serie
-- nunca mais voltou ao patamar anterior (2.804 em 2026-09). Usuarios ativos no mes
-- vao de 53 para 63-78.
-- **As pessoas continuaram entrando, e em maior numero. O que mudou foi o que elas
-- foram fazer la dentro.** Isso estreita a explicacao daquele evento sem fecha-la.
--
-- REGRAS DE NEGOCIO
-- 1. O GRAO EXIGE USUARIO, entao os **6 acessos sem `id_usuario`** ficam fora. Sao
--    0,01% e a origem grava zero, que a Trusted ja transformou em NULL. Contar acesso
--    total pela soma desta tabela devolve 49.428, nao 49.434 -- declarado, nao perdido.
-- 2. USUARIO NAO CATALOGADO FICA, COM FLAG. 97 dos 305 usuarios (31,8%) e 2.508 dos
--    acessos nao existem em `trs_vjob__usuario`; `usuario_nome` sai NULL e
--    `flag_usuario_nao_catalogado` acende. Orfao e melhor que falso par -- a mesma
--    regra do join da auditoria. **Qualquer leitura POR NOME cobre 68% dos usuarios.**
-- 3. O FUSO FOI RECONFERIDO NESTA TABELA, nao herdado. A distribuicao horaria tem pico
--    as **9h (7.386)**, queda as **12h (1.799)** e retomada as 14h (5.275): chegada,
--    almoco e volta. Em UTC o pico cairia as 6h, que nao e hora de ninguem chegar.
--    Portanto hora local, sem conversao -- como a Trusted ja entrega.
--    (O almoco aqui e as 12h; nas marcacoes de escopo e as 13-14h. Sao gestos
--    diferentes -- entrar no sistema e marcar entrega -- e nao precisam coincidir.)
-- 4. `qtd_dias_ativos` E MAIS HONESTO QUE `qtd_acessos`. Acesso e login, e uma pessoa
--    que perde a sessao loga de novo: 400 pares (usuario, data-hora) repetidos ja
--    estao medidos na Trusted. Dia ativo nao infla com isso.
-- 5. COORTE: `mes_primeiro_acesso` e `meses_desde_o_primeiro_acesso` saem por usuario,
--    e `flag_primeiro_mes` marca a entrada. Servem para separar quem e novo de quem
--    voltou -- duas leituras que um COUNT de usuarios ativos junta sem avisar.
-- 6. `flag_retorno_apos_ausencia` acende quando o mes anterior COM acesso nao e o mes
--    imediatamente anterior. E o unico jeito de ver reativacao; sem ele, o usuario que
--    sumiu por seis meses e voltou conta igual a quem nunca parou.
-- 7. O MES CORRENTE E PARCIAL e sai marcado (`flag_mes_parcial`). Compara-lo com mes
--    fechado subestima sempre.
--
-- LIMITACOES MEDIDAS -- NAO CONTORNE
-- 1. ACESSO NAO E TRABALHO. Esta tabela conta LOGIN, nao entrega. Quem quiser producao
--    usa `rfn_operacao__job` ou `rfn_operacao__escopo_mensal`; quem quiser
--    pontualidade usa `rfn_operacao__conformidade_cliente`.
-- 2. NAO HA SESSAO, NAO HA DURACAO, NAO HA TELA. A origem tem tres colunas -- id,
--    usuario e data-hora. Tempo de permanencia e o que a pessoa fez nao existem nesta
--    base, e nenhuma coluna aqui deve ser lida como tal.
-- 3. NAO HA CLIENTE. O log de acesso nao liga a cliente nenhum. Cruzar uso com
--    carteira exige outra tabela.
-- 4. AS DUAS ORIGENS TEM JANELAS DIFERENTES e a Trusted ja provou que nao duplicam
--    (zero pares em comum). `qtd_acessos_log_vigente` separa `ACESSOS2` de `ACESSOS`
--    para quem precisar recortar por sistema de log.
-- 5. A SERIE COMECA EM 2019-05 e os primeiros anos sao rasos -- o log antigo
--    (`ACESSOS`, 1.351 linhas) cobre pouco. Comparar 2019 com 2026 compara
--    instrumentacao, nao comportamento.
--
-- VALIDACAO (2026-09-28, sobre a tabela materializada): 2.109 linhas, 2.109 chaves
-- distintas, 305 usuarios, 85 meses (2019-05 a 2026-09). A soma de `qtd_acessos`
-- devolve **49.428** -- exatamente os 49.434 da Trusted menos os 6 sem usuario, que e
-- a REGRA 1 fechando. 20.692 dias ativos somados.
-- Invariantes conferidas: **305 linhas com `flag_primeiro_mes`**, uma por usuario,
-- nem uma a mais; **ZERO linhas que sejam primeiro mes E retorno** ao mesmo tempo;
-- **ZERO orfaos com nome e ZERO catalogados sem nome** -- a flag e o NULL do nome
-- dizem a mesma coisa em 2.109 de 2.109; ZERO razoes ausentes; ZERO meses com mais
-- dias ativos que acessos. 293 linhas (13,9%) saem sem nome, e sao exatamente as do
-- usuario nao catalogado. 140 linhas sao retorno apos ausencia.
--
-- Gatilho: evento em query-OwrE (trs_vjob__acesso), dentro da cadeia semanal do VJOB.
WITH a AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_vjob__acesso`
  WHERE id_usuario IS NOT NULL          -- REGRA 1
),
u AS (
  SELECT id_usuario, nome AS usuario_nome, ativo AS usuario_ativo
  FROM `vanguardamartech_trusted`.`trs_vjob__usuario`
),
mensal AS (
  SELECT
    a.id_usuario,
    DATE_TRUNC(a.dt_acesso, MONTH)                    AS mes_referencia,

    COUNT(*)                                          AS qtd_acessos,
    COUNT(DISTINCT a.dt_acesso)                       AS qtd_dias_ativos,   -- REGRA 4
    COUNTIF(a.is_log_vigente)                         AS qtd_acessos_log_vigente,
    COUNTIF(NOT a.is_log_vigente)                     AS qtd_acessos_log_antigo,

    MIN(a.acessado_em)                                AS primeiro_acesso_no_mes,
    MAX(a.acessado_em)                                AS ultimo_acesso_no_mes,

    -- REGRA 3 -- hora local, sem conversao.
    COUNTIF(EXTRACT(DAYOFWEEK FROM a.dt_acesso) IN (1, 7)) AS qtd_acessos_fim_de_semana,
    COUNTIF(EXTRACT(HOUR FROM a.acessado_em) < 8
            OR EXTRACT(HOUR FROM a.acessado_em) >= 19)     AS qtd_acessos_fora_do_expediente,
    MIN(EXTRACT(HOUR FROM a.acessado_em))             AS hora_mais_cedo,
    MAX(EXTRACT(HOUR FROM a.acessado_em))             AS hora_mais_tarde,

    LOGICAL_OR(a.flag_usuario_nao_catalogado)         AS flag_usuario_nao_catalogado
  FROM a
  GROUP BY 1, 2
),
-- REGRAS 5 e 6 -- coorte e retorno saem de janela por usuario.
com_coorte AS (
  SELECT
    m.*,
    MIN(m.mes_referencia) OVER (PARTITION BY m.id_usuario)  AS mes_primeiro_acesso,
    MAX(m.mes_referencia) OVER (PARTITION BY m.id_usuario)  AS mes_ultimo_acesso,
    COUNT(*)              OVER (PARTITION BY m.id_usuario)  AS qtd_meses_com_acesso,
    LAG(m.mes_referencia) OVER (PARTITION BY m.id_usuario
                                ORDER BY m.mes_referencia)  AS mes_anterior_com_acesso
  FROM mensal m
)
SELECT
  CONCAT(CAST(c.id_usuario AS STRING), ':',
         FORMAT_DATE('%Y-%m', c.mes_referencia))            AS id_acesso_mensal,
  c.id_usuario,
  u.usuario_nome,
  u.usuario_ativo,
  c.flag_usuario_nao_catalogado,

  c.mes_referencia,
  -- REGRA 7 -- o mes corrente nunca esta fechado.
  (c.mes_referencia = DATE_TRUNC(CURRENT_DATE(), MONTH))     AS flag_mes_parcial,

  c.qtd_acessos,
  c.qtd_dias_ativos,
  c.qtd_acessos_log_vigente,
  c.qtd_acessos_log_antigo,
  ROUND(SAFE_DIVIDE(c.qtd_acessos, NULLIF(c.qtd_dias_ativos, 0)), 2)
                                                             AS acessos_por_dia_ativo,

  c.primeiro_acesso_no_mes,
  c.ultimo_acesso_no_mes,
  c.qtd_acessos_fim_de_semana,
  c.qtd_acessos_fora_do_expediente,
  c.hora_mais_cedo,
  c.hora_mais_tarde,

  -- REGRA 5 -- coorte
  c.mes_primeiro_acesso,
  c.mes_ultimo_acesso,
  c.qtd_meses_com_acesso,
  DATE_DIFF(c.mes_referencia, c.mes_primeiro_acesso, MONTH)  AS meses_desde_o_primeiro_acesso,
  (c.mes_referencia = c.mes_primeiro_acesso)                 AS flag_primeiro_mes,
  (c.mes_referencia = c.mes_ultimo_acesso)                   AS flag_ultimo_mes_conhecido,

  -- REGRA 6 -- reativacao. O primeiro mes do usuario nao e retorno.
  c.mes_anterior_com_acesso,
  (c.mes_anterior_com_acesso IS NOT NULL
   AND DATE_DIFF(c.mes_referencia, c.mes_anterior_com_acesso, MONTH) > 1)
                                                             AS flag_retorno_apos_ausencia,
  IF(c.mes_anterior_com_acesso IS NULL, NULL,
     DATE_DIFF(c.mes_referencia, c.mes_anterior_com_acesso, MONTH) - 1)
                                                             AS meses_ausente_antes,

  'L4_PERSONAL_DATA'                                         AS classificacao_dado,
  CURRENT_TIMESTAMP()                                        AS _extraido_at
FROM com_coorte c
LEFT JOIN u ON u.id_usuario = c.id_usuario
