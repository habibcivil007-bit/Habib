;;; RNR_Colors.lsp - colour utilities (TrueColor <-> ACI, apply palette, list)
(vl-load-com)

(defun rnr:rgb->int (r g b) (+ (* r 65536) (* g 256) b))
(defun rnr:int->rgb (i) (list (lsh i -16) (logand (lsh i -8) 255) (logand i 255)))

(defun c:RNRL-COLORS ( / )
  ;; list the standard layer colours
  (foreach rec *RNR-LAYERS*
    (princ (strcat "\n  " (car rec) "  RGB " (itoa (nth 1 rec)) "," (itoa (nth 2 rec)) "," (itoa (nth 3 rec))
                   "  LW " (rtos (/ (nth 5 rec) 100.0) 2 2) "  T" (itoa (nth 6 rec)) "%")))
  (princ))

(defun c:RNRL-COLORAPPLY ( / n)
  ;; re-apply standard colours to existing standard layers only
  (rnr:start '("CMDECHO"))
  (setvar "CMDECHO" 0)
  (setq n 0)
  (foreach rec *RNR-LAYERS*
    (if (tblsearch "LAYER" (car rec))
      (progn (rnr:set-truecolor (vla-Item (vla-get-Layers (rnr:doc)) (car rec)) (nth 1 rec) (nth 2 rec) (nth 3 rec))
             (setq n (1+ n)))))
  (princ (strcat "\n[RNR] Colours re-applied to " (itoa n) " layer(s)."))
  (rnr:end) (princ))

(defun c:RNRL-BYLAYER ( / ss i e n)
  ;; set selected objects' colour to ByLayer (after confirmation)
  (if (setq ss (ssget))
    (if (= (rnr:getkw "Set colour of selected objects to ByLayer?" "Yes No" "No") "Yes")
      (progn
        (rnr:start nil)
        (setq i 0 n (sslength ss))
        (while (< i n)
          (vla-put-Color (vlax-ename->vla-object (ssname ss i)) 256)
          (setq i (1+ i)))
        (rnr:end)
        (princ (strcat "\n[RNR] " (itoa n) " object(s) set to ByLayer."))))
    (princ "\n[RNR] Nothing selected."))
  (princ))
(princ)
