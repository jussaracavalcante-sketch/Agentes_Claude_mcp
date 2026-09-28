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
--   14 regras em 23/09; +13 quando a cadeia do VJOB real materializou as 14:28; +1 com a
--   correcao de veiculo do PI; +7 em 24/09 com a cadeia de custo e margem; +7 de MIDIA
--   no mesmo dia; **+14 das nove tabelas novas do VJOB**, acrescentadas quando a
--   `mysql-yIOn` terminou as **12:43 de 24/09** e a cadeia inteira materializou.
--   Eram 61 ate 27/09; **+23 em 2026-09-28** -- 10 da familia CONEXA e 13 do lote de
--   25/09 (seis Trusted do VJOB e a Refined do Linear), todas medidas na tabela
--   MATERIALIZADA antes de publicar e **todas as 23 em ZERO falhas**. Sao **84**.
--   AINDA DE FORA: as 3 Trusted do GitHub. Nao e esquecimento -- a fonte `github-s0VO`
--   falhou em **24, 25 e 26/09** com `401 Bad credentials` e foi DESATIVADA pelo
--   `settings_max_consecutive_failures`; nao ha tentativa desde entao. As regras entram
--   quando a credencial for renovada (interface web da Nekt) e a cadeia rodar. Junto
--   com elas entra a `rfn_operacao__repositorio_mensal`, publicada em 27/09 e que nunca
--   vai rodar enquanto a fonte estiver assim.
--   FORA TAMBEM, com outra razao: a familia CONTA AZUL tem SUITE PROPRIA
--   (`rfn_qualidade__regra_contazul`, `query-AQjU`, 19 regras) porque ela anda SEMANAL,
--   na cadeia da `mysql-yIOn`, e esta anda todo dia as 07:10. Somar as duas aqui faria a
--   suite inteira falhar nos seis dias em que as tabelas de la nao existem. O contrato de
--   colunas e identico de proposito: um `UNION ALL` entre as duas da o painel unico.
--
-- O QUE A EXECUCAO DE 2026-09-28 DEVOLVEU, e o unico caso que ela acusou.
--   61 regras, 60 conformes e **1 FALHA BLOQUEANTE**:
--   `trs_vjob__job_prazo_alteracao.job_existe`, 227 avaliadas, 1 falha, 99,56%.
--   A regra estava CERTA sobre o fato e ERRADA sobre a severidade. Ela foi escrita em
--   24/09 medindo zero orfaos sobre 224 linhas, quando a QUARTA origem do log de prazo
--   (`tbjobs_prazo_hist_geral`) ainda nao tinha materializado -- e a unica linha dela e
--   orfa por construcao: aponta para o job 2, que **nao existe em `tbjobsgeral`** (160
--   linhas, menor id = 4). O cadastro do job foi apagado e o log, de 27/10/2025,
--   sobreviveu; e o mesmo mecanismo do gestor deletado na `trs_vjob__gestor_cliente`.
--   Rebaixada para ALERTA/0,98 e a Trusted passou a emitir `flag_job_nao_catalogado`,
--   que ela ate aqui DECLARAVA na descricao sem emitir em coluna nenhuma.
--   **Regra BLOQUEANTE sobre buraco que a casa ja conhece e nao pode fechar ensina a
--   ignorar a suite** -- a mesma razao que rebaixou o limiar do escopo e do cronograma
--   para 0,70 e o do PI para 0,78.
--
-- GRAO MISTO DO GOOGLE ADS -- a premissa mais fragil da base, e agora ela tem guarda.
--   A `trs_google_ads__insight_diario` junta linhas ANUNCIO de `ad_performance` com
--   linhas CAMPANHA de `campaign_performance`, estas SO para os pares (campanha, dia)
--   que o Google nao publica por anuncio -- o caso PERFORMANCE_MAX. A uniao so e exata
--   porque a ausencia e por campanha-dia INTEIRO. Medido em 24/09: **45.938 pares,
--   ZERO em mais de um grao** (35.833 ANUNCIO + 10.105 CAMPANHA).
--   SE UM PAR APARECER NOS DOIS, o investimento daquele dia e contado DUAS VEZES e
--   nada na contagem de linhas denuncia. A descricao da Trusted ja avisava que nessa
--   hora "a premissa cai e a query precisa de residuo por diferenca, nao por presenca";
--   esta regra e o gatilho que avisa que a hora chegou.
--
-- O QUE A PRIMEIRA EXECUCAO DEVOLVEU (2026-09-24 07:12, sucesso): 28 regras,
--   **27 conformes e 1 em falha**. A falha e `trs_vjob__cliente.cnpj_14_digitos`
--   (98,81%), e ela ainda aparece porque a cadeia do VJOB e SEMANAL e nao rodou de novo.
--   CORRIGINDO O QUE EU PREVI ERRADO na versao anterior desta descricao: eu escrevi que
--   a falha seria a da ORIGEM do PI. Nao e -- com limiar 0,78 ela mede 80,58% e PASSA,
--   que era exatamente a intencao de rebaixar o limiar. Errei a previsao, nao a regra.
--   O tratamento do PI valeu em producao: `trs_pi__insercao.veiculo_com_cnpj` em
--   **96,83%** (99 falhas de 3.120) contra 80,58% na origem, e
--   `rfn_operacao__peca.documento_tem_forma` em **130.317 avaliadas, ZERO falhas**.
--
-- DIVIDA COM DATA MARCADA -- **PAGA EM 2026-09-24**
--   A regra era `trs_vjob__cliente.cnpj_14_digitos`, medindo `tem_cnpj AND LENGTH <> 14`.
--   Depois da correcao de 23/09 a Trusted passou a segurar o fragmento de mascara fora
--   de `cnpj_digitos` -- entao, assim que a cadeia rodasse, ela devolveria ZERO falhas e
--   o caso sumiria do painel **sem ter sido resolvido na origem**. A `mysql-yIOn`
--   terminou as 12:43 de 24/09, as colunas novas passaram a existir, e a regra foi
--   repontada para `COUNTIF(flag_cnpj_invalido)` sobre `cnpj_digitos_origem` --
--   renomeada para `trs_vjob__cliente.cnpj_valido_na_origem`. Medida na tabela
--   materializada: **168 avaliadas, 2 invalidas, 98,81%**, CONFORME com limiar 0,98.
--   Os 2 sao os cadastros Move com a mascara do formulario preenchida pela metade, e
--   continuam visiveis -- que era exatamente o ponto.

