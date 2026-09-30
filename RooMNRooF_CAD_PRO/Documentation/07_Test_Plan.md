# Test Plan

## Automated (offline, runs anywhere with Python)
| Script | What it checks |
|---|---|
| `python Scripts/validate_standards.py` | colors, layers, filters, members, rebar weights, hatches, PAT syntax, LISP data sync, sample DXF audit |
| `python Scripts/check_lisp.py` | paren balance, protected-symbol misuse, duplicate commands |
| `python Scripts/syntax_check_csharp.py` | C# syntax (tree-sitter) — **not** a compiler |

## Automated (Windows, .NET 8)
`dotnet test Tests\RooMNRooF.Core.Tests` — Core library (units, rebar notation/weights, BBS, BOQ, geometry, QA).

## Manual AutoCAD acceptance (record in VerificationMatrix.xlsx)
1. Fresh `acad.dwt` drawing → `RNRSTANDARD` → layers/styles/linetypes created, no errors on command line.
2. `RNRGRID` 4×4, `RNRCOLUMN`, `RNRBEAM`, `RNRSLAB`, `RNRFOOTING` — correct layers, TrueColor ByLayer.
3. `RNRWALL`, `RNRDOOR`, `RNRWINDOW`, `RNRROOM` (area tag), `RNRSTAIR`.
4. `RNRMATLIB` → apply Brick/RCC; `RNRMATLEGEND`.
5. `RNRREBAR`, `RNRBBS` → CSV/XLSX/JSON open correctly; weights = d²/162.2.
6. `RNRSCHEDULE`, `RNRBOQ`.
7. `RNRTITLE A1`, `RNRLAYOUT`, `RNRPLOTBW` / `RNRPLOTGRAY` / `RNRPLOTCOLOR` → PDFs.
8. `RNRQA` on the sample drawings and on a drawing with a non-standard layer (must FAIL it).
9. `RNRPREVIEW` then `RNRCLEAN` → answer *No* → verify nothing was deleted.
10. `APPLOAD AutoLISP\RNR_Load.lsp` → `RNRL-HELP`, try every RNRL command.
11. Open each `Samples\SampleProject\*.dxf`, run `AUDIT` → 0 errors.
12. Install MSI, restart AutoCAD, plugin auto-loads; uninstall removes bundle.
