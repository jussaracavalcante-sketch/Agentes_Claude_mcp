-- trs_vjob__servico
-- Dimensao de servico do escopo mensal do VJOB. Um servico por linha. Chave id_servico.
--
-- ATENCAO AO SUJEITO DESTA TABELA. Ela NAO le o sistema. A tabela de dominio do
-- sistema EXISTE e esta VAZIA: `mysql_vjobvjob_2024_tb_servicos_servico`
-- (id, categoria, subcategoria, nome, datacriacao) tem **ZERO linhas**, apesar de a
-- extracao da `mysql-yIOn` ter terminado com sucesso em 21/09/2026 17:38.
-- Enquanto ela estiver vazia, **o nome do servico nao existe no sistema** -- o unico
-- lugar da base que tem os rotulos e o derivado Supabase.
--
-- Por isso esta dimensao e montada a partir de `supabase_silver_vjob_escopo`, com a
-- origem declarada linha a linha em `origem_do_nome`. Mesmo padrao da
-- `trs_iclips__tarefa`, que junta bronze e notebook e declara a procedencia.
--
-- QUANDO `tb_servicos_servico` MATERIALIZAR COM LINHA, esta query deve passar a ler
-- o sistema e manter o derivado so como resíduo para os ids que o sistema nao trouxer.
-- Nao apagar a coluna `origem_do_nome` ao fazer isso -- ela e o que torna a troca
-- auditavel.
--
-- VOLUME -- medido em 2026-09-23
--   38 servicos, 38 ids distintos. **4 sem nome** (ids 10, 17, 19 e 27), que o
--   derivado entrega como o literal "(outro)" e aqui viram NULL.
--   Esses 4 cobrem 7.980 escopos dos 195.163 (4,1%).
--
-- O VOLUME E MEDIDO, NAO DIGITADO. `qtd_escopos` sai de um COUNT sobre o proprio
-- derivado a cada execucao. Servico que sumir da origem deixa de produzir linha.
--
-- LIMITACOES -- NAO CONTORNE
--   1. **O nome aqui e rotulo de segunda mao.** Identidade se resolve por
--      `id_servico`, nunca por `servico`. Se o derivado renomear, esta tabela muda
--      sem que nada tenha mudado no sistema.
--   2. `categoria` e `subcategoria` existem no esquema do sistema e **nao chegam
--      aqui**, porque a tabela do sistema esta vazia. Nao ha agrupamento de servico
--      por familia nesta base hoje.
--   3. Os 4 sem nome NAO sao servico inexistente -- sao servico cujo rotulo o
--      derivado nao resolveu. Eles tem escopo real e entram em toda contagem.
SELECT
  d.id_servico,
  d.nome                                          AS servico,
  (d.nome IS NULL)                                AS flag_nome_nao_resolvido,
  IF(d.nome IS NULL, 'NAO_RESOLVIDO', 'DERIVADO_SUPABASE') AS origem_do_nome,
  d.qtd_escopos,
  d.qtd_clientes,
  d.qtd_concluidos,
  CURRENT_TIMESTAMP()                             AS _extraido_at,
  'supabase-x0tz (derivado)'                      AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(d)))                  AS _payload_hash
FROM (
  SELECT
    id_servico,
    -- "(outro)" e o literal que o derivado usa quando nao resolve o rotulo.
    -- Vira NULL: ausencia declarada vale mais que um rotulo que nao diz nada.
    NULLIF(NULLIF(ANY_VALUE(servico), ''), '(outro)') AS nome,
    COUNT(*)                                        AS qtd_escopos,
    COUNT(DISTINCT id_cliente)                      AS qtd_clientes,
    COUNTIF(concluido)                              AS qtd_concluidos
  FROM `vanguardamartech_raw`.`supabase_silver_vjob_escopo`
  GROUP BY id_servico
) d
