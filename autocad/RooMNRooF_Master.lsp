;;; -----------------------------------------------------------------------------
;;; RooMNRooF Master 2D CAD Standard
;;; Version 5.0 DELIVERY SUITE | Metric | AutoCAD / AutoCAD LT with AutoLISP
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

   ;; 5. Leaders / arrows / annotation
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

   ;; 6. Presentation / plotting
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
(setq *RMR-VERSION* "5.0 DELIVERY SUITE")

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
    ((= (strcase keyword) "ANNOTATION") "ANNOTATION")
    ((= (strcase keyword) "PRESENTATION") "PRESENTATION")
    ((= (strcase keyword) "CONTROL") "CONTROL")
    (T nil)
  )
)

(defun RMR:GroupKeywords ()
  "Main Furniture Structural Plumbing Annotation Presentation Control"
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

(princ (strcat "\nRooMNRooF " *RMR-VERSION* " loaded | " (itoa (length *RMR-LAYER-SPECS*)) " layers, "
               (itoa (length *RMR-HATCH-SPECS*)) " materials, " (itoa (length *RMR-NOTES*)) " notes."))
(princ "\nStart with RMR-PRO-SETUP, then RMR-SCALE. Type RMR-PALETTE for the full command guide.")
(princ)
