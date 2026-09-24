# Regras de trabalho — Vanguarda MarTech

## Nekt · arquitetura de dados

### R-001 · Uma camada por fonte

**Política da empresa: cada fonte (source) da Nekt grava na sua própria camada.**
Nunca uma camada compartilhada entre fontes.

Nome da camada = cliente + conta + plataforma, quando o cliente tem mais de uma
conta na mesma plataforma. Ex.: `braga_veiculos_fb_ads`, `braga_acessorios_fb_ads`
— não uma `Braga_veiculos` para as duas.

Motivo: é o que mantém o permissionamento e a leitura da IA organizados conforme a
base cresce. Camada compartilhada obriga controle de acesso por tabela e faz a busca
semântica misturar contas e clientes.

**Criar camada dá pelo MCP** — `create_layer`, em duas fases (`confirm=False` mostra o
preview, `confirm=True` cria). Verificado em 2026-09-04 criando a `Trusted Facebook Ads`.
De 2026-08-26 a 2026-09-03 esta regra dizia que criar camada era backoffice sem endpoint;
estava errado. A camada precisa existir antes de publicar a fonte.

**O nome da camada é irreversível.** Ele deriva o `slug` e o `database_name` físico que toda
query futura referencia. Camada não se renomeia e recurso não se move entre camadas — o
conserto é criar outra e reconstruir tudo que apontava para a primeira, perdendo o histórico
das tabelas e deixando a antiga como lixo que também não se exclui. Confirmar a grafia exata
com quem pediu, sempre.

**Nome de camada não é nome de dataset.** A camada `Nova_era_` é o dataset
`vanguardamartech_nova_era`, sem o underscore final. Descobrir o dataset pelo catálogo ou pela
mensagem de erro do `execute_sql`, que lista as camadas candidatas — nunca deduzir do nome.

**Escopo:** a R-001 governa onde a **fonte** grava. Sistemas internos da Vanguarda (VJOB,
iClips, Conexa, Conta Azul, Qulture, Quickin, VBOT, GitHub, Linear) gravam na camada `Raw`,
folder = sistema de origem; dado de cliente grava na camada da própria fonte.

**Isso não isenta ninguém do medalhão.** O ADR-0009 vale para TODO dado, de cliente
inclusive — corrigido em 2026-09-04 a pedido. Até essa data este bloco dizia que o medalhão
era só para sistemas internos, e isso estava errado: levava a tratar camada de cliente como
depósito de cópia fiel sem estágio seguinte.

**Histórico:** de 2026-08-26 a 2026-08-31 esta regra dizia "a camada de saída é o
catálogo do cliente". Isso conflitava com uma camada por fonte sempre que o cliente
tinha várias contas. Corrigida em 2026-08-31 conforme a política da empresa.

**Não existe "catálogo do cliente" nesta base.** As camadas sem sufixo de
plataforma (`Acesso_saude`, `Braga_veiculos`, `colmeia`, `Best_car`, `PMZ_loja`,
`Patio_gourmet`, `Constroi_incorporadora`, `Nova_era_`, `Nova_era_pvh`,
`Nova_era_boa_vista`) **são as camadas do Facebook Ads** — ficaram sem sufixo
porque o Meta foi integrado antes de existir a convenção. Verificado em
2026-08-31: `Acesso_saude` tem 33 campanhas de Facebook e o Google Ads da mesma
conta está em `Acesso_saude_google_ADS`, com 36.

**Desvios conhecidos, anteriores à regra — não corrigir sem decisão explícita:**

- As 33 fontes de RD Station gravam todas em `RD_marketing`.
- **Camadas com duas plataformas misturadas:** `colmeia` (Facebook 122 campanhas +
  Google Ads 12), `Braga_veiculos` (2 fontes de Facebook + 1 de Google Ads) e
  `PMZ_loja` (1 de cada). Fontes envolvidas: `google-ads-R4be`, `google-ads-PsES`,
  `google-ads-NP4k`, `facebook-ads-kQ2S`, `facebook-ads-GWZ2`, `facebook-ads-ln1a`,
  `facebook-ads-x4yO`.
- `facebook-ads-mrJt` ("Campanhas"), sem cliente definido.

### R-002 · Não mexer no que já está conectado

**Fonte já publicada e rodando não se altera** — nem cron, nem stream, nem camada de
destino — sem pedido explícito. Vale inclusive para correção que pareça óbvia.

O que é permitido sem pedido: leitura, diagnóstico, e escrever descrição
(`update_resource_description`), que é documentação e não muda comportamento.

Registrado em 2026-08-31.

### R-003 · Conta com nome igual não se unifica

**Contas cujo nome começa igual são unidades distintas e nunca são fundidas numa
única linha de cliente.** Registrado em 2026-09-01 a pedido.

Vale para todos os grupos da base: as 10 contas `BRAGA *`, as 3 `PMZ *`, as 4 do
conjunto Pneu Forte (`PNEU FORTE *`, `PNEU EXPRESS`, `SMILE PNEUS`), as 2 `CAA *`,
as 2 `DON WATCHES *`, as 2 `DR. CABRAL *` e as 3 `UNIPAR *`.

Na prática, na camada Trusted: a coluna `cliente` recebe o nome **da conta**, nunca
o do grupo. Nada de `CASE WHEN cliente LIKE 'BRAGA%' THEN 'GRUPO BRAGA'`. Quem
quiser o consolidado agrupa na leitura, por `id_conta` ou por prefixo de nome — a
Trusted não decide isso por ninguém.

Motivo: as contas têm verba, calendário e responsável próprios. Fundi-las na
ingestão destrói informação que não volta; separá-las na leitura é trivial.

**O que a regra NÃO proíbe:** várias contas dividirem a mesma tabela Trusted. O que
não pode é perderem identidade dentro dela. As linhas convivem desde que
`id_conta` e `cliente` continuem distintos por conta.

### R-004 · Achado que não afeta ingestão nem tratamento: documenta e segue

**Se o achado não muda o dado que entra nem o tratamento que ele recebe, vira documentação
— não vira pergunta, nem pedido de ajuste, nem tarefa para outro time.**
Registrado em 2026-09-01 a pedido.

**Afeta, e portanto escala:** fonte falhando, credencial inválida, stream faltando, coluna
ausente, tipo incompatível, grão errado, investimento perdido, chave duplicada, fuso ou
unidade trocados. Aqui parar e perguntar é certo.

**Não afeta, e portanto só documenta:** rótulo divergente do nome na plataforma, grafia,
acento, nomenclatura de camada, apelido desatualizado, conta sem entrega, nome duplicado
na origem, numeração interna, qualquer inconsistência cosmética.

Na prática: escolher o default sensato, registrar a escolha **e a alternativa que não foi
tomada**, seguir. Sem `AskUserQuestion` para esses casos, sem lista para outro time a menos
que peçam. O registro vai no doc do domínio e na descrição do recurso — quem precisar decidir
encontra lá, quando quiser.

### R-005 · Não pedir revisão antes de agir

**Construir, alterar e excluir na Nekt não passa por revisão prévia.** Registrado em
2026-09-18 a pedido, com a frase "exclua, altere sem a minha revisão, use isso como regra
sempre".

Na prática: nada de `AskUserQuestion` para escolher entre caminhos técnicos, nada de parar
para confirmar deploy, nada de "posso seguir?". Escolher o default defensável, executar,
**medir antes de publicar** e relatar o que foi feito com os números — o relato vem depois
do trabalho, não no lugar dele.

**O que a regra NÃO muda**, porque são outras coisas:

- **A R-002 continua valendo.** Ela é política da empresa sobre fonte já publicada, não
  pedido de revisão. Cron, stream e camada de destino de fonte viva seguem exigindo pedido.
- **Rodar pipeline à mão continua proibido** — "somente no horário agendado", registrado
  antes. A prova é a execução agendada.
