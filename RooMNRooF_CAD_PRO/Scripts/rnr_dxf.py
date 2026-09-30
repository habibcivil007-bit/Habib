#!/usr/bin/env python3
"""
Shared helpers for DXF generation with ezdxf (used by generate_samples.py / generate_dxf_library.py).
Everything is driven by Standards/*.json so the DXF output matches the plugin's standards.

DXF files are an OPEN interchange format and can be opened by AutoCAD 2026/2027 directly.
They are NOT DWT templates: real .dwt files are produced inside AutoCAD by RNRTEMPLATE.
"""
import json
import math
import os

import ezdxf
from ezdxf import colors
from ezdxf.enums import TextEntityAlignment

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STD = os.path.join(ROOT, "Standards")


def load(name):
    with open(os.path.join(STD, name), encoding="utf-8") as f:
        return json.load(f)


LAYERS = load("RNR_Layers.json")["layers"]
STYLES = load("RNR_Styles.json")
HATCHES = {h["name"]: h for h in load("RNR_Hatches.json")["hatches"]}

LINETYPES = {
    # name: (description, pattern in drawing units for ezdxf: [total, dash, gap, ...]) scaled x100 for 1:100 model
    "RNR_GRID": ("Grid ____ _ ____", [0.2064, 0.127, -0.03175, 0.015875, -0.03175]),
    "RNR_HIDDEN": ("Hidden __ __", [0.09525, 0.0635, -0.03175]),
    "RNR_DEMO": ("Demolition _ _", [0.0635, 0.03175, -0.03175]),
    "RNR_BOUNDARY": ("Boundary ____ _ _", [0.28575, 0.1905, -0.03175, 0.015875, -0.03175, 0.015875, -0.03175]),
    "RNR_JOINT": ("Joint __ .", [0.1429, 0.09525, -0.0238, 0.0, -0.0238]),
    "RNR_UTILITY": ("Utility ___ . .", [0.1745, 0.127, -0.0238, 0.0, -0.0238, 0.0, -0.0238]),
    "RNR_WATER": ("Water ___ __", [0.2222, 0.127, -0.0238, 0.0635, -0.0238]),
}


def new_doc(ltscale=100.0):
    doc = ezdxf.new("R2018", setup=True, units=ezdxf.units.MM)
    doc.header["$INSUNITS"] = 4
    doc.header["$MEASUREMENT"] = 1
    doc.header["$LTSCALE"] = ltscale
    doc.header["$LUNITS"] = 2
    doc.header["$LUPREC"] = 0
    doc.header["$LWDISPLAY"] = 1
    for name, (desc, pat) in LINETYPES.items():
        if name not in doc.linetypes:
            doc.linetypes.add(name, pattern=[p * 100 for p in pat], description=desc)
    for ts in STYLES["textStyles"]:
        if ts["name"] not in doc.styles:
            doc.styles.add(ts["name"], font=ts["font"]).dxf.width = ts["widthFactor"]
    for L in LAYERS:
        if L["name"] in doc.layers:
            continue
        lay = doc.layers.add(L["name"])
        r, g, b = L["rgb"]
        lay.rgb = (r, g, b)
        lay.color = L["aci"]
        lt = L["linetype"]
        lay.dxf.linetype = lt if (lt in doc.linetypes or lt == "Continuous") else "Continuous"
        lay.dxf.lineweight = int(round(L["lineweight"] * 100))
        lay.dxf.plot = 1 if L["plot"] else 0
        lay.description = L["description"]
        if L["transparency"]:
            lay.transparency = L["transparency"] / 100.0
    # dimension styles (ticks), text heights for 1:100 set per call via dimscale
    for ds in STYLES["dimStyles"]:
        if ds["name"] in doc.dimstyles:
            continue
        d = doc.dimstyles.new(ds["name"])
        d.dxf.dimtxsty = ds["textStyle"]
        d.dxf.dimtxt = ds["textHeight"]
        d.dxf.dimasz = ds["arrowSize"]
        d.dxf.dimtsz = ds["arrowSize"] if ds["arrow"] else 0
        d.dxf.dimexo = ds["extOffset"]
        d.dxf.dimexe = ds["extBeyond"]
        d.dxf.dimdec = ds["decimals"]
        d.dxf.dimtad = 1
        d.dxf.dimgap = 0.8
        d.dxf.dimzin = 8
        d.dxf.dimscale = 100
    return doc


