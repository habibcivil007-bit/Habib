# RooMNRooF PRO 2D AutoCAD Standard

`RooMNRooF_Master.lsp` is a professional, metric AutoLISP generator for a modern consultant 2D CAD standard. It creates a consistent visual system rather than only a list of layers: brand colours, lineweight hierarchy, modern font fallback, annotation symbols, dimension and multileader styles, sheet graphics and production helpers.

## What was upgraded in PRO 2.0

- Modern visual palette: deep ink, terracotta, teal, gold, sand, blue, slate and soft presentation fills.
- Font stack with automatic fallback: Montserrat, Aptos, Arial, Calibri, Segoe UI, Romans, Simplex and TXT.
- Additional professional layers for glass, fills, room tags, keynotes, levels, revisions and issue stamps.
- `RMR-MLEADER` multileader style with branded gold lines and custom chevron arrowhead.
- Reusable symbol library:
  - `RMR-NORTH-ARROW`
  - `RMR-DETAIL-BUBBLE`
  - `RMR-KEYNOTE-BUBBLE`
  - `RMR-LEVEL-DATUM`
- Ready-made commands for realistic plan annotation: room tags, details, keynotes, levels, revisions, north arrow and multileaders.
- Lineweight display, viewport linetype scaling, visual retention and metric precision settings.
- A0-A4 sheet frame and branded title block generator.
- Colour / layer legend generator.
- Normal `RMR-MASTER` runs preserve existing office styles. `RMR-PRO-SETUP` explicitly refreshes only the RMR-owned text styles to the PRO font stack.

## Install and generate the master

1. Open a blank metric AutoCAD drawing.
2. Run `APPLOAD`.
3. Load `RooMNRooF_Master.lsp`.
4. Run:

   ```text
   RMR-PRO-SETUP
   ```

   `RMR-MASTER` is also available and performs the same standard build.

5. Place a sheet with `RMR-SHEET`.
6. Place the colour legend with `RMR-LEGEND`.
7. Use `RMR-SAVE-TEMPLATE` to save the configured drawing as `RooMNRooF_PRO_Master.dwt`.

## PRO commands

| Command | Result |
| --- | --- |
| `RMR-PRO-SETUP` | Builds the complete PRO standard, symbol library and multileader style. |
| `RMR-MASTER` | Rebuilds the standard in the active drawing. |
| `RMR-SETLAYER` | Lists a discipline and sets the current layer. |
| `RMR-SHEET` | Draws an A0-A4 sheet frame and modern RooMNRooF title block. |
| `RMR-LEGEND` | Draws a true-colour layer and lineweight legend. |
| `RMR-NORTH` | Inserts a modern north arrow symbol. |
| `RMR-ROOMTAG` | Draws a room number, room name and area tag. |
| `RMR-KEYNOTE` | Draws a numbered keynote bubble. |
| `RMR-DETAIL` | Draws a detail bubble with detail number and sheet reference. |
| `RMR-LEVEL` | Draws a level / datum marker. |
| `RMR-REVISION` | Draws a revision triangle with issue text. |
| `RMR-MLEADER` | Starts a branded multileader using `RMR-MLEADER`. |
| `RMR-SAVE-TEMPLATE` | Saves the active configured drawing as a `.DWT`. |
| `RMR-PALETTE` | Prints the palette and command guide. |

## Layer system

- `RMR-M-...` - Main Theme: walls, doors, windows, finishes, glass, fills and grids.
- `RMR-F-...` - Furniture: furniture, casework, fixtures, equipment and overhead lines.
- `RMR-S-...` - Structural: columns, beams, slabs, foundations, rebar and grids.
- `RMR-P-...` - Plumbing: supply, drain, vent, fixtures, equipment and annotations.
- `RMR-A-...` - Annotation: text, dimensions, leaders, arrows, room tags, keynotes, levels, revisions and frames.
- `RMR-PRES-...` - Presentation: title block, keynotes, north arrow and issue graphics.
- `RMR-00-...` - Control: no-plot and external reference layers.

All named layers use true RGB colour values and millimetre lineweights. The file retains ACI 7 as a safe fallback for older display / plotting workflows.

## Add a personal group palette

At the top of the LISP, append an item to `*RMR-LAYER-SPECS*`:

```lisp
("RMR-X-ITEM" "MY GROUP" (R G B) "Continuous" 18 "My layer description")
```

Then run `RMR-PRO-SETUP` again. Use RGB values from `0` to `255` and standard linetypes such as `Continuous`, `CENTER`, `HIDDEN`, `DASHED`, `DOT` or `PHANTOM`.

## Font customization

The preferred PRO styles are configured near the top of the LISP:

- `RMR-TITLE` and `RMR-HEAD` - Montserrat SemiBold
- `RMR-SUBHEAD` - Montserrat Regular
- `RMR-BODY` and `RMR-NOTE` - Aptos
- `RMR-NUMBER` - Montserrat SemiBold
- `RMR-LABEL` - Aptos
- `RMR-MARK` - Roboto Mono

The generator falls back automatically when a font is not installed. To force an office font, replace the font file names in `*RMR-TEXT-STYLES*`.

## Production notes

- The generator is metric: `INSUNITS=4`, decimal dimensions, millimetre lineweights and A-series sheet sizes.
- `RMR-SHEET` is a drafting aid. For production, place the frame/title block in paper space and use viewports at the required scale.
- AutoLISP cannot generate a binary `.DWT` in this repository. Run `RMR-SAVE-TEMPLATE` inside AutoCAD after setup.
- The source file is intentionally idempotent. It does not overwrite existing named text styles, blocks or dimension styles; this protects office customizations.
