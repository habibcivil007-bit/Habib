# RooMNRooF PRO 2D AutoCAD Standard — 3.0 PRO SUITE

`RooMNRooF_Master.lsp` is a professional, metric AutoLISP generator for a modern
consultant 2D CAD standard. It creates a consistent visual system rather than only a
list of layers: brand colours, lineweight hierarchy, modern font fallback, rich text /
dimension / multileader styles, annotation symbols, sheet graphics and a full production
suite (scale, grids, areas, stamps, revisions, notes, hatch library, layer control,
QA, page setup and publishing).

Version string inside the LISP: `*RMR-VERSION* = "3.0 PRO SUITE"`.

## Package contents

| File | Purpose |
| --- | --- |
| `RooMNRooF_Master.lsp` | The complete AutoLISP application (generator + production suite). |
| `README.md` | This document. |
| `preview/RooMNRooF_PRO_Standard_Preview.dxf` | A1 preview sheet generated from the shipped palette data (open in AutoCAD or any DXF viewer). |
| `preview/RooMNRooF_PRO_Standard_Preview.png` | Rendered A1 preview sheet (dark presentation ground). |
| `preview/RooMNRooF_PRO_Plan_Detail.png` | Zoomed 1:50 sample apartment plan from the same sheet. |
| `tools/rmr_lint.py` | Standalone static checker that validates the LISP structure before delivery. |
| `tools/make_preview_dxf.py` | Regenerates the preview DXF/PNGs directly from the LISP data tables (needs `ezdxf`, `matplotlib`). |

The binary `.DWT` template is intentionally **not** shipped: it can only be produced
inside AutoCAD by loading the LISP and running `RMR-SAVE-TEMPLATE`.

## Install and generate the master

1. Open a blank metric AutoCAD drawing.
2. `APPLOAD` → load `RooMNRooF_Master.lsp`.
3. Run `RMR-MASTER` (or `RMR-PRO-SETUP` for a first-time / refresh install).
4. Optional: run `RMR-SAVE-TEMPLATE` to write `RooMNRooF_PRO_Standard.dwt` next to the
   drawing (or into the AutoCAD template folder when writable).

`RMR-MASTER` is idempotent and preserves existing office styles. `RMR-PRO-SETUP`
additionally refreshes the RMR-owned text styles to the PRO font stack; set
`*RMR-FORCE-STYLE-REFRESH*` to `T` to force the same refresh from `RMR-MASTER`.

## Command reference (31 commands)

### Setup, palette and templates
| Command | What it does |
| --- | --- |
| `RMR-MASTER` | Grouped launcher: builds/updates the full standard and offers the production tools. |
| `RMR-PRO-SETUP` | Full PRO build: layers, true colours, linetypes, text styles, dim styles, MLeader style, symbol blocks, standards variables. |
| `RMR-SAVE-TEMPLATE` | Saves the current drawing as the reusable `.DWT` template. |
| `RMR-PALETTE` | Interactive palette editor: list groups, edit layer colour/linetype/lineweight/description, add layers, dump the palette. |
| `RMR-EXPORT-PALETTE` | Writes the live palette to a `;`-delimited CSV (8 fields per row). |
| `RMR-IMPORT-PALETTE` | Reads a palette CSV back in and rebuilds the standard from it. |
| `RMR-LAYGROUP` | Freeze/Thaw/Off/On/Lock/Unlock a whole layer group (protects the current layer). |
| `RMR-SETLAYER` | Quick set-current-layer by wildcard-filtered pick list. |

### Annotation and presentation
| Command | What it does |
| --- | --- |
| `RMR-ROOMTAG` | Scale-aware room tag (number, name, m² + ft²) on `RMR-A-ROOM`. |
| `RMR-KEYNOTE` | Gold chevron leader + numbered keynote bubble. |
| `RMR-MLEADER` | Branded multileader using the `RMR-MLEADER` style. |
| `RMR-DETAIL` | Detail callout bubble (mark + sheet reference). |
| `RMR-LEVEL` | Level datum marker with formatted ± level text. |
| `RMR-NORTH` | Inserts/rotates the `RMR-NORTH-ARROW` block. |
| `RMR-REVISION` | Revision cloud tag (triangle marker + rev letter). |
| `RMR-REVTABLE` | Revision history table with branded header row. |
| `RMR-STAMP` | Rotatable double-border issue stamp (rev, date, auto-fitted label). |
| `RMR-NOTES` | Numbered general notes as wrapped MTEXT paragraphs. |
| `RMR-LEGEND` | Colour / layer / linetype legend generator. |
| `RMR-SHEET` | A0–A4 sheet frame, border and branded title block. |
| `RMR-SCALEBAR` | Graphic scale bar for the active drawing scale. |
| `RMR-KEYPLAN` | Mini key plan box with north arrow and outline. |

