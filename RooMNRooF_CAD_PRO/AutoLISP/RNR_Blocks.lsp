;;; RNR_Blocks.lsp - block insertion helpers (RNR block definitions come from RNR_BlockDefs.lsp,
;;; the .NET RNRBLOCKS command, or NAME.dwg files on the support path)
(defun rnr:block-available-p (name)
  ;; existing definition, built-in RNR definition (RNR_BlockDefs.lsp) or NAME.dwg on the support path
  (or (tblsearch "BLOCK" name)
      (and rnr:define-block (rnr:define-block name))
      (findfile (strcat name ".dwg"))))

(defun c:RNRL-INSERT ( / name p lay)
  (rnr:start '("CMDECHO" "ATTREQ" "ATTDIA" "CLAYER"))
  (setvar "CMDECHO" 0) (setvar "ATTREQ" 1) (setvar "ATTDIA" 0)
  (setq name (strcase (rnr:getstr "Block name (e.g. RNR_TOILET, RNR_BED_DOUBLE)" "RNR_CHAIR")))
  (if (rnr:block-available-p name)
    (progn
     (setq lay (if rnr:block-layer (rnr:block-layer name) "0"))
     (if (and (/= lay "0") (tblsearch "LAYER" lay)) (setvar "CLAYER" lay))
     (while (setq p (getpoint (strcat "\nInsertion point for " name " <done>: ")))
      (command "_.-INSERT" name p 1 1 0)
      (while (> (getvar "CMDACTIVE") 0) (command ""))))
    (princ (strcat "\n[RNR] Unknown block " name ". Type RNRL-BLOCKLIST for the RNR block names.")))
  (rnr:end) (princ))

(defun c:RNRL-BLOCKLIST ( / b)
  (if rnr:block-names
    (progn (princ "\nBuilt-in RNR blocks (insert with RNRL-INSERT):")
           (foreach n (rnr:block-names) (princ (strcat "\n  " n "  -> layer " (rnr:block-layer n))))
           (princ "\nDefined in this drawing:")))
  (setq b (tblnext "BLOCK" T))
  (while b
    (if (wcmatch (cdr (assoc 2 b)) "RNR_*") (princ (strcat "\n  " (cdr (assoc 2 b)))))
    (setq b (tblnext "BLOCK")))
  (princ))
(princ)
