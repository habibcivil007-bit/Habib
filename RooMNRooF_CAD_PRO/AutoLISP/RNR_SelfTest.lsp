;;; RNR_SelfTest.lsp - RNRL-SELFTEST: non-destructive installation check.
;;; Checks modules/commands are loaded and support files are found. Creates nothing in the drawing.
;;; Reports PASS only for checks that actually ran and succeeded.
(defun rnr:st-line (ok msg)
  (setq *rnr-st-pass* (+ *rnr-st-pass* (if ok 1 0))
        *rnr-st-fail* (+ *rnr-st-fail* (if ok 0 1)))
  (princ (strcat "\n  " (if ok "PASS  " "FAIL  ") msg)))

(defun c:RNRL-SELFTEST ( / cmds c f)
  (setq *rnr-st-pass* 0 *rnr-st-fail* 0)
  (princ (strcat "\n[RNR] Self-test  AutoCAD " (getvar "ACADVER") "  LISP folder: "
                 (if *RNR-DIR* *RNR-DIR* "?")))
  (rnr:st-line (= (type *RNR-LAYERS*) 'LIST)
               (strcat "Standards data loaded (" (itoa (if (listp *RNR-LAYERS*) (length *RNR-LAYERS*) 0)) " layers)"))
  (rnr:st-line (= (type *RNR-BARS*) 'LIST) "Rebar table loaded")
  (setq cmds '("RNRL-LAYERS" "RNRL-LA" "RNRL-ARCH" "RNRL-STRUCT" "RNRL-CIVIL" "RNRL-RCC" "RNRL-ANNO"
               "RNRL-THAW" "RNRL-COLORS" "RNRL-COLORAPPLY" "RNRL-BYLAYER" "RNRL-UNITS" "RNRL-GRID"
               "RNRL-WALL" "RNRL-DOOR" "RNRL-WINDOW" "RNRL-ROOM" "RNRL-COLUMN" "RNRL-BEAM" "RNRL-FOOTING"
               "RNRL-REBAR" "RNRL-BARWT" "RNRL-HATCH" "RNRL-INSERT" "RNRL-BLOCKLIST" "RNRL-STYLES"
               "RNRL-LEVEL" "RNRL-TAG" "RNRL-NORTH" "RNRL-QA" "RNRPLOT-BW" "RNRPLOT-COLOR" "RNRPLOT-GRAY"
               "RNRL-HELP"))
  (setq c 0)
  (foreach n cmds
    (if (not (eval (read (strcat "c:" n))))
      (princ (strcat "\n        missing command: " n))
      (setq c (1+ c))))
  (rnr:st-line (= c (length cmds)) (strcat "Commands defined: " (itoa c) "/" (itoa (length cmds))))
  (rnr:st-line (setq f (findfile "RooMNRooF.lin")) "RooMNRooF.lin on support path")
  (rnr:st-line (findfile "RNR_RCC.pat") "RNR_RCC.pat on support path")
  (rnr:st-line (findfile "RNR_BRICK.pat") "RNR_BRICK.pat on support path")
  (rnr:st-line (findfile "RNR_Layers.json") "Standards folder on support path")
  (princ (strcat "\n[RNR] Self-test: " (itoa *rnr-st-pass*) " PASS, " (itoa *rnr-st-fail*) " FAIL."))
  (if (> *rnr-st-fail* 0)
    (princ "\n[RNR] Fix: reinstall with Install.bat, or add the bundle Contents\\Hatch and Contents\\Standards folders to Options > Files > Support File Search Path."))
  (princ))
