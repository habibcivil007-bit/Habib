;;; RNR_Units.lsp - exact unit conversion (1 in = 25.4 mm exactly). Never changes geometry.
(setq *RNR-MM-PER* '(("MM" . 1.0) ("CM" . 10.0) ("M" . 1000.0) ("IN" . 25.4) ("FT" . 304.8)))

(defun rnr:convert (v from to)
  (/ (* v (cdr (assoc (strcase from) *RNR-MM-PER*))) (cdr (assoc (strcase to) *RNR-MM-PER*))))

(defun rnr:mm->ftin (mm den / sign tot ft rm in fr)
  ;; feet-inch string rounded to 1/den inch
  (setq sign (if (< mm 0) "-" "") mm (abs mm)
        tot (fix (+ 0.5 (* (/ mm 25.4) den)))
        ft (/ tot (* 12 den)) rm (- tot (* ft 12 den))
        in (/ rm den) fr (rem rm den))
  (strcat sign (itoa ft) "'-" (itoa in) (if (> fr 0) (strcat " " (itoa fr) "/" (itoa den)) "") "\""))

(defun c:RNRL-UNITS ( / v from u)
  (setq v (rnr:getreal "Value" 1000.0)
        from (rnr:getkw "From unit" "MM CM M IN FT" "MM"))
  (foreach u '("MM" "CM" "M" "IN" "FT")
    (princ (strcat "\n  " (rtos (rnr:convert v from u) 2 6) " " u)))
  (princ (strcat "\n  " (rnr:mm->ftin (rnr:convert v from "MM") 16) " (ft-in)"))
  (princ (strcat "\n  Drawing INSUNITS = " (itoa (getvar "INSUNITS")) " (4 = mm). Not changed."))
  (princ))
(princ)
