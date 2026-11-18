# RooMNRooF PRO 2D AutoCAD Standard — 13.0 FACILITY MANAGEMENT SUITE

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
clean-up and project-driven drawing properties) plus the 6.0 site and services
suite (solar study diagrams, falls and drainage runs, parking and tiling setout,
reflected ceiling plans, level and keynote libraries, a printable standard report
and a stray-layer audit) plus the 7.0 coordination suite (bounding-box clash
checks between layer groups, parametric gable / hip / shed roof plans, balustrades
with spaced posts, a glazing schedule counted from the symbol library, zone plans
hatched by area band, block swap, tag renumbering, text-to-baseline alignment, a
full object information report and true-north orientation) plus the 8.0
documentation suite (a specification clause library and index, an abbreviations
legend, a data-driven revision history, a pre-issue checklist, a room data
schedule built from picked boundaries, a folder document list, a sheet index, a
project cover sheet and one command that lays out a complete documentation
sheet) plus the 9.0 presentation suite (axonometric massing extruded from a plan
outline, one point interior perspectives, layered construction build-ups with
leaders, a material swatch board, a colour reference board, an image board, an
area distribution chart, a programme bar chart, the brand masthead and a
complete client presentation sheet) plus the 10.0 quantity and automation suite
(measured survey import, interactive measurement, a rate-driven quantity
takeoff, a rate library, an elemental cost plan, a cost per m² dashboard, a
cash flow curve, generic CSV import, quantity validation and a full quantity
surveyor report, then short command aliases, a menu / tool palette file, a
scripted automation runner and a batch script writer for whole folders of
drawings) plus the 11.0 structural and MEP coordination suite (parametric
columns, beams, pad and strip foundations, reinforcement, slab panels,
setting-out coordinates and a structural element schedule, then ductwork,
pipework, cable containment, lighting, sprinklers, a services schedule and a
vertical clearance check against the service zone bands, all drawn on a new
true-colour **SERVICES** layer group) plus the 12.0 construction detailing
suite (a detail library, a parametric junction builder driven by the
construction build-up tables, detail tags with a running counter, locator
plans, continuous dimension chains, a materials key, a detail scale bar, a
complete A1 detail sheet, a specification link block, the detail index, a U
value calculator, fire compartment lines, acoustic ratings and a detail
compliance check, plus `RMR-A-FIRE` and `RMR-A-ACOUSTIC` annotation layers)
plus the 13.0 facility management suite (asset tags with automatic numbering,
asset registers read from the session or the drawing, printable asset label
sheets with a CSV export, maintenance cards built from the task table, a 52
week PPM planner, work orders with priority and response times, condition
grading 1 to 5, lifecycle replacement forecasts with a five year budget,
space standard and occupancy checks, room data sheets, a statutory compliance
register with real next-due month arithmetic, inspection stamps and a session
report, all drawn on a new **FACILITY** layer group `RMR-FM-`).

Version string inside the LISP: `*RMR-VERSION* = "13.0 FACILITY MANAGEMENT SUITE"`.

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
| `preview/RooMNRooF_PRO_Site_Services_Suite.dxf` | A1 sheet showing the 6.0 site and services suite: solar study, drainage, parking, tiling setout, RCP, level schedule, keynote legend and report excerpt. |
| `preview/RooMNRooF_PRO_Site_Services_Suite.png` | Rendered site and services sheet. |
| `preview/RooMNRooF_PRO_Coordination_Suite.dxf` | A1 sheet showing the 7.0 coordination suite: clash check, roof plans, balustrade and glazing schedule, zone plan with the band legend, the swap / renumber / align fixes and the object information report. |
| `preview/RooMNRooF_PRO_Coordination_Suite.png` | Rendered coordination sheet. |
| `preview/RooMNRooF_PRO_Documentation_Suite.dxf` | A1 sheet showing the 8.0 documentation suite: a specification clause note, the clause index grouped by trade, the abbreviations legend, the revision history with the current revision marked, the room data schedule, the sheet index grid, the pre-issue checklist, a cover-sheet thumbnail and the command list. |
| `preview/RooMNRooF_PRO_Documentation_Suite.png` | Rendered documentation sheet. |
| `preview/RooMNRooF_PRO_Presentation_Suite.dxf` | A1 sheet showing the 9.0 presentation suite: axonometric massing with the plan footprint it came from, a one point interior perspective, an external wall build-up with leaders, the material swatch board, the colour reference board, the programme bar chart, the area chart with the brand masthead, the image board and the command list. |
| `preview/RooMNRooF_PRO_Presentation_Suite.png` | Rendered presentation sheet. |
| `preview/RooMNRooF_PRO_Quantity_Suite.dxf` | A1 sheet showing the 10.0 quantity and automation suite: the rate library, a measured survey plot, a priced takeoff, the elemental cost plan, the cost per m² dashboard, the cash flow S curve, a CSV import table, the validation verdict and the automation sequence with the alias and menu output. |
| `preview/RooMNRooF_PRO_Quantity_Suite.png` | Rendered quantity and automation sheet. |
| `preview/RooMNRooF_PRO_Structural_MEP_Suite.dxf` | A1 sheet showing the 11.0 structural and MEP suite: a column grid with beams, pads on a strip with three rebar runs, a slab panel layout with its schedule, three duct sizes, three pipe sizes with a cable tray, a luminaire grid with its switch, a sprinkler grid with coverage circles, the vertical service zone diagram with its verdict, and the structural and services schedules. |
| `preview/RooMNRooF_PRO_Structural_MEP_Suite.png` | Rendered structural and MEP sheet. |
| `preview/RooMNRooF_PRO_Detailing_Suite.dxf` | A1 sheet showing the 12.0 construction detailing suite: six captioned detail frames, an eaves junction built from the roof and external wall build-ups, a locator plan with two detail bubbles, a dimension chain with witness ticks over a metric scale bar, the materials key, a U value calculation with its layer resistances, a fire compartment line and an acoustic partition with the ratings table, a specification link block above the detail index, and the A1 detail sheet in miniature with the compliance verdict. |
| `preview/RooMNRooF_PRO_Detailing_Suite.png` | Rendered construction detailing sheet. |
| `preview/RooMNRooF_PRO_Facility_Management_Suite.dxf` | A1 sheet showing the 13.0 facility suite: asset tags and a register, a 52 week PPM planner with the visits marked, a compliance table with an inspection stamp, a maintenance card beside a work order card, the five condition grades with the action each one triggers, a lifecycle table with a five year budget chart, a room data sheet beside a space standard check, an occupancy and utilisation panel with the space budget, and six asset labels with the CSV column set. |
| `preview/RooMNRooF_PRO_Facility_Management_Suite.png` | Rendered facility management sheet. |
| `tools/rmr_lint.py` | Standalone static checker that validates the LISP structure before delivery. |
| `tools/make_preview_dxf.py` | Regenerates the preview DXF/PNGs directly from the LISP data tables (needs `ezdxf`, `matplotlib`). |
| `tools/check_preview_sheets.py` | Layout audit for the generated sheets: text outside the frame and copy that would overprint other copy. |

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

