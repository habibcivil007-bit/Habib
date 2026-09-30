#!/usr/bin/env python3
"""Static AutoLISP checks: balanced parentheses (string/comment aware), no assignment to protected
symbols (T, pi, nil), every c: command unique. Not a substitute for loading in AutoCAD."""
import pathlib, re, sys
root = pathlib.Path(__file__).resolve().parents[1] / "AutoLISP"
bad = 0; cmds = {}
for f in sorted(root.glob("*.lsp")):
    s = f.read_text(encoding="utf-8")
    depth = 0; i = 0; line = 1; instr = False
    while i < len(s):
        ch = s[i]
        if ch == "\n": line += 1
        if instr:
            if ch == "\\": i += 1
            elif ch == '"': instr = False
        elif ch == '"': instr = True
        elif ch == ";":
            while i < len(s) and s[i] != "\n": i += 1
            line += 1
        elif ch == "(": depth += 1
        elif ch == ")":
            depth -= 1
            if depth < 0: print(f"{f.name}:{line}: unexpected ')'"); bad += 1; depth = 0
        i += 1
    if depth != 0: print(f"{f.name}: {depth} unclosed '('"); bad += 1
    if instr: print(f"{f.name}: unterminated string"); bad += 1
    for m in re.finditer(r"\(setq\s+(?:[^()]*\s)?(t|pi|nil)\s", s, re.I):
        print(f"{f.name}: assignment to protected symbol '{m.group(1)}'"); bad += 1
    for m in re.finditer(r"\(defun\s+([^\s(]+)\s*\(([^)]*)\)", s):
        args = m.group(2).replace("/", " ").split()
        if any(a.lower() in ("t", "pi", "nil") for a in args):
            print(f"{f.name}: protected symbol used as argument/local in {m.group(1)}"); bad += 1
    for m in re.finditer(r"\(defun\s+(c:[^\s(]+)", s, re.I):
        n = m.group(1).upper()
        if n in cmds: print(f"{f.name}: duplicate command {n} (also in {cmds[n]})"); bad += 1
        cmds[n] = f.name
print(f"{len(list(root.glob('*.lsp')))} LISP files, {len(cmds)} commands, {bad} problem(s)")
sys.exit(1 if bad else 0)
