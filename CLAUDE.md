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
  **11 streams de descarte** — eram "23" até 24/09, quando as 12 supostas duplicatas de
  sufixo caíram na medição. São: backups (`tbarquivosauditoria_bkp_20260120`,
  `tbauditoriaclientes_bkp_20260120`, `tbescopofinal_backup_202505`,
  `backup_tbcronogramadatas_nfse_20260909`), lixeiras (`deleted_tbcronograma`,
  `deleted_tbcronogramadatas`, `deleted_tbcronogramadatas_individual`, `tbexcluidos`,
  `tbexcluidos2`), teste (`tbescopofinalteste`, `__tbjobs__`). **A lista de "12 duplicatas com sufixo `2`/`3`"
  que este bloco trazia ESTAVA ERRADA e foi removida em 24/09:** medido, `acessos2` tem
  **47.857 linhas contra 1.349 de `acessos`**, `tbnoticiasextra2` 3.732 contra 460 e
  `tbatividades2` 28 contra 1. O sufixo não prova descarte — ver o inventário dos 199.
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

### 24/09 — os três satélites de job que faltavam, e uma tabela que quase ficou de fora

Três Trusted publicadas, todas com gatilho de evento em `query-tfHg` e alerta ligado:
`trs_vjob__job_comentario` (`query-D6HS`, 1.290, **L4**) · `trs_vjob__job_arquivo`
(`query-8QxL`, 302, L2) · `trs_vjob__job_recorrencia` (`query-UCso`, 30, L2).

**SÃO TRÊS TABELAS DE COMENTÁRIO, NÃO DUAS.** `tarefas_tbjobs_comentarios` (620) e
`advisory_tbjobs_comentarios` (14) são o módulo vivo; **`tbjobs_comentarios` tem 656 e é
do módulo aposentado** — mais da metade do total. Ela não aparece ao procurar pelo nome do
módulo novo; só apareceu ao procurar explicitamente pelo prefixo antigo. É a mesma lição
do `ia_geracoes`: **busca que não devolve a tabela não prova que a tabela não existe.**

**A colisão de id aqui é quase metade:** 1.290 linhas para **692 ids crus**. Sem chave
composta, 598 comentários desapareceriam numa deduplicação ingênua. Zero órfãos nas três
origens, medido contra a união de `trs_vjob__job` e `trs_vjob__job_tarefa`.

**120 comentários estão vazios — e é desigual entre módulos:** `tbjobs` 103 de 656
(**15,7%**), `tarefas` 17 de 620 (2,7%), `advisory` zero. Vazio de verdade: nenhum tem
`conteudo_html`. Contar comentário como sinal de conversa sem descontar estes superestima
o módulo aposentado em 15,7%.

**A data do último comentário do módulo aposentado é 02/09/2026 11:26:24 — o mesmo
instante da última aprovação de `tbjobs`.** Duas tabelas independentes param no mesmo
segundo: é a confirmação de que aquele módulo foi desligado, não que parou de ser usado aos
poucos.

**`editado_em`/`editado_por` só existem no módulo de TAREFAS.** Nas outras duas origens
saem NULL, e isso é **ausência de coluna, não comentário não editado** —
`flag_edicao_rastreavel` separa os dois. Quem somar `flag_editado` sobre as 1.290 mede
21 edições sobre um universo de **620**, não de 1.290.

**OS 5 ANEXOS COM `upload_token` SÃO EXATAMENTE OS 5 SEM JOB.** Não é coincidência, é o
mecanismo: uploads pelo fluxo de token público que nunca foram amarrados a um job. E **não
é o buraco de cadastro** do resto do VJOB — ali a linha aponta para um id que não existe
mais, aqui ela não aponta para lugar nenhum. Saem em flags diferentes
(`flag_anexo_sem_job` × `flag_job_nao_catalogado`, esta última hoje zero). O token em si
**não é emitido** (§31: secret é L5), como já se fez com o `public_token`.

**`advisory_tbjobs_arquivos` existe com 9 linhas e eu quase a omiti** — o módulo aposentado
é que não tem tabela de anexo. Conferido, não suposto. Último upload **24/09/2026
10:26:26**, de hoje.

**Recorrência é 1,9% da operação:** 30 de 1.585 jobs do módulo vivo, relação 1:1 com o job,
**24 das 30 não terminam nunca**. `ocorrencias` é campo morto (zero nas 30) e sai **NULL,
nunca zero**. A chave aqui **não** é composta, porque a origem é uma só — declarado para
ninguém "padronizar" por simetria e carregar um prefixo sem significado.

### 24/09 — INVENTÁRIO DOS 199 STREAMS DO VJOB, e ele achou defeito no que eu tinha acabado de publicar

**Medido com `COUNT(*)` nas 199 tabelas**, não com o metadado do catálogo. Detalhe e a
contagem completa: `docs/nekt/vjob-inventario-199-streams-2026-09-24.md`.

| | streams | linhas |
|---|---:|---:|
| **Total** | **199** | **354.190** |
| Com Trusted publicada | 33 | 230.976 (65,2%) |
| Descarte declarado | 11 | 11.758 |
| Vazias | 21 | 0 |
| **Sem tratamento e com linha** | **136** | **111.456 (31,5%)** |

`tbescopofinal` sozinha é **55% de tudo**; as 12 maiores somam 87%; e **91 streams têm 10
linhas ou menos**. Todos habilitados, todos FULL_SYNC.

**O INVENTÁRIO ACHOU QUE A `trs_vjob__job_arquivo` ESTAVA FALTANDO 69% DOS ANEXOS.** Publicada
horas antes com 302 linhas, declarando que "o módulo APOSENTADO não tem tabela de arquivo —
conferido, não suposto". **`tbjobs_arquivos` tem 688 linhas.** Corrigida no mesmo dia para
**990, quatro origens**. Junto vieram mais duas: `tbjobs_comentarios_geral` (21) levou a
`trs_vjob__job_comentario` de 1.290 para **1.311**, e `tbjobs_prazo_hist_geral` (1) levou a
`trs_vjob__job_prazo_alteracao` de 224 para **225**.

**`get_relevant_tables_ddl` COM `selected_tables` NÃO É BUSCA POR NOME.** Ela filtra candidatos
semânticos e **omite em silêncio** o que não casou — pedi `tbjobs_arquivos` pelo nome exato e
recebi outra tabela, sem aviso de que a pedida não estava no resultado. **Terceira vez nesta
base:** antes foram `ia_geracoes` (86 linhas declaradas inexistentes) e `tbjobs_comentarios`
(656). **Prova de ausência é `COUNT(*)`, nunca uma busca que voltou vazia.**

**`acessos2` TEM 47.857 LINHAS e é a segunda maior tabela da base.** Este arquivo listava
`acessos2` entre as "12 duplicatas com sufixo 2/3" a descartar. `acessos` tem **1.349** — a com
sufixo é **35× maior**. Mesmo caso já corrigido do `tbetapasxclientes2`. Também maiores que o
original: `tbnoticiasextra2` (3.732 contra 460), `tbatividades2` (28 contra **1**),
`tblinks2`+`tblinks3` (138 contra 92). **O sufixo `2` não prova nada em nenhuma direção —
medir antes de descartar.**