## Command reference (153 commands)

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


### Site and services (new in 6.0)
| Command | What it does |
| --- | --- |
| `RMR-SUNPATH` | Solar study diagram for a chosen latitude: horizon circle, altitude rings, summer / equinox / winter declination curves, hour marks, N-E-S-W and the three noon altitudes. |
| `RMR-FALL` | Fall arrow between two points with the gradient label and the drop calculated over the picked run (1:40 / 1:60 / 1:80 / 1:100 / 1:120). |
| `RMR-DRAIN` | Drainage run along a picked path: pipes, numbered manholes and invert levels that fall automatically at the chosen gradient. |
| `RMR-PARK` | Parametric parking row: bay width, depth, count, aisle and 90 / 60 / 45 degree bay angle, with numbered bays and a summary label. |
| `RMR-TILE` | Tiling setout grid with tile count and waste allowance; reports how many tiles to order. |
| `RMR-RCP` | Reflected ceiling plan: ceiling grid module plus light fittings at a chosen spacing, with a fitting count. |
| `RMR-LEVELSCHED` | Level schedule from the editable `*RMR-LEVEL-SPECS*` table. |
| `RMR-KEYLIB` | Keynote legend drawn straight from the editable `*RMR-KEYNOTES*` library. |
| `RMR-REPORT` | Writes a printable text report of the entire standard: project data, layers by group, text and dimension styles, hatch library, wall types, levels, keynotes, drawing register and notes. |
| `RMR-STRAY` | Audits the drawing for objects on layers that are not in `*RMR-LAYER-SPECS*` (ignoring xrefs, layer 0 and Defpoints) and can move them onto a standard layer. |


### Coordination suite (new in 7.0)
| Command | What it does |
| --- | --- |
| `RMR-CLASH` | Bounding-box clash check between two layer groups (MAIN / FURNITURE / STRUCTURAL / PLUMBING). Every box in one group is compared with every box in the other; overlaps are listed with the two layers and the overlap area in mm² and can be circled on `RMR-A-REVISION`. |
| `RMR-ROOF` | Parametric roof plan from two corners: GABLE / HIP / SHED, eaves overhang (600 mm default) and pitch (25° default). The ridge runs along the longer axis; the hip ridge is `long − short`, the gable ridge is the full length and a shed draws no ridge. Adds a slope arrow and a `TYPE \| PITCH n DEG \| n m EAVES` label. |
| `RMR-RAIL` | Balustrade along a picked polyline path: thickness (100 mm default) and post spacing (1100 mm default). Offsets the path to both faces and places post circles, skipping the duplicated post at every shared corner vertex. |
| `RMR-WINDOWSCHED` | Glazing schedule counted from the `RMR-SYM-WINDOW*` inserts in the drawing, grouped by block name and layer, sorted descending by quantity, drawn as a `NO. / TYPE / LAYER / QTY` table. |
| `RMR-ZONE` | Hatches each selected closed area on `RMR-M-AREA` with the colour and pattern of its band from `*RMR-ZONE-BANDS*`, prints the band counts and total m², and can draw the band legend with the total. |
| `RMR-BLKSWAP` | Replaces every insert of one block with another while keeping the layer, insertion point, rotation and scale. Attributed inserts are skipped and counted, because their attribute references cannot be rebuilt safely. |
| `RMR-RENUMBER` | Renumbers picked TEXT / MTEXT tags in selection order with an optional prefix, a start number and optional two-digit padding. |
| `RMR-TEXTALIGN` | Projects the insertion point of each selected single-line text onto a picked baseline and rotates the text to match the line (resets DXF 72 / 73 and sets 50 to the baseline angle). |
| `RMR-INFO` | Full report for one object: entity type, layer, colour (BYLAYER / BYBLOCK / index), true colour R-G-B, linetype, lineweight, block name, style, text content, plus length in mm and m and area in m² and sq ft. |
| `RMR-ORIENT` | Rotates every object in model space about a picked base point by a prompted angle so drawing north matches true north; answer `No` to only read the current angle. |


### Documentation suite (new in 8.0)
| Command | What it does |
| --- | --- |
| `RMR-SPECNOTE` | Places one clause from `*RMR-SPEC-CLAUSES*` as a note: a filled tab with the clause code, the work-section title, a trade line and the clause text wrapped to the width you pick. |
| `RMR-SPECINDEX` | Draws the whole clause index grouped by trade, with a terra band for every trade heading and one row per clause. |
| `RMR-ABBREV` | Two-column abbreviations legend from `*RMR-ABBREV-SPECS*`, so a long list takes half the sheet height. |
| `RMR-REVLIB` | Revision history table from `*RMR-REVISIONS*` (revision, date, description, by). The revision that matches `*RMR-PROJECT*` is highlighted, so the table and the title block can never drift apart. |
| `RMR-CHECKLIST` | Prints the pre-issue checklist from `*RMR-CHECKLIST-SPECS*` to the command line and can draw it grouped, with an empty tick box beside every item. |
| `RMR-ROOMSCHED` | Builds a room data schedule interactively: select each closed boundary, name the room, and it records the area in m² plus the floor, wall and ceiling finish pulled from `*RMR-FINISH-SPECS*` when the room name matches. Rows are numbered and totalled in m² and sq ft. |
| `RMR-DOCLIST` | Lists every DWG and PDF next to the current drawing with its size in KB, draws it as a table and optionally writes a CSV document list. |
| `RMR-SHEETINDEX` | Cover-sheet style sheet index grid from `*RMR-SHEET-LIST*` with the number, title, scale, revision and status in each cell; the current sheet number is highlighted. |
| `RMR-COVER` | Complete project cover sheet (A0-A4): frame, brand strip, project and client identity, job / stage / date, the drawing set listing and the title block. |
| `RMR-DOCSHEET` | Lays out a whole A1 documentation sheet in one command: frame, banner, specification index, abbreviations, revision history, checklist and title block. |


