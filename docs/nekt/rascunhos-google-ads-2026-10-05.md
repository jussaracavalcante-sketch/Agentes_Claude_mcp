# Rascunhos Google Ads — contas do MCC sem fonte (05/10/2026)

Origem: `docs/nekt/varredura-fontes-2026-10-05.md`. **Dez rascunhos novos** criados com `create_draft`, mais os dois já existentes (`4YJU`, `H3hJ`) com link novo. Nenhum está publicado, nenhum tem credencial, nenhuma camada foi criada. Os links de autorização (`/scl/...`) valem 24 h e **não são versionados aqui**: geram-se de novo com `get_setup_link`.

## Config comum a todos os rascunhos novos
`customer_id` (sem hífen) · `login_customer_id` = **1704439246** (MCC da Vanguarda; as 88 contas foram listadas por ele) · `start_date` 2024-01-01 (mesmo ponto de partida do Facebook) · `lookback_window` 7 · `performance_granularity` daily. O que falta em cada um é só o `oauth_credentials`, que entra pela interface.

## Os rascunhos

| slug | conta | customer_id | gasto 30d (R$) | camada proposta (NÃO criada) |
|---|---|---|---:|---|
| `google-ads-WKmK` | UIARA AMAZON RESORT | 193-832-6229 | 13.725,52 | `uiara_amazon_resort_g_ads` |
| `google-ads-z1CZ` | SANTO REMEDIO (conta viva) | 513-801-6841 | 4.398,65 | `santo_remedio_conta_2_g_ads` |
| `google-ads-hLZl` | ECOMM \| PÁTIO GOURMET | 681-914-4625 | 2.943,02 | `patio_gourmet_ecomm_g_ads` |
| `google-ads-DhJv` | Aço Manaus | 514-135-8700 | 1.517,71 | `aco_manaus_g_ads` |
| `google-ads-DR7n` | Hope Bay Park | 407-149-9349 | 1.509,19 | `hope_bay_park_g_ads` |
| `google-ads-10KI` | JULIA HERRERA | 382-053-1237 | 736,27 | `julia_herrera_g_ads` |
| `google-ads-4aNo` | Pátio Gourmet — Loja Física | 965-772-4454 | 379,79 | `patio_gourmet_loja_g_ads` |
| `google-ads-1pe8` | Tuboaços da Amazônia (2) | 752-297-1952 | 289,78 | `tuboacos_da_amazonia_g_ads` |
| `google-ads-zksL` | CDL Manaus | 661-855-7333 | 87,82 | `cdl_manaus_g_ads` |
| `google-ads-H4oR` | BRAGA MOTORS — CARRO | 432-609-6939 | 87,41 | `braga_motors_carro_g_ads` |
| `google-ads-4YJU` *(já existia)* | Dr. Cabral [NOVA] | 251-691-8741 | 1.936,79 | camada já definida no rascunho |
| `google-ads-H3hJ` *(já existia)* | Pneu Forte \| Varejo | 399-828-7431 | 779,40 | camada já definida no rascunho |

**Total coberto pelos 12:** R$ 28.391,35 em 30 dias. **Fora desta lista, de propósito:** Prestex (R$ 11.328,08) — já tem a fonte `google-ads-OzfZ`, que precisa de reautenticação, não de rascunho novo — e as cinco contas Nova Era (a Nova Era saiu da agência).

## Decisões que precisam do nome certo (R-001: o nome da camada é irreversível)
1. **Santo Remédio.** A fonte velha `google-ads-AMd2` aponta para a conta 281-904-4460, que saiu do MCC (dados até 16/07/2025). A conta viva é outra (513-801-6841). Pela convenção, cliente com mais de uma conta na plataforma leva o bloco `<conta>` — daí `santo_remedio_conta_2_g_ads`. Alternativa não tomada: reusar a camada antiga, que misturaria duas contas numa fonte só e fere a R-001.
2. **Pátio Gourmet** tem duas contas Google Ads → `_ecomm` e `_loja`. O Facebook dele já está na camada `Patio_gourmet`, que fica como está.
3. **Tuboaços da Amazônia (2).** O "(2)" no nome na plataforma sugere uma conta anterior; não há outra no MCC. Grafia proposta sem o "(2)".
4. **Acentos** saem (`aco_manaus`, `tuboacos`): a convenção da casa é minúscula, underscore, sem acento.

## Sequência por rascunho, depois do OAuth
1. `validate_source_connector_config` → `check_connector_validation`. **Lista de streams vazia = credencial que não alcança a conta** (foi o que aconteceu com `4YJU` e `H3hJ`); não prosseguir.
2. `create_layer` com o nome confirmado (preview, depois `confirm=True`).
3. `complete_pipeline` com os streams da validação, cron semanal de terça (mesmo padrão das outras Google Ads) e **alerta de falha ligado**.
4. **Esperar a primeira execução agendada** (nada de rodar à mão) e conferir `COUNT(*)` — fonte publicada não é fonte integrada.
5. Só então somar a conta às uniões da Trusted: `trs_google_ads__insight_diario`, `trs_google_ads__campanha` e a dimensão `rfn_cadastro__conta`, rodando `SELECT f FROM (<união>) LIMIT 0` antes de publicar. **A lista não se atualiza sozinha.**

## Credencial
O usuário Google que autoriza precisa ter acesso às contas **por esse MCC**. A Prestex falhou exatamente porque o usuário do OAuth da Nekt não alcançava a conta; `4YJU` e `H3hJ` mostram o mesmo sintoma. Autorizar com o usuário que administra o MCC 1704439246.

## Bloqueio registrado (05/10): quem pediu os rascunhos não tem acesso a essas contas
O OAuth só pode ser feito por um usuário Google que alcance as contas **pelo MCC 1704439246**. Quem pediu os rascunhos não tem esse acesso, então **os 12 rascunhos ficam parados até alguém que administre o MCC autorizar**.

- **O link de setup não exige login na Nekt** (é um `/scl/<token>` que a própria ferramenta descreve como aberto "sem login na plataforma"): pode ser **encaminhado a quem administra o MCC**, que só completa o OAuth. Vale 24 h; gera-se de novo com `get_setup_link(kind="source", slug=...)` quando expirar.
- **Nada precisa ser refeito do lado da Nekt:** o `customer_id`, o `login_customer_id` e a configuração já estão nos rascunhos. A pessoa só autoriza.
- **Enquanto ninguém autorizar:** os 12 rascunhos ficam inativos, sem custo, sem camada e sem tabela. A cobertura de Google Ads segue com as 45 fontes de hoje, e as contas desta lista (R$ 28.391,35 em 30 dias) continuam fora da Trusted.
- **O mesmo bloqueio vale para a Prestex (`OzfZ`) e para o `AMd2`:** reautenticar ou trocar o `customer_id` também pede o OAuth de quem tem acesso. Um único administrador do MCC resolve os quatro casos de uma vez (os 12 rascunhos + `OzfZ` + `AMd2`).
- **Nada foi apagado:** os rascunhos são reversíveis e baratos de manter. Se ninguém for autorizar, a limpeza é excluí-los na interface.
