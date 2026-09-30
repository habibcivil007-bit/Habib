;;; RNR_Utilities.lsp - shared helpers: error handling, undo marks, sysvar save/restore, prompts
(vl-load-com)

(setq *RNR-ACAD* (vlax-get-acad-object))
(defun rnr:doc () (vla-get-ActiveDocument *RNR-ACAD*))

;;; ---------- error handling / undo ---------------------------------------
(defun rnr:start (sysvars / )
  ;; save sysvars, open an undo group, install the error handler
  (setq *rnr-saved* (mapcar '(lambda (v) (cons v (getvar v))) sysvars))
  (vla-StartUndoMark (rnr:doc))
  (setq *rnr-olderr* *error* *error* rnr:error)
  (princ))

(defun rnr:end ( / )
  (foreach p *rnr-saved* (if (cdr p) (setvar (car p) (cdr p))))
  (setq *rnr-saved* nil)
  (vla-EndUndoMark (rnr:doc))
  (if *rnr-olderr* (setq *error* *rnr-olderr* *rnr-olderr* nil))
  (princ))

(defun rnr:error (msg)
  (if (not (member msg '("Function cancelled" "quit / exit abort" "console break")))
    (princ (strcat "\n[RNR] Error: " msg))
    (princ "\n[RNR] Operation cancelled."))
  (rnr:end)
  (princ))

(defun rnr:ok () (princ "\n[RNR] Command completed successfully.") (princ))

;;; ---------- prompts with defaults ---------------------------------------
(defun rnr:getreal (msg def / v)
  (setq v (getreal (strcat "\n" msg " <" (rtos def 2 2) ">: ")))
  (if v v def))

(defun rnr:getposreal (msg def / v)
  (initget 6) ; no zero, no negative
  (setq v (getreal (strcat "\n" msg " <" (rtos def 2 0) ">: ")))
  (if v v def))

(defun rnr:getint (msg def / v)
  (initget 6)
  (setq v (getint (strcat "\n" msg " <" (itoa def) ">: ")))
  (if v v def))

(defun rnr:getstr (msg def / v)
  (setq v (getstring T (strcat "\n" msg " <" def ">: ")))
  (if (= v "") def v))

(defun rnr:getkw (msg kws def / v)
  ;; kws like "Yes No"
  (initget kws)
  (setq v (getkword (strcat "\n" msg " [" (vl-string-translate " " "/" kws) "] <" def ">: ")))
  (if v v def))

;;; ---------- geometry helpers -------------------------------------------
(defun rnr:polar2 (p a d) (polar p a d))

(defun rnr:lwpoly (pts closed layer / ent)
  ;; create a LWPOLYLINE from a list of 2D/3D points
  (entmakex
    (append
      (list '(0 . "LWPOLYLINE") '(100 . "AcDbEntity") (cons 8 layer)
            '(100 . "AcDbPolyline") (cons 90 (length pts)) (cons 70 (if closed 1 0)))
      (mapcar '(lambda (p) (cons 10 (list (car p) (cadr p)))) pts))))

(defun rnr:line (a b layer)
  (entmakex (list '(0 . "LINE") (cons 8 layer) (cons 10 a) (cons 11 b))))

(defun rnr:circle (c r layer)
  (entmakex (list '(0 . "CIRCLE") (cons 8 layer) (cons 10 c) (cons 40 r))))

(defun rnr:text (p s h layer / )
  ;; middle-centred single-line text
  (entmakex (list '(0 . "TEXT") (cons 8 layer) (cons 10 p) (cons 11 p) (cons 40 h)
                  (cons 1 s) '(72 . 1) '(73 . 2)
                  (cons 7 (if (tblsearch "STYLE" "RNR_TEXT") "RNR_TEXT" (getvar "TEXTSTYLE"))))))

(defun rnr:scale ( / ds)
  ;; model-space text scale: DIMSCALE if set (>0) else 100
  (setq ds (getvar "DIMSCALE"))
  (if (and ds (> ds 0)) ds 100.0))

(defun rnr:rect (c w d layer / hw hd x y)
  (setq hw (/ w 2.0) hd (/ d 2.0) x (car c) y (cadr c))
  (rnr:lwpoly (list (list (- x hw) (- y hd)) (list (+ x hw) (- y hd))
                    (list (+ x hw) (+ y hd)) (list (- x hw) (+ y hd))) T layer))

(defun rnr:split (str delim / pos out)
  (while (setq pos (vl-string-search delim str))
    (setq out (cons (substr str 1 pos) out) str (substr str (+ pos 1 (strlen delim)))))
  (reverse (cons str out)))

(princ)
