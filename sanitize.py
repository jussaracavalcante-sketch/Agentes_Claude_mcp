#!/usr/bin/env python3
"""
Remove dado sensivel para publicacao em repositorio PUBLICO.
Substitui nomes de pessoas por cargos e remove CNPJ.

Uso:  python3 sanitize.py --check    # so relata, nao altera
      python3 sanitize.py --apply    # aplica as substituicoes
"""
import glob, re, sys, os

SUBS = [
    (r"Wilson Caldas Jr\.?", "CFO"),
    (r"Breno Maciel", "CEO"),
    (r"Thyago Molde", "Supervisor de Controladoria"),
    (r"\b\d{2}\.\d{3}\.\d{3}/\d{4}-\d{2}\b", "[CNPJ omitido]"),
]
# limpa duplicacao gerada pela substituicao, ex.: "CFO — CFO"
CLEANUP = [
    (r"CFO\s*—\s*CFO", "CFO"),
    (r"CEO\s*—\s*CEO", "CEO"),
    (r"CFO\s*\(CFO[^)]*\)", "CFO"),
    (r"CEO\s*\(CEO\)", "CEO"),
    (r"CFO,\s*Gestor de processos", "Gestor de processos"),
    (r"Supervisor de Controladoria\s*\(Supervisor Controladoria\)", "Supervisor de Controladoria"),
]

check = "--check" in sys.argv
apply_ = "--apply" in sys.argv
if not (check or apply_):
    print(__doc__); sys.exit(1)

files = [f for f in glob.glob("**/*.md", recursive=True) if ".git/" not in f]
total, touched = 0, []

for path in files:
    txt = open(path, encoding="utf-8").read()
    orig = txt
    hits = 0
    for pat, rep in SUBS:
        txt, n = re.subn(pat, rep, txt)
        hits += n
    for pat, rep in CLEANUP:
        txt = re.sub(pat, rep, txt)
    if hits:
        total += hits
        touched.append((path, hits))
        if apply_:
            open(path, "w", encoding="utf-8").write(txt)

for p, n in sorted(touched):
    print(f"{n:>3} ocorrencia(s)  {p}")

print(f"\n{total} ocorrencia(s) em {len(touched)} arquivo(s)")
if check and total:
    print("\nModo --check: nada foi alterado. Rode com --apply para sanitizar.")
    print("Depois: python3 build-catalog.py && python3 validate.py")
elif apply_:
    print("\nSanitizado. Rode agora:")
    print("  python3 build-catalog.py && python3 validate.py")
