# RooMNRooF PRO 2D AutoCAD Standard — 5.0 DELIVERY SUITE

`RooMNRooF_Master.lsp` is a professional, metric AutoLISP generator for a modern
consultant 2D CAD standard. It creates a consistent visual system rather than only a
list of layers: brand colours, lineweight hierarchy, modern font fallback, rich text /
dimension / multileader styles, annotation symbols, sheet graphics and a full production
suite (scale, grids, areas, stamps, revisions, notes, hatch library, layer control,
QA, page setup and publishing) plus the 4.0 studio suite (layouts with scaled
viewports, section / elevation / match / break / cloud markers, dimension launcher,
parametric symbol library, door schedules, text find/replace, live fields, project
data files and timestamped backups) plus the 5.0 delivery suite (parametric walls
and stairs, linear takeoff, bill of materials, room finishes and drawing registers,
xref register, transmittal records, layer states, ByLayer standardisation, drawing
clean-up and project-driven drawing properties).

Version string inside the LISP: `*RMR-VERSION* = "5.0 DELIVERY SUITE"`.

## Package contents

| File | Purpose |
| --- | --- |
| `RooMNRooF_Master.lsp` | The complete AutoLISP application (generator + production suite). |
| `README.md` | This document. |
| `preview/RooMNRooF_PRO_Standard_Preview.dxf` | A1 preview sheet generated from the shipped palette data (open in AutoCAD or any DXF viewer). |
| `preview/RooMNRooF_PRO_Standard_Preview.png` | Rendered A1 preview sheet (dark presentation ground). |
| `preview/RooMNRooF_PRO_Plan_Detail.png` | Zoomed 1:50 sample apartment plan from the same sheet. |
| `preview/RooMNRooF_PRO_Studio_Suite.dxf` | A1 sheet showing the 4.0 studio suite: layouts, viewports, title block, markers, symbol library and door schedules. |
| `preview/RooMNRooF_PRO_Studio_Suite.png` | Rendered studio-suite sheet. |
| `preview/RooMNRooF_PRO_Delivery_Suite.dxf` | A1 sheet showing the 5.0 delivery suite: parametric walls and stair, takeoff, bill of materials, finishes, register, transmittal, xrefs and housekeeping. |
| `preview/RooMNRooF_PRO_Delivery_Suite.png` | Rendered delivery-suite sheet. |
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

## Command reference (57 commands)

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

### Studio suite (new in 4.0)
| Command | What it does |
| --- | --- |
| `RMR-LAYOUTS` | Creates a new layout: paper size (A0–A4), branded `RMR-TITLEBLOCK` with live attributes, and an optional scaled viewport. |
| `RMR-VPORT` | Adds a scaled, display-locked viewport to the active layout (falls back to `MVIEW` where ActiveX is unavailable). |
| `RMR-SECTION` | Section cut line with viewing-direction arrows and numbered sheet bubbles at both ends. |
| `RMR-ELEVATION` | Elevation marker with direction arrow, number and sheet reference. |
| `RMR-MATCHLINE` | Phantom match line to the adjoining sheet, with upright labels at both ends. |
| `RMR-BREAKLINE` | Break / cut line drawn as a bulged polyline. |
| `RMR-REVCLOUD` | Revision cloud: pick points, or pick two corners for a rectangular cloud. |
| `RMR-DIM` | Dimension launcher: pick a style (`RMR-DIM-PLAN/DETAIL/LARGE`) then linear, aligned, ordinate, radial, angular or continue. |
| `RMR-SYMBOLS` | Builds the parametric `RMR-SYM-*` library: doors (700/800/900/1000 single, 1500 double), window, WC, basin, shower, single/double bed, desk, chair, sofa, washer. |
| `RMR-DOORSCHED` | Door schedule table built from inserted `RMR-SYM-DOOR*` blocks and their `TAG` / `WIDTH` attributes, sorted by tag. |
| `RMR-FINDTEXT` | Find / replace across `TEXT`, `MTEXT` and `ATTRIB`, with `*` wildcards. |
| `RMR-FIELDS` | Inserts live fields (date, drawing name, layout, area, block name) or project values as static text. |
| `RMR-PROJECT` | Show / set / save / load project data (`*RMR-PROJECT*`), and fill every inserted title block from it. |
| `RMR-BACKUP` | Timestamped backup copy of the drawing into the drawing folder. |


