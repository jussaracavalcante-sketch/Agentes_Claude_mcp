-- trs_vjob__cronograma_alteracao
-- Trusted / VJOB. Grao: uma ALTERACAO de campo no cronograma. Chave: id_alteracao.
-- Origem: mysql-yIOn, `tbmudancas` (18.932 linhas). L2 INTERNAL.
--
-- O QUE ELA RESPONDE: **quem mudou o que, de quanto para quanto, e quando** na familia de
--   cronograma -- inclusive `valor`, `comissao`, `fornecedor`, `nfse` e `cliente`. E o
--   unico log de alteracao de dinheiro de contrato que esta base tem. Vai de
--   **22/04/2024 22:37:08** a **23/09/2026 15:47:12** -- viva.
--
-- ============================================================================
-- **O ACHADO QUE DECIDE A LEITURA: `id_cronograma` APONTA PARA DOIS UNIVERSOS
-- DIFERENTES, E EM QUASE METADE DAS LINHAS NAO DA PARA SABER QUAL.**
-- ============================================================================
--   A coluna se chama `id_cronograma`, mas o valor casa **ora com o CONTRATO
--   (`tbcronograma`), ora com a PARCELA (`tbcronogramadatas`)** -- e as duas sequencias
--   de id **se sobrepoem**: contrato vai de 19 a 7.603, parcela de 75 a 14.633, e
--   **4.121 ids existem nos dois**.
--
--   Medido em 2026-09-24 sobre as duas Trusted materializadas:
--     AMBIGUO ......... **8.786 (46,4%)** -- o id existe nos DOIS, indecidivel
--     PARCELA ......... 6.242 (33,0%)
--     CONTRATO ........ 3.087 (16,3%)
--     NAO_CATALOGADO .. 817 (4,3%) -- nao existe em nenhum dos dois (apagado)
--
--   **A TABELA NAO ESCOLHE, porque escolher seria inventar.** `alvo_resolvido` declara
--   o caso linha a linha e `id_alvo` sai cru. **Quem juntar esta tabela com contrato ou
--   com parcela TEM de filtrar `alvo_resolvido`** -- um join direto por `id_alvo`
--   duplica 8.786 linhas entre as duas pontas e ninguem percebe, porque a contagem de
--   linhas de cada lado continua plausivel.
--
--   A hipotese de que a coluna afetada resolveria a ambiguidade **foi testada e
--   descartada**: quase toda coluna casa nos dois lados em proporcao variavel
--   (`vencimentocontrato` 3.872 contrato e 6.145 parcela; `nfse` 1.845 e 2.906). Nao ha
--   regra por coluna.
--
-- AS 18 COLUNAS AFETADAS, por volume: `vencimentocontrato` 6.917 · `mesanoreferencia`
--   5.048 · `nfse` 3.185 · `servico` 1.401 · `piocci` 1.254 · `valor` 355 · `cs` 182 ·
--   `cliente` 154 · `competencia` 139 · `comissao` 89 · `fornecedor` 85 ·
--   `observacoes` 67 · `parcelanumero` 18 · `finaldecontrato` 15 · `primeiracobranca`
--   11 · `iniciodecontrato` 9 · `os` 2 · `qtdparcelas` 1.
--   **Nao ha tabela de dominio** para esses rotulos; eles sao o nome fisico da coluna na
--   origem e saem crus.
--
-- `usuario` E TEXTO, NAO ID -- 42 valores distintos e **953 linhas sem usuario** (5%).
--   Nao junta com `trs_vjob__usuario` por chave; quem quiser a pessoa casa por rotulo, e
--   isso e hipotese, nao prova.
--
-- **8 ALTERACOES NAO ALTERARAM NADA** -- `valor_antigo` igual a `valor_novo`.
--   `flag_sem_mudanca` marca. Sao 8 em 18.932, mas contar "quantas vezes o valor mudou"
--   sem o filtro conta 8 eventos que nao foram mudanca.
--   Mais 2.353 linhas sem `valor_antigo` e 311 sem `valor_novo` -- preenchimento
--   inicial e limpeza de campo, que sao mudancas de verdade e ficam.
--
-- FUSO: relogio local da intranet. **NAO CONVERTER.**
--
-- MEDIDO EM 2026-09-24: 18.932 linhas · 18.932 chaves · 9.767 ids de alvo distintos ·
--   18 colunas afetadas, zero linha sem coluna · 42 usuarios · 953 sem usuario ·
--   8 sem mudanca.
WITH base AS (
  SELECT id, id_cronograma, coluna_afetada, valor_antigo, valor_novo, data_mudanca, usuario
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbmudancas`
),
contratos AS (SELECT DISTINCT id_cronograma FROM `vanguardamartech_trusted`.`trs_vjob__cronograma`),
parcelas  AS (SELECT DISTINCT id_parcela    FROM `vanguardamartech_trusted`.`trs_vjob__cronograma_parcela`),
tratado AS (
  SELECT
    b.id                                          AS id_alteracao,
    -- O id cru, sem interpretacao. Ver o bloco do cabecalho antes de usar em join.
    b.id_cronograma                               AS id_alvo,
    -- A unica resposta honesta sobre o que esse id significa.
    CASE
      WHEN c.id_cronograma IS NOT NULL AND p.id_parcela IS NOT NULL THEN 'AMBIGUO'
      WHEN c.id_cronograma IS NOT NULL                              THEN 'CONTRATO'
      WHEN p.id_parcela    IS NOT NULL                              THEN 'PARCELA'
      ELSE 'NAO_CATALOGADO'
    END                                           AS alvo_resolvido,
    -- Preenchidos SO quando o alvo e inequivoco. Em AMBIGUO os dois saem NULL, de
    -- proposito: preencher os dois convidaria a somar a mesma alteracao duas vezes.
    IF(c.id_cronograma IS NOT NULL AND p.id_parcela IS NULL,
       b.id_cronograma, NULL)                     AS id_contrato,
    IF(p.id_parcela IS NOT NULL AND c.id_cronograma IS NULL,
       b.id_cronograma, NULL)                     AS id_parcela,

    NULLIF(TRIM(b.coluna_afetada), '')            AS coluna_afetada,
    NULLIF(TRIM(b.valor_antigo), '')              AS valor_antigo,
    NULLIF(TRIM(b.valor_novo), '')                AS valor_novo,
    (TRIM(COALESCE(b.valor_antigo, '')) = TRIM(COALESCE(b.valor_novo, '')))
                                                  AS flag_sem_mudanca,

    -- Texto livre, NAO id. 42 valores distintos.
    NULLIF(TRIM(b.usuario), '')                   AS usuario,
    (NULLIF(TRIM(b.usuario), '') IS NULL)         AS flag_sem_usuario,

    -- FUSO: relogio local da intranet. Nao converter.
    b.data_mudanca                                AS alterado_em
  FROM base b
  LEFT JOIN contratos c ON c.id_cronograma = b.id_cronograma
  LEFT JOIN parcelas  p ON p.id_parcela    = b.id_cronograma
)
SELECT
  t.*,
  CURRENT_TIMESTAMP()                             AS _extraido_at,
  'mysql-yIOn'                                    AS _fonte,
  'America/Sao_Paulo'                             AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(t)))                  AS _payload_hash
FROM tratado t
