-- rfn_qualidade__regra
-- Refined / dominio Qualidade. Grao: uma REGRA de qualidade em uma execucao.
-- Chave: id_regra (a execucao se le em _extraido_at).
--
-- PARA QUE SERVE
--   E a camada de Data Quality da secao 13 da arquitetura, que pede completude,
--   unicidade e validade medidas **automaticamente** e diz, com todas as letras, que
--   os percentuais "devem ser gerados automaticamente pelos testes de qualidade e nao
--   devem ser tratados como avaliacoes subjetivas". Ate aqui a casa tinha qualidade
--   escrita na descricao de cada tabela, medida uma vez, na mao, no dia em que a
--   tabela nasceu. Isto roda toda vez que a cadeia anda.
--
-- COMO LER
--   Cada linha e uma regra: o que ela exige, sobre quantas linhas, quantas falharam e
--   a taxa. `is_conforme` compara a taxa com o `limiar` DA PROPRIA REGRA -- nao ha
--   limiar unico, porque 96,7% de CNPJ preenchido e o teto conhecido desta base e
--   99,99% de unicidade de chave seria falha grave.
--
-- SEVERIDADE
--   BLOQUEANTE .. chave duplicada ou integridade quebrada. Falhar aqui invalida
--                 qualquer contagem feita sobre a tabela.
--   ALERTA ...... completude e validade abaixo do limiar. O numero ainda serve, mas
--                 a cobertura tem de viajar junto com ele.
--   OBSERVACAO .. medida que existe para acompanhar tendencia, sem limiar duro.
--
-- O QUE ESTA TABELA NAO E -- E A DIFERENCA COM A SECAO 14 ESTA DECLARADA
--   A arquitetura pede QUARENTENA: o registro invalido e desviado antes da Silver e
--   nao entra na camada tratada. **Esta tabela nao desvia nada.** Ela mede e
--   denuncia; o registro invalido continua entrando, marcado com a flag que a Trusted
--   dele ja emite (`flag_cliente_nao_catalogado`, `cnpj_valido`, `registro_confiavel`,
--   `flag_repo_nao_catalogado`). A razao e deliberada: desviar exigiria reescrever as
--   78 transformacoes existentes e quebraria a linhagem de quem ja consome; e a
--   doutrina desta casa e "marcar, nunca apagar", porque descartar esconde que o caso
--   existe. Quem quiser a quarentena de verdade tem aqui a lista do que iria para ela.
--
-- LIMITE DE COBERTURA, E ELE E GRANDE
--   So entram tabelas MATERIALIZADAS. Tudo o que foi publicado em 2026-09-23 (a cadeia
--   do VJOB real, as tres do GitHub e as quatro de custo e margem) ainda nao rodou --
--   cada uma espera a proxima execucao da sua fonte. Referenciar tabela nao
--   materializada **derruba a query inteira**, nao so aquele ramo. Por isso esta
--   primeira versao cobre iClips, financeiro e PI, e as demais entram quando
--   materializarem.
WITH
-- ---------- COMPLETUDE ----------
r_completude AS (
  SELECT 'rfn_operacao__peca.cliente_cnpj'        AS id_regra,
         'Refined'                                AS camada,
         'rfn_operacao__peca'                     AS tabela,
         'iClips'                                 AS sistema,
         'COMPLETUDE'                             AS dimensao,
         'cliente_cnpj preenchido'                AS regra,
         'ALERTA'                                 AS severidade,
         0.90                                     AS limiar,
         COUNT(*)                                 AS linhas_avaliadas,
         COUNTIF(cliente_cnpj IS NULL OR cliente_cnpj = '') AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_operacao__peca`
  UNION ALL
  SELECT 'rfn_operacao__peca.mes_referencia', 'Refined', 'rfn_operacao__peca', 'iClips',
         'COMPLETUDE', 'mes_referencia preenchido', 'ALERTA', 0.90,
         COUNT(*), COUNTIF(mes_referencia IS NULL)
  FROM `vanguardamartech_refined`.`rfn_operacao__peca`
  UNION ALL
  SELECT 'silver_pi_insercao.tipo_faturamento', 'Raw', 'supabase_silver_pi_insercao', 'PI',
         'COMPLETUDE', 'tipo_faturamento preenchido (Bruto ou Liquido)', 'BLOQUEANTE', 0.99,
         COUNT(*), COUNTIF(NULLIF(TRIM(tipo_faturamento), '') IS NULL)
  FROM `vanguardamartech_raw`.`supabase_silver_pi_insercao`
  UNION ALL
  SELECT 'fato_movimento_financeiro.competencia', 'Raw', 'supabase_public_fato_movimento_financeiro', 'Financeiro',
         'COMPLETUDE', 'competencia preenchida', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(competencia IS NULL)
  FROM `vanguardamartech_raw`.`supabase_public_fato_movimento_financeiro`
),
-- ---------- UNICIDADE ----------
r_unicidade AS (
  SELECT 'rfn_operacao__peca.id_job_peca' AS id_regra, 'Refined' AS camada,
         'rfn_operacao__peca' AS tabela, 'iClips' AS sistema,
         'UNICIDADE' AS dimensao, 'id_job_peca unico' AS regra,
         'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_job_peca) AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_operacao__peca`
  UNION ALL
  SELECT 'trs_iclips__peca.id_job_peca', 'Trusted', 'trs_iclips__peca', 'iClips',
         'UNICIDADE', 'id_job_peca unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_job_peca)
  FROM `vanguardamartech_trusted`.`trs_iclips__peca`
  UNION ALL
  SELECT 'fato_movimento_financeiro.codigo', 'Raw', 'supabase_public_fato_movimento_financeiro', 'Financeiro',
         'UNICIDADE', 'codigo unico (chave natural do movimento)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT codigo)
  FROM `vanguardamartech_raw`.`supabase_public_fato_movimento_financeiro`
  UNION ALL
  SELECT 'silver_iclips_peca.peca_id', 'Raw', 'supabase_silver_iclips_peca', 'iClips',
         'UNICIDADE', 'peca_id unico no catalogo de tipos', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT peca_id)
  FROM `vanguardamartech_raw`.`supabase_silver_iclips_peca`
),
-- ---------- VALIDADE ----------
r_validade AS (
  SELECT 'rfn_operacao__peca.cnpj_14_digitos' AS id_regra, 'Refined' AS camada,
         'rfn_operacao__peca' AS tabela, 'iClips' AS sistema,
         'VALIDADE' AS dimensao, 'cliente_cnpj tem 14 digitos quando preenchido' AS regra,
         'ALERTA' AS severidade, 0.99 AS limiar,
         COUNTIF(cliente_cnpj IS NOT NULL AND cliente_cnpj <> '') AS linhas_avaliadas,
         COUNTIF(cliente_cnpj IS NOT NULL AND cliente_cnpj <> ''
                 AND LENGTH(REGEXP_REPLACE(cliente_cnpj, r'[^0-9]', '')) <> 14) AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_operacao__peca`
  UNION ALL
  -- secao 13: "investimento >= 0"
  SELECT 'silver_iclips_peca.valor_nao_negativo', 'Raw', 'supabase_silver_iclips_peca', 'iClips',
         'VALIDADE', 'valor de tabela da peca >= 0', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(valor < 0)
  FROM `vanguardamartech_raw`.`supabase_silver_iclips_peca`
  UNION ALL
  -- secao 13: "data_campanha <= data_atual"
  SELECT 'fato_movimento_financeiro.competencia_nao_futura', 'Raw',
         'supabase_public_fato_movimento_financeiro', 'Financeiro',
         'VALIDADE', 'movimento REALIZADO nao tem competencia futura', 'ALERTA', 0.99,
         COUNTIF(NOT flag_projecao),
         COUNTIF(NOT flag_projecao AND competencia > CURRENT_DATE('America/Sao_Paulo'))
  FROM `vanguardamartech_raw`.`supabase_public_fato_movimento_financeiro`
  UNION ALL
  -- o sinal e o que permite somar tudo e obter o liquido; se quebrar, quebra a margem
  SELECT 'fato_movimento_financeiro.sinal_coerente', 'Raw',
         'supabase_public_fato_movimento_financeiro', 'Financeiro',
         'VALIDADE', 'saida tem valor <= 0 e entrada tem valor >= 0', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF((TRIM(tipo) IN ('Saída','A Pagar')  AND valor > 0)
              OR (TRIM(tipo) IN ('Entrada','A Receber') AND valor < 0))
  FROM `vanguardamartech_raw`.`supabase_public_fato_movimento_financeiro`
),
-- ---------- INTEGRIDADE ----------
-- secao 13: "campaign_id deve existir", "cliente deve existir"
r_integridade AS (
  SELECT 'trs_iclips__peca.id_peca_existe_no_catalogo' AS id_regra, 'Trusted' AS camada,
         'trs_iclips__peca' AS tabela, 'iClips' AS sistema,
         'INTEGRIDADE' AS dimensao,
         'id_peca existe em supabase_silver_iclips_peca' AS regra,
         'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNTIF(c.peca_id IS NULL) AS linhas_falha
  FROM `vanguardamartech_trusted`.`trs_iclips__peca` p
  LEFT JOIN (SELECT DISTINCT CAST(peca_id AS STRING) peca_id
             FROM `vanguardamartech_raw`.`supabase_silver_iclips_peca`) c
    ON c.peca_id = p.id_peca
  UNION ALL
  SELECT 'silver_pi_insercao.veiculo_com_cnpj', 'Raw', 'supabase_silver_pi_insercao', 'PI',
         'INTEGRIDADE', 'PI nao cancelado identifica o veiculo por CNPJ', 'ALERTA', 0.95,
         COUNTIF(NOT is_cancelado),
         COUNTIF(NOT is_cancelado
                 AND LENGTH(REGEXP_REPLACE(COALESCE(cnpj_veiculo,''), r'[^0-9]','')) <> 14)
  FROM `vanguardamartech_raw`.`supabase_silver_pi_insercao`
),
todas AS (
  SELECT * FROM r_completude
  UNION ALL SELECT * FROM r_unicidade
  UNION ALL SELECT * FROM r_validade
  UNION ALL SELECT * FROM r_integridade
),
avaliado AS (
  SELECT
    t.*,
    (t.linhas_avaliadas - t.linhas_falha)                       AS linhas_conformes,
    SAFE_DIVIDE(t.linhas_avaliadas - t.linhas_falha, NULLIF(t.linhas_avaliadas, 0))
                                                                AS taxa_conformidade,
    -- Regra sem linha para avaliar NAO passa por conformidade: sai NULL, nunca TRUE.
    -- Zero de zero seria 100% e esconderia tabela vazia.
    IF(t.linhas_avaliadas = 0, NULL,
       SAFE_DIVIDE(t.linhas_avaliadas - t.linhas_falha, t.linhas_avaliadas) >= t.limiar)
                                                                AS is_conforme,
    (t.linhas_avaliadas = 0)                                    AS flag_sem_linha_para_avaliar
  FROM todas t
)
SELECT
  a.*,
  CASE
    WHEN a.flag_sem_linha_para_avaliar          THEN 'SEM_DADO'
    WHEN a.is_conforme                          THEN 'CONFORME'
    WHEN a.severidade = 'BLOQUEANTE'            THEN 'FALHA_BLOQUEANTE'
    ELSE                                             'FALHA_ALERTA'
  END                                           AS resultado,
  CURRENT_TIMESTAMP()                           AS _extraido_at,
  'multiplas'                                   AS _fonte,
  'America/Sao_Paulo'                           AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(a)))                AS _payload_hash
FROM avaliado a
