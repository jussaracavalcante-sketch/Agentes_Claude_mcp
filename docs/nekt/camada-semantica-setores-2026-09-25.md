# Camada semântica por setor — os 8 documentos que faltavam

**Criados em 2026-09-25**, a partir do levantamento **VAN-SEM-001 v1.0** (emissão 11/09/2026,
13 abas) cruzado com o que a plataforma Nekt de fato tem hoje.

## O que existia e o que faltava

Inventário levantado com três buscas em `get_semantic_context`, usando o vocabulário distintivo de
cada setor. **Ressalva de método:** busca semântica devolve os N mais relevantes e não é prova de
ausência — o equivalente ao `COUNT(*)` não existe para documento de contexto. Três buscas
independentes com os termos exatos (turnover, ATIVO_INCONSISTENTE, inadimplência, MRR,
flag_projecao, grupo econômico, tempo de ciclo da peça, lacuna de dado) não devolveram nenhum
documento dos sete setores ausentes.

| Setor | Situação antes | Ação |
|---|---|---|
| Mídia Paga | `e3f5674e` | já existia |
| Inbound | `05f0c335` | já existia |
| Social Media | `e92f630b` | já existia |
| Mídia OFF | `051ce79c` | já existia |
| **Planejamento, Estratégia e Inovação** | **ausente** | criado `aa43cbe7` |
| **Criação** | ver nota | criado `20f0af45` |
| **Diretoria Executiva** | ausente | criado `da9d84be` |
| **Financeiro / Controladoria** | ausente | criado `a034ca75` |
| **Diretoria de Operações** | ausente | criado `a1fd0966` |
| **Account (Atendimento)** | ausente | criado `64dc365b` |
| **Recursos Humanos** | ausente | criado `51e97cff` |
| **Direção de Arte** | ausente | criado `8c0555ad` |

**Nota sobre Criação:** existia `e0ee2418` "Criação - camada semântica", **27.344 caracteres** —
mas é outro documento. Aquele é o **pedido de extração** do Farol da Criação (granularidade por
apontamento, recorte por colaborador, normalização das 605 grafias de etapa). Diz *o que extrair*;
não diz *o que o número significa*. Os dois convivem e o novo aponta para ele.

**Resultado: os 12 setores da planilha têm documento na camada semântica.**

---

## O achado que mais muda trabalho

**Todas as tabelas que os setores não validados citam existem — e estão na camada Raw.**
A planilha usa nomes curtos; o catálogo usa o prefixo da fonte.

| Citado na planilha | Nome real no catálogo | Setor |
|---|---|---|
| `vw_inad_titulos_vbot` | `raw.supabase_public_vw_inad_titulos_vbot` | Financeiro |
| `vw_fluxo_caixa_diario` | `raw.supabase_public_vw_fluxo_caixa_diario` | Financeiro |
| `ca_fato_evento_financeiro` | `raw.supabase_conta_azul_ca_fato_evento_financeiro` | Financeiro |
| `gold_vw_fin_cliente` | `raw.supabase_gold_vw_fin_cliente` | Executiva |
| `gold_vw_fato_dfc_dia` | `raw.supabase_gold_vw_fato_dfc_dia` | Executiva |
| `silver_colaborador_rel` | `raw.supabase_silver_colaborador_rel` | RH |
| `fato_atividade` | `raw.supabase_public_fato_atividade` | Account, Dir. Arte |
| `vw_funil_faturamento` | `raw.supabase_conta_azul_vw_funil_faturamento` | Account |

**A §18 da arquitetura diz que a IA não consulta a Raw.** Então cinco perguntas de negócio
declaradas pelos setores **não têm resposta na camada oficial de consumo**:

- inadimplência por cliente e faixa de atraso (Financeiro)
- fluxo de caixa diário por conta (Financeiro)
- caixa realizado × projetado (Executiva)
- turnover e tempo de casa (RH — **o setor não tem nenhuma `rfn_`**)
- o que está por faturar (Account)

Isso não é falha de nomenclatura: é a fila de trabalho da plataforma, e cada documento declara a
sua parte dela.

---

## A decisão de método: publicar o não validado, marcando que não foi validado

Seis setores devolveram a planilha com a **ficha zerada** — sem responsável, sem sistemas, sem
frequência. O conteúdo deles é pré-preenchimento da plataforma que ninguém confirmou.

**Duas saídas ruins:** não publicar deixa a plataforma sem definição nenhuma para metade da casa;
publicar como se fosse validado dá autoridade a texto que ninguém assinou.

**O que foi feito:** publicar, com um bloco de procedência no topo de cada documento dizendo, com
todas as letras, que **não foi validado pelo setor** e que quando a ficha voltar o documento é
substituído. É o mesmo princípio de "marcar, nunca apagar" e de "a cobertura vai junto com o
número".

Separação dentro de cada documento:
- **regras de leitura** — medições da plataforma, valem independentemente da validação;
- **definições de negócio** — propostas, podem estar erradas;
- **anotações `@table::`** — só para tabelas verificadas no catálogo. O que a planilha cita e mora
  na Raw entra como texto, não como anotação, para não ensinar a IA a consultar o que a §18 proíbe.

---

## Cobertura semântica da casa, medida

Dos 12 setores: **3 com ficha completa validada** (Mídia Paga · Criação · Planejamento),
1 com ficha completa e indicadores incompletos (Social Media), 1 com ficha parcial (Mídia OFF),
**6 com ficha zerada, 1 sem devolução**.

Essa é a resposta medida da primeira pergunta do setor de Planejamento — "índice de cobertura
semântica" — e está escrita no documento dele.