**Três tabelas grandes que nenhuma medição desta base tinha mencionado:** `tbmudancas`
**18.932** (a terceira maior), `sms_logs` **11.054**, `tb_logs_squad` **2.332** — mais
`tbservicoauditoria` 1.387. Contadas, não caracterizadas.

**Uma família inteira fora do medalhão: anexo de COMENTÁRIO**, grão diferente do anexo de job
porque o pai é o comentário — `tarefas_tbjobs_comentarios_arquivos` 498 ·
`tbjobs_comentarios_arquivos` 249 · `advisory` 6 · `geral` 1 = **754 linhas**. E
`tarefas_tbjobs_recorrencia_ocorrencias` (**410**) é o outro lado da
`trs_vjob__job_recorrencia`: 30 regras geraram 410 ocorrências.

**Conta Azul: 2.796 linhas, nenhum tratamento** — `contazul_fornecedores` 1.299,
`contazul_clientes` 661, `contazul_servicos` 403, `contazul_categorias` 382, mais oito menores.

**Os streams sensíveis são 16, não 12**, e a lista completa com linha está no documento.
Acrescentam-se aos 12 já registrados: `acessos2` (47.857, o maior de todos),
`tbrh_renovacoes` (125, L4), `contazul_oauth_conexoes` e `contazul_oauth_config`.

### 24/09 — o anexo de COMENTÁRIO é outra tabela, e o MIME dele mente em 8 linhas

**`trs_vjob__comentario_arquivo`** (`query-uR7K`, **754**, L2, gatilho de evento em
`query-D6HS`, alerta ligado). A família achada pelo inventário dos 199 streams.

**NÃO é a `trs_vjob__job_arquivo` — o pai é outro.** Lá o anexo pende do JOB, aqui do
COMENTÁRIO. Duas tabelas de propósito: juntar num grão só exigiria uma coluna "tipo de pai"
e um id que às vezes é job e às vezes é comentário, que é a receita para somar anexo duas
vezes. **Total de anexos do VJOB = 990 + 754 = 1.744.**

Quatro origens, contadas uma a uma: `tarefas_tbjobs_comentarios_arquivos` 498 ·
`tbjobs_comentarios_arquivos` 249 · `advisory_*` 6 · `tbjobs_comentarios_arquivos_geral` 1.
**499 ids crus para 754 linhas** — 255 colisões, chave composta. O caminho físico confirma o
pareamento: `uploads/comentarios/<id>/` nas três primeiras, `uploads/comentarios_geral/<id>/`
na quarta.

**A IGUALDADE TOKEN = SEM-PAI SE CONFIRMA PELA TERCEIRA VEZ, E AGORA POR ORIGEM.** Dos 754,
**85 carregam `upload_token` e exatamente os mesmos 85 têm `comentario_id` nulo** — e vale
dentro de cada origem: TAREFAS 70 e 70, tbjobs 15 e 15, advisory 0 e 0, geral 0 e 0. É o
mesmo mecanismo do anexo de job (28 e 28), mas **a taxa aqui é 4× maior: 11,3% contra 2,8%**.
Upload pelo fluxo público que nunca foi amarrado ao registro.

**O MIME NÃO CLASSIFICA SOZINHO — 8 de 754 são inúteis e a EXTENSÃO salva 7.**
- **3 anexos têm MIME concatenado e truncado:**
  `application/vnd.openxmlformats-officedocument.wordprocessingml.documentapplication/vnd.openxmlformat`
  — dois tipos colados e cortados no meio. Defeito da origem, não do transporte.
- **4 têm `application/octet-stream`**, o genérico de "não sei".
- 1 tem `application/msword`, que é legítimo (.doc legado).

Os 7 dos dois primeiros casos são **todos `.docx`** pela extensão. `categoria_arquivo` usa o
MIME quando bem formado e **cai para a extensão** quando ele é malformado ou genérico, com
`origem_da_categoria` declarando a rota linha a linha. Medido: **zero em OUTRO e zero sem
categoria**, contra 8 que cairiam se o MIME mandasse sozinho. `tipo_mime` preserva o valor
cru — marcar, nunca apagar.

**NADA DA CADEIA DE COMENTÁRIO MATERIALIZOU AINDA.** A `mysql-yIOn` rodou 11:51→12:43 e as
quatro Trusted de hoje (`job_comentario`, `job_arquivo`, `job_recorrencia`,
`comentario_arquivo`) foram publicadas depois disso — conferido: `trs_vjob__job_arquivo` e
`trs_vjob__job_comentario` respondem `table_not_materialized`. **O deploy passa mesmo assim**
(a Nekt valida o catálogo, não a existência física), e o **gatilho de evento é o que garante
a ordem**: `tfHg` → `D6HS` → `uR7K`. As regras de qualidade sobre as quatro entram quando a
fonte rodar de novo.

### 24/09 — a ocorrência de recorrência: 26% dos jobs do módulo vivo são AGENDA, não entrega

**`trs_vjob__recorrencia_ocorrencia`** (`query-r7ps`, **410**, L2, gatilho de evento em
`query-UCso`, alerta ligado). É o elo que faltava entre as 30 regras
(`trs_vjob__job_recorrencia`) e os jobs (`trs_vjob__job_tarefa`): **quais jobs a máquina
criou, a partir de qual regra, para qual data.**

**A ligação é 1:1 e isso é medido: 410 ocorrências, 410 `job_id` DISTINTOS.** Nenhuma
ocorrência divide job, nenhum job aparece duas vezes. As 30 regras produziram de **1 a 16**
ocorrências cada (média 13,7). **Zero órfãos nos dois lados.**

**O ACHADO QUE MUDA A LEITURA DE PRODUTIVIDADE: 349 das 410 são de data FUTURA.** O
intervalo vai de 04/09 a **23/12/2026** e só 61 já passaram. Como **cada ocorrência já tem
um job criado**, isso quer dizer que **410 dos 1.343 jobs do módulo TAREFAS (30,5%) são
gerados por máquina e 349 deles (26% da tabela) são trabalho que ainda não aconteceu.**
Quem contar job do módulo vivo como produção está contando um quarto de tabela que é
**agenda, não entrega** — `flag_ocorrencia_futura` existe para esse filtro. É o mesmo
mecanismo que já obrigou a recortar janela no escopo, que tem cadastro até 2027.

**A ocorrência guarda o prazo ORIGINAL; o job guarda o VIGENTE — e a diferença nunca é
inexplicada.** `data_entrega` do job é igual a `data_ocorrencia` em **406 de 410**, e os
**4 que divergem têm, todos os quatro, registro em `tarefas_tbjobs_prazo_hist`**. O
deslocamento é de **1 a 3 dias** — nada parecido com os 365 do maior adiamento da base.
`flag_prazo_alterado` torna isso legível sem join, e a invariante vira regra da suíte.

**114 dos 410 jobs recorrentes foram CANCELADOS (27,8%)**, 268 estão `A fazer`, 28
`Aprovado` — e **2 desses estão aprovados com data futura**. A recorrência gera, e mais de
um quarto do que ela gera é descartado.

