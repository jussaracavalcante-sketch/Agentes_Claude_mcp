# Revisão de rótulos de cliente — Google Ads

**Para:** time de mídia · **De:** dados/BI · **Data:** 2026-09-01
**Anexo:** `rotulos-google-ads-revisao.csv` (23 linhas, com coluna de decisão)

## O pedido, em uma frase

Nos relatórios de Google Ads, **23 contas aparecem com um nome diferente do que está na
plataforma**. Preciso que vocês digam, em cada uma, qual nome vale.

## Por que isso apareceu agora

O nome do cliente nos relatórios nunca veio da Google — era digitado à mão na configuração.
Isso foi corrigido esta semana: agora existe uma tabela de contas alimentada pela listagem do
MCC da Vanguarda, e cada conta é identificada pelo seu ID, não pelo nome.

Ao fazer essa ligação, o sistema comparou os dois lados pela primeira vez. **Nenhuma conta
estava trocada** — os 39 IDs conferem e as moedas também. Mas 23 rótulos divergem do nome da
conta, e o sistema não tem como saber se cada um é apelido que vocês escolheram ou nome que
ficou para trás.

**Nada muda até vocês responderem.** Os nomes atuais continuam nos relatórios.

## Como preencher

Na planilha, para cada linha, a coluna **DECISÃO**:

- `manter` — o rótulo atual é o apelido correto, mantém como está
- `usar nome da Google` — adota o nome da plataforma
- `outro` — nenhum dos dois serve; escreva o certo em `SE_OUTRO_qual_nome`

As linhas estão em ordem de prioridade. Se o tempo for curto, **as 4 primeiras resolvem o
essencial**.

## As 4 críticas

| Rótulo hoje | Conta na Google | O problema |
|---|---|---|
| `BRAGA MOTORS BMW` | BRAGA VEICULOS LTDA | Os nomes não têm relação nenhuma. Ou o rótulo está errado, ou a conta está com nome genérico. |
| `SANTO REMEDIO` | SANTO REMÉDIO VNG | **Colisão.** `SANTO REMEDIO` é o nome exato de *outra* conta do MCC (`5138016841`), ainda não integrada. Se ela entrar, haverá dois `SANTO REMEDIO` no relatório. |
| `PMZ GRUPO LOJA` | PMZ | A conta se chama só `PMZ`. Nosso rótulo assume que é a operação de loja — mas a PMZ tem três contas. |
| `OLA CASA NOVA` | Olá Empreendimentos | "Casa Nova" não aparece no nome da conta. É um empreendimento específico ou a holding inteira? |

## As 4 em que a marca parece ter mudado

| Rótulo hoje | Conta na Google |
|---|---|
| `BRAGA VAREJO` | Braga Motomarcas |
| `BRAGA YAMAHA` | Braga Motos |
| `BRAGA YAMAHA CONSORCIOS` | Braga Consórcio |
| `CONSTROI INCORPORADORA` | Constrói Construtora |

Nos três primeiros, a conta não cita mais a marca que está no nosso rótulo. No último,
incorporadora e construtora são atividades diferentes.

## As 15 restantes

Diferenças que parecem apelido deliberado — abreviação, nome fantasia, prefixo de grupo
omitido: `BRAGA POS VENDAS`, `BRAGA MINI`, `BRAGA MOTORRAD`, `COLMEIA`, `DEB TRANSPORTADORA`,
`STEEL PORT`, `BA ELETRICA`, `MILLENIUM`, `PNEU EXPRESS`, `SMILE PNEUS`, `PMZ GRUPO ECOMM`,
`PMZ ESCOLA DE MECANICOS`, `DR. CABRAL CONTA 1`, `DON WATCHES CONTA 1`, `DON WATCHES CONTA 2`.

Dois pontos dentro desse grupo que valem o olhar:

- **`MILLENIUM` está escrito com um N.** Na Google é `Millennium Shopping`, com dois.
- **`CONTA 1` e `CONTA 2` são numeração nossa**, não existe na Google. Na plataforma as Don
  Watches são `Ativa` e `Ativa Validada` (e há uma terceira, `Desativada`, não integrada);
  as Dr. Cabral são `Dr. Cabral` e `Dr. Cabral [NOVA]` (a segunda não integrada). Se a
  numeração não bate com a que vocês usam no dia a dia, é o momento de acertar.

## Duas coisas que não são decisão de vocês, mas vocês precisam saber

1. **Dr. Cabral conta 1 (`738-192-0209`): 38 campanhas e zero investimento** desde que
   entrou, em 26/08. A extração roda todo dia e funciona — a conta simplesmente não teve
   entrega. Conta parada, ou a janela que puxamos é curta demais?
2. **Duas contas do MCC têm nome idêntico:** `TS Clinic - Saúde , Emagrecimento e
   Performance` (`1752601290` e `6337596664`). Nenhuma integrada hoje. Se forem, vão precisar
   de rótulos distintos.
