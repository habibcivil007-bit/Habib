# User Guide

**RooMNRooF CAD PRO ULTIMATE is a drafting tool.** It does not design structures or check code
compliance (BNBC 2020 / ACI 318-19 / ASCE 7 are referenced only as project metadata). All sizes,
covers, reinforcement and loads are project inputs to be verified by the responsible engineer.
BBS/BOQ quantities are CAD-derived estimates.

## Getting started
1. Install (MSI) or `NETLOAD` the DLL. Type `RNR` for the command menu or `RNRPANEL` for the palette.
2. New drawing → `RNRSTANDARD` (layers, styles, linetypes, hatches) → `RNRUNITS`.
3. `RNRPROJECT` to fill project metadata used by title blocks.

## Command reference (C# plugin)
| Group | Commands |
|---|---|
| Setup / standards | RNR, RNRPANEL, RNRSTANDARD, RNRLAYERS, RNRLA, RNRSTYLES, RNRCOLOR, RNRUNITS, RNRPROJECT, RNRTEMPLATE, RNRLOG |
| Discipline layer sets | RNRARCH, RNRSTRUCT, RNRCIVIL, RNRMEP, RNRANNO, RNRRCC |
| Grid & structure | RNRGRID, RNRMEMBER, RNRCOLUMN, RNRBEAM, RNRSLAB, RNRFOOTING, RNRPILE, RNRPILECAP, RNRRAFT, RNRSWALL, RNRSTAIR, RNRRAMP, RNRROOF, RNRTANK, RNRJOINT |
| Rebar | RNRREBAR, RNRSTIRRUP, RNRREBARNOTE, RNRBBS |
| Architecture | RNRWALL, RNRDOOR, RNRWINDOW, RNRROOM, RNRFLOOR, RNRCEILING, RNRFURN, RNRBLOCKS |
| Hatch / materials | RNRHATCH, RNRHATCHNAME, RNRMATLIB, RNRMATAPPLY, RNRMATPREVIEW, RNRMATLEGEND |
| Annotation | RNRTAG, RNRLEADER, RNRLEVEL, RNRNORTH, RNRSECTIONMARK, RNRELEVMARK, RNRDETAILMARK, RNRSECTIONDETAIL |
| Sheets / plot | RNRTITLE, RNRLAYOUT, RNRPLOTCOLOR, RNRPLOTBW, RNRPLOTGRAY |
| Data | RNRSCHEDULE, RNRBOQ, RNRETABS, RNRIMPORT, RNRDXFOUT |
| QA / cleanup | RNRQA, RNRAUDIT, RNRPREVIEW, RNRCLEAN (always previews and asks) |

## AutoLISP (works without the DLL)
`APPLOAD` → `AutoLISP\RNR_Load.lsp`, then `RNRL-HELP`. Commands: RNRL-LAYERS, RNRL-ARCH, RNRL-STRUCT,
RNRL-CIVIL, RNRL-ANNO, RNRL-RCC, RNRL-LA, RNRL-THAW, RNRL-COLORS, RNRL-COLORAPPLY, RNRL-BYLAYER, RNRL-UNITS,
RNRL-STYLES, RNRL-GRID, RNRL-WALL, RNRL-DOOR, RNRL-WINDOW, RNRL-ROOM, RNRL-COLUMN, RNRL-BEAM, RNRL-FOOTING,
RNRL-REBAR, RNRL-BARWT, RNRL-HATCH, RNRL-INSERT, RNRL-BLOCKLIST, RNRL-TAG, RNRL-LEVEL, RNRL-NORTH, RNRL-QA,
RNRPLOT-BW, RNRPLOT-COLOR, RNRPLOT-GRAY.

No default AutoCAD shortcuts/aliases are overridden.

## Plotting
Colour TrueColor layers print black with `RNRPLOTBW` (monochrome.ctb) while keeping lineweights;
`RNRPLOTGRAY` uses grayscale.ctb. Output PDF next to the drawing.
