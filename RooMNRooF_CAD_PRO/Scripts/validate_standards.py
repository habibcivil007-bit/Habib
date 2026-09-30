#!/usr/bin/env python3
"""
Offline validator for Standards/*.json, Hatch/*.pat, AutoLISP data and sample DXF files.
Exit code 0 = all checks passed, 1 = at least one FAIL. Output is a plain PASS/FAIL list:
a check only reports PASS when it was actually executed and satisfied.
"""
import glob
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
results = []


def check(name, ok, detail=""):
    results.append((name, bool(ok), detail))


def load(n):
    with open(os.path.join(ROOT, "Standards", n), encoding="utf-8") as f:
        return json.load(f)


colors = load("RNR_Colors.json")["colors"]
layers = load("RNR_Layers.json")["layers"]
filters = load("RNR_LayerFilters.json")["filters"]
members = load("RNR_Members.json")["members"]
hatches = load("RNR_Hatches.json")["hatches"]
blocks = load("RNR_Blocks.json")["blocks"]
rebar = load("RNR_Rebar.json")
styles = load("RNR_Styles.json")

# ---- colors
ids = [c["id"] for c in colors]
check("colors: >= 100 entries", len(colors) >= 100, f"{len(colors)}")
check("colors: unique ids", len(ids) == len(set(ids)))
check("colors: rgb in 0..255", all(len(c["rgb"]) == 3 and all(0 <= v <= 255 for v in c["rgb"]) for c in colors))
check("colors: aci 1..255", all(1 <= c["aci"] <= 255 for c in colors))

# ---- layers
names = [l["name"] for l in layers]
check("layers: unique names", len(names) == len(set(names)))
check("layers: valid prefixes", all(re.match(r"^(A|S|C|P|E|M|ANNO|XREF|Z)(-|$)", n) for n in names),
      ",".join(n for n in names if not re.match(r"^(A|S|C|P|E|M|ANNO|XREF|Z)(-|$)", n)))
check("layers: colorId resolves", all(l["colorId"] in ids for l in layers),
      ",".join(l["name"] for l in layers if l["colorId"] not in ids))
valid_lw = {0.0, 0.05, 0.09, 0.13, 0.15, 0.18, 0.2, 0.25, 0.3, 0.35, 0.4, 0.5, 0.53, 0.6, 0.7, 0.8, 0.9, 1.0,
            1.06, 1.2, 1.4, 1.58, 2.0, 2.11}
check("layers: standard lineweights", all(l["lineweight"] in valid_lw for l in layers))
check("layers: transparency 0..90", all(0 <= l["transparency"] <= 90 for l in layers))
with open(os.path.join(ROOT, "Standards", "RooMNRooF.lin"), encoding="utf-8") as f:
    lin = set(re.findall(r"^\*(\w+)", f.read(), re.M))
check("layers: linetypes defined", all(l["linetype"] in lin | {"Continuous"} for l in layers),
      ",".join(sorted({l["linetype"] for l in layers} - lin - {"Continuous"})))
check("layers: Z-VPORT non-plot", any(l["name"] == "Z-VPORT" and not l["plot"] for l in layers))

# ---- filters
check("filters: 12 filters", len(filters) == 12, f"{len(filters)}")

# ---- members
mids = [m["code"] for m in members] if members and "code" in members[0] else [m.get("id") for m in members]
check("members: 55 definitions", len(members) == 55, f"{len(members)}")
check("members: unique codes", len(mids) == len(set(mids)))
check("members: layers exist", all(m.get("layer", "S-COL") in names for m in members),
      ",".join(sorted({m.get("layer") for m in members} - set(names))))

# ---- rebar
dias = sorted(b["diameter"] for b in rebar["bars"]) if "bars" in rebar else []
check("rebar: T8..T32 present", {8, 10, 12, 16, 20, 25, 32}.issubset(dias), str(dias))
if "bars" in rebar:
    check("rebar: unit weight = d^2/162.2 (+-0.5%)",
          all(abs(b["unitWeight"] - b["diameter"] ** 2 / 162.2) / (b["diameter"] ** 2 / 162.2) < 0.005 for b in rebar["bars"]))

# ---- hatches + PAT
check("hatches: 20 definitions", len(hatches) == 20, f"{len(hatches)}")
pats = {os.path.splitext(os.path.basename(p))[0].upper() for p in glob.glob(os.path.join(ROOT, "Hatch", "*.pat"))}
custom = [h for h in hatches if h["custom"]]
check("hatches: custom PAT files exist", all(h["pattern"].upper() in pats for h in custom),
      ",".join(h["pattern"] for h in custom if h["pattern"].upper() not in pats))
pat_ok, bad = True, []
for p in glob.glob(os.path.join(ROOT, "Hatch", "*.pat")):
    with open(p, encoding="ascii", errors="replace") as f:
        txt = f.read()
    heads = re.findall(r"^\*([\w-]+)", txt, re.M)
    if not heads:
        pat_ok = False
        bad.append(os.path.basename(p))
    for line in txt.splitlines():
        line = line.strip()
        if not line or line.startswith(";") or line.startswith("*"):
            continue
        try:
            vals = [float(v) for v in line.split(",")]
            if len(vals) < 5:
                raise ValueError
        except ValueError:
            pat_ok = False
            bad.append(f"{os.path.basename(p)}:{line[:30]}")
    if not txt.endswith("\n"):
        pat_ok = False
        bad.append(os.path.basename(p) + " (no trailing newline)")
check("PAT: syntax (header + numeric descriptor lines)", pat_ok, ";".join(bad[:5]))

# ---- blocks
bn = [b["name"] for b in blocks]
check("blocks: unique names", len(bn) == len(set(bn)))

# ---- styles
check("styles: A0..A4 sheets", set(styles["sheets"]) >= {"A0", "A1", "A2", "A3", "A4"})

# ---- LISP data in sync
with open(os.path.join(ROOT, "AutoLISP", "RNR_Data.lsp"), encoding="utf-8") as f:
    lsp = f.read()
check("AutoLISP RNR_Data: every layer present", all(f'"{n}"' in lsp for n in names))

# ---- sample DXF
try:
    import ezdxf
    dxfs = sorted(glob.glob(os.path.join(ROOT, "Samples", "**", "*.dxf"), recursive=True))
    errs = []
    for d in dxfs:
        doc = ezdxf.readfile(d)
        a = doc.audit()
        used = {e.dxf.layer for e in doc.modelspace()}
        foreign = used - set(names) - {"0"}
        if a.has_errors or foreign:
            errs.append(f"{os.path.basename(d)} errors={len(a.errors)} foreign={sorted(foreign)}")
    check(f"sample DXF: {len(dxfs)} files audit clean, only standard layers", dxfs and not errs, "; ".join(errs))
except ImportError:
    check("sample DXF: ezdxf installed", False, "pip install ezdxf")

w = max(len(r[0]) for r in results)
for n, ok, d in results:
    print(f"{'PASS' if ok else 'FAIL'}  {n.ljust(w)}  {d if not ok or d.isdigit() else ''}")
fails = sum(1 for r in results if not r[1])
print(f"\n{len(results) - fails}/{len(results)} checks passed")
sys.exit(1 if fails else 0)
