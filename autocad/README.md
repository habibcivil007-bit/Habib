# RooMNRooF Master 2D AutoCAD Standard

`RooMNRooF_Master.lsp` is a self-contained AutoLISP generator for a metric 2D consultant drawing standard. It is designed around the requested discipline palette:

1. Main Theme
2. Furniture
3. Structural
4. Plumbing
5. Annotation: leaders, arrows, text and dimensions
6. Presentation: title, keynotes and north arrow

It uses true RGB layer colours with an ACI fallback, so the palette stays branded while remaining usable in normal AutoCAD workflows.

## Install and generate the master drawing

1. Open a blank metric AutoCAD drawing.
2. Run `APPLOAD`.
3. Select `RooMNRooF_Master.lsp`.
4. At the command line, run:

   ```text
   RMR-MASTER
   ```

5. Optionally run `RMR-SHEET` to draw an A0, A1, A2, A3 or A4 frame and RooMNRooF title block.
6. Optionally run `RMR-LEGEND` to place the colour and layer legend.
7. Run `RMR-SAVE-TEMPLATE` and save as `RooMNRooF_Master.dwt`.

The LISP does not overwrite existing named styles. This protects an office's personal edits if the generator is run again.

## Commands

| Command | Result |
| --- | --- |
| `RMR-MASTER` | Creates or refreshes layers, linetypes, text styles, dimension styles, custom leader arrow and metric standards. |
| `RMR-SETLAYER` | Lists a discipline and sets the current layer from the selected group. |
| `RMR-LEGEND` | Draws a complete brand colour legend at a picked point. |
| `RMR-SHEET` | Draws an A0-A4 sheet frame and a branded title block. |
| `RMR-SAVE-TEMPLATE` | Saves the active drawing as a `.DWT`. |
| `RMR-PALETTE` | Prints the palette groups and usage guide in the command line. |

## Layer naming

- `RMR-M-...` - Main Theme
- `RMR-F-...` - Furniture
- `RMR-S-...` - Structural
- `RMR-P-...` - Plumbing
- `RMR-A-...` - Annotation, leaders, arrows, dimensions and frames
- `RMR-PRES-...` - Presentation and title graphics
- `RMR-00-...` - Control and reference layers

## Add another personal palette

At the top of the LISP, add a new item to `*RMR-LAYER-SPECS*`:

```lisp
("RMR-X-ITEM" "MY GROUP" (R G B) "Continuous" 18 "My layer description")
```

Then run `RMR-MASTER` again. Use RGB values from `0` to `255` and use one of the standard linetypes (`Continuous`, `CENTER`, `HIDDEN`, `DASHED`, `DOT` or `PHANTOM`). Existing named layers remain intact except for the standard's configured colour, linetype, lineweight and description.

## Notes

- The generator is intentionally metric: `INSUNITS=4`, decimal dimensions, millimetre lineweights and A-series sheet sizes.
- `RMR-SHEET` is a drafting aid. For production, place the frame/title block in a paper-space layout and use viewports as required.
- A `.DWT` file is not generated until `RMR-SAVE-TEMPLATE` is run inside AutoCAD. AutoLISP cannot ship a binary DWG/DWT file from this source repository.
- Fonts are resolved in this order: Arial, Romans, Simplex, then TXT. Replace the font names in `*RMR-TEXT-STYLES*` if a project standard requires another installed font.
