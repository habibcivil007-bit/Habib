;;; RNR_Plot.lsp - B&W safety mode aliases. The .NET plugin registers RNRPLOTBW / RNRPLOTCOLOR /
;;; RNRPLOTGRAY; these LISP commands provide the hyphenated names from the specification and a
;;; LISP-only fallback that assigns the plot style table and opens the PLOT dialog.
(defun rnr:net-command-p (name) (and (getcname name) T))

(defun rnr:set-ctb (ctb / lay)
  (setq lay (vla-get-ActiveLayout (rnr:doc)))
  (vl-catch-all-apply 'vla-RefreshPlotDeviceInfo (list lay))
  (if (vl-catch-all-error-p (vl-catch-all-apply 'vla-put-StyleSheet (list lay ctb)))
    (princ (strcat "\n[RNR] Plot style " ctb " not found."))
    (progn (vla-put-PlotWithLineweights lay :vlax-true)
           (vla-put-PlotWithPlotStyles lay :vlax-true)
           (princ (strcat "\n[RNR] Layout plot style set to " ctb " (lineweights on).")))))

(defun rnr:plot (netcmd ctb)
  (if (rnr:net-command-p netcmd)
    (vla-SendCommand (rnr:doc) (strcat netcmd " "))
    (progn (rnr:set-ctb ctb) (initdia) (command "_.PLOT")))
  (princ))

(defun c:RNRPLOT-BW () (rnr:plot "RNRPLOTBW" "monochrome.ctb"))
(defun c:RNRPLOT-COLOR () (rnr:plot "RNRPLOTCOLOR" "acad.ctb"))
(defun c:RNRPLOT-GRAY () (rnr:plot "RNRPLOTGRAY" "grayscale.ctb"))

(defun c:RNRL-HELP ()
  (princ "\nRooMNRooF AutoLISP commands:")
  (princ "\n  RNRL-LAYERS RNRL-LA RNRL-ARCH RNRL-STRUCT RNRL-CIVIL RNRL-RCC RNRL-ANNO RNRL-THAW")
  (princ "\n  RNRL-COLORS RNRL-COLORAPPLY RNRL-BYLAYER RNRL-UNITS RNRL-GRID")
  (princ "\n  RNRL-WALL RNRL-DOOR RNRL-WINDOW RNRL-ROOM RNRL-COLUMN RNRL-BEAM RNRL-FOOTING")
  (princ "\n  RNRL-REBAR RNRL-BARWT RNRL-HATCH RNRL-INSERT RNRL-BLOCKLIST RNRL-STYLES RNRL-LEVEL RNRL-TAG RNRL-NORTH")
  (princ "\n  RNRL-QA RNRPLOT-BW RNRPLOT-COLOR RNRPLOT-GRAY")
  (princ "\n.NET commands: type RNR")
  (princ))
(princ)