### Delivery suite (new in 5.0)
| Command | What it does |
| --- | --- |
| `RMR-WALL` | Parametric double-line wall: pick a wall type (`*RMR-WALL-SPECS*`) then a path; corners are mitred so both faces stay exactly on thickness, with cap lines and a type label. |
| `RMR-STAIR` | Parametric straight stair: width, risers, going and direction of travel produce the outline, treads, walking line, direction arrow and an "UP 16R @ 280" label. |
| `RMR-LENGTH` | Linear takeoff across LINE / LWPOLYLINE / ARC / CIRCLE / ELLIPSE / SPLINE, with an optional in-drawing label and CSV export. |
| `RMR-BOM` | Bill of materials from block inserts, counted per block name **and** layer, sorted by quantity, drawn as a table and/or written to CSV. |
| `RMR-FINISHES` | Room finishes schedule (room, floor, skirting, wall, ceiling, notes) straight from the editable `*RMR-FINISH-SPECS*` table. |
| `RMR-SHEETREG` | Drawing register / sheet index from the editable `*RMR-SHEET-LIST*` table. |
| `RMR-XREFLIST` | Lists attached xrefs with resolved source paths and draws an xref register table. |
| `RMR-TRANSMITTAL` | Issue / transmittal record for the whole set: sheet, title, revision, issue date and a signature column, headed with the live project data. |
| `RMR-LAYERSTATE` | Save / restore / list / delete layer states in a plain `.rms` text file (`Name;Colour;Linetype;Lineweight;Frozen;Off;Locked`). Restore preserves xref-dependent flags and reports what it skipped. |
| `RMR-STANDARDIZE` | Forces colour, linetype and lineweight of a selection (or the whole drawing) to `BYLAYER`. |
| `RMR-CLEAN` | Three `-PURGE` passes plus an `AUDIT`, then optionally runs `RMR-STANDARDIZE`. |
| `RMR-DWGPROPS` | Writes title, subject, author, category, keywords and comments from `*RMR-PROJECT*` into the drawing properties. |


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
- `*RMR-PROJECT*` — dotted-pair project data (CLIENT, PROJECT, JOB, STAGE, TITLE,
  DWGNO, REV, DATE, DRAWN, CHECKED, SCALE, SIZE) used by the title block,
  fields and schedules; save/load it with `RMR-PROJECT`.
- `*RMR-CLOUD-ARC*` — revision cloud bulge factor (default `0.65`)
- `*RMR-WALL-SPECS*` — wall types: `(Key Thickness Layer Description)`
- `*RMR-FINISH-SPECS*` — room finishes: `(Room Floor Skirting Wall Ceiling Notes)`
- `*RMR-SHEET-LIST*` — drawing register / transmittal rows:
  `(SheetNumber Title Scale Revision Status)`

Groups currently shipped: **Control, Main Theme, Furniture, Structural, Plumbing,
Annotation, Presentation**. Version 4.0 adds `RMR-A-MATCH` (match / break / cut
lines, phantom) and `RMR-PRES-VPORT` (viewport frames and labels) to those groups. Add a row (or a whole new group) and every generator,
legend, layer-group command and the preview tool pick it up automatically. For
non-LISP workflows use `RMR-EXPORT-PALETTE` / `RMR-IMPORT-PALETTE` (CSV round-trip).

Layer descriptions are stored the AutoCAD-native way: XDATA under
`AcAecLayerStandard` plus the COM `Description` property where ActiveX exists, so they
show up in the Layer Properties Manager.

## Production workflow cheat-sheet

