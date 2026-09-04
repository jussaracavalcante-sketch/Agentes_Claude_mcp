# Breakdowns do Google Ads — exploração antes de construir — 2026-09-04

Preparação para a Trusted dos cinco streams de segmentação, combinada para 05/09. **Nada foi
publicado** — deploy está bloqueado por falta de saldo. Isto é o levantamento que permite
construir direto quando destravar.

Conta piloto: Acesso Saúde (`vanguardamartech_acesso_saude_google_ads`, prefixo
`google_ads_acesso_saude`). Segunda conta de confirmação: Hospital Santa Júlia.

## Os cinco existem e estão materializados

| Stream | Linhas (Acesso Saúde, total) |
|---|---:|
| `search_term_performance` | 161.182 |
| `age_range_performance` | 20.916 |
| `user_location_performance` | 18.512 |
| `gender_performance` | 9.885 |
| `geographic_performance` | 6.501 |

**Alerta de escala:** `search_term` sozinho tem 161 mil linhas numa conta. Com 36 contas, a
consolidada pode ir à casa dos milhões. Medir antes de decidir se vai numa Trusted única ou
separada — e conferir materialização conta a conta, porque tabela catalogada não é tabela
existente.

## O achado principal: os cinco NÃO se comportam igual

Reconciliação contra `campaign_performance`, agosto/2026:

| Stream | Acesso Saúde | Hospital Santa Júlia | Veredito |
|---|---:|---:|---|
| campanha (referência) | 2.459,91 | 2.449,30 | — |
| `age_range` | 2.459,91 | 2.449,30 | **fecha exato** |
| `gender` | 2.459,91 | 2.449,30 | **fecha exato** |
| `geographic` (total) | 2.459,91 | 2.449,30 | **fecha exato** |
| `user_location` (total) | 2.404,83 | 2.422,99 | **falta 1 a 2%** |
| `search_term` | 1.447,28 | 1.013,37 | **41 a 59% só** |

Padrão idêntico nas duas contas — é sistêmico, não coincidência.

### `geographic`: o risco é subcontar, não duplicar

A tabela tem `location_type` com dois valores, e a intuição diz que somar os dois duplica.
**É o contrário.** Medido na Acesso Saúde:

| `location_type` | Investimento |
|---|---:|
| `AREA_OF_INTEREST` | 902,80 |
| `LOCATION_OF_PRESENCE` | 1.557,11 |
| **soma** | **2.459,91 = total da campanha** |

O Google particiona: cada impressão cai em **um** dos dois. Somar a tabela inteira dá o número
certo; **filtrar um `location_type` dá um número parcial** e parece completo.

### `user_location`: perde 1 a 2% e não dá para consertar aqui

Soma 2.404,83 contra 2.459,91 da campanha — faltam R$ 55,08 e 355 impressões na Acesso Saúde;
R$ 26,31 no Hospital Santa Júlia. São linhas cuja localização o Google não resolveu e por isso
não emite.

**Consequência:** esta tabela **nunca** deve ser usada para total de investimento. Serve para
distribuição geográfica, sempre com a ressalva de que 1 a 2% do gasto não tem localização.

Curiosidade que vale registrar: `user_location` com `targeting_location = true` bate **exato**
com `geographic / LOCATION_OF_PRESENCE` (1.557,11 nas duas). As duas tabelas se cruzam nesse
recorte.

### `search_term`: incompleto por privacidade, não por tipo de campanha

Esperava-se que o buraco fosse campanha sem termo de busca — PMax, Display, Video. **Não é.**
Medido na Acesso Saúde: as **6 campanhas do mês são todas `SEARCH`**, e **todas as 6 têm linhas
em `search_term`**. Ainda assim a tabela cobre só 58,8% do gasto.

A explicação é o Google **suprimir termos de baixo volume** por privacidade — o gasto existe, o
termo não é reportável.

**Regra que sai daqui:** `search_term` serve para descobrir intenção e negativar termo. **Nunca
para somar investimento.** Quem somar vai reportar 40 a 60% do gasto real achando que está
completo.

## Grão provado

Contagem sobre a Acesso Saúde inteira. `id` é hash e é único em todos os cinco.

| Stream | Linhas | `id` únicos | Chave natural | Chave natural proposta |
|---|---:|---:|---:|---|
| `age_range` | 20.916 | 20.916 | 20.916 | campanha, grupo, faixa, data |
| `gender` | 9.885 | 9.885 | 9.885 | campanha, grupo, gênero, data |
| `geographic` | 6.501 | 6.501 | 6.501 | campanha, país, `location_type`, data |
| `search_term` | 161.182 | 161.182 | 161.182 | campanha, grupo, termo, tipo de correspondência, data |
| `user_location` | 18.512 | 18.512 | **18.511** | ver abaixo |

