#!/usr/bin/env python3
"""
Single-source block geometry for the 29 RooMNRooF blocks (Standards/RNR_Blocks.json).

Outputs
  Blocks/RNR_Blocks.dxf              block definitions + labelled catalogue in model space
  Blocks/RNR_Blocks_preview.png      rendered catalogue
  AutoLISP/RNR_BlockDefs.lsp         entmake definitions so the LISP Edition can create the blocks itself

Geometry is drawn on layer 0 (inherits the insert layer / ByBlock); units mm; base point at the
logical insertion point (door hinge, fixture wall-centre, symbol centre).
Dynamic parameters (stretch/flip/visibility) cannot be authored here: see Documentation/09_Dynamic_Block_Manual.md.
"""
import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rnr_dxf import ROOT, new_doc  # noqa: E402
from ezdxf.enums import TextEntityAlignment  # noqa: E402

META = {b["name"]: b for b in json.load(open(os.path.join(ROOT, "Standards", "RNR_Blocks.json"), encoding="utf-8"))["blocks"]}


# primitives: ("L",x1,y1,x2,y2) ("C",x,y,r) ("A",x,y,r,a0deg,a1deg) ("P",closed,[(x,y)...])
#             ("T",x,y,h,text) centred text   ("ATT",x,y,h,tag,prompt,default) centred attribute
def rect(x, y, w, h):
    return ("P", True, [(x, y), (x + w, y), (x + w, y + h), (x, y + h)])


def crect(cx, cy, w, h):
    return rect(cx - w / 2, cy - h / 2, w, h)


