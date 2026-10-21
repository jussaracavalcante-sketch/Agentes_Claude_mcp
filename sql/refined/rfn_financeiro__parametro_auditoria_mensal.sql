-- rfn_financeiro__parametro_auditoria_mensal  ·  Refined / financeiro  ·  L2 INTERNAL (so contagem; autor e evidencia NAO atravessam)
-- Grao: mes do evento (America/Sao_Paulo) x origem x dimensao x ERP x acao. Le: trs_financeiro__parametro_auditoria (query-GiKT). Gatilho: evento em query-GiKT. Cadencia herdada: semanal (segunda 07:10 America/Manaus).
-- VALIDACAO (2026-10-19): 25 linhas, 25 chaves; 142 eventos (138 edicoes + 4 anotacoes), 107 insert e 31 update, 37 nos da arvore, 2026-06 a 2026-09 (= Trusted).
-- REGRA 1 - AGREGA, NAO FILTRA: soma de qtd_eventos = Trusted (142 eventos em 19/10/2026: 138 edicoes do de-para e 4 anotacoes de conta sem API).
-- REGRA 2 - NO DA ARVORE NAO E ERP: `erp` = `_no_` significa no da arvore da DRE; fica contado a parte em `qtd_nos_da_arvore` e nunca somado como ERP.
-- REGRA 3 - `qtd_autores_distintos` e distinta DENTRO da linha e nao e aditiva entre linhas; o autor (e-mail) nunca e emitido. As 4 anotacoes de CONTA_SEM_API nao tem autor (zero, nao ausencia de evento).
-- LIMITACOES - NAO CONTORNE: e trilha de auditoria, nao o de-para vigente (trs_financeiro__dicionario); a janela vai de 2026-06 a 2026-09; nao ha evento de delete na origem.
WITH t AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_financeiro__parametro_auditoria`
),
g AS (
  SELECT
    mes_evento,
    origem,
    dimensao,
    erp,
    acao,
    COUNT(*)                                       AS qtd_eventos,
    COUNTIF(flag_e_no_da_arvore)                   AS qtd_nos_da_arvore,
    COUNT(DISTINCT autor)                          AS qtd_autores_distintos,
    MIN(evento_em_local)                           AS primeiro_evento_local,
    MAX(evento_em_local)                           AS ultimo_evento_local,
    MAX(DATE(_extraido_at, 'America/Sao_Paulo'))   AS data_carga_trusted
  FROM t
  GROUP BY mes_evento, origem, dimensao, erp, acao
),
final AS (
  SELECT
    CONCAT(CAST(mes_evento AS STRING), '|', origem, '|', IFNULL(dimensao, '~'), '|', IFNULL(erp, '~'), '|', IFNULL(acao, '~')) AS id_parametro_auditoria_mensal,
    g.*,
    'L2_INTERNAL' AS classificacao_dado
  FROM g
)
SELECT
  f.*,
  CURRENT_TIMESTAMP()                AS _extraido_at,
  'supabase-x0tz'                    AS _fonte,
  'America/Sao_Paulo'                AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(f)))     AS _payload_hash
FROM final f