### A colisão do `user_location`

Uma chave a menos que o número de linhas. As duas linhas colidentes:

- mesma campanha (`21298472833`), mesma data (15/08/2025), mesmo `targeting_location`
- **mesma cidade** (`geo_target_city_id = 1000073`)
- **regiões diferentes** — `9198138` e `9199092`

Ou seja, o mesmo id de cidade aparece sob dois ids de região. **A chave natural precisa de
`geo_target_region_id`**, senão uma linha é descartada silenciosamente no dedup.

Chave correta: `(campaign_id, geo_target_region_id, geo_target_city_id, targeting_location, date)`.

## Correção a fazer na camada semântica

O documento "Google Ads — Regras de leitura" afirma:

> **Não há quebra por cidade nem por placement.** Análises geográficas ficam limitadas
> ao nível do stream `geographic_performance` padrão; região e cidade exigiriam
> habilitar o stream detalhado.

**A parte de cidade e região está errada.** O `user_location_performance` está habilitado e
traz `geo_target_region_id` e `geo_target_city_id`. O que não existe é o
`geographic_performance_detailed`, que é outra coisa. A parte de placement continua correta.

Corrigir junto com a publicação da Trusted.

## Materialização: as 39 contas verificadas, 195 tabelas

Verificado em 2026-09-04, conta a conta, em lotes — porque uma tabela inexistente derrubaria
a query inteira e eu precisava saber qual.

**Todas as 195 tabelas existem e respondem.** Nenhuma referência quebrada. A armadilha de
"tabela no catálogo não é tabela existente" não se aplica aqui.

| Stream | Linhas | Contas zeradas | Maior conta |
|---|---:|---:|---|
| `search_term` | 2.941.715 | 3 | `NP4k` (1.060.213) |
| `user_location` | 780.154 | 3 | `NP4k` (145.519) |
| `age_range` | 275.360 | 3 | `NP4k` (45.814) |
| `gender` | 132.072 | 3 | `NP4k` (19.874) |
| `geographic` | 68.210 | 3 | `NP4k` (10.105) |
| **Total** | **4.197.511** | | |

**Três contas inteiramente vazias**, todas coerentes com o que já se sabia:
`vE2C` (Don Watches conta 1, sem atividade desde 2023), `rYKp` (Rodrix Motos) e
`wypN` (Dr. Cabral conta 1) — as duas últimas já constavam como sem entrega desde 22/08.
Tabelas existem, sem linha. Não é falha, é conta sem veiculação.

### O que o volume muda no desenho

**`search_term` sozinho é 70,1% do volume** — 2,94 milhões de linhas. E uma única conta, a
PMZ GRUPO LOJA (`NP4k`), responde por **1,06 milhão**, mais de um terço do stream.

Isso confirma a decisão de não fazer uma Trusted única de "segmentos": o `search_term` tem
uma ordem de grandeza a mais que os outros quatro somados (2,94 M contra 1,25 M) e um perfil
de crescimento próprio. Juntá-lo com `gender`, que tem 132 mil linhas, faria toda consulta de
gênero varrer o volume de termo de busca.

Os quatro demográficos e geográficos somam 1,25 milhão — volume confortável.

## O que ainda falta levantar

- **Quantas contas têm campanha não-`SEARCH`.** Na Acesso Saúde as 6 do mês eram todas
  `SEARCH`, então o efeito de PMax/Display sobre a cobertura do `search_term` não foi
  observado — só o de supressão por privacidade. Em contas com PMax a perda deve ser maior.
- **Reconciliação em mais contas.** As duas medidas mostraram padrão idêntico, mas o
  percentual de perda do `user_location` (1 a 2%) e do `search_term` (41 a 59%) varia, e vale
  medir a faixa real antes de escrever o número na descrição.

## Rascunho do desenho

Cinco tabelas Trusted, não uma:

- `trs_google_ads__segmento_faixa_etaria`
- `trs_google_ads__segmento_genero`
- `trs_google_ads__segmento_geografico`
- `trs_google_ads__segmento_localizacao_usuario`
- `trs_google_ads__termo_busca`

Motivo de não unificar: os grãos são diferentes e a completude também. Juntar num "segmentos"
único obrigaria coluna de tipo e faria alguém somar tudo — que é exatamente o erro que os
números acima mostram ser fácil cometer.

As três que fecham exato (`faixa_etaria`, `genero`, `geografico`) podem ir para a Refined como
recorte de `rfn_midia__desempenho_diario`. As duas incompletas ficam na Trusted com a limitação
declarada, e só sobem para a Refined se alguém pedir — com o percentual de perda na descrição.