class Pen:
    """Small drawing API on top of a layout (model space by default)."""

    def __init__(self, doc, msp=None, scale=100.0):
        self.doc = doc
        self.msp = msp if msp is not None else doc.modelspace()
        self.s = scale  # paper -> model factor for text/dims

    def line(self, a, b, layer, **kw):
        return self.msp.add_line(a, b, dxfattribs={"layer": layer, **kw})

    def poly(self, pts, layer, closed=True, width=0, **kw):
        e = self.msp.add_lwpolyline(pts, close=closed, dxfattribs={"layer": layer, **kw})
        if width:
            e.dxf.const_width = width
        return e

    def rect(self, x, y, w, h, layer, **kw):
        return self.poly([(x, y), (x + w, y), (x + w, y + h), (x, y + h)], layer, **kw)

    def crect(self, cx, cy, w, h, layer, **kw):
        return self.rect(cx - w / 2, cy - h / 2, w, h, layer, **kw)

    def circle(self, c, r, layer, **kw):
        return self.msp.add_circle(c, r, dxfattribs={"layer": layer, **kw})

    def arc(self, c, r, a0, a1, layer):
        return self.msp.add_arc(c, r, a0, a1, dxfattribs={"layer": layer})

    def text(self, s, p, h_paper, layer, align="MIDDLE_CENTER", rot=0.0, style="RNR_TEXT"):
        t = self.msp.add_text(s, height=h_paper * self.s, rotation=rot, dxfattribs={"layer": layer, "style": style})
        t.set_placement(p, align=TextEntityAlignment[align])
        return t

    def mtext(self, s, p, h_paper, layer, width=0):
        m = self.msp.add_mtext(s, dxfattribs={"layer": layer, "style": "RNR_TEXT", "char_height": h_paper * self.s})
        m.set_location(p)
        if width:
            m.dxf.width = width
        return m

    def dim(self, a, b, off, layer, style="RNR_STRUCT", angle=None):
        """Linear dimension; angle None -> aligned."""
        if angle is None:
            d = self.msp.add_aligned_dim(p1=a, p2=b, distance=off, dimstyle=style, dxfattribs={"layer": layer},
                                         override={"dimscale": self.s})
        else:
            base = (a[0], a[1] + off) if angle == 0 else (a[0] + off, a[1])
            d = self.msp.add_linear_dim(base=base, p1=a, p2=b, angle=angle, dimstyle=style, dxfattribs={"layer": layer},
                                        override={"dimscale": self.s})
        d.render()
        return d

    def hatch(self, pts, name, layer, scale_mult=1.0):
        h = HATCHES.get(name)
        pat = h["pattern"] if h else "ANSI31"
        if pat.startswith("RNR_"):
            pat = {"RNR_RCC": "ANSI31", "RNR_BRICK": "BRICK", "RNR_STONE": "AR-RSHKE", "RNR_TILE": "NET",
                   "RNR_WOOD": "AR-PARQ1", "RNR_SOIL": "EARTH", "RNR_MARBLE": "AR-SAND", "RNR_TIMBER": "ANSI36",
                   "RNR_WATER": "ANSI33", "RNR_GLASS": "ANSI32", "RNR_INSUL": "HONEY"}.get(pat, "ANSI31")
        sc = (h["scale"] if h else 1.0) * scale_mult
        e = self.msp.add_hatch(dxfattribs={"layer": layer})
        if h:
            e.rgb = tuple(h["rgb"])
        try:
            e.set_pattern_fill(pat, scale=sc, angle=h["angle"] if h else 0)
        except Exception:
            e.set_pattern_fill("ANSI31", scale=sc)
        e.paths.add_polyline_path(pts, is_closed=True)
        return e

    def solid_circle(self, c, r, layer):
        self.circle(c, r, layer)
        e = self.msp.add_hatch(dxfattribs={"layer": layer})
        e.set_solid_fill(color=256)
        e.paths.add_edge_path().add_arc(c, r, 0, 360)
        return e

    def bubble(self, c, label, layer="ANNO-GRID", d_paper=10):
        r = d_paper / 2 * self.s
        self.circle(c, r, layer)
        self.text(label, c, 4, layer)

    def table(self, x, y, title, headers, rows, colw_paper=24, rowh_paper=7, layer="ANNO-SCHEDULE"):
        s = self.s
        cw, rh = colw_paper * s, rowh_paper * s
        n = len(headers)
        W = cw * n
        H = rh * (len(rows) + 2)
        self.rect(x, y - H, W, H, layer)
        self.text(title, (x + W / 2, y - rh / 2), 3.5, layer, style="RNR_HEADING")
        for i in range(1, len(rows) + 2):
            self.line((x, y - rh * i), (x + W, y - rh * i), layer)
        for j in range(1, n):
            self.line((x + cw * j, y - rh), (x + cw * j, y - H), layer)
        for j, hd in enumerate(headers):
            self.text(hd, (x + cw * j + cw / 2, y - rh * 1.5), 2.2, layer)
        for i, row in enumerate(rows):
            for j, c in enumerate(row):
                self.text(str(c), (x + cw * j + cw / 2, y - rh * (i + 2.5)), 2.2, layer)
        return W, H

    def title_block(self, x, y, sheet, title, dwgno, scale_txt, discipline, project=None):
        """Model-space title block frame at 1:self.s (A-size sheet)."""
        sw, sh = STYLES["sheets"][sheet]
        s = self.s
        W, H = sw * s, sh * s
        self.rect(x, y, W, H, "ANNO-TITLE")
        self.rect(x + 20 * s, y + 10 * s, W - 30 * s, H - 20 * s, "ANNO-TITLE", lineweight=70)
        bx, by, bw, bh = x + W - 10 * s - 180 * s, y + 10 * s, 180 * s, 70 * s
        self.rect(bx, by, bw, bh, "ANNO-TITLE", lineweight=50)
        rows = [("PROJECT", "RooMNRooF SAMPLE RESIDENCE, DHAKA"), ("CLIENT", "SAMPLE CLIENT"),
                ("CONSULTANT", "RooMNRooF CAD PRO (SAMPLE)"), ("DRAWING TITLE", title)]
        if project is not None:
            rows = [("PROJECT", project[0]), ("CLIENT", project[1]), ("CONSULTANT", project[2]), ("DRAWING TITLE", title)]
        rh = bh / 7
        for i, (k, v) in enumerate(rows):
            yy = by + bh - rh * (i + 1)
            self.line((bx, yy), (bx + bw, yy), "ANNO-TITLE")
            self.text(k, (bx + 2 * s, yy + rh - 2.5 * s), 1.8, "ANNO-TITLE", align="LEFT")
            self.text(v, (bx + 32 * s, yy + 1.5 * s), 3.0, "ANNO-TITLE", align="LEFT")
        grid = [("DWG NO", dwgno), ("REV", "P0"), ("SHEET", sheet), ("DATE", "SAMPLE" if project is None else "-"), ("SCALE", scale_txt),
                ("DRAWN", "RNR"), ("CHECKED", "-"), ("APPROVED", "-"), ("STATUS", "SAMPLE - NOT FOR CONSTRUCTION" if project is None else "PRELIMINARY")]
        for i in range(1, 3):
            self.line((bx + bw * i / 3, by), (bx + bw * i / 3, by + 3 * rh), "ANNO-TITLE")
        for i in range(1, 3):
            self.line((bx, by + rh * i), (bx + bw, by + rh * i), "ANNO-TITLE")
        for i, (k, v) in enumerate(grid):
            c, r = i % 3, 2 - i // 3
            cx, cy = bx + c * bw / 3, by + r * rh
            self.text(k, (cx + 1.5 * s, cy + rh - 2.3 * s), 1.8, "ANNO-TITLE", align="LEFT")
            self.text(v, (cx + 1.5 * s, cy + 1.2 * s), 1.8 if k == "STATUS" else 2.5, "ANNO-TITLE", align="LEFT")
        self.text(f"{discipline} | CAD drafting sample. Engineering content subject to review by the responsible engineer.",
                  (bx, by + bh + 3 * s), 1.8, "ANNO-TITLE", align="LEFT")
        return (x + 25 * s, y + 15 * s, W - 40 * s - bw, H - 30 * s)  # usable drawing area