### Presentation suite (new in 9.0)
| Command | What it does |
| --- | --- |
| `RMR-AXO` | Extrudes any closed plan outline into a 30° axonometric mass: the top face is filled, only the vertical faces whose outward normal points at the viewer are shaded (in two tones), every corner gets a vertical edge and the height is labelled. |
| `RMR-ROOMVIEW` | One point interior perspective of a room: width, depth, height and eye level, with the back wall placed as a fraction of the distance to the vanishing point, a converging floor grid, five shaded surfaces and the room size label. |
| `RMR-BUILDUP` | Layered construction build-up from `*RMR-BUILDUP-SPECS*` (external wall, internal wall, floor and roof). Every layer is drawn to scale, hatched in its own colour and labelled through a leader, with the total thickness underneath. |
| `RMR-SWATCH` | Material swatch board: every entry in `*RMR-HATCH-SPECS*` drawn as a true-colour hatched square with its key, name and pattern. Columns are prompted, rows follow. |
| `RMR-COLOURBOARD` | Colour reference board: the seven brand colours with their RGB values, then every layer in the palette grouped by theme with its swatch, name and RGB. |
| `RMR-MOODBOARD` | Image board from `*RMR-MOOD-SPECS*`: captioned frames with a placeholder cross and a numbered tab, ready for `IMAGEATTACH`. |
| `RMR-AREACHART` | Area distribution bar chart. Select each room boundary, name it, and the command draws a bar scaled to the largest room with the area in m² and the share of the total as a percentage. |
| `RMR-PROGRAMME` | Programme bar chart from `*RMR-PROGRAMME-SPECS*`: a week grid with a tick every four weeks and one colour-coded bar per stage, with the duration beside it. |
| `RMR-BRANDING` | The RooMNRooF masthead — wordmark, rule, straplines, project name and client / job / stage / date — filled from `*RMR-PROJECT*` at any scale. |
| `RMR-PRESENTSHEET` | Lays out a complete A1 client presentation sheet in one command: frame, masthead, material swatch board, programme, image board, three captioned view frames, the brand palette strip and the title block. |


### Quantity suite (new in 10.0)
| Command | What it does |
| --- | --- |
| `RMR-SURVEY` | Imports a measured survey CSV (`number,east,north,level`). Blank coordinate rows are dropped, the coordinates are normalised to the first point, and every point is plotted as a numbered marker with its level and a traverse polyline on `RMR-00-REF`. Reports the site extent and the level range. |
| `RMR-MEASURE` | Interactive measurement. Pick objects one after another: closed ones contribute area, open ones length. Running totals are kept **per unit** so square metres are never added to metres, and the list is drawn on the drawing with both totals underneath. |
| `RMR-QUANTITY` | Rate-driven takeoff. Pick a basis (length, area, count or finish), select the objects, choose a rate code from `*RMR-RATE-SPECS*`, and the command measures, prices and adds a row. Finish and it draws the full table with the total. |
| `RMR-RATES` | Draws the rate library: every entry in `*RMR-RATE-SPECS*` with its code, description, unit and rate. |
| `RMR-COSTPLAN` | Elemental cost plan bar chart from `*RMR-ELEMENT-SPECS*`: one colour-coded bar per element with its allowance and its share of the total, and the plan total underneath. |
| `RMR-PERQM` | Cost per m² dashboard. Asks for the cost, the gross internal floor area and a benchmark, then draws the rate as a large number, two comparison bars (this project and the benchmark) and the over / under percentage. |
| `RMR-CASHFLOW` | Cash flow curve. Spreads the elemental total across the programme in `*RMR-PROGRAMME-SPECS*`, each stage evenly over its own weeks, then draws the weekly spend bars above the axis and the cumulative S curve over the full height. |
| `RMR-CSVIMPORT` | Brings any CSV into the drawing as a table: the first row becomes the header band, the rest become body rows, 41 rows maximum and the columns are auto-sized. |
| `RMR-VALIDATE` | Checks the rate library (known unit, rate above zero) and lists every block in the drawing that is not part of the standard, so nothing goes unpriced. PASS / REVIEW verdict, optional `.txt` report. |
| `RMR-QSREPORT` | Writes the complete quantity surveyor report to a text file: project details, the rate library, the elemental cost plan with shares, the cost per m² and the programme cash flow by stage. |

### Automation (new in 10.0)
| Command | What it does |
| --- | --- |
| `RMR-ALIAS` | Discovers every `C:RMR-*` command from the symbol table, registers a short alias for each one (`RMR-AXO` → `RAXO`) with `vlax-add-cmd`, and writes ready-to-paste lines to `RooMNRooF.pgp`. Because the list is discovered at run time it can never fall out of step with the code. |
| `RMR-TOOLPALETTE` | Writes `RooMNRooF.mnu`: a pull-down menu with 14 sections — one per suite, covering all 111 commands — plus a floating toolbar. Load it with `MENULOAD` (or `CUILOAD` on newer builds). |
| `RMR-AUTO` | Runs the scripted sequence in `*RMR-AUTO-SEQUENCE*` (build the standard, set the scale, force ByLayer, write the drawing properties, audit stray layers, write the aliases, purge and audit) and writes `RooMNRooF_Automation_Log.txt` beside the drawing. |
| `RMR-BATCH` | Picks any drawing in a folder, asks which commands to run, and writes `RooMNRooF-Batch.scr` that opens every `.dwg` in that folder, runs the steps and saves and closes. Review it first, then run it with `SCRIPT`. |

