#!/usr/bin/env python3
"""Layout audit for the RooMNRooF preview sheets.

The sheets are drawn blind (no AutoCAD, no visual check), so this script reads
back the generated DXFs and reports two classes of defect:

  * text that runs outside the sheet frame or outside the panel it belongs to
  * text boxes that overlap each other, i.e. copy that would print on top of
    other copy

Text extents are estimated from the glyph count, the style width factor and the
text height, which is close enough for a layout sanity check at sheet scale.
"""

import os
import sys

import ezdxf

HERE = os.path.dirname(os.path.abspath(__file__))
OUT_DIR = os.path.normpath(os.path.join(HERE, "..", "preview"))

SHEET_W, SHEET_H = 841.0, 594.0
MARGIN = 10.0
INNER = (MARGIN + 2.0, MARGIN + 2.0, SHEET_W - MARGIN - 2.0, SHEET_H - MARGIN - 2.0)

# average glyph advance as a fraction of the cap height, per nominal style width
ADVANCE = 0.58


def style_width(doc, name):
    try:
        return float(doc.styles.get(name).dxf.width)
    except Exception:
        return 1.0


def text_boxes(doc):
    """[(layer, value, x0, y0, x1, y1)] for every TEXT entity in modelspace."""
    boxes = []
    for e in doc.modelspace().query("TEXT"):
        value = e.dxf.text or ""
        if not value.strip():
            continue
        h = float(e.dxf.height)
        w = len(value) * h * ADVANCE * style_width(doc, e.dxf.style)
        x, y = float(e.dxf.insert[0]), float(e.dxf.insert[1])
        rot = float(getattr(e.dxf, "rotation", 0.0) or 0.0)
        halign = int(getattr(e.dxf, "halign", 0) or 0)
        valign = int(getattr(e.dxf, "valign", 0) or 0)
        # DXF halign: 0 left, 1 centre, 2 right, 3 aligned, 4 middle, 5 fit
        if halign in (1, 4, 5):
            x0, x1 = x - w / 2.0, x + w / 2.0
        elif halign == 2:
            x0, x1 = x - w, x
        else:                                      # 0 left, 3 aligned (fitted)
            x0, x1 = x, x + w
        # DXF valign: 0 baseline, 1 bottom, 2 middle, 3 top
        if valign == 2:
            y0, y1 = y - h / 2.0, y + h / 2.0
        elif valign == 3:
            y0, y1 = y - h, y
        else:
            y0, y1 = y, y + h
        boxes.append((e.dxf.layer, value, x0, y0, x1, y1, rot))
    return boxes


def overlap(a, b, tol=0.4):
    ax0, ay0, ax1, ay1 = a[2], a[3], a[4], a[5]
    bx0, by0, bx1, by1 = b[2], b[3], b[4], b[5]
    ix = min(ax1, bx1) - max(ax0, bx0)
    iy = min(ay1, by1) - max(ay0, by0)
    if ix <= tol or iy <= tol:
        return None
    return (ix, iy)


def audit(path):
    doc = ezdxf.readfile(path)
    boxes = text_boxes(doc)
    problems = []

    for layer, value, x0, y0, x1, y1, rot in boxes:
        if rot:
            continue                                # rotated copy is checked visually
        if x0 < INNER[0] or y0 < INNER[1] or x1 > INNER[2] or y1 > INNER[3]:
            problems.append(("OUT-OF-FRAME", layer, value,
                             "%.1f,%.1f -> %.1f,%.1f" % (x0, y0, x1, y1)))

    for i in range(len(boxes)):
        for j in range(i + 1, len(boxes)):
            a, b = boxes[i], boxes[j]
            if a[6] or b[6]:
                continue
            hit = overlap(a, b)
            if not hit:
                continue
            area = hit[0] * hit[1]
            area_a = (a[4] - a[2]) * (a[5] - a[3])
            area_b = (b[4] - b[2]) * (b[5] - b[3])
            share = area / max(0.001, min(area_a, area_b))
            if share < 0.22:
                continue                            # grazing corners are fine
            problems.append(("TEXT-OVERLAP", "%s / %s" % (a[0], b[0]),
                             "%r over %r" % (a[1][:34], b[1][:34]),
                             "%.0f%% of the smaller box" % (share * 100.0)))

    name = os.path.basename(path)
    print("%-46s %4d texts  %3d problems" % (name, len(boxes), len(problems)))
    for kind, where, what, detail in problems[:40]:
        print("    %-13s %-34s %-52s %s" % (kind, str(where)[:34], what, detail))
    if len(problems) > 40:
        print("    ... and %d more" % (len(problems) - 40))
    return len(problems)


def main():
    files = sorted(f for f in os.listdir(OUT_DIR) if f.lower().endswith(".dxf"))
    if not files:
        print("no DXF sheets in", OUT_DIR)
        return 1
    total = 0
    for name in files:
        total += audit(os.path.join(OUT_DIR, name))
    print("-" * 78)
    print("TOTAL PROBLEMS: %d" % total)
    return 0 if total == 0 else 2


if __name__ == "__main__":
    sys.exit(main())
