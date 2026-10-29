WITH d AS (SELECT * FROM `vanguardamartech_refined`.`rfn_rh__desligamento_resumo`),
td AS (SELECT * FROM `vanguardamartech_trusted`.`trs_rh__desligamento`),
p AS (SELECT * FROM `vanguardamartech_refined`.`rfn_rh__pessoa_engajamento_resumo`),
tp AS (SELECT * FROM `vanguardamartech_trusted`.`trs_rh__pessoa`),
-- Totais da Trusted, uma linha so, para as identidades de grao 1.
tdt AS (
  SELECT COUNT(*) AS n, COUNTIF(is_desligado_com_data) AS n_data, COUNTIF(situacao = 'AVISO_PREVIO') AS n_aviso,
         COUNTIF(situacao = 'ATIVO_INCONSISTENTE') AS n_incons, COUNTIF(custo_tt IS NOT NULL AND custo_tt > 0) AS n_custo,
         COUNTIF(origem = 'DETECCAO') AS n_deteccao, MAX(_extraido_at) AS max_extraido
  FROM td
),
tpt AS (
  SELECT COUNT(*) AS n, SUM(feedbacks_dados) AS fbd, SUM(feedbacks_recebidos) AS fbr, SUM(elogios_dados) AS eld, SUM(elogios_recebidos) AS elr,
         SUM(pdis) AS pdi, SUM(reunioes_1a1) AS r1a1,
         COUNTIF(IFNULL(feedbacks_dados, 0) + IFNULL(feedbacks_recebidos, 0) + IFNULL(elogios_dados, 0) + IFNULL(elogios_recebidos, 0)
                 + IFNULL(pdis, 0) + IFNULL(reunioes_1a1, 0) = 0) AS n_sem_uso,
         MAX(_extraido_at) AS max_extraido
  FROM tp
),
-- Somas por recorte da Refined de desligamento (uma linha por dimensao).
dd AS (
  SELECT dimensao, SUM(qtd_pessoas) AS s, SUM(qtd_com_custo) AS s_custo, SUM(qtd_aviso_previo) AS s_aviso,
         SUM(qtd_situacao_inconsistente) AS s_incons, SUM(qtd_deteccao_sem_relatorio) AS s_deteccao
  FROM d GROUP BY dimensao
),
-- Somas por recorte da Refined de engajamento (uma linha por dimensao).
pp AS (
  SELECT dimensao, SUM(qtd_pessoas) AS s, SUM(soma_feedbacks_dados) AS fbd, SUM(soma_feedbacks_recebidos) AS fbr, SUM(soma_elogios_dados) AS eld,
         SUM(soma_elogios_recebidos) AS elr, SUM(soma_pdis) AS pdi, SUM(soma_reunioes_1a1) AS r1a1, SUM(qtd_sem_nenhum_uso) AS s_sem_uso
  FROM p GROUP BY dimensao
),
-- Pessoas por departamento, somando ATIVO e INATIVO, para a regra de privacidade.
pdep AS (SELECT chave, SUM(qtd_pessoas) AS n FROM p WHERE dimensao = 'DEPARTAMENTO' GROUP BY chave),
r AS (
  -- ===== rfn_rh__desligamento_resumo =====
  SELECT 'rfn_rh__desligamento_resumo.id_unico' AS id_regra, 'Refined' AS camada, 'rfn_rh__desligamento_resumo' AS tabela, 'RH' AS sistema, 'UNICIDADE' AS dimensao,
         'id_resumo e unico e nunca nulo' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_resumo) + COUNTIF(id_resumo IS NULL) AS linhas_falha FROM d
  UNION ALL
  SELECT 'rfn_rh__desligamento_resumo.dimensao_conhecida', 'Refined', 'rfn_rh__desligamento_resumo', 'RH', 'VALIDADE',
         'dimensao e uma das quatro (MES_TIPO, MOTIVO_TIPO, FAIXA_TIPO, SITUACAO_ORIGEM)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(dimensao IS NULL OR dimensao NOT IN ('MES_TIPO', 'MOTIVO_TIPO', 'FAIXA_TIPO', 'SITUACAO_ORIGEM')) FROM d
  UNION ALL
  SELECT 'rfn_rh__desligamento_resumo.chaves_preenchidas', 'Refined', 'rfn_rh__desligamento_resumo', 'RH', 'COMPLETUDE',
         'chave_1 e chave_2 nunca nulas (sentinela da origem vira rotulo, nao NULL)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(chave_1 IS NULL OR chave_2 IS NULL) FROM d
  UNION ALL
  SELECT 'rfn_rh__desligamento_resumo.qtd_positiva', 'Refined', 'rfn_rh__desligamento_resumo', 'RH', 'VALIDADE',
         'toda linha tem ao menos uma pessoa (recorte vazio nao e emitido)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(qtd_pessoas IS NULL OR qtd_pessoas <= 0) FROM d
  UNION ALL
  SELECT 'rfn_rh__desligamento_resumo.admissao_decompoe', 'Refined', 'rfn_rh__desligamento_resumo', 'RH', 'INTEGRIDADE',
         'qtd_com_admissao + qtd_sem_admissao = qtd_pessoas', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(qtd_com_admissao + qtd_sem_admissao <> qtd_pessoas) FROM d
  UNION ALL
  SELECT 'rfn_rh__desligamento_resumo.partes_nao_excedem_o_total', 'Refined', 'rfn_rh__desligamento_resumo', 'RH', 'VALIDADE',
         'tempo de casa, custo, deteccao, aviso previo e situacao inconsistente nunca passam de qtd_pessoas', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(qtd_com_tempo_casa > qtd_pessoas OR qtd_com_custo > qtd_pessoas OR qtd_deteccao_sem_relatorio > qtd_pessoas
                           OR qtd_aviso_previo > qtd_pessoas OR qtd_situacao_inconsistente > qtd_pessoas) FROM d
  UNION ALL
  SELECT 'rfn_rh__desligamento_resumo.flag_celula_pequena_reproduz', 'Refined', 'rfn_rh__desligamento_resumo', 'RH', 'VALIDADE',
         'flag_celula_pequena acende exatamente quando qtd_pessoas < 3 (a linha fica, marcada, nunca apagada)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(flag_celula_pequena <> (qtd_pessoas < 3)) FROM d
  UNION ALL
  SELECT 'rfn_rh__desligamento_resumo.mes_ref_so_no_recorte_mensal', 'Refined', 'rfn_rh__desligamento_resumo', 'RH', 'VALIDADE',
         'mes_ref existe exatamente nas linhas MES_TIPO e chave_1 e o mes dele no formato AAAA-MM', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF((dimensao = 'MES_TIPO') <> (mes_ref IS NOT NULL) OR (dimensao = 'MES_TIPO' AND chave_1 <> FORMAT_DATE('%Y-%m', mes_ref))) FROM d
  UNION ALL
  SELECT 'rfn_rh__desligamento_resumo.classificacao_l3', 'Refined', 'rfn_rh__desligamento_resumo', 'RH', 'VALIDADE',
         'classificacao_dado e L3_CONFIDENTIAL em toda linha (a Trusted e L4; o nivel nao desce sem prova na descricao)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(classificacao_dado IS NULL OR classificacao_dado <> 'L3_CONFIDENTIAL') FROM d
  UNION ALL
  -- Identidades entre camadas. A Refined agrega e nao filtra (alem da REGRA 1 dela).
  SELECT 'rfn_rh__desligamento_resumo.recortes_com_data_reproduzem_a_trusted', 'Refined', 'rfn_rh__desligamento_resumo', 'RH', 'INTEGRIDADE',
         'MES_TIPO, MOTIVO_TIPO e FAIXA_TIPO somam, cada um, as pessoas com data de desligamento da Trusted (grao: recorte)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(dd.s <> (SELECT n_data FROM tdt)) FROM dd WHERE dd.dimensao IN ('MES_TIPO', 'MOTIVO_TIPO', 'FAIXA_TIPO')
  UNION ALL
  SELECT 'rfn_rh__desligamento_resumo.situacao_reproduz_o_total', 'Refined', 'rfn_rh__desligamento_resumo', 'RH', 'INTEGRIDADE',
         'SITUACAO_ORIGEM soma todas as linhas do relatorio da Trusted', 'BLOQUEANTE', 1.00,
         1, IF(IFNULL((SELECT s FROM dd WHERE dimensao = 'SITUACAO_ORIGEM'), -1) = (SELECT n FROM tdt), 0, 1) FROM UNNEST([1])
  UNION ALL
  SELECT 'rfn_rh__desligamento_resumo.situacoes_reproduzem_a_trusted', 'Refined', 'rfn_rh__desligamento_resumo', 'RH', 'INTEGRIDADE',
         'aviso previo, situacao inconsistente e deteccao sem relatorio no recorte SITUACAO_ORIGEM reproduzem as contagens da Trusted', 'BLOQUEANTE', 1.00,
         1, IF((SELECT s_aviso FROM dd WHERE dimensao = 'SITUACAO_ORIGEM') = (SELECT n_aviso FROM tdt)
               AND (SELECT s_incons FROM dd WHERE dimensao = 'SITUACAO_ORIGEM') = (SELECT n_incons FROM tdt)
               AND (SELECT s_deteccao FROM dd WHERE dimensao = 'SITUACAO_ORIGEM') = (SELECT n_deteccao FROM tdt), 0, 1) FROM UNNEST([1])
  UNION ALL
  SELECT 'rfn_rh__desligamento_resumo.custo_reproduz_a_trusted', 'Refined', 'rfn_rh__desligamento_resumo', 'RH', 'INTEGRIDADE',
         'qtd_com_custo no recorte SITUACAO_ORIGEM = pessoas com custo_tt > 0 na Trusted (o valor nao atravessa)', 'BLOQUEANTE', 1.00,
         1, IF(IFNULL((SELECT s_custo FROM dd WHERE dimensao = 'SITUACAO_ORIGEM'), -1) = (SELECT n_custo FROM tdt), 0, 1) FROM UNNEST([1])
  UNION ALL
  SELECT 'rfn_rh__desligamento_resumo.lida_da_trusted_atual', 'Refined', 'rfn_rh__desligamento_resumo', 'RH', 'INTEGRIDADE',
         'a carga da Trusted que a Refined leu e a mais recente (nenhuma passada ficou para tras)', 'BLOQUEANTE', 1.00,
         1, IF((SELECT MAX(_extraido_trusted) FROM d) = (SELECT max_extraido FROM tdt), 0, 1) FROM UNNEST([1])
  UNION ALL
  -- ===== rfn_rh__pessoa_engajamento_resumo =====
  SELECT 'rfn_rh__pessoa_engajamento_resumo.id_unico', 'Refined', 'rfn_rh__pessoa_engajamento_resumo', 'RH', 'UNICIDADE',
         'id_resumo e unico e nunca nulo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_resumo) + COUNTIF(id_resumo IS NULL) FROM p
  UNION ALL
  SELECT 'rfn_rh__pessoa_engajamento_resumo.dimensao_conhecida', 'Refined', 'rfn_rh__pessoa_engajamento_resumo', 'RH', 'VALIDADE',
         'dimensao e uma das tres (DEPARTAMENTO, NIVEL, FAIXA_CASA)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(dimensao IS NULL OR dimensao NOT IN ('DEPARTAMENTO', 'NIVEL', 'FAIXA_CASA')) FROM p
  UNION ALL
  -- Regra de privacidade: nenhuma linha identifica menos de 3 pessoas.
  SELECT 'rfn_rh__pessoa_engajamento_resumo.minimo_de_3_pessoas', 'Refined', 'rfn_rh__pessoa_engajamento_resumo', 'RH', 'VALIDADE',
         'toda linha tem ao menos 3 pessoas (regra de privacidade da tabela: engajamento de 1 ou 2 pessoas e identificavel)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(qtd_pessoas IS NULL OR qtd_pessoas < 3) FROM p
  UNION ALL
  SELECT 'rfn_rh__pessoa_engajamento_resumo.flag_celula_pequena_reproduz', 'Refined', 'rfn_rh__pessoa_engajamento_resumo', 'RH', 'VALIDADE',
         'flag_celula_pequena acende exatamente quando qtd_pessoas < 3', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(flag_celula_pequena <> (qtd_pessoas < 3)) FROM p
  UNION ALL
  -- Departamento com menos de 5 pessoas (ativas + inativas) nunca aparece com o proprio nome.
  SELECT 'rfn_rh__pessoa_engajamento_resumo.departamento_pequeno_nao_aparece', 'Refined', 'rfn_rh__pessoa_engajamento_resumo', 'RH', 'VALIDADE',
         'nenhum departamento com menos de 5 pessoas aparece com nome: ou tem 5 ou mais, ou e o rotulo agrupado (grao: departamento)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(n < 5 AND chave <> '(departamentos com menos de 5 pessoas)') FROM pdep
  UNION ALL
  SELECT 'rfn_rh__pessoa_engajamento_resumo.rotulo_agrupado_so_em_departamento', 'Refined', 'rfn_rh__pessoa_engajamento_resumo', 'RH', 'VALIDADE',
         'o rotulo (departamentos com menos de 5 pessoas) so existe no recorte DEPARTAMENTO', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(chave = '(departamentos com menos de 5 pessoas)' AND dimensao <> 'DEPARTAMENTO') FROM p
  UNION ALL
  SELECT 'rfn_rh__pessoa_engajamento_resumo.partes_nao_excedem_o_total', 'Refined', 'rfn_rh__pessoa_engajamento_resumo', 'RH', 'VALIDADE',
         'gestor, e-mail corporativo, equipe, registro de engajamento, PDI, 1:1 e sem nenhum uso nunca passam de qtd_pessoas', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(qtd_com_gestor > qtd_pessoas OR qtd_email_corporativo > qtd_pessoas OR qtd_em_equipe > qtd_pessoas
                           OR qtd_com_registro_de_engajamento > qtd_pessoas OR qtd_com_pdi > qtd_pessoas OR qtd_com_1a1 > qtd_pessoas
                           OR qtd_sem_nenhum_uso > qtd_pessoas) FROM p
  UNION ALL
  SELECT 'rfn_rh__pessoa_engajamento_resumo.classificacao_l3', 'Refined', 'rfn_rh__pessoa_engajamento_resumo', 'RH', 'VALIDADE',
         'classificacao_dado e L3_CONFIDENTIAL em toda linha (a Trusted e L4)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(classificacao_dado IS NULL OR classificacao_dado <> 'L3_CONFIDENTIAL') FROM p
  UNION ALL
  SELECT 'rfn_rh__pessoa_engajamento_resumo.recortes_somam_as_pessoas', 'Refined', 'rfn_rh__pessoa_engajamento_resumo', 'RH', 'INTEGRIDADE',
         'cada recorte (DEPARTAMENTO, NIVEL, FAIXA_CASA) soma todas as pessoas da Trusted (grao: recorte)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(pp.s <> (SELECT n FROM tpt)) FROM pp
  UNION ALL
  SELECT 'rfn_rh__pessoa_engajamento_resumo.engajamento_reproduz_a_trusted', 'Refined', 'rfn_rh__pessoa_engajamento_resumo', 'RH', 'INTEGRIDADE',
         'feedbacks, elogios, PDIs e 1:1 somados em cada recorte reproduzem a Trusted (grao: recorte)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(IFNULL(pp.fbd, 0) <> IFNULL((SELECT fbd FROM tpt), 0) OR IFNULL(pp.fbr, 0) <> IFNULL((SELECT fbr FROM tpt), 0)
                           OR IFNULL(pp.eld, 0) <> IFNULL((SELECT eld FROM tpt), 0) OR IFNULL(pp.elr, 0) <> IFNULL((SELECT elr FROM tpt), 0)
                           OR IFNULL(pp.pdi, 0) <> IFNULL((SELECT pdi FROM tpt), 0) OR IFNULL(pp.r1a1, 0) <> IFNULL((SELECT r1a1 FROM tpt), 0)) FROM pp
  UNION ALL
  SELECT 'rfn_rh__pessoa_engajamento_resumo.sem_nenhum_uso_reproduz_a_trusted', 'Refined', 'rfn_rh__pessoa_engajamento_resumo', 'RH', 'INTEGRIDADE',
         'quem tem as seis contagens em zero soma, em cada recorte, o mesmo que a Trusted (grao: recorte)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(pp.s_sem_uso <> (SELECT n_sem_uso FROM tpt)) FROM pp
  UNION ALL
  SELECT 'rfn_rh__pessoa_engajamento_resumo.lida_da_trusted_atual', 'Refined', 'rfn_rh__pessoa_engajamento_resumo', 'RH', 'INTEGRIDADE',
         'a carga da Trusted que a Refined leu e a mais recente', 'BLOQUEANTE', 1.00,
         1, IF((SELECT MAX(_extraido_trusted) FROM p) = (SELECT max_extraido FROM tpt), 0, 1) FROM UNNEST([1])
  UNION ALL
  -- Frescor: as duas Refined foram escritas na mesma passada (a mesma fonte, gatilhos em paralelo).
  SELECT 'rh_resumos.carga_do_mesmo_dia', 'Refined', 'rfn_rh__desligamento_resumo+pessoa_engajamento_resumo', 'RH', 'INTEGRIDADE',
         'as duas Refined foram escritas no mesmo dia', 'BLOQUEANTE', 1.00,
         1, IF((SELECT MAX(DATE(_extraido_at)) FROM d) = (SELECT MAX(DATE(_extraido_at)) FROM p), 0, 1) FROM UNNEST([1])
  -- Sem LIMIT: no ultimo ramo de um UNION ALL ele vale para a uniao inteira.
),
avaliado AS (
  SELECT r.*, (r.linhas_avaliadas - r.linhas_falha) AS linhas_conformes,
    SAFE_DIVIDE(r.linhas_avaliadas - r.linhas_falha, NULLIF(r.linhas_avaliadas, 0)) AS taxa_conformidade,
    IF(r.linhas_avaliadas = 0, NULL, SAFE_DIVIDE(r.linhas_avaliadas - r.linhas_falha, r.linhas_avaliadas) >= r.limiar) AS is_conforme,
    (r.linhas_avaliadas = 0) AS flag_sem_linha_para_avaliar
  FROM r
)
SELECT a.*,
  CASE WHEN a.flag_sem_linha_para_avaliar THEN 'SEM_DADO' WHEN a.is_conforme THEN 'CONFORME'
       WHEN a.severidade = 'BLOQUEANTE' THEN 'FALHA_BLOQUEANTE' ELSE 'FALHA_ALERTA' END AS resultado,
  'RH' AS familia, CURRENT_TIMESTAMP() AS _extraido_at, 'supabase-x0tz' AS _fonte, 'America/Sao_Paulo' AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(a))) AS _payload_hash
FROM avaliado a