### Structural suite (new in 11.0)
| Command | What it does |
| --- | --- |
| `RMR-COLUMN` | Places columns from `*RMR-COLUMN-SPECS*`. Each one is a filled section on `RMR-S-COLUMN` with a setting-out cross, a mark bubble and a size label underneath. |
| `RMR-BEAM` | Places beams from `*RMR-BEAM-SPECS*`. Two picked points give a four-sided section filled in the mark colour, with a rotated `mark / width x depth / span` label, and a warning when the span passes the mark's limit. |
| `RMR-FOUNDATION` | Pads or strips. Pads are filled squares with a hidden-line inner offset and a `PAD 900 X 900 X 450 DP` label; strips are offset polylines either side of a picked centre line with the run length. |
| `RMR-REBAR` | Reinforcement runs from `*RMR-REBAR-SPECS*`: a bar with 90° hooks at both ends, a mark bubble and a `T16 @ 200` label. Hooks are symbolic, drawn at the annotation scale. |
| `RMR-SLABPANEL` | Splits a picked rectangle into panels on a chosen module, horizontally or vertically, labelling each `P01`, `P02`… and writing an optional panel schedule. The last panel is clipped to the boundary. |
| `RMR-SETOUT` | Setting-out coordinates. Every picked point becomes a numbered marker with its easting and northing, an on-screen table, and an optional `POINT,EASTING,NORTHING` CSV. |
| `RMR-STRUCTSCHED` | Counts the structural layers in the drawing and draws the schedule, with an optional `.txt` report. |

### Services / MEP suite (new in 11.0)
| Command | What it does |
| --- | --- |
| `RMR-DUCT` | Ductwork runs from `*RMR-DUCT-SPECS*`. Each run is offset both sides of the picked route, hatched as one closed body, and labelled with its size and length, with a flow arrow at the end. |
| `RMR-PIPE` | Pipework runs from `*RMR-PIPE-SPECS*`. Same construction as the duct run, plus a fall — `1:80` by default — in the label and a flow arrow. |
| `RMR-TRAY` | Cable containment: two side rails offset from the route plus rungs walked along every segment at the spacing you set. |
| `RMR-LIGHTING` | Luminaire grid over a picked rectangle: spacing across and down, a circuit letter, watts per fitting. Every fitting is tagged `A1`, `A2`…, a switch is drawn at the picked corner and an optional schedule lists the circuit load in kW. |
| `RMR-SPRINKLER` | Sprinkler grid with a coverage circle per head, numbered `S01`, `S02`…, reporting the protected area in m². |
| `RMR-MEPSCHED` | Counts every services layer in the drawing and draws the schedule, with an optional `.txt` report. |
| `RMR-CLEARANCE` | Draws the vertical service zone bands from `*RMR-SERVICE-ZONES*`, then groups every services layer that carries geometry by the zone in `*RMR-SERVICE-LAYER-ZONES*`. Any zone carrying more than one service is listed as a shared zone to coordinate, with a PASS / REVIEW verdict and an optional report. |

### Construction detailing suite (new in 12.0)
| Command | What it does |
| --- | --- |
| `RMR-DETAILLIB` | Lays out one captioned frame per entry in `*RMR-DETAIL-SPECS*` — number, title and scale in the caption bar, a placeholder cross in the picture area — across as many columns as you ask for. |
| `RMR-JUNCTION` | Parametric junction builder. Pick a junction type and the command reads both legs out of `*RMR-BUILDUP-SPECS*`, draws the horizontal leg as layers stacked downwards and the vertical leg as layers stacked across, hatches every layer in its own colour and lists each one with its thickness. |
| `RMR-DETAILTAG` | Detail bubble and leader. Pick the point of interest, then the bubble position; the number comes from the library or from a session counter that runs `D01`, `D02`…, and each tag carries its sheet reference and title. |
| `RMR-DETLOC` | Locator plan: a light setting-out grid over a picked rectangle with the detail position ringed and called out. |
| `RMR-DIMCHAIN` | Continuous dimension chain with witness ticks and a running total, drawn on `RMR-A-DIMS` at a chosen offset. |
| `RMR-MATKEY` | Materials key for any build-up type: swatch, layer name, thickness and note. It reads the same table the junction builder draws from, so the two can never disagree. |
| `RMR-DETSCALE` | Sets the detail scale and syncs `DIMSCALE`, `CELTSCALE`, `LTSCALE`, `MSLTSCALE` and `PSLTSCALE`, then draws a metric scale bar — 100 mm increments at 1:20 and finer, 500 mm above that. |
| `RMR-DETSHEET` | Lays out a complete A1 detail sheet in one command: sheet frame, brand masthead, six captioned detail frames and the detail index. |
| `RMR-SPECLINK` | Links a detail to specification clauses from `*RMR-SPEC-CLAUSES*` and draws a `REFER TO SPECIFICATION` block under the detail. |
| `RMR-DETINDEX` | Detail index schedule: number, title, scale, category and sheet. |
| `RMR-UVALUE` | Thermal calculator. Build the construction layer by layer from `*RMR-MATERIAL-R-SPECS*`, and it draws the build-up with each layer's resistance, gives the total R and the U value in W/m²K, and can write the calculation to a text file. |
| `RMR-FIRESTOP` | Fire compartment line: a band along the picked route labelled with its rating from `*RMR-FIRE-SPECS*`, on the new `RMR-A-FIRE` layer. |
| `RMR-ACOUSTIC` | Acoustic rating markers on partitions from `*RMR-ACOUSTIC-SPECS*`, with an optional ratings table, on the new `RMR-A-ACOUSTIC` layer. |
| `RMR-CHECKDETAIL` | Detail compliance check: counts the detail markers, compares the library against what is tagged, confirms the scale and the title block, and writes an optional report with a PASS / REVIEW verdict. |

