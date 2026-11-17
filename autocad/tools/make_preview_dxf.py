#!/usr/bin/env python3
"""Build the RooMNRooF PRO preview drawing.

The preview is generated from the *same* data tables that the AutoLISP file
uses, so it can never drift away from the shipped palette:

    *RMR-LAYER-SPECS*   *RMR-TEXT-STYLES*   *RMR-DIMSTYLE-SPECS*
    *RMR-HATCH-SPECS*   *RMR-STAMP-SPECS*   *RMR-NOTES*   *RMR-VERSION*

Outputs (written to ../preview)
    RooMNRooF_PRO_Standard_Preview.dxf   A1 sheet, opens directly in AutoCAD
    RooMNRooF_PRO_Standard_Preview.png   full sheet image
    RooMNRooF_PRO_Plan_Detail.png        zoomed plan image

Usage:  python3 make_preview_dxf.py
Needs:  ezdxf (+ matplotlib and pillow for the PNG renders)

The sheet is drawn in paper millimetres (1 unit = 1 mm on the plotted A1
sheet). The sample apartment plan is real millimetre geometry placed at 1:50,
exactly the way a production drawing is composed.
"""
import math
import os
import re
import sys

import ezdxf
from ezdxf import rgb2int
from ezdxf.enums import TextEntityAlignment
from ezdxf.tools import pattern as ez_pattern
from ezdxf.tools import standards as ez_standards

HERE = os.path.dirname(os.path.abspath(__file__))
LSP = os.path.normpath(os.path.join(HERE, "..", "RooMNRooF_Master.lsp"))
OUT_DIR = os.path.normpath(os.path.join(HERE, "..", "preview"))

SHEET_W, SHEET_H = 841.0, 594.0
MARGIN = 10.0

PLAN_SCALE = 50.0            # sample plan plotted at 1:50
PLAN_X0, PLAN_Y0 = 70.0, 250.0
GRID_EXT = 800.0             # real mm the grid lines run past the building


# --------------------------------------------------------------------------- #
# 1. read the AutoLISP data tables
# --------------------------------------------------------------------------- #
def _tokenize(text):
    tokens, i, n = [], 0, len(text)
    while i < n:
        c = text[i]
        if c.isspace():
            i += 1
        elif c == ";":
            while i < n and text[i] != "\n":
                i += 1
        elif c in "()":
            tokens.append(c)
            i += 1
        elif c == '"':
            i += 1
            buf = []
            while i < n and text[i] != '"':
                if text[i] == "\\" and i + 1 < n:
                    buf.append(text[i + 1])
                    i += 2
                    continue
                buf.append(text[i])
                i += 1
            i += 1
            tokens.append("".join(buf))
        else:
            start = i
            while i < n and not text[i].isspace() and text[i] not in '();"':
                i += 1
            tokens.append(("SYM", text[start:i]))
    return tokens


def _parse(tokens, pos):
    if tokens[pos] == "(":
        pos += 1
        items = []
        while tokens[pos] != ")":
            value, pos = _parse(tokens, pos)
            items.append(value)
        return items, pos + 1
    tok = tokens[pos]
    if isinstance(tok, tuple):
        sym = tok[1]
        low = sym.lower()
        if low == "nil":
            return None, pos + 1
        if low == "t":
            return True, pos + 1
        try:
            return (int(sym) if re.fullmatch(r"[-+]?\d+", sym) else float(sym)), pos + 1
        except ValueError:
            return sym, pos + 1
    return tok, pos + 1


def _extract_form(src, varname):
    """Return the parsed value of (setq *VAR* <value>)."""
    match = re.search(r"\(setq\s+" + re.escape(varname) + r"\s", src)
    if not match:
        raise SystemExit("could not find %s in %s" % (varname, LSP))
    i = match.end()
    depth = 0
    seen_open = False
    while i < len(src):
        ch = src[i]
        if ch == '"':
            i += 1
            while i < len(src) and src[i] != '"':
                i += 2 if src[i] == "\\" else 1
        elif ch == ";":
            while i < len(src) and src[i] != "\n":
                i += 1
            continue
        elif ch == "(":
            depth += 1
            seen_open = True
        elif ch == ")":
            if seen_open:
                depth -= 1
                if depth == 0:
                    i += 1          # keep the closing bracket of the value list
                    break
            else:
                break               # this bracket closes the setq form itself
        i += 1
    body = src[match.end():i].lstrip()
    if body.startswith("'"):
        body = body[1:]
    tokens = _tokenize(body)
    value, _ = _parse(tokens, 0)
    return value


def load_lisp_data():
    src = open(LSP, encoding="utf-8").read()
    return {
        "layers": _extract_form(src, "*RMR-LAYER-SPECS*"),
        "styles": _extract_form(src, "*RMR-TEXT-STYLES*"),
        "dimstyles": _extract_form(src, "*RMR-DIMSTYLE-SPECS*"),
        "hatches": _extract_form(src, "*RMR-HATCH-SPECS*"),
        "stamps": _extract_form(src, "*RMR-STAMP-SPECS*"),
        "notes": _extract_form(src, "*RMR-NOTES*"),
        "version": _extract_form(src, "*RMR-VERSION*"),
        "brand": {name: _extract_form(src, "*RMR-BRAND-%s*" % name)
                  for name in ("INK", "TERRA", "TEAL", "GOLD", "SAND", "BLUE", "SLATE")},
        # dotted pairs arrive as [tag, ".", value]
        "project": [(item[0], item[2]) if len(item) > 2 else (item[0], "")
                    for item in _extract_form(src, "*RMR-PROJECT*")],
        "cloud_arc": _extract_form(src, "*RMR-CLOUD-ARC*"),
    }


DATA = load_lisp_data()
INK = tuple(DATA["brand"]["INK"])
TERRA = tuple(DATA["brand"]["TERRA"])
TEAL = tuple(DATA["brand"]["TEAL"])
GOLD = tuple(DATA["brand"]["GOLD"])
SAND = tuple(DATA["brand"]["SAND"])
BLUE = tuple(DATA["brand"]["BLUE"])
SLATE = tuple(DATA["brand"]["SLATE"])
# light sheet-paper tone for body copy that sits on the dark presentation ground
PAPER = (244, 241, 234)
VERSION = DATA["version"]


def layer_rgb(name):
    for spec in DATA["layers"]:
        if spec[0] == name:
            return tuple(int(v) for v in spec[2])
    return INK


# --------------------------------------------------------------------------- #
# 2. document setup
# --------------------------------------------------------------------------- #
def build_document():
    doc = ezdxf.new("R2018", setup=True)
    doc.header["$INSUNITS"] = 4
    doc.header["$MEASUREMENT"] = 1
    doc.header["$LTSCALE"] = 1.0
    doc.header["$PSLTSCALE"] = 1
    doc.header["$LWDISPLAY"] = 1

    for entry in ez_standards.linetypes(ez_standards.ISO_LTYPE_FACTOR):
        if isinstance(entry, tuple):
            raw_name, description, pattern = entry[0], entry[1], list(entry[2])
        else:
            raw_name, description = entry.name, entry.description
            pattern = [entry.length] + list(entry.pattern)
        name = raw_name.title()
        if name not in doc.linetypes:
            try:
                doc.linetypes.add(name, pattern=pattern, description=description)
            except Exception:
                pass
    if "HIDDEN" not in doc.linetypes:
        doc.linetypes.add("HIDDEN", pattern=[0.25, 0.125, -0.125],
                          description="Hidden __ __ __ __")

    for name, group, rgb, ltype, lineweight, description in DATA["layers"]:
        weight = int(lineweight)
        attribs = {
            "color": 7,
            "linetype": ltype if ltype in doc.linetypes else "Continuous",
            "lineweight": weight if weight >= -3 else -3,
        }
        layer = doc.layers.get(name) if name in doc.layers else doc.layers.new(name, dxfattribs=attribs)
        layer.dxf.linetype = attribs["linetype"]
        layer.dxf.lineweight = attribs["lineweight"]
        layer.dxf.true_color = rgb2int(tuple(int(v) for v in rgb))
        layer.dxf.plot = 0 if name.endswith("NPLT") else 1
        # AutoCAD keeps layer descriptions as AcAecLayerStandard XDATA, which is
        # exactly what RMR:EnsureLayerDescription in the LSP writes.
        try:
            layer.description = "%s | %s" % (group, description)
        except Exception:
            pass

    for name, font, width, oblique, description in DATA["styles"]:
        style = doc.styles.new(name, dxfattribs={"font": font, "width": float(width)})
        style.dxf.oblique = float(oblique)
        try:
            style.dxf.description = description
        except Exception:
            pass

    for name, textheight, arrowsize, description in DATA["dimstyles"]:
        dim = doc.dimstyles.duplicate_entry("EZ_M_100_H25_CM", name)
        dim.dxf.dimtxt = float(textheight)
        dim.dxf.dimasz = float(arrowsize)
        dim.dxf.dimexo = 1.0
        dim.dxf.dimexe = 1.5
        dim.dxf.dimgap = 1.0
        dim.dxf.dimtad = 1
        dim.dxf.dimdec = 0
        dim.dxf.dimzin = 8
        dim.dxf.dimclrd = rgb2int(INK)
        dim.dxf.dimclre = rgb2int(INK)
        dim.dxf.dimclrt = rgb2int(INK)
        try:
            dim.dxf.dimtxsty = "RMR-BODY"
            dim.set_arrows(blk="ARCHTICK")
        except Exception:
            pass

    try:
        doc.mleader_styles.duplicate_entry("Standard", "RMR-MLEADER")
    except Exception:
        pass
    return doc


