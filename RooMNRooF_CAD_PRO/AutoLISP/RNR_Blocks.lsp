;;; RNR_Blocks.lsp - block insertion helpers (block definitions are created by the .NET RNRBLOCKS
;;; command or found as DWG files on the support path, e.g. Blocks\*.dwg)
(defun rnr:block-available-p (name)
  (or (tblsearch "BLOCK" name) (findfile (strcat name ".dwg"))))

(defun c:RNRL-INSERT ( / name p)
  (rnr:start '("CMDECHO" "ATTREQ" "ATTDIA"))
  (setvar "CMDECHO" 0) (setvar "ATTREQ" 1) (setvar "ATTDIA" 0)
  (setq name (strcase (rnr:getstr "Block name (e.g. RNR_TOILET, RNR_BED_DOUBLE)" "RNR_CHAIR")))
  (if (rnr:block-available-p name)
    (while (setq p (getpoint (strcat "\nInsertion point for " name " <done>: ")))
      (command "_.-INSERT" name p 1 1 0)
      (while (> (getvar "CMDACTIVE") 0) (command "")))
    (princ (strcat "\n[RNR] Block " name " not defined. Run RNRBLOCKS (.NET) first.")))
  (rnr:end) (princ))

(defun c:RNRL-BLOCKLIST ( / b)
  (setq b (tblnext "BLOCK" T))
  (while b
    (if (wcmatch (cdr (assoc 2 b)) "RNR_*") (princ (strcat "\n  " (cdr (assoc 2 b)))))
    (setq b (tblnext "BLOCK")))
  (princ))
(princ)