- **A checagem antes de excluir continua obrigatória** (seção "Antes de excluir qualquer
  coisa"). A regra tira a revisão dela, não a conferência: camada só sai vazia, repontar
  fonte não move dado, e o lookback do Facebook é de 37 meses.
- **Credencial continua fora do chat.**

O que substitui a revisão é a medição: equivalência declarada, `LIMIT 0` antes de publicar,
alerta de falha ligado, e o custo da escolha escrito na descrição.

### ADR-0009 · Medalhão

**O medalhão é estágio de tratamento, não camada física.** Toda fonte atravessa os três
estágios, esteja ela na camada `Raw` (sistemas internos) ou na camada da própria fonte
(dado de cliente). O estágio se lê no prefixo da tabela, não no nome da camada.

- **Raw** — cópia fiel da fonte, sem tratamento. Nada se corrige aqui. Folder = sistema
  de origem.
- **Trusted** — `trs_<sistema>__<entidade>`. Fidelidade ao número, correção da forma:
  tipagem, fuso `America/Sao_Paulo`, unicidade provada, desaninhamento de estrutura,
  sentinela (`"UNKNOWN"`) → NULL, identidade resolvida por id e nunca por rótulo,
  colunas de linhagem. **Não** recalcula métrica derivada (`cpc`, `ctr`, `cpm` passam
  como a plataforma entrega) e **não** escolhe qual evento é "a conversão" — as duas
  coisas são regra de negócio.
- **Refined** — `rfn_<domínio>__<entidade>`. Regras de negócio, agregação e as escolhas,
  declaradas e numeradas na descrição. Camada oficial de consumo. Folder = domínio.

**Fonte sem Trusted é fonte inacabada**, não fonte pronta em outro padrão. Publicar a
extração é meio caminho; o outro meio é o estágio de tratamento.

### ADR-0010 · O documento de arquitetura é norma

**"Arquitetura de Data Lake Medalhão — Agência MarTech" está na CAMADA SEMÂNTICA da Nekt**
(31.893 caracteres, 41 seções), não no repositório. Lê-se com
`get_semantic_context`. Registrado como norma em 2026-09-23 a pedido: **seguir esse
documento sempre**.

**O que ele fixa e que a casa já cumpre:**
- Bronze preserva · Silver organiza · Gold representa o negócio · Semantic Layer define o
  significado · IA consome dado governado (§29). É o ADR-0009 com outros nomes:
  Raw = Bronze, Trusted = Silver, Refined = Gold.
- §18: **a IA não consulta a Bronze**. Consulta Gold e Semantic Layer.
- §5 Silver: tipagem, deduplicação, normalização de data e moeda, resolução de ids,
  chaves técnicas — exatamente o que as `trs_*` fazem.
- §17: métrica tem definição oficial na Semantic Layer, e BI e IA consomem dali.

**Cinco divergências entre a arquitetura-alvo e o que existe hoje — medidas em 2026-09-23.**
**O estado de cada uma mudou no mesmo dia; o texto abaixo é o diagnóstico original e o status
atual vem logo depois de cada item:**

1. **Não existe `cliente_sk`** (§6). A arquitetura pede uma chave técnica central que
   consolide ERP id, CRM id e Google Ads id num só cliente. Sem ela é que aparecem os
   **96 clientes de escopo e 1.303 contratos sem cadastro** e o casamento por nome que a
   casa já proíbe tratar como prova. **É a causa-raiz, não um sintoma.**
   → **FECHADA em 2026-09-23:** `rfn_cadastro__cliente_sk` (`query-4ZDe`) publicada e
   **materializada** com 1.353 cadastros.
2. **A Gold não é dimensional** (§8). A arquitetura pede `dim_*` e `fact_*`
   (`dim_cliente`, `dim_contrato`, `fact_faturamento`, `fact_custos`, `fact_horas`);
   as `rfn_*` de hoje são tabelas largas. Mudar o padrão é decisão de quem manda, não
   escolha técnica — **não mudar sem pedido explícito**.
   → **DECIDIDA em 2026-09-23:** "mantenha o padrão largo". Não é dívida, é escolha.
3. **Nenhuma tabela carrega classificação L1–L5** (§31). Contrato, custo e margem são
   **L3 Confidential**; CPF e telefone **L4**; senha e token **L5**. E o documento diz
   que **secret não deve estar no Data Lake** — o que condena diretamente
   `tbusuariointranet`, `tbportalusuarios` e `contazul_oauth_*`, já materializadas.
   → **CLASSIFICADA, NÃO APLICADA (2026-09-23):** as 4 tabelas do dia levaram o nível na
   descrição e o warehouse inteiro foi classificado num documento da camada semântica
   (`29eca9d5-010d-419b-8efa-eebbe8c81ba4`). **Continua sem RLS e sem CLS** — hoje é
   documentação, não controle.
4. **Não há Data Quality nem Quarantine** (§13, §14). Hoje o dado inválido entra na
   Trusted com uma flag; a arquitetura manda desviar para quarentena e alertar.
   → **PARCIAL em 2026-09-23:** `rfn_qualidade__regra` (`query-wD6c`) roda **27 regras**
   automáticas em 4 dimensões (14 na primeira versão + 13 da família VJOB, acrescentadas
   no mesmo dia, depois que a cadeia do VJOB real materializou às 14:28). **A quarentena NÃO foi feita**, e a razão está declarada na
   própria tabela: desviar exigiria reescrever as 78 transformações e a doutrina da casa é
   "marcar, nunca apagar".
5. **Não há `fact_custos` nem `fact_horas`** (§8). **É isso que bloqueia a margem.**
   → **FECHADA em 2026-09-23 por outro caminho:** `trs_financeiro__movimento` é o
   `fact_custos`, e a margem saiu **sem** `fact_horas` — o custo por peça substituiu o
   custo por hora a pedido ("esqueça as horas"). A cobertura saltou de 0,8% para 63,5%
   das peças.

**Consequência prática para a Refined de rentabilidade:** a arquitetura coloca `margem` em
`gold/financeiro/` (§7) e lista `fact_custos` entre os fatos esperados (§8). Medido em
2026-09-23, **não existe custo ligável ao VJOB**: o escopo conta peças e não horas, e o
`custo_hora` que existe está em `supabase_public_dim_colaborador` — 128 de 850 pessoas
(15%), do iClips, ligável ao VJOB só **por nome** (122 dos 166 marcadores casam, 55 com
custo). Sem hora gasta, custo/hora não multiplica nada. **Margem não se calcula com o que
há hoje; receita por entrega, sim.**

### A camada de identidade existe — `rfn_cadastro__cliente_sk`

**Publicada em 2026-09-23** (`query-4ZDe`, Refined / `cadastro`, **L2 INTERNAL**). É a
`cliente_sk` da §6 da arquitetura, e fecha a divergência nº 1 do ADR-0010.

**Grão: um cadastro por sistema.** `sistema`, `id_no_sistema` e `rotulo_na_origem` ficam
intactos na linha — o `cliente_sk` **agrupa, não apaga as partes**.

**1.353 cadastros → 843 identidades.** 1.137 com documento, 216 isolados,
**319 identidades em mais de um sistema** (máximo de 4). Inventário: VJOB 317/166/140 ·
iClips 408/349/349 · Conexa 133/128/113 · Financeiro 495 documentos. Cruzamento por
documento: VJOB × iClips **118**, VJOB × financeiro 123, iClips × financeiro 225,
iClips × Conexa 38.

**O QUE CONTA COMO DOCUMENTO — corrigido em 2026-09-23.** Até aqui **qualquer** cadeia de
dígitos formava sk por documento, e isso errava **nos dois sentidos**:

1. **Separava quem era a mesma PJ.** Quatro documentos do financeiro chegam com **13 dígitos**,
   porque o CNPJ foi guardado como número em algum ponto do caminho e **perdeu o zero à
   esquerda**. Os quatro, depois do `LPAD`, **existem na base na forma de 14 dígitos e com a
   mesma empresa nos dois lados** — INTELICOM, MERCANTIL NOVA ERA (que também é `NOVA ERA
   SUPER FRIOS` no iClips), RÁDIO TARUMÃ e SOCIEDADE FOGÁS (também no iClips e no VJOB).
   Cada um virava **duas** identidades.
2. **Fundia quem não tinha documento nenhum.** `MOVE RENTAL CARS` (VJOB 335 e 336) e
   `MOVE COMPANY LLC` (financeiro) carregam `87.176.853/4___-__` — **a máscara do formulário
   preenchida pela metade**, 9 dígitos. Não é CNPJ, é prefixo, e **agrupar por prefixo é o
   mesmo erro de agrupar por rótulo**. Os três passam a ISOLADO.

**O `LPAD` só vale quando o valor corrigido JÁ EXISTE** entre os documentos de 14 dígitos da
própria base — a autoridade é o conjunto de documentos válidos, **nunca a aritmética sozinha**.
Só é documento o que tem **14 dígitos (CNPJ) ou 11 (CPF)**; `documento_na_origem` preserva o
que veio, `flag_documento_repadronizado` e `flag_documento_invalido` marcam os casos, e o
fragmento reaparece em `candidato_sk_por_documento_parcial` — pista para revisão humana,
**fora do sk**, exatamente como `candidato_sk_por_nome`.

**A aritmética fecha:** eram 845 identidades, passaram a 843. Os 4 repadronizados deixam de ter
sk próprio e entram no da empresa que já existia (−4); os 3 do fragmento saem de um sk
compartilhado e viram três isolados (−1 +3). Por documento cai de 1.140 para 1.137, isolado
sobe de 213 para 216.

**O sk tem DOIS caminhos e só dois**, e `sk_metodo` diz qual valeu linha a linha:
- `DOCUMENTO` → `DOC:<dígitos do CNPJ>`. Mesmo documento = mesma PJ = mesmo sk.
- `ISOLADO_SEM_DOCUMENTO` → `<sistema>:<id>`. **Fica sozinho**, não é fundido com ninguém.

**NOME NÃO FORMA sk, nunca.** O casamento por rótulo sai como `candidato_sk_por_nome`
(88 candidatos, 2 ambíguos) — sugestão para revisão humana, **fora do sk**.

**A R-003 não conflita.** Ela proíbe fundir CONTAS por nome parecido; aqui nada se funde por
nome, e o que se agrupa é documento. O cadastro continua visível dentro do sk — quem quer a
conta lê a linha, quem quer a PJ agrupa pelo sk.

**O sk agrupa PJ, não marca:** o CNPJ `16.665.666/0001-07` (três marcas) vira um sk, e
Vanguarda Mídia Digital + VPromo viram um sk só. **Metade do VJOB (149 de 315) fica isolada**
por não ter documento — não é defeito da tabela, é o cadastro de origem.

**Não inclui conta de mídia:** Google Ads e Facebook Ads não carregam CNPJ nas dimensões.
Detalhe: `docs/nekt/refined-cadastro-cliente-sk.md`.

**O gargalo da margem mudou de lugar.** Era identidade **e** custo; agora é só custo — o
`custo_hora` do iClips já tem como chegar ao cliente certo pelo sk, mas continua não havendo
hora gasta por cliente no VJOB para multiplicar.

### Convenções operacionais

- **Fuso dos crons:** `America/Manaus` em todas as pipelines.
- **Nomenclatura Trusted:** `trs_<sistema>__<entidade>` (ex.: `trs_vjob__job`).
- **Nomenclatura Refined:** `rfn_<domínio>__<entidade>` (ex.: `rfn_midia__desempenho_diario`),
  folder = domínio de negócio. A descrição da transformação é parte da entrega: regras de
  negócio numeradas, bloco de limitações com "não contorne", e os números da validação com
  data. Inventário: `docs/nekt/refined-camada.md`.
- **Metadados de linhagem na Trusted:** `_extraido_at`, `_fonte`, `_payload_hash`.
- **Fuso na origem:** VJOB **e iClips** gravam hora local (`America/Sao_Paulo`) —
  nenhum dos dois precisa de conversão. De 2026-08-21 a 2026-09-15 esta linha dizia
  que "iClips devolve UTC"; **estava errado**, e o erro produziu seis tabelas Trusted
  com todos os horários 3 horas adiantados. Corrigido em 2026-09-16. O Facebook Ads,
  esse sim, entrega UTC e converte corretamente com `DATETIME(ts,'America/Sao_Paulo')`.
  Conferir a origem medindo, nunca herdando a suposição.
- **Nomenclatura de camada por plataforma:** minúsculas, underscore, sem hífen,
  com sufixo da plataforma — `<cliente>_<conta>_g_ads` para Google Ads,
  `<cliente>_<conta>_fb_ads` para Facebook Ads. Uma por fonte, conforme a R-001.
  O bloco `<conta>` só entra quando o cliente tem mais de uma conta na plataforma.
  Inventário e renomeações pendentes: `docs/nekt/camadas-google-ads.md`.

### Armadilhas conhecidas

- **`TIMESTAMP(dt, 'America/Sao_Paulo')` NÃO converte de UTC para São Paulo — ela faz o
  contrário.** A função recebe um relógio de parede (DATETIME) e o **interpreta como se
  já estivesse em SP**, devolvendo o instante absoluto correspondente. Sobre um dado que
  já é local, isso **soma** 3 horas. O mesmo vale para
  `TIMESTAMP(DATETIME(ts,'UTC'), 'America/Sao_Paulo')`, que é a mesma armadilha em dois
  passos e parece uma conversão honesta. Para converter um instante em hora local o certo
  é `DATETIME(ts, 'America/Sao_Paulo')` — é o que a família Facebook Ads sempre fez.
  Custou seis tabelas do iClips 3 horas adiantadas entre 21/08 e 15/09/2026
  (`query-9nws`, `8nEt`, `W3zE`, `vHzW`, `tF7c`, `hamR`), corrigidas em 2026-09-16.
  **O erro não aparece em contagem nem em unicidade** — só em comparação com uma
  referência externa ou no formato da jornada: com o defeito, a agência parecia trabalhar
  das 11h às 21h e almoçar às 15h.

- `supabase_bronze_vjob__tbjobs.projeto` **não** é FK de cliente, e no DERIVADO Supabase a
  tabela-pai de projetos não existe em nenhum stream — ali cliente só via `tbcronograma.cliente`
  ou `tbclientexservico.id_cliente`. **Isso vale só para o derivado:** a fonte `mysql-yIOn`
  (VJOB real) traz `tbclientes`, `tbcronograma`, `tbclientexservico` e mais 196 tabelas.
- `tbjobsgeral.id_setor` é constante `1` e não resolve contra `tbsetor`
  (que começa no id 11). Campo morto — não modelar como dimensão.
- **Google Ads: `ad_performance` não fecha com `campaign_performance`.** O Google
  não publica desempenho por anúncio em campanha `PERFORMANCE_MAX`. Trusted lida
  só sobre `ad_performance` perde esse investimento em silêncio — medido em
  2026-08-31: Move Rental Cars perdia US$ 1.347,11 de US$ 19.372,45 (7%, 18.072
  cliques) e Olá Casa Nova R$ 126,35. A Acesso Saúde não perdia nada, o que faz o
  erro passar despercebido em conta sem PMax. Solução aplicada na
  `trs_google_ads__insight_diario`: grão misto com coluna `grao` — linhas
  `ANUNCIO` de `ad_performance` mais linhas `CAMPANHA` de `campaign_performance`
  só para os pares (campanha, dia) ausentes. A ausência é sempre por campanha-dia
  inteiro, então a união é exata — **verificado nas 39 contas em 2026-09-01**: dos 42.758
  pares (campanha, dia) de `campaign_performance`, 9.607 (22,5%) não têm nenhuma linha de
  anúncio e **zero** têm cobertura parcial; zero anúncios órfãos; o total reproduz
  `campaign_performance` ao micro (1.354.538.045.829 dos dois lados). Se um dia aparecer
  par parcial, a premissa cai e a query precisa de resíduo por diferença, não por presença.
- **`NOT EXISTS` correlacionado sobre CTE de união grande não roda no BigQuery.**
  Falhou em 2026-09-02 na `trs_google_ads__insight_diario` com *"Correlated subqueries that
  reference other tables are not supported unless they can be de-correlated"*. Com 5 fontes
  passava; com 39 o otimizador desistiu. **O tamanho da união muda o que o motor aceita —
  query que valida em piloto pequeno pode quebrar ao escalar.** A forma que funciona é
  anti-join: `LEFT JOIN <chaves distintas> ... WHERE <chave> IS NULL`. O `DISTINCT` no lado
  direito é obrigatório, senão o join multiplica a linha da esquerda.
- **Tabela no catálogo não é tabela existente.** A Nekt cria a entrada no catálogo quando a
  fonte é configurada; a tabela só nasce na primeira execução que **escreve dado**. Uma
  referência a tabela catalogada mas não materializada derruba a query inteira, não só aquele
  ramo. Confirmado em 2026-09-02 com a `rd-station-socq`. Conferir materialização com um
  `COUNT(*)` antes de somar fonte nova a qualquer união.
- **O prefixo de tabela também não segue o nome da camada.** A camada
  `move_rental_cars_g_ads` guarda tabelas com prefixo `google_ads_move_rental`,
  sem o `_cars`. Pior caso confirmado, a Don Watches: a camada
  `don_watches_conta_1_g_ads` guarda a conta **2** (945-172-6644, fonte
  `google-ads-QuKh`) com prefixo `google_ads_don_watches_2`, e a camada
  `don_watches_conta_2` guarda a conta **1** (855-373-3895, fonte
  `google-ads-vE2C`) com prefixo `google_ads_watches_2` — os dois prefixos dizem
  "2". Descobrir o prefixo pelo catálogo e a conta pelo `resource_name`, nunca
  deduzir do nome.
- **Nome de camada e prefixo de tabela não identificam a conta Google Ads.**
  Casos confirmados de nome trocado: `don_watches_conta_1_g_ads` guarda a
  conta 2 e vice-versa; `braga_yamaha_consorcios` guarda a Braga Yamaha/Motos;
  `caa` guarda só a CAA Tintas. Sempre resolver a conta pelo `customer_id`
  extraído de `resource_name` (`customers/<id>/...`).
- `vanguardamartech_don_watches_conta_2` está vazia (0 linhas em todas as
  tabelas) porque a conta Don Watches 1 (`855-373-3895`) não tem atividade desde
  2023 — confirmado na API do Google Ads: R$ 0 de investimento, 0 impressões.
  A fonte `google-ads-vE2C` foi movida para execução semanal em 2026-08-31
  (era diária, consumindo ~30 créditos/mês para trazer zero linha).
- **Trocar credencial de fonte já publicada não passa pelo MCP.** O
  `get_setup_link` só aceita fonte em rascunho: *"Setup links can only be
  generated for draft sources."* Em fonte viva, credencial e `connector_config`
  se editam apenas na interface web da Nekt. Verificado em 2026-08-31 tentando
  gerar link para `semrush-OnLY`.
- `list_layers` do MCP devolve lista incompleta (20 camadas, omite as `_g_ads`).
  Para inventário completo, paginar `list_tables` e agrupar por `layer_id`.
  `INFORMATION_SCHEMA` não é alternativa: o nível de projeto está sem
  permissão e o por-dataset falha porque a Nekt encapsula em `EXPORT DATA`.
- **`status: idle` + `active: true` NÃO significam que a fonte funciona — no MCP.**
  Esses campos da API descrevem o deploy, não a execução: pelo MCP, uma fonte que
  falhou em 100% das tentativas é indistinguível de uma saudável. Só o histórico
  (`list_pipeline_runs` por slug) revela. **A interface web da Nekt, ao contrário,
  mostra um selo "Failed" por fonte** — ali a falha é visível, é a API que não a
  expõe. Ao diagnosticar via MCP, nunca concluir saúde por `status`/`active`.
  Complicando: `settings_max_consecutive_failures` (3 por padrão) faz a Nekt parar
  de executar depois de três falhas seguidas. O efeito no `active` é inconsistente:
  em 2026-08-31 as 3 fontes da Unipar estavam paradas há dois dias e ainda
  apareciam com `active: true`; em 2026-09-01, depois de mais uma falha, viraram
  `active: false` / `status: inactive`. Não dá para confiar no campo em nenhuma das
  direções. Medido em 2026-08-31: 12 das 93 fontes
  ativas nunca tiveram uma execução bem-sucedida, 7 delas criadas nos dois dias
  anteriores. **Fonte publicada não é fonte integrada — conferir a primeira
  execução antes de considerar pronta.**
- **`validate_source_connector_config`: o sinal confiável é a lista de streams, não o
  status.** Medido em 2026-09-01 na `semrush-OnLY`, cuja chave de API é rejeitada com
  `403 ERROR 120 :: WRONG KEY - ID PAIR` em toda extração: a validação retornou
  `status: "success"` e `streams: []`. **Validação boa traz os streams do conector;
  lista vazia significa que a credencial não funcionou.** O comportamento varia por
  conector — em 2026-09-03, com a senha do Postgres rejeitada, a `supabase-x0tz`
  devolveu `status: "failed"` corretamente (com `parsed_error: "Unknown Python
  exception."`, que não diz nada; o motivo real só aparece em
  `get_pipeline_run_logs`). Então: `failed` é conclusivo, `success` não é — nesse caso
  confira os streams. Vale como teste de credencial em fonte já publicada, ao
  contrário do `get_setup_link`.
- **Fonte que volta a funcionar não entra sozinha no Trusted.** As 3 fontes do Grupo
  Unipar voltaram a extrair com sucesso e ficaram **invisíveis no consumo** até 2026-09-17,
  porque a união da Trusted e a dimensão de contas tinham sido escritas quando elas estavam
  quebradas. R$ 95.097,20 de histórico parados na Raw, R$ 4.412,84/mês. **Ao destravar uma
  fonte, conferir todo lugar que enumera fontes** — união da Trusted, dimensão de contas,
  dimensão de campanhas. A lista não se atualiza sozinha.

- **Query grande demais é query que não se conserta.** As duas Trusted de Google Ads
  nomeavam as 26 colunas em cada ramo por fonte: 76 mil caracteres na `query-tL4g` e 45 mil
  na `query-zF8L`. `update_transformation` substitui o código inteiro, então somar 3 fontes
  exigia reescrever tudo sem errar um caractere — inviável, e foi o que manteve a Unipar
  fora por meses depois de o acesso ter sido resolvido. Corrigido em 2026-09-17: cada ramo
  virou `SELECT '<slug>' _fonte, * FROM <tabela>` e as colunas são nomeadas **uma vez** numa
  CTE seguinte. Caíram para 26 mil e 15 mil. **O custo é real e está declarado nas
  descrições:** o `*` depende de esquema idêntico entre as contas, então divergência numa
  conta passa a quebrar a união inteira em vez de só aquele ramo. **Ao somar fonte nova,
  rodar `SELECT f FROM (<união>) LIMIT 0` antes de publicar** — falha no plano, sem custo de
  leitura. Alerta de falha ligado nas duas.

- **Validar a conta contra a API não valida a credencial da Nekt.** As 3 fontes do
  Grupo Unipar (`google-ads-3eFc`, `mvUx`, `hBlk`) foram validadas contra a API do
  Google Ads na integração e por meses deram `USER_PERMISSION_DENIED` na extração
  (resolvido antes de 2026-09-13):
  as contas pendem do MCC do cliente (7749545148), não do MCC da Vanguarda
  (1704439246), e a conta Google do OAuth da Nekt não tem acesso a ele. A validação
  na integração usou outra credencial. Ao integrar conta de MCC de terceiro,
  confirmar o acesso **com a credencial que a Nekt usa**, não com outra.
- **Fontes Supabase espelham os schemas internos do Postgres/Supabase**
  (`auth`, `vault`, `storage`, `realtime`, `extensions`, `cron`,
  `information_schema`), e o padrão da Nekt é trazer tudo habilitado. Em
  2026-08-31 a `supabase-fEvu` tinha 109 streams habilitados e **apenas um** era
  dado de negócio (`public-app_meta`).
  Isso não é só ruído: o schema `auth` traz `refresh_tokens`, `sessions`,
  `mfa_factors` e `webauthn_credentials` — credenciais. Medido em 2026-08-31 na
  `supabase-x0tz`: 34 refresh tokens, 20 usuários e 9 sessões materializados no
  warehouse. Streams `auth` e `vault` desabilitados nas duas fontes nessa data;
  as tabelas já materializadas **continuam existindo** (desabilitar não apaga) e
  a exclusão é backoffice. Sobraram habilitados 82 streams de `information_schema`,
  `storage`, `realtime`, `extensions` e `cron` — ruído, sem risco.
  Ao conectar Supabase novo, desabilitar esses schemas antes do primeiro run.

- **RD Station: a origem de tráfego vem em cinco formatos no mesmo campo.**
  `fonte_trafego_bruta` mistura, medido em 2026-09-03 sobre 17.602 conversões:
  `encoded_<base64>` (4.995, um JSON com a sessão de origem dentro), query string
  `utm_source=...` (1.400), texto livre (~4.200, ~990 grafias — `FACEBOOK` e `Facebook`
  convivem), URL ou `android-app://<pacote>` (~660) e vazio (8.354). Dentro do blob base64 a
  origem está em `first_session.value` e ainda vem em três dialetos: UTM, o cookie `__utmz`
  legado do Analytics (`utmcsr=`/`utmcmd=`/`utmccn=`, separado por `|`) e URL crua.
  **Ler só `utm_source` dá 1.400 linhas com um único valor distinto** e a falsa impressão de
  que não há origem. Tratado na `rfn_marketing__conversao`. Decodificar percent-encoding
  trocando `%XX` por caractere um a um corrompe acento — o jeito certo é montar a cadeia de
  bytes em hexadecimal e converter para texto uma vez no fim.
- **`gad_campaignid` é a chave de funil, e é a única honesta.** O auto-tagging do Google Ads
  deixa `gad_source` e `gad_campaignid` na origem de tráfego do RD, e `gad_campaignid` **é** o
  `id_campanha` do Google Ads — junção exata por id, que resolve o cliente de graça
  (campanha → `id_conta` → `cliente`). Medido em 2026-09-03: 1.083 conversões carregam o
  parâmetro, 38 das 57 campanhas casam na Trusted, cobrindo 908 conversões (5,2%).
  **Cobertura baixa é o número certo.** Casar por nome de cliente não é alternativa: dos 39
  rótulos do Google Ads e 29 do RD, só 8 batem exatamente, e os quase-pares incluem os casos
  3-para-1 do PMZ e 2-para-1 da Don Watches, que a R-003 proíbe fundir.

- **Pooler do Supabase: o usuário precisa carregar o identificador do projeto.** No
  host compartilhado `aws-<n>-<região>.pooler.supabase.com` o Supavisor não descobre
  qual projeto é o alvo pelo hostname, então o usuário tem de ser
  `postgres.<project_ref>`, não `postgres`. Usuário sem o sufixo dá
  `FATAL: (ENOIDENTIFIER) no tenant identifier provided (external_id or sni_hostname
  required)` — que é erro de **roteamento**, não de senha. Confusão fácil porque o
  Supavisor reporta o erro de senha também como `user "postgres"`, sem o sufixo:
  `password authentication failed for user "postgres"` significa que o tenant FOI
  resolvido e a senha é que foi rejeitada. Distinguir os dois evita trocar a senha
  quando o problema é o usuário, e vice-versa. Visto em 2026-09-03 na `supabase-x0tz`.

- **Existem DUAS `trs_projetos__projeto`, e a do nome da camada é a morta.** A de
  `vanguardamartech_gestao_de_projetos_do_iclips` tem 98 projetos e última carga em
  **21/08/2026**; a de `vanguardamartech_trusted` tem 106 e carga de **18/09/2026**. Quem
  resolve a tabela pelo nome da camada pega dado de um mês atrás, sem nenhum sinal de erro.
  Descoberto em 2026-09-18 montando a `trs_pi__insercao`. Conferir `MAX(_extraido_at)` antes
  de apontar query nova para tabela homônima.

- **PI não vem do iClips na Nekt — vem do Supabase, e a ponte é o `numero_projeto`.**
  Verificado em 2026-09-18: a fonte `rest-api-73hk` tem 14 streams, **todos de projeto**
  (`idProjeto, nomeProjeto, statusProjeto, verba, datas, responsaveis, cliente, grupoCliente,
  pecas, tarefas`) — nenhum de PI. Toda informação de PI entra pela `supabase-x0tz`, em seis
  tabelas: três no grão PI (`silver_pi_insercao` 3.348, `gold_vw_pi_monitoramento` 3.063,
  `gold_vw_pi_ca_evento` 3.063, **zero órfãos, 1:1**) e três agregadas
  (`gold_mvw_bv_pi_cliente`, `gold_mvw_dre_cliente_pi`, `gold_vw_fin_reconcile_dre_cliente_pi`).
  O `numero_projeto` do PI **é** o `idProjeto` do iClips — confirmado porque o nome do projeto
  bate caractere a caractere, inclusive espaço duplo e espaço final. Consolidadas na
  `trs_pi__insercao` (`query-iX2P`).

- **PI cancelado carrega valor e ninguém avisa.** 228 PIs cancelados, 223 com valor > 0,
  somando **R$ 2.087.562,09 de R$ 47.083.182,87 (4,4%)**. Somar `valor_negociado` sem filtrar
  `is_cancelado` infla o faturamento em dois milhões. Medido em 2026-09-18. O monitoramento
  financeiro do Supabase já exclui cancelado — por isso os 228 estão entre os 285 PIs sem
  acompanhamento.

- **`TIMESTAMP` que é data disfarçada: a armadilha do fuso invertida.** Em
  `supabase_silver_pi_insercao`, `data_aprovacao_proposta` é TIMESTAMP mas **zero** das 3.348
  linhas tem hora ≠ 00:00:00 — é data guardada como instante. `DATE(ts)` sem argumento lê em
  UTC e devolve o dia certo; **`DATE(ts,'America/Sao_Paulo')` jogaria 1.968 aprovações um dia
  para trás**, porque meia-noite UTC é 21h do dia anterior em SP. Na mesma família,
  `dt_nf_fornecedor` tem zero linhas com hora (é data) e `dt_nf_agencia` tem **301** (é
  instante de verdade) — a mesma tabela mistura os dois casos. Medir coluna a coluna, nunca
  aplicar fuso por família.

- **Um espaço no rótulo tira R$ 363 mil do acompanhamento financeiro.** A
  `supabase_gold_vw_pi_monitoramento` filtra por **lista fixa de `tipo_midia`**, e o sintoma
  que denuncia o mecanismo é este: `Frontlight` tem 4 PIs e **100%** de cobertura,
  `Front Light` tem 3 e **zero**. Sete tipos ficam de fora inteiros — `Internet`, `Dooh`,
  `Shopping`, `Front Light`, `Ação`, `Jornal`, `Mega Banner` — somando **50 PIs e
  R$ 363.435,67**. Medido em 2026-09-18 ao explicar os 57 PIs não cancelados sem
  acompanhamento (os outros 7: 5 de `CLIENTE TESTE`/`VBOT`, 2 de `Mobilário Urbano` sem data).
  **Ao derivar cobertura, calcule da própria tabela** (`LOGICAL_OR(tem_acompanhamento)` por
  rótulo cru), nunca repita a lista fixa — e nunca normalize a grafia antes de medir, porque
  a normalização apaga o único sintoma visível. Feito assim na `rfn_midia_off__pi`.

- **No financeiro, a empresa entra pela RAZÃO SOCIAL — filtrar por nome erra as duas pontas.**
  Em `supabase_gold_mvw_fin_cliente` a Vanguarda Comunicação aparece como
  `B. R. M. COSTA DE LIMA E CIA SOCIEDADE SIMPLES PURA`. Medido em 2026-09-21: um filtro
  `cliente_nome LIKE '%VANGUARDA%'` traz **R$ 40.067,03 que são de OUTRA empresa** (Vanguarda
  Mídia Digital) e **perde os R$ 47.544,32** que eram o alvo. Errar por excesso e por falta na
  mesma consulta. A chave é `cliente_doc`, sempre.

- **As quatro empresas do grupo têm CNPJ próprio e NÃO se fundem pelo nome.**
  Vanguarda Comunicação `07.865.616/0001-74` (controladora) · Vanguarda Mídia Digital **e**
  VPromo, os dois sob `26.123.250/0001-02` (mesma PJ, dois cadastros no iClips: 1511 e 3893) ·
  VBOT `61.077.352/0001-30` (dois cadastros no iClips: 3552 e 3894). Tabelas do par intragrupo:
  `rfn_cadastro__cliente_vbot` (`query-NxG1`) e `rfn_cadastro__cliente_vanguarda_comunicacao`
  (`query-hH5g`).
  **Dois nomes enganam e são CLIENTE REAL:** `VANGUARDA INTERNACIONAL` (`59.772.810/0001-09`,
  iClips 3531, 3 projetos LAVENDER e 21 atividades em 6 departamentos, sem lançamento no
  financeiro) e `PARA GUARDAR` (`16.665.666/0001-07`, iClips 1683/2842/2843, 29 projetos).
  Classificar intragrupo por nome quebra os dois.
  **O CNPJ 16.665.666/0001-07 carrega TRÊS marcas** — `PARA GUARDAR`, `HAYA SOLAR` e
  `PARA CHEGAR` — e no financeiro entra pela razão social `EF LOCAÇÃO DE IMÓVEIS PRÓPRIOS
  LTDA.`, que não contém nenhuma das três (R$ 16.196,00 em 6 lançamentos). Mesmo mecanismo da
  Vanguarda Comunicação, em cliente de terceiro.

- **Cadastro de teste com CNPJ de verdade passa por cliente.** `CLIENTE TESTE` tem CNPJ
  `62.361.814/0001-09`; `CADASTRO TESTE MESMO CNPJ` (Conexa 96) divide o CNPJ da Vanguarda
  Comunicação com o cadastro legítimo (Conexa 74) e os dois estão `is_ativo = true`, contando na
  base de 122 clientes da VBOT; `TESTE HUGO SENNA` (VJOB `id_cliente` 146) tem 1.163 escopos em 20 serviços com
  `cliente_ativo = true` e `cliente_resolvido = true`. Nenhum se detecta por ausência de
  documento nem por flag de inativo — só por lista de ids. Marcar, nunca apagar: fundir esconde
  que existem, descartar esconde que contam.
  **`TESTE HUGO SENNA` NÃO É ARTEFATO DE TESTE** — apesar do nome. Corrigido em 2026-09-21
  depois de levantar o conteúdo: é **escopo completo de agência**, mensal, em 20 serviços
  (CARDS 320, BLOGS 102, E-MAIL MKT 102, REELS 100, relatórios, PI, visita ao cliente…),
  e **pessoas reais trabalharam nele** — 76% de conclusão em 2024, com 10 pessoas distintas
  marcando. A conclusão parou em **novembro/2024** e é zero em todos os 23 meses seguintes,
  enquanto o escopo continuou sendo gerado (878 escopos em 2025-2026). Não existe cliente
  Hugo Senna em nenhuma outra base (busca por "SENNA" em `rfn_cadastro__cliente`,
  `dim_cliente_vbot` e `gold_mvw_fin_cliente` dá zero), então o mais provável é escopo
  recorrente que ficou ligado depois de a operação acabar. **Classificá-lo como teste pelo
  nome foi erro meu, duas vezes no mesmo dia.** Ele segue fora das duas tabelas intragrupo,
  mas por não ter identidade resolvida — não por ser teste. Detalhe:
  `docs/nekt/vjob-escopo-sem-conclusao-2026-09-21.md`.

- **`silver_vjob_escopo` NÃO tem CNPJ, então nada nela se liga a documento por prova.** A
  tabela-pai de cliente do VJOB não existe no catálogo; o que há é `id_cliente` + um
  `cliente_nome` já resolvido no silver. Ligar um `id_cliente` do VJOB a um CNPJ do iClips é
  casamento **por nome**, não por documento — e é permitido apenas como hipótese declarada.
  Caso concreto: `PARA GUARDAR SELF STORAGE` (VJOB 74, 1.493 escopos) e `PARA GUARDAR`
  (iClips 1683, CNPJ 16.665.666/0001-07) só se ligam pelo nome. Escrito como se fosse provado
  em 2026-09-21 e corrigido no mesmo dia.

- **A coluna `empresa` de `gold_mvw_fin_cliente` é o separador de operação.** Valores medidos:
  `BRM` (Vanguarda Comunicação), `VD` e `VBOT`. É por ela que se separa quem faturou, não pelo
  nome do cliente. E `tipo_receita` distingue `CLIENTE` de `CONTA_ORDEM` — repasse por conta e
  ordem não é receita da casa.

- **Dinheiro visto duas vezes: Conexa e financeiro se sobrepõem.** A cobrança de R$ 5,00 da
  Vanguarda Comunicação aparece em `vw_faturamento_vbot` (Conexa 74) **e** em
  `gold_mvw_fin_cliente` como `empresa = 'VBOT'`, `linha_servico = 'Saas'`. Somar as duas
  fontes duplica. Medido em 2026-09-21.

- **`DATE(MAX(ano), MAX(mes), 1)` inventa mês que não existe.** Ela combina o ano máximo com o
  mês máximo **independentemente**. Medido em 2026-09-21 em `supabase_gold_mvw_fin_cliente` no
  CNPJ `26.123.250/0001-02`: devolvia `2025-12-01` quando o último lançamento é `2025-03-01` —
  **9 meses de erro**. No CNPJ vizinho os dois coincidiam por sorte, que é o que torna o defeito
  difícil de ver. A forma certa é `MAX(DATE(ano, mes, 1))`. Vale para qualquer par ano/mês
  guardado em colunas separadas.

- **ATENÇÃO AO SUJEITO: o que as fontes Supabase chamam de VJOB é um DERIVADO FINANCEIRO
  TRATADO, não o sistema.** Corrigido em 2026-09-21 a pedido: `supabase-fEvu`, `supabase-3gKz` e
  as tabelas `supabase_bronze_vjob__*` / `supabase_silver_vjob_*` carregam informação financeira
  **já tratada e empurrada** para a plataforma. **O VJOB completo está em `mysql-yIOn`**
  (banco MySQL `vjob_2024`, camada `vanguardamartech_vjob_real_mysql`, 199 tabelas), conectado
  em 2026-09-21 16:28. Toda medição abaixo que diga "o VJOB" e tenha sido feita sobre tabela
  `supabase_*` fala do derivado, **não** do sistema — os números continuam certos sobre o
  derivado e a conclusão sobre o VJOB está **pendente de remedição** contra a fonte nova.
  **A tabela-pai de cliente do VJOB EXISTE:** `tbclientes`, no MySQL. Até 2026-09-21 este
  arquivo afirmava que ela não existia em nenhum stream e que os 339 ids eram "números sem
  nome, sem CNPJ e sem ponte para lugar nenhum" — era verdade sobre o Supabase e falso sobre o
  sistema.

- **Os dois módulos em estados opostos — medido no DERIVADO Supabase, não no VJOB.** Medido em
  2026-09-21, com as duas fontes (`supabase-x0tz` e `supabase-fEvu`) tendo rodado com sucesso
  no mesmo dia, então a extração está sã e o que segue é conteúdo da origem:
  - **Módulo de JOB (tarefas) — parado NESTAS TABELAS, não no sistema.** Corrigido em
    2026-09-24: o trabalho continuou em `tarefas_tbjobs` (1.329, último cadastro
    **23/09/2026**) e `advisory_tbjobs` (256). Ver a seção "o módulo de JOB do VJOB
    não parou: MUDOU DE TABELA". O que segue vale só para `tbjobs`/`tbjobsgeral`.
    `tbjobs` (1.354 jobs): último cadastro
    **24/08/2026 14:15:59**, última checagem e aprovação **02/09/2026 14:26:33**.
    `tbjobsgeral` (160): último cadastro **05/06/2026**, última aprovação **23/06/2026** —
    parada há mais de três meses.
  - **Módulo de ESCOPO (planejamento mensal) — vivo.** Último escopo cadastrado
    **11/09/2026 18:11:09**. Setembro/2026 tem 12.041 escopos com 2.087 concluídos em 65
    clientes; outubro (em curso) tem 11.581. Há escopo cadastrado até **02/09/2027**.

  **Portanto a última atividade registrada do VJOB é 11/09/2026 18:11:09**, não 24/08. Concluir
  que a base toda congelou em agosto por causa do `tbjobs` subestima o escopo em ~12 mil linhas
  por mês. Dizer qual módulo se está olhando é obrigatório.

  **Ressalva de medição:** a tabela de escopo **não carimba quando a conclusão foi marcada** —
  só `datacadastro` (criação da linha) e `datafinal` (prazo). Os 2.087 concluídos de setembro
  não datam a ação. Os únicos eventos dateáveis são os dois acima.

  **Tendência visível:** clientes com conclusão caem de 83 (06/2026) para 74 (08) e 65 (09) —
  consistente com os 86 clientes de conclusão zero da armadilha seguinte.

- **Metade do escopo do DERIVADO Supabase não tem conclusão registrada — a taxa agregada não
  serve como indicador.** Sujeito corrigido em 2026-09-21: é o derivado, não o VJOB. Medido sobre `supabase_silver_vjob_escopo`,
  janela 2025-2026: dos 251 clientes com escopo, **86 têm ZERO conclusão**, e eles carregam
  **71.210 dos 146.336 escopos (48,7%)**. Entre eles há cliente grande e vivo — Revemar
  Amazonas (2.199 escopos), Braga Veículos Pós Venda (1.974), Doctor Mais Saúde (1.704),
  Tropical Atacadão (1.568), CAA Tintas (1.433).
  **Não é a base que parou:** ela concluiu 20.120 escopos em 2025 e 18.840 em 2026. O que houve
  foi o volume planejado triplicar (29,5 mil em 2024 → 83,4 mil em 2026) e a taxa cair de 62,5%
  para 22,6%. E a mecânica funciona onde alguém registra: a VBOT mantém **86%** de conclusão na
  mesma janela e na mesma tabela.
  **Duas causas, indistinguíveis no dado:** (A) o trabalho existe e o registro não — 14 dos 86
  casam por rótulo com cliente que tem PI desde 2025, somando 12.217 escopos; (B) o escopo
  recorrente ficou ligado depois de a operação acabar — caso do `TESTE HUGO SENNA`, sem rastro
  em nenhum outro sistema. Para 49 deles não há evidência em direção nenhuma.
  **Na prática:** zero conclusão com centenas de escopos planejados **não é "100% de atraso"**,
  é ausência de registro — por cliente, conferir primeiro se existe QUALQUER conclusão na
  janela. `cliente_ativo` não separa (38 dos 86 estão marcados ativos), 23 dos 86 têm
  `cliente_nome` **vazio**, e a base tem **escopo futuro** (o cadastro 404 vai até 01/2027), então
  contagem sem recorte de janela soma mês que não aconteceu. Isto estende ao lado da conclusão
  o mesmo problema que a casa já declarou no contador de atraso.
  Detalhe: `docs/nekt/vjob-escopo-sem-conclusao-2026-09-21.md`.

- **`mysql-yIOn` (VJOB real) trouxe 199 streams, TODOS habilitados — e 23 são descarte.**
  Conectada em 2026-09-21 16:28, banco `vjob_2024`, camada `vanguardamartech_vjob_real_mysql`,
  todos FULL_SYNC, 196 com chave primária. É o mesmo padrão de sobre-coleta já registrado nas
  fontes Supabase.
  **23 streams de descarte:** backups (`tbarquivosauditoria_bkp_20260120`,
  `tbauditoriaclientes_bkp_20260120`, `tbescopofinal_backup_202505`,
  `backup_tbcronogramadatas_nfse_20260909`), lixeiras (`deleted_tbcronograma`,
  `deleted_tbcronogramadatas`, `deleted_tbcronogramadatas_individual`, `tbexcluidos`,
  `tbexcluidos2`), teste (`tbescopofinalteste`, `__tbjobs__`) e 12 duplicatas com sufixo `2`/`3`
  (`acessos2`, `tbatividades2`, `tbetapas2`, `tblinks2`, `tblinks3`, `tbonboardingclientes2`…).
  **12 streams carregam acesso ou credencial:** `usuario`, `tbusuariointranet`,
  `tbportalusuarios`, `tbclientes_acessos`, `acessos`, `acessos2`, `tbpermissoes`,
  `tarefas_tb_acl_cliente_usuario`, **`tarefas_tbjobs_aprovacao_inicial_tokens`**,
  `ia_usuario_cliente`, `tbportaldocumentos`, `tbportalnotificacoes`. Mesma classe de risco do
  schema `auth` do Supabase, onde 34 refresh tokens, 20 usuários e 9 sessões chegaram a
  materializar no warehouse.
  **A janela para decidir é ANTES da primeira carga:** desabilitar stream **não apaga** tabela
  já materializada, e a exclusão é backoffice. Em 2026-09-21 17:00 a primeira execução ainda
  estava rodando e nenhuma tabela havia materializado (`tbclientes` respondia
  `table_not_materialized`).
  **Achado a investigar quando materializar:** o módulo `ia_*` (8 tabelas) tem
  `ia_cliente_config` e `ia_cliente_documentos` — candidatos a já serem o repositório de
  contexto por cliente que a arquitetura de `docs/nekt/contexto-cliente-arquitetura.md` presume
  não existir.

- **O VJOB real MATERIALIZOU, e derruba duas coisas que este arquivo dizia.** A `mysql-yIOn`
  rodou uma vez, 21/09/2026 16:34→17:38, sucesso. Prefixo de tabela: **`mysql_vjob` colado ao
  nome do stream**, que já inclui o banco — `tbclientes` é
  `vanguardamartech_vjob_real_mysql.mysql_vjobvjob_2024_tbclientes`. Terceiro caso da armadilha
  de prefixo (Google Ads, Linear, agora MySQL): nunca deduzir, sempre achar pelo catálogo ou
  pelo `get_relevant_tables_ddl`.

  **1. A tabela de escopo CARIMBA a conclusão — no sistema.** `tbescopofinal` (195.163 linhas)
  tem `datahoramarcado`, preenchida em **57.163 linhas**, a mais recente **21/09/2026 16:21:12**.
  Até 21/09 este arquivo dizia que "a tabela de escopo não carimba quando a conclusão foi
  marcada" e que "os 2.087 concluídos de setembro não datam a ação" — **era verdade sobre o
  derivado Supabase e é falso sobre o VJOB**. O derivado perdeu a coluna no caminho.

  **2. A tendência de queda era artefato do derivado.** Medido no sistema, por mês em que a
  marcação REALMENTE aconteceu: 05/2026 1.897 marcações / 90 clientes / 36 pessoas · 06 2.368 /
  85 / 28 · 07 2.807 / 80 / 31 · 08 2.696 / 73 / 35 · **09 (até o dia 21) 4.632 / 91 / 56**.
  Setembro é o **maior mês da série** e ainda não tinha fechado. Em 21/09 este arquivo relatava
  o contrário — "clientes com conclusão caem de 83 (06) para 74 (08) e 65 (09)" — porque sem a
  coluna de marcação só dava para contar pelo mês de CADASTRO do escopo. **Contar conclusão pelo
  mês de cadastro inverte o sinal.** Toda conclusão sobre produtividade tirada do derivado está
  pendente de remedição contra `tbescopofinal`.

  **3. `tbclientes` existe e tem CNPJ, mas cobre metade.** 315 clientes, **166 com CNPJ** (53%),
  **140 CNPJs distintos** (então há CNPJ repetido entre cadastros), 21 com CPF, 130 com
  `status = 1`. A ponte por documento entre VJOB e iClips/financeiro **existe e é parcial** —
  para os 149 sem documento continua valendo o que a armadilha do `silver_vjob_escopo` diz:
  ligação por nome é hipótese declarada, não prova.

- **A janela dos streams sensíveis do VJOB FECHOU — está tudo materializado.** Em 21/09 este
  arquivo dizia "a janela para decidir é ANTES da primeira carga". A carga terminou às 17:38
  daquele dia. Confirmado no catálogo em 23/09, com linha e coluna:
  `tbusuariointranet` **272 linhas** com `senha`, `cpf`, `rg`, `nascimento`, `endereco`, `cep`,
  `data_admissao`, `data_demissao`, `matricula`, `beneficio` — prontuário de RH inteiro ·
  `tbportalusuarios` **72 linhas** com `senha_hash` · `contazul_oauth_conexoes` **1 linha** com
  `access_token_criptografado` e `refresh_token_criptografado` · `contazul_oauth_config`
  **1 linha** com `client_secret_criptografado` · `tarefas_tb_acl_cliente_usuario` **477
  linhas** · `tbclientes` com `cpf` do responsável em 21 linhas.
  Desabilitar stream **não apaga** — é o mesmo caminho das tabelas `auth_*` do Supabase, que
  seguem no Raw desde 31/08. Decisão de exclusão é backoffice e é dela.

- **O repositório de contexto por cliente JÁ EXISTE no VJOB.** `ia_cliente_documentos` 21 linhas
  com `conteudo_extraido` (53 KB de texto já extraído), `ia_cliente_config`, e `ia_solicitacoes`
  86 linhas / 1,8 MB com `briefing`, `publico`, `objetivo`, `tipo_peca` e `prompt_final`.
  A arquitetura de `docs/nekt/contexto-cliente-arquitetura.md` foi escrita presumindo que não
  existia lugar onde a casa autora conteúdo de marca. Existe — e a decisão sobre onde autorar
  (seção 6 do documento) tem agora uma quarta opção, que é usar o que já está em uso.

- **Trusted do VJOB real publicada em 2026-09-23** — `trs_vjob__cliente` (`query-MZdN`,
  315 linhas) e `trs_vjob__escopo` (`query-Ty76`, 195.163), encadeadas por evento: a
  segunda dispara **na primeira**, não na fonte. A cadeia anda **semanal**, porque a
  `mysql-yIOn` roda domingo 00:00 `America/Manaus`.
  Detalhe: `docs/nekt/trusted-vjob-real.md`.

- **O fuso do VJOB foi MEDIDO na fonte nova, não herdado — e confirma o local.** A
  convenção "VJOB grava hora local" tinha sido estabelecida sobre o derivado. Verificado
  em 2026-09-23 por dois caminhos: (a) o mesmo registro carrega o relógio **idêntico** no
  MySQL e no payload bronze do Supabase (`tbjobs` 1461 = `2026-08-24 11:15:59` nos dois);
  (b) a distribuição horária das 57.163 marcações de escopo tem pico às 12h (9.566),
  **queda às 13-14h** (1.982 e 1.711) e retomada às 15-19h — o almoço da casa; em UTC esse
  almoço cairia às 10-11h, que não é almoço de ninguém. Portanto **`DATETIME(ts)` sem
  argumento de fuso**; aplicar `'America/Sao_Paulo'` subtrairia 3 horas de dado já local.

- **CORREÇÃO: dois números de `tbjobs` que este arquivo registrou em 21/09 estavam +3h.**
  O último cadastro é **24/08/2026 11:15:59** e a última checagem/aprovação é
  **02/09/2026 11:26:33** — não 14:15:59 e 14:26:33. Medi o derivado aplicando
  `TIMESTAMP(dt,'America/Sao_Paulo')` sobre um valor que já era local, que é exatamente a
  armadilha descrita no topo deste arquivo. Os números de escopo daquele dia
  (11/09 18:11:09) estavam certos, porque vieram por outro caminho.

- **96 dos 251 clientes do escopo do VJOB (38%) NÃO têm cadastro em `tbclientes`**, e eles
  carregam **44.356 escopos (23% da base), dos quais 19.416 concluídos**. Não é falha de
  extração — as duas tabelas vieram da mesma carga, no mesmo minuto. É a origem que tem
  escopo apontando para cadastro que não existe mais.
  **A hipótese óbvia foi testada e descartada:** contra os nomes já resolvidos no derivado,
  `tbclientes` bate em **155 de 156** e `tbclientesatedimentos` bate em **ZERO** — o
  `id_cliente` do escopo não aponta para a tabela de atendimentos.
  `flag_cliente_nao_catalogado` acende nessas linhas e o join é LEFT: com INNER, um quarto
  da base sumiria sem sinal. Isso também explica os "23 dos 86 com `cliente_nome` vazio"
  registrados em 21/09 — é o mesmo buraco, visto pelo derivado.

- **16% das conclusões do VJOB não datam a ação.** Dos 68.016 escopos com `status = 1`,
  **57.090 têm `datahoramarcado` e 10.926 não**. Qualquer série temporal de conclusão cobre
  **84%** das conclusões — a cobertura vai junto com o número. Mais 73 linhas têm carimbo e
  `status = 0` (marcado e desmarcado). E o derivado marca **82 linhas** como concluídas que
  o sistema marca `status = 0`, com `status2..status7` todos nulos: a divergência não se
  explica por coluna nenhuma, e o sistema é a fonte de verdade.

- **O escopo do VJOB não tem nome de serviço, e o derivado também não fecha.** `id_servico`
  tem 38 valores; a tabela de domínio **não foi localizada no catálogo** em 2026-09-23
  (`tbservico` e `tbservicos` não existem). O derivado resolve 34 dos 38 e deixa 4 como
  "(outro)" — ids 10, 17, 19 e 27, somando **7.980 escopos**. Maiores por volume: CARDS
  71.195 · REELS 15.398 · STORIES 13.370 · E-MAIL MKT 11.512 · BLOGS 9.575.

- **A `trs_vjob__job` foi REESCRITA sobre o sistema em 2026-09-23 — e estava 3 horas
  adiantada, 100% das linhas.** Ela lia o DERIVADO Supabase e usava
  `TIMESTAMP(PARSE_DATETIME(...), 'America/Sao_Paulo')` sobre um relógio que já era local.
  Medido contra o MySQL: **1.354 de 1.354 registros com `data_cadastro` exatamente +3h,
  ZERO iguais**; `checado_em` +3h em 1.051 e `aprovado_em` em 1.340. **É a sétima tabela com
  a armadilha — as seis do iClips foram corrigidas em 16/09 e esta passou.** A
  `rfn_operacao__job` (`query-wpYP`) herdava o deslocamento e passa a ler certo sozinha,
  porque a Trusted manteve nome, colunas e tipos.
  **A ironia está na descrição antiga**, que dizia a coisa certa — "a intranet grava hora
  local" — e usava a função errada. Agora as colunas vêm TIMESTAMP direto do MySQL e **nada
  se converte**.
  **O volume bate exatamente:** 1.354 `tbjobs` + 160 `tbjobsgeral` = **1.514**, o mesmo que o
  derivado entregava — então a troca de sujeito é verificável, não uma aposta.
  **`id_job` sozinho NÃO é chave:** 147 ids aparecem nas duas tabelas de origem. A chave é
  `(origem, id_job)`, agora explícita em `id_job_unico`.
  **182 jobs carregam `public_token`** — token de acesso público ao job, no sistema. Não é
  emitido na Trusted (§31: secret é L5 e não deve estar no Data Lake), junto com
  `public_enabled`, `public_generated_at` e `public_expires_at`.
  Gatilho trocado para evento em `query-MZdN`, entrando na cadeia semanal do VJOB real, e
  **alerta de falha ligado** (estava desligado).

- **`ia_cliente_config` é a estrutura de contexto de marca que a arquitetura presumia não
  existir.** Colunas medidas em 2026-09-23: `nome_exibicao`, `gpt_referencia_url`,
  `instrucoes`, **`biblia_resumo`**, **`tom_voz`**, `palavras_evitar`,
  **`regras_inegociaveis`**, **`fatos_verificados`**, **`elementos_visuais`**.
  Preenchida para **3 clientes**. A seção 6 de `docs/nekt/contexto-cliente-arquitetura.md`
  pergunta onde a casa autora conteúdo de marca — a resposta já está no VJOB, em uso.

- **O `Number of rows` do DDL do catálogo da Nekt é METADADO ANTIGO, não contagem.** Dois
  casos medidos em 2026-09-23: o DDL dizia `github_commits` = 710 quando a tabela tinha
  **790**, e `supabase_silver_vjob_escopo` = 183.455 quando ela tem **195.163**. O segundo me
  fez publicar, na descrição da `trs_vjob__escopo`, que o derivado tinha "11.708 linhas a
  menos" que o sistema — **não tem, tem exatamente as mesmas 195.163**. Corrigido no mesmo dia.
  **Contar com `COUNT(*)` antes de comparar volume entre duas tabelas**; o número do DDL serve
  para escolher tabela, nunca para afirmar diferença.

- **A cadeia do VJOB vai da fonte ao consumo, encadeada por evento e semanal:**
  `mysql-yIOn` (domingo 00h) → `query-MZdN` (`trs_vjob__cliente`, 315) → `query-Ty76`
  (`trs_vjob__escopo`, 195.163) → `query-lCot` (`trs_vjob__servico`, 38) → `query-V3c3`
  (`rfn_operacao__escopo_mensal`, 70.963). Cada elo dispara no anterior, não na fonte — quando
  o último roda, os três de cima já materializaram. Detalhe:
  `docs/nekt/refined-operacao-escopo.md`.

- **A tabela de domínio de serviços do VJOB EXISTE e está VAZIA.** É
  `mysql_vjobvjob_2024_tb_servicos_servico` (`id`, `categoria`, `subcategoria`, `nome`,
  `datacriacao`) — a forma exata que faltava, com **zero linhas**, e a extração rodou com
  sucesso. Enquanto ela estiver assim, **o nome do serviço não existe no sistema**. A
  `trs_vjob__servico` lê o derivado Supabase com `origem_do_nome` declarada linha a linha
  (34 de 38 resolvidos; 4 sem nome, 7.980 escopos). **Quando ela materializar com linha, a
  query passa a ler o sistema** e mantém o derivado só como resíduo. Perde-se também
  `categoria` e `subcategoria`: não há agrupamento de serviço por família nesta base hoje.

- **62 dos 86 clientes sem conclusão do VJOB pararam no MESMO trimestre.** Medido em
  2026-09-23 sobre o sistema: dos 251 clientes com escopo de 2025 em diante, 86 não têm uma
  conclusão sequer (71.210 escopos) — e **62 deles concluíam no quarto trimestre de 2024 e não
  concluem nada desde então**. Os outros 24: 21 nunca concluíram nada em tempo algum e 3
  pararam antes do Q4/2024.
  Isso muda a leitura registrada em 21/09. **Não são 86 histórias separadas de cliente
  inativo — é um evento único no fim de 2024 que 62 operações atravessaram juntas** (mudança
  de processo, de ferramenta ou de equipe). É o mesmo padrão do `TESTE HUGO SENNA`, cuja
  conclusão parou em novembro/2024, agora em escala. `is_parou_q4_2024` marca na Refined.

- **Zero de conclusão não é zero: é NULL.** Regra R3 da `rfn_operacao__escopo_mensal`. Cliente
  sem nenhuma conclusão na janela recebe `taxa_conclusao` **NULL**, nunca zero, e
  `is_cliente_sem_registro` acende — 26.532 das 70.963 linhas. Zero é um número e seria
  somado; NULL obriga quem lê a decidir. **Ao agregar, recalcule da razão de somas e exclua os
  clientes sem registro** — senão o denominador carrega 71 mil escopos que ninguém marcou.

- **`tbcronograma.valor` do VJOB NÃO é o valor do contrato — é o valor de UMA parcela, e a
  diferença é de R$ 26,3 milhões.** Medido em 2026-09-23: somar `valor` entre os 6.754
  contratos dá **R$ 84.923.957,85**; somar `valormensal` nas 10.036 parcelas dá
  **R$ 111.209.496,44**. **A grandeza aditiva é a da parcela.**
  **Duas provas:** (a) dos 785 contratos em que a soma das parcelas difere do `valor`,
  **TODOS** têm parcela maior — nenhum menor — e **696 (89%) são exatamente
  `valor × número de parcelas`**, o mensal repetido; (b) os 98 contratos de
  `tipocronograma = 6` têm **`valor` zero em todos** e suas parcelas somam **R$ 547.783,03**
  — quem somar `valor` conclui que o tipo não vale nada.
  **Por que passava despercebido:** em 5.969 dos 6.754 (88%) há parcela única e os dois
  números coincidem. Na `trs_vjob__cronograma` (`query-bc9M`) a coluna saiu renomeada para
  `valor_parcela`, e `valor_contrato_calculado` traz a soma real — medida, nunca multiplicada.
  O dinheiro se soma na `trs_vjob__cronograma_parcela` (`query-VxBS`).

- **Não existe flag de faturamento no cronograma do VJOB.** `faturado = 1` em **ZERO das
  10.036 parcelas**; `status` está **vazio em 10.007** (só 29 têm valor: 18 `FATURADO`, 8
  `BOLETO EMITIDO`, 3 `A FATURA`); `data_faturamento` em **119** (1,2%). Medir faturamento por
  qualquer um devolve praticamente zero — **e zero parece um resultado**.
  O único sinal com cobertura é a **NFSe: 9.146 de 10.036 (91%)**, e ela **não é chave**:
  7.977 números distintos para 9.146 preenchidas, ou seja **1.169 repetições** — uma nota
  cobre mais de uma parcela. Contar parcela por NFSe distinta subconta; contar NFSe por
  parcela superconta.

- **No cronograma do VJOB, fornecedor separa repasse de honorário — e isso é medido, não
  suposto.** `tipocronograma` 1, 2, 3 e 4 têm fornecedor em **100%** das linhas (6.106 de
  6.106); os tipos 5 e 6 em **0%** (648 de 648). Não há meio-termo. Com fornecedor
  **R$ 91,46 mi** (veiculação, produção, comissão — há um terceiro que recebe); sem fornecedor
  **R$ 19,75 mi** (Fee Mensal, manutenção — a casa entrega). Tratar os dois como a mesma
  grandeza infla a receita própria em quase cinco vezes; é o mesmo mecanismo do `tipo_receita`
  CLIENTE vs CONTA_ORDEM no financeiro. **`tipocronograma` não tem tabela de domínio**, então
  a Trusted emite `tem_fornecedor` (o fato) e deixa a leitura declarada na descrição, sem
  rotular os seis tipos.

- **As dimensões do cronograma resolvem 100%, ao contrário do escopo.** Os 26 serviços casam
  com `tbservicoscronograma` (30 linhas) e os 187 fornecedores com `tbfornecedorescronograma`
  (212) — **zero órfãos**. O serviço do cronograma tem nome; o do escopo não, porque
  `tb_servicos_servico` veio vazia. São catálogos diferentes: o do cronograma usa ids 22–159,
  o do escopo 1–44.

- **Vigência e integração do cronograma são escassas.** Só **648 de 6.754 contratos** (10%)
  têm `iniciodecontrato` e 647 têm `finaldecontrato` — indicador de contrato vigente cobre
  10% da base. A integração Conta Azul tem 126 parcelas com `contaazul_venda_id`, 75 com NF
  emitida e **5 com venda recebida**, de 10.036: não sustenta indicador de recebimento.
  E `mesanoreferencia` não é competência limpa — **327 das 10.036 não caem no dia 1**.

- **"Linear está vazio" é FALSO — ele tem 230 issues. E "Linear é fonte viva" também é
  falso: parou em 01/08/2026.** Remedido em 2026-09-23: 230 issues, 8 projetos, 67
  concluídas, **último criado 28/07/2026 16:19 e último atualizado 01/08/2026 04:25** —
  enquanto a fonte `linear-byrt` acumula **29 execuções, todas com sucesso, a última hoje
  às 04:20**. A extração está sã; o que não há é atividade nova. **O Linear não quebrou,
  parou de ser usado.** Serve para histórico até julho, não para acompanhar trabalho
  corrente. Texto exato para corrigir a skill (duas linhas):
  `docs/nekt/skill-contexto-correcao-linear.md` — **a correção é na skill da conta dela,
  não dá para fazer daqui**, porque ela vive em `/root/.claude/skills/synced/` e uma
  edição local vale só para a sessão. Medido em 2026-09-21 em
  `vanguardamartech_linear_vanguarda.linear_vanguardaissues`. A skill de contexto
  (`contexto-head-ia-vanguarda`) afirma "**Linear está vazio** — não é fonte, não insistir", e
  isso está errado hoje: a fonte `linear-byrt` tem **7 streams habilitados** (`issues`,
  `projects`, `cycles`, `teams`, `users`, `customers`, `issue_labels`), todos INCREMENTAL com
  `updatedAt` como chave de replicação, e roda diária às 03:20 `America/Manaus` com 24
  execuções bem-sucedidas. **Corrigir a skill**, senão a afirmação volta a cada sessão nova.
  **E o prefixo de tabela é `linear_vanguarda` colado ao nome do stream** — a tabela de issues
  é `linear_vanguardaissues`, não `linear_issues`. Mesma armadilha de prefixo já registrada no
  Google Ads: adivinhar o nome dá `not_in_catalog` e parece ausência de dado.

- **`dueDate` do Linear é o segundo caso confirmado de DATA disfarçada de TIMESTAMP — e neste
  o dano é de 100%.** Medido em 2026-09-21 em `linear_vanguardaissues`: das 83 linhas com
  `dueDate`, **zero** têm hora ≠ 00:00:00 e **todas as 83** mudariam de dia se lidas com
  `DATE(dueDate,'America/Sao_Paulo')`. Na mesma tabela, `createdAt` e `completedAt` são
  instantes de verdade (226 de 230 e 64 de 67 com hora ≠ 00) e **precisam** de
  `DATETIME(ts,'America/Sao_Paulo')`. Os dois tratamentos convivem na mesma tabela — é a
  confirmação prática do "medir coluna a coluna, nunca aplicar fuso por família". Resolvido
  na `trs_linear__issue` (`query-lhYJ`).

- **Linear: quatro campos mortos e uma dimensão de um só valor.** Medido em 2026-09-21 sobre
  as 230 issues: `cycle` 100% NULL, `estimate` 0% preenchido, `archivedAt` 100% NULL,
  `previousIdentifiers` 100% vazio, `customerTicketCount` zero em todas as linhas, e **uma
  única equipe** (`VAN`). Além disso **196 das 230 (85%) não têm responsável** — qualquer
  indicador por responsável cobre 15% da base e a cobertura tem de vir junto com o número.
  Nada disso aparece em contagem de linha: a fonte parece rica e é rasa em quase toda
  dimensão que se tentaria usar. Declarado no bloco de limitações da `trs_linear__issue`.

- **A issue do Linear NÃO carrega cliente.** `project.name` é projeto interno da agência
  (`SGQ v4.0`, `Vanguarda BI Hub v2`, `App01 - E-mail Marketing`, `Fechamento Contábil
  02/2026`…), não cliente de mídia — 9 projetos, 26 issues sem projeto. Ligar
  `trs_linear__issue` a `rfn_cadastro__cliente` produziria casamento falso por rótulo.

- **GitHub (`github-s0VO`) tem 3 tabelas pequenas e reais na Raw.** Medido em 2026-09-23:
  `github_repositories` 10 linhas, `github_pull_requests` 16, `github_commits` **790**
  (eram 775 em 21/09). O esquema é largo e muito aninhado (o struct `head`/`base` do PR
  carrega o repositório inteiro repetido, ~90 campos cada), então a Trusted aqui é
  sobretudo desaninhamento. Tratadas em 2026-09-23: `trs_github__repositorio` (`query-UFhj`),
  `trs_github__commit` (`query-45Rs`) e `trs_github__pull_request` (`query-3vaR`), as duas
  últimas com gatilho de evento **na primeira**, não na fonte — dependem dela para resolver
  o cadastro de repositório e o encadeamento garante a ordem.
  Detalhe: `docs/nekt/trusted-github.md`.

- **Três em cada quatro commits do GitHub são de repositório FORK.** 580 dos 790 (73,4%)
  vêm de `system-prompts-and-models-of-ai-tools` (518) e `claude-user-memory` (62), forks de
  repositório público. É histórico do repositório de origem, **não trabalho da casa**.
  Sem `flag_repo_fork = FALSE` a base parece ter 790 commits de trabalho; com o filtro tem
  **210**. A coluna está denormalizada na `trs_github__commit` para o filtro não exigir join.

- **Não existe volume de código em nenhuma tabela do GitHub.** `stats` (adições, deleções)
  é **100% NULL** nos 790 commits, e em `github_pull_requests` os campos `additions`,
  `deletions`, `changed_files`, `commits`, `comments` e `review_comments` são **NULL nas 16
  linhas** — junto com os arrays `labels`, `assignees`, `requested_reviewers`, `milestone` e
  `auto_merge`, todos vazios. É a assinatura do endpoint de **listagem** do GitHub, que não
  devolve esses campos; só a chamada por item individual devolveria. As colunas ficaram
  **fora** das Trusted de propósito: emitidas como NULL, convidariam a somar e obter zero,
  que é um número, quando o certo é ausência. **Desta fonte dá para contar e datar, e nada
  mais** — nem tamanho, nem revisão, nem responsável (`assignee` é NULL nos 16 PRs).

- **Um repositório tem commit e não tem cadastro.** `jussaracavalcante-sketch/ai-hub-agencia-aws`
  aparece em 3 commits (09/09/2026) e não existe em `github_repositories`: o stream `commits`
  alcança **11** repositórios e o `repositories` cadastra **10**. Por isso o join da Trusted é
  LEFT e acende `flag_repo_nao_catalogado` — mesmo padrão do `flag_conta_nao_catalogada` do
  Google Ads. Com INNER os 3 sumiriam sem sinal.

- **Commit tem DUAS datas e elas não são a mesma coisa.** `commit.author.date` é quando o
  código foi escrito, `commit.committer.date` é quando entrou na árvore. Medido em 2026-09-23:
  o `committed_at` da fonte é idêntico ao committer em **790 de 790** e difere do author em
  **3** — rebase ou cherry-pick, marcados com `flag_reescrito`. Quem mede entrega usa o
  committer; quem mede autoria usa o author. E **18 commits não têm usuário GitHub resolvido**
  (o e-mail não casou com conta): sobra o nome digitado no git, que não é identidade — não
  somar por `autor_nome` esperando pessoa única.

- **Todo PR mesclado do GitHub entrou no mesmo dia.** Os 11 mesclados de 16 têm
  `dias_ate_merge` = 0, média e máximo. Nenhum esperou um dia. O indicador está na tabela mas
  só passa a dizer algo quando a base crescer. E só 3 dos 11 repositórios com commit têm PR.

### Custo por peça — a margem deixou de estar bloqueada

**Publicado em 2026-09-23** a pedido ("esqueça as horas, devemos calcular custo por peça").
Três tabelas, cadeia linear, cada elo dispara no anterior:
`query-wzIg` (`trs_iclips__peca_tipo`, 1.049) → `query-NnxD` (`trs_financeiro__movimento`,
45.154) → `query-VMUW` (`rfn_operacao__custo_peca`, 134.751). Detalhe:
`docs/nekt/custo-por-peca.md`.

**O valor unitário por peça SEMPRE EXISTIU e ninguém tinha olhado.** O catálogo do iClips
(`supabase_silver_iclips_peca`) tem `valor` em 147 dos 1.049 tipos. O
`dim_peca_canonica.valor_referencia` **não é uma segunda fonte — é cópia desta**: dos 65
tipos com valor nos dois lados, **65 batem ao centavo e zero divergem**, e no grão da
entrega são **13.720 de 13.720 iguais**. O iClips cobre mais (147 contra 65), então o
valor sai dele e o canônico entra só como rótulo. **Zero é sentinela**: 902 tipos têm
`valor = 0` e nenhum tem NULL.

**A cobertura do custo saltou 63×.** Hora apontada existe em **1.050 de 134.751 peças
(0,8%)** — a `rfn_operacao__peca` já avisava que não serve de base de custo. O rateio por
peça cobre **85.539 (63,5%)**.

**`classe_financeira` impede somar coisas diferentes — 57% de erro.** O custo operacional
realizado da casa é **R$ 29.850.726,93**; somar toda a saída dá **R$ 46,80 mi**, porque
mistura repasse por conta e ordem (R$ 7,82 mi), retirada de sócios (R$ 9,16 mi),
financiamento e capex. Mesmo mecanismo do `tipo_receita` CLIENTE vs CONTA_ORDEM e do
`tem_fornecedor` no cronograma do VJOB. Receita operacional realizada: R$ 38.129.752,74.
**Escolha declarada:** `Tributos` (R$ 4,34 mi) fica em OPERACIONAL; a alternativa não
tomada era deduzi-lo da receita, e `categoria` continua visível para quem preferir.

**O rateio fecha no centavo, e a prova é a soma.** No mês, com C = custo operacional,
n = peças, k = peças com valor, V = soma dos valores: peça com valor recebe
`C·(k/n)·(v/V)`, peça sem valor recebe `C/n`, e o total é **C, sempre** — verificado nos
42 meses fechados com diferença **zero até a sexta casa decimal**.
**Nada é imputado:** imputar a mediana da categoria inventaria peso para 54 mil peças de
Social Media (70.257 peças, só 23,1% precificadas). `origem_do_custo` declara a rota
linha a linha.

**O corte de mês não é data escrita à mão.** A despesa está completa até a competência
**2026-05** (2026-06 tem 6 lançamentos, 2026-07 em diante tem zero) enquanto a peça vai
até 2026-09 — somar assim mostraria o custo desabando e a margem explodindo. O mês é
fechado quando tem **≥ 30% da mediana de lançamentos dos meses de 2023 em diante**
(mediana 379, piso 114): fecha **2022-12 a 2026-05** e descarta 2021-01 a 2022-11, quando
a despesa ainda não era lançada. **Nenhuma data precisa ser reescrita quando a base andar.**

**O peso diferencia bem OFF e mal social.** Off 95% precificado, Inbound 97%, Dev 99% —
contra **Social Media 23%, e Social Media é 52% da base**. E `Off` e `OFF` são categorias
distintas na origem: a primeira tem 95% de precificação e a segunda **zero**. A duplicata
de caixa não é cosmética, por isso a coluna crua e a normalizada convivem.

**"Peça entregue" não é provável.** `status_peca_codigo` tem 5 valores (5, −1, 6, 12, 13)
e não existe tabela de domínio dizendo qual é "concluída". O rateio é sobre a peça
**registrada** no mês — dizer "entregue" seria afirmar o que a base não afirma.

**O gargalo da margem acabou.** Este arquivo registrava em 2026-09-23 que "era identidade
**e** custo; agora é só custo". Deixou de ser: receita por cliente/mês está em
`rfn_financeiro__receita_cliente_mensal` (`query-awMU`) e custo por cliente/mês sai da
agregação de `rfn_operacao__custo_peca` por `cliente_cnpj` + `mes_referencia`. **A janela
em que a margem existe é 2022-12 a 2026-05.**

### A margem por cliente existe — `rfn_financeiro__rentabilidade_cliente`

**Publicada em 2026-09-23** (`query-dGga`, Refined / `financeiro`, gatilho de evento em
`query-VMUW`). Grão: um cliente (documento) em uma competência. 4.545 linhas, 4.545 chaves
distintas, **446 clientes**. Janela **2022-12 a 2026-05**, herdada do custo. Lista completa dos
261 clientes com custo: `docs/nekt/rentabilidade-por-cliente.md`.

**A RECEITA DE MÍDIA É COMISSÃO — provado no mesmo dia, por três caminhos.** A primeira
versão desta tabela, publicada horas antes, dizia que a base não decidia se a linha de mídia
(R$ 15,51 mi) era bruto do cliente ou comissão da casa, e emitia duas margens de sinais
opostos deixando a escolha para quem lesse. **Era eu que não tinha medido.** A base decide:

1. **A própria origem declara.** As **nove** subcategorias de `Mídia Off` começam todas com
   "Comissão" — Comissão TV (R$ 4,17 mi), Rádios, Mídia Exterior, Indoor, BUSDOOR, OUTDOOR,
   Locação de Espaço, Programática, Jornais. Em `Mídia On`, **onze das doze** também —
   Comissão Facebook (R$ 1,98 mi), Google, Tiktok, Spotify, Waze, LinkedIn, Twitter, KWAI.
   Única exceção: "Globo Express", R$ 15.621,90, **0,4%** da categoria.
2. **A casa NÃO paga veículo por esta base.** Dos **90 CNPJs de veículo** do PI, só **4**
   aparecem como contraparte de saída — 26 lançamentos, **R$ 18.603,67**, contra R$ 21,66 mi
   de saída total no período. Se a entrada fosse bruta, o dinheiro entraria e nunca sairia.
3. **O tamanho não fecha com bruto.** No período maduro do PI (2026-02 a 2026-04) o valor
   faturado ao cliente nos PIs `Bruto` é R$ 0,9–1,2 mi/mês contra R$ 0,32–0,35 mi de entrada
   de `Mídia Off` — **um terço**. Bruto teria de ser maior ou igual.

**Portanto `margem_total` é A margem, sem ressalva: +R$ 5.833.203,89 (16,4% da receita).**
A coluna que eu tinha chamado de `margem_servico` **não era um piso conservador** — subtraía
receita que a casa de fato fica com. Foi renomeada para **`margem_sem_comissao_midia`**
(−R$ 9.674.317,82) e agora responde outra pergunta: **quanto sobraria sem a comissão de mídia**.

**A distância entre as duas é o achado de negócio:** a casa **depende da comissão de mídia
para ter resultado** — sem ela a operação de serviço próprio (fee, OS, dev, SaaS) não paga o
próprio custo. E na mesma janela a **retirada de sócios foi R$ 9,16 mi, maior que a margem de
R$ 5,83 mi**.

**`tipo_faturamento` do PI é a chave que faltava para o bruto.** `supabase_silver_pi_insercao`
traz `Bruto` (1.939 PIs, R$ 16,42 mi faturados ao cliente) e `Líquido` (1.409, R$ 27,05 mi),
com `valor_comissao_veiculo` ao lado — é **ali** que o bruto de veiculação existe, não no
financeiro do iClips. **O PI só cobre de 2025-01 em diante**, e o volume vai de 4 PIs/mês em
janeiro/2025 a 150/mês em março/2026: a instrumentação é recente, então não serve para
reconstruir bruto histórico.

**FULL OUTER é obrigatório e o tamanho está medido:** dos 4.545 pares (cliente, mês), apenas
**1.924 têm os dois lados**; 1.125 têm só custo e 1.496 só receita. INNER descartaria 58% das
linhas. Boa parte do descasamento é competência — a peça sai num mês e a nota no seguinte — e
é por isso que **cada linha carrega também `custo_janela`, `receita_janela` e
`margem_janela_*`** do mesmo cliente somados sobre toda a janela. **Para ranking de cliente,
usar as colunas de janela**, nunca as mensais.

**Margem de um lado só não é margem.** Falta receita no mês → a margem não é o custo negativo;
falta peça → a margem não é a receita inteira. Nos dois casos `margem_mes_*` sai **NULL** e
`motivo_margem_mes_indisponivel` diz qual lado faltou. Mesma doutrina do "zero de conclusão
não é zero, é NULL".

**59 dos 261 clientes com custo têm ZERO receita na janela**, carregando R$ 1.645.035 —
TARGO CONSULTORIA R$ 233.170, LEGACY PNEUS R$ 141.805, L27 LOCADORA R$ 112.776, MANAUS MOTORS
R$ 71.711, VBOT R$ 30.210. Não significa que não pagaram: significa que o CNPJ não aparece na
entrada operacional do financeiro nessa janela. **Dos 202 que têm os dois lados, 92 têm margem positiva** —
110 dão prejuízo. Sem a comissão de mídia sobrariam 78.

**A VANGUARDA COMUNICAÇÃO entra na conta de produção como se fosse cliente** — 944 peças e
R$ 300.711 de custo contra R$ 23.539 de receita. É trabalho interno da casa, e quem ranquear
cliente por prejuízo vai encontrá-la no topo sem que isso queira dizer nada sobre cliente.

**Um balde sem CNPJ:** 2.258 peças e R$ 798.941,16 de custo cujo cliente o iClips não resolve.
Vira uma linha por mês com `flag_sem_documento` acesa e `documento` NULL — **nunca somar junto
com cliente real**.

**Receita aqui ≠ receita da `supabase_gold_mvw_fin_cliente`:** aquela view dá R$ 33,88 mi de
`tipo_receita = CLIENTE` na mesma janela contra R$ 35,60 mi aqui, porque separa `BV`
(R$ 2,60 mi) como terceira natureza e a Trusted ainda não tem como separar — o BV está dentro
de `Mídia Off` na origem. **Os dois números não competem:** um separa BV, o outro não.

**Conta e ordem está fora dos dois lados, de propósito** (R$ 7,82 mi de saída, R$ 8,15 mi de
entrada), e **retirada de sócios (R$ 9,16 mi) não é custo** — sai depois da margem, não antes.

### Classificação L1–L5 — a divergência nº 3 do ADR-0010 começou a ser cumprida

**Registrado em 2026-09-23.** As quatro tabelas publicadas hoje saíram sem classificação,
e a §31 é norma. Corrigido no mesmo dia, com o nível medido e escrito na descrição de cada
uma:

| tabela | nível | por quê |
|---|---|---|
| `trs_iclips__peca_tipo` (`query-wzIg`) | **L3 CONFIDENTIAL** | é a tabela de preços da casa |
| `trs_financeiro__movimento` (`query-NnxD`) | **L4 PERSONAL_DATA** | carrega folha nominal |
| `rfn_operacao__custo_peca` (`query-VMUW`) | **L3 CONFIDENTIAL** | custo por cliente |
| `rfn_financeiro__rentabilidade_cliente` (`query-dGga`) | **L3 CONFIDENTIAL** | margem por cliente |

**`trs_financeiro__movimento` é L4, não L3 — e isso eu só vi depois de publicar.** Medido:
**6.429 linhas trazem CPF no lugar do CNPJ, 304 CPFs distintos**, e a maior parte está na
categoria `Pessoal` — **4.944 linhas, 277 CPFs, R$ 15.707.213,45**, ou seja **quanto cada
pessoa recebeu, mês a mês, identificada**. Mais `Retiradas Sócios`, **595 linhas e 7 CPFs
somando R$ 5.614.132,45**. Uma tabela que eu descrevi como "o `fact_custos` que faltava" é
também uma folha de pagamento.

**O documento NÃO foi removido, porque é a chave:** 35 CPFs são **cliente pessoa física**,
com R$ 451.991,17 de receita, e sem ele a rentabilidade deles desaparece. O que a Trusted
passou a fazer é tornar o caso **visível e filtrável** — `contraparte_is_pf` e
`is_folha_pessoal` existem para que ninguém exponha folha por engano. **Não publicar essa
tabela em painel sem filtrar `is_folha_pessoal = FALSE`.**

**As duas consumidoras não propagam o dado pessoal, e isso foi conferido:** a
`rfn_operacao__custo_peca` lê o financeiro **só agregado por mês**, então nenhum CPF de
colaborador chega lá; e a `rfn_financeiro__rentabilidade_cliente` usa o documento **só do
lado da receita**, onde CPF é cliente, nunca folha.

**O resto da camada foi classificado no mesmo dia, mas na CAMADA SEMÂNTICA, não tabela a
tabela.** São 78 transformações; reescrever 78 descrições seria desproporcional e a
classificação é **política**, não metadado de uma tabela só. Então ela virou documento da
camada semântica — que é onde a §17 manda a definição oficial morar, e é de onde qualquer
IA e qualquer análise já leem.

**Documento: "Classificação L1–L5 — que nível cada tabela carrega e o que isso proíbe"**
(`29eca9d5-010d-419b-8efa-eebbe8c81ba4`, raiz da camada semântica). **Verificado indexado**
em 2026-09-23: uma busca por "nível de classificação da tabela de margem e da folha" devolve
ele em primeiro lugar.

**A regra que o documento fixa:** o nível **sobe pela linhagem, nunca desce**. Refined que lê
L4 é L4 — a menos que a agregação prove que o dado pessoal não passou, e **a prova tem de
estar escrita na descrição**. Foi assim que a `rfn_operacao__custo_peca` ficou L3 lendo uma
L4.

**L4 medido, além da folha:** `trs_iclips__peca_atributo` tem **274 executores identificados
e 134 com valor/hora** (R$ 9,49 a R$ 7.000) — remuneração individual, que a
`rfn_operacao__peca` herda. Mais `trs_vjob__usuario` (nome; escopo já minimizado em 26/08,
sem admissão/demissão/regime/nível/líder/e-mail), `trs_vjob__cliente` (CPF do responsável em
21 linhas), a família RD (nome, e-mail, telefone, nascimento e o `custom_fields` livre),
`trs_google_ads__termo_busca` (termo digitado pode conter nome ou telefone) e, com
intensidade baixa mas mesmo nível, `trs_linear__issue` e `trs_github__commit`.

**L1 PUBLIC está vazio** — nada neste warehouse é público. Dado publicável nasce de recorte
aprovado de L2, não de tabela existente.

**L5 não existe em Trusted nem Refined, mas existe na Raw e já materializou:**
`tbusuariointranet` (`senha`), `tbportalusuarios` (`senha_hash`), `contazul_oauth_*`,
`tarefas_tbjobs_aprovacao_inicial_tokens` e as `supabase_auth_*`. A arquitetura diz que
secret não deve estar no Data Lake.

**O que a classificação NÃO é:** controle de acesso. **Não há RLS nem CLS aplicado** — hoje
ela é documentação, e quem consome é responsável pelo filtro. A divergência nº 3 deixa de
estar aberta como "ninguém classificou" e passa a estar aberta como "classificado, não
aplicado".

### A camada semântica tem mais documentos do que este arquivo registrava

**Medido em 2026-09-23.** Uma busca por classificação e LGPD devolveu **dois documentos que o
ADR-0010 não lista**: **"LGPD — Classificação de dado pessoal e regras de uso das fontes"**
(5.458 caracteres) e **"Governança — Uma camada por fonte, medalhão e identidade de cliente"**
(7.691), além de **"Inbound — leitura do setor"**. Como `get_semantic_context` é busca
semântica e devolve os mais relevantes, **não dá para afirmar quantos documentos existem** —
só que são mais que os cinco registrados. Inventariar antes de citar "os cinco documentos".

**O que o documento de LGPD fixa e que muda trabalho:**
- **O filtro de autorização é `status = 'granted'`, não a existência do array.** Contar
  `ARRAY_LENGTH(legal_bases) > 0` inclui quem **recusou**. Medido em 4 dos 34 clientes de RD:
  1.956 contatos, 1.881 autorizados, **20 recusaram**, 55 sem registro — **75 pessoas não
  devem receber comunicação**. Não há bloqueio automático.
- **Exclusão de titular NÃO funciona hoje.** Os streams de contato são INCREMENTAL por
  `updated_at`: registro apagado na origem não ganha `updated_at` novo, deixa de vir e
  **permanece no warehouse indefinidamente**. A correção existe e não está aplicada —
  `settings_full_sync_cron`, hoje `null` em todas as fontes.
- **Retenção de 5 anos é definição, não controle.** Nada apaga por idade.
- **`custom_fields` do RD é campo livre do cliente** — em cliente de saúde pode conter
  informação clínica, o que torna o registro **dado sensível (Art. 11)**. Não presumir o
  conteúdo.
- **Não usar `last_conversion_date` para medir inatividade** — ele varia numa janela de
  poucos dias e faz toda a base parecer ativa. Usar `created_at`.

### Data Quality existe — `rfn_qualidade__regra` (`query-wD6c`)

**Publicada em 2026-09-23**, Refined / `qualidade`, gatilho de evento em `query-dGga` (último
elo da cadeia de custo e margem), alerta de falha ligado. **L2 INTERNAL** — só contagem e taxa.

**Fecha PARCIALMENTE a divergência nº 4 do ADR-0010.** A §13 pede completude, unicidade e
validade medidas **automaticamente**, e diz que os percentuais *"devem ser gerados
automaticamente pelos testes de qualidade e não devem ser tratados como avaliações
subjetivas"*. Até aqui a qualidade desta casa estava escrita na descrição de cada tabela,
medida **uma vez, na mão, no dia em que a tabela nasceu**. Agora roda toda vez que a cadeia anda.

**27 regras, 4 dimensões** (COMPLETUDE, UNICIDADE, VALIDADE, INTEGRIDADE), duas severidades
(BLOQUEANTE para chave e integridade, ALERTA para completude e validade) e **limiar por regra,
não global** — 96,7% de CNPJ preenchido é o teto conhecido desta base, enquanto 99,99% de
unicidade de chave seria falha grave.

**Regra sem linha para avaliar NÃO passa:** `is_conforme` sai NULL e `resultado` vira
`SEM_DADO`. Zero de zero seria 100% e esconderia tabela vazia.

**O LIMIAR DE INTEGRIDADE DO VJOB É 0,70 DE PROPÓSITO.** O buraco de cadastro — escopo e
contrato apontando para cliente que não existe em `tbclientes` — é **da origem** e já está
medido neste arquivo. A regra existe para detectar **piora**, não para reclamar todo dia do
que a casa já sabe. Limiar apertado ali só ensinaria a ignorar a suíte.

**28 regras.** Resultado esperado na próxima execução: **27 conformes e 1 em falha** — a da
ORIGEM do PI, que fica de propósito como linha de base.
As conformes **reproduzem números já conhecidos**, que é como se sabe que a suíte mede o que
diz: `codigo` único 45.154/45.154, `id_job_peca` 134.751/134.751, `peca_id` 1.049/1.049,
`id_cliente` 317/317, `id_job_unico` 1.514/1.514, `id_cronograma` 6.773/6.773, `id_parcela`
10.055/10.055, `id_escopo_mensal` 70.963/70.963, grão do `cliente_sk` 1.353/1.353.

**REGRA QUE ACUSA O QUE É LEGÍTIMO ENSINA A IGNORAR A SUÍTE — e isso aconteceu no primeiro
dia.** A terceira "falha" que a suíte apontou eram **2.555 de 130.311 documentos da
`rfn_operacao__peca` sem 14 dígitos**, que a regra chamava de "CPF ou malformados". Medido:
são **18 CLIENTES PESSOA FÍSICA** — BARCO CARIBBEAN, CITY SPORT, DON WATCHES, DR. JOSÉ CABRAL
JR. — com **CPF de 11 dígitos, que é documento válido** e junta com o financeiro igual (a
`rfn_financeiro__rentabilidade_cliente` já os trata assim, com `is_pj` distinguindo). A regra
passou a exigir **forma de documento — 14 ou 11 dígitos** — e virou
`rfn_operacao__peca.documento_tem_forma`: **130.311 avaliadas, zero falhas**. Falso positivo
custa mais caro que regra ausente, porque some junto com os verdadeiros quando alguém para de
olhar.

**A suíte achou DOIS defeitos de verdade e DOIS defeitos dela mesma, no primeiro dia.**

De verdade: **2 cadastros do VJOB** com `tem_cnpj` aceso e documento que não é CNPJ; e
**507 PIs** cujo CNPJ de veículo tem 13 dígitos, **R$ 5,63 mi** que não juntavam com nada.
Os dois corrigidos.

Dela mesma: a regra de documento da peça acusava 2.555 CPFs legítimos; e a regra de veículo
do PI tratava os 507 como "sem CNPJ" quando o problema era de forma, corrigível.

**As duas regras de veículo do PI agora são duas de propósito, e medem coisas diferentes:**

- `silver_pi_insercao.veiculo_com_cnpj` (Raw, **limiar 0,78**) — a **origem**. Ela não vai se
  corrigir sozinha, então limiar alto seria reclamação permanente. Fica como **linha de base,
  para detectar piora**.
- `trs_pi__insercao.veiculo_com_cnpj` (Trusted, **limiar 0,95**) — a **cobertura que importa**,
  96,8% depois do repadronizado. **Se ela cair para o nível da origem, o sinal é que o
  TRATAMENTO não rodou** — não que a origem piorou.

Observações dentro do limiar, que valem como linha de base: **11 movimentos REALIZADOS com
competência futura**; **43.329 de 195.163 escopos (22,2%)** apontando para cliente sem
cadastro; **1.274 de 6.773 contratos (18,8%)** idem; e só **168 dos 317 cadastros do VJOB
(53%) têm CNPJ**.

**DÍVIDA QUE A CORREÇÃO DE DOCUMENTO DEIXOU, e ela tem data.** A regra
`trs_vjob__cliente.cnpj_14_digitos` mede `tem_cnpj AND LENGTH(cnpj_digitos) <> 14`. Depois da
correção publicada hoje, a Trusted já segura o fragmento fora de `cnpj_digitos` — então, quando
a cadeia do VJOB rodar de novo (**domingo**, com a `mysql-yIOn`), essa regra passa a devolver
zero falhas e **o caso some do painel sem ter sido resolvido na origem**. Repontar então para
`COUNTIF(flag_cnpj_invalido)` sobre `cnpj_digitos_origem`, que mede a ORIGEM e é o que importa
acompanhar. **Não dá para repontar antes:** as colunas novas só existem depois da execução, e
referenciar coluna inexistente derruba a suíte inteira. Na mesma execução a regra
`trs_vjob__cliente.tem_cnpj` muda de linha de base — de 149 para 151 sem documento, porque dois
deixaram de contar como CNPJ.

**A QUARENTENA DA §14 NÃO FOI FEITA, e a diferença está declarada na tabela.** A arquitetura
manda **desviar** o registro inválido antes da Silver; esta tabela **mede e denuncia**, e o
registro continua entrando, marcado com a flag que a Trusted dele já emite. A razão é
deliberada: desviar exigiria reescrever as 78 transformações e quebraria a linhagem de quem já
consome, e a doutrina da casa é **"marcar, nunca apagar"**, porque descartar esconde que o caso
existe. Quem quiser a quarentena de verdade tem aqui a lista do que iria para ela.

**LIMITE DE COBERTURA:** só entram tabelas **materializadas**, porque referenciar tabela não
materializada **derruba a query inteira**, não só aquele ramo. Quando a suíte foi escrita,
nada do que tinha sido publicado naquele dia existia ainda. **A cadeia do VJOB materializou
poucas horas depois** e as 13 regras da família entraram no mesmo dia — essa parte da dívida
está paga. **Continuam de fora as 3 Trusted do GitHub e as 4 de custo e margem**, que
materializam no dia seguinte (~04:11 e ~07:10); as regras sobre elas entram quando a tabela
existir.

**E isso vale como aviso geral:** **nada do que foi publicado hoje existe como tabela ainda.**
Verificado em 2026-09-23 — `trs_vjob__cliente`, `trs_github__commit` e as demais respondem
`table_not_materialized`. Publicar não é materializar; a prova é a execução agendada.

**QUANDO CADA COISA MATERIALIZA — medido pelo histórico de execução, não pelo `status`.**
Corrige o que este arquivo dizia antes ("esperam a `supabase-x0tz`", vago demais):

| cadeia | dispara em | cadência medida | materializa |
|---|---|---|---|
| 3 Trusted do GitHub | evento em `github-s0VO` | diária 04:10, **31 execuções, todas success** | **24/09 ~04:11** |
| custo → margem → qualidade (5 tabelas) | evento em `query-jdUw` | diária ~07:08, **todas success**, última 23/09 07:10 | **24/09 ~07:10** |
| VJOB inteiro (10 tabelas) | evento em `query-MZdN` | `mysql-yIOn` 13:40→**14:28, sucesso** | ✅ **MATERIALIZOU em 23/09** |

**A `mysql-yIOn` não esperou domingo.** A execução iniciada em 23/09 às 13:40 terminou às
**14:28 com sucesso** e disparou toda a cadeia do VJOB — **com o código já corrigido**, porque
a `trs_vjob__job` reescrita (14:08) e a `rfn_operacao__job` (14:14) tinham deploy concluído
antes disso.

**CONFERIDO EM PRODUÇÃO, não em simulação:**

| tabela | linhas | antes (21/09) |
|---|---:|---:|
| `trs_vjob__cliente` | **317** | 315 |
| `trs_vjob__job` | 1.514 (1.514 chaves) | 1.514 |
| `trs_vjob__escopo` | 195.163 | 195.163 |
| `trs_vjob__cronograma` | **6.773** | 6.754 |
| `trs_vjob__cronograma_parcela` | **10.055** | 10.036 |
| `rfn_cadastro__cliente_sk` | **1.353** | 1.351 |
| `rfn_financeiro__receita_cliente_mensal` | **7.457** | 7.455 |
| `rfn_operacao__escopo_mensal` | 70.963 | 70.963 |
| `rfn_operacao__job` | 1.514 | — |

**A correção de fuso está valendo, e a prova é dupla:** `trs_vjob__job` traz
`data_cadastro` máximo **2026-08-24 11:15:59** e `checado_em` **2026-09-02 11:26:33** — as
horas certas, não 14:15:59 e 14:26:33. E o erro compensado foi verificado no par: dos 1.514
jobs, **zero divergem** entre `DATE(data_cadastro)` da Trusted e `data_cadastro_local` da
Refined, e os **13 jobs de madrugada** (00:00–03:00), que eram exatamente os que mudariam de
dia, estão **todos com o dia certo**.

**As fontes que sustentam tudo estão sãs, e isso foi medido por execução:**
`supabase-x0tz` diária 01:00→03:29, **27 execuções, todas success**, última hoje ·
`github-s0VO` 31/31 · `linear-byrt` 29/29 · `query-jdUw` todas success.

**`facebook-pages-ftS8` tem ZERO execuções — nunca extraiu nada.** Publicada com gatilho
manual em 21/09 e nunca acionada. É o caso literal da armadilha "fonte publicada não é fonte
integrada". Mudar o gatilho depende de pedido (R-002).

### 24/09 — as correções valeram em produção, e a fonte do GitHub caiu

**Tudo o que foi publicado em 23/09 rodou e foi conferido contra a tabela materializada, não
contra simulação.**

**A suíte rodou às 07:12 com sucesso: 28 regras, 27 conformes, 1 falha.** A falha é
`trs_vjob__cliente.cnpj_14_digitos` (98,81%), e ela ainda aparece **porque a cadeia do VJOB é
semanal e não rodou de novo** — a correção está publicada, não executada.
**Eu tinha previsto errado na descrição:** escrevi que a falha seria a da ORIGEM do PI. Não é —
com limiar 0,78 ela mede 80,58% e passa, que era exatamente a intenção ao rebaixar o limiar.
Errei a previsão, não a regra.

**As cinco correções de documento, medidas em produção:**

| o que | medido em 24/09 |
|---|---|
| repadronizado no financeiro | 123 linhas, 4 documentos, **R$ 157.945,50** — igual ao previsto |
| documento nem PJ nem PF | **0** (era 123) |
| `trs_pi__insercao.veiculo_com_cnpj` | **96,83%** (99 falhas de 3.120) contra 80,58% na origem |
| `rfn_operacao__peca.documento_tem_forma` | **130.317 avaliadas, ZERO falhas** |
| documento do financeiro fora de forma | **0** de 40.018 com documento |

**A margem não mudou, e era essa a previsão:** **+R$ 5.833.203,89 (16,39%)** e
−R$ 9.674.317,82 sem a comissão de mídia — os mesmos centavos de ontem. O que mudou foi
identidade: **4.545 → 4.537 linhas e 446 → 443 clientes**, porque quatro documentos deixaram de
ser clientes separados. **O repad reorganizou identidade; não criou nem destruiu dinheiro.**

**A suíte foi para 35 regras** (e depois 42), com as 7 da cadeia de custo e margem, que materializou às 07:08.
Todas medidas antes de publicar e todas conformes. A mais importante é nova em espécie:

**`rfn_operacao__custo_peca.rateio_fecha_no_centavo` — a única regra que verifica uma
IDENTIDADE CONTÁBIL.** O rateio promete que a soma do custo distribuído em cada mês é
exatamente o custo operacional daquele mês. Até 23/09 isso era uma **afirmação na descrição,
medida à mão uma vez**. Agora é teste, com grão MÊS: **42 meses, ZERO fora de um centavo,
maior diferença ZERO, R$ 29.765.153,44 dos dois lados**. BLOQUEANTE com limiar 1,00 — se ela
falhar, todo número de custo por cliente está errado.

**MÍDIA ENTROU NA SUÍTE — e até hoje a maior área da casa não tinha UMA regra.** Mais 7,
todas medidas antes de publicar e todas conformes: `id_insight` único (82.141), conta
catalogada (**zero órfãs**), investimento ≥ 0, data não futura, chave `(id_anuncio, data)` do
Facebook (140.715), investimento ≥ 0 no Facebook — e a que importa:

**`trs_google_ads__insight_diario.grao_sem_dupla_contagem` — a premissa mais frágil da base
passou a ter guarda.** A Trusted de Google Ads tem **grão misto**: linhas `ANUNCIO` mais
linhas `CAMPANHA` só para os pares (campanha, dia) que o Google não publica por anúncio — o
caso PERFORMANCE_MAX. **A união só é exata porque nenhum par aparece nos dois grãos.** Se um
aparecer, **o investimento daquele dia é contado duas vezes e nada na contagem de linhas
denuncia**. Medido em 24/09: **45.938 pares, ZERO em mais de um grão** (35.833 ANUNCIO +
10.105 CAMPANHA). A descrição da Trusted já avisava que nessa hora "a premissa cai e a query
precisa de resíduo por diferença, não por presença" — **agora existe o gatilho que avisa que a
hora chegou**.

**Armadilha de camada registrada no código:** a consolidada do Facebook é
`vanguardamartech_trusted_facebook_ads`, **não** `vanguardamartech_trusted`. Existem **onze**
tabelas chamadas `trs_facebook_ads__insight_diario`, uma por camada de cliente, porque a R-001
manda uma camada por fonte. **Apontar para a camada errada devolve um cliente só e parece a
base inteira.**

**A suíte está em 42 regras.**

**A FONTE DO GITHUB CAIU: `401 Bad credentials`.** A `github-s0VO` falhou em 24/09 às 04:10 —
**primeira falha em 32 execuções**. O token expirou ou foi revogado. Como o gatilho das 3
Trusted do GitHub é evento nessa fonte, **nenhuma das três materializou** e as regras de
qualidade sobre elas continuam de fora — não por esquecimento, por ausência de tabela.
**Trocar credencial de fonte publicada não passa pelo MCP** (o `get_setup_link` só aceita
rascunho) — é na interface web da Nekt, e é decisão dela.

### 24/09 — a cadeia do VJOB rodou e a suíte foi para 61 regras

**A `mysql-yIOn` rodou em 24/09, 11:51 → 12:43 (51 min), com sucesso**, e disparou a
cadeia inteira. Foi a terceira execução da fonte (21/09, 23/09, 24/09) — o cron é
domingo 00:00 `America/Manaus`, então as três foram fora de horário.

**Tudo o que foi publicado hoje materializou**, e a base andou entre a medição e a carga:

| tabela | medido antes | materializado |
|---|---:|---:|
| `trs_vjob__job_tarefa` | 1.585 | **1.599** |
| `trs_vjob__job_responsavel` | 1.381 | **1.395** |
| `rfn_operacao__job` | 3.099 | **3.113** |
| `trs_vjob__job_prazo_alteracao` | 224 | 224 |
| `trs_vjob__auditoria_cliente` | 3.025 | 3.025 |
| `trs_vjob__etapa_cliente` | 7.782 | 7.782 |
| `rfn_operacao__conformidade_cliente` | 510 | 510 |
| as 5 do módulo `ia_*` | 86/86/78/21/3 | iguais |

**`rfn_operacao__job` tem `MAX(data_cadastro_local)` = 2026-09-24 — HOJE.** Até de manhã
a Gold de job parava em 24/08.

**A SUÍTE FOI PARA 56 REGRAS** (`query-wD6c`), com **14 novas sobre as tabelas de hoje**.
**Todas as 14 mediram zero falhas** na tabela materializada. As quatro que guardam
premissa de verdade:
- `trs_vjob__auditoria_cliente.status_sempre_carimbado` — a invariante que faz a série de
  auditoria cobrir 100% das conclusões, contra 84% do escopo.
- `trs_vjob__etapa_cliente.nunca_ativada_nunca_marcada` — a premissa do denominador da
  Refined de conformidade.
- `rfn_operacao__conformidade_cliente.taxa_nunca_maior_que_um` — guarda a razão que eu
  errei na primeira versão daquela query.
- `rfn_operacao__job.status_canonico_conhecido` — dispara se qualquer das quatro origens
  de job inventar um status novo, que hoje sumiria da leitura sem a contagem mudar.

**A DÍVIDA DATADA FOI PAGA, no dia em que destravou.** `trs_vjob__cliente.cnpj_14_digitos`
media `tem_cnpj AND LENGTH <> 14`; depois da correção de 23/09 ela devolveria **zero
falhas e o caso sumiria do painel sem ter sido resolvido na origem**. Repontada para
`COUNTIF(flag_cnpj_invalido)` sobre `cnpj_digitos_origem` e renomeada para
`cnpj_valido_na_origem`. Medida na tabela materializada: **168 avaliadas, 2 inválidas,
98,81% — CONFORME com limiar 0,98**, como linha de base para detectar piora.

**+5 DOS SATÉLITES DE JOB, no mesmo dia.** `trs_vjob__job_responsavel` e
`trs_vjob__job_prazo_alteracao` foram publicadas **depois** da atualização de 56 regras,
mas materializaram na **mesma cadeia, às 12:45:20** — então a lacuna que a própria
descrição da suíte declarava foi fechada horas depois de ser aberta. As 5 regras medem
zero falhas: unicidade de `id_job_responsavel` (1.395) e de `id_alteracao_unico` (224),
integridade de job nas duas, e a invariante do satélite:

- **`trs_vjob__job_responsavel.um_principal_por_job`** — 1.281 jobs, 1.281 principais,
  **zero sem e zero em duplicidade**. O grão aqui é o **JOB, não a linha**. Se quebrar,
  "o responsável do job" vira ambíguo e toda leitura por principal escolhe um dos dois em
  silêncio.
- **`trs_vjob__job_prazo_alteracao.job_existe`** é conferida contra a **Refined**, não
  contra uma Trusted: a `rfn_operacao__job` é a única que tem as quatro origens de job
  somadas, e o log de prazo cobre as três que existem.

**Verificação de integridade da publicação:** o arquivo do repositório tem **31 tabelas
distintas e 61 regras**, e a Nekt detectou exatamente **31 input tables** — subiu de 29,
que é o número das duas tabelas novas. Publicado e repositório conferem.

**Ainda de fora:** só as 3 Trusted do GitHub, e não por esquecimento — a fonte
`github-s0VO` segue com `401 Bad credentials`, o gatilho de evento nunca disparou e as
tabelas não existem. Referenciar tabela não materializada derruba a query inteira.

### 24/09 — o módulo de JOB do VJOB não parou: MUDOU DE TABELA

**Isto contradiz o que este arquivo dizia**, e o que ele dizia estava certo sobre as
tabelas que a `trs_vjob__job` lê e errado sobre o sistema. Medido em 2026-09-24:

| tabela | linhas | último cadastro |
|---|---:|---|
| `tbjobs` | 1.354 | **24/08/2026** — aposentada |
| `tbjobsgeral` | 160 | 05/06/2026 — aposentada |
| **`tarefas_tbjobs`** | **1.329** | **23/09/2026** |
| **`advisory_tbjobs`** | **256** | 18/09/2026 |

**E NÃO É CÓPIA — a hipótese foi testada e descartada.** Entre `tbjobs` e
`tarefas_tbjobs` há **ZERO** linhas que casem por `(projeto, atividade, data_cadastro)` e
**ZERO** por `(id, data_cadastro)`. Os 1.229 ids em comum são **coincidência de sequência
numérica**, não a mesma linha. Somar as duas não duplica nada.

**A chave é composta**, pelo mesmo motivo da `trs_vjob__job`: 1.585 linhas, **1.585
chaves `(origem, id_job)` e apenas 1.330 ids crus** — 255 ids nas duas origens.

**Vocabulário de status DIFERENTE entre as duas origens** — `status` sai cru por isso:
TAREFAS usa `Aprovado` (676), ADVISORY usa **`Feito`** (213). E elas se comportam ao
contrário em quem executa: **TAREFAS é 100% interno** (1.329/1.329), **ADVISORY é 70%
externo** (179/256). Somar num indicador de produtividade interna infla o denominador.

**`checado_em` é campo morto no módulo novo:** ZERO das 1.329 de TAREFAS, contra 66 das
256 de ADVISORY e 1.051 das 1.354 do módulo aposentado. A etapa de checagem sumiu do fluxo.

**Publicada `trs_vjob__job_tarefa`** (`query-tfHg`, 1.585, **L4 por linhagem**). Ela
**não substitui a `trs_vjob__job`** — cobre o período que a outra não cobre, e o corte
está em 24/08/2026. Série histórica de job precisa das duas.

**E a `rfn_operacao__job` foi ESTENDIDA para as duas no mesmo dia** (`query-wpYP`), porque
Trusted não é consumo: até aqui a camada oficial media só o módulo aposentado. Agora são
**3.099 jobs (1.585 vivo + 1.514 aposentado), 3.099 chaves distintas**, e `MAX(data_cadastro)`
passa de 24/08 para **23/09/2026**.
- **A coluna `modulo`** (`APOSENTADO` / `VIVO`, mais `is_modulo_vivo`) é o eixo: série
  histórica usa os dois, produtividade atual filtra `VIVO`. `origem` mantém os quatro
  valores crus — a grafia mista (`tbjobs` minúscula, `TAREFAS` maiúscula) é cosmética e
  **não foi normalizada, porque mexer nela quebraria filtro de quem já consome**.
- **`status_canonico` traduz SETE valores e sai ZERO em `desconhecido`.** `Aprovado`
  (TAREFAS) e `Feito` (ADVISORY e aposentado) são o mesmo estado final → **2.358
  concluídos**. `Aguardando analista` e `Aprovação cliente` (9 jobs) viram `aguardando`,
  canônico novo — não são `pendente` nem `em_andamento`.
- **135 concluídos sem `aprovado = 1`** (132 no vivo), com `flag_concluido_sem_aprovacao`.
- **Zero usuário órfão** nos quatro papéis contra as 272 linhas de `trs_vjob__usuario`.

**A CADEIA FICOU LINEAR, e isso não é detalhe.** `query-tfHg` e `query-4XbY` disparavam as
duas em `query-MZdN`, **em paralelo** — a Refined podia rodar antes de a Trusted nova
materializar e derrubar a query inteira. Agora:
`mysql-yIOn` → `query-MZdN` → `query-4XbY` → `query-tfHg` → `query-wpYP`.
**Ao somar uma Trusted nova a uma Refined existente, conferir se o gatilho garante a
ordem** — evento em paralelo não garante.

**Correção no mesmo dia:** escrevi na `trs_vjob__job_tarefa` que `projeto` é "texto livre".
Não é — são **1.585 de 1.585 valores numéricos** guardados como STRING, mesmo formato da
`tbjobs`. O que continua valendo é que **a tabela-pai de projetos não existe no catálogo**,
então o id não resolve contra nada e continua proibido ligá-lo a cliente.

**Também sem tratamento e vivas:** `tbetapasxclientes2` **7.782 linhas, marcação em
23/09/2026 12:45** e `tbauditoriaclientes` **3.025, marcação em 22/09 19:48**. A primeira
tem sufixo `2` e **não é descarte** — este arquivo lista doze tabelas com sufixo `2`/`3`
como duplicatas, e `tbetapasxclientes2` não é uma delas. **O sufixo não prova descarte;
a data do último evento prova.** Já `tbblogs` (1.323) parou em 18/12/2025.

### 24/09 — o módulo `ia_*` do VJOB está tratado, e a operação de IA custou US$ 14,04

**Cinco tabelas do módulo, cinco Trusted**, todas com gatilho de evento em `query-MZdN` e
alerta de falha ligado: `trs_vjob__ia_cliente_config` (`query-vqwG`, 3, L3) ·
`trs_vjob__ia_documento` (`query-cAhw`, 21, L3) · `trs_vjob__ia_solicitacao`
(`query-GbCw`, 86, L3) · `trs_vjob__ia_geracao` (`query-awpp`, 86, L3) ·
`trs_vjob__ia_geracao_arquivo` (`query-wZoc`, 78, L2).
Detalhe: `docs/nekt/vjob-modulos-vivos-2026-09-24.md`.

**A adoção é de 3 clientes em 315 (0,95%), e só DOIS têm contexto utilizável.** O
`PRESTEX ENCOMENDAS` (136) tem a configuração aberta, `ativo = 1` e **zero caractere** nos
7 campos de conteúdo. `MOVE RENTAL CARS` (336) tem 8.588 caracteres em 5 campos,
`THEREZINHA RUIZ` (339) 3.402 em 6. `fatos_verificados` está **vazio nos três**. Por isso
`qtd_campos_preenchidos` e `flag_config_vazia` existem: um COUNT diria 3.

**Custo da operação de IA: US$ 14,04 em três meses** (US$ 14,043281), maior geração
US$ 0,528973, **um único modelo (`gpt-5.4`) e um único provedor**. 75 das 86 gerações têm
custo; 11 não — os 6 `erro`, os 3 `aguardando_configuracao` e **2 concluídas sem
explicação na base**. Nos onze, `custo_estimado_usd` sai **NULL, nunca zero**.

**A cadeia fecha e isso foi medido:** das 86 solicitações, **73 das 75 concluídas têm
arquivo e NENHUMA das 11 não concluídas tem**. 78 arquivos (59 PNG, 19 SVG).

**ERRO MEU, corrigido no mesmo dia.** Publiquei na descrição da `trs_vjob__ia_solicitacao`
que "a peça gerada NÃO está aqui, não há coluna com o que a IA devolveu". **Há** —
`ia_geracoes`, 86 linhas, com `resultado` (4.314 caracteres em média), `modelo`,
`uso_json` e `custo_estimado_usd`. Eu procurei a tabela-pai pela busca semântica do
catálogo, recebi "não encontrada" e concluí que não existia, **sem contar as linhas dela**.
Um `COUNT(*)` respondeu 86. **Busca semântica que não devolve a tabela não prova que a
tabela não existe — conferir com `COUNT(*)` antes de afirmar ausência.**

### 24/09 — `tbclientexservico` não recebeu Trusted, e a decisão está medida

6.094 linhas, 265 valores de `id_cliente` (**969 com `id_cliente = 0`**), 1.740 sem
gestor, período 05/03/2023 a **06/10/2026** (futuro). É um **checklist de entrega** com
dez itens, cada um com flag, data e texto.

**Das ~60.940 células de flag possíveis, SETE estão preenchidas** — `kv` 4 e
`planejamento` 3. Os outros oito itens são **zero em todas as 6.094 linhas**.

Uma Trusted sobre ela emitiria dez colunas constantes zero, que é exatamente o erro já
declarado sobre o `stats` do GitHub: emitidas, convidariam a somar e obter zero, que é um
número, quando o certo é ausência. **A Raw continua lá — não se apaga nada.** O que não
se faz é apresentar como indicador de entrega uma tabela que ninguém preencheu.

### 24/09 — as duas maiores tabelas vivas do VJOB que faltavam

**`tbetapasxclientes2` → `trs_vjob__etapa_cliente`** (`query-DYWJ`, 7.782, L2).
**O sufixo `2` não prova descarte.** Este arquivo lista doze tabelas com sufixo `2`/`3`
como duplicatas descartáveis; `tbetapas2` é uma delas, **esta não é**. Ela recebeu
marcação em **23/09/2026 12:45**. Conferir a data do último evento antes de descartar
por nome.
**Ela tem TRÊS estados, não dois:** `ativo` é NULL em **3.790 das 7.782 (48,7%)** e
**nenhuma dessas tem marcação** — nem uma. A taxa de marcação muda de sentido conforme o
denominador: **18,6% sobre a tabela inteira, 36,3% sobre as ativas**. `flag_nunca_ativada`
existe para ninguém dividir pelo denominador errado sem perceber. Mais 24 linhas marcadas
sem que o sistema registrasse quem.

**`tbauditoriaclientes` → `trs_vjob__auditoria_cliente`** (`query-LQ5u`, 3.025, L2),
última marcação **22/09/2026 19:48**.
**Aqui a conclusão SEMPRE data a ação, ao contrário do escopo:** `status = 1` são 1.544 e
`datahoramarcacao` preenchida são 1.544 — **zero exceções nas duas direções**. Série
temporal de auditoria cobre **100%** das conclusões; a de escopo cobre 84%. A invariante
virou coluna (`flag_status_sem_carimbo`, hoje FALSE em 3.025 de 3.025) para que uma quebra
futura apareça sem ninguém precisar lembrar de conferir.
**O setor resolve pela metade:** dos 5 ids presentes (3, 4, 6, 7, 8), só 3 existem em
`tbsetor` — 584 linhas ficam sem rótulo e 2.441 resolvem.
**`id_servico` aqui NÃO é dimensão de serviço:** 1.339 valores distintos em 3.025 linhas,
faixa 2 a 1.393. Não juntar com `trs_vjob__servico` (38) nem com `tbservicoscronograma`
(30).

**O buraco de cadastro aparece nas duas**, consistente com o resto do VJOB: **1.372 de
3.025 (45,4%)** e **882 de 7.782 (11,3%)** apontam para cliente que não existe em
`tbclientes`. Joins LEFT com flag — com INNER, 45% da auditoria sumiria sem sinal.

### 24/09 — `trs_vjob__job_responsavel`: o lado N que as duas tabelas de job declaravam faltar

**Publicada** (`query-tc97`, Trusted, **L2 INTERNAL**, gatilho de evento em `query-tfHg`,
alerta ligado). **1.381 linhas, 1.267 jobs.**

A `trs_vjob__job_tarefa` e a `rfn_operacao__job` diziam as duas, na limitação 3, que "o
responsável é o do cabeçalho e há um só". **Medido: a limitação era real** — **101 dos
1.267 jobs têm mais de um responsável, até seis**. Contar trabalho pelo cabeçalho
subconta colaboração em 8% dos jobs.

**Duas invariantes medidas, e as duas viraram coluna:**
1. **Exatamente um principal por job** — 1.267 de 1.267, zero sem e zero em duplicidade.
2. **O principal nunca contradiz o cabeçalho** — 1.267 batem, **zero divergem**. Então a
   tabela **acrescenta** responsável e nunca corrige o que a outra já diz; as duas se
   leem juntas sem conflito.

**62 dos 1.329 jobs (4,7%) não têm linha aqui**, e não é defeito: o satélite começa em
30/06/2026 e o módulo de job em 04/03/2026. **Join a partir do job tem de ser LEFT.**

**Mais um caso de metadado velho:** o DDL do catálogo dizia 1.329 linhas; são **1.381**.
E `responsavel_externo_id` está **vazio nas 1.381** — o módulo prevê externo e ninguém
usou, então sai como ausência declarada, nunca zero.

### 24/09 — `trs_vjob__job_prazo_alteracao`: quando o prazo muda, ele adia

**Publicada** (`query-l08y`, Trusted, **L2**, gatilho em `query-tfHg`, alerta ligado).
**224 linhas, 180 jobs**, unindo os históricos de prazo dos três módulos.

**De 224 alterações, 214 foram adiamento (95,5%)** — e no módulo aposentado foram
**123 de 123, cem por cento, nenhuma antecipação em toda a história dele**. As 10
antecipações da base inteira estão todas no módulo vivo. Deslocamento médio **+10,2
dias**; o maior adiamento foi de **365**. 24 pessoas já alteraram prazo.

**A cobertura é 5,8% e tem de vir junto com o número:** 180 jobs de 3.099 tiveram prazo
alterado. **Isso não quer dizer que os outros 2.919 cumpriram o prazo** — quer dizer que
o prazo deles nunca foi editado. Alteração registrada não é medida de atraso; atraso se
mede na `rfn_operacao__conformidade_cliente`, que compara marcação contra prazo.

### 24/09 — a Refined de conformidade: `rfn_operacao__conformidade_cliente`

**Publicada** (`query-ecYs`, Refined / `operacao`, **L2 INTERNAL**, alerta ligado).
Grão: uma **origem**, um cliente, um mês. **510 linhas** — 83 AUDITORIA + 427 ETAPA.
Responde: *do que estava previsto para o cliente no mês X, quanto foi marcado — e quanto
dentro do prazo.*

**Os dois instrumentos cobrem clientes quase disjuntos, e isso decidiu o formato:** 46
clientes na auditoria, 169 na etapa, **só 17 nos dois** (198 no total). Tabela larga com
as duas lado a lado seria quase toda NULL. **Não somar as duas origens num indicador
único** sem dizer que o denominador muda.

**O ACHADO: a maioria das marcações acontece DEPOIS do prazo, nas duas.** Auditoria
**65,7%** (1.014 de 1.544), etapa **60,8%** (879 de 1.447). E é atraso de **registro ou
de entrega** — a base não separa os dois, então dizer "entregou atrasado" é afirmar o
que ela não afirma.

**ERRO MEU, pego antes de publicar, e ele teria feito a tabela mentir.** Tratei o `ativo`
da auditoria como se não significasse nada e deixei o denominador bruto. Medido:
`ativo = 1` tem **1.563 itens com 1.542 marcados (98,7%)**; `ativo = 0` tem **1.462 com
apenas 2**. É o mesmo mecanismo da etapa — **item inativo não é item atrasado, saiu do
checklist**. Com o denominador bruto a taxa da auditoria sairia **51,04%** em vez de
**98,66%**. A etapa vai de 18,59% para **36,27%**. `qtd_itens` e `qtd_itens_ativos`
convivem, e a taxa usa o ativo **nos dois lados da razão** — 2 marcações da auditoria e 1
da etapa caem sobre item inativo e ficam fora do numerador.
**A regra geral:** quando uma tabela tem flag de ativação, **medir a taxa de marcação por
valor da flag antes de escolher o denominador**. Se os inativos não são marcados, eles não
são atraso.

**Seis regras numeradas**, entre elas: `mes_referencia` é o mês do **prazo**, nunca o da
marcação (contar pela marcação inverte o sinal — erro que o derivado do escopo já
produziu); zero de conclusão é **NULL, nunca zero** (350 células na etapa, 3 na auditoria);
`taxa_pontualidade` tem o **marcado** como denominador, não o previsto.

**Identidade resolve bem na etapa e mal na auditoria:** 132 dos 169 clientes da etapa têm
CNPJ (77% dos itens ligam a documento), contra **17 dos 46** da auditoria, onde 45,4% dos
itens não têm cadastro.

**Cadeia linearizada de novo:** `query-LQ5u` → `query-DYWJ` → `query-ecYs`. As duas
Trusted disparavam em paralelo em `query-MZdN` e a Refined podia rodar antes de uma delas
materializar.

**Correção de catálogo:** `tbsetor` tem **17 linhas e começa no id 5** (5 Diretoria,
6 Inbound Marketing, 7 Social Media, 8 Account Manager, 9 Criação, depois 11–24), não no
id 11 como este arquivo dizia. O que continua verdadeiro é que `tbjobsgeral.id_setor = 1`
não resolve contra ele.

**Nenhuma das OITO Trusted publicadas em 24/09 materializou ainda**, e as regras da suíte
de qualidade sobre elas só entram depois — referenciar tabela não materializada derruba a
query inteira.


### Permissionamento — o que está concedido, e a ressalva que decide tudo

**Medido em 2026-09-23, só leitura.** Detalhe: `docs/nekt/permissionamento-2026-09-23.md`.
**Nada foi alterado** — conceder e revogar acesso muda o que pessoas reais enxergam, e isso
não é default técnico. A R-005 cobre construir, alterar e excluir **na Nekt como dado**; não
cobre mexer no acesso de gente.

**Três grupos, dois criados em 23/09 às 11:17 e 11:18** — o permissionamento começou a ser
montado antes desta sessão chegar em classificação.

| grupo | descrição | pessoas | concessões |
|---|---|---:|---|
| `All` | automático | 9 | `manager` só em **Sample data** |
| `Administrador_` | "visão geral do data lake" | 3 | `manager` em **16 camadas**, inclusive Raw, Trusted e Refined |
| `Usuário_comum` | "apenas_google ADS-facebook_ADS" | 5 | **NENHUMA** |

**`Usuário_comum` não tem concessão nenhuma.** O grupo existe, tem 5 pessoas e o nome promete
Google Ads e Facebook Ads — **zero linhas de permissão apontam para ele**. A intenção está no
nome; a concessão não foi feita.

**As tabelas L3 e L4 de hoje são, por concessão, acessíveis só às 3 pessoas do
`Administrador_`** — que é a postura certa para margem e folha.

**A RESSALVA QUE DECIDE TUDO, e ela já estava escrita na descrição da camada "Gestão de
Projetos do iClips" desde 17/09:** *"no plano Starter a permissão em nível de dado não existe
e **TODO membro do workspace tem nível Manager por padrão, concessão ou não**"*. **O plano não
é verificável pelo MCP.** Então o quadro acima descreve as concessões **registradas**, não
necessariamente o acesso **efetivo**. Se o workspace estiver em Starter, os 9 membros têm
Manager em tudo — inclusive na Trusted com a folha nominal e na Refined com a margem por
cliente. **Conferir o plano em Workspace Settings › Billing é o primeiro passo, e é o único
que muda a leitura.**

**Três concessões individuais** a uma mesma pessoa (id 3701), todas `viewer`: `RD_marketing` e
duas camadas que **não aparecem em `list_layers`**. Pela armadilha já registrada o mais
provável é que sejam `_g_ads`, **mas isso é inferência, não medição.**

### ERRO COMPENSADO — dois defeitos de fuso que se anulavam no VJOB

**Achado em 2026-09-23, ao corrigir a `trs_vjob__job`.** É o tipo de defeito mais perigoso
desta base, e merece regra própria.

A `trs_vjob__job` **somava** 3 horas (`TIMESTAMP(dt,'America/Sao_Paulo')` sobre valor local).
A `rfn_operacao__job`, por cima, fazia `DATE(data_cadastro, 'America/Sao_Paulo')`, que
**subtrai** 3 horas. **O resultado saía certo por acidente** — dois defeitos se anulando.

**Consertar metade quebraria o todo.** Ao corrigir só a Trusted, a Refined passaria a
subtrair 3h de um valor já certo: **13 dos 1.514 jobs** (cadastrados entre 00:00 e 03:00)
mudariam de dia, arrastando junto `mes_referencia` — a chave de agregação temporal — e
`flag_entrega_antes_cadastro`. As duas foram corrigidas na mesma sessão.

**A regra:** ao corrigir fuso numa Trusted, **conferir sempre o que a Refined faz por cima**.
E o inverso vale igual. Erro compensado não aparece em contagem, não aparece em unicidade e
não aparece no resultado final — só aparece quando alguém mexe num dos lados.

**Varredura feita no mesmo dia, e o resto está limpo:** `trs_iclips__peca_atributo` foi
comparada contra a `supabase_public_fato_atividade` em três colunas de timestamp
(`play_start_date`, `project_entry_date`, `play_end_date`) e os valores são **idênticos** —
nenhuma conversão aplicada. `trs_vjob__usuario` não converte nada (usa `fetched_at` direto).

**Cadeia do VJOB depois da correção:** `mysql-yIOn` (domingo 00h) → `query-MZdN`
(`trs_vjob__cliente`) → duas ramificações: `query-Ty76` → `query-lCot` → `query-V3c3`
(escopo) e `query-4XbY` (`trs_vjob__job`) → `query-wpYP` (`rfn_operacao__job`).
**Alerta de falha ligado nas duas do ramo de job** — estava desligado nas duas.

### DOCUMENTO — cinco formas de errar CNPJ, todas medidas em 2026-09-23

**Corrigidas no mesmo dia, nas cinco tabelas que decidem identidade:**
`trs_financeiro__movimento` (`query-NnxD`), `rfn_cadastro__cliente_sk` (`query-4ZDe`),
`trs_vjob__cliente` (`query-MZdN`), `rfn_operacao__peca` (`query-jdUw`) e
`trs_pi__insercao` (`query-iX2P`).

**1. O CNPJ que perdeu o zero à esquerda — R$ 157.945,50 fora de toda junção.** No financeiro,
**123 lançamentos e 4 documentos** chegam com **13 dígitos**: o CNPJ foi guardado como número
em algum ponto do caminho e comeu o zero inicial. O efeito é silencioso e total — 13 dígitos
não é 14 nem 11, então `contraparte_is_pj` e `contraparte_is_pf` davam **FALSE nos dois**, e a
linha ficava fora de qualquer junção por documento. **A prova de que é a mesma empresa** é que
os quatro, depois do `LPAD`, existem na própria base na forma de 14 dígitos, com a mesma razão
social nos dois lados: INTELICOM (R$ 48,01 contra R$ 9.904,87), MERCANTIL NOVA ERA (R$ 211,76
contra R$ 42.393,70), RÁDIO TARUMÃ (R$ 411,40 contra R$ 307.760,47) e SOCIEDADE FOGÁS
(**R$ 157.274,33** contra R$ 1.684.835,81).

**A regra de correção não é "padroniza número curto".** O `LPAD` só é aceito quando o valor
corrigido **já existe** entre os documentos de 14 dígitos da própria tabela — **o conjunto de
documentos válidos é a autoridade, nunca a aritmética sozinha**. Número de 12 ou 13 dígitos que
não case com nada segue intacto e continua fora das junções, que é o certo.

**2. A máscara do formulário preenchida pela metade.** `MOVE RENTAL CARS` (VJOB 335 e 336) e
`MOVE COMPANY LLC` (financeiro) trazem `87.176.853/4___-__` — **9 dígitos**. Não é CNPJ, é
prefixo. O `cliente_sk` antigo fundia os três num `DOC:871768534`; **agrupar por prefixo é o
mesmo erro de agrupar por rótulo**. Agora os três ficam ISOLADO e o fragmento vive em
`candidato_sk_por_documento_parcial`. (Move Company LLC é empresa americana — é plausível que
não tenha CNPJ para preencher.)

**3. `tem_cnpj` significava "preenchido", não "válido".** Era o que a suíte de qualidade
apontou. No `trs_vjob__cliente` a flag acendia nos dois cadastros Move **e o fragmento saía em
`cnpj_digitos`, que é a chave de junção**. Agora `cnpj_digitos` só existe com 14 dígitos,
`cnpj_digitos_origem` preserva os dígitos como vieram e `flag_cnpj_invalido` marca o caso.
**A contagem de CNPJ do VJOB cai de 168 para 166** — mudança de sentido, não de dado.

**4. String vazia não é documento — e ela bloqueava o fallback declarado.** Na
`rfn_operacao__peca`, 6 peças da CAA ALUMÍNIO chegavam com `cliente_cnpj = ''`. O defeito tinha
**dois** efeitos, e o segundo é o grave: `''` não é NULL, então (a) a peça contava como
documento preenchido e quebrava qualquer filtro `IS NOT NULL`; e (b) `REGEXP_REPLACE` sobre
valor não-nulo devolve não-nulo, então o `COALESCE` da REGRA 1 **nunca caía para o atributo** —
a precedência declarada simplesmente não funcionava nessas linhas. Dois `NULLIF` resolvem.
Medido: `''` cai de 6 para 0, NULL sobe de 4.434 para 4.440, CNPJ e CPF ficam intactos. Neste
caso o fallback não recuperou nada, porque o atributo também vem vazio — **o conserto vale pelo
mecanismo, não pelas 6 linhas**.

**E `cliente_identificado` significa PJ POR CNPJ, não "cliente resolvido".** Cliente pessoa
física tem documento válido de 11 dígitos e sai FALSE. Desde 23/09 existe `cliente_is_pf` ao
lado, para a distinção não depender de contar dígitos na leitura.

**5. O mesmo zero à esquerda no CNPJ do VEÍCULO do PI — R$ 5,63 milhões.** A suíte
acusava **606 de 3.120 PIs não cancelados (19,4%) "sem CNPJ de veículo"**. Medido: **507
deles TÊM CNPJ**, de 13 dígitos. São **4 veículos**, e os quatro foram confirmados contra a
razão social do financeiro:

| 13 díg. → 14 | rótulo no PI | razão social no financeiro |
|---|---|---|
| `04382099000194` | TV A Crítica | Televisão A Crítica Ltda. |
| `04642799000170` | Rádio Jovem Pan FM - 104,1 | Rádio Tarumã Ltda. |
| `04486636000146` | RÁDIO POP FM | TRANSMISSÃO DE RÁDIO E TELEVISÃO DO NORDESTE LTDA |
| `07625810000182` | GRUPO INTELICOM \| NORTE OUTDOOR | INTELICOM COMUNICAÇÃO E MARKETING LTDA |

**Dois deles são os MESMOS do financeiro** — duas fontes independentes com o mesmo defeito,
o que confirma que o problema é de **armazenamento numérico num ponto comum do caminho**, não
digitação. Medido: **533 PIs repadronizados, R$ 5.630.847,04**, e a cobertura de veículo por
CNPJ nos não cancelados sobe de **80,6% para 96,8%**. Os 99 que sobram não têm CNPJ mesmo
(GLOBO NEGÓCIOS e M3 COMUNICAÇÃO).

**E `cnpj_veiculo` passou a sair em DÍGITOS**, não no texto com máscara — 2.571 das 3.245
linhas preenchidas vinham como `60.628.369/0009-22`. É coluna de junção; comparar com
pontuação já tinha produzido falso conflito na ponte iClips × Facebook.
`cnpj_veiculo_origem` preserva o texto cru.

**A regra geral:** só é documento o que tem **14 dígitos (CNPJ) ou 11 (CPF)**. Qualquer outra
coisa é fragmento, e fragmento não junta ninguém. **Medir o comprimento antes de usar como
chave** — a contagem de linhas não denuncia nenhum dos três casos.

**As contas da margem não mudam por isso:** os 4 documentos repadronizados são clientes que já
tinham a maior parte do movimento sob o CNPJ correto, e os 3 do fragmento não tinham receita
casada com custo. O que muda é que **R$ 157.945,50 deixam de estar invisíveis**.

### Antes de excluir qualquer coisa

- Camada só é excluível quando vazia (tabelas **e** volumes).
- Repontar a fonte **não move dados** — a Nekt re-extrai da API. Para preservar
  histórico, copiar de fato via transformação antes de excluir.
- API do Facebook Ads: janela de lookback de insights é de 37 meses. Histórico mais
  antigo que isso não é re-extraível.