# --------------------------------------------------------------------------- #
# 3. drawing helpers (same vocabulary as the AutoLISP helpers)
# --------------------------------------------------------------------------- #
class Sheet(object):
    def __init__(self, doc):
        self.doc = doc
        self.msp = doc.modelspace()
        self.patterns = ez_pattern.load(1)

    def _color(self, entity, layer, rgb):
        entity.dxf.true_color = rgb2int(tuple(int(v) for v in (rgb if rgb else layer_rgb(layer))))
        return entity

    def line(self, p1, p2, layer, rgb=None):
        return self._color(self.msp.add_line(p1, p2, dxfattribs={"layer": layer}), layer, rgb)

    def rect(self, p, w, h, layer, rgb=None):
        x, y = p
        pts = [(x, y), (x + w, y), (x + w, y + h), (x, y + h), (x, y)]
        return self._color(self.msp.add_lwpolyline(pts, dxfattribs={"layer": layer}), layer, rgb)

    def circle(self, c, r, layer, rgb=None):
        return self._color(self.msp.add_circle(c, r, dxfattribs={"layer": layer}), layer, rgb)

    def arc(self, c, r, a1, a2, layer, rgb=None):
        return self._color(
            self.msp.add_arc(c, r, a1, a2, dxfattribs={"layer": layer}), layer, rgb)

    def solid(self, p, w, h, layer, rgb):
        x, y = p
        pts = [(x, y), (x + w, y), (x, y + h), (x + w, y + h)]
        return self._color(self.msp.add_solid(pts, dxfattribs={"layer": layer}), layer, rgb)

    def tri(self, p, size, layer, rgb):
        x, y = p
        pts = [(x, y), (x + size, y), (x + size / 2.0, y + size), (x + size / 2.0, y + size)]
        return self._color(self.msp.add_solid(pts, dxfattribs={"layer": layer}), layer, rgb)

    def text(self, p, value, height, style, layer, rgb=None, align="left", rotation=0.0):
        align_map = {
            "left": TextEntityAlignment.LEFT,
            "center": TextEntityAlignment.CENTER,
            "middle": TextEntityAlignment.MIDDLE,
            "right": TextEntityAlignment.RIGHT,
            "top_left": TextEntityAlignment.TOP_LEFT,
            "bottom_left": TextEntityAlignment.BOTTOM_LEFT,
        }
        e = self.msp.add_text(value, dxfattribs={
            "layer": layer, "style": style, "height": height, "rotation": rotation})
        e.set_placement(p, align=align_map[align])
        return self._color(e, layer, rgb)

    def mtext(self, p, value, width, height, style, layer, rgb=None):
        e = self.msp.add_mtext(value, dxfattribs={
            "layer": layer, "style": style, "char_height": height, "width": width,
            "attachment_point": 1, "line_spacing_factor": 1.3})
        e.set_location(p)
        return self._color(e, layer, rgb)

    def poly(self, pts, bulges, closed, layer, rgb=None):
        """LWPolyline with per-vertex bulges (break lines and revision clouds)."""
        data = [(float(x), float(y), float(b)) for (x, y), b in zip(pts, bulges)]
        e = self.msp.add_lwpolyline(data, format="xyb", close=bool(closed),
                                    dxfattribs={"layer": layer})
        return self._color(e, layer, rgb)

    def hatch_solid(self, pts, layer, rgb):
        h = self.msp.add_hatch(dxfattribs={"layer": layer})
        h.set_solid_fill(rgb=tuple(int(v) for v in rgb))
        h.paths.add_polyline_path(pts, is_closed=True)
        return h

    def hatch_pattern(self, pts, layer, rgb, name, scale=1.0, angle=0.0):
        h = self.msp.add_hatch(dxfattribs={"layer": layer})
        definition = self.patterns.get(str(name).upper())
        if str(name).upper() == "SOLID" or definition is None:
            h.set_solid_fill(rgb=tuple(int(v) for v in rgb))
        else:
            h.set_pattern_fill(str(name).upper(), color=7, scale=scale, angle=angle,
                               definition=definition)
            h.dxf.true_color = rgb2int(tuple(int(v) for v in rgb))
        h.paths.add_polyline_path(pts, is_closed=True)
        return h


def px(x_real):
    return PLAN_X0 + x_real / PLAN_SCALE


def py(y_real):
    return PLAN_Y0 + y_real / PLAN_SCALE


def ppt(x_real, y_real):
    return (px(x_real), py(y_real))


# --------------------------------------------------------------------------- #
# 4. sheet furniture
# --------------------------------------------------------------------------- #
def draw_frame(sh):
    sh.rect((0, 0), SHEET_W, SHEET_H, "RMR-A-FRAME", INK)
    sh.rect((MARGIN, MARGIN), SHEET_W - 2 * MARGIN, SHEET_H - 2 * MARGIN, "RMR-A-FRAME", TEAL)
    for cx, cy in ((MARGIN, MARGIN), (SHEET_W - MARGIN - 5, MARGIN),
                   (MARGIN, SHEET_H - MARGIN - 5), (SHEET_W - MARGIN - 5, SHEET_H - MARGIN - 5)):
        sh.solid((cx + 1.5, cy + 1.5), 3.5, 3.5, "RMR-PRES-KEY", GOLD)


SHEET_TITLE = "PRO SUITE PREVIEW SHEET"
SHEET_SUBTITLE = "LAYER PALETTE, TEXT STYLES, MATERIALS, ANNOTATION AND PRODUCTION TOOLS"
SHEET_NOTE = "Sample apartment plan drawn at 1:50 to demonstrate the RooMNRooF standard."