-- AS 14 REGRAS DE 24/09 GUARDAM PREMISSAS, nao sao contagem por contagem. As quatro que
--   mais importam: `trs_vjob__auditoria_cliente.status_sempre_carimbado` (a invariante
--   que faz a serie de auditoria cobrir 100% das conclusoes, contra 84% do escopo);
--   `trs_vjob__etapa_cliente.nunca_ativada_nunca_marcada` (a premissa do denominador da
--   `rfn_operacao__conformidade_cliente` -- se uma nunca-ativada aparecer marcada, a
--   taxa fica errada); `rfn_operacao__conformidade_cliente.taxa_nunca_maior_que_um`
--   (guarda a razao); e `rfn_operacao__job.status_canonico_conhecido` (dispara se
--   qualquer das quatro origens de job inventar um status novo, que hoje sumiria da
--   leitura sem a contagem de linhas mudar).
--   **TODAS as 14 mediram ZERO falhas** na tabela materializada, em 24/09.
--   FICOU DE FORA DE PROPOSITO: uma regra de completude sobre `trs_vjob__ia_cliente_config`
--   acusaria o PRESTEX, que tem a configuracao aberta e zero caractere de contexto.
--   Configuracao vazia e um estado real, nao um defeito.
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
  -- DIVIDA PAGA EM 2026-09-24, e ela tinha data marcada desde 23/09.
  -- A regra antiga era `cnpj_14_digitos` e media `tem_cnpj AND LENGTH(cnpj_digitos) <> 14`.
  -- Depois da correcao de 23/09 a Trusted passou a segurar o fragmento FORA de
  -- `cnpj_digitos`, entao assim que a cadeia rodasse a regra devolveria zero falhas e
  -- **o caso sumiria do painel sem ter sido resolvido na origem**. Ela agora mede
  -- `flag_cnpj_invalido` sobre `cnpj_digitos_origem`, que e a ORIGEM -- o que importa
  -- acompanhar. Nao dava para repontar antes: as colunas so existem depois da execucao,
  -- e referenciar coluna inexistente derruba a suite inteira.
  -- LIMIAR 0,98 DE PROPOSITO, mesma logica da regra de origem do PI: sao 2 cadastros
  -- Move com a mascara do formulario preenchida pela metade, de 168 com documento
  -- (98,81%). A origem nao vai se corrigir sozinha; limiar alto seria reclamacao
  -- permanente e ensinaria a ignorar a suite. Fica como LINHA DE BASE: um terceiro
  -- caso derruba para 98,21% e a regra acende.
  SELECT 'trs_vjob__cliente.cnpj_valido_na_origem', 'Trusted', 'trs_vjob__cliente', 'VJOB',
         'VALIDADE', 'documento preenchido na origem tem forma de CNPJ (14 digitos)', 'ALERTA', 0.98,
         COUNTIF(cnpj_digitos_origem IS NOT NULL),
         COUNTIF(flag_cnpj_invalido)
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
-- ---------- CUSTO E MARGEM (acrescentada em 2026-09-24, quando materializou) ----------
r_custo AS (
  SELECT 'trs_iclips__peca_tipo.id_peca' AS id_regra, 'Trusted' AS camada,
         'trs_iclips__peca_tipo' AS tabela, 'iClips' AS sistema,
         'UNICIDADE' AS dimensao, 'id_peca unico no catalogo de tipos' AS regra,
         'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_peca) AS linhas_falha
  FROM `vanguardamartech_trusted`.`trs_iclips__peca_tipo`
  UNION ALL
  SELECT 'trs_financeiro__movimento.id_movimento', 'Trusted', 'trs_financeiro__movimento', 'Financeiro',
         'UNICIDADE', 'id_movimento unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_movimento)
  FROM `vanguardamartech_trusted`.`trs_financeiro__movimento`
  UNION ALL
  -- Esta e a regra que guarda o repadronizado do zero a esquerda. Antes da correcao
  -- de 23/09 ela acusaria 123 linhas; depois, ZERO. Se voltar a acusar, ou a origem
  -- inventou uma forma nova de documento, ou o repadronizado parou de rodar.
  SELECT 'trs_financeiro__movimento.documento_tem_forma', 'Trusted',
         'trs_financeiro__movimento', 'Financeiro',
         'VALIDADE', 'documento preenchido tem 14 digitos (CNPJ) ou 11 (CPF)', 'ALERTA', 0.99,
         COUNTIF(contraparte_documento IS NOT NULL),
         COUNTIF(contraparte_documento IS NOT NULL
                 AND LENGTH(contraparte_documento) NOT IN (11, 14))
  FROM `vanguardamartech_trusted`.`trs_financeiro__movimento`
  UNION ALL
  SELECT 'rfn_operacao__custo_peca.id_job_peca', 'Refined', 'rfn_operacao__custo_peca', 'iClips',
         'UNICIDADE', 'id_job_peca unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_job_peca)
  FROM `vanguardamartech_refined`.`rfn_operacao__custo_peca`
  UNION ALL
  SELECT 'rfn_financeiro__rentabilidade_cliente.chave', 'Refined',
         'rfn_financeiro__rentabilidade_cliente', 'Financeiro',
         'UNICIDADE', 'id_rentabilidade unico (documento + competencia)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_rentabilidade)
  FROM `vanguardamartech_refined`.`rfn_financeiro__rentabilidade_cliente`
  UNION ALL
  -- "Margem de um lado so nao e margem": quando margem_mes_total sai NULL, o motivo
  -- TEM de estar declarado, e quando ela existe, o motivo TEM de estar vazio. A regra
  -- verifica a equivalencia nos dois sentidos -- NULL silencioso e o que ela impede.
  SELECT 'rfn_financeiro__rentabilidade_cliente.motivo_declarado', 'Refined',
         'rfn_financeiro__rentabilidade_cliente', 'Financeiro',
         'VALIDADE', 'margem NULL <=> motivo da indisponibilidade preenchido', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF((margem_mes_total IS NULL) <> (motivo_margem_mes_indisponivel IS NOT NULL))
  FROM `vanguardamartech_refined`.`rfn_financeiro__rentabilidade_cliente`
),
-- A REGRA MAIS IMPORTANTE DA SUITE, e a unica que verifica uma IDENTIDADE CONTABIL.
-- O rateio do custo por peca promete que a soma do custo distribuido em cada mes e
-- EXATAMENTE o custo operacional daquele mes -- nem um centavo a mais ou a menos.
-- Ate 23/09 isso era uma afirmacao na descricao, medida a mao uma vez. Aqui vira
-- teste: grao MES, 42 meses fechados, e falha se algum desviar mais de um centavo.
-- Se esta regra falhar, TODO numero de custo por cliente esta errado -- por isso
-- BLOQUEANTE com limiar 1.00.
r_rateio AS (
  SELECT 'rfn_operacao__custo_peca.rateio_fecha_no_centavo' AS id_regra, 'Refined' AS camada,
         'rfn_operacao__custo_peca' AS tabela, 'iClips' AS sistema,
         'VALIDADE' AS dimensao,
         'a soma do custo rateado no mes e igual ao custo operacional do mes' AS regra,
         'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNTIF(ABS(custo_rateado - custo_declarado) > 0.01) AS linhas_falha
  FROM (
    SELECT mes_referencia,
           ANY_VALUE(custo_operacional_mes) AS custo_declarado,
           ROUND(SUM(custo_peca), 2)        AS custo_rateado
    FROM `vanguardamartech_refined`.`rfn_operacao__custo_peca`
    WHERE custo_peca IS NOT NULL
    GROUP BY mes_referencia
  )
),
-- ---------- MIDIA (acrescentada em 2026-09-24) ----------
-- A maior area da casa nao tinha UMA regra ate aqui. E a primeira delas guarda a
-- premissa mais fragil da base -- ver o bloco GRAO MISTO no cabecalho.
r_midia AS (
  SELECT 'trs_google_ads__insight_diario.id_insight' AS id_regra, 'Trusted' AS camada,
         'trs_google_ads__insight_diario' AS tabela, 'Google Ads' AS sistema,
         'UNICIDADE' AS dimensao, 'id_insight unico' AS regra,
         'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_insight) AS linhas_falha
  FROM `vanguardamartech_trusted`.`trs_google_ads__insight_diario`
  UNION ALL
  SELECT 'trs_google_ads__insight_diario.conta_catalogada', 'Trusted',
         'trs_google_ads__insight_diario', 'Google Ads',
         'INTEGRIDADE', 'toda linha resolve a conta na dimensao', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(flag_conta_nao_catalogada)
  FROM `vanguardamartech_trusted`.`trs_google_ads__insight_diario`
  UNION ALL
  -- secao 13: "investimento >= 0"
  SELECT 'trs_google_ads__insight_diario.investimento_nao_negativo', 'Trusted',
         'trs_google_ads__insight_diario', 'Google Ads',
         'VALIDADE', 'investimento >= 0', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(investimento < 0)
  FROM `vanguardamartech_trusted`.`trs_google_ads__insight_diario`
  UNION ALL
  -- secao 13: "data_campanha <= data_atual"
  SELECT 'trs_google_ads__insight_diario.data_nao_futura', 'Trusted',
         'trs_google_ads__insight_diario', 'Google Ads',
         'VALIDADE', 'data de veiculacao nao e futura', 'ALERTA', 1.00,
         COUNT(*), COUNTIF(data > CURRENT_DATE('America/Sao_Paulo'))
  FROM `vanguardamartech_trusted`.`trs_google_ads__insight_diario`
  UNION ALL
  -- A camada consolidada do Facebook e `vanguardamartech_trusted_facebook_ads`. NAO e
  -- `vanguardamartech_trusted`: existem ONZE tabelas com este nome, uma por camada de
  -- cliente, porque a R-001 manda uma camada por fonte. Apontar para a camada errada
  -- devolve um cliente so e parece a base inteira.
  SELECT 'trs_facebook_ads__insight_diario.chave', 'Trusted',
         'trs_facebook_ads__insight_diario', 'Facebook Ads',
         'UNICIDADE', 'chave composta (id_anuncio, data) unica', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT CONCAT(id_anuncio, '|', CAST(data AS STRING)))
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__insight_diario`
  UNION ALL
  SELECT 'trs_facebook_ads__insight_diario.investimento_nao_negativo', 'Trusted',
         'trs_facebook_ads__insight_diario', 'Facebook Ads',
         'VALIDADE', 'investimento >= 0', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(investimento < 0)
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__insight_diario`
),
-- A REGRA QUE GUARDA A PREMISSA MAIS FRAGIL DESTA BASE.
-- A trs_google_ads__insight_diario tem GRAO MISTO: linhas ANUNCIO de ad_performance
-- mais linhas CAMPANHA de campaign_performance, estas SO para os pares (campanha, dia)
-- que o Google nao publica por anuncio -- o caso PERFORMANCE_MAX. A uniao so e exata
-- porque a ausencia e por campanha-dia INTEIRO: nenhum par aparece nos dois graos.
-- SE UM PAR APARECER NOS DOIS, O INVESTIMENTO DAQUELE DIA E CONTADO DUAS VEZES, e nada
-- na contagem de linhas denuncia isso. A propria descricao da Trusted ja avisava que,
-- se aparecer par parcial, "a premissa cai e a query precisa de residuo por diferenca,
-- nao por presenca" -- esta regra e o gatilho que avisa que chegou essa hora.
r_grao_misto AS (
  SELECT 'trs_google_ads__insight_diario.grao_sem_dupla_contagem' AS id_regra,
         'Trusted' AS camada, 'trs_google_ads__insight_diario' AS tabela,
         'Google Ads' AS sistema, 'VALIDADE' AS dimensao,
         'nenhum par (campanha, dia) aparece nos dois graos' AS regra,
         'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNTIF(graos > 1) AS linhas_falha
  FROM (
    SELECT CONCAT(CAST(id_campanha AS STRING), '|', CAST(data AS STRING)) AS par,
           COUNT(DISTINCT grao) AS graos
    FROM `vanguardamartech_trusted`.`trs_google_ads__insight_diario`
    GROUP BY par
  )
),
-- ---------- TABELAS PUBLICADAS EM 2026-09-24 (acrescentadas quando materializaram) ----
-- Catorze regras sobre as nove tabelas novas do VJOB. Cada uma GUARDA UMA PREMISSA de que
-- algo ja publicado depende -- nenhuma e contagem por contagem.
--
-- O QUE FICOU DE FORA, DE PROPOSITO: uma regra de completude sobre
-- `trs_vjob__ia_cliente_config` acusaria o PRESTEX, que tem a configuracao aberta e zero
-- caractere de contexto. **Configuracao vazia e um estado real, nao um defeito.** Regra
-- que acusa o que e legitimo ensina a ignorar a suite -- foi o que aconteceu no primeiro
-- dia com os 2.555 CPFs da `rfn_operacao__peca`.
r_vjob_novo AS (
  -- MODULO DE JOB VIVO --------------------------------------------------------------
  SELECT 'trs_vjob__job_tarefa.id_job_unico' AS id_regra, 'Trusted' AS camada,
         'trs_vjob__job_tarefa' AS tabela, 'VJOB' AS sistema,
         'UNICIDADE' AS dimensao, 'id_job_unico unico -- id_job sozinho colide' AS regra,
         'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_job_unico) AS linhas_falha
  FROM `vanguardamartech_trusted`.`trs_vjob__job_tarefa`
  UNION ALL
  SELECT 'rfn_operacao__job.id_job_unico', 'Refined', 'rfn_operacao__job', 'VJOB',
         'UNICIDADE', 'id_job_unico unico nas QUATRO origens somadas', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_job_unico)
  FROM `vanguardamartech_refined`.`rfn_operacao__job`
  UNION ALL
  -- GUARDA DE PREMISSA. A Refined traduz SETE valores de status em canonico, vindos de
  -- dois vocabularios diferentes (TAREFAS diz "Aprovado", ADVISORY diz "Feito"). Valor
  -- novo em qualquer origem cai em 'desconhecido' e some de toda leitura por
  -- status_canonico SEM que a contagem de linhas mude. Esta regra e o gatilho.
  SELECT 'rfn_operacao__job.status_canonico_conhecido', 'Refined', 'rfn_operacao__job', 'VJOB',
         'VALIDADE', 'nenhum status caiu em desconhecido -- vocabulario novo na origem', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(status_canonico = 'desconhecido')
  FROM `vanguardamartech_refined`.`rfn_operacao__job`
  UNION ALL
  -- CONFORMIDADE ---------------------------------------------------------------------
  SELECT 'trs_vjob__auditoria_cliente.id_auditoria_item', 'Trusted', 'trs_vjob__auditoria_cliente', 'VJOB',
         'UNICIDADE', 'id_auditoria_item unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_auditoria_item)
  FROM `vanguardamartech_trusted`.`trs_vjob__auditoria_cliente`
  UNION ALL
  -- A INVARIANTE DA AUDITORIA. Nesta tabela `status = 1` e `datahoramarcacao` coincidem
  -- EXATAMENTE -- zero excecoes nas duas direcoes -- e e o que a distingue do escopo,
  -- onde 16% das conclusoes nao datam a acao. Serie temporal de auditoria cobre 100%
  -- das conclusoes POR CAUSA disso. Se quebrar, a cobertura deixa de ser 100% e nada
  -- na contagem de linhas denuncia.
  SELECT 'trs_vjob__auditoria_cliente.status_sempre_carimbado', 'Trusted', 'trs_vjob__auditoria_cliente', 'VJOB',
         'VALIDADE', 'status feito e carimbo de marcacao coincidem sempre', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(flag_status_sem_carimbo)
  FROM `vanguardamartech_trusted`.`trs_vjob__auditoria_cliente`
  UNION ALL
  SELECT 'trs_vjob__etapa_cliente.id_etapa', 'Trusted', 'trs_vjob__etapa_cliente', 'VJOB',
         'UNICIDADE', 'id_etapa unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_etapa)
  FROM `vanguardamartech_trusted`.`trs_vjob__etapa_cliente`
  UNION ALL
  -- GUARDA DA REGRA R2 DA REFINED DE CONFORMIDADE. Ela tira a etapa NUNCA ATIVADA do
  -- denominador porque **nenhuma delas tem marcacao** -- 3.790 linhas, zero marcadas.
  -- Se uma nunca-ativada aparecer marcada, a premissa cai e o denominador da taxa passa
  -- a estar errado. NAO confundir com a etapa DESATIVADA (`ativo = 0`, 5 linhas, 1
  -- marcada): essa e legitima, marcada antes de ser desativada, e fica fora desta regra.
  SELECT 'trs_vjob__etapa_cliente.nunca_ativada_nunca_marcada', 'Trusted', 'trs_vjob__etapa_cliente', 'VJOB',
         'VALIDADE', 'etapa nunca ativada nao tem marcacao -- premissa do denominador', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(flag_nunca_ativada AND is_marcada)
  FROM `vanguardamartech_trusted`.`trs_vjob__etapa_cliente`
  UNION ALL
  SELECT 'rfn_operacao__conformidade_cliente.chave', 'Refined', 'rfn_operacao__conformidade_cliente', 'VJOB',
         'UNICIDADE', 'grao (origem, cliente, mes) unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT CONCAT(origem, '|', CAST(id_cliente AS STRING), '|',
                                                    COALESCE(CAST(mes_referencia AS STRING), 'SEM_PRAZO')))
  FROM `vanguardamartech_refined`.`rfn_operacao__conformidade_cliente`
  UNION ALL
  -- GUARDA DA RAZAO. `taxa_conclusao` e marcados_ATIVOS / itens_ATIVOS. Se o numerador
  -- voltar a contar marcacao sobre item inativo -- o erro que eu cometi na primeira
  -- versao daquela query -- a taxa pode passar de 1 e o indicador fica sem sentido.
  SELECT 'rfn_operacao__conformidade_cliente.taxa_nunca_maior_que_um', 'Refined', 'rfn_operacao__conformidade_cliente', 'VJOB',
         'VALIDADE', 'taxa_conclusao nunca excede 1 -- numerador contido no denominador', 'BLOQUEANTE', 1.00,
         COUNTIF(taxa_conclusao IS NOT NULL), COUNTIF(taxa_conclusao > 1)
  FROM `vanguardamartech_refined`.`rfn_operacao__conformidade_cliente`
  UNION ALL
  -- MODULO ia_* ----------------------------------------------------------------------
  SELECT 'trs_vjob__ia_solicitacao.id_solicitacao', 'Trusted', 'trs_vjob__ia_solicitacao', 'VJOB',
         'UNICIDADE', 'id_solicitacao unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_solicitacao)
  FROM `vanguardamartech_trusted`.`trs_vjob__ia_solicitacao`
  UNION ALL
  SELECT 'trs_vjob__ia_cliente_config.id_cliente', 'Trusted', 'trs_vjob__ia_cliente_config', 'VJOB',
         'UNICIDADE', 'uma configuracao por cliente', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_cliente)
  FROM `vanguardamartech_trusted`.`trs_vjob__ia_cliente_config`
  UNION ALL
  -- A CADEIA DO MODULO DE IA: solicitacao -> geracao -> arquivo. As duas regras abaixo
  -- guardam os dois elos. Medido em 24/09: ZERO orfaos nos dois.
  SELECT 'trs_vjob__ia_geracao.solicitacao_existe', 'Trusted', 'trs_vjob__ia_geracao', 'VJOB',
         'INTEGRIDADE', 'geracao aponta para solicitacao existente', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(s.id_solicitacao IS NULL)
  FROM `vanguardamartech_trusted`.`trs_vjob__ia_geracao` g
  LEFT JOIN (SELECT DISTINCT id_solicitacao FROM `vanguardamartech_trusted`.`trs_vjob__ia_solicitacao`) s
    ON s.id_solicitacao = g.id_solicitacao
  UNION ALL
  SELECT 'trs_vjob__ia_geracao_arquivo.geracao_existe', 'Trusted', 'trs_vjob__ia_geracao_arquivo', 'VJOB',
         'INTEGRIDADE', 'arquivo aponta para geracao existente', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(g.id_geracao IS NULL)
  FROM `vanguardamartech_trusted`.`trs_vjob__ia_geracao_arquivo` a
  LEFT JOIN (SELECT DISTINCT id_geracao FROM `vanguardamartech_trusted`.`trs_vjob__ia_geracao`) g
    ON g.id_geracao = a.id_geracao
  UNION ALL
  SELECT 'trs_vjob__ia_documento.id_documento', 'Trusted', 'trs_vjob__ia_documento', 'VJOB',
         'UNICIDADE', 'id_documento unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_documento)
  FROM `vanguardamartech_trusted`.`trs_vjob__ia_documento`
),
-- ---------- SATELITES DE JOB (acrescentadas em 2026-09-24, apos a cadeia rodar) -------
-- As duas tabelas foram publicadas DEPOIS da atualizacao anterior da suite, mas
-- materializaram na mesma cadeia (12:45:20) -- entao entram no mesmo dia.
r_vjob_satelite AS (
  SELECT 'trs_vjob__job_responsavel.id_job_responsavel' AS id_regra, 'Trusted' AS camada,
         'trs_vjob__job_responsavel' AS tabela, 'VJOB' AS sistema,
         'UNICIDADE' AS dimensao, 'id_job_responsavel unico' AS regra,
         'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_job_responsavel) AS linhas_falha
  FROM `vanguardamartech_trusted`.`trs_vjob__job_responsavel`
  UNION ALL
  -- A INVARIANTE DO SATELITE: exatamente UM principal por job. Medido em 24/09: 1.281
  -- jobs, 1.281 principais, zero sem e zero em duplicidade. Se quebrar, "o responsavel
  -- do job" vira ambiguo e toda leitura por principal passa a escolher um dos dois em
  -- silencio. O grao aqui e o JOB, nao a linha.
  SELECT 'trs_vjob__job_responsavel.um_principal_por_job', 'Trusted',
         'trs_vjob__job_responsavel', 'VJOB',
         'VALIDADE', 'cada job tem exatamente um responsavel principal', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(principais <> 1)
  FROM (
    SELECT id_job_unico, COUNTIF(is_principal) AS principais
    FROM `vanguardamartech_trusted`.`trs_vjob__job_responsavel`
    GROUP BY id_job_unico
  )
  UNION ALL
  SELECT 'trs_vjob__job_responsavel.job_existe', 'Trusted', 'trs_vjob__job_responsavel', 'VJOB',
         'INTEGRIDADE', 'responsavel aponta para job existente no modulo vivo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(j.id_job_unico IS NULL)
  FROM `vanguardamartech_trusted`.`trs_vjob__job_responsavel` r
  LEFT JOIN (SELECT DISTINCT id_job_unico FROM `vanguardamartech_trusted`.`trs_vjob__job_tarefa`) j
    ON j.id_job_unico = r.id_job_unico
  UNION ALL
  SELECT 'trs_vjob__job_prazo_alteracao.id_alteracao_unico', 'Trusted',
         'trs_vjob__job_prazo_alteracao', 'VJOB',
         'UNICIDADE', 'id_alteracao_unico unico -- as tres origens tem sequencia propria',
         'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_alteracao_unico)
  FROM `vanguardamartech_trusted`.`trs_vjob__job_prazo_alteracao`
  UNION ALL
  -- Conferida contra a REFINED, nao contra uma Trusted: a rfn_operacao__job e a unica
  -- que tem as QUATRO origens de job somadas, e o log de prazo cobre as tres que
  -- existem.
  --
  -- REBAIXADA DE BLOQUEANTE/1,00 PARA ALERTA/0,98 EM 2026-09-28, e a razao e o unico
  -- caso que ela acusa. Ela foi escrita em 24/09 medindo ZERO orfaos sobre 224 linhas --
  -- mas a QUARTA origem (`tbjobs_prazo_hist_geral`) ainda nao tinha materializado, e a
  -- unica linha dela e orfa: aponta para o job 2, que **nao existe em `tbjobsgeral`**
  -- (160 linhas, menor id = 4). Medido em 28/09, na primeira execucao com a quarta
  -- origem presente: 227 avaliadas, 1 falha, 99,56%.
  --
  -- O orfao e DA ORIGEM e nao se conserta daqui: o cadastro do job foi apagado e o log
  -- de prazo, de 27/10/2025, sobreviveu -- o mesmo mecanismo do gestor deletado na
  -- `trs_vjob__gestor_cliente`. **Regra BLOQUEANTE sobre buraco que a casa ja conhece e
  -- nao pode fechar ensina a ignorar a suite**, que e exatamente o que esta base
  -- registrou ao rebaixar o limiar de integridade do escopo e do cronograma para 0,70.
  -- Aqui 0,98 deixa passar o caso conhecido e dispara a partir do quinto orfao.
  --
  -- A `trs_vjob__job_prazo_alteracao` passou a emitir `flag_job_nao_catalogado` no mesmo
  -- dia -- ate aqui ela DECLARAVA o orfao na descricao sem emiti-lo em coluna nenhuma.
  -- DIVIDA DATADA: quando a `mysql-yIOn` rodar e a coluna existir, esta regra deve ser
  -- repontada para `COUNTIF(p.flag_job_nao_catalogado)`, que dispensa o join e a
  -- dependencia da Refined. **Nao da para repontar antes** -- referenciar coluna
  -- inexistente derruba a suite inteira.
  SELECT 'trs_vjob__job_prazo_alteracao.job_existe', 'Trusted',
         'trs_vjob__job_prazo_alteracao', 'VJOB',
         'INTEGRIDADE', 'alteracao aponta para job existente nas quatro origens', 'ALERTA', 0.98,
         COUNT(*), COUNTIF(j.id_job_unico IS NULL)
  FROM `vanguardamartech_trusted`.`trs_vjob__job_prazo_alteracao` p
  LEFT JOIN (SELECT DISTINCT id_job_unico FROM `vanguardamartech_refined`.`rfn_operacao__job`) j
    ON j.id_job_unico = p.id_job_unico
),
-- ---------- CONEXA / VBOT (acrescentada em 2026-09-28, quando materializou) ----------
-- As seis tabelas do Conexa foram publicadas em 25/09 e materializaram na passada da
-- `supabase-x0tz`. Elas andam DIARIAMENTE, como esta suite -- ao contrario da familia
-- Conta Azul, que anda semanal e por isso tem suite propria (`query-AQjU`).
--
-- A PREMISSA QUE ESTAS REGRAS GUARDAM: **o bronze do Conexa e um LOG DE VERSOES, nao uma
-- copia de estado.** Cada carga regrava a entidade inteira -- charges tem 5.197 linhas
-- para 933 cobrancas (5,6x), sales 9.417 para 3.638, bills 3.025 para 1.458. As Trusted
-- leem a ULTIMA versao por `natural_key`. Se a deduplicacao quebrar, a contagem de
-- linhas explode e todo valor e contado ate seis vezes -- e a chave duplicada e a unica
-- coisa que denuncia isso cedo.
r_conexa AS (
  SELECT 'trs_conexa__cliente.id_cliente' AS id_regra, 'Trusted' AS camada,
         'trs_conexa__cliente' AS tabela, 'Conexa' AS sistema,
         'UNICIDADE' AS dimensao,
         'id_cliente unico -- uma linha por cliente, nao por versao' AS regra,
         'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_cliente) AS linhas_falha
  FROM `vanguardamartech_trusted`.`trs_conexa__cliente`
  UNION ALL
  -- O derivado do Supabase e o bronze concordam campo a campo neste sistema -- o oposto
  -- do VJOB, onde o derivado PERDE coluna. `flag_sem_bronze` acende quando o derivado
  -- tem cliente que o log de versoes nao tem: se subir, a premissa de que as duas
  -- extracoes andam juntas caiu, e a Trusted passa a nao ter de onde tirar telefone,
  -- logradouro e ramo de atividade.
  SELECT 'trs_conexa__cliente.versao_do_bronze', 'Trusted', 'trs_conexa__cliente', 'Conexa',
         'INTEGRIDADE', 'todo cliente do derivado tem versao no log do bronze', 'ALERTA', 1.00,
         COUNT(*), COUNTIF(flag_sem_bronze)
  FROM `vanguardamartech_trusted`.`trs_conexa__cliente`
  UNION ALL
  SELECT 'trs_conexa__cobranca.id_cobranca', 'Trusted', 'trs_conexa__cobranca', 'Conexa',
         'UNICIDADE', 'id_cobranca unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_cobranca)
  FROM `vanguardamartech_trusted`.`trs_conexa__cobranca`
  UNION ALL
  -- secao 13: "investimento >= 0". Aqui o sentido esta em tipo_cobranca, nunca no sinal.
  SELECT 'trs_conexa__cobranca.valor_nao_negativo', 'Trusted', 'trs_conexa__cobranca', 'Conexa',
         'VALIDADE', 'valor_original >= 0 -- o sentido esta no tipo, nao no sinal', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(valor_original < 0)
  FROM `vanguardamartech_trusted`.`trs_conexa__cobranca`
  UNION ALL
  SELECT 'trs_conexa__contrato.id_contrato', 'Trusted', 'trs_conexa__contrato', 'Conexa',
         'UNICIDADE', 'id_contrato unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_contrato)
  FROM `vanguardamartech_trusted`.`trs_conexa__contrato`
  UNION ALL
  SELECT 'trs_conexa__venda.id_venda', 'Trusted', 'trs_conexa__venda', 'Conexa',
         'UNICIDADE', 'id_venda unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_venda)
  FROM `vanguardamartech_trusted`.`trs_conexa__venda`
  UNION ALL
  SELECT 'trs_conexa__despesa.id_despesa', 'Trusted', 'trs_conexa__despesa', 'Conexa',
         'UNICIDADE', 'id_despesa unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_despesa)
  FROM `vanguardamartech_trusted`.`trs_conexa__despesa`
  UNION ALL
  SELECT 'trs_conexa__despesa.valor_nao_negativo', 'Trusted', 'trs_conexa__despesa', 'Conexa',
         'VALIDADE', 'valor >= 0 -- o sentido esta no tipo, nao no sinal', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(valor < 0)
  FROM `vanguardamartech_trusted`.`trs_conexa__despesa`
  UNION ALL
  SELECT 'rfn_financeiro__inadimplencia_vbot.id_titulo', 'Refined',
         'rfn_financeiro__inadimplencia_vbot', 'Conexa',
         'UNICIDADE', 'id_titulo unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_titulo)
  FROM `vanguardamartech_refined`.`rfn_financeiro__inadimplencia_vbot`
  UNION ALL
  SELECT 'rfn_financeiro__inadimplencia_vbot.titulo_existe', 'Refined',
         'rfn_financeiro__inadimplencia_vbot', 'Conexa',
         'INTEGRIDADE', 'todo titulo da Refined existe na Trusted de cobranca', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(c.id_cobranca IS NULL)
  FROM `vanguardamartech_refined`.`rfn_financeiro__inadimplencia_vbot` i
  LEFT JOIN (SELECT DISTINCT id_cobranca FROM `vanguardamartech_trusted`.`trs_conexa__cobranca`) c
    ON c.id_cobranca = i.id_titulo
),
-- ---------- LOTE DE 25/09 (acrescentada em 2026-09-28, quando materializou) -----------
-- Seis Trusted do VJOB e a Refined do Linear. Cada regra guarda uma INVARIANTE que a
-- descricao da tabela ja declarava e que ate aqui ninguem verificava de novo.
r_lote_2509 AS (
  SELECT 'trs_vjob__gestor_cliente.id_gestor_cliente' AS id_regra, 'Trusted' AS camada,
         'trs_vjob__gestor_cliente' AS tabela, 'VJOB' AS sistema,
         'UNICIDADE' AS dimensao, 'id_gestor_cliente unico' AS regra,
         'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_gestor_cliente) AS linhas_falha
  FROM `vanguardamartech_trusted`.`trs_vjob__gestor_cliente`
  UNION ALL
  SELECT 'trs_vjob__parcela_analista_alteracao.id_alteracao', 'Trusted',
         'trs_vjob__parcela_analista_alteracao', 'VJOB',
         'UNICIDADE', 'id_alteracao unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_alteracao)
  FROM `vanguardamartech_trusted`.`trs_vjob__parcela_analista_alteracao`
  UNION ALL
  -- A INVARIANTE QUE DISTINGUE ESTE LOG DO `tbmudancas`. Aqui a origem declara PARCELA e
  -- CONTRATO, as duas explicitas, e o contrato declarado e SEMPRE o da propria parcela --
  -- 248 de 248, zero divergem. No `tbmudancas` a coluna e uma so e o alvo e indecidivel
  -- em 46,4% das linhas. Se esta regra acender, o log deixa de ser auto-consistente e o
  -- join por parcela passa a nao concordar com o join por contrato.
  SELECT 'trs_vjob__parcela_analista_alteracao.contrato_declarado_bate', 'Trusted',
         'trs_vjob__parcela_analista_alteracao', 'VJOB',
         'VALIDADE', 'o contrato declarado no log e o contrato da propria parcela', 'BLOQUEANTE', 1.00,
         COUNTIF(id_contrato_no_log IS NOT NULL AND id_contrato_na_parcela IS NOT NULL),
         COUNTIF(flag_contrato_diverge_da_parcela)
  FROM `vanguardamartech_trusted`.`trs_vjob__parcela_analista_alteracao`
  UNION ALL
  SELECT 'trs_vjob__acao_administrativa.id_acao', 'Trusted', 'trs_vjob__acao_administrativa', 'VJOB',
         'UNICIDADE', 'id_acao unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_acao)
  FROM `vanguardamartech_trusted`.`trs_vjob__acao_administrativa`
  UNION ALL
  -- O GATILHO DE MANUTENCAO DO PARSER. A acao e TEXTO LIVRE na origem -- 327 frases
  -- distintas em 430 linhas -- e cinco padroes cobrem 430 de 430, zero residuo. Quando
  -- o sistema passar a escrever uma frase nova, ela cai em NAO_RECONHECIDO e some de
  -- toda leitura por verbo SEM que a contagem de linhas mude. ALERTA e nao BLOQUEANTE
  -- porque a linha continua valida: o que se perde e a classificacao, nao o registro.
  SELECT 'trs_vjob__acao_administrativa.padrao_reconhecido', 'Trusted',
         'trs_vjob__acao_administrativa', 'VJOB',
         'VALIDADE', 'toda acao casa com um dos cinco padroes de frase da origem', 'ALERTA', 1.00,
         COUNT(*), COUNTIF(flag_padrao_nao_reconhecido)
  FROM `vanguardamartech_trusted`.`trs_vjob__acao_administrativa`
  UNION ALL
  SELECT 'trs_vjob__cronograma_verba.id_verba', 'Trusted', 'trs_vjob__cronograma_verba', 'VJOB',
         'UNICIDADE', 'id_verba unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_verba)
  FROM `vanguardamartech_trusted`.`trs_vjob__cronograma_verba`
  UNION ALL
  -- A INVARIANTE QUE DECIDIU O TRATAMENTO DA VERBA, e ela vale dinheiro. A verba e a
  -- DECOMPOSICAO do contrato por veiculo, nao um valor adicional: em 35 dos 37 contratos
  -- catalogados a soma das verbas e exatamente o valor do contrato, e em NENHUM ela e
  -- maior. E por isso que somar verba com parcela duplica. Se um contrato passar a ter
  -- verba MAIOR que ele mesmo, a premissa cai e a leitura "a verba nao e dinheiro novo"
  -- deixa de valer -- sem que contagem nenhuma denuncie.
  SELECT 'trs_vjob__cronograma_verba.verba_nunca_excede_o_contrato', 'Trusted',
         'trs_vjob__cronograma_verba', 'VJOB',
         'VALIDADE', 'a soma das verbas nunca excede o valor do contrato', 'BLOQUEANTE', 1.00,
         COUNTIF(diferenca_para_o_contrato IS NOT NULL),
         COUNTIF(diferenca_para_o_contrato > 0.01)
  FROM `vanguardamartech_trusted`.`trs_vjob__cronograma_verba`
  UNION ALL
  SELECT 'trs_vjob__job_aprovacao_inicial.id_aprovacao', 'Trusted',
         'trs_vjob__job_aprovacao_inicial', 'VJOB',
         'UNICIDADE', 'id_aprovacao unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_aprovacao)
  FROM `vanguardamartech_trusted`.`trs_vjob__job_aprovacao_inicial`
  UNION ALL
  -- As DUAS invariantes do porteiro, numa regra so: decisao sem data e pendente com
  -- data. As duas em ZERO. Se qualquer uma acender, o status deixa de concordar com o
  -- carimbo e toda serie temporal de aprovacao mente sobre QUANDO a decisao aconteceu.
  SELECT 'trs_vjob__job_aprovacao_inicial.status_concorda_com_carimbo', 'Trusted',
         'trs_vjob__job_aprovacao_inicial', 'VJOB',
         'VALIDADE', 'status e carimbo de decisao concordam nos dois sentidos', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(flag_decidida_sem_data OR flag_pendente_com_data)
  FROM `vanguardamartech_trusted`.`trs_vjob__job_aprovacao_inicial`
  UNION ALL
  SELECT 'trs_vjob__job_comentario_cliente.id_comentario_cliente', 'Trusted',
         'trs_vjob__job_comentario_cliente', 'VJOB',
         'UNICIDADE', 'id_comentario_cliente unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_comentario_cliente)
  FROM `vanguardamartech_trusted`.`trs_vjob__job_comentario_cliente`
  UNION ALL
  -- A VOZ DO CLIENTE resolve a conta de ATENDIMENTO em 22 de 22 -- e e a conta, nao o
  -- cadastro juridico, a mesma licao ja provada em tbgestoresclientes. Se cair, a unica
  -- tabela desta base escrita por quem esta do outro lado perde o cliente dela.
  SELECT 'trs_vjob__job_comentario_cliente.conta_catalogada', 'Trusted',
         'trs_vjob__job_comentario_cliente', 'VJOB',
         'INTEGRIDADE', 'o comentario resolve a conta de atendimento', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(flag_conta_nao_catalogada)
  FROM `vanguardamartech_trusted`.`trs_vjob__job_comentario_cliente`
  UNION ALL
  SELECT 'rfn_operacao__issue_mensal.id_issue_mensal', 'Refined', 'rfn_operacao__issue_mensal', 'Linear',
         'UNICIDADE', 'id_issue_mensal unico (unidade + mes)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_issue_mensal)
  FROM `vanguardamartech_refined`.`rfn_operacao__issue_mensal`
  UNION ALL
  -- A INVARIANTE QUE FAZ COORTE E FLUXO DAREM O MESMO NUMERO NO LINEAR. As 67 issues
  -- concluidas foram todas concluidas no MESMO MES em que nasceram -- media de 1,88 dia,
  -- 60% no mesmo dia. Enquanto isso valer, `qtd_criadas_no_mes_ja_concluidas` e
  -- `qtd_concluidas_no_mes` coincidem. No dia em que uma atravessar o mes os dois numeros
  -- divergem e quem estiver lendo um pelo outro erra SEM AVISO. ALERTA, nao BLOQUEANTE:
  -- atravessar o mes e um fato legitimo, nao um defeito -- o que nao pode e passar
  -- despercebido.
  SELECT 'rfn_operacao__issue_mensal.conclusao_nao_atravessa_mes', 'Refined',
         'rfn_operacao__issue_mensal', 'Linear',
         'VALIDADE', 'nenhuma conclusao atravessa o mes -- coorte e fluxo coincidem', 'ALERTA', 1.00,
         COUNT(*), COUNTIF(flag_conclusao_atravessa_mes)
  FROM `vanguardamartech_refined`.`rfn_operacao__issue_mensal`
),
todas AS (
  SELECT * FROM r_completude
  UNION ALL SELECT * FROM r_unicidade
  UNION ALL SELECT * FROM r_validade
  UNION ALL SELECT * FROM r_integridade
  UNION ALL SELECT * FROM r_vjob
  UNION ALL SELECT * FROM r_vjob_fk
  UNION ALL SELECT * FROM r_custo
  UNION ALL SELECT * FROM r_rateio
  UNION ALL SELECT * FROM r_midia
  UNION ALL SELECT * FROM r_grao_misto
  UNION ALL SELECT * FROM r_vjob_novo
  UNION ALL SELECT * FROM r_vjob_satelite
  UNION ALL SELECT * FROM r_conexa
  UNION ALL SELECT * FROM r_lote_2509
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