def B():
    g = {}
    g["RNR_DOOR"] = [("P", True, [(0, 0), (40, 0), (40, 900), (0, 900)]), ("A", 0, 0, 900, 0, 90), ("L", 0, 0, 900, 0)]
    g["RNR_WINDOW"] = [rect(0, -125, 1200, 250), ("L", 0, -42, 1200, -42), ("L", 0, 42, 1200, 42)]
    g["RNR_BED_DOUBLE"] = [rect(0, 0, 1500, 2000), rect(0, 1800, 1500, 200), crect(375, 1600, 550, 300),
                           crect(1125, 1600, 550, 300), ("L", 0, 1300, 1500, 1300)]
    g["RNR_SOFA"] = [rect(0, 0, 2100, 850), rect(0, 650, 2100, 200), rect(0, 0, 200, 650), rect(1900, 0, 200, 650),
                     ("L", 700, 0, 700, 650), ("L", 1400, 0, 1400, 650)]
    din = [rect(0, 0, 1600, 900)]
    for cx in (400, 1200):
        din += [crect(cx, -300, 450, 450), crect(cx, 1200, 450, 450)]
    g["RNR_DINING"] = din
    g["RNR_CHAIR"] = [rect(0, 0, 450, 450), rect(0, 400, 450, 80)]
    g["RNR_KITCHEN_COUNTER"] = [rect(0, 0, 2400, 600), ("L", 0, 560, 2400, 560), crect(700, 300, 500, 400),
                                ("C", 1700, 200, 90), ("C", 1700, 420, 90), ("C", 1950, 200, 90), ("C", 1950, 420, 90)]
    g["RNR_SINK"] = [rect(0, 0, 800, 500), ("P", True, [(60, 60), (740, 60), (740, 440), (60, 440)]), ("C", 400, 380, 25)]
    g["RNR_TOILET"] = [rect(-250, 0, 500, 180), ("P", True, [(-180, 180), (180, 180), (180, 300), (-180, 300)]),
                       ("A", 0, 450, 180, 180, 360), ("L", -180, 450, -180, 300), ("L", 180, 450, 180, 300),
                       ("A", 0, 450, 180, 0, 180)]
    g["RNR_BASIN"] = [rect(-275, 0, 550, 420), ("C", 0, 210, 160), ("C", 0, 330, 20)]
    g["RNR_SHOWER"] = [rect(0, 0, 900, 900), ("L", 0, 0, 900, 900), ("L", 0, 900, 900, 0), ("C", 450, 450, 50)]
    g["RNR_BATHTUB"] = [rect(0, 0, 1700, 750), ("P", True, [(80, 80), (1620, 80), (1620, 670), (80, 670)]),
                        ("C", 1500, 375, 40)]
    g["RNR_WARDROBE"] = [rect(0, 0, 1800, 600), ("L", 900, 0, 900, 600), ("L", 0, 520, 1800, 520),
                         ("L", 60, 300, 1740, 300)]
    g["RNR_TV"] = [rect(0, 0, 1800, 450), crect(900, 380, 1200, 60)]
    g["RNR_DESK"] = [rect(0, 0, 1200, 600), crect(600, -250, 450, 450)]
    g["RNR_CAR"] = [("P", True, [(0, 300), (300, 0), (1500, 0), (1800, 300), (1800, 4500), (1500, 4800),
                                 (300, 4800), (0, 4500)]), rect(200, 1300, 1400, 800), rect(200, 3300, 1400, 600),
                    ("T", 900, 2700, 250, "CAR")]
    tree = [("C", 0, 0, 1500), ("C", 0, 0, 100)]
    for k in range(8):
        a = math.radians(k * 45)
        tree.append(("L", 100 * math.cos(a), 100 * math.sin(a), 1300 * math.cos(a), 1300 * math.sin(a)))
    g["RNR_TREE"] = tree
    g["RNR_PLANT"] = [("C", 0, 0, 300), ("C", 0, 0, 150), ("L", -300, 0, 300, 0), ("L", 0, -300, 0, 300)]
    g["RNR_LIGHT"] = [("C", 0, 0, 150), ("L", -106, -106, 106, 106), ("L", -106, 106, 106, -106)]
    fan = [("C", 0, 0, 100)]
    for k in range(3):
        a = math.radians(90 + k * 120)
        c, s = math.cos(a), math.sin(a)
        fan.append(("P", True, [(100 * c - 60 * s, 100 * s + 60 * c), (600 * c - 80 * s, 600 * s + 80 * c),
                                (600 * c + 80 * s, 600 * s - 80 * c), (100 * c + 60 * s, 100 * s - 60 * c)]))
    g["RNR_FAN"] = fan
    g["RNR_AC"] = [rect(0, 0, 1000, 250), ("L", 50, 60, 950, 60), ("L", 50, 120, 950, 120), ("T", 500, 180, 60, "AC")]
    g["RNR_LIFT"] = [rect(0, 0, 1800, 1800), rect(150, 150, 1500, 1350), ("L", 150, 150, 1650, 1500),
                     ("L", 150, 1500, 1650, 150), ("L", 450, 1650, 1350, 1650)]
    g["RNR_STAIR_ARROW"] = [("L", 0, 0, 0, 2000), ("P", False, [(-120, 1780), (0, 2000), (120, 1780)]), ("C", 0, 0, 50),
                            ("T", 0, -250, 150, "UP")]
    g["RNR_NORTH"] = [("C", 0, 0, 800), ("P", True, [(0, 800), (-320, -480), (0, -160), (320, -480)]),
                      ("T", 0, 1100, 300, "N")]
    g["RNR_GRIDBUBBLE"] = [("C", 0, 0, 500), ("ATT", 0, 0, 350, "GRID", "Grid label", "A")]
    g["RNR_LEVEL"] = [("P", True, [(0, 0), (-150, 250), (150, 250)]), ("L", 0, 0, 1800, 0),
                      ("ATT", 900, 150, 200, "LEVEL", "Level", "+0.000"), ("ATT", 900, 450, 150, "NAME", "Level name", "FFL")]
    g["RNR_SECTIONMARK"] = [("C", 0, 0, 600), ("L", -600, 0, 600, 0), ("P", True, [(600, 0), (600, 700), (1100, 0)]),
                            ("ATT", 0, 280, 280, "NO", "Section no", "A"), ("ATT", 0, -300, 200, "SHEET", "Sheet", "A-201")]
    g["RNR_DETAILMARK"] = [("C", 0, 0, 600), ("L", -600, 0, 600, 0),
                           ("ATT", 0, 280, 280, "NO", "Detail no", "1"), ("ATT", 0, -300, 200, "SHEET", "Sheet", "S-301")]
    g["RNR_ELEVMARK"] = [("C", 0, 0, 600), ("P", True, [(-600, 0), (0, 850), (600, 0)]),
                         ("ATT", 0, 0, 300, "NO", "Elevation no", "1")]
    return g