**As ocorrências vêm em 39 lotes**, de 03/09 11:14:29 a **24/09 09:37:20** (hoje) — o
sistema vai criando conforme a regra avança, não numa geração única.

**`flag_ocorrencia_futura` é relativa à data da CARGA**, não a uma data fixa: a tabela é
reconstruída inteira a cada execução. Para corte histórico estável, comparar
`prazo_planejado` contra a data escolhida, nunca a flag.

### 24/09 — as três tabelas grandes sem tratamento, e duas regras da casa postas à prova

`trs_vjob__cronograma_alteracao` (`query-v4r2`, **18.932**, L2, evento em `query-VxBS`) ·
`trs_vjob__sms_notificacao` (`query-UpoG`, **11.054**, **L4**, evento em `query-MZdN`) ·
`trs_vjob__squad_alteracao` (`query-SLRc`, **2.332**, L2, evento em `query-MZdN`).
Todas com alerta ligado.

#### `id_cronograma` aponta para DOIS universos, e em 46% das linhas não dá para saber qual

`tbmudancas` é o **único log de alteração de dinheiro de contrato** desta base — muda
`valor`, `comissao`, `fornecedor`, `nfse`, `cliente`, em 18 colunas. Mas a coluna chamada
`id_cronograma` casa **ora com o CONTRATO, ora com a PARCELA**, e as duas sequências de id
se sobrepõem: contrato vai de 19 a 7.603, parcela de 75 a 14.633, **4.121 ids existem nos
dois**.

| `alvo_resolvido` | linhas | |
|---|---:|---|
| **AMBIGUO** | **8.786** | **46,4% — indecidível** |
| PARCELA | 6.242 | 33,0% |
| CONTRATO | 3.087 | 16,3% |
| NAO_CATALOGADO | 817 | 4,3% |

**A tabela não escolhe, porque escolher seria inventar.** `id_contrato` e `id_parcela` só
saem preenchidos quando o alvo é inequívoco; em AMBIGUO os dois saem NULL. **Um join direto
por `id_alvo` duplica 8.786 linhas entre as duas pontas e nada na contagem denuncia.**
A hipótese de que a coluna afetada resolveria **foi testada e descartada** — quase toda
coluna casa nos dois lados (`vencimentocontrato` 3.872 × 6.145).

`usuario` é **texto, não id** (42 valores, 953 vazios), e **8 alterações não alteraram nada**
(`valor_antigo = valor_novo`).

#### A regra do repadronizado foi posta à prova e **recusou** a correção

`sms_logs` tem **1.144 envios (10,4%) com o DDI duplicado** — todos os de 15 dígitos e 360
dos de 14 começam com `5555`. Pela aritmética, tirar dois dígitos devolve forma válida.
**E a base não confirma nenhum: dos 1.144 candidatos (21 números), ZERO existem entre os
números canônicos da própria tabela.**

A regra escrita no caso do CNPJ — *"a autoridade é o conjunto de valores válidos, nunca a
aritmética sozinha"* — **vale nas duas direções**. Lá os quatro CNPJs existiam com 14 dígitos
e a correção foi aceita; aqui nenhum existe e **a correção é recusada**. O valor corrigido
fica em `candidato_telefone_repadronizado`, fora da chave, como o
`candidato_sk_por_documento_parcial`.

**A tabela é L4 por uma coluna só:** 79 telefones distintos (56 em forma válida) e a mensagem
carrega nome de cliente. São notificações de etapa vencida — 2.234 mensagens distintas em
11.054 envios, média de 140 por número, **lista fixa de destinatários internos**. E ela diz
que o SMS foi **registrado, não entregue**: não há status, retorno de operadora nem custo.

#### A história do time por cliente, com três movimentos que não se somam

`tb_logs_squad` responde **quem atendeu qual cliente, em qual papel, e quando mudou** — 15
papéis, 187 clientes, 36 pessoas alterando. `tipo_evento` separa **ATRIBUIÇÃO 520 · TROCA
1.687 · REMOÇÃO 73 · SEM_EFEITO 52**: contar "trocas de responsável" junto mistura entrada
de gente com saída.

**Zero é sentinela de "sem responsável", não id** (572 anteriores, 125 novos) — sai NULL.
O buraco de cadastro reaparece: **923 de 2.332 (39,6%)** apontam para cliente que não existe,
consistente com os 45,4% da auditoria. **O autor, ao contrário, resolve 100%** — quem alterou
se sabe sempre; para quem foi alterado, nem sempre.

**Armadilha evitada no código:** as flags de responsável usam **anti-join**, não `NOT EXISTS`
correlacionado — esta base já registrou que o correlacionado não roda no BigQuery quando o
lado direito cresce. Eu tinha escrito com `NOT EXISTS` e troquei antes de validar.

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

### 24/09 — inventário das tabelas tratadas: 97 transformações, 97 tabelas, 1:1

**Medido com `COUNT(*)` na tabela materializada**, nunca com o metadado do catálogo.
Detalhe por tabela: `docs/nekt/inventario-tabelas-tratadas-2026-09-24.md`.

| | tabelas | linhas |
|---|---:|---:|
| Trusted materializada | 69 | **6.115.687** |
| Refined materializada | 17 | **566.846** |
| Publicada, **não materializada** | 11 | — |
| **Total publicado** | **97** | |

**Cada transformação escreve exatamente uma tabela** — 96 ativas mais a `query-ir9k`,
aposentada em 21/08. A conta fecha nos dois lados, e é assim que se sabe que o inventário
está completo: 69 + 17 + 11 = 97.

**Trusted e Refined NÃO se somam** (a Refined lê a Trusted), e **a geração por cliente e a
consolidada também não** — as 27 tabelas por cliente de Facebook e RD cobrem o mesmo dado
das 5 consolidadas.

**Por sistema, materializado:** Google Ads 4.521.554 (8 tabelas) · iClips 731.478 (7) ·
VJOB real 228.433 (17) · RD Station consolidada 227.940 (2) · geração por cliente 215.303
(27) · Facebook consolidada 142.050 (3) · financeiro/PI/Linear 48.732 (3) · mais as duas
`trs_projetos__projeto` da geração anterior (98 viva, 99 aposentada).

**`rfn_qualidade__regra` materializada tem 28 linhas, não 61.** A suíte foi a 61 regras
hoje; a tabela é a execução das 07:12. Publicar não é materializar — vale para ela e para
as 11 pendentes.

**As 11 pendentes têm causa declarada, não esquecimento:** as 8 do VJOB foram publicadas
**depois** da carga da `mysql-yIOn` (11:51→12:43) e entram na próxima passada; as 3 do
GitHub dependem da `github-s0VO`, parada com `401 Bad credentials`.

**`trs_rh__colaborador` está no repositório e NUNCA foi publicada** — a fonte (planilha do
Farol de RH) não existe na Nekt. O cabeçalho do arquivo declara isso e proíbe o deploy.

### 24/09 — O VJOB TEM DOIS CADASTROS DE CLIENTE, e metade dos módulos aponta para o outro

**É a correção mais consequente desta base até aqui.** Detalhe:
`docs/nekt/vjob-136-sem-tratamento-2026-09-24.md`.

