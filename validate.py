#!/usr/bin/env python3
"""Valida os agentes contra as regras de governanca. Falha o build se violar."""
import glob, re, sys

REQUIRED = ["name","agent-id","description","layer","autonomy","status","owner","composes"]
VALID_AUTONOMY = {"N1","N2","N3"}          # N4 vedado por politica
VALID_STATUS   = {"backlog","homologacao","piloto","producao","bloqueado"}
VALID_LAYER    = {"0","1","2","3","4"}

errors, warnings = [], []

for path in sorted(glob.glob("agents/*/AGENT.md")):
    txt = open(path, encoding="utf-8").read()
    tag = path.split("/")[-2]

    if not txt.startswith("---"):
        errors.append(f"{tag}: sem frontmatter YAML"); continue
    fm = txt.split("---")[1]

    def val(k):
        m = re.search(rf"^{k}:\s*(.*)$", fm, re.M)
        return m.group(1).strip() if m else None

    for key in REQUIRED:
        if val(key) is None:
            errors.append(f"{tag}: campo obrigatorio ausente -> '{key}'")

    a = val("autonomy")
    if a and a not in VALID_AUTONOMY:
        errors.append(f"{tag}: autonomia '{a}' invalida. N4 e vedado; use N1, N2 ou N3")

    s = val("status")
    if s and s not in VALID_STATUS:
        errors.append(f"{tag}: status '{s}' invalido")

    l = val("layer")
    if l and l not in VALID_LAYER:
        errors.append(f"{tag}: camada '{l}' invalida")

    o = val("owner")
    if not o or o.strip() in ("", "a definir", "TBD"):
        errors.append(f"{tag}: agente sem dono nomeado — nao pode ir a producao")

    if "## Falhas conhecidas" not in txt and "## Falha conhecida" not in txt:
        warnings.append(f"{tag}: sem secao 'Falhas conhecidas' — agente nao testado")

    if s == "bloqueado" and not val("blocked-by"):
        errors.append(f"{tag}: status 'bloqueado' exige o campo 'blocked-by'")

    if s in ("piloto","producao") and val("blocked-by"):
        errors.append(f"{tag}: agente com 'blocked-by' nao pode estar em {s}")

n = len(glob.glob("agents/*/AGENT.md"))
print(f"Agentes verificados: {n}\n")

for w in warnings: print(f"AVISO  {w}")
for e in errors:   print(f"ERRO   {e}")

if errors:
    print(f"\nFALHOU: {len(errors)} erro(s), {len(warnings)} aviso(s)")
    sys.exit(1)
print(f"\nOK: {n} agentes validos, {len(warnings)} aviso(s)")