### Production suite
| Command | What it does |
| --- | --- |
| `RMR-SCALE` | Sets the drawing scale by keyword (1:20 … 1:200), model or layout annotation space; syncs `DIMSCALE`, `CELTSCALE`, `LTSCALE`, `MSLTSCALE`, `PSLTSCALE` and the scale label. |
| `RMR-GRID` | Structural grid lines with lettered/numbered bubbles (skips I and O, then AA, AB…). |
| `RMR-AREA` | Computes room areas (closed boundary pick) and builds the m²/ft² area schedule table. |
| `RMR-HATCHLIB` / `RMR-HATCH` | 12-material hatch library; hatch a closed area by material keyword. |
| `RMR-COUNT` | Block takeoff by name and layer, optional CSV export, console report. |
| `RMR-CHECK` | Drawing QA pass (`ssget "X"` audit of layers/linetypes/styles/text) with PASS/REVIEW verdict, optional `.txt` report. |
| `RMR-PAGESETUP` | Named page setup with brand plot device, plot style and paper size. |
| `RMR-PUBLISH` | Writes a `.dsd` sheet set for one-click PDF publish of the drawing. |

All annotation commands ask for the symbol scale once per session and honour
`*RMR-ANNO-SCALE*` / `*RMR-ANNO-SPACE*` (model vs layout annotation).

## Editing the palette (group-wise, future-proof)

All visual data lives in plain editable tables near the top of the LISP:

- `*RMR-LAYER-SPECS*` — `("LayerName" "Group" (R G B) "Linetype" Lineweight "Description")`
- `*RMR-TEXT-STYLES*` — `(name font width oblique description)`
- `*RMR-DIMSTYLE-SPECS*` — `(name textheight arrowsize description)`
- `*RMR-MLEADER-SPECS*` — multileader style definitions
- `*RMR-BRAND-*` — INK / TERRACOTTA / TEAL / GOLD / SAND / BLUE / SLATE RGB triples
- `*RMR-HATCH-SPECS*`, `*RMR-STAMP-SPECS*`, `*RMR-NOTES*`, `*RMR-PAPER-SPECS*`,
  `*RMR-SCALE-SPECS*`, `*RMR-GRID-LETTERS*`, plot/publish defaults

Groups currently shipped: **Control, Main Theme, Furniture, Structural, Plumbing,
Annotation, Presentation**. Add a row (or a whole new group) and every generator,
legend, layer-group command and the preview tool pick it up automatically. For
non-LISP workflows use `RMR-EXPORT-PALETTE` / `RMR-IMPORT-PALETTE` (CSV round-trip).

Layer descriptions are stored the AutoCAD-native way: XDATA under
`AcAecLayerStandard` plus the COM `Description` property where ActiveX exists, so they
show up in the Layer Properties Manager.

## Production workflow cheat-sheet

```text
RMR-PRO-SETUP        ; once per office / template
RMR-SHEET  A1        ; frame + title block
RMR-SCALE  1:50 LAYOUT
RMR-GRID             ; structural bubbles
RMR-HATCH            ; materials
RMR-ROOMTAG          ; room tags with areas
RMR-AREA             ; area schedule
RMR-KEYNOTE RMR-LEVEL RMR-DETAIL RMR-NORTH
RMR-NOTES  RMR-REVTABLE  RMR-STAMP
RMR-CHECK            ; QA before issue
RMR-PAGESETUP  RMR-PUBLISH
RMR-SAVE-TEMPLATE    ; freeze as .DWT
```

## Preview sheet and QA tooling

`tools/make_preview_dxf.py` parses the LISP data tables (it never hard-codes palette
values) and rebuilds the A1 preview sheet: sample 1:50 apartment plan with walls,
doors, glass, columns, furniture, plumbing, grid bubbles, room tags, dimensions,
keynotes, level datum, section marker, north arrow, scale bar, area schedule,
revision table, layer palette legend, text-style samples, symbol gallery, the
12-material hatch strip, general notes and the command panel. Regenerate with:

```bash
python -m venv .venv-rmr && .venv-rmr/bin/pip install ezdxf matplotlib
./.venv-rmr/bin/python autocad/tools/make_preview_dxf.py
```

`tools/rmr_lint.py` statically checks the LISP before every delivery (string
termination, parenthesis balance, defun argument/local hygiene, duplicate defuns,
undeclared `setq`, unknown function calls, quoted-symbol references and unset global
variables). Current state: **PASS**, 0 findings.

```bash
python3 autocad/tools/rmr_lint.py autocad/RooMNRooF_Master.lsp
```

## Notes and limitations

- Requires full AutoCAD 2018+ (ActiveX paths degrade gracefully on AutoCAD LT /
  restricted environments; hatch, COM styling and plotting are wrapped in
  `vl-catch-all-apply` and report failures instead of crashing).
- Plot device / plot style names (`*RMR-PLOT-DEVICE*`, `*RMR-PLOT-STYLE*`) must exist on
  the machine that plots; defaults fall back to `DWG To PDF.pc3` and `monochrome.ctb`.
- The `.DWT` is produced in AutoCAD via `RMR-SAVE-TEMPLATE`; this package ships the
  generator, documentation and previews only.