`tbclientes` (317) é o cadastro **jurídico** — CNPJ, razão social, responsável.
**`tbclientesatedimentos` (310) é a CONTA DE ATENDIMENTO** — squad, grupo, carteira, classe,
data de contrato, desativação. A ponte é `id_tbclientes`: **310 de 310 preenchidos, 6 sem
correspondente**. Publicada como `trs_vjob__cliente_atendimento` (`query-BuYc`).

**Este arquivo vinha chamando de "buraco de cadastro da origem" o que era FK errada.**
Órfãos medidos contra cada um:

| tabela | vs `tbclientesatedimentos` | vs `tbclientes` |
|---|---:|---:|
| `tbauditoriaclientes` 3.025 | **0** | 1.372 (45,4%) |
| `tb_logs_squad` 2.332 | **0** | 923 (39,6%) |
| `tbauditorias` 56 · `tbarquivosauditoria` 54 | **0** · **0** | 28 · 28 |
| `tbblogs` 1.323 | **2** | 252 |
| `checklist_diario` 2.748 | **5** | 214 |
| `tbetapasxclientes2` 7.782 | 1.856 | **882** |
| `tbescopofinal` 195.163 | 24.778 | **43.329** |

**NÃO É REGRA, É MEDIÇÃO POR TABELA.** Escopo e etapa continuam pendendo de `tbclientes` —
no escopo isso já estava provado por NOME (155 de 156 rótulos casam lá, zero aqui), e a
contagem de órfãos sozinha teria levado à conclusão errada. **Contagem de órfãos não
identifica o pai; confirmar com uma segunda evidência.**

**E NÃO ERA FALTA DE DADO: ERA IDENTIDADE TROCADA.** Dos 46 ids de cliente da auditoria,
**20 encontravam par em `tbclientes` e nos vinte o nome DIVERGE** — zero batem. A
`rfn_operacao__conformidade_cliente`, publicada horas antes, atribuía **nome e CNPJ de outra
empresa** a 20 dos 46 clientes da auditoria e chamava os outros 26 de "sem cadastro".
**Órfão é melhor que falso par:** uma flag acesa é visível, um nome errado não é.

**Três tabelas publicadas foram corrigidas no mesmo dia:**
- `trs_vjob__auditoria_cliente` (`query-LQ5u`) — cliente, setor e serviço passam a resolver
  pela dimensão certa: **0 órfãos nos três** (eram 1.372, 584 e "não existe"). CNPJ sobe de
  **17 para 37 das 46 contas**, 2.282 dos 3.025 itens.
- `trs_vjob__squad_alteracao` (`query-SLRc`) — **0 órfãos** (eram 923), mais nome da conta e
  ponte jurídica com zero nulos.
- `rfn_operacao__conformidade_cliente` (`query-ecYs`) — cada origem resolve contra **a sua**
  dimensão; o join único deixou de existir. Surgem **33 CNPJs presentes nos dois
  instrumentos**, cruzamento antes impossível. **Os números de conformidade não mudam** —
  510 linhas, taxa 98,66% e 36,27% — porque identidade não entra no grão nem no denominador.
  **O que muda é quem é o cliente de cada linha.**

### 24/09 — 6 Trusted novas sobre os 136 streams sem tratamento

**12 dos 136 streams, 55.154 das 111.456 linhas (49,5%).** Não viraram 136 tabelas, e a
decisão está declarada: 91 streams têm ≤10 linhas, vários são junção sem conteúdo e 10
carregam credencial. **Trata o que carrega informação que nenhuma outra tabela carrega.**

| tabela | slug | linhas |
|---|---|---:|
| `trs_vjob__acesso` | `query-OwrE` | **49.206** |
| `trs_vjob__checklist_diario` | `query-OFX4` | 2.748 |
| `trs_vjob__auditoria_servico` | `query-TkGA` | 1.387 |
| `trs_vjob__blog_pauta` | `query-8JWf` | 1.323 |
| `trs_vjob__cliente_atendimento` | `query-BuYc` | 310 |
| `trs_vjob__auditoria_ciclo` | `query-w4wL` | 56 |

- **`trs_vjob__acesso` é L4, NÃO L5** — o inventário dos 199 streams classificava `acessos` e
  `acessos2` junto com os tokens do Conta Azul. Medido: as duas têm **três colunas**
  (`id`, `idusuario`, `datahora`) e nenhuma credencial. É log de **evento**, não de segredo.
  **Duas origens independentes:** zero pares (usuário, data-hora) em comum e janelas que se
  sobrepõem — `acessos` recebeu linha até 11/09/2026. Chave composta por prevenção: as
  faixas de id são disjuntas hoje (1–1.349 e 8.748–56.605), mas são duas sequências.
- **`trs_vjob__auditoria_servico` é a dimensão que a `trs_vjob__auditoria_cliente` declarou
  não existir** — resolve **3.025 de 3.025 itens e 1.339 de 1.339 ids**. **Armadilha de
  nome:** a coluna `categoria` aponta para `tbservicosauditoria` (SUBSERVIÇO), não para
  `tbcategoriasauditoria` — 0 órfãos contra a primeira, 699 contra a segunda. E o setor
  resolve por `tbsetoresauditoria` (5), não pelo `tbsetor` geral (17): **5 de 5**.
- **`trs_vjob__blog_pauta` é a ÚNICA tabela desta base que liga uma entrega à linha de escopo
  que a pediu** — `id_escopo` resolve **1.183 de 1.323 com 1 órfão**, e ela carrega
  `link_iclips`, uma segunda ponte para fora do VJOB. Módulo parado em 18/12/2025.
  **"Publicado" é declaração, não prova:** 1.064 com status, **849 com link, 719 com data**.
- **`trs_vjob__auditoria_ciclo`** — os 56 ciclos somam **exatamente 3.025 itens**, nenhum
  vazio, e 54 finalizados = 54 com data. **36 dos 56 (64%) não registram quem abriu** e os 20
  restantes são da mesma pessoa: um COUNT DISTINCT diria "1 pessoa faz auditoria".
- **`trs_vjob__checklist_diario`** — 2.748 de 2.748 com carimbo (terceiro instrumento da casa
  com cobertura total), **só 8 das 34 atividades do catálogo usadas**, parado em 04/02/2026.

**A cadeia ficou linear:** `mysql-yIOn` → `MZdN` → `BuYc` → `TkGA` → `8JWf` → `OFX4` →
`LQ5u` → `DYWJ` → `ecYs`, mais `w4wL` e `SLRc` pendurados em `TkGA` e `BuYc`.
Alerta de falha ligado nas seis. **Nenhuma materializou ainda** — a `mysql-yIOn` rodou
11:51→12:43 e tudo isto é posterior.

**Os 124 que ficam, com o motivo declarado:** 10 streams de credencial (§31, entre eles
`tbrh_renovacoes` com salário criptografado) · `tbclientexservico` (7 células preenchidas de
~60.940) · `tbnoticiasextra2`+`tbnoticiasextra` (4.192 recibos de leitura para **8** notícias)
· os próximos candidatos reais — **Conta Azul 2.796 em 12 streams** e **`municipio` 5.570
(tem consumidor: `trs_vjob__cliente.id_cidade`)** · e ~70 streams com ≤10 linhas.

