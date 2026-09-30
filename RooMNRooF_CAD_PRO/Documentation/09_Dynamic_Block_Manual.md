# Dynamic Block Manual

`RNRBLOCKS` creates the RooMNRooF block definitions (see `Standards/RNR_Blocks.json`, 29 blocks:
doors, windows, fixtures, furniture, north arrow, level/section/detail markers, grid bubble, column/footing symbols)
with **attribute definitions** and geometry on the correct layers.

## Honest limitation
The public AutoCAD .NET API cannot author dynamic-block *parameters and actions* (stretch, flip,
visibility, lookup). The plugin therefore creates **static parametric blocks** (one definition per size
via the command options) and attributes. To convert a block to a dynamic block:

1. `BEDIT` → select e.g. `RNR_DOOR_SINGLE`.
2. Add a **Linear parameter** across the leaf width; add a **Stretch action** on the leaf/arc end.
3. Add a **Flip parameter** (hinge side) + Flip action on all geometry.
4. Optional **Lookup parameter** with widths 750/900/1000/1200.
5. `BSAVE`, then `WBLOCK` into `Blocks\` so it is shipped in the bundle.

Recommended parameters per family:
| Family | Parameters |
|---|---|
| Doors | Width (Linear+Stretch), Hinge (Flip), Swing (Flip) |
| Windows | Width (Linear+Stretch), Wall thickness (Linear+Stretch) |
| Level marker | Visibility: plan / section |
| Grid bubble | Flip for side, Attribute `GRID` |
| Column symbol | Lookup of standard sizes |

Blocks remain ByLayer/ByBlock so layer standards and BW plotting apply.
