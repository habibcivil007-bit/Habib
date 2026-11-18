;;; -----------------------------------------------------------------------------
;;; RooMNRooF Master 2D CAD Standard
;;; Version 7.0 COORDINATION SUITE | Metric | AutoCAD / AutoCAD LT with AutoLISP
;;;
;;; Purpose
;;;   Builds a complete, colour-led 2D consultant standard in the active drawing.
;;;   It creates named layers, true-colour brand palette, linetypes, text styles,
;;;   dimension styles, a custom leader arrow, a sheet frame and a legend.
;;;   Version 3.0 adds the production suite: annotation scales, structural grids,
;;;   room area schedules, material hatches, issue stamps, revision tables, notes
;;;   blocks, graphic scale bars, key plans, standards checks, block takeoffs,
;;;   palette CSV import/export, layer group control, page setup and publish lists.
;;;   Version 4.0 adds the studio suite: layouts with scaled viewports, section,
;;;   elevation, match, break and revision-cloud markers, a dimension launcher,
;;;   a parametric RMR-SYM-* symbol library, door schedules, text find/replace,
;;;   live fields, project data files and timestamped drawing backups.
;;;   Version 5.0 adds the delivery suite: parametric walls and stairs, linear
;;;   takeoff, bill of materials, room finishes and drawing registers, an xref
;;;   register, transmittal records, layer states, ByLayer standardisation,
;;;   drawing clean-up and drawing properties driven by the project data.
;;;   Version 6.0 adds the site and services suite: solar study diagrams, fall
;;;   and drainage runs, parking and tiling setout, reflected ceiling plans,
;;;   level and keynote libraries, a printable standard report and a stray
;;;   layer audit.
;;;   Version 7.0 adds the coordination suite: bounding-box clash checks between
;;;   layer groups, parametric roofs and balustrades, glazing and zone schedules,
;;;   block swapping, tag renumbering, text alignment, entity information and
;;;   true-north orientation.
;;;   Version 8.0 adds the documentation suite: a specification clause library
;;;   and index, an abbreviations legend, a data-driven revision history, a
;;;   pre-issue checklist, a room data schedule built from picked boundaries,
;;;   a folder document list, a sheet index, a project cover sheet and one
;;;   command that lays out a complete documentation sheet.
;;;   Version 9.0 adds the presentation suite: axonometric massing extruded
;;;   from a plan outline, one point interior perspectives, layered
;;;   construction build-ups with leaders, a material swatch board, a colour
;;;   reference board, an image board, an area distribution chart, a programme
;;;   bar chart, the brand masthead and a complete client presentation sheet.
;;;   Version 10.0 adds the quantity and automation suite: measured survey
;;;   import, interactive measurement, a rate-driven quantity takeoff, a rate
;;;   library, an elemental cost plan, a cost per m2 dashboard, a cash flow
;;;   curve, CSV import, quantity validation and the surveyor report, plus
;;;   command aliases, a menu / tool palette file, a scripted automation
;;;   runner and a batch script writer for whole folders of drawings.
;;;   Version 11.0 adds the structural and MEP coordination suite: parametric
;;;   columns, beams, pad and strip foundations, reinforcement, slab panels,
;;;   setting-out coordinates and a structural element schedule, plus ductwork,
;;;   pipework, cable containment, lighting, sprinklers, a services schedule
;;;   and a vertical clearance check against the service zone bands. It also
;;;   adds a SERVICES layer group so every discipline has its own layer.
;;;   Version 12.0 adds the construction detailing suite: a detail library,
;;;   a parametric junction builder driven by the construction build-up
;;;   tables, detail tags with a running counter, locator plans, continuous
;;;   dimension chains, a materials key, a detail scale bar, a complete A1
;;;   detail sheet, a specification link block, the detail index, a U value
;;;   calculator, fire compartment lines, acoustic ratings and a detail
;;;   compliance check, plus RMR-A-FIRE and RMR-A-ACOUSTIC annotation layers.
;;;
;;; Main command
;;;   RMR-MASTER       Build / refresh the standard in the current drawing
;;;
;;; Utility commands
;;;   RMR-SETLAYER     Choose a layer by discipline
;;;   RMR-LEGEND       Draw the RooMNRooF colour legend at a picked point
;;;   RMR-SHEET        Draw an A0-A4 sheet frame and title block
;;;   RMR-SAVE-TEMPLATE Save the current drawing as a .DWT file
;;;   RMR-PALETTE      Print the palette and command guide
;;;   RMR-NORTH        Place a modern north-arrow symbol
;;;   RMR-ROOMTAG      Place a room name / number / area tag
;;;   RMR-KEYNOTE      Place a numbered keynote bubble
;;;   RMR-DETAIL       Place a detail callout marker
;;;   RMR-LEVEL        Place a level datum marker
;;;   RMR-REVISION     Place a revision triangle and label
;;;   RMR-MLEADER      Start a branded multileader
;;;
;;; Production suite commands
;;;   RMR-SCALE        Set the drawing scale and annotation size factor
;;;   RMR-GRID         Draw a labelled structural grid with bubbles
;;;   RMR-AREA         Measure room boundaries and place an area schedule
;;;   RMR-HATCH        Apply a branded material hatch from the library
;;;   RMR-HATCHLIB     Print the material hatch library
;;;   RMR-STAMP        Place an issue / status stamp (IFR, IFC, AS-BUILT...)
;;;   RMR-REVTABLE     Place a revision history table
;;;   RMR-NOTES        Place the numbered general notes block
;;;   RMR-SCALEBAR     Place a graphic scale bar in metres
;;;   RMR-KEYPLAN      Place a key plan box with north arrow
;;;   RMR-LAYGROUP     Freeze / thaw / lock / off a whole discipline group
;;;   RMR-CHECK        Audit the drawing against the RooMNRooF standard
;;;   RMR-COUNT        Block takeoff with CSV export
;;;   RMR-EXPORT-PALETTE  Write the layer palette to a CSV file
;;;   RMR-IMPORT-PALETTE  Read a CSV palette and rebuild the standard
;;;   RMR-PAGESETUP    Configure the active layout for PDF plotting
;;;   RMR-PUBLISH      Write a DSD publish list (optionally start -PUBLISH)
;;;
;;; Studio suite commands
;;;   RMR-LAYOUTS      New layout: paper size, title block, scaled viewport
;;;   RMR-VPORT        Scaled and locked viewport in the active layout
;;;   RMR-SECTION      Section cut line with arrows and sheet bubbles
;;;   RMR-ELEVATION    Elevation marker with direction arrow
;;;   RMR-MATCHLINE    Match line to the adjoining sheet
;;;   RMR-BREAKLINE    Break / cut line on RMR-A-MATCH
;;;   RMR-REVCLOUD     Revision cloud drawn as a bulged polyline
;;;   RMR-DIM          Dimension launcher: style + linear/aligned/radial/angular
;;;   RMR-SYMBOLS      Build the parametric RMR-SYM-* symbol library
;;;   RMR-DOORSCHED    Door schedule from inserted RMR-SYM-DOOR* blocks
;;;   RMR-FINDTEXT     Find / replace across TEXT, MTEXT and ATTRIB
;;;   RMR-FIELDS       Insert live fields (date, drawing name, layout...)
;;;   RMR-PROJECT      Show / set / save / load project data (*RMR-PROJECT*)
;;;   RMR-BACKUP       Timestamped backup copy of the drawing
;;;
;;; Delivery suite commands
;;;   RMR-WALL         Parametric double-line wall from a picked path
;;;   RMR-STAIR        Parametric straight stair plan with walking line
;;;   RMR-LENGTH       Linear takeoff: total length with label and CSV
;;;   RMR-BOM          Bill of materials table and CSV from block inserts
;;;   RMR-FINISHES     Room finishes schedule from *RMR-FINISH-SPECS*
;;;   RMR-SHEETREG     Drawing register from *RMR-SHEET-LIST*
;;;   RMR-XREFLIST     Xref register table with resolved paths
;;;   RMR-TRANSMITTAL  Issue / transmittal record for the drawing set
;;;   RMR-LAYERSTATE   Save / restore / list / delete layer states (.rms)
;;;   RMR-STANDARDIZE  Force colour, linetype and lineweight to BYLAYER
;;;   RMR-CLEAN        Repeated purge plus audit, then optional standardise
;;;   RMR-DWGPROPS     Write drawing properties from *RMR-PROJECT*
;;;
;;; Site and services commands
;;;   RMR-SUNPATH     Solar study diagram: latitude, declination curves, hours
;;;   RMR-FALL        Fall arrow with gradient label and calculated drop
;;;   RMR-DRAIN       Drainage run with manholes, pipes and invert levels
;;;   RMR-PARK        Parametric parking bay layout (90 / 60 / 45 degrees)
;;;   RMR-TILE        Tiling setout grid with tile count and waste allowance
;;;   RMR-RCP         Reflected ceiling plan: grid and light fittings
;;;   RMR-LEVELSCHED  Level schedule from *RMR-LEVEL-SPECS*
;;;   RMR-KEYLIB      Keynote legend from *RMR-KEYNOTES*
;;;   RMR-REPORT      Printable report of the whole standard
;;;   RMR-STRAY       Audit objects sitting on non-standard layers
;;;
;;; Coordination suite commands
;;;   RMR-CLASH       Bounding-box clash check between two layer groups
;;;   RMR-ROOF        Parametric roof plan: gable, hip or shed with eaves
;;;   RMR-RAIL        Balustrade along a path with posts at a spacing
;;;   RMR-WINDOWSCHED Glazing schedule from RMR-SYM-WINDOW* blocks
;;;   RMR-ZONE        Zone plan: areas hatched by band with a legend
;;;   RMR-BLKSWAP     Replace every insert of one block with another
;;;   RMR-RENUMBER    Renumber picked tags in selection order
;;;   RMR-TEXTALIGN   Align selected text onto a picked baseline
;;;   RMR-INFO        Full information report for one object
;;;   RMR-ORIENT      Rotate the model to true north
;;;
;;; Documentation suite commands
;;;   RMR-SPECNOTE    Place one specification clause as a titled note
;;;   RMR-SPECINDEX   Specification index grouped by trade
;;;   RMR-ABBREV      Abbreviations legend in two columns
;;;   RMR-REVLIB      Revision history from *RMR-REVISIONS*
;;;   RMR-CHECKLIST   Pre-issue checklist with tick boxes
;;;   RMR-ROOMSCHED   Room data schedule from picked boundaries
;;;   RMR-DOCLIST     Document list for the drawing folder (with CSV)
;;;   RMR-SHEETINDEX  Sheet index grid with the current sheet marked
;;;   RMR-COVER       Project cover sheet with the drawing set listing
;;;   RMR-DOCSHEET    Complete documentation sheet in one command
;;;
;;; Presentation suite commands
;;;   RMR-AXO         Axonometric massing extruded from a plan outline
;;;   RMR-ROOMVIEW    One point interior perspective of a room
;;;   RMR-BUILDUP     Layered construction build-up with leaders
;;;   RMR-SWATCH      Material swatch board from the hatch library
;;;   RMR-COLOURBOARD Colour reference board: brand palette and every layer
;;;   RMR-MOODBOARD   Image / mood board with captioned frames
;;;   RMR-AREACHART   Area distribution bar chart from room boundaries
;;;   RMR-PROGRAMME   Programme bar chart from *RMR-PROGRAMME-SPECS*
;;;   RMR-BRANDING    RooMNRooF brand masthead with project data
;;;   RMR-PRESENTSHEET Complete client presentation sheet in one command
;;;
;;; Quantity suite commands
;;;   RMR-SURVEY      Import a measured survey CSV as numbered points
;;;   RMR-MEASURE     Interactive length and area measurement with totals
;;;   RMR-QUANTITY    Rate-driven quantity takeoff table
;;;   RMR-RATES       Rate library table from *RMR-RATE-SPECS*
;;;   RMR-COSTPLAN    Elemental cost plan bar chart
;;;   RMR-PERQM       Cost per m2 dashboard against a benchmark
;;;   RMR-CASHFLOW    Cash flow curve spread over the programme
;;;   RMR-CSVIMPORT   Bring any CSV into the drawing as a table
;;;   RMR-VALIDATE    Validate rates and blocks before pricing
;;;   RMR-QSREPORT    Full quantity surveyor report to a text file
;;;
;;; Automation commands
;;;   RMR-ALIAS       Register short aliases and write RooMNRooF.pgp
;;;   RMR-TOOLPALETTE Write RooMNRooF.mnu: pull-down menu and toolbar
;;;   RMR-AUTO        Run the scripted sequence in *RMR-AUTO-SEQUENCE*
;;;   RMR-BATCH       Write a script that processes a whole folder
;;;
;;; Structural commands
;;;   RMR-COLUMN      Place columns from *RMR-COLUMN-SPECS*
;;;   RMR-BEAM        Place beams from *RMR-BEAM-SPECS*
;;;   RMR-FOUNDATION  Pad and strip foundations with depth labels
;;;   RMR-REBAR       Reinforcement bars with hooks, marks and spacing
;;;   RMR-SLABPANEL   Slab panel layout with marks and a panel schedule
;;;   RMR-SETOUT      Setting-out coordinates, table and CSV
;;;   RMR-STRUCTSCHED Structural element schedule from the drawing
;;;
;;; Services / MEP commands
;;;   RMR-DUCT        Ductwork runs from *RMR-DUCT-SPECS*
;;;   RMR-PIPE        Pipework runs with a fall and a flow arrow
;;;   RMR-TRAY        Cable tray with rungs at a chosen spacing
;;;   RMR-LIGHTING    Luminaire grid with circuit tags and a schedule
;;;   RMR-SPRINKLER   Sprinkler head grid with coverage circles
;;;   RMR-MEPSCHED    Services schedule from the drawing
;;;   RMR-CLEARANCE   Vertical service zone diagram and shared-zone check
;;;
;;; Construction detailing commands
;;;   RMR-DETAILLIB   Grid of captioned detail frames from *RMR-DETAIL-SPECS*
;;;   RMR-JUNCTION    Parametric junction built from two build-up legs
;;;   RMR-DETAILTAG   Detail bubble and leader with a running number
;;;   RMR-DETLOC      Locator plan with the detail position marked
;;;   RMR-DIMCHAIN    Continuous dimension chain with witness ticks
;;;   RMR-MATKEY      Materials key for a build-up
;;;   RMR-DETSCALE    Detail scale plus a metric scale bar
;;;   RMR-DETSHEET    Complete A1 detail sheet in one command
;;;   RMR-SPECLINK    Link a detail to specification clauses
;;;   RMR-DETINDEX    Detail index schedule
;;;   RMR-UVALUE      U value and thermal resistance calculator
;;;   RMR-FIRESTOP    Fire compartment line with its rating
;;;   RMR-ACOUSTIC    Acoustic rating markers and table
;;;   RMR-CHECKDETAIL Detail compliance check and report
;;;
;;; IMPORTANT
;;;   1. This is an AutoLISP source file. APPLOAD it in AutoCAD.
;;;   2. Run RMR-MASTER in a blank drawing before drawing production work.
;;;   3. All colours are true RGB colours. ACI 7 is retained as a fallback.
;;;   4. Edit the data tables below to add a personal/group palette. Normal
;;;      RMR-MASTER runs preserve existing named styles; RMR-PRO-SETUP refreshes
;;;      only the RMR-owned text styles to the modern PRO font stack.
;;;   5. Run RMR-SAVE-TEMPLATE after RMR-MASTER to save a reusable .DWT.
;;;   6. Run RMR-PRO-SETUP once for the extra symbol blocks and MLeader style.
;;;   7. The PRO layer, font and style tables are intentionally editable.
;;;   8. Run RMR-SCALE before annotating so tags, grids, notes and bars are the
;;;      right model-space size. 1.0 factors are used for layout / paper space.
;;;   9. RMR-CHECK reports non-standard layers, text styles and dimension styles.
;;;  10. RMR-PAGESETUP and RMR-PUBLISH never plot silently - both print what was
;;;      applied and leave the final decision to you.
;;;
;;; Branding
;;;   Brand: RooMNRooF
;;;   Role:  Consultant 2D CAD standard
;;;   Palette: Ink / Terracotta / Teal / Gold / Sand / Blue / Slate
;;;   Suite:   Standard + PRO symbols + Production suite
;;; -----------------------------------------------------------------------------

(vl-load-com)

;;; -----------------------------------------------------------------------------
;;; PERSONAL PALETTE - edit this section to add or change colours.
;;; RGB values are written as (Red Green Blue), from 0 to 255.
;;; Every layer spec is:
;;;   (LayerName Group RGB Linetype Lineweight Description)
;;; Lineweight is in hundredths of a millimetre: 25 = 0.25 mm.
;;; -----------------------------------------------------------------------------

(setq *RMR-LAYER-SPECS*
 '(
   ;; Control / coordination
   ("RMR-00-NPLT"   "CONTROL"    (120 120 120) "Continuous"  -3 "No-plot construction and viewport controls")
   ("RMR-00-REF"    "CONTROL"    (145 155 160) "DASHED"      9 "External references and underlays")

   ;; 1. Main Theme
   ("RMR-M-WALL"    "MAIN THEME" (198  93  72) "Continuous" 35 "Primary walls and major outlines")
   ("RMR-M-DOOR"    "MAIN THEME" (214 163  76) "Continuous" 18 "Doors and door swings")
   ("RMR-M-WINDOW"  "MAIN THEME" ( 57 137 130) "Continuous" 18 "Windows, glazing and frames")
   ("RMR-M-FINISH"  "MAIN THEME" (238 225 201) "Continuous" 13 "Finishes, skirting and trims")
   ("RMR-M-CEILING" "MAIN THEME" (166 177 181) "DASHED"      13 "Reflected ceiling information")
   ("RMR-M-AREA"    "MAIN THEME" (239 191  80) "Continuous"  9 "Room areas and zoning")
   ("RMR-M-HATCH"   "MAIN THEME" (192 160 129) "Continuous"  9 "Material hatches")
   ("RMR-M-FILL"    "MAIN THEME" (244 238 226) "Continuous"  9 "Soft presentation fills")
   ("RMR-M-GLASS"   "MAIN THEME" (116 190 198) "Continuous" 13 "Glass and transparent elements")
   ("RMR-M-GRID"    "MAIN THEME" ( 88 112 123) "CENTER"      9 "Architectural grids and axes")

   ;; 2. Furniture
   ("RMR-F-FURN"    "FURNITURE"  ( 31  42  51) "Continuous" 18 "Loose and fixed furniture")
   ("RMR-F-CASE"    "FURNITURE"  ( 57 137 130) "Continuous" 18 "Casework and cabinetry")
   ("RMR-F-FIXTURE" "FURNITURE"  (214 163  76) "Continuous" 13 "Sanitary and loose fixtures")
   ("RMR-F-EQUIP"   "FURNITURE"  ( 86 104 116) "Continuous" 18 "Equipment and appliances")
   ("RMR-F-HIDDEN"  "FURNITURE"  (100 110 118) "HIDDEN"      9 "Furniture hidden / overhead")

   ;; 3. Structural
   ("RMR-S-COLUMN"  "STRUCTURAL" (184  72  72) "Continuous" 50 "Columns and vertical structure")
   ("RMR-S-BEAM"    "STRUCTURAL" (210 119  58) "Continuous" 35 "Beams and primary framing")
   ("RMR-S-SLAB"    "STRUCTURAL" (125 134 168) "Continuous" 25 "Slabs and structural decks")
   ("RMR-S-FOUND"   "STRUCTURAL" ( 78  78  90) "Continuous" 35 "Foundations and footings")
   ("RMR-S-REBAR"   "STRUCTURAL" (130  92 160) "Continuous" 18 "Reinforcement and embeds")
   ("RMR-S-HIDDEN"  "STRUCTURAL" (115 125 140) "HIDDEN"       9 "Structural hidden lines")
   ("RMR-S-GRID"    "STRUCTURAL" ( 90 105 155) "CENTER"       9 "Structural grids")

   ;; 4. Plumbing
   ("RMR-P-SUPPLY"  "PLUMBING"   ( 47 116 181) "Continuous" 25 "Cold / hot water supply")
   ("RMR-P-DRAIN"   "PLUMBING"   ( 31  82 129) "Continuous" 25 "Soil, waste and drainage")
   ("RMR-P-VENT"    "PLUMBING"   ( 57 137 130) "DASHED"      18 "Vent and relief lines")
   ("RMR-P-FIXTURE" "PLUMBING"   ( 39 154 170) "Continuous" 18 "Plumbing fixtures")
   ("RMR-P-EQUIP"   "PLUMBING"   (210 119  58) "Continuous" 18 "Pumps, tanks and equipment")
   ("RMR-P-ANNO"    "PLUMBING"   ( 47 116 181) "Continuous" 13 "Plumbing annotations")

   ;; 5. Services / MEP
   ("RMR-E-DUCT"    "SERVICES"   ( 57 137 130) "Continuous" 25 "Supply and extract ductwork")
   ("RMR-E-GRILLE"  "SERVICES"   ( 90 168 160) "Continuous" 18 "Grilles, diffusers and air terminals")
   ("RMR-E-PIPE"    "SERVICES"   ( 47 116 181) "Continuous" 25 "Mechanical pipework, flow and return")
   ("RMR-E-EQUIP"   "SERVICES"   ( 86 104 116) "Continuous" 18 "Plant, tanks and mechanical equipment")
   ("RMR-E-POWER"   "SERVICES"   (214 163  76) "Continuous" 18 "Small power, outlets and switchgear")
   ("RMR-E-LIGHT"   "SERVICES"   (232 196 110) "Continuous" 13 "Luminaires, switching and circuits")
   ("RMR-E-TRAY"    "SERVICES"   (124 106 168) "Continuous" 18 "Cable tray, conduit and containment")
   ("RMR-E-DATA"    "SERVICES"   (150 132 190) "DASHED"      13 "Data, comms and security cabling")
   ("RMR-E-SPRINK"  "SERVICES"   (198  93  72) "Continuous" 18 "Sprinkler heads and fire detection")

   ;; 6. Leaders / arrows / annotation
   ("RMR-A-TEXT"    "ANNOTATION" ( 31  42  51) "Continuous" 13 "General notes and text")
   ("RMR-A-DIMS"    "ANNOTATION" ( 31  42  51) "Continuous" 13 "Dimensions")
   ("RMR-A-LEADER"  "ANNOTATION" (214 163  76) "Continuous" 18 "Leaders and callouts")
   ("RMR-A-ARROW"   "ANNOTATION" (198  93  72) "Continuous" 18 "Section, detail and north arrows")
   ("RMR-A-GRID"    "ANNOTATION" ( 88 112 123) "CENTER"       9 "Annotation grids and bubbles")
   ("RMR-A-MATCH"   "ANNOTATION" ( 86 104 116) "PHANTOM"      9 "Match, break and cut lines")
   ("RMR-A-FRAME"   "ANNOTATION" ( 31  42  51) "Continuous" 35 "Sheet frame and title block")
   ("RMR-A-DETAIL"  "ANNOTATION" (130  92 160) "Continuous" 18 "Detail markers")
   ("RMR-A-ROOMTAG" "ANNOTATION" ( 31  42  51) "Continuous" 18 "Room number, name and area tags")
   ("RMR-A-KEYNOTE" "ANNOTATION" (214 163  76) "Continuous" 18 "Numbered keynote bubbles")
   ("RMR-A-LEVEL"   "ANNOTATION" ( 57 137 130) "Continuous" 18 "Level and datum markers")
   ("RMR-A-REVISION" "ANNOTATION" (198  93  72) "Continuous" 18 "Revision triangles and clouds")
   ("RMR-A-FIRE"    "ANNOTATION" (198  93  72) "Continuous" 25 "Fire compartment lines and ratings")
   ("RMR-A-ACOUSTIC" "ANNOTATION" ( 47 116 181) "DASHED"      18 "Acoustic ratings and partitions")

   ;; 7. Presentation / plotting
   ("RMR-PRES-TITLE" "PRESENTATION" (198  93  72) "Continuous" 25 "Title block and brand")
   ("RMR-PRES-KEY"   "PRESENTATION" (214 163  76) "Continuous" 18 "Keynotes and numbered tags")
   ("RMR-PRES-NORTH" "PRESENTATION" ( 57 137 130) "Continuous" 18 "North arrows and orientation")
   ("RMR-PRES-STAMP" "PRESENTATION" ( 57 137 130) "Continuous" 18 "Issue, status and approval stamps")
   ("RMR-PRES-VPORT" "PRESENTATION" ( 47 116 181) "Continuous"  9 "Viewport frames and labels")
  )
)

;;; Text styles: (StyleName FontFile WidthFactor ObliqueAngle Description)
;;; Preferred fonts are modern and clean. RMR:FindFont falls back safely when
;;; a preferred font is not installed on the workstation.
(setq *RMR-TEXT-STYLES*
 '(
   ("RMR-TITLE"   "Montserrat-SemiBold.ttf" 0.92 0.0 "Modern display title")
   ("RMR-HEAD"    "Montserrat-SemiBold.ttf" 0.95 0.0 "Modern drawing headings")
   ("RMR-SUBHEAD" "Montserrat-Regular.ttf"   0.96 0.0 "Subheads and secondary titles")
   ("RMR-BODY"    "Aptos.ttf"                1.00 0.0 "General notes and dimensions")
   ("RMR-NOTE"    "Aptos.ttf"                0.95 0.0 "Small notes and technical references")
   ("RMR-NUMBER"  "Montserrat-SemiBold.ttf" 0.90 0.0 "Sheet, detail and revision numbers")
   ("RMR-LABEL"   "Aptos.ttf"                0.98 0.0 "Room tags and component labels")
   ("RMR-MARK"    "RobotoMono-Regular.ttf"   0.90 0.0 "Compact technical marker style")
  )
)

;;; Dimension styles: (Name TextHeight ArrowSize Description)
(setq *RMR-DIMSTYLE-SPECS*
 '(
   ("RMR-DIM-PLAN"   2.50 2.50 "General plans and layouts")
   ("RMR-DIM-DETAIL" 1.80 1.80 "Detail drawings and small-scale work")
   ("RMR-DIM-LARGE"  3.50 3.50 "Large sheets and presentation dimensions")
  )
)

;;; Multileader style: (Name TextHeight ArrowSize Description)
(setq *RMR-MLEADER-SPECS*
 '(
   ("RMR-MLEADER" 2.50 2.50 "Modern plan callouts and keynote leaders")
  )
)

(setq *RMR-BRAND-INK*       '(31 42 51))
(setq *RMR-BRAND-TERRA*     '(198 93 72))
(setq *RMR-BRAND-TEAL*      '(57 137 130))
(setq *RMR-BRAND-GOLD*      '(214 163 76))
(setq *RMR-BRAND-SAND*      '(238 225 201))
(setq *RMR-BRAND-BLUE*      '(47 116 181))
(setq *RMR-BRAND-SLATE*     '(86 104 116))
;; RMR-PRO-SETUP enables this only for the named RMR text styles.
(setq *RMR-FORCE-STYLE-REFRESH* nil)

;;; -----------------------------------------------------------------------------
;;; PRODUCTION SUITE DATA TABLES
;;; Everything below is editable in exactly the same way as the layer palette.
;;; Add, remove or re-order entries; the commands read these tables at run time.
;;; -----------------------------------------------------------------------------

;;; Suite version, printed by RMR-PALETTE and at load time.
(setq *RMR-VERSION* "12.0 CONSTRUCTION DETAILING SUITE")

;;; Annotation scale factor applied to every PRO symbol command.
;;; RMR-SCALE updates it. 1.0 means the drawing is annotated at 1:100 size.
(setq *RMR-ANNO-SCALE* 1.0)
(setq *RMR-DRAW-SCALE-LABEL* "1:100")

;;; Drawing scales: (Keyword Label Denominator PlotStandardScaleEnum)
;;; Keyword is what you type at the RMR-SCALE prompt, Label is what is printed.
;;; PlotStandardScaleEnum is the AutoCAD AcPlotScale index used by RMR-PAGESETUP.
;;; nil means AutoCAD has no named plot scale for it, so the layout scale is
;;; left untouched and the command tells you to set it in PAGESETUP.
(setq *RMR-SCALE-SPECS*
 '(
   ("20"  "1:20"    20.0  23)
   ("50"  "1:50"    50.0  26)
   ("75"  "1:75"    75.0  nil)
   ("100" "1:100"  100.0  27)
   ("150" "1:150"  150.0  nil)
   ("200" "1:200"  200.0  nil)
   ("500" "1:500"  500.0  nil)
   ("FIT" "Fit"      nil   0)
  )
)

;;; Annotation space used by RMR-SCALE: "MODEL" or "LAYOUT".
;;; LAYOUT keeps the original paper-size symbols (factor 1.0). MODEL multiplies
;;; every symbol, tag, note and table size by the scale denominator, which is
;;; what a real-world millimetre model space needs.
(setq *RMR-ANNO-SPACE* "LAYOUT")

;;; Material hatch library:
;;;   (Keyword Label Pattern Scale Angle Layer RGB Description)
;;; Patterns are standard AutoCAD (acad.pat / acadiso.pat) names.
(setq *RMR-HATCH-SPECS*
 '(
   ("1"  "SOLID FILL"      "SOLID"    1.0   0.0 "RMR-M-FILL"   (244 238 226) "Soft presentation solid fill")
   ("2"  "CONCRETE / RCC"  "AR-CONC"  1.0   0.0 "RMR-M-HATCH"  (192 160 129) "Cast in-situ concrete, RCC members")
   ("3"  "BRICK MASONRY"   "AR-B816"  1.0   0.0 "RMR-M-HATCH"  (198  93  72) "Brick / block masonry in cut")
   ("4"  "PLASTER / SAND"  "AR-SAND"  1.0   0.0 "RMR-M-HATCH"  (214 190 150) "Plaster, screed, bedding and mortar")
   ("5"  "SECTION CUT"     "ANSI31"   1.0  45.0 "RMR-M-HATCH"  (184  72  72) "Generic cut material in sections")
   ("6"  "STRUCTURAL STEEL" "ANSI31"  0.50 45.0 "RMR-S-BEAM"   (210 119  58) "Steel sections and plates")
   ("7"  "TIMBER / WOOD"   "DOLMIT"   1.0   0.0 "RMR-F-FURN"   (186 138  74) "Timber, joinery and carpentry")
   ("8"  "GLASS / GLAZING" "LINE"     0.50 45.0 "RMR-M-GLASS"  (116 190 198) "Glazing, mirrors and screens")
   ("9"  "INSULATION"      "HEX"      1.0   0.0 "RMR-M-FINISH" (238 225 201) "Thermal and acoustic insulation")
   ("10" "EARTH / FILL"    "GRAVEL"   1.0   0.0 "RMR-S-FOUND"  (125 134 168) "Excavation, backfill and earthworks")
   ("11" "TILE / FLOOR"    "AR-HBONE" 0.60  0.0 "RMR-M-FINISH" ( 57 137 130) "Floor tiles, pavers and herringbone")
   ("12" "DEMOLITION"      "ANSI37"   1.50  0.0 "RMR-A-REVISION" (198 93 72) "Existing work to be demolished")
  )
)

;;; Issue / status stamps: (Keyword Label RGB)
(setq *RMR-STAMP-SPECS*
 '(
   ("PRELIM"   "PRELIMINARY"             (214 163  76))
   ("IFR"      "ISSUED FOR REVIEW"       ( 47 116 181))
   ("IFC"      "ISSUED FOR CONSTRUCTION" ( 57 137 130))
   ("TENDER"   "ISSUED FOR TENDER"       (130  92 160))
   ("ASBUILT"  "AS-BUILT RECORD"         ( 86 104 116))
   ("NOTSCALE" "DO NOT SCALE"            (198  93  72))
   ("VOID"     "DRAWING VOID / SUPERSEDED" (120 120 120))
  )
)

;;; General notes library: each entry is one numbered note.
;;; Edit freely - RMR-NOTES renumbers and wraps them automatically.
(setq *RMR-NOTES*
 '(
   "All dimensions are in millimetres unless noted otherwise on the drawing."
   "Do not scale from this drawing. Work to the written dimensions only."
   "This drawing follows the RooMNRooF consultant 2D CAD standard."
   "Verify all site dimensions and existing conditions before fabrication."
   "Contractor to coordinate architectural, structural and plumbing services."
   "Report any discrepancy to the consultant in writing before proceeding."
   "All finishes, colours and samples to be approved by the client first."
   "Drawings remain the property of RooMNRooF and may not be reused."
  )
)

;;; Structural grid bubbles. Letters I and O are excluded on purpose because
;;; they are confused with 1 and 0 on site.
(setq *RMR-GRID-LETTERS*
 '("A" "B" "C" "D" "E" "F" "G" "H" "J" "K" "L" "M"
   "N" "P" "Q" "R" "S" "T" "U" "V" "W" "X" "Y" "Z")
)
(setq *RMR-GRID-DIAMETER* 12.0)

;;; Plot and publish defaults. RMR-PAGESETUP verifies the device and the media
;;; name against the installed plotter before it applies them.
(setq *RMR-PLOT-DEVICE* "DWG To PDF.pc3")
(setq *RMR-PLOT-STYLE*  "monochrome.ctb")
(setq *RMR-PLOT-BRAND-STYLE* "RooMNRooF.ctb")
(setq *RMR-PLOT-ROTATION* 1) ; 0 = portrait, 1 = landscape

;;; Sheet paper names used for fuzzy media-name matching, in millimetres.
;;;   (SheetKey Width Height)
(setq *RMR-PAPER-SPECS*
 '(
   ("A0" 1189.0 841.0)
   ("A1"  841.0 594.0)
   ("A2"  594.0 420.0)
   ("A3"  420.0 297.0)
   ("A4"  297.0 210.0)
  )
)

;;; Area unit conversion. INSUNITS value -> square metres per square unit.
;;;   (InsUnits Factor Name)
(setq *RMR-AREA-UNITS*
 '(
   (1 0.00064516 "sq.in")
   (2 0.09290304 "sq.ft")
   (4 0.000001   "sq.mm")
   (5 0.0001     "sq.cm")
   (6 1.0        "sq.m")
  )
)
(setq *RMR-SQFT-PER-SQM* 10.7639104167)

;;; -----------------------------------------------------------------------------
;;; Small helpers
;;; -----------------------------------------------------------------------------

(defun RMR:RGB->420 (rgb)
  (+ (* (car rgb) 65536) (* (cadr rgb) 256) (caddr rgb))
)

(defun RMR:3D (p)
  (list (car p) (cadr p) (if (caddr p) (caddr p) 0.0))
)

(defun RMR:PT+ (p dx dy)
  (list (+ (car p) dx) (+ (cadr p) dy) (if (caddr p) (caddr p) 0.0))
)

(defun RMR:DXF (code value data)
  (if (assoc code data)
    (subst (cons code value) (assoc code data) data)
    (append data (list (cons code value)))
  )
)

(defun RMR:SafeSet (variable value / result)
  (setq result (vl-catch-all-apply 'setvar (list variable value)))
  (not (vl-catch-all-error-p result))
)

(defun RMR:TryPut (object property value / result)
  (setq result (vl-catch-all-apply 'vlax-put-property (list object property value)))
  (not (vl-catch-all-error-p result))
)

(defun RMR:FindFont (requested)
  ;; Preferred font -> modern system font -> common AutoCAD font fallback.
  (cond
    ((findfile requested) requested)
    ((findfile "Aptos.ttf") "Aptos.ttf")
    ((findfile "Arial.ttf") "Arial.ttf")
    ((findfile "arial.ttf") "arial.ttf")
    ((findfile "Calibri.ttf") "Calibri.ttf")
    ((findfile "segoeui.ttf") "segoeui.ttf")
    ((findfile "romans.shx") "romans.shx")
    ((findfile "simplex.shx") "simplex.shx")
    (T "txt.shx")
  )
)

(defun RMR:LayerLtype (requested)
  (if (tblsearch "LTYPE" requested) requested "Continuous")
)

(defun RMR:GroupPrefix (group)
  (cond
    ((= (strcase group) "MAIN THEME") "RMR-M-")
    ((= (strcase group) "FURNITURE") "RMR-F-")
    ((= (strcase group) "STRUCTURAL") "RMR-S-")
    ((= (strcase group) "PLUMBING") "RMR-P-")
    ((= (strcase group) "SERVICES") "RMR-E-")
    ((= (strcase group) "ANNOTATION") "RMR-A-")
    ((= (strcase group) "PRESENTATION") "RMR-PRES-")
    ((= (strcase group) "CONTROL") "RMR-00-")
    (T "RMR-")
  )
)

;;; -----------------------------------------------------------------------------
;;; Linetypes, text styles and layers
;;; -----------------------------------------------------------------------------

(defun RMR:EnsureLinetypes (/ linfile names)
  (setq names '("CENTER" "HIDDEN" "DASHED" "DOT" "PHANTOM"))
  (setq linfile (or (findfile "acadiso.lin") (findfile "acad.lin")))
  (if linfile
    (foreach name names
      (if (not (tblsearch "LTYPE" name))
        (command "_.-linetype" "_Load" name linfile "")
      )
    )
  )
)

(defun RMR:EnsureTextStyle (spec / name font width oblique ename data)
  (setq name (nth 0 spec))
  (setq font (RMR:FindFont (nth 1 spec)))
  (setq width (nth 2 spec))
  (setq oblique (nth 3 spec))
  (if (not (tblsearch "STYLE" name))
    (entmake
      (list
        '(0 . "STYLE")
        '(100 . "AcDbSymbolTableRecord")
        '(100 . "AcDbTextStyleTableRecord")
        (cons 2 name)
        '(70 . 0)
        '(40 . 0.0)
        (cons 41 width)
        (cons 50 oblique)
        '(71 . 0)
        '(42 . 2.5)
        (cons 3 font)
        (cons 4 "")
      )
    )
    ;; PRO setup may explicitly refresh only the RMR-owned text styles.
    (if *RMR-FORCE-STYLE-REFRESH*
      (progn
        (setq ename (tblobjname "STYLE" name))
        (setq data (entget ename))
        (setq data (RMR:DXF 3 font data))
        (setq data (RMR:DXF 41 width data))
        (setq data (RMR:DXF 50 oblique data))
        (entmod data)
      )
    )
  )
)

(defun RMR:EnsureLayerDescription (name description / ename data)
  ;; A LAYER record has no DXF description group code, so the description is
  ;; written the way AutoCAD keeps it: XDATA under AcAecLayerStandard plus the
  ;; COM Description property when ActiveX is available (full AutoCAD).
  (if (and name description (/= description ""))
    (progn
      (vl-catch-all-apply 'regapp (list "AcAecLayerStandard"))
      (setq ename (tblobjname "LAYER" name))
      (if ename
        (progn
          (setq data (entget ename '("AcAecLayerStandard")))
          (setq data (vl-remove-if '(lambda (x) (= (car x) -3)) data))
          (vl-catch-all-apply
            'entmod
            (list
              (append data
                (list
                  (list -3
                    (list "AcAecLayerStandard"
                          (cons 1000 "")
                          (cons 1000 description)
                    )
                  )
                )
              )
            )
          )
          (RMR:TryPut
            (vl-catch-all-apply 'vlax-ename->vla-object (list ename))
            'Description description
          )
        )
      )
    )
  )
  T
)

(defun RMR:EnsureLayer (spec / name group rgb ltype lw description record ename data colour)
  (setq name        (nth 0 spec))
  (setq group       (nth 1 spec))
  (setq rgb         (nth 2 spec))
  (setq ltype       (RMR:LayerLtype (nth 3 spec)))
  (setq lw          (nth 4 spec))
  (setq description (nth 5 spec))
  (if (setq record (tblsearch "LAYER" name))
    (progn
      (setq ename (tblobjname "LAYER" name))
      (setq data (entget ename))
      ;; 7 remains a safe ACI fallback; 420 is the brand true colour.
      ;; A negative 62 means the layer is switched off, and that state is kept.
      (setq colour (cdr (assoc 62 data)))
      (setq data (RMR:DXF 62 (if (and (numberp colour) (< colour 0)) -7 7) data))
      (setq data (RMR:DXF 420 (RMR:RGB->420 rgb) data))
      (setq data (RMR:DXF 6 ltype data))
      (setq data (RMR:DXF 370 lw data))
      (if (= (strcase name) "RMR-00-NPLT")
        (setq data (RMR:DXF 290 0 data))
        (setq data (RMR:DXF 290 1 data))
      )
      (entmod data)
    )
    (entmake
      (list
        '(0 . "LAYER")
        '(100 . "AcDbSymbolTableRecord")
        '(100 . "AcDbLayerTableRecord")
        (cons 2 name)
        '(70 . 0)
        '(62 . 7)
        (cons 420 (RMR:RGB->420 rgb))
        (cons 6 ltype)
        (cons 370 lw)
        (cons 290 (if (= (strcase name) "RMR-00-NPLT") 0 1))
      )
    )
  )
  (RMR:EnsureLayerDescription name description)
  name
)

;;; -----------------------------------------------------------------------------
;;; Arrow, symbol blocks and dimension styles
;;; -----------------------------------------------------------------------------

(defun RMR:BeginBlock (name)
  (entmake
    (list '(0 . "BLOCK") (cons 2 name) '(70 . 0) (cons 10 '(0.0 0.0 0.0)))
  )
)

(defun RMR:EndBlock ()
  (entmake '((0 . "ENDBLK") (8 . "0")))
)

(defun RMR:BlockLine (p1 p2)
  (entmake
    (list '(0 . "LINE") '(8 . "0") (cons 10 p1) (cons 11 p2))
  )
)

(defun RMR:BlockCircle (center radius)
  (entmake
    (list '(0 . "CIRCLE") '(8 . "0") (cons 10 center) (cons 40 radius))
  )
)

(defun RMR:BlockSolid (p1 p2 p3 p4)
  (entmake
    (list '(0 . "SOLID") '(8 . "0")
          (cons 10 p1) (cons 11 p2) (cons 12 p3) (cons 13 p4))
  )
)

(defun RMR:BlockText (p text height style)
  (entmake
    (list '(0 . "TEXT") '(8 . "0") (cons 10 p) (cons 40 height)
          (cons 1 text) (cons 7 style) '(72 . 0) '(73 . 0))
  )
)

(defun RMR:EnsureProBlocks (/ block)
  ;; These are deliberately simple, annotative-friendly symbols. They are
  ;; created once and can be inserted on any RMR presentation layer.
  (setq block "RMR-NORTH-ARROW")
  (if (not (tblsearch "BLOCK" block))
    (progn
      (RMR:BeginBlock block)
      (RMR:BlockCircle '(0.0 0.0 0.0) 7.0)
      (RMR:BlockLine '(0.0 -5.0 0.0) '(0.0 9.0 0.0))
      (RMR:BlockSolid '(0.0 9.0 0.0) '(-2.4 4.0 0.0) '(0.0 5.0 0.0) '(2.4 4.0 0.0))
      (RMR:BlockText '(-1.5 11.0 0.0) "N" 3.5 "RMR-NUMBER")
      (RMR:EndBlock)
    )
  )
  (setq block "RMR-DETAIL-BUBBLE")
  (if (not (tblsearch "BLOCK" block))
    (progn
      (RMR:BeginBlock block)
      (RMR:BlockCircle '(0.0 0.0 0.0) 5.0)
      (RMR:BlockLine '(5.0 0.0 0.0) '(21.0 0.0 0.0))
      (RMR:BlockText '(-1.1 -1.5 0.0) "A" 3.0 "RMR-NUMBER")
      (RMR:EndBlock)
    )
  )
  (setq block "RMR-KEYNOTE-BUBBLE")
  (if (not (tblsearch "BLOCK" block))
    (progn
      (RMR:BeginBlock block)
      (RMR:BlockCircle '(0.0 0.0 0.0) 5.0)
      (RMR:BlockText '(-2.3 -1.5 0.0) "01" 3.0 "RMR-NUMBER")
      (RMR:EndBlock)
    )
  )
  (setq block "RMR-LEVEL-DATUM")
  (if (not (tblsearch "BLOCK" block))
    (progn
      (RMR:BeginBlock block)
      (RMR:BlockLine '(0.0 0.0 0.0) '(20.0 0.0 0.0))
      (RMR:BlockSolid '(0.0 0.0 0.0) '(5.0 3.5 0.0) '(5.0 -3.5 0.0) '(5.0 0.0 0.0))
      (RMR:BlockText '(7.0 -1.5 0.0) "±0.000" 3.0 "RMR-NUMBER")
      (RMR:EndBlock)
    )
  )
  T
)

(defun RMR:EnsureArrowBlock (/ block)
  (setq block "RMR-ARROW-CHEVRON")
  (if (not (tblsearch "BLOCK" block))
    (progn
      (entmake
        (list
          '(0 . "BLOCK")
          (cons 2 block)
          '(70 . 0)
          (cons 10 '(0.0 0.0 0.0))
        )
      )
      ;; Tip is at 0,0. AutoCAD rotates/scales the block for a leader.
      (entmake
        (list '(0 . "LINE") '(8 . "0")
              (cons 10 '(0.0 0.0 0.0)) (cons 11 '(-1.25 0.55 0.0)))
      )
      (entmake
        (list '(0 . "LINE") '(8 . "0")
              (cons 10 '(0.0 0.0 0.0)) (cons 11 '(-1.25 -0.55 0.0)))
      )
      (entmake
        (list '(0 . "LINE") '(8 . "0")
              (cons 10 '(-1.25 0.55 0.0)) (cons 11 '(-0.88 0.0 0.0)))
      )
      (entmake
        (list '(0 . "LINE") '(8 . "0")
              (cons 10 '(-1.25 -0.55 0.0)) (cons 11 '(-0.88 0.0 0.0)))
      )
      (entmake '((0 . "ENDBLK") (8 . "0")))
    )
  )
  block
)

(defun RMR:ComColor (rgb / acad colour version result)
  ;; AcCmColor's ProgID changes with AutoCAD releases. Try common releases.
  (setq acad (vlax-get-acad-object))
  (setq version 30)
  (while (and (not colour) (> version 10))
    (setq result
      (vl-catch-all-apply
        'vla-GetInterfaceObject
        (list acad (strcat "AutoCAD.AcCmColor." (itoa version)))
      )
    )
    (if (not (vl-catch-all-error-p result))
      (setq colour result)
    )
    (setq version (1- version))
  )
  (if colour
    (vla-SetRGB colour (car rgb) (cadr rgb) (caddr rgb))
  )
  colour
)

(defun RMR:EnsureDimStyle (spec / acad doc styles name txt asz ds colour)
  (setq name (nth 0 spec))
  (setq txt  (nth 1 spec))
  (setq asz  (nth 2 spec))
  (setq acad (vlax-get-acad-object))
  (setq doc (vla-get-ActiveDocument acad))
  (setq styles (vla-get-DimStyles doc))
  (if (tblsearch "DIMSTYLE" name)
    (setq ds (vla-Item styles name))
    (setq ds (vla-Add styles name))
  )
  ;; Properties are set defensively because a few AutoCAD LT releases expose
  ;; fewer COM properties than full AutoCAD.
  (RMR:TryPut ds 'TextStyle "RMR-BODY")
  (RMR:TryPut ds 'Dimtxt txt)
  (RMR:TryPut ds 'Dimasz asz)
  (RMR:TryPut ds 'Dimexo 1.0)
  (RMR:TryPut ds 'Dimexe 1.5)
  (RMR:TryPut ds 'Dimgap 1.0)
  (RMR:TryPut ds 'Dimdli (* asz 3.0))
  (RMR:TryPut ds 'Dimtad 1)
  (RMR:TryPut ds 'Dimtih 0)
  (RMR:TryPut ds 'Dimtoh 0)
  (RMR:TryPut ds 'Dimtmove 2)
  (RMR:TryPut ds 'Dimtix :vlax-false)
  (RMR:TryPut ds 'Dimlunit 2)
  (RMR:TryPut ds 'Dimdec 0)
  (RMR:TryPut ds 'Dimdsep ".")
  (RMR:TryPut ds 'Dimaunit 0)
  (RMR:TryPut ds 'Dimadec 0)
  (RMR:TryPut ds 'Dimazin 0)
  (RMR:TryPut ds 'Dimzin 8)
  (RMR:TryPut ds 'Dimassoc 2)
  (RMR:TryPut ds 'Dimscale 1.0)
  (RMR:TryPut ds 'Dimblk "RMR-ARROW-CHEVRON")
  (RMR:TryPut ds 'Dimblk1 "RMR-ARROW-CHEVRON")
  (RMR:TryPut ds 'Dimblk2 "RMR-ARROW-CHEVRON")
  (RMR:TryPut ds 'Dimldrblk "RMR-ARROW-CHEVRON")
  (setq colour (RMR:ComColor *RMR-BRAND-INK*))
  (if colour
    (progn
      (RMR:TryPut ds 'Dimclrd colour)
      (RMR:TryPut ds 'Dimclre colour)
      (RMR:TryPut ds 'Dimclrt colour)
    )
  )
  ds
)

(defun RMR:EnsureMLeaderStyle (spec / acad doc styles name txt asz ml colour)
  (setq name (nth 0 spec))
  (setq txt  (nth 1 spec))
  (setq asz  (nth 2 spec))
  (setq acad (vlax-get-acad-object))
  (setq doc (vla-get-ActiveDocument acad))
  (setq styles (vla-get-MLeaderStyles doc))
  (if (tblsearch "MLEADERSTYLE" name)
    (setq ml (vla-Item styles name))
    (setq ml (vla-Add styles name))
  )
  (RMR:TryPut ml 'ContentType 2)
  (RMR:TryPut ml 'TextStyle "RMR-BODY")
  (RMR:TryPut ml 'TextHeight txt)
  (RMR:TryPut ml 'ArrowSize asz)
  (RMR:TryPut ml 'DoglegLength (* asz 3.0))
  (RMR:TryPut ml 'LandingGap (* asz 0.5))
  (RMR:TryPut ml 'EnableDogleg :vlax-true)
  (RMR:TryPut ml 'EnableLanding :vlax-true)
  (RMR:TryPut ml 'ScaleFactor 1.0)
  (RMR:TryPut ml 'ArrowheadBlock "RMR-ARROW-CHEVRON")
  (setq colour (RMR:ComColor *RMR-BRAND-GOLD*))
  (if colour
    (progn
      (RMR:TryPut ml 'TextColor colour)
      (RMR:TryPut ml 'LeaderLineColor colour)
    )
  )
  ml
)

;;; -----------------------------------------------------------------------------
;;; Drawing entities used by RMR-LEGEND and RMR-SHEET
;;; -----------------------------------------------------------------------------

(defun RMR:Line (p1 p2 layer rgb)
  (entmake
    (list
      '(0 . "LINE")
      (cons 8 layer)
      (cons 10 (RMR:3D p1))
      (cons 11 (RMR:3D p2))
      (cons 62 7)
      (cons 420 (RMR:RGB->420 rgb))
    )
  )
)

(defun RMR:Rect (p width height layer rgb / p1 p2 p3 p4)
  (setq p1 (RMR:3D p))
  (setq p2 (RMR:PT+ p width 0.0))
  (setq p3 (RMR:PT+ p width height))
  (setq p4 (RMR:PT+ p 0.0 height))
  (RMR:Line p1 p2 layer rgb)
  (RMR:Line p2 p3 layer rgb)
  (RMR:Line p3 p4 layer rgb)
  (RMR:Line p4 p1 layer rgb)
)

(defun RMR:Circle (p radius layer rgb)
  (entmake
    (list
      '(0 . "CIRCLE")
      (cons 8 layer)
      (cons 10 (RMR:3D p))
      (cons 40 radius)
      '(62 . 7)
      (cons 420 (RMR:RGB->420 rgb))
    )
  )
)

(defun RMR:Triangle (p size layer rgb / p1 p2 p3)
  (setq p1 (RMR:3D p))
  (setq p2 (RMR:PT+ p size 0.0))
  (setq p3 (RMR:PT+ p (/ size 2.0) size))
  (entmake
    (list
      '(0 . "SOLID")
      (cons 8 layer)
      (cons 10 p1)
      (cons 11 p2)
      (cons 12 p3)
      (cons 13 p3)
      '(62 . 7)
      (cons 420 (RMR:RGB->420 rgb))
    )
  )
)

(defun RMR:Solid (p width height layer rgb / p1 p2 p3 p4)
  (setq p1 (RMR:3D p))
  (setq p2 (RMR:PT+ p width 0.0))
  (setq p3 (RMR:PT+ p 0.0 height))
  (setq p4 (RMR:PT+ p width height))
  (entmake
    (list
      '(0 . "SOLID")
      (cons 8 layer)
      (cons 10 p1)
      (cons 11 p2)
      (cons 12 p3)
      (cons 13 p4)
      '(62 . 7)
      (cons 420 (RMR:RGB->420 rgb))
    )
  )
)

(defun RMR:Text (p text height style layer rgb)
  (entmake
    (list
      '(0 . "TEXT")
      (cons 8 layer)
      (cons 10 (RMR:3D p))
      (cons 40 height)
      (cons 1 text)
      (cons 7 style)
      '(62 . 7)
      (cons 420 (RMR:RGB->420 rgb))
      '(72 . 0)
      '(73 . 0)
    )
  )
)

(defun RMR:CenterText (p text height style layer rgb)
  (entmake
    (list
      '(0 . "TEXT")
      (cons 8 layer)
      (cons 10 (RMR:3D p))
      (cons 11 (RMR:3D p))
      (cons 40 height)
      (cons 1 text)
      (cons 7 style)
      '(62 . 7)
      (cons 420 (RMR:RGB->420 rgb))
      '(72 . 1)
      '(73 . 0)
    )
  )
)

;;; -----------------------------------------------------------------------------
;;; Production-suite helpers
;;; -----------------------------------------------------------------------------

(defun RMR:Scaled (value)
  ;; Multiplies a paper-size value by the active annotation scale factor.
  (* value (if *RMR-ANNO-SCALE* *RMR-ANNO-SCALE* 1.0))
)

(defun RMR:Polar (point angle distance)
  (list
    (+ (car point) (* distance (cos angle)))
    (+ (cadr point) (* distance (sin angle)))
    (if (caddr point) (caddr point) 0.0)
  )
)

(defun RMR:Num (value precision / old result)
  (if (not value) (setq value 0.0))
  (setq old (getvar "DIMZIN"))
  (RMR:SafeSet "DIMZIN" 0)
  (setq result (rtos value 2 precision))
  (RMR:SafeSet "DIMZIN" old)
  result
)

(defun RMR:NumPad2 (number)
  (if (< number 10) (strcat "0" (itoa number)) (itoa number))
)

(defun RMR:StartsWith (text prefix)
  (and
    (>= (strlen text) (strlen prefix))
    (= (substr text 1 (strlen prefix)) prefix)
  )
)

(defun RMR:TrimString (text)
  (vl-string-trim " \t\r\n" text)
)

(defun RMR:GridLabel (index / len rest first second)
  ;; 1 -> A, 24 -> Z, 25 -> AA. Letters I and O are excluded on purpose.
  (setq len (length *RMR-GRID-LETTERS*))
  (cond
    ((< index 1) "0")
    ((<= index len) (nth (1- index) *RMR-GRID-LETTERS*))
    (T
      (setq rest (- index len))
      (setq first (/ (1- rest) len))
      (setq second (rem (1- rest) len))
      (if (< first len)
        (strcat (nth first *RMR-GRID-LETTERS*) (nth second *RMR-GRID-LETTERS*))
        (itoa index)
      )
    )
  )
)

(defun RMR:TableSpec (key table / spec found)
  (foreach spec table
    (if (= (strcase (nth 0 spec)) (strcase key)) (setq found spec))
  )
  found
)

(defun RMR:ReplaceSpec (key spec table / out item)
  (setq out '())
  (foreach item table
    (if (= (strcase (nth 0 item)) (strcase key))
      (setq out (append out (list spec)))
      (setq out (append out (list item)))
    )
  )
  out
)

(defun RMR:KeywordList (table / out spec)
  (setq out "")
  (foreach spec table
    (setq out (strcat out (if (= out "") "" " ") (nth 0 spec)))
  )
  out
)

(defun RMR:KeywordBar (keywords)
  (vl-string-translate " " "/" keywords)
)

(defun RMR:LabelList (table / out spec)
  (setq out "")
  (foreach spec table
    (setq out (strcat out (if (= out "") "" "  ") (nth 0 spec) "=" (nth 1 spec)))
  )
  out
)

(defun RMR:PromptReal (message default / value)
  (setq value (getreal (strcat "\n" message " <" (RMR:Num default 1) ">: ")))
  (if (or (not value) (<= value 0.0)) default value)
)

(defun RMR:PromptInt (message default / value)
  (setq value (getint (strcat "\n" message " <" (itoa default) ">: ")))
  (if (or (not value) (<= value 0)) default value)
)

(defun RMR:PromptText (message default / value)
  (setq value (getstring T (strcat "\n" message " <" default ">: ")))
  (if (or (not value) (= (RMR:TrimString value) "")) default value)
)

(defun RMR:PromptAngle (message default / value)
  (setq value (getreal (strcat "\n" message " in degrees <" (RMR:Num default 1) ">: ")))
  (if (not value) default value)
)

(defun RMR:PromptYesNo (message default / kw)
  (initget "Yes No")
  (setq kw (getkword (strcat "\n" message " [Yes/No] <" default ">: ")))
  (if (not kw) default kw)
)

(defun RMR:PromptKeyword (message keywords default / kw)
  (initget keywords)
  (setq kw (getkword (strcat "\n" message " [" (RMR:KeywordBar keywords) "] <" default ">: ")))
  (if (not kw) default kw)
)

(defun RMR:YesP (answer)
  (= (strcase (RMR:TrimString answer)) "YES")
)

(defun RMR:InList (item lst / found x)
  (foreach x lst
    (if (= (strcase item) (strcase x)) (setq found T))
  )
  (if found T nil)
)

(defun RMR:GroupLayerNames (group / names spec)
  (setq names '())
  (foreach spec *RMR-LAYER-SPECS*
    (if (= (strcase (nth 1 spec)) (strcase group))
      (setq names (append names (list (nth 0 spec))))
    )
  )
  names
)

(defun RMR:ResolveGroup (keyword)
  (cond
    ((= (strcase keyword) "MAIN") "MAIN THEME")
    ((= (strcase keyword) "FURNITURE") "FURNITURE")
    ((= (strcase keyword) "STRUCTURAL") "STRUCTURAL")
    ((= (strcase keyword) "PLUMBING") "PLUMBING")
    ((= (strcase keyword) "MEP") "SERVICES")
    ((= (strcase keyword) "ANNOTATION") "ANNOTATION")
    ((= (strcase keyword) "PRESENTATION") "PRESENTATION")
    ((= (strcase keyword) "CONTROL") "CONTROL")
    (T nil)
  )
)

(defun RMR:GroupKeywords ()
  "Main Furniture Structural Plumbing MEP Annotation Presentation Control"
)

(defun RMR:DocSafe (/ acad doc)
  (setq acad (vl-catch-all-apply 'vlax-get-acad-object nil))
  (if (vl-catch-all-error-p acad)
    nil
    (progn
      (setq doc (vl-catch-all-apply 'vla-get-ActiveDocument (list acad)))
      (if (vl-catch-all-error-p doc) nil doc)
    )
  )
)

;;; --- text and table drawing helpers -----------------------------------------

(defun RMR:RotText (point text height style layer rgb angle)
  ;; Centred, rotated single-line text. Angle is in radians.
  (entmake
    (list
      '(0 . "TEXT")
      (cons 8 layer)
      (cons 10 (RMR:3D point))
      (cons 11 (RMR:3D point))
      (cons 40 height)
      (cons 1 text)
      (cons 7 style)
      '(62 . 7)
      (cons 420 (RMR:RGB->420 rgb))
      '(72 . 1)
      '(73 . 0)
      (cons 50 angle)
    )
  )
)

(defun RMR:RotRect (point width height layer rgb angle / p1 p2 p3 p4 perp)
  ;; point is the lower-left corner measured along the rotation angle.
  (setq perp (+ angle (/ pi 2.0)))
  (setq p1 (RMR:3D point))
  (setq p2 (RMR:Polar p1 angle width))
  (setq p3 (RMR:Polar p2 perp height))
  (setq p4 (RMR:Polar p1 perp height))
  (RMR:Line p1 p2 layer rgb)
  (RMR:Line p2 p3 layer rgb)
  (RMR:Line p3 p4 layer rgb)
  (RMR:Line p4 p1 layer rgb)
)

(defun RMR:ChunkText (text size / out rest)
  ;; MTEXT stores more than 250 characters in repeated group-3 entries.
  (setq out '())
  (setq rest text)
  (while (> (strlen rest) size)
    (setq out (append out (list (cons 3 (substr rest 1 size)))))
    (setq rest (substr rest (1+ size)))
  )
  (append out (list (cons 1 rest)))
)

(defun RMR:MText (point text width height style layer rgb attach / base)
  (setq base
    (list
      '(0 . "MTEXT")
      '(100 . "AcDbEntity")
      (cons 8 layer)
      '(62 . 7)
      (cons 420 (RMR:RGB->420 rgb))
      '(100 . "AcDbMText")
      (cons 10 (RMR:3D point))
      (cons 40 height)
      (cons 41 width)
      (cons 71 attach)
      '(72 . 1)
    )
  )
  (setq base (append base (RMR:ChunkText text 240)))
  (setq base (append base (list (cons 7 style) '(73 . 1) '(44 . 1.2))))
  (entmake base)
)

(defun RMR:TableDividers (x y widths height layer rgb / cx count index)
  (setq cx x)
  (setq count (length widths))
  (setq index 0)
  (foreach width widths
    (setq index (1+ index))
    (if (< index count)
      (progn
        (setq cx (+ cx width))
        (RMR:Line (list cx y 0.0) (list cx (+ y height) 0.0) layer rgb)
      )
    )
  )
)

(defun RMR:GridBubble (center label radius)
  (RMR:Circle center radius "RMR-A-GRID" *RMR-BRAND-SLATE*)
  (RMR:CenterText center label (* radius 0.85) "RMR-NUMBER" "RMR-A-GRID" *RMR-BRAND-INK*)
)

;;; --- units, dates and files --------------------------------------------------

(defun RMR:AreaToSqm (raw / units factor spec)
  (setq units (getvar "INSUNITS"))
  (setq factor 0.000001) ; unitless drawings are treated as millimetres
  (foreach spec *RMR-AREA-UNITS*
    (if (= (nth 0 spec) units) (setq factor (nth 1 spec)))
  )
  (* raw factor)
)

(defun RMR:LinearToMetres (value / units factor)
  (setq units (getvar "INSUNITS"))
  (setq factor
    (cond
      ((= units 1) 0.0254)
      ((= units 2) 0.3048)
      ((= units 4) 0.001)
      ((= units 5) 0.01)
      ((= units 6) 1.0)
      (T 0.001)
    )
  )
  (* value factor)
)

(defun RMR:EntityArea (ename / obj result)
  (setq obj (vl-catch-all-apply 'vlax-ename->vla-object (list ename)))
  (if (vl-catch-all-error-p obj)
    nil
    (progn
      (setq result (vl-catch-all-apply 'vlax-get-property (list obj 'Area)))
      (if (vl-catch-all-error-p result) nil result)
    )
  )
)

(defun RMR:TodayDate (/ result)
  (setq result (vl-catch-all-apply 'menucmd (list "M=$(edtime,0,YYYY-MM-DD)")))
  (if (or (vl-catch-all-error-p result) (not result) (= result ""))
    (setq result "YYYY-MM-DD")
  )
  result
)

(defun RMR:FolderOf (path / index ch pos)
  (setq pos 0)
  (setq index 1)
  (while (<= index (strlen path))
    (setq ch (substr path index 1))
    (if (or (= ch "\\") (= ch "/")) (setq pos index))
    (setq index (1+ index))
  )
  (if (> pos 0) (substr path 1 pos) "")
)

(defun RMR:StripExtension (name / index ch pos)
  (setq pos 0)
  (setq index 1)
  (while (<= index (strlen name))
    (setq ch (substr name index 1))
    (if (= ch ".") (setq pos index))
    (setq index (1+ index))
  )
  (if (> pos 0) (substr name 1 (1- pos)) name)
)

(defun RMR:FileTitle (path / folder)
  (setq folder (RMR:FolderOf path))
  (RMR:StripExtension (substr path (1+ (strlen folder))))
)

(defun RMR:SplitString (text delim / out current index len ch)
  (setq out '())
  (setq current "")
  (setq index 1)
  (setq len (strlen text))
  (while (<= index len)
    (setq ch (substr text index 1))
    (if (= ch delim)
      (progn
        (setq out (append out (list current)))
        (setq current "")
      )
      (setq current (strcat current ch))
    )
    (setq index (1+ index))
  )
  (append out (list current))
)

(defun RMR:ReadLines (path / file line lines)
  (setq lines '())
  (setq file (open path "r"))
  (if file
    (progn
      (while (setq line (read-line file))
        (setq lines (append lines (list line)))
      )
      (close file)
    )
  )
  lines
)

(defun RMR:WriteLines (path lines / file ok)
  (setq file (open path "w"))
  (if file
    (progn
      (foreach line lines (write-line line file))
      (close file)
      (setq ok T)
    )
  )
  ok
)

(defun RMR:AssocCountInc (key alist / entry)
  (setq entry (assoc key alist))
  (if entry
    (subst (cons key (1+ (cdr entry))) entry alist)
    (append alist (list (cons key 1)))
  )
)

(defun RMR:InsertPair (item sorted)
  (cond
    ((null sorted) (list item))
    ((>= (cdr item) (cdr (car sorted))) (cons item sorted))
    (T (cons (car sorted) (RMR:InsertPair item (cdr sorted))))
  )
)

(defun RMR:SortPairsDesc (alist / sorted item)
  (setq sorted '())
  (foreach item alist (setq sorted (RMR:InsertPair item sorted)))
  sorted
)

(defun RMR:SayLine (lines text)
  (princ (strcat "\n" text))
  (append lines (list text))
)

;;; --- layer state control (pure LISP, works without ActiveX) -------------------

(defun RMR:SetLayerState (name action / ename data flag colour)
  (if (setq ename (tblobjname "LAYER" name))
    (progn
      (setq data (entget ename))
      (setq flag (cdr (assoc 70 data)))
      (setq colour (cdr (assoc 62 data)))
      (if (not flag) (setq flag 0))
      (if (not colour) (setq colour 7))
      (cond
        ((= (strcase action) "FREEZE") (setq data (RMR:DXF 70 (logior flag 1) data)))
        ((= (strcase action) "THAW")   (setq data (RMR:DXF 70 (logand flag (lognot 1)) data)))
        ((= (strcase action) "LOCK")   (setq data (RMR:DXF 70 (logior flag 4) data)))
        ((= (strcase action) "UNLOCK") (setq data (RMR:DXF 70 (logand flag (lognot 4)) data)))
        ((= (strcase action) "OFF")    (setq data (RMR:DXF 62 (- (abs colour)) data)))
        ((= (strcase action) "ON")     (setq data (RMR:DXF 62 (abs colour) data)))
      )
      (entmod data)
    )
  )
)

;;; --- plotter media name lookup ------------------------------------------------

(defun RMR:FindMediaName (device sheetkey / spec token width height plot result names found name)
  (setq spec (RMR:TableSpec sheetkey *RMR-PAPER-SPECS*))
  (if spec
    (progn
      (setq width (RMR:Num (nth 1 spec) 2))
      (setq height (RMR:Num (nth 2 spec) 2))
      (setq token (strcat width "_x_" height))
      (setq plot (vl-catch-all-apply 'vla-get-Plot (list (RMR:DocSafe))))
      (if (not (vl-catch-all-error-p plot))
        (progn
          (setq result (vl-catch-all-apply 'vlax-invoke-method (list plot 'GetCanonicalMediaNames device)))
          (if (not (vl-catch-all-error-p result))
            (progn
              (setq names (vl-catch-all-apply 'vlax-safearray->list (list (vlax-variant-value result))))
              (if (vl-catch-all-error-p names) (setq names nil))
              (foreach name names
                (if (and (not found) (vl-string-search token (strcase name)))
                  (setq found name)
                )
              )
              (if (not found)
                (foreach name names
                  (if (and (not found) (vl-string-search (strcat "_" sheetkey "_") (strcase name)))
                    (setq found name)
                  )
                )
              )
            )
          )
        )
      )
    )
  )
  found
)

;;; -----------------------------------------------------------------------------
;;; Standard build and system settings
;;; -----------------------------------------------------------------------------

(defun RMR:ApplyStandards (/)
  ;; Metric drawing setup. Change these values here if your office uses inches.
  (RMR:SafeSet "MEASUREMENT" 1)
  (RMR:SafeSet "INSUNITS" 4)
  (RMR:SafeSet "LUNITS" 2)
  (RMR:SafeSet "LUPREC" 2)
  (RMR:SafeSet "AUNITS" 0)
  (RMR:SafeSet "AUPREC" 2)
  (RMR:SafeSet "PSLTSCALE" 1)
  (RMR:SafeSet "MSLTSCALE" 1)
  (RMR:SafeSet "CELTSCALE" 1.0)
  (RMR:SafeSet "LTSCALE" 1.0)
  (RMR:SafeSet "LWDISPLAY" 1)
  (RMR:SafeSet "VISRETAIN" 1)
  (RMR:SafeSet "MIRRTEXT" 0)
  (RMR:SafeSet "TEXTSIZE" 2.5)
  (RMR:SafeSet "DIMTXT" 2.5)
  (RMR:SafeSet "DIMASZ" 2.5)
  (RMR:SafeSet "DIMEXO" 1.0)
  (RMR:SafeSet "DIMEXE" 1.5)
  (RMR:SafeSet "DIMGAP" 1.0)
  (RMR:SafeSet "DIMASSOC" 2)
  (RMR:SafeSet "DIMLUNIT" 2)
  (RMR:SafeSet "DIMDEC" 0)
  (RMR:SafeSet "DIMTAD" 1)
  (RMR:SafeSet "DIMTMOVE" 2)
  (RMR:SafeSet "DIMLDRBLK" "RMR-ARROW-CHEVRON")
  (RMR:SafeSet "DIMBLK" "RMR-ARROW-CHEVRON")
  (RMR:SafeSet "DIMBLK1" "RMR-ARROW-CHEVRON")
  (RMR:SafeSet "DIMBLK2" "RMR-ARROW-CHEVRON")
  (if (tblsearch "STYLE" "RMR-BODY")
    (RMR:SafeSet "TEXTSTYLE" "RMR-BODY")
  )
  (if (tblsearch "DIMSTYLE" "RMR-DIM-PLAN")
    (RMR:SafeSet "DIMSTYLE" "RMR-DIM-PLAN")
  )
  (if (tblsearch "MLEADERSTYLE" "RMR-MLEADER")
    (RMR:SafeSet "CMLEADERSTYLE" "RMR-MLEADER")
  )
  (if (tblsearch "LAYER" "RMR-M-WALL")
    (RMR:SafeSet "CLAYER" "RMR-M-WALL")
  )
)

(defun RMR:Build (/ dim-result)
  (RMR:EnsureLinetypes)
  (foreach spec *RMR-TEXT-STYLES*
    (RMR:EnsureTextStyle spec)
  )
  (RMR:EnsureArrowBlock)
  (RMR:EnsureProBlocks)
  (RMR:BuildTitleBlock)
  (foreach spec *RMR-LAYER-SPECS*
    (RMR:EnsureLayer spec)
  )
  (foreach spec *RMR-DIMSTYLE-SPECS*
    (setq dim-result (vl-catch-all-apply 'RMR:EnsureDimStyle (list spec)))
  )
  (foreach spec *RMR-MLEADER-SPECS*
    (setq dim-result (vl-catch-all-apply 'RMR:EnsureMLeaderStyle (list spec)))
  )
  (RMR:ApplyStandards)
  T
)

;;; -----------------------------------------------------------------------------
;;; Main command
;;; -----------------------------------------------------------------------------

(defun C:RMR-MASTER (/ oldecho result)
  (setq oldecho (getvar "CMDECHO"))
  (setvar "CMDECHO" 0)
  (princ "\nRooMNRooF: building consultant 2D master standard...")
  (setq result (vl-catch-all-apply 'RMR:Build nil))
  (setvar "CMDECHO" oldecho)
  (if (vl-catch-all-error-p result)
    (princ (strcat "\nRooMNRooF: build stopped - " (vl-catch-all-error-message result)))
    (princ "\nRooMNRooF PRO: master standard ready. Current layer: RMR-M-WALL")
  )
  (princ (strcat "\nRooMNRooF " *RMR-VERSION* " | scale " *RMR-DRAW-SCALE-LABEL* " (" *RMR-ANNO-SPACE* ") | symbol factor " (RMR:Num *RMR-ANNO-SCALE* 2)))
  (princ "\nStandard: RMR-PRO-SETUP, RMR-SETLAYER, RMR-LEGEND, RMR-SHEET, RMR-PALETTE")
  (princ "\nAnnotate: RMR-SCALE, RMR-NORTH, RMR-ROOMTAG, RMR-AREA, RMR-KEYNOTE, RMR-DETAIL, RMR-LEVEL, RMR-REVISION, RMR-MLEADER, RMR-DIM")
  (princ "\nMarkers:  RMR-SECTION, RMR-ELEVATION, RMR-MATCHLINE, RMR-BREAKLINE, RMR-REVCLOUD")
  (princ "\nPresent:  RMR-HATCH, RMR-STAMP, RMR-REVTABLE, RMR-NOTES, RMR-SCALEBAR, RMR-KEYPLAN, RMR-GRID")
  (princ "\nSheets:   RMR-LAYOUTS, RMR-VPORT, RMR-PAGESETUP, RMR-PUBLISH")
  (princ "\nManage:   RMR-LAYGROUP, RMR-CHECK, RMR-COUNT, RMR-SYMBOLS, RMR-DOORSCHED, RMR-FINDTEXT, RMR-FIELDS, RMR-PROJECT, RMR-BACKUP")
  (princ "\nPalette:  RMR-EXPORT-PALETTE, RMR-IMPORT-PALETTE, RMR-SAVE-TEMPLATE")
  (princ "\nDeliver:  RMR-WALL, RMR-STAIR, RMR-LENGTH, RMR-BOM, RMR-FINISHES, RMR-SHEETREG, RMR-XREFLIST, RMR-TRANSMITTAL")
  (princ "\nHousekeeping: RMR-LAYERSTATE, RMR-STANDARDIZE, RMR-CLEAN, RMR-DWGPROPS")
  (princ "\nSite:   RMR-SUNPATH, RMR-FALL, RMR-DRAIN, RMR-PARK, RMR-TILE, RMR-RCP")
  (princ "\nData:   RMR-LEVELSCHED, RMR-KEYLIB, RMR-REPORT, RMR-STRAY")
  (princ "\nCoordinate: RMR-CLASH, RMR-ROOF, RMR-RAIL, RMR-WINDOWSCHED, RMR-ZONE")
  (princ "\nFix:    RMR-BLKSWAP, RMR-RENUMBER, RMR-TEXTALIGN, RMR-INFO, RMR-ORIENT")
  (princ "\nSpec:   RMR-SPECNOTE, RMR-SPECINDEX, RMR-ABBREV, RMR-REVLIB")
  (princ "\nDocs:   RMR-ROOMSCHED, RMR-DOCLIST, RMR-SHEETINDEX, RMR-COVER")
  (princ "\nSet:    RMR-CHECKLIST, RMR-DOCSHEET")
  (princ "\nPresent: RMR-AXO, RMR-ROOMVIEW, RMR-BUILDUP, RMR-SWATCH")
  (princ "\nBoards: RMR-COLOURBOARD, RMR-MOODBOARD, RMR-BRANDING")
  (princ "\nCharts: RMR-AREACHART, RMR-PROGRAMME, RMR-PRESENTSHEET")
  (princ "\nMeasure: RMR-SURVEY, RMR-MEASURE, RMR-QUANTITY, RMR-RATES")
  (princ "\nCost:   RMR-COSTPLAN, RMR-PERQM, RMR-CASHFLOW, RMR-QSREPORT")
  (princ "\nAuto:   RMR-ALIAS, RMR-TOOLPALETTE, RMR-AUTO, RMR-BATCH")
  (princ "\nStruct: RMR-COLUMN, RMR-BEAM, RMR-FOUNDATION, RMR-REBAR")
  (princ "\nStruct: RMR-SLABPANEL, RMR-SETOUT, RMR-STRUCTSCHED")
  (princ "\nMEP:    RMR-DUCT, RMR-PIPE, RMR-TRAY, RMR-CLEARANCE")
  (princ "\nMEP:    RMR-LIGHTING, RMR-SPRINKLER, RMR-MEPSCHED")
  (princ "\nDetail: RMR-DETAILLIB, RMR-JUNCTION, RMR-DETAILTAG, RMR-MATKEY")
  (princ "\nDetail: RMR-DETSCALE, RMR-DETSHEET, RMR-UVALUE, RMR-CHECKDETAIL")
  (princ)
)

;;; -----------------------------------------------------------------------------
;;; Layer selection by group
;;; -----------------------------------------------------------------------------

(defun RMR:PrintGroupLayers (group / prefix spec)
  (setq prefix (RMR:GroupPrefix group))
  (princ (strcat "\n" group " (" prefix "):"))
  (foreach spec *RMR-LAYER-SPECS*
    (if (= (strcase (nth 1 spec)) (strcase group))
      (princ (strcat "\n  " (nth 0 spec) " - " (nth 5 spec)))
    )
  )
)

(defun C:RMR-SETLAYER (/ group name found spec)
  (if (not (tblsearch "LAYER" "RMR-M-WALL"))
    (C:RMR-MASTER)
  )
  (initget "Main Furniture Structural Plumbing Annotation Presentation Control")
  (setq group (getkword "\nDiscipline [Main/Furniture/Structural/Plumbing/Annotation/Presentation/Control] <Main>: "))
  (if (not group) (setq group "Main"))
  (setq group
    (cond
      ((= (strcase group) "MAIN") "MAIN THEME")
      ((= (strcase group) "FURNITURE") "FURNITURE")
      ((= (strcase group) "STRUCTURAL") "STRUCTURAL")
      ((= (strcase group) "PLUMBING") "PLUMBING")
      ((= (strcase group) "ANNOTATION") "ANNOTATION")
      ((= (strcase group) "PRESENTATION") "PRESENTATION")
      (T "CONTROL")
    )
  )
  (RMR:PrintGroupLayers group)
  (setq name (getstring T "\nEnter exact layer name (press Enter to keep current): "))
  (if (= name "")
    (princ (strcat "\nCurrent layer remains: " (getvar "CLAYER")))
    (progn
      (foreach spec *RMR-LAYER-SPECS*
        (if (= (strcase name) (strcase (nth 0 spec)))
          (setq found (nth 0 spec))
        )
      )
      (if found
        (progn
          (setvar "CLAYER" found)
          (princ (strcat "\nCurrent layer: " found))
        )
        (princ "\nThat layer is not in the RooMNRooF standard.")
      )
    )
  )
  (princ)
)

;;; -----------------------------------------------------------------------------
;;; Palette legend
;;; -----------------------------------------------------------------------------

(defun C:RMR-LEGEND (/ base x y row group spec first item rgb layername)
  (if (not (tblsearch "LAYER" "RMR-M-WALL"))
    (C:RMR-MASTER)
  )
  (setq base (getpoint "\nPick lower-left point for RooMNRooF colour legend: "))
  (if base
    (progn
      (setq x (car base))
      (setq y (cadr base))
      (RMR:Text (RMR:PT+ base 0.0 10.0) "RooMNRooF" 6.0 "RMR-TITLE" "RMR-PRES-TITLE" *RMR-BRAND-TERRA*)
      (RMR:Text (RMR:PT+ base 0.0 4.0) "CONSULTANT 2D COLOUR STANDARD" 2.5 "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-INK*)
      (RMR:Line (RMR:PT+ base 0.0 1.5) (RMR:PT+ base 260.0 1.5) "RMR-A-FRAME" *RMR-BRAND-TEAL*)
      (setq y (- y 6.0))
      (foreach group '("CONTROL" "MAIN THEME" "FURNITURE" "STRUCTURAL" "PLUMBING" "ANNOTATION" "PRESENTATION")
        (setq first T)
        (foreach spec *RMR-LAYER-SPECS*
          (if (= (strcase (nth 1 spec)) group)
            (progn
              (if first
                (progn
                  (RMR:Text (list x y 0.0) group 3.0 "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-INK*)
                  (setq y (- y 5.0))
                  (setq first nil)
                )
              )
              (setq rgb (nth 2 spec))
              (setq layername (nth 0 spec))
              (RMR:Solid (list x y 0.0) 6.0 3.5 "RMR-A-TEXT" rgb)
              (RMR:Text (list (+ x 9.0) (+ y 0.3) 0.0) layername 2.5 "RMR-BODY" "RMR-A-TEXT" *RMR-BRAND-INK*)
              (RMR:Text (list (+ x 78.0) (+ y 0.3) 0.0) (nth 5 spec) 2.5 "RMR-NOTE" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
              (setq y (- y 5.0))
            )
          )
        )
        (setq y (- y 2.0))
      )
      (RMR:Text (list x (- y 1.0) 0.0) "RGB true-colour layers | metric | lineweights in mm" 2.2 "RMR-NOTE" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
      (princ "\nRooMNRooF colour legend created.")
    )
  )
  (princ)
)

;;; -----------------------------------------------------------------------------
;;; Sheet frame and title block
;;; -----------------------------------------------------------------------------

(defun RMR:SheetSize (size)
  (cond
    ((= size "A0") '(1189.0 841.0))
    ((= size "A1") '(841.0 594.0))
    ((= size "A2") '(594.0 420.0))
    ((= size "A3") '(420.0 297.0))
    (T '(297.0 210.0))
  )
)

(defun RMR:TitleCell (p width height label value / y)
  (RMR:Rect p width height "RMR-A-FRAME" *RMR-BRAND-INK*)
  (setq y (+ (cadr p) (/ height 2.0)))
  (RMR:Text (RMR:PT+ p 2.0 (+ (/ height 2.0) 0.7)) label 1.8 "RMR-NOTE" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
  (RMR:Text (RMR:PT+ p 2.0 (- (/ height 2.0) 2.8)) value 2.5 "RMR-BODY" "RMR-A-TEXT" *RMR-BRAND-INK*)
)

(defun RMR:DrawTitleBlock (p width height scale / tw th x y colw)
  ;; p is lower-left corner of the title block.
  (setq tw (* 190.0 scale))
  (setq th (* 50.0 scale))
  (RMR:Rect p tw th "RMR-A-FRAME" *RMR-BRAND-INK*)
  ;; Brand strip
  (RMR:Solid p (* 42.0 scale) th "RMR-PRES-TITLE" *RMR-BRAND-TERRA*)
  (RMR:Text (RMR:PT+ p (* 4.0 scale) (* 34.0 scale)) "RooMNRooF" (* 5.0 scale) "RMR-TITLE" "RMR-PRES-TITLE" *RMR-BRAND-SAND*)
  (RMR:Text (RMR:PT+ p (* 4.0 scale) (* 26.0 scale)) "CONSULTANT" (* 2.4 scale) "RMR-HEAD" "RMR-PRES-TITLE" *RMR-BRAND-SAND*)
  (RMR:Text (RMR:PT+ p (* 4.0 scale) (* 20.0 scale)) "2D CAD STANDARD" (* 1.8 scale) "RMR-NOTE" "RMR-PRES-TITLE" *RMR-BRAND-SAND*)
  (RMR:Line (RMR:PT+ p (* 4.0 scale) (* 14.0 scale)) (RMR:PT+ p (* 37.0 scale) (* 14.0 scale)) "RMR-PRES-TITLE" *RMR-BRAND-GOLD*)
  (RMR:Text (RMR:PT+ p (* 4.0 scale) (* 9.0 scale)) "ROOF THE ROOM" (* 1.8 scale) "RMR-NOTE" "RMR-PRES-TITLE" *RMR-BRAND-SAND*)
  ;; Information field area
  (setq x (+ (car p) (* 42.0 scale)))
  (setq y (cadr p))
  (setq colw (* 74.0 scale))
  (RMR:TitleCell (list x (+ y (* 35.0 scale)) 0.0) colw (* 15.0 scale) "PROJECT" "PROJECT NAME")
  (RMR:TitleCell (list x (+ y (* 20.0 scale)) 0.0) colw (* 15.0 scale) "DRAWING TITLE" "DRAWING TITLE")
  (RMR:TitleCell (list x y 0.0) (* 37.0 scale) (* 20.0 scale) "DRAWN BY" "NAME")
  (RMR:TitleCell (list (+ x (* 37.0 scale)) y 0.0) (* 37.0 scale) (* 20.0 scale) "CHECKED BY" "NAME")
  (RMR:TitleCell (list (+ x (* 74.0 scale)) y 0.0) (* 37.0 scale) (* 20.0 scale) "DATE" "YYYY-MM-DD")
  ;; Right-hand drawing control area
  (setq x (+ x colw))
  (RMR:TitleCell (list x (+ y (* 35.0 scale)) 0.0) (* 37.0 scale) (* 15.0 scale) "DRAWING NO." "A-101")
  (RMR:TitleCell (list x (+ y (* 20.0 scale)) 0.0) (* 37.0 scale) (* 15.0 scale) "SCALE" "1:100")
  (RMR:TitleCell (list x y 0.0) (* 37.0 scale) (* 20.0 scale) "REVISION" "00")
  ;; small registration marks / accent
  (setq colw (* 4.0 scale))
  (RMR:Solid (RMR:PT+ p (* 182.0 scale) (* 44.0 scale)) colw colw "RMR-PRES-NORTH" *RMR-BRAND-TEAL*)
  (RMR:Solid (RMR:PT+ p (* 182.0 scale) (* 38.0 scale)) colw colw "RMR-PRES-KEY" *RMR-BRAND-GOLD*)
)

(defun C:RMR-SHEET (/ size dims scale base w h outer inset titlep)
  (if (not (tblsearch "LAYER" "RMR-M-WALL"))
    (C:RMR-MASTER)
  )
  (initget "A0 A1 A2 A3 A4")
  (setq size (getkword "\nSheet size [A0/A1/A2/A3/A4] <A1>: "))
  (if (not size) (setq size "A1"))
  (setq dims (RMR:SheetSize size))
  (setq scale (getreal "\nSheet scale factor <1.0>: "))
  (if (or (not scale) (<= scale 0.0)) (setq scale 1.0))
  (setq base (getpoint "\nPick lower-left sheet point: "))
  (if base
    (progn
      (setq w (* (car dims) scale))
      (setq h (* (cadr dims) scale))
      (setq outer (list (car base) (cadr base) 0.0))
      (setq inset (* 10.0 scale))
      (RMR:Rect outer w h "RMR-A-FRAME" *RMR-BRAND-INK*)
      (RMR:Rect (RMR:PT+ outer inset inset) (- w (* 2.0 inset)) (- h (* 2.0 inset)) "RMR-A-FRAME" *RMR-BRAND-TEAL*)
      ;; Title block is anchored at lower-right, inside the inner frame.
      (setq titlep (RMR:PT+ outer (- w (* 10.0 scale) (* 190.0 scale)) (* 10.0 scale)))
      (RMR:DrawTitleBlock titlep 190.0 50.0 scale)
      (RMR:Text (RMR:PT+ outer (* 10.0 scale) (- h (* 8.0 scale))) size (* 2.5 scale) "RMR-HEAD" "RMR-PRES-TITLE" *RMR-BRAND-TERRA*)
      (princ (strcat "\n" size " RooMNRooF sheet and title block created."))
    )
  )
  (princ)
)

;;; -----------------------------------------------------------------------------
;;; Advanced annotation commands
;;; -----------------------------------------------------------------------------

(defun RMR:EnsureReady ()
  (if (not (tblsearch "LAYER" "RMR-M-WALL"))
    (C:RMR-MASTER)
  )
  T
)

(defun RMR:PlaceBlock (block layer / point scale oldlayer oldecho)
  (RMR:EnsureReady)
  (setq point (getpoint (strcat "\nPick insertion point for " block ": ")))
  (if point
    (progn
      (setq scale (RMR:PromptReal "Symbol scale" (RMR:Scaled 1.0)))
      (setq oldlayer (getvar "CLAYER"))
      (setq oldecho (getvar "CMDECHO"))
      (setvar "CMDECHO" 0)
      (setvar "CLAYER" layer)
      (command "_.-insert" block point scale scale 0.0)
      (setvar "CLAYER" oldlayer)
      (setvar "CMDECHO" oldecho)
      (princ (strcat "\n" block " placed."))
    )
  )
  (princ)
)

(defun C:RMR-PRO-SETUP (/ old-refresh)
  (setq old-refresh *RMR-FORCE-STYLE-REFRESH*)
  (setq *RMR-FORCE-STYLE-REFRESH* T)
  (C:RMR-MASTER)
  (setq *RMR-FORCE-STYLE-REFRESH* old-refresh)
  (princ "\nRooMNRooF PRO setup complete: modern fonts, MLeader style, symbol library and annotation layers ready.")
  (princ "\nAnnotate with RMR-NORTH, RMR-ROOMTAG, RMR-AREA, RMR-KEYNOTE, RMR-DETAIL, RMR-LEVEL and RMR-REVISION.")
  (princ "\nProduce sheets with RMR-GRID, RMR-HATCH, RMR-STAMP, RMR-REVTABLE, RMR-NOTES, RMR-SCALEBAR and RMR-KEYPLAN.")
  (princ "\nFinish with RMR-SCALE, RMR-CHECK, RMR-PAGESETUP, RMR-PUBLISH and RMR-SAVE-TEMPLATE.")
  (princ)
)

(defun C:RMR-NORTH ()
  (RMR:PlaceBlock "RMR-NORTH-ARROW" "RMR-PRES-NORTH")
)

(defun C:RMR-ROOMTAG (/ point number room area width height layer s)
  (RMR:EnsureReady)
  (setq s (RMR:Scaled 1.0))
  (setq point (getpoint "\nPick lower-left point for room tag: "))
  (if point
    (progn
      (setq number (RMR:PromptText "Room number" "01"))
      (setq room (strcase (RMR:PromptText "Room name" "ROOM NAME")))
      (setq area (RMR:PromptText "Area text" "00.00 m2"))
      (setq width (RMR:PromptReal "Tag width" (* 70.0 s)))
      (setq height (RMR:PromptReal "Tag height" (* 24.0 s)))
      (setq layer "RMR-A-ROOMTAG")
      (RMR:Rect point width height layer *RMR-BRAND-INK*)
      (RMR:Solid point (* 4.0 s) height "RMR-PRES-TITLE" *RMR-BRAND-TERRA*)
      (RMR:Line (RMR:PT+ point (* 4.0 s) (* height 0.55)) (RMR:PT+ point width (* height 0.55)) layer *RMR-BRAND-TEAL*)
      (RMR:Text (RMR:PT+ point (* 8.0 s) (- height (* 5.5 s))) number (* 4.0 s) "RMR-NUMBER" layer *RMR-BRAND-TERRA*)
      (RMR:Text (RMR:PT+ point (* 8.0 s) (* height 0.30)) room (* 3.0 s) "RMR-LABEL" layer *RMR-BRAND-INK*)
      (RMR:Text (RMR:PT+ point (* 8.0 s) (* 3.0 s)) area (* 2.5 s) "RMR-NOTE" layer *RMR-BRAND-SLATE*)
      (princ "\nRooMNRooF room tag created. Use RMR-AREA to measure and schedule rooms.")
    )
  )
  (princ)
)

(defun C:RMR-KEYNOTE (/ point number radius s)
  (RMR:EnsureReady)
  (setq s (RMR:Scaled 1.0))
  (setq point (getpoint "\nPick keynote bubble centre: "))
  (if point
    (progn
      (setq number (RMR:PromptText "Keynote number" "01"))
      (setq radius (RMR:PromptReal "Bubble radius" (* 5.0 s)))
      (RMR:Circle point radius "RMR-A-KEYNOTE" *RMR-BRAND-GOLD*)
      (RMR:CenterText point number (* radius 0.65) "RMR-NUMBER" "RMR-A-KEYNOTE" *RMR-BRAND-INK*)
      (princ "\nRooMNRooF keynote bubble created.")
    )
  )
  (princ)
)

(defun C:RMR-DETAIL (/ point detail sheet radius start end s)
  (RMR:EnsureReady)
  (setq s (RMR:Scaled 1.0))
  (setq point (getpoint "\nPick detail bubble centre: "))
  (if point
    (progn
      (setq detail (RMR:PromptText "Detail number" "A"))
      (setq sheet (RMR:PromptText "Reference sheet" "A-501"))
      (setq radius (RMR:PromptReal "Bubble radius" (* 6.0 s)))
      (setq start (RMR:PT+ point radius 0.0))
      (setq end (RMR:PT+ point (* 32.0 s) 0.0))
      (RMR:Circle point radius "RMR-A-DETAIL" *RMR-BRAND-SLATE*)
      (RMR:Line start end "RMR-A-DETAIL" *RMR-BRAND-SLATE*)
      (RMR:CenterText point detail (* radius 0.7) "RMR-NUMBER" "RMR-A-DETAIL" *RMR-BRAND-INK*)
      (RMR:Text (RMR:PT+ point (+ radius (* 3.0 s)) (* 1.5 s)) sheet (* 2.5 s) "RMR-NOTE" "RMR-A-DETAIL" *RMR-BRAND-SLATE*)
      (princ "\nRooMNRooF detail callout created.")
    )
  )
  (princ)
)

(defun C:RMR-LEVEL (/ point level length s)
  (RMR:EnsureReady)
  (setq s (RMR:Scaled 1.0))
  (setq point (getpoint "\nPick level datum point: "))
  (if point
    (progn
      (setq level (RMR:PromptText "Level text" "+0.000"))
      (setq length (RMR:PromptReal "Datum length" (* 38.0 s)))
      (RMR:Line point (RMR:PT+ point length 0.0) "RMR-A-LEVEL" *RMR-BRAND-TEAL*)
      (RMR:Triangle point (* 6.0 s) "RMR-A-LEVEL" *RMR-BRAND-TEAL*)
      (RMR:Text (RMR:PT+ point (* 9.0 s) (* 2.0 s)) level (* 3.0 s) "RMR-NUMBER" "RMR-A-LEVEL" *RMR-BRAND-INK*)
      (princ "\nRooMNRooF level datum created.")
    )
  )
  (princ)
)

(defun C:RMR-REVISION (/ point number text size p1 p2 p3 s)
  (RMR:EnsureReady)
  (setq s (RMR:Scaled 1.0))
  (setq point (getpoint "\nPick revision marker point: "))
  (if point
    (progn
      (setq number (RMR:PromptText "Revision number" "00"))
      (setq text (RMR:PromptText "Revision description" "ISSUED FOR REVIEW"))
      (setq size (RMR:PromptReal "Triangle size" (* 8.0 s)))
      (setq p1 (RMR:3D point))
      (setq p2 (RMR:PT+ point size 0.0))
      (setq p3 (RMR:PT+ point (/ size 2.0) size))
      (RMR:Line p1 p2 "RMR-A-REVISION" *RMR-BRAND-TERRA*)
      (RMR:Line p2 p3 "RMR-A-REVISION" *RMR-BRAND-TERRA*)
      (RMR:Line p3 p1 "RMR-A-REVISION" *RMR-BRAND-TERRA*)
      (RMR:CenterText (RMR:PT+ point (/ size 2.0) (* size 0.36)) number (* size 0.34) "RMR-NUMBER" "RMR-A-REVISION" *RMR-BRAND-TERRA*)
      (RMR:Text (RMR:PT+ point (+ size (* 3.0 s)) (* 2.0 s)) text (* 2.5 s) "RMR-NOTE" "RMR-A-REVISION" *RMR-BRAND-INK*)
      (princ "\nRooMNRooF revision marker created.")
    )
  )
  (princ)
)

(defun C:RMR-MLEADER (/ point end text oldlayer oldecho)
  (RMR:EnsureReady)
  (setq point (getpoint "\nPick multileader arrow point: "))
  (if point
    (progn
      (setq end (getpoint point "\nPick multileader landing point: "))
      (if end
        (progn
          (setq text (getstring T "\nLeader note: "))
          (if (or (not text) (= text "")) (setq text "NOTE"))
          (setq oldlayer (getvar "CLAYER"))
          (setq oldecho (getvar "CMDECHO"))
          (setvar "CMDECHO" 0)
          (setvar "CLAYER" "RMR-A-LEADER")
          (if (tblsearch "MLEADERSTYLE" "RMR-MLEADER")
            (setvar "CMLEADERSTYLE" "RMR-MLEADER")
          )
          (command "_.mleader" point end "" text)
          (setvar "CLAYER" oldlayer)
          (setvar "CMDECHO" oldecho)
          (princ "\nRooMNRooF multileader created.")
        )
      )
    )
  )
  (princ)
)

;;; -----------------------------------------------------------------------------
;;; PRODUCTION SUITE COMMANDS
;;; Scale, grids, areas, schedules, hatches, stamps, notes, quality checks,
;;; palette exchange, layer groups, page setup and publish lists.
;;; -----------------------------------------------------------------------------

(defun C:RMR-SCALE (/ keyword spec label denom space factor applied)
  (setq keyword (RMR:PromptKeyword "Drawing scale 1:" (RMR:KeywordList *RMR-SCALE-SPECS*) "100"))
  (setq spec (RMR:TableSpec keyword *RMR-SCALE-SPECS*))
  (if spec
    (progn
      (setq label (nth 1 spec))
      (setq denom (nth 2 spec))
      (setq space (RMR:PromptKeyword "Annotate in" "Model Layout" *RMR-ANNO-SPACE*))
      (setq *RMR-ANNO-SPACE* (strcase space))
      (setq *RMR-DRAW-SCALE-LABEL* label)
      (if (= *RMR-ANNO-SPACE* "MODEL")
        (setq factor (if denom denom 100.0))
        (setq factor 1.0)
      )
      (setq *RMR-ANNO-SCALE* factor)
      (RMR:SafeSet "DIMSCALE" (if (= *RMR-ANNO-SPACE* "MODEL") (if denom denom 100.0) 1.0))
      (RMR:SafeSet "CELTSCALE" 1.0)
      (RMR:SafeSet "MSLTSCALE" 1)
      (RMR:SafeSet "PSLTSCALE" 1)
      (RMR:SafeSet "LTSCALE" 1.0)
      (princ (strcat "\nRooMNRooF scale: " label " | annotation space " *RMR-ANNO-SPACE*
                     " | symbol factor " (RMR:Num factor 2)))
      (princ (strcat "\nDIMSCALE = " (RMR:Num (getvar "DIMSCALE") 2)
                     " | MSLTSCALE = " (itoa (getvar "MSLTSCALE"))))
      (princ "\nNew room tags, grids, bubbles, notes, stamps and bars use this size.")
      (princ "\nExisting annotation keeps its size - redraw it if you change the sheet scale.")
      (setq applied T)
    )
  )
  (if (not applied) (princ "\nScale not changed."))
  (princ)
)

(defun C:RMR-GRID (/ base nx ny dx dy diameter radius both index x y label)
  (RMR:EnsureReady)
  (setq base (getpoint "\nPick the lower-left grid origin: "))
  (if base
    (progn
      (setq nx (RMR:PromptInt "Number of bays along X" 4))
      (setq dx (RMR:PromptReal "Bay spacing along X" 4000.0))
      (setq ny (RMR:PromptInt "Number of bays along Y" 3))
      (setq dy (RMR:PromptReal "Bay spacing along Y" 4000.0))
      (setq diameter (RMR:PromptReal "Grid bubble diameter" (* *RMR-GRID-DIAMETER* (RMR:Scaled 1.0))))
      (setq radius (/ diameter 2.0))
      (setq both (RMR:YesP (RMR:PromptYesNo "Label both ends of every grid line" "Yes")))
      (setq index 0)
      (while (<= index nx)
        (setq x (+ (car base) (* index dx)))
        (setq label (RMR:GridLabel (1+ index)))
        (RMR:Line (list x (cadr base) 0.0)
                  (list x (+ (cadr base) (* ny dy)) 0.0)
                  "RMR-A-GRID" *RMR-BRAND-SLATE*)
        (RMR:GridBubble (list x (- (cadr base) radius) 0.0) label radius)
        (if both
          (RMR:GridBubble (list x (+ (cadr base) (* ny dy) radius) 0.0) label radius)
        )
        (setq index (1+ index))
      )
      (setq index 0)
      (while (<= index ny)
        (setq y (+ (cadr base) (* index dy)))
        (setq label (RMR:NumPad2 (1+ index)))
        (RMR:Line (list (car base) y 0.0)
                  (list (+ (car base) (* nx dx)) y 0.0)
                  "RMR-A-GRID" *RMR-BRAND-SLATE*)
        (RMR:GridBubble (list (- (car base) radius) y 0.0) label radius)
        (if both
          (RMR:GridBubble (list (+ (car base) (* nx dx) radius) y 0.0) label radius)
        )
        (setq index (1+ index))
      )
      (princ (strcat "\nRooMNRooF structural grid created: "
                     (itoa (1+ nx)) " letter lines x " (itoa (1+ ny)) " number lines."))
    )
  )
  (princ)
)

(defun RMR:DrawAreaTable (rows total / base s text colw width rowh y top row)
  (setq base (getpoint "\nPick the upper-left point of the room schedule table: "))
  (if base
    (progn
      (setq s (RMR:Scaled 1.0))
      (setq text (* 2.8 s))
      (setq colw (list (* 16.0 s) (* 54.0 s) (* 24.0 s) (* 24.0 s)))
      (setq width (+ (nth 0 colw) (nth 1 colw) (nth 2 colw) (nth 3 colw)))
      (setq rowh (* 8.0 s))
      (RMR:Text base "ROOM AREA SCHEDULE" (* 4.5 s) "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-TERRA*)
      (RMR:Text (RMR:PT+ base 0.0 (- (* 5.5 s)))
                (strcat "SCALE " *RMR-DRAW-SCALE-LABEL* "   |   AREAS IN SQUARE METRES")
                (* 2.2 s) "RMR-NOTE" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
      (setq y (- (cadr base) (* 13.0 s)))
      (setq top y)
      (RMR:Solid (list (car base) (- y rowh) 0.0) width rowh "RMR-PRES-TITLE" *RMR-BRAND-SAND*)
      (RMR:Text (RMR:PT+ (list (car base) (- y rowh) 0.0) (* 2.0 s) (* 2.2 s)) "NO." text "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-INK*)
      (RMR:Text (RMR:PT+ (list (+ (car base) (nth 0 colw)) (- y rowh) 0.0) (* 2.0 s) (* 2.2 s)) "ROOM" text "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-INK*)
      (RMR:Text (RMR:PT+ (list (+ (car base) (nth 0 colw) (nth 1 colw)) (- y rowh) 0.0) (* 2.0 s) (* 2.2 s)) "AREA m2" text "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-INK*)
      (RMR:Text (RMR:PT+ (list (+ (car base) (nth 0 colw) (nth 1 colw) (nth 2 colw)) (- y rowh) 0.0) (* 2.0 s) (* 2.2 s)) "AREA ft2" text "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-INK*)
      (RMR:TableDividers (car base) (- y rowh) colw rowh "RMR-A-FRAME" *RMR-BRAND-INK*)
      (setq y (- y rowh))
      (foreach row rows
        (RMR:Rect (list (car base) (- y rowh) 0.0) width rowh "RMR-A-FRAME" *RMR-BRAND-SLATE*)
        (RMR:TableDividers (car base) (- y rowh) colw rowh "RMR-A-FRAME" *RMR-BRAND-SLATE*)
        (RMR:Text (RMR:PT+ (list (car base) (- y rowh) 0.0) (* 2.0 s) (* 2.2 s)) (nth 0 row) text "RMR-NUMBER" "RMR-A-TEXT" *RMR-BRAND-TERRA*)
        (RMR:Text (RMR:PT+ (list (+ (car base) (nth 0 colw)) (- y rowh) 0.0) (* 2.0 s) (* 2.2 s)) (nth 1 row) text "RMR-LABEL" "RMR-A-TEXT" *RMR-BRAND-INK*)
        (RMR:Text (RMR:PT+ (list (+ (car base) (nth 0 colw) (nth 1 colw)) (- y rowh) 0.0) (* 2.0 s) (* 2.2 s)) (RMR:Num (nth 2 row) 2) text "RMR-BODY" "RMR-A-TEXT" *RMR-BRAND-INK*)
        (RMR:Text (RMR:PT+ (list (+ (car base) (nth 0 colw) (nth 1 colw) (nth 2 colw)) (- y rowh) 0.0) (* 2.0 s) (* 2.2 s)) (RMR:Num (nth 3 row) 1) text "RMR-BODY" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
        (setq y (- y rowh))
      )
      (RMR:Solid (list (car base) (- y rowh) 0.0) width rowh "RMR-PRES-TITLE" *RMR-BRAND-TERRA*)
      (RMR:Text (RMR:PT+ (list (+ (car base) (nth 0 colw)) (- y rowh) 0.0) (* 2.0 s) (* 2.2 s)) "TOTAL" text "RMR-HEAD" "RMR-PRES-TITLE" *RMR-BRAND-SAND*)
      (RMR:Text (RMR:PT+ (list (+ (car base) (nth 0 colw) (nth 1 colw)) (- y rowh) 0.0) (* 2.0 s) (* 2.2 s)) (RMR:Num total 2) text "RMR-NUMBER" "RMR-PRES-TITLE" *RMR-BRAND-SAND*)
      (RMR:Text (RMR:PT+ (list (+ (car base) (nth 0 colw) (nth 1 colw) (nth 2 colw)) (- y rowh) 0.0) (* 2.0 s) (* 2.2 s)) (RMR:Num (* total *RMR-SQFT-PER-SQM*) 1) text "RMR-NUMBER" "RMR-PRES-TITLE" *RMR-BRAND-SAND*)
      (setq y (- y rowh))
      (RMR:Rect (list (car base) y 0.0) width (- top y) "RMR-A-FRAME" *RMR-BRAND-INK*)
      (princ (strcat "\nRoom schedule placed with " (itoa (length rows)) " rows."))
    )
  )
)

(defun C:RMR-AREA (/ selection ename area sqm sqft number name rows total)
  (RMR:EnsureReady)
  (princ "\nMeasure closed room boundaries and build a RooMNRooF area schedule.")
  (setq rows '())
  (setq total 0.0)
  (setq selection T)
  (while selection
    (setq ename (car (entsel "\nPick a closed room boundary (Enter to finish): ")))
    (if ename
      (progn
        (setq area (RMR:EntityArea ename))
        (if area
          (progn
            (setq sqm (RMR:AreaToSqm area))
            (setq sqft (* sqm *RMR-SQFT-PER-SQM*))
            (setq number (RMR:PromptText "Room number" (RMR:NumPad2 (1+ (length rows)))))
            (setq name (strcase (RMR:PromptText "Room name" "ROOM")))
            (setq rows (append rows (list (list number name sqm sqft))))
            (setq total (+ total sqm))
            (princ (strcat "\n  " number " " name " = " (RMR:Num sqm 2) " m2 / " (RMR:Num sqft 1) " sq.ft"))
          )
          (princ "\n  No area property. Pick a closed polyline, circle, region or hatch.")
        )
      )
      (setq selection nil)
    )
  )
  (if rows
    (progn
      (princ (strcat "\nRooms measured: " (itoa (length rows))
                     "  |  Total: " (RMR:Num total 2) " m2 / "
                     (RMR:Num (* total *RMR-SQFT-PER-SQM*) 1) " sq.ft"))
      (if (RMR:YesP (RMR:PromptYesNo "Place the room schedule table" "Yes"))
        (RMR:DrawAreaTable rows total)
      )
    )
    (princ "\nNo rooms were measured.")
  )
  (princ)
)

(defun C:RMR-STAMP (/ keyword spec label rgb point width height factor angle radians revision date corner inner offset text)
  (RMR:EnsureReady)
  (setq keyword (RMR:PromptKeyword "Stamp type" (RMR:KeywordList *RMR-STAMP-SPECS*) "IFR"))
  (setq spec (RMR:TableSpec keyword *RMR-STAMP-SPECS*))
  (if spec
    (progn
      (setq label (nth 1 spec))
      (setq rgb (nth 2 spec))
      (setq factor (RMR:Scaled 1.0))
      (setq point (getpoint "\nPick the stamp centre point: "))
      (if point
        (progn
          (setq width (RMR:PromptReal "Stamp width" (* 96.0 factor)))
          (setq height (RMR:PromptReal "Stamp height" (* 26.0 factor)))
          (setq angle (RMR:PromptAngle "Stamp rotation" 0.0))
          (setq radians (* angle (/ pi 180.0)))
          (setq revision (RMR:PromptText "Revision" "00"))
          (setq date (RMR:PromptText "Date" (RMR:TodayDate)))
          (setq offset (* 1.8 factor))
          (setq corner (RMR:Polar (RMR:Polar point (+ radians pi) (/ width 2.0))
                                  (- radians (/ pi 2.0)) (/ height 2.0)))
          (RMR:RotRect corner width height "RMR-PRES-STAMP" rgb radians)
          (setq inner (RMR:Polar (RMR:Polar corner radians offset) (+ radians (/ pi 2.0)) offset))
          (RMR:RotRect inner (- width (* 2.0 offset)) (- height (* 2.0 offset)) "RMR-PRES-STAMP" rgb radians)
          (setq text (* 4.6 factor))
          ;; Auto-fit long labels such as ISSUED FOR CONSTRUCTION inside the box.
          (if (> (* (strlen label) text 0.62) (- width (* 16.0 factor)))
            (setq text (/ (- width (* 16.0 factor)) (* (strlen label) 0.62)))
          )
          (RMR:RotText point label text "RMR-HEAD" "RMR-PRES-STAMP" rgb radians)
          (RMR:RotText (RMR:Polar point (+ radians (/ pi 2.0)) (* 7.6 factor))
                       (strcat "REV " revision) (* 2.4 factor) "RMR-NOTE" "RMR-PRES-STAMP" rgb radians)
          (RMR:RotText (RMR:Polar point (- radians (/ pi 2.0)) (* 7.6 factor))
                       date (* 2.4 factor) "RMR-NOTE" "RMR-PRES-STAMP" rgb radians)
          (RMR:RotText (RMR:Polar (RMR:Polar corner radians (* 4.0 factor)) (+ radians (/ pi 2.0)) (* height 0.5))
                       "RooMNRooF" (* 2.2 factor) "RMR-MARK" "RMR-PRES-STAMP" rgb radians)
          (princ (strcat "\nRooMNRooF stamp placed: " label))
        )
      )
    )
  )
  (princ)
)

(defun C:RMR-REVTABLE (/ point rows s text height colw width rowh y top bottom index)
  (RMR:EnsureReady)
  (setq point (getpoint "\nPick the upper-left point of the revision table: "))
  (if point
    (progn
      (setq rows (RMR:PromptInt "Number of revision rows" 5))
      (setq s (RMR:Scaled 1.0))
      (setq text (* 2.6 s))
      (setq colw (list (* 14.0 s) (* 26.0 s) (* 80.0 s) (* 20.0 s) (* 20.0 s)))
      (setq width (+ (nth 0 colw) (nth 1 colw) (nth 2 colw) (nth 3 colw) (nth 4 colw)))
      (setq rowh (* 8.0 s))
      (RMR:Text point "REVISION HISTORY" (* 4.2 s) "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-TERRA*)
      (RMR:Line (RMR:PT+ point 0.0 (- (* 3.0 s))) (RMR:PT+ point width (- (* 3.0 s))) "RMR-A-TEXT" *RMR-BRAND-GOLD*)
      (setq y (- (cadr point) (* 11.0 s)))
      (setq top y)
      (RMR:Solid (list (car point) (- y rowh) 0.0) width rowh "RMR-PRES-TITLE" *RMR-BRAND-SAND*)
      (RMR:Text (RMR:PT+ (list (car point) (- y rowh) 0.0) (* 2.0 s) (* 2.2 s)) "REV" text "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-INK*)
      (RMR:Text (RMR:PT+ (list (+ (car point) (nth 0 colw)) (- y rowh) 0.0) (* 2.0 s) (* 2.2 s)) "DATE" text "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-INK*)
      (RMR:Text (RMR:PT+ (list (+ (car point) (nth 0 colw) (nth 1 colw)) (- y rowh) 0.0) (* 2.0 s) (* 2.2 s)) "DESCRIPTION" text "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-INK*)
      (RMR:Text (RMR:PT+ (list (+ (car point) (nth 0 colw) (nth 1 colw) (nth 2 colw)) (- y rowh) 0.0) (* 2.0 s) (* 2.2 s)) "BY" text "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-INK*)
      (RMR:Text (RMR:PT+ (list (+ (car point) (nth 0 colw) (nth 1 colw) (nth 2 colw) (nth 3 colw)) (- y rowh) 0.0) (* 2.0 s) (* 2.2 s)) "CHK" text "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-INK*)
      (RMR:TableDividers (car point) (- y rowh) colw rowh "RMR-A-FRAME" *RMR-BRAND-INK*)
      (setq y (- y rowh))
      (setq index 0)
      (while (< index rows)
        (RMR:Rect (list (car point) (- y rowh) 0.0) width rowh "RMR-A-FRAME" *RMR-BRAND-SLATE*)
        (RMR:TableDividers (car point) (- y rowh) colw rowh "RMR-A-FRAME" *RMR-BRAND-SLATE*)
        (RMR:Text (RMR:PT+ (list (car point) (- y rowh) 0.0) (* 2.0 s) (* 2.2 s)) (RMR:NumPad2 index) text "RMR-NUMBER" "RMR-A-REVISION" *RMR-BRAND-TERRA*)
        (setq y (- y rowh))
        (setq index (1+ index))
      )
      (setq bottom y)
      (RMR:Rect (list (car point) bottom 0.0) width (- top bottom) "RMR-A-FRAME" *RMR-BRAND-INK*)
      (princ (strcat "\nRooMNRooF revision table created with " (itoa rows) " rows."))
    )
  )
  (princ)
)

(defun C:RMR-NOTES (/ point width s body index note height heading)
  (RMR:EnsureReady)
  (setq point (getpoint "\nPick the upper-left point of the notes block: "))
  (if point
    (progn
      (setq s (RMR:Scaled 1.0))
      (setq width (RMR:PromptReal "Notes block width" (* 120.0 s)))
      (setq height (* 2.6 s))
      (setq heading "GENERAL NOTES")
      (RMR:Text point heading (* 4.2 s) "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-TERRA*)
      (RMR:Line (RMR:PT+ point 0.0 (- (* 3.0 s))) (RMR:PT+ point width (- (* 3.0 s))) "RMR-A-TEXT" *RMR-BRAND-GOLD*)
      (setq body "")
      (setq index 1)
      (foreach note *RMR-NOTES*
        (setq body (strcat body (RMR:NumPad2 index) ".   " note "\\P"))
        (setq index (1+ index))
      )
      (RMR:MText (RMR:PT+ point 0.0 (- (* 9.0 s))) body width height "RMR-NOTE" "RMR-A-TEXT" *RMR-BRAND-INK* 1)
      (princ (strcat "\nRooMNRooF general notes created: " (itoa (length *RMR-NOTES*)) " numbered notes."))
      (princ "\nEdit *RMR-NOTES* near the top of the LSP file to change the wording.")
    )
  )
  (princ)
)

(defun C:RMR-SCALEBAR (/ point segments segment bar height s index x metres text)
  (RMR:EnsureReady)
  (setq s (RMR:Scaled 1.0))
  (setq point (getpoint "\nPick the lower-left point of the graphic scale bar: "))
  (if point
    (progn
      (setq segments (RMR:PromptInt "Number of segments" 5))
      (setq segment (RMR:PromptReal "Drawing units represented by one segment" 5000.0))
      (setq bar (RMR:PromptReal "Bar height" (/ segment 8.0)))
      (setq text (* 2.6 s))
      (RMR:Line point (RMR:PT+ point (* segments segment) 0.0) "RMR-A-FRAME" *RMR-BRAND-INK*)
      (setq index 0)
      (while (< index segments)
        (setq x (+ (car point) (* index segment)))
        (if (= (rem index 2) 0)
          (RMR:Solid (list x (cadr point) 0.0) segment bar "RMR-PRES-TITLE" *RMR-BRAND-TERRA*)
          (progn
            (RMR:Solid (list x (cadr point) 0.0) segment bar "RMR-PRES-TITLE" *RMR-BRAND-SAND*)
            (RMR:Rect (list x (cadr point) 0.0) segment bar "RMR-A-FRAME" *RMR-BRAND-INK*)
          )
        )
        (setq metres (RMR:LinearToMetres (* index segment)))
        (RMR:Text (list (- x (* text 0.35)) (+ (cadr point) bar (* text 0.5)) 0.0)
                  (RMR:Num metres (if (< (abs (- metres (float (fix metres)))) 0.01) 0 1))
                  text "RMR-NUMBER" "RMR-A-TEXT" *RMR-BRAND-INK*)
        (setq index (1+ index))
      )
      (setq metres (RMR:LinearToMetres (* segments segment)))
      (RMR:Text (list (+ (car point) (* segments segment) (* text 0.4)) (+ (cadr point) bar (* text 0.5)) 0.0)
                (RMR:Num metres 0) text "RMR-NUMBER" "RMR-A-TEXT" *RMR-BRAND-TERRA*)
      (RMR:Text (RMR:PT+ point 0.0 (- (* text 1.8)))
                (strcat "METRES   |   SCALE " *RMR-DRAW-SCALE-LABEL*)
                text "RMR-NOTE" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
      (princ (strcat "\nRooMNRooF graphic scale bar created: " (itoa segments) " segments of "
                     (RMR:Num (RMR:LinearToMetres segment) 1) " m."))
    )
  )
  (princ)
)

(defun C:RMR-KEYPLAN (/ point width height s oldlayer oldecho)
  (RMR:EnsureReady)
  (setq point (getpoint "\nPick the lower-left point of the key plan box: "))
  (if point
    (progn
      (setq s (RMR:Scaled 1.0))
      (setq width (RMR:PromptReal "Key plan width" (* 62.0 s)))
      (setq height (RMR:PromptReal "Key plan height" (* 46.0 s)))
      (RMR:Rect point width height "RMR-A-FRAME" *RMR-BRAND-INK*)
      (RMR:Solid point width (* 7.5 s) "RMR-PRES-TITLE" *RMR-BRAND-TERRA*)
      (RMR:Text (RMR:PT+ point (* 2.5 s) (* 2.2 s)) "KEY PLAN" (* 3.4 s) "RMR-HEAD" "RMR-PRES-TITLE" *RMR-BRAND-SAND*)
      (RMR:Rect (RMR:PT+ point (* 2.5 s) (* 10.0 s)) (- width (* 5.0 s)) (- height (* 12.5 s)) "RMR-00-REF" *RMR-BRAND-SLATE*)
      (RMR:Text (RMR:PT+ point (* 2.5 s) (* 1.2 s)) "ADD SITE OUTLINE AND HIGHLIGHT THE PLOT" (* 2.0 s) "RMR-NOTE" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
      (if (tblsearch "BLOCK" "RMR-NORTH-ARROW")
        (progn
          (setq oldlayer (getvar "CLAYER"))
          (setq oldecho (getvar "CMDECHO"))
          (setvar "CMDECHO" 0)
          (setvar "CLAYER" "RMR-PRES-NORTH")
          (command "_.-insert" "RMR-NORTH-ARROW"
                   (RMR:PT+ point (- width (* 9.0 s)) (- height (* 9.0 s)))
                   (* 0.6 s) (* 0.6 s) 0.0)
          (setvar "CLAYER" oldlayer)
          (setvar "CMDECHO" oldecho)
        )
      )
      (princ "\nRooMNRooF key plan box created.")
    )
  )
  (princ)
)

(defun C:RMR-HATCHLIB (/ index spec)
  (princ "\n---------- RooMNRooF material hatch library ----------")
  (setq index 0)
  (foreach spec *RMR-HATCH-SPECS*
    (setq index (1+ index))
    (princ (strcat "\n " (RMR:NumPad2 index) "  [" (nth 0 spec) "]  "
                   (nth 1 spec)
                   "  |  pattern " (nth 2 spec)
                   "  |  scale " (RMR:Num (nth 3 spec) 2)
                   "  |  angle " (RMR:Num (nth 4 spec) 0)
                   "  |  layer " (nth 5 spec)))
    (princ (strcat "\n        " (nth 7 spec)))
  )
  (princ "\nRun RMR-HATCH to apply a material to one or more closed boundaries.")
  (princ)
)

(defun C:RMR-HATCH (/ keyword spec pattern scale angle layer rgb objects selection ename obj doc modelspace hatch array variant result colour)
  (RMR:EnsureReady)
  (setq keyword (RMR:PromptKeyword "Material" (RMR:KeywordList *RMR-HATCH-SPECS*) "2"))
  (setq spec (RMR:TableSpec keyword *RMR-HATCH-SPECS*))
  (if spec
    (progn
      (setq pattern (nth 2 spec))
      (setq scale (RMR:PromptReal "Hatch pattern scale" (nth 3 spec)))
      (setq angle (RMR:PromptAngle "Hatch angle" (nth 4 spec)))
      (setq layer (nth 5 spec))
      (setq rgb (nth 6 spec))
      (if (not (tblsearch "LAYER" layer)) (setq layer "RMR-M-HATCH"))
      (princ (strcat "\nMaterial: " (nth 1 spec) " | pattern " pattern " | layer " layer))
      (setq objects '())
      (setq selection T)
      (while selection
        (setq ename (car (entsel "\nPick a closed boundary (Enter to finish): ")))
        (if ename
          (progn
            (setq obj (vl-catch-all-apply 'vlax-ename->vla-object (list ename)))
            (if (not (vl-catch-all-error-p obj))
              (setq objects (append objects (list obj)))
            )
          )
          (setq selection nil)
        )
      )
      (cond
        ((null objects) (princ "\nNo boundary was selected."))
        (T
          (setq doc (RMR:DocSafe))
          (if (not doc)
            (princ "\nActiveX is not available in this session. Run -HATCH manually and use the settings printed by RMR-HATCHLIB.")
            (progn
              (setq modelspace (vla-get-ModelSpace doc))
              (setq hatch (vl-catch-all-apply 'vla-AddHatch (list modelspace 0 pattern :vlax-true)))
              (if (vl-catch-all-error-p hatch)
                (princ (strcat "\nHatch was not created: " (vl-catch-all-error-message hatch)))
                (progn
                  (RMR:TryPut hatch 'PatternScale scale)
                  (RMR:TryPut hatch 'PatternAngle (* angle (/ pi 180.0)))
                  (RMR:TryPut hatch 'Associative :vlax-true)
                  (setq array (vlax-make-safearray vlax-vbObject (cons 0 (1- (length objects)))))
                  (vlax-safearray-fill array objects)
                  (setq variant (vlax-make-variant array vlax-vbObject))
                  (setq result (vl-catch-all-apply 'vla-AppendOuterLoop (list hatch variant)))
                  (if (vl-catch-all-error-p result)
                    (progn
                      (princ (strcat "\nBoundary rejected: " (vl-catch-all-error-message result)))
                      (vl-catch-all-apply 'vla-Delete (list hatch))
                    )
                    (progn
                      (setq result (vl-catch-all-apply 'vla-Evaluate (list hatch)))
                      (RMR:TryPut hatch 'Layer layer)
                      (setq colour (RMR:ComColor rgb))
                      (if colour (RMR:TryPut hatch 'TrueColor colour))
                      (if (vl-catch-all-error-p result)
                        (princ (strcat "\nHatch created but not evaluated: " (vl-catch-all-error-message result)))
                        (princ (strcat "\nRooMNRooF hatch applied: " (nth 1 spec) " on " layer))
                      )
                    )
                  )
                )
              )
            )
          )
        )
      )
    )
  )
  (princ)
)

(defun C:RMR-LAYGROUP (/ keyword group action names name current changed skipped)
  (if (not (tblsearch "LAYER" "RMR-M-WALL")) (C:RMR-MASTER))
  (setq keyword (RMR:PromptKeyword "Discipline" (RMR:GroupKeywords) "Main"))
  (setq group (RMR:ResolveGroup keyword))
  (if group
    (progn
      (setq action (RMR:PromptKeyword "Action" "Freeze Thaw Off On Lock Unlock" "Freeze"))
      (setq names (RMR:GroupLayerNames group))
      (setq current (getvar "CLAYER"))
      (setq changed 0)
      (setq skipped 0)
      (if (and (RMR:InList current names)
               (or (= (strcase action) "FREEZE") (= (strcase action) "OFF")))
        (progn
          (if (and (tblsearch "LAYER" "RMR-M-WALL") (not (RMR:InList "RMR-M-WALL" names)))
            (progn
              (setvar "CLAYER" "RMR-M-WALL")
              (setq current "RMR-M-WALL")
              (princ "\nCurrent layer moved to RMR-M-WALL so the group can be switched off.")
            )
            (princ "\nWarning: the current layer belongs to this group, so it will be skipped.")
          )
        )
      )
      (foreach name names
        (if (not (tblsearch "LAYER" name))
          (setq skipped (1+ skipped))
          (if (and (= (strcase name) (strcase current))
                   (or (= (strcase action) "FREEZE") (= (strcase action) "OFF")))
            (setq skipped (1+ skipped))
            (progn
              (RMR:SetLayerState name action)
              (setq changed (1+ changed))
            )
          )
        )
      )
      (princ (strcat "\n" (strcase action) " applied to " (itoa changed) " " group " layers"))
      (if (> skipped 0) (princ (strcat " | skipped " (itoa skipped))))
      (princ ".")
    )
  )
  (princ)
)

(defun C:RMR-CHECK (/ ss index ename data layer style total onzero ondefpoints layercounts stylecounts dimcounts foreign badstyles baddims pair lines answer path verdict)
  (if (not (tblsearch "LAYER" "RMR-M-WALL")) (C:RMR-MASTER))
  (setq total 0 onzero 0 ondefpoints 0)
  (setq layercounts '() stylecounts '() dimcounts '())
  (setq ss (ssget "X"))
  (if ss
    (progn
      (setq index 0)
      (repeat (sslength ss)
        (setq ename (ssname ss index))
        (setq index (1+ index))
        (if ename
          (progn
            (setq data (entget ename))
            (setq layer (cdr (assoc 8 data)))
            (if (not layer) (setq layer "(none)"))
            (setq total (1+ total))
            (if layer (setq layercounts (RMR:AssocCountInc layer layercounts)))
            (cond
              ((= (strcase layer) "0") (setq onzero (1+ onzero)))
              ((= (strcase layer) "DEFPOINTS") (setq ondefpoints (1+ ondefpoints)))
            )
            (setq style (cdr (assoc 7 data)))
            (if (and style (/= style "")) (setq stylecounts (RMR:AssocCountInc style stylecounts)))
            (if (= (cdr (assoc 0 data)) "DIMENSION")
              (progn
                (setq style (cdr (assoc 3 data)))
                (if (or (not style) (= style "")) (setq style "(current)"))
                (setq dimcounts (RMR:AssocCountInc style dimcounts))
              )
            )
          )
        )
      )
    )
  )
  (setq foreign '())
  (foreach pair layercounts
    (setq layer (car pair))
    (if (and (not (RMR:StartsWith (strcase layer) "RMR"))
             (not (= (strcase layer) "0"))
             (not (= (strcase layer) "DEFPOINTS")))
      (setq foreign (append foreign (list pair)))
    )
  )
  (setq badstyles '())
  (foreach pair stylecounts
    (if (not (RMR:StartsWith (strcase (car pair)) "RMR"))
      (setq badstyles (append badstyles (list pair)))
    )
  )
  (setq baddims '())
  (foreach pair dimcounts
    (if (not (RMR:StartsWith (strcase (car pair)) "RMR"))
      (setq baddims (append baddims (list pair)))
    )
  )
  (setq verdict "PASS")
  (if (or (> onzero 0) (> (length foreign) 0) (> (length badstyles) 0) (> (length baddims) 0))
    (setq verdict "REVIEW")
  )
  (setq lines '())
  (setq lines (RMR:SayLine lines "=============== RooMNRooF standard check ==============="))
  (setq lines (RMR:SayLine lines (strcat " Drawing ............. " (RMR:FileTitle (getvar "DWGNAME")))))
  (setq lines (RMR:SayLine lines (strcat " Standard version .... " *RMR-VERSION*)))
  (setq lines (RMR:SayLine lines (strcat " Drawing scale ....... " *RMR-DRAW-SCALE-LABEL " (" *RMR-ANNO-SPACE* ")")))
  (setq lines (RMR:SayLine lines (strcat " Entities checked .... " (itoa total))))
  (setq lines (RMR:SayLine lines (strcat " Standard layers ..... " (itoa (length *RMR-LAYER-SPECS*)))))
  (setq lines (RMR:SayLine lines (strcat " Entities on layer 0 . " (itoa onzero))))
  (setq lines (RMR:SayLine lines (strcat " Entities on Defpoints " (itoa ondefpoints))))
  (setq lines (RMR:SayLine lines (strcat " Non-standard layers . " (itoa (length foreign)))))
  (foreach pair (RMR:SortPairsDesc foreign)
    (setq lines (RMR:SayLine lines (strcat "   - " (car pair) " : " (itoa (cdr pair)) " entities")))
  )
  (setq lines (RMR:SayLine lines (strcat " Non-RMR text styles . " (itoa (length badstyles)))))
  (foreach pair (RMR:SortPairsDesc badstyles)
    (setq lines (RMR:SayLine lines (strcat "   - " (car pair) " : " (itoa (cdr pair)) " objects")))
  )
  (setq lines (RMR:SayLine lines (strcat " Non-RMR dim styles .. " (itoa (length baddims)))))
  (foreach pair (RMR:SortPairsDesc baddims)
    (setq lines (RMR:SayLine lines (strcat "   - " (car pair) " : " (itoa (cdr pair)) " dimensions")))
  )
  (setq lines (RMR:SayLine lines (strcat " Verdict ............. " verdict)))
  (setq lines (RMR:SayLine lines " Next steps: AUDIT, then -PURGE, then RMR-LAYGROUP to isolate disciplines."))
  (setq lines (RMR:SayLine lines "========================================================"))
  (setq answer (RMR:PromptYesNo "Save this report as a text file" "No"))
  (if (RMR:YesP answer)
    (progn
      (setq path (getfiled "Save the RooMNRooF check report" "RooMNRooF_Check_Report.txt" "txt" 1))
      (if path
        (if (RMR:WriteLines path lines)
          (princ (strcat "\nReport saved: " path))
          (princ "\nThe report could not be written to that location.")
        )
      )
    )
  )
  (princ)
)

(defun C:RMR-COUNT (/ filter ss index ename data block layer counts pair lines limit shown answer path parts)
  (if (not (tblsearch "LAYER" "RMR-M-WALL")) (C:RMR-MASTER))
  (setq filter (RMR:PromptText "Block name filter (DOOR, *DOOR*, DOOR-0*, * for all)" "*"))
  (setq ss (ssget "X" '((0 . "INSERT"))))
  (setq counts '())
  (if ss
    (progn
      (setq index 0)
      (repeat (sslength ss)
        (setq ename (ssname ss index))
        (setq index (1+ index))
        (if ename
          (progn
            (setq data (entget ename))
            (setq block (cdr (assoc 2 data)))
            (setq layer (cdr (assoc 8 data)))
            (if (and block
                     (/= block "")
                     (not (RMR:StartsWith block "*"))
                     (or (= filter "*") (RMR:MatchFilter block filter)))
              (setq counts (RMR:AssocCountInc (strcat block "|" layer) counts))
            )
          )
        )
      )
    )
  )
  (setq counts (RMR:SortPairsDesc counts))
  (setq lines '())
  (setq lines (RMR:SayLine lines (strcat "RooMNRooF block takeoff | filter: " filter)))
  (if counts
    (progn
      (setq limit 40)
      (setq shown 0)
      (foreach pair counts
        (if (< shown limit)
          (progn
            (setq parts (RMR:SplitString (car pair) "|"))
            (setq lines (RMR:SayLine lines (strcat "  " (nth 0 parts) " [" (nth 1 parts) "] = " (itoa (cdr pair)))))
            (setq shown (1+ shown))
          )
        )
      )
      (if (> (length counts) limit)
        (setq lines (RMR:SayLine lines (strcat "  ... " (itoa (- (length counts) limit)) " more block types in the file export")))
      )
      (setq lines (RMR:SayLine lines (strcat "Total block types: " (itoa (length counts)))))
      (setq answer (RMR:PromptYesNo "Export the full takeoff as CSV" "Yes"))
      (if (RMR:YesP answer)
        (progn
          (setq path (getfiled "Save the RooMNRooF block takeoff" "RooMNRooF_Block_Takeoff.csv" "csv" 1))
          (if path
            (progn
              (setq lines (cons "BlockName;Layer;Count" (RMR:CsvLines counts)))
              (if (RMR:WriteLines path lines)
                (princ (strcat "\nTakeoff exported: " path))
                (princ "\nThe takeoff could not be written to that location.")
              )
            )
          )
        )
      )
    )
    (princ "\nNo matching blocks were found in this drawing.")
  )
  (princ)
)

(defun RMR:EndsWith (text tail)
  (and
    (>= (strlen text) (strlen tail))
    (= (substr text (1+ (- (strlen text) (strlen tail))) (strlen tail)) tail)
  )
)

(defun RMR:FindFrom (text part start / len plen index found)
  ;; Returns the 1-based position of part inside text at or after start.
  (setq len (strlen text))
  (setq plen (strlen part))
  (setq index (if (< start 1) 1 start))
  (setq found nil)
  (while (and (not found) (<= index (1+ (- len plen))))
    (if (= (substr text index plen) part)
      (setq found index)
      (setq index (1+ index))
    )
  )
  found
)

(defun RMR:MatchFilter (name filter / upper pattern parts pos part len index total match found)
  ;; Block-name filter with AutoCAD style * wildcards.
  ;;   "DOOR"    matches any name containing DOOR
  ;;   "*DOOR*"  matches any name containing DOOR
  ;;   "DOOR*"   matches names starting with DOOR
  ;;   "*-01"    matches names ending with -01
  ;;   "*"       matches everything
  (setq upper (strcase name))
  (setq pattern (strcase (RMR:TrimString filter)))
  (setq len (strlen upper))
  (cond
    ((or (= pattern "") (= pattern "*")) T)
    ((not (vl-string-search "*" pattern)) (if (vl-string-search pattern upper) T nil))
    (T
      (setq parts (RMR:SplitString pattern "*"))
      (setq total (length parts))
      (setq index 0)
      (setq pos 1)
      (setq match T)
      (foreach part parts
        (setq index (1+ index))
        (if (and match (/= part ""))
          (cond
            ((and (= index 1) (not (RMR:StartsWith pattern "*")))
              (if (= (substr upper 1 (strlen part)) part)
                (setq pos (1+ (strlen part)))
                (setq match nil)
              )
            )
            ((and (= index total) (not (RMR:EndsWith pattern "*")))
              (if (RMR:EndsWith upper part)
                (setq match (<= pos (1+ (- len (strlen part)))))
                (setq match nil)
              )
            )
            (T
              (setq found (RMR:FindFrom upper part pos))
              (if found
                (setq pos (+ found (strlen part)))
                (setq match nil)
              )
            )
          )
        )
      )
      (if match T nil)
    )
  )
)

(defun RMR:CsvLines (counts / lines pair parts)
  (setq lines '())
  (foreach pair counts
    (setq parts (RMR:SplitString (car pair) "|"))
    (setq lines (append lines (list (strcat (nth 0 parts) ";" (nth 1 parts) ";" (itoa (cdr pair))))))
  )
  lines
)

(defun C:RMR-EXPORT-PALETTE (/ path lines spec rgb)
  (setq path (getfiled "Export the RooMNRooF palette" "RooMNRooF_Palette.csv" "csv" 1))
  (if path
    (progn
      (setq lines (list "RooMNRooF palette export - edit freely then run RMR-IMPORT-PALETTE"))
      (setq lines (append lines (list "LayerName;Group;Red;Green;Blue;Linetype;Lineweight;Description")))
      (foreach spec *RMR-LAYER-SPECS*
        (setq rgb (nth 2 spec))
        (setq lines
          (append lines
            (list
              (strcat (nth 0 spec) ";" (nth 1 spec) ";"
                      (itoa (nth 0 rgb)) ";" (itoa (nth 1 rgb)) ";" (itoa (nth 2 rgb)) ";"
                      (nth 3 spec) ";" (itoa (nth 4 spec)) ";" (nth 5 spec))
            )
          )
        )
      )
      (if (RMR:WriteLines path lines)
        (princ (strcat "\nPalette exported: " path " (" (itoa (length *RMR-LAYER-SPECS*)) " layers)"))
        (princ "\nThe palette could not be written to that location.")
      )
    )
  )
  (princ)
)

(defun C:RMR-IMPORT-PALETTE (/ path lines line parts added skipped replaced spec name group red green blue ltype lw desc)
  (setq path (getfiled "Import a RooMNRooF palette" "" "csv" 0))
  (if path
    (progn
      (setq lines (RMR:ReadLines path))
      (setq added 0 replaced 0 skipped 0)
      (foreach line lines
        (setq parts (RMR:SplitString line ";"))
        (if (= (length parts) 8)
          (progn
            (setq name (RMR:TrimString (nth 0 parts)))
            (setq group (strcase (RMR:TrimString (nth 1 parts))))
            (setq red (read (nth 2 parts)))
            (setq green (read (nth 3 parts)))
            (setq blue (read (nth 4 parts)))
            (setq ltype (RMR:TrimString (nth 5 parts)))
            (setq lw (read (nth 6 parts)))
            (setq desc (RMR:TrimString (nth 7 parts)))
            (if (and (/= name "")
                     (/= group "")
                     (numberp red) (numberp green) (numberp blue) (numberp lw)
                     (<= 0 red 255) (<= 0 green 255) (<= 0 blue 255))
              (progn
                (setq spec
                  (list name group
                        (list (fix red) (fix green) (fix blue))
                        (if (= ltype "") "Continuous" ltype)
                        (fix lw)
                        (if (= desc "") name desc))
                )
                (if (RMR:TableSpec name *RMR-LAYER-SPECS*)
                  (progn
                    (setq *RMR-LAYER-SPECS* (RMR:ReplaceSpec name spec *RMR-LAYER-SPECS*))
                    (setq replaced (1+ replaced))
                  )
                  (progn
                    (setq *RMR-LAYER-SPECS* (append *RMR-LAYER-SPECS* (list spec)))
                    (setq added (1+ added))
                  )
                )
              )
              (setq skipped (1+ skipped))
            )
          )
          (if (and (/= (RMR:TrimString line) "")
                   (not (RMR:StartsWith (strcase line) "LAYERNAME"))
                   (not (RMR:StartsWith (strcase line) "ROOMNROOF")))
            (setq skipped (1+ skipped))
          )
        )
      )
      (princ (strcat "\nPalette import: " (itoa added) " new, " (itoa replaced) " updated, " (itoa skipped) " ignored."))
      (if (> (+ added replaced) 0)
        (progn
          (C:RMR-MASTER)
          (princ "\nThe imported palette is now active. Run RMR-EXPORT-PALETTE to keep a backup.")
        )
      )
    )
    (princ "\nNo palette file was selected.")
  )
  (princ)
)

(defun C:RMR-PAGESETUP (/ doc layout sheetkeyword scalekeyword spec enum media device style applied item result readback)
  (setq doc (RMR:DocSafe))
  (if (not doc)
    (progn
      (princ "\nActiveX is not available in this session, so the layout could not be configured automatically.")
      (princ (strcat "\nManual settings: plotter " *RMR-PLOT-DEVICE* ", paper A1, landscape, centred, plot styles on."))
      (princ (strcat "\nPlot style table: " (if (findfile *RMR-PLOT-BRAND-STYLE*) *RMR-PLOT-BRAND-STYLE* *RMR-PLOT-STYLE*)))
    )
    (progn
      (setq layout (vl-catch-all-apply 'vla-get-ActiveLayout (list doc)))
      (if (or (vl-catch-all-error-p layout) (not layout))
        (princ "\nNo layout object was returned. Switch to a paper-space layout and run RMR-PAGESETUP again.")
        (progn
          (setq sheetkeyword (RMR:PromptKeyword "Paper size" "A0 A1 A2 A3 A4" "A1"))
          (setq scalekeyword (RMR:PromptKeyword "Plot scale 1:" (RMR:KeywordList *RMR-SCALE-SPECS*) "100"))
          (setq spec (RMR:TableSpec scalekeyword *RMR-SCALE-SPECS*))
          (setq enum (nth 3 spec))
          (setq device *RMR-PLOT-DEVICE*)
          (setq style
            (cond
              ((findfile *RMR-PLOT-BRAND-STYLE*) *RMR-PLOT-BRAND-STYLE*)
              ((findfile *RMR-PLOT-STYLE*) *RMR-PLOT-STYLE*)
              (T "")
            )
          )
          (setq applied '())
          (if (RMR:TryPut layout 'ConfigName device)
            (setq applied (append applied (list (strcat "Plotter ............ " device))))
            (princ (strcat "\nPlotter not applied: " device " is not installed. Edit *RMR-PLOT-DEVICE* near the top of the file."))
          )
          (setq media (RMR:FindMediaName device sheetkeyword))
          (cond
            ((and media (RMR:TryPut layout 'CanonicalMediaName media))
              (setq applied (append applied (list (strcat "Paper .............. " media))))
            )
            (media (princ (strcat "\nPaper name was rejected by the plotter: " media)))
            (T (princ (strcat "\nNo " sheetkeyword " paper name was found for " device ". Set it in PAGESETUP.")))
          )
          (if (RMR:TryPut layout 'PlotRotation *RMR-PLOT-ROTATION*)
            (setq applied (append applied (list (strcat "Orientation ........ " (if (= *RMR-PLOT-ROTATION* 1) "Landscape" "Portrait")))))
          )
          (if (/= style "")
            (if (RMR:TryPut layout 'StyleSheet style)
              (setq applied (append applied (list (strcat "Plot style ......... " style))))
              (princ (strcat "\nPlot style table not applied: " style))
            )
          )
          (if (RMR:TryPut layout 'PaperUnits 1)
            (setq applied (append applied (list "Paper units ........ Millimetres")))
          )
          (if (RMR:TryPut layout 'CenterPlot :vlax-true)
            (setq applied (append applied (list "Centred ............ Yes")))
          )
          (if (RMR:TryPut layout 'PlotWithLineweights :vlax-true)
            (setq applied (append applied (list "Lineweights ........ Yes")))
          )
          (if (RMR:TryPut layout 'PlotWithPlotStyles :vlax-true)
            (setq applied (append applied (list "Plot styles ........ Yes")))
          )
          (if (RMR:TryPut layout 'ShowPlotStyles :vlax-false)
            (setq applied (append applied (list "Display styles ..... Off")))
          )
          (if enum
            (progn
              (RMR:TryPut layout 'UseStandardScale :vlax-true)
              (if (RMR:TryPut layout 'StandardScale enum)
                (progn
                  (setq readback (vl-catch-all-apply 'vlax-get-property (list layout 'StandardScale)))
                  (setq applied
                    (append applied
                      (list (strcat "Scale .............. " (nth 1 spec) " (enum read-back "
                                    (if (numberp readback) (RMR:Num readback 0) "n/a") ")"))
                      )
                  )
                )
                (princ (strcat "\nScale " (nth 1 spec) " was not applied. Set it in PAGESETUP."))
              )
            )
            (princ (strcat "\n" (nth 1 spec) " is not a named AutoCAD plot scale. Set it manually in PAGESETUP."))
          )
          (setq result (vl-catch-all-apply 'vlax-get-property (list layout 'PlotType)))
          (if (not (vl-catch-all-error-p result))
            (setq applied (append applied (list (strcat "Plot area .......... untouched (current enum " (if (numberp result) (RMR:Num result 0) "n/a") ")"))))
          )
          (princ "\n---------- RooMNRooF page setup ----------")
          (foreach item applied (princ (strcat "\n  " item)))
          (princ "\nVerify with PAGESETUP. Nothing is plotted automatically.")
        )
      )
    )
  )
  (princ)
)

(defun C:RMR-PUBLISH (/ doc path folder name layouts layout count lines dsd answer oldecho result)
  (setq doc (RMR:DocSafe))
  (if (not doc)
    (princ "\nActiveX is not available. Use the PUBLISH command and add your layouts manually.")
    (progn
      (setq path (vl-catch-all-apply 'vla-get-FullFileName (list doc)))
      (if (or (vl-catch-all-error-p path) (= path ""))
        (princ "\nSave the drawing first - a publish list needs the real DWG path.")
        (progn
          (setq folder (RMR:FolderOf path))
          (setq name (RMR:FileTitle path))
          (setq lines '())
          (setq count 0)
          (setq layouts (vla-get-Layouts doc))
          (vlax-for layout layouts
            (if (/= (strcase (vla-get-Name layout)) "MODEL")
              (progn
                (setq count (1+ count))
                (setq lines (append lines (list (strcat "[Sheet" (itoa count) "]"))))
                (setq lines (append lines (list (strcat "DWG=" path))))
                (setq lines (append lines (list (strcat "Layout=" (vla-get-Name layout)))))
                (setq lines (append lines (list (strcat "Setup=" (vla-get-Name layout)))))
                (setq lines (append lines (list (strcat "OutputDWF=" folder name " - " (vla-get-Name layout) ".pdf"))))
              )
            )
          )
          (if (= count 0)
            (princ "\nThis drawing has no paper-space layouts. Run RMR-SHEET in a layout and try again.")
            (progn
              (setq lines
                (append lines
                  (list "[DSDVersion]"
                        "Version=7.0"
                        "[DSD_Data]"
                        "NoOfCopies=1"
                        "IncludeLayer=TRUE"
                        "IncludeModelSpace=FALSE"
                        "PromptForDwfName=FALSE"
                        "PromptForLocation=FALSE"
                        "Type=6"
                        "XrefIncluded=TRUE")
                )
              )
              (setq dsd (strcat folder name "_RooMNRooF.dsd"))
              (if (RMR:WriteLines dsd lines)
                (progn
                  (princ (strcat "\nPublish list written: " dsd))
                  (princ (strcat "\nSheets listed: " (itoa count) " | Type=6 means PDF output."))
                  (setq answer (RMR:PromptYesNo "Start -PUBLISH with this list now" "No"))
                  (if (RMR:YesP answer)
                    (progn
                      (setq oldecho (getvar "CMDECHO"))
                      (setvar "CMDECHO" 0)
                      (setq result (vl-catch-all-apply 'command (list "_.-PUBLISH" dsd)))
                      (setvar "CMDECHO" oldecho)
                      (if (vl-catch-all-error-p result)
                        (princ (strcat "\n-PUBLISH did not start: " (vl-catch-all-error-message result)
                                       "\nRun PUBLISH and browse to the .dsd file instead."))
                        (princ "\n-PUBLISH started. Watch the publish progress window.")
                      )
                    )
                    (princ "\nRun PUBLISH and browse to the .dsd file whenever you are ready.")
                  )
                )
                (princ (strcat "\nThe publish list could not be written to " dsd))
              )
            )
          )
        )
      )
    )
  )
  (princ)
)

;;; -----------------------------------------------------------------------------
;;; Save the current standard as an AutoCAD template
;;; -----------------------------------------------------------------------------

(defun C:RMR-SAVE-TEMPLATE (/ path acad doc result)
  (if (not (tblsearch "LAYER" "RMR-M-WALL"))
    (C:RMR-MASTER)
  )
  (setq path (getfiled "Save RooMNRooF PRO template" "RooMNRooF_PRO_Master.dwt" "dwt" 1))
  (if path
    (progn
      (vl-load-com)
      (setq acad (vlax-get-acad-object))
      (setq doc (vla-get-ActiveDocument acad))
      (setq result (vl-catch-all-apply 'vla-SaveAs (list doc path)))
      (if (vl-catch-all-error-p result)
        (princ (strcat "\nCould not save automatically: " (vl-catch-all-error-message result) "\nUse SAVEAS and choose .DWT."))
        (princ (strcat "\nRooMNRooF template saved: " path))
      )
    )
  )
  (princ)
)

;;; -----------------------------------------------------------------------------
;;; Palette / usage guide
;;; -----------------------------------------------------------------------------

(defun C:RMR-PALETTE (/ spec hatch stamp scale)
  (princ "\n=================================================")
  (princ (strcat "\n RooMNRooF | Consultant 2D CAD Standard | " *RMR-VERSION*))
  (princ "\n=================================================")
  (princ "\n Layer groups")
  (princ "\n  1  Main Theme      RMR-M-...")
  (princ "\n  2  Furniture       RMR-F-...")
  (princ "\n  3  Structural      RMR-S-...")
  (princ "\n  4  Plumbing        RMR-P-...")
  (princ "\n  5  Annotation      RMR-A-...  (leaders, arrows, text, dims, tags)")
  (princ "\n  6  Presentation    RMR-PRES-... (title, keys, north, stamps)")
  (princ "\n  7  Control         RMR-00-...  (no-plot, references)")
  (princ "\n")
  (princ (strcat "\n Active scale " *RMR-DRAW-SCALE-LABEL *RMR-ANNO-SPACE*
                 " | symbol factor " (RMR:Num *RMR-ANNO-SCALE* 2)))
  (princ "\n")
  (princ "\n Standard")
  (princ "\n  RMR-MASTER         Build / refresh the whole standard")
  (princ "\n  RMR-PRO-SETUP      Build standard + PRO fonts, symbols, MLeader")
  (princ "\n  RMR-SETLAYER       Set the current layer by discipline")
  (princ "\n  RMR-LAYGROUP       Freeze / Thaw / Off / On / Lock a whole group")
  (princ "\n  RMR-LEGEND         Place the true-colour layer legend")
  (princ "\n  RMR-SHEET          Place an A0-A4 sheet and title block")
  (princ "\n")
  (princ "\n Annotate")
  (princ "\n  RMR-SCALE          Set drawing scale + annotation size factor")
  (princ "\n  RMR-NORTH          North arrow symbol")
  (princ "\n  RMR-ROOMTAG        Room number / name / area tag")
  (princ "\n  RMR-AREA           Measure rooms and place an area schedule")
  (princ "\n  RMR-GRID           Labelled structural grid with bubbles")
  (princ "\n  RMR-KEYNOTE        Numbered keynote bubble")
  (princ "\n  RMR-DETAIL         Detail callout bubble")
  (princ "\n  RMR-LEVEL          Level datum marker")
  (princ "\n  RMR-REVISION       Revision triangle and description")
  (princ "\n  RMR-MLEADER        Branded multileader")
  (princ "\n  RMR-DIM            Dimension launcher on RMR-A-DIMS")
  (princ "\n")
  (princ "\n Markers and views")
  (princ "\n  RMR-SECTION        Section cut line, arrows and sheet bubbles")
  (princ "\n  RMR-ELEVATION      Elevation marker with direction arrow")
  (princ "\n  RMR-MATCHLINE      Match line to the adjoining sheet")
  (princ "\n  RMR-BREAKLINE      Break / cut line on RMR-A-MATCH")
  (princ "\n  RMR-REVCLOUD       Revision cloud (bulged polyline)")
  (princ "\n")
  (princ "\n Present")
  (princ "\n  RMR-HATCH          Apply a material hatch from the library")
  (princ "\n  RMR-HATCHLIB       Print the material hatch library")
  (princ "\n  RMR-STAMP          Issue / status stamp (IFR, IFC, AS-BUILT...)")
  (princ "\n  RMR-REVTABLE       Revision history table")
  (princ "\n  RMR-NOTES          Numbered general notes block")
  (princ "\n  RMR-SCALEBAR       Graphic scale bar in metres")
  (princ "\n  RMR-KEYPLAN        Key plan box with north arrow")
  (princ "\n")
  (princ "\n Manage and issue")
  (princ "\n  RMR-CHECK          Audit the drawing against the standard")
  (princ "\n  RMR-COUNT          Block takeoff with CSV export")
  (princ "\n  RMR-FINDTEXT       Find / replace text (wildcards allowed)")
  (princ "\n  RMR-EXPORT-PALETTE Write the palette to a CSV file")
  (princ "\n  RMR-IMPORT-PALETTE Read a CSV palette and rebuild")
  (princ "\n  RMR-PAGESETUP      Configure the active layout for PDF")
  (princ "\n  RMR-PUBLISH        Write a DSD publish list")
  (princ "\n  RMR-SAVE-TEMPLATE  Save the drawing as a .DWT")
  (princ "\n")
  (princ "\n Studio suite")
  (princ "\n  RMR-LAYOUTS        New layout: paper, title block, scaled viewport")
  (princ "\n  RMR-VPORT          Scaled, locked viewport in the active layout")
  (princ "\n  RMR-SYMBOLS        Build the RMR-SYM-* parametric symbol library")
  (princ "\n  RMR-DOORSCHED      Door schedule from inserted door blocks")
  (princ "\n  RMR-FIELDS         Insert live fields (date, drawing, layout...)")
  (princ "\n  RMR-PROJECT        Show / set / save / load project data")
  (princ "\n  RMR-BACKUP         Timestamped backup copy of the drawing")
  (princ "\n")
  (princ "\n Delivery suite")
  (princ "\n  RMR-WALL           Parametric wall: type, thickness, mitred path")
  (princ "\n  RMR-STAIR          Straight stair: width, risers, going, direction")
  (princ "\n  RMR-LENGTH         Linear takeoff with label and CSV export")
  (princ "\n  RMR-BOM            Bill of materials table and CSV")
  (princ "\n  RMR-FINISHES       Room finishes schedule (*RMR-FINISH-SPECS*)")
  (princ "\n  RMR-SHEETREG       Drawing register (*RMR-SHEET-LIST*)")
  (princ "\n  RMR-XREFLIST       Xref register with resolved paths")
  (princ "\n  RMR-TRANSMITTAL    Issue / transmittal record for the set")
  (princ "\n  RMR-LAYERSTATE     Save / restore / list / delete layer states")
  (princ "\n  RMR-STANDARDIZE    Force colour, linetype and lineweight to BYLAYER")
  (princ "\n  RMR-CLEAN          Repeated purge + audit, then optional standardise")
  (princ "\n  RMR-DWGPROPS       Drawing properties from *RMR-PROJECT*")
  (princ "\n")
  (princ "\n Site and services")
  (princ "\n  RMR-SUNPATH        Solar study diagram for a chosen latitude")
  (princ "\n  RMR-FALL           Fall arrow, gradient label and drop in mm")
  (princ "\n  RMR-DRAIN          Drainage run with manholes and invert levels")
  (princ "\n  RMR-PARK           Parking row: 90 / 60 / 45 degree bays")
  (princ "\n  RMR-TILE           Tiling setout grid, tile count and waste")
  (princ "\n  RMR-RCP            Reflected ceiling grid and light fittings")
  (princ "\n  RMR-LEVELSCHED     Level schedule from *RMR-LEVEL-SPECS*")
  (princ "\n  RMR-KEYLIB         Keynote legend from *RMR-KEYNOTES*")
  (princ "\n  RMR-REPORT         Printable report of the whole standard")
  (princ "\n  RMR-STRAY          Audit objects on non-standard layers")
  (princ "\n")
  (princ "\n Coordination suite")
  (princ "\n  RMR-CLASH          Bounding-box clash check between two groups")
  (princ "\n  RMR-ROOF           Gable / hip / shed roof plan with eaves")
  (princ "\n  RMR-RAIL           Balustrade with posts at a spacing")
  (princ "\n  RMR-WINDOWSCHED    Glazing schedule from window blocks")
  (princ "\n  RMR-ZONE           Zone plan hatched by area band")
  (princ "\n  RMR-BLKSWAP        Swap every insert of one block for another")
  (princ "\n  RMR-RENUMBER       Renumber picked tags in selection order")
  (princ "\n  RMR-TEXTALIGN      Align selected text onto a baseline")
  (princ "\n  RMR-INFO           Full report for one object")
  (princ "\n  RMR-ORIENT         Rotate the model to true north")
  (princ "\n")
  (princ "\n Documentation suite")
  (princ "\n  RMR-SPECNOTE       Place one specification clause as a note")
  (princ "\n  RMR-SPECINDEX      Specification index grouped by trade")
  (princ "\n  RMR-ABBREV         Abbreviations legend (*RMR-ABBREV-SPECS*)")
  (princ "\n  RMR-REVLIB         Revision history (*RMR-REVISIONS*)")
  (princ "\n  RMR-CHECKLIST      Pre-issue checklist (*RMR-CHECKLIST-SPECS*)")
  (princ "\n  RMR-ROOMSCHED      Room data schedule from picked boundaries")
  (princ "\n  RMR-DOCLIST        Document list for the folder, with CSV")
  (princ "\n  RMR-SHEETINDEX     Sheet index grid, current sheet marked")
  (princ "\n  RMR-COVER          Project cover sheet with the drawing set")
  (princ "\n  RMR-DOCSHEET       Complete documentation sheet in one go")
  (princ "\n")
  (princ "\n Presentation suite")
  (princ "\n  RMR-AXO            Axonometric massing from a plan outline")
  (princ "\n  RMR-ROOMVIEW       One point interior perspective of a room")
  (princ "\n  RMR-BUILDUP        Layered build-up (*RMR-BUILDUP-SPECS*)")
  (princ "\n  RMR-SWATCH         Material swatch board (*RMR-HATCH-SPECS*)")
  (princ "\n  RMR-COLOURBOARD    Brand palette and every layer colour")
  (princ "\n  RMR-MOODBOARD      Image board (*RMR-MOOD-SPECS*)")
  (princ "\n  RMR-AREACHART      Area distribution bar chart")
  (princ "\n  RMR-PROGRAMME      Programme bars (*RMR-PROGRAMME-SPECS*)")
  (princ "\n  RMR-BRANDING       RooMNRooF masthead with project data")
  (princ "\n  RMR-PRESENTSHEET   Complete presentation sheet in one go")
  (princ "\n")
  (princ "\n Quantity suite")
  (princ "\n  RMR-SURVEY         Import a measured survey CSV")
  (princ "\n  RMR-MEASURE        Measure lengths and areas with totals")
  (princ "\n  RMR-QUANTITY       Quantity takeoff against the rate library")
  (princ "\n  RMR-RATES          Rate library (*RMR-RATE-SPECS*)")
  (princ "\n  RMR-COSTPLAN       Elemental cost plan (*RMR-ELEMENT-SPECS*)")
  (princ "\n  RMR-PERQM          Cost per m2 against a benchmark")
  (princ "\n  RMR-CASHFLOW       Cash flow spread over the programme")
  (princ "\n  RMR-CSVIMPORT      Bring any CSV in as a table")
  (princ "\n  RMR-VALIDATE       Validate rates and blocks before pricing")
  (princ "\n  RMR-QSREPORT       Quantity surveyor report to a text file")
  (princ "\n")
  (princ "\n Automation")
  (princ "\n  RMR-ALIAS          Short aliases for every command + .pgp file")
  (princ "\n  RMR-TOOLPALETTE    Write RooMNRooF.mnu menu and toolbar")
  (princ "\n  RMR-AUTO           Run *RMR-AUTO-SEQUENCE* with a log")
  (princ "\n  RMR-BATCH          Write a .scr for a whole folder of drawings")
  (princ "\n")
  (princ "\n Structural suite")
  (princ "\n  RMR-COLUMN         Place columns from *RMR-COLUMN-SPECS*")
  (princ "\n  RMR-BEAM           Place beams from *RMR-BEAM-SPECS*")
  (princ "\n  RMR-FOUNDATION     Pad and strip foundations with depths")
  (princ "\n  RMR-REBAR          Bars with hooks, marks and spacing")
  (princ "\n  RMR-SLABPANEL      Slab panel layout and panel schedule")
  (princ "\n  RMR-SETOUT         Setting-out coordinates, table and CSV")
  (princ "\n  RMR-STRUCTSCHED    Structural element schedule")
  (princ "\n")
  (princ "\n Services and MEP suite")
  (princ "\n  RMR-DUCT           Ductwork runs from *RMR-DUCT-SPECS*")
  (princ "\n  RMR-PIPE           Pipework runs with a fall")
  (princ "\n  RMR-TRAY           Cable tray with rungs")
  (princ "\n  RMR-LIGHTING       Luminaire grid with circuit tags")
  (princ "\n  RMR-SPRINKLER      Sprinkler grid with coverage")
  (princ "\n  RMR-MEPSCHED       Services schedule from the drawing")
  (princ "\n  RMR-CLEARANCE      Service zone diagram and shared-zone check")
  (princ "\n")
  (princ "\n Construction detailing suite")
  (princ "\n  RMR-DETAILLIB      Grid of captioned detail frames")
  (princ "\n  RMR-JUNCTION       Parametric junction from two build-up legs")
  (princ "\n  RMR-DETAILTAG      Detail bubble, leader and running number")
  (princ "\n  RMR-DETLOC         Locator plan with the detail marked")
  (princ "\n  RMR-DIMCHAIN       Continuous dimension chain")
  (princ "\n  RMR-MATKEY         Materials key for a build-up")
  (princ "\n  RMR-DETSCALE       Detail scale and metric scale bar")
  (princ "\n  RMR-DETSHEET       Complete A1 detail sheet")
  (princ "\n  RMR-SPECLINK       Link a detail to specification clauses")
  (princ "\n  RMR-DETINDEX       Detail index schedule")
  (princ "\n  RMR-UVALUE         U value and thermal resistance")
  (princ "\n  RMR-FIRESTOP       Fire compartment line and rating")
  (princ "\n  RMR-ACOUSTIC       Acoustic rating markers and table")
  (princ "\n  RMR-CHECKDETAIL    Detail compliance check and report")
  (princ "\n")
  (princ "\n Editable tables near the top of this file")
  (princ "\n  *RMR-LAYER-SPECS*    layer palette and group structure")
  (princ "\n  *RMR-TEXT-STYLES*    fonts, width factors and obliques")
  (princ "\n  *RMR-DIMSTYLE-SPECS* dimension styles")
  (princ "\n  *RMR-MLEADER-SPECS*  multileader styles")
  (princ "\n  *RMR-SCALE-SPECS*    drawing scales and plot scale enums")
  (princ "\n  *RMR-HATCH-SPECS*    material hatch library")
  (princ "\n  *RMR-STAMP-SPECS*    issue and status stamps")
  (princ "\n  *RMR-NOTES*          general notes wording")
  (princ "\n  *RMR-PLOT-DEVICE*    plotter, plot style and paper defaults")
  (princ "\n  *RMR-PROJECT*        client, job, sheet and issue data")
  (princ "\n  *RMR-CLOUD-ARC*      revision cloud bulge factor")
  (princ "\n  *RMR-WALL-SPECS*     wall types, thickness and target layer")
  (princ "\n  *RMR-FINISH-SPECS*   room finish schedule rows")
  (princ "\n  *RMR-SHEET-LIST*     drawing register and transmittal rows")
  (princ "\n  *RMR-LEVEL-SPECS*    level schedule rows")
  (princ "\n  *RMR-KEYNOTES*       keynote library entries")
  (princ "\n  *RMR-SUN-CITIES*     reference latitudes for RMR-SUNPATH")
  (princ "\n  *RMR-ZONE-BANDS*     zone bands: label, max m2, colour, pattern")
  (princ "\n  *RMR-SPEC-CLAUSES*   specification clauses: code, trade, title, text")
  (princ "\n  *RMR-ABBREV-SPECS*   abbreviation legend entries")
  (princ "\n  *RMR-REVISIONS*      revision log: revision, date, description, by")
  (princ "\n  *RMR-CHECKLIST-SPECS* pre-issue checklist groups and items")
  (princ "\n  *RMR-BUILDUP-SPECS*   build-up layers: type, order, name, mm, colour")
  (princ "\n  *RMR-PROGRAMME-SPECS* programme stages: name, start week, weeks, colour")
  (princ "\n  *RMR-MOOD-SPECS*      image board slots: number, caption")
  (princ "\n  *RMR-RATE-SPECS*      rate library: code, description, unit, rate")
  (princ "\n  *RMR-ELEMENT-SPECS*   elemental cost plan: element, sum, colour key")
  (princ "\n  *RMR-AUTO-SEQUENCE*   automation steps: label, action, argument")
  (princ "\n  *RMR-COLUMN-SPECS*    column sizes: mark, width, depth, colour")
  (princ "\n  *RMR-BEAM-SPECS*      beam sizes: mark, width, depth, max span")
  (princ "\n  *RMR-REBAR-SPECS*     bars: mark, diameter, spacing")
  (princ "\n  *RMR-DUCT-SPECS*      duct sizes: size, width, height, colour")
  (princ "\n  *RMR-PIPE-SPECS*      pipe sizes: size, bore, colour")
  (princ "\n  *RMR-SERVICE-ZONES*   vertical bands: zone, bottom, top, colour")
  (princ "\n  *RMR-SERVICE-LAYER-ZONES*  which zone each services layer uses")
  (princ "\n  *RMR-DETAIL-SPECS*    detail library: number, title, scale, category")
  (princ "\n  *RMR-JUNCTION-SPECS*  junctions: type, category, leg A, leg B, note")
  (princ "\n  *RMR-MATERIAL-R-SPECS* thermal: material, lambda, thickness, note")
  (princ "\n  *RMR-FIRE-SPECS*     fire ratings: code, minutes, colour, note")
  (princ "\n  *RMR-ACOUSTIC-SPECS* acoustic ratings: code, Rw dB, application")
  (princ "\n")
  (princ "\n Add a personal palette by appending a layer spec:")
  (princ "\n  (\"RMR-X-ITEM\" \"MY GROUP\" (R G B) \"Continuous\" 18 \"Description\")")
  (princ "\n then run RMR-MASTER again, or export, edit and re-import the CSV.")
  (princ "\n")
  (setq hatch (length *RMR-HATCH-SPECS*))
  (setq stamp (length *RMR-STAMP-SPECS*))
  (setq scale (length *RMR-SCALE-SPECS*))
  (princ (strcat "\n Library size: " (itoa (length *RMR-LAYER-SPECS*)) " layers, "
                 (itoa (length *RMR-TEXT-STYLES*)) " text styles, "
                 (itoa scale) " scales, " (itoa hatch) " materials, "
                 (itoa stamp) " stamps, " (itoa (length *RMR-NOTES*)) " notes."))
  (princ "\n=================================================")
  (princ)
)

;;; =====================================================================
;;; PRO 4.0 STUDIO SUITE
;;; Layouts and viewports, section / elevation / match / break markers,
;;; revision clouds, dimension launcher, parametric symbol library,
;;; door schedule, text find and replace, live fields, project data and
;;; timestamped drawing backups.
;;; =====================================================================

(setq *RMR-PROJECT*
 '(
    ("CLIENT"  . "RooMNRooF Studio Client")
    ("PROJECT" . "RooMNRooF Reference Apartment")
    ("JOB"     . "2401")
    ("STAGE"   . "ISSUED FOR REVIEW")
    ("TITLE"   . "GENERAL ARRANGEMENT")
    ("DWGNO"   . "A-000")
    ("REV"     . "01")
    ("DATE"    . "")
    ("DRAWN"   . "RMR")
    ("CHECKED" . "KH")
    ("SCALE"   . "")
    ("SIZE"    . "A1")
  )
)
(setq *RMR-CLOUD-ARC* 0.65)

(defun RMR:ProjectValue (tag fallback / entry)
  (setq entry (assoc tag *RMR-PROJECT*))
  (cond
    ((and entry (cdr entry) (/= (cdr entry) "")) (cdr entry))
    ((= tag "DATE")  (RMR:TodayDate))
    ((= tag "SCALE") *RMR-DRAW-SCALE-LABEL*)
    (T (if fallback fallback ""))
  )
)

(defun RMR:SetProject (tag value / out item)
  (setq out nil)
  (foreach item *RMR-PROJECT*
    (if (= (car item) tag)
      (setq out (cons (cons tag value) out))
      (setq out (cons item out))
    )
  )
  (if (not (assoc tag *RMR-PROJECT*))
    (setq out (cons (cons tag value) out))
  )
  (setq *RMR-PROJECT* (reverse out))
  value
)

(defun RMR:ProjectPairs (/ out item)
  (setq out nil)
  (foreach item *RMR-PROJECT*
    (setq out (cons (cons (car item) (RMR:ProjectValue (car item) "")) out))
  )
  (reverse out)
)

;;; --- block-definition primitives (geometry on layer 0, colour BYBLOCK)
(defun RMR:SymLine (p1 p2)
  (entmake
    (list '(0 . "LINE") '(8 . "0") '(62 . 0)
          (cons 10 (RMR:3D p1)) (cons 11 (RMR:3D p2)))
  )
)

(defun RMR:SymArc (c radius a1 a2)
  (entmake
    (list '(0 . "ARC") '(8 . "0") '(62 . 0)
          (cons 10 (RMR:3D c)) (cons 40 radius) (cons 50 a1) (cons 51 a2))
  )
)

(defun RMR:SymCircle (c radius)
  (entmake
    (list '(0 . "CIRCLE") '(8 . "0") '(62 . 0)
          (cons 10 (RMR:3D c)) (cons 40 radius))
  )
)

(defun RMR:SymPoly (pts bulges closed / items index bulge)
  (setq items
    (list '(0 . "LWPOLYLINE") '(8 . "0") '(62 . 0)
          (cons 90 (length pts)) (cons 70 (if closed 1 0)))
  )
  (setq index 0)
  (foreach p pts
    (setq items (append items (list (cons 10 p))))
    (setq bulge (nth index bulges))
    (if bulge (setq items (append items (list (cons 42 bulge)))))
    (setq index (1+ index))
  )
  (entmake items)
)

(defun RMR:SymRect (p width height)
  (RMR:SymPoly
    (list p
          (list (+ (car p) width) (cadr p))
          (list (+ (car p) width) (+ (cadr p) height))
          (list (car p) (+ (cadr p) height)))
    nil T
  )
)

(defun RMR:SymText (p text height style)
  (entmake
    (list '(0 . "TEXT") '(8 . "0") '(62 . 0)
          (cons 10 (RMR:3D p)) (cons 40 height) (cons 1 text) (cons 7 style))
  )
)

(defun RMR:Attdef (tag prompt default height point style)
  (entmake
    (list '(0 . "ATTDEF") '(8 . "0") '(62 . 0)
          (cons 10 (RMR:3D point)) (cons 40 height) (cons 1 default)
          (cons 7 style) (cons 2 tag) (cons 3 prompt) '(70 . 0))
  )
)

(defun RMR:DropBlock (name / doc blk)
  (vl-load-com)
  (setq doc (vla-get-activedocument (vlax-get-acad-object)))
  (setq blk (vl-catch-all-apply 'vla-item (list (vla-get-blocks doc) name)))
  (if (not (vl-catch-all-error-p blk))
    (vl-catch-all-apply 'vla-delete (list blk))
  )
  T
)

(defun RMR:SymBegin (name refresh)
  ;; Returns T when the caller should draw a fresh block body.
  (if (tblsearch "BLOCK" name)
    (if refresh (progn (RMR:DropBlock name) T) nil)
    T
  )
)

;;; --- model-space poly with bulges (match lines, break lines, clouds)
(defun RMR:PolyLine (pts bulges closed layer rgb / items index bulge)
  (setq items
    (list '(0 . "LWPOLYLINE") (cons 8 layer) '(62 . 256)
          (cons 420 (RMR:RGB->420 rgb))
          (cons 90 (length pts)) (cons 70 (if closed 1 0)))
  )
  (setq index 0)
  (foreach p pts
    (setq items (append items (list (cons 10 p))))
    (setq bulge (nth index bulges))
    (if bulge (setq items (append items (list (cons 42 bulge)))))
    (setq index (1+ index))
  )
  (entmake items)
)

(defun RMR:SolidTri (tip ux uy size layer rgb / bx by px py q1 q2)
  (setq bx (- (car tip) (* ux size)))
  (setq by (- (cadr tip) (* uy size)))
  (setq px (- uy))
  (setq py ux)
  (setq q1 (list (+ bx (* px (* 0.35 size))) (+ by (* py (* 0.35 size)))))
  (setq q2 (list (- bx (* px (* 0.35 size))) (- by (* py (* 0.35 size)))))
  (entmake
    (list '(0 . "SOLID") (cons 8 layer)
          (cons 10 (RMR:3D tip)) (cons 11 (RMR:3D q1))
          (cons 12 (RMR:3D q2)) (cons 13 (RMR:3D q2))
          '(62 . 7) (cons 420 (RMR:RGB->420 rgb)))
  )
)

;;; --- attributes -------------------------------------------------------
(defun RMR:GetAttributes (ename / ent data out)
  (setq out nil)
  (if (= (cdr (assoc 66 (entget ename))) 1)
    (progn
      (setq ent (entnext ename))
      (while (and ent (setq data (entget ent))
                  (/= (cdr (assoc 0 data)) "SEQEND"))
        (if (= (cdr (assoc 0 data)) "ATTRIB")
          (setq out (cons (cons (cdr (assoc 2 data)) (cdr (assoc 1 data))) out))
        )
        (setq ent (entnext ent))
      )
    )
  )
  (reverse out)
)

(defun RMR:FillAttributes (ename pairs / ent data tag hit)
  (if (= (cdr (assoc 66 (entget ename))) 1)
    (progn
      (setq ent (entnext ename))
      (while (and ent (setq data (entget ent))
                  (/= (cdr (assoc 0 data)) "SEQEND"))
        (if (= (cdr (assoc 0 data)) "ATTRIB")
          (progn
            (setq tag (cdr (assoc 2 data)))
            (setq hit (assoc tag pairs))
            (if hit
              (entmod (subst (cons 1 (cdr hit)) (assoc 1 data) data))
            )
          )
        )
        (setq ent (entnext ent))
      )
    )
  )
  T
)

(defun RMR:InsertAttributed (name point layer / def ent data defs dp insert)
  (setq insert nil)
  (setq def (tblobjname "BLOCK" name))
  (if def
    (progn
      (setq defs nil)
      (setq ent (entnext def))
      (while (and ent (setq data (entget ent))
                  (/= (cdr (assoc 0 data)) "ENDBLK"))
        (if (= (cdr (assoc 0 data)) "ATTDEF")
          (setq defs (cons data defs))
        )
        (setq ent (entnext ent))
      )
      (setq defs (reverse defs))
      (setq insert
        (entmake
          (list '(0 . "INSERT") (cons 8 layer)
                (cons 66 (if defs 1 0))
                (cons 2 name) (cons 10 (RMR:3D point))
                '(41 . 1.0) '(42 . 1.0) '(50 . 0.0)))
      )
      (foreach d defs
        (setq dp (cdr (assoc 10 d)))
        (entmake
          (list '(0 . "ATTRIB") (cons 8 layer)
                (cons 10 (RMR:3D (list (+ (car point) (car dp))
                                       (+ (cadr point) (cadr dp)))))
                (cons 40 (cdr (assoc 40 d)))
                (cons 1 (RMR:ProjectValue (cdr (assoc 2 d)) ""))
                (cons 7 (cdr (assoc 7 d)))
                (cons 2 (cdr (assoc 2 d)))
                '(70 . 0)
                (cons 3 (cdr (assoc 3 d))))
        )
      )
      (if defs
        (entmake (list '(0 . "SEQEND") (cons 8 layer)))
      )
    )
  )
  insert
)

;;; --- branded title block with live attribute tags ---------------------
(defun RMR:BuildTitleBlock (/ w h)
  (if (tblsearch "BLOCK" "RMR-TITLEBLOCK") (RMR:DropBlock "RMR-TITLEBLOCK"))
  (setq w 180.0 h 60.0)
  (RMR:BeginBlock "RMR-TITLEBLOCK")
  (RMR:SymRect (list 0.0 0.0) w h)
  (RMR:SymLine (list 40.0 0.0) (list 40.0 h))
  (RMR:SymLine (list 140.0 0.0) (list 140.0 h))
  (RMR:SymLine (list 40.0 44.0) (list 140.0 44.0))
  (RMR:SymLine (list 40.0 34.0) (list 140.0 34.0))
  (RMR:SymLine (list 40.0 12.0) (list 140.0 12.0))
  (RMR:SymLine (list 70.0 0.0) (list 70.0 12.0))
  (RMR:SymLine (list 100.0 0.0) (list 100.0 12.0))
  (RMR:SymLine (list 140.0 44.0) (list w 44.0))
  (RMR:SymLine (list 160.0 44.0) (list 160.0 h))
  (RMR:SymLine (list 140.0 16.0) (list w 16.0))
  (RMR:SymLine (list 6.0 40.0) (list 34.0 40.0))
  (RMR:SymText (list 6.0 28.0) "RooMNRooF" 6.0 "RMR-TITLE")
  (RMR:SymText (list 6.0 20.0) "CONSULTANT" 2.4 "RMR-LABEL")
  (RMR:SymText (list 6.0 8.0) "ROOF THE ROOM" 2.4 "RMR-LABEL")
  (RMR:SymText (list 42.0 54.0) "CLIENT" 2.0 "RMR-LABEL")
  (RMR:SymText (list 42.0 40.0) "PROJECT" 2.0 "RMR-LABEL")
  (RMR:SymText (list 42.0 28.0) "DRAWING TITLE" 2.0 "RMR-LABEL")
  (RMR:SymText (list 42.0 8.0) "DRAWN" 1.8 "RMR-LABEL")
  (RMR:SymText (list 72.0 8.0) "CHECKED" 1.8 "RMR-LABEL")
  (RMR:SymText (list 102.0 8.0) "DATE" 1.8 "RMR-LABEL")
  (RMR:SymText (list 142.0 54.0) "SIZE" 1.8 "RMR-LABEL")
  (RMR:SymText (list 162.0 54.0) "SCALE" 1.8 "RMR-LABEL")
  (RMR:SymText (list 142.0 38.0) "DRAWING NO." 2.0 "RMR-LABEL")
  (RMR:SymText (list 142.0 12.0) "REV" 1.8 "RMR-LABEL")
  (RMR:Attdef "CLIENT"  "Client"         "" 3.2 (list 42.0 47.0)  "RMR-BODY")
  (RMR:Attdef "PROJECT" "Project"        "" 3.0 (list 42.0 35.5)  "RMR-BODY")
  (RMR:Attdef "TITLE"   "Drawing title"  "" 5.0 (list 42.0 18.0)  "RMR-SUBHEAD")
  (RMR:Attdef "DRAWN"   "Drawn by"       "" 2.5 (list 42.0 3.0)   "RMR-LABEL")
  (RMR:Attdef "CHECKED" "Checked by"     "" 2.5 (list 72.0 3.0)   "RMR-LABEL")
  (RMR:Attdef "DATE"    "Issue date"     "" 2.5 (list 102.0 3.0)  "RMR-LABEL")
  (RMR:Attdef "SIZE"    "Paper size"     "" 3.5 (list 142.0 47.0) "RMR-NUMBER")
  (RMR:Attdef "SCALE"   "Plot scale"     "" 3.0 (list 162.0 47.0) "RMR-LABEL")
  (RMR:Attdef "DWGNO"   "Drawing number" "" 7.0 (list 142.0 22.0) "RMR-HEAD")
  (RMR:Attdef "REV"     "Revision"       "" 4.0 (list 142.0 4.0)  "RMR-NUMBER")
  (RMR:EndBlock)
  T
)

;;; --- layouts and viewports --------------------------------------------
(defun C:RMR-LAYOUTS (/ doc name size spec kw ratio lay ps vp p1 p2 w h center)
  (RMR:EnsureReady)
  (vl-load-com)
  (setq doc (vla-get-activedocument (vlax-get-acad-object)))
  (setq size (RMR:PromptKeyword "Paper size" (RMR:KeywordBar "A0 A1 A2 A3 A4") "A1"))
  (if size
    (progn
      (setq spec (RMR:TableSpec size *RMR-PAPER-SPECS*))
      (setq w (nth 1 spec))
      (setq h (nth 2 spec))
      (setq name (RMR:PromptText "Layout name" (strcat size "-01")))
      (if (member name (layoutlist))
        (princ (strcat "\nLayout " name " already exists - nothing created."))
        (progn
          (setq lay (vl-catch-all-apply 'vla-add (list (vla-get-layouts doc) name)))
          (if (vl-catch-all-error-p lay)
            (princ (strcat "\nLayout creation failed: " (vl-catch-all-error-text lay)))
            (progn
              (setvar "CTAB" name)
              (RMR:SetProject "SIZE" size)
              (if (not (tblsearch "BLOCK" "RMR-TITLEBLOCK")) (RMR:BuildTitleBlock))
              (RMR:InsertAttributed "RMR-TITLEBLOCK"
                                    (list (- w 190.0) 5.0) "RMR-PRES-TITLE")
              (setq kw (RMR:PromptKeyword
                         "Viewport scale"
                         (strcat "NONE " (RMR:KeywordBar (RMR:KeywordList *RMR-SCALE-SPECS*)))
                         "50"))
              (if (/= kw "NONE")
                (progn
                  (setq spec (RMR:TableSpec kw *RMR-SCALE-SPECS*))
                  (setq ratio (nth 2 spec))
                  (setq p1 (list 20.0 75.0 0.0))
                  (setq p2 (list (- w 20.0) (- h 20.0) 0.0))
                  (setq center (list (* 0.5 (+ (car p1) (car p2)))
                                     (* 0.5 (+ (cadr p1) (cadr p2))) 0.0))
                  (vla-put-activespace doc acPaperSpace)
                  (setq ps (vla-get-paperspace doc))
                  (setq vp (vl-catch-all-apply
                             'vla-addpviewport
                             (list ps (vlax-3d-point center)
                                   (- (car p2) (car p1)) (- (cadr p2) (cadr p1)))))
                  (if (vl-catch-all-error-p vp)
                    (progn
                      (command "_.mview" (list (car p1) (cadr p1))
                               (list (car p2) (cadr p2)))
                      (setq vp (vl-catch-all-apply
                                 'vlax-ename->vla-object (list (entlast))))
                    )
                  )
                  (if (vl-catch-all-error-p vp)
                    (princ "\nViewport could not be created - add it manually.")
                    (progn
                      (if ratio (vla-put-customscale vp (/ 1.0 ratio)))
                      (vla-put-displaylocked vp :vlax-true)
                      (vl-catch-all-apply 'vla-put-layer (list vp "RMR-PRES-VPORT"))
                      (princ (strcat "\nViewport placed at " (nth 1 spec) " and locked."))
                    )
                  )
                )
              )
              (princ (strcat "\nLayout " name " (" size ") ready - run RMR-PAGESETUP for plot settings."))
            )
          )
        )
      )
    )
  )
  (princ)
)

(defun C:RMR-VPORT (/ doc p1 p2 kw spec ratio ps vp center w h x1 y1)
  (RMR:EnsureReady)
  (vl-load-com)
  (if (= (getvar "CTAB") "Model")
    (princ "\nSwitch to a layout (paper space) first.")
    (progn
      (setq p1 (getpoint "\nFirst viewport corner: "))
      (if p1
        (progn
          (setq p2 (getcorner p1 "\nOther viewport corner: "))
          (if p2
            (progn
              (setq kw (RMR:PromptKeyword
                         "Viewport scale"
                         (RMR:KeywordBar (RMR:KeywordList *RMR-SCALE-SPECS*)) "50"))
              (setq spec (RMR:TableSpec kw *RMR-SCALE-SPECS*))
              (setq ratio (nth 2 spec))
              (setq doc (vla-get-activedocument (vlax-get-acad-object)))
              (vla-put-activespace doc acPaperSpace)
              (setq ps (vla-get-paperspace doc))
              (setq w (abs (- (car p2) (car p1))))
              (setq h (abs (- (cadr p2) (cadr p1))))
              (setq center (list (* 0.5 (+ (car p1) (car p2)))
                                 (* 0.5 (+ (cadr p1) (cadr p2))) 0.0))
              (setq vp (vl-catch-all-apply
                         'vla-addpviewport
                         (list ps (vlax-3d-point center) w h)))
              (if (vl-catch-all-error-p vp)
                (progn
                  (command "_.mview" (list (car p1) (cadr p1))
                           (list (car p2) (cadr p2)))
                  (setq vp (vl-catch-all-apply
                             'vlax-ename->vla-object (list (entlast))))
                )
              )
              (if (vl-catch-all-error-p vp)
                (princ "\nViewport creation failed on this platform.")
                (progn
                  (if ratio (vla-put-customscale vp (/ 1.0 ratio)))
                  (vla-put-displaylocked vp :vlax-true)
                  (vl-catch-all-apply 'vla-put-layer (list vp "RMR-PRES-VPORT"))
                  (setq x1 (if (< (car p1) (car p2)) (car p1) (car p2)))
                  (setq y1 (if (< (cadr p1) (cadr p2)) (cadr p1) (cadr p2)))
                  (RMR:Text (list x1 (- y1 6.0))
                            (strcat "VIEWPORT " (nth 1 spec) " - LOCKED")
                            2.5 "RMR-LABEL" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
                  (princ (strcat "\nViewport created at " (nth 1 spec) " and locked."))
                )
              )
            )
          )
        )
      )
    )
  )
  (princ)
)

;;; --- section, elevation, match and break markers -----------------------
(defun RMR:SectionBubble (c number sheet radius)
  (RMR:Circle c radius "RMR-A-DETAIL" *RMR-BRAND-TERRA*)
  (RMR:Line (list (- (car c) radius) (cadr c))
            (list (+ (car c) radius) (cadr c))
            "RMR-A-DETAIL" *RMR-BRAND-TERRA*)
  (RMR:CenterText (list (car c) (+ (cadr c) (* radius 0.35))) number
                  (* radius 0.62) "RMR-NUMBER" "RMR-A-DETAIL" *RMR-BRAND-INK*)
  (RMR:CenterText (list (car c) (- (cadr c) (* radius 0.62))) sheet
                  (* radius 0.45) "RMR-LABEL" "RMR-A-DETAIL" *RMR-BRAND-INK*)
)

(defun C:RMR-SECTION (/ p1 p2 side num sheet s r ang perp mid vx vy ux uy dir t1 t2)
  (RMR:EnsureReady)
  (setq s (RMR:Scaled 1.0))
  (setq p1 (getpoint "\nStart of section cut: "))
  (if p1
    (progn
      (setq p2 (getpoint p1 "\nEnd of section cut: "))
      (if p2
        (progn
          (setq side (getpoint p2 "\nPick the viewing direction side: "))
          (if side
            (progn
              (setq num (RMR:PromptText "Section number" "1"))
              (setq sheet (RMR:PromptText "Sheet reference"
                                          (RMR:ProjectValue "DWGNO" "A-101")))
              (setq r (* 5.0 s))
              (setq ang (angle p1 p2))
              (setq perp (+ ang (/ pi 2.0)))
              (setq mid (list (* 0.5 (+ (car p1) (car p2)))
                              (* 0.5 (+ (cadr p1) (cadr p2)))))
              (setq vx (- (car side) (car mid)))
              (setq vy (- (cadr side) (cadr mid)))
              (setq ux (cos perp))
              (setq uy (sin perp))
              (if (< (+ (* vx ux) (* vy uy)) 0.0)
                (progn (setq ux (- ux)) (setq uy (- uy)))
              )
              (setq dir (list (cos ang) (sin ang)))
              (RMR:Line p1 p2 "RMR-A-DETAIL" *RMR-BRAND-TERRA*)
              (foreach end (list p1 p2)
                (setq t1 (list (+ (car end) (* ux (* 6.0 s)))
                               (+ (cadr end) (* uy (* 6.0 s)))))
                (RMR:Line end t1 "RMR-A-DETAIL" *RMR-BRAND-TERRA*)
                (setq t2 (list (+ (car t1) (* ux (* 3.0 s)))
                               (+ (cadr t1) (* uy (* 3.0 s)))))
                (RMR:SolidTri t2 ux uy (* 3.0 s) "RMR-A-DETAIL" *RMR-BRAND-TERRA*)
              )
              (RMR:SectionBubble
                (list (- (car p1) (* (car dir) (* 9.0 s)))
                      (- (cadr p1) (* (cadr dir) (* 9.0 s))))
                num sheet r)
              (RMR:SectionBubble
                (list (+ (car p2) (* (car dir) (* 9.0 s)))
                      (+ (cadr p2) (* (cadr dir) (* 9.0 s))))
                num sheet r)
              (princ (strcat "\nSection " num " marked, looking to the picked side."))
            )
          )
        )
      )
    )
  )
  (princ)
)

(defun C:RMR-ELEVATION (/ p rot num sheet s r ux uy tip)
  (RMR:EnsureReady)
  (setq s (RMR:Scaled 1.0))
  (setq p (getpoint "\nElevation marker centre: "))
  (if p
    (progn
      (setq rot (RMR:PromptAngle "Viewing direction angle" 0.0))
      (setq num (RMR:PromptText "Elevation number" "E1"))
      (setq sheet (RMR:PromptText "Sheet reference"
                                  (RMR:ProjectValue "DWGNO" "A-101")))
      (setq r (* 5.0 s))
      (setq rot (* rot (/ pi 180.0)))
      (setq ux (cos rot))
      (setq uy (sin rot))
      (RMR:Circle p r "RMR-A-DETAIL" *RMR-BRAND-TEAL*)
      (RMR:Line (list (- (car p) (* ux r)) (- (cadr p) (* uy r)))
                (list (+ (car p) (* ux r)) (+ (cadr p) (* uy r)))
                "RMR-A-DETAIL" *RMR-BRAND-TEAL*)
      (RMR:CenterText (list (+ (car p) (* (- uy) (* r 0.45)))
                            (+ (cadr p) (* ux (* r 0.45))))
                      num (* r 0.62) "RMR-NUMBER" "RMR-A-DETAIL" *RMR-BRAND-INK*)
      (RMR:CenterText (list (+ (car p) (* uy (* r 0.50)))
                            (+ (cadr p) (* (- ux) (* r 0.50))))
                      sheet (* r 0.45) "RMR-LABEL" "RMR-A-DETAIL" *RMR-BRAND-INK*)
      (setq tip (list (+ (car p) (* ux (+ r (* 4.0 s))))
                      (+ (cadr p) (* uy (+ r (* 4.0 s))))))
      (RMR:Line (list (+ (car p) (* ux r)) (+ (cadr p) (* uy r))) tip
                "RMR-A-DETAIL" *RMR-BRAND-TEAL*)
      (RMR:SolidTri (list (+ (car tip) (* ux (* 3.0 s)))
                          (+ (cadr tip) (* uy (* 3.0 s))))
                    ux uy (* 3.0 s) "RMR-A-DETAIL" *RMR-BRAND-TEAL*)
      (princ (strcat "\nElevation " num " marked."))
    )
  )
  (princ)
)

(defun C:RMR-MATCHLINE (/ p1 p2 sheet s ang lab off u1 u2)
  (RMR:EnsureReady)
  (setq s (RMR:Scaled 1.0))
  (setq p1 (getpoint "\nMatch line start: "))
  (if p1
    (progn
      (setq p2 (getpoint p1 "\nMatch line end: "))
      (if p2
        (progn
          (setq sheet (RMR:PromptText "Adjoining sheet" "A-102"))
          (setq ang (angle p1 p2))
          ;; (angle ...) returns 0..2pi. Flip 90..270 by 180 degrees and anything
          ;; past 270 by 360 so the match-line label always reads upright.
          (cond
            ((and (> ang (* pi 0.5)) (<= ang (* pi 1.5))) (setq ang (- ang pi)))
            ((> ang (* pi 1.5)) (setq ang (- ang (* 2.0 pi))))
          )
          (RMR:Line p1 p2 "RMR-A-MATCH" *RMR-BRAND-SLATE*)
          (setq lab (strcat "MATCH LINE - SEE " sheet))
          (setq off (* 3.0 s))
          (setq u1 (list (+ (car p1) (* (cos (+ ang (/ pi 2.0))) off))
                         (+ (cadr p1) (* (sin (+ ang (/ pi 2.0))) off))))
          (setq u2 (list (+ (car p2) (* (cos (+ ang (/ pi 2.0))) off))
                         (+ (cadr p2) (* (sin (+ ang (/ pi 2.0))) off))))
          (RMR:RotText u1 lab (* 2.5 s) "RMR-LABEL" "RMR-A-MATCH" *RMR-BRAND-SLATE* ang)
          (RMR:RotText u2 lab (* 2.5 s) "RMR-LABEL" "RMR-A-MATCH" *RMR-BRAND-SLATE* ang)
          (princ "\nMatch line placed on RMR-A-MATCH (phantom).")
        )
      )
    )
  )
  (princ)
)

(defun C:RMR-BREAKLINE (/ p1 p2 d a b c pts bul)
  (RMR:EnsureReady)
  (setq p1 (getpoint "\nBreak line start: "))
  (if p1
    (progn
      (setq p2 (getpoint p1 "\nBreak line end: "))
      (if p2
        (progn
          (setq d (list (- (car p2) (car p1)) (- (cadr p2) (cadr p1))))
          (setq a (list (+ (car p1) (* (car d) 0.40))
                        (+ (cadr p1) (* (cadr d) 0.40))))
          (setq b (list (+ (car p1) (* (car d) 0.50))
                        (+ (cadr p1) (* (cadr d) 0.50))))
          (setq c (list (+ (car p1) (* (car d) 0.60))
                        (+ (cadr p1) (* (cadr d) 0.60))))
          (setq pts (list p1 a b c p2))
          (setq bul (list nil 0.9 -0.9 nil nil))
          (RMR:PolyLine pts bul nil "RMR-A-MATCH" *RMR-BRAND-SLATE*)
          (princ "\nBreak line placed.")
        )
      )
    )
  )
  (princ)
)

(defun RMR:RectSamples (a b step / pts edges e len n i d ang)
  (setq pts nil)
  (setq edges (list (list a (list (car b) (cadr a)))
                    (list (list (car b) (cadr a)) b)
                    (list b (list (car a) (cadr b)))
                    (list (list (car a) (cadr b)) a)))
  (foreach e edges
    (setq len (distance (car e) (cadr e)))
    (setq n (fix (/ len step)))
    (if (< n 2) (setq n 2))
    (setq d (/ len (float n)))
    (setq ang (angle (car e) (cadr e)))
    (setq i 0)
    (while (< i n)
      (setq pts (cons (list (+ (car (car e)) (* (cos ang) (* d i)))
                            (+ (cadr (car e)) (* (sin ang) (* d i))))
                      pts))
      (setq i (1+ i))
    )
  )
  (reverse pts)
)

(defun C:RMR-REVCLOUD (/ p pts next s chord done a b)
  (RMR:EnsureReady)
  (setq s (RMR:Scaled 1.0))
  (setq chord (* 10.0 s))
  (setq p (getpoint "\nFirst cloud point (2 points = rectangle): "))
  (if p
    (progn
      (setq pts (list p))
      (setq done nil)
      (while (not done)
        (setq next (getpoint (last pts) "\nNext cloud point <enter to finish>: "))
        (if next
          (setq pts (append pts (list next)))
          (setq done T)
        )
      )
      (if (= (length pts) 2)
        (progn
          (setq a (car pts))
          (setq b (cadr pts))
          (setq pts (RMR:RectSamples a b chord))
        )
      )
      (if (< (length pts) 3)
        (princ "\nA cloud needs at least three points.")
        (progn
          (RMR:PolyLine pts
                        (mapcar '(lambda (x) *RMR-CLOUD-ARC*) pts)
                        T "RMR-A-REVISION" *RMR-BRAND-TERRA*)
          (princ "\nRevision cloud placed - tag it with RMR-REVISION.")
        )
      )
    )
  )
  (princ)
)

;;; --- dimension launcher ------------------------------------------------
(defun C:RMR-DIM (/ kw ty style)
  (RMR:EnsureReady)
  (setq kw (RMR:PromptKeyword "Dimension style"
                              (RMR:KeywordBar "PLAN DETAIL LARGE") "PLAN"))
  (if kw
    (progn
      (setq style (strcat "RMR-DIM-" kw))
      (setq ty (RMR:PromptKeyword "Dimension type"
                                  (RMR:KeywordBar "LINEAR ALIGN ORD RAD ANG CONT")
                                  "LINEAR"))
      (if ty
        (progn
          (setvar "CLAYER" "RMR-A-DIMS")
          (command "_.-dimstyle" "_R" style)
          (princ (strcat "\n" style " current on RMR-A-DIMS - pick dimension points."))
          (cond
            ((= ty "LINEAR") (command "_.dimlinear"))
            ((= ty "ALIGN")  (command "_.dimaligned"))
            ((= ty "ORD")    (command "_.dimordinate"))
            ((= ty "RAD")    (command "_.dimradius"))
            ((= ty "ANG")    (command "_.dimangular"))
            ((= ty "CONT")   (command "_.dimcontinue"))
          )
        )
      )
    )
  )
  (princ)
)

;;; --- text search and replace -------------------------------------------
(defun RMR:ReplaceAll (str find rep / pos out)
  (if (= find "")
    str
    (progn
      (setq out "")
      (while (setq pos (vl-string-search find str))
        (setq out (strcat out (substr str 1 pos) rep))
        (setq str (substr str (+ pos (strlen find) 1)))
      )
      (strcat out str)
    )
  )
)

(defun C:RMR-FINDTEXT (/ search replace ss i ent data str new wild count)
  (RMR:EnsureReady)
  (setq search (RMR:PromptText "Text to find (wildcards allowed)" ""))
  (if (/= search "")
    (progn
      (setq replace (RMR:PromptText "Replacement (empty removes the match)" ""))
      (setq wild (vl-string-search "*" search))
      (setq ss (ssget "X" '((0 . "TEXT,MTEXT,ATTRIB"))))
      (if ss
        (progn
          (setq count 0 i 0)
          (repeat (sslength ss)
            (setq ent (ssname ss i))
            (setq data (entget ent))
            (setq str (cdr (assoc 1 data)))
            (if (and str (RMR:MatchFilter str search))
              (progn
                (cond
                  (wild (setq new replace))
                  (T (setq new (RMR:ReplaceAll str search replace)))
                )
                (entmod (subst (cons 1 new) (assoc 1 data) data))
                (setq count (1+ count))
              )
            )
            (setq i (1+ i))
          )
          (princ (strcat "\nUpdated " (itoa count) " text object(s)."))
        )
        (princ "\nNo TEXT, MTEXT or ATTRIB entities in this drawing.")
      )
    )
  )
  (princ)
)

;;; --- parametric symbol library -----------------------------------------
(defun RMR:BuildDoor (name width double / w)
  (RMR:BeginBlock name)
  (setq w width)
  (if double
    (progn
      (RMR:SymLine (list 0.0 0.0) (list 0.0 (/ w 2.0)))
      (RMR:SymArc (list 0.0 0.0) (/ w 2.0) 0.0 (/ pi 2.0))
      (RMR:SymLine (list w 0.0) (list w (/ w 2.0)))
      (RMR:SymArc (list w 0.0) (/ w 2.0) (/ pi 2.0) pi)
    )
    (progn
      (RMR:SymLine (list 0.0 0.0) (list 0.0 w))
      (RMR:SymArc (list 0.0 0.0) w 0.0 (/ pi 2.0))
    )
  )
  (RMR:Attdef "TAG"   "Door tag"   "D01" 2.5 (list (* 0.5 w) -12.0) "RMR-NUMBER")
  (RMR:Attdef "WIDTH" "Leaf width" (itoa (fix w)) 2.5 (list (* 0.5 w) -18.0) "RMR-LABEL")
  (RMR:EndBlock)
)

(defun C:RMR-SYMBOLS (/ refresh built spec)
  (RMR:EnsureReady)
  (setq refresh (RMR:YesP (RMR:PromptYesNo "Rebuild existing symbol blocks" "No")))
  (setq built 0)
  (foreach spec '(("RMR-SYM-DOOR-07"  700.0  nil)
                  ("RMR-SYM-DOOR-08"  800.0  nil)
                  ("RMR-SYM-DOOR-09"  900.0  nil)
                  ("RMR-SYM-DOOR-10" 1000.0  nil)
                  ("RMR-SYM-DOORD-15" 1500.0 T))
    (if (RMR:SymBegin (nth 0 spec) refresh)
      (progn
        (RMR:BuildDoor (nth 0 spec) (nth 1 spec) (nth 2 spec))
        (setq built (1+ built))
      )
    )
  )
  (if (RMR:SymBegin "RMR-SYM-WINDOW" refresh)
    (progn
      (RMR:BeginBlock "RMR-SYM-WINDOW")
      (RMR:SymRect (list 0.0 0.0) 1200.0 200.0)
      (RMR:SymLine (list 0.0 70.0) (list 1200.0 70.0))
      (RMR:SymLine (list 0.0 130.0) (list 1200.0 130.0))
      (RMR:EndBlock)
      (setq built (1+ built))
    )
  )
  (if (RMR:SymBegin "RMR-SYM-WC" refresh)
    (progn
      (RMR:BeginBlock "RMR-SYM-WC")
      (RMR:SymRect (list 0.0 350.0) 400.0 150.0)
      (RMR:SymCircle (list 200.0 175.0) 175.0)
      (RMR:EndBlock)
      (setq built (1+ built))
    )
  )
  (if (RMR:SymBegin "RMR-SYM-BASIN" refresh)
    (progn
      (RMR:BeginBlock "RMR-SYM-BASIN")
      (RMR:SymRect (list 0.0 0.0) 500.0 400.0)
      (RMR:SymCircle (list 250.0 200.0) 90.0)
      (RMR:EndBlock)
      (setq built (1+ built))
    )
  )
  (if (RMR:SymBegin "RMR-SYM-SHOWER" refresh)
    (progn
      (RMR:BeginBlock "RMR-SYM-SHOWER")
      (RMR:SymRect (list 0.0 0.0) 900.0 900.0)
      (RMR:SymLine (list 0.0 0.0) (list 900.0 900.0))
      (RMR:SymLine (list 900.0 0.0) (list 0.0 900.0))
      (RMR:SymCircle (list 450.0 450.0) 60.0)
      (RMR:EndBlock)
      (setq built (1+ built))
    )
  )
  (if (RMR:SymBegin "RMR-SYM-BED-S" refresh)
    (progn
      (RMR:BeginBlock "RMR-SYM-BED-S")
      (RMR:SymRect (list 0.0 0.0) 1000.0 2000.0)
      (RMR:SymLine (list 0.0 1700.0) (list 1000.0 1700.0))
      (RMR:SymRect (list 300.0 1750.0) 400.0 200.0)
      (RMR:EndBlock)
      (setq built (1+ built))
    )
  )
  (if (RMR:SymBegin "RMR-SYM-BED-D" refresh)
    (progn
      (RMR:BeginBlock "RMR-SYM-BED-D")
      (RMR:SymRect (list 0.0 0.0) 1500.0 2000.0)
      (RMR:SymLine (list 0.0 1700.0) (list 1500.0 1700.0))
      (RMR:SymRect (list 200.0 1750.0) 450.0 200.0)
      (RMR:SymRect (list 850.0 1750.0) 450.0 200.0)
      (RMR:EndBlock)
      (setq built (1+ built))
    )
  )
  (if (RMR:SymBegin "RMR-SYM-DESK" refresh)
    (progn
      (RMR:BeginBlock "RMR-SYM-DESK")
      (RMR:SymRect (list 0.0 0.0) 1400.0 700.0)
      (RMR:SymLine (list 0.0 600.0) (list 1400.0 600.0))
      (RMR:EndBlock)
      (setq built (1+ built))
    )
  )
  (if (RMR:SymBegin "RMR-SYM-CHAIR" refresh)
    (progn
      (RMR:BeginBlock "RMR-SYM-CHAIR")
      (RMR:SymRect (list 0.0 0.0) 450.0 450.0)
      (RMR:SymRect (list 0.0 450.0) 450.0 80.0)
      (RMR:EndBlock)
      (setq built (1+ built))
    )
  )
  (if (RMR:SymBegin "RMR-SYM-SOFA" refresh)
    (progn
      (RMR:BeginBlock "RMR-SYM-SOFA")
      (RMR:SymRect (list 0.0 0.0) 1800.0 850.0)
      (RMR:SymLine (list 0.0 700.0) (list 1800.0 700.0))
      (RMR:SymLine (list 150.0 0.0) (list 150.0 850.0))
      (RMR:SymLine (list 1650.0 0.0) (list 1650.0 850.0))
      (RMR:EndBlock)
      (setq built (1+ built))
    )
  )
  (if (RMR:SymBegin "RMR-SYM-WASHER" refresh)
    (progn
      (RMR:BeginBlock "RMR-SYM-WASHER")
      (RMR:SymRect (list 0.0 0.0) 600.0 600.0)
      (RMR:SymCircle (list 300.0 300.0) 200.0)
      (RMR:EndBlock)
      (setq built (1+ built))
    )
  )
  (princ (strcat "\nSymbol library: " (itoa built)
                 " block(s) built or refreshed (RMR-SYM-*)."))
  (princ "\nPlace them with -INSERT, DesignCenter or the tool palettes.")
  (princ)
)

;;; --- door schedule -----------------------------------------------------
(defun RMR:DrawDoorTable (base rows / s colw rowh width y text i row)
  (setq s (RMR:Scaled 1.0))
  (setq text (* 2.5 s))
  (setq colw (list (* 16.0 s) (* 54.0 s) (* 34.0 s) (* 36.0 s)))
  (setq width (+ (nth 0 colw) (nth 1 colw) (nth 2 colw) (nth 3 colw)))
  (setq rowh (* 8.0 s))
  (setq y (cadr base))
  (RMR:Text base "DOOR SCHEDULE" (* 4.5 s) "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-TERRA*)
  (RMR:Text (RMR:PT+ base 0.0 (- (* 5.5 s)))
            (strcat "PROJECT " (RMR:ProjectValue "PROJECT" "") "   |   SCALE "
                    *RMR-DRAW-SCALE-LABEL*)
            (* 2.2 s) "RMR-NOTE" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
  (setq y (- y (* 13.0 s)))
  (RMR:Solid (list (car base) (- y rowh) 0.0) width rowh "RMR-PRES-TITLE" *RMR-BRAND-SAND*)
  (RMR:Text (RMR:PT+ (list (car base) (- y rowh) 0.0) (* 2.0 s) (* 2.2 s)) "NO." text "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-INK*)
  (RMR:Text (RMR:PT+ (list (+ (car base) (nth 0 colw)) (- y rowh) 0.0) (* 2.0 s) (* 2.2 s)) "TAG" text "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-INK*)
  (RMR:Text (RMR:PT+ (list (+ (car base) (nth 0 colw) (nth 1 colw)) (- y rowh) 0.0) (* 2.0 s) (* 2.2 s)) "TYPE" text "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-INK*)
  (RMR:Text (RMR:PT+ (list (+ (car base) (nth 0 colw) (nth 1 colw) (nth 2 colw)) (- y rowh) 0.0) (* 2.0 s) (* 2.2 s)) "WIDTH mm" text "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-INK*)
  (RMR:TableDividers (car base) (- y rowh) colw rowh "RMR-A-FRAME" *RMR-BRAND-INK*)
  (setq y (- y rowh))
  (setq i 0)
  (foreach row rows
    (RMR:Rect (list (car base) (- y rowh) 0.0) width rowh "RMR-A-FRAME" *RMR-BRAND-SLATE*)
    (RMR:TableDividers (car base) (- y rowh) colw rowh "RMR-A-FRAME" *RMR-BRAND-SLATE*)
    (RMR:Text (RMR:PT+ (list (car base) (- y rowh) 0.0) (* 2.0 s) (* 2.2 s))
              (itoa (1+ i)) text "RMR-NUMBER" "RMR-A-TEXT" *RMR-BRAND-TERRA*)
    (RMR:Text (RMR:PT+ (list (+ (car base) (nth 0 colw)) (- y rowh) 0.0) (* 2.0 s) (* 2.2 s))
              (nth 0 row) text "RMR-LABEL" "RMR-A-TEXT" *RMR-BRAND-INK*)
    (RMR:Text (RMR:PT+ (list (+ (car base) (nth 0 colw) (nth 1 colw)) (- y rowh) 0.0) (* 2.0 s) (* 2.2 s))
              (nth 2 row) text "RMR-BODY" "RMR-A-TEXT" *RMR-BRAND-INK*)
    (RMR:Text (RMR:PT+ (list (+ (car base) (nth 0 colw) (nth 1 colw) (nth 2 colw)) (- y rowh) 0.0) (* 2.0 s) (* 2.2 s))
              (nth 1 row) text "RMR-BODY" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
    (setq i (1+ i))
    (setq y (- y rowh))
  )
  (princ (strcat "\nDoor schedule: " (itoa (length rows)) " door(s) listed."))
  T
)

(defun C:RMR-DOORSCHED (/ ss i ent data name attrs tag width typ rows pt)
  (RMR:EnsureReady)
  (setq ss (ssget '((0 . "INSERT") (66 . 1))))
  (if ss
    (progn
      (setq rows nil i 0)
      (repeat (sslength ss)
        (setq ent (ssname ss i))
        (setq data (entget ent))
        (setq name (cdr (assoc 2 data)))
        (if (wcmatch (strcase name) "RMR-SYM-DOOR*")
          (progn
            (setq attrs (RMR:GetAttributes ent))
            (setq tag (cdr (assoc "TAG" attrs)))
            (setq width (cdr (assoc "WIDTH" attrs)))
            (if (not tag) (setq tag ""))
            (if (not width) (setq width ""))
            (if (wcmatch (strcase name) "RMR-SYM-DOORD*")
              (setq typ "DOUBLE LEAF")
              (setq typ "SINGLE LEAF")
            )
            (setq rows (cons (list tag width typ) rows))
          )
        )
        (setq i (1+ i))
      )
      (setq rows
        (vl-sort rows '(lambda (a b) (< (car a) (car b)))))
      (if rows
        (progn
          (setq pt (getpoint "\nTop-left of door schedule: "))
          (if pt (RMR:DrawDoorTable pt rows))
        )
        (princ "\nNo RMR-SYM-DOOR* blocks with TAG / WIDTH attributes were selected.")
      )
    )
    (princ "\nNo attributed blocks selected - run RMR-SYMBOLS and insert doors first.")
  )
  (princ)
)

;;; --- live fields and project data --------------------------------------
(defun C:RMR-FIELDS (/ kw pt code)
  (RMR:EnsureReady)
  (setq kw (RMR:PromptKeyword
             "Field to insert"
             (RMR:KeywordBar "DATE JOBSHEET DRAWING LAYOUT TITLE DWGNO REV AREA BLOCKNAME")
             "DATE"))
  (if kw
    (progn
      (setq pt (getpoint "\nField insertion point: "))
      (if pt
        (progn
          (setq code
            (cond
              ((= kw "DATE")     "\\AcVar Date")
              ((= kw "JOBSHEET") "\\AcObjProp Object(%<\\_ObjId 0>%).Scale")
              ((= kw "DRAWING")  "\\AcVar DWGNAME")
              ((= kw "LAYOUT")   "\\AcVar CTAB")
              ((= kw "TITLE")    "\\AcVar DWGTITLE")
              ((= kw "DWGNO")    "\\AcVar DWGPREFIX")
              ((= kw "AREA")     "\\AcObjProp Object(%<\\_ObjId 0>%).Area")
              ((= kw "BLOCKNAME") "\\AcObjProp Object(%<\\_ObjId 0>%).Name")
            )
          )
          (if (member kw '("TITLE" "DWGNO" "REV"))
            (setq code (RMR:ProjectValue kw kw))
          )
          (RMR:Text pt code (* 3.0 (RMR:Scaled 1.0)) "RMR-BODY" "RMR-A-TEXT" *RMR-BRAND-INK*)
          (if (member kw '("DATE" "JOBSHEET" "DRAWING" "LAYOUT" "AREA" "BLOCKNAME"))
            (princ "\nField code inserted - regen or UPDATEFIELD refreshes it.")
            (princ (strcat "\nProject value \"" code "\" inserted as static text."))
          )
        )
      )
    )
  )
  (princ)
)

(defun C:RMR-PROJECT (/ kw value item ss i path)
  (RMR:EnsureReady)
  (setq kw (RMR:PromptKeyword
             "Project data"
             (RMR:KeywordBar "SHOW SET FILLTITLE SAVE LOAD") "SHOW"))
  (cond
    ((= kw "SHOW")
      (princ "\n-------------------------------------------------")
      (foreach item (RMR:ProjectPairs)
        (princ (strcat "\n " (car item) " = " (cdr item)))
      )
      (princ "\n-------------------------------------------------")
    )
    ((= kw "SET")
      (foreach item (RMR:ProjectPairs)
        (setq value (RMR:PromptText (car item) (cdr item)))
        (RMR:SetProject (car item) value)
      )
      (princ "\nProject data stored in *RMR-PROJECT*.")
    )
    ((= kw "FILLTITLE")
      (if (not (tblsearch "BLOCK" "RMR-TITLEBLOCK")) (RMR:BuildTitleBlock))
      (setq ss (ssget "X" '((0 . "INSERT") (2 . "RMR-TITLEBLOCK"))))
      (if ss
        (progn
          (setq i 0)
          (repeat (sslength ss)
            (RMR:FillAttributes (ssname ss i) (RMR:ProjectPairs))
            (setq i (1+ i))
          )
          (princ (strcat "\nFilled " (itoa (sslength ss)) " title block(s)."))
        )
        (princ "\nNo RMR-TITLEBLOCK inserted - run RMR-LAYOUTS first.")
      )
    )
    ((= kw "SAVE")
      (if (RMR:WriteLines (getfiled "Save project data" (strcat (RMR:ProjectValue "JOB" "job") ".rmr") "rmr" 1)
                          (mapcar '(lambda (x) (strcat (car x) "=" (cdr x)))
                                  (RMR:ProjectPairs)))
        (princ "\nProject data written.")
        (princ "\nProject data not written.")
      )
    )
    ((= kw "LOAD")
      (setq path (getfiled "Load project data" "" "rmr" 4))
      (if path
        (foreach item (RMR:ReadLines path)
          (if (vl-string-search "=" item)
            (RMR:SetProject
              (substr item 1 (vl-string-search "=" item))
              (substr item (+ 2 (vl-string-search "=" item))))
          )
        )
      )
      (princ "\nProject data loaded.")
    )
  )
  (princ)
)

;;; --- timestamped backup -------------------------------------------------
(defun C:RMR-BACKUP (/ pre src dst stamp cdate)
  (RMR:EnsureReady)
  (setq src (getvar "DWGNAME"))
  (if (or (not src) (= src "") (= src "Drawing1.dwg"))
    (princ "\nSave the drawing at least once before backing it up.")
    (progn
      (setq pre (RMR:PromptText "Backup prefix" "BACKUP_"))
      (setq cdate (rtos (getvar "CDATE") 2 6))
      (setq stamp (strcat (substr cdate 1 8) "-" (substr cdate 10 4)))
      (setq dst (strcat (getvar "DWGPREFIX") pre stamp "_" src))
      (command "_.saveas" "" dst)
      (if (findfile dst)
        (princ (strcat "\nBackup saved to " dst " - returning you to the backup drawing."))
        (princ "\nBackup not written - check the folder permissions.")
      )
    )
  )
  (princ)
)

;;; =====================================================================
;;; PRO 5.0 DELIVERY SUITE
;;; Parametric geometry (walls, stairs), quantification (lengths, bill of
;;; materials), delivery documents (finishes, sheet register, xref
;;; register, transmittal) and drawing housekeeping (layer states,
;;; ByLayer standardisation, clean-up, drawing properties).
;;; =====================================================================

;;; Wall types: (Key Thickness Layer Description)
(setq *RMR-WALL-SPECS*
 '(
    ("W100" 100 "RMR-M-WALL" "100mm internal partition")
    ("W150" 150 "RMR-M-WALL" "150mm internal partition")
    ("W200" 200 "RMR-S-SLAB" "200mm blockwork wall")
    ("W250" 250 "RMR-S-SLAB" "250mm party / core wall")
    ("W300" 300 "RMR-S-FOUND" "300mm retaining or foundation wall")
  )
)

;;; Room finishes: (Room Floor Skirting Wall Ceiling Notes)
(setq *RMR-FINISH-SPECS*
 '(
    ("LIVING / DINING" "Porcelain tile 600x600" "Tile 100mm" "Matte emulsion" "Gypsum board" "Feature wall to TV")
    ("MASTER BEDROOM" "Engineered oak" "Timber 100mm" "Matte emulsion" "Gypsum board" "Wardrobe to bed wall")
    ("BEDROOM 02" "Engineered oak" "Timber 100mm" "Matte emulsion" "Gypsum board" "Built-in wardrobe")
    ("KITCHEN" "Porcelain tile 600x600" "Tile 100mm" "Ceramic tile to 1500" "Moisture board" "Splashback to hob")
    ("BATHROOM" "Non-slip tile 300x300" "Waterproof 100mm" "Ceramic tile full height" "Moisture board" "Tanked to wet areas")
    ("BALCONY" "External tile 300x300" "None" "External paint" "Soffit lining" "Fall 1:80 to drain")
  )
)

;;; Drawing register: (SheetNumber Title Scale Revision Status)
(setq *RMR-SHEET-LIST*
 '(
    ("A-000" "COVER SHEET AND DRAWING REGISTER" "NTS" "01" "ISSUED FOR REVIEW")
    ("A-101" "GENERAL ARRANGEMENT PLAN" "1:50" "01" "ISSUED FOR REVIEW")
    ("A-102" "ENLARGED PLANS AND SECTIONS" "1:50" "01" "ISSUED FOR REVIEW")
    ("A-201" "ELEVATIONS" "1:100" "01" "ISSUED FOR REVIEW")
    ("A-301" "DOOR AND WINDOW SCHEDULES" "NTS" "01" "ISSUED FOR REVIEW")
    ("A-401" "FINISHES AND ROOM DATA" "NTS" "01" "ISSUED FOR REVIEW")
  )
)

;;; --- geometry helpers --------------------------------------------------
(defun RMR:UnitNormal (p1 p2 / dx dy len)
  ;; Left-hand unit normal of the segment p1 -> p2.
  (setq dx (- (car p2) (car p1)))
  (setq dy (- (cadr p2) (cadr p1)))
  (setq len (distance p1 p2))
  (if (< len 0.000001)
    '(0.0 0.0)
    (list (/ (- dy) len) (/ dx len))
  )
)

(defun RMR:OffsetPath (pts d / out n i cur prev next n1 n2 mx my len scale)
  ;; Mitred offset of a polyline path. Positive d offsets to the left.
  (setq out '())
  (setq n (length pts))
  (setq i 0)
  (while (< i n)
    (setq cur (nth i pts))
    (cond
      ((= i 0)
        (setq next (nth (1+ i) pts))
        (setq n1 (RMR:UnitNormal cur next))
        (setq out (cons (list (+ (car cur) (* (car n1) d))
                              (+ (cadr cur) (* (cadr n1) d))) out))
      )
      ((= i (1- n))
        (setq prev (nth (1- i) pts))
        (setq n1 (RMR:UnitNormal prev cur))
        (setq out (cons (list (+ (car cur) (* (car n1) d))
                              (+ (cadr cur) (* (cadr n1) d))) out))
      )
      (T
        (setq prev (nth (1- i) pts))
        (setq next (nth (1+ i) pts))
        (setq n1 (RMR:UnitNormal prev cur))
        (setq n2 (RMR:UnitNormal cur next))
        (setq mx (+ (car n1) (car n2)))
        (setq my (+ (cadr n1) (cadr n2)))
        (setq len (sqrt (+ (* mx mx) (* my my))))
        (if (< len 0.000001)
          (progn (setq mx (car n1)) (setq my (cadr n1)) (setq len 1.0))
        )
        (setq scale (/ d (/ (+ (* mx (car n1)) (* my (cadr n1))) len)))
        ;; guard against extreme mitres on shallow corners
        (if (> (abs scale) (* 4.0 (abs d))) (setq scale (* 4.0 (abs d))))
        (if (< (abs scale) (abs d)) (setq scale d))
        (setq out (cons (list (+ (car cur) (* (/ mx len) scale))
                              (+ (cadr cur) (* (/ my len) scale))) out))
      )
    )
    (setq i (1+ i))
  )
  (reverse out)
)

;;; --- parametric wall ---------------------------------------------------
(defun C:RMR-WALL (/ keyword spec thickness layer pts p next left right s mid index)
  (RMR:EnsureReady)
  (setq keyword (RMR:PromptKeyword
                  "Wall type"
                  (RMR:KeywordBar (RMR:KeywordList *RMR-WALL-SPECS*)) "W100"))
  (if keyword
    (progn
      (setq spec (RMR:TableSpec keyword *RMR-WALL-SPECS*))
      (setq thickness (nth 1 spec))
      (setq layer (nth 2 spec))
      (setq pts '())
      (setq p (getpoint "\nWall start point: "))
      (while p
        (setq pts (append pts (list (list (car p) (cadr p)))))
        (setq p (getpoint (last pts) "\nNext wall point <enter to finish>: "))
      )
      (if (< (length pts) 2)
        (princ "\nA wall needs at least two points.")
        (progn
          (setq s (RMR:Scaled 1.0))
          (setq left (RMR:OffsetPath pts (/ (float thickness) 2.0)))
          (setq right (RMR:OffsetPath pts (- (/ (float thickness) 2.0))))
          (RMR:PolyLine left nil nil layer *RMR-BRAND-TERRA*)
          (RMR:PolyLine right nil nil layer *RMR-BRAND-TERRA*)
          (RMR:Line (nth 0 left) (nth 0 right) layer *RMR-BRAND-TERRA*)
          (RMR:Line (last left) (last right) layer *RMR-BRAND-TERRA*)
          (setq index (1- (length pts)))
          (setq mid (nth (/ index 2) pts))
          (RMR:Text (list (+ (car mid) (* 2.0 s)) (+ (cadr mid) (* 2.0 s)))
                    (strcat keyword " / " (itoa thickness) "mm")
                    (* 2.2 s) "RMR-LABEL" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
          (princ (strcat "\n" keyword " wall drawn: " (itoa thickness) "mm thick on " layer "."))
        )
      )
    )
  )
  (princ)
)

;;; --- parametric straight stair ------------------------------------------
(defun RMR:StairPlan (base width going risers angle layer / s total dirx diry nx ny
                      i y p1 p2 p3 p4 midx midy-base start tip)
  (setq s (RMR:Scaled 1.0))
  (setq total (* (float risers) (float going)))
  (setq dirx (cos angle))
  (setq diry (sin angle))
  (setq nx (- diry))
  (setq ny dirx)
  ;; outline: base is the bottom-left corner, stair runs along the direction
  (setq p1 base)
  (setq p2 (list (+ (car base) (* nx (float width)))
                 (+ (cadr base) (* ny (float width)))))
  (setq p3 (list (+ (car p2) (* dirx total)) (+ (cadr p2) (* diry total))))
  (setq p4 (list (+ (car base) (* dirx total)) (+ (cadr base) (* diry total))))
  (RMR:PolyLine (list p1 p4 p3 p2) nil T layer *RMR-BRAND-TERRA*)
  ;; treads
  (setq i 1)
  (while (< i risers)
    (setq y (* (float i) (float going)))
    (RMR:Line (list (+ (car base) (* dirx y)) (+ (cadr base) (* diry y)))
              (list (+ (car p2) (* dirx y)) (+ (cadr p2) (* diry y)))
              layer *RMR-BRAND-TERRA*)
    (setq i (1+ i))
  )
  ;; walking line with direction arrow
  (setq midx (+ (car base) (* nx (/ (float width) 2.0))))
  (setq midy-base (+ (cadr base) (* ny (/ (float width) 2.0))))
  (setq start (list midx midy-base))
  (setq tip (list (+ midx (* dirx total)) (+ midy-base (* diry total))))
  (RMR:Line start tip "RMR-A-ARROW" *RMR-BRAND-TERRA*)
  (RMR:SolidTri tip (- dirx) (- diry) (* 4.0 s) "RMR-A-ARROW" *RMR-BRAND-TERRA*)
  (RMR:RotText (list (+ midx (* dirx (* total 0.25)))
                     (+ midy-base (* diry (* total 0.25)) (* 2.5 s)))
               (strcat "UP  " (itoa risers) "R @ " (itoa going) " = "
                       (RMR:Num (RMR:LinearToMetres total) 2) "m GOING")
               (* 2.4 s) "RMR-LABEL" "RMR-A-ARROW" *RMR-BRAND-TERRA* angle)
  T
)

(defun C:RMR-STAIR (/ base width going risers angle)
  (RMR:EnsureReady)
  (setq base (getpoint "\nBottom-left corner of the stair: "))
  (if base
    (progn
      (setq width (RMR:PromptReal "Stair width in mm" 1100.0))
      (setq risers (RMR:PromptInt "Number of risers" 16))
      (setq going (RMR:PromptReal "Going (tread) in mm" 280.0))
      (setq angle (RMR:PromptAngle "Direction of travel" 90.0))
      (if (< risers 1) (setq risers 1))
      (RMR:StairPlan (list (car base) (cadr base)) width going risers
                     (* angle (/ pi 180.0)) "RMR-M-WALL")
      (princ (strcat "\nStair drawn: " (itoa risers) " risers, " (itoa (fix going))
                     "mm going, " (itoa (fix width)) "mm wide on RMR-M-WALL."))
    )
  )
  (princ)
)

;;; --- linear takeoff ------------------------------------------------------
(defun RMR:EntityLength (ename / obj result data)
  (setq obj (vl-catch-all-apply 'vlax-ename->vla-object (list ename)))
  (if (vl-catch-all-error-p obj)
    nil
    (progn
      (setq result (vl-catch-all-apply 'vlax-get-property (list obj 'Length)))
      (if (vl-catch-all-error-p result)
        (progn
          (setq data (entget ename))
          (if (= (cdr (assoc 0 data)) "LINE")
            (distance (cdr (assoc 10 data)) (cdr (assoc 11 data)))
            nil
          )
        )
        result
      )
    )
  )
)

(defun C:RMR-LENGTH (/ ss i ent len total s point csv)
  (RMR:EnsureReady)
  (setq ss (ssget '((0 . "LINE,LWPOLYLINE,POLYLINE,ARC,CIRCLE,ELLIPSE,SPLINE"))))
  (if ss
    (progn
      (setq total 0.0)
      (setq i 0)
      (repeat (sslength ss)
        (setq len (RMR:EntityLength (ssname ss i)))
        (if len (setq total (+ total len)))
        (setq i (1+ i))
      )
      (setq s (RMR:Scaled 1.0))
      (princ (strcat "\nObjects measured: " (itoa (sslength ss))
                     " | total length " (RMR:Num total 1) " mm = "
                     (RMR:Num (RMR:LinearToMetres total) 2) " m"))
      (setq point (getpoint "\nPlace the total label <enter to skip>: "))
      (if point
        (RMR:Text point (strcat "TOTAL LENGTH " (RMR:Num (RMR:LinearToMetres total) 2) " m")
                  (* 2.5 s) "RMR-NOTE" "RMR-A-TEXT" *RMR-BRAND-INK*)
      )
      (if (RMR:YesP (RMR:PromptYesNo "Write the total to a CSV file" "No"))
        (progn
          (setq csv (getfiled "Save the takeoff" "RooMNRooF_Takeoff.csv" "csv" 1))
          (if csv
            (if (RMR:WriteLines csv
                  (list "RooMNRooF linear takeoff"
                        (strcat "Drawing;" (getvar "DWGNAME"))
                        (strcat "Objects;" (itoa (sslength ss)))
                        (strcat "Total mm;" (RMR:Num total 1))
                        (strcat "Total m;" (RMR:Num (RMR:LinearToMetres total) 2))))
              (princ (strcat "\nTakeoff written to " csv))
              (princ "\nThe takeoff file could not be written.")
            )
          )
        )
      )
    )
    (princ "\nNo linear objects selected.")
  )
  (princ)
)

;;; --- bill of materials ---------------------------------------------------
(defun RMR:DrawBomTable (base rows / s text colw rowh width y i row parts)
  (setq s (RMR:Scaled 1.0))
  (setq text (* 2.5 s))
  (setq colw (list (* 14.0 s) (* 62.0 s) (* 56.0 s) (* 20.0 s)))
  (setq width (+ (nth 0 colw) (nth 1 colw) (nth 2 colw) (nth 3 colw)))
  (setq rowh (* 8.0 s))
  (setq y (cadr base))
  (RMR:Text base "BILL OF MATERIALS  |  RMR-BOM" (* 4.5 s) "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-TERRA*)
  (RMR:Text (RMR:PT+ base 0.0 (- (* 5.5 s)))
            (strcat "PROJECT " (RMR:ProjectValue "PROJECT" "") "   |   BLOCK TAKEOFF")
            (* 2.2 s) "RMR-NOTE" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
  (setq y (- y (* 13.0 s)))
  (RMR:Solid (list (car base) (- y rowh) 0.0) width rowh "RMR-PRES-TITLE" *RMR-BRAND-SAND*)
  (RMR:Text (RMR:PT+ (list (car base) (- y rowh) 0.0) (* 2.0 s) (* 2.2 s)) "NO." text "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-INK*)
  (RMR:Text (RMR:PT+ (list (+ (car base) (nth 0 colw)) (- y rowh) 0.0) (* 2.0 s) (* 2.2 s)) "BLOCK" text "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-INK*)
  (RMR:Text (RMR:PT+ (list (+ (car base) (nth 0 colw) (nth 1 colw)) (- y rowh) 0.0) (* 2.0 s) (* 2.2 s)) "LAYER" text "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-INK*)
  (RMR:Text (RMR:PT+ (list (+ (car base) (nth 0 colw) (nth 1 colw) (nth 2 colw)) (- y rowh) 0.0) (* 2.0 s) (* 2.2 s)) "QTY" text "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-INK*)
  (RMR:TableDividers (car base) (- y rowh) colw rowh "RMR-A-FRAME" *RMR-BRAND-INK*)
  (setq y (- y rowh))
  (setq i 0)
  (foreach row rows
    (setq parts (RMR:SplitString (car row) "|"))
    (RMR:Rect (list (car base) (- y rowh) 0.0) width rowh "RMR-A-FRAME" *RMR-BRAND-SLATE*)
    (RMR:TableDividers (car base) (- y rowh) colw rowh "RMR-A-FRAME" *RMR-BRAND-SLATE*)
    (RMR:Text (RMR:PT+ (list (car base) (- y rowh) 0.0) (* 2.0 s) (* 2.2 s))
              (itoa (1+ i)) text "RMR-NUMBER" "RMR-A-TEXT" *RMR-BRAND-TERRA*)
    (RMR:Text (RMR:PT+ (list (+ (car base) (nth 0 colw)) (- y rowh) 0.0) (* 2.0 s) (* 2.2 s))
              (nth 0 parts) text "RMR-LABEL" "RMR-A-TEXT" *RMR-BRAND-INK*)
    (RMR:Text (RMR:PT+ (list (+ (car base) (nth 0 colw) (nth 1 colw)) (- y rowh) 0.0) (* 2.0 s) (* 2.2 s))
              (nth 1 parts) text "RMR-BODY" "RMR-A-TEXT" *RMR-BRAND-INK*)
    (RMR:Text (RMR:PT+ (list (+ (car base) (nth 0 colw) (nth 1 colw) (nth 2 colw)) (- y rowh) 0.0) (* 2.0 s) (* 2.2 s))
              (itoa (cdr row)) text "RMR-NUMBER" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
    (setq i (1+ i))
    (setq y (- y rowh))
  )
  T
)

(defun C:RMR-BOM (/ ss i data name layer key counts rows point csv action parts)
  (RMR:EnsureReady)
  (princ "\nSelect the blocks to count <enter for the whole drawing>: ")
  (setq ss (ssget '((0 . "INSERT"))))
  (if (not ss) (setq ss (ssget "_X" '((0 . "INSERT")))))
  (if ss
    (progn
      (setq counts nil)
      (setq i 0)
      (repeat (sslength ss)
        (setq data (entget (ssname ss i)))
        (setq name (cdr (assoc 2 data)))
        (setq layer (cdr (assoc 8 data)))
        (if (not layer) (setq layer "0"))
        (setq key (strcat name "|" layer))
        (setq counts (RMR:AssocCountInc key counts))
        (setq i (1+ i))
      )
      (setq rows (RMR:SortPairsDesc counts))
      (princ (strcat "\nDistinct block / layer combinations: " (itoa (length rows))
                     " | total inserts: " (itoa (sslength ss))))
      (setq action (RMR:PromptKeyword "Output" (RMR:KeywordBar "TABLE CSV BOTH") "TABLE"))
      (if (or (= action "TABLE") (= action "BOTH"))
        (progn
          (setq point (getpoint "\nTop-left of the bill of materials: "))
          (if point (RMR:DrawBomTable point rows))
        )
      )
      (if (or (= action "CSV") (= action "BOTH"))
        (progn
          (setq csv (getfiled "Save the bill of materials" "RooMNRooF_BOM.csv" "csv" 1))
          (if csv
            (if (RMR:WriteLines csv
                  (append (list "RooMNRooF bill of materials"
                                "Block;Layer;Quantity")
                          (RMR:CsvLines rows)))
              (princ (strcat "\nBill of materials written to " csv))
              (princ "\nThe file could not be written.")
            )
          )
        )
      )
    )
    (princ "\nNo block references found.")
  )
  (princ)
)

;;; --- room finishes schedule ----------------------------------------------
(defun RMR:DrawFinishTable (base rows / s text colw rowh width y row cx i label-index value)
  (setq s (RMR:Scaled 1.0))
  (setq text (* 2.2 s))
  (setq colw (list (* 34.0 s) (* 44.0 s) (* 26.0 s) (* 44.0 s) (* 32.0 s) (* 40.0 s)))
  (setq width (+ (nth 0 colw) (nth 1 colw) (nth 2 colw) (nth 3 colw) (nth 4 colw) (nth 5 colw)))
  (setq rowh (* 8.0 s))
  (setq y (cadr base))
  (RMR:Text base "ROOM FINISHES SCHEDULE  |  RMR-FINISHES" (* 4.5 s) "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-TERRA*)
  (RMR:Text (RMR:PT+ base 0.0 (- (* 5.5 s)))
            (strcat "PROJECT " (RMR:ProjectValue "PROJECT" "") "   |   EDIT *RMR-FINISH-SPECS*")
            (* 2.2 s) "RMR-NOTE" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
  (setq y (- y (* 13.0 s)))
  (RMR:Solid (list (car base) (- y rowh) 0.0) width rowh "RMR-PRES-TITLE" *RMR-BRAND-SAND*)
  (foreach label-index '(0 1 2 3 4 5)
    (setq cx (car base))
    (setq i 0)
    (while (< i label-index)
      (setq cx (+ cx (nth i colw)))
      (setq i (1+ i))
    )
    (RMR:Text (RMR:PT+ (list cx (- y rowh) 0.0) (* 1.6 s) (* 2.2 s))
              (nth label-index '("ROOM" "FLOOR" "SKIRTING" "WALL" "CEILING" "NOTES"))
              text "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-INK*)
  )
  (RMR:TableDividers (car base) (- y rowh) colw rowh "RMR-A-FRAME" *RMR-BRAND-INK*)
  (setq y (- y rowh))
  (foreach row rows
    (RMR:Rect (list (car base) (- y rowh) 0.0) width rowh "RMR-A-FRAME" *RMR-BRAND-SLATE*)
    (RMR:TableDividers (car base) (- y rowh) colw rowh "RMR-A-FRAME" *RMR-BRAND-SLATE*)
    (setq cx (car base))
    (setq i 0)
    (foreach value row
      (RMR:Text (RMR:PT+ (list cx (- y rowh) 0.0) (* 1.6 s) (* 2.2 s)) value
                text (if (= i 0) "RMR-LABEL" "RMR-BODY") "RMR-A-TEXT"
                (if (= i 0) *RMR-BRAND-INK* *RMR-BRAND-SLATE*))
      (setq cx (+ cx (nth i colw)))
      (setq i (1+ i))
    )
    (setq y (- y rowh))
  )
  T
)

(defun C:RMR-FINISHES (/ point)
  (RMR:EnsureReady)
  (setq point (getpoint "\nTop-left of the finishes schedule: "))
  (if point
    (progn
      (RMR:DrawFinishTable point *RMR-FINISH-SPECS*)
      (princ (strcat "\nFinishes schedule placed with " (itoa (length *RMR-FINISH-SPECS*))
                     " rooms from *RMR-FINISH-SPECS*."))
    )
  )
  (princ)
)

;;; --- drawing register ------------------------------------------------------
(defun RMR:DrawRegisterTable (base rows / s text colw rowh width y row cx i label-index value)
  (setq s (RMR:Scaled 1.0))
  (setq text (* 2.3 s))
  (setq colw (list (* 24.0 s) (* 96.0 s) (* 22.0 s) (* 18.0 s) (* 54.0 s)))
  (setq width (+ (nth 0 colw) (nth 1 colw) (nth 2 colw) (nth 3 colw) (nth 4 colw)))
  (setq rowh (* 8.0 s))
  (setq y (cadr base))
  (RMR:Text base "DRAWING REGISTER  |  RMR-SHEETREG" (* 4.5 s) "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-TERRA*)
  (RMR:Text (RMR:PT+ base 0.0 (- (* 5.5 s)))
            (strcat "JOB " (RMR:ProjectValue "JOB" "") "   |   "
                    (RMR:ProjectValue "PROJECT" ""))
            (* 2.2 s) "RMR-NOTE" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
  (setq y (- y (* 13.0 s)))
  (RMR:Solid (list (car base) (- y rowh) 0.0) width rowh "RMR-PRES-TITLE" *RMR-BRAND-SAND*)
  (foreach label-index '(0 1 2 3 4)
    (setq cx (car base))
    (setq i 0)
    (while (< i label-index)
      (setq cx (+ cx (nth i colw)))
      (setq i (1+ i))
    )
    (RMR:Text (RMR:PT+ (list cx (- y rowh) 0.0) (* 1.6 s) (* 2.2 s))
              (nth label-index '("SHEET" "TITLE" "SCALE" "REV" "STATUS"))
              text "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-INK*)
  )
  (RMR:TableDividers (car base) (- y rowh) colw rowh "RMR-A-FRAME" *RMR-BRAND-INK*)
  (setq y (- y rowh))
  (foreach row rows
    (RMR:Rect (list (car base) (- y rowh) 0.0) width rowh "RMR-A-FRAME" *RMR-BRAND-SLATE*)
    (RMR:TableDividers (car base) (- y rowh) colw rowh "RMR-A-FRAME" *RMR-BRAND-SLATE*)
    (setq cx (car base))
    (setq i 0)
    (foreach value row
      (RMR:Text (RMR:PT+ (list cx (- y rowh) 0.0) (* 1.6 s) (* 2.2 s)) value
                text (if (< i 2) "RMR-LABEL" "RMR-BODY") "RMR-A-TEXT"
                (if (= i 0) *RMR-BRAND-TERRA* *RMR-BRAND-INK*))
      (setq cx (+ cx (nth i colw)))
      (setq i (1+ i))
    )
    (setq y (- y rowh))
  )
  T
)

(defun C:RMR-SHEETREG (/ point)
  (RMR:EnsureReady)
  (setq point (getpoint "\nTop-left of the drawing register: "))
  (if point
    (progn
      (RMR:DrawRegisterTable point *RMR-SHEET-LIST*)
      (princ (strcat "\nDrawing register placed with " (itoa (length *RMR-SHEET-LIST*))
                     " sheets from *RMR-SHEET-LIST*."))
    )
  )
  (princ)
)

;;; --- xref register ---------------------------------------------------------
(defun C:RMR-XREFLIST (/ data name flags path rows row point s y x text)
  (RMR:EnsureReady)
  (setq rows nil)
  (setq data (tblnext "BLOCK" T))
  (while data
    (setq name (cdr (assoc 2 data)))
    (setq flags (cdr (assoc 70 data)))
    (setq path (cdr (assoc 1 data)))
    (if (and flags (= (logand flags 4) 4))
      (setq rows (append rows (list (list name (if path path "(unresolved)")))))
    )
    (setq data (tblnext "BLOCK"))
  )
  (if rows
    (progn
      (princ (strcat "\nExternal references in this drawing: " (itoa (length rows))))
      (foreach row rows
        (princ (strcat "\n  " (nth 0 row) " <- " (nth 1 row)))
      )
      (setq point (getpoint "\nTop-left of the xref register <enter to skip>: "))
      (if point
        (progn
          (setq s (RMR:Scaled 1.0))
          (setq text (* 2.3 s))
          (setq x (car point))
          (setq y (cadr point))
          (RMR:Text point "XREF REGISTER  |  RMR-XREFLIST" (* 4.5 s) "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-TERRA*)
          (setq y (- y (* 8.0 s)))
          (foreach row rows
            (RMR:Rect (list x (- y (* 8.0 s))) (* 200.0 s) (* 8.0 s) "RMR-A-FRAME" *RMR-BRAND-SLATE*)
            (RMR:Text (list (+ x (* 2.0 s)) (- y (* 6.0 s))) (nth 0 row) text
                      "RMR-LABEL" "RMR-A-TEXT" *RMR-BRAND-INK*)
            (RMR:Text (list (+ x (* 60.0 s)) (- y (* 6.0 s))) (nth 1 row) text
                      "RMR-BODY" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
            (setq y (- y (* 8.0 s)))
          )
        )
      )
    )
    (princ "\nThis drawing has no external references attached.")
  )
  (princ)
)

;;; --- transmittal record ------------------------------------------------------
(defun C:RMR-TRANSMITTAL (/ point s x y row text colw rowh width i cx label-index)
  (RMR:EnsureReady)
  (setq point (getpoint "\nTop-left of the transmittal record: "))
  (if point
    (progn
      (setq s (RMR:Scaled 1.0))
      (setq text (* 2.3 s))
      (setq colw (list (* 26.0 s) (* 96.0 s) (* 18.0 s) (* 30.0 s) (* 60.0 s)))
      (setq width (+ (nth 0 colw) (nth 1 colw) (nth 2 colw) (nth 3 colw) (nth 4 colw)))
      (setq rowh (* 8.0 s))
      (setq x (car point))
      (setq y (cadr point))
      (RMR:Text point "ISSUE / TRANSMITTAL RECORD  |  RMR-TRANSMITTAL" (* 4.5 s)
                "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-TERRA*)
      (setq y (- y (* 8.0 s)))
      (RMR:Text (list x y)
                (strcat "PROJECT " (RMR:ProjectValue "PROJECT" "")
                        "   |   CLIENT " (RMR:ProjectValue "CLIENT" "")
                        "   |   JOB " (RMR:ProjectValue "JOB" ""))
                (* 2.2 s) "RMR-NOTE" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
      (setq y (- y (* 8.0 s)))
      (RMR:Solid (list x (- y rowh)) width rowh "RMR-PRES-TITLE" *RMR-BRAND-SAND*)
      (foreach label-index '(0 1 2 3 4)
        (setq cx x)
        (setq i 0)
        (while (< i label-index)
          (setq cx (+ cx (nth i colw)))
          (setq i (1+ i))
        )
        (RMR:Text (list (+ cx (* 1.6 s)) (- y (* 5.6 s)))
                  (nth label-index '("SHEET" "TITLE" "REV" "ISSUE DATE" "RECEIVED BY / SIGNATURE"))
                  text "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-INK*)
      )
      (RMR:TableDividers x (- y rowh) colw rowh "RMR-A-FRAME" *RMR-BRAND-INK*)
      (setq y (- y rowh))
      (foreach row *RMR-SHEET-LIST*
        (RMR:Rect (list x (- y rowh)) width rowh "RMR-A-FRAME" *RMR-BRAND-SLATE*)
        (RMR:TableDividers x (- y rowh) colw rowh "RMR-A-FRAME" *RMR-BRAND-SLATE*)
        (RMR:Text (list (+ x (* 1.6 s)) (- y (* 5.6 s))) (nth 0 row) text
                  "RMR-NUMBER" "RMR-A-TEXT" *RMR-BRAND-TERRA*)
        (RMR:Text (list (+ x (nth 0 colw) (* 1.6 s)) (- y (* 5.6 s))) (nth 1 row) text
                  "RMR-BODY" "RMR-A-TEXT" *RMR-BRAND-INK*)
        (RMR:Text (list (+ x (nth 0 colw) (nth 1 colw) (* 1.6 s)) (- y (* 5.6 s)))
                  (nth 3 row) text "RMR-NUMBER" "RMR-A-TEXT" *RMR-BRAND-INK*)
        (RMR:Text (list (+ x (nth 0 colw) (nth 1 colw) (nth 2 colw) (* 1.6 s)) (- y (* 5.6 s)))
                  (RMR:TodayDate) text "RMR-BODY" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
        (setq y (- y rowh))
      )
      (RMR:Text (list x (- y (* 6.0 s)))
                (strcat "Issued by " (RMR:ProjectValue "DRAWN" "")
                        "  |  Checked by " (RMR:ProjectValue "CHECKED" "")
                        "  |  Stage: " (RMR:ProjectValue "STAGE" ""))
                (* 2.2 s) "RMR-NOTE" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
      (princ (strcat "\nTransmittal record placed for " (itoa (length *RMR-SHEET-LIST*))
                     " sheets."))
    )
  )
  (princ)
)

;;; --- layer states (own .rms format, no command-line guessing) ---------------
(defun RMR:LayerSnapshot (/ data out name colour ltype lw flags)
  (setq out nil)
  (setq data (tblnext "LAYER" T))
  (while data
    (setq name (cdr (assoc 2 data)))
    (setq colour (cdr (assoc 62 data)))
    (setq ltype (cdr (assoc 6 data)))
    (setq lw (cdr (assoc 370 data)))
    (setq flags (cdr (assoc 70 data)))
    (setq out
      (cons
        (list name
              (itoa (abs (if colour colour 7)))
              (if ltype ltype "Continuous")
              (itoa (if lw lw -3))
              (if (and flags (= (logand flags 1) 1)) "1" "0")
              (if (and colour (< colour 0)) "1" "0")
              (if (and flags (= (logand flags 4) 4)) "1" "0"))
        out))
    (setq data (tblnext "LAYER"))
  )
  (reverse out)
)

(defun RMR:StateLine (row)
  (strcat (nth 0 row) ";" (nth 1 row) ";" (nth 2 row) ";" (nth 3 row) ";"
          (nth 4 row) ";" (nth 5 row) ";" (nth 6 row))
)

(defun RMR:ApplyLayerState (row / name colour ltype lw frozen off locked ename data flags result)
  (setq name (nth 0 row))
  (setq ename (tblobjname "LAYER" name))
  (if (not ename)
    nil
    (progn
      (setq data (entget ename))
      (setq colour (atoi (nth 1 row)))
      (setq ltype (nth 2 row))
      (setq lw (atoi (nth 3 row)))
      (setq frozen (= (nth 4 row) "1"))
      (setq off (= (nth 5 row) "1"))
      (setq locked (= (nth 6 row) "1"))
      (if off (setq colour (- (abs colour))))
      (setq data (RMR:DXF 62 colour data))
      (if (tblsearch "LTYPE" ltype)
        (setq data (RMR:DXF 6 ltype data))
      )
      (setq data (RMR:DXF 370 lw data))
      (setq flags (cdr (assoc 70 data)))
      (if (not flags) (setq flags 0))
      (if frozen
        (setq flags (logior flags 1))
        (setq flags (logand flags -2))
      )
      (if locked
        (setq flags (logior flags 4))
        (setq flags (logand flags -5))
      )
      (setq data (RMR:DXF 70 flags data))
      (setq result (vl-catch-all-apply 'entmod (list data)))
      (not (vl-catch-all-error-p result))
    )
  )
)

(defun C:RMR-LAYERSTATE (/ action name path rows line ok skipped total)
  (RMR:EnsureReady)
  (setq action (RMR:PromptKeyword "Layer state"
                                  (RMR:KeywordBar "SAVE RESTORE LIST DELETE") "SAVE"))
  (cond
    ((= action "LIST")
      (setq path (getfiled "Layer state file" "" "rms" 4))
      (if path
        (progn
          (setq rows (RMR:ReadLines path))
          (princ (strcat "\nLayer states in " path ": " (itoa (length rows))))
          (setq total 0)
          (foreach line rows
            (if (> (strlen line) 0)
              (progn
                (setq total (1+ total))
                (if (<= total 24)
                  (princ (strcat "\n  " line))
                )
              )
            )
          )
          (if (> total 24) (princ (strcat "\n  ... " (itoa (- total 24)) " more")))
        )
      )
    )
    ((= action "SAVE")
      (setq name (RMR:PromptText "Layer state name" (strcat "STATE-" (RMR:TodayDate))))
      (setq path (getfiled "Save the layer state" (strcat (RMR:StripExtension (getvar "DWGNAME")) ".rms") "rms" 1))
      (if path
        (progn
          (setq rows (RMR:LayerSnapshot))
          (setq rows (mapcar 'RMR:StateLine rows))
          (if (RMR:WriteLines path (cons (strcat "# RooMNRooF layer state | name=" name) rows))
            (princ (strcat "\nLayer state \"" name "\" saved: " (itoa (length rows)) " layers -> " path))
            (princ "\nThe layer state file could not be written.")
          )
        )
      )
    )
    ((= action "RESTORE")
      (setq path (getfiled "Layer state file" "" "rms" 4))
      (if path
        (progn
          (setq rows (RMR:ReadLines path))
          (setq ok 0 skipped 0 total 0)
          (foreach line rows
            (if (and (> (strlen line) 0) (/= (substr line 1 1) "#"))
              (progn
                (setq total (1+ total))
                (if (RMR:ApplyLayerState (RMR:SplitString line ";"))
                  (setq ok (1+ ok))
                  (setq skipped (1+ skipped))
                )
              )
            )
          )
          (princ (strcat "\nRestored " (itoa ok) " of " (itoa total)
                         " layer(s). Skipped (missing or protected): " (itoa skipped)))
          (if (> skipped 0)
            (princ "\nXref-dependent, missing and current layers are skipped by AutoCAD.")
          )
        )
      )
    )
    ((= action "DELETE")
      (setq path (getfiled "Layer state file to delete" "" "rms" 4))
      (if path
        (if (vl-catch-all-error-p (vl-catch-all-apply 'vl-file-delete (list path)))
          (princ (strcat "\n" path " could not be deleted."))
          (princ (strcat "\n" path " deleted."))
        )
      )
    )
  )
  (princ)
)

;;; --- force everything to ByLayer -------------------------------------------
(defun C:RMR-STANDARDIZE (/ ss i count changed ent data result)
  (RMR:EnsureReady)
  (princ "\nSelect the objects to standardise <enter for the whole drawing>: ")
  (setq ss (ssget))
  (if (not ss) (setq ss (ssget "_X")))
  (if ss
    (progn
      (setq changed 0)
      (setq i 0)
      (repeat (sslength ss)
        (setq ent (ssname ss i))
        (setq data (entget ent))
        (if (assoc 62 data) (setq data (RMR:DXF 62 256 data)))
        (if (assoc 6 data) (setq data (RMR:DXF 6 "BYLAYER" data)))
        (if (assoc 370 data) (setq data (RMR:DXF 370 -1 data)))
        (setq result (vl-catch-all-apply 'entmod (list data)))
        (if (not (vl-catch-all-error-p result)) (setq changed (1+ changed)))
        (setq i (1+ i))
      )
      (princ (strcat "\nStandardised " (itoa changed) " of " (itoa (sslength ss))
                     " object(s) to BYLAYER colour, linetype and lineweight."))
      (princ "\nRun RMR-CHECK afterwards to confirm the drawing standard.")
    )
    (princ "\nNothing selected.")
  )
  (princ)
)

;;; --- clean-up ---------------------------------------------------------------
(defun C:RMR-CLEAN (/ oldexpert oldcmdecho pass answer)
  (RMR:EnsureReady)
  (setq oldexpert (getvar "EXPERT"))
  (setq oldcmdecho (getvar "CMDECHO"))
  (setvar "EXPERT" 3)
  (setvar "CMDECHO" 0)
  (setq pass 0)
  (repeat 3
    (vl-catch-all-apply 'command (list "_.-purge" "_A" "*" "_N"))
    (setq pass (1+ pass))
  )
  (vl-catch-all-apply 'command (list "_.audit" "_N"))
  (setvar "EXPERT" oldexpert)
  (setvar "CMDECHO" oldcmdecho)
  (princ (strcat "\nClean-up finished: " (itoa pass) " purge passes plus an audit."))
  (setq answer (RMR:PromptYesNo "Also force every object to BYLAYER (RMR-STANDARDIZE)" "No"))
  (if (RMR:YesP answer)
    (C:RMR-STANDARDIZE)
    (princ "\nRun RMR-STANDARDIZE separately if the drawing mixes overrides.")
  )
  (princ)
)

;;; --- drawing properties from project data -------------------------------------
(defun C:RMR-DWGPROPS (/ doc si result)
  (RMR:EnsureReady)
  (vl-load-com)
  (setq doc (RMR:DocSafe))
  (if (not doc)
    (princ "\nActiveX is not available - set the properties with DWGPROPS.")
    (progn
      (setq si (vl-catch-all-apply 'vla-get-SummaryInfo (list doc)))
      (if (vl-catch-all-error-p si)
        (princ "\nThe drawing summary could not be opened - use the DWGPROPS command.")
        (progn
          (setq result 0)
          (if (not (vl-catch-all-error-p
                     (vl-catch-all-apply 'vla-put-Title
                       (list si (RMR:ProjectValue "TITLE" "")))))
            (setq result (1+ result))
          )
          (if (not (vl-catch-all-error-p
                     (vl-catch-all-apply 'vla-put-Subject
                       (list si (RMR:ProjectValue "PROJECT" "")))))
            (setq result (1+ result))
          )
          (if (not (vl-catch-all-error-p
                     (vl-catch-all-apply 'vla-put-Author
                       (list si (RMR:ProjectValue "DRAWN" "")))))
            (setq result (1+ result))
          )
          (if (not (vl-catch-all-error-p
                     (vl-catch-all-apply 'vla-put-Category
                       (list si (RMR:ProjectValue "STAGE" "")))))
            (setq result (1+ result))
          )
          (if (not (vl-catch-all-error-p
                     (vl-catch-all-apply 'vla-put-Keywords
                       (list si (strcat "RooMNRooF;" (RMR:ProjectValue "JOB" "")
                                        ";" (RMR:ProjectValue "DWGNO" ""))))))
            (setq result (1+ result))
          )
          (if (not (vl-catch-all-error-p
                     (vl-catch-all-apply 'vla-put-Comments
                       (list si (strcat "RooMNRooF " *RMR-VERSION* " | "
                                        (RMR:ProjectValue "PROJECT" ""))))))
            (setq result (1+ result))
          )
          (princ (strcat "\nDrawing properties updated from *RMR-PROJECT*: "
                         (itoa result) " field(s). Open DWGPROPS to review them."))
        )
      )
    )
  )
  (princ)
)

;;; =====================================================================
;;; PRO 6.0 SITE AND SERVICES SUITE
;;; Solar study diagrams, falls and drainage, parking and tiling setout,
;;; reflected ceiling plans, level and keynote libraries, a printable
;;; standard report and a stray-layer audit.
;;; =====================================================================

;;; Level schedule: (Level Height_mm Description)
(setq *RMR-LEVEL-SPECS*
 '(
    ("L00"     0 "Ground floor finished level")
    ("L01"  3300 "First floor finished level")
    ("L02"  6600 "Second floor finished level")
    ("L03"  9900 "Third floor finished level")
    ("ROOF" 20100 "Roof finish level")
    ("PARAPET" 21500 "Top of parapet")
  )
)

;;; Keynote library: (Number Text)
(setq *RMR-KEYNOTES*
 '(
    ("01" "100mm blockwork partition, plastered and painted both faces")
    ("02" "Floor waste with 1:80 fall to trapped gully")
    ("03" "Acoustic sealant to partition head and perimeter")
    ("04" "Waterproof tanking to wet areas, 150mm above finished floor")
    ("05" "Porcelain floor tile on 25mm cement sand screed")
    ("06" "Skirting to match floor finish, 100mm high")
    ("07" "Gypsum board ceiling on concealed suspension grid")
    ("08" "Fire rated door assembly, 60/60/60, with intumescent seals")
    ("09" "Insulated external wall: blockwork, cavity, insulation, render")
    ("10" "Double glazed unit, low-E coating, U-value 1.6 W/m2K")
    ("11" "Reinforced concrete slab, 200mm thick, mesh reinforced")
    ("12" "Aluminium rainwater downpipe, 100mm diameter, painted")
  )
)

;;; Reference latitudes: (City Latitude_degrees)
(setq *RMR-SUN-CITIES*
 '(
    ("DHAKA"     23.81)
    ("DUBAI"     25.20)
    ("SINGAPORE"  1.35)
    ("LONDON"    51.51)
    ("NEW YORK"  40.71)
    ("SYDNEY"   -33.87)
  )
)

(setq *RMR-SUN-DECLINATIONS*
 '(
    ("SUMMER"  23.45)
    ("EQUINOX"  0.00)
    ("WINTER" -23.45)
  )
)

;;; --- solar geometry ------------------------------------------------------
(defun RMR:Radians (deg) (* deg (/ pi 180.0)))
(defun RMR:Degrees (rad) (* rad (/ 180.0 pi)))

(defun RMR:SolarAltitude (lat dec hour / value)
  ;; lat, dec and hour are in radians. Returns the solar altitude in radians.
  (setq value (+ (* (sin lat) (sin dec))
                 (* (cos lat) (cos dec) (cos hour))))
  (setq value (max -1.0 (min 1.0 value)))
  (asin value)
)

(defun RMR:SolarAzimuth (lat dec hour alt / value cosalt az)
  ;; Azimuth in radians measured clockwise from north. hour < 0 is morning.
  (setq cosalt (cos alt))
  (if (< (abs cosalt) 0.000001)
    (setq value 0.0)
    (progn
      (setq value (/ (- (* (sin dec) (cos lat))
                        (* (cos dec) (sin lat) (cos hour)))
                     cosalt))
      (setq value (max -1.0 (min 1.0 value)))
    )
  )
  (setq az (acos value))
  (if (> hour 0.0) (setq az (- (* 2.0 pi) az)))
  az
)

(defun C:RMR-SUNPATH (/ spec lat limit centre kw dec hour alt az pt
                      points index value hh)
  (RMR:EnsureReady)
  (setq kw (RMR:PromptKeyword
             "Reference latitude"
             (strcat (RMR:KeywordBar (RMR:KeywordList *RMR-SUN-CITIES*)) " OTHER")
             "DHAKA"))
  (if kw
    (progn
      (if (= kw "OTHER")
        (progn
          (setq lat (getreal "\nLatitude in degrees (negative is south) <23.81>: "))
          (if (not lat) (setq lat 23.81))
        )
        (progn
          (setq spec (RMR:TableSpec kw *RMR-SUN-CITIES*))
          (setq lat (nth 1 spec))
        )
      )
      (setq centre (getpoint "\nCentre of the sun-path diagram: "))
      (if centre
        (progn
          (setq limit (RMR:PromptReal "Horizon circle radius" 60.0))
          (setq lat (RMR:Radians lat))
          (setq value (RMR:Scaled 1.0))
          (RMR:Circle centre limit "RMR-A-FRAME" *RMR-BRAND-SLATE*)
          ;; cardinal marks and 30 degree altitude rings
          (foreach label-index '(0 1 2 3)
            (setq az (* label-index (/ pi 2.0)))
            (RMR:Line centre (RMR:Polar centre az limit) "RMR-00-REF" *RMR-BRAND-SLATE*)
          )
          (foreach ring '(30.0 60.0)
            (RMR:Circle centre (* limit (/ (- 90.0 ring) 90.0))
                        "RMR-00-REF" *RMR-BRAND-SLATE*)
          )
          ;; declination curves
          (foreach spec *RMR-SUN-DECLINATIONS*
            (setq dec (RMR:Radians (nth 1 spec)))
            (setq points nil)
            (setq hour (- pi 0.0001))
            (while (<= hour pi)
              (setq alt (RMR:SolarAltitude lat dec hour))
              (if (> alt 0.0)
                (progn
                  (setq az (RMR:SolarAzimuth lat dec hour alt))
                  (setq points (append points (list (RMR:Polar centre az (* limit (/ (- 90.0 (RMR:Degrees alt)) 90.0))))))
                )
              )
              (setq hour (+ hour (/ pi 24.0)))
            )
            (if (> (length points) 1)
              (RMR:PolyLine points nil nil "RMR-A-ARROW" *RMR-BRAND-GOLD*)
            )
            (setq index (if (= (nth 0 spec) "SUMMER") 0.62
                          (if (= (nth 0 spec) "EQUINOX") 0.42 0.22)))
            (RMR:Text (RMR:Polar centre (RMR:Radians -45.0) (* limit index))
                      (nth 0 spec) (* 2.4 value) "RMR-LABEL"
                      "RMR-A-TEXT" *RMR-BRAND-GOLD*)
          )
          ;; hour marks around the horizon for the equinox
          (foreach hh '(6 9 12 15 18)
            (setq hour (RMR:Radians (* (- hh 12.0) 15.0)))
            (setq dec 0.0)
            (setq alt (RMR:SolarAltitude lat dec hour))
            (if (> alt -0.000001)
              (progn
                (setq az (RMR:SolarAzimuth lat dec hour alt))
                (setq pt (RMR:Polar centre az (* limit 1.05)))
                (RMR:Text (list (car pt) (cadr pt)) (strcat (itoa hh) "h")
                          (* 2.0 value) "RMR-LABEL" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
              )
            )
          )
          (foreach label-index '(0 1 2 3)
            (setq az (* label-index (/ pi 2.0)))
            (RMR:Text (RMR:Polar centre az (* limit 1.10))
                      (nth label-index '("N" "E" "S" "W"))
                      (* 3.0 value) "RMR-NUMBER" "RMR-A-TEXT" *RMR-BRAND-INK*)
          )
          ;; noon altitudes reported in the corner
          (setq index 0)
          (foreach spec *RMR-SUN-DECLINATIONS*
            (setq dec (RMR:Radians (nth 1 spec)))
            (setq alt (RMR:SolarAltitude lat dec 0.0))
            (RMR:Text (RMR:PT+ centre (- limit) (- limit (* index 4.0) 12.0))
                      (strcat (nth 0 spec) " NOON ALTITUDE " (RMR:Num (RMR:Degrees alt) 1) " DEG")
                      (* 2.2 value) "RMR-NOTE" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
            (setq index (1+ index))
          )
          (RMR:Text (RMR:PT+ centre (- limit) (+ limit 8.0))
                    (strcat "SOLAR STUDY  |  LATITUDE " (RMR:Num (RMR:Degrees lat) 2) " DEG")
                    (* 3.4 value) "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-TERRA*)
          (princ (strcat "\nSun-path diagram drawn at latitude "
                         (RMR:Num (RMR:Degrees lat) 2) " degrees."))
        )
      )
    )
  )
  (princ)
)

;;; --- falls and drainage ---------------------------------------------------
(defun C:RMR-FALL (/ p1 p2 kw gradient run drop s mid ang ux uy label)
  (RMR:EnsureReady)
  (setq s (RMR:Scaled 1.0))
  (setq p1 (getpoint "\nHigh point of the fall: "))
  (if p1
    (progn
      (setq p2 (getpoint p1 "\nLow point of the fall: "))
      (if p2
        (progn
          (setq kw (RMR:PromptKeyword "Gradient"
                                      (RMR:KeywordBar "40 60 80 100 120") "80"))
          (if kw
            (progn
              (setq gradient (atof kw))
              (setq run (distance p1 p2))
              (setq drop (if (> gradient 0.0) (/ run gradient) 0.0))
              (setq ang (angle p1 p2))
              (setq ux (cos ang))
              (setq uy (sin ang))
              (RMR:Line p1 p2 "RMR-P-DRAIN" *RMR-BRAND-BLUE*)
              (RMR:SolidTri p2 (- ux) (- uy) (* 4.0 s) "RMR-P-DRAIN" *RMR-BRAND-BLUE*)
              (setq mid (list (/ (+ (car p1) (car p2)) 2.0)
                              (/ (+ (cadr p1) (cadr p2)) 2.0)))
              (setq label (strcat "FALL 1:" kw "  (" (RMR:Num drop 0) "mm OVER "
                                  (RMR:Num run 0) "mm)"))
              (RMR:RotText (list (+ (car mid) (* 2.0 s)) (+ (cadr mid) (* 2.0 s)))
                           label (* 2.4 s) "RMR-LABEL" "RMR-P-ANNO" *RMR-BRAND-BLUE*
                           (if (and (> ang (* pi 0.5)) (<= ang (* pi 1.5))) (- ang pi) ang))
              (princ (strcat "\nFall 1:" kw " drawn - " (RMR:Num drop 0)
                             "mm drop over " (RMR:Num run 0) "mm."))
            )
          )
        )
      )
    )
  )
  (princ)
)

(defun C:RMR-DRAIN (/ p1 p2 pts start gradient length-so-far index name level
                    previous s label)
  (RMR:EnsureReady)
  (setq s (RMR:Scaled 1.0))
  (setq p1 (getpoint "\nStart of the drainage run: "))
  (if p1
    (progn
      (setq pts (list (list (car p1) (cadr p1))))
      (setq p2 (getpoint (last pts) "\nNext point <enter to finish>: "))
      (while p2
        (setq pts (append pts (list (list (car p2) (cadr p2)))))
        (setq p2 (getpoint (last pts) "\nNext point <enter to finish>: "))
      )
      (if (< (length pts) 2)
        (princ "\nA drainage run needs at least two points.")
        (progn
          (setq start (RMR:PromptReal "Start invert level in mm" 1500.0))
          (setq gradient (RMR:PromptReal "Gradient 1:x" 80.0))
          (setq name (RMR:PromptText "First manhole reference" "MH01"))
          (setq level start)
          (setq index 0)
          (setq previous (nth 0 pts))
          (RMR:PolyLine pts nil nil "RMR-P-DRAIN" *RMR-BRAND-BLUE*)
          (foreach pt pts
            (if (> index 0)
              (progn
                (setq length-so-far (distance previous pt))
                (setq level (- level (/ length-so-far gradient)))
              )
            )
            (RMR:Circle pt (* 3.0 s) "RMR-P-FIXTURE" *RMR-BRAND-BLUE*)
            (setq label (strcat name "  IL " (RMR:Num (/ level 1000.0) 3)))
            (RMR:Text (RMR:PT+ pt (* 4.0 s) (* 1.0 s)) label (* 2.2 s)
                      "RMR-LABEL" "RMR-P-ANNO" *RMR-BRAND-BLUE*)
            (setq name (strcat "MH" (RMR:NumPad2 (+ index 2))))
            (setq previous pt)
            (setq index (1+ index))
          )
          (princ (strcat "\nDrainage run drawn: " (itoa (length pts))
                         " manholes, invert from " (RMR:Num (/ start 1000.0) 3)
                         "m down to " (RMR:Num (/ level 1000.0) 3) "m at 1:"
                         (RMR:Num gradient 0) "."))
        )
      )
    )
  )
  (princ)
)

;;; --- parking layout --------------------------------------------------------
(defun C:RMR-PARK (/ base kw ang bayw bayd count aisle i x corner rot pts s
                    ux uy nx ny)
  (RMR:EnsureReady)
  (setq s (RMR:Scaled 1.0))
  (setq base (getpoint "\nStart corner of the parking row: "))
  (if base
    (progn
      (setq kw (RMR:PromptKeyword "Bay angle" (RMR:KeywordBar "90 60 45") "90"))
      (if kw
        (progn
          (setq rot (atof kw))
          (setq bayw (RMR:PromptReal "Bay width in mm" 2500.0))
          (setq bayd (RMR:PromptReal "Bay depth in mm" 5000.0))
          (setq count (RMR:PromptInt "Number of bays" 4))
          (setq aisle (RMR:PromptReal "Aisle width in mm" 6000.0))
          (if (< count 1) (setq count 1))
          (setq ang (RMR:Radians rot))
          (setq ux (cos ang))
          (setq uy (sin ang))
          (setq nx (- uy))
          (setq ny ux)
          (setq i 0)
          (while (< i count)
            (setq corner (list (+ (car base) (* nx (* i bayw)))
                               (+ (cadr base) (* ny (* i bayw)))))
            (setq pts
              (list corner
                    (list (+ (car corner) (* ux bayd)) (+ (cadr corner) (* uy bayd)))
                    (list (+ (car corner) (* ux bayd) (* nx bayw))
                          (+ (cadr corner) (* uy bayd) (* ny bayw)))
                    (list (+ (car corner) (* nx bayw)) (+ (cadr corner) (* ny bayw)))))
            (RMR:PolyLine pts nil T "RMR-M-WALL" *RMR-BRAND-SLATE*)
            (RMR:Text (list (+ (car corner) (* ux (* bayd 0.5)) (* nx (* bayw 0.5))
                               (- (* 1.2 s)))
                            (+ (cadr corner) (* uy (* bayd 0.5)) (* ny (* bayw 0.5))))
                      (itoa (1+ i)) (* 2.6 s) "RMR-NUMBER" "RMR-A-TEXT" *RMR-BRAND-TERRA*)
            (setq i (1+ i))
          )
          ;; aisle edge line, behind the row on the opposite side of the bays
          (setq x (list (+ (car base) (* nx (* count bayw)))
                        (+ (cadr base) (* ny (* count bayw)))))
          (RMR:Line (list (- (car base) (* ux aisle)) (- (cadr base) (* uy aisle)))
                    (list (- (car x) (* ux aisle)) (- (cadr x) (* uy aisle)))
                    "RMR-00-REF" *RMR-BRAND-SLATE*)
          (RMR:Line (list (+ (car base) (* ux bayd)) (+ (cadr base) (* uy bayd)))
                    (list (+ (car base) (* ux bayd) (* nx (* count bayw)))
                          (+ (cadr base) (* uy bayd) (* ny (* count bayw))))
                    "RMR-M-WALL" *RMR-BRAND-SLATE*)
          (RMR:Text (RMR:PT+ base 0.0 (- (* 12.0 s)))
                    (strcat (itoa count) " BAYS AT " kw " DEG  |  " (itoa (fix bayw))
                            " x " (itoa (fix bayd)) "mm  |  AISLE " (itoa (fix aisle)) "mm")
                    (* 2.4 s) "RMR-LABEL" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
          (princ (strcat "\n" (itoa count) " parking bays drawn at " kw " degrees."))
        )
      )
    )
  )
  (princ)
)

;;; --- tiling setout ---------------------------------------------------------
(defun C:RMR-TILE (/ p1 p2 x1 y1 x2 y2 tw th grout cols rows used waste s i x y)
  (RMR:EnsureReady)
  (setq s (RMR:Scaled 1.0))
  (setq p1 (getpoint "\nFirst corner of the room: "))
  (if p1
    (progn
      (setq p2 (getcorner p1 "\nOther corner of the room: "))
      (if p2
        (progn
          (setq x1 (min (car p1) (car p2)))
          (setq y1 (min (cadr p1) (cadr p2)))
          (setq x2 (max (car p1) (car p2)))
          (setq y2 (max (cadr p1) (cadr p2)))
          (setq tw (RMR:PromptReal "Tile width in mm" 600.0))
          (setq th (RMR:PromptReal "Tile height in mm" 600.0))
          (setq grout (RMR:PromptReal "Allowance percentage for cutting and waste" 10.0))
          (setq cols (fix (+ 0.999999 (/ (- x2 x1) tw))))
          (setq rows (fix (+ 0.999999 (/ (- y2 y1) th))))
          (if (< cols 1) (setq cols 1))
          (if (< rows 1) (setq rows 1))
          ;; setout grid, capped so huge rooms stay light
          (setq i 1)
          (while (and (< i cols) (< i 80))
            (setq x (+ x1 (* i tw)))
            (RMR:Line (list x y1) (list x y2) "RMR-M-FINISH" *RMR-BRAND-TEAL*)
            (setq i (1+ i))
          )
          (setq i 1)
          (while (and (< i rows) (< i 80))
            (setq y (+ y1 (* i th)))
            (RMR:Line (list x1 y) (list x2 y) "RMR-M-FINISH" *RMR-BRAND-TEAL*)
            (setq i (1+ i))
          )
          (setq used (* cols rows))
          (setq waste (* used (/ grout 100.0)))
          (RMR:Text (list x1 (- y1 (* 8.0 s)))
                    (strcat "TILING SETOUT " (itoa (fix tw)) " x " (itoa (fix th))
                            "mm  |  " (itoa cols) " x " (itoa rows) " = "
                            (itoa used) " TILES  |  WITH " (RMR:Num grout 0)
                            "% WASTE ORDER " (itoa (fix (+ used waste))) " TILES")
                    (* 2.4 s) "RMR-LABEL" "RMR-M-FINISH" *RMR-BRAND-TEAL*)
          (princ (strcat "\nSetout: " (itoa cols) " x " (itoa rows) " = " (itoa used)
                         " tiles, order " (itoa (fix (+ used waste)))
                         " with " (RMR:Num grout 0) "% waste."))
        )
      )
    )
  )
  (princ)
)

;;; --- reflected ceiling plan -------------------------------------------------
(defun C:RMR-RCP (/ p1 p2 x1 y1 x2 y2 module spacing cols rows i x y count s)
  (RMR:EnsureReady)
  (setq s (RMR:Scaled 1.0))
  (setq p1 (getpoint "\nFirst corner of the ceiling: "))
  (if p1
    (progn
      (setq p2 (getcorner p1 "\nOther corner of the ceiling: "))
      (if p2
        (progn
          (setq x1 (min (car p1) (car p2)))
          (setq y1 (min (cadr p1) (cadr p2)))
          (setq x2 (max (car p1) (car p2)))
          (setq y2 (max (cadr p1) (cadr p2)))
          (setq module (RMR:PromptReal "Ceiling grid module in mm" 600.0))
          (setq spacing (RMR:PromptReal "Light fitting spacing in mm" 1200.0))
          (setq cols (fix (/ (- x2 x1) module)))
          (setq rows (fix (/ (- y2 y1) module)))
          (setq i 1)
          (while (and (< i cols) (< i 80))
            (setq x (+ x1 (* i module)))
            (RMR:Line (list x y1) (list x y2) "RMR-M-CEILING" *RMR-BRAND-SAND*)
            (setq i (1+ i))
          )
          (setq i 1)
          (while (and (< i rows) (< i 80))
            (setq y (+ y1 (* i module)))
            (RMR:Line (list x1 y) (list x2 y) "RMR-M-CEILING" *RMR-BRAND-SAND*)
            (setq i (1+ i))
          )
          (setq count 0)
          (setq i 0)
          (while (< (+ x1 (* (+ i 0.5) spacing)) x2)
            (setq y y1)
            (setq y (+ y (* 0.5 spacing)))
            (while (< y y2)
              (setq x (+ x1 (* (+ i 0.5) spacing)))
              (RMR:Circle (list x y) (* 90.0 (/ module 600.0)) "RMR-M-CEILING" *RMR-BRAND-GOLD*)
              (RMR:Line (list (- x (* 120.0 (/ module 600.0))) y)
                        (list (+ x (* 120.0 (/ module 600.0))) y)
                        "RMR-M-CEILING" *RMR-BRAND-GOLD*)
              (RMR:Line (list x (- y (* 120.0 (/ module 600.0))))
                        (list x (+ y (* 120.0 (/ module 600.0))))
                        "RMR-M-CEILING" *RMR-BRAND-GOLD*)
              (setq count (1+ count))
              (setq y (+ y spacing))
            )
            (setq i (1+ i))
          )
          (RMR:Text (list x1 (- y1 (* 8.0 s)))
                    (strcat "RCP  |  GRID " (itoa (fix module)) "mm  |  "
                            (itoa count) " LIGHT FITTINGS AT " (itoa (fix spacing)) "mm")
                    (* 2.4 s) "RMR-LABEL" "RMR-M-CEILING" *RMR-BRAND-SAND*)
          (princ (strcat "\nReflected ceiling plan drawn: " (itoa count)
                         " fittings on a " (itoa (fix module)) "mm grid."))
        )
      )
    )
  )
  (princ)
)

;;; --- level schedule ---------------------------------------------------------
(defun C:RMR-LEVELSCHED (/ point s text colw rowh width y row i cx label-index)
  (RMR:EnsureReady)
  (setq point (getpoint "\nTop-left of the level schedule: "))
  (if point
    (progn
      (setq s (RMR:Scaled 1.0))
      (setq text (* 2.3 s))
      (setq colw (list (* 30.0 s) (* 34.0 s) (* 96.0 s)))
      (setq width (+ (nth 0 colw) (nth 1 colw) (nth 2 colw)))
      (setq rowh (* 8.0 s))
      (setq y (cadr point))
      (RMR:Text point "LEVEL SCHEDULE  |  RMR-LEVELSCHED" (* 4.5 s) "RMR-HEAD"
                "RMR-A-TEXT" *RMR-BRAND-TERRA*)
      (RMR:Text (RMR:PT+ point 0.0 (- (* 5.5 s)))
                (strcat "DATUM " (RMR:ProjectValue "PROJECT" "")
                        "   |   LEVELS IN MILLIMETRES ABOVE DATUM")
                (* 2.2 s) "RMR-NOTE" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
      (setq y (- y (* 13.0 s)))
      (RMR:Solid (list (car point) (- y rowh) 0.0) width rowh "RMR-PRES-TITLE" *RMR-BRAND-SAND*)
      (foreach label-index '(0 1 2)
        (setq cx (car point))
        (setq i 0)
        (while (< i label-index)
          (setq cx (+ cx (nth i colw)))
          (setq i (1+ i))
        )
        (RMR:Text (RMR:PT+ (list cx (- y rowh) 0.0) (* 1.6 s) (* 2.2 s))
                  (nth label-index '("LEVEL" "HEIGHT" "DESCRIPTION"))
                  text "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-INK*)
      )
      (RMR:TableDividers (car point) (- y rowh) colw rowh "RMR-A-FRAME" *RMR-BRAND-INK*)
      (setq y (- y rowh))
      (foreach row *RMR-LEVEL-SPECS*
        (RMR:Rect (list (car point) (- y rowh) 0.0) width rowh "RMR-A-FRAME" *RMR-BRAND-SLATE*)
        (RMR:TableDividers (car point) (- y rowh) colw rowh "RMR-A-FRAME" *RMR-BRAND-SLATE*)
        (RMR:Text (RMR:PT+ (list (car point) (- y rowh) 0.0) (* 1.6 s) (* 2.2 s))
                  (nth 0 row) text "RMR-NUMBER" "RMR-A-TEXT" *RMR-BRAND-TERRA*)
        (RMR:Text (RMR:PT+ (list (+ (car point) (nth 0 colw)) (- y rowh) 0.0) (* 1.6 s) (* 2.2 s))
                  (strcat (RMR:Num (nth 1 row) 0) " mm") text "RMR-BODY"
                  "RMR-A-TEXT" *RMR-BRAND-INK*)
        (RMR:Text (RMR:PT+ (list (+ (car point) (nth 0 colw) (nth 1 colw)) (- y rowh) 0.0)
                           (* 1.6 s) (* 2.2 s))
                  (nth 2 row) text "RMR-BODY" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
        (setq y (- y rowh))
      )
      (princ (strcat "\nLevel schedule placed with " (itoa (length *RMR-LEVEL-SPECS*))
                     " levels from *RMR-LEVEL-SPECS*."))
    )
  )
  (princ)
)

;;; --- keynote library ---------------------------------------------------------
(defun C:RMR-KEYLIB (/ point s y row text)
  (RMR:EnsureReady)
  (setq point (getpoint "\nTop-left of the keynote legend: "))
  (if point
    (progn
      (setq s (RMR:Scaled 1.0))
      (setq text (* 2.2 s))
      (setq y (cadr point))
      (RMR:Text point "KEYNOTE LEGEND  |  RMR-KEYLIB" (* 4.5 s) "RMR-HEAD"
                "RMR-A-TEXT" *RMR-BRAND-TERRA*)
      (setq y (- y (* 8.0 s)))
      (RMR:Line (list (car point) y) (list (+ (car point) (* 210.0 s)) y)
                "RMR-A-TEXT" *RMR-BRAND-GOLD*)
      (setq y (- y (* 6.0 s)))
      (foreach row *RMR-KEYNOTES*
        (RMR:Circle (list (+ (car point) (* 3.0 s)) (+ y (* 1.2 s))) (* 2.6 s)
                    "RMR-A-KEYNOTE" *RMR-BRAND-GOLD*)
        (RMR:CenterText (list (+ (car point) (* 3.0 s)) (+ y (* 1.2 s))) (nth 0 row)
                        (* 2.2 s) "RMR-NUMBER" "RMR-A-KEYNOTE" *RMR-BRAND-INK*)
        (RMR:Text (list (+ (car point) (* 8.0 s)) y) (nth 1 row) text
                  "RMR-BODY" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
        (setq y (- y (* 5.0 s)))
      )
      (princ (strcat "\nKeynote legend placed with " (itoa (length *RMR-KEYNOTES*))
                     " notes from *RMR-KEYNOTES*."))
    )
  )
  (princ)
)

;;; --- standard report ----------------------------------------------------------
(defun RMR:RGBText (rgb / r g b)
  (setq r (itoa (fix (nth 0 rgb))))
  (setq g (itoa (fix (nth 1 rgb))))
  (setq b (itoa (fix (nth 2 rgb))))
  (strcat r "," g "," b)
)

(defun C:RMR-REPORT (/ path lines spec group groups weight note)
  (RMR:EnsureReady)
  (setq path (getfiled "Save the standard report"
                       (strcat "RooMNRooF_Standard_Report_" (RMR:TodayDate) ".txt")
                       "txt" 1))
  (if path
    (progn
      (setq lines
        (list
          "=============================================================="
          (strcat "RooMNRooF " *RMR-VERSION* " - STANDARD REPORT")
          (strcat "Generated " (RMR:TodayDate))
          "=============================================================="
          ""
          "PROJECT DATA"
        )
      )
      (foreach pair (RMR:ProjectPairs)
        (setq lines (append lines (list (strcat "  " (car pair) " = " (cdr pair)))))
      )
      (setq lines (append lines (list "" "LAYER PALETTE" "")))
      (setq groups nil)
      (foreach spec *RMR-LAYER-SPECS*
        (if (not (member (nth 1 spec) groups))
          (setq groups (append groups (list (nth 1 spec))))
        )
      )
      (foreach group groups
        (setq lines (append lines (list (strcat "  [" group "]"))))
        (foreach spec *RMR-LAYER-SPECS*
          (if (= (nth 1 spec) group)
            (progn
              (setq weight (nth 4 spec))
              (setq lines
                (append lines
                  (list
                    (strcat "    " (nth 0 spec)
                            "  |  RGB " (RMR:RGBText (nth 2 spec))
                            "  |  " (nth 3 spec)
                            "  |  " (if (< weight 0) "default"
                                      (strcat (RMR:Num (/ weight 100.0) 2) "mm"))
                            "  |  " (nth 5 spec)))))
            )
          )
        )
      )
      (setq lines (append lines (list "" "TEXT STYLES" "")))
      (foreach spec *RMR-TEXT-STYLES*
        (setq lines (append lines
          (list (strcat "  " (nth 0 spec) "  |  font " (nth 1 spec)
                        "  |  width " (RMR:Num (nth 2 spec) 2)
                        "  |  " (nth 4 spec)))))
      )
      (setq lines (append lines (list "" "DIMENSION STYLES" "")))
      (foreach spec *RMR-DIMSTYLE-SPECS*
        (setq lines (append lines
          (list (strcat "  " (nth 0 spec) "  |  text " (RMR:Num (nth 1 spec) 2)
                        "  |  arrows " (RMR:Num (nth 2 spec) 2)
                        "  |  " (nth 3 spec)))))
      )
      (setq lines (append lines (list "" "MATERIAL HATCH LIBRARY" "")))
      (foreach spec *RMR-HATCH-SPECS*
        (setq lines (append lines
          (list (strcat "  " (nth 0 spec) "  " (nth 1 spec) "  |  pattern "
                        (nth 2 spec) "  |  scale " (RMR:Num (nth 3 spec) 2)
                        "  |  " (nth 6 spec)))))
      )
      (setq lines (append lines (list "" "WALL TYPES" "")))
      (foreach spec *RMR-WALL-SPECS*
        (setq lines (append lines
          (list (strcat "  " (nth 0 spec) "  |  " (RMR:Num (nth 1 spec) 0)
                        "mm  |  " (nth 2 spec) "  |  " (nth 3 spec)))))
      )
      (setq lines (append lines (list "" "LEVELS" "")))
      (foreach spec *RMR-LEVEL-SPECS*
        (setq lines (append lines
          (list (strcat "  " (nth 0 spec) "  |  " (RMR:Num (nth 1 spec) 0)
                        "mm  |  " (nth 2 spec)))))
      )
      (setq lines (append lines (list "" "KEYNOTES" "")))
      (foreach spec *RMR-KEYNOTES*
        (setq lines (append lines (list (strcat "  " (nth 0 spec) "  " (nth 1 spec)))))
      )
      (setq lines (append lines (list "" "DRAWING REGISTER" "")))
      (foreach spec *RMR-SHEET-LIST*
        (setq lines (append lines
          (list (strcat "  " (nth 0 spec) "  |  " (nth 1 spec) "  |  "
                        (nth 2 spec) "  |  REV " (nth 3 spec) "  |  " (nth 4 spec)))))
      )
      (setq lines (append lines (list "" "GENERAL NOTES" "")))
      (setq spec 0)
      (foreach note *RMR-NOTES*
        (setq spec (1+ spec))
        (setq lines (append lines (list (strcat "  " (RMR:NumPad2 spec) ".  " note))))
      )
      (setq note (itoa spec))
      (setq lines
        (append lines
          (list
            ""
            "=============================================================="
            (strcat "Layers " (itoa (length *RMR-LAYER-SPECS*))
                    "  |  text styles " (itoa (length *RMR-TEXT-STYLES*))
                    "  |  dim styles " (itoa (length *RMR-DIMSTYLE-SPECS*))
                    "  |  materials " (itoa (length *RMR-HATCH-SPECS*))
                    "  |  keynotes " (itoa (length *RMR-KEYNOTES*))
                    "  |  notes " (itoa (length *RMR-NOTES*)))
            "Editable tables live near the top of RooMNRooF_Master.lsp."
            "=============================================================="
          )
        )
      )
      (if (RMR:WriteLines path lines)
        (progn
          (princ (strcat "\nStandard report written: " path))
          (princ (strcat "\n" (itoa (length lines)) " lines covering the whole standard."))
        )
        (princ "\nThe report file could not be written.")
      )
    )
  )
  (princ)
)

;;; --- stray layer audit ---------------------------------------------------------
(defun RMR:StandardLayerP (name / spec found)
  (setq found nil)
  (foreach spec *RMR-LAYER-SPECS*
    (if (= (strcase (nth 0 spec)) (strcase name)) (setq found T))
  )
  found
)

(defun C:RMR-STRAY (/ ss i data layer counts line target names)
  (RMR:EnsureReady)
  (setq ss (ssget "_X"))
  (if ss
    (progn
      (setq counts nil)
      (setq i 0)
      (repeat (sslength ss)
        (setq data (entget (ssname ss i)))
        (setq layer (cdr (assoc 8 data)))
        (if (and layer
                 (not (RMR:StandardLayerP layer))
                 (not (vl-string-search "|" layer))
                 (not (member (strcase layer) '("0" "DEFPOINTS"))))
          (setq counts (RMR:AssocCountInc layer counts))
        )
        (setq i (1+ i))
      )
      (setq counts (RMR:SortPairsDesc counts))
      (if counts
        (progn
          (princ (strcat "\nObjects on non-standard layers: " (itoa (apply '+ (mapcar 'cdr counts)))))
          (foreach line counts
            (princ (strcat "\n  " (car line) " - " (itoa (cdr line)) " object(s)"))
          )
          (if (RMR:YesP (RMR:PromptYesNo "Move them all onto a standard layer" "No"))
            (progn
              (setq names (RMR:GroupLayerNames "MAIN THEME"))
              (setq target (RMR:PromptText "Target layer" (nth 0 names)))
              (if (tblsearch "LAYER" target)
                (progn
                  (setq i 0)
                  (repeat (sslength ss)
                    (setq data (entget (ssname ss i)))
                    (setq layer (cdr (assoc 8 data)))
                    (if (and layer (not (RMR:StandardLayerP layer))
                             (not (vl-string-search "|" layer))
                             (not (member (strcase layer) '("0" "DEFPOINTS"))))
                      (vl-catch-all-apply 'entmod
                        (list (RMR:DXF 8 target data)))
                    )
                    (setq i (1+ i))
                  )
                  (princ (strcat "\nMoved the stray objects onto " target
                                 ". Run RMR-CHECK to confirm."))
                )
                (princ (strcat "\n" target " is not a layer in this drawing."))
              )
            )
          )
        )
        (princ "\nEvery object sits on a RooMNRooF standard layer.")
      )
    )
    (princ "\nThis drawing has no objects.")
  )
  (princ)
)

;;; =====================================================================
;;; PRO 7.0 COORDINATION SUITE
;;; Clash detection, parametric roofs and balustrades, glazing and zone
;;; schedules, block swapping, renumbering, text alignment, entity
;;; information and true-north orientation.
;;; =====================================================================

;;; Zone bands: (Label MaxArea_m2 Red Green Blue Pattern)
(setq *RMR-ZONE-BANDS*
 '(
    ("UNDER 5"    5.0  (214 234 226) "ANSI31")
    ("5 TO 15"   15.0  (168 214 196) "ANSI31")
    ("15 TO 30"  30.0  (110 186 165) "ANSI31")
    ("30 TO 60"  60.0  ( 57 137 130) "ANSI31")
    ("OVER 60"  99999.0 ( 31  90  86) "ANSI31")
  )
)

;;; --- clash detection ------------------------------------------------------
(defun RMR:EntityBox (ename / obj result minp maxp lo hi)
  (setq obj (vl-catch-all-apply 'vlax-ename->vla-object (list ename)))
  (if (vl-catch-all-error-p obj)
    nil
    (progn
      (setq minp nil)
      (setq maxp nil)
      (setq result (vl-catch-all-apply 'vla-GetBoundingBox (list obj 'minp 'maxp)))
      (if (vl-catch-all-error-p result)
        nil
        (progn
          (setq lo (vl-catch-all-apply 'vlax-safearray->list (list minp)))
          (setq hi (vl-catch-all-apply 'vlax-safearray->list (list maxp)))
          (if (or (vl-catch-all-error-p lo) (vl-catch-all-error-p hi))
            nil
            (list lo hi)
          )
        )
      )
    )
  )
)

(defun RMR:BoxOverlap (a b / lo1 hi1 lo2 hi2 overlap)
  (setq lo1 (nth 0 a))
  (setq hi1 (nth 1 a))
  (setq lo2 (nth 0 b))
  (setq hi2 (nth 1 b))
  (if (or (<= (car hi1) (car lo2)) (<= (car hi2) (car lo1))
          (<= (cadr hi1) (cadr lo2)) (<= (cadr hi2) (cadr lo1)))
    nil
    (progn
      (setq overlap
        (list
          (list (max (car lo1) (car lo2)) (max (cadr lo1) (cadr lo2)))
          (list (min (car hi1) (car hi2)) (min (cadr hi1) (cadr hi2)))
        )
      )
      (if (or (<= (- (car (nth 1 overlap)) (car (nth 0 overlap))) 0.0)
              (<= (- (cadr (nth 1 overlap)) (cadr (nth 0 overlap))) 0.0))
        nil
        overlap
      )
    )
  )
)

(defun C:RMR-CLASH (/ kw1 kw2 names1 names2 ss1 ss2 i j e1 e2 box1 box2 overlap
                     clashes marker s)
  (RMR:EnsureReady)
  (vl-load-com)
  (setq kw1 (RMR:PromptKeyword "First group"
                               (RMR:KeywordBar "MAIN FURNITURE STRUCTURAL PLUMBING")
                               "STRUCTURAL"))
  (if kw1
    (progn
      (setq kw2 (RMR:PromptKeyword "Second group"
                                   (RMR:KeywordBar "MAIN FURNITURE STRUCTURAL PLUMBING")
                                   "PLUMBING"))
      (if kw2
        (progn
          (setq names1 (RMR:GroupLayerNames kw1))
          (setq names2 (RMR:GroupLayerNames kw2))
          (if (or (not names1) (not names2))
            (princ "\nBoth groups must contain layers in *RMR-LAYER-SPECS*.")
            (progn
              (setq ss1 (ssget "_X" (list (cons 8 (RMR:LayerList->Filter names1)))))
              (setq ss2 (ssget "_X" (list (cons 8 (RMR:LayerList->Filter names2)))))
              (if (or (not ss1) (not ss2))
                (princ "\nOne of the groups has no objects in this drawing.")
                (progn
                  (setq clashes nil)
                  (setq i 0)
                  (repeat (sslength ss1)
                    (setq e1 (ssname ss1 i))
                    (setq box1 (RMR:EntityBox e1))
                    (if box1
                      (progn
                        (setq j 0)
                        (repeat (sslength ss2)
                          (setq e2 (ssname ss2 j))
                          (setq box2 (RMR:EntityBox e2))
                          (if box2
                            (progn
                              (setq overlap (RMR:BoxOverlap box1 box2))
                              (if overlap
                                (setq clashes
                                  (cons
                                    (list
                                      (cdr (assoc 8 (entget e1)))
                                      (cdr (assoc 8 (entget e2)))
                                      (list (/ (+ (car (nth 0 overlap)) (car (nth 1 overlap))) 2.0)
                                            (/ (+ (cadr (nth 0 overlap)) (cadr (nth 1 overlap))) 2.0))
                                      (* (- (car (nth 1 overlap)) (car (nth 0 overlap)))
                                         (- (cadr (nth 1 overlap)) (cadr (nth 0 overlap))))
                                    )
                                    clashes))
                              )
                            )
                          )
                          (setq j (1+ j))
                        )
                      )
                    )
                    (setq i (1+ i))
                  )
                  (setq s (RMR:Scaled 1.0))
                  (if clashes
                    (progn
                      (princ (strcat "\nBounding-box overlaps between " kw1 " and " kw2
                                     ": " (itoa (length clashes))))
                      (foreach marker clashes
                        (princ (strcat "\n  " (nth 0 marker) " x " (nth 1 marker)
                                       "  " (RMR:Num (nth 3 marker) 2) " mm2"))
                      )
                      (if (RMR:YesP (RMR:PromptYesNo "Mark the overlaps with circles" "Yes"))
                        (foreach marker clashes
                          (RMR:Circle (nth 2 marker) (* 4.0 s) "RMR-A-REVISION" *RMR-BRAND-TERRA*)
                        )
                      )
                      (princ "\nBounding boxes overlap objects, so treat this as a")
                      (princ "\nreview list rather than a true solid clash report.")
                    )
                    (princ (strcat "\nNo bounding-box overlaps between " kw1 " and " kw2
                                   " - clean coordination check."))
                  )
                )
              )
            )
          )
        )
      )
    )
  )
  (princ)
)

(defun RMR:LayerList->Filter (names / out name)
  ;; Builds an ssget layer filter string from a list of layer names.
  (setq out "")
  (foreach name names
    (setq out (strcat out (if (= out "") "" ",") name))
  )
  out
)

;;; --- parametric roof --------------------------------------------------------
(defun C:RMR-ROOF (/ p1 p2 x1 y1 x2 y2 over rooftype slope s ux uy nx ny
                     long short lo eaves r1 r2 hip ux2 uy2 mid corner)
  (RMR:EnsureReady)
  (setq s (RMR:Scaled 1.0))
  (setq p1 (getpoint "\nFirst corner of the building: "))
  (if p1
    (progn
      (setq p2 (getcorner p1 "\nOther corner of the building: "))
      (if p2
        (progn
          (setq rooftype (RMR:PromptKeyword "Roof type"
                                        (RMR:KeywordBar "GABLE HIP SHED") "HIP"))
          (if rooftype
            (progn
              (setq over (RMR:PromptReal "Eaves overhang in mm" 600.0))
              (setq slope (RMR:PromptReal "Roof pitch in degrees" 25.0))
              (setq x1 (min (car p1) (car p2)))
              (setq y1 (min (cadr p1) (cadr p2)))
              (setq x2 (max (car p1) (car p2)))
              (setq y2 (max (cadr p1) (cadr p2)))
              ;; eaves rectangle, expanded by the overhang
              (setq eaves
                (list (list (- x1 over) (- y1 over))
                      (list (+ x2 over) (- y1 over))
                      (list (+ x2 over) (+ y2 over))
                      (list (- x1 over) (+ y2 over))))
              (RMR:PolyLine eaves nil T "RMR-M-WALL" *RMR-BRAND-TERRA*)
              ;; the ridge runs along the longer direction
              (if (>= (- x2 x1) (- y2 y1))
                (progn (setq ux 1.0) (setq uy 0.0) (setq long (- x2 x1)) (setq short (- y2 y1)))
                (progn (setq ux 0.0) (setq uy 1.0) (setq long (- y2 y1)) (setq short (- x2 x1)))
              )
              (setq nx (- uy))
              (setq ny ux)
              (setq lo (list (/ (+ x1 x2) 2.0) (/ (+ y1 y2) 2.0)))
              (cond
                ((= rooftype "GABLE")
                  (setq r1 (list (- (car lo) (* ux (/ long 2.0))) (- (cadr lo) (* uy (/ long 2.0)))))
                  (setq r2 (list (+ (car lo) (* ux (/ long 2.0))) (+ (cadr lo) (* uy (/ long 2.0)))))
                )
                ((= rooftype "HIP")
                  (setq hip (/ (- long short) 2.0))
                  (if (< hip 0.0) (setq hip 0.0))
                  (setq r1 (list (- (car lo) (* ux (/ hip 1.0))) (- (cadr lo) (* uy (/ hip 1.0)))))
                  (setq r2 (list (+ (car lo) (* ux (/ hip 1.0))) (+ (cadr lo) (* uy (/ hip 1.0)))))
                )
                ((= rooftype "SHED")
                  (setq r1 (list (- (car lo) (* ux (/ long 2.0))) (- (cadr lo) (* uy (/ long 2.0)))))
                  (setq r2 (list (+ (car lo) (* ux (/ long 2.0))) (+ (cadr lo) (* uy (/ long 2.0)))))
                )
              )
              (if (/= rooftype "SHED")
                (RMR:Line r1 r2 "RMR-M-WALL" *RMR-BRAND-TERRA*)
              )
              (if (= rooftype "HIP")
                (progn
                  (foreach corner eaves
                    (if (< (+ (* (- (car corner) (car lo)) nx) (* (- (cadr corner) (cadr lo)) ny)) 0.0)
                      (RMR:Line corner r1 "RMR-M-WALL" *RMR-BRAND-TERRA*)
                      (RMR:Line corner r2 "RMR-M-WALL" *RMR-BRAND-TERRA*)
                    )
                  )
                )
              )
              ;; slope arrow across the short direction with the pitch label
              (setq ux2 nx)
              (setq uy2 ny)
              (setq mid (list (- (car lo) (* ux2 (/ (+ short (* 2.0 over)) 2.0)))
                              (- (cadr lo) (* uy2 (/ (+ short (* 2.0 over)) 2.0)))))
              (RMR:Line mid (list (+ (car mid) (* ux2 (+ short (* 2.0 over))))
                                  (+ (cadr mid) (* uy2 (+ short (* 2.0 over)))))
                        "RMR-A-ARROW" *RMR-BRAND-TERRA*)
              (RMR:SolidTri (list (+ (car mid) (* ux2 (+ short (* 2.0 over))))
                                  (+ (cadr mid) (* uy2 (+ short (* 2.0 over)))))
                            (- ux2) (- uy2) (* 4.0 s) "RMR-A-ARROW" *RMR-BRAND-TERRA*)
              (RMR:RotText (list (+ (car mid) (* 3.0 s)) (+ (cadr mid) (* 3.0 s)))
                           (strcat rooftype " ROOF  |  PITCH " (RMR:Num slope 1) " DEG  |  "
                                   (RMR:Num (RMR:LinearToMetres over) 2) "m EAVES")
                           (* 2.4 s) "RMR-LABEL" "RMR-A-TEXT" *RMR-BRAND-TERRA*
                           (if (= ux 1.0) 0.0 (/ pi 2.0)))
              (princ (strcat "\n" rooftype " roof drawn over "
                             (RMR:Num (RMR:LinearToMetres (- x2 x1)) 2) " x "
                             (RMR:Num (RMR:LinearToMetres (- y2 y1)) 2) "m."))
            )
          )
        )
      )
    )
  )
  (princ)
)

;;; --- balustrade -------------------------------------------------------------
(defun C:RMR-RAIL (/ pts p next spacing width s i total handrail
                    seg-start seg-end seg-len count step ang j pt)
  (RMR:EnsureReady)
  (setq s (RMR:Scaled 1.0))
  (setq p (getpoint "\nStart of the balustrade: "))
  (if p
    (progn
      (setq pts (list (list (car p) (cadr p))))
      (setq next (getpoint (last pts) "\nNext point <enter to finish>: "))
      (while next
        (setq pts (append pts (list (list (car next) (cadr next)))))
        (setq next (getpoint (last pts) "\nNext point <enter to finish>: "))
      )
      (if (< (length pts) 2)
        (princ "\nA balustrade needs at least two points.")
        (progn
          (setq width (RMR:PromptReal "Balustrade thickness in mm" 100.0))
          (setq spacing (RMR:PromptReal "Post spacing in mm" 1100.0))
          ;; handrail: offset the path both sides of the thickness
          (setq handrail (RMR:OffsetPath pts (/ width 2.0)))
          (RMR:PolyLine handrail nil nil "RMR-M-FINISH" *RMR-BRAND-TEAL*)
          (RMR:PolyLine (RMR:OffsetPath pts (- (/ width 2.0))) nil nil
                        "RMR-M-FINISH" *RMR-BRAND-TEAL*)
          ;; posts along the path at the chosen spacing
          (setq i 0)
          (setq total (length pts))
          (while (< i (1- total))
            (setq seg-start (nth i pts))
            (setq seg-end (nth (1+ i) pts))
            (setq seg-len (distance seg-start seg-end))
            (setq count (fix (/ seg-len spacing)))
            (if (< count 1) (setq count 1))
            (setq step (/ seg-len (float count)))
            (setq ang (angle seg-start seg-end))
            ;; the shared vertex already carries a post, so later segments
            ;; start at the first interior spacing
            (setq j (if (= i 0) 0 1))
            (while (<= j count)
              (setq pt (RMR:Polar seg-start ang (* step j)))
              (RMR:Circle pt (* 25.0 (/ width 100.0)) "RMR-M-FINISH" *RMR-BRAND-TEAL*)
              (setq j (1+ j))
            )
            (setq i (1+ i))
          )
          (princ (strcat "\nBalustrade drawn: " (itoa (length pts))
                         " vertices, posts at " (RMR:Num spacing 0) "mm."))
        )
      )
    )
  )
  (princ)
)

;;; --- glazing schedule --------------------------------------------------------
(defun C:RMR-WINDOWSCHED (/ ss i data name layer counts rows point s text colw
                             rowh width y row index parts)
  (RMR:EnsureReady)
  (princ "\nSelect the glazing blocks <enter for the whole drawing>: ")
  (setq ss (ssget '((0 . "INSERT"))))
  (if (not ss) (setq ss (ssget "_X" '((0 . "INSERT")))))
  (if ss
    (progn
      (setq counts nil)
      (setq i 0)
      (repeat (sslength ss)
        (setq data (entget (ssname ss i)))
        (setq name (cdr (assoc 2 data)))
        (setq layer (cdr (assoc 8 data)))
        (if (wcmatch (strcase name) "RMR-SYM-WINDOW*")
          (setq counts (RMR:AssocCountInc (strcat name "|" layer) counts))
        )
        (setq i (1+ i))
      )
      (setq rows (RMR:SortPairsDesc counts))
      (if rows
        (progn
          (setq point (getpoint "\nTop-left of the glazing schedule: "))
          (if point
            (progn
              (setq s (RMR:Scaled 1.0))
              (setq text (* 2.3 s))
              (setq colw (list (* 14.0 s) (* 70.0 s) (* 70.0 s) (* 18.0 s)))
              (setq width (+ (nth 0 colw) (nth 1 colw) (nth 2 colw) (nth 3 colw)))
              (setq rowh (* 8.0 s))
              (setq y (cadr point))
              (RMR:Text point "GLAZING SCHEDULE  |  RMR-WINDOWSCHED" (* 4.5 s)
                        "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-TERRA*)
              (setq y (- y (* 13.0 s)))
              (RMR:Solid (list (car point) (- y rowh) 0.0) width rowh
                         "RMR-PRES-TITLE" *RMR-BRAND-SAND*)
              (RMR:Text (RMR:PT+ (list (car point) (- y rowh) 0.0) (* 2.0 s) (* 2.2 s))
                        "NO." text "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-INK*)
              (RMR:Text (RMR:PT+ (list (+ (car point) (nth 0 colw)) (- y rowh) 0.0) (* 2.0 s) (* 2.2 s))
                        "TYPE" text "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-INK*)
              (RMR:Text (RMR:PT+ (list (+ (car point) (nth 0 colw) (nth 1 colw)) (- y rowh) 0.0) (* 2.0 s) (* 2.2 s))
                        "LAYER" text "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-INK*)
              (RMR:Text (RMR:PT+ (list (+ (car point) (nth 0 colw) (nth 1 colw) (nth 2 colw)) (- y rowh) 0.0) (* 2.0 s) (* 2.2 s))
                        "QTY" text "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-INK*)
              (RMR:TableDividers (car point) (- y rowh) colw rowh "RMR-A-FRAME" *RMR-BRAND-INK*)
              (setq y (- y rowh))
              (setq index 0)
              (foreach row rows
                (setq parts (RMR:SplitString (car row) "|"))
                (RMR:Rect (list (car point) (- y rowh) 0.0) width rowh
                          "RMR-A-FRAME" *RMR-BRAND-SLATE*)
                (RMR:TableDividers (car point) (- y rowh) colw rowh "RMR-A-FRAME" *RMR-BRAND-SLATE*)
                (RMR:Text (RMR:PT+ (list (car point) (- y rowh) 0.0) (* 2.0 s) (* 2.2 s))
                          (itoa (1+ index)) text "RMR-NUMBER" "RMR-A-TEXT" *RMR-BRAND-TERRA*)
                (RMR:Text (RMR:PT+ (list (+ (car point) (nth 0 colw)) (- y rowh) 0.0) (* 2.0 s) (* 2.2 s))
                          (nth 0 parts) text "RMR-LABEL" "RMR-A-TEXT" *RMR-BRAND-INK*)
                (RMR:Text (RMR:PT+ (list (+ (car point) (nth 0 colw) (nth 1 colw)) (- y rowh) 0.0) (* 2.0 s) (* 2.2 s))
                          (nth 1 parts) text "RMR-BODY" "RMR-A-TEXT" *RMR-BRAND-INK*)
                (RMR:Text (RMR:PT+ (list (+ (car point) (nth 0 colw) (nth 1 colw) (nth 2 colw)) (- y rowh) 0.0) (* 2.0 s) (* 2.2 s))
                          (itoa (cdr row)) text "RMR-NUMBER" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
                (setq index (1+ index))
                (setq y (- y rowh))
              )
              (princ (strcat "\nGlazing schedule placed: " (itoa (length rows)) " type(s)."))
            )
          )
        )
        (princ "\nNo RMR-SYM-WINDOW* blocks found - run RMR-SYMBOLS first.")
      )
    )
    (princ "\nNo block references in this drawing.")
  )
  (princ)
)

;;; --- zone plan ---------------------------------------------------------------
(defun RMR:ZoneBand (area / band found)
  (setq found nil)
  (foreach band *RMR-ZONE-BANDS*
    (if (and (not found) (<= area (nth 1 band))) (setq found band))
  )
  (if found found (last *RMR-ZONE-BANDS*))
)

(defun C:RMR-ZONE (/ ss i ename area band counts s y total point sorted)
  (RMR:EnsureReady)
  (setq ss (ssget '((0 . "LWPOLYLINE,POLYLINE,CIRCLE,ELLIPSE,REGION,HATCH"))))
  (if ss
    (progn
      (setq counts nil)
      (setq total 0.0)
      (setq i 0)
      (repeat (sslength ss)
        (setq ename (ssname ss i))
        (setq area (RMR:EntityArea ename))
        (if area
          (progn
            (setq area (RMR:AreaToSqm area))
            (setq band (RMR:ZoneBand area))
            (setq counts (RMR:AssocCountInc (nth 0 band) counts))
            (setq total (+ total area))
            (RMR:HatchEntity ename (nth 3 band) (nth 2 band))
          )
        )
        (setq i (1+ i))
      )
      (setq sorted (RMR:SortPairsDesc counts))
      (princ (strcat "\nZones hatched: " (itoa (sslength ss))
                     " | total area " (RMR:Num total 2) " m2"))
      (foreach pair sorted
        (princ (strcat "\n  " (car pair) " m2 band - " (itoa (cdr pair)) " room(s)"))
      )
      (setq point (getpoint "\nTop-left of the zone legend <enter to skip>: "))
      (if point
        (progn
          (setq s (RMR:Scaled 1.0))
          (setq y (cadr point))
          (RMR:Text point "ZONE PLAN  |  RMR-ZONE" (* 4.5 s) "RMR-HEAD" "RMR-A-TEXT"
                    *RMR-BRAND-TERRA*)
          (setq y (- y (* 8.0 s)))
          (foreach band *RMR-ZONE-BANDS*
            (RMR:Solid (list (car point) y) (* 10.0 s) (* 5.0 s) "RMR-M-AREA"
                       (nth 2 band))
            (RMR:Text (list (+ (car point) (* 13.0 s)) y) (nth 0 band) (* 2.4 s)
                      "RMR-LABEL" "RMR-A-TEXT" *RMR-BRAND-INK*)
            (setq y (- y (* 6.0 s)))
          )
          (RMR:Text (list (car point) (- y (* 2.0 s)))
                    (strcat "TOTAL " (RMR:Num total 2) " m2") (* 2.6 s)
                    "RMR-NUMBER" "RMR-A-TEXT" *RMR-BRAND-TERRA*)
        )
      )
    )
    (princ "\nNo closed areas selected.")
  )
  (princ)
)

(defun RMR:HatchEntity (ename pattern rgb / obj result data)
  ;; Hatches a single closed entity using the AutoCAD HATCH command path so it
  ;; works with the boundary detection AutoCAD already has.
  (vl-load-com)
  (setq obj (vl-catch-all-apply 'vlax-ename->vla-object (list ename)))
  (if (not (vl-catch-all-error-p obj))
    (progn
      (setq result
        (vl-catch-all-apply
          'command
          (list "_.-hatch" "_P" pattern "_S" (vlax-vla-object->ename obj) "" "")))
      (if (vl-catch-all-error-p result)
        nil
        (progn
          (setq result (entlast))
          (if result
            (progn
              (setq data (entget result))
              (setq data (RMR:DXF 8 "RMR-M-AREA" data))
              (setq data (RMR:DXF 420 (RMR:RGB->420 rgb) data))
              (vl-catch-all-apply 'entmod (list data))
            )
          )
          T
        )
      )
    )
    nil
  )
)

;;; --- block swap ----------------------------------------------------------------
(defun C:RMR-BLKSWAP (/ old new ss i data ename insert count skipped)
  (RMR:EnsureReady)
  (setq old (RMR:PromptText "Block name to replace" ""))
  (if (/= old "")
    (progn
      (if (not (tblsearch "BLOCK" old))
        (princ (strcat "\nThere is no block called " old " in this drawing."))
        (progn
          (setq new (RMR:PromptText "Replacement block name" ""))
          (if (not (and (/= new "") (tblsearch "BLOCK" new)))
            (princ "\nThe replacement block is missing - nothing changed.")
            (progn
              (princ (strcat "\nSelect the " old " blocks to swap <enter for all>: "))
              (setq ss (ssget (list '(0 . "INSERT") (cons 2 old))))
              (if (not ss)
                (setq ss (ssget "_X" (list '(0 . "INSERT") (cons 2 old))))
              )
              (if ss
                (progn
                  (setq count 0)
                  (setq skipped 0)
                  (setq i 0)
                  (repeat (sslength ss)
                    (setq ename (ssname ss i))
                    (setq data (entget ename))
                    (if (= (cdr (assoc 66 data)) 1)
                      (setq skipped (1+ skipped))
                      (progn
                        (setq insert
                          (entmake
                            (subst (cons 2 new) (assoc 2 data) data)))
                        (if insert
                          (progn
                            (entdel ename)
                            (setq count (1+ count))
                          )
                          (setq skipped (1+ skipped))
                        )
                      )
                    )
                    (setq i (1+ i))
                  )
                  (princ (strcat "\nSwapped " (itoa count) " block(s) from " old
                                 " to " new ". Skipped " (itoa skipped)
                                 " (attributed or failed)."))
                )
                (princ (strcat "\nNo inserts of " old " were found."))
              )
            )
          )
        )
      )
    )
  )
  (princ)
)

;;; --- renumber --------------------------------------------------------------------
(defun C:RMR-RENUMBER (/ ss order prefix start pad i ename data value)
  (RMR:EnsureReady)
  (princ "\nPick the tags to renumber in the order you want them numbered: ")
  (setq ss (ssget '((0 . "TEXT,MTEXT"))))
  (if ss
    (progn
      (setq prefix (RMR:PromptText "Prefix (empty for none)" ""))
      (setq start (RMR:PromptInt "First number" 1))
      (setq pad (RMR:YesP (RMR:PromptYesNo "Pad to two digits" "Yes")))
      ;; keep the pick order reported by ssnamex
      (setq order (vl-sort (ssnamex ss)
                           '(lambda (a b) (< (cadr (assoc 1 (caddr a)))
                                             (cadr (assoc 1 (caddr b)))))))
      (setq i 0)
      (foreach entry order
        (if (= (car entry) 1)
          (progn
            (setq ename (cadr entry))
            (setq value (itoa (+ start i)))
            (if pad (setq value (RMR:NumPad2 (+ start i))))
            (setq value (strcat prefix value))
            (setq data (entget ename))
            (vl-catch-all-apply 'entmod (list (subst (cons 1 value) (assoc 1 data) data)))
            (setq i (1+ i))
          )
        )
      )
      (princ (strcat "\nRenumbered " (itoa i) " tag(s) from " prefix
                     (itoa start) " upwards."))
      (princ "\nPick order follows the crossing window; check the result on screen.")
    )
    (princ "\nNo text selected.")
  )
  (princ)
)

;;; --- text alignment ---------------------------------------------------------------
(defun C:RMR-TEXTALIGN (/ ss p1 p2 ang i ename data value dx dy point)
  (RMR:EnsureReady)
  (princ "\nSelect the text to align: ")
  (setq ss (ssget '((0 . "TEXT"))))
  (if ss
    (progn
      (setq p1 (getpoint "\nFirst point of the baseline: "))
      (if p1
        (progn
          (setq p2 (getpoint p1 "\nSecond point of the baseline: "))
          (if p2
            (progn
              (setq ang (angle p1 p2))
              (setq i 0)
              (repeat (sslength ss)
                (setq ename (ssname ss i))
                (setq data (entget ename))
                ;; project the current insertion point onto the baseline
                (setq dx (- (car (cdr (assoc 10 data))) (car p1)))
                (setq dy (- (cadr (cdr (assoc 10 data))) (cadr p1)))
                (setq value (+ (* dx (cos ang)) (* dy (sin ang))))
                (setq point (list (+ (car p1) (* value (cos ang)))
                                  (+ (cadr p1) (* value (sin ang)))
                                  0.0))
                (setq data (RMR:DXF 10 point data))
                (setq data (RMR:DXF 11 point data))
                (if (assoc 50 data) (setq data (RMR:DXF 50 ang data)))
                (if (assoc 72 data) (setq data (RMR:DXF 72 0 data)))
                (if (assoc 73 data) (setq data (RMR:DXF 73 0 data)))
                (vl-catch-all-apply 'entmod (list data))
                (setq i (1+ i))
              )
              (princ (strcat "\nAligned " (itoa (sslength ss))
                             " text object(s) onto the picked baseline."))
            )
          )
        )
      )
    )
    (princ "\nNo single-line text selected.")
  )
  (princ)
)

;;; --- entity information -------------------------------------------------------------
(defun C:RMR-INFO (/ ename data obj result colour truecolour length area)
  (RMR:EnsureReady)
  (vl-load-com)
  (setq ename (car (entsel "\nSelect an object: ")))
  (if ename
    (progn
      (setq data (entget ename))
      (princ "\n-------------------------------------------------")
      (princ (strcat "\n Entity type   " (cdr (assoc 0 data))))
      (princ (strcat "\n Layer         " (cdr (assoc 8 data))))
      (setq colour (cdr (assoc 62 data)))
      (princ (strcat "\n Colour        "
                     (cond
                       ((not colour) "BYLAYER")
                       ((= colour 0) "BYBLOCK")
                       ((= colour 256) "BYLAYER")
                       (T (itoa colour))
                     )))
      (setq truecolour (cdr (assoc 420 data)))
      (if truecolour
        (princ (strcat "\n True colour   R" (itoa (lsh truecolour -16))
                       " G" (itoa (logand (lsh truecolour -8) 255))
                       " B" (itoa (logand truecolour 255))))
      )
      (princ (strcat "\n Linetype      "
                     (if (assoc 6 data) (cdr (assoc 6 data)) "BYLAYER")))
      (if (assoc 370 data)
        (princ (strcat "\n Lineweight    " (RMR:Num (/ (cdr (assoc 370 data)) 100.0) 2) " mm"))
      )
      (if (= (cdr (assoc 0 data)) "INSERT")
        (princ (strcat "\n Block         " (cdr (assoc 2 data))))
      )
      (if (assoc 7 data)
        (princ (strcat "\n Text style    " (cdr (assoc 7 data))))
      )
      (if (assoc 1 data)
        (princ (strcat "\n Text          " (cdr (assoc 1 data))))
      )
      (setq obj (vl-catch-all-apply 'vlax-ename->vla-object (list ename)))
      (if (not (vl-catch-all-error-p obj))
        (progn
          (setq length (vl-catch-all-apply 'vlax-get-property (list obj 'Length)))
          (if (not (vl-catch-all-error-p length))
            (princ (strcat "\n Length        " (RMR:Num length 1) " mm  =  "
                           (RMR:Num (RMR:LinearToMetres length) 3) " m"))
          )
          (setq area (vl-catch-all-apply 'vlax-get-property (list obj 'Area)))
          (if (not (vl-catch-all-error-p area))
            (princ (strcat "\n Area          " (RMR:Num (RMR:AreaToSqm area) 3)
                           " m2  =  " (RMR:Num (* (RMR:AreaToSqm area) *RMR-SQFT-PER-SQM*) 1)
                           " sq ft"))
          )
        )
      )
      (princ "\n-------------------------------------------------")
    )
    (princ "\nNothing selected.")
  )
  (princ)
)

;;; --- true north orientation --------------------------------------------------------
(defun C:RMR-ORIENT (/ angle base ss i ename obj result count)
  (RMR:EnsureReady)
  (vl-load-com)
  (setq angle (RMR:PromptAngle "Rotate the model to true north by" 0.0))
  (if (not (equal angle 0.0 0.0001))
    (progn
      (if (RMR:YesP (RMR:PromptYesNo "Rotate every object in model space" "No"))
        (progn
          (setq base (getpoint "\nRotation base point: "))
          (if base
            (progn
              (setq ss (ssget "_X" (list (cons 410 "Model"))))
              (if ss
                (progn
                  (setq count 0)
                  (setq i 0)
                  (repeat (sslength ss)
                    (setq ename (ssname ss i))
                    (setq obj (vl-catch-all-apply 'vlax-ename->vla-object (list ename)))
                    (if (not (vl-catch-all-error-p obj))
                      (progn
                        (setq result
                          (vl-catch-all-apply 'vla-Rotate
                            (list obj (vlax-3d-point base) (RMR:Radians angle))))
                        (if (not (vl-catch-all-error-p result))
                          (setq count (1+ count))
                        )
                      )
                    )
                    (setq i (1+ i))
                  )
                  (princ (strcat "\nRotated " (itoa count) " object(s) by "
                                 (RMR:Num angle 2) " degrees."))
                  (princ "\nMove the north arrow to match, then run RMR-CHECK.")
                )
                (princ "\nNothing found in model space.")
              )
            )
          )
        )
        (princ (strcat "\nNo rotation applied. True north is "
                       (RMR:Num angle 2) " degrees from the drawing Y axis."))
      )
    )
    (princ "\nAngle is zero - nothing to do.")
  )
  (princ)
)

;;; =====================================================================
;;; PRO 8.0 DOCUMENTATION SUITE
;;; Specification clauses and index, abbreviations legend, revision log,
;;; pre-issue checklist, room data schedule, document list, sheet index,
;;; cover sheet and the complete documentation sheet.
;;; =====================================================================

;;; --- specification clause library -----------------------------------------
;;; (Code Trade WorkSection Clause)
(setq *RMR-SPEC-CLAUSES*
 '(
    ("M10" "MASONRY"     "BLOCKWORK WALLS"      "Blockwork laid in stretcher bond with 10mm joints, built to the setting out grid and tied to the frame at every course.") 
    ("M20" "MASONRY"     "PLASTER AND SCREED"   "Cement sand render to internal faces, two coats, steel trowelled to a smooth finish ready for decoration.")
    ("F10" "FINISHES"    "FLOOR FINISHES"       "Floor finishes laid to falls where shown, with movement joints at door thresholds and at 6m centres.")
    ("F20" "FINISHES"    "WALL FINISHES"        "Internal walls prepared, mist coated and finished with two coats of matte emulsion to the approved colour.")
    ("F30" "FINISHES"    "CEILING FINISHES"     "Gypsum board ceilings on a suspended grid, taped, jointed and decorated to match the wall finish.")
    ("J10" "WATERPROOF"  "TANKING TO WET AREAS" "Waterproof tanking to wet areas, turned up 150mm above finished floor level and dressed into the floor waste.")
    ("K10" "JOINERY"     "INTERNAL DOORSETS"    "Internal doorsets supplied with frames, architraves, ironmongery and acoustic seals, hung to open as shown.")
    ("K20" "JOINERY"     "BUILT-IN FITMENTS"    "Built-in joinery manufactured to the room data, with adjustable shelving and soft-close fittings throughout.")
    ("L10" "SERVICES"    "PLUMBING AND DRAINAGE" "Soil and waste pipework in uPVC, falls at 1:80 minimum, with access points at every change of direction.")
    ("L20" "SERVICES"    "ELECTRICAL"           "Electrical installation to the current wiring regulations, with circuits, accessories and fittings as scheduled.")
    ("P10" "EXTERNAL"    "ROOF COVERINGS"       "Roof finish laid to the falls shown, with eaves, verges and abutments dressed to shed water clear of the walls.")
    ("P20" "EXTERNAL"    "RAINWATER GOODS"      "Gutters and downpipes sized for the roof area, discharged to the drainage system through a trapped gully.")
  )
)

;;; Abbreviation legend: (Abbreviation Meaning)
(setq *RMR-ABBREV-SPECS*
 '(
    ("AFFL"  "ABOVE FINISHED FLOOR LEVEL")
    ("BWK"   "BLOCKWORK")
    ("CL"    "CENTRE LINE")
    ("CLG"   "CEILING")
    ("DPC"   "DAMP PROOF COURSE")
    ("DWG"   "DRAWING")
    ("EXT"   "EXTERNAL")
    ("FFL"   "FINISHED FLOOR LEVEL")
    ("FW"    "FLOOR WASTE")
    ("INT"   "INTERNAL")
    ("MH"    "MANHOLE")
    ("NTS"   "NOT TO SCALE")
    ("RC"    "REINFORCED CONCRETE")
    ("SSL"   "STRUCTURAL SLAB LEVEL")
    ("T/O"   "TOP OF")
    ("TC"    "TILE CREASE")
    ("U/S"   "UNDERSIDE")
    ("WC"    "WATER CLOSET")
  )
)

;;; Revision log: (Revision Date Description By)
(setq *RMR-REVISIONS*
 '(
    ("00" "2026-01-12" "FIRST ISSUE FOR COORDINATION" "RMR")
    ("01" "2026-02-03" "LAYOUT REVISED TO CLIENT COMMENTS" "RMR")
    ("02" "2026-02-24" "DOOR AND WINDOW SCHEDULES UPDATED" "KH")
    ("03" "2026-03-10" "WET AREAS RE-DETAILED AFTER SITE SURVEY" "RMR")
    ("04" "2026-03-31" "FINISHES AND SPECIFICATION ADDED" "KH")
  )
)

;;; Pre-issue checklist: (Group Item)
(setq *RMR-CHECKLIST-SPECS*
 '(
    ("DRAWING"    "All layers set to ByLayer colour, linetype and lineweight")
    ("DRAWING"    "Drawing purged and audited with no errors")
    ("DRAWING"    "External references bound or paths resolved")
    ("LAYERS"     "No objects left on layer 0 or Defpoints")
    ("LAYERS"     "No stray layers outside *RMR-LAYER-SPECS*")
    ("ANNOTATION" "Text, dimension and leader styles are RooMNRooF styles")
    ("ANNOTATION" "Room numbers, areas and tags all present and legible")
    ("ANNOTATION" "Keynotes, levels and north arrow shown on every plan")
    ("SHEETS"     "Title block filled with the current project data")
    ("SHEETS"     "Revision letter matches the revision history table")
    ("SHEETS"     "Scale bar and drawing scale agree")
    ("ISSUE"      "Specification clauses referenced on the drawings")
    ("ISSUE"      "Abbreviations legend included in the set")
    ("ISSUE"      "Drawing register matches the sheets issued")
  )
)

;;; --- documentation helpers -------------------------------------------------
(defun RMR:Shorten (text limit / out)
  ;; Cuts a long string to limit characters and marks the cut with a full stop.
  ;; The parameter is called limit so it cannot shadow the builtin max.
  (if (<= (strlen text) limit)
    text
    (strcat (substr text 1 (max 1 (- limit 1))) ".")
  )
)

(defun RMR:DocTable (base title subtitle headers colw rows highlight scale / s text
                     rowh width y label cx i row band value)
  ;; Generic documentation table. scale is 1.0 for a paper-size sheet and
  ;; (RMR:Scaled 1.0) for model-space annotation. Returns the bottom y.
  (setq s (if (and scale (> scale 0.0)) scale (RMR:Scaled 1.0)))
  (setq text (* 2.3 s))
  (setq rowh (* 7.6 s))
  (setq width (apply '+ colw))
  (setq y (cadr base))
  (if (and title (/= title ""))
    (progn
      (RMR:Text base title (* 4.2 s) "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-TERRA*)
      (setq y (- y (* 5.0 s)))
    )
  )
  (if (and subtitle (/= subtitle ""))
    (progn
      (RMR:Text (list (car base) y 0.0) subtitle (* 2.2 s) "RMR-NOTE"
                "RMR-A-TEXT" *RMR-BRAND-SLATE*)
      (setq y (- y (* 6.0 s)))
    )
  )
  (RMR:Solid (list (car base) (- y rowh) 0.0) width rowh "RMR-PRES-TITLE"
             *RMR-BRAND-SAND*)
  (setq cx (car base))
  (setq i 0)
  (foreach label headers
    (RMR:Text (list (+ cx (* 1.6 s)) (+ (- y rowh) (* 2.2 s)) 0.0) label
              text "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-INK*)
    (setq cx (+ cx (nth i colw)))
    (setq i (1+ i))
  )
  (RMR:TableDividers (car base) (- y rowh) colw rowh "RMR-A-FRAME" *RMR-BRAND-INK*)
  (setq y (- y rowh))
  (foreach row rows
    (setq band (and highlight (= (strcase (nth 0 row)) (strcase highlight))))
    (if band
      (RMR:Solid (list (car base) (- y rowh) 0.0) width rowh "RMR-PRES-KEY"
                 *RMR-BRAND-SAND*)
    )
    (RMR:Rect (list (car base) (- y rowh) 0.0) width rowh "RMR-A-FRAME"
              *RMR-BRAND-SLATE*)
    (RMR:TableDividers (car base) (- y rowh) colw rowh "RMR-A-FRAME"
                       *RMR-BRAND-SLATE*)
    (setq cx (car base))
    (setq i 0)
    (foreach value row
      (RMR:Text (list (+ cx (* 1.6 s)) (+ (- y rowh) (* 2.2 s)) 0.0) value
                text (if (= i 0) "RMR-LABEL" "RMR-BODY") "RMR-A-TEXT"
                (if (= i 0) *RMR-BRAND-TERRA* *RMR-BRAND-INK*))
      (setq cx (+ cx (nth i colw)))
      (setq i (1+ i))
    )
    (setq y (- y rowh))
  )
  y
)

(defun RMR:DrawSpecIndex (base scale / s text rowh width colw y spec trade last-trade)
  ;; Specification index grouped by trade. Returns the y of the bottom.
  (setq s (if (and scale (> scale 0.0)) scale (RMR:Scaled 1.0)))
  (setq text (* 2.3 s))
  (setq rowh (* 7.2 s))
  (setq colw (list (* 24.0 s) (* 116.0 s)))
  (setq width (apply '+ colw))
  (setq y (cadr base))
  (RMR:Text base "SPECIFICATION INDEX  |  RMR-SPECINDEX" (* 4.2 s) "RMR-HEAD"
            "RMR-A-TEXT" *RMR-BRAND-TERRA*)
  (setq y (- y (* 5.0 s)))
  (RMR:Text (list (car base) y 0.0)
            (strcat "JOB " (RMR:ProjectValue "JOB" "") "   |   "
                    (RMR:ProjectValue "PROJECT" ""))
            (* 2.2 s) "RMR-NOTE" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
  (setq y (- y (* 6.0 s)))
  (RMR:Solid (list (car base) (- y rowh) 0.0) width rowh "RMR-PRES-TITLE"
             *RMR-BRAND-SAND*)
  (RMR:Text (list (+ (car base) (* 1.6 s)) (+ (- y rowh) (* 2.2 s)) 0.0)
            "CLAUSE" text "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-INK*)
  (RMR:Text (list (+ (car base) (nth 0 colw) (* 1.6 s)) (+ (- y rowh) (* 2.2 s)) 0.0)
            "WORK SECTION" text "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-INK*)
  (RMR:TableDividers (car base) (- y rowh) colw rowh "RMR-A-FRAME" *RMR-BRAND-INK*)
  (setq y (- y rowh))
  (setq last-trade "")
  (foreach spec *RMR-SPEC-CLAUSES*
    (setq trade (nth 1 spec))
    (if (/= (strcase trade) (strcase last-trade))
      (progn
        (RMR:Solid (list (car base) (- y rowh) 0.0) width rowh "RMR-PRES-TITLE"
                   *RMR-BRAND-TERRA*)
        (RMR:Text (list (+ (car base) (* 1.6 s)) (+ (- y rowh) (* 2.2 s)) 0.0)
                  trade text "RMR-HEAD" "RMR-PRES-TITLE" *RMR-BRAND-SAND*)
        (setq y (- y rowh))
        (setq last-trade trade)
      )
    )
    (RMR:Rect (list (car base) (- y rowh) 0.0) width rowh "RMR-A-FRAME"
              *RMR-BRAND-SLATE*)
    (RMR:TableDividers (car base) (- y rowh) colw rowh "RMR-A-FRAME"
                       *RMR-BRAND-SLATE*)
    (RMR:Text (list (+ (car base) (* 1.6 s)) (+ (- y rowh) (* 2.2 s)) 0.0)
              (nth 0 spec) text "RMR-LABEL" "RMR-A-TEXT" *RMR-BRAND-TERRA*)
    (RMR:Text (list (+ (car base) (nth 0 colw) (* 1.6 s)) (+ (- y rowh) (* 2.2 s)) 0.0)
              (nth 2 spec) text "RMR-BODY" "RMR-A-TEXT" *RMR-BRAND-INK*)
    (setq y (- y rowh))
  )
  y
)

(defun RMR:DrawAbbrev (base scale / s text count half index row y1 y2)
  ;; Two-column abbreviation legend. Returns the lower of the two column ends.
  (setq s (if (and scale (> scale 0.0)) scale (RMR:Scaled 1.0)))
  (setq text (* 2.2 s))
  (setq count (length *RMR-ABBREV-SPECS*))
  (setq half (+ (fix (/ count 2.0)) (if (= (rem count 2) 0) 0 1)))
  (RMR:Text base "ABBREVIATIONS  |  RMR-ABBREV" (* 4.2 s) "RMR-HEAD"
            "RMR-A-TEXT" *RMR-BRAND-TERRA*)
  (setq y1 (- (cadr base) (* 5.0 s)))
  (RMR:Text (list (car base) y1 0.0)
            (strcat (itoa count) " standard abbreviations")
            (* 2.2 s) "RMR-NOTE" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
  (setq y1 (- y1 (* 6.0 s)))
  (RMR:Line (list (car base) y1 0.0)
            (list (+ (car base) (* 230.0 s)) y1 0.0) "RMR-A-TEXT" *RMR-BRAND-GOLD*)
  (setq y1 (- y1 (* 5.0 s)))
  (setq y2 y1)
  (setq index 0)
  (foreach row *RMR-ABBREV-SPECS*
    (if (< index half)
      (progn
        (RMR:Text (list (car base) y1 0.0) (nth 0 row) text "RMR-LABEL"
                  "RMR-A-TEXT" *RMR-BRAND-TERRA*)
        (RMR:Text (list (+ (car base) (* 22.0 s)) y1 0.0) (nth 1 row) text
                  "RMR-BODY" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
        (setq y1 (- y1 (* 5.0 s)))
      )
      (progn
        (RMR:Text (list (+ (car base) (* 118.0 s)) y2 0.0) (nth 0 row) text
                  "RMR-LABEL" "RMR-A-TEXT" *RMR-BRAND-TERRA*)
        (RMR:Text (list (+ (car base) (* 140.0 s)) y2 0.0) (nth 1 row) text
                  "RMR-BODY" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
        (setq y2 (- y2 (* 5.0 s)))
      )
    )
    (setq index (1+ index))
  )
  (min y1 y2)
)

(defun RMR:DrawChecklist (base scale / s text rowh width y row group last-group box)
  ;; Pre-issue checklist with empty tick boxes. Returns the y of the bottom.
  (setq s (if (and scale (> scale 0.0)) scale (RMR:Scaled 1.0)))
  (setq text (* 2.2 s))
  (setq rowh (* 5.4 s))
  (setq width (* 150.0 s))
  (setq y (cadr base))
  (RMR:Text base "PRE-ISSUE CHECKLIST  |  RMR-CHECKLIST" (* 4.2 s) "RMR-HEAD"
            "RMR-A-TEXT" *RMR-BRAND-TERRA*)
  (setq y (- y (* 5.0 s)))
  (RMR:Text (list (car base) y 0.0)
            (strcat (itoa (length *RMR-CHECKLIST-SPECS*)) " items  |  tick by hand or with a revision cloud")
            (* 2.2 s) "RMR-NOTE" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
  (setq y (- y (* 6.0 s)))
  (setq last-group "")
  (foreach row *RMR-CHECKLIST-SPECS*
    (setq group (nth 0 row))
    (if (/= (strcase group) (strcase last-group))
      (progn
        (RMR:Solid (list (car base) (- y rowh) 0.0) width rowh "RMR-PRES-KEY"
                   *RMR-BRAND-SAND*)
        (RMR:Text (list (+ (car base) (* 1.6 s)) (+ (- y rowh) (* 1.6 s)) 0.0)
                  group (* 2.1 s) "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-INK*)
        (setq y (- y rowh))
        (setq last-group group)
      )
    )
    (setq box (* 3.0 s))
    (RMR:Rect (list (+ (car base) (* 1.6 s)) (+ (- y rowh) (* 1.2 s)) 0.0)
              box box "RMR-A-FRAME" *RMR-BRAND-SLATE*)
    (RMR:Text (list (+ (car base) (* 7.0 s)) (+ (- y rowh) (* 1.6 s)) 0.0)
              (nth 1 row) text "RMR-BODY" "RMR-A-TEXT" *RMR-BRAND-INK*)
    (setq y (- y rowh))
  )
  y
)

;;; --- specification notes ---------------------------------------------------
(defun C:RMR-SPECNOTE (/ keys code spec point width s trade title clause y)
  (RMR:EnsureReady)
  (setq keys (RMR:KeywordList *RMR-SPEC-CLAUSES*))
  (setq code (RMR:PromptKeyword "Specification clause" keys
                                (nth 0 (nth 0 *RMR-SPEC-CLAUSES*))))
  (if code
    (progn
      (setq spec (RMR:TableSpec code *RMR-SPEC-CLAUSES*))
      (if spec
        (progn
          (setq point (getpoint "\nTop-left of the specification note: "))
          (if point
            (progn
              (setq s (RMR:Scaled 1.0))
              (setq width (RMR:PromptReal "Note width" (* 130.0 s)))
              (setq trade (nth 1 spec))
              (setq title (nth 2 spec))
              (setq clause (nth 3 spec))
              (RMR:Solid point (* 30.0 s) (* 7.0 s) "RMR-PRES-TITLE"
                         *RMR-BRAND-TERRA*)
              (RMR:Text (RMR:PT+ point (* 2.0 s) (* 2.2 s)) code (* 3.2 s)
                        "RMR-HEAD" "RMR-PRES-TITLE" *RMR-BRAND-SAND*)
              (RMR:Text (RMR:PT+ point (* 34.0 s) (* 2.2 s)) title (* 3.4 s)
                        "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-TERRA*)
              (setq y (- (cadr point) (* 8.0 s)))
              (RMR:Text (list (car point) y 0.0)
                        (strcat "TRADE " trade "   |   CLAUSE " code)
                        (* 2.0 s) "RMR-MARK" "RMR-A-TEXT" *RMR-BRAND-GOLD*)
              (setq y (- y (* 5.0 s)))
              (RMR:MText (list (car point) y 0.0) clause width (* 2.4 s)
                         "RMR-BODY" "RMR-A-TEXT" *RMR-BRAND-INK* 1)
              (princ (strcat "\nSpecification clause " code " (" title ") placed."))
            )
          )
        )
        (princ "\nClause not found in *RMR-SPEC-CLAUSES*.")
      )
    )
  )
  (princ)
)

(defun C:RMR-SPECINDEX (/ point s)
  (RMR:EnsureReady)
  (setq point (getpoint "\nTop-left of the specification index: "))
  (if point
    (progn
      (setq s (RMR:Scaled 1.0))
      (RMR:DrawSpecIndex point s)
      (princ (strcat "\nSpecification index placed with "
                     (itoa (length *RMR-SPEC-CLAUSES*))
                     " clauses from *RMR-SPEC-CLAUSES*."))
    )
  )
  (princ)
)

(defun C:RMR-ABBREV (/ point s)
  (RMR:EnsureReady)
  (setq point (getpoint "\nTop-left of the abbreviations legend: "))
  (if point
    (progn
      (setq s (RMR:Scaled 1.0))
      (RMR:DrawAbbrev point s)
      (princ (strcat "\nAbbreviations placed: "
                     (itoa (length *RMR-ABBREV-SPECS*))
                     " entries from *RMR-ABBREV-SPECS*."))
    )
  )
  (princ)
)

(defun C:RMR-REVLIB (/ point s rows row)
  (RMR:EnsureReady)
  (setq point (getpoint "\nTop-left of the revision history: "))
  (if point
    (progn
      (setq s (RMR:Scaled 1.0))
      (setq rows '())
      (foreach row *RMR-REVISIONS*
        (setq rows (append rows (list (list (nth 0 row) (nth 1 row)
                                            (nth 2 row) (nth 3 row)))))
      )
      (RMR:DocTable point "REVISION HISTORY  |  RMR-REVLIB"
                    (strcat "Current revision " (RMR:ProjectValue "REV" "")
                            " is highlighted")
                    '("REV" "DATE" "DESCRIPTION" "BY")
                    (list (* 16.0 s) (* 30.0 s) (* 92.0 s) (* 24.0 s))
                    rows (RMR:ProjectValue "REV" "") s)
      (princ (strcat "\nRevision history placed with "
                     (itoa (length *RMR-REVISIONS*))
                     " revisions from *RMR-REVISIONS*."))
    )
  )
  (princ)
)

(defun C:RMR-CHECKLIST (/ row answer point s)
  (RMR:EnsureReady)
  (princ "\nRooMNRooF pre-issue checklist")
  (foreach row *RMR-CHECKLIST-SPECS*
    (princ (strcat "\n  [ ]  " (nth 0 row) "  -  " (nth 1 row)))
  )
  (princ "\n")
  (setq answer (RMR:PromptYesNo "Draw the checklist on the drawing" "No"))
  (if (RMR:YesP answer)
    (progn
      (setq point (getpoint "\nTop-left of the checklist: "))
      (if point
        (progn
          (setq s (RMR:Scaled 1.0))
          (RMR:DrawChecklist point s)
          (princ (strcat "\nChecklist drawn with "
                         (itoa (length *RMR-CHECKLIST-SPECS*)) " items."))
        )
      )
    )
  )
  (princ)
)

;;; --- room data schedule ----------------------------------------------------
(defun C:RMR-ROOMSCHED (/ point s rows pick ename area sqm name finish floor
                         wall ceiling number total)
  (RMR:EnsureReady)
  (vl-load-com)
  (setq s (RMR:Scaled 1.0))
  (setq rows '())
  (setq number 1)
  (setq total 0.0)
  (princ "\nSelect the closed boundary of each room. Press Enter when finished.")
  (setq pick (entsel "\nSelect room boundary <finish>: "))
  (while pick
    (setq ename (car pick))
    (setq area (RMR:EntityArea ename))
    (if (and area (> area 0.0))
      (progn
        (setq sqm (RMR:AreaToSqm area))
        (setq name (RMR:PromptText (strcat "Room " (itoa number) " name")
                                   (strcat "ROOM " (RMR:NumPad2 number))))
        (setq finish (RMR:TableSpec name *RMR-FINISH-SPECS*))
        (setq floor (if finish (nth 1 finish) "-"))
        (setq wall (if finish (nth 3 finish) "-"))
        (setq ceiling (if finish (nth 4 finish) "-"))
        (setq rows (append rows
                     (list (list (RMR:NumPad2 number) name (RMR:Num sqm 2)
                                 floor wall ceiling))))
        (setq total (+ total sqm))
        (setq number (1+ number))
        (princ (strcat "\n  " name "  " (RMR:Num sqm 2) " m2"))
      )
      (princ "\nThat object has no measurable area - skipped.")
    )
    (setq pick (entsel "\nSelect next room boundary <finish>: "))
  )
  (if rows
    (progn
      (setq point (getpoint "\nTop-left of the room schedule: "))
      (if point
        (RMR:DocTable point "ROOM SCHEDULE  |  RMR-ROOMSCHED"
                      (strcat (itoa (length rows)) " rooms  |  total "
                              (RMR:Num total 2) " m2  |  "
                              (RMR:Num (* total 10.7639) 1) " sq ft")
                      '("NO." "ROOM" "AREA M2" "FLOOR" "WALL" "CEILING")
                      (list (* 14.0 s) (* 40.0 s) (* 22.0 s) (* 50.0 s)
                            (* 46.0 s) (* 30.0 s))
                      rows nil s)
      )
      (princ (strcat "\nRoom schedule: " (itoa (length rows)) " rooms, "
                     (RMR:Num total 2) " m2 total."))
      (princ "\nFinishes come from *RMR-FINISH-SPECS* when the room name matches.")
    )
    (princ "\nNo rooms selected - nothing drawn.")
  )
  (princ)
)

;;; --- document list ---------------------------------------------------------
(defun C:RMR-DOCLIST (/ folder names name rows size point s answer path lines row)
  (RMR:EnsureReady)
  (setq folder (getvar "DWGPREFIX"))
  (setq s (RMR:Scaled 1.0))
  (setq rows '())
  (setq names (vl-directory-files folder "*.dwg" 1))
  (if names
    (foreach name names
      (setq size (vl-file-size (strcat folder name)))
      (setq rows (append rows
                   (list (list (strcase (RMR:StripExtension name)) "DWG"
                               (RMR:Num (/ (float (if size size 0)) 1024.0) 0)))))
    )
  )
  (setq names (vl-directory-files folder "*.pdf" 1))
  (if names
    (foreach name names
      (setq size (vl-file-size (strcat folder name)))
      (setq rows (append rows
                   (list (list (strcase (RMR:StripExtension name)) "PDF"
                               (RMR:Num (/ (float (if size size 0)) 1024.0) 0)))))
    )
  )
  (princ (strcat "\nDocuments in " folder))
  (foreach row rows
    (princ (strcat "\n  " (nth 0 row) "  " (nth 1 row) "  " (nth 2 row) " KB"))
  )
  (if rows
    (progn
      (setq answer (RMR:PromptYesNo "Write a CSV document list" "Yes"))
      (if (RMR:YesP answer)
        (progn
          (setq path (strcat folder "RMR-Document-List.csv"))
          (setq lines (list "FILE,TYPE,SIZE KB"))
          (foreach row rows
            (setq lines (append lines
                          (list (strcat (nth 0 row) "," (nth 1 row) ","
                                        (nth 2 row)))))
          )
          (if (RMR:WriteLines path lines)
            (princ (strcat "\nWritten: " path))
            (princ "\nCould not write the CSV file.")
          )
        )
      )
      (setq point (getpoint "\nTop-left of the document list <skip>: "))
      (if point
        (RMR:DocTable point "DOCUMENT LIST  |  RMR-DOCLIST"
                      folder
                      '("FILE" "TYPE" "SIZE KB")
                      (list (* 86.0 s) (* 20.0 s) (* 24.0 s))
                      rows nil s)
      )
    )
    (princ "\nNo DWG or PDF files found next to the current drawing.")
  )
  (princ)
)

;;; --- sheet index -----------------------------------------------------------
(defun C:RMR-SHEETINDEX (/ point s cols cw ch index row x y current)
  (RMR:EnsureReady)
  (setq point (getpoint "\nTop-left of the sheet index: "))
  (if point
    (progn
      (setq s (RMR:Scaled 1.0))
      (setq cols (RMR:PromptInt "Columns" 4))
      (setq cw (* 62.0 s))
      (setq ch (* 30.0 s))
      (setq current (RMR:ProjectValue "DWGNO" ""))
      (RMR:Text point "SHEET INDEX  |  RMR-SHEETINDEX" (* 4.2 s) "RMR-HEAD"
                "RMR-A-TEXT" *RMR-BRAND-TERRA*)
      (setq y (- (cadr point) (* 5.0 s)))
      (RMR:Text (list (car point) y 0.0)
                (strcat (itoa (length *RMR-SHEET-LIST*))
                        " sheets  |  current sheet " current " is highlighted")
                (* 2.2 s) "RMR-NOTE" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
      (setq y (- y (* 8.0 s)))
      (setq index 0)
      (foreach row *RMR-SHEET-LIST*
        (if (and (> index 0) (= (rem index cols) 0))
          (setq y (- y (+ ch (* 8.0 s))))
        )
        (setq x (+ (car point) (* (rem index cols) cw)))
        (if (= (strcase (nth 0 row)) (strcase current))
          (progn
            (RMR:Solid (list x (- y (* 8.0 s)) 0.0) cw (* 8.0 s) "RMR-PRES-TITLE"
                       *RMR-BRAND-TERRA*)
            (RMR:Text (list (+ x (* 2.0 s)) (- y (* 5.6 s)) 0.0) (nth 0 row)
                      (* 3.4 s) "RMR-NUMBER" "RMR-PRES-TITLE" *RMR-BRAND-SAND*)
            (RMR:Rect (list x (- y ch) 0.0) cw ch "RMR-A-FRAME" *RMR-BRAND-TERRA*)
          )
          (progn
            (RMR:Solid (list x (- y (* 8.0 s)) 0.0) cw (* 8.0 s) "RMR-PRES-KEY"
                       *RMR-BRAND-SAND*)
            (RMR:Text (list (+ x (* 2.0 s)) (- y (* 5.6 s)) 0.0) (nth 0 row)
                      (* 3.4 s) "RMR-NUMBER" "RMR-A-TEXT" *RMR-BRAND-INK*)
            (RMR:Rect (list x (- y ch) 0.0) cw ch "RMR-A-FRAME" *RMR-BRAND-SLATE*)
          )
        )
        (RMR:Text (list (+ x (* 2.0 s)) (- y (* 14.0 s)) 0.0)
                  (RMR:Shorten (nth 1 row) 26) (* 2.1 s) "RMR-BODY"
                  "RMR-A-TEXT" *RMR-BRAND-INK*)
        (RMR:Text (list (+ x (* 2.0 s)) (- y (* 18.4 s)) 0.0)
                  (strcat (nth 2 row) "   REV " (nth 3 row)) (* 2.0 s)
                  "RMR-NOTE" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
        (RMR:Text (list (+ x (* 2.0 s)) (- y (* 26.0 s)) 0.0)
                  (RMR:Shorten (nth 4 row) 26) (* 2.0 s) "RMR-MARK"
                  "RMR-A-TEXT" *RMR-BRAND-GOLD*)
        (setq index (1+ index))
      )
      (princ (strcat "\nSheet index drawn from *RMR-SHEET-LIST*: "
                     (itoa (length *RMR-SHEET-LIST*)) " sheets."))
    )
  )
  (princ)
)

;;; --- cover sheet -----------------------------------------------------------
(defun C:RMR-COVER (/ size dims scale base outer inset iw ih top y row)
  (RMR:EnsureReady)
  (initget "A0 A1 A2 A3 A4")
  (setq size (getkword "\nCover sheet size [A0/A1/A2/A3/A4] <A1>: "))
  (if (not size) (setq size "A1"))
  (setq dims (RMR:SheetSize size))
  (setq scale (getreal "\nSheet scale factor <1.0>: "))
  (if (or (not scale) (<= scale 0.0)) (setq scale 1.0))
  (setq base (getpoint "\nPick lower-left cover sheet point: "))
  (if base
    (progn
      (setq outer (list (car base) (cadr base) 0.0))
      (setq inset (* 10.0 scale))
      (setq iw (- (* (car dims) scale) (* 2.0 inset)))
      (setq ih (- (* (cadr dims) scale) (* 2.0 inset)))
      (RMR:Rect outer (* (car dims) scale) (* (cadr dims) scale) "RMR-A-FRAME"
                *RMR-BRAND-INK*)
      (RMR:Rect (RMR:PT+ outer inset inset) iw ih "RMR-A-FRAME" *RMR-BRAND-TEAL*)
      ;; brand strip
      (setq top (+ (cadr outer) (* (cadr dims) scale) (- inset)))
      (RMR:Solid (list (+ (car outer) inset) (- top (* 42.0 scale)) 0.0) iw
                 (* 42.0 scale) "RMR-PRES-TITLE" *RMR-BRAND-TERRA*)
      (RMR:Text (list (+ (car outer) inset (* 10.0 scale)) (- top (* 27.0 scale)) 0.0)
                "RooMNRooF" (* 17.0 scale) "RMR-TITLE" "RMR-PRES-TITLE"
                *RMR-BRAND-SAND*)
      (RMR:Text (list (+ (car outer) inset (* 10.0 scale)) (- top (* 13.0 scale)) 0.0)
                "CONSULTANT   |   2D CAD STANDARD" (* 4.2 scale) "RMR-HEAD"
                "RMR-PRES-TITLE" *RMR-BRAND-SAND*)
      ;; project identity
      (setq y (- top (* 68.0 scale)))
      (RMR:Text (list (+ (car outer) inset) y 0.0)
                (strcase (RMR:ProjectValue "PROJECT" "PROJECT TITLE"))
                (* 11.0 scale) "RMR-TITLE" "RMR-A-TEXT" *RMR-BRAND-INK*)
      (setq y (- y (* 13.0 scale)))
      (RMR:Text (list (+ (car outer) inset) y 0.0)
                (strcase (RMR:ProjectValue "CLIENT" "CLIENT NAME"))
                (* 5.4 scale) "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-TERRA*)
      (setq y (- y (* 9.0 scale)))
      (RMR:Text (list (+ (car outer) inset) y 0.0)
                (strcat "JOB " (RMR:ProjectValue "JOB" "0000")
                        "   |   " (RMR:ProjectValue "STAGE" "STAGE")
                        "   |   " (RMR:TodayDate))
                (* 3.4 scale) "RMR-NOTE" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
      ;; drawing set listing
      (setq y (- y (* 12.0 scale)))
      (RMR:Line (list (+ (car outer) inset) y 0.0)
                (list (+ (car outer) inset iw) y 0.0) "RMR-A-TEXT"
                *RMR-BRAND-GOLD*)
      (setq y (- y (* 12.0 scale)))
      (RMR:Text (list (+ (car outer) inset) y 0.0)
                "DRAWING SET  |  *RMR-SHEET-LIST*" (* 4.4 scale) "RMR-HEAD"
                "RMR-A-TEXT" *RMR-BRAND-TERRA*)
      (setq y (- y (* 9.0 scale)))
      (foreach row *RMR-SHEET-LIST*
        (RMR:Text (list (+ (car outer) inset) y 0.0) (nth 0 row)
                  (* 3.4 scale) "RMR-NUMBER" "RMR-A-TEXT" *RMR-BRAND-TERRA*)
        (RMR:Text (list (+ (car outer) inset (* 28.0 scale)) y 0.0)
                  (RMR:Shorten (nth 1 row) 46) (* 3.2 scale) "RMR-BODY"
                  "RMR-A-TEXT" *RMR-BRAND-INK*)
        (RMR:Text (list (+ (car outer) inset (* 300.0 scale)) y 0.0)
                  (nth 2 row) (* 3.0 scale) "RMR-BODY" "RMR-A-TEXT"
                  *RMR-BRAND-SLATE*)
        (RMR:Text (list (+ (car outer) inset (* 350.0 scale)) y 0.0)
                  (strcat "REV " (nth 3 row)) (* 3.0 scale) "RMR-MARK"
                  "RMR-A-TEXT" *RMR-BRAND-GOLD*)
        (setq y (- y (* 6.4 scale)))
      )
      ;; title block anchored lower right
      (RMR:DrawTitleBlock
        (RMR:PT+ outer (- (* (car dims) scale) inset (* 190.0 scale)) inset)
        190.0 50.0 scale)
      (princ (strcat "\n" size " cover sheet created with "
                     (itoa (length *RMR-SHEET-LIST*)) " sheets listed."))
    )
  )
  (princ)
)

;;; --- complete documentation sheet -----------------------------------------
(defun C:RMR-DOCSHEET (/ size dims base outer inset iw ih top p1 p2 p3 p4
                       rows row)
  (RMR:EnsureReady)
  (initget "A0 A1 A2 A3 A4")
  (setq size (getkword "\nDocumentation sheet size [A0/A1/A2/A3/A4] <A1>: "))
  (if (not size) (setq size "A1"))
  (setq dims (RMR:SheetSize size))
  (setq base (getpoint "\nPick lower-left documentation sheet point: "))
  (if base
    (progn
      (setq outer (list (car base) (cadr base) 0.0))
      (setq inset 10.0)
      (setq iw (- (car dims) (* 2.0 inset)))
      (setq ih (- (cadr dims) (* 2.0 inset)))
      (RMR:Rect outer (car dims) (cadr dims) "RMR-A-FRAME" *RMR-BRAND-INK*)
      (RMR:Rect (RMR:PT+ outer inset inset) iw ih "RMR-A-FRAME" *RMR-BRAND-TEAL*)
      (setq top (+ (cadr outer) (cadr dims) (- inset)))
      (RMR:Solid (list (+ (car outer) inset) (- top 26.0) 0.0) iw 26.0
                 "RMR-PRES-TITLE" *RMR-BRAND-TERRA*)
      (RMR:Text (list (+ (car outer) inset 8.0) (- top 17.0) 0.0)
                "DOCUMENTATION SHEET" 9.0 "RMR-TITLE" "RMR-PRES-TITLE"
                *RMR-BRAND-SAND*)
      (RMR:Text (list (+ (car outer) inset 8.0) (- top 6.0) 0.0)
                (strcat (RMR:ProjectValue "PROJECT" "")
                        "   |   JOB " (RMR:ProjectValue "JOB" "")
                        "   |   REV " (RMR:ProjectValue "REV" "")
                        "   |   " (RMR:TodayDate))
                3.0 "RMR-HEAD" "RMR-PRES-TITLE" *RMR-BRAND-SAND*)
      ;; left: specification index, right: abbreviations
      (setq p1 (list (+ (car outer) 24.0) (- top 44.0) 0.0))
      (RMR:DrawSpecIndex p1 1.0)
      (setq p2 (list (+ (car outer) 210.0) (- top 44.0) 0.0))
      (RMR:DrawAbbrev p2 1.0)
      ;; right column: revision history and checklist
      (setq rows '())
      (foreach row *RMR-REVISIONS*
        (setq rows (append rows (list (list (nth 0 row) (nth 1 row)
                                            (nth 2 row) (nth 3 row)))))
      )
      (setq p3 (list (+ (car outer) 470.0) (- top 44.0) 0.0))
      (RMR:DocTable p3 "REVISION HISTORY"
                    (strcat "Current revision " (RMR:ProjectValue "REV" ""))
                    '("REV" "DATE" "DESCRIPTION" "BY")
                    (list 16.0 30.0 84.0 22.0) rows (RMR:ProjectValue "REV" "") 1.0)
      (setq p4 (list (+ (car outer) 470.0) (- top 300.0) 0.0))
      (RMR:DrawChecklist p4 1.0)
      ;; title block
      (RMR:DrawTitleBlock (RMR:PT+ outer (- (car dims) 200.0) 10.0)
                          190.0 50.0 1.0)
      (princ (strcat "\n" size " documentation sheet created: specification index, "))
      (princ (strcat "\n" (itoa (length *RMR-ABBREV-SPECS*))
                     " abbreviations, " (itoa (length *RMR-REVISIONS*))
                     " revisions and " (itoa (length *RMR-CHECKLIST-SPECS*))
                     " checklist items."))
    )
  )
  (princ)
)

;;; =====================================================================
;;; PRO 9.0 PRESENTATION SUITE
;;; Axonometric massing, one point interior perspectives, layered
;;; construction build-ups, material swatch boards, colour reference
;;; boards, image boards, area distribution charts, programme bar
;;; charts, the brand masthead and the complete presentation sheet.
;;; =====================================================================

;;; --- construction build-ups -----------------------------------------------
;;; (Type Order LayerName Thickness_mm (R G B) Pattern Note)
(setq *RMR-BUILDUP-SPECS*
 '(
    ("EXTWALL" 1 "EXTERNAL RENDER"       15 (230 226 216) "AR-SAND"  "Silicone render, matte finish")
    ("EXTWALL" 2 "BLOCKWORK"            200 (198 186 168) "ANSI31"   "200mm dense concrete blockwork")
    ("EXTWALL" 3 "CAVITY INSULATION"     60 (168 214 196) "ANSI31"   "60mm rigid insulation board")
    ("EXTWALL" 4 "PLASTERBOARD"          13 (244 241 234) "SOLID"    "12.5mm plasterboard on dabs")
    ("EXTWALL" 5 "SKIM AND EMULSION"      3 (214 234 226) "SOLID"    "2mm skim coat and two coats")
    ("INTWALL" 1 "PLASTERBOARD"          13 (244 241 234) "SOLID"    "12.5mm plasterboard, both faces")
    ("INTWALL" 2 "STUD PARTITION"       100 (198 186 168) "ANSI31"   "100mm metal stud at 600 centres")
    ("INTWALL" 3 "PLASTERBOARD"          13 (244 241 234) "SOLID"    "12.5mm plasterboard, both faces")
    ("FLOOR"   1 "FLOOR FINISH"          20 (214 163  76) "AR-HBONE" "Engineered oak or porcelain tile")
    ("FLOOR"   2 "CEMENT SCREED"         65 (198 186 168) "AR-SAND"  "65mm cement sand screed")
    ("FLOOR"   3 "ACOUSTIC LAYER"        50 (168 214 196) "ANSI31"   "50mm acoustic and thermal layer")
    ("FLOOR"   4 "STRUCTURAL SLAB"      250 (145 155 160) "AR-CONC"  "250mm reinforced concrete slab")
    ("ROOF"    1 "ROOF COVERING"         30 ( 57 137 130) "ANSI31"   "Standing seam or concrete tile")
    ("ROOF"    2 "BREATHER MEMBRANE"      2 (214 234 226) "SOLID"    "Vapour permeable underlay")
    ("ROOF"    3 "STRUCTURAL DECK"       18 (214 163  76) "AR-HBONE" "18mm ply deck on joists")
    ("ROOF"    4 "JOIST AND INSULATION" 220 (198 186 168) "ANSI31"   "220mm insulated joist zone")
    ("ROOF"    5 "PLASTERBOARD"          13 (244 241 234) "SOLID"    "12.5mm plasterboard ceiling")
  )
)

;;; Programme bars: (Stage StartWeek DurationWeeks ColourKey)
(setq *RMR-PROGRAMME-SPECS*
 '(
    ("CONCEPT DESIGN"      0  4 "TEAL")
    ("DEVELOPED DESIGN"    4  6 "TERRA")
    ("TECHNICAL DESIGN"   10  8 "GOLD")
    ("STATUTORY APPROVAL" 16  6 "BLUE")
    ("CONSTRUCTION"       22 16 "SLATE")
    ("HANDOVER"           38  3 "SAND")
  )
)

;;; Mood board slots: (Slot Caption)
(setq *RMR-MOOD-SPECS*
 '(
    ("01" "EXTERNAL APPROACH")
    ("02" "LIVING SPACE")
    ("03" "KITCHEN AND DINING")
    ("04" "BEDROOM")
    ("05" "BATHROOM")
    ("06" "MATERIAL DETAIL")
  )
)

;;; --- presentation helpers --------------------------------------------------
(defun RMR:BrandRGB (key / value)
  ;; Brand colour by keyword, so programme and chart rows stay on palette.
  (cond
    ((= (strcase key) "INK")   (setq value *RMR-BRAND-INK*))
    ((= (strcase key) "TERRA") (setq value *RMR-BRAND-TERRA*))
    ((= (strcase key) "TEAL")  (setq value *RMR-BRAND-TEAL*))
    ((= (strcase key) "GOLD")  (setq value *RMR-BRAND-GOLD*))
    ((= (strcase key) "SAND")  (setq value *RMR-BRAND-SAND*))
    ((= (strcase key) "BLUE")  (setq value *RMR-BRAND-BLUE*))
    ((= (strcase key) "SLATE") (setq value *RMR-BRAND-SLATE*))
    (T (setq value *RMR-BRAND-TERRA*))
  )
  value
)

(defun RMR:ThemeName (group)
  ;; RMR:GroupKeywords returns short group words; only MAIN is a "THEME" group.
  (if (= (strcase group) "MAIN")
    "MAIN THEME"
    (strcase group)
  )
)

(defun RMR:Quad (q1 q2 q3 q4 layer rgb)
  ;; Filled quadrilateral. The corners are given in order round the quad; a DXF
  ;; SOLID draws 10-11-13-12, so groups 12 and 13 are swapped on the way in.
  (entmake
    (list
      '(0 . "SOLID")
      (cons 8 layer)
      (cons 10 (RMR:3D q1))
      (cons 11 (RMR:3D q2))
      (cons 12 (RMR:3D q4))
      (cons 13 (RMR:3D q3))
      '(62 . 7)
      (cons 420 (RMR:RGB->420 rgb))
    )
  )
)

(defun RMR:ClosedPoly (pts layer rgb / data)
  ;; Closed LWPOLYLINE boundary, returned as an ename so it can be hatched.
  (setq data (RMR:PolyLine pts nil T layer rgb))
  (if data (cdr (assoc -1 data)) nil)
)

(defun RMR:FillLayer (ename pattern scale angle rgb layer / obj result data args)
  ;; Hatch one closed entity through the HATCH command path and then move the
  ;; result onto the requested layer and true colour.
  (vl-load-com)
  (setq obj (vl-catch-all-apply 'vlax-ename->vla-object (list ename)))
  (if (vl-catch-all-error-p obj)
    nil
    (progn
      (setq args (list "_.-hatch" "_P" pattern))
      ;; SOLID has no scale or angle prompt, so those arguments must be omitted.
      (if (/= (strcase pattern) "SOLID")
        (setq args (append args (list (RMR:Num scale 3) (RMR:Num angle 1))))
      )
      (setq args (append args (list "_S" (vlax-vla-object->ename obj) "" "")))
      (setq result (vl-catch-all-apply 'command args))
      (if (vl-catch-all-error-p result)
        nil
        (progn
          (setq result (entlast))
          (if result
            (progn
              (setq data (entget result))
              (setq data (RMR:DXF 8 layer data))
              (setq data (RMR:DXF 420 (RMR:RGB->420 rgb) data))
              (vl-catch-all-apply 'entmod (list data))
            )
          )
          T
        )
      )
    )
  )
)

(defun RMR:ReverseList (lst / out item)
  (setq out '())
  (foreach item lst (setq out (cons item out)))
  out
)

(defun RMR:PolySignedArea (pts / total n i p q)
  ;; Shoelace area: positive means the vertices run counter-clockwise.
  (setq total 0.0)
  (setq n (length pts))
  (setq i 0)
  (while (< i n)
    (setq p (nth i pts))
    (setq q (nth (rem (1+ i) n) pts))
    (setq total (+ total (- (* (car p) (cadr q)) (* (car q) (cadr p)))))
    (setq i (1+ i))
  )
  (/ total 2.0)
)

(defun RMR:AxoPoint (p height)
  ;; 30 degree axonometric projection of a plan point at a given height.
  ;; Both plan axes rise at 30 degrees, so the plan origin sits at the bottom.
  (list
    (* (- (car p) (cadr p)) 0.8660254)
    (+ (* (+ (car p) (cadr p)) 0.5) height)
  )
)

(defun RMR:PolyVertices (data / out item)
  ;; Plan vertices from an LWPOLYLINE entity list.
  (setq out '())
  (foreach item data
    (if (= (car item) 10) (setq out (append out (list (cdr item)))))
  )
  out
)

;;; --- axonometric massing ---------------------------------------------------
(defun C:RMR-AXO (/ ename data pts area height base low high i n
                  a b dx dy toppt botpt fill shade s label)
  (RMR:EnsureReady)
  (setq ename (car (entsel "\nSelect a closed plan outline: ")))
  (if (and ename (setq data (entget ename))
           (= (cdr (assoc 0 data)) "LWPOLYLINE"))
    (progn
      (setq pts (RMR:PolyVertices data))
      (if (< (length pts) 3)
        (princ "\nThat outline has fewer than three vertices.")
        (progn
          (setq height (RMR:PromptReal "Extrusion height in mm" 3300.0))
          (setq base (getpoint "\nPick the axonometric origin: "))
          (if base
            (progn
              (setq s (RMR:Scaled 1.0))
              ;; counter-clockwise so the outward normal test below is valid
              (setq area (RMR:PolySignedArea pts))
              (if (< area 0.0)
                (setq pts (RMR:ReverseList pts))
              )
              (setq n (length pts))
              ;; projected rings
              (setq low '())
              (setq high '())
              (foreach p pts
                (setq botpt (RMR:AxoPoint p 0.0))
                (setq toppt (RMR:AxoPoint p height))
                (setq low (append low
                            (list (list (+ (car base) (car botpt))
                                        (+ (cadr base) (cadr botpt))))))
                (setq high (append high
                             (list (list (+ (car base) (car toppt))
                                         (+ (cadr base) (cadr toppt))))))
              )
              ;; top face first so the side faces sit under its edge
              (setq fill (RMR:ClosedPoly high "RMR-M-FILL" *RMR-BRAND-SAND*))
              (if fill (RMR:FillLayer fill "SOLID" 1.0 0.0
                                      (list 244 238 226) "RMR-M-FILL"))
              ;; only the faces whose outward normal points at the viewer
              (setq i 0)
              (while (< i n)
                (setq a (nth i pts))
                (setq b (nth (rem (1+ i) n) pts))
                (setq dx (- (car b) (car a)))
                (setq dy (- (cadr b) (cadr a)))
                (if (< dy dx)
                  (progn
                    (if (> (abs dy) (abs dx))
                      (setq shade (list 214 196 178))
                      (setq shade (list 232 214 194))
                    )
                    (RMR:Quad (nth i low) (nth (rem (1+ i) n) low)
                              (nth (rem (1+ i) n) high) (nth i high)
                              "RMR-M-FILL" shade)
                  )
                )
                (setq i (1+ i))
              )
              ;; vertical edges, then the two outlines
              (setq i 0)
              (while (< i n)
                (RMR:Line (nth i low) (nth i high) "RMR-M-WALL" *RMR-BRAND-TERRA*)
                (setq i (1+ i))
              )
              (RMR:PolyLine low nil T "RMR-00-REF" *RMR-BRAND-SLATE*)
              (RMR:PolyLine high nil T "RMR-M-WALL" *RMR-BRAND-TERRA*)
              ;; height note
              (setq toppt (nth 0 high))
              (setq botpt (nth 0 low))
              (RMR:Line (RMR:PT+ toppt (* 6.0 s) 0.0) (RMR:PT+ toppt (* 14.0 s) 0.0)
                        "RMR-A-LEADER" *RMR-BRAND-GOLD*)
              (setq label (strcat "AXONOMETRIC  |  HEIGHT "
                                  (RMR:Num height 0) " mm  |  30 DEGREES"))
              (RMR:Text (RMR:PT+ toppt (* 16.0 s) (- (* 1.2 s))) label (* 2.6 s)
                        "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-TERRA*)
              (princ (strcat "\nAxonometric drawn from " (itoa n)
                             " vertices at " (RMR:Num height 0) " mm."))
            )
          )
        )
      )
    )
    (princ "\nPick a closed lightweight polyline for the footprint.")
  )
  (princ)
)

;;; --- one point interior perspective ---------------------------------------
(defun C:RMR-ROOMVIEW (/ base w d h eye frame hp vpx vpy tdepth
                       fl fr tl tr bfl bfr btl btr i gx gy)
  (RMR:EnsureReady)
  (setq w (RMR:PromptReal "Room width in mm" 4200.0))
  (setq d (RMR:PromptReal "Room depth in mm" 5400.0))
  (setq h (RMR:PromptReal "Room height in mm" 2700.0))
  (setq eye (RMR:PromptReal "Eye height in mm" 1500.0))
  (setq frame (RMR:PromptReal "Drawn width of the opening" 200.0))
  (setq tdepth (getreal "\nDepth of the back wall as a fraction <0.62>: "))
  (if (or (not tdepth) (<= tdepth 0.0) (>= tdepth 1.0)) (setq tdepth 0.62))
  (setq base (getpoint "\nPick the lower-left of the opening: "))
  (if base
    (progn
      (setq hp (* frame (/ h w)))
      ;; front opening corners, relative to the base point
      (setq fl (list (car base) (cadr base)))
      (setq fr (list (+ (car base) frame) (cadr base)))
      (setq tl (list (car base) (+ (cadr base) hp)))
      (setq tr (list (+ (car base) frame) (+ (cadr base) hp)))
      ;; one vanishing point on the eye level, centred on the opening
      (setq vpx (+ (car base) (/ frame 2.0)))
      (setq vpy (+ (cadr base) (* hp (/ eye h))))
      ;; back wall corners are the front corners pulled towards the vanishing point
      (setq bfl (list (+ (car fl) (* tdepth (- vpx (car fl))))
                      (+ (cadr fl) (* tdepth (- vpy (cadr fl))))))
      (setq bfr (list (+ (car fr) (* tdepth (- vpx (car fr))))
                      (+ (cadr fr) (* tdepth (- vpy (cadr fr))))))
      (setq btl (list (+ (car tl) (* tdepth (- vpx (car tl))))
                      (+ (cadr tl) (* tdepth (- vpy (cadr tl))))))
      (setq btr (list (+ (car tr) (* tdepth (- vpx (car tr))))
                      (+ (cadr tr) (* tdepth (- vpy (cadr tr))))))
      ;; surfaces, drawn far to near
      (RMR:Quad bfl bfr btr btl "RMR-M-FILL" (list 226 232 228))
      (RMR:Quad fl tl btl bfl "RMR-M-FILL" (list 238 231 216))
      (RMR:Quad fr tr btr bfr "RMR-M-FILL" (list 246 240 226))
      (RMR:Quad tl tr btr btl "RMR-M-FILL" (list 250 248 242))
      (RMR:Quad fl fr bfr bfl "RMR-M-FILL" *RMR-BRAND-SAND*)
      ;; floor grid: nine divisions converging on the vanishing point
      (setq i 1)
      (while (< i 9)
        (setq gx (+ (car fl) (* frame (/ (float i) 9.0))))
        (RMR:Line (list gx (cadr fl)) (list (+ gx (* tdepth (- vpx gx)))
                                            (+ (cadr fl) (* tdepth (- vpy (cadr fl)))))
                  "RMR-00-REF" *RMR-BRAND-SLATE*)
        (setq i (1+ i))
      )
      (setq i 1)
      (while (< i 4)
        (setq gy (/ (float i) 4.0))
        (RMR:Line (list (+ (car fl) (* gy (- (car bfl) (car fl))))
                        (+ (cadr fl) (* gy (- (cadr bfl) (cadr fl)))))
                  (list (+ (car fr) (* gy (- (car bfr) (car fr))))
                        (+ (cadr fr) (* gy (- (cadr bfr) (cadr fr)))))
                  "RMR-00-REF" *RMR-BRAND-SLATE*)
        (setq i (1+ i))
      )
      ;; outlines: back wall, then the front opening on top
      (RMR:Line bfl bfr "RMR-M-WALL" *RMR-BRAND-TERRA*)
      (RMR:Line bfr btr "RMR-M-WALL" *RMR-BRAND-TERRA*)
      (RMR:Line btr btl "RMR-M-WALL" *RMR-BRAND-TERRA*)
      (RMR:Line btl bfl "RMR-M-WALL" *RMR-BRAND-TERRA*)
      (RMR:Rect fl frame hp "RMR-M-WALL" *RMR-BRAND-TERRA*)
      (RMR:Line fl bfl "RMR-M-WALL" *RMR-BRAND-TERRA*)
      (RMR:Line fr bfr "RMR-M-WALL" *RMR-BRAND-TERRA*)
      (RMR:Line tl btl "RMR-M-WALL" *RMR-BRAND-TERRA*)
      (RMR:Line tr btr "RMR-M-WALL" *RMR-BRAND-TERRA*)
      (RMR:Text (RMR:PT+ fl 0.0 (- (* 6.0 (RMR:Scaled 1.0))))
                (strcat (RMR:Num w 0) " x " (RMR:Num d 0) " x " (RMR:Num h 0)
                        " mm   |   eye " (RMR:Num eye 0) " mm")
                (* 2.6 (RMR:Scaled 1.0)) "RMR-HEAD" "RMR-A-TEXT"
                *RMR-BRAND-TERRA*)
      (princ (strcat "\nOne point interior perspective drawn: "
                     (RMR:Num w 0) " x " (RMR:Num d 0) " x " (RMR:Num h 0) " mm."))
    )
  )
  (princ)
)

;;; --- layered construction build-up ----------------------------------------
(defun RMR:BuildupTypes (/ out spec name)
  ;; Distinct build-up type keywords, in the order they first appear.
  (setq out '())
  (foreach spec *RMR-BUILDUP-SPECS*
    (setq name (nth 0 spec))
    (if (not (member name out)) (setq out (append out (list name))))
  )
  out
)

(defun RMR:BuildupRows (wanted / out spec)
  (setq out '())
  (foreach spec *RMR-BUILDUP-SPECS*
    (if (= (strcase (nth 0 spec)) (strcase wanted))
      (setq out (append out (list spec)))
    )
  )
  out
)

(defun C:RMR-BUILDUP (/ keys keyword rows drawn wide base x y k total
                      spec name thk rgb pattern note band label-y s ename)
  (RMR:EnsureReady)
  (setq keys "")
  (foreach keyword (RMR:BuildupTypes)
    (setq keys (strcat keys (if (= keys "") "" " ") keyword))
  )
  (setq keyword (RMR:PromptKeyword "Build-up type" keys (nth 0 (RMR:BuildupTypes))))
  (if keyword
    (progn
      (setq rows (RMR:BuildupRows keyword))
      (setq total 0.0)
      (foreach spec rows (setq total (+ total (float (nth 2 spec)))))
      (setq base (getpoint "\nPick the lower-left of the build-up: "))
      (if base
        (progn
          (setq s (RMR:Scaled 1.0))
          (setq wide (RMR:PromptReal "Drawn width" (* 120.0 s)))
          (setq drawn (RMR:PromptReal "Drawn height of the whole build-up"
                                      (* 80.0 s)))
          (setq k (/ drawn total))
          (setq x (car base))
          (setq y (cadr base))
          (setq label-y (+ y drawn (* 4.0 s)))
          (foreach spec rows
            (setq name (nth 1 spec))
            (setq thk (float (nth 2 spec)))
            (setq rgb (nth 3 spec))
            (setq pattern (nth 4 spec))
            (setq note (nth 5 spec))
            (setq band (* thk k))
            (setq ename (RMR:ClosedPoly
                          (list (list x y) (list (+ x wide) y)
                                (list (+ x wide) (+ y band)) (list x (+ y band)))
                          "RMR-M-HATCH" rgb))
            (if ename
              (RMR:FillLayer ename pattern (* 2.0 s) 0.0 rgb "RMR-M-HATCH")
            )
            (RMR:Rect (list x y 0.0) wide band "RMR-A-FRAME" *RMR-BRAND-SLATE*)
            ;; leader out to a label line that never crowds the thin layers
            (RMR:Line (list (+ x wide) (+ y (/ band 2.0)) 0.0)
                      (list (+ x wide (* 12.0 s)) label-y 0.0)
                      "RMR-A-LEADER" *RMR-BRAND-GOLD*)
            (RMR:Line (list (+ x wide (* 12.0 s)) label-y 0.0)
                      (list (+ x wide (* 16.0 s)) label-y 0.0)
                      "RMR-A-LEADER" *RMR-BRAND-GOLD*)
            (RMR:Text (list (+ x wide (* 18.0 s)) (- label-y (* 1.0 s)) 0.0)
                      (strcat name "   " (RMR:Num thk 0) " mm") (* 2.3 s)
                      "RMR-LABEL" "RMR-A-TEXT" *RMR-BRAND-INK*)
            (RMR:Text (list (+ x wide (* 18.0 s)) (- label-y (* 4.4 s)) 0.0)
                      note (* 1.9 s) "RMR-NOTE" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
            (setq y (+ y band))
            (setq label-y (- label-y (* 8.0 s)))
          )
          (RMR:Text (list x (- (cadr base) (* 6.0 s)) 0.0)
                    (strcat keyword " BUILD-UP   |   TOTAL " (RMR:Num total 0) " mm")
                    (* 3.2 s) "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-TERRA*)
          (princ (strcat "\n" keyword " build-up drawn: " (itoa (length rows))
                         " layers, " (RMR:Num total 0) " mm total."))
        )
      )
    )
  )
  (princ)
)

;;; --- material swatch board -------------------------------------------------
(defun RMR:DrawSwatchBoard (base scale cols / s cell gap spec index col row
                            ox oy ename)
  (setq s scale)
  (setq cell (* 42.0 s))
  (setq gap (* 14.0 s))
  (RMR:Text base "MATERIAL SWATCH BOARD  |  RMR-SWATCH" (* 4.2 s) "RMR-HEAD"
            "RMR-A-TEXT" *RMR-BRAND-TERRA*)
  (RMR:Text (list (car base) (- (cadr base) (* 5.0 s)) 0.0)
            (strcat (itoa (length *RMR-HATCH-SPECS*))
                    " materials from *RMR-HATCH-SPECS*")
            (* 2.2 s) "RMR-NOTE" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
  (setq index 0)
  (foreach spec *RMR-HATCH-SPECS*
    (setq col (rem index cols))
    (setq row (/ index cols))
    (setq ox (+ (car base) (* col (+ cell gap))))
    (setq oy (- (cadr base) (* 14.0 s) (* row (+ cell (* 20.0 s)))))
    ;; the cell hangs below its row baseline, so rows can never ride over
    ;; the heading and each other
    (setq ename (RMR:ClosedPoly
                  (list (list ox oy) (list (+ ox cell) oy)
                        (list (+ ox cell) (- oy cell)) (list ox (- oy cell)))
                  "RMR-M-HATCH" (nth 6 spec)))
    (if ename
      (RMR:FillLayer ename (nth 2 spec) (* (float (nth 3 spec)) 0.35 s)
                     (float (nth 4 spec)) (nth 6 spec) "RMR-M-HATCH")
    )
    (RMR:Rect (list ox (- oy cell) 0.0) cell cell "RMR-A-FRAME" *RMR-BRAND-SLATE*)
    (RMR:Text (list ox (- oy cell (* 5.0 s)) 0.0) (nth 0 spec) (* 2.6 s)
              "RMR-NUMBER" "RMR-A-TEXT" *RMR-BRAND-TERRA*)
    (RMR:Text (list ox (- oy cell (* 9.0 s)) 0.0) (RMR:Shorten (nth 1 spec) 22)
              (* 2.0 s) "RMR-BODY" "RMR-A-TEXT" *RMR-BRAND-INK*)
    (RMR:Text (list ox (- oy cell (* 12.4 s)) 0.0) (nth 2 spec) (* 1.8 s)
              "RMR-MARK" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
    (setq index (1+ index))
  )
  (- (cadr base) (* 12.0 s)
     (* (/ (+ (length *RMR-HATCH-SPECS*) (1- cols)) cols) (+ cell (* 20.0 s))))
)

(defun C:RMR-SWATCH (/ base s cols)
  (RMR:EnsureReady)
  (setq base (getpoint "\nTop-left of the swatch board: "))
  (if base
    (progn
      (setq s (RMR:Scaled 1.0))
      (setq cols (RMR:PromptInt "Columns" 6))
      (RMR:DrawSwatchBoard base s cols)
      (princ (strcat "\nSwatch board drawn: " (itoa (length *RMR-HATCH-SPECS*))
                     " materials in " (itoa cols) " columns."))
    )
  )
  (princ)
)

;;; --- colour reference board -------------------------------------------------
(defun RMR:DrawBrandRow (base scale / s keys key rgb x)
  (setq s scale)
  (setq keys '("INK" "TERRA" "TEAL" "GOLD" "SAND" "BLUE" "SLATE"))
  (setq x (car base))
  (foreach key keys
    (setq rgb (RMR:BrandRGB key))
    (RMR:Solid (list x (cadr base) 0.0) (* 20.0 s) (* 8.0 s) "RMR-M-FILL" rgb)
    (RMR:Rect (list x (cadr base) 0.0) (* 20.0 s) (* 8.0 s) "RMR-A-FRAME"
              *RMR-BRAND-SLATE*)
    (RMR:Text (list x (- (cadr base) (* 4.0 s)) 0.0) key (* 2.0 s) "RMR-LABEL"
              "RMR-A-TEXT" *RMR-BRAND-INK*)
    (RMR:Text (list x (- (cadr base) (* 7.4 s)) 0.0)
              (strcat (itoa (fix (nth 0 rgb))) " "
                      (itoa (fix (nth 1 rgb))) " "
                      (itoa (fix (nth 2 rgb))))
              (* 1.8 s) "RMR-MARK" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
    (setq x (+ x (* 24.0 s)))
  )
  (- (cadr base) (* 12.0 s))
)

(defun C:RMR-COLOURBOARD (/ base s y groups group spec rgb)
  (RMR:EnsureReady)
  (setq base (getpoint "\nTop-left of the colour board: "))
  (if base
    (progn
      (setq s (RMR:Scaled 1.0))
      (setq y (cadr base))
      (RMR:Text base "COLOUR REFERENCE BOARD  |  RMR-COLOURBOARD"
                (* 4.2 s) "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-TERRA*)
      (setq y (- y (* 6.0 s)))
      (RMR:Text (list (car base) y 0.0) "BRAND PALETTE" (* 2.4 s) "RMR-HEAD"
                "RMR-A-TEXT" *RMR-BRAND-GOLD*)
      (setq y (- y (* 6.0 s)))
      (RMR:DrawBrandRow (list (car base) y 0.0) s)
      (setq y (- y (* 16.0 s)))
      (setq groups (RMR:SplitString (RMR:GroupKeywords) " "))
      (setq y (- y (* 4.0 s)))
      (foreach group groups
        (RMR:Solid (list (car base) (- y (* 6.0 s)) 0.0) (* 200.0 s) (* 6.0 s)
                   "RMR-PRES-TITLE" *RMR-BRAND-TERRA*)
        (RMR:Text (list (+ (car base) (* 2.0 s)) (- y (* 4.2 s)) 0.0)
                  (RMR:ThemeName group) (* 2.2 s) "RMR-HEAD"
                  "RMR-PRES-TITLE" *RMR-BRAND-SAND*)
        (setq y (- y (* 10.0 s)))
        (foreach spec *RMR-LAYER-SPECS*
          (if (= (strcase (nth 1 spec)) (RMR:ThemeName group))
            (progn
              (setq rgb (nth 2 spec))
              (RMR:Solid (list (car base) y 0.0) (* 12.0 s) (* 4.0 s)
                         "RMR-M-FILL" rgb)
              (RMR:Rect (list (car base) y 0.0) (* 12.0 s) (* 4.0 s)
                        "RMR-A-FRAME" *RMR-BRAND-SLATE*)
              (RMR:Text (list (+ (car base) (* 15.0 s)) y 0.0) (nth 0 spec)
                        (* 2.1 s) "RMR-LABEL" "RMR-A-TEXT" *RMR-BRAND-INK*)
              (RMR:Text (list (+ (car base) (* 96.0 s)) y 0.0)
                        (strcat (itoa (fix (nth 0 rgb))) " "
                                (itoa (fix (nth 1 rgb))) " "
                                (itoa (fix (nth 2 rgb))))
                        (* 1.9 s) "RMR-MARK" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
              (setq y (- y (* 5.4 s)))
            )
          )
        )
        (setq y (- y (* 4.0 s)))
      )
      (princ (strcat "\nColour board drawn: 7 brand colours and "
                     (itoa (length *RMR-LAYER-SPECS*))
                     " layers across " (itoa (length groups)) " groups."))
    )
  )
  (princ)
)

;;; --- mood board -------------------------------------------------------------
(defun RMR:DrawMoodBoard (base scale cols / s fw fh gap slot caption index
                          col row ox oy)
  (setq s scale)
  (setq fw (* 104.0 s))
  (setq fh (* 74.0 s))
  (setq gap (* 12.0 s))
  (RMR:Text base "IMAGE / MOOD BOARD  |  RMR-MOODBOARD" (* 4.2 s) "RMR-HEAD"
            "RMR-A-TEXT" *RMR-BRAND-TERRA*)
  (RMR:Text (list (car base) (- (cadr base) (* 5.0 s)) 0.0)
            "Use IMAGEATTACH to drop a picture into each frame" (* 2.2 s)
            "RMR-NOTE" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
  (setq index 0)
  (foreach slot *RMR-MOOD-SPECS*
    (setq col (rem index cols))
    (setq row (/ index cols))
    (setq ox (+ (car base) (* col (+ fw gap))))
    (setq oy (- (cadr base) (* 12.0 s) (* row (+ fh (* 18.0 s)))))
    ;; the frame hangs below its row baseline, the tab sits inside the
    ;; top-left corner and the caption goes under the frame
    (RMR:Rect (list ox (- oy fh) 0.0) fw fh "RMR-PRES-VPORT" *RMR-BRAND-TEAL*)
    (RMR:Line (list ox (- oy fh) 0.0) (list (+ ox fw) oy 0.0) "RMR-00-REF"
              *RMR-BRAND-SLATE*)
    (RMR:Line (list ox oy 0.0) (list (+ ox fw) (- oy fh) 0.0) "RMR-00-REF"
              *RMR-BRAND-SLATE*)
    (RMR:Solid (list ox (- oy (* 6.0 s)) 0.0) (* 16.0 s) (* 6.0 s)
               "RMR-PRES-TITLE" *RMR-BRAND-TERRA*)
    (RMR:Text (list (+ ox (* 2.0 s)) (- oy (* 4.4 s)) 0.0) (nth 0 slot)
              (* 2.4 s) "RMR-NUMBER" "RMR-PRES-TITLE" *RMR-BRAND-SAND*)
    (RMR:Text (list ox (- oy fh (* 5.0 s)) 0.0) (nth 1 slot) (* 2.2 s)
              "RMR-LABEL" "RMR-A-TEXT" *RMR-BRAND-INK*)
    (setq index (1+ index))
  )
  (- (cadr base) (* 12.0 s)
     (* (/ (+ (length *RMR-MOOD-SPECS*) (1- cols)) cols) (+ fh (* 18.0 s))))
)

(defun C:RMR-MOODBOARD (/ base s cols)
  (RMR:EnsureReady)
  (setq base (getpoint "\nTop-left of the mood board: "))
  (if base
    (progn
      (setq s (RMR:Scaled 1.0))
      (setq cols (RMR:PromptInt "Columns" 3))
      (RMR:DrawMoodBoard base s cols)
      (princ (strcat "\nMood board drawn: " (itoa (length *RMR-MOOD-SPECS*))
                     " framed slots in " (itoa cols) " columns."))
    )
  )
  (princ)
)

;;; --- area distribution chart -------------------------------------------------
(defun C:RMR-AREACHART (/ pick ename area sqm name rows number total base
                        barw rowh widest s i row bar pct shade)
  (RMR:EnsureReady)
  (vl-load-com)
  (setq rows '())
  (setq number 1)
  (setq total 0.0)
  (princ "\nSelect the closed boundary of each room. Press Enter when finished.")
  (setq pick (entsel "\nSelect room boundary <finish>: "))
  (while pick
    (setq ename (car pick))
    (setq area (RMR:EntityArea ename))
    (if (and area (> area 0.0))
      (progn
        (setq sqm (RMR:AreaToSqm area))
        (setq name (RMR:PromptText (strcat "Room " (itoa number) " name")
                                   (strcat "ROOM " (RMR:NumPad2 number))))
        (setq rows (append rows (list (list name sqm))))
        (setq total (+ total sqm))
        (setq number (1+ number))
      )
      (princ "\nThat object has no measurable area - skipped.")
    )
    (setq pick (entsel "\nSelect next room boundary <finish>: "))
  )
  (if rows
    (progn
      (setq base (getpoint "\nTop-left of the area chart: "))
      (if base
        (progn
          (setq s (RMR:Scaled 1.0))
          (setq barw (RMR:PromptReal "Width of the longest bar" (* 150.0 s)))
          (setq rowh (* 9.0 s))
          (setq widest 0.0)
          (foreach row rows
            (if (> (nth 1 row) widest) (setq widest (nth 1 row)))
          )
          (RMR:Text base "AREA DISTRIBUTION  |  RMR-AREACHART" (* 4.2 s)
                    "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-TERRA*)
          (RMR:Text (list (car base) (- (cadr base) (* 5.0 s)) 0.0)
                    (strcat (itoa (length rows)) " rooms  |  total "
                            (RMR:Num total 2) " m2  |  "
                            (RMR:Num (* total *RMR-SQFT-PER-SQM*) 1) " sq ft")
                    (* 2.2 s) "RMR-NOTE" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
          (setq i 0)
          (foreach row rows
            (setq bar (* barw (/ (nth 1 row) (if (> widest 0.0) widest 1.0))))
            (setq pct (* 100.0 (/ (nth 1 row) (if (> total 0.0) total 1.0))))
            (setq shade (nth (rem i 6)
                             (list *RMR-BRAND-TERRA* *RMR-BRAND-GOLD*
                                   *RMR-BRAND-TEAL* *RMR-BRAND-BLUE*
                                   *RMR-BRAND-SLATE* *RMR-BRAND-SAND*)))
            (RMR:Text (list (car base)
                            (- (cadr base) (* 12.0 s) (* i rowh)) 0.0)
                      (nth 0 row) (* 2.3 s) "RMR-LABEL" "RMR-A-TEXT"
                      *RMR-BRAND-INK*)
            (RMR:Solid (list (+ (car base) (* 56.0 s))
                             (- (cadr base) (* 12.0 s) (* i rowh) (* 1.0 s)) 0.0)
                       bar (* 5.0 s) "RMR-M-FILL" shade)
            (RMR:Rect (list (+ (car base) (* 56.0 s))
                            (- (cadr base) (* 12.0 s) (* i rowh) (* 1.0 s)) 0.0)
                      bar (* 5.0 s) "RMR-A-FRAME" *RMR-BRAND-SLATE*)
            (RMR:Text (list (+ (car base) (* 60.0 s) bar)
                            (- (cadr base) (* 12.0 s) (* i rowh)) 0.0)
                      (strcat (RMR:Num (nth 1 row) 2) " m2   "
                              (RMR:Num pct 1) "%")
                      (* 2.1 s) "RMR-BODY" "RMR-A-TEXT" *RMR-BRAND-INK*)
            (setq i (1+ i))
          )
          (princ (strcat "\nArea chart drawn: " (itoa (length rows))
                         " rooms, " (RMR:Num total 2) " m2."))
        )
      )
    )
    (princ "\nNo rooms selected - nothing drawn.")
  )
  (princ)
)

;;; --- programme bar chart ------------------------------------------------------
(defun RMR:DrawProgramme (base scale colw / s rowh weeks spec index bar start
                          finish rgb x y)
  (setq s scale)
  (setq rowh (* 9.0 s))
  (setq weeks 0)
  (foreach spec *RMR-PROGRAMME-SPECS*
    (setq finish (+ (nth 1 spec) (nth 2 spec)))
    (if (> finish weeks) (setq weeks finish))
  )
  (RMR:Text base "PROGRAMME  |  RMR-PROGRAMME" (* 4.2 s) "RMR-HEAD"
            "RMR-A-TEXT" *RMR-BRAND-TERRA*)
  (RMR:Text (list (car base) (- (cadr base) (* 5.0 s)) 0.0)
            (strcat (itoa weeks) " weeks  |  *RMR-PROGRAMME-SPECS*")
            (* 2.2 s) "RMR-NOTE" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
  ;; week grid, with a tick and a number every four weeks
  (setq index 0)
  (while (<= index weeks)
    (setq x (+ (car base) (* 56.0 s) (* index colw)))
    (if (= (rem index 4) 0)
      (progn
        (RMR:Line (list x (- (cadr base) (* 8.0 s)) 0.0)
                  (list x (- (cadr base) (* 8.0 s)
                             (* rowh (length *RMR-PROGRAMME-SPECS*))) 0.0)
                  "RMR-00-REF" *RMR-BRAND-SLATE*)
        (RMR:Text (list x (- (cadr base) (* 12.0 s)) 0.0) (itoa index)
                  (* 1.9 s) "RMR-NUMBER" "RMR-A-TEXT" *RMR-BRAND-TERRA*)
      )
    )
    (setq index (1+ index))
  )
  (setq index 0)
  (foreach spec *RMR-PROGRAMME-SPECS*
    (setq start (nth 1 spec))
    (setq finish (nth 2 spec))
    (setq rgb (RMR:BrandRGB (nth 3 spec)))
    (setq y (- (cadr base) (* 16.0 s) (* index rowh)))
    (RMR:Text (list (car base) y 0.0) (nth 0 spec) (* 2.3 s) "RMR-LABEL"
              "RMR-A-TEXT" *RMR-BRAND-INK*)
    (setq x (+ (car base) (* 56.0 s) (* start colw)))
    (setq bar (* finish colw))
    (RMR:Solid (list x (- y (* 1.0 s)) 0.0) bar (* 5.0 s) "RMR-M-FILL" rgb)
    (RMR:Rect (list x (- y (* 1.0 s)) 0.0) bar (* 5.0 s) "RMR-A-FRAME"
              *RMR-BRAND-SLATE*)
    (RMR:Text (list (+ x bar (* 3.0 s)) y 0.0)
              (strcat (itoa finish) " wks") (* 2.0 s) "RMR-BODY"
              "RMR-A-TEXT" *RMR-BRAND-INK*)
    (setq index (1+ index))
  )
  (- (cadr base) (* 16.0 s) (* rowh (length *RMR-PROGRAMME-SPECS*)))
)

(defun C:RMR-PROGRAMME (/ base s colw)
  (RMR:EnsureReady)
  (setq base (getpoint "\nTop-left of the programme: "))
  (if base
    (progn
      (setq s (RMR:Scaled 1.0))
      (setq colw (RMR:PromptReal "Width of one week" (* 5.0 s)))
      (RMR:DrawProgramme base s colw)
      (princ (strcat "\nProgramme drawn: " (itoa (length *RMR-PROGRAMME-SPECS*))
                     " stages."))
    )
  )
  (princ)
)

;;; --- brand masthead -----------------------------------------------------------
(defun RMR:DrawBranding (base scale / s y)
  (setq s scale)
  (setq y (cadr base))
  (RMR:Text (list (car base) y 0.0) "RooMNRooF" (* 20.0 s) "RMR-TITLE"
            "RMR-PRES-TITLE" *RMR-BRAND-TERRA*)
  (setq y (- y (* 6.0 s)))
  (RMR:Line (list (car base) y 0.0) (list (+ (car base) (* 210.0 s)) y 0.0)
            "RMR-PRES-TITLE" *RMR-BRAND-GOLD*)
  (setq y (- y (* 6.0 s)))
  (RMR:Text (list (car base) y 0.0) "CONSULTANT   |   2D CAD STANDARD"
            (* 3.4 s) "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-INK*)
  (setq y (- y (* 6.0 s)))
  (RMR:Text (list (car base) y 0.0) "ROOF THE ROOM" (* 2.6 s) "RMR-MARK"
            "RMR-A-TEXT" *RMR-BRAND-GOLD*)
  (setq y (- y (* 10.0 s)))
  (RMR:Text (list (car base) y 0.0) (strcase (RMR:ProjectValue "PROJECT" ""))
            (* 5.0 s) "RMR-TITLE" "RMR-A-TEXT" *RMR-BRAND-INK*)
  (setq y (- y (* 6.0 s)))
  (RMR:Text (list (car base) y 0.0)
            (strcat (strcase (RMR:ProjectValue "CLIENT" ""))
                    "   |   JOB " (RMR:ProjectValue "JOB" "")
                    "   |   " (RMR:ProjectValue "STAGE" "")
                    "   |   " (RMR:TodayDate))
            (* 2.6 s) "RMR-NOTE" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
  (- y (* 6.0 s))
)

(defun C:RMR-BRANDING (/ base scale)
  (RMR:EnsureReady)
  (setq base (getpoint "\nTop-left of the brand block: "))
  (if base
    (progn
      (setq scale (getreal "\nBlock scale factor <1.0>: "))
      (if (or (not scale) (<= scale 0.0)) (setq scale 1.0))
      (RMR:DrawBranding base scale)
      (princ "\nRooMNRooF brand block placed.")
    )
  )
  (princ)
)

;;; --- complete presentation sheet -----------------------------------------------
(defun C:RMR-PRESENTSHEET (/ size dims base outer inset iw ih top p1 p2 p3 p4
                           frame plans index caption)
  (RMR:EnsureReady)
  (initget "A0 A1 A2 A3 A4")
  (setq size (getkword "\nPresentation sheet size [A0/A1/A2/A3/A4] <A1>: "))
  (if (not size) (setq size "A1"))
  (setq dims (RMR:SheetSize size))
  (setq base (getpoint "\nPick lower-left presentation sheet point: "))
  (if base
    (progn
      (setq outer (list (car base) (cadr base) 0.0))
      (setq inset 10.0)
      (setq iw (- (car dims) (* 2.0 inset)))
      (setq ih (- (cadr dims) (* 2.0 inset)))
      (RMR:Rect outer (car dims) (cadr dims) "RMR-A-FRAME" *RMR-BRAND-INK*)
      (RMR:Rect (RMR:PT+ outer inset inset) iw ih "RMR-A-FRAME" *RMR-BRAND-TEAL*)
      (setq top (+ (cadr outer) (cadr dims) (- inset)))
      ;; masthead
      (RMR:DrawBranding (list (+ (car outer) 24.0) (- top 26.0) 0.0) 1.0)
      ;; left column: materials and programme
      (setq p1 (list (+ (car outer) 24.0) (- top 120.0) 0.0))
      (RMR:DrawSwatchBoard p1 1.0 6)
      (setq p2 (list (+ (car outer) 24.0) (- top 330.0) 0.0))
      (RMR:DrawProgramme p2 1.0 5.0)
      ;; right column: mood board and empty view frames
      (setq p3 (list (+ (car outer) 440.0) (- top 120.0) 0.0))
      (RMR:DrawMoodBoard p3 1.0 3)
      (setq p4 (list (+ (car outer) 440.0) (- top 330.0) 0.0))
      (RMR:Text p4 "VIEWS FOR ISSUE" 4.2 "RMR-HEAD" "RMR-A-TEXT"
                *RMR-BRAND-TERRA*)
      (setq plans (list "GENERAL ARRANGEMENT PLAN" "SECTION AA"
                        "ELEVATION - NORTH"))
      (setq index 0)
      (foreach caption plans
        (setq frame (list (+ (car p4) (* index 116.0)) (- (cadr p4) 12.0) 0.0))
        (RMR:Rect frame 104.0 74.0 "RMR-A-FRAME" *RMR-BRAND-SLATE*)
        (RMR:Text (list (car frame) (- (cadr frame) 8.0) 0.0) caption 2.2
                  "RMR-LABEL" "RMR-A-TEXT" *RMR-BRAND-INK*)
        (setq index (1+ index))
      )
      ;; brand palette strip and title block
      (RMR:DrawBrandRow (list (+ (car outer) 24.0) (- top 470.0) 0.0) 1.0)
      (RMR:DrawTitleBlock (RMR:PT+ outer (- (car dims) 200.0) 10.0)
                          190.0 50.0 1.0)
      (princ (strcat "\n" size " presentation sheet created: masthead, "))
      (princ (strcat (itoa (length *RMR-HATCH-SPECS*)) " material swatches, "))
      (princ (strcat (itoa (length *RMR-PROGRAMME-SPECS*)) " programme stages, "))
      (princ (strcat (itoa (length *RMR-MOOD-SPECS*))
                     " image slots and 3 view frames."))
    )
  )
  (princ)
)


;;; =====================================================================
;;; =====================================================================
;;; --- rate library ---------------------------------------------------------
;;; (Code Description Unit Rate)
(setq *RMR-RATE-SPECS*
 '(
    ("M100" "Blockwork partition 100mm"   "M2"   62.50)
    ("M200" "Blockwork partition 200mm"   "M2"   98.00)
    ("F100" "Porcelain floor tile 600x600" "M2" 128.00)
    ("F200" "Engineered oak flooring"     "M2"  186.00)
    ("C100" "Gypsum ceiling on grid"      "M2"   74.00)
    ("D100" "Internal doorset, painted"   "NR"  540.00)
    ("D200" "External entrance doorset"   "NR" 1850.00)
    ("W100" "Double glazed window"        "NR" 1180.00)
    ("P100" "Soil and waste pipework"     "M"    84.00)
    ("P200" "Rainwater downpipe"          "M"    56.00)
    ("S100" "Skirting, painted timber"    "M"    28.00)
    ("X100" "Decoration, two coats"       "M2"   22.00)
  )
)

;;; Elemental cost plan: (Element Allowance ColourKey)
(setq *RMR-ELEMENT-SPECS*
 '(
    ("SUBSTRUCTURE"   18500.0 "SLATE")
    ("SUPERSTRUCTURE" 74200.0 "TERRA")
    ("EXTERNAL WALLS" 46800.0 "GOLD")
    ("ROOF"           31500.0 "TEAL")
    ("INTERNAL WALLS" 29400.0 "BLUE")
    ("FINISHES"       62800.0 "SAND")
    ("SERVICES"       54600.0 "TEAL")
    ("EXTERNAL WORKS" 21200.0 "GOLD")
  )
)

;;; Automation sequence: (Label Action Argument)
(setq *RMR-AUTO-SEQUENCE*
 '(
    ("BUILD STANDARD" "STANDARD"  "")
    ("SET SCALE"      "SCALE"     "50")
    ("FORCE BYLAYER"  "BYLAYER"   "")
    ("DRAWING PROPS"  "PROPS"     "")
    ("STRAY LAYERS"   "STRAY"     "")
    ("WRITE ALIASES"  "ALIAS"     "PGP")
    ("PURGE AND AUDIT" "PURGE"    "")
    ("WRITE LOG"      "LOG"       "")
  )
)

;;; --- shared quantity and automation helpers --------------------------------
(defun RMR:ForceByLayer (ss / i count ent data result)
  ;; Forces colour, linetype and lineweight to BYLAYER on a selection set.
  (setq count 0)
  (setq i 0)
  (repeat (sslength ss)
    (setq ent (ssname ss i))
    (setq data (entget ent))
    (if (assoc 62 data) (setq data (RMR:DXF 62 256 data)))
    (if (assoc 6 data) (setq data (RMR:DXF 6 "BYLAYER" data)))
    (if (assoc 370 data) (setq data (RMR:DXF 370 -1 data)))
    (setq result (vl-catch-all-apply 'entmod (list data)))
    (if (not (vl-catch-all-error-p result)) (setq count (1+ count)))
    (setq i (1+ i))
  )
  count
)

(defun RMR:SetNth (lst index value / out i item)
  ;; Copy of lst with the entry at index replaced by value.
  (setq out '())
  (setq i 0)
  (foreach item lst
    (if (= i index)
      (setq out (append out (list value)))
      (setq out (append out (list item)))
    )
    (setq i (1+ i))
  )
  out
)

(defun RMR:UnitLabel (unit code)
  ;; Keeps the unit column inside a narrow table cell.
  (cond
    ((= (strcase unit) "M2") "m2")
    ((= (strcase unit) "M3") "m3")
    ((= (strcase unit) "M") "m")
    (T (strcase unit))
  )
)

(defun RMR:ElementTotal (/ total spec)
  (setq total 0.0)
  (foreach spec *RMR-ELEMENT-SPECS*
    (setq total (+ total (float (nth 1 spec))))
  )
  total
)

(defun RMR:CsvCells (line / cells out cell)
  ;; Splits one CSV row and trims the surrounding spaces.
  (setq out '())
  (foreach cell (RMR:SplitString line ",")
    (setq out (append out (list (RMR:TrimString cell))))
  )
  out
)

;;; --- measured survey import -------------------------------------------------
(defun C:RMR-SURVEY (/ path lines line cells east north level pts
                    base k minx maxx miny maxy minz maxz s count first)
  (RMR:EnsureReady)
  (setq path (getfiled "Select the survey CSV (number,east,north,level)"
                       "survey.csv" "csv" 4))
  (if (and path (setq lines (RMR:ReadLines path)))
    (progn
      (setq pts '())
      (setq count 0)
      (foreach line lines
        (setq cells (RMR:CsvCells line))
        (if (>= (length cells) 4)
          (progn
            ;; the first field is the point number, the last three are the coordinates
            (setq east (atof (nth (- (length cells) 3) cells)))
            (setq north (atof (nth (- (length cells) 2) cells)))
            (setq level (atof (nth (- (length cells) 1) cells)))
            (if (or (/= east 0.0) (/= north 0.0) (/= level 0.0))
              (progn
                (setq pts (append pts
                            (list (list (nth 0 cells) east north level))))
                (setq count (1+ count))
              )
            )
          )
        )
      )
      (if pts
        (progn
          (setq base (getpoint "\nPick the survey origin: "))
          (if base
            (progn
              (setq k (RMR:PromptReal "Drawing units per metre" 1.0))
              (setq minx (nth 1 (nth 0 pts)))
              (setq maxx minx)
              (setq miny (nth 2 (nth 0 pts)))
              (setq maxy miny)
              (setq minz (nth 3 (nth 0 pts)))
              (setq maxz minz)
              (foreach pt pts
                (if (< (nth 1 pt) minx) (setq minx (nth 1 pt)))
                (if (> (nth 1 pt) maxx) (setq maxx (nth 1 pt)))
                (if (< (nth 2 pt) miny) (setq miny (nth 2 pt)))
                (if (> (nth 2 pt) maxy) (setq maxy (nth 2 pt)))
                (if (< (nth 3 pt) minz) (setq minz (nth 3 pt)))
                (if (> (nth 3 pt) maxz) (setq maxz (nth 3 pt)))
              )
              (setq s (RMR:Scaled 1.0))
              (setq first '())
              (foreach pt pts
                (setq east (- (nth 1 pt) minx))
                (setq north (- (nth 2 pt) miny))
                (setq level (nth 3 pt))
                (setq first (append first
                              (list (list (+ (car base) (* east k))
                                          (+ (cadr base) (* north k))))))
                (RMR:Circle (list (+ (car base) (* east k))
                                  (+ (cadr base) (* north k)) 0.0)
                            (* 1.2 s) "RMR-00-REF" *RMR-BRAND-TERRA*)
                (RMR:Text (RMR:PT+ (list (+ (car base) (* east k))
                                         (+ (cadr base) (* north k)) 0.0)
                                   (* 1.6 s) (* 1.6 s))
                          (nth 0 pt) (* 2.0 s) "RMR-NUMBER" "RMR-A-TEXT"
                          *RMR-BRAND-INK*)
                (RMR:Text (RMR:PT+ (list (+ (car base) (* east k))
                                         (+ (cadr base) (* north k)) 0.0)
                                   (* 1.6 s) (- (* 3.4 s)))
                          (RMR:Num level 2) (* 1.8 s) "RMR-MARK"
                          "RMR-A-TEXT" *RMR-BRAND-SLATE*)
              )
              (if (> (length first) 1)
                (RMR:PolyLine first nil nil "RMR-00-REF" *RMR-BRAND-TEAL*)
              )
              (princ (strcat "\nSurvey imported: " (itoa count) " points."))
              (princ (strcat "\nExtent " (RMR:Num (- maxx minx) 2) " x "
                             (RMR:Num (- maxy miny) 2) " m"
                             "  |  levels " (RMR:Num minz 2) " to "
                             (RMR:Num maxz 2) " m"))
            )
          )
        )
        (princ "\nNo coordinate rows found in that file.")
      )
    )
  )
  (princ)
)

;;; --- interactive measurement -------------------------------------------------
(defun C:RMR-MEASURE (/ pick ename area length value unit rows runm runm2
                     base s row rowh y)
  (RMR:EnsureReady)
  (vl-load-com)
  (setq rows '())
  (setq runm 0.0)
  (setq runm2 0.0)
  (princ "\nPick objects to measure. Press Enter when finished.")
  (setq pick (entsel "\nSelect object <finish>: "))
  (while pick
    (setq ename (car pick))
    (setq area (RMR:EntityArea ename))
    (setq length (RMR:EntityLength ename))
    (if (and area (> area 0.0))
      (progn
        (setq value (RMR:AreaToSqm area))
        (setq unit "m2")
        (setq runm2 (+ runm2 value))
        (setq rows (append rows
                     (list (list (itoa (1+ (length rows))) "AREA" unit
                                 (RMR:Num value 2) (RMR:Num runm2 2)))))
        (princ (strcat "\n  area " (RMR:Num value 2) " m2  |  running total "
                       (RMR:Num runm2 2) " m2"))
      )
      (if (and length (> length 0.0))
        (progn
          (setq value (RMR:LinearToMetres length))
          (setq unit "m")
          (setq runm (+ runm value))
          (setq rows (append rows
                       (list (list (itoa (1+ (length rows))) "LINEAR" unit
                                   (RMR:Num value 2) (RMR:Num runm 2)))))
          (princ (strcat "\n  length " (RMR:Num value 2) " m  |  running total "
                         (RMR:Num runm 2) " m"))
        )
        (princ "\n  no length or area on that object - skipped.")
      )
    )
    (setq pick (entsel "\nSelect next object <finish>: "))
  )
  (if rows
    (progn
      (setq base (getpoint "\nTop-left of the measurement list <enter to skip>: "))
      (if base
        (progn
          (setq s (RMR:Scaled 1.0))
          (setq rowh (* 6.0 s))
          (setq y (cadr base))
          (RMR:Text base "MEASURED QUANTITIES  |  RMR-MEASURE" (* 4.2 s)
                    "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-TERRA*)
          (setq y (- y (* 8.0 s)))
          (foreach row rows
            (RMR:Text (list (car base) y 0.0)
                      (strcat (nth 0 row) "  " (nth 1 row) "  "
                              (nth 3 row) " " (nth 2 row)
                              "   total " (nth 4 row))
                      (* 2.2 s) "RMR-BODY" "RMR-A-TEXT" *RMR-BRAND-INK*)
            (setq y (- y rowh))
          )
          (RMR:Text (list (car base) (- y (* 2.0 s)) 0.0)
                    (strcat "TOTAL AREA " (RMR:Num runm2 2) " m2") (* 2.8 s)
                    "RMR-NUMBER" "RMR-A-TEXT" *RMR-BRAND-TERRA*)
          (RMR:Text (list (car base) (- y (* 8.0 s)) 0.0)
                    (strcat "TOTAL LENGTH " (RMR:Num runm 2) " m") (* 2.8 s)
                    "RMR-NUMBER" "RMR-A-TEXT" *RMR-BRAND-TERRA*)
        )
      )
    )
    (princ "\nNothing measured.")
  )
  (princ)
)

;;; --- quantity takeoff with rates ----------------------------------------------
(defun C:RMR-QUANTITY (/ keys rows basis code spec qty rate cost total
                       unit pick ss base s ename value)
  (RMR:EnsureReady)
  (vl-load-com)
  (setq keys (RMR:KeywordList *RMR-RATE-SPECS*))
  (setq rows '())
  (setq total 0.0)
  (princ "\nQuantity takeoff. Choose a basis, select objects, then a rate code.")
  (setq basis (RMR:PromptKeyword "Basis" "Length Area Count Finish"
                                 "Finish"))
  (while (not (= (strcase basis) "FINISH"))
    (setq code (RMR:PromptKeyword "Rate code" keys (nth 0 (nth 0 *RMR-RATE-SPECS*))))
    (setq spec (RMR:TableSpec code *RMR-RATE-SPECS*))
    (setq qty 0.0)
    (setq unit (nth 2 spec))
    (if (= (strcase basis) "COUNT")
      (progn
        (princ "\nSelect the blocks to count: ")
        (setq pick (ssget))
        (if pick (setq qty (float (sslength pick))))
      )
      (progn
        (princ "\nSelect the objects to measure: ")
        (setq pick (ssget))
        (if pick
          (progn
            (setq ss 0)
            (repeat (sslength pick)
              (setq ename nil)
              (setq ename (ssname pick ss))
              (if (= (strcase basis) "LENGTH")
                (progn
                  (setq value (RMR:EntityLength ename))
                  (if value (setq qty (+ qty (RMR:LinearToMetres value))))
                )
                (progn
                  (setq value (RMR:EntityArea ename))
                  (if value (setq qty (+ qty (RMR:AreaToSqm value))))
                )
              )
              (setq ss (1+ ss))
            )
          )
        )
      )
    )
    (if spec
      (progn
        (setq rate (float (nth 3 spec)))
        (setq cost (* qty rate))
        (setq total (+ total cost))
        (setq rows (append rows
                     (list (list code (nth 1 spec) (RMR:UnitLabel unit code)
                                 (RMR:Num qty 2) (RMR:Num rate 2)
                                 (RMR:Num cost 2)))))
        (princ (strcat "\n  " code "  " (RMR:Num qty 2) " "
                       (RMR:UnitLabel unit code) " x " (RMR:Num rate 2)
                       " = " (RMR:Num cost 2)))
      )
    )
    (setq basis (RMR:PromptKeyword "Basis" "Length Area Count Finish"
                                   "Finish"))
  )
  (if rows
    (progn
      (setq base (getpoint "\nTop-left of the quantity table: "))
      (if base
        (progn
          (setq s (RMR:Scaled 1.0))
          (RMR:DocTable base "QUANTITY TAKEOFF  |  RMR-QUANTITY"
                        (strcat (itoa (length rows)) " items  |  total "
                                (RMR:Num total 2))
                        '("CODE" "DESCRIPTION" "UNIT" "QTY" "RATE" "COST")
                        (list (* 18.0 s) (* 62.0 s) (* 14.0 s) (* 18.0 s)
                              (* 20.0 s) (* 24.0 s))
                        rows nil s)
        )
      )
      (princ (strcat "\nTakeoff: " (itoa (length rows)) " items, "
                     (RMR:Num total 2) " total."))
    )
    (princ "\nNo quantities taken off.")
  )
  (princ)
)

;;; --- rate library table --------------------------------------------------------
(defun C:RMR-RATES (/ base s rows spec)
  (RMR:EnsureReady)
  (setq base (getpoint "\nTop-left of the rate library: "))
  (if base
    (progn
      (setq s (RMR:Scaled 1.0))
      (setq rows '())
      (foreach spec *RMR-RATE-SPECS*
        (setq rows (append rows
                     (list (list (nth 0 spec) (nth 1 spec)
                                 (RMR:UnitLabel (nth 2 spec) (nth 0 spec))
                                 (RMR:Num (float (nth 3 spec)) 2)))))
      )
      (RMR:DocTable base "RATE LIBRARY  |  RMR-RATES"
                    (strcat (itoa (length *RMR-RATE-SPECS*))
                            " rates from *RMR-RATE-SPECS*")
                    '("CODE" "DESCRIPTION" "UNIT" "RATE")
                    (list (* 18.0 s) (* 76.0 s) (* 16.0 s) (* 22.0 s))
                    rows nil s)
    )
  )
  (princ)
)

;;; --- elemental cost plan ---------------------------------------------------------
(defun C:RMR-COSTPLAN (/ base s total spec bar wide rowh y rgb share)
  (RMR:EnsureReady)
  (setq base (getpoint "\nTop-left of the cost plan: "))
  (if base
    (progn
      (setq s (RMR:Scaled 1.0))
      (setq total (RMR:ElementTotal))
      (setq wide (* 150.0 s))
      (setq rowh (* 9.0 s))
      (setq y (cadr base))
      (RMR:Text base "ELEMENTAL COST PLAN  |  RMR-COSTPLAN" (* 4.2 s)
                "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-TERRA*)
      (setq y (- y (* 5.0 s)))
      (RMR:Text (list (car base) y 0.0)
                (strcat (itoa (length *RMR-ELEMENT-SPECS*))
                        " elements  |  total " (RMR:Num total 2))
                (* 2.2 s) "RMR-NOTE" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
      (setq y (- y (* 10.0 s)))
      (foreach spec *RMR-ELEMENT-SPECS*
        (setq share (* 100.0 (/ (float (nth 1 spec))
                                (if (> total 0.0) total 1.0))))
        (setq bar (* wide (/ (float (nth 1 spec))
                             (if (> total 0.0) total 1.0))))
        (setq rgb (RMR:BrandRGB (nth 2 spec)))
        (RMR:Text (list (car base) y 0.0) (nth 0 spec) (* 2.3 s)
                  "RMR-LABEL" "RMR-A-TEXT" *RMR-BRAND-INK*)
        (RMR:Solid (list (+ (car base) (* 56.0 s)) (- y (* 1.0 s)) 0.0)
                   bar (* 5.0 s) "RMR-M-FILL" rgb)
        (RMR:Rect (list (+ (car base) (* 56.0 s)) (- y (* 1.0 s)) 0.0)
                  bar (* 5.0 s) "RMR-A-FRAME" *RMR-BRAND-SLATE*)
        (RMR:Text (list (+ (car base) (* 60.0 s) bar) y 0.0)
                  (strcat (RMR:Num (float (nth 1 spec)) 2) "   "
                          (RMR:Num share 1) "%")
                  (* 2.1 s) "RMR-BODY" "RMR-A-TEXT" *RMR-BRAND-INK*)
        (setq y (- y rowh))
      )
      (RMR:Text (list (car base) (- y (* 2.0 s)) 0.0)
                (strcat "TOTAL " (RMR:Num total 2)) (* 2.8 s)
                "RMR-NUMBER" "RMR-A-TEXT" *RMR-BRAND-TERRA*)
    )
  )
  (princ)
)

;;; --- cost per square metre --------------------------------------------------------
(defun C:RMR-PERQM (/ base s cost gifa bench perm diff wide better)
  (RMR:EnsureReady)
  (setq cost (RMR:PromptReal "Total construction cost" (RMR:ElementTotal)))
  (setq gifa (RMR:PromptReal "Gross internal floor area in m2" 124.0))
  (setq bench (RMR:PromptReal "Benchmark cost per m2" 2200.0))
  (if (and (> gifa 0.0) (> bench 0.0))
    (progn
      (setq perm (/ cost gifa))
      (setq diff (* 100.0 (/ (- perm bench) bench)))
      (setq better (< perm bench))
      (princ (strcat "\nCost per m2: " (RMR:Num perm 2)
                     "  |  benchmark " (RMR:Num bench 2)
                     "  |  " (if better "under" "over") " by "
                     (RMR:Num (abs diff) 1) "%"))
      (setq base (getpoint "\nTop-left of the cost per m2 panel: "))
      (if base
        (progn
          (setq s (RMR:Scaled 1.0))
          (setq wide (* 160.0 s))
          (RMR:Text base "COST PER M2  |  RMR-PERQM" (* 4.2 s) "RMR-HEAD"
                    "RMR-A-TEXT" *RMR-BRAND-TERRA*)
          (RMR:Text (list (car base) (- (cadr base) (* 5.0 s)) 0.0)
                    (strcat "GIFA " (RMR:Num gifa 2) " m2   |   cost "
                            (RMR:Num cost 2))
                    (* 2.2 s) "RMR-NOTE" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
          (RMR:Text (list (car base) (- (cadr base) (* 16.0 s)) 0.0)
                    (RMR:Num perm 0) (* 14.0 s) "RMR-NUMBER"
                    "RMR-A-TEXT" (if better *RMR-BRAND-TEAL* *RMR-BRAND-TERRA*))
          (RMR:Text (list (car base) (- (cadr base) (* 20.0 s)) 0.0)
                    "PER SQUARE METRE" (* 2.4 s) "RMR-HEAD"
                    "RMR-A-TEXT" *RMR-BRAND-SLATE*)
          ;; two comparison bars: this project and the benchmark
          (RMR:Solid (list (car base) (- (cadr base) (* 28.0 s)) 0.0)
                     wide (* 6.0 s) "RMR-M-FILL"
                     (if better *RMR-BRAND-TEAL* *RMR-BRAND-TERRA*))
          (RMR:Rect (list (car base) (- (cadr base) (* 28.0 s)) 0.0)
                    wide (* 6.0 s) "RMR-A-FRAME" *RMR-BRAND-SLATE*)
          (RMR:Solid (list (car base) (- (cadr base) (* 37.0 s)) 0.0)
                     (* wide (/ bench (max bench perm))) (* 6.0 s)
                     "RMR-M-FILL" *RMR-BRAND-SAND*)
          (RMR:Rect (list (car base) (- (cadr base) (* 37.0 s)) 0.0)
                    (* wide (/ bench (max bench perm))) (* 6.0 s)
                    "RMR-A-FRAME" *RMR-BRAND-SLATE*)
          (RMR:Text (list (+ (car base) wide (* 4.0 s))
                          (- (cadr base) (* 26.0 s)) 0.0)
                    (strcat "THIS PROJECT  " (RMR:Num perm 0)) (* 2.2 s)
                    "RMR-LABEL" "RMR-A-TEXT" *RMR-BRAND-INK*)
          (RMR:Text (list (+ (car base) wide (* 4.0 s))
                          (- (cadr base) (* 35.0 s)) 0.0)
                    (strcat "BENCHMARK  " (RMR:Num bench 0)) (* 2.2 s)
                    "RMR-LABEL" "RMR-A-TEXT" *RMR-BRAND-INK*)
          (RMR:Text (list (car base) (- (cadr base) (* 46.0 s)) 0.0)
                    (strcat (if better "Under" "Over") " benchmark by "
                            (RMR:Num (abs diff) 1) "%")
                    (* 2.6 s) "RMR-HEAD"
                    "RMR-A-TEXT" (if better *RMR-BRAND-TEAL* *RMR-BRAND-TERRA*))
        )
      )
    )
    (princ "\nThe floor area and the benchmark must both be greater than zero.")
  )
  (princ)
)

;;; --- cash flow curve ---------------------------------------------------------------
(defun C:RMR-CASHFLOW (/ base s weeks spec total dur index start weekly
                       cumulative maxw maxc colw maxh x y prev pts value
                       stage-total)
  (RMR:EnsureReady)
  (setq weeks 0)
  (setq dur 0)
  (foreach spec *RMR-PROGRAMME-SPECS*
    (if (> (+ (nth 1 spec) (nth 2 spec)) weeks)
      (setq weeks (+ (nth 1 spec) (nth 2 spec)))
    )
    (setq dur (+ dur (nth 2 spec)))
  )
  (setq total (RMR:ElementTotal))
  (if (and (> weeks 0) (> dur 0))
    (progn
      ;; spend each stage evenly across its own weeks
      (setq weekly '())
      (setq index 0)
      (while (< index weeks)
        (setq weekly (append weekly (list 0.0)))
        (setq index (1+ index))
      )
      (foreach spec *RMR-PROGRAMME-SPECS*
        (setq start (nth 1 spec))
        (setq stage-total (* total (/ (float (nth 2 spec)) (float dur))))
        (setq index 0)
        (while (< index (nth 2 spec))
          (if (< (+ start index) weeks)
            (setq weekly (RMR:SetNth weekly (+ start index)
                           (+ (nth (+ start index) weekly)
                              (/ stage-total (float (nth 2 spec))))))
          )
          (setq index (1+ index))
        )
      )
      (setq cumulative '())
      (setq prev 0.0)
      (foreach value weekly
        (setq prev (+ prev value))
        (setq cumulative (append cumulative (list prev)))
      )
      (setq maxw 0.0)
      (foreach value weekly (if (> value maxw) (setq maxw value)))
      (setq maxc 0.0)
      (foreach value cumulative (if (> value maxc) (setq maxc value)))
      (setq base (getpoint "\nTop-left of the cash flow chart: "))
      (if base
        (progn
          (setq s (RMR:Scaled 1.0))
          (setq colw (RMR:PromptReal "Width of one week" (* 5.0 s)))
          (setq maxh (* 90.0 s))
          (RMR:Text base "CASH FLOW  |  RMR-CASHFLOW" (* 4.2 s) "RMR-HEAD"
                    "RMR-A-TEXT" *RMR-BRAND-TERRA*)
          (RMR:Text (list (car base) (- (cadr base) (* 5.0 s)) 0.0)
                    (strcat (itoa weeks) " weeks  |  total "
                            (RMR:Num total 2)
                            "  |  spread by programme duration")
                    (* 2.2 s) "RMR-NOTE" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
          (setq y (- (cadr base) (* 12.0 s)))
          ;; weekly spend bars, hanging down from the axis
          (setq index 0)
          (foreach value weekly
            (setq x (+ (car base) (* index colw)))
            (RMR:Solid (list x (- y (* maxh 0.35)) 0.0) (* colw 0.7)
                       (* (/ value (if (> maxw 0.0) maxw 1.0)) (* maxh 0.35))
                       "RMR-M-FILL" *RMR-BRAND-GOLD*)
            (setq index (1+ index))
          )
          ;; cumulative S curve over the full height
          (setq pts '())
          (setq index 0)
          (foreach value cumulative
            (setq pts (append pts
                        (list (list (+ (car base) (* index colw))
                                    (- y (* maxh (/ value
                                                    (if (> maxc 0.0) maxc 1.0))))))))
            (setq index (1+ index))
          )
          (RMR:PolyLine pts nil nil "RMR-M-WALL" *RMR-BRAND-TERRA*)
          (RMR:Line (list (car base) (- y (* maxh 0.35)) 0.0)
                    (list (+ (car base) (* weeks colw)) (- y (* maxh 0.35)) 0.0)
                    "RMR-00-REF" *RMR-BRAND-SLATE*)
          (RMR:Text (list (car base) (- y maxh (* 6.0 s)) 0.0)
                    (strcat "CUMULATIVE TO " (RMR:Num maxc 2)
                            "   |   peak week " (RMR:Num maxw 2))
                    (* 2.4 s) "RMR-NUMBER" "RMR-A-TEXT" *RMR-BRAND-TERRA*)
          (princ (strcat "\nCash flow drawn: " (itoa weeks) " weeks, "
                         (RMR:Num total 2) " total, peak week "
                         (RMR:Num maxw 2) "."))
        )
      )
    )
    (princ "\nThe programme needs at least one stage with a duration.")
  )
  (princ)
)

;;; --- generic CSV import ---------------------------------------------------------
(defun C:RMR-CSVIMPORT (/ path lines row base s index rowh y colw cx
                       count width)
  (RMR:EnsureReady)
  (setq path (getfiled "Select the CSV to import" "table.csv" "csv" 4))
  (if (and path (setq lines (RMR:ReadLines path)))
    (progn
      (setq base (getpoint "\nTop-left of the imported table: "))
      (if base
        (progn
          (setq s (RMR:Scaled 1.0))
          (setq count 0)
          (setq width (* 160.0 s))
          (setq rowh (* 6.4 s))
          (setq y (cadr base))
          (setq index 0)
          (foreach line lines
            (if (< index 41)
              (progn
                (setq row (RMR:CsvCells line))
                (setq colw (/ width (float (max 1 (length row)))))
                (if (= index 0)
                  (RMR:Solid (list (car base) (- y rowh) 0.0) width rowh
                             "RMR-PRES-TITLE" *RMR-BRAND-SAND*)
                  (RMR:Rect (list (car base) (- y rowh) 0.0) width rowh
                            "RMR-A-FRAME" *RMR-BRAND-SLATE*)
                )
                (setq cx (car base))
                (foreach cell row
                  (RMR:Text (list (+ cx (* 1.4 s)) (+ (- y rowh) (* 1.8 s)) 0.0)
                            (RMR:Shorten cell 22) (* 2.0 s)
                            (if (= index 0) "RMR-HEAD" "RMR-BODY")
                            "RMR-A-TEXT" *RMR-BRAND-INK*)
                  (setq cx (+ cx colw))
                )
                (setq y (- y rowh))
                (setq count (1+ count))
              )
            )
            (setq index (1+ index))
          )
          (princ (strcat "\nImported " (itoa count) " rows from "
                         (RMR:FileTitle path) "."))
          (if (> (length lines) 41)
            (princ "\nOnly the first 41 rows are drawn - split large files.")
          )
        )
      )
    )
  )
  (princ)
)

;;; --- quantity validation ------------------------------------------------------------
(defun C:RMR-VALIDATE (/ spec unit rate problems data name flags blocks
                      answer path lines verdict)
  (RMR:EnsureReady)
  (setq problems '())
  (foreach spec *RMR-RATE-SPECS*
    (setq unit (strcase (nth 2 spec)))
    (setq rate (float (nth 3 spec)))
    (if (not (RMR:InList unit '("M" "M2" "M3" "NR" "ITEM")))
      (setq problems (append problems
                       (list (strcat (nth 0 spec)
                                     " has an unknown unit " (nth 2 spec)))))
    )
    (if (<= rate 0.0)
      (setq problems (append problems
                       (list (strcat (nth 0 spec) " has no rate"))))
    )
  )
  (setq blocks '())
  (setq data (tblnext "BLOCK" T))
  (while data
    (setq name (cdr (assoc 2 data)))
    (setq flags (cdr (assoc 70 data)))
    (if (and name (/= (substr name 1 1) "*")
             (= (logand (if flags flags 0) 4) 0))
      (if (and (not (RMR:StartsWith name "RMR-SYM-"))
               (not (RMR:StartsWith name "RMR-")))
        (setq blocks (append blocks (list name)))
      )
    )
    (setq data (tblnext "BLOCK"))
  )
  (princ (strcat "\nRooMNRooF quantity validation"))
  (princ (strcat "\n  " (itoa (length *RMR-RATE-SPECS*)) " rates checked"))
  (princ (strcat "\n  " (itoa (length blocks)) " unrated blocks in the drawing"))
  (foreach name blocks
    (princ (strcat "\n    " name))
  )
  (setq verdict (if problems "REVIEW" "PASS"))
  (princ (strcat "\n  Verdict: " verdict))
  (foreach item problems
    (princ (strcat "\n    " item))
  )
  (setq answer (RMR:PromptYesNo "Write a validation report" "No"))
  (if (RMR:YesP answer)
    (progn
      (setq path (getfiled "Save the validation report"
                           "RooMNRooF_Validation.txt" "txt" 1))
      (if path
        (progn
          (setq lines
            (list
              "RooMNRooF QUANTITY VALIDATION"
              (strcat "Project: " (RMR:ProjectValue "PROJECT" ""))
              (strcat "Job: " (RMR:ProjectValue "JOB" ""))
              (strcat "Date: " (RMR:TodayDate))
              (strcat "Verdict: " verdict)
              ""
              (strcat "Rates checked: " (itoa (length *RMR-RATE-SPECS*)))
              (strcat "Unrated blocks: " (itoa (length blocks)))))
          (foreach name blocks
            (setq lines (append lines (list (strcat "  " name))))
          )
          (setq lines (append lines (list "" "Problems:")))
          (if problems
            (foreach item problems (setq lines (append lines (list (strcat "  " item)))))
            (setq lines (append lines (list "  none")))
          )
          (if (RMR:WriteLines path lines)
            (princ (strcat "\nWritten: " path))
            (princ "\nCould not write the report.")
          )
        )
      )
    )
  )
  (princ)
)

;;; --- quantity surveyor report ---------------------------------------------------------
(defun C:RMR-QSREPORT (/ path lines spec total gifa perm start
                       stage-total dur weeks)
  (RMR:EnsureReady)
  (setq gifa (RMR:PromptReal "Gross internal floor area in m2" 124.0))
  (setq total (RMR:ElementTotal))
  (setq perm (if (> gifa 0.0) (/ total gifa) 0.0))
  (setq path (getfiled "Save the quantity surveyor report"
                       "RooMNRooF_QS_Report.txt" "txt" 1))
  (if path
    (progn
      (setq lines
        (list
          "================================================================"
          " RooMNRooF QUANTITY SURVEYOR REPORT"
          "================================================================"
          (strcat " Project  : " (RMR:ProjectValue "PROJECT" ""))
          (strcat " Client   : " (RMR:ProjectValue "CLIENT" ""))
          (strcat " Job      : " (RMR:ProjectValue "JOB" ""))
          (strcat " Stage    : " (RMR:ProjectValue "STAGE" ""))
          (strcat " Date     : " (RMR:TodayDate))
          ""
          " RATE LIBRARY"
          " --------------------------------------------------------------"))
      (foreach spec *RMR-RATE-SPECS*
        (setq lines (append lines
                      (list (strcat "  " (nth 0 spec) "  "
                                    (RMR:Shorten (nth 1 spec) 34)
                                    "  " (RMR:UnitLabel (nth 2 spec) (nth 0 spec))
                                    "  " (RMR:Num (float (nth 3 spec)) 2)))))
      )
      (setq lines (append lines
        (list
          ""
          " ELEMENTAL COST PLAN"
          " --------------------------------------------------------------")))
      (foreach spec *RMR-ELEMENT-SPECS*
        (setq lines (append lines
                      (list (strcat "  " (nth 0 spec)
                                    "  " (RMR:Num (float (nth 1 spec)) 2)
                                    "  "
                                    (RMR:Num (* 100.0 (/ (float (nth 1 spec))
                                                         (if (> total 0.0) total 1.0)))
                                             1) "%"))))
      )
      (setq lines (append lines
        (list (strcat "  TOTAL  " (RMR:Num total 2))
              ""
              " COST PER SQUARE METRE"
              " --------------------------------------------------------------"
              (strcat "  GIFA          " (RMR:Num gifa 2) " m2")
              (strcat "  Cost per m2   " (RMR:Num perm 2))
              ""
              " PROGRAMME CASH FLOW"
              " --------------------------------------------------------------")))
      (setq weeks 0)
      (setq dur 0)
      (foreach spec *RMR-PROGRAMME-SPECS*
        (if (> (+ (nth 1 spec) (nth 2 spec)) weeks)
          (setq weeks (+ (nth 1 spec) (nth 2 spec)))
        )
        (setq dur (+ dur (nth 2 spec)))
      )
      (if (> dur 0)
        (foreach spec *RMR-PROGRAMME-SPECS*
          (setq start (nth 1 spec))
          (setq stage-total (* total (/ (float (nth 2 spec)) (float dur))))
          (setq lines (append lines
                        (list (strcat "  " (RMR:Shorten (nth 0 spec) 24)
                                      "  wk " (itoa start) "  "
                                      (itoa (nth 2 spec)) " wks  "
                                      (RMR:Num stage-total 2)))))
        )
      )
      (setq lines (append lines
        (list ""
              "================================================================"
              " Generated by RooMNRooF_Master.lsp | RMR-QSREPORT"
              "================================================================")))
      (if (RMR:WriteLines path lines)
        (progn
          (princ (strcat "\nWritten: " path))
          (princ (strcat "\nTotal " (RMR:Num total 2) "  |  "
                         (RMR:Num perm 2) " per m2 over "
                         (RMR:Num gifa 2) " m2"))
        )
        (princ "\nCould not write the report.")
      )
    )
  )
  (princ)
)

;;; --- command aliases -------------------------------------------------------------
(defun RMR:CommandNames (/ out sym)
  ;; Every C:RMR-* command in this file, discovered from the symbol table so
  ;; the alias list never falls out of step with the code.
  (setq out '())
  (foreach sym (atoms-family 1)
    (if (and (> (strlen sym) 6) (= (strcase (substr sym 1 6)) "C:RMR-"))
      (setq out (append out (list (substr sym 3))))
    )
  )
  out
)

(defun RMR:AliasFor (name / out index ch len)
  ;; RMR-AXO -> RAXO, RMR-PRO-SETUP -> RPROSETUP
  (setq out "R")
  (setq len (strlen name))
  (setq index 5)
  (while (<= index len)
    (setq ch (substr name index 1))
    (if (/= ch "-") (setq out (strcat out ch)))
    (setq index (1+ index))
  )
  out
)

(defun RMR:AliasPairs (/ out names name)
  (setq out '())
  (foreach name (RMR:CommandNames)
    (setq out (append out (list (list (RMR:AliasFor name) name))))
  )
  out
)

(defun C:RMR-ALIAS (/ action pairs pair alias name registered skipped path
                  lines result)
  (RMR:EnsureReady)
  (vl-load-com)
  (setq action (RMR:PromptKeyword "Aliases" "Register Pgp Both" "Both"))
  (setq pairs (RMR:AliasPairs))
  (setq action (strcase action))
  (if (or (= action "REGISTER") (= action "BOTH"))
    (progn
      (setq registered 0)
      (setq skipped 0)
      (foreach pair pairs
        (setq alias (nth 0 pair))
        (setq name (nth 1 pair))
        (setq result
          (vl-catch-all-apply
            'vlax-add-cmd
            (list alias (read (strcat "C:" name)) alias
                  (strcat "RooMNRooF " name) 0)))
        (if (vl-catch-all-error-p result)
          (setq skipped (1+ skipped))
          (setq registered (1+ registered))
        )
      )
      (princ (strcat "\nRegistered " (itoa registered) " command aliases"
                     "  |  " (itoa skipped) " skipped"))
      (princ "\nType the short alias, for example RAXO for RMR-AXO.")
    )
  )
  (if (or (= action "PGP") (= action "BOTH"))
    (progn
      (setq path (strcat (getvar "DWGPREFIX") "RooMNRooF.pgp"))
      (setq lines (list ";;; RooMNRooF command aliases - generated by RMR-ALIAS"
                        ";;; Merge these lines into acad.pgp, then run REINIT."
                        ""))
      (foreach pair pairs
        (setq lines (append lines
                      (list (strcat (nth 0 pair) ", *" (nth 1 pair)))))
      )
      (if (RMR:WriteLines path lines)
        (princ (strcat "\nWritten: " path))
        (princ "\nCould not write the PGP file.")
      )
      (princ (strcat "\n" (itoa (length pairs))
                     " aliases. Merge them into acad.pgp and run REINIT."))
    )
  )
  (princ)
)

;;; --- menu / tool palette file ----------------------------------------------------------
(defun RMR:MenuSections (/ out group names)
  ;; One menu section per suite, built from the live command list.
  (setq out '())
  (foreach group
    '(("STANDARD" "RMR-MASTER RMR-PRO-SETUP RMR-SETLAYER RMR-LAYGROUP"
       "RMR-LEGEND RMR-SHEET RMR-SAVE-TEMPLATE RMR-PALETTE")
      ("ANNOTATE" "RMR-SCALE RMR-NORTH RMR-ROOMTAG RMR-AREA RMR-GRID"
       "RMR-KEYNOTE RMR-DETAIL RMR-LEVEL RMR-REVISION RMR-MLEADER RMR-DIM")
      ("MARKERS" "RMR-SECTION RMR-ELEVATION RMR-MATCHLINE RMR-BREAKLINE"
       "RMR-REVCLOUD")
      ("PRESENT" "RMR-HATCH RMR-HATCHLIB RMR-STAMP RMR-REVTABLE RMR-NOTES"
       "RMR-SCALEBAR RMR-KEYPLAN")
      ("MANAGE" "RMR-CHECK RMR-COUNT RMR-FINDTEXT RMR-EXPORT-PALETTE"
       "RMR-IMPORT-PALETTE RMR-PAGESETUP RMR-PUBLISH")
      ("STUDIO" "RMR-LAYOUTS RMR-VPORT RMR-SYMBOLS RMR-DOORSCHED RMR-FIELDS"
       "RMR-PROJECT RMR-BACKUP")
      ("DELIVERY" "RMR-WALL RMR-STAIR RMR-LENGTH RMR-BOM RMR-FINISHES"
       "RMR-SHEETREG RMR-XREFLIST RMR-TRANSMITTAL")
      ("HOUSEKEEPING" "RMR-LAYERSTATE RMR-STANDARDIZE RMR-CLEAN RMR-DWGPROPS")
      ("SITE" "RMR-SUNPATH RMR-FALL RMR-DRAIN RMR-PARK RMR-TILE RMR-RCP"
       "RMR-LEVELSCHED RMR-KEYLIB RMR-REPORT RMR-STRAY")
      ("COORDINATION" "RMR-CLASH RMR-ROOF RMR-RAIL RMR-WINDOWSCHED RMR-ZONE"
       "RMR-BLKSWAP RMR-RENUMBER RMR-TEXTALIGN RMR-INFO RMR-ORIENT")
      ("DOCUMENTATION" "RMR-SPECNOTE RMR-SPECINDEX RMR-ABBREV RMR-REVLIB"
       "RMR-CHECKLIST RMR-ROOMSCHED RMR-DOCLIST RMR-SHEETINDEX RMR-COVER"
       "RMR-DOCSHEET")
      ("PRESENTATION" "RMR-AXO RMR-ROOMVIEW RMR-BUILDUP RMR-SWATCH"
       "RMR-COLOURBOARD RMR-MOODBOARD RMR-AREACHART RMR-PROGRAMME"
       "RMR-BRANDING RMR-PRESENTSHEET")
      ("QUANTITY" "RMR-SURVEY RMR-MEASURE RMR-QUANTITY RMR-RATES RMR-COSTPLAN"
       "RMR-PERQM RMR-CASHFLOW RMR-CSVIMPORT RMR-VALIDATE RMR-QSREPORT")
      ("AUTOMATION" "RMR-ALIAS RMR-TOOLPALETTE RMR-AUTO RMR-BATCH")
      ("STRUCTURE" "RMR-COLUMN RMR-BEAM RMR-FOUNDATION RMR-REBAR"
       "RMR-SLABPANEL RMR-SETOUT RMR-STRUCTSCHED")
      ("SERVICES" "RMR-DUCT RMR-PIPE RMR-TRAY RMR-LIGHTING"
       "RMR-SPRINKLER RMR-MEPSCHED RMR-CLEARANCE")
      ("DETAILING" "RMR-DETAILLIB RMR-JUNCTION RMR-DETAILTAG RMR-DETLOC"
       "RMR-DIMCHAIN RMR-MATKEY RMR-DETSCALE")
      ("DETAIL SHEETS" "RMR-DETSHEET RMR-SPECLINK RMR-DETINDEX RMR-UVALUE"
       "RMR-FIRESTOP RMR-ACOUSTIC RMR-CHECKDETAIL"))
    (setq out (append out (list group)))
  )
  out
)

(defun C:RMR-TOOLPALETTE (/ path lines section title names name count group)
  (RMR:EnsureReady)
  (setq path (strcat (getvar "DWGPREFIX") "RooMNRooF.mnu"))
  (setq lines (list "***MENUGROUP=RooMNRooF"
                    "***POP1"
                    "**RMR"
                    "[&RooMNRooF]"
                    "[&Aliases...]^C^C_RMR-ALIAS"
                    "[&Automation...]^C^C_RMR-AUTO"
                    "[--]"))
  (setq count 0)
  (foreach section (RMR:MenuSections)
    (setq title (nth 0 section))
    (setq names (append (list (nth 1 section)) (list (nth 2 section))))
    (setq lines (append lines (list (strcat "->[&" title "]"))))
    (foreach group names
      (foreach name (RMR:SplitString group " ")
        (if (> (strlen name) 0)
          (progn
            (setq lines (append lines
                          (list (strcat "[" name "]^C^C_" name))))
            (setq count (1+ count))
          )
        )
      )
    )
    (setq lines (append lines (list "<-[" title " done]")))
  )
  (setq lines (append lines
    (list ""
          "***TOOLBARS"
          "**RMR_STANDARD"
          "ID_RMR_0 [_Toolbar(\"RooMNRooF\", _Floating, _Show, 100, 100, 1)]"
          "ID_RMR_1 [_Button(\"Master\", \"RMR-Master.bmp\", \"RMR-Icon.bmp\")]^C^C_RMR-MASTER"
          "ID_RMR_2 [_Button(\"Scale\", \"RMR-Scale.bmp\", \"RMR-Icon.bmp\")]^C^C_RMR-SCALE"
          "ID_RMR_3 [_Button(\"Check\", \"RMR-Check.bmp\", \"RMR-Icon.bmp\")]^C^C_RMR-CHECK"
          "ID_RMR_4 [_Button(\"Aliases\", \"RMR-Alias.bmp\", \"RMR-Icon.bmp\")]^C^C_RMR-ALIAS"
          "")))
  (if (RMR:WriteLines path lines)
    (progn
      (princ (strcat "\nWritten: " path))
      (princ (strcat "\n" (itoa count)
                     " commands across 18 pull-down sections."))
      (princ "\nLoad it with MENULOAD, or CUILOAD for newer builds.")
    )
    (princ "\nCould not write the menu file.")
  )
  (princ)
)

;;; --- automation runner ------------------------------------------------------------
(defun C:RMR-AUTO (/ log step label action argument result changed ss
                 answer path index spec ent data i pair lines oldexpert
                 oldcmdecho)
  (RMR:EnsureReady)
  (vl-load-com)
  (setq log '())
  (setq answer (RMR:PromptYesNo
                 (strcat "Run " (itoa (length *RMR-AUTO-SEQUENCE*))
                         " automation steps from *RMR-AUTO-SEQUENCE*") "Yes"))
  (if (RMR:YesP answer)
    (progn
      (foreach step *RMR-AUTO-SEQUENCE*
        (setq label (nth 0 step))
        (setq action (strcase (nth 1 step)))
        (setq argument (nth 2 step))
        (setq result "skipped")
        (cond
          ((= action "STANDARD")
           (RMR:EnsureReady)
           (setq result (strcat (itoa (length *RMR-LAYER-SPECS*)) " layers, "
                                (itoa (length *RMR-TEXT-STYLES*)) " styles")))
          ((= action "SCALE")
           (setq spec (RMR:TableSpec argument *RMR-SCALE-SPECS*))
           (if spec
             (progn
               (setq *RMR-DRAW-SCALE-LABEL* (nth 1 spec))
               (setq *RMR-ANNO-SPACE* "MODEL")
               (setq *RMR-ANNO-SCALE* (float (nth 2 spec)))
               (RMR:SafeSet "DIMSCALE" (float (nth 2 spec)))
               (RMR:SafeSet "CELTSCALE" 1.0)
               (RMR:SafeSet "MSLTSCALE" 1)
               (RMR:SafeSet "PSLTSCALE" 1)
               (RMR:SafeSet "LTSCALE" 1.0)
               (setq result (nth 1 spec))
             )
             (setq result "unknown scale")
           ))
          ((= action "BYLAYER")
           (setq ss (ssget "_X" (list (cons 410 "Model"))))
           (if ss
             (setq result (strcat (itoa (RMR:ForceByLayer ss)) " objects"))
             (setq result "nothing in model space")
           ))
          ((= action "PROPS")
           (setq result
             (if (vl-catch-all-error-p
                   (vl-catch-all-apply 'C:RMR-DWGPROPS nil))
               "failed"
               "drawing properties written")))
          ((= action "STRAY")
           (setq index 0)
           (setq ss (ssget "_X"))
           (if ss
             (progn
               (setq changed 0)
               (setq i 0)
               (repeat (sslength ss)
                 (setq ent (ssname ss i))
                 (setq data (entget ent))
                 (if (not (RMR:StandardLayerP (cdr (assoc 8 data))))
                   (setq changed (1+ changed))
                 )
                 (setq i (1+ i))
               )
               (setq result (strcat (itoa changed) " objects on stray layers"))
             )
             (setq result "nothing to check")
           ))
          ((= action "ALIAS")
           (setq path (strcat (getvar "DWGPREFIX") "RooMNRooF.pgp"))
           (setq lines (list ";;; RooMNRooF command aliases - generated by RMR-AUTO"
                             ""))
           (foreach pair (RMR:AliasPairs)
             (setq lines (append lines
                           (list (strcat (nth 0 pair) ", *" (nth 1 pair)))))
           )
           (if (RMR:WriteLines path lines)
             (setq result (strcat (itoa (length lines)) " lines to RooMNRooF.pgp"))
             (setq result "could not write the PGP file")
           ))
          ((= action "PURGE")
           (setq oldexpert (getvar "EXPERTS"))
           (setq oldcmdecho (getvar "CMDECHO"))
           (RMR:SafeSet "CMDECHO" 0)
           (RMR:SafeSet "EXPERTS" 1)
           (setq index 0)
           (while (< index 3)
             (vl-catch-all-apply 'command (list "_.-purge" "_A" "*" "_N"))
             (setq index (1+ index))
           )
           (vl-catch-all-apply 'command (list "_.-purge" "_R" "*" "_N"))
           (vl-catch-all-apply 'command (list "_.audit" "_Y"))
           (RMR:SafeSet "EXPERTS" oldexpert)
           (RMR:SafeSet "CMDECHO" oldcmdecho)
           (setq result "three purge passes and an audit"))
          ((= action "LOG")
           (setq result "log written at the end of the run"))
          (T (setq result (strcat "unknown action " action)))
        )
        (princ (strcat "\n  " label " - " result))
        (setq log (append log (list (strcat label " | " result))))
      )
      (setq path (strcat (getvar "DWGPREFIX") "RooMNRooF_Automation_Log.txt"))
      (setq lines
        (append
          (list "RooMNRooF AUTOMATION LOG"
                (strcat "Project: " (RMR:ProjectValue "PROJECT" ""))
                (strcat "Drawing: " (getvar "DWGNAME"))
                (strcat "Date: " (RMR:TodayDate))
                "")
          log))
      (if (RMR:WriteLines path lines)
        (princ (strcat "\nLog written: " path))
        (princ "\nCould not write the automation log.")
      )
    )
    (princ "\nAutomation cancelled.")
  )
  (princ)
)

;;; --- batch script writer -----------------------------------------------------------
(defun C:RMR-BATCH (/ folder files name path lines steps step answer here)
  (RMR:EnsureReady)
  (setq here (strcat (getvar "DWGPREFIX") (getvar "DWGNAME")))
  (setq path (getfiled "Pick any drawing in the folder to batch" here "dwg" 4))
  (if path
    (progn
      (setq folder (RMR:FolderOf path))
      (setq files (vl-directory-files folder "*.dwg" 1))
      (setq steps (list "(load \"RooMNRooF_Master.lsp\")"
                        "RMR-STANDARDIZE"
                        "RMR-DWGPROPS"
                        "RMR-STRAY"))
      (setq answer (RMR:PromptText "Commands to run in each drawing"
                                   "RMR-STANDARDIZE RMR-DWGPROPS RMR-STRAY"))
      (if (and answer (> (strlen (RMR:TrimString answer)) 0))
        (setq steps (append (list "(load \"RooMNRooF_Master.lsp\")")
                            (RMR:SplitString (RMR:TrimString answer) " ")))
      )
      (setq lines (list ";; RooMNRooF batch script - generated by RMR-BATCH"
                        (strcat ";; Folder: " folder)
                        (strcat ";; Date: " (RMR:TodayDate))
                        "FILEDIA 0"
                        "SDI 0"
                        ""))
      (foreach name files
        (setq lines (append lines (list (strcat "_.open \"" folder name "\""))))
        (foreach step steps
          (setq lines (append lines (list step)))
        )
        (setq lines (append lines (list "_.qsave" "_.close" "")))
      )
      (setq lines (append lines (list "FILEDIA 1" "SDI 0" "")))
      (setq path (strcat folder "RooMNRooF-Batch.scr"))
      (if (RMR:WriteLines path lines)
        (progn
          (princ (strcat "\nWritten: " path))
          (princ (strcat "\n" (itoa (length files)) " drawings, "
                         (itoa (length steps)) " steps each."))
          (princ "\nReview it first, then run it with the SCRIPT command.")
          (princ "\nCopy RooMNRooF_Master.lsp into a trusted folder and edit")
          (princ "\nthe load line to the full path if it is not on the search path.")
        )
        (princ "\nCould not write the batch script.")
      )
    )
  )
  (princ)
)

;;; =====================================================================
;;; PRO 11.0 STRUCTURAL AND MEP COORDINATION SUITE
;;; Parametric columns, beams, foundations, reinforcement, slab panels,
;;; setting-out coordinates and a structural element schedule, plus
;;; ductwork, pipework, cable containment, lighting, sprinklers, a
;;; services schedule and a vertical clearance coordination check.
;;; The suite adds a SERVICES layer group so every discipline in the
;;; model has its own true-colour layer.
;;; =====================================================================

;;; --- structural sizes --------------------------------------------------------
;;; Column sizes: (Mark Width_mm Depth_mm ColourKey)
(setq *RMR-COLUMN-SPECS*
 '(
    ("C1" 230 230 "TERRA")
    ("C2" 300 300 "TERRA")
    ("C3" 230 450 "TERRA")
    ("C4" 300 450 "TERRA")
    ("C5" 400 400 "TERRA")
    ("C6" 450 600 "TERRA")
  )
)

;;; Beam sizes: (Mark Width_mm Depth_mm MaxSpan_mm ColourKey)
(setq *RMR-BEAM-SPECS*
 '(
    ("B1" 230  400  6000 "TERRA")
    ("B2" 300  500  7500 "TERRA")
    ("B3" 300  600  9000 "TERRA")
    ("B4" 400  700 12000 "SLATE")
    ("B5" 400  850 15000 "SLATE")
  )
)

;;; Reinforcement: (BarMark Diameter_mm Spacing_mm)
(setq *RMR-REBAR-SPECS*
 '(
    ("T12" 12 200)
    ("T16" 16 200)
    ("T20" 20 150)
    ("T25" 25 150)
    ("T32" 32 125)
    ("T40" 40 100)
  )
)

;;; --- services sizes ----------------------------------------------------------
;;; Duct sizes: (Size Width_mm Height_mm ColourKey)
(setq *RMR-DUCT-SPECS*
 '(
    ("100 X 100" 100 100 "TEAL")
    ("200 X 150" 200 150 "TEAL")
    ("300 X 200" 300 200 "TEAL")
    ("400 X 250" 400 250 "TEAL")
    ("600 X 300" 600 300 "TEAL")
    ("800 X 400" 800 400 "TEAL")
  )
)

;;; Pipe sizes: (Size Bore_mm ColourKey)
(setq *RMR-PIPE-SPECS*
 '(
    ("15" 15 "BLUE")
    ("22" 22 "BLUE")
    ("28" 28 "BLUE")
    ("35" 35 "BLUE")
    ("54" 54 "BLUE")
    ("76" 76 "BLUE")
  )
)

;;; Vertical service zones: (Zone Bottom_mm Top_mm ColourKey Description)
(setq *RMR-SERVICE-ZONES*
 '(
    ("STRUCTURAL ZONE"    0  450 "SLATE" "Structure, slab and primary framing")
    ("HVAC DUCT ZONE"   450  750 "TEAL"  "Supply and extract ductwork")
    ("PIPEWORK ZONE"    750  950 "BLUE"  "Flow, return, drainage and sprinkler mains")
    ("ELECTRICAL ZONE"  950 1050 "GOLD"  "Containment, cable tray and small power")
    ("CEILING ZONE"    1050 1250 "SAND"  "Ceiling, luminaires and air terminals")
  )
)

;;; Which vertical zone each services layer occupies: (Layer Zone)
(setq *RMR-SERVICE-LAYER-ZONES*
 '(
    ("RMR-S-BEAM"    "STRUCTURAL ZONE")
    ("RMR-S-SLAB"    "STRUCTURAL ZONE")
    ("RMR-S-COLUMN"  "STRUCTURAL ZONE")
    ("RMR-E-DUCT"    "HVAC DUCT ZONE")
    ("RMR-E-GRILLE"  "HVAC DUCT ZONE")
    ("RMR-E-PIPE"    "PIPEWORK ZONE")
    ("RMR-P-SUPPLY"  "PIPEWORK ZONE")
    ("RMR-P-DRAIN"   "PIPEWORK ZONE")
    ("RMR-E-POWER"   "ELECTRICAL ZONE")
    ("RMR-E-TRAY"    "ELECTRICAL ZONE")
    ("RMR-E-DATA"    "ELECTRICAL ZONE")
    ("RMR-E-LIGHT"   "CEILING ZONE")
    ("RMR-E-SPRINK"  "CEILING ZONE")
  )
)

;;; --- shared structural and services helpers -----------------------------------
(defun RMR:Mm (mm k)
  ;; Millimetres to drawing units. k is drawing units per metre.
  (* (/ (float mm) 1000.0) k)
)

(defun RMR:Mid2D (p1 p2)
  (list (/ (+ (car p1) (car p2)) 2.0) (/ (+ (cadr p1) (cadr p2)) 2.0) 0.0)
)

(defun RMR:LayerCount (layer / ss)
  (setq ss (ssget "_X" (list (cons 8 layer))))
  (if ss (sslength ss) 0)
)

(defun RMR:LayerDescription (layer / spec found)
  (foreach spec *RMR-LAYER-SPECS*
    (if (= (strcase (nth 0 spec)) (strcase layer)) (setq found (nth 5 spec)))
  )
  (if found found layer)
)

(defun RMR:ZoneFor (level / zone found)
  ;; The service zone a level in millimetres falls into.
  (foreach zone *RMR-SERVICE-ZONES*
    (if (and (>= level (float (nth 1 zone))) (< level (float (nth 2 zone))))
      (setq found zone)
    )
  )
  found
)

(defun RMR:ZoneTop (/ top zone)
  (setq top 0.0)
  (foreach zone *RMR-SERVICE-ZONES*
    (if (> (float (nth 2 zone)) top) (setq top (float (nth 2 zone))))
  )
  top
)

(defun RMR:ZoneOfLayer (layer / pair found)
  (foreach pair *RMR-SERVICE-LAYER-ZONES*
    (if (= (strcase (nth 0 pair)) (strcase layer)) (setq found (nth 1 pair)))
  )
  found
)

(defun RMR:CountByLayer (layers / out layer count)
  (setq out '())
  (foreach layer layers
    (setq count (RMR:LayerCount layer))
    (setq out (append out (list (list layer (RMR:LayerDescription layer) count))))
  )
  out
)

(defun RMR:FlowArrow (tip angle size layer rgb / ux uy)
  (setq ux (cos angle))
  (setq uy (sin angle))
  (RMR:SolidTri tip ux uy size layer rgb)
)

(defun RMR:Rung (centre angle half size layer rgb / ux uy p1 p2)
  ;; A short cross bar, used for cable tray rungs and sprinkler heads.
  (setq ux (- (sin angle)))
  (setq uy (cos angle))
  (setq p1 (list (- (car centre) (* ux half)) (- (cadr centre) (* uy half)) 0.0))
  (setq p2 (list (+ (car centre) (* ux half)) (+ (cadr centre) (* uy half)) 0.0))
  (RMR:Line p1 p2 layer rgb)
  (setq p1 (list (- (car centre) (* (- ux) size)) (- (cadr centre) (* (- uy) size)) 0.0))
  (setq p2 (list (+ (car centre) (* (- ux) size)) (+ (cadr centre) (* (- uy) size)) 0.0))
  (if (> size 0.0) (RMR:Line p1 p2 layer rgb))
)

;;; --- columns -------------------------------------------------------------------
(defun C:RMR-COLUMN (/ keys mark spec k pick count w d centre base s)
  (RMR:EnsureReady)
  (setq keys (RMR:KeywordList *RMR-COLUMN-SPECS*))
  (setq mark (RMR:PromptKeyword "Column mark" keys (nth 0 (nth 0 *RMR-COLUMN-SPECS*))))
  (setq spec (RMR:TableSpec mark *RMR-COLUMN-SPECS*))
  (if spec
    (progn
      (setq k (RMR:PromptReal "Drawing units per metre" 1.0))
      (setq w (RMR:Mm (nth 1 spec) k))
      (setq d (RMR:Mm (nth 2 spec) k))
      (setq s (RMR:Scaled 1.0))
      (setq count 0)
      (princ (strcat "\nPlacing " mark " columns at " (itoa (nth 1 spec))
                     " x " (itoa (nth 2 spec)) " mm. Pick the centres."))
      (setq pick (getpoint "\nColumn centre <finish>: "))
      (while pick
        (setq centre (list (car pick) (cadr pick) 0.0))
        (setq base (list (- (car centre) (/ w 2.0)) (- (cadr centre) (/ d 2.0)) 0.0))
        (RMR:Solid base w d "RMR-S-COLUMN" (RMR:BrandRGB (nth 3 spec)))
        (RMR:Rect base w d "RMR-S-COLUMN" *RMR-BRAND-INK*)
        ;; setting-out cross through the centre
        (RMR:Line (list (- (car centre) w) (cadr centre) 0.0)
                  (list (+ (car centre) w) (cadr centre) 0.0)
                  "RMR-S-COLUMN" *RMR-BRAND-SLATE*)
        (RMR:Line (list (car centre) (- (cadr centre) d) 0.0)
                  (list (car centre) (+ (cadr centre) d) 0.0)
                  "RMR-S-COLUMN" *RMR-BRAND-SLATE*)
        (RMR:GridBubble (list (+ (car centre) (* 1.6 s)) (+ (cadr centre) (* 1.6 s)) 0.0)
                        mark (* 2.2 s))
        (setq count (1+ count))
        (setq pick (getpoint "\nNext column centre <finish>: "))
      )
      (princ (strcat "\n" (itoa count) " " mark " columns placed."))
    )
    (princ "\nUnknown column mark.")
  )
  (princ)
)

;;; --- beams ---------------------------------------------------------------------
(defun C:RMR-BEAM (/ keys mark spec k pick p1 p2 count half span maxspan
                 angle mid nx ny rgb a b c d)
  (RMR:EnsureReady)
  (setq keys (RMR:KeywordList *RMR-BEAM-SPECS*))
  (setq mark (RMR:PromptKeyword "Beam mark" keys (nth 0 (nth 0 *RMR-BEAM-SPECS*))))
  (setq spec (RMR:TableSpec mark *RMR-BEAM-SPECS*))
  (if spec
    (progn
      (setq k (RMR:PromptReal "Drawing units per metre" 1.0))
      (setq half (/ (RMR:Mm (nth 1 spec) k) 2.0))
      (setq maxspan (nth 3 spec))
      (setq rgb (RMR:BrandRGB (nth 4 spec)))
      (setq count 0)
      (princ (strcat "\nPlacing " mark " beams at " (itoa (nth 1 spec))
                     " x " (itoa (nth 2 spec)) " mm."))
      (setq pick (getpoint "\nBeam start <finish>: "))
      (while pick
        (setq p1 pick)
        (setq p2 (getpoint p1 "\nBeam end: "))
        (if p2
          (progn
            (setq angle (angle p1 p2))
            ;; left and right offsets from the centre line give the beam edges
            (setq nx (* (- (sin angle)) half))
            (setq ny (* (cos angle) half))
            (setq a (list (+ (car p1) nx) (+ (cadr p1) ny) 0.0))
            (setq b (list (+ (car p2) nx) (+ (cadr p2) ny) 0.0))
            (setq c (list (- (car p2) nx) (- (cadr p2) ny) 0.0))
            (setq d (list (- (car p1) nx) (- (cadr p1) ny) 0.0))
            (RMR:Quad a b c d "RMR-S-BEAM" rgb)
            (RMR:Line a b "RMR-S-BEAM" *RMR-BRAND-INK*)
            (RMR:Line c d "RMR-S-BEAM" *RMR-BRAND-INK*)
            (RMR:Line d a "RMR-S-BEAM" *RMR-BRAND-INK*)
            (RMR:Line b c "RMR-S-BEAM" *RMR-BRAND-INK*)
            (setq mid (RMR:Mid2D a c))
            (setq span (* (/ (distance p1 p2) k) 1000.0))
            (RMR:RotText mid
              (strcat mark "  " (itoa (nth 1 spec)) " X " (itoa (nth 2 spec))
                      "  SPAN " (RMR:Num (/ span 1000.0) 2) " m")
              (* 2.2 (RMR:Scaled 1.0)) "RMR-LABEL" "RMR-A-TEXT" *RMR-BRAND-INK*
              angle)
            (if (> span (float maxspan))
              (princ (strcat "\n  span " (RMR:Num (/ span 1000.0) 2)
                             " m exceeds the " (itoa maxspan)
                             " mm limit for " mark))
            )
            (setq count (1+ count))
          )
        )
        (setq pick (getpoint "\nNext beam start <finish>: "))
      )
      (princ (strcat "\n" (itoa count) " " mark " beams placed."))
    )
    (princ "\nUnknown beam mark.")
  )
  (princ)
)

;;; --- foundations ----------------------------------------------------------------
(defun C:RMR-FOUNDATION (/ kind w dp k pick centre base half pts left right
                        count s)
  (RMR:EnsureReady)
  (setq kind (RMR:PromptKeyword "Foundation" "Pad Strip" "Pad"))
  (setq k (RMR:PromptReal "Drawing units per metre" 1.0))
  (setq w (RMR:PromptReal "Foundation width in mm" 900.0))
  (setq dp (RMR:PromptReal "Foundation depth in mm" 450.0))
  (setq s (RMR:Scaled 1.0))
  (setq count 0)
  (if (= (strcase kind) "PAD")
    (progn
      (princ "\nPick the pad centres.")
      (setq pick (getpoint "\nPad centre <finish>: "))
      (while pick
        (setq centre (list (car pick) (cadr pick) 0.0))
        (setq half (/ (RMR:Mm w k) 2.0))
        (setq base (list (- (car centre) half) (- (cadr centre) half) 0.0))
        (RMR:Solid base (* 2.0 half) (* 2.0 half) "RMR-S-FOUND"
                   *RMR-BRAND-SLATE*)
        (RMR:Rect base (* 2.0 half) (* 2.0 half) "RMR-S-FOUND" *RMR-BRAND-INK*)
        (RMR:Rect (list (+ (car base) (* 1.5 s)) (+ (cadr base) (* 1.5 s)) 0.0)
                  (- (* 2.0 half) (* 3.0 s)) (- (* 2.0 half) (* 3.0 s))
                  "RMR-S-HIDDEN" *RMR-BRAND-SLATE*)
        (RMR:Text (RMR:PT+ base (* 1.0 s) (- (* 4.0 s)))
                  (strcat "PAD " (RMR:Num w 0) " X " (RMR:Num w 0) " X "
                          (RMR:Num dp 0) " DP")
                  (* 2.0 s) "RMR-NOTE" "RMR-A-TEXT" *RMR-BRAND-INK*)
        (setq count (1+ count))
        (setq pick (getpoint "\nNext pad centre <finish>: "))
      )
      (princ (strcat "\n" (itoa count) " pads placed."))
    )
    (progn
      (princ "\nPick the strip centre line, Enter when finished.")
      (setq pts '())
      (setq pick (getpoint "\nStrip start: "))
      (while pick
        (setq pts (append pts (list (list (car pick) (cadr pick) 0.0))))
        (setq pick (getpoint "\nNext point <finish>: "))
      )
      (if (> (length pts) 1)
        (progn
          (setq half (/ (RMR:Mm w k) 2.0))
          (setq left (RMR:OffsetPath pts half))
          (setq right (RMR:OffsetPath pts (- half)))
          (RMR:PolyLine left nil nil "RMR-S-FOUND" *RMR-BRAND-SLATE*)
          (RMR:PolyLine right nil nil "RMR-S-FOUND" *RMR-BRAND-SLATE*)
          (RMR:PolyLine pts nil nil "RMR-S-HIDDEN" *RMR-BRAND-SLATE*)
          (RMR:Text (RMR:PT+ (nth 0 pts) (* 2.0 s) (* 2.0 s))
                    (strcat "STRIP " (RMR:Num w 0) " WIDE X "
                            (RMR:Num dp 0) " DP  |  "
                            (RMR:Num (/ (* (RMR:PathLength pts) 1000.0) k) 2)
                            " m run")
                    (* 2.2 s) "RMR-LABEL" "RMR-A-TEXT" *RMR-BRAND-INK*)
          (princ (strcat "\nStrip foundation drawn, " (itoa (length pts))
                         " points."))
        )
        (princ "\nA strip needs at least two points.")
      )
    )
  )
  (princ)
)

(defun RMR:PathLength (pts / total i)
  (setq total 0.0)
  (setq i 0)
  (while (< i (1- (length pts)))
    (setq total (+ total (distance (nth i pts) (nth (1+ i) pts))))
    (setq i (1+ i))
  )
  total
)

;;; --- reinforcement ---------------------------------------------------------------
(defun C:RMR-REBAR (/ keys mark spec pick p1 p2 angle mid s count hook)
  (RMR:EnsureReady)
  (setq keys (RMR:KeywordList *RMR-REBAR-SPECS*))
  (setq mark (RMR:PromptKeyword "Bar mark" keys (nth 0 (nth 0 *RMR-REBAR-SPECS*))))
  (setq spec (RMR:TableSpec mark *RMR-REBAR-SPECS*))
  (if spec
    (progn
      (setq s (RMR:Scaled 1.0))
      (setq count 0)
      (princ (strcat "\nDrawing " mark " bars. Pick the bar runs."))
      (setq pick (getpoint "\nBar start <finish>: "))
      (while pick
        (setq p1 (list (car pick) (cadr pick) 0.0))
        (setq p2 (getpoint p1 "\nBar end: "))
        (if p2
          (progn
            (setq p2 (list (car p2) (cadr p2) 0.0))
            (setq angle (angle p1 p2))
            (setq hook (* 2.0 s))
            (RMR:Line p1 p2 "RMR-S-REBAR" *RMR-BRAND-INK*)
            ;; 90 degree hooks at both ends, the standard bar callout
            (RMR:Line p1 (polar p1 (+ angle (* 0.5 pi)) hook)
                      "RMR-S-REBAR" *RMR-BRAND-INK*)
            (RMR:Line p2 (polar p2 (- angle (* 0.5 pi)) hook)
                      "RMR-S-REBAR" *RMR-BRAND-INK*)
            (setq mid (RMR:Mid2D p1 p2))
            (RMR:GridBubble (RMR:PT+ mid (* 1.4 s) (* 1.4 s)) mark (* 2.0 s))
            (RMR:RotText (RMR:PT+ mid 0.0 (- (* 3.6 s)))
              (strcat (itoa (nth 1 spec)) " @ " (itoa (nth 2 spec)))
              (* 2.0 s) "RMR-NOTE" "RMR-A-TEXT" *RMR-BRAND-SLATE* angle)
            (setq count (1+ count))
          )
        )
        (setq pick (getpoint "\nNext bar start <finish>: "))
      )
      (princ (strcat "\n" (itoa count) " " mark " bars drawn."))
    )
    (princ "\nUnknown bar mark.")
  )
  (princ)
)

;;; --- slab panels ------------------------------------------------------------------
(defun C:RMR-SLABPANEL (/ c1 c2 module thick dir k s x0 x1 y0 y1 span panels
                     index pos rows base count)
  (RMR:EnsureReady)
  (setq c1 (getpoint "\nFirst corner of the slab: "))
  (if c1
    (progn
      (setq c2 (getcorner c1 "\nOpposite corner: "))
      (if c2
        (progn
          (setq k (RMR:PromptReal "Drawing units per metre" 1.0))
          (setq module (RMR:PromptReal "Panel module in mm" 1200.0))
          (setq thick (RMR:PromptReal "Slab thickness in mm" 200.0))
          (setq dir (RMR:PromptKeyword "Panels run" "Horizontal Vertical"
                                       "Horizontal"))
          (setq s (RMR:Scaled 1.0))
          (setq x0 (min (car c1) (car c2)))
          (setq x1 (max (car c1) (car c2)))
          (setq y0 (min (cadr c1) (cadr c2)))
          (setq y1 (max (cadr c1) (cadr c2)))
          (RMR:Rect (list x0 y0 0.0) (- x1 x0) (- y1 y0) "RMR-S-SLAB"
                    *RMR-BRAND-INK*)
          (setq panels '())
          (setq rows '())
          (setq count 0)
          (if (= (strcase dir) "HORIZONTAL")
            (progn
              (setq span (- x1 x0))
              (setq index 0)
              (setq pos x0)
              (while (< pos x1)
                (setq panels (append panels (list pos)))
                (setq pos (+ pos (RMR:Mm module k)))
              )
              (foreach pos panels
                (if (> pos x0)
                  (RMR:Line (list pos y0 0.0) (list pos y1 0.0)
                            "RMR-S-SLAB" *RMR-BRAND-SLATE*)
                )
                (setq count (1+ count))
                (RMR:Text (list (/ (+ pos (min (+ pos (RMR:Mm module k)) x1)) 2.0)
                                (/ (+ y0 y1) 2.0) 0.0)
                          (strcat "P" (RMR:NumPad2 count)) (* 2.4 s)
                          "RMR-NUMBER" "RMR-A-TEXT" *RMR-BRAND-INK*)
                (setq rows (append rows
                            (list (list (strcat "P" (RMR:NumPad2 count))
                                        (RMR:Num (min (* (/ (- (+ pos (RMR:Mm module k)) pos) 1000.0) (/ 1.0 k)) 1000.0) 0)
                                        (RMR:Num (* (/ (- y1 y0) k) 1000.0) 0)
                                        (RMR:Num thick 0)))))
                (setq index (1+ index))
              )
            )
            (progn
              (setq span (- y1 y0))
              (setq pos y0)
              (while (< pos y1)
                (setq panels (append panels (list pos)))
                (setq pos (+ pos (RMR:Mm module k)))
              )
              (foreach pos panels
                (if (> pos y0)
                  (RMR:Line (list x0 pos 0.0) (list x1 pos 0.0)
                            "RMR-S-SLAB" *RMR-BRAND-SLATE*)
                )
                (setq count (1+ count))
                (RMR:Text (list (/ (+ x0 x1) 2.0)
                                (/ (+ pos (min (+ pos (RMR:Mm module k)) y1)) 2.0)
                                0.0)
                          (strcat "P" (RMR:NumPad2 count)) (* 2.4 s)
                          "RMR-NUMBER" "RMR-A-TEXT" *RMR-BRAND-INK*)
                (setq rows (append rows
                            (list (list (strcat "P" (RMR:NumPad2 count))
                                        (RMR:Num (* (/ (- x1 x0) k) 1000.0) 0)
                                        (RMR:Num (min (* (/ (- (+ pos (RMR:Mm module k)) pos) 1000.0) (/ 1.0 k)) 1000.0) 0)
                                        (RMR:Num thick 0)))))
              )
            )
          )
          (RMR:Text (list x0 (- y0 (* 5.0 s)) 0.0)
                    (strcat (itoa count) " PANELS  |  MODULE "
                            (RMR:Num module 0) " mm  |  "
                            (RMR:Num thick 0) " mm THICK")
                    (* 2.4 s) "RMR-LABEL" "RMR-A-TEXT" *RMR-BRAND-TERRA*)
          (setq base (getpoint "\nTop-left of the panel schedule <enter to skip>: "))
          (if base
            (RMR:DocTable base "SLAB PANEL SCHEDULE  |  RMR-SLABPANEL"
                          (strcat (itoa count) " panels at "
                                  (RMR:Num module 0) " mm module")
                          '("PANEL" "LENGTH" "WIDTH" "THICK")
                          (list (* 20.0 s) (* 26.0 s) (* 26.0 s) (* 26.0 s))
                          rows nil s)
          )
        )
      )
    )
  )
  (princ)
)

;;; --- setting out -------------------------------------------------------------------
(defun C:RMR-SETOUT (/ k s pick point index rows base count answer path lines)
  (RMR:EnsureReady)
  (setq k (RMR:PromptReal "Drawing units per metre" 1.0))
  (setq s (RMR:Scaled 1.0))
  (setq rows '())
  (setq count 0)
  (princ "\nPick the setting-out points in order.")
  (setq pick (getpoint "\nSetting-out point <finish>: "))
  (while pick
    (setq point (list (car pick) (cadr pick) 0.0))
    (setq count (1+ count))
    (RMR:Circle point (* 1.2 s) "RMR-00-REF" *RMR-BRAND-TERRA*)
    (RMR:Text (RMR:PT+ point (* 1.8 s) (* 1.4 s))
              (strcat "S" (itoa count)) (* 2.2 s) "RMR-NUMBER" "RMR-A-TEXT"
              *RMR-BRAND-TERRA*)
    (RMR:Text (RMR:PT+ point (* 1.8 s) (- (* 3.4 s)))
              (strcat "E " (RMR:Num (/ (car point) k) 3)
                      "  N " (RMR:Num (/ (cadr point) k) 3))
              (* 1.9 s) "RMR-MARK" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
    (setq rows (append rows
                (list (list (strcat "S" (itoa count))
                            (RMR:Num (/ (car point) k) 3)
                            (RMR:Num (/ (cadr point) k) 3)))))
    (setq pick (getpoint "\nNext setting-out point <finish>: "))
  )
  (if rows
    (progn
      (setq base (getpoint "\nTop-left of the setting-out table <enter to skip>: "))
      (if base
        (RMR:DocTable base "SETTING OUT COORDINATES  |  RMR-SETOUT"
                      (strcat (itoa count) " points  |  metres")
                      '("POINT" "EASTING" "NORTHING")
                      (list (* 22.0 s) (* 34.0 s) (* 34.0 s))
                      rows nil s)
      )
      (setq answer (RMR:PromptYesNo "Write a setting-out CSV" "No"))
      (if (RMR:YesP answer)
        (progn
          (setq path (getfiled "Save the setting-out coordinates"
                               "RooMNRooF_SettingOut.csv" "csv" 1))
          (if path
            (progn
              (setq lines (list "POINT,EASTING,NORTHING"))
              (foreach row rows
                (setq lines (append lines
                              (list (strcat (nth 0 row) "," (nth 1 row) ","
                                            (nth 2 row)))))
              )
              (if (RMR:WriteLines path lines)
                (princ (strcat "\nWritten: " path))
                (princ "\nCould not write the CSV.")
              )
            )
          )
        )
      )
      (princ (strcat "\n" (itoa count) " setting-out points recorded."))
    )
    (princ "\nNo points picked.")
  )
  (princ)
)

;;; --- structural schedule -------------------------------------------------------------
(defun C:RMR-STRUCTSCHED (/ layers rows base s answer path lines total)
  (RMR:EnsureReady)
  (setq layers '("RMR-S-COLUMN" "RMR-S-BEAM" "RMR-S-SLAB" "RMR-S-FOUND"
                 "RMR-S-REBAR" "RMR-S-GRID"))
  (setq rows (RMR:CountByLayer layers))
  (setq s (RMR:Scaled 1.0))
  (setq total 0)
  (foreach row rows (setq total (+ total (nth 2 row))))
  (princ (strcat "\nStructural elements in the drawing: " (itoa total)))
  (foreach row rows
    (princ (strcat "\n  " (nth 0 row) "  " (itoa (nth 2 row))))
  )
  (setq base (getpoint "\nTop-left of the structural schedule <enter to skip>: "))
  (if base
    (RMR:DocTable base "STRUCTURAL ELEMENT SCHEDULE  |  RMR-STRUCTSCHED"
                  (strcat (itoa total) " elements  |  counted from the drawing")
                  '("LAYER" "DESCRIPTION" "COUNT")
                  (list (* 34.0 s) (* 86.0 s) (* 22.0 s))
                  (mapcar '(lambda (row)
                             (list (nth 0 row) (RMR:Shorten (nth 1 row) 40)
                                   (itoa (nth 2 row))))
                          rows)
                  nil s)
  )
  (setq answer (RMR:PromptYesNo "Write a structural schedule report" "No"))
  (if (RMR:YesP answer)
    (progn
      (setq path (getfiled "Save the structural schedule"
                           "RooMNRooF_Structural_Schedule.txt" "txt" 1))
      (if path
        (progn
          (setq lines (list "RooMNRooF STRUCTURAL ELEMENT SCHEDULE"
                            (strcat "Project: " (RMR:ProjectValue "PROJECT" ""))
                            (strcat "Date: " (RMR:TodayDate))
                            ""
                            "LAYER                 DESCRIPTION                              COUNT"))
          (foreach row rows
            (setq lines (append lines
                          (list (strcat "  " (nth 0 row) "  "
                                        (RMR:Shorten (nth 1 row) 40)
                                        "  " (itoa (nth 2 row))))))
          )
          (setq lines (append lines (list "" (strcat "TOTAL  " (itoa total)))))
          (if (RMR:WriteLines path lines)
            (princ (strcat "\nWritten: " path))
            (princ "\nCould not write the report.")
          )
        )
      )
    )
  )
  (princ)
)

;;; --- ductwork -------------------------------------------------------------------------
(defun C:RMR-DUCT (/ keys size spec k pick pts count length left right
                 inner outer angle mid s)
  (RMR:EnsureReady)
  (setq keys (RMR:KeywordList *RMR-DUCT-SPECS*))
  (setq size (RMR:PromptKeyword "Duct size" keys (nth 0 (nth 0 *RMR-DUCT-SPECS*))))
  (setq spec (RMR:TableSpec size *RMR-DUCT-SPECS*))
  (if spec
    (progn
      (setq k (RMR:PromptReal "Drawing units per metre" 1.0))
      (setq s (RMR:Scaled 1.0))
      (setq count 0)
      (princ (strcat "\nDrawing " size " ductwork. Pick the route."))
      (setq pick (getpoint "\nDuct start: "))
      (while pick
        (setq pts (list (list (car pick) (cadr pick) 0.0)))
        (setq pick (getpoint (nth 0 pts) "\nNext point <finish>: "))
        (while pick
          (setq pts (append pts (list (list (car pick) (cadr pick) 0.0))))
          (setq pick (getpoint (nth (1- (length pts)) pts) "\nNext point <finish>: "))
        )
        (if (> (length pts) 1)
          (progn
            (setq left (RMR:OffsetPath pts (/ (RMR:Mm (nth 1 spec) k) 2.0)))
            (setq right (RMR:OffsetPath pts (- (/ (RMR:Mm (nth 1 spec) k) 2.0))))
            (setq inner (RMR:ClosedPoly
                          (append left (reverse right))
                          "RMR-E-DUCT" (RMR:BrandRGB (nth 3 spec))))
            (if inner (RMR:HatchEntity inner "ANSI31" (RMR:BrandRGB (nth 3 spec))))
            (RMR:PolyLine left nil nil "RMR-E-DUCT" *RMR-BRAND-INK*)
            (RMR:PolyLine right nil nil "RMR-E-DUCT" *RMR-BRAND-INK*)
            (setq angle (angle (nth 0 pts) (nth 1 pts)))
            (setq length (* (/ (RMR:PathLength pts) k) 1000.0))
            (setq mid (RMR:Mid2D (nth 0 pts) (nth 1 pts)))
            (RMR:RotText (RMR:PT+ mid 0.0 (* 2.0 s))
              (strcat size "  |  " (RMR:Num (/ length 1000.0) 2) " m")
              (* 2.2 s) "RMR-LABEL" "RMR-P-ANNO" *RMR-BRAND-TEAL* angle)
            (RMR:FlowArrow (nth (1- (length pts)) pts)
                           (angle (nth (- (length pts) 2) pts)
                                  (nth (1- (length pts)) pts))
                           (* 2.6 s) "RMR-E-DUCT" (RMR:BrandRGB (nth 3 spec)))
            (setq count (1+ count))
            (princ (strcat "\n  run " (itoa count) ": "
                           (RMR:Num (/ length 1000.0) 2) " m"))
          )
        )
        (setq pick (getpoint "\nNext duct start <finish>: "))
      )
      (princ (strcat "\n" (itoa count) " duct runs drawn at " size "."))
    )
    (princ "\nUnknown duct size.")
  )
  (princ)
)

;;; --- pipework --------------------------------------------------------------------------
(defun C:RMR-PIPE (/ keys size spec k slope pick pts count left right inner
                 angle mid s)
  (RMR:EnsureReady)
  (setq keys (RMR:KeywordList *RMR-PIPE-SPECS*))
  (setq size (RMR:PromptKeyword "Pipe size" keys (nth 0 (nth 0 *RMR-PIPE-SPECS*))))
  (setq spec (RMR:TableSpec size *RMR-PIPE-SPECS*))
  (if spec
    (progn
      (setq k (RMR:PromptReal "Drawing units per metre" 1.0))
      (setq slope (RMR:PromptReal "Fall, 1 in" 80.0))
      (setq s (RMR:Scaled 1.0))
      (setq count 0)
      (princ (strcat "\nDrawing " size " mm pipework at 1:" (RMR:Num slope 0)
                     " fall. Pick the route."))
      (setq pick (getpoint "\nPipe start: "))
      (while pick
        (setq pts (list (list (car pick) (cadr pick) 0.0)))
        (setq pick (getpoint (nth 0 pts) "\nNext point <finish>: "))
        (while pick
          (setq pts (append pts (list (list (car pick) (cadr pick) 0.0))))
          (setq pick (getpoint (nth (1- (length pts)) pts) "\nNext point <finish>: "))
        )
        (if (> (length pts) 1)
          (progn
            (setq left (RMR:OffsetPath pts (/ (RMR:Mm (nth 1 spec) k) 2.0)))
            (setq right (RMR:OffsetPath pts (- (/ (RMR:Mm (nth 1 spec) k) 2.0))))
            (setq inner (RMR:ClosedPoly
                          (append left (reverse right))
                          "RMR-E-PIPE" (RMR:BrandRGB (nth 2 spec))))
            (if inner (RMR:HatchEntity inner "ANSI31" (RMR:BrandRGB (nth 2 spec))))
            (RMR:PolyLine left nil nil "RMR-E-PIPE" *RMR-BRAND-INK*)
            (RMR:PolyLine right nil nil "RMR-E-PIPE" *RMR-BRAND-INK*)
            (setq angle (angle (nth 0 pts) (nth 1 pts)))
            (setq mid (RMR:Mid2D (nth 0 pts) (nth 1 pts)))
            (RMR:RotText (RMR:PT+ mid 0.0 (* 2.0 s))
              (strcat "0" size " mm  1:" (RMR:Num slope 0) " FALL  |  "
                      (RMR:Num (/ (* (RMR:PathLength pts) 1000.0) k) 2) " m")
              (* 2.2 s) "RMR-LABEL" "RMR-P-ANNO" *RMR-BRAND-BLUE* angle)
            (RMR:FlowArrow (nth (1- (length pts)) pts)
                           (angle (nth (- (length pts) 2) pts)
                                  (nth (1- (length pts)) pts))
                           (* 2.4 s) "RMR-E-PIPE" (RMR:BrandRGB (nth 2 spec)))
            (setq count (1+ count))
          )
        )
        (setq pick (getpoint "\nNext pipe start <finish>: "))
      )
      (princ (strcat "\n" (itoa count) " pipe runs drawn at " size " mm."))
    )
    (princ "\nUnknown pipe size.")
  )
  (princ)
)

;;; --- cable containment -------------------------------------------------------------------
(defun C:RMR-TRAY (/ width rung k pick pts left right count step dist index
                 point angle s mid)
  (RMR:EnsureReady)
  (setq width (RMR:PromptReal "Tray width in mm" 300.0))
  (setq rung (RMR:PromptReal "Rung spacing in mm" 300.0))
  (setq k (RMR:PromptReal "Drawing units per metre" 1.0))
  (setq s (RMR:Scaled 1.0))
  (setq count 0)
  (princ (strcat "\nDrawing " (RMR:Num width 0)
                 " mm cable tray. Pick the route."))
  (setq pick (getpoint "\nTray start: "))
  (while pick
    (setq pts (list (list (car pick) (cadr pick) 0.0)))
    (setq pick (getpoint (nth 0 pts) "\nNext point <finish>: "))
    (while pick
      (setq pts (append pts (list (list (car pick) (cadr pick) 0.0))))
      (setq pick (getpoint (nth (1- (length pts)) pts) "\nNext point <finish>: "))
    )
    (if (> (length pts) 1)
      (progn
        (setq left (RMR:OffsetPath pts (/ (RMR:Mm width k) 2.0)))
        (setq right (RMR:OffsetPath pts (- (/ (RMR:Mm width k) 2.0))))
        (RMR:PolyLine left nil nil "RMR-E-TRAY" *RMR-BRAND-GOLD*)
        (RMR:PolyLine right nil nil "RMR-E-TRAY" *RMR-BRAND-GOLD*)
        ;; rungs walked along each segment at the spacing given
        (setq index 0)
        (while (< index (1- (length pts)))
          (setq point (nth index pts))
          (setq angle (angle point (nth (1+ index) pts)))
          (setq dist (distance point (nth (1+ index) pts)))
          (setq step (RMR:Mm rung k))
          (while (< step dist)
            (setq mid (polar point angle step))
            (RMR:Rung mid angle (/ (RMR:Mm width k) 2.0) 0.0
                      "RMR-E-TRAY" *RMR-BRAND-GOLD*)
            (setq step (+ step (RMR:Mm rung k)))
          )
          (setq index (1+ index))
        )
        (setq mid (RMR:Mid2D (nth 0 pts) (nth 1 pts)))
        (RMR:RotText (RMR:PT+ mid 0.0 (* 2.0 s))
          (strcat "CABLE TRAY " (RMR:Num width 0))
          (* 2.2 s) "RMR-LABEL" "RMR-P-ANNO" *RMR-BRAND-GOLD*
          (angle (nth 0 pts) (nth 1 pts)))
        (setq count (1+ count))
        (princ (strcat "\n  run " (itoa count) ": "
                       (RMR:Num (/ (* (RMR:PathLength pts) 1000.0) k) 2) " m"))
      )
    )
    (setq pick (getpoint "\nNext tray start <finish>: "))
  )
  (princ (strcat "\n" (itoa count) " tray runs drawn."))
  (princ)
)

;;; --- lighting layout ----------------------------------------------------------------------
(defun C:RMR-LIGHTING (/ c1 c2 sx sy circuit k s x0 x1 y0 y1 nx ny ix iy
                     index cx cy base rows count watts)
  (RMR:EnsureReady)
  (setq c1 (getpoint "\nFirst corner of the lit area: "))
  (if c1
    (progn
      (setq c2 (getcorner c1 "\nOpposite corner: "))
      (if c2
        (progn
          (setq k (RMR:PromptReal "Drawing units per metre" 1.0))
          (setq sx (RMR:PromptReal "Spacing across in mm" 2400.0))
          (setq sy (RMR:PromptReal "Spacing down in mm" 2400.0))
          (setq circuit (strcase (RMR:PromptText "Circuit letter" "A")))
          (setq watts (RMR:PromptReal "Watts per luminaire" 18.0))
          (setq s (RMR:Scaled 1.0))
          (setq x0 (min (car c1) (car c2)))
          (setq x1 (max (car c1) (car c2)))
          (setq y0 (min (cadr c1) (cadr c2)))
          (setq y1 (max (cadr c1) (cadr c2)))
          (RMR:Rect (list x0 y0 0.0) (- x1 x0) (- y1 y0) "RMR-E-LIGHT"
                    *RMR-BRAND-SLATE*)
          (setq nx (max 1 (fix (+ 0.5 (/ (- x1 x0) (RMR:Mm sx k))))))
          (setq ny (max 1 (fix (+ 0.5 (/ (- y1 y0) (RMR:Mm sy k))))))
          (setq index 0)
          (setq rows '())
          (setq ix 0)
          (while (< ix nx)
            (setq iy 0)
            (while (< iy ny)
              (setq cx (+ x0 (* (RMR:Mm sx k) (+ ix 0.5))))
              (setq cy (+ y0 (* (RMR:Mm sy k) (+ iy 0.5))))
              (if (and (< cx x1) (< cy y1))
                (progn
                  (setq index (1+ index))
                  (RMR:Rect (RMR:PT+ (list cx cy 0.0) (- (* 1.6 s)) (- (* 1.6 s)))
                            (* 3.2 s) (* 3.2 s) "RMR-E-LIGHT" *RMR-BRAND-GOLD*)
                  (RMR:Line (RMR:PT+ (list cx cy 0.0) (- (* 1.6 s)) (- (* 1.6 s)))
                            (RMR:PT+ (list cx cy 0.0) (* 1.6 s) (* 1.6 s))
                            "RMR-E-LIGHT" *RMR-BRAND-GOLD*)
                  (RMR:Text (RMR:PT+ (list cx cy 0.0) (* 2.2 s) (* 0.8 s))
                            (strcat circuit (itoa index)) (* 2.0 s) "RMR-NUMBER"
                            "RMR-P-ANNO" *RMR-BRAND-INK*)
                  (setq rows (append rows
                               (list (list (strcat circuit (itoa index))
                                           (RMR:Num watts 0)
                                           (strcat "CCT " circuit)))))
                )
              )
              (setq iy (1+ iy))
            )
            (setq ix (1+ ix))
          )
          ;; the switch, drawn at the corner the area was picked from
          (RMR:Circle (RMR:PT+ (list x0 y0 0.0) (- (* 3.0 s)) (- (* 3.0 s)))
                      (* 1.6 s) "RMR-E-POWER" *RMR-BRAND-GOLD*)
          (RMR:Line (RMR:PT+ (list x0 y0 0.0) (- (* 3.0 s)) (- (* 3.0 s)))
                    (RMR:PT+ (list x0 y0 0.0) (- (* 1.4 s)) (- (* 4.6 s)))
                    "RMR-E-POWER" *RMR-BRAND-GOLD*)
          (RMR:Text (RMR:PT+ (list x0 y0 0.0) (- (* 3.0 s)) (- (* 8.0 s)))
                    (strcat "S/" circuit) (* 2.0 s) "RMR-LABEL" "RMR-P-ANNO"
                    *RMR-BRAND-INK*)
          (RMR:Text (list x0 (- y0 (* 5.0 s)) 0.0)
                    (strcat (itoa index) " LUMINAIRES  |  CIRCUIT " circuit
                            "  |  " (RMR:Num (/ (* index watts) 1000.0) 2)
                            " kW  |  " (RMR:Num sx 0) " x " (RMR:Num sy 0)
                            " mm GRID")
                    (* 2.4 s) "RMR-LABEL" "RMR-A-TEXT" *RMR-BRAND-TERRA*)
          (setq base (getpoint "\nTop-left of the lighting schedule <enter to skip>: "))
          (if base
            (RMR:DocTable base "LIGHTING SCHEDULE  |  RMR-LIGHTING"
                          (strcat (itoa index) " luminaires on circuit "
                                  circuit)
                          '("TAG" "WATTS" "CIRCUIT")
                          (list (* 22.0 s) (* 24.0 s) (* 28.0 s))
                          rows nil s)
          )
          (princ (strcat "\n" (itoa index) " luminaires placed."))
        )
      )
    )
  )
  (princ)
)

;;; --- sprinkler layout -----------------------------------------------------------------------
(defun C:RMR-SPRINKLER (/ c1 c2 spacing cover k s x0 x1 y0 y1 nx ny ix iy
                      index cx cy count area)
  (RMR:EnsureReady)
  (setq c1 (getpoint "\nFirst corner of the protected area: "))
  (if c1
    (progn
      (setq c2 (getcorner c1 "\nOpposite corner: "))
      (if c2
        (progn
          (setq k (RMR:PromptReal "Drawing units per metre" 1.0))
          (setq spacing (RMR:PromptReal "Head spacing in mm" 3000.0))
          (setq cover (RMR:PromptReal "Coverage radius in mm" 2100.0))
          (setq s (RMR:Scaled 1.0))
          (setq x0 (min (car c1) (car c2)))
          (setq x1 (max (car c1) (car c2)))
          (setq y0 (min (cadr c1) (cadr c2)))
          (setq y1 (max (cadr c1) (cadr c2)))
          (RMR:Rect (list x0 y0 0.0) (- x1 x0) (- y1 y0) "RMR-E-SPRINK"
                    *RMR-BRAND-SLATE*)
          (setq nx (max 1 (fix (+ 0.5 (/ (- x1 x0) (RMR:Mm spacing k))))))
          (setq ny (max 1 (fix (+ 0.5 (/ (- y1 y0) (RMR:Mm spacing k))))))
          (setq index 0)
          (setq ix 0)
          (while (< ix nx)
            (setq iy 0)
            (while (< iy ny)
              (setq cx (+ x0 (* (RMR:Mm spacing k) (+ ix 0.5))))
              (setq cy (+ y0 (* (RMR:Mm spacing k) (+ iy 0.5))))
              (if (and (< cx x1) (< cy y1))
                (progn
                  (setq index (1+ index))
                  (RMR:Circle (list cx cy 0.0) (RMR:Mm cover k)
                              "RMR-E-SPRINK" *RMR-BRAND-SAND*)
                  (RMR:Circle (list cx cy 0.0) (* 1.1 s) "RMR-E-SPRINK"
                              *RMR-BRAND-TERRA*)
                  (RMR:Line (RMR:PT+ (list cx cy 0.0) (- (* 1.8 s)) 0.0)
                            (RMR:PT+ (list cx cy 0.0) (* 1.8 s) 0.0)
                            "RMR-E-SPRINK" *RMR-BRAND-TERRA*)
                  (RMR:Line (RMR:PT+ (list cx cy 0.0) 0.0 (- (* 1.8 s)))
                            (RMR:PT+ (list cx cy 0.0) 0.0 (* 1.8 s))
                            "RMR-E-SPRINK" *RMR-BRAND-TERRA*)
                  (RMR:Text (RMR:PT+ (list cx cy 0.0) (* 2.0 s) (* 0.8 s))
                            (strcat "S" (RMR:NumPad2 index)) (* 1.8 s)
                            "RMR-MARK" "RMR-P-ANNO" *RMR-BRAND-SLATE*)
                )
              )
              (setq iy (1+ iy))
            )
            (setq ix (1+ ix))
          )
          (setq area (/ (* (- x1 x0) (- y1 y0)) (* k k)))
          (RMR:Text (list x0 (- y0 (* 5.0 s)) 0.0)
                    (strcat (itoa index) " HEADS  |  "
                            (RMR:Num spacing 0) " mm GRID  |  "
                            (RMR:Num cover 0) " mm COVER  |  "
                            (RMR:Num area 1) " m2 PROTECTED")
                    (* 2.4 s) "RMR-LABEL" "RMR-A-TEXT" *RMR-BRAND-TERRA*)
          (princ (strcat "\n" (itoa index) " sprinkler heads over "
                         (RMR:Num area 1) " m2."))
        )
      )
    )
  )
  (princ)
)

;;; --- services schedule ------------------------------------------------------------------------
(defun C:RMR-MEPSCHED (/ layers rows base s total answer path lines)
  (RMR:EnsureReady)
  (setq layers '("RMR-E-DUCT" "RMR-E-GRILLE" "RMR-E-PIPE" "RMR-E-EQUIP"
                 "RMR-E-POWER" "RMR-E-LIGHT" "RMR-E-TRAY" "RMR-E-DATA"
                 "RMR-E-SPRINK" "RMR-P-SUPPLY" "RMR-P-DRAIN" "RMR-P-FIXTURE"))
  (setq rows (RMR:CountByLayer layers))
  (setq s (RMR:Scaled 1.0))
  (setq total 0)
  (foreach row rows (setq total (+ total (nth 2 row))))
  (princ (strcat "\nServices elements in the drawing: " (itoa total)))
  (foreach row rows
    (if (> (nth 2 row) 0)
      (princ (strcat "\n  " (nth 0 row) "  " (itoa (nth 2 row))))
    )
  )
  (setq base (getpoint "\nTop-left of the services schedule <enter to skip>: "))
  (if base
    (RMR:DocTable base "SERVICES SCHEDULE  |  RMR-MEPSCHED"
                  (strcat (itoa total) " elements  |  counted from the drawing")
                  '("LAYER" "DESCRIPTION" "COUNT")
                  (list (* 34.0 s) (* 86.0 s) (* 22.0 s))
                  (mapcar '(lambda (row)
                             (list (nth 0 row) (RMR:Shorten (nth 1 row) 40)
                                   (itoa (nth 2 row))))
                          rows)
                  nil s)
  )
  (setq answer (RMR:PromptYesNo "Write a services schedule report" "No"))
  (if (RMR:YesP answer)
    (progn
      (setq path (getfiled "Save the services schedule"
                           "RooMNRooF_Services_Schedule.txt" "txt" 1))
      (if path
        (progn
          (setq lines (list "RooMNRooF SERVICES SCHEDULE"
                            (strcat "Project: " (RMR:ProjectValue "PROJECT" ""))
                            (strcat "Date: " (RMR:TodayDate))
                            ""
                            "LAYER                 DESCRIPTION                              COUNT"))
          (foreach row rows
            (setq lines (append lines
                          (list (strcat "  " (nth 0 row) "  "
                                        (RMR:Shorten (nth 1 row) 40)
                                        "  " (itoa (nth 2 row))))))
          )
          (setq lines (append lines (list "" (strcat "TOTAL  " (itoa total)))))
          (if (RMR:WriteLines path lines)
            (princ (strcat "\nWritten: " path))
            (princ "\nCould not write the report.")
          )
        )
      )
    )
  )
  (princ)
)

;;; --- vertical clearance coordination -----------------------------------------------------------
(defun C:RMR-CLEARANCE (/ base s wide zone height total y rgb conflicts
                     byzone pair layer count names answer path lines
                     verdict found item)
  (RMR:EnsureReady)
  (setq s (RMR:Scaled 1.0))
  (setq wide (* 150.0 s))
  (setq base (getpoint "\nTop-left of the service zone diagram: "))
  (if base
    (progn
      (setq total (RMR:ZoneTop))
      (RMR:Text base "VERTICAL SERVICE ZONES  |  RMR-CLEARANCE"
                (* 4.2 s) "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-TERRA*)
      (RMR:Text (list (car base) (- (cadr base) (* 5.0 s)) 0.0)
                (strcat (itoa (length *RMR-SERVICE-ZONES*))
                        " zones  |  structural zone to "
                        (RMR:Num total 0) " mm")
                (* 2.2 s) "RMR-NOTE" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
      (setq y (- (cadr base) (* 14.0 s)))
      ;; bands stack downwards from the ceiling zone at the top
      (foreach zone (reverse *RMR-SERVICE-ZONES*)
        (setq height (* 90.0 s (/ (- (float (nth 2 zone)) (float (nth 1 zone)))
                                  (if (> total 0.0) total 1.0))))
        (setq rgb (RMR:BrandRGB (nth 3 zone)))
        (RMR:Solid (list (car base) (- y height) 0.0) wide height
                   "RMR-M-FILL" rgb)
        (RMR:Rect (list (car base) (- y height) 0.0) wide height
                  "RMR-A-FRAME" *RMR-BRAND-SLATE*)
        (RMR:Text (list (+ (car base) (* 3.0 s)) (- y (* height 0.55)) 0.0)
                  (nth 0 zone) (* 2.4 s) "RMR-LABEL" "RMR-A-TEXT"
                  *RMR-BRAND-INK*)
        (RMR:Text (list (+ (car base) (* 3.0 s)) (- y (* height 0.85)) 0.0)
                  (nth 4 zone) (* 1.9 s) "RMR-NOTE" "RMR-A-TEXT"
                  *RMR-BRAND-SLATE*)
        (RMR:Text (list (+ (car base) wide (* 3.0 s)) (- y (* height 0.6)) 0.0)
                  (strcat (RMR:Num (float (nth 1 zone)) 0) " - "
                          (RMR:Num (float (nth 2 zone)) 0) " mm")
                  (* 2.1 s) "RMR-NUMBER" "RMR-A-TEXT" *RMR-BRAND-INK*)
        (setq y (- y height))
      )
      ;; group every services layer that carries geometry by its zone
      (setq byzone '())
      (foreach pair *RMR-SERVICE-LAYER-ZONES*
        (setq layer (nth 0 pair))
        (setq zone (nth 1 pair))
        (setq count (RMR:LayerCount layer))
        (if (> count 0)
          (progn
            (setq found nil)
            (foreach item byzone
              (if (= (nth 0 item) zone) (setq found T))
            )
            (if (not found) (setq byzone (append byzone (list (list zone)))))
            (setq byzone
              (mapcar '(lambda (item)
                         (if (= (nth 0 item) zone)
                           (append item (list layer))
                           item))
                      byzone))
          )
        )
      )
      (setq conflicts '())
      (foreach item byzone
        (if (> (length item) 2)
          (setq conflicts
            (append conflicts
              (list (strcat (nth 0 item) " carries "
                            (itoa (- (length item) 1))
                            " services - coordinate: "
                            (RMR:Shorten
                              (apply 'strcat
                                (mapcar '(lambda (name) (strcat name " "))
                                        (cdr item)))
                              44)))))
        )
      )
      (setq verdict (if conflicts "REVIEW" "PASS"))
      (RMR:Text (list (car base) (- y (* 8.0 s)) 0.0)
                (strcat "VERDICT: " verdict "  |  "
                        (itoa (length conflicts)) " shared zones")
                (* 2.8 s) "RMR-HEAD" "RMR-A-TEXT"
                (if conflicts *RMR-BRAND-TERRA* *RMR-BRAND-TEAL*))
      (setq y (- y (* 14.0 s)))
      (if conflicts
        (progn
          (RMR:Text (list (car base) y 0.0) "Shared zones to coordinate:"
                    (* 2.2 s) "RMR-LABEL" "RMR-A-TEXT" *RMR-BRAND-INK*)
          (setq y (- y (* 5.0 s)))
          (foreach item conflicts
            (RMR:Text (list (car base) y 0.0) (strcat "  " item) (* 2.0 s)
                      "RMR-BODY" "RMR-A-TEXT" *RMR-BRAND-TERRA*)
            (setq y (- y (* 4.6 s)))
          )
        )
        (RMR:Text (list (car base) y 0.0)
                  "No zone carries more than one service." (* 2.2 s)
                  "RMR-LABEL" "RMR-A-TEXT" *RMR-BRAND-TEAL*)
      )
      (setq answer (RMR:PromptYesNo "Write a clearance report" "No"))
      (if (RMR:YesP answer)
        (progn
          (setq path (getfiled "Save the clearance report"
                               "RooMNRooF_Clearance.txt" "txt" 1))
          (if path
            (progn
              (setq lines (list "RooMNRooF VERTICAL CLEARANCE REPORT"
                                (strcat "Project: " (RMR:ProjectValue "PROJECT" ""))
                                (strcat "Date: " (RMR:TodayDate))
                                ""
                                "SERVICE ZONES"))
              (foreach zone *RMR-SERVICE-ZONES*
                (setq lines (append lines
                              (list (strcat "  " (nth 0 zone) "  "
                                            (itoa (nth 1 zone)) " - "
                                            (itoa (nth 2 zone)) " mm  "
                                            (nth 4 zone)))))
              )
              (setq lines (append lines (list "" "OCCUPANCY")))
              (foreach item byzone
                (setq lines (append lines
                              (list (strcat "  " (nth 0 item) ": "
                                            (itoa (- (length item) 1))
                                            " services"))))
              )
              (setq lines (append lines (list "" "SHARED ZONES")))
              (if conflicts
                (foreach item conflicts
                  (setq lines (append lines (list (strcat "  " item))))
                )
                (setq lines (append lines (list "  none")))
              )
              (setq lines (append lines (list ""
                                              (strcat "Verdict: " verdict))))
              (if (RMR:WriteLines path lines)
                (princ (strcat "\nWritten: " path))
                (princ "\nCould not write the report.")
              )
            )
          )
        )
      )
      (princ (strcat "\nClearance check: " verdict ", "
                     (itoa (length conflicts)) " shared zones."))
    )
  )
  (princ)
)


;;; =====================================================================
;;; PRO 12.0 CONSTRUCTION DETAILING SUITE
;;; A detail library, a parametric junction builder built from the
;;; construction build-up tables, detail tags with a running counter,
;;; locator plans, continuous dimension chains, a materials key, a
;;; detail scale bar, a complete A1 detail sheet, a specification link
;;; block, the detail index, a U value calculator, fire compartment
;;; lines, acoustic ratings and a detail compliance check.
;;; =====================================================================

;;; --- detail library -------------------------------------------------------------
;;; (Number Title Scale Category)
(setq *RMR-DETAIL-SPECS*
 '(
    ("D01" "Eaves, roof to external wall"        "1:5"  "ROOF")
    ("D02" "Parapet, roof over external wall"    "1:5"  "ROOF")
    ("D03" "Verge, roof to gable wall"           "1:5"  "ROOF")
    ("D04" "Threshold, floor to external wall"   "1:5"  "FLOOR")
    ("D05" "Balcony threshold and upstand"       "1:5"  "FLOOR")
    ("D06" "Intermediate floor to internal wall" "1:10" "FLOOR")
    ("D07" "External corner, wall to wall"       "1:10" "WALL")
    ("D08" "Party wall to party wall junction"   "1:10" "WALL")
    ("D09" "Window head and reveal"              "1:5"  "OPENING")
    ("D10" "Window cill and cavity tray"         "1:5"  "OPENING")
    ("D11" "External door threshold"             "1:5"  "OPENING")
    ("D12" "Roof abutment to parapet upstand"    "1:5"  "ROOF")
  )
)

;;; Junction types: (Type Category LegA LegB Description)
;;; LegA and LegB name a type in *RMR-BUILDUP-SPECS*.
(setq *RMR-JUNCTION-SPECS*
 '(
    ("EAVES"     "ROOF"  "ROOF"    "EXTWALL" "Eaves, roof meeting the external wall")
    ("PARAPET"   "ROOF"  "ROOF"    "EXTWALL" "Parapet, roof upstand over the wall")
    ("THRESHOLD" "FLOOR" "FLOOR"   "EXTWALL" "Threshold, floor meeting the external wall")
    ("CORNER"    "WALL"  "EXTWALL" "EXTWALL" "External corner, wall to wall")
    ("PARTY"     "WALL"  "INTWALL" "INTWALL" "Party wall junction")
    ("BALCONY"   "FLOOR" "FLOOR"   "INTWALL" "Balcony, floor meeting the internal wall")
  )
)

;;; Thermal properties: (Material Lambda_WmK Thickness_mm Note)
(setq *RMR-MATERIAL-R-SPECS*
 '(
    ("FACING BRICK"   0.770 102 "Facing brickwork, 102mm")
    ("BLOCKWORK"      0.190 100 "Dense concrete blockwork")
    ("PIR INSULATION" 0.022 100 "Rigid PIR insulation board")
    ("MINERAL WOOL"   0.035 100 "Mineral wool quilt")
    ("PLASTERBOARD"   0.250  13 "12.5mm gypsum plasterboard")
    ("SCREED"         0.410  65 "Cement and sand screed")
    ("CONCRETE"       1.130 200 "Reinforced concrete slab")
    ("RENDER"         0.500  15 "Cement and sand render")
  )
)

;;; Fire ratings: (Rating Minutes ColourKey Note)
(setq *RMR-FIRE-SPECS*
 '(
    ("NFR"     0 "SLATE" "No fire rating required")
    ("FD30"   30 "TERRA" "Half hour fire resisting")
    ("FD60"   60 "TERRA" "One hour fire resisting")
    ("FD90"   90 "GOLD"  "Ninety minute fire resisting")
    ("FD120" 120 "GOLD"  "Two hour fire resisting")
  )
)

;;; Acoustic ratings: (Rating Rw_dB Note)
(setq *RMR-ACOUSTIC-SPECS*
 '(
    ("Rw 38" 38 "Internal partition, room to room")
    ("Rw 43" 43 "Internal partition, quiet to noisy")
    ("Rw 48" 48 "Party wall, dwelling to dwelling")
    ("Rw 53" 53 "Party floor, dwelling to dwelling")
    ("Rw 58" 58 "Plant room enclosure")
  )
)

;;; Session counter for the detail tagger.
(if (not *RMR-DETAIL-N*) (setq *RMR-DETAIL-N* 0))

;;; --- shared detailing helpers -----------------------------------------------------
(defun RMR:LayerR (spec)
  ;; Thermal resistance of one layer: thickness in metres over lambda.
  (/ (/ (float (nth 2 spec)) 1000.0) (float (nth 1 spec)))
)

(defun RMR:RSum (rows / total spec)
  (setq total 0.0)
  (foreach spec rows (setq total (+ total (RMR:LayerR spec))))
  total
)

(defun RMR:UValue (rows / r)
  ;; U = 1 / (Rsi + sum R + Rse), with Rsi 0.13 and Rse 0.04.
  (setq r (+ 0.17 (RMR:RSum rows)))
  (if (> r 0.0) (/ 1.0 r) 0.0)
)

(defun RMR:DetailFrame (p width height number title scale s / bar)
  ;; A captioned detail frame: picture area above, caption bar below.
  (setq bar (* 11.0 s))
  (RMR:Rect (list (car p) (+ (cadr p) bar) 0.0) width height
            "RMR-A-DETAIL" *RMR-BRAND-SLATE*)
  (RMR:Solid p width bar "RMR-PRES-TITLE" *RMR-BRAND-TERRA*)
  (RMR:Rect p width bar "RMR-A-FRAME" *RMR-BRAND-INK*)
  (RMR:Text (list (+ (car p) (* 2.0 s)) (+ (cadr p) (* 3.4 s)) 0.0)
            number (* 3.4 s) "RMR-NUMBER" "RMR-PRES-TITLE" *RMR-BRAND-SAND*)
  (RMR:Text (list (+ (car p) (* 14.0 s)) (+ (cadr p) (* 3.2 s)) 0.0)
            (RMR:Shorten title 44) (* 2.6 s) "RMR-HEAD" "RMR-PRES-TITLE"
            *RMR-BRAND-SAND*)
  (RMR:Text (list (- (+ (car p) width) (* 16.0 s)) (+ (cadr p) (* 3.2 s)) 0.0)
            scale (* 2.6 s) "RMR-NUMBER" "RMR-PRES-TITLE" *RMR-BRAND-SAND*)
  bar
)

(defun RMR:WitnessTicks (pts offset size layer rgb / index point normal pt1 pt2)
  ;; Short witness ticks standing off a chain of measured points.
  (setq index 0)
  (while (< index (length pts))
    (setq point (nth index pts))
    (if (< index (1- (length pts)))
      (setq normal (angle point (nth (1+ index) pts)))
    )
    (setq pt1 (polar point (+ normal (* 0.5 pi)) offset))
    (setq pt2 (polar point (+ normal (* 0.5 pi)) (+ offset size)))
    (RMR:Line pt1 pt2 layer rgb)
    (setq index (1+ index))
  )
)

(defun RMR:DetailCategories (/ out spec name)
  (setq out '())
  (foreach spec *RMR-DETAIL-SPECS*
    (setq name (nth 3 spec))
    (if (not (RMR:InList name out)) (setq out (append out (list name))))
  )
  out
)

(defun RMR:FireBand (p1 p2 width rgb / normal a b c d)
  ;; A band of a given true width drawn along a picked line.
  (setq normal (+ (angle p1 p2) (* 0.5 pi)))
  (setq a (polar p1 normal (/ width 2.0)))
  (setq b (polar p2 normal (/ width 2.0)))
  (setq c (polar p2 (- normal pi) (/ width 2.0)))
  (setq d (polar p1 (- normal pi) (/ width 2.0)))
  (RMR:Quad a b c d "RMR-A-FIRE" rgb)
  (RMR:Line a b "RMR-A-FIRE" *RMR-BRAND-INK*)
  (RMR:Line c d "RMR-A-FIRE" *RMR-BRAND-INK*)
)

;;; --- detail library sheet -----------------------------------------------------------
(defun C:RMR-DETAILLIB (/ base s cols count spec index col row fw fh gx gy
                     origin bar)
  (RMR:EnsureReady)
  (setq base (getpoint "\nTop-left of the detail library: "))
  (if base
    (progn
      (setq s (RMR:Scaled 1.0))
      (setq cols (RMR:PromptInt "Frames across" 3))
      (setq fw (* 250.0 s))
      (setq fh (* 120.0 s))
      (setq gx (* 14.0 s))
      (setq gy (* 16.0 s))
      (setq index 0)
      (setq count 0)
      (foreach spec *RMR-DETAIL-SPECS*
        (setq col (rem index cols))
        (setq row (/ index cols))
        (setq origin (list (+ (car base) (* col (+ fw gx)))
                           (- (cadr base) (* row (+ fh gy (* 11.0 s))))
                           0.0))
        (setq bar (RMR:DetailFrame origin fw fh (nth 0 spec) (nth 1 spec)
                                   (nth 2 spec) s))
        ;; a placeholder cross so an empty frame still reads as a frame
        (RMR:Line (list (car origin) (+ (cadr origin) bar) 0.0)
                  (list (+ (car origin) fw) (+ (cadr origin) bar fh) 0.0)
                  "RMR-A-DETAIL" *RMR-BRAND-SAND*)
        (RMR:Line (list (car origin) (+ (cadr origin) bar fh) 0.0)
                  (list (+ (car origin) fw) (+ (cadr origin) bar) 0.0)
                  "RMR-A-DETAIL" *RMR-BRAND-SAND*)
        (setq count (1+ count))
        (setq index (1+ index))
      )
      (princ (strcat "\n" (itoa count) " detail frames drawn across "
                     (itoa (length (RMR:DetailCategories)))
                     " categories."))
      (foreach spec (RMR:DetailCategories)
        (princ (strcat "\n  " spec))
      )
    )
  )
  (princ)
)

;;; --- parametric junction builder -------------------------------------------------------
(defun C:RMR-JUNCTION (/ keys type spec lega legb rowsa rowsb k s corner
                     count y x thk rgb pattern name note totala totalb
                     leglen labx laby ename)
  (RMR:EnsureReady)
  (setq keys (RMR:KeywordList *RMR-JUNCTION-SPECS*))
  (setq type (RMR:PromptKeyword "Junction" keys
                                (nth 0 (nth 0 *RMR-JUNCTION-SPECS*))))
  (setq spec (RMR:TableSpec type *RMR-JUNCTION-SPECS*))
  (if spec
    (progn
      (setq rowsa (RMR:BuildupRows (nth 2 spec)))
      (setq rowsb (RMR:BuildupRows (nth 3 spec)))
      (if (and rowsa rowsb)
        (progn
          (setq k (RMR:PromptReal "Drawing units per metre" 1.0))
          (setq s (RMR:Scaled 1.0))
          (setq corner (getpoint "\nPick the inside corner of the junction: "))
          (if corner
            (progn
              (setq corner (list (car corner) (cadr corner) 0.0))
              (setq leglen (* 2.4 (RMR:Scaled 1.0)))
              ;; leg A: the horizontal element, layers stacked downwards
              (setq totala 0.0)
              (foreach spec rowsa (setq totala (+ totala (float (nth 3 spec)))))
              (setq y (cadr corner))
              (setq count 0)
              (foreach spec rowsa
                (setq thk (RMR:Mm (nth 3 spec) k))
                (setq rgb (nth 4 spec))
                (setq pattern (nth 5 spec))
                (setq name (nth 2 spec))
                (setq note (nth 6 spec))
                (setq ename (RMR:ClosedPoly
                              (list (list (- (car corner) leglen) (- y thk))
                                    (list (car corner) (- y thk))
                                    (list (car corner) y)
                                    (list (- (car corner) leglen) y))
                              "RMR-M-HATCH" rgb))
                (if ename (RMR:HatchEntity ename pattern rgb))
                (RMR:Rect (list (- (car corner) leglen) (- y thk) 0.0)
                          leglen thk "RMR-A-DETAIL" *RMR-BRAND-INK*)
                (RMR:Text (list (+ (car corner) (* 3.0 s)) (- y (/ thk 2.0)) 0.0)
                          (strcat name "  " (itoa (nth 3 spec)) " mm")
                          (* 2.0 s) "RMR-NOTE" "RMR-A-TEXT" *RMR-BRAND-INK*)
                (setq y (- y thk))
                (setq count (1+ count))
              )
              ;; leg B: the vertical element, layers stacked to the right
              (setq totalb 0.0)
              (foreach spec rowsb (setq totalb (+ totalb (float (nth 3 spec)))))
              (setq x (car corner))
              (foreach spec rowsb
                (setq thk (RMR:Mm (nth 3 spec) k))
                (setq rgb (nth 4 spec))
                (setq pattern (nth 5 spec))
                (setq name (nth 2 spec))
                (setq ename (RMR:ClosedPoly
                              (list (list x (- (cadr corner) leglen))
                                    (list (+ x thk) (- (cadr corner) leglen))
                                    (list (+ x thk) (cadr corner))
                                    (list x (cadr corner)))
                              "RMR-M-HATCH" rgb))
                (if ename (RMR:HatchEntity ename pattern rgb))
                (RMR:Rect (list x (- (cadr corner) leglen) 0.0) thk leglen
                          "RMR-A-DETAIL" *RMR-BRAND-INK*)
                (RMR:RotText (list (+ x (/ thk 2.0))
                                   (- (cadr corner) leglen (* 3.0 s)) 0.0)
                             (strcat name "  " (itoa (nth 3 spec)) " mm")
                             (* 2.0 s) "RMR-NOTE" "RMR-A-TEXT"
                             *RMR-BRAND-INK* (* 0.5 pi))
                (setq x (+ x thk))
              )
              ;; caption block underneath the junction
              (setq laby (- (cadr corner) leglen (* 10.0 s)))
              (RMR:Text (list (car corner) laby 0.0)
                        (strcat type "  |  " (nth 4 spec)) (* 3.0 s)
                        "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-TERRA*)
              (RMR:Text (list (car corner) (- laby (* 5.0 s)) 0.0)
                        (strcat (nth 2 spec) " " (RMR:Num totala 0)
                                " mm total  |  " (nth 3 spec) " "
                                (RMR:Num totalb 0) " mm total")
                        (* 2.2 s) "RMR-NOTE" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
              (princ (strcat "\n" type " drawn: " (itoa (length rowsa))
                             " + " (itoa (length rowsb)) " layers."))
            )
          )
        )
        (princ "\nThat junction needs two build-up types that both exist.")
      )
    )
    (princ "\nUnknown junction type.")
  )
  (princ)
)

;;; --- detail tag -------------------------------------------------------------------------
(defun C:RMR-DETAILTAG (/ keys number spec pick point tip s radius sheet)
  (RMR:EnsureReady)
  (setq keys (RMR:KeywordList *RMR-DETAIL-SPECS*))
  (setq number (RMR:PromptKeyword
                 "Detail number"
                 (strcat keys " Next")
                 "Next"))
  (if (= (strcase number) "NEXT")
    (progn
      (setq *RMR-DETAIL-N* (1+ *RMR-DETAIL-N*))
      (setq number (strcat "D" (RMR:NumPad2 *RMR-DETAIL-N*)))
    )
  )
  (setq spec (RMR:TableSpec number *RMR-DETAIL-SPECS*))
  (setq s (RMR:Scaled 1.0))
  (setq radius (* 4.6 s))
  (setq sheet (RMR:PromptText "Sheet the detail is drawn on" "A-500"))
  (princ "\nPick the point the detail refers to, then the bubble position.")
  (setq pick (getpoint "\nPoint of interest: "))
  (while pick
    (setq point (list (car pick) (cadr pick) 0.0))
    (setq tip (getpoint point "\nBubble position: "))
    (if tip
      (progn
        (setq tip (list (car tip) (cadr tip) 0.0))
        (RMR:Line point tip "RMR-A-DETAIL" *RMR-BRAND-TERRA*)
        (RMR:Circle point (* 1.0 s) "RMR-A-DETAIL" *RMR-BRAND-TERRA*)
        (RMR:Circle tip radius "RMR-PRES-KEY" *RMR-BRAND-TERRA*)
        (RMR:CenterText tip number radius "RMR-NUMBER" "RMR-A-DETAIL"
                        *RMR-BRAND-INK*)
        (RMR:Text (RMR:PT+ tip (* 1.6 s) (- (* 9.0 s)))
                  (strcat "SEE SHEET " sheet) (* 2.0 s) "RMR-NOTE"
                  "RMR-A-TEXT" *RMR-BRAND-SLATE*)
        (if spec
          (RMR:Text (RMR:PT+ tip (* 1.6 s) (- (* 13.0 s)))
                    (RMR:Shorten (nth 1 spec) 40) (* 2.0 s) "RMR-BODY"
                    "RMR-A-TEXT" *RMR-BRAND-INK*)
        )
      )
    )
    (setq pick (getpoint "\nNext point of interest <finish>: "))
  )
  (princ (strcat "\nDetail tags drawn. Next free number is D"
                 (RMR:NumPad2 (1+ *RMR-DETAIL-N*)) "."))
  (princ)
)

;;; --- detail locator -----------------------------------------------------------------------
(defun C:RMR-DETLOC (/ c1 c2 pick number s cx cy w h mx my)
  (RMR:EnsureReady)
  (setq c1 (getpoint "\nFirst corner of the locator plan: "))
  (if c1
    (progn
      (setq c2 (getcorner c1 "\nOpposite corner: "))
      (if c2
        (progn
          (setq s (RMR:Scaled 1.0))
          (setq number (strcase (RMR:PromptText "Detail number" "D01")))
          (setq cx (min (car c1) (car c2)))
          (setq cy (min (cadr c1) (cadr c2)))
          (setq w (- (max (car c1) (car c2)) cx))
          (setq h (- (max (cadr c1) (cadr c2)) cy))
          (RMR:Rect (list cx cy 0.0) w h "RMR-A-DETAIL" *RMR-BRAND-SLATE*)
          ;; a light setting-out grid inside the locator
          (setq mx (+ cx (/ w 3.0)))
          (while (< mx (+ cx w))
            (RMR:Line (list mx cy 0.0) (list mx (+ cy h) 0.0)
                      "RMR-00-REF" *RMR-BRAND-SAND*)
            (setq mx (+ mx (/ w 3.0)))
          )
          (setq my (+ cy (/ h 3.0)))
          (while (< my (+ cy h))
            (RMR:Line (list cx my 0.0) (list (+ cx w) my 0.0)
                      "RMR-00-REF" *RMR-BRAND-SAND*)
            (setq my (+ my (/ h 3.0)))
          )
          (setq pick (getpoint "\nPick the detail location inside the plan: "))
          (if pick
            (progn
              (setq pick (list (car pick) (cadr pick) 0.0))
              (RMR:Circle pick (* 3.4 s) "RMR-A-DETAIL" *RMR-BRAND-GOLD*)
              (RMR:Line (RMR:PT+ pick (* 2.4 s) (* 2.4 s))
                        (RMR:PT+ pick (* 8.0 s) (* 8.0 s))
                        "RMR-A-DETAIL" *RMR-BRAND-GOLD*)
              (RMR:Line (RMR:PT+ pick (* 8.0 s) (* 8.0 s))
                        (RMR:PT+ pick (* 22.0 s) (* 8.0 s))
                        "RMR-A-DETAIL" *RMR-BRAND-GOLD*)
              (RMR:Text (RMR:PT+ pick (* 23.0 s) (* 6.4 s))
                        (strcat number " LOCATED HERE") (* 2.2 s) "RMR-LABEL"
                        "RMR-A-TEXT" *RMR-BRAND-GOLD*)
            )
          )
          (RMR:Text (list cx (- cy (* 5.0 s)) 0.0)
                    (strcat "LOCATOR PLAN  |  DETAIL " number)
                    (* 2.4 s) "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-TERRA*)
          (princ (strcat "\nLocator drawn for " number "."))
        )
      )
    )
  )
  (princ)
)

;;; --- continuous dimension chain -------------------------------------------------------------
(defun C:RMR-DIMCHAIN (/ s offset pick pts point text size tick total index
                    p1 p2 mid ang)
  (RMR:EnsureReady)
  (setq s (RMR:Scaled 1.0))
  (setq offset (RMR:PromptReal "Dimension line offset" (* 12.0 s)))
  (princ "\nPick the points to chain, Enter when finished.")
  (setq pts '())
  (setq pick (getpoint "\nFirst point: "))
  (while pick
    (setq pts (append pts (list (list (car pick) (cadr pick) 0.0))))
    (setq pick (getpoint "\nNext point <finish>: "))
  )
  (if (> (length pts) 1)
    (progn
      (setq size (* 3.0 s))
      (setq total 0.0)
      (setq index 0)
      (while (< index (1- (length pts)))
        (setq p1 (nth index pts))
        (setq p2 (nth (1+ index) pts))
        (setq ang (angle p1 p2))
        (setq mid (RMR:Mid2D p1 p2))
        ;; the dimension line, offset to the left of the chain direction
        (RMR:Line (polar p1 (+ ang (* 0.5 pi)) offset)
                  (polar p2 (+ ang (* 0.5 pi)) offset)
                  "RMR-A-DIMS" *RMR-BRAND-INK*)
        (RMR:RotText (polar mid (+ ang (* 0.5 pi)) (+ offset (* 1.6 s)))
                     (RMR:Num (distance p1 p2) 0) (* 2.2 s) "RMR-NUMBER"
                     "RMR-A-DIMS" *RMR-BRAND-INK* ang)
        (setq total (+ total (distance p1 p2)))
        (setq index (1+ index))
      )
      (RMR:WitnessTicks pts (- offset size) size "RMR-A-DIMS" *RMR-BRAND-INK*)
      (RMR:Text (list (car (nth 0 pts)) (- (cadr (nth 0 pts)) (* 8.0 s)) 0.0)
                (strcat (itoa (1- (length pts)))
                        " DIMENSIONS  |  CHAIN " (RMR:Num total 0))
                (* 2.2 s) "RMR-LABEL" "RMR-A-TEXT" *RMR-BRAND-TERRA*)
      (princ (strcat "\n" (itoa (1- (length pts))) " dimensions, chain "
                     (RMR:Num total 0) "."))
    )
    (princ "\nA chain needs at least two points.")
  )
  (princ)
)

;;; --- materials key ---------------------------------------------------------------------------
(defun C:RMR-MATKEY (/ keys base s rows spec y swatch name)
  (RMR:EnsureReady)
  (setq keys "")
  (foreach name (RMR:BuildupTypes)
    (setq keys (strcat keys (if (> (strlen keys) 0) " ") name))
  )
  (setq name (RMR:PromptKeyword "Build-up for the key" keys
                                (nth 0 (RMR:BuildupTypes))))
  (setq rows (RMR:BuildupRows name))
  (setq base (getpoint "\nTop-left of the materials key: "))
  (if (and rows base)
    (progn
      (setq s (RMR:Scaled 1.0))
      (setq y (cadr base))
      (RMR:Text base (strcat "MATERIALS KEY  |  " name) (* 3.4 s) "RMR-HEAD"
                "RMR-A-TEXT" *RMR-BRAND-TERRA*)
      (setq y (- y (* 8.0 s)))
      (foreach spec rows
        (setq swatch (* 5.0 s))
        (RMR:Solid (list (car base) (- y swatch) 0.0) swatch swatch
                   "RMR-M-HATCH" (nth 4 spec))
        (RMR:Rect (list (car base) (- y swatch) 0.0) swatch swatch
                  "RMR-A-FRAME" *RMR-BRAND-INK*)
        (RMR:Text (list (+ (car base) (* 8.0 s)) y 0.0)
                  (nth 2 spec) (* 2.2 s) "RMR-LABEL" "RMR-A-TEXT"
                  *RMR-BRAND-INK*)
        (RMR:Text (list (+ (car base) (* 60.0 s)) y 0.0)
                  (strcat (itoa (nth 3 spec)) " mm") (* 2.2 s) "RMR-NUMBER"
                  "RMR-A-TEXT" *RMR-BRAND-TERRA*)
        (RMR:Text (list (+ (car base) (* 78.0 s)) y 0.0)
                  (RMR:Shorten (nth 6 spec) 40) (* 2.0 s) "RMR-NOTE"
                  "RMR-A-TEXT" *RMR-BRAND-SLATE*)
        (setq y (- y (* 7.0 s)))
      )
      (RMR:Text (list (car base) (- y (* 3.0 s)) 0.0)
                (strcat (itoa (length rows)) " materials  |  pattern "
                        (nth 5 (nth 0 rows)) " upward")
                (* 2.2 s) "RMR-NOTE" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
      (princ (strcat "\nMaterials key drawn for " name "."))
    )
  )
  (princ)
)

;;; --- detail scale and scale bar -----------------------------------------------------------------
(defun C:RMR-DETSCALE (/ keys scale spec base s seg mm unit bar y index)
  (RMR:EnsureReady)
  (setq keys (RMR:KeywordList *RMR-SCALE-SPECS*))
  (setq scale (RMR:PromptKeyword "Detail scale" keys "20"))
  (setq spec (RMR:TableSpec scale *RMR-SCALE-SPECS*))
  (if spec
    (progn
      (setq *RMR-DRAW-SCALE-LABEL* (nth 1 spec))
      (setq *RMR-ANNO-SPACE* "MODEL")
      (setq *RMR-ANNO-SCALE* (float (nth 2 spec)))
      (RMR:SafeSet "DIMSCALE" (float (nth 2 spec)))
      (RMR:SafeSet "CELTSCALE" 1.0)
      (RMR:SafeSet "MSLTSCALE" 1)
      (RMR:SafeSet "PSLTSCALE" 1)
      (RMR:SafeSet "LTSCALE" 1.0)
      (princ (strcat "\nDetail scale set to " (nth 1 spec) "."))
      (setq base (getpoint "\nPick the left end of the scale bar <enter to skip>: "))
      (if base
        (progn
          (setq s (RMR:Scaled 1.0))
          ;; a detail bar works in 100 mm steps at 1:20 and coarser
          (setq mm (if (<= (float (nth 2 spec)) 20.0) 100.0 500.0))
          (setq seg 4)
          (setq unit (RMR:Mm mm 1.0))
          (setq bar (* 9.0 s))
          (setq y (cadr base))
          (setq index 0)
          (while (< index seg)
            (if (= (rem index 2) 0)
              (RMR:Solid (list (+ (car base) (* index unit)) y 0.0) unit bar
                         "RMR-A-DIMS" *RMR-BRAND-INK*)
              (RMR:Solid (list (+ (car base) (* index unit)) y 0.0) unit bar
                         "RMR-A-DIMS" *RMR-BRAND-SAND*)
            )
            (setq index (1+ index))
          )
          (RMR:Rect (list (car base) y 0.0) (* seg unit) bar "RMR-A-FRAME"
                    *RMR-BRAND-INK*)
          (RMR:Text (list (car base) (- y (* 5.0 s)) 0.0) "0" (* 2.0 s)
                    "RMR-NUMBER" "RMR-A-TEXT" *RMR-BRAND-INK*)
          (RMR:Text (RMR:PT+ base (* seg unit) (- (* 5.0 s)))
                    (strcat (RMR:Num (* seg mm) 0) " mm") (* 2.0 s)
                    "RMR-NUMBER" "RMR-A-TEXT" *RMR-BRAND-INK*)
          (RMR:Text (list (car base) (+ y (* bar) (* 3.0 s)) 0.0)
                    (strcat "SCALE " (nth 1 spec) " AT A1") (* 2.4 s)
                    "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-TERRA*)
          (princ (strcat "\nScale bar drawn at " (nth 1 spec) "."))
        )
      )
    )
    (princ "\nUnknown detail scale.")
  )
  (princ)
)

;;; --- complete detail sheet ------------------------------------------------------------------------
(defun C:RMR-DETSHEET (/ base size s wide high frame rows spec index col row
                    fw fh gx gy origin bar count y key)
  (RMR:EnsureReady)
  (setq base (getpoint "\nBottom-left of the detail sheet: "))
  (if base
    (progn
      (setq size (RMR:SheetSize "A1"))
      (setq wide (nth 0 size))
      (setq high (nth 1 size))
      (setq s (RMR:Scaled 1.0))
      (setq base (list (car base) (cadr base) 0.0))
      (RMR:Rect base wide high "RMR-A-FRAME" *RMR-BRAND-INK*)
      (RMR:Rect (list (+ (car base) (* 10.0 s)) (+ (cadr base) (* 10.0 s)) 0.0)
                (- wide (* 20.0 s)) (- high (* 20.0 s))
                "RMR-A-FRAME" *RMR-BRAND-TEAL*)
      ;; six detail frames in two rows of three
      (setq fw (* 250.0 s))
      (setq fh (* 150.0 s))
      (setq gx (* 12.0 s))
      (setq gy (* 30.0 s))
      (setq count 0)
      (setq index 0)
      (foreach spec *RMR-DETAIL-SPECS*
        (if (< index 6)
          (progn
            (setq col (rem index 3))
            (setq row (/ index 3))
            (setq origin (list (+ (car base) (* 24.0 s) (* col (+ fw gx)))
                               (+ (cadr base) (* 150.0 s)
                                  (* (- 1 row) (+ fh gy (* 11.0 s))))
                               0.0))
            (setq bar (RMR:DetailFrame origin fw fh (nth 0 spec) (nth 1 spec)
                                       (nth 2 spec) s))
            (RMR:Line (list (car origin) (+ (cadr origin) bar) 0.0)
                      (list (+ (car origin) fw) (+ (cadr origin) bar fh) 0.0)
                      "RMR-A-DETAIL" *RMR-BRAND-SAND*)
            (RMR:Line (list (car origin) (+ (cadr origin) bar fh) 0.0)
                      (list (+ (car origin) fw) (+ (cadr origin) bar) 0.0)
                      "RMR-A-DETAIL" *RMR-BRAND-SAND*)
            (setq count (1+ count))
          )
        )
        (setq index (1+ index))
      )
      ;; masthead and the detail index down the right hand side
      (RMR:Solid (list (+ (car base) (* 10.0 s))
                       (+ (cadr base) high (* -10.0 s) (* -44.0 s)) 0.0)
                 (- wide (* 20.0 s)) (* 44.0 s) "RMR-PRES-TITLE"
                 *RMR-BRAND-TERRA*)
      (RMR:Text (list (+ (car base) (* 24.0 s))
                      (+ (cadr base) high (* -10.0 s) (* -30.0 s)) 0.0)
                "CONSTRUCTION DETAILS  |  RooMNRooF" (* 8.0 s) "RMR-TITLE"
                "RMR-PRES-TITLE" *RMR-BRAND-SAND*)
      (RMR:Text (list (+ (car base) (* 24.0 s))
                      (+ (cadr base) high (* -10.0 s) (* -38.0 s)) 0.0)
                (strcat "Project " (RMR:ProjectValue "PROJECT" "")
                        "  |  " (RMR:Num (length *RMR-DETAIL-SPECS*))
                        " details  |  scale as labelled")
                (* 2.6 s) "RMR-HEAD" "RMR-PRES-TITLE" *RMR-BRAND-SAND*)
      ;; detail index, listed at the bottom left
      (setq y (+ (cadr base) (* 96.0 s)))
      (RMR:Text (list (+ (car base) (* 24.0 s)) y 0.0) "DETAIL INDEX"
                (* 3.0 s) "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-TERRA*)
      (setq y (- y (* 7.0 s)))
      (setq index 0)
      (foreach spec *RMR-DETAIL-SPECS*
        (if (< index 6)
          (progn
            (RMR:Text (list (+ (car base) (* 24.0 s)) y 0.0)
                      (strcat (nth 0 spec) "  " (RMR:Shorten (nth 1 spec) 40)
                              "  " (nth 2 spec) "  " (nth 3 spec))
                      (* 2.2 s) "RMR-BODY" "RMR-A-TEXT" *RMR-BRAND-INK*)
            (setq y (- y (* 5.0 s)))
          )
        )
        (setq index (1+ index))
      )
      (RMR:Text (list (+ (car base) wide (* -24.0 s)) (+ (cadr base) (* 30.0 s)) 0.0)
                "MATERIALS KEY: SEE RMR-MATKEY  |  SPECIFICATION: RMR-SPECLINK"
                (* 2.2 s) "RMR-NOTE" "RMR-A-TEXT" *RMR-BRAND-SLATE*)
      (princ (strcat "\nDetail sheet laid out with " (itoa count)
                     " frames and the detail index."))
    )
  )
  (princ)
)

;;; --- specification link ----------------------------------------------------------------------------
(defun C:RMR-SPECLINK (/ number keys code spec base s rows y answer)
  (RMR:EnsureReady)
  (setq number (strcase (RMR:PromptText "Detail number" "D01")))
  (setq keys (RMR:KeywordList *RMR-SPEC-CLAUSES*))
  (setq s (RMR:Scaled 1.0))
  (setq rows '())
  (setq answer (RMR:PromptKeyword "Add a clause" (strcat keys " Done") "Done"))
  (while (not (= (strcase answer) "DONE"))
    (setq spec (RMR:TableSpec answer *RMR-SPEC-CLAUSES*))
    (if spec
      (setq rows (append rows
                   (list (list (nth 0 spec) (nth 2 spec)
                               (RMR:Shorten (nth 3 spec) 58)))))
    )
    (setq answer (RMR:PromptKeyword "Add a clause" (strcat keys " Done")
                                    "Done"))
  )
  (if rows
    (progn
      (setq base (getpoint "\nTop-left of the specification link block: "))
      (if base
        (progn
          (setq y (cadr base))
          (RMR:Solid base (* 150.0 s) (* 9.0 s) "RMR-PRES-TITLE"
                     *RMR-BRAND-TEAL*)
          (RMR:Text (list (+ (car base) (* 2.0 s)) (+ y (* 3.0 s)) 0.0)
                    (strcat "DETAIL " number "  |  REFER TO SPECIFICATION")
                    (* 2.6 s) "RMR-HEAD" "RMR-PRES-TITLE" *RMR-BRAND-SAND*)
          (setq y (- y (* 14.0 s)))
          (foreach spec rows
            (RMR:Text (list (car base) y 0.0)
                      (strcat "  " (nth 0 spec) "  " (nth 1 spec)) (* 2.2 s)
                      "RMR-LABEL" "RMR-A-TEXT" *RMR-BRAND-TERRA*)
            (RMR:Text (list (car base) (- y (* 4.4 s)) 0.0)
                      (strcat "    " (nth 2 spec)) (* 2.0 s) "RMR-BODY"
                      "RMR-A-TEXT" *RMR-BRAND-INK*)
            (setq y (- y (* 10.0 s)))
          )
          (princ (strcat "\n" (itoa (length rows)) " clauses linked to "
                         number "."))
        )
      )
    )
    (princ "\nNo clauses were picked.")
  )
  (princ)
)

;;; --- detail index ------------------------------------------------------------------------------------
(defun C:RMR-DETINDEX (/ base s rows sheet spec)
  (RMR:EnsureReady)
  (setq sheet (strcase (RMR:PromptText "Sheet number for the index" "A-500")))
  (setq rows '())
  (foreach spec *RMR-DETAIL-SPECS*
    (setq rows (append rows
                 (list (list (nth 0 spec) (RMR:Shorten (nth 1 spec) 42)
                             (nth 2 spec) (nth 3 spec) sheet))))
  )
  (setq s (RMR:Scaled 1.0))
  (setq base (getpoint "\nTop-left of the detail index <enter to skip>: "))
  (if base
    (RMR:DocTable base "DETAIL INDEX  |  RMR-DETINDEX"
                  (strcat (itoa (length rows)) " details on sheet " sheet)
                  '("NO" "TITLE" "SCALE" "CATEGORY" "SHEET")
                  (list (* 12.0 s) (* 78.0 s) (* 16.0 s) (* 24.0 s)
                        (* 18.0 s))
                  rows nil s)
  )
  (princ (strcat "\n" (itoa (length rows)) " details indexed on " sheet "."))
  (princ)
)

;;; --- U value calculator -------------------------------------------------------------------------------
(defun C:RMR-UVALUE (/ keys name spec rows base s y thick total u r answer
                  index path lines)
  (RMR:EnsureReady)
  (setq keys (RMR:KeywordList *RMR-MATERIAL-R-SPECS*))
  (setq rows '())
  (setq name "")
  (setq answer (RMR:PromptKeyword "Add a layer" (strcat keys " Done") "Done"))
  (while (not (= (strcase answer) "DONE"))
    (setq spec (RMR:TableSpec answer *RMR-MATERIAL-R-SPECS*))
    (if spec
      (progn
        (setq thick (RMR:PromptReal (strcat (nth 0 spec) " thickness in mm")
                                    (float (nth 2 spec))))
        (setq rows (append rows (list (list (nth 0 spec) (nth 1 spec) thick))))
        (princ (strcat "\n  " (nth 0 spec) "  " (RMR:Num thick 0)
                       " mm  R " (RMR:Num (RMR:LayerR
                                            (list (nth 0 spec) (nth 1 spec)
                                                  thick)) 3)))
      )
    )
    (setq answer (RMR:PromptKeyword "Add a layer" (strcat keys " Done")
                                    "Done"))
  )
  (if rows
    (progn
      (setq r (RMR:RSum rows))
      (setq u (RMR:UValue rows))
      (princ (strcat "\nTotal resistance R " (RMR:Num r 3)
                     " m2K/W  |  U value " (RMR:Num u 3) " W/m2K"))
      (setq base (getpoint "\nTop-left of the U value panel <enter to skip>: "))
      (if base
        (progn
          (setq s (RMR:Scaled 1.0))
          (setq y (cadr base))
          (RMR:Text base "THERMAL PERFORMANCE  |  RMR-UVALUE" (* 4.2 s)
                    "RMR-HEAD" "RMR-A-TEXT" *RMR-BRAND-TERRA*)
          (setq y (- y (* 8.0 s)))
          (setq thick 0.0)
          (setq index 0)
          (foreach spec rows
            (setq index (1+ index))
            (RMR:Solid (list (car base) (- y (* 6.0 s)) 0.0) (* 90.0 s)
                       (* 6.0 s) "RMR-M-FILL" *RMR-BRAND-SAND*)
            (RMR:Rect (list (car base) (- y (* 6.0 s)) 0.0) (* 90.0 s)
                      (* 6.0 s) "RMR-A-FRAME" *RMR-BRAND-SLATE*)
            (RMR:Text (list (+ (car base) (* 2.0 s)) y 0.0) (nth 0 spec)
                      (* 2.2 s) "RMR-LABEL" "RMR-A-TEXT" *RMR-BRAND-INK*)
            (RMR:Text (list (+ (car base) (* 96.0 s)) y 0.0)
                      (RMR:Num (float (nth 2 spec)) 0) (* 2.0 s) "RMR-NUMBER"
                      "RMR-A-TEXT" *RMR-BRAND-INK*)
            (RMR:Text (list (+ (car base) (* 112.0 s)) y 0.0)
                      (strcat "R " (RMR:Num (RMR:LayerR spec) 3)) (* 2.0 s)
                      "RMR-BODY" "RMR-A-TEXT" *RMR-BRAND-TEAL*)
            (setq thick (+ thick (float (nth 2 spec))))
            (setq y (- y (* 8.0 s)))
          )
          (RMR:Text (list (car base) (- y (* 2.0 s)) 0.0)
                    (strcat "TOTAL " (RMR:Num thick 0) " mm  |  R "
                            (RMR:Num r 3) " m2K/W") (* 2.6 s) "RMR-NUMBER"
                    "RMR-A-TEXT" *RMR-BRAND-TERRA*)
          (RMR:Text (list (car base) (- y (* 12.0 s)) 0.0)
                    (strcat "U = " (RMR:Num u 3) " W/m2K") (* 6.0 s)
                    "RMR-NUMBER" "RMR-A-TEXT" *RMR-BRAND-TEAL*)
          (RMR:Text (list (car base) (- y (* 19.0 s)) 0.0)
                    "Includes Rsi 0.13 and Rse 0.04" (* 2.0 s) "RMR-NOTE"
                    "RMR-A-TEXT" *RMR-BRAND-SLATE*)
        )
      )
      (setq answer (RMR:PromptYesNo "Write a U value report" "No"))
      (if (RMR:YesP answer)
        (progn
          (setq path (getfiled "Save the U value calculation"
                               "RooMNRooF_UValue.txt" "txt" 1))
          (if path
            (progn
              (setq lines (list "RooMNRooF U VALUE CALCULATION"
                                (strcat "Project: " (RMR:ProjectValue "PROJECT" ""))
                                (strcat "Date: " (RMR:TodayDate))
                                ""
                                "MATERIAL                  LAMBDA   THICKNESS   R"))
              (foreach spec rows
                (setq lines (append lines
                              (list (strcat "  " (nth 0 spec) "  "
                                            (RMR:Num (float (nth 1 spec)) 3)
                                            "  " (RMR:Num (float (nth 2 spec)) 0)
                                            " mm  "
                                            (RMR:Num (RMR:LayerR spec) 3)))))
              )
              (setq lines (append lines
                (list ""
                      (strcat "Total resistance R " (RMR:Num r 3) " m2K/W")
                      (strcat "U value            " (RMR:Num u 3) " W/m2K")
                      "Includes Rsi 0.13 and Rse 0.04")))
              (if (RMR:WriteLines path lines)
                (princ (strcat "\nWritten: " path))
                (princ "\nCould not write the report.")
              )
            )
          )
        )
      )
    )
    (princ "\nNo layers were added.")
  )
  (princ)
)

;;; --- fire compartment line ------------------------------------------------------------------------------
(defun C:RMR-FIRESTOP (/ keys rating spec width rgb pick p1 p2 s mid label
                    count length)
  (RMR:EnsureReady)
  (setq keys (RMR:KeywordList *RMR-FIRE-SPECS*))
  (setq rating (RMR:PromptKeyword "Fire rating" keys "FD60"))
  (setq spec (RMR:TableSpec rating *RMR-FIRE-SPECS*))
  (if spec
    (progn
      (setq s (RMR:Scaled 1.0))
      (setq width (* 3.0 s))
      (setq rgb (RMR:BrandRGB (nth 2 spec)))
      (setq count 0)
      (setq length 0.0)
      (princ "\nPick the compartment line, two points at a time.")
      (setq pick (getpoint "\nLine start <finish>: "))
      (while pick
        (setq p1 (list (car pick) (cadr pick) 0.0))
        (setq p2 (getpoint p1 "\nLine end: "))
        (if p2
          (progn
            (setq p2 (list (car p2) (cadr p2) 0.0))
            (RMR:FireBand p1 p2 width rgb)
            (setq mid (RMR:Mid2D p1 p2))
            (setq label (strcat rating "  " (nth 3 spec)))
            (RMR:RotText (RMR:PT+ mid 0.0 (* 6.0 s)) label (* 2.4 s)
                         "RMR-LABEL" "RMR-A-FIRE" *RMR-BRAND-INK*
                         (angle p1 p2))
            (setq length (+ length (distance p1 p2)))
            (setq count (1+ count))
          )
        )
        (setq pick (getpoint "\nNext line start <finish>: "))
      )
      (princ (strcat "\n" (itoa count) " compartment segments at " rating
                     ", " (RMR:Num length 2) " total."))
    )
    (princ "\nUnknown fire rating.")
  )
  (princ)
)

;;; --- acoustic rating -----------------------------------------------------------------------------------------
(defun C:RMR-ACOUSTIC (/ keys rating spec s pick p1 p2 mid base rows index)
  (RMR:EnsureReady)
  (setq keys (RMR:KeywordList *RMR-ACOUSTIC-SPECS*))
  (setq rating (RMR:PromptKeyword "Acoustic rating" keys "Rw 48"))
  (setq spec (RMR:TableSpec rating *RMR-ACOUSTIC-SPECS*))
  (if spec
    (progn
      (setq s (RMR:Scaled 1.0))
      (setq pick (getpoint "\nFirst end of the partition <finish>: "))
      (while pick
        (setq p1 (list (car pick) (cadr pick) 0.0))
        (setq p2 (getpoint p1 "\nOther end: "))
        (if p2
          (progn
            (setq p2 (list (car p2) (cadr p2) 0.0))
            (RMR:Line p1 p2 "RMR-A-ACOUSTIC" *RMR-BRAND-BLUE*)
            (setq mid (RMR:Mid2D p1 p2))
            (RMR:Circle mid (* 5.0 s) "RMR-A-ACOUSTIC" *RMR-BRAND-BLUE*)
            (RMR:CenterText mid rating (* 2.6 s) "RMR-NUMBER"
                            "RMR-A-ACOUSTIC" *RMR-BRAND-INK*)
            (RMR:RotText (RMR:PT+ mid 0.0 (* 8.0 s))
                         (RMR:Shorten (nth 2 spec) 40) (* 2.0 s) "RMR-NOTE"
                         "RMR-A-ACOUSTIC" *RMR-BRAND-SLATE* (angle p1 p2))
          )
        )
        (setq pick (getpoint "\nNext partition <finish>: "))
      )
      (setq base (getpoint "\nTop-left of the acoustic table <enter to skip>: "))
      (if base
        (progn
          (setq rows '())
          (foreach spec *RMR-ACOUSTIC-SPECS*
            (setq rows (append rows
                         (list (list (nth 0 spec) (itoa (nth 1 spec))
                                     (RMR:Shorten (nth 2 spec) 40)))))
          )
          (RMR:DocTable base "ACOUSTIC PERFORMANCE  |  RMR-ACOUSTIC"
                        "Ratings from *RMR-ACOUSTIC-SPECS*"
                        '("RATING" "Rw dB" "APPLICATION")
                        (list (* 20.0 s) (* 18.0 s) (* 82.0 s))
                        rows nil s)
        )
      )
      (princ (strcat "\nAcoustic markers drawn at " rating "."))
    )
    (princ "\nUnknown acoustic rating.")
  )
  (princ)
)

;;; --- detail compliance check -------------------------------------------------------------------------------------
(defun C:RMR-CHECKDETAIL (/ ss i ent data total problems verdict answer path
                     lines spec index found)
  (RMR:EnsureReady)
  (setq problems '())
  (setq total 0)
  (setq ss (ssget "_X" (list (cons 8 "RMR-A-DETAIL"))))
  (if ss
    (progn
      (setq i 0)
      (repeat (sslength ss)
        (setq ent (ssname ss i))
        (setq data (entget ent))
        (if (= (cdr (assoc 0 data)) "CIRCLE") (setq total (1+ total)))
        (setq i (1+ i))
      )
    )
  )
  (princ (strcat "\nRooMNRooF detail compliance check"))
  (princ (strcat "\n  " (itoa total) " detail markers on RMR-A-DETAIL"))
  (princ (strcat "\n  " (itoa (length *RMR-DETAIL-SPECS*))
                 " details in the library"))
  (if (< total 1)
    (setq problems (append problems
                     (list "No detail markers found - tag the details first.")))
  )
  (if (not *RMR-DRAW-SCALE-LABEL*)
    (setq problems (append problems
                     (list "No drawing scale set - run RMR-DETSCALE.")))
  )
  (setq index 0)
  (foreach spec *RMR-DETAIL-SPECS*
    (setq found nil)
    (if (and ss
             (ssget "_X" (list (cons 8 "RMR-A-DETAIL") (cons 0 "TEXT")
                               (cons 1 (nth 0 spec)))))
      (setq found T)
    )
    (if (not found) (setq index (1+ index)))
  )
  (if (> index 0)
    (setq problems (append problems
                     (list (strcat (itoa index)
                                   " library details are not tagged on any sheet."))))
  )
  (if (not (tblsearch "BLOCK" "RMR-TITLEBLOCK"))
    (setq problems (append problems
                     (list "No RMR-TITLEBLOCK in the drawing - run RMR-MASTER.")))
  )
  (setq verdict (if problems "REVIEW" "PASS"))
  (princ (strcat "\n  Verdict: " verdict))
  (foreach item problems
    (princ (strcat "\n    " item))
  )
  (setq answer (RMR:PromptYesNo "Write a detail check report" "No"))
  (if (RMR:YesP answer)
    (progn
      (setq path (getfiled "Save the detail check"
                           "RooMNRooF_Detail_Check.txt" "txt" 1))
      (if path
        (progn
          (setq lines (list "RooMNRooF DETAIL COMPLIANCE CHECK"
                            (strcat "Project: " (RMR:ProjectValue "PROJECT" ""))
                            (strcat "Date: " (RMR:TodayDate))
                            (strcat "Scale: "
                                    (if *RMR-DRAW-SCALE-LABEL*
                                      *RMR-DRAW-SCALE-LABEL* "not set"))
                            ""
                            (strcat "Detail markers: " (itoa total))
                            (strcat "Library details: "
                                    (itoa (length *RMR-DETAIL-SPECS*)))
                            ""
                            "DETAIL LIBRARY"))
          (foreach spec *RMR-DETAIL-SPECS*
            (setq lines (append lines
                          (list (strcat "  " (nth 0 spec) "  "
                                        (nth 1 spec) "  " (nth 2 spec)
                                        "  " (nth 3 spec)))))
          )
          (setq lines (append lines (list "" "PROBLEMS")))
          (if problems
            (foreach item problems
              (setq lines (append lines (list (strcat "  " item))))
            )
            (setq lines (append lines (list "  none")))
          )
          (setq lines (append lines
                        (list "" (strcat "Verdict: " verdict))))
          (if (RMR:WriteLines path lines)
            (princ (strcat "\nWritten: " path))
            (princ "\nCould not write the report.")
          )
        )
      )
    )
  )
  (princ)
)


(princ (strcat "\nRooMNRooF " *RMR-VERSION* " loaded | " (itoa (length *RMR-LAYER-SPECS*)) " layers, "
               (itoa (length *RMR-HATCH-SPECS*)) " materials, " (itoa (length *RMR-NOTES*)) " notes."))
(princ "\nStart with RMR-PRO-SETUP, then RMR-SCALE. Type RMR-PALETTE for the full command guide.")
(princ)
