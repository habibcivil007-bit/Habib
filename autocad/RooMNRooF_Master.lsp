;;; -----------------------------------------------------------------------------
;;; RooMNRooF Master 2D CAD Standard
;;; Version 1.0 | Metric | AutoCAD / AutoCAD LT with AutoLISP
;;;
;;; Purpose
;;;   Builds a complete, colour-led 2D consultant standard in the active drawing.
;;;   It creates named layers, true-colour brand palette, linetypes, text styles,
;;;   dimension styles, a custom leader arrow, a sheet frame and a legend.
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
;;;
;;; IMPORTANT
;;;   1. This is an AutoLISP source file. APPLOAD it in AutoCAD.
;;;   2. Run RMR-MASTER in a blank drawing before drawing production work.
;;;   3. All colours are true RGB colours. ACI 7 is retained as a fallback.
;;;   4. Edit the data tables below to add a personal/group palette. Existing
;;;      named styles are intentionally preserved when this file is run again.
;;;   5. Run RMR-SAVE-TEMPLATE after RMR-MASTER to save a reusable .DWT.
;;;
;;; Branding
;;;   Brand: RooMNRooF
;;;   Role:  Consultant 2D CAD standard
;;;   Palette: Ink / Terracotta / Teal / Gold / Sand / Blue
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
   ("RMR-A-FRAME"   "ANNOTATION" ( 31  42  51) "Continuous" 35 "Sheet frame and title block")
   ("RMR-A-DETAIL"  "ANNOTATION" (130  92 160) "Continuous" 18 "Detail markers")

   ;; 6. Presentation / plotting
   ("RMR-PRES-TITLE" "PRESENTATION" (198  93  72) "Continuous" 25 "Title block and brand")
   ("RMR-PRES-KEY"   "PRESENTATION" (214 163  76) "Continuous" 18 "Keynotes and numbered tags")
   ("RMR-PRES-NORTH" "PRESENTATION" ( 57 137 130) "Continuous" 18 "North arrows and orientation")
  )
)

;;; Text styles: (StyleName FontFile WidthFactor ObliqueAngle Description)
(setq *RMR-TEXT-STYLES*
 '(
   ("RMR-TITLE"  "arial.ttf" 0.92 0.0 "Bold-looking title style; uses Arial when available")
   ("RMR-HEAD"   "arial.ttf" 0.95 0.0 "Drawing headings and section labels")
   ("RMR-BODY"   "arial.ttf" 1.00 0.0 "General notes and dimensions")
   ("RMR-NOTE"   "arial.ttf" 0.95 0.0 "Small notes and technical references")
   ("RMR-NUMBER" "arial.ttf" 0.90 0.0 "Sheet, detail and revision numbers")
   ("RMR-MARK"   "romans.shx" 0.90 0.0 "Compact technical marker style")
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

(setq *RMR-BRAND-INK*       '(31 42 51))
(setq *RMR-BRAND-TERRA*     '(198 93 72))
(setq *RMR-BRAND-TEAL*      '(57 137 130))
(setq *RMR-BRAND-GOLD*      '(214 163 76))
(setq *RMR-BRAND-SAND*      '(238 225 201))
(setq *RMR-BRAND-BLUE*      '(47 116 181))
(setq *RMR-BRAND-SLATE*     '(86 104 116))

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
  (cond
    ((findfile requested) requested)
    ((and (= (strcase requested) "ARIAL.TTF") (findfile "Arial.ttf")) "Arial.ttf")
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

(defun RMR:EnsureTextStyle (spec / name font width oblique)
  (setq name (nth 0 spec))
  (setq font (RMR:FindFont (nth 1 spec)))
  (setq width (nth 2 spec))
  (setq oblique (nth 3 spec))
  ;; Existing styles are left intact so a personal font choice is not overwritten.
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
  )
)

(defun RMR:EnsureLayer (spec / name group rgb ltype lw description record ename data)
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
      (setq data (RMR:DXF 62 7 data))
      (setq data (RMR:DXF 420 (RMR:RGB->420 rgb) data))
      (setq data (RMR:DXF 6 ltype data))
      (setq data (RMR:DXF 370 lw data))
      (setq data (RMR:DXF 4 description data))
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
        (cons 4 description)
        (cons 290 (if (= (strcase name) "RMR-00-NPLT") 0 1))
      )
    )
  )
  name
)

;;; -----------------------------------------------------------------------------
;;; Arrow block and dimension styles
;;; -----------------------------------------------------------------------------

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
  (foreach spec *RMR-LAYER-SPECS*
    (RMR:EnsureLayer spec)
  )
  (foreach spec *RMR-DIMSTYLE-SPECS*
    (setq dim-result (vl-catch-all-apply 'RMR:EnsureDimStyle (list spec)))
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
    (princ "\nRooMNRooF: master standard ready. Current layer: RMR-M-WALL")
  )
  (princ "\nCommands: RMR-SETLAYER, RMR-LEGEND, RMR-SHEET, RMR-SAVE-TEMPLATE, RMR-PALETTE")
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
;;; Save the current standard as an AutoCAD template
;;; -----------------------------------------------------------------------------

(defun C:RMR-SAVE-TEMPLATE (/ path acad doc result)
  (if (not (tblsearch "LAYER" "RMR-M-WALL"))
    (C:RMR-MASTER)
  )
  (setq path (getfiled "Save RooMNRooF template" "RooMNRooF_Master.dwt" "dwt" 1))
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

(defun C:RMR-PALETTE (/ spec)
  (princ "\n-----------------------------------------------")
  (princ "\n RooMNRooF | Consultant 2D CAD Standard")
  (princ "\n-----------------------------------------------")
  (princ "\n 1  Main Theme      RMR-M-...")
  (princ "\n 2  Furniture       RMR-F-...")
  (princ "\n 3  Structural      RMR-S-...")
  (princ "\n 4  Plumbing        RMR-P-...")
  (princ "\n 5  Annotation      RMR-A-...  (leaders, arrows, text, dims)")
  (princ "\n 6  Presentation     RMR-PRES-... (title, keys, north)")
  (princ "\n")
  (princ "\nCommands:")
  (princ "\n RMR-MASTER       Build the complete standard")
  (princ "\n RMR-SETLAYER     Set a current layer by discipline")
  (princ "\n RMR-LEGEND       Place a true-colour layer legend")
  (princ "\n RMR-SHEET        Place an A0-A4 sheet and title block")
  (princ "\n RMR-SAVE-TEMPLATE Save an active drawing as .DWT")
  (princ "\n")
  (princ "\nTo add a personal palette, append a layer spec near the top:")
  (princ "\n (\"RMR-X-ITEM\" \"MY GROUP\" (R G B) \"Continuous\" 18 \"Description\")")
  (princ "\nThen run RMR-MASTER again.")
  (princ "\n")
  (princ)
)

(princ "\nRooMNRooF Master loaded. Type RMR-MASTER to build the standard.")
(princ)