### 24/09 — `trs_vjob__municipio`: a dimensão geográfica, e mais um "não existe" desmentido

**`query-ouMW`, 5.570 linhas, L2, gatilho de evento em `query-MZdN`, alerta ligado.**
Origem: `municipio` (5.570) + `estado` (27).

**É a lista oficial completa do IBGE, e isso foi medido, não suposto:** 5.570 linhas,
5.570 ids e **5.570 códigos distintos de exatamente 7 dígitos**, id contíguo de 1 a 5.570,
zero UF órfã. É o número de municípios do Brasil.

**A LIMITAÇÃO 4 DA `trs_vjob__cliente` ESTAVA ERRADA.** Ela dizia que a cidade "não tem
tabela de domínio localizada nesta passagem". Tem — e é o **quarto caso** nesta base de
"a busca não devolveu, logo não existe", depois de `ia_geracoes`, `tbjobs_comentarios` e
`tbjobs_arquivos`. **Prova de ausência é `COUNT(*)`.**

**O consumidor resolve inteiro:** 289 dos 317 cadastros, **ZERO UF divergente** — a UF
escrita no cadastro concorda com a UF do município em todas as linhas. E são apenas
**18 municípios distintos** para 289 clientes: a carteira é geograficamente concentrada.

**Os 10 "órfãos" eram sentinela.** `trs_vjob__cliente.id_cidade` trazia **10 zeros** sem
`NULLIF`, então a tabela contava 299 cadastros "com cidade" quando são **289** — 3,5% a
mais. Corrigido na mesma sessão em `query-MZdN`.

**A REGIÃO FOI PROVADA PELA COMPOSIÇÃO, NÃO HERDADA DE MEMÓRIA.** `estado.Regiao` traz
1 a 5 sem tabela de domínio. Em vez de aplicar a ordem do IBGE de cabeça, o conteúdo foi
medido: 1 = AC/AM/AP/PA/RO/RR/TO (7) · 2 = AL/BA/CE/MA/PB/PE/PI/RN/SE (9) ·
3 = ES/MG/RJ/SP (4) · 4 = PR/RS/SC (3) · 5 = DF/GO/MS/MT (4). Bate exatamente com as cinco
regiões oficiais, 27 UFs, nenhuma fora. **`id_regiao` sai cru ao lado do rótulo** — se a
origem mudar a numeração, o id continua sendo a verdade.

**NOME NÃO É CHAVE, e a margem é grande:** 5.570 municípios para **5.297 nomes distintos**;
**506 (9,1%) carregam nome que existe em mais de uma UF**. Juntar por rótulo funde cidades
de estados diferentes em silêncio. `flag_nome_repetido_no_brasil` e
`qtd_municipios_com_este_nome` tornam o caso visível. A chave interna é `id_municipio`; a
chave universal, para fora desta base, é `codigo_ibge`.

**`codigo_ibge` sai como TEXTO**, não número — é código, não quantidade, mesma doutrina do
`cnpj_digitos`. Aqui não há risco de zero à esquerda (mínimo e máximo são 7 dígitos), mas o
tipo deve impedir que alguém some ou tire média de código.

**Tabela estática:** não tem coluna de tempo, então não há fuso a tratar. Muda quando o
IBGE cria ou funde município, não com a operação da casa.

**O nome da cidade NÃO foi denormalizado na `trs_vjob__cliente`** de propósito: esta tabela
dispara no evento daquela, então ler de volta seria dependência circular. O id fica e o
join está disponível.

### 25/09 — a camada semântica por setor: os 8 documentos que faltavam

**Criados a partir do levantamento VAN-SEM-001 v1.0 (13 abas, emissão 11/09/2026)** cruzado com o
que a plataforma tem hoje. Detalhe: `docs/nekt/camada-semantica-setores-2026-09-25.md`.

**Existiam 4** (Mídia Paga `e3f5674e` · Inbound `05f0c335` · Social Media `e92f630b` ·
Mídia OFF `051ce79c`). **Criados 8:** Planejamento `aa43cbe7` · Criação `20f0af45` ·
Diretoria Executiva `da9d84be` · Financeiro `a034ca75` · Diretoria de Operações `a1fd0966` ·
Account `64dc365b` · RH `51e97cff` · Direção de Arte `8c0555ad`.
**Os 12 setores da planilha passam a ter documento.**

**`e0ee2418` "Criação - camada semântica" NÃO é a leitura do setor** — é o pedido de extração do
Farol (27.344 caracteres: granularidade por apontamento, recorte por colaborador, as 605 grafias de
etapa). Diz *o que extrair*, não *o que o número significa*. Os dois convivem.

**O ACHADO: tudo o que os setores não validados citam está na camada RAW.** A planilha usa nome
curto; o catálogo usa o prefixo da fonte — `vw_inad_titulos_vbot` é
`raw.supabase_public_vw_inad_titulos_vbot`, `gold_vw_fin_cliente` é `raw.supabase_gold_vw_fin_cliente`,
`silver_colaborador_rel` é `raw.supabase_silver_colaborador_rel`, `fato_atividade` é
`raw.supabase_public_fato_atividade`, `vw_funil_faturamento` é
`raw.supabase_conta_azul_vw_funil_faturamento`.

**E a §18 diz que a IA não consulta a Raw.** Então **cinco perguntas de negócio declaradas pelos
setores não têm resposta na camada oficial de consumo**: inadimplência, fluxo de caixa diário,
caixa realizado × projetado, turnover/tempo de casa e "o que está por faturar".
**RH é o caso extremo — não tem nenhuma `rfn_`**, e a `trs_rh__colaborador` do repositório nunca
foi publicada porque a fonte não está conectada. O desbloqueio ali é de acesso, não técnico.

**DECISÃO DE MÉTODO — publicar o não validado, marcando que não foi validado.** Seis setores
devolveram a planilha com **ficha zerada** (sem responsável, sem sistemas, sem frequência): o
conteúdo é pré-preenchimento da plataforma que ninguém confirmou. Não publicar deixaria metade da
casa sem definição; publicar como validado daria autoridade a texto que ninguém assinou. Cada um
desses documentos abre com um bloco declarando **"NÃO validado pelo setor"** e que será substituído
quando a ficha voltar. Dentro deles, **regra de leitura** (medição da plataforma, vale) fica
separada de **definição de negócio** (proposta, pode estar errada), e **anotação `@table::` só para
tabela verificada no catálogo** — o que mora na Raw entra como texto, para não ensinar a IA a
consultar o que a §18 proíbe.

**Cobertura semântica medida:** 3 setores com ficha completa validada (Mídia Paga, Criação,
Planejamento), 1 com ficha completa e indicadores incompletos (Social Media), 1 parcial (Mídia OFF),
6 com ficha zerada. É a resposta da primeira pergunta do setor de Planejamento, e está escrita no
documento dele.

**Ressalva de método, registrada:** o inventário foi feito com três buscas em
`get_semantic_context`, usando o vocabulário distintivo de cada setor. **Busca semântica devolve os
N mais relevantes e não é prova de ausência** — não existe `COUNT(*)` para documento de contexto,
ao contrário do que vale para tabela.

