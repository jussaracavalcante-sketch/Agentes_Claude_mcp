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
  - **Módulo de JOB (tarefas) — parado.** `tbjobs` (1.354 jobs): último cadastro
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

- **"Linear está vazio" é FALSO — ele tem 230 issues.** Medido em 2026-09-21 em
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

- **GitHub (`github-s0VO`) tem 3 tabelas pequenas e reais na Raw.** Medido em 2026-09-21:
  `github_repositories` 10 linhas, `github_pull_requests` 16, `github_commits` 775. O esquema
  é largo e muito aninhado (o struct `head`/`base` do PR carrega o repositório inteiro
  repetido), então a Trusted aqui é sobretudo desaninhamento — não há métrica a preservar.

### Antes de excluir qualquer coisa

- Camada só é excluível quando vazia (tabelas **e** volumes).
- Repontar a fonte **não move dados** — a Nekt re-extrai da API. Para preservar
  histórico, copiar de fato via transformação antes de excluir.
- API do Facebook Ads: janela de lookback de insights é de 37 meses. Histórico mais
  antigo que isso não é re-extraível.
