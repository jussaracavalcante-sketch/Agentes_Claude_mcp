# Duas suítes novas de qualidade — Gmail e Mídia — e a suíte principal virou grande demais

**Publicadas em 2026-09-29**, deploy limpo e alerta ligado nas duas.

| suíte | slug | regras | gatilho | cadência |
|---|---|---:|---|---|
| `rfn_qualidade__regra_gmail` | `query-dWvx` | **9** | evento em `query-TXoY` | diária |
| `rfn_qualidade__regra_midia` | `query-4tgF` | **24** | evento em `query-SGbQ` | semanal (terça) |

**A casa passa a ter 136 regras em quatro tabelas** — 84 diárias na principal, 19 semanais no
Conta Azul, 9 diárias no Gmail, 24 semanais em Mídia.

---

## A cobertura estava pior do que parecia

Inventário feito hoje sobre as 109 tabelas tratadas do repositório: **48 tinham regra e 61
não**. As duas maiores lacunas eram **o negócio principal da casa** e **a maior Trusted
recém-materializada**:

- **Mídia: 4,4 milhões de linhas sem uma única regra** — conta 88 · campanha 827 · termo de
  busca **3.096.346** · faixa etária 296.566 · gênero 143.895 · geográfico 74.245 ·
  localização 827.446 · campanha do Facebook 1.233. A suíte principal só cobria as duas
  tabelas de insight diário.
- **Gmail: 32 rótulos e 32.911 mensagens**, materializadas na madrugada de hoje, sem nenhuma.

---

## Por que suítes separadas, e por que o motivo é novo

A segunda suíte (Conta Azul) nasceu de dois motivos: **as tabelas ainda não existiam** e a
**cadência era outra**. Nenhum dos dois vale aqui — Gmail e Mídia já materializaram, e o
Gmail roda diária igual à principal.

**O motivo agora é o TAMANHO, e ele é a armadilha que esta casa já registrou contra si
mesma.** A `rfn_qualidade__regra` está com **57 KB e 84 regras**, e `update_transformation`
substitui o **código inteiro**: somar 9 regras exigiria reescrever 57 mil caracteres **sem
errar um**.

É literalmente o caso de *"query grande demais é query que não se conserta"*, que nas duas
Trusted de Google Ads (76 mil e 45 mil caracteres) **manteve o Grupo Unipar fora do consumo
por meses depois de o acesso ter sido resolvido**. **A suíte principal atingiu esse
tamanho** — e isso é um achado sobre a própria casa, não só sobre esta publicação.

A **alternativa não tomada** está declarada nas duas descrições: reescrever a principal
inteira, arriscando derrubar 84 regras diárias por uma divergência de um caractere.

**O contrato de colunas é idêntico nas quatro**, de propósito — um `UNION ALL` dá o painel
único e `familia` diz de onde veio cada linha.

---

## A regra que importa mais é uma DESIGUALDADE — a primeira desta casa

Cada breakdown do Google Ads é um recorte do **mesmo** investimento da campanha. Logo, a
soma dele por **(campanha, dia)** **nunca pode passar** do total de
`trs_google_ads__insight_diario`. Se passar, **o grão duplicou — e nada na contagem de linhas
denuncia**, exatamente como no grão misto ANUNCIO/CAMPANHA.

É irmã do `rateio_fecha_no_centavo` e do `caixa_reproduz_o_razao`, mas é a primeira que testa
uma **desigualdade** em vez de uma identidade.

| breakdown | pares avaliados | excedem |
|---|---:|---:|
| termo de busca | 29.389 | **0** |
| faixa etária | 33.786 | **0** |
| gênero | 33.786 | **0** |
| geográfico | 42.472 | **0** |
| **localização** | 42.449 | **7** |

**E os 7 foram investigados antes de virar limiar.** Somam **R$ 3,43**; o maior excesso é de
**R$ 0,79 sobre R$ 54,06**. São de janeiro/2025, 4 campanhas, e **todos carregam os dois
valores de `local_e_alvo`** — ou seja, **não é a partição que quebrou**. É arredondamento do
próprio Google na atribuição por localização. Por isso essa única regra sai **ALERTA com
limiar 0,999**, linha de base para detectar piora, como o 0,78 da origem do PI. As outras
quatro são BLOQUEANTE com limiar 1,00.

---

## Duas armadilhas registradas no código

**Tipo:** `id_campanha` é **INT64 na dimensão e STRING nos breakdowns**. Todo join casta para
STRING dos dois lados — sem isso o BigQuery **recusa a comparação**, o que é melhor do que
casar errado em silêncio. Foi assim que o defeito apareceu.

**Camada:** a consolidada do Facebook é `vanguardamartech_trusted_facebook_ads`, **não**
`vanguardamartech_trusted`. Existem **onze** tabelas com o mesmo nome, uma por camada de
cliente. Foi o primeiro erro ao medir esta suíte, e o erro veio com a lista das onze.

---

## A orfandade do Facebook é linha de base, e isso foi provado

**2.157 de 142.305 linhas de insight (1,5%)** apontam para campanha que não existe na
dimensão. Medido: as **18 campanhas órfãs param em 27/03/2026** enquanto as 1.156 saudáveis
vão até hoje.

**A dimensão é uma FOTOGRAFIA e o fato é HISTÓRICO** — campanha apagada da conta some da
dimensão e o insight dela sobrevive. Mesmo mecanismo do gestor deletado no VJOB e do job
apagado com log de prazo. Limiar **0,98**, ALERTA.

---

## As duas do Gmail que guardam premissa de verdade

1. **`sempre_tem_rotulo`** — `is_inbox`, `is_enviada`, `is_spam`, `is_lixeira`,
   `flag_nao_lida_na_extracao` e `categoria_gmail` saem **todos** do array de rótulos da
   mensagem. Mensagem sem rótulo sairia com os seis em FALSE — **"não está em lugar nenhum e
   foi lida"** — e a contagem de linhas não mudaria. BLOQUEANTE. Medido: 0 de 32.911.
2. **`migracao_nao_reabre`** — **63,7% das mensagens vieram de migração de caixa** e a
   migração **preserva a data original**: as migradas param em 09/2025 e de 10/2025 em diante
   é 100% nativo. Se acender, **houve nova migração e o corte de regime mudou de lugar** —
   não é defeito, é aviso de que a série mudou de sujeito.

As outras sete guardam mecanismo já medido: a chave do rótulo é composta **por obrigação**
(32 linhas para **17 ids crus**) · `email_tem_forma` guarda o `LOWER()` da extração de
cabeçalho · `data_nao_futura` guarda o fuso, porque aqui `internalDate` é **UTC** e
`DATETIME(ts,'America/Sao_Paulo')` está **certo**, ao contrário do VJOB e do iClips.

---

## O que fica de fora, com a causa conferida

- `trs_google_ads__geo_alvo`, `rfn_midia__segmento_mensal` e `rfn_midia__localizacao_mensal`
  — publicadas em 28/09, **ainda não materializaram**. Entram na passada de terça, e com elas
  a candidata já declarada: **a identidade contábil da partição de `local_e_alvo`**, hoje
  161.041 de 161.041.
- `rfn_operacao__email_remetente_mensal` — publicada hoje **depois** da carga, responde
  `table_not_materialized`.

**Continuam sem regra 37 tabelas tratadas**, quase todas Refined publicadas entre 27 e 29/09
que ainda não rodaram uma vez.