### Facility management suite (new in 13.0)
| Command | What it does |
| --- | --- |
| `RMR-ASSET` | Asset tag. Pick the type from `*RMR-ASSET-TYPES*`, then the position: a square tag with a tick cross, the category above, the type below and an automatic `A-001` number. Each tag is kept in the session asset log. |
| `RMR-ASSETREG` | Asset register. Draws a schedule of the session log, or — in a fresh drawing — reads the `A-###` tags already drawn on `RMR-FM-ASSET`, so a register can be rebuilt from the drawing itself. |
| `RMR-ASSETLABEL` | Printable asset label sheet: three column blocks of numbered labels with location, life and a CAFM note, plus an optional CSV (`ID,TYPE,CATEGORY,LOCATION,LIFE_YEARS,COST`). |
| `RMR-MAINT` | Maintenance card for one asset: every task in `*RMR-MAINT-TASKS*` whose category is `ALL` or matches the asset category, with its frequency and priority. |
| `RMR-PPM` | 52 week planned maintenance planner: one row per task and one column per month, with a cell marked every time the task falls due. |
| `RMR-WORKORDER` | Work order card: `WO-###` number, asset, priority, description and the response time that priority carries — `P1` 4 hours, `P2` 24, `P3` 120, `P4` 480. |
| `RMR-CONDITION` | Condition grade 1–5 marker. Each grade in `*RMR-CONDITION-GRADES*` carries a label, the action it triggers and a brand colour, so the marker reads on a plot. |
| `RMR-LIFECYCLE` | Lifecycle forecast: installation year plus each asset's life gives a replacement year, with the replacement cost and a five year budget total. |
| `RMR-SPACESTD` | Space standard check: pick the use from `*RMR-SPACE-STANDARDS*`, enter the area and the occupants, and it draws the achieved density against the minimum and target with a `PASS` / `REVIEW` verdict. |
| `RMR-ROOMDATA` | Room data sheet card: number, name, area, occupancy, density, finishes and services, with the density worked out for you. |
| `RMR-OCCUPANCY` | Occupancy and utilisation for a whole building: density and the percentage of the 12 m² benchmark, with a bar and an over-benchmark warning. |
| `RMR-COMPLIANCE` | Statutory compliance register. Enter the last inspection month per item and it computes the next due month from the interval in `*RMR-COMPLIANCE-ITEMS*`, grading each item `OK`, `DUE` or `OVERDUE` against today. |
| `RMR-INSPECT` | Inspection stamp: area, inspector, date, result and the next inspection month, coloured by the result. |
| `RMR-FMREPORT` | Facility management report for the session: asset register, work orders, condition records, compliance status and the totals, written to a text file. |

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
- `*RMR-LEVEL-SPECS*` — level schedule rows: `(Level Height_mm Description)`
- `*RMR-KEYNOTES*` — keynote library: `(Number Text)`
- `*RMR-SUN-CITIES*` — reference latitudes for `RMR-SUNPATH`: `(City Latitude)`
- `*RMR-ZONE-BANDS*` — zone bands for `RMR-ZONE`: `(Label MaxArea_m2 (R G B) Pattern)`,
  a teal ramp `UNDER 5 → 5 TO 15 → 15 TO 30 → 30 TO 60 → OVER 60` m², all `ANSI31`
- `*RMR-SPEC-CLAUSES*` — specification clauses: `(Code Trade WorkSection ClauseText)`,
  12 clauses across 6 trades
- `*RMR-ABBREV-SPECS*` — abbreviation legend: `(Abbreviation Meaning)`
- `*RMR-REVISIONS*` — revision log: `(Revision Date Description By)`
- `*RMR-CHECKLIST-SPECS*` — pre-issue checklist: `(Group Item)`
- `*RMR-BUILDUP-SPECS*` — construction layers:
  `(Type Order LayerName Thickness_mm (R G B) Pattern Note)`, 17 layers across
  `EXTWALL / INTWALL / FLOOR / ROOF`
- `*RMR-PROGRAMME-SPECS*` — programme bars: `(Stage StartWeek Weeks ColourKey)`
- `*RMR-MOOD-SPECS*` — image board slots: `(Slot Caption)`
- `*RMR-RATE-SPECS*` — rate library: `(Code Description Unit Rate)`, 12 rates
  across `m`, `m²`, `m³` and `nr`. Units are drawn as `m`, `m2`, `m3`, `nr`
  so they fit a narrow table cell
- `*RMR-ELEMENT-SPECS*` — elemental cost plan: `(Element Allowance ColourKey)`,
  8 elements totalling **339,000.00** with the colour keys
  `SLATE / TERRA / GOLD / TEAL / BLUE / SAND`. `RMR-COSTPLAN`, `RMR-PERQM`,
  `RMR-CASHFLOW` and `RMR-QSREPORT` all read the same numbers
- `*RMR-AUTO-SEQUENCE*` — the automation runner steps:
  `(Label Action Argument)`, 8 steps from `STANDARD` through to `LOG`
- `*RMR-COLUMN-SPECS*` — column sizes: `(Mark Width_mm Depth_mm ColourKey)`,
  6 marks from `C1 230 x 230` to `C6 450 x 600`
- `*RMR-BEAM-SPECS*` — beam sizes:
  `(Mark Width_mm Depth_mm MaxSpan_mm ColourKey)`, 5 marks from
  `B1 230 x 400` to `B5 400 x 850`
- `*RMR-REBAR-SPECS*` — reinforcement: `(BarMark Diameter_mm Spacing_mm)`,
  `T12` to `T40`, spacing tightening as the bar grows
- `*RMR-DUCT-SPECS*` — duct sizes: `(Size Width_mm Height_mm ColourKey)`,
  6 sizes from `100 X 100` to `800 X 400`
- `*RMR-PIPE-SPECS*` — pipe sizes: `(Size Bore_mm ColourKey)`,
  6 bores from 15 mm to 76 mm
- `*RMR-SERVICE-ZONES*` — vertical bands:
  `(Zone Bottom_mm Top_mm ColourKey Description)`, 5 contiguous bands from
  `0` to `1250` mm
- `*RMR-SERVICE-LAYER-ZONES*` — which vertical zone each services layer
  occupies: `(Layer Zone)`, 13 rows. `RMR-CLEARANCE` reads both tables, so
  retargeting a service is a one-row edit
- `*RMR-DETAIL-SPECS*` — the detail library:
  `(Number Title Scale Category)`, 12 details across
  `ROOF / FLOOR / WALL / OPENING`
- `*RMR-JUNCTION-SPECS*` — junctions: `(Type Category LegA LegB Description)`,
  6 junctions. `LegA` and `LegB` name a type in `*RMR-BUILDUP-SPECS*`, so
  adding a junction is a one-row edit and changing a build-up updates every
  junction that uses it
- `*RMR-MATERIAL-R-SPECS*` — thermal properties:
  `(Material Lambda_WmK Thickness_mm Note)`, 8 materials from
  `PIR INSULATION` at 0.022 to `CONCRETE` at 1.130 W/mK
