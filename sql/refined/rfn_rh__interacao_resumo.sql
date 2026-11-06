-- rfn_rh__interacao_resumo  ·  Refined / rh (Qulture)  ·  L2 INTERNAL
-- Grao: origem do evento de gente (ELOGIO, FEEDBACK, UM_A_UM, PDI, PESQUISA, HUMOR, TAREFA_REUNIAO) x estado x rotulo de humor.
-- Le: trs_qulture__interacao (query-bCo5, L4). Gatilho: evento em query-bCo5. Cadencia diaria (supabase-x0tz).
-- Identidade (19/10/2026, contra a Trusted materializada): 4.754 linhas = 4.754 · 4.754 eventos distintos (o grao da Trusted e
--   evento x destino e nenhum evento tem dois destinos hoje) · 17 linhas, 17 chaves · HUMOR 2.529 (137 com rotulo, 2.392 sem) ·
--   PDI 1.280 · TAREFA_REUNIAO 337 (119 FEITA, 218 ABERTA) · UM_A_UM 326 (DONE 212, PENDING 99, NEXT 12, FUTURE 3) · PESQUISA 125 ·
--   ELOGIO 80 · FEEDBACK 77 · 5.277 versoes do bronze.
-- R1 NADA PESSOAL ATRAVESSA: quem elogiou/avaliou quem (ids e nomes de contrato) fica na Trusted. Aqui pessoas saem so como
--    contagem distinta (qtd_pessoas_origem_distintas / qtd_pessoas_destino_distintas); humor individual vira contagem por rotulo.
-- R2 qtd_concluidas so existe em TAREFA_REUNIAO (unica origem com is_concluida); nas outras sai NULL, nao zero.
-- R3 A unica origem DATAVEL e TAREFA_REUNIAO (data_referencia = dueDate, 312 de 337): por isso esta tabela e _resumo e nao _mensal.
--    Os payloads de elogio, feedback, 1:1, PDI, pesquisa e humor NAO trazem data do evento (ver Trusted).
-- R4 rotulo_humor NULL vira '(sem rótulo)': 2.392 check-ins de humor chegam sem rotulo na origem e nao sao humor neutro.
-- LIMITACAO -- NAO CONTORNE: estado e a foto da ultima leitura (versao_lida_em); nao ha serie temporal. 'FEITA' em tarefa e 'DONE'
--   em 1:1 sao vocabularios da origem, mantidos crus.
WITH i AS (SELECT * FROM `vanguardamartech_trusted`.`trs_qulture__interacao`),
agg AS (
  SELECT
    origem,
    IFNULL(estado, '(sem estado)') AS estado,
    IFNULL(rotulo_humor, '(sem rótulo)') AS rotulo_humor,
    COUNT(*) AS qtd_linhas,
    COUNT(DISTINCT id_evento) AS qtd_eventos_distintos,
    COUNT(DISTINCT id_contrato_origem) AS qtd_pessoas_origem_distintas,
    COUNT(DISTINCT id_contrato_destino) AS qtd_pessoas_destino_distintas,
    COUNTIF(id_contrato_origem IS NULL) AS qtd_sem_pessoa_origem,
    COUNTIF(data_referencia IS NOT NULL) AS qtd_com_data_referencia,
    MIN(data_referencia) AS primeira_data_referencia,
    MAX(data_referencia) AS ultima_data_referencia,
    IF(COUNTIF(is_concluida IS NOT NULL) = 0, NULL, COUNTIF(is_concluida)) AS qtd_concluidas,
    COUNTIF(flag_elogio_sem_destinatario) AS qtd_elogio_sem_destinatario,
    COUNT(DISTINCT id_ciclo) AS qtd_ciclos_distintos,
    COUNTIF(comportamentos IS NOT NULL) AS qtd_com_comportamentos,
    COUNTIF(assuntos IS NOT NULL) AS qtd_com_assuntos,
    SUM(qtd_versoes) AS soma_versoes,
    MAX(versao_lida_em) AS versao_lida_em
  FROM i
  GROUP BY 1, 2, 3
),
final AS (
  SELECT CONCAT(origem, '|', estado, '|', rotulo_humor) AS id_interacao_resumo, a.*, 'L2_INTERNAL' AS classificacao_dado FROM agg a
)
SELECT f.*, CURRENT_TIMESTAMP() AS _extraido_at, 'supabase-x0tz' AS _fonte,
  'America/Sao_Paulo' AS _fuso, TO_HEX(MD5(TO_JSON_STRING(f))) AS _payload_hash
FROM final f
