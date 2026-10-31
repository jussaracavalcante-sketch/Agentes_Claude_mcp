-- rfn_operacao__email_rotulo_resumo  ·  Refined / operacao  ·  L2 INTERNAL
-- Grao: caixa (CONTATO/VTECH) x tipo de rotulo (system/user). Le: trs_gmail__rotulo + trs_gmail__mensagem. Gatilho: evento em query-TXoY (mensagem).
-- Identidade (07/10/2026): 32 rotulos = 32 · 4 linhas · mensagens distintas com rotulo de sistema 2.068 + 31.160 = 33.228 = total da Trusted.
-- R1 O Gmail declara contagem de mensagens por rotulo (gmail_mensagens_total) e ela e NULL nos 32: a contagem aqui sai das mensagens (rotulos desaninhados).
-- R2 qtd_pares_mensagem_rotulo NAO e numero de mensagens: uma mensagem carrega varios rotulos e entra em cada um. Mensagens se leem em qtd_mensagens_distintas.
-- R3 Tem rotulo e conta por caixa: o id de rotulo e compartilhado entre caixas em 30 de 32 (Label_1 e outro sentido em cada caixa) — chave sempre (caixa, id).
-- R4 Nao ha mensagem sem rotulo de sistema (invariante da suite de qualidade do Gmail).
WITH r AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_gmail__rotulo`
),
mr AS (
  SELECT m.id_mensagem_unico, m.caixa, id_rotulo
  FROM `vanguardamartech_trusted`.`trs_gmail__mensagem` m, UNNEST(m.rotulos) AS id_rotulo
),
por_rotulo AS (
  SELECT r.id_rotulo_unico, r.caixa, r.tipo, r.is_rotulo_de_usuario, r.flag_id_compartilhado_entre_caixas, r.flag_nome_diverge_entre_caixas,
    COUNT(mr.id_mensagem_unico) AS n
  FROM r
  LEFT JOIN mr ON mr.caixa = r.caixa AND mr.id_rotulo = r.id_rotulo
  GROUP BY 1, 2, 3, 4, 5, 6
),
grp AS (
  SELECT r.caixa, r.tipo, r.is_rotulo_de_usuario, COUNT(DISTINCT mr.id_mensagem_unico) AS qtd_mensagens_distintas
  FROM r
  LEFT JOIN mr ON mr.caixa = r.caixa AND mr.id_rotulo = r.id_rotulo
  GROUP BY 1, 2, 3
),
agg AS (
  SELECT
    p.caixa, p.tipo, p.is_rotulo_de_usuario,
    COUNT(*) AS qtd_rotulos,
    COUNTIF(p.n = 0) AS qtd_rotulos_sem_mensagem,
    COUNTIF(p.flag_id_compartilhado_entre_caixas) AS qtd_id_compartilhado,
    COUNTIF(p.flag_nome_diverge_entre_caixas) AS qtd_nome_diverge,
    SUM(p.n) AS qtd_pares_mensagem_rotulo,
    ANY_VALUE(g.qtd_mensagens_distintas) AS qtd_mensagens_distintas
  FROM por_rotulo p
  JOIN grp g ON g.caixa = p.caixa AND g.tipo = p.tipo AND g.is_rotulo_de_usuario = p.is_rotulo_de_usuario
  GROUP BY 1, 2, 3
),
final AS (
  SELECT CONCAT(caixa, '|', tipo) AS id_rotulo_resumo, a.*, 'L2_INTERNAL' AS classificacao_dado
  FROM agg a
)
SELECT f.*, CURRENT_TIMESTAMP() AS _extraido_at, 'gmail-c3ku | gmail-cF2Q' AS _fonte,
  'America/Sao_Paulo' AS _fuso, TO_HEX(MD5(TO_JSON_STRING(f))) AS _payload_hash
FROM final f