### 25/09 — Conta Azul tratado, e o razão financeiro mudou de sistema em junho/2026

**Quatro Trusted publicadas**, cadeia linear, alerta ligado nas quatro, deploy limpo:
`trs_contazul__entidade` (`query-kwIs`, **1.828**, **L4**, evento em `query-MZdN`) →
`trs_contazul__categoria` (`query-y2xj`, 382, L2) → `trs_contazul__vinculo`
(`query-PdzT`, 10, L2) → `trs_contazul__movimento` (`query-rtu2`, **6.768**, **L4**).
Detalhe: `docs/nekt/conta-azul-2026-09-25.md`.

**ATENÇÃO AO SUJEITO: são DOIS Conta Azul e não têm nada em comum além do nome.**
O **espelho** no MySQL do VJOB (`mysql_vjobvjob_2024_contazul_*`, 12 streams, 2.796 linhas)
é catálogo de entidades e fila de envio, e **não tem valor nenhum**. O **razão** é
`raw.supabase_conta_azul_ca_fato_evento_financeiro` (6.768 parcelas, R$ 49,82 mi), e ele
**não tem nome nem documento de contraparte** — só `id_pessoa` como UUID. Sozinho, nenhum
dos dois identifica quem pagou ou recebeu; o tratamento usa o espelho como **dimensão** do
razão.

**O RAZÃO MUDOU DE SISTEMA EM JUNHO/2026 — e isso corrige o que esta casa vinha dizendo
sobre a janela da margem.** Lançamentos por competência, os dois razões lado a lado:
2026-04 iClips 1.048 × CA 58 · 2026-05 iClips 708 × CA 397 · **2026-06 iClips 13 × CA
1.120** · 2026-07 zero × 1.089 · 2026-08 zero × 1.129 · 2026-09 zero × 614.
A `trs_financeiro__movimento` declara a despesa "completa até 2026-05" e a
`rfn_operacao__custo_peca` fecha o mês por volume de lançamento, descartando 2026-06 em
diante. **Não é mês não fechado — é handoff.** A janela em que a margem existe
(**2022-12 a 2026-05**) é o fim do razão do iClips, **não o fim do dado**.
**O que NÃO foi feito, e por quê:** estender a margem exige decidir a sobreposição de
**2025-12 a 2026-05**, em que os dois razões têm lançamento. É escolha de negócio com risco
de contar o mesmo dinheiro duas vezes — declarada nas descrições, medida, não executada.

**37,7% DO DINHEIRO DO RAZÃO ESTÁ REMOVIDO NA ORIGEM.** 1.518 de 6.768 parcelas têm
`removido_em`, somando **R$ 18.769.466,63 de R$ 49.824.862,25**. Somar sem filtrar infla o
total em **60%** — é a maior armadilha de soma desta base, quatro vezes maior que o PI
cancelado (4,4%). Vivo: saída R$ 14,51 mi, entrada R$ 16,55 mi. A linha fica, com
`is_vigente`/`is_removido`: **toda leitura de valor começa por `is_vigente = TRUE`.**

**`data_pagamento` é 100% NULL e a data da baixa EXISTE.** Zero das 6.768 linhas tem a
coluna preenchida; **3.329 têm a data dentro do JSON `baixas[0].data_pagamento`**. Série de
caixa sobre a coluna devolve **vazio, e vazio parece um resultado**. `data_emissao` também
é 100% NULL e por isso **não é emitida** — mesma doutrina do `stats` do GitHub.

**`status_traduzido` mente sobre a direção:** a origem escreve `RECEBIDO` também em parcela
**a pagar** (1.461 linhas), onde quer dizer **quitado**. `status_canonico` traduz; string
vazia é sentinela em 505 linhas.

**"Transferência entre contas" vem em TRÊS grafias, uma com erro de digitação** —
`transferencia entre contas`, `transferencia entre  contas` (espaço duplo) e
**`tranferencia entre contas`** (sem o `s`). O Conta Azul lança transferência dos **dois**
lados; sem separar, o mesmo dinheiro entra e sai e infla os dois totais (R$ 2,29 mi). O
padrão `tra%sferencia entre%contas` pega as três e a grafia crua fica preservada.

**O FORNECEDOR É CHAMADO DE "VEÍCULO" PELO PRÓPRIO SISTEMA, E NÃO É.** O log
`contazul_sincronizacoes` nomeia a carga de fornecedores de **`veiculos`** e os números
batem exatamente (1.297, depois 1.299) — mas dos **541** documentos válidos de fornecedor
apenas **4** casam com os 92 CNPJs de veículo da `trs_pi__insercao`. **Não usar como
dimensão de veículo de mídia.**

**O MESMO FRAGMENTO DE CNPJ, PELO QUARTO SISTEMA.** O único documento inválido dos 1.828
cadastros é `871768534` — nove dígitos, a máscara `87.176.853/4___-__` pela metade, já
registrada no VJOB (335/336, MOVE RENTAL CARS) e no financeiro (MOVE COMPANY LLC).
**Nenhum `LPAD`:** o valor corrigido não existe entre os documentos válidos desta base.

**SETE CATEGORIAS DUPLICADAS no plano de contas:** 382 categorias para 376 nomes. Seis
pares têm grafia **idêntica** e dois UUIDs — "Custo com time", "Custo com freelancer",
"Ajustes", "Ferramenta", "Sistemas", "Outras Despesas Administrativas". Agrupar custo por
`id_categoria` **parte "Custo com time" em dois**; agrupar por `nome` os junta. A tabela não
escolhe — emite os dois com `flag_nome_duplicado`.

**O DE-PARA DE 10 LINHAS PROVA A DOUTRINA, E DÁ A TERCEIRA CONFIRMAÇÃO DE
`tbclientesatedimentos`.** `contazul_vinculos`: 10 linhas, todas MANUAL, **10 de 10 resolvem
dos dois lados, zero órfãos** — e em **seis** o nome difere nas duas pontas (VANGUARDA
COMUNICAÇÃO → VANGUARDA COMUNICACAO DIGITAL LTDA; OLÁ CASA NOVA → FIT PONTA NEGRA - OLA
CASA NOVA; Veiculação de Mídia → [MÍDIA PERFORMANCE] Comissão Mídia On - RT). Casamento por
nome encontraria no máximo 4 dos 10. E os três vínculos de tipo `cliente` apontam para
**`tbclientesatedimentos`**: a integração que a própria casa escreveu escolheu essa tabela —
evidência independente da contagem de órfãos e do casamento por nome.

**Cobertura medida:** evento → entidade **5.395 de 6.768 (79,7%)**, evento → documento
**4.950 (73,1%)**, categoria com nome 6.314 (93,3%, por duas rotas: o nome vem no próprio
evento em 6.213 e o espelho recupera mais 101). As 822 que não resolvem apontam para pessoa
criada **depois de 17/08/2026**, quando o espelho parou de sincronizar enquanto o razão
recebe dado até 15/09 — não é defeito da junção.

