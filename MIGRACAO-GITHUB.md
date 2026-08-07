# Migração para o GitHub — Instruções

**Destino:** `https://github.com/jussaracavalcante-sketch/Agentes_Claude_mcp`
**Estado do remoto:** repositório existe, está **vazio** e é **PÚBLICO**
**Estado local:** 5 commits prontos, working tree limpo, remote já configurado

---

## ⚠ DECIDA ISTO ANTES DE RODAR O PUSH

O repositório de destino é **público**. O conteúdo atual inclui:

| O que | Onde | Risco |
|---|---|---|
| CNPJ das três entidades | `runbooks/mapeamento-fonte-financeira.md` | Baixo (dado público) mas desnecessário |
| Nomes de 3 executivos + cargos | `AGT-13`, `README.md`, `CATALOG.md` | **LGPD** — dado pessoal de titular identificado |
| Fragilidades operacionais declaradas | `risk-register.md`, agentes bloqueados | **Competitivo** — expõe gargalos a concorrente e cliente |
| Lacuna de LGPD assumida | `governance/lgpd-mapping.md` ("NÃO PREENCHIDO") | **Reputacional** — declara não conformidade publicamente |
| Método e arquitetura de operação | repositório inteiro | **Propriedade intelectual** |

### Três caminhos

**A · Tornar o repositório privado — recomendado**
Mantém o conteúdo íntegro. A franqueza do registro de riscos é o que dá valor ao
documento; sanitizar destrói isso. Settings → General → Danger Zone → Change visibility.

**B · Manter público, mas sanitizar**
```bash
python3 sanitize.py --check    # simula, não altera
python3 sanitize.py --apply    # substitui nomes por cargos, remove CNPJ
python3 build-catalog.py && python3 validate.py
git add -A && git commit -m "chore: sanitiza dado pessoal para repositorio publico"
```
Resolve LGPD e CNPJ. **Não resolve** exposição competitiva nem a declaração de
não conformidade — essas exigiriam reescrever o registro de riscos, o que
esvazia o documento.

**C · Repositório público sanitizado + privado completo**
Público com método e estrutura (vitrine técnica, útil para posicionamento).
Privado com riscos, nomes, dado financeiro e bloqueios.

> **Recomendação:** A. Este repositório é instrumento de gestão interna, não vitrine.
> Se o objetivo for portfólio público, C é o caminho — mas exige separar os dois
> repositórios antes do primeiro push, não depois.

---

## Push

Sem credenciais neste ambiente, o push é executado por você.

### 1. Descompacte e entre na pasta
```bash
unzip vanguarda-agents.zip && cd vanguarda-agents
```
O `.git` já vem pronto: 5 commits, branch `main`, remote `origin` configurado.

### 2. Confira antes de subir
```bash
git log --oneline      # 5 commits
git remote -v          # aponta para Agentes_Claude_mcp
python3 validate.py    # deve dar "17 agentes validos, 0 aviso(s)"
```

### 3. Ajuste sua identidade
```bash
git config user.name  "Seu Nome"
git config user.email "seu-email@dominio.com"
```

### 4. Push
```bash
git push -u origin main
```

**Autenticação:** o GitHub não aceita mais senha via HTTPS. Use uma das opções:

- **Personal Access Token** — Settings → Developer settings → Tokens (classic) →
  escopo `repo`. Use o token no lugar da senha quando solicitado.
- **GitHub CLI** — `gh auth login` e depois o push normalmente.
- **SSH** — troque o remote:
  ```bash
  git remote set-url origin git@github.com:jussaracavalcante-sketch/Agentes_Claude_mcp.git
  ```

> **Nunca cole um token em chat, issue ou commit.** A CI deste repositório varre
> credenciais a cada push, mas prevenir é melhor que detectar.

---

## Depois do push

1. **Branch protection** — Settings → Branches → proteger `main`:
   exigir PR, exigir CI verde, bloquear force push
2. **Conferir a CI** — a aba Actions deve mostrar "Validar Agentes" em verde
3. **Ativar Issues** — os templates em `.github/ISSUE_TEMPLATE/` já estão prontos
4. **Abrir as 3 issues de bloqueio:**
   - AGT-06 · mapear fonte financeira (iClips/Conexa)
   - AGT-10 · decidir entre implementar skills ausentes ou redesenhar
   - AGT-14 · implementar ou substituir `change-management`
5. **Abrir as 3 issues de Onda 0:**
   - Medir baseline (2 semanas) — `metrics/baseline.md`
   - Preencher mapa LGPD — `governance/lgpd-mapping.md`
   - Rodar `data-context-extractor` para o glossário de métricas

---

## O que a CI faz a cada push

`.github/workflows/validate-agents.yml` bloqueia o merge se:

- Faltar campo obrigatório no frontmatter de qualquer agente
- Algum agente declarar autonomia **N4** (vedada por política)
- Algum agente estiver **sem dono nomeado**
- Faltar a seção "Falhas conhecidas"
- Agente `bloqueado` não declarar `blocked-by`
- Agente em `piloto`/`producao` ainda tiver `blocked-by`
- `CATALOG.md` estiver desatualizado em relação ao frontmatter
- For detectada credencial (`ghp_`, `github_pat_`, `sk-`, `AKIA`)

**Isto é o que transforma a política de governança em regra executável.**
Sem a CI, `governance/autonomy-levels.md` é intenção; com ela, é controle.
