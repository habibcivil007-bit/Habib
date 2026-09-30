;;; RNR_Rebar.lsp - reinforcement call-out validation and annotation (LISP)
(setq *RNR-DIAS* '(8 10 12 16 20 25 32))

(defun rnr:rebar-valid-p (s / u pos n d)
  ;; accepts "4T16" or "T10@150" / "T10 @ 150 c/c"
  (setq u (vl-string-translate " " "" (strcase s)))
  (cond
    ((and (setq pos (vl-string-search "T" u)) (> pos 0) (not (vl-string-search "@" u)))
     (setq n (atoi (substr u 1 pos)) d (atoi (substr u (+ pos 2))))
     (and (> n 0) (member d *RNR-DIAS*)))
    ((and (= (substr u 1 1) "T") (setq pos (vl-string-search "@" u)))
     (setq d (atoi (substr u 2 (1- pos))))
     (and (member d *RNR-DIAS*) (> (atof (substr u (+ pos 2))) 0)))
    (T nil)))

(defun rnr:unit-weight (d) (/ (* d d) 162.2))

(defun c:RNRL-REBAR ( / s a b)
  (rnr:start '("CMDECHO"))
  (rnr:layers-apply "S-REBAR,S-REBAR-TEXT")
  (setq s (rnr:getstr "Bar call-out (4T16 / T10 @ 150 c/c)" "2T16"))
  (if (not (rnr:rebar-valid-p s))
    (princ "\n[RNR] Invalid input. Unsupported notation or diameter.")
    (if (and (setq a (getpoint "\nBar start: ")) (setq b (getpoint a "\nBar end: ")))
      (progn
        (rnr:line a b "S-REBAR")
        (rnr:text (polar (polar a (angle a b) (/ (distance a b) 2.0)) (+ (angle a b) (/ pi 2)) (* 3.0 (rnr:scale)))
                  (strcase s) (* 2.5 (rnr:scale)) "S-REBAR-TEXT")
        (rnr:ok))))
  (rnr:end) (princ))

(defun c:RNRL-BARWT ( / d l n)
  (setq d (rnr:getint "Bar diameter (mm)" 16) l (rnr:getposreal "Bar length (mm)" 6000.0) n (rnr:getint "Quantity" 10))
  (if (member d *RNR-DIAS*)
    (princ (strcat "\n  T" (itoa d) ": " (rtos (rnr:unit-weight d) 2 3) " kg/m; total "
                   (rtos (* n (/ l 1000.0) (rnr:unit-weight d)) 2 2) " kg (CAD estimate)"))
    (princ "\n[RNR] Invalid input. Diameter not in 8,10,12,16,20,25,32."))
  (princ))
(princ)