**211 documentos que o Conta Azul conhece e a `cliente_sk` não.** Dos 625 documentos válidos
distintos de cliente, 414 existem em `rfn_cadastro__cliente_sk`, 381 em
`trs_financeiro__movimento` e 122 em `trs_vjob__cliente`. **Não foram incorporados** — é
candidato declarado, não feito.

**CADÊNCIA DECLARADA, E O CUSTO DELA:** o razão é atualizado **diariamente** pela
`supabase-x0tz`, mas a `trs_contazul__movimento` anda **semanal**, porque depende do espelho
de entidade, que vem do MySQL semanal. Pendurar o movimento na `supabase-x0tz` faria a query
rodar antes de a dimensão existir e **derrubaria a query inteira**. Latência de até 6 dias.

**Sete streams não viraram tabela, com o motivo medido:** `contazul_servicos` (403 — o
`nome` não é nome de serviço: **280 das 403 têm mais de 60 caracteres** e são linhas de
descrição de nota fiscal) · `contazul_vendedores` (20, absorvido na entidade como papel) ·
`contazul_empresas` (1, desnormalizado) · `contazul_sincronizacoes` (13 — **não fecha com as
tabelas**: três cargas de serviços registram `recebidos = 5000`, teto de paginação da API,
quando a tabela tem 403) · `contazul_vendas_envios` + `_historico` (2+1 — **envios de
teste**: `motivo = "testes hugo"`, `PI 2147483647`, que é o máximo de um inteiro de 32 bits,
e **zero casamento** com os 105 `contaazul_venda_id` da `trs_vjob__cronograma_parcela`) ·
`contazul_oauth_conexoes` e `contazul_oauth_config` (**nunca** — §31, secret é L5).

**Escopo: uma empresa só.** `empresa_chave` é constante e resolve para
`07.865.616/0001-74`, VANGUARDA COMUNICAÇÃO (razão social `B R M COSTA DE LIMA`). No razão,
`operacao` tem **BRM e VD** e **não tem VBOT**, ao contrário da
`supabase_gold_mvw_fin_cliente`, que tem as três — **as duas fontes não são somáveis**, e a
view é um recorte (medido em 2026-06: R$ 1,21 mi de BRM na view contra R$ 2,37 mi de
`receber` BRM no razão).

**Três das cinco perguntas órfãs da camada semântica ganharam origem governada.** Os
documentos de Financeiro (`a034ca75`) e Account (`64dc365b`) declaram que fluxo de caixa
diário, caixa realizado × projetado e "o que está por faturar" só existem na Raw, que a §18
proíbe a IA de consultar. O razão agora está na Trusted — **falta a Refined que responda, e
ela não foi feita.** Continuam sem resposta: **inadimplência** e **turnover/tempo de casa**
(RH segue sem nenhuma `rfn_`).

**Nenhuma das quatro materializou ainda** — a `mysql-yIOn` roda domingo 00:00
`America/Manaus` e a última execução foi 24/09 12:43. As regras de qualidade sobre elas
entram quando as tabelas existirem.

### 25/09 — a Refined de caixa: `rfn_financeiro__fluxo_caixa` (`query-FDpl`)

**Publicada** (Refined / `financeiro`, **L4 por linhagem**, gatilho de evento em `query-rtu2`,
alerta ligado, deploy limpo). Grão: **uma parcela do razão Conta Azul em um REGIME de caixa**.
Chave `id_fluxo` = `<id_movimento>:<regime>`. **5.237 linhas, 5.237 chaves.**

**Fecha TRÊS das cinco perguntas órfãs da camada semântica** — fluxo de caixa por dia, caixa
realizado × projetado, e aging/inadimplência de BRM e VD. Os documentos de Financeiro
(`a034ca75`) e Account (`64dc365b`) declaravam que essas perguntas só existiam na **Raw**, que a
§18 proíbe a IA de consultar. **Continuam sem resposta:** inadimplência da **VBOT** (operação
que não existe no razão Conta Azul) e "o que está por faturar" antes de virar parcela.

**DOIS REGIMES NA MESMA TABELA, E ELES NÃO DUPLICAM.** REALIZADO usa a data da **baixa** e
`valor_pago` (3.205 linhas, **R$ 21.227.444,68**); PREVISTO usa o **vencimento** e
`valor_nao_pago` (2.032, **R$ 9.793.507,73**). Os dois totais batem **ao centavo** com as somas
do razão. Parcela parcialmente paga aparece nos dois com o valor repartido — 3 casos. Somar a
tabela inteira não duplica; misturar os dois num mesmo gráfico mistura banco com promessa.

**O QUE ENTROU NO BANCO NÃO É O VALOR DE FACE, EM 760 PARCELAS.** `valor_pago + valor_nao_pago`
rompe a face em **772 das 5.250** — 694 para mais (juros, multa), 78 para menos (desconto),
maior diferença **R$ 10.167,16**. Caixa se mede com `valor_caixa`; `valor_face` fica ao lado e
`diferenca_para_a_face` mostra o quanto, com sinal. **Usar a face como caixa erra na linha.**

**A SITUAÇÃO VEM DA DATA, NUNCA DO RÓTULO DE STATUS.** 395 parcelas estão vencidas pela data e
**285 delas NÃO carregam `ATRASADO`** na origem — só 110 carregam. **Filtrar atraso pelo status
perde 72% dos casos.** `situacao`, `dias_vencido` e `faixa_aging` saem todos da comparação de
datas; o status da origem segue visível e não manda em nada.

**AS 16 PARCELAS ZERADAS FICAM DE FORA, DECLARADAS.** `valor_pago = 0` **e**
`valor_nao_pago = 0`, com R$ 30.252,20 de face — não são caixa nem saldo. 5.250 vigentes →
5.237 linhas: 5.234 parcelas, 3 em dois regimes, 16 ausentes. **A aritmética fecha e está
escrita**, para ninguém procurar as 13 linhas que "faltam".

**UMA PARCELA PAGA SEM DATA DE BAIXA (R$ 27.500) entra com o VENCIMENTO**, com
`flag_data_caixa_estimada` acesa. Descartá-la faria o caixa realizado **divergir do razão**;
a alternativa não tomada — deixar sem data — está declarada.

**AGING MEDIDO EM 25/09:** a receber **R$ 1.046.743,14 vencidos** (233 parcelas) contra
R$ 4.815.921,93 a vencer (815); a pagar R$ 481.933,17 vencidos (162) contra R$ 3.448.909,49 a
vencer (822). A inadimplência concentra na primeira faixa: **171 parcelas e R$ 829.218,24 com
até 30 dias**. `is_inadimplencia` exclui TRANSFERENCIA, FINANCEIRO e SOCIOS — transferência
entre contas próprias, mútuo e adiantamento de sócio não são inadimplência de terceiro.

**CAIXA REALIZADO POR MÊS:** 2026-05 R$ 15.501,23 (5 parcelas, cauda da migração) ·
06 R$ 5,40 mi · 07 R$ 7,12 mi · 08 R$ 6,91 mi · 09 (até o dia 15) R$ 1,75 mi.