```text
RMR-PRO-SETUP        ; once per office / template
RMR-LAYOUTS  A1      ; layout: paper + title block + scaled viewport
RMR-SHEET  A1        ; frame + title block (model-space sheet)
RMR-SCALE  1:50 LAYOUT
RMR-GRID             ; structural bubbles
RMR-HATCH            ; materials
RMR-ROOMTAG          ; room tags with areas
RMR-AREA             ; area schedule
RMR-WALL  RMR-STAIR        ; parametric walls and stairs
RMR-SECTION RMR-ELEVATION RMR-MATCHLINE RMR-BREAKLINE RMR-REVCLOUD
RMR-DIM                ; dimensions on the right style and layer
RMR-SYMBOLS RMR-DOORSCHED
RMR-KEYNOTE RMR-LEVEL RMR-DETAIL RMR-NORTH
RMR-NOTES  RMR-REVTABLE  RMR-STAMP
RMR-FINISHES  RMR-SHEETREG   ; finishes and drawing register
RMR-BOM  RMR-LENGTH          ; quantities
RMR-XREFLIST                 ; check attached references
RMR-FINDTEXT         ; global wording fixes
RMR-PROJECT FILLTITLE ; push project data into every title block
RMR-LAYERSTATE SAVE / RMR-STANDARDIZE  ; freeze a state, force BYLAYER
RMR-CLEAN  RMR-DWGPROPS      ; clean up and stamp the properties
RMR-CHECK            ; QA before issue
RMR-PAGESETUP  RMR-PUBLISH
RMR-TRANSMITTAL      ; issue record for the set
RMR-BACKUP           ; timestamped safety copy
RMR-SAVE-TEMPLATE    ; freeze as .DWT
```

## Preview sheet and QA tooling

`tools/make_preview_dxf.py` parses the LISP data tables (it never hard-codes palette
values) and rebuilds two A1 sheets: the standard sheet (below) and
`RooMNRooF_PRO_Studio_Suite.dxf`, which previews the 4.0 studio suite — layout and
viewport setup, the branded `RMR-TITLEBLOCK`, section / elevation / match / break /
cloud markers, the `RMR-SYM-*` symbol gallery, a door schedule and the project-data
panel — and `RooMNRooF_PRO_Delivery_Suite.dxf`, which previews the 5.0 delivery
suite: a mitred parametric wall plan, a 16-riser stair, the takeoff readout and
bill of materials, the finishes schedule, drawing register, transmittal record,
xref register and the housekeeping panel. The standard sheet contains: sample 1:50 apartment plan with walls,
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
variables). Current state: **PASS**, 0 findings (190,775 bytes / 4,849 lines, 180 defuns,
57 commands).

```bash
python3 autocad/tools/rmr_lint.py autocad/RooMNRooF_Master.lsp
```

## Notes and limitations

- `RMR-WALL` mitres corners by bisecting the offset; extremely sharp corners are
  clamped to four times the offset so geometry can never run away.
- `RMR-LAYERSTATE` uses its own `.rms` text format instead of the `-LAYERSTATE`
  command line, so it behaves identically on every AutoCAD build.
- `RMR-LAYOUTS` / `RMR-VPORT` create viewports through ActiveX and fall back to the
  `MVIEW` command where `vla-addpviewport` is unavailable (some 64-bit builds).
- `RMR-BACKUP` leaves you in the newly saved backup drawing, matching AutoCAD's
  `SAVEAS` behaviour.
- Requires full AutoCAD 2018+ (ActiveX paths degrade gracefully on AutoCAD LT /
  restricted environments; hatch, COM styling and plotting are wrapped in
  `vl-catch-all-apply` and report failures instead of crashing).
- Plot device / plot style names (`*RMR-PLOT-DEVICE*`, `*RMR-PLOT-STYLE*`) must exist on
  the machine that plots; defaults fall back to `DWG To PDF.pc3` and `monochrome.ctb`.
- The `.DWT` is produced in AutoCAD via `RMR-SAVE-TEMPLATE`; this package ships the
  generator, documentation and previews only.
