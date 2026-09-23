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
-- REGRA QUE ACUSA O QUE E LEGITIMO ENSINA A IGNORAR A SUITE.
--   Aconteceu duas vezes no primeiro dia e foi corrigido no primeiro dia:
--   (a) a regra de documento da `rfn_operacao__peca` exigia 14 digitos e acusava 2.555
--       linhas -- que sao 18 CLIENTES PESSOA FISICA com CPF de 11 digitos, documento
--       valido que junta com o financeiro igual. Passou a exigir FORMA DE DOCUMENTO.
--   (b) a regra de veiculo do PI acusava 606 PIs "sem CNPJ" -- 507 deles TEM CNPJ, de
--       13 digitos, porque a origem comeu o zero a esquerda. A Trusted passou a
--       repadronizar, a regra da origem virou LINHA DE BASE e a cobertura real ganhou
--       regra propria sobre a Trusted.
--   Falso positivo custa mais caro que regra ausente: ele some junto com os verdadeiros
--   quando alguem para de olhar.
--
-- SEVERIDADE
--   BLOQUEANTE .. chave duplicada ou integridade quebrada. Falhar aqui invalida
--                 qualquer contagem feita sobre a tabela.
--   ALERTA ...... completude e validade abaixo do limiar. O numero ainda serve, mas
--                 a cobertura tem de viajar junto com ele.
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
-- LIMITE DE COBERTURA
--   So entram tabelas MATERIALIZADAS -- referenciar tabela nao materializada **derruba
--   a query inteira**, nao so aquele ramo.
--   **ESTENDIDA EM 2026-09-23**, horas depois da primeira versao de 14 regras: a cadeia
--   do VJOB real materializou as 14:28 e as 13 regras da familia entraram; mais tarde
--   entrou a 28a, sobre a cobertura de veiculo do PI apos tratamento. Faltam as 3 do
--   GitHub e as 4 de custo e margem, que materializam no dia seguinte.
--
-- DIVIDA COM DATA MARCADA
--   A regra `trs_vjob__cliente.cnpj_14_digitos` mede `tem_cnpj AND LENGTH <> 14`.
--   Depois da correcao publicada em 23/09, a Trusted ja segura o fragmento de mascara
--   fora de `cnpj_digitos` -- entao, quando a `mysql-yIOn` rodar de novo, esta regra
--   passa a devolver ZERO falhas e o caso some do painel **sem ter sido resolvido na
--   origem**. Repontar entao para `COUNTIF(flag_cnpj_invalido)` sobre
--   `cnpj_digitos_origem`, que mede a ORIGEM. Nao da para repontar antes: as colunas
--   novas so existem depois daquela execucao.
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
  -- CORRIGIDA EM 2026-09-23. A versao anterior exigia 14 digitos e acusava os 2.555
  -- documentos de CPF como falha -- mas sao 18 CLIENTES PESSOA FISICA, e CPF de 11
  -- digitos e documento valido que junta com o financeiro igual. Somar caso legitimo
  -- com defeito ensina a ignorar a suite. A regra passa a exigir FORMA DE DOCUMENTO:
  -- 14 (CNPJ) ou 11 (CPF). O que sobra e defeito de verdade -- hoje 6 linhas de
  -- string vazia, ja corrigidas na origem no mesmo dia.
  SELECT 'rfn_operacao__peca.documento_tem_forma' AS id_regra, 'Refined' AS camada,
         'rfn_operacao__peca' AS tabela, 'iClips' AS sistema,
         'VALIDADE' AS dimensao,
         'documento preenchido tem 14 digitos (CNPJ) ou 11 (CPF)' AS regra,
         'ALERTA' AS severidade, 0.99 AS limiar,
         COUNTIF(cliente_cnpj IS NOT NULL AND cliente_cnpj <> '') AS linhas_avaliadas,
         COUNTIF(cliente_cnpj IS NOT NULL AND cliente_cnpj <> ''
                 AND LENGTH(REGEXP_REPLACE(cliente_cnpj, r'[^0-9]', '')) NOT IN (11, 14)) AS linhas_falha
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
  -- LIMIAR REBAIXADO PARA 0.78 EM 2026-09-23, e o motivo esta medido. Esta regra le a
  -- ORIGEM, onde 507 dos 606 PIs "sem CNPJ" na verdade tem CNPJ de 13 digitos -- o zero
  -- a esquerda comido no armazenamento. A origem nao vai se corrigir sozinha, entao um
  -- limiar de 0.95 aqui seria reclamacao permanente do que a casa ja sabe. Ela fica
  -- como LINHA DE BASE, para detectar PIORA. A cobertura que importa para analise e a
  -- da regra seguinte, sobre a Trusted, onde o repadronizado ja entrou.
  SELECT 'silver_pi_insercao.veiculo_com_cnpj', 'Raw', 'supabase_silver_pi_insercao', 'PI',
         'INTEGRIDADE', 'PI nao cancelado identifica o veiculo por CNPJ NA ORIGEM', 'ALERTA', 0.78,
         COUNTIF(NOT is_cancelado),
         COUNTIF(NOT is_cancelado
                 AND LENGTH(REGEXP_REPLACE(COALESCE(cnpj_veiculo,''), r'[^0-9]','')) <> 14)
  FROM `vanguardamartech_raw`.`supabase_silver_pi_insercao`
  UNION ALL
  -- A COBERTURA QUE IMPORTA: depois do repadronizado da Trusted, 96,8% dos PIs nao
  -- cancelados identificam o veiculo por CNPJ. Se esta cair para o nivel da origem,
  -- e sinal de que o tratamento nao rodou -- nao de que a origem piorou.
  SELECT 'trs_pi__insercao.veiculo_com_cnpj', 'Trusted', 'trs_pi__insercao', 'PI',
         'INTEGRIDADE', 'PI nao cancelado identifica o veiculo por CNPJ APOS TRATAMENTO',
         'ALERTA', 0.95,
         COUNTIF(NOT is_cancelado),
         -- REGEXP_REPLACE de proposito: a regra tem de funcionar antes e depois da
         -- correcao de 23/09, quando cnpj_veiculo passou de texto com mascara para
         -- digitos. Contar caracteres direto daria 100% de falha no esquema antigo.
         COUNTIF(NOT is_cancelado
                 AND LENGTH(REGEXP_REPLACE(COALESCE(cnpj_veiculo,''), r'[^0-9]','')) <> 14)
  FROM `vanguardamartech_trusted`.`trs_pi__insercao`
),
-- ---------- FAMILIA VJOB REAL (acrescentada em 2026-09-23, quando materializou) ----------
r_vjob AS (
  SELECT 'trs_vjob__cliente.tem_cnpj' AS id_regra, 'Trusted' AS camada,
         'trs_vjob__cliente' AS tabela, 'VJOB' AS sistema,
         'COMPLETUDE' AS dimensao, 'cadastro de cliente tem CNPJ' AS regra,
         'ALERTA' AS severidade, 0.50 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNTIF(NOT tem_cnpj) AS linhas_falha
  FROM `vanguardamartech_trusted`.`trs_vjob__cliente`
  UNION ALL
  SELECT 'trs_vjob__escopo.competencia', 'Trusted', 'trs_vjob__escopo', 'VJOB',
         'COMPLETUDE', 'competencia preenchida', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(competencia IS NULL)
  FROM `vanguardamartech_trusted`.`trs_vjob__escopo`
  UNION ALL
  SELECT 'trs_vjob__cliente.id_cliente', 'Trusted', 'trs_vjob__cliente', 'VJOB',
         'UNICIDADE', 'id_cliente unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_cliente)
  FROM `vanguardamartech_trusted`.`trs_vjob__cliente`
  UNION ALL
  -- id_job sozinho NAO e chave: 147 ids aparecem nas duas tabelas de origem.
  SELECT 'trs_vjob__job.id_job_unico', 'Trusted', 'trs_vjob__job', 'VJOB',
         'UNICIDADE', 'chave composta (origem, id_job) unica', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_job_unico)
  FROM `vanguardamartech_trusted`.`trs_vjob__job`
  UNION ALL
  SELECT 'trs_vjob__cronograma.id_cronograma', 'Trusted', 'trs_vjob__cronograma', 'VJOB',
         'UNICIDADE', 'id_cronograma unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_cronograma)
  FROM `vanguardamartech_trusted`.`trs_vjob__cronograma`
  UNION ALL
  SELECT 'trs_vjob__cronograma_parcela.id_parcela', 'Trusted', 'trs_vjob__cronograma_parcela', 'VJOB',
         'UNICIDADE', 'id_parcela unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_parcela)
  FROM `vanguardamartech_trusted`.`trs_vjob__cronograma_parcela`
  UNION ALL
  SELECT 'rfn_operacao__escopo_mensal.chave', 'Refined', 'rfn_operacao__escopo_mensal', 'VJOB',
         'UNICIDADE', 'id_escopo_mensal unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_escopo_mensal)
  FROM `vanguardamartech_refined`.`rfn_operacao__escopo_mensal`
  UNION ALL
  SELECT 'rfn_cadastro__cliente_sk.grao', 'Refined', 'rfn_cadastro__cliente_sk', 'Cadastro',
         'UNICIDADE', 'um cadastro por sistema: (sistema, id_no_sistema) unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT CONCAT(sistema, ':', id_no_sistema))
  FROM `vanguardamartech_refined`.`rfn_cadastro__cliente_sk`
  UNION ALL
  -- a flag acende, o valor nao e CNPJ: 2 casos em 2026-09-23
  SELECT 'trs_vjob__cliente.cnpj_14_digitos', 'Trusted', 'trs_vjob__cliente', 'VJOB',
         'VALIDADE', 'quando tem_cnpj, o documento tem 14 digitos', 'ALERTA', 0.99,
         COUNTIF(tem_cnpj),
         COUNTIF(tem_cnpj AND LENGTH(REGEXP_REPLACE(COALESCE(cnpj_digitos, ''), r'[^0-9]', '')) <> 14)
  FROM `vanguardamartech_trusted`.`trs_vjob__cliente`
  UNION ALL
  SELECT 'trs_vjob__cronograma_parcela.valor_nao_negativo', 'Trusted',
         'trs_vjob__cronograma_parcela', 'VJOB',
         'VALIDADE', 'valor_parcela >= 0 (a grandeza aditiva da familia)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(valor_parcela < 0)
  FROM `vanguardamartech_trusted`.`trs_vjob__cronograma_parcela`
  UNION ALL
  -- limiar 0.70 porque o buraco e da ORIGEM e ja esta documentado; a regra existe
  -- para detectar PIORA, nao para reclamar do que ja se sabe.
  SELECT 'trs_vjob__escopo.cliente_catalogado', 'Trusted', 'trs_vjob__escopo', 'VJOB',
         'INTEGRIDADE', 'escopo aponta para cliente que existe em tbclientes', 'ALERTA', 0.70,
         COUNT(*), COUNTIF(flag_cliente_nao_catalogado)
  FROM `vanguardamartech_trusted`.`trs_vjob__escopo`
  UNION ALL
  SELECT 'trs_vjob__cronograma.cliente_catalogado', 'Trusted', 'trs_vjob__cronograma', 'VJOB',
         'INTEGRIDADE', 'contrato aponta para cliente que existe em tbclientes', 'ALERTA', 0.70,
         COUNT(*), COUNTIF(flag_cliente_nao_catalogado)
  FROM `vanguardamartech_trusted`.`trs_vjob__cronograma`
),
r_vjob_fk AS (
  SELECT 'trs_vjob__cronograma_parcela.contrato_existe' AS id_regra, 'Trusted' AS camada,
         'trs_vjob__cronograma_parcela' AS tabela, 'VJOB' AS sistema,
         'INTEGRIDADE' AS dimensao, 'parcela aponta para contrato existente' AS regra,
         'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNTIF(c.id_cronograma IS NULL) AS linhas_falha
  FROM `vanguardamartech_trusted`.`trs_vjob__cronograma_parcela` p
  LEFT JOIN (SELECT DISTINCT id_cronograma FROM `vanguardamartech_trusted`.`trs_vjob__cronograma`) c
    ON c.id_cronograma = p.id_cronograma
),
todas AS (
  SELECT * FROM r_completude
  UNION ALL SELECT * FROM r_unicidade
  UNION ALL SELECT * FROM r_validade
  UNION ALL SELECT * FROM r_integridade
  UNION ALL SELECT * FROM r_vjob
  UNION ALL SELECT * FROM r_vjob_fk
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