- `*RMR-FIRE-SPECS*` — fire ratings: `(Rating Minutes ColourKey Note)`,
  `NFR` through to `FD120`
- `*RMR-ACOUSTIC-SPECS*` — acoustic ratings: `(Rating Rw_dB Note)`,
  5 ratings from `Rw 38` to `Rw 58`
- `*RMR-ASSET-TYPES*` — asset types:
  `(Code Category LifeYears Cost MaintMonths Note)`, 12 types across mechanical,
  vertical transport, electrical, fire and fabric. `RMR-ASSET`,
  `RMR-ASSETLABEL` and `RMR-LIFECYCLE` all read it
- `*RMR-MAINT-TASKS*` — maintenance tasks:
  `(Code Task Category FreqMonths Priority Note)`, 12 tasks. Category `ALL`
  applies to every asset; any other value must match an asset category
- `*RMR-CONDITION-GRADES*` — `(Grade Label Action ColourKey)`, grades 1 to 5
- `*RMR-COMPLIANCE-ITEMS*` — `(Item Regulation IntervalMonths Owner)`, 8 items
- `*RMR-SPACE-STANDARDS*` — `(Key Use Min_m2 Target_m2 Note)`, 7 uses

Groups currently shipped: **Control, Main Theme, Furniture, Structural, Plumbing,
Services, Annotation, Presentation**. Version 4.0 adds `RMR-A-MATCH` (match / break / cut
lines, phantom) and `RMR-PRES-VPORT` (viewport frames and labels) to those groups.
Version 11.0 adds the whole **Services** group — `RMR-E-DUCT`, `RMR-E-GRILLE`,
`RMR-E-PIPE`, `RMR-E-EQUIP`, `RMR-E-POWER`, `RMR-E-LIGHT`, `RMR-E-TRAY`,
`RMR-E-DATA` and `RMR-E-SPRINK` — so every MEP discipline has its own
true-colour layer. Version 12.0 adds `RMR-A-FIRE` and `RMR-A-ACOUSTIC` to the
annotation group, and version 13.0 adds the whole **Facility** group —
`RMR-FM-ASSET`, `RMR-FM-MAINT`, `RMR-FM-ROOM` and `RMR-FM-ROUTE`. Add a row
(or a whole new group) and every generator,
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
RMR-STRAY  RMR-REPORT        ; audit layers, print the standard
RMR-CHECK            ; QA before issue
RMR-PAGESETUP  RMR-PUBLISH
RMR-SUNPATH  RMR-FALL  RMR-DRAIN   ; site studies
RMR-PARK  RMR-TILE  RMR-RCP        ; setout and services
RMR-LEVELSCHED  RMR-KEYLIB         ; schedules and legends
RMR-CLASH  RMR-ZONE                ; coordinate before issue
RMR-ROOF  RMR-RAIL                 ; roof plan and balustrade
RMR-WINDOWSCHED                    ; glazing quantities
RMR-BLKSWAP  RMR-RENUMBER  RMR-TEXTALIGN
RMR-INFO  RMR-ORIENT               ; interrogate and orientate
RMR-SPECNOTE  RMR-SPECINDEX         ; specification clauses
RMR-ABBREV  RMR-REVLIB              ; legend and revision history
RMR-ROOMSCHED  RMR-DOCLIST          ; room data and folder contents
RMR-SHEETINDEX  RMR-COVER           ; index and cover sheet
RMR-CHECKLIST  RMR-DOCSHEET         ; check, then lay out the doc sheet
RMR-AXO  RMR-ROOMVIEW               ; massing and interior perspective
RMR-BUILDUP  RMR-SWATCH             ; build-up and material board
RMR-COLOURBOARD  RMR-MOODBOARD      ; colour and image boards
RMR-AREACHART  RMR-PROGRAMME        ; area and programme charts
RMR-BRANDING  RMR-PRESENTSHEET      ; masthead and presentation sheet
RMR-SURVEY  RMR-MEASURE             ; survey in, quantities out
RMR-QUANTITY  RMR-RATES             ; priced takeoff
RMR-COSTPLAN  RMR-PERQM             ; elemental plan and cost per m2
RMR-CASHFLOW  RMR-CSVIMPORT         ; spend curve and any table
RMR-VALIDATE  RMR-QSREPORT          ; check, then write the report
RMR-ALIAS                           ; short aliases + RooMNRooF.pgp
RMR-TOOLPALETTE                     ; RooMNRooF.mnu menu and toolbar
RMR-AUTO                            ; run the standard end to end
RMR-BATCH                           ; script a whole folder of drawings
RMR-COLUMN  RMR-BEAM                 ; columns and beams from the size tables
RMR-FOUNDATION  RMR-REBAR            ; pads, strips and reinforcement
RMR-SLABPANEL  RMR-SETOUT            ; panels and setting-out coordinates
RMR-STRUCTSCHED                      ; structural element schedule
RMR-DUCT  RMR-PIPE  RMR-TRAY         ; ductwork, pipework, containment
RMR-LIGHTING  RMR-SPRINKLER          ; lighting and sprinkler grids
RMR-MEPSCHED  RMR-CLEARANCE          ; services schedule and zone check
RMR-DETAILLIB  RMR-JUNCTION          ; library and parametric junctions
RMR-DETAILTAG  RMR-DETLOC            ; tag the detail, locate the detail
RMR-DIMCHAIN  RMR-DETSCALE           ; dimension chain and detail scale
RMR-MATKEY  RMR-UVALUE               ; materials key and thermal check
RMR-FIRESTOP  RMR-ACOUSTIC           ; fire and acoustic ratings
RMR-SPECLINK  RMR-DETINDEX           ; link to spec, index the details
RMR-DETSHEET  RMR-CHECKDETAIL        ; lay out the sheet, then check it
RMR-ASSET  RMR-ASSETREG              ; tag the kit, list the kit
RMR-ASSETLABEL  RMR-MAINT            ; print the labels, plan the upkeep
RMR-PPM  RMR-WORKORDER               ; the year ahead, then today's job
RMR-CONDITION  RMR-LIFECYCLE         ; how it is now, when it needs replacing
RMR-SPACESTD  RMR-ROOMDATA           ; is the space right, what is in the room
RMR-OCCUPANCY  RMR-COMPLIANCE        ; utilisation, then the statutory register
RMR-INSPECT  RMR-FMREPORT            ; stamp the visit, report the month
RMR-TRANSMITTAL      ; issue record for the set
RMR-BACKUP           ; timestamped safety copy
RMR-SAVE-TEMPLATE    ; freeze as .DWT
```

## Preview sheet and QA tooling

`tools/make_preview_dxf.py` parses the LISP data tables (it never hard-codes palette
values) and rebuilds eleven A1 sheets: the standard sheet (below) and
`RooMNRooF_PRO_Studio_Suite.dxf`, which previews the 4.0 studio suite — layout and
viewport setup, the branded `RMR-TITLEBLOCK`, section / elevation / match / break /
cloud markers, the `RMR-SYM-*` symbol gallery, a door schedule and the project-data
panel — and `RooMNRooF_PRO_Delivery_Suite.dxf`, which previews the 5.0 delivery
suite: a mitred parametric wall plan, a 16-riser stair, the takeoff readout and
bill of materials, the finishes schedule, drawing register, transmittal record,
xref register and the housekeeping panel — and
`RooMNRooF_PRO_Site_Services_Suite.dxf`, which previews the 6.0 site and services
suite: the solar study diagram, a drainage run with invert levels, parking bays,
a tiling setout, a reflected ceiling plan, the level schedule, the keynote legend
and a report excerpt, and `RooMNRooF_PRO_Coordination_Suite.dxf`, which previews the
7.0 coordination suite: a clash check on two overlapping service runs, hip and gable
roof plans with the ridge lengths, a balustrade with spaced posts and the glazing
schedule, the zone plan with its band legend, the block swap / renumber / text-align
fixes and the object information report with the true-north rotation, and
`RooMNRooF_PRO_Documentation_Suite.dxf`, which previews the 8.0 documentation
suite: a specification clause note, the clause index grouped by trade, the
abbreviations legend, the revision history with the current revision marked, the
room data schedule, the sheet index grid, the pre-issue checklist and a cover-sheet
thumbnail, and `RooMNRooF_PRO_Presentation_Suite.dxf`, which previews the 9.0
presentation suite: an axonometric mass beside the plan footprint it came from, a
one point interior perspective with its floor grid, an external wall build-up with
leaders, the material swatch board, the colour reference board, the programme bar
chart, the area chart with the brand masthead and the image board, and
`RooMNRooF_PRO_Quantity_Suite.dxf`, which previews the 10.0 quantity and
automation suite: the 12-rate library, a 12-point measured survey with its
traverse, an 8-line priced takeoff with its total, the elemental cost plan
bars, the cost per m² dashboard against a benchmark, the weekly spend bars with
the cumulative S curve, a CSV import table, the validation verdict and the
eight automation steps with the alias and menu output, and
`RooMNRooF_PRO_Structural_MEP_Suite.dxf`, which previews the 11.0 structural and
MEP suite: a 3 x 2 column grid with two beams, three pads on a strip with three
rebar runs, a six-panel slab with its schedule, three duct sizes, three pipe
sizes above a cable tray, a luminaire grid with its switch, a sprinkler grid with
coverage circles, the vertical service zone diagram with its verdict, and the
structural and services schedules, and `RooMNRooF_PRO_Detailing_Suite.dxf`,
which previews the 12.0 construction detailing suite: six captioned detail
frames, an eaves junction built from the roof and external wall build-ups, a
locator plan with two detail bubbles, a dimension chain with witness ticks
over a metric scale bar, the materials key for an external wall, a U value
calculation with its layer resistances, a fire compartment line and an
acoustic partition with the ratings table, a specification link block above
the detail index, and the A1 detail sheet in miniature with the compliance
verdict, and `RooMNRooF_PRO_Facility_Management_Suite.dxf`, which previews the
13.0 facility suite: asset tags and a register, a PPM planner, a compliance
table with an inspection stamp, a maintenance card beside a work order card,
the condition grades, a lifecycle table with a five year budget chart, a room
data sheet beside a space standard check, an occupancy panel with the space
budget and six asset labels. The standard sheet contains: sample 1:50 apartment plan with walls,
doors, glass, columns, furniture, plumbing, grid bubbles, room tags, dimensions,
keynotes, level datum, section marker, north arrow, scale bar, area schedule,
revision table, layer palette legend, text-style samples, symbol gallery, the
12-material hatch strip, general notes and the command panel. Regenerate with:

```bash
python -m venv .venv-rmr && .venv-rmr/bin/pip install ezdxf matplotlib
./.venv-rmr/bin/python autocad/tools/make_preview_dxf.py
./.venv-rmr/bin/python autocad/tools/check_preview_sheets.py   # layout audit
```

`tools/check_preview_sheets.py` reads the generated DXFs back and reports copy that
runs outside the sheet frame and text boxes that would print on top of each other.
Current state across the eleven sheets: **0 problems** (2,764 text entities and
2,390 geometry entities checked).

`tools/rmr_lint.py` statically checks the LISP before every delivery (string
termination, parenthesis balance, defun argument/local hygiene, duplicate defuns,
undeclared `setq`, unknown function calls, quoted-symbol references and unset global
variables). Current state: **PASS**, 0 findings (520,168 bytes / 12,485 lines, 345 defuns,
153 commands).

```bash
python3 autocad/tools/rmr_lint.py autocad/RooMNRooF_Master.lsp
```

## Notes and limitations

- `RMR-AXO` fills only the vertical faces whose outward normal points at the
  viewer. Footprints are reversed to counter-clockwise first, so the test works
  whichever way the polyline was drawn; it is exact for convex footprints and a
  good approximation for concave ones.
- `RMR-ROOMVIEW` places the back wall as a fraction of the distance from each
  front corner to the vanishing point, which is a drawing convention rather than
  a true perspective divide. Depths between about 0.3 and 0.85 read well.
- `RMR-BUILDUP`, `RMR-SWATCH` and `RMR-ZONE` all hatch through the `-HATCH`
  command line, so the patterns must exist in the drawing. `SOLID` is handled
  separately because it has no scale or angle prompt.
- `RMR-ROOMSCHED` reads the area of whatever object you pick, so any closed
  polyline, circle or hatch works; objects with no `Area` property are skipped
  and the finish columns fall back to `-` when the room name is not in
  `*RMR-FINISH-SPECS*`.
- `RMR-DOCLIST` uses `vl-directory-files` on `DWGPREFIX`, so it lists the folder
  of the saved drawing, not the folder you last browsed to.
- `RMR-COVER` and `RMR-DOCSHEET` draw at paper size in model space (the same
  convention as `RMR-SHEET`), so their text is sized by the sheet scale factor
  rather than the annotation scale. Give them a scale of `1.0` for a true A1.
- `RMR-SPECINDEX` groups *contiguous* trades only: sort `*RMR-SPEC-CLAUSES*` by
  trade if you reorder it, or the same trade will head two bands.
- `RMR-CLASH` compares bounding boxes, not solids: two objects whose boxes overlap
  but whose geometry does not will still be listed. Treat the output as a review
  list to walk through, not as a clash engine result.
- `RMR-ROOF` takes the longer picked edge as the ridge direction, so the same two
  corners give a hip ridge of `long − short` and a gable ridge of the full length.
- `RMR-RAIL` walks each polyline segment separately and skips the first post of every
  segment after the first, so a shared corner vertex gets one post, not two.
- `RMR-BLKSWAP` rebuilds inserts with `entmake`; attributed inserts (DXF 66 = 1) are
  skipped and reported, so check the skip count before trusting a furniture swap.
- `RMR-ALIAS` registers aliases for the current session only. Merge the lines it
  writes into `acad.pgp` and run `REINIT` to make them permanent, and remember
  an alias is refused if AutoCAD already uses that name for something else —
  the command reports how many were skipped.
- `RMR-AUTO` runs against the current drawing and writes its log to `DWGPREFIX`.
  It sets `EXPERT` and `CMDECHO` around the purge passes and restores both
  afterwards, but it cannot undo the standard it builds, so work on a copy the
  first time.
- `RMR-BATCH` writes a plain `.scr` and opens each drawing in turn. It sets
  `FILEDIA 0` while the script runs and back to `1` at the end; check the
  `(load "RooMNRooF_Master.lsp")` line resolves on the machines that will run it.
- `RMR-CASHFLOW` spreads each stage evenly across its own weeks, so a stage
  with no duration contributes nothing and overlapping stages simply add
  together in the weeks they share.
- `RMR-SURVEY` expects the last three fields of every row to be the easting,
  northing and level, so a header row is skipped automatically, and rows where
  all three are zero are treated as blanks.
- `RMR-BEAM`, `RMR-DUCT`, `RMR-PIPE` and `RMR-TRAY` all offset a picked
  centre-line path, so a route that turns back on itself inside its own width
  will self-intersect at the corner. Keep the turn radius wider than the
  section.
- `RMR-REBAR` draws hooks at a fixed annotation-scale length, not at the real
  bend radius. Use it as a callout on a plan, not as a bending schedule.
- `RMR-SLABPANEL` and the two grid commands (`RMR-LIGHTING`, `RMR-SPRINKLER`)
  round the count with `fix`, so the last cell is clipped to the boundary and
  may be narrower than the module.
- `RMR-CLEARANCE` assigns a service to a zone from
  `*RMR-SERVICE-LAYER-ZONES*`, one zone per layer. A service that genuinely
  occupies two bands has to be modelled on two layers or checked by hand.
- `RMR-DUCT` and `RMR-PIPE` hatch through the `HATCH` command line, so the
  pattern must exist in the drawing; `ANSI31` ships with the standard.
- `RMR-SETOUT` divides the picked coordinates by the units-per-metre factor,
  so it reports metres in a metric drawing and the same numbers scaled in a
  millimetre drawing. Give it `0.001` for a millimetre drawing.
- The facility registers (`*RMR-ASSET-LOG*`, `*RMR-WO-LOG*`,
  `*RMR-CONDITION-LOG*`, `*RMR-COMPLIANCE-LOG*`) live in memory for the
  session. They are not saved to the drawing, so `RMR-FMREPORT` only reports
  what this session recorded; `RMR-ASSETREG` can rebuild the asset list from
  the tags in the drawing, but nothing rebuilds the work orders or the
  compliance dates.
- `RMR-COMPLIANCE` works in whole months. It compares the computed next-due
  month with the current month, so an item inspected on the 30th reports the
  same status as one inspected on the 1st.
- `RMR-LIFECYCLE` is straight-line: installation year plus life, at today's
  replacement cost. It does not model inflation, condition-adjusted remaining
  life or a phased programme — treat the five year figure as a budget
  indicator, not a cost plan.
- `RMR-SPACESTD` and `RMR-OCCUPANCY` compare net internal area with a density
  benchmark. They do not measure the room from the drawing, so the area has
  to be entered; use `RMR-AREA` or `RMR-MEASURE` first if you need it
  measured.
- `RMR-JUNCTION` reads both legs out of `*RMR-BUILDUP-SPECS*`, so a junction
  is only as good as the build-up rows behind it. A leg with no rows is
  reported and nothing is drawn.
- `RMR-UVALUE` gives a steady-state U value only: it adds `Rsi 0.13` and
  `Rse 0.04`, ignores repeating thermal bridges, air gaps are treated as a
  material with a lambda, and it does not check condensation risk.
- `RMR-DETAILLIB` and `RMR-DETSHEET` draw empty frames with a placeholder
  cross. They lay out the sheet; the geometry inside each frame is still
  yours, or comes from `RMR-JUNCTION`.
- `RMR-CHECKDETAIL` counts `CIRCLE` entities on `RMR-A-DETAIL` as detail
  markers and looks for the detail number as `TEXT` on the same layer. Tags
  drawn any other way will not be counted.
- `RMR-DETAILTAG` keeps its counter in memory for the session. Start a new
  drawing and the counter restarts at `D01`, so check the sheet before you
  trust the numbering on an old drawing.
- `RMR-SUNPATH` uses the standard solar position formulae (declination,
  hour angle, altitude and azimuth); noon altitude equals `90 - |latitude -
  declination|`, and southern latitudes put the noon sun in the north.
- `RMR-TILE` and `RMR-RCP` cap setout lines at 80 per direction so very large
  rooms cannot flood the drawing with geometry.
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