def draw_header(sh):
    y0 = SHEET_H - MARGIN - 38.0
    sh.solid((MARGIN, y0), 46.0, 38.0, "RMR-PRES-TITLE", TERRA)
    sh.text((MARGIN + 4, y0 + 24), "RooMNRooF", 6.0, "RMR-TITLE", "RMR-PRES-TITLE", SAND)
    sh.text((MARGIN + 4, y0 + 16), "CONSULTANT", 2.6, "RMR-HEAD", "RMR-PRES-TITLE", SAND)
    sh.text((MARGIN + 4, y0 + 11), "2D CAD STANDARD", 2.0, "RMR-NOTE", "RMR-PRES-TITLE", SAND)
    sh.line((MARGIN + 4, y0 + 8), (MARGIN + 42, y0 + 8), "RMR-PRES-TITLE", GOLD)
    sh.text((MARGIN + 4, y0 + 3.5), "ROOF THE ROOM", 1.8, "RMR-MARK", "RMR-PRES-TITLE", SAND)

    x = MARGIN + 54
    sh.text((x, y0 + 24), SHEET_TITLE, 8.0, "RMR-TITLE", "RMR-PRES-TITLE", TERRA)
    sh.text((x, y0 + 15), SHEET_SUBTITLE,
            3.0, "RMR-HEAD", "RMR-A-TEXT", INK)
    sh.text((x, y0 + 9), SHEET_NOTE,
            2.4, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((x, y0 + 4), "Standard %s | metric | true-colour layers | generated from RooMNRooF_Master.lsp"
            % VERSION, 2.2, "RMR-MARK", "RMR-A-TEXT", SLATE)
    sh.line((MARGIN, y0), (SHEET_W - MARGIN, y0), "RMR-A-FRAME", TEAL)

    right = SHEET_W - MARGIN - 4
    sh.text((right, y0 + 26), "SHEET  A-000", 3.4, "RMR-NUMBER", "RMR-PRES-TITLE", INK, align="right")
    sh.text((right, y0 + 19), "SCALE  1:50 / A1", 2.8, "RMR-NUMBER", "RMR-PRES-KEY", TERRA, align="right")
    sh.text((right, y0 + 13), "REV  01", 2.4, "RMR-NOTE", "RMR-A-TEXT", SLATE, align="right")


def draw_title_block(sh):
    w, h = 190.0, 50.0
    p = (SHEET_W - MARGIN - w, MARGIN + 6)
    sh.rect(p, w, h, "RMR-A-FRAME", INK)
    sh.solid(p, 42.0, h, "RMR-PRES-TITLE", TERRA)
    sh.text((p[0] + 4, p[1] + 34), "RooMNRooF", 5.0, "RMR-TITLE", "RMR-PRES-TITLE", SAND)
    sh.text((p[0] + 4, p[1] + 26), "CONSULTANT", 2.4, "RMR-HEAD", "RMR-PRES-TITLE", SAND)
    sh.text((p[0] + 4, p[1] + 20), "2D CAD STANDARD", 1.8, "RMR-NOTE", "RMR-PRES-TITLE", SAND)
    sh.line((p[0] + 4, p[1] + 14), (p[0] + 37, p[1] + 14), "RMR-PRES-TITLE", GOLD)
    sh.text((p[0] + 4, p[1] + 9), "ROOF THE ROOM", 1.8, "RMR-NOTE", "RMR-PRES-TITLE", SAND)

    def cell(cp, cw, ch, label, value, style="RMR-BODY", rgb=None, size=2.5):
        sh.rect(cp, cw, ch, "RMR-A-FRAME", INK)
        sh.text((cp[0] + 2, cp[1] + ch - 3.2), label, 1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)
        sh.text((cp[0] + 2, cp[1] + 2.2), value, size, style, "RMR-A-TEXT", rgb if rgb else INK)

    x, y, colw = p[0] + 42.0, p[1], 74.0
    third = colw / 3.0
    cell((x, y + 35), colw, 15, "PROJECT", "RooMNRooF RESIDENCE")
    cell((x, y + 20), colw, 15, "DRAWING TITLE", "PRO STANDARD PREVIEW PLAN")
    cell((x, y), third, 20, "DRAWN BY", "RMR")
    cell((x + third, y), third, 20, "CHECKED BY", "RMR")
    cell((x + 2 * third, y), third, 20, "DATE", "2026-09-30")
    x2 = x + colw
    cell((x2, y + 35), colw, 15, "DRAWING NO.", "A-000", "RMR-NUMBER", TERRA, 3.4)
    cell((x2, y + 20), colw, 15, "SCALE", "1:50", "RMR-NUMBER", None, 3.0)
    cell((x2, y), colw, 20, "REVISION", "01", "RMR-NUMBER", None, 3.4)
    sh.solid((p[0] + 182, p[1] + 44), 4.0, 4.0, "RMR-PRES-NORTH", TEAL)
    sh.solid((p[0] + 182, p[1] + 38), 4.0, 4.0, "RMR-PRES-KEY", GOLD)


# --------------------------------------------------------------------------- #
# 5. sample plan (real millimetre geometry at 1:50)
# --------------------------------------------------------------------------- #
ROOMS = [
    ("01", "LIVING / DINING", (200, 200), (5950, 5950)),
    ("02", "BEDROOM 02", (200, 6050), (5950, 8800)),
    ("03", "MASTER BEDROOM", (6050, 4550), (11800, 8800)),
    ("04", "KITCHEN", (6050, 200), (8950, 4450)),
    ("05", "BATHROOM", (9050, 200), (11800, 4450)),
]

WALLS = [
    ((0, 0), (1200, 200)), ((2100, 0), (12000, 200)),
    ((0, 8800), (12000, 9000)),
    ((0, 0), (200, 9000)), ((11800, 0), (12000, 9000)),
    ((5950, 0), (6050, 2400)), ((5950, 3300), (6050, 6600)), ((5950, 7500), (6050, 8800)),
    ((200, 5950), (2400, 6050)), ((3300, 5950), (5950, 6050)),
    ((6050, 4450), (7200, 4550)), ((8100, 4450), (11800, 4550)),
    ((8950, 200), (9050, 1800)), ((8950, 2700), (9050, 4450)),
]

DOORS = [
    ((1200, 200), (1200, 1100), 270, 0),
    ((6050, 2400), (6950, 2400), 0, 90),
    ((5950, 6600), (5050, 6600), 90, 180),
    ((2400, 6050), (2400, 6950), 0, 90),
    ((8100, 4450), (8100, 3550), 180, 270),
    ((8950, 2700), (8050, 2700), 180, 270),
]

WINDOWS = [
    ((3000, 0), (5000, 200), "h"),
    ((6500, 0), (8000, 200), "h"),
    ((1500, 8800), (3000, 9000), "h"),
    ((11800, 5500), (12000, 7500), "v"),
    ((11800, 1000), (12000, 2000), "v"),
]

COLUMNS = [((4000, 4500), 300), ((8000, 4500), 300)]
GRID_X = [0, 4000, 8000, 12000]
GRID_Y = [0, 4500, 9000]
GRID_LETTERS = ["A", "B", "C", "D"]
GRID_NUMBERS = ["01", "02", "03"]


def draw_grid(sh):
    r = 4.0
    for i, gx in enumerate(GRID_X):
        sh.line(ppt(gx, -GRID_EXT), ppt(gx, 9000 + GRID_EXT), "RMR-A-GRID")
        for yy in (-GRID_EXT, 9000 + GRID_EXT):
            c = ppt(gx, yy)
            sh.circle(c, r, "RMR-A-GRID")
            sh.text(c, GRID_LETTERS[i], 2.6, "RMR-NUMBER", "RMR-A-GRID", INK, align="middle")
    for j, gy in enumerate(GRID_Y):
        sh.line(ppt(-GRID_EXT, gy), ppt(12000 + GRID_EXT, gy), "RMR-A-GRID")
        for xx in (-GRID_EXT, 12000 + GRID_EXT):
            c = ppt(xx, gy)
            sh.circle(c, r, "RMR-A-GRID")
            sh.text(c, GRID_NUMBERS[j], 2.6, "RMR-NUMBER", "RMR-A-GRID", INK, align="middle")


def draw_structure(sh):
    sh.rect(ppt(0, 0), 12000 / PLAN_SCALE, 9000 / PLAN_SCALE, "RMR-S-SLAB", (125, 134, 168))
    for (cx, cy), size in COLUMNS:
        half = size / 2.0
        pts = [ppt(cx - half, cy - half), ppt(cx + half, cy - half),
               ppt(cx + half, cy + half), ppt(cx - half, cy + half)]
        sh.hatch_solid(pts, "RMR-S-COLUMN", (184, 72, 72))
        sh.rect(ppt(cx - half, cy - half), size / PLAN_SCALE, size / PLAN_SCALE,
                "RMR-S-COLUMN", (184, 72, 72))


def draw_rooms(sh):
    for number, _name, (x1, y1), (x2, y2) in ROOMS:
        pts = [ppt(x1, y1), ppt(x2, y1), ppt(x2, y2), ppt(x1, y2)]
        if number == "01":
            sh.hatch_solid(pts, "RMR-M-FILL", (244, 238, 226))
        elif number == "03":
            sh.hatch_pattern(pts, "RMR-M-FINISH", (186, 138, 74), "DOLMIT", scale=0.35)
        elif number == "04":
            sh.hatch_pattern(pts, "RMR-M-HATCH", (214, 190, 150), "AR-SAND", scale=0.25)
        elif number == "05":
            sh.hatch_pattern(pts, "RMR-M-FINISH", TEAL, "AR-HBONE", scale=0.12)


def draw_walls(sh):
    for (x1, y1), (x2, y2) in WALLS:
        pts = [ppt(x1, y1), ppt(x2, y1), ppt(x2, y2), ppt(x1, y2)]
        sh.hatch_pattern(pts, "RMR-M-WALL", TERRA, "ANSI31", scale=0.3)
        sh.rect(ppt(x1, y1), (x2 - x1) / PLAN_SCALE, (y2 - y1) / PLAN_SCALE, "RMR-M-WALL", TERRA)


def draw_openings(sh):
    for hinge, leaf, a1, a2 in DOORS:
        sh.line(ppt(*hinge), ppt(*leaf), "RMR-M-DOOR", GOLD)
        radius = math.dist(hinge, leaf) / PLAN_SCALE
        sh.arc(ppt(*hinge), radius, a1, a2, "RMR-M-DOOR", GOLD)
    for (x1, y1), (x2, y2), direction in WINDOWS:
        layer, rgb = "RMR-M-WINDOW", TEAL
        glass = [ppt(x1, y1), ppt(x2, y1), ppt(x2, y2), ppt(x1, y2)]
        if direction == "h":
            for f in (0.25, 0.5, 0.75):
                yy = y1 + (y2 - y1) * f
                sh.line(ppt(x1, yy), ppt(x2, yy), layer, rgb)
            sh.line(ppt(x1, y1), ppt(x1, y2), layer, rgb)
            sh.line(ppt(x2, y1), ppt(x2, y2), layer, rgb)
        else:
            for f in (0.25, 0.5, 0.75):
                xx = x1 + (x2 - x1) * f
                sh.line(ppt(xx, y1), ppt(xx, y2), layer, rgb)
            sh.line(ppt(x1, y1), ppt(x2, y1), layer, rgb)
            sh.line(ppt(x1, y2), ppt(x2, y2), layer, rgb)
        sh.hatch_pattern(glass, "RMR-M-GLASS", (116, 190, 198), "LINE", scale=0.35, angle=45.0)


def draw_furniture(sh):
    furn, case, fix = "RMR-F-FURN", "RMR-F-CASE", "RMR-F-FIXTURE"

    def box(x1, y1, x2, y2, layer, rgb=None):
        sh.rect(ppt(x1, y1), (x2 - x1) / PLAN_SCALE, (y2 - y1) / PLAN_SCALE, layer, rgb)

    # living / dining
    box(700, 700, 2900, 1600, furn)
    box(900, 800, 1600, 1500, furn)
    box(2000, 800, 2700, 1500, furn)
    box(1200, 2200, 2400, 2800, furn)
    box(400, 4200, 800, 5600, case)
    box(3200, 3200, 4800, 4100, furn)
    for cx, cy in ((3500, 2900), (4000, 2900), (4500, 2900),
                   (3500, 4400), (4000, 4400), (4500, 4400)):
        sh.circle(ppt(cx, cy), 250 / PLAN_SCALE, furn)
    # bedroom 02
    box(900, 6600, 2300, 8600, furn)
    box(900, 8200, 2300, 8600, furn)
    box(400, 8200, 850, 8650, case)
    box(2350, 8200, 2800, 8650, case)
    box(3600, 6300, 5600, 6900, case)
    # master bedroom
    box(7000, 5200, 8800, 7200, furn)
    box(7000, 6800, 8800, 7200, furn)
    box(6500, 6800, 6950, 7250, case)
    box(8850, 6800, 9300, 7250, case)
    box(9800, 4700, 11600, 5300, case)
    # kitchen
    box(6200, 250, 8800, 850, case)
    box(6200, 850, 6800, 2600, case)
    box(7200, 400, 7800, 800, fix)
    box(8100, 400, 8600, 800, fix)
    box(6300, 3200, 6900, 3800, "RMR-F-EQUIP")
    # bathroom
    box(9200, 300, 9800, 900, fix)
    box(10200, 300, 11000, 800, fix)
    box(10600, 1200, 11700, 2300, fix)
    sh.circle(ppt(9500, 600), 120 / PLAN_SCALE, fix)
    sh.circle(ppt(10600, 550), 100 / PLAN_SCALE, fix)
    # reflected ceiling
    sh.rect(ppt(900, 1800), 3000 / PLAN_SCALE, 2200 / PLAN_SCALE, "RMR-M-CEILING", (166, 177, 181))
    for cx, cy in ((1650, 2350), (2400, 2350), (3150, 2350), (1650, 3450), (2400, 3450), (3150, 3450)):
        sh.circle(ppt(cx, cy), 120 / PLAN_SCALE, "RMR-M-CEILING", (166, 177, 181))


def draw_plumbing(sh):
    supply = [(6500, 500), (6500, 1400), (9400, 1400), (9400, 600), (10600, 600)]
    drain = [(7500, 350), (7500, 1000), (9500, 1000), (9500, 450), (11150, 450), (11150, 1700)]
    vent = [(9500, 1000), (9500, 2400), (11600, 2400)]
    for path, layer in ((supply, "RMR-P-SUPPLY"), (drain, "RMR-P-DRAIN"), (vent, "RMR-P-VENT")):
        e = sh.msp.add_lwpolyline([ppt(*p) for p in path], dxfattribs={"layer": layer})
        e.dxf.true_color = rgb2int(layer_rgb(layer))
    for cx, cy in ((9400, 1400), (7500, 1000), (11150, 1700)):
        sh.circle(ppt(cx, cy), 150 / PLAN_SCALE, "RMR-P-FIXTURE", (39, 154, 170))
    sh.circle(ppt(6900, 3500), 300 / PLAN_SCALE, "RMR-P-EQUIP", (210, 119, 58))
    sh.text(ppt(6900, 3950), "WH", 1.8, "RMR-MARK", "RMR-P-ANNO", BLUE, align="center")


def draw_room_tags(sh):
    placements = {"01": (2400, 5100), "02": (2400, 7000), "03": (7600, 7700),
                  "04": (6500, 3300), "05": (9900, 3300)}
    for number, name, (x1, y1), (x2, y2) in ROOMS:
        area = (x2 - x1) * (y2 - y1) / 1e6
        p = ppt(*placements[number])
        w, h = 34.0, 12.0
        sh.rect(p, w, h, "RMR-A-ROOMTAG", INK)
        sh.solid(p, 2.0, h, "RMR-PRES-TITLE", TERRA)
        sh.line((p[0] + 2.0, p[1] + h * 0.55), (p[0] + w, p[1] + h * 0.55), "RMR-A-ROOMTAG", TEAL)
        sh.text((p[0] + 4.0, p[1] + h - 5.0), number, 3.0, "RMR-NUMBER", "RMR-A-ROOMTAG", TERRA)
        sh.text((p[0] + 11.0, p[1] + h - 5.0), name, 2.6, "RMR-LABEL", "RMR-A-ROOMTAG", INK)
        sh.text((p[0] + 4.0, p[1] + 1.6), "%.2f m2  /  %.0f sq.ft" % (area, area * 10.7639),
                2.0, "RMR-NOTE", "RMR-A-ROOMTAG", SLATE)


def draw_dimensions(sh):
    y1 = py(0) - 34
    y2 = py(0) - 46
    for base, p1, p2, label, style in (
            ((px(0), y1), ppt(0, 0), ppt(12000, 0), "12000", "RMR-DIM-PLAN"),
            ((px(0), y2), ppt(0, 0), ppt(4000, 0), "4000", "RMR-DIM-PLAN"),
            ((px(4000), y2), ppt(4000, 0), ppt(8000, 0), "4000", "RMR-DIM-PLAN"),
            ((px(8000), y2), ppt(8000, 0), ppt(12000, 0), "4000", "RMR-DIM-PLAN"),
            ((px(0) - 30, py(0)), ppt(0, 0), ppt(0, 9000), "9000", "RMR-DIM-PLAN"),
            ((px(6050) + 6, py(4400)), ppt(6050, 4450), ppt(7200, 4450), "1150", "RMR-DIM-DETAIL"),
    ):
        angle = 90 if label == "9000" else 0
        dim = sh.msp.add_linear_dim(base=base, p1=p1, p2=p2, dimstyle=style,
                                    text=label, angle=angle)
        dim.render()


def draw_plan_annotation(sh):
    keynotes = [
        ((6300, 4500), (px(6300) + 24, py(4500) + 18), "01", "100mm PARTITION, PLASTERED BOTH FACES"),
        ((9000, 1800), (px(9000) - 24, py(1800) - 20), "02", "FLOOR WASTE, FALL 1:80 TO TRAP"),
        ((2400, 6000), (px(2400) - 24, py(6000) + 20), "03", "ACOUSTIC SEALANT TO PARTITION HEAD"),
    ]
    for tip, landing, number, note in keynotes:
        tp = ppt(*tip)
        sh.line(tp, landing, "RMR-A-LEADER", GOLD)
        sh.line(landing, (landing[0] + 8, landing[1]), "RMR-A-LEADER", GOLD)
        c = (landing[0] + 10.8, landing[1])
        sh.circle(c, 2.8, "RMR-A-KEYNOTE", GOLD)
        sh.text(c, number, 2.2, "RMR-NUMBER", "RMR-A-KEYNOTE", INK, align="middle")
        text_p = (landing[0] + 15, landing[1] - 1.0)
        sh.text(text_p, note, 2.0, "RMR-NOTE", "RMR-A-TEXT", INK, align="left")

    dc = (px(11200), py(6200))
    sh.circle(dc, 3.4, "RMR-A-DETAIL", SLATE)
    sh.line((dc[0] + 3.4, dc[1]), (dc[0] + 18, dc[1]), "RMR-A-DETAIL", SLATE)
    sh.text(dc, "A", 2.6, "RMR-NUMBER", "RMR-A-DETAIL", INK, align="middle")
    sh.text((dc[0] + 6, dc[1] + 4.4), "A-501", 2.0, "RMR-NOTE", "RMR-A-DETAIL", SLATE)

    lp = (px(1700), py(900))
    sh.line(lp, (lp[0] + 20, lp[1]), "RMR-A-LEVEL", TEAL)
    sh.tri((lp[0] - 3.0, lp[1] - 3.0), 3.0, "RMR-A-LEVEL", TEAL)
    sh.text((lp[0] + 5, lp[1] + 1.2), "+0.000 FFL", 2.4, "RMR-NUMBER", "RMR-A-LEVEL", INK)

    sp = (352.0, 402.0)
    sh.circle(sp, 3.0, "RMR-A-ARROW", TERRA)
    sh.text(sp, "1", 2.2, "RMR-NUMBER", "RMR-A-ARROW", TERRA, align="middle")
    sh.line((sp[0] + 3.0, sp[1]), (sp[0] + 20, sp[1]), "RMR-A-ARROW", TERRA)
    sh.tri((sp[0] + 20, sp[1] - 1.6), 3.2, "RMR-A-ARROW", TERRA)
    sh.text((sp[0] + 26, sp[1] - 1.0), "SECTION 1-1", 2.2, "RMR-NOTE", "RMR-A-TEXT", INK)
    sh.text((sp[0], sp[1] - 8.0), "RMR-DETAIL / RMR-LEVEL / RMR-REVISION markers are drawn",
            2.0, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((sp[0], sp[1] - 12.0), "from the same brand geometry as the LISP commands.",
            2.0, "RMR-NOTE", "RMR-A-TEXT", SLATE)


def draw_north(sh, centre=(436.0, 486.0), scale=1.0):
    r = 7.0 * scale
    sh.circle(centre, r, "RMR-PRES-NORTH", TEAL)
    sh.line((centre[0], centre[1] - r * 0.7), (centre[0], centre[1] + r * 1.25),
            "RMR-PRES-NORTH", TEAL)
    pts = [(centre[0], centre[1] + r * 1.25),
           (centre[0] - r * 0.34, centre[1] + r * 0.55),
           (centre[0], centre[1] + r * 0.7),
           (centre[0] + r * 0.34, centre[1] + r * 0.55)]
    sh.hatch_solid(pts, "RMR-PRES-NORTH", TEAL)
    sh.text((centre[0], centre[1] + r * 1.5), "N", 3.4 * scale, "RMR-NUMBER",
            "RMR-PRES-NORTH", TEAL, align="bottom_left")
    sh.text((centre[0], centre[1] - r - 3.2 * scale), "TRUE NORTH", 1.8 * scale, "RMR-NOTE",
            "RMR-A-TEXT", SLATE, align="center")


def draw_scale_bar(sh, p=(200.0, 190.0), segments=5, metres_each=1.0):
    seg = metres_each * 1000.0 / PLAN_SCALE
    h = 2.6
    for i in range(segments):
        x = p[0] + i * seg
        if i % 2 == 0:
            sh.solid((x, p[1]), seg, h, "RMR-PRES-TITLE", TERRA)
        else:
            sh.solid((x, p[1]), seg, h, "RMR-PRES-TITLE", SAND)
            sh.rect((x, p[1]), seg, h, "RMR-A-FRAME", INK)
        sh.text((x, p[1] + h + 1.0), "%d" % (i * metres_each), 2.2, "RMR-NUMBER",
                "RMR-A-TEXT", INK, align="center")
    end = p[0] + segments * seg
    sh.line((p[0], p[1]), (end, p[1]), "RMR-A-FRAME", INK)
    sh.text((end, p[1] + h + 1.0), "%d" % (segments * metres_each), 2.2, "RMR-NUMBER",
            "RMR-A-TEXT", TERRA, align="center")
    sh.text((p[0], p[1] - 5.0), "METRES  |  GRAPHIC SCALE BAR  |  RMR-SCALEBAR", 2.0,
            "RMR-NOTE", "RMR-A-TEXT", SLATE)


def draw_stamp(sh, centre, label, rgb, width=96.0, height=26.0, angle_deg=-12.0,
               revision="01", date="2026-09-30"):
    a = math.radians(angle_deg)
    ca, sa = math.cos(a), math.sin(a)
    corner = (centre[0] - width / 2 * ca + height / 2 * sa,
              centre[1] - width / 2 * sa - height / 2 * ca)

    def rot_rect(p, w, h):
        p2 = (p[0] + w * ca, p[1] + w * sa)
        p3 = (p2[0] - h * sa, p2[1] + h * ca)
        p4 = (p[0] - h * sa, p[1] + h * ca)
        sh.line(p, p2, "RMR-PRES-STAMP", rgb)
        sh.line(p2, p3, "RMR-PRES-STAMP", rgb)
        sh.line(p3, p4, "RMR-PRES-STAMP", rgb)
        sh.line(p4, p, "RMR-PRES-STAMP", rgb)

    rot_rect(corner, width, height)
    off = 1.8
    rot_rect((corner[0] + off * ca - off * sa, corner[1] + off * sa + off * ca),
             width - 2 * off, height - 2 * off)
    size = 4.6
    if len(label) * size * 0.62 > width - 16:
        size = (width - 16) / (len(label) * 0.62)
    sh.text(centre, label, size, "RMR-HEAD", "RMR-PRES-STAMP", rgb, align="middle",
            rotation=angle_deg)
    sh.text((centre[0] - 7.6 * sa, centre[1] + 7.6 * ca), "REV %s" % revision, 2.4, "RMR-NOTE",
            "RMR-PRES-STAMP", rgb, align="middle", rotation=angle_deg)
    sh.text((centre[0] + 7.6 * sa, centre[1] - 7.6 * ca), date, 2.4, "RMR-NOTE",
            "RMR-PRES-STAMP", rgb, align="middle", rotation=angle_deg)


# --------------------------------------------------------------------------- #
# 6. information panels
# --------------------------------------------------------------------------- #
def draw_legend(sh):
    x0, x1 = 480.0, 658.0
    top, row = 536.0, 5.2
    bottom = 300.0
    sh.text((x0, top), "LAYER PALETTE  |  TRUE COLOUR  |  GROUP STRUCTURE", 3.0, "RMR-HEAD",
            "RMR-A-TEXT", TERRA)
    sh.line((x0, top - 3.0), (825.0, top - 3.0), "RMR-A-TEXT", GOLD)

    rows = []
    groups = []
    for spec in DATA["layers"]:
        if spec[1] not in groups:
            groups.append(spec[1])
    for group in groups:
        rows.append(("group", group, None))
        for spec in DATA["layers"]:
            if spec[1] == group:
                rows.append(("layer", group, spec))
    half = (len(rows) + 1) // 2
    columns = (rows[:half], rows[half:])
    for column_x, column_rows in zip((x0, x1), columns):
        y = top - 9.0
        for kind, group, spec in column_rows:
            if kind == "group":
                sh.text((column_x, y), group, 2.6, "RMR-HEAD", "RMR-A-TEXT", INK)
                sh.line((column_x, y - 1.4), (column_x + 162.0, y - 1.4), "RMR-A-TEXT", SLATE)
                y -= row * 0.85
                continue
            name, _grp, rgb, ltype, weight, desc = spec
            sh.solid((column_x, y - 0.6), 6.0, 3.4, "RMR-A-TEXT", tuple(int(v) for v in rgb))
            sh.text((column_x + 8.0, y - 0.6), name, 2.2, "RMR-MARK", "RMR-A-TEXT", INK)
            text = desc if len(desc) <= 33 else desc[:32] + "."
            sh.text((column_x + 60.0, y - 0.6), text, 2.0, "RMR-NOTE", "RMR-A-TEXT", SLATE)
            weight_text = "default" if int(weight) < 0 else "%.2fmm" % (int(weight) / 100.0)
            ltype_text = "" if ltype == "Continuous" else " %s" % ltype
            sh.text((column_x + 138.0, y - 0.6), weight_text + ltype_text, 1.8, "RMR-MARK",
                    "RMR-A-TEXT", TEAL)
            y -= row
        if y < bottom:
            print("warning: legend column overflowed to y=%.1f" % y)


def draw_text_styles(sh):
    x, y = 480.0, 272.0
    sh.text((x, y), "TEXT STYLES  |  MODERN FONT STACK WITH SAFE FALLBACK", 3.0, "RMR-HEAD",
            "RMR-A-TEXT", TERRA)
    sh.line((x, y - 3.0), (825.0, y - 3.0), "RMR-A-TEXT", GOLD)
    y -= 9.0
    for name, font, width, _oblique, _desc in DATA["styles"]:
        sh.text((x, y), name, 2.4, "RMR-MARK", "RMR-A-TEXT", SLATE)
        sh.text((x + 34.0, y - 0.4), "RooMNRooF AaBbCc 0123456789", 3.2, name, "RMR-A-TEXT", INK)
        sh.text((x + 214.0, y), "%s | width %.2f" % (font, float(width)), 1.9, "RMR-NOTE",
                "RMR-A-TEXT", TEAL)
        y -= 7.2
    sh.text((x, y + 1.2),
            "Fallback order: Montserrat / Aptos / Arial / Calibri / Segoe UI / romans.shx / txt.shx",
            1.9, "RMR-NOTE", "RMR-A-TEXT", SLATE)


def draw_symbols(sh):
    x, y = 480.0, 196.0
    sh.text((x, y), "ANNOTATION AND PRESENTATION SYMBOLS", 3.0, "RMR-HEAD", "RMR-A-TEXT", TERRA)
    sh.line((x, y - 3.0), (825.0, y - 3.0), "RMR-A-TEXT", GOLD)

    ty = y - 20.0
    sh.rect((x, ty), 34.0, 12.0, "RMR-A-ROOMTAG", INK)
    sh.solid((x, ty), 2.0, 12.0, "RMR-PRES-TITLE", TERRA)
    sh.line((x + 2.0, ty + 6.6), (x + 34.0, ty + 6.6), "RMR-A-ROOMTAG", TEAL)
    sh.text((x + 4.0, ty + 7.0), "06", 3.0, "RMR-NUMBER", "RMR-A-ROOMTAG", TERRA)
    sh.text((x + 11.0, ty + 7.2), "STUDY", 2.6, "RMR-LABEL", "RMR-A-ROOMTAG", INK)
    sh.text((x + 4.0, ty + 1.6), "12.48 m2 / 134 sq.ft", 2.0, "RMR-NOTE", "RMR-A-ROOMTAG", SLATE)
    sh.text((x + 42.0, ty + 7.0), "RMR-ROOMTAG | RMR-AREA builds the schedule", 2.1, "RMR-NOTE",
            "RMR-A-TEXT", SLATE)

    ky = ty - 12.0
    sh.line((x + 2.0, ky), (x + 14.0, ky + 6.0), "RMR-A-LEADER", GOLD)
    sh.line((x + 14.0, ky + 6.0), (x + 22.0, ky + 6.0), "RMR-A-LEADER", GOLD)
    sh.circle((x + 24.8, ky + 6.0), 2.8, "RMR-A-KEYNOTE", GOLD)
    sh.text((x + 24.8, ky + 6.0), "04", 2.2, "RMR-NUMBER", "RMR-A-KEYNOTE", INK, align="middle")
    sh.text((x + 42.0, ky + 5.0), "RMR-KEYNOTE / RMR-MLEADER | gold chevron leader", 2.1,
            "RMR-NOTE", "RMR-A-TEXT", SLATE)

    dy = ky - 12.0
    c = (x + 5.0, dy)
    sh.circle(c, 3.4, "RMR-A-DETAIL", SLATE)
    sh.line((c[0] + 3.4, c[1]), (c[0] + 18.0, c[1]), "RMR-A-DETAIL", SLATE)
    sh.text(c, "B", 2.6, "RMR-NUMBER", "RMR-A-DETAIL", INK, align="middle")
    sh.text((c[0] + 6.0, c[1] + 4.4), "A-502", 2.0, "RMR-NOTE", "RMR-A-DETAIL", SLATE)
    sh.text((x + 42.0, dy - 1.0), "RMR-DETAIL | detail number plus reference sheet", 2.1,
            "RMR-NOTE", "RMR-A-TEXT", SLATE)

    ly = dy - 12.0
    sh.line((x, ly), (x + 20.0, ly), "RMR-A-LEVEL", TEAL)
    sh.tri((x - 3.0, ly - 3.0), 3.0, "RMR-A-LEVEL", TEAL)
    sh.text((x + 5.0, ly + 1.2), "+3.450", 2.4, "RMR-NUMBER", "RMR-A-LEVEL", INK)
    sh.text((x + 42.0, ly - 1.0), "RMR-LEVEL | datum marker and level text", 2.1, "RMR-NOTE",
            "RMR-A-TEXT", SLATE)

    ry = ly - 12.0
    sh.tri((x, ry - 3.0), 4.0, "RMR-A-REVISION", TERRA)
    sh.text((x + 2.0, ry - 1.6), "01", 1.8, "RMR-NUMBER", "RMR-A-REVISION", TERRA, align="middle")
    sh.text((x + 6.0, ry - 1.4), "ISSUED FOR REVIEW", 2.1, "RMR-NOTE", "RMR-A-REVISION", INK)
    sh.text((x + 42.0, ry - 1.4), "RMR-REVISION | RMR-REVTABLE logs the history", 2.1,
            "RMR-NOTE", "RMR-A-TEXT", SLATE)

    ny = ry - 20.0
    draw_north(sh, (x + 6.0, ny), 0.62)
    sh.text((x + 42.0, ny - 1.0), "RMR-NORTH | reusable block RMR-NORTH-ARROW", 2.1, "RMR-NOTE",
            "RMR-A-TEXT", SLATE)

    kx, ky2 = x + 214.0, ry + 2.0
    sh.rect((kx, ky2 - 30.0), 62.0, 46.0, "RMR-A-FRAME", INK)
    sh.solid((kx, ky2 + 8.5), 62.0, 7.5, "RMR-PRES-TITLE", TERRA)
    sh.text((kx + 2.5, ky2 + 10.4), "KEY PLAN", 3.4, "RMR-HEAD", "RMR-PRES-TITLE", SAND)
    sh.rect((kx + 2.5, ky2 - 27.5), 57.0, 34.0, "RMR-00-REF", SLATE)
    sh.text((kx + 2.5, ky2 - 33.5), "ADD SITE OUTLINE", 2.0, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    draw_north(sh, (kx + 50.0, ky2 - 8.0), 0.5)
    sh.text((kx + 2.5, ky2 - 22.0), "RMR-KEYPLAN", 2.1, "RMR-NOTE", "RMR-A-TEXT", SLATE)


def draw_materials(sh):
    x, y = MARGIN + 6.0, 92.0
    sh.text((x, y), "MATERIAL HATCH LIBRARY  |  RMR-HATCH", 3.0, "RMR-HEAD", "RMR-A-TEXT", TERRA)
    sh.line((x, y - 3.0), (292.0, y - 3.0), "RMR-A-TEXT", GOLD)
    cw, ch, gap = 42.0, 20.0, 4.0
    for index, spec in enumerate(DATA["hatches"]):
        key, label, pattern, scale, angle, layer, rgb, _desc = spec
        col, rowi = index % 6, index // 6
        ox = x + col * (cw + gap)
        oy = y - 10.0 - rowi * (ch + 12.0)
        pts = [(ox, oy - ch), (ox + cw, oy - ch), (ox + cw, oy), (ox, oy)]
        sh.hatch_pattern(pts, layer, tuple(int(v) for v in rgb), pattern, scale=0.6,
                         angle=float(angle))
        sh.rect((ox, oy - ch), cw, ch, "RMR-A-FRAME", INK)
        short = label if len(label) <= 17 else label[:16] + "."
        sh.text((ox + 1.5, oy + 2.4), "%s %s" % (key, short), 1.9, "RMR-HEAD", "RMR-A-TEXT", INK)
        sh.text((ox + 1.5, oy - ch - 3.8), "%s | %s" % (pattern, layer), 1.6, "RMR-MARK",
                "RMR-A-TEXT", SLATE)


def draw_notes(sh):
    x, y = 308.0, 92.0
    sh.text((x, y), "GENERAL NOTES  |  RMR-NOTES", 3.0, "RMR-HEAD", "RMR-A-TEXT", TERRA)
    sh.line((x, y - 3.0), (470.0, y - 3.0), "RMR-A-TEXT", GOLD)
    body = "\\P".join("%02d.   %s" % (i + 1, note) for i, note in enumerate(DATA["notes"]))
    sh.mtext((x, y - 8.0), body, 158.0, 2.2, "RMR-NOTE", "RMR-A-TEXT", PAPER)


def draw_area_schedule(sh):
    x, y = 20.0, 176.0
    sh.text((x, y), "ROOM AREA SCHEDULE  |  RMR-AREA", 3.0, "RMR-HEAD", "RMR-A-TEXT", TERRA)
    sh.text((x, y - 5.0), "SCALE 1:50   |   AREAS IN SQUARE METRES", 2.0, "RMR-NOTE",
            "RMR-A-TEXT", SLATE)
    colw = [16.0, 54.0, 24.0, 24.0]
    width, rowh = sum(colw), 8.0
    y -= 13.0
    top = y
    sh.solid((x, y - rowh), width, rowh, "RMR-PRES-TITLE", SAND)
    for i, head in enumerate(["NO.", "ROOM", "AREA m2", "AREA ft2"]):
        sh.text((x + sum(colw[:i]) + 2.0, y - rowh + 2.2), head, 2.6, "RMR-HEAD", "RMR-A-TEXT", INK)
    for i in range(len(colw) - 1):
        cx = x + sum(colw[: i + 1])
        sh.line((cx, y - rowh), (cx, y), "RMR-A-FRAME", INK)
    y -= rowh
    total = 0.0
    for number, name, (x1, y1), (x2, y2) in ROOMS:
        area = (x2 - x1) * (y2 - y1) / 1e6
        total += area
        sh.rect((x, y - rowh), width, rowh, "RMR-A-FRAME", SLATE)
        for i in range(len(colw) - 1):
            cx = x + sum(colw[: i + 1])
            sh.line((cx, y - rowh), (cx, y), "RMR-A-FRAME", SLATE)
        sh.text((x + 2.0, y - rowh + 2.2), number, 2.6, "RMR-NUMBER", "RMR-A-TEXT", TERRA)
        sh.text((x + colw[0] + 2.0, y - rowh + 2.2), name, 2.6, "RMR-LABEL", "RMR-A-TEXT", INK)
        sh.text((x + sum(colw[:2]) + 2.0, y - rowh + 2.2), "%.2f" % area, 2.6, "RMR-BODY",
                "RMR-A-TEXT", INK)
        sh.text((x + sum(colw[:3]) + 2.0, y - rowh + 2.2), "%.0f" % (area * 10.7639), 2.6,
                "RMR-BODY", "RMR-A-TEXT", SLATE)
        y -= rowh
    sh.solid((x, y - rowh), width, rowh, "RMR-PRES-TITLE", TERRA)
    sh.text((x + colw[0] + 2.0, y - rowh + 2.2), "TOTAL", 2.6, "RMR-HEAD", "RMR-PRES-TITLE", SAND)
    sh.text((x + sum(colw[:2]) + 2.0, y - rowh + 2.2), "%.2f" % total, 2.6, "RMR-NUMBER",
            "RMR-PRES-TITLE", SAND)
    sh.text((x + sum(colw[:3]) + 2.0, y - rowh + 2.2), "%.0f" % (total * 10.7639), 2.6,
            "RMR-NUMBER", "RMR-PRES-TITLE", SAND)
    y -= rowh
    sh.rect((x, y), width, top - y, "RMR-A-FRAME", INK)


def draw_revision_table(sh):
    rx, ry = 250.0, 176.0
    sh.text((rx, ry), "REVISION HISTORY  |  RMR-REVTABLE", 3.0, "RMR-HEAD", "RMR-A-TEXT", TERRA)
    sh.line((rx, ry - 3.0), (470.0, ry - 3.0), "RMR-A-TEXT", GOLD)
    colw = [14.0, 26.0, 80.0, 20.0, 20.0]
    width, rowh = sum(colw), 8.0
    ry -= 11.0
    top = ry
    sh.solid((rx, ry - rowh), width, rowh, "RMR-PRES-TITLE", SAND)
    for i, head in enumerate(["REV", "DATE", "DESCRIPTION", "BY", "CHK"]):
        sh.text((rx + sum(colw[:i]) + 2.0, ry - rowh + 2.2), head, 2.4, "RMR-HEAD",
                "RMR-A-TEXT", INK)
    for i in range(len(colw) - 1):
        cx = rx + sum(colw[: i + 1])
        sh.line((cx, ry - rowh), (cx, ry), "RMR-A-FRAME", INK)
    ry -= rowh
    rows = [("00", "2026-08-14", "PRELIMINARY LAYOUT ISSUED", "RMR", "AH"),
            ("01", "2026-09-30", "PRO SUITE STANDARD ADOPTED", "RMR", "AH"),
            ("02", "", "", "", ""),
            ("03", "", "", "", "")]
    for values in rows:
        sh.rect((rx, ry - rowh), width, rowh, "RMR-A-FRAME", SLATE)
        for i in range(len(colw) - 1):
            cx = rx + sum(colw[: i + 1])
            sh.line((cx, ry - rowh), (cx, ry), "RMR-A-FRAME", SLATE)
        for i, value in enumerate(values):
            if i == 0:
                sh.text((rx + 2.0, ry - rowh + 2.2), value, 2.4, "RMR-NUMBER", "RMR-A-REVISION", TERRA)
            else:
                sh.text((rx + sum(colw[:i]) + 2.0, ry - rowh + 2.2), value, 2.2, "RMR-BODY",
                        "RMR-A-TEXT", INK if i < 3 else SLATE)
        ry -= rowh
    sh.rect((rx, ry), width, top - ry, "RMR-A-FRAME", INK)


def draw_command_panel(sh):
    x, y = 480.0, 92.0
    sh.text((x, y), "PRODUCTION + STUDIO SUITE COMMANDS", 3.0, "RMR-HEAD", "RMR-A-TEXT", TERRA)
    sh.line((x, y - 3.0), (635.0, y - 3.0), "RMR-A-TEXT", GOLD)
    sh.text((x, y - 7.0), "31 shown of 45 - type RMR-PALETTE for the full guide", 1.9,
            "RMR-NOTE", "RMR-A-TEXT", SLATE)
    commands = [
        ("RMR-SCALE", "scale + annotation size"),
        ("RMR-GRID", "labelled structural grid"),
        ("RMR-AREA", "room areas + schedule"),
        ("RMR-HATCH", "material hatch library"),
        ("RMR-STAMP", "issue / status stamp"),
        ("RMR-NOTES", "numbered general notes"),
        ("RMR-REVTABLE", "revision history table"),
        ("RMR-CHECK", "standard compliance audit"),
        ("RMR-COUNT", "block takeoff + CSV"),
        ("RMR-LAYOUTS", "layout + title block + viewport"),
        ("RMR-VPORT", "scaled locked viewport"),
        ("RMR-SECTION", "cut line, arrows, bubbles"),
        ("RMR-ELEVATION", "elevation direction marker"),
        ("RMR-MATCHLINE", "phantom sheet match line"),
        ("RMR-BREAKLINE", "bulged break / cut line"),
        ("RMR-REVCLOUD", "rectangular or picked cloud"),
        ("RMR-SYMBOLS", "RMR-SYM-* block library"),
        ("RMR-DOORSCHED", "door schedule from blocks"),
        ("RMR-FINDTEXT", "find / replace text"),
        ("RMR-PROJECT", "project data show / set / save"),
    ]
    cy = y - 11.0
    for name, desc in commands:
        sh.text((x, cy), name, 2.1, "RMR-MARK", "RMR-A-TEXT", TEAL)
        sh.text((x + 44.0, cy), desc, 2.0, "RMR-NOTE", "RMR-A-TEXT", INK)
        cy -= 3.4
    sh.text((x, cy - 0.8), "RMR-BACKUP           timestamped drawing backup", 2.0,
            "RMR-NOTE", "RMR-A-TEXT", SLATE)


# --------------------------------------------------------------------------- #
# 8. studio suite sheet (4.0): layouts, title block, markers, symbols,
#    door schedule, project data and the new command set.
# --------------------------------------------------------------------------- #

def _panel(sh, x, y, w, h, title):
    sh.rect((x, y), w, h, "RMR-A-FRAME", SLATE)
    sh.solid((x, y + h - 7.0), w, 7.0, "RMR-PRES-TITLE", TERRA)
    sh.text((x + 3.0, y + h - 5.0), title, 2.6, "RMR-HEAD", "RMR-PRES-TITLE", SAND)
    return y + h - 12.0


def draw_studio_layouts(sh):
    x, y, w, h = 20.0, 396.0, 286.0, 148.0
    ty = _panel(sh, x, y, w, h, "LAYOUTS AND SCALED VIEWPORTS  |  RMR-LAYOUTS / RMR-VPORT")

    # an A3 sheet drawn at 0.30 inside the panel to show the layout recipe
    k = 0.30
    sheet_w, sheet_h = 420.0 * k, 297.0 * k      # 126.0 x 89.1
    sx, sy = x + 12.0, y + 34.0
    sh.rect((sx, sy), sheet_w, sheet_h, "RMR-PRES-VPORT", BLUE)
    sh.rect((sx + 6, sy + 6), sheet_w - 12, sheet_h - 12, "RMR-A-FRAME", INK)

    # viewport (locked) with a 1:50 label
    vpx, vpy = sx + 12.0, sy + 26.0
    vpw, vph = sheet_w - 24.0, sheet_h - 62.0
    sh.rect((vpx, vpy), vpw, vph, "RMR-PRES-VPORT", BLUE)
    sh.text((vpx + 4, vpy + vph - 8), "MODEL VIEW AT 1:50", 2.6, "RMR-LABEL",
            "RMR-A-TEXT", SLATE)
    sh.line((vpx + 4, vpy + vph - 12), (vpx + vpw - 4, vpy + vph - 12),
            "RMR-A-DIMS", TEAL)
    sh.text((vpx + 2, vpy - 4.0), "VIEWPORT 1:50 - LOCKED", 2.0, "RMR-LABEL",
            "RMR-A-TEXT", TEAL)

    # the branded title block strip along the bottom of the layout
    tb_w, tb_h = 99.0, 33.0
    tb_x, tb_y = sx + (sheet_w - tb_w) / 2.0, sy + 3.0
    sh.rect((tb_x, tb_y), tb_w, tb_h, "RMR-A-FRAME", INK)
    sh.line((tb_x + 22.0, tb_y), (tb_x + 22.0, tb_y + tb_h), "RMR-A-FRAME", INK)
    sh.line((tb_x + 77.0, tb_y), (tb_x + 77.0, tb_y + tb_h), "RMR-A-FRAME", INK)
    sh.line((tb_x, tb_y + tb_h - 9.0), (tb_x + 77.0, tb_y + tb_h - 9.0),
            "RMR-A-FRAME", INK)
    sh.line((tb_x, tb_y + 6.6), (tb_x + 77.0, tb_y + 6.6), "RMR-A-FRAME", INK)
    sh.text((tb_x + 2.0, tb_y + tb_h - 6.5), "RooMNRooF", 3.4, "RMR-TITLE",
            "RMR-A-TEXT", TERRA)
    sh.text((tb_x + 24.0, tb_y + tb_h - 5.0), "CLIENT", 1.4, "RMR-NOTE",
            "RMR-A-TEXT", SLATE)
    sh.text((tb_x + 24.0, tb_y + tb_h - 8.0), project("CLIENT"), 2.0, "RMR-BODY",
            "RMR-A-TEXT", INK)
    sh.text((tb_x + 24.0, tb_y + 8.6), "DRAWING TITLE", 1.4, "RMR-NOTE",
            "RMR-A-TEXT", SLATE)
    sh.text((tb_x + 24.0, tb_y + 2.0), project("TITLE"), 2.4, "RMR-SUBHEAD",
            "RMR-A-TEXT", INK)
    sh.text((tb_x + 79.0, tb_y + tb_h - 5.0), "DWG NO.", 1.4, "RMR-NOTE",
            "RMR-A-TEXT", SLATE)
    sh.text((tb_x + 79.0, tb_y + tb_h - 8.6), project("DWGNO"), 3.0, "RMR-NUMBER",
            "RMR-A-TEXT", TERRA)

    notes = [
        "RMR-LAYOUTS  creates the layout, sets the paper size,",
        "inserts RMR-TITLEBLOCK with live attributes and places",
        "a viewport at a chosen scale, then locks its display.",
        "RMR-VPORT     adds further scaled, locked viewports.",
    ]
    ny = sy + sheet_h - 6.0
    for i, line in enumerate(notes):
        sh.text((sx, ny - i * 4.4), line, 2.0, "RMR-NOTE", "RMR-A-TEXT", SLATE)


def draw_studio_titleblock(sh):
    x, y, w, h = 20.0, 232.0, 286.0, 156.0
    ty = _panel(sh, x, y, w, h, "BRANDED TITLE BLOCK  |  RMR-TITLEBLOCK + RMR-PROJECT")

    k = 1.45                      # block is 180 x 60 mm
    bw, bh = 180.0 * k, 60.0 * k  # 261 x 87
    bx, by = x + 12.0, y + 8.0

    sh.rect((bx, by), bw, bh, "RMR-A-FRAME", INK)
    # the same division lines the AutoLISP block builds
    for fx in (40.0, 140.0):
        sh.line((bx + fx * k, by), (bx + fx * k, by + bh), "RMR-A-FRAME", INK)
    for fy in (44.0, 34.0, 12.0):
        sh.line((bx + 40.0 * k, by + fy * k), (bx + 140.0 * k, by + fy * k),
                "RMR-A-FRAME", INK)
    sh.line((bx + 70.0 * k, by), (bx + 70.0 * k, by + 12.0 * k), "RMR-A-FRAME", INK)
    sh.line((bx + 100.0 * k, by), (bx + 100.0 * k, by + 12.0 * k), "RMR-A-FRAME", INK)
    sh.line((bx + 140.0 * k, by + 44.0 * k), (bx + bw, by + 44.0 * k), "RMR-A-FRAME", INK)
    sh.line((bx + 160.0 * k, by + 44.0 * k), (bx + 160.0 * k, by + bh), "RMR-A-FRAME", INK)
    sh.line((bx + 140.0 * k, by + 16.0 * k), (bx + bw, by + 16.0 * k), "RMR-A-FRAME", INK)
    sh.line((bx + 6.0 * k, by + 40.0 * k), (bx + 34.0 * k, by + 40.0 * k),
            "RMR-A-FRAME", INK)

    sh.text((bx + 6.0 * k, by + 28.0 * k), "RooMNRooF", 6.0 * k, "RMR-TITLE",
            "RMR-A-TEXT", TERRA)
    sh.text((bx + 6.0 * k, by + 20.0 * k), "CONSULTANT", 2.4 * k, "RMR-LABEL",
            "RMR-A-TEXT", SLATE)
    sh.text((bx + 6.0 * k, by + 8.0 * k), "ROOF THE ROOM", 2.4 * k, "RMR-LABEL",
            "RMR-A-TEXT", SLATE)

    def lbl(px, py, text, size=2.0, style="RMR-LABEL", rgb=None):
        sh.text((bx + px * k, by + py * k), text, size * k, style, "RMR-A-TEXT",
                rgb if rgb else SLATE)

    def val(px, py, text, size=3.2, style="RMR-BODY", rgb=None):
        sh.text((bx + px * k, by + py * k), text, size * k, style, "RMR-A-TEXT",
                rgb if rgb else INK)

    lbl(42.0, 54.0, "CLIENT")
    val(42.0, 47.0, project("CLIENT"))
    lbl(42.0, 40.0, "PROJECT")
    val(42.0, 35.5, project("PROJECT"), 3.0)
    lbl(42.0, 28.0, "DRAWING TITLE")
    val(42.0, 18.0, project("TITLE"), 5.0, "RMR-SUBHEAD")
    lbl(42.0, 8.0, "DRAWN", 1.8)
    val(42.0, 3.0, project("DRAWN"), 2.5, "RMR-LABEL")
    lbl(72.0, 8.0, "CHECKED", 1.8)
    val(72.0, 3.0, project("CHECKED"), 2.5, "RMR-LABEL")
    lbl(102.0, 8.0, "DATE", 1.8)
    val(102.0, 3.0, project("DATE"), 2.5, "RMR-LABEL")
    lbl(142.0, 54.0, "SIZE", 1.8)
    val(142.0, 47.0, project("SIZE"), 3.5, "RMR-NUMBER")
    lbl(162.0, 54.0, "SCALE", 1.8)
    val(162.0, 47.0, project("SCALE"), 3.0, "RMR-LABEL")
    lbl(142.0, 38.0, "DRAWING NO.")
    val(142.0, 22.0, project("DWGNO"), 7.0, "RMR-HEAD", TERRA)
    lbl(142.0, 12.0, "REV", 1.8)
    val(142.0, 4.0, project("REV"), 4.0, "RMR-NUMBER", TERRA)

    sh.text((x + 3.0, y + 4.0),
            "Attributes are filled from *RMR-PROJECT* by RMR-PROJECT / FILLTITLE.",
            1.9, "RMR-NOTE", "RMR-A-TEXT", SLATE)


def draw_studio_project(sh):
    x, y, w, h = 20.0, 74.0, 286.0, 150.0
    ty = _panel(sh, x, y, w, h, "PROJECT DATA  |  *RMR-PROJECT*  |  RMR-PROJECT")

    pairs = DATA["project"]
    half = (len(pairs) + 1) // 2
    columns = (pairs[:half], pairs[half:])
    for col, items in enumerate(columns):
        cx = x + 6.0 + col * 142.0
        cy = ty
        for tag, value in items:
            sh.text((cx, cy), tag, 2.1, "RMR-MARK", "RMR-A-TEXT", TEAL)
            text = value if value else "(blank - set by RMR-PROJECT)"
            sh.text((cx + 26.0, cy), text, 2.1, "RMR-BODY", "RMR-A-TEXT",
                    INK if value else SLATE)
            cy -= 5.0

    cy -= 4.0
    sh.text((x + 6.0, cy), "RMR-PROJECT SHOW / SET / FILLTITLE / SAVE / LOAD", 2.2,
            "RMR-HEAD", "RMR-A-TEXT", TERRA)
    cy -= 5.0
    sh.text((x + 6.0, cy), "RMR-FIELDS inserts live fields (date, drawing, layout,",
            1.9, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    cy -= 4.0
    sh.text((x + 6.0, cy), "area, block name) or project values as static text.",
            1.9, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    cy -= 4.0
    sh.text((x + 6.0, cy), "RMR-BACKUP writes BACKUP_YYYYMMDD-HHMM_<drawing>.dwg",
            1.9, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    cy -= 4.0
    sh.text((x + 6.0, cy), "Cloud bulge factor *RMR-CLOUD-ARC* = %.2f" % DATA["cloud_arc"],
            1.9, "RMR-NOTE", "RMR-A-TEXT", SLATE)


def draw_studio_markers(sh):
    x, y, w, h = 316.0, 74.0, 250.0, 470.0
    ty = _panel(sh, x, y, w, h, "MARKERS  |  SECTION, ELEVATION, MATCH, BREAK, CLOUD")

    s = 1.0
    # --- section -----------------------------------------------------------
    sy = ty - 6.0
    sh.text((x + 6.0, sy), "RMR-SECTION", 2.4, "RMR-HEAD", "RMR-A-TEXT", TERRA)
    sh.text((x + 66.0, sy), "cut line, arrows, numbered sheet bubbles", 1.9,
            "RMR-NOTE", "RMR-A-TEXT", SLATE)
    p1 = (x + 20.0, sy - 34.0)
    p2 = (x + 130.0, sy - 34.0)
    sh.line(p1, p2, "RMR-A-DETAIL", TERRA)
    for end in (p1, p2):
        sh.line(end, (end[0], end[1] + 12.0), "RMR-A-DETAIL", TERRA)
        sh.tri((end[0] - 3.0, end[1] + 12.0), 6.0, "RMR-A-DETAIL", TERRA)
    for cx, num in ((p1[0] - 18.0, "1"), (p2[0] + 18.0, "1")):
        c = (cx, sy - 34.0)
        r = 7.0
        sh.circle(c, r, "RMR-A-DETAIL", TERRA)
        sh.line((c[0] - r, c[1]), (c[0] + r, c[1]), "RMR-A-DETAIL", TERRA)
        sh.text((c[0], c[1] + 2.4), num, 4.4, "RMR-NUMBER", "RMR-A-DETAIL", INK,
                align="middle")
        sh.text((c[0], c[1] - 4.4), project("DWGNO"), 3.0, "RMR-LABEL",
                "RMR-A-DETAIL", INK, align="middle")
    sh.text((x + 6.0, sy - 52.0), "Viewing side is picked, so the arrows always point",
            1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((x + 6.0, sy - 55.4), "away from the cut towards the drawn elevation.",
            1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)

    # --- elevation ---------------------------------------------------------
    ey = sy - 66.0
    sh.text((x + 6.0, ey), "RMR-ELEVATION", 2.4, "RMR-HEAD", "RMR-A-TEXT", TERRA)
    sh.text((x + 66.0, ey), "direction angle, number, sheet reference", 1.9,
            "RMR-NOTE", "RMR-A-TEXT", SLATE)
    c = (x + 26.0, ey - 26.0)
    r = 7.0
    sh.circle(c, r, "RMR-A-DETAIL", TEAL)
    sh.line((c[0] - r, c[1]), (c[0] + r, c[1]), "RMR-A-DETAIL", TEAL)
    sh.text((c[0], c[1] + 2.4), "E1", 4.4, "RMR-NUMBER", "RMR-A-DETAIL", INK,
            align="middle")
    sh.text((c[0], c[1] - 4.6), project("DWGNO"), 3.0, "RMR-LABEL", "RMR-A-DETAIL",
            INK, align="middle")
    tip_x = c[0] + r + 10.0
    sh.line((c[0] + r, c[1]), (tip_x, c[1]), "RMR-A-DETAIL", TEAL)
    sh.tri((tip_x - 6.0, c[1] - 3.0), 6.0, "RMR-A-DETAIL", TEAL)
    sh.text((x + 60.0, ey - 26.0), "Number above the bar, sheet below, arrow along the",
            1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((x + 60.0, ey - 29.4), "viewing direction you type in degrees.",
            1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)

    # --- match line --------------------------------------------------------
    my = ey - 46.0
    sh.text((x + 6.0, my), "RMR-MATCHLINE", 2.4, "RMR-HEAD", "RMR-A-TEXT", TERRA)
    sh.text((x + 66.0, my), "phantom line, upright labels both ends", 1.9,
            "RMR-NOTE", "RMR-A-TEXT", SLATE)
    m1 = (x + 16.0, my - 22.0)
    m2 = (x + 150.0, my - 22.0)
    sh.line(m1, m2, "RMR-A-MATCH", SLATE)
    sh.text((m1[0], m1[1] + 3.0), "MATCH LINE - SEE A-102", 2.2, "RMR-LABEL",
            "RMR-A-MATCH", SLATE)
    sh.text((m2[0], m2[1] + 3.0), "MATCH LINE - SEE A-102", 2.2, "RMR-LABEL",
            "RMR-A-MATCH", SLATE)
    sh.text((x + 16.0, my - 34.0), "Text is flipped through 180 degrees in the 90..270",
            1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((x + 16.0, my - 37.4), "range so every label stays readable.",
            1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)

    # --- break line --------------------------------------------------------
    by = my - 50.0
    sh.text((x + 6.0, by), "RMR-BREAKLINE", 2.4, "RMR-HEAD", "RMR-A-TEXT", TERRA)
    sh.text((x + 66.0, by), "bulged polyline on RMR-A-MATCH", 1.9, "RMR-NOTE",
            "RMR-A-TEXT", SLATE)
    b1 = (x + 16.0, by - 20.0)
    b2 = (x + 150.0, by - 20.0)
    span = b2[0] - b1[0]
    pts = [b1,
           (b1[0] + span * 0.40, b1[1]),
           (b1[0] + span * 0.50, b1[1]),
           (b1[0] + span * 0.60, b1[1]),
           b2]
    sh.poly(pts, [0.0, 0.9, -0.9, 0.0, 0.0], False, "RMR-A-MATCH", SLATE)

    # --- revision cloud ----------------------------------------------------
    cy = by - 44.0
    sh.text((x + 6.0, cy), "RMR-REVCLOUD", 2.4, "RMR-HEAD", "RMR-A-TEXT", TERRA)
    sh.text((x + 66.0, cy), "two corners build a rectangular cloud", 1.9, "RMR-NOTE",
            "RMR-A-TEXT", SLATE)
    ca = (x + 16.0, cy - 74.0)
    cb = (x + 150.0, cy - 14.0)
    step = 16.0
    cloud = [(round(v, 4), round(w, 4)) for v, w in _rect_samples(ca, cb, step)]
    sh.poly(cloud, [DATA["cloud_arc"]] * len(cloud), True, "RMR-A-REVISION", TERRA)
    sh.text((ca[0] + 6.0, ca[1] + 4.0), "REV 01 ISSUED FOR REVIEW", 2.2, "RMR-NOTE",
            "RMR-A-REVISION", TERRA)

    # --- dimension launcher ------------------------------------------------
    dy = cy - 86.0
    sh.text((x + 6.0, dy), "RMR-DIM", 2.4, "RMR-HEAD", "RMR-A-TEXT", TERRA)
    sh.text((x + 66.0, dy), "style + linear / aligned / radial / angular", 1.9,
            "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((x + 6.0, dy - 6.0),
            "Puts the chosen RMR-DIM-* style current on RMR-A-DIMS, then starts",
            1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((x + 6.0, dy - 9.4),
            "the AutoCAD dimension command you pick from the list.",
            1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((x + 6.0, dy - 16.0), "RMR-FINDTEXT  find / replace TEXT, MTEXT, ATTRIB",
            2.0, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((x + 6.0, dy - 19.4), "RMR-SYMBOLS   rebuild the RMR-SYM-* library",
            2.0, "RMR-NOTE", "RMR-A-TEXT", SLATE)


def _rect_samples(a, b, step):
    """Same sampling the LISP RMR:RectSamples uses for rectangular clouds."""
    import math
    edges = ((a, (b[0], a[1])), ((b[0], a[1]), b), (b, (a[0], b[1])),
             ((a[0], b[1]), a))
    pts = []
    for p, q in edges:
        length = math.dist(p, q)
        n = max(2, int(length / step))
        d = length / float(n)
        ang = math.atan2(q[1] - p[1], q[0] - p[0])
        for i in range(n):
            pts.append((p[0] + math.cos(ang) * d * i, p[1] + math.sin(ang) * d * i))
    return pts


def project(tag):
    for key, value in DATA["project"]:
        if key == tag:
            return value if value else tag
    return tag


def _sym(sh, name, ox, oy, cell):
    """Draw one RMR-SYM-* block scaled to fit the cell (mm in, sheet mm out)."""
    import math
    rects, lines, arcs, circles = SYMBOLS[name]
    xs = [v for item in rects for v in (item[0], item[0] + item[2])]
    xs += [v for item in lines for v in (item[0], item[2])]
    xs += [c[0] - c[2] for c in circles] + [c[0] + c[2] for c in circles]
    ys = [v for item in rects for v in (item[1], item[1] + item[3])]
    ys += [v for item in lines for v in (item[1], item[3])]
    ys += [c[1] - c[2] for c in circles] + [c[1] + c[2] for c in circles]
    xs += [a[0] + a[2] for a in arcs] + [a[0] - a[2] for a in arcs]
    ys += [a[1] + a[2] for a in arcs] + [a[1] - a[2] for a in arcs]
    span = max(max(xs) - min(xs), max(ys) - min(ys), 1.0)
    k = (cell - 10.0) / span
    kx = ox - min(xs) * k
    ky = oy - min(ys) * k

    def tp(p):
        return (kx + p[0] * k, ky + p[1] * k)

    for rx, ry, rw, rh in rects:
        sh.rect(tp((rx, ry)), rw * k, rh * k, "RMR-F-FURNITURE", TEAL)
    for x1, y1, x2, y2 in lines:
        sh.line(tp((x1, y1)), tp((x2, y2)), "RMR-F-FURNITURE", TEAL)
    for cx, cy, r, a1, a2 in arcs:
        # angles are stored in degrees, ezdxf wants radians
        sh.arc(tp((cx, cy)), r * k, math.radians(a1), math.radians(a2),
               "RMR-F-FURNITURE", TEAL)
    for cx, cy, r in circles:
        sh.circle(tp((cx, cy)), r * k, "RMR-F-FURNITURE", TEAL)


SYMBOLS = {
    # name: (rects, lines, arcs(cx,cy,r,a1,a2 deg), circles(cx,cy,r)) - mm
    "DOOR-07":  ([], [(0, 0, 0, 700)], [(0, 0, 700, 0, 90)], []),
    "DOOR-08":  ([], [(0, 0, 0, 800)], [(0, 0, 800, 0, 90)], []),
    "DOOR-09":  ([], [(0, 0, 0, 900)], [(0, 0, 900, 0, 90)], []),
    "DOORD-15": ([], [(0, 0, 0, 750), (1500, 0, 1500, 750)],
                [(0, 0, 750, 0, 90), (1500, 0, 750, 90, 180)], []),
    "WINDOW":   ([(0, 0, 1200, 200)], [(0, 70, 1200, 70), (0, 130, 1200, 130)], [], []),
    "WC":       ([(0, 350, 400, 150)], [], [], [(200, 175, 175)]),
    "BASIN":    ([(0, 0, 500, 400)], [], [], [(250, 200, 90)]),
    "SHOWER":   ([(0, 0, 900, 900)], [(0, 0, 900, 900), (900, 0, 0, 900)],
                [], [(450, 450, 60)]),
    "BED-S":    ([(0, 0, 1000, 2000), (300, 1750, 400, 200)],
                [(0, 1700, 1000, 1700)], [], []),
    "BED-D":    ([(0, 0, 1500, 2000), (200, 1750, 450, 200), (850, 1750, 450, 200)],
                [(0, 1700, 1500, 1700)], [], []),
    "DESK":     ([(0, 0, 1400, 700)], [(0, 600, 1400, 600)], [], []),
    "CHAIR":    ([(0, 0, 450, 450), (0, 450, 450, 80)], [], [], []),
    "SOFA":     ([(0, 0, 1800, 850)], [(0, 700, 1800, 700), (150, 0, 150, 850),
                                      (1650, 0, 1650, 850)], [], []),
    "WASHER":   ([(0, 0, 600, 600)], [], [], [(300, 300, 200)]),
}


def draw_studio_symbols(sh):
    x, y, w, h = 576.0, 300.0, 250.0, 244.0
    ty = _panel(sh, x, y, w, h, "PARAMETRIC SYMBOL LIBRARY  |  RMR-SYMBOLS")

    order = ["DOOR-07", "DOOR-08", "DOOR-09", "DOORD-15", "WINDOW", "WC", "BASIN",
             "SHOWER", "BED-S", "BED-D", "DESK", "CHAIR", "SOFA", "WASHER"]
    cols, cell = 5, 46.0
    gy = ty - 4.0
    for i, name in enumerate(order):
        col, row = i % cols, i // cols
        cx = x + 4.0 + col * 49.0
        cy = gy - row * 58.0 - 46.0
        sh.rect((cx, cy), 45.0, 45.0, "RMR-00-REF", SLATE)
        _sym(sh, name, cx + 3.0, cy + 3.0, 42.0)
        sh.text((cx + 22.5, cy - 4.0), "RMR-SYM-%s" % name, 1.7, "RMR-MARK",
                "RMR-A-TEXT", INK, align="center")
    sh.text((x + 4.0, y + 4.0),
            "Doors carry TAG and WIDTH attributes for RMR-DOORSCHED.", 1.9,
            "RMR-NOTE", "RMR-A-TEXT", SLATE)


DOOR_ROWS = [("D01", "900", "SINGLE LEAF"), ("D02", "800", "SINGLE LEAF"),
         ("D03", "700", "SINGLE LEAF"), ("D04", "900", "SINGLE LEAF"),
         ("D05", "1500", "DOUBLE LEAF"), ("D06", "800", "SINGLE LEAF")]


def draw_studio_doors(sh):
    x, y, w, h = 576.0, 74.0, 250.0, 216.0
    ty = _panel(sh, x, y, w, h, "DOOR SCHEDULE  |  RMR-DOORSCHED")

    colw = [22.0, 46.0, 96.0, 66.0]
    width = sum(colw)
    rowh = 8.0
    header = ["NO.", "TAG", "TYPE", "WIDTH mm"]
    top = ty - 6.0
    sh.solid((x + 4.0, top - rowh), width, rowh, "RMR-PRES-TITLE", SAND)
    cx = x + 4.0
    for i, label in enumerate(header):
        sh.text((cx + 2.0, top - rowh + 2.2), label, 2.4, "RMR-HEAD", "RMR-A-TEXT",
                INK)
        if i < len(colw) - 1:
            cx += colw[i]
            sh.line((cx, top - rowh), (cx, top), "RMR-A-FRAME", INK)
    cy = top - rowh
    for i, (tag, wid, typ) in enumerate(DOOR_ROWS):
        sh.rect((x + 4.0, cy - rowh), width, rowh, "RMR-A-FRAME", SLATE)
        cx = x + 4.0
        values = [str(i + 1), tag, typ, wid]
        for j in range(len(colw) - 1):
            cx += colw[j]
            sh.line((cx, cy - rowh), (cx, cy), "RMR-A-FRAME", SLATE)
        sh.text((x + 6.0, cy - rowh + 2.2), values[0], 2.3, "RMR-NUMBER",
                "RMR-A-TEXT", TERRA)
        sh.text((x + 4.0 + colw[0] + 2.0, cy - rowh + 2.2), values[1], 2.3,
                "RMR-LABEL", "RMR-A-TEXT", INK)
        sh.text((x + 4.0 + colw[0] + colw[1] + 2.0, cy - rowh + 2.2), values[2],
                2.3, "RMR-BODY", "RMR-A-TEXT", INK)
        sh.text((x + 4.0 + colw[0] + colw[1] + colw[2] + 2.0, cy - rowh + 2.2),
                values[3], 2.3, "RMR-BODY", "RMR-A-TEXT", SLATE)
        cy -= rowh
    sh.text((x + 4.0, y + 4.0),
            "Sorted by tag from the TAG / WIDTH attributes of inserted blocks.",
            1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)


def build_studio():
    doc = build_document()
    sh = Sheet(doc)
    draw_frame(sh)
    draw_header(sh)
    draw_studio_layouts(sh)
    draw_studio_titleblock(sh)
    draw_studio_project(sh)
    draw_studio_markers(sh)
    draw_studio_symbols(sh)
    draw_studio_doors(sh)
    draw_title_block(sh)
    return doc


# --------------------------------------------------------------------------- #
# 7. assemble, save, render
# --------------------------------------------------------------------------- #
def build():
    doc = build_document()
    sh = Sheet(doc)
    draw_frame(sh)
    draw_header(sh)
    draw_title_block(sh)
    draw_grid(sh)
    draw_structure(sh)
    draw_rooms(sh)
    draw_walls(sh)
    draw_openings(sh)
    draw_furniture(sh)
    draw_plumbing(sh)
    draw_room_tags(sh)
    draw_dimensions(sh)
    draw_plan_annotation(sh)
    draw_north(sh)
    draw_scale_bar(sh)
    draw_area_schedule(sh)
    draw_revision_table(sh)
    draw_stamp(sh, (150.0, 490.0), "ISSUED FOR REVIEW", BLUE, angle_deg=-12.0)
    draw_stamp(sh, (392.0, 208.0), "DO NOT SCALE", TERRA, width=76.0, height=20.0,
               angle_deg=0.0, revision="A-000", date="SHEET 1 OF 1")
    draw_legend(sh)
    draw_text_styles(sh)
    draw_symbols(sh)
    draw_materials(sh)
    draw_notes(sh)
    draw_command_panel(sh)
    return doc


def render_png(doc, path, xlim=None, ylim=None, dpi=110, figsize=None):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    from ezdxf.addons.drawing import Frontend, RenderContext
    from ezdxf.addons.drawing.matplotlib import MatplotlibBackend

    if figsize is None:
        figsize = (SHEET_W / 25.4, SHEET_H / 25.4)
    fig = plt.figure(figsize=figsize)
    ax = fig.add_axes([0, 0, 1, 1])
    ctx = RenderContext(doc)
    backend = MatplotlibBackend(ax)
    Frontend(ctx, backend).draw_layout(doc.modelspace(), finalize=(xlim is None))
    # ezdxf's backend.finalize() resizes the figure to the model extents, so the
    # intended sheet size has to be restored before saving.
    fig.set_size_inches(figsize[0], figsize[1], forward=True)
    if xlim:
        # box-adjustable keeps the requested window while staying square
        ax.set_aspect("equal", adjustable="box")
        ax.set_xlim(*xlim)
        ax.set_ylim(*ylim)
        ax.set_axis_off()
    fig.savefig(path, dpi=dpi, facecolor="white")
    plt.close(fig)
    return path


def main():
    if not os.path.isdir(OUT_DIR):
        os.makedirs(OUT_DIR)
    doc = build()
    dxf_path = os.path.join(OUT_DIR, "RooMNRooF_PRO_Standard_Preview.dxf")
    doc.saveas(dxf_path)
    print("DXF  :", dxf_path, os.path.getsize(dxf_path), "bytes")
    try:
        print("PNG  :", render_png(doc, os.path.join(OUT_DIR, "RooMNRooF_PRO_Standard_Preview.png"),
                                   dpi=150))
        print("ZOOM :", render_png(doc, os.path.join(OUT_DIR, "RooMNRooF_PRO_Plan_Detail.png"),
                                   xlim=(25, 355), ylim=(90, 470), dpi=190,
                                   figsize=(330 / 25.4, 380 / 25.4)))
    except Exception as exc:
        print("PNG render skipped:", exc)
    std = build_studio()
    std_path = os.path.join(OUT_DIR, "RooMNRooF_PRO_Studio_Suite.dxf")
    std.saveas(std_path)
    print("DXF  :", std_path, os.path.getsize(std_path), "bytes")
    try:
        print("PNG  :", render_png(std, os.path.join(OUT_DIR, "RooMNRooF_PRO_Studio_Suite.png"),
                                   dpi=150))
    except Exception as exc:
        print("Studio PNG render skipped:", exc)
    print("layers: %d | styles: %d | dimstyles: %d | materials: %d | notes: %d | version: %s"
          % (len(DATA["layers"]), len(DATA["styles"]), len(DATA["dimstyles"]),
             len(DATA["hatches"]), len(DATA["notes"]), VERSION))
    print("project tags: %d | symbols: %d | doors: %d | cloud arc: %s"
          % (len(DATA["project"]), len(SYMBOLS), len(DOOR_ROWS), DATA["cloud_arc"]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
