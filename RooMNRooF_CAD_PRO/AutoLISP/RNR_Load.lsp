;;; ======================================================================
;;; RNR_Load.lsp  -  RooMNRooF CAD PRO ULTIMATE AutoLISP loader
;;; Loads every RNR_*.lsp module from the folder this file lives in.
;;; Usage: APPLOAD this file, or it is autoloaded by the .bundle
;;;        (PackageContents.xml, LoadOnAutoCADStartup="True").
;;; ======================================================================
(vl-load-com)

(defun rnr:this-dir (/ f)
  ;; folder of RNR_Load.lsp: support path first, then the standard bundle locations
  (cond
    ((setq f (findfile "RNR_Load.lsp")) (vl-filename-directory f))
    ((setq f (findfile (strcat (getenv "APPDATA")
               "\\Autodesk\\ApplicationPlugins\\RooMNRooF.bundle\\Contents\\AutoLISP\\RNR_Load.lsp")))
     (vl-filename-directory f))
    ((setq f (findfile (strcat (getenv "ProgramData")
               "\\Autodesk\\ApplicationPlugins\\RooMNRooF.bundle\\Contents\\AutoLISP\\RNR_Load.lsp")))
     (vl-filename-directory f))
    (T (getvar "DWGPREFIX"))))

(setq *RNR-DIR* (rnr:this-dir))
(setq *RNR-VERSION* "2.0.0")

(defun rnr:load-module (name / path)
  (setq path (strcat *RNR-DIR* "\\" name ".lsp"))
  (cond
    ((not (findfile path)) (princ (strcat "\n[RNR] Module missing: " name)) nil)
    ((vl-catch-all-error-p (vl-catch-all-apply 'load (list path)))
     (princ (strcat "\n[RNR] Error loading module: " name)) nil)
    (T T)))

(foreach m '("RNR_Data" "RNR_Utilities" "RNR_Layers" "RNR_Colors" "RNR_Units" "RNR_Grid"
             "RNR_Architecture" "RNR_Structural" "RNR_Rebar" "RNR_Hatch" "RNR_Blocks"
             "RNR_Annotation" "RNR_QA" "RNR_Plot")
  (rnr:load-module m))

(princ (strcat "\n[RNR] RooMNRooF AutoLISP " *RNR-VERSION* " loaded. Type RNRL-HELP for LISP commands."))
(princ)