**A LIMITAÇÃO QUE MANDA: o caixa realizado começa em 25/05/2026.** Não há **uma única baixa**
anterior, embora a competência vá até 2025-02 — o Conta Azul recebeu os saldos em aberto na
migração e só passou a registrar liquidação depois. **Série de caixa antes de junho/2026 não
existe nesta base**, e o iClips, que cobre o período anterior, **não registra data de pagamento
por parcela**. Quem pedir caixa de 2025 não tem resposta em lugar nenhum deste warehouse.

**NÃO SOMAR com `trs_financeiro__movimento` nem com `rfn_financeiro__receita_cliente_mensal`:**
aquelas medem **competência**, esta mede **caixa**, sobre períodos que se sobrepõem de 2025-12 a
2026-05. **São grandezas diferentes, não versões do mesmo número.**

**`valor_caixa` é sempre positivo; `valor_caixa_liquido` tem sinal** (ENTRADA +, SAÍDA −), para
que a soma direta por dia dê o caixa líquido sem ninguém precisar lembrar do sinal.

**Cobertura de contraparte: 73%.** 1.407 das 5.237 linhas (26,9%) não têm contraparte
identificada — ou a parcela não tem `id_pessoa`, ou a pessoa foi criada depois de 17/08/2026,
quando o espelho parou de sincronizar. **Aging por cliente cobre 73%, e a cobertura vai junto
com o número.**

**Ainda não materializou** — entra na próxima passada da `mysql-yIOn` (domingo), depois de
`query-rtu2`. As regras de qualidade sobre ela entram quando a tabela existir.

### 25/09 — as regras de qualidade do Conta Azul, numa SEGUNDA suíte

**`rfn_qualidade__regra_contazul`** (`query-AQjU`, **19 regras**, L2, gatilho de evento em
`query-FDpl`, alerta ligado, deploy limpo). A Nekt detectou exatamente **5 input tables** — as
cinco do Conta Azul; publicado e escrito conferem.

**POR QUE UMA SEGUNDA TABELA DE QUALIDADE, E POR QUE NÃO É DUPLICAÇÃO.** A suíte principal
(`query-wD6c`, 61 regras) dispara em `query-dGga`, que roda **todo dia ~07:10**. A família Conta
Azul dispara em `mysql-yIOn`, que roda **domingo**. Duas consequências:
1. **As cinco tabelas não existem ainda** — publicadas em 25/09, depois da última carga
   (24/09 12:43). Conferido com `COUNT(*)`: as cinco respondem `table_not_materialized`.
   Referenciar tabela não materializada **derruba a query inteira** — somar as 19 regras à suíte
   principal a faria **falhar amanhã às 07:10 e levaria as 61 regras junto, todo dia, até
   domingo**.
2. Aqui elas rodam como **gate de pós-carga**: o gatilho é o último elo da cadeia do Conta Azul,
   então medem a tabela **no instante em que ela acabou de ser reescrita**, não seis dias depois.

**O contrato de colunas é IDÊNTICO ao da suíte principal, de propósito** — `id_regra`, `camada`,
`tabela`, `sistema`, `dimensao`, `regra`, `severidade`, `limiar`, `linhas_avaliadas`,
`linhas_falha`, `linhas_conformes`, `taxa_conformidade`, `is_conforme`,
`flag_sem_linha_para_avaliar`, `resultado`. Um `UNION ALL` entre as duas dá o painel único, e a
coluna `familia` diz de onde veio cada linha. **Fundir é opção futura; hoje seria trocar 61
regras diárias por um erro.**

**AS 19 REGRAS, MEDIDAS ANTES DE PUBLICAR** — todas sobre a Raw e o espelho, reproduzindo a
lógica das Trusted linha a linha, porque as tabelas ainda não existem. **Resultado esperado na
primeira execução: 19 conformes, zero falhas.**
- **ENTIDADE (4)** — `id_entidade` único 1.828/1.828 · `cadastros_nao_divergem` 0 de 1.828 ·
  `documento_tem_forma` 1 falha em 1.053 com dígitos (99,91%) · `tem_documento` 1.052 de 1.828.
- **CATEGORIA (2)** — `id_categoria` único 382/382 · `nome_preenchido` 0 falhas.
- **VÍNCULO (2)** — os dois lados do de-para resolvem, 10 de 10 em cada.
- **MOVIMENTO (6)** — chave 6.768/6.768 · `valor >= 0` · `classe_conhecida` ·
  `data_competencia` · `contraparte_resolvida` 79,7% · `categoria_com_nome` 93,3%.
- **FLUXO (5)** — `id_fluxo` único 5.237/5.237 · `data_caixa_preenchida` · `data_caixa_nao_estimada`
  1 em 3.205 · `movimento_existe` zero órfãos · **a identidade contábil**.

**A REGRA QUE IMPORTA MAIS É UMA IDENTIDADE CONTÁBIL — a segunda desta base.**
`rfn_financeiro__fluxo_caixa.caixa_reproduz_o_razao`: a soma de cada regime tem de reproduzir o
razão (REALIZADO = `SUM(valor_pago)`, PREVISTO = `SUM(valor_nao_pago)` das vigentes). Era
**afirmação na descrição, medida à mão uma vez**; virou teste, com grão **REGIME** — 2 linhas
avaliadas, **diferença ZERO nas duas** (R$ 21.227.444,68 e R$ 9.793.507,73 dos dois lados).
BLOQUEANTE, limiar 1,00. **Se falhar, todo número de caixa desta casa está errado.** É a irmã da
`rfn_operacao__custo_peca.rateio_fecha_no_centavo`.

**UMA REGRA DESTA LEVA EXISTE PARA PIORAR, e isso é o ponto.**
`trs_contazul__movimento.contraparte_resolvida`, limiar **0,75** contra 79,7% medido: o espelho
de entidades parou de sincronizar em **17/08/2026** e o razão recebe dado até hoje, então a
cobertura **cai sozinha a cada semana**. Cruzar o limiar significa que **a sincronização precisa
voltar** — não que o tratamento quebrou. A outra linha de base é
`trs_contazul__entidade.tem_documento` em 0,55: 42% do cadastro não tem documento e isso é da
origem; limiar apertado ali só ensinaria a ignorar a suíte.

**A HIPÓTESE ÓBVIA FOI TESTADA E REPROVADA.** A candidata era *"transferência entre contas bate
nos dois lados"* — o Conta Azul lança a transferência como saída numa conta e entrada na outra.
**Medido: não batem.** Nas 115 linhas vigentes de TRANSFERENCIA a entrada soma
**R$ 1.145.265,94** e a saída **R$ 835.452,42** — **R$ 309.813,52 de diferença**, um lado sem
par. Publicar como regra criaria falha permanente que ninguém pode resolver, que é o que ensina a
ignorar a suíte. Fica como **achado**: somar a classe TRANSFERENCIA dá um líquido de R$ 309 mil
que é **artefato de pareamento, não dinheiro**, e reforça por que `is_caixa_operacional` a exclui.

**A casa passa a ter 80 regras de qualidade em duas tabelas** — 61 diárias na suíte principal e
19 semanais na do Conta Azul. Nenhuma das 19 rodou ainda: entram na próxima passada da
`mysql-yIOn`, depois de `query-FDpl`.