BLOCKS = B()


def to_dxf():
    doc = new_doc()
    for name, prims in BLOCKS.items():
        blk = doc.blocks.new(name=name)
        for p in prims:
            k = p[0]
            a = {"layer": "0"}
            if k == "L":
                blk.add_line(p[1:3], p[3:5], dxfattribs=a)
            elif k == "C":
                blk.add_circle(p[1:3], p[3], dxfattribs=a)
            elif k == "A":
                blk.add_arc(p[1:3], p[3], p[4], p[5], dxfattribs=a)
            elif k == "P":
                blk.add_lwpolyline(p[2], close=p[1], dxfattribs=a)
            elif k == "T":
                blk.add_text(p[4], height=p[3], dxfattribs={**a, "style": "RNR_TEXT"}).set_placement(
                    p[1:3], align=TextEntityAlignment.MIDDLE_CENTER)
            elif k == "ATT":
                ad = blk.add_attdef(p[4], text=p[6], dxfattribs={**a, "height": p[3], "prompt": p[5], "style": "RNR_TEXT"})
                ad.set_placement(p[1:3], align=TextEntityAlignment.MIDDLE_CENTER)
    msp = doc.modelspace()
    x = y = 0
    for i, name in enumerate(BLOCKS):
        cx, cy = (i % 6) * 6000, -(i // 6) * 7000
        layer = META.get(name, {}).get("layer", "0")
        ref = msp.add_blockref(name, (cx, cy), dxfattribs={"layer": layer})
        if any(p[0] == "ATT" for p in BLOCKS[name]):
            ref.add_auto_attribs({})
        msp.add_text(name, height=250, dxfattribs={"layer": "ANNO-TEXT", "style": "RNR_TEXT"}).set_placement(
            (cx, cy - 2800), align=TextEntityAlignment.MIDDLE_CENTER)
    os.makedirs(os.path.join(ROOT, "Blocks"), exist_ok=True)
    path = os.path.join(ROOT, "Blocks", "RNR_Blocks.dxf")
    doc.saveas(path)
    return doc, path


def f(v):
    return f"{v:.4f}".rstrip("0").rstrip(".") if isinstance(v, float) else str(v)


def pt(x, y):
    return f"(list {f(float(x))} {f(float(y))} 0.0)"


def to_lisp():
    L = [";;; RNR_BlockDefs.lsp - GENERATED by Scripts/generate_block_library.py - do not edit.",
         ";;; Lets the LISP Edition create the 29 RooMNRooF block definitions with entmake (no .NET needed).",
         ";;; Geometry on layer 0 (inherits insert layer). Existing definitions are never redefined.", "",
         "(defun rnr:bd-line (a b) (entmake (list '(0 . \"LINE\") '(8 . \"0\") (cons 10 a) (cons 11 b))))",
         "(defun rnr:bd-circle (c r) (entmake (list '(0 . \"CIRCLE\") '(8 . \"0\") (cons 10 c) (cons 40 r))))",
         "(defun rnr:bd-arc (c r a0 a1) (entmake (list '(0 . \"ARC\") '(8 . \"0\") (cons 10 c) (cons 40 r)"
         " (cons 50 (* pi (/ a0 180.0))) (cons 51 (* pi (/ a1 180.0))))))",
         "(defun rnr:bd-pline (closed pts)",
         "  (entmake (append (list '(0 . \"LWPOLYLINE\") '(100 . \"AcDbEntity\") '(8 . \"0\") '(100 . \"AcDbPolyline\")",
         "                         (cons 90 (length pts)) (cons 70 (if closed 1 0)))",
         "                   (mapcar '(lambda (p) (cons 10 (list (car p) (cadr p)))) pts))))",
         "(defun rnr:bd-text (p h s) (entmake (list '(0 . \"TEXT\") '(8 . \"0\") (cons 10 p) (cons 11 p) (cons 40 h)",
         " (cons 1 s) '(72 . 1) '(73 . 2))))",
         "(defun rnr:bd-att (p h tag prm def) (entmake (list '(0 . \"ATTDEF\") '(8 . \"0\") (cons 10 p) (cons 11 p)",
         " (cons 40 h) (cons 1 def) (cons 3 prm) (cons 2 tag) '(70 . 0) '(72 . 1) '(74 . 2))))", "",
         "(setq *RNR-BLOCK-LAYERS* '("]
    for n in BLOCKS:
        L.append(f'  ("{n}" . "{META.get(n, {}).get("layer", "0")}")')
    L += ["))", "", "(defun rnr:block-names () (mapcar 'car *RNR-BLOCK-LAYERS*))", "",
          "(defun rnr:block-layer (name / a) (if (setq a (assoc (strcase name) *RNR-BLOCK-LAYERS*)) (cdr a) \"0\"))", "",
          "(defun rnr:define-block (name / n)",
          "  ;; returns T when the block exists afterwards",
          "  (setq n (strcase name))",
          "  (cond",
          "    ((tblsearch \"BLOCK\" n) T)",
          "    ((not (assoc n *RNR-BLOCK-LAYERS*)) nil)",
          "    (T"]
    L.append("     (cond")
    for n, prims in BLOCKS.items():
        att = any(p[0] == "ATT" for p in prims)
        L.append(f'      ((= n "{n}")')
        L.append(f"       (entmake (list '(0 . \"BLOCK\") '(2 . \"{n}\") '(70 . {2 if att else 0}) '(10 0.0 0.0 0.0)))")
        for p in prims:
            k = p[0]
            if k == "L":
                L.append(f"       (rnr:bd-line {pt(p[1], p[2])} {pt(p[3], p[4])})")
            elif k == "C":
                L.append(f"       (rnr:bd-circle {pt(p[1], p[2])} {f(float(p[3]))})")
            elif k == "A":
                L.append(f"       (rnr:bd-arc {pt(p[1], p[2])} {f(float(p[3]))} {f(float(p[4]))} {f(float(p[5]))})")
            elif k == "P":
                pts = " ".join(f"(list {f(float(x))} {f(float(y))})" for x, y in p[2])
                L.append(f"       (rnr:bd-pline {'T' if p[1] else 'nil'} (list {pts}))")
            elif k == "T":
                L.append(f'       (rnr:bd-text {pt(p[1], p[2])} {f(float(p[3]))} "{p[4]}")')
            elif k == "ATT":
                L.append(f'       (rnr:bd-att {pt(p[1], p[2])} {f(float(p[3]))} "{p[4]}" "{p[5]}" "{p[6]}")')
        L.append("       (entmake '((0 . \"ENDBLK\"))))")
    L += ["     )", "     (if (tblsearch \"BLOCK\" n) T nil))))", "",
          "(defun c:RNRL-BLOCKS ( / c)",
          "  ;; define all 29 blocks in the current drawing (skips existing ones)",
          "  (setq c 0)",
          "  (foreach n (rnr:block-names) (if (rnr:define-block n) (setq c (1+ c))))",
          "  (princ (strcat \"\\n[RNR] \" (itoa c) \" of \" (itoa (length *RNR-BLOCK-LAYERS*)) \" RNR blocks available.\"))",
          "  (princ))", "(princ)", ""]
    path = os.path.join(ROOT, "AutoLISP", "RNR_BlockDefs.lsp")
    with open(path, "w", encoding="utf-8") as fh:
        fh.write("\n".join(L))
    return path


def main():
    missing = set(META) - set(BLOCKS)
    extra = set(BLOCKS) - set(META)
    if missing or extra:
        sys.exit(f"block list mismatch: missing={missing} extra={extra}")
    doc, dxf = to_dxf()
    lsp = to_lisp()
    if "--no-png" not in sys.argv:
        from generate_samples import render
        render(doc, os.path.join(ROOT, "Blocks", "RNR_Blocks_preview.png"))
    print("wrote", os.path.relpath(dxf, ROOT), "and", os.path.relpath(lsp, ROOT), f"({len(BLOCKS)} blocks)")


if __name__ == "__main__":
    main()
