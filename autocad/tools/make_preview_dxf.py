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
        "walls": _extract_form(src, "*RMR-WALL-SPECS*"),
        "finishes": _extract_form(src, "*RMR-FINISH-SPECS*"),
        "sheets": _extract_form(src, "*RMR-SHEET-LIST*"),
        "levels": _extract_form(src, "*RMR-LEVEL-SPECS*"),
        # dotted pairs arrive as [number, ".", text]
        "keynotes": [(item[0], item[2]) if len(item) > 2 else (item[0], "")
                     for item in _extract_form(src, "*RMR-KEYNOTES*")],
        "cities": [(item[0], item[1])
                   for item in _extract_form(src, "*RMR-SUN-CITIES*")],
        "zones": _extract_form(src, "*RMR-ZONE-BANDS*"),
        "specs": _extract_form(src, "*RMR-SPEC-CLAUSES*"),
        "abbrevs": _extract_form(src, "*RMR-ABBREV-SPECS*"),
        "revisions": _extract_form(src, "*RMR-REVISIONS*"),
        "checklist": _extract_form(src, "*RMR-CHECKLIST-SPECS*"),
        "buildups": _extract_form(src, "*RMR-BUILDUP-SPECS*"),
        "programme": _extract_form(src, "*RMR-PROGRAMME-SPECS*"),
        "mood": _extract_form(src, "*RMR-MOOD-SPECS*"),
        "rates": _extract_form(src, "*RMR-RATE-SPECS*"),
        "elements": _extract_form(src, "*RMR-ELEMENT-SPECS*"),
        "auto": _extract_form(src, "*RMR-AUTO-SEQUENCE*"),
        "columns": _extract_form(src, "*RMR-COLUMN-SPECS*"),
        "beams": _extract_form(src, "*RMR-BEAM-SPECS*"),
        "rebar": _extract_form(src, "*RMR-REBAR-SPECS*"),
        "ducts": _extract_form(src, "*RMR-DUCT-SPECS*"),
        "pipes": _extract_form(src, "*RMR-PIPE-SPECS*"),
        "service_zones": _extract_form(src, "*RMR-SERVICE-ZONES*"),
        "service_layer_zones": _extract_form(src, "*RMR-SERVICE-LAYER-ZONES*"),
        "details": _extract_form(src, "*RMR-DETAIL-SPECS*"),
        "junctions": _extract_form(src, "*RMR-JUNCTION-SPECS*"),
        "materials": _extract_form(src, "*RMR-MATERIAL-R-SPECS*"),
        "fire": _extract_form(src, "*RMR-FIRE-SPECS*"),
        "acoustic": _extract_form(src, "*RMR-ACOUSTIC-SPECS*"),
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
    sh.text((x, y - 7.0), "Selected commands - type RMR-PALETTE for all 57", 1.9,
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
# 9. delivery suite sheet (5.0): parametric walls and stairs, quantification,
#    finishes, drawing register, transmittal, xrefs and housekeeping.
# --------------------------------------------------------------------------- #

WALL_K = 0.019          # millimetres -> sheet units for the sample plans


def _plan(ox, oy, pts, k=WALL_K):
    return [(ox + p[0] * k, oy + p[1] * k) for p in pts]


def _offset_path(pts, d):
    """Mirror of the LISP RMR:OffsetPath (mitred polyline offset)."""
    import math
    out = []
    n = len(pts)
    for i, cur in enumerate(pts):
        if i == 0:
            n1 = _unit_normal(cur, pts[i + 1])
        elif i == n - 1:
            n1 = _unit_normal(pts[i - 1], cur)
        else:
            n1, n2 = _unit_normal(pts[i - 1], cur), _unit_normal(cur, pts[i + 1])
            mx, my = n1[0] + n2[0], n1[1] + n2[1]
            L = math.hypot(mx, my)
            if L < 1e-6:
                mx, my, L = n1[0], n1[1], 1.0
            sc = d / ((mx * n1[0] + my * n1[1]) / L)
            if abs(sc) > 4 * abs(d):
                sc = 4 * abs(d) * (1 if d >= 0 else -1)
            if abs(sc) < abs(d):
                sc = d
            n1 = (mx / L * sc, my / L * sc)
            out.append((cur[0] + n1[0], cur[1] + n1[1]))
            continue
        out.append((cur[0] + n1[0] * d, cur[1] + n1[1] * d))
    return out


def _unit_normal(p1, p2):
    import math
    dx, dy = p2[0] - p1[0], p2[1] - p1[1]
    L = math.hypot(dx, dy)
    return (0.0, 0.0) if L < 1e-6 else (-dy / L, dx / L)


def _wall(sh, ox, oy, pts, thickness, layer, rgb, k=WALL_K):
    d = thickness / 2.0
    left = _plan(ox, oy, _offset_path(pts, d), k)
    right = _plan(ox, oy, _offset_path(pts, -d), k)
    sh.poly(left, [0.0] * len(left), False, layer, rgb)
    sh.poly(right, [0.0] * len(right), False, layer, rgb)
    sh.line(left[0], right[0], layer, rgb)
    sh.line(left[-1], right[-1], layer, rgb)
    return left, right


def _stair(sh, ox, oy, width, going, risers, angle_deg, layer, rgb, k=WALL_K):
    import math
    a = math.radians(angle_deg)
    dx, dy = math.cos(a), math.sin(a)
    nx, ny = -dy, dx
    total = risers * going
    p1 = (0.0, 0.0)
    p2 = (nx * width, ny * width)
    p3 = (p2[0] + dx * total, p2[1] + dy * total)
    p4 = (dx * total, dy * total)
    outline = _plan(ox, oy, [p1, p4, p3, p2], k)
    sh.poly(outline, [0.0] * 4, True, layer, rgb)
    for i in range(1, risers):
        t = i * going
        sh.line(_plan(ox, oy, [(dx * t, dy * t),
                               (p2[0] + dx * t, p2[1] + dy * t)], k)[0],
                _plan(ox, oy, [(dx * t, dy * t),
                               (p2[0] + dx * t, p2[1] + dy * t)], k)[1],
                layer, rgb)
    mx, my = nx * width / 2.0, ny * width / 2.0
    sh.line(_plan(ox, oy, [(mx, my)], k)[0],
            _plan(ox, oy, [(mx + dx * total, my + dy * total)], k)[0],
            "RMR-A-ARROW", TERRA)
    tip = _plan(ox, oy, [(mx + dx * total, my + dy * total)], k)[0]
    sh.tri((tip[0] - 6.0 * dx, tip[1] - 6.0 * dy), 6.0, "RMR-A-ARROW", TERRA)
    return total


def draw_delivery_walls(sh):
    x, y, w, h = 20.0, 396.0, 286.0, 140.0
    ty = _panel(sh, x, y, w, h, "PARAMETRIC WALLS  |  RMR-WALL")

    ox, oy = x + 14.0, y + 16.0
    # sample apartment corner: 200 external, 100 internal partition
    ext = [(0, 0), (6200, 0), (6200, 4200), (0, 4200), (0, 0)]
    _wall(sh, ox, oy, ext, 200.0, "RMR-S-SLAB", BLUE)
    _wall(sh, ox, oy, [(2400, 200), (2400, 4200)], 100.0, "RMR-M-WALL", TERRA)
    _wall(sh, ox, oy, [(2400, 2400), (6200, 2400)], 100.0, "RMR-M-WALL", TERRA)

    # opening gaps shown as door swings on the internal wall
    sh.arc(_plan(ox, oy, [(2400, 2600)], WALL_K)[0], 900 * WALL_K, 0.0,
           math.radians(90.0), "RMR-M-DOOR", GOLD)
    sh.line(_plan(ox, oy, [(2400, 2600)], WALL_K)[0],
            _plan(ox, oy, [(2400, 3500)], WALL_K)[0], "RMR-M-DOOR", GOLD)
    sh.arc(_plan(ox, oy, [(3400, 2400)], WALL_K)[0], 800 * WALL_K,
           math.radians(90.0), math.radians(180.0), "RMR-M-DOOR", GOLD)
    sh.line(_plan(ox, oy, [(3400, 2400)], WALL_K)[0],
            _plan(ox, oy, [(4200, 2400)], WALL_K)[0], "RMR-M-DOOR", GOLD)

    sh.text((ox + 8.0, oy - 5.0), "Sample drawn from a picked path - corners are mitred",
            1.9, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((ox + 8.0, oy - 8.4), "so both faces stay exactly on thickness.",
            1.9, "RMR-NOTE", "RMR-A-TEXT", SLATE)

    # wall type legend from the LISP table
    lx = x + 168.0
    ly = ty - 4.0
    sh.text((lx, ly), "WALL TYPES  |  *RMR-WALL-SPECS*", 2.3, "RMR-HEAD", "RMR-A-TEXT", TERRA)
    ly -= 5.0
    sh.text((lx, ly), "TYPE", 1.9, "RMR-MARK", "RMR-A-TEXT", SLATE)
    sh.text((lx + 18.0, ly), "THICK", 1.9, "RMR-MARK", "RMR-A-TEXT", SLATE)
    sh.text((lx + 42.0, ly), "TARGET LAYER", 1.9, "RMR-MARK", "RMR-A-TEXT", SLATE)
    ly -= 4.2
    for key, thickness, layer, desc in DATA["walls"]:
        sh.text((lx, ly), key, 2.0, "RMR-NUMBER", "RMR-A-TEXT", TERRA)
        sh.text((lx + 18.0, ly), "%dmm" % int(thickness), 2.0, "RMR-BODY", "RMR-A-TEXT", INK)
        sh.text((lx + 42.0, ly), layer, 2.0, "RMR-BODY", "RMR-A-TEXT", SLATE)
        ly -= 4.2
    sh.text((lx, y + 4.0), "Add a row to the table to add a wall type.", 1.8,
            "RMR-NOTE", "RMR-A-TEXT", SLATE)


def draw_delivery_stair(sh):
    x, y, w, h = 316.0, 396.0, 250.0, 140.0
    ty = _panel(sh, x, y, w, h, "PARAMETRIC STAIR  |  RMR-STAIR")

    ox, oy = x + 16.0, y + 14.0
    total = _stair(sh, ox, oy, 1100.0, 280.0, 16, 90.0, "RMR-M-WALL", TERRA)
    sh.text((ox + 4.0, oy - 5.0), "UP  16R @ 280 = %.2fm GOING" % (total / 1000.0),
            2.2, "RMR-LABEL", "RMR-A-TEXT", TERRA)

    lx = x + 96.0
    ly = ty - 4.0
    sh.text((lx, ly), "PROMPTS", 2.3, "RMR-HEAD", "RMR-A-TEXT", TERRA)
    ly -= 5.0
    for prompt, value in (("Bottom-left corner", "picked"), ("Width", "1100 mm"),
                          ("Risers", "16"), ("Going", "280 mm"),
                          ("Direction of travel", "90 deg")):
        sh.text((lx, ly), prompt, 1.9, "RMR-NOTE", "RMR-A-TEXT", SLATE)
        sh.text((lx + 62.0, ly), value, 2.0, "RMR-BODY", "RMR-A-TEXT", INK)
        ly -= 4.2
    ly -= 2.0
    sh.text((lx, ly), "DRAWN GEOMETRY", 2.3, "RMR-HEAD", "RMR-A-TEXT", TERRA)
    ly -= 5.0
    for line in ("Outline with closed tread lines", "Walking line with direction arrow",
                 "UP label with risers, going and total", "Everything on RMR-M-WALL"):
        sh.text((lx, ly), "- " + line, 1.9, "RMR-NOTE", "RMR-A-TEXT", SLATE)
        ly -= 4.2


def draw_delivery_quantity(sh):
    x, y, w, h = 576.0, 396.0, 240.0, 140.0
    ty = _panel(sh, x, y, w, h, "QUANTIFICATION  |  RMR-LENGTH / RMR-BOM")

    # linear takeoff readout
    sh.text((x + 6.0, ty - 4.0), "RMR-LENGTH  linear takeoff", 2.3, "RMR-HEAD",
            "RMR-A-TEXT", TERRA)
    sh.rect((x + 6.0, ty - 24.0), 100.0, 16.0, "RMR-A-FRAME", INK)
    sh.text((x + 9.0, ty - 12.0), "TOTAL LENGTH", 2.0, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((x + 9.0, ty - 17.6), "24.60 m", 3.4, "RMR-NUMBER", "RMR-A-TEXT", TERRA)
    sh.text((x + 6.0, ty - 25.0), "Measures LINE, LWPOLYLINE, ARC, CIRCLE,",
            1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((x + 6.0, ty - 28.0), "ELLIPSE and SPLINE, then labels or exports CSV.",
            1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)

    # bill of materials sample
    by = ty - 38.0
    sh.text((x + 6.0, by), "RMR-BOM  bill of materials", 2.3, "RMR-HEAD", "RMR-A-TEXT", TERRA)
    colw = [14.0, 58.0, 52.0, 18.0]
    width = sum(colw)
    rowh = 7.6
    cy = by - 5.0
    sh.solid((x + 6.0, cy - rowh), width, rowh, "RMR-PRES-TITLE", SAND)
    cx = x + 6.0
    for i, label in enumerate(("NO.", "BLOCK", "LAYER", "QTY")):
        sh.text((cx + 1.6, cy - 5.4), label, 2.1, "RMR-HEAD", "RMR-A-TEXT", INK)
        if i < len(colw) - 1:
            cx += colw[i]
            sh.line((cx, cy - rowh), (cx, cy), "RMR-A-FRAME", INK)
    cy -= rowh
    for i, (blk, layer, qty) in enumerate((("RMR-SYM-DOOR-09", "RMR-M-DOOR", 6),
                                           ("RMR-SYM-WINDOW", "RMR-M-WINDOW", 4),
                                           ("RMR-SYM-BED-D", "RMR-F-FURN", 2),
                                           ("RMR-SYM-WC", "RMR-F-FIXTURE", 2),
                                           ("RMR-SYM-SOFA", "RMR-F-FURN", 1))):
        sh.rect((x + 6.0, cy - rowh), width, rowh, "RMR-A-FRAME", SLATE)
        cx = x + 6.0
        for j in range(len(colw) - 1):
            cx += colw[j]
            sh.line((cx, cy - rowh), (cx, cy), "RMR-A-FRAME", SLATE)
        sh.text((x + 7.6, cy - 5.4), str(i + 1), 2.1, "RMR-NUMBER", "RMR-A-TEXT", TERRA)
        sh.text((x + 6.0 + colw[0] + 1.6, cy - 5.4), blk, 2.1, "RMR-LABEL",
                "RMR-A-TEXT", INK)
        sh.text((x + 6.0 + colw[0] + colw[1] + 1.6, cy - 5.4), layer, 2.1,
                "RMR-BODY", "RMR-A-TEXT", INK)
        sh.text((x + 6.0 + colw[0] + colw[1] + colw[2] + 1.6, cy - 5.4), str(qty),
                2.1, "RMR-NUMBER", "RMR-A-TEXT", SLATE)
        cy -= rowh
    sh.text((x + 6.0, y + 4.0), "Counted per block name and layer, then sorted by quantity.",
            1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)


def _table(sh, x, y, headers, colw, rows, text=2.1):
    width = sum(colw)
    rowh = 7.6
    sh.solid((x, y - rowh), width, rowh, "RMR-PRES-TITLE", SAND)
    cx = x
    for i, label in enumerate(headers):
        sh.text((cx + 1.6, y - 5.4), label, text, "RMR-HEAD", "RMR-A-TEXT", INK)
        if i < len(colw) - 1:
            cx += colw[i]
            sh.line((cx, y - rowh), (cx, y), "RMR-A-FRAME", INK)
    cy = y - rowh
    for row in rows:
        sh.rect((x, cy - rowh), width, rowh, "RMR-A-FRAME", SLATE)
        cx = x
        for j in range(len(colw) - 1):
            cx += colw[j]
            sh.line((cx, cy - rowh), (cx, cy), "RMR-A-FRAME", SLATE)
        cx = x
        for j, value in enumerate(row):
            if value == "":
                cx += colw[j]
                continue
            sh.text((cx + 1.6, cy - 5.4), value, text,
                    "RMR-LABEL" if j == 0 else "RMR-BODY", "RMR-A-TEXT",
                    TERRA if j == 0 else INK)
            cx += colw[j]
        cy -= rowh
    return cy


def draw_delivery_finishes(sh):
    x, y, w, h = 20.0, 242.0, 250.0, 144.0
    ty = _panel(sh, x, y, w, h, "ROOM FINISHES  |  RMR-FINISHES")
    sh.text((x + 6.0, ty - 4.0), "Rows come from *RMR-FINISH-SPECS*", 1.8, "RMR-NOTE",
            "RMR-A-TEXT", SLATE)
    rows = [list(r) for r in DATA["finishes"]]
    # trim notes so the columns stay inside the panel
    rows = [r[:5] + [r[5][:26]] for r in rows]
    _table(sh, x + 6.0, ty - 9.0, ("ROOM", "FLOOR", "SKIRT", "WALL", "CEILING", "NOTES"),
           [40.0, 46.0, 26.0, 42.0, 32.0, 44.0], rows, text=1.9)


def draw_delivery_register(sh):
    x, y, w, h = 280.0, 242.0, 244.0, 144.0
    ty = _panel(sh, x, y, w, h, "DRAWING REGISTER  |  RMR-SHEETREG")
    sh.text((x + 6.0, ty - 4.0), "Rows come from *RMR-SHEET-LIST*", 1.8, "RMR-NOTE",
            "RMR-A-TEXT", SLATE)
    _table(sh, x + 6.0, ty - 9.0, ("SHEET", "TITLE", "SCALE", "REV", "STATUS"),
           [24.0, 92.0, 22.0, 16.0, 52.0],
           [list(r) for r in DATA["sheets"]], text=1.9)


def draw_delivery_transmittal(sh):
    x, y, w, h = 534.0, 242.0, 282.0, 144.0
    ty = _panel(sh, x, y, w, h, "ISSUE RECORD  |  RMR-TRANSMITTAL")
    sh.text((x + 6.0, ty - 4.0),
            "Issued by %s  |  Checked by %s  |  %s"
            % (project("DRAWN"), project("CHECKED"), project("STAGE")),
            1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    rows = [(r[0], r[1][:34], r[3], project("DATE"), "") for r in DATA["sheets"]]
    _table(sh, x + 6.0, ty - 9.0, ("SHEET", "TITLE", "REV", "ISSUE DATE", "RECEIVED BY"),
           [24.0, 90.0, 16.0, 46.0, 56.0], rows, text=1.9)


def draw_delivery_housekeeping(sh):
    x, y, w, h = 20.0, 74.0, 380.0, 158.0
    ty = _panel(sh, x, y, w, h, "HOUSEKEEPING  |  LAYER STATES, BYLAYER, CLEAN, PROPERTIES")

    lx = x + 6.0
    ly = ty - 4.0
    entries = [
        ("RMR-LAYERSTATE", "save / restore / list / delete layer states as .rms files"),
        ("RMR-STANDARDIZE", "force colour, linetype and lineweight to BYLAYER"),
        ("RMR-CLEAN", "three purge passes plus an audit, then optional standardise"),
        ("RMR-DWGPROPS", "title, subject, author, category and keywords from the project"),
    ]
    for name, desc in entries:
        sh.text((lx, ly), name, 2.2, "RMR-MARK", "RMR-A-TEXT", TEAL)
        sh.text((lx + 44.0, ly), desc, 1.9, "RMR-NOTE", "RMR-A-TEXT", SLATE)
        ly -= 4.4

    ly -= 4.0
    sh.text((lx, ly), "LAYER STATE FILE FORMAT  |  one line per layer", 2.2, "RMR-HEAD",
            "RMR-A-TEXT", TERRA)
    ly -= 4.6
    sh.text((lx, ly), "Name;Colour;Linetype;Lineweight;Frozen;Off;Locked", 1.9,
            "RMR-NOTE", "RMR-A-TEXT", INK)
    ly -= 4.2
    for sample in ("RMR-M-WALL;7;Continuous;35;0;0;0",
                   "RMR-A-DIMS;-7;Continuous;18;0;1;0",
                   "RMR-S-GRID;7;CENTER;9;1;0;0"):
        sh.text((lx + 4.0, ly), sample, 1.9, "RMR-BODY", "RMR-A-TEXT", SLATE)
        ly -= 4.0
    sh.text((lx, ly - 1.0),
            "Restore keeps xref-dependent bits, skips missing layers and reports the count.",
            1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)

    # wall specs table on the right half of the panel
    rx = x + 208.0
    ry = ty - 4.0
    sh.text((rx, ry), "*RMR-WALL-SPECS* (editable)", 2.2, "RMR-HEAD", "RMR-A-TEXT", TERRA)
    ry -= 5.0
    for key, thickness, layer, desc in DATA["walls"]:
        sh.text((rx, ry), key, 2.0, "RMR-NUMBER", "RMR-A-TEXT", TERRA)
        sh.text((rx + 18.0, ry), "%dmm" % int(thickness), 2.0, "RMR-BODY", "RMR-A-TEXT", INK)
        sh.text((rx + 42.0, ry), desc, 1.9, "RMR-NOTE", "RMR-A-TEXT", SLATE)
        ry -= 4.4
    ry -= 3.0
    sh.text((rx, ry), "*RMR-FINISH-SPECS*", 2.2, "RMR-HEAD", "RMR-A-TEXT", TERRA)
    ry -= 4.6
    for room, floor, skirt, wall, ceil, _notes in DATA["finishes"]:
        sh.text((rx, ry), room[:26], 2.0, "RMR-LABEL", "RMR-A-TEXT", INK)
        sh.text((rx + 58.0, ry), floor[:24], 1.9, "RMR-NOTE", "RMR-A-TEXT", SLATE)
        ry -= 4.0


def draw_delivery_xref_commands(sh):
    x, y, w, h = 410.0, 74.0, 406.0, 158.0
    ty = _panel(sh, x, y, w, h, "XREF REGISTER AND DELIVERY COMMANDS")

    lx = x + 6.0
    ly = ty - 4.0
    sh.text((lx, ly), "RMR-XREFLIST  external references with resolved paths", 2.2,
            "RMR-MARK", "RMR-A-TEXT", TEAL)
    ly -= 5.0
    _table(sh, lx, ly, ("XREF NAME", "SOURCE PATH"),
           [70.0, 130.0],
           [("A-101-PLAN", "C:\\Projects\\2401\\A-101-PLAN.dwg"),
            ("S-201-FRAMING", "C:\\Projects\\2401\\S-201-FRAMING.dwg"),
            ("M-301-SERVICES", "C:\\Projects\\2401\\M-301-SERVICES.dwg")], text=1.9)

    cx = x + 216.0
    cy = ty - 4.0
    sh.text((cx, cy), "NEW IN 5.0 DELIVERY SUITE", 2.2, "RMR-HEAD", "RMR-A-TEXT", TERRA)
    cy -= 5.0
    commands = [
        ("RMR-WALL", "mitred parametric walls"),
        ("RMR-STAIR", "straight stair plans"),
        ("RMR-LENGTH", "linear takeoff"),
        ("RMR-BOM", "bill of materials"),
        ("RMR-FINISHES", "room finish schedule"),
        ("RMR-SHEETREG", "drawing register"),
        ("RMR-XREFLIST", "xref register"),
        ("RMR-TRANSMITTAL", "issue record"),
        ("RMR-LAYERSTATE", "layer state files"),
        ("RMR-STANDARDIZE", "everything BYLAYER"),
        ("RMR-CLEAN", "purge and audit"),
        ("RMR-DWGPROPS", "drawing properties"),
    ]
    half = (len(commands) + 1) // 2
    for col, group in enumerate((commands[:half], commands[half:])):
        gx = cx + col * 96.0
        gy = cy
        for name, desc in group:
            sh.text((gx, gy), name, 2.0, "RMR-MARK", "RMR-A-TEXT", TEAL)
            sh.text((gx + 40.0, gy), desc, 1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)
            gy -= 4.0
    sh.text((lx, y + 4.0),
            "Wall, finish and sheet data live in editable tables near the top of the LISP.",
            1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)


def build_delivery():
    global SHEET_TITLE, SHEET_SUBTITLE, SHEET_NOTE
    SHEET_TITLE = "DELIVERY SUITE PREVIEW SHEET"
    SHEET_SUBTITLE = "PARAMETRIC GEOMETRY, QUANTIFICATION, REGISTERS AND HOUSEKEEPING"
    SHEET_NOTE = ("The 5.0 delivery suite: everything needed to take a coordinated "
                  "drawing set to issue.")
    doc = build_document()
    sh = Sheet(doc)
    draw_frame(sh)
    draw_header(sh)
    draw_delivery_walls(sh)
    draw_delivery_stair(sh)
    draw_delivery_quantity(sh)
    draw_delivery_finishes(sh)
    draw_delivery_register(sh)
    draw_delivery_transmittal(sh)
    draw_delivery_housekeeping(sh)
    draw_delivery_xref_commands(sh)
    draw_title_block(sh)
    return doc


# --------------------------------------------------------------------------- #
# 10. site and services sheet (6.0): solar study, falls and drainage,
#     parking, tiling setout, RCP, level schedule, keynotes, report.
# --------------------------------------------------------------------------- #

def _solar_alt(lat, dec, hour):
    import math
    v = math.sin(lat) * math.sin(dec) + math.cos(lat) * math.cos(dec) * math.cos(hour)
    return math.asin(max(-1.0, min(1.0, v)))


def _solar_az(lat, dec, hour, alt):
    import math
    ca = math.cos(alt)
    v = 0.0 if abs(ca) < 1e-6 else (math.sin(dec) * math.cos(lat)
                                    - math.cos(dec) * math.sin(lat) * math.cos(hour)) / ca
    a = math.acos(max(-1.0, min(1.0, v)))
    return (2 * math.pi - a) if hour > 0 else a


def _sun_path_points(centre, limit, lat_deg, dec_deg, steps=48):
    import math
    lat, dec = math.radians(lat_deg), math.radians(dec_deg)
    pts = []
    for i in range(steps + 1):
        hour = -math.pi + (2 * math.pi * i / steps)
        alt = _solar_alt(lat, dec, hour)
        if alt <= 0:
            continue
        az = _solar_az(lat, dec, hour, alt)
        r = limit * (90.0 - math.degrees(alt)) / 90.0
        pts.append((centre[0] + r * math.sin(az), centre[1] + r * math.cos(az)))
    return pts


def draw_site_sunpath(sh):
    x, y, w, h = 20.0, 396.0, 286.0, 140.0
    ty = _panel(sh, x, y, w, h, "SOLAR STUDY  |  RMR-SUNPATH")

    centre = (x + 96.0, y + 68.0)
    limit = 52.0
    lat = 23.81                     # Dhaka, the user's reference latitude

    sh.circle(centre, limit, "RMR-A-FRAME", SLATE)
    for ring in (30.0, 60.0):
        sh.circle(centre, limit * (90.0 - ring) / 90.0, "RMR-00-REF", SLATE)
    for i in range(4):
        a = math.radians(i * 90.0)
        sh.line(centre, (centre[0] + limit * math.sin(a), centre[1] + limit * math.cos(a)),
                "RMR-00-REF", SLATE)
    for i, tag in enumerate(("N", "E", "S", "W")):
        a = math.radians(i * 90.0)
        sh.text((centre[0] + limit * 1.14 * math.sin(a) - 1.4,
                 centre[1] + limit * 1.14 * math.cos(a) - 1.2), tag, 3.0,
                "RMR-NUMBER", "RMR-A-TEXT", INK)

    for name, dec in (("SUMMER", 23.45), ("EQUINOX", 0.0), ("WINTER", -23.45)):
        pts = _sun_path_points(centre, limit, lat, dec)
        if len(pts) > 1:
            sh.poly(pts, [0.0] * len(pts), False, "RMR-A-ARROW", GOLD)
        k = {"SUMMER": 0.60, "EQUINOX": 0.40, "WINTER": 0.20}[name]
        a = math.radians(-45.0)
        sh.text((centre[0] + limit * k * math.sin(a), centre[1] + limit * k * math.cos(a)),
                name, 2.2, "RMR-LABEL", "RMR-A-TEXT", GOLD)

    for hh in (6, 9, 12, 15, 18):
        hour = math.radians((hh - 12) * 15.0)
        alt = _solar_alt(math.radians(lat), 0.0, hour)
        if alt > -1e-9:
            az = _solar_az(math.radians(lat), 0.0, hour, alt)
            # sit the label just inside the equinox curve it belongs to
            r = limit * (90.0 - math.degrees(alt)) / 90.0 * 0.82
            sh.text((centre[0] + r * math.sin(az) - 2.0,
                     centre[1] + r * math.cos(az) - 1.0),
                    "%dh" % hh, 1.8, "RMR-LABEL", "RMR-A-TEXT", SLATE)

    lx = x + 176.0
    ly = ty - 4.0
    sh.text((lx, ly), "NOON ALTITUDE", 2.2, "RMR-HEAD", "RMR-A-TEXT", TERRA)
    ly -= 4.6
    for name, dec in (("SUMMER", 23.45), ("EQUINOX", 0.0), ("WINTER", -23.45)):
        alt = math.degrees(_solar_alt(math.radians(lat), math.radians(dec), 0.0))
        sh.text((lx, ly), name, 2.0, "RMR-LABEL", "RMR-A-TEXT", INK)
        sh.text((lx + 34.0, ly), "%.1f deg" % alt, 2.0, "RMR-NUMBER", "RMR-A-TEXT", TERRA)
        ly -= 4.2
    ly -= 2.0
    sh.text((lx, ly), "LATITUDE %.2f" % lat, 2.0, "RMR-HEAD", "RMR-A-TEXT", TERRA)
    ly -= 4.4
    sh.text((lx, ly), "*RMR-SUN-CITIES*", 1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    ly -= 4.0
    for city, city_lat in DATA["cities"][:6]:
        sh.text((lx, ly), city, 1.8, "RMR-BODY", "RMR-A-TEXT", INK)
        sh.text((lx + 30.0, ly), "%.2f" % float(city_lat), 1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)
        ly -= 3.6


def draw_site_drainage(sh):
    x, y, w, h = 316.0, 396.0, 250.0, 140.0
    ty = _panel(sh, x, y, w, h, "FALLS AND DRAINAGE  |  RMR-FALL / RMR-DRAIN")

    # fall arrow
    fy = ty - 14.0
    p1, p2 = (x + 12.0, fy), (x + 92.0, fy - 16.0)
    sh.line(p1, p2, "RMR-P-DRAIN", BLUE)
    sh.tri((p2[0] - 6.0, p2[1] + 1.6), 6.0, "RMR-P-DRAIN", BLUE)
    sh.text((x + 12.0, fy + 4.0), "FALL 1:80  (200mm OVER 16000mm)", 2.0,
            "RMR-LABEL", "RMR-P-ANNO", BLUE)
    sh.text((x + 12.0, fy - 22.0), "RMR-FALL draws the arrow, the gradient and the",
            1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((x + 12.0, fy - 25.4), "drop calculated from the picked run.",
            1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)

    # drainage run
    dy = fy - 40.0
    sh.text((x + 12.0, dy), "RMR-DRAIN  drainage run", 2.2, "RMR-HEAD", "RMR-A-TEXT", TERRA)
    run = [(x + 16.0, dy - 14.0), (x + 76.0, dy - 14.0), (x + 76.0, dy - 40.0),
           (x + 128.0, dy - 40.0)]
    sh.poly(run, [0.0] * len(run), False, "RMR-P-DRAIN", BLUE)
    levels = ("IL 1.500", "IL 1.250", "IL 1.125", "IL 1.000")
    for i, (pt, level) in enumerate(zip(run, levels)):
        sh.circle(pt, 3.0, "RMR-P-FIXTURE", BLUE)
        sh.text((pt[0] + 4.0, pt[1] + 1.0), "MH%02d  %s" % (i + 1, level), 1.9,
                "RMR-LABEL", "RMR-P-ANNO", BLUE)
    sh.text((x + 12.0, dy - 52.0),
            "Invert levels fall automatically along the picked run at 1:x.",
            1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)


def draw_site_parking(sh):
    x, y, w, h = 576.0, 396.0, 240.0, 140.0
    ty = _panel(sh, x, y, w, h, "PARKING LAYOUT  |  RMR-PARK")

    def bays(ox, oy, count, rot, bw, bd, scale):
        import math
        a = math.radians(rot)
        ux, uy = math.cos(a) * scale, math.sin(a) * scale
        nx, ny = -uy, ux
        for i in range(count):
            # ux/uy/nx/ny already include the scale, so bay width is nx * bw
            c = (ox + nx * i * bw, oy + ny * i * bw)
            pts = [c,
                   (c[0] + ux * bd, c[1] + uy * bd),
                   (c[0] + ux * bd + nx * bw, c[1] + uy * bd + ny * bw),
                   (c[0] + nx * bw, c[1] + ny * bw)]
            sh.poly(pts, [0.0] * 4, True, "RMR-M-WALL", SLATE)
            sh.text((c[0] + ux * bd * 0.45 + nx * bw * 0.5 - 1.0,
                     c[1] + uy * bd * 0.45 + ny * bw * 0.5 - 1.0),
                    str(i + 1), 2.4, "RMR-NUMBER", "RMR-A-TEXT", TERRA)

    k = 0.0042                      # mm -> sheet units
    bays(x + 18.0, y + 22.0, 4, 90.0, 2500.0, 5000.0, k)
    sh.text((x + 18.0, y + 14.0), "4 BAYS AT 90 DEG  |  2500 x 5000mm  |  AISLE 6000mm",
            2.0, "RMR-LABEL", "RMR-A-TEXT", SLATE)
    bays(x + 150.0, y + 30.0, 3, 60.0, 2500.0, 5000.0, k * 0.85)
    sh.text((x + 150.0, y + 22.0), "60 DEG BAYS", 2.0, "RMR-LABEL", "RMR-A-TEXT", SLATE)
    sh.text((x + 12.0, ty - 4.0), "90 / 60 / 45 degree bays, numbered, with the aisle",
            1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((x + 12.0, ty - 7.4), "set back behind the row.",
            1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)


def draw_site_tiling(sh):
    x, y, w, h = 20.0, 242.0, 250.0, 144.0
    ty = _panel(sh, x, y, w, h, "TILING SETOUT  |  RMR-TILE")

    rx, ry = x + 16.0, y + 16.0
    rw, rh = 120.0, 86.0
    sh.rect((rx, ry), rw, rh, "RMR-M-FINISH", TEAL)
    cols, rows = 8, 6
    for i in range(1, cols):
        sh.line((rx + rw * i / cols, ry), (rx + rw * i / cols, ry + rh),
                "RMR-M-FINISH", TEAL)
    for j in range(1, rows):
        sh.line((rx, ry + rh * j / rows), (rx + rw, ry + rh * j / rows),
                "RMR-M-FINISH", TEAL)
    sh.text((rx, ry - 5.0),
            "8 x 6 = 48 TILES  |  WITH 10% WASTE ORDER 53 TILES", 1.9,
            "RMR-LABEL", "RMR-M-FINISH", TEAL)
    sh.text((x + 12.0, ty - 4.0), "RMR-TILE draws the setout grid on RMR-M-FINISH and",
            1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((x + 12.0, ty - 7.4), "reports the tile count with a cutting allowance.",
            1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((x + 12.0, ty - 12.0), "Grid lines are capped at 80 per direction so large",
            1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((x + 12.0, ty - 15.4), "rooms stay light.",
            1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)


def draw_site_rcp(sh):
    x, y, w, h = 280.0, 242.0, 250.0, 144.0
    ty = _panel(sh, x, y, w, h, "REFLECTED CEILING PLAN  |  RMR-RCP")

    rx, ry = x + 16.0, y + 16.0
    rw, rh = 120.0, 86.0
    sh.rect((rx, ry), rw, rh, "RMR-M-CEILING", SAND)
    cols, rows = 8, 6
    for i in range(1, cols):
        sh.line((rx + rw * i / cols, ry), (rx + rw * i / cols, ry + rh),
                "RMR-M-CEILING", SAND)
    for j in range(1, rows):
        sh.line((rx, ry + rh * j / rows), (rx + rw, ry + rh * j / rows),
                "RMR-M-CEILING", SAND)
    count = 0
    for i in range(4):
        for j in range(3):
            cx = rx + rw * (i + 0.5) / 4.0
            cy = ry + rh * (j + 0.5) / 3.0
            sh.circle((cx, cy), 2.4, "RMR-M-CEILING", GOLD)
            sh.line((cx - 3.4, cy), (cx + 3.4, cy), "RMR-M-CEILING", GOLD)
            sh.line((cx, cy - 3.4), (cx, cy + 3.4), "RMR-M-CEILING", GOLD)
            count += 1
    sh.text((rx, ry - 5.0), "GRID 600mm  |  %d LIGHT FITTINGS AT 1200mm" % count, 1.9,
            "RMR-LABEL", "RMR-M-CEILING", SAND)
    sh.text((x + 12.0, ty - 4.0), "RMR-RCP lays out the ceiling module on RMR-M-CEILING",
            1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((x + 12.0, ty - 7.4), "and places fittings at the spacing you choose.",
            1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)


def draw_site_levels(sh):
    x, y, w, h = 540.0, 242.0, 276.0, 144.0
    ty = _panel(sh, x, y, w, h, "LEVEL SCHEDULE  |  RMR-LEVELSCHED")
    rows = [(r[0], "%s mm" % int(float(r[1])), r[2]) for r in DATA["levels"]]
    _table(sh, x + 6.0, ty - 8.0, ("LEVEL", "HEIGHT", "DESCRIPTION"),
           [26.0, 34.0, 120.0], rows, text=2.0)
    sh.text((x + 6.0, y + 4.0), "Rows come from *RMR-LEVEL-SPECS*", 1.8, "RMR-NOTE",
            "RMR-A-TEXT", SLATE)


def draw_site_keynotes(sh):
    x, y, w, h = 20.0, 74.0, 400.0, 158.0
    ty = _panel(sh, x, y, w, h, "KEYNOTE LEGEND  |  RMR-KEYLIB  |  *RMR-KEYNOTES*")

    ly = ty - 4.0
    colw = 188.0
    half = (len(DATA["keynotes"]) + 1) // 2
    for col, group in enumerate((DATA["keynotes"][:half], DATA["keynotes"][half:])):
        gx = x + 6.0 + col * colw
        gy = ly
        for number, text in group:
            sh.circle((gx + 3.0, gy + 1.2), 2.6, "RMR-A-KEYNOTE", GOLD)
            sh.text((gx + 3.0, gy + 1.2), number, 2.0, "RMR-NUMBER", "RMR-A-KEYNOTE",
                    INK, align="middle")
            body = text if len(text) <= 46 else text[:45] + "."
            sh.text((gx + 8.0, gy), body, 1.8, "RMR-BODY", "RMR-A-TEXT", SLATE)
            gy -= 5.0


def draw_site_report(sh):
    x, y, w, h = 430.0, 74.0, 386.0, 158.0
    ty = _panel(sh, x, y, w, h, "STANDARD REPORT AND LAYER AUDIT")

    lx = x + 6.0
    ly = ty - 4.0
    sh.text((lx, ly), "RMR-REPORT  printable standard report", 2.2, "RMR-MARK",
            "RMR-A-TEXT", TEAL)
    ly -= 5.0
    sample = [
        "==============================================================",
        "RooMNRooF %s - STANDARD REPORT" % VERSION,
        "Generated %s" % project("DATE"),
        "==============================================================",
        "",
        "PROJECT DATA",
        "  CLIENT = %s" % project("CLIENT"),
        "  PROJECT = %s" % project("PROJECT"),
        "  JOB = %s   DWGNO = %s   REV = %s" % (project("JOB"), project("DWGNO"), project("REV")),
        "",
        "LAYER PALETTE",
        "  [MAIN THEME]",
        "    RMR-M-WALL  |  RGB 198,93,72  |  Continuous  |  0.35mm  |  Primary walls",
        "    RMR-M-DOOR  |  RGB 214,163,76  |  Continuous  |  0.18mm  |  Doors and swings",
        "  [FURNITURE]",
        "    RMR-F-FURN  |  RGB 31,42,51  |  Continuous  |  0.18mm  |  Loose furniture",
        "",
        "WALL TYPES   LEVELS   KEYNOTES   DRAWING REGISTER   GENERAL NOTES",
        "==============================================================",
    ]
    for line in sample:
        if line:
            sh.text((lx + 2.0, ly), line[:62], 1.75, "RMR-BODY", "RMR-A-TEXT", SLATE)
        ly -= 3.1

    ly -= 2.0
    sh.text((lx, ly), "RMR-STRAY  objects on non-standard layers", 2.2, "RMR-MARK",
            "RMR-A-TEXT", TEAL)
    ly -= 5.0
    for line in ("Reports every layer that is not in *RMR-LAYER-SPECS*,",
                 "ignoring xrefs, layer 0 and Defpoints, then optionally",
                 "moves the objects onto a standard layer."):
        sh.text((lx + 2.0, ly), line, 1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)
        ly -= 3.6


def build_site():
    global SHEET_TITLE, SHEET_SUBTITLE, SHEET_NOTE
    SHEET_TITLE = "SITE AND SERVICES SHEET"
    SHEET_SUBTITLE = "SOLAR STUDY, DRAINAGE, PARKING, SETOUT, RCP, LEVELS AND KEYNOTES"
    SHEET_NOTE = ("The 6.0 site and services suite: drawing the information a "
                  "coordinated set needs around the plan.")
    doc = build_document()
    sh = Sheet(doc)
    draw_frame(sh)
    draw_header(sh)
    draw_site_sunpath(sh)
    draw_site_drainage(sh)
    draw_site_parking(sh)
    draw_site_tiling(sh)
    draw_site_rcp(sh)
    draw_site_levels(sh)
    draw_site_keynotes(sh)
    draw_site_report(sh)
    draw_title_block(sh)
    return doc


# --------------------------------------------------------------------------- #
# 11. coordination sheet (7.0): clash check, roof plan, balustrade,
#     glazing schedule, zone plan, block swap, renumber, align, info.
# --------------------------------------------------------------------------- #

ROOF_K = 0.0062          # millimetres -> sheet units for the roof plans


def _box_overlap(pts_a, pts_b):
    """min/max bounding boxes of two point lists, as the LISP does."""
    lo1 = (min(p[0] for p in pts_a), min(p[1] for p in pts_a))
    hi1 = (max(p[0] for p in pts_a), max(p[1] for p in pts_a))
    lo2 = (min(p[0] for p in pts_b), min(p[1] for p in pts_b))
    hi2 = (max(p[0] for p in pts_b), max(p[1] for p in pts_b))
    if hi1[0] <= lo2[0] or hi2[0] <= lo1[0] or hi1[1] <= lo2[1] or hi2[1] <= lo1[1]:
        return None
    return [(max(lo1[0], lo2[0]), max(lo1[1], lo2[1])),
            (min(hi1[0], hi2[0]), min(hi1[1], hi2[1]))]


def draw_coord_clash(sh):
    x, y, w, h = 20.0, 396.0, 286.0, 140.0
    ty = _panel(sh, x, y, w, h, "CLASH CHECK  |  RMR-CLASH")

    # two overlapping service runs drawn as rectangles, one clash found
    a = [(x + 14.0, y + 24.0), (x + 104.0, y + 24.0),
         (x + 104.0, y + 34.0), (x + 14.0, y + 34.0)]
    b = [(x + 74.0, y + 14.0), (x + 122.0, y + 14.0),
         (x + 122.0, y + 52.0), (x + 74.0, y + 52.0)]
    c = [(x + 20.0, y + 74.0), (x + 60.0, y + 74.0),
         (x + 60.0, y + 84.0), (x + 20.0, y + 84.0)]
    sh.poly(a, [0.0] * 4, True, "RMR-S-BEAM", TERRA)
    sh.poly(b, [0.0] * 4, True, "RMR-P-DRAIN", BLUE)
    sh.poly(c, [0.0] * 4, True, "RMR-S-BEAM", TERRA)

    ov = _box_overlap(a, b)
    cx = (ov[0][0] + ov[1][0]) / 2.0
    cy = (ov[0][1] + ov[1][1]) / 2.0
    sh.circle((cx, cy), 8.0, "RMR-A-REVISION", TERRA)
    sh.circle((cx, cy), 5.0, "RMR-A-REVISION", GOLD)
    sh.text((cx + 10.0, cy + 1.0), "CLASH 01", 2.2, "RMR-NUMBER", "RMR-A-REVISION", TERRA)
    sh.text((x + 14.0, y + 8.0),
            "Structural beam x Plumbing drain", 2.0, "RMR-LABEL", "RMR-A-TEXT", INK)
    sh.text((x + 14.0, y + 4.0),
            "1 overlap found, 1 group pair clear", 1.9, "RMR-NOTE", "RMR-A-TEXT", SLATE)

    lx = x + 150.0
    ly = ty - 4.0
    sh.text((lx, ly), "HOW IT WORKS", 2.2, "RMR-HEAD", "RMR-A-TEXT", TERRA)
    ly -= 4.6
    for line in ("Pick two layer groups, for",
                 "example STRUCTURAL and PLUMBING.",
                 "Every object bounding box is",
                 "compared with every other box.",
                 "Overlaps are listed with their",
                 "area and can be circled so you",
                 "can walk the model and review.",
                 "",
                 "Bounding boxes overlap objects,",
                 "so read it as a review list,",
                 "not a solid clash engine."):
        sh.text((lx, ly), line, 1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)
        ly -= 3.5


def _roof(sh, ox, oy, w_mm, h_mm, over, rooftype):
    k = ROOF_K
    x1, y1 = ox, oy
    x2, y2 = ox + w_mm * k, oy + h_mm * k
    o = over * k
    eaves = [(x1 - o, y1 - o), (x2 + o, y1 - o), (x2 + o, y2 + o), (x1 - o, y2 + o)]
    sh.poly(eaves, [0.0] * 4, True, "RMR-M-WALL", TERRA)
    long_is_x = (x2 - x1) >= (y2 - y1)
    ux, uy = (1.0, 0.0) if long_is_x else (0.0, 1.0)
    L, S = ((x2 - x1), (y2 - y1)) if long_is_x else ((y2 - y1), (x2 - x1))
    cx, cy = (x1 + x2) / 2.0, (y1 + y2) / 2.0
    if rooftype == "HIP":
        hip = max(0.0, (L - S) / 2.0)
    else:
        hip = L / 2.0
    r1 = (cx - ux * hip, cy - uy * hip)
    r2 = (cx + ux * hip, cy + uy * hip)
    if rooftype != "SHED":
        sh.line(r1, r2, "RMR-M-WALL", TERRA)
    if rooftype == "HIP":
        nx, ny = -uy, ux
        for pt in eaves:
            side = (pt[0] - cx) * nx + (pt[1] - cy) * ny
            sh.line(pt, r1 if side < 0 else r2, "RMR-M-WALL", TERRA)
    return round(math.dist(r1, r2) / k)


def draw_coord_roof(sh):
    x, y, w, h = 316.0, 396.0, 250.0, 140.0
    ty = _panel(sh, x, y, w, h, "ROOF PLANS  |  RMR-ROOF")

    ly = ty - 4.0
    for line in ("GABLE / HIP / SHED, with an eaves overhang and a pitch label.",
                 "The ridge always follows the longer direction, and hip lines",
                 "run from the ridge ends out to the eaves corners."):
        sh.text((x + 12.0, ly), line, 1.9, "RMR-NOTE", "RMR-A-TEXT", SLATE)
        ly -= 4.0

    ridge = _roof(sh, x + 14.0, y + 44.0, 12000.0, 8000.0, 600.0, "HIP")
    sh.text((x + 14.0, y + 36.0), "HIP", 2.2, "RMR-LABEL", "RMR-A-TEXT", TERRA)
    sh.text((x + 14.0, y + 29.0), "ridge %d mm = long - short" % ridge, 1.8,
            "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((x + 14.0, y + 24.0), "eaves 600 mm overhang", 1.8, "RMR-NOTE",
            "RMR-A-TEXT", SLATE)

    ridge2 = _roof(sh, x + 104.0, y + 44.0, 12000.0, 8000.0, 600.0, "GABLE")
    sh.text((x + 104.0, y + 36.0), "GABLE", 2.2, "RMR-LABEL", "RMR-A-TEXT", TERRA)
    sh.text((x + 104.0, y + 29.0), "ridge %d mm = full length" % ridge2, 1.8,
            "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((x + 104.0, y + 24.0), "gable ends left open", 1.8, "RMR-NOTE",
            "RMR-A-TEXT", SLATE)

    sh.text((x + 186.0, y + 36.0), "SHED", 2.2, "RMR-LABEL", "RMR-A-TEXT", TERRA)
    sh.text((x + 186.0, y + 29.0), "no ridge, hips", 1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((x + 186.0, y + 24.0), "to one ridge end", 1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)


def draw_coord_rail(sh):
    x, y, w, h = 576.0, 396.0, 240.0, 140.0
    ty = _panel(sh, x, y, w, h, "BALUSTRADE AND GLAZING  |  RMR-RAIL / RMR-WINDOWSCHED")

    # balustrade along an L-shaped path
    pts = [(x + 16.0, y + 20.0), (x + 96.0, y + 20.0), (x + 96.0, y + 62.0)]
    inner = _offset_path([(p[0] / 1.0, p[1] / 1.0) for p in pts], 3.0)
    outer = _offset_path([(p[0] / 1.0, p[1] / 1.0) for p in pts], -3.0)
    sh.poly(inner, [0.0] * len(inner), False, "RMR-M-FINISH", TEAL)
    sh.poly(outer, [0.0] * len(outer), False, "RMR-M-FINISH", TEAL)
    for i in range(len(pts) - 1):
        a, b = pts[i], pts[i + 1]
        L = math.dist(a, b)
        n = max(1, int(L / 16.0))
        ang = math.atan2(b[1] - a[1], b[0] - a[0])
        start = 0 if i == 0 else 1
        for j in range(start, n + 1):
            t = L * j / n
            sh.circle((a[0] + t * math.cos(ang), a[1] + t * math.sin(ang)), 1.6,
                      "RMR-M-FINISH", TEAL)
    sh.text((x + 16.0, y + 14.0), "Posts at spacing, corners counted once", 1.8,
            "RMR-NOTE", "RMR-A-TEXT", SLATE)

    # glazing schedule
    gy = ty - 4.0
    sh.text((x + 12.0, gy), "GLAZING SCHEDULE", 2.2, "RMR-HEAD", "RMR-A-TEXT", TERRA)
    gy -= 5.0
    rows = (("RMR-SYM-WINDOW", "RMR-M-WINDOW", "4"),
            ("RMR-SYM-WINDOW", "RMR-F-FURN", "1"))
    _table(sh, x + 12.0, gy, ("TYPE", "LAYER", "QTY"), [58.0, 56.0, 16.0], rows, text=1.9)


def draw_coord_zone(sh):
    x, y, w, h = 20.0, 242.0, 250.0, 144.0
    ty = _panel(sh, x, y, w, h, "ZONE PLAN  |  RMR-ZONE  |  *RMR-ZONE-BANDS*")

    # five sample areas, each hatches into its band
    bands = DATA["zones"]
    samples = [(x + 14.0, y + 20.0, 30.0, 20.0, 0),
               (x + 50.0, y + 20.0, 44.0, 26.0, 1),
               (x + 14.0, y + 48.0, 52.0, 30.0, 2),
               (x + 72.0, y + 20.0, 60.0, 34.0, 3),
               (x + 72.0, y + 60.0, 70.0, 38.0, 4)]
    for sx, sy, sw, shh, band_index in samples:
        name, limit, rgb, pattern = bands[band_index]
        pts = [(sx, sy), (sx + sw, sy), (sx + sw, sy + shh), (sx, sy + shh)]
        sh.hatch_pattern(pts, "RMR-M-AREA", tuple(int(v) for v in rgb),
                         pattern, scale=0.6)
        sh.rect((sx, sy), sw, shh, "RMR-M-AREA", tuple(int(v) for v in rgb))

    lx = x + 156.0
    ly = ty - 4.0
    sh.text((lx, ly), "BANDS", 2.2, "RMR-HEAD", "RMR-A-TEXT", TERRA)
    ly -= 5.0
    for name, limit, rgb, pattern in bands:
        sh.solid((lx, ly - 3.0), 10.0, 5.0, "RMR-M-AREA", tuple(int(v) for v in rgb))
        sh.text((lx + 13.0, ly - 2.4), name, 2.0, "RMR-LABEL", "RMR-A-TEXT", INK)
        ly -= 6.0
    sh.text((lx, ly - 1.0), "TOTAL 178.40 m2", 2.2, "RMR-NUMBER", "RMR-A-TEXT", TERRA)
    sh.text((x + 12.0, y + 4.0), "Closed areas are hatched by band, then totaled.",
            1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)


def draw_coord_fixes(sh):
    x, y, w, h = 280.0, 242.0, 250.0, 144.0
    ty = _panel(sh, x, y, w, h, "DRAWING FIXES  |  SWAP, RENUMBER, ALIGN")

    # block swap before / after
    bx = x + 14.0
    by = ty - 8.0
    sh.text((bx, by), "RMR-BLKSWAP", 2.2, "RMR-MARK", "RMR-A-TEXT", TEAL)
    for i, (label, rgb) in enumerate((("CHAIR-OLD", SLATE), ("CHAIR-NEW", TEAL))):
        cx = bx + i * 44.0
        sh.rect((cx, by - 22.0), 14.0, 12.0, "RMR-F-FURN", rgb)
        sh.rect((cx + 2.0, by - 20.0), 10.0, 2.5, "RMR-F-FURN", rgb)
        sh.text((cx, by - 26.0), label, 1.9, "RMR-LABEL", "RMR-A-TEXT", INK)
        if i == 0:
            sh.text((cx + 20.0, by - 16.0), ">", 3.0, "RMR-NUMBER", "RMR-A-TEXT", GOLD)
    sh.text((bx, by - 32.0), "Position, rotation, scale and layer are kept.", 1.8,
            "RMR-NOTE", "RMR-A-TEXT", SLATE)

    # renumber
    ry = by - 44.0
    sh.text((bx, ry), "RMR-RENUMBER", 2.2, "RMR-MARK", "RMR-A-TEXT", TEAL)
    for i in range(5):
        cx = bx + i * 16.0
        sh.circle((cx + 4.0, ry - 12.0), 3.4, "RMR-A-ROOMTAG", TERRA)
        sh.text((cx + 4.0, ry - 12.0), "%02d" % (i + 1), 2.2, "RMR-NUMBER",
                "RMR-A-ROOMTAG", INK, align="middle")
    sh.text((bx, ry - 22.0), "Tags renumbered in selection order, optional prefix",
            1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((bx, ry - 25.4), "and two-digit padding.", 1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)

    # text align
    ay = ry - 38.0
    sh.text((bx, ay), "RMR-TEXTALIGN", 2.2, "RMR-MARK", "RMR-A-TEXT", TEAL)
    sh.line((bx, ay - 10.0), (bx + 90.0, ay - 6.0), "RMR-00-REF", SLATE)
    for i, yy in enumerate((18.0, 12.0, 6.0)):
        sh.text((bx + 8.0 + i * 26.0, ay - 10.0 - yy + 0.0), "NOTE %d" % (i + 1), 2.0,
                "RMR-BODY", "RMR-A-TEXT", INK)


def draw_coord_info(sh):
    x, y, w, h = 540.0, 242.0, 276.0, 144.0
    ty = _panel(sh, x, y, w, h, "OBJECT INFORMATION  |  RMR-INFO / RMR-ORIENT")

    lines = [
        "---------------------------------------------",
        " Entity type   LWPOLYLINE",
        " Layer         RMR-M-WALL",
        " Colour        BYLAYER",
        " True colour   R198 G93 B72",
        " Linetype      Continuous",
        " Lineweight    0.35 mm",
        " Length        18400 mm  =  18.400 m",
        " Area          62.400 m2  =  671.7 sq ft",
        "---------------------------------------------",
    ]
    ly = ty - 4.0
    for line in lines:
        sh.text((x + 8.0, ly), line, 1.8, "RMR-BODY" if line.startswith(" ") else
                "RMR-NOTE", "RMR-A-TEXT", SLATE)
        ly -= 3.6

    ly -= 3.0
    sh.text((x + 8.0, ly), "RMR-ORIENT  true north", 2.2, "RMR-MARK", "RMR-A-TEXT", TEAL)
    ly -= 5.0
    # north rotation illustration: original Y axis vs true north
    cx, cy = x + 40.0, y + 34.0
    r = 22.0
    sh.circle((cx, cy), r, "RMR-00-REF", SLATE)
    sh.line((cx, cy - r), (cx, cy + r), "RMR-00-REF", SLATE)
    sh.line((cx - r, cy), (cx + r, cy), "RMR-00-REF", SLATE)
    a = math.radians(27.0)
    sh.line((cx, cy), (cx + r * math.sin(a), cy + r * math.cos(a)), "RMR-PRES-NORTH", TEAL)
    sh.tri((cx + r * math.sin(a) - 3.0, cy + r * math.cos(a) - 3.0), 5.0,
           "RMR-PRES-NORTH", TEAL)
    sh.text((cx + r * math.sin(a) + 2.0, cy + r * math.cos(a) + 1.0), "N 27", 2.2,
            "RMR-LABEL", "RMR-A-TEXT", TEAL)
    lx = x + 96.0
    for line in ("Rotate the whole model by an",
                 "angle about a base point so",
                 "drawing north matches true",
                 "north, then move the north",
                 "arrow to suit."):
        sh.text((lx, ly), line, 1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)
        ly -= 3.6


def draw_coord_commands(sh):
    x, y, w, h = 20.0, 74.0, 796.0, 158.0
    ty = _panel(sh, x, y, w, h, "COORDINATION SUITE  |  10 NEW COMMANDS")

    entries = [
        ("RMR-CLASH", "Bounding-box clash check between two layer groups, with the",
         "overlap area, an optional marker circle and a printed review list."),
        ("RMR-ROOF", "Gable, hip or shed roof plan: eaves overhang, ridge along the",
         "long axis, hip lines to the corners and a pitch label."),
        ("RMR-RAIL", "Balustrade along a picked path: two handrail lines plus posts",
         "at your spacing, with corner posts counted once."),
        ("RMR-WINDOWSCHED", "Glazing schedule counted from the RMR-SYM-WINDOW* blocks",
         "you have inserted, sorted by quantity."),
        ("RMR-ZONE", "Hatch closed areas by band from *RMR-ZONE-BANDS* and draw the",
         "colour legend with the total area."),
        ("RMR-BLKSWAP", "Replace every insert of one block with another, keeping the",
         "insertion point, rotation, scale and layer."),
        ("RMR-RENUMBER", "Renumber picked tags in selection order with an optional",
         "prefix and two-digit padding."),
        ("RMR-TEXTALIGN", "Project selected single-line text onto a picked baseline",
         "and rotate it to match the line."),
        ("RMR-INFO", "Full report for one object: type, layer, colour, true colour,",
         "linetype, lineweight, block, style, length and area."),
        ("RMR-ORIENT", "Rotate every object in model space about a base point so the",
         "drawing matches true north."),
    ]
    colw = 265.0
    ly = ty - 4.0
    for i, (name, line1, line2) in enumerate(entries):
        col, row = i // 5, i % 5
        gx = x + 8.0 + col * colw
        gy = ly - row * 26.0
        sh.text((gx, gy), name, 2.3, "RMR-MARK", "RMR-A-TEXT", TEAL)
        sh.text((gx, gy - 4.4), line1, 1.9, "RMR-NOTE", "RMR-A-TEXT", SLATE)
        sh.text((gx, gy - 7.6), line2, 1.9, "RMR-NOTE", "RMR-A-TEXT", SLATE)


def build_coordination():
    global SHEET_TITLE, SHEET_SUBTITLE, SHEET_NOTE
    SHEET_TITLE = "COORDINATION SUITE SHEET"
    SHEET_SUBTITLE = "CLASH CHECKS, ROOFS, BALUSTRADES, ZONES AND DRAWING FIXES"
    SHEET_NOTE = ("The 7.0 coordination suite: the checks and utilities that keep a "
                  "drawing set consistent before issue.")
    doc = build_document()
    sh = Sheet(doc)
    draw_frame(sh)
    draw_header(sh)
    draw_coord_clash(sh)
    draw_coord_roof(sh)
    draw_coord_rail(sh)
    draw_coord_zone(sh)
    draw_coord_fixes(sh)
    draw_coord_info(sh)
    draw_coord_commands(sh)
    draw_title_block(sh)
    return doc


# --------------------------------------------------------------------------- #
# 12. documentation sheet (8.0): specification clauses and index,
#     abbreviations, revision log, room data, sheet index, checklist,
#     cover sheet and the complete documentation sheet.
# --------------------------------------------------------------------------- #


def draw_doc_specnote(sh):
    x, y, w, h = 20.0, 396.0, 286.0, 140.0
    ty = _panel(sh, x, y, w, h, "SPECIFICATION CLAUSE  |  RMR-SPECNOTE")

    clause = None
    for code, trade, title, text in DATA["specs"]:
        if code == "F10":
            clause = (code, trade, title, text)
    if clause is None:
        clause = DATA["specs"][0]
    code, trade, title, text = clause

    # the clause tab exactly as the command draws it
    ox, oy = x + 12.0, ty - 8.0
    sh.solid((ox, oy - 7.0), 30.0, 7.0, "RMR-PRES-TITLE", TERRA)
    sh.text((ox + 2.0, oy - 4.6), code, 3.2, "RMR-HEAD", "RMR-PRES-TITLE", SAND)
    sh.text((ox + 34.0, oy - 4.4), title, 3.4, "RMR-HEAD", "RMR-A-TEXT", TERRA)
    sh.text((ox, oy - 15.0), "TRADE %s   |   CLAUSE %s" % (trade, code), 2.0,
            "RMR-MARK", "RMR-A-TEXT", GOLD)
    sh.mtext((ox, oy - 22.0), text, 200.0, 2.4, "RMR-BODY", "RMR-A-TEXT", INK)

    ly = ty - 56.0
    sh.text((x + 12.0, ly), "HOW IT WORKS", 2.2, "RMR-HEAD", "RMR-A-TEXT", TERRA)
    ly -= 4.6
    for line in ("Pick a clause code from *RMR-SPEC-CLAUSES*.",
                 "The tab carries the code, the work section",
                 "carries the title and the body is wrapped",
                 "to the width you give it. Edit the table to",
                 "add your office clauses."):
        sh.text((x + 12.0, ly), line, 1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)
        ly -= 3.5


def draw_doc_specindex(sh):
    x, y, w, h = 316.0, 396.0, 250.0, 140.0
    ty = _panel(sh, x, y, w, h, "SPECIFICATION INDEX  |  RMR-SPECINDEX")

    ox = x + 12.0
    oy = ty - 5.0
    sh.text((ox, oy), "JOB %s   |   %s" % ("2401", "ROOMNRROOF REFERENCE APARTMENT"),
            1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    oy -= 8.0
    colw = (30.0, 160.0)
    rowh = 5.0
    _doc_head(sh, ox, oy, colw, rowh, ("CLAUSE", "WORK SECTION"))
    oy -= rowh
    last = ""
    for code, trade, title, text in DATA["specs"]:
        if trade != last:
            sh.solid((ox, oy - rowh), sum(colw), rowh, "RMR-PRES-TITLE", TERRA)
            sh.text((ox + 1.6, oy - rowh + 1.4), trade, 2.0, "RMR-HEAD",
                    "RMR-PRES-TITLE", SAND)
            oy -= rowh
            last = trade
        sh.rect((ox, oy - rowh), sum(colw), rowh, "RMR-A-FRAME", SLATE)
        sh.line((ox + colw[0], oy - rowh), (ox + colw[0], oy), "RMR-A-FRAME", SLATE)
        sh.text((ox + 1.6, oy - rowh + 1.4), code, 2.0, "RMR-LABEL", "RMR-A-TEXT", TERRA)
        sh.text((ox + colw[0] + 1.6, oy - rowh + 1.4), title, 2.0, "RMR-BODY",
                "RMR-A-TEXT", INK)
        oy -= rowh


def _doc_head(sh, x, y, colw, rowh, labels):
    """Header band of a documentation table, drawn from y down by rowh."""
    sh.solid((x, y - rowh), sum(colw), rowh, "RMR-PRES-TITLE", SAND)
    cx = x
    for i, label in enumerate(labels):
        sh.text((cx + 1.6, y - rowh + 1.4), label, 2.0, "RMR-HEAD", "RMR-A-TEXT", INK)
        cx += colw[i]
        if i < len(colw) - 1:
            sh.line((cx, y - rowh), (cx, y), "RMR-A-FRAME", INK)


def draw_doc_abbrev(sh):
    x, y, w, h = 576.0, 396.0, 240.0, 140.0
    ty = _panel(sh, x, y, w, h, "ABBREVIATIONS  |  RMR-ABBREV")

    ox = x + 12.0
    oy = ty - 5.0
    rows = DATA["abbrevs"]
    sh.text((ox, oy), "%d standard abbreviations" % len(rows), 1.8, "RMR-NOTE",
            "RMR-A-TEXT", SLATE)
    oy -= 6.0
    sh.line((ox, oy), (ox + 210.0, oy), "RMR-A-TEXT", GOLD)
    oy -= 5.0
    count = len(rows)
    half = count // 2 + (0 if count % 2 == 0 else 1)
    y1, y2 = oy, oy
    for i, (abbrev, meaning) in enumerate(rows):
        if i < half:
            sh.text((ox, y1), abbrev, 2.0, "RMR-LABEL", "RMR-A-TEXT", TERRA)
            sh.text((ox + 22.0, y1), meaning, 2.0, "RMR-BODY", "RMR-A-TEXT", SLATE)
            y1 -= 5.0
        else:
            sh.text((ox + 116.0, y2), abbrev, 2.0, "RMR-LABEL", "RMR-A-TEXT", TERRA)
            sh.text((ox + 138.0, y2), meaning, 2.0, "RMR-BODY", "RMR-A-TEXT", SLATE)
            y2 -= 5.0


def draw_doc_revisions(sh):
    x, y, w, h = 20.0, 242.0, 250.0, 144.0
    ty = _panel(sh, x, y, w, h, "REVISION HISTORY  |  RMR-REVLIB")

    ox = x + 12.0
    oy = ty - 5.0
    sh.text((ox, oy), "Current revision 03 is highlighted", 1.8, "RMR-NOTE",
            "RMR-A-TEXT", SLATE)
    oy -= 6.0
    colw = (20.0, 44.0, 110.0, 26.0)
    rowh = 6.0
    _doc_head(sh, ox, oy, colw, rowh, ("REV", "DATE", "DESCRIPTION", "BY"))
    oy -= rowh
    for rev, date, description, by in DATA["revisions"]:
        if rev == "03":
            sh.solid((ox, oy - rowh), sum(colw), rowh, "RMR-PRES-KEY", SAND)
        sh.rect((ox, oy - rowh), sum(colw), rowh, "RMR-A-FRAME", SLATE)
        cx = ox
        for i in range(len(colw) - 1):
            cx += colw[i]
            sh.line((cx, oy - rowh), (cx, oy), "RMR-A-FRAME", SLATE)
        sh.text((ox + 1.6, oy - rowh + 1.7), rev, 2.1, "RMR-LABEL", "RMR-A-TEXT", TERRA)
        sh.text((ox + colw[0] + 1.6, oy - rowh + 1.7), date, 2.0, "RMR-BODY",
                "RMR-A-TEXT", INK)
        sh.text((ox + colw[0] + colw[1] + 1.6, oy - rowh + 1.7), description, 2.0,
                "RMR-BODY", "RMR-A-TEXT", INK)
        sh.text((ox + colw[0] + colw[1] + colw[2] + 1.6, oy - rowh + 1.7), by, 2.0,
                "RMR-BODY", "RMR-A-TEXT", INK)
        oy -= rowh

    oy -= 4.0
    sh.text((ox, oy), "Rows come from *RMR-REVISIONS*, so the", 1.8, "RMR-NOTE",
            "RMR-A-TEXT", SLATE)
    sh.text((ox, oy - 3.4), "table and the title block never drift apart.",
            1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)


ROOMSCHED = (
    ("01", "LIVING / DINING", "32.40", "Porcelain tile 600x600", "Matte emulsion"),
    ("02", "KITCHEN", "14.85", "Porcelain tile 600x600", "Ceramic tile"),
    ("03", "MASTER BEDROOM", "18.60", "Engineered oak", "Matte emulsion"),
    ("04", "BEDROOM 02", "12.40", "Engineered oak", "Matte emulsion"),
    ("05", "BATHROOM", "6.20", "Non-slip tile 300x300", "Ceramic tile"),
    ("06", "BALCONY", "8.75", "External tile 300x300", "External paint"),
)


def draw_doc_roomsched(sh):
    x, y, w, h = 280.0, 242.0, 250.0, 144.0
    ty = _panel(sh, x, y, w, h, "ROOM DATA SCHEDULE  |  RMR-ROOMSCHED")

    ox = x + 10.0
    oy = ty - 5.0
    total = sum(float(r[2]) for r in ROOMSCHED)
    sh.text((ox, oy), "%d rooms  |  total %.2f m2  |  %.1f sq ft"
            % (len(ROOMSCHED), total, total * 10.7639), 1.8, "RMR-NOTE",
            "RMR-A-TEXT", SLATE)
    oy -= 6.0
    colw = (16.0, 48.0, 24.0, 74.0, 54.0)
    rowh = 6.0
    _doc_head(sh, ox, oy, colw, rowh, ("NO.", "ROOM", "M2", "FLOOR", "WALL"))
    oy -= rowh
    for row in ROOMSCHED:
        sh.rect((ox, oy - rowh), sum(colw), rowh, "RMR-A-FRAME", SLATE)
        cx = ox
        for i in range(len(colw) - 1):
            cx += colw[i]
            sh.line((cx, oy - rowh), (cx, oy), "RMR-A-FRAME", SLATE)
        cx = ox
        for i, value in enumerate(row):
            sh.text((cx + 1.4, oy - rowh + 1.7), value, 1.9,
                    "RMR-LABEL" if i < 2 else "RMR-BODY", "RMR-A-TEXT",
                    TERRA if i == 0 else INK)
            cx += colw[i]
        oy -= rowh
    sh.solid((ox, oy - rowh), sum(colw), rowh, "RMR-PRES-KEY", SAND)
    sh.text((ox + 1.4, oy - rowh + 1.7), "TOTAL", 2.0, "RMR-HEAD", "RMR-A-TEXT", TERRA)
    sh.text((ox + colw[0] + colw[1] + 1.4, oy - rowh + 1.7), "%.2f" % total, 2.0,
            "RMR-HEAD", "RMR-A-TEXT", TERRA)
    oy -= rowh

    oy -= 4.0
    sh.text((ox, oy), "Finishes are pulled from *RMR-FINISH-SPECS*", 1.8, "RMR-NOTE",
            "RMR-A-TEXT", SLATE)
    sh.text((ox, oy - 3.4), "whenever the room name matches a row.",
            1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)


def draw_doc_sheetindex(sh):
    x, y, w, h = 540.0, 242.0, 276.0, 144.0
    ty = _panel(sh, x, y, w, h, "SHEET INDEX  |  RMR-SHEETINDEX")

    ox = x + 12.0
    oy = ty - 5.0
    sheets = DATA["sheets"]
    sh.text((ox, oy), "%d sheets  |  current sheet A-000 is highlighted" % len(sheets),
            1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    oy -= 8.0
    cw, ch, gap = 82.0, 34.0, 8.0
    cols = 3
    for i, (number, title, scale, rev, status) in enumerate(sheets):
        if i > 0 and i % cols == 0:
            oy -= ch + gap
        cx = ox + (i % cols) * cw
        if number == "A-000":
            sh.solid((cx, oy - 8.0), cw - 4.0, 8.0, "RMR-PRES-TITLE", TERRA)
            sh.text((cx + 2.0, oy - 5.6), number, 3.4, "RMR-NUMBER",
                    "RMR-PRES-TITLE", SAND)
            sh.rect((cx, oy - ch), cw - 4.0, ch, "RMR-A-FRAME", TERRA)
        else:
            sh.solid((cx, oy - 8.0), cw - 4.0, 8.0, "RMR-PRES-KEY", SAND)
            sh.text((cx + 2.0, oy - 5.6), number, 3.4, "RMR-NUMBER", "RMR-A-TEXT", INK)
            sh.rect((cx, oy - ch), cw - 4.0, ch, "RMR-A-FRAME", SLATE)
        sh.text((cx + 2.0, oy - 15.0), _shorten(title, 22), 2.0, "RMR-BODY",
                "RMR-A-TEXT", INK)
        sh.text((cx + 2.0, oy - 19.4), "%s   REV %s" % (scale, rev), 1.9, "RMR-NOTE",
                "RMR-A-TEXT", SLATE)
        sh.text((cx + 2.0, oy - 26.0), _shorten(status, 22), 1.9, "RMR-MARK",
                "RMR-A-TEXT", GOLD)


def _shorten(text, limit):
    return text if len(text) <= limit else text[:max(1, limit - 1)] + "."


def draw_doc_checklist(sh):
    x, y, w, h = 20.0, 74.0, 286.0, 158.0
    ty = _panel(sh, x, y, w, h, "PRE-ISSUE CHECKLIST  |  RMR-CHECKLIST")

    ox = x + 12.0
    oy = ty - 5.0
    rows = DATA["checklist"]
    sh.text((ox, oy), "%d items  |  tick by hand or with a revision cloud" % len(rows),
            1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    oy -= 6.0
    rowh = 5.4
    last = ""
    for group, item in rows:
        if group != last:
            sh.solid((ox, oy - rowh), 254.0, rowh, "RMR-PRES-KEY", SAND)
            sh.text((ox + 1.6, oy - rowh + 1.6), group, 2.1, "RMR-HEAD",
                    "RMR-A-TEXT", INK)
            oy -= rowh
            last = group
        sh.rect((ox + 1.6, oy - rowh + 1.2), 3.0, 3.0, "RMR-A-FRAME", SLATE)
        sh.text((ox + 7.0, oy - rowh + 1.6), item, 2.0, "RMR-BODY", "RMR-A-TEXT", INK)
        oy -= rowh


def draw_doc_cover(sh):
    x, y, w, h = 316.0, 74.0, 240.0, 158.0
    ty = _panel(sh, x, y, w, h, "COVER SHEET  |  RMR-COVER / RMR-DOCSHEET")

    # miniature A1 cover sheet, sized so the caption sits clear above it
    cw = 140.0
    chh = cw / (841.0 / 594.0)
    ox = x + 20.0
    oy = y + 12.0
    sh.rect((ox, oy), cw, chh, "RMR-A-FRAME", INK)
    sh.rect((ox + 2.0, oy + 2.0), cw - 4.0, chh - 4.0, "RMR-A-FRAME", TEAL)
    sh.solid((ox + 2.0, oy + chh - 13.0), cw - 4.0, 9.0, "RMR-PRES-TITLE", TERRA)
    sh.text((ox + 5.0, oy + chh - 10.0), "RooMNRooF", 4.2, "RMR-TITLE",
            "RMR-PRES-TITLE", SAND)
    cy = oy + chh - 20.0
    sh.text((ox + 4.0, cy), "ROOMNRROOF APARTMENT", 3.4, "RMR-TITLE", "RMR-A-TEXT", INK)
    cy -= 5.0
    sh.text((ox + 4.0, cy), "CLIENT NAME", 2.2, "RMR-HEAD", "RMR-A-TEXT", TERRA)
    cy -= 4.0
    sh.text((ox + 4.0, cy), "JOB 2401  |  ISSUED FOR REVIEW", 1.7, "RMR-NOTE",
            "RMR-A-TEXT", SLATE)
    cy -= 4.0
    sh.line((ox + 4.0, cy), (ox + cw - 6.0, cy), "RMR-A-TEXT", GOLD)
    cy -= 5.0
    sh.text((ox + 4.0, cy), "DRAWING SET", 2.2, "RMR-HEAD", "RMR-A-TEXT", TERRA)
    cy -= 4.5
    for number, title, scale, rev, status in DATA["sheets"]:
        sh.text((ox + 4.0, cy), number, 1.9, "RMR-NUMBER", "RMR-A-TEXT", TERRA)
        sh.text((ox + 18.0, cy), _shorten(title, 24), 1.8, "RMR-BODY",
                "RMR-A-TEXT", INK)
        sh.text((ox + 118.0, cy), scale, 1.7, "RMR-BODY", "RMR-A-TEXT", SLATE)
        cy -= 3.6
    # title block stub
    sh.rect((ox + cw - 46.0, oy + 2.0), 44.0, 12.0, "RMR-A-FRAME", INK)
    sh.solid((ox + cw - 46.0, oy + 2.0), 10.0, 12.0, "RMR-PRES-TITLE", TERRA)

    ly = ty - 4.0
    sh.text((x + 12.0, ly), "RMR-COVER builds the sheet above from", 1.8, "RMR-NOTE",
            "RMR-A-TEXT", SLATE)
    sh.text((x + 12.0, ly - 3.4), "*RMR-PROJECT* and *RMR-SHEET-LIST*.", 1.8,
            "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((x + 12.0, ly - 6.8), "RMR-DOCSHEET lays the specification", 1.8,
            "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((x + 12.0, ly - 10.2), "index, abbreviations, revisions and", 1.8,
            "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((x + 12.0, ly - 13.6), "the checklist onto one A1 sheet, and", 1.8,
            "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((x + 12.0, ly - 17.0), "RMR-DOCLIST lists every DWG and PDF", 1.8,
            "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((x + 12.0, ly - 20.4), "next to the drawing, with a CSV.", 1.8,
            "RMR-NOTE", "RMR-A-TEXT", SLATE)


def draw_doc_commands(sh):
    x, y, w, h = 576.0, 74.0, 240.0, 158.0
    ty = _panel(sh, x, y, w, h, "DOCUMENTATION SUITE  |  10 NEW COMMANDS")

    entries = (
        ("RMR-SPECNOTE", "One specification clause as a", "titled, wrapped note."),
        ("RMR-SPECINDEX", "Clause index grouped by trade", "from the clause table."),
        ("RMR-ABBREV", "Two-column abbreviations", "legend for the set."),
        ("RMR-REVLIB", "Revision history with the", "current revision marked."),
        ("RMR-CHECKLIST", "Pre-issue checklist with", "tick boxes, printed too."),
        ("RMR-ROOMSCHED", "Room areas and finishes from", "picked boundaries."),
        ("RMR-DOCLIST", "Folder contents as a table", "and a CSV document list."),
        ("RMR-SHEETINDEX", "Sheet index grid with the", "current sheet highlighted."),
        ("RMR-COVER", "Cover sheet: brand, project", "data and the drawing set."),
        ("RMR-DOCSHEET", "The whole documentation", "sheet in one command."),
    )
    ly = ty - 4.0
    for name, line1, line2 in entries:
        sh.text((x + 10.0, ly), name, 2.3, "RMR-MARK", "RMR-A-TEXT", TEAL)
        sh.text((x + 10.0, ly - 3.4), line1, 1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)
        sh.text((x + 10.0, ly - 6.3), line2, 1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)
        ly -= 12.6


def build_documentation():
    global SHEET_TITLE, SHEET_SUBTITLE, SHEET_NOTE
    SHEET_TITLE = "DOCUMENTATION SUITE SHEET"
    SHEET_SUBTITLE = ("SPECIFICATIONS, ABBREVIATIONS, REVISIONS, ROOM DATA, "
                      "SHEET INDEX AND ISSUE CHECKS")
    SHEET_NOTE = ("The 8.0 documentation suite: the written information that turns "
                  "a coordinated drawing set into an issued one.")
    doc = build_document()
    sh = Sheet(doc)
    draw_frame(sh)
    draw_header(sh)
    draw_doc_specnote(sh)
    draw_doc_specindex(sh)
    draw_doc_abbrev(sh)
    draw_doc_revisions(sh)
    draw_doc_roomsched(sh)
    draw_doc_sheetindex(sh)
    draw_doc_checklist(sh)
    draw_doc_cover(sh)
    draw_doc_commands(sh)
    draw_title_block(sh)
    return doc


# --------------------------------------------------------------------------- #
# 13. presentation sheet (9.0): axonometric massing, one point interior
#     perspective, construction build-ups, swatch board, colour board,
#     programme, area chart, brand masthead and image board.
# --------------------------------------------------------------------------- #

COS30 = 0.8660254


def _quad(sh, q1, q2, q3, q4, layer, rgb):
    """Filled quadrilateral, the same corner order as RMR:Quad."""
    sh.hatch_pattern([q1, q2, q3, q4], layer, rgb, "SOLID")


def _axo(p, height, k):
    return ((p[0] - p[1]) * COS30 * k, (p[0] + p[1]) * 0.5 * k + height * k)


def draw_pres_axo(sh):
    x, y, w, h = 20.0, 396.0, 286.0, 140.0
    ty = _panel(sh, x, y, w, h, "AXONOMETRIC MASSING  |  RMR-AXO")

    sh.text((x + 12.0, ty - 4.0),
            "12000 x 8000 footprint extruded to 3300 mm, 30 degree projection",
            1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    k = 0.007
    ox, oy = 110.0, 406.0
    plan = [(0.0, 0.0), (12000.0, 0.0), (12000.0, 8000.0), (0.0, 8000.0)]
    height = 3300.0
    base = [(ox + _axo(p, 0.0, k)[0], oy + _axo(p, 0.0, k)[1]) for p in plan]
    top = [(ox + _axo(p, height, k)[0], oy + _axo(p, height, k)[1]) for p in plan]

    # top face, then only the two vertical faces that point at the viewer
    _quad(sh, top[0], top[1], top[2], top[3], "RMR-M-FILL", (244, 238, 226))
    front = []
    n = len(plan)
    for i in range(n):
        px, py = plan[i]
        qx, qy = plan[(i + 1) % n]
        if (qy - py) < (qx - px):
            front.append(i)
            shade = (214, 196, 178) if abs(qy - py) > abs(qx - px) else (232, 214, 194)
            j = (i + 1) % n
            _quad(sh, base[i], base[j], top[j], top[i], "RMR-M-FILL", shade)
            sh.poly([base[i], base[j], top[j], top[i]], [0.0] * 4, True,
                    "RMR-00-REF", SLATE)
    for i in range(n):
        sh.line(base[i], top[i], "RMR-M-WALL", TERRA)
    sh.poly(base, [0.0] * n, True, "RMR-00-REF", SLATE)
    sh.poly(top, [0.0] * n, True, "RMR-M-WALL", TERRA)

    # height note on the near vertical
    sh.line((top[0][0] + 6.0, top[0][1]), (top[0][0] + 14.0, top[0][1]),
            "RMR-A-LEADER", GOLD)
    sh.text((top[0][0] + 16.0, top[0][1] - 1.2),
            "AXONOMETRIC  |  HEIGHT 3300 mm  |  30 DEGREES", 2.4, "RMR-HEAD",
            "RMR-A-TEXT", TERRA)

    # the plan footprint it came from
    ix, iy = 206.0, 412.0
    sh.rect((ix, iy), 12000.0 * k, 8000.0 * k, "RMR-00-REF", SLATE)
    sh.text((ix, iy - 5.0), "PLAN FOOTPRINT", 2.0, "RMR-LABEL", "RMR-A-TEXT", INK)
    sh.text((x + 12.0, y + 4.0), "Only the two faces pointing at the viewer are "
            "filled, in two shades.", 1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)


def draw_pres_roomview(sh):
    x, y, w, h = 316.0, 396.0, 250.0, 140.0
    ty = _panel(sh, x, y, w, h, "INTERIOR PERSPECTIVE  |  RMR-ROOMVIEW")

    frame = 170.0
    room_w, room_h, eye = 4200.0, 2700.0, 1500.0
    t = 0.62
    hp = frame * room_h / room_w
    bx, by = x + 26.0, y + 12.0
    fl = (bx, by)
    fr = (bx + frame, by)
    tl = (bx, by + hp)
    tr = (bx + frame, by + hp)
    vpx = bx + frame / 2.0
    vpy = by + hp * eye / room_h
    lerp = lambda p: (p[0] + t * (vpx - p[0]), p[1] + t * (vpy - p[1]))
    bfl, bfr, btl, btr = lerp(fl), lerp(fr), lerp(tl), lerp(tr)

    _quad(sh, bfl, bfr, btr, btl, "RMR-M-FILL", (226, 232, 228))
    _quad(sh, fl, tl, btl, bfl, "RMR-M-FILL", (238, 231, 216))
    _quad(sh, fr, tr, btr, bfr, "RMR-M-FILL", (246, 240, 226))
    _quad(sh, tl, tr, btr, btl, "RMR-M-FILL", (250, 248, 242))
    _quad(sh, fl, fr, bfr, bfl, "RMR-M-FILL", SAND)
    for i in range(1, 9):
        gx = fl[0] + frame * i / 9.0
        end = (gx + t * (vpx - gx), fl[1] + t * (vpy - fl[1]))
        sh.line((gx, fl[1]), end, "RMR-00-REF", SLATE)
    for i in range(1, 4):
        g = i / 4.0
        sh.line((fl[0] + g * (bfl[0] - fl[0]), fl[1] + g * (bfl[1] - fl[1])),
                (fr[0] + g * (bfr[0] - fr[0]), fr[1] + g * (bfr[1] - fr[1])),
                "RMR-00-REF", SLATE)
    sh.line(bfl, bfr, "RMR-M-WALL", TERRA)
    sh.line(bfr, btr, "RMR-M-WALL", TERRA)
    sh.line(btr, btl, "RMR-M-WALL", TERRA)
    sh.line(btl, bfl, "RMR-M-WALL", TERRA)
    sh.rect((bx, by), frame, hp, "RMR-M-WALL", TERRA)
    sh.line(fl, bfl, "RMR-M-WALL", TERRA)
    sh.line(fr, bfr, "RMR-M-WALL", TERRA)
    sh.line(tl, btl, "RMR-M-WALL", TERRA)
    sh.line(tr, btr, "RMR-M-WALL", TERRA)

    sh.text((x + 12.0, ty - 3.0),
            "One vanishing point on the eye level, back wall at 0.62", 1.8,
            "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((x + 12.0, y + 4.0), "4200 x 5400 x 2700 mm   |   eye 1500 mm", 1.8,
            "RMR-NOTE", "RMR-A-TEXT", SLATE)


def draw_pres_buildup(sh):
    x, y, w, h = 576.0, 396.0, 240.0, 140.0
    ty = _panel(sh, x, y, w, h, "CONSTRUCTION BUILD-UP  |  RMR-BUILDUP")

    rows = [r for r in DATA["buildups"] if r[0] == "EXTWALL"]
    total = float(sum(int(r[3]) for r in rows))
    drawn = 80.0
    wide = 80.0
    bx, by = x + 14.0, y + 16.0
    k = drawn / total
    cy = by
    label_y = by + drawn + 4.0
    for row in rows:
        name = row[2]
        thk = float(row[3])
        rgb = tuple(int(v) for v in row[4])
        band = thk * k
        pts = [(bx, cy), (bx + wide, cy), (bx + wide, cy + band), (bx, cy + band)]
        sh.hatch_pattern(pts, "RMR-M-HATCH", rgb, str(row[5]), scale=2.0)
        sh.rect((bx, cy), wide, band, "RMR-A-FRAME", SLATE)
        sh.line((bx + wide, cy + band / 2.0), (bx + wide + 12.0, label_y),
                "RMR-A-LEADER", GOLD)
        sh.line((bx + wide + 12.0, label_y), (bx + wide + 16.0, label_y),
                "RMR-A-LEADER", GOLD)
        sh.text((bx + wide + 18.0, label_y - 1.0),
                "%s   %d mm" % (name, int(thk)), 2.2, "RMR-LABEL", "RMR-A-TEXT", INK)
        sh.text((bx + wide + 18.0, label_y - 4.4), str(row[6]), 1.8, "RMR-NOTE",
                "RMR-A-TEXT", SLATE)
        cy += band
        label_y -= 8.0
    sh.text((x + 12.0, ty - 4.0), "Layers from *RMR-BUILDUP-SPECS*", 1.8,
            "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((bx, y + 6.0), "EXTWALL BUILD-UP   |   TOTAL %d mm" % int(total), 2.6,
            "RMR-HEAD", "RMR-A-TEXT", TERRA)


def draw_pres_swatch(sh):
    x, y, w, h = 20.0, 242.0, 250.0, 144.0
    ty = _panel(sh, x, y, w, h, "MATERIAL SWATCH BOARD  |  RMR-SWATCH")

    cols = 6
    cell, gap = 30.0, 5.0
    bx, by = x + 12.0, ty - 6.0
    sh.text((bx, by), "MATERIALS", 3.4, "RMR-HEAD", "RMR-A-TEXT", TERRA)
    sh.text((bx, by - 5.0), "%d materials from *RMR-HATCH-SPECS*"
            % len(DATA["hatches"]), 1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    for index, spec in enumerate(DATA["hatches"]):
        col, row = index % cols, index // cols
        ox = bx + col * (cell + gap)
        oy = by - 14.0 - row * (cell + 20.0)
        rgb = tuple(int(v) for v in spec[6])
        pts = [(ox, oy), (ox + cell, oy), (ox + cell, oy - cell), (ox, oy - cell)]
        sh.hatch_pattern(pts, "RMR-M-HATCH", rgb, str(spec[2]), scale=float(spec[3]) * 0.35)
        sh.rect((ox, oy - cell), cell, cell, "RMR-A-FRAME", SLATE)
        sh.text((ox, oy - cell - 4.0), str(spec[0]), 2.2, "RMR-NUMBER",
                "RMR-A-TEXT", TERRA)
        sh.text((ox, oy - cell - 7.4), _shorten(str(spec[1]), 18), 1.7,
                "RMR-BODY", "RMR-A-TEXT", INK)


def draw_pres_colourboard(sh):
    x, y, w, h = 280.0, 242.0, 250.0, 144.0
    ty = _panel(sh, x, y, w, h, "COLOUR REFERENCE BOARD  |  RMR-COLOURBOARD")

    bx = x + 12.0
    ly = ty - 4.0
    sh.text((bx, ly), "BRAND PALETTE", 2.4, "RMR-HEAD", "RMR-A-TEXT", GOLD)
    ly -= 6.0
    brand = (("INK", INK), ("TERRA", TERRA), ("TEAL", TEAL), ("GOLD", GOLD),
             ("SAND", SAND), ("BLUE", BLUE), ("SLATE", SLATE))
    cx = bx
    for name, rgb in brand:
        sh.solid((cx, ly), 20.0, 8.0, "RMR-M-FILL", rgb)
        sh.rect((cx, ly), 20.0, 8.0, "RMR-A-FRAME", SLATE)
        sh.text((cx, ly - 4.0), name, 1.8, "RMR-LABEL", "RMR-A-TEXT", INK)
        sh.text((cx, ly - 7.0), "%d %d %d" % tuple(int(v) for v in rgb), 1.6,
                "RMR-MARK", "RMR-A-TEXT", SLATE)
        cx += 24.0

    ly -= 18.0
    sh.solid((bx, ly - 6.0), 200.0, 6.0, "RMR-PRES-TITLE", TERRA)
    sh.text((bx + 2.0, ly - 4.2), "MAIN THEME", 2.2, "RMR-HEAD", "RMR-PRES-TITLE", SAND)
    ly -= 10.0
    for name, group, rgb, ltype, lw, desc in DATA["layers"]:
        if str(group).upper() != "MAIN THEME":
            continue
        rgb = tuple(int(v) for v in rgb)
        sh.solid((bx, ly), 12.0, 4.0, "RMR-M-FILL", rgb)
        sh.rect((bx, ly), 12.0, 4.0, "RMR-A-FRAME", SLATE)
        sh.text((bx + 15.0, ly), name, 2.0, "RMR-LABEL", "RMR-A-TEXT", INK)
        sh.text((bx + 96.0, ly), "%d %d %d" % tuple(int(v) for v in rgb), 1.8,
                "RMR-MARK", "RMR-A-TEXT", SLATE)
        ly -= 5.4
    sh.text((bx, ly - 4.0), "The board continues with the other six groups.",
            1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)


def draw_pres_programme(sh):
    x, y, w, h = 540.0, 242.0, 276.0, 144.0
    ty = _panel(sh, x, y, w, h, "PROGRAMME  |  RMR-PROGRAMME")

    colw = 4.5
    rowh = 9.0
    bx, by = x + 12.0, ty - 6.0
    rows = DATA["programme"]
    weeks = max(int(r[1]) + int(r[2]) for r in rows)
    sh.text((bx, by), "PROGRAMME", 3.4, "RMR-HEAD", "RMR-A-TEXT", TERRA)
    sh.text((bx, by - 5.0), "%d weeks  |  *RMR-PROGRAMME-SPECS*" % weeks, 1.8,
            "RMR-NOTE", "RMR-A-TEXT", SLATE)
    gridx = bx + 56.0
    bottom = by - 16.0 - rowh * len(rows)
    for i in range(weeks + 1):
        if i % 4 == 0:
            gx = gridx + i * colw
            sh.line((gx, by - 8.0), (gx, bottom), "RMR-00-REF", SLATE)
            sh.text((gx, by - 12.0), str(i), 1.8, "RMR-NUMBER", "RMR-A-TEXT", TERRA)
    palette = {"TEAL": TEAL, "TERRA": TERRA, "GOLD": GOLD,
               "BLUE": BLUE, "SLATE": SLATE, "SAND": SAND}
    for index, row in enumerate(rows):
        name, start, dur = str(row[0]), int(row[1]), int(row[2])
        rgb = palette.get(str(row[3]).upper(), TERRA)
        ry = by - 16.0 - index * rowh
        sh.text((bx, ry), name, 2.1, "RMR-LABEL", "RMR-A-TEXT", INK)
        bx2 = gridx + start * colw
        sh.solid((bx2, ry - 1.0), dur * colw, 5.0, "RMR-M-FILL", rgb)
        sh.rect((bx2, ry - 1.0), dur * colw, 5.0, "RMR-A-FRAME", SLATE)
        sh.text((bx2 + dur * colw + 3.0, ry), "%d wks" % dur, 1.9, "RMR-BODY",
                "RMR-A-TEXT", INK)


AREAS = (("LIVING / DINING", 32.40), ("KITCHEN", 14.85),
         ("MASTER BEDROOM", 18.60), ("BEDROOM 02", 12.40),
         ("BATHROOM", 6.20), ("BALCONY", 8.75))


def draw_pres_chart(sh):
    x, y, w, h = 20.0, 74.0, 286.0, 158.0
    ty = _panel(sh, x, y, w, h, "AREA CHART AND MASTHEAD  |  AREACHART / BRANDING")

    bx, by = x + 12.0, ty - 6.0
    total = sum(a for _, a in AREAS)
    widest = max(a for _, a in AREAS)
    barw = 120.0
    rowh = 9.0
    sh.text((bx, by), "AREA DISTRIBUTION  |  RMR-AREACHART", 3.4, "RMR-HEAD",
            "RMR-A-TEXT", TERRA)
    sh.text((bx, by - 5.0), "%d rooms  |  total %.2f m2  |  %.1f sq ft"
            % (len(AREAS), total, total * 10.7639), 1.8, "RMR-NOTE",
            "RMR-A-TEXT", SLATE)
    cycle = [TERRA, GOLD, TEAL, BLUE, SLATE]
    for i, (name, area) in enumerate(AREAS):
        ry = by - 12.0 - i * rowh
        bar = area / widest * barw
        sh.text((bx, ry), name, 2.1, "RMR-LABEL", "RMR-A-TEXT", INK)
        sh.solid((bx + 56.0, ry - 1.0), bar, 5.0, "RMR-M-FILL", cycle[i % 5])
        sh.rect((bx + 56.0, ry - 1.0), bar, 5.0, "RMR-A-FRAME", SLATE)
        sh.text((bx + 60.0 + bar, ry), "%.2f m2  %.1f%%" % (area, area / total * 100.0),
                1.9, "RMR-BODY", "RMR-A-TEXT", INK)

    # brand masthead, drawn at 0.6 so it fits under the chart
    s = 0.6
    my = 140.0
    sh.text((bx, my), "RooMNRooF", 20.0 * s, "RMR-TITLE", "RMR-PRES-TITLE", TERRA)
    sh.line((bx, my - 6.0 * s), (bx + 210.0 * s, my - 6.0 * s), "RMR-PRES-TITLE", GOLD)
    sh.text((bx, my - 12.0 * s), "CONSULTANT   |   2D CAD STANDARD", 3.4 * s,
            "RMR-HEAD", "RMR-A-TEXT", INK)
    sh.text((bx, my - 18.0 * s), "ROOF THE ROOM", 2.6 * s, "RMR-MARK",
            "RMR-A-TEXT", GOLD)
    sh.text((bx, my - 28.0 * s), "ROOMNRROOF REFERENCE APARTMENT", 5.0 * s,
            "RMR-TITLE", "RMR-A-TEXT", INK)
    sh.text((bx, my - 34.0 * s), "CLIENT   |   JOB 2401   |   ISSUED FOR REVIEW",
            2.6 * s, "RMR-NOTE", "RMR-A-TEXT", SLATE)


def draw_pres_moodboard(sh):
    x, y, w, h = 316.0, 74.0, 240.0, 158.0
    ty = _panel(sh, x, y, w, h, "IMAGE BOARD  |  RMR-MOODBOARD")

    s = 0.62
    cols = 3
    fw, fh, gap = 104.0 * s, 74.0 * s, 12.0 * s
    bx, by = x + 12.0, ty - 6.0
    sh.text((bx, by), "IMAGE BOARD", 3.4, "RMR-HEAD", "RMR-A-TEXT", TERRA)
    sh.text((bx, by - 5.0), "Use IMAGEATTACH to drop a picture into each frame",
            1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    for index, row in enumerate(DATA["mood"]):
        col, rw = index % cols, index // cols
        ox = bx + col * (fw + gap)
        oy = by - 12.0 * s - rw * (fh + 18.0 * s)
        sh.rect((ox, oy - fh), fw, fh, "RMR-PRES-VPORT", TEAL)
        sh.line((ox, oy - fh), (ox + fw, oy), "RMR-00-REF", SLATE)
        sh.line((ox, oy), (ox + fw, oy - fh), "RMR-00-REF", SLATE)
        sh.solid((ox, oy - 6.0 * s), 16.0 * s, 6.0 * s, "RMR-PRES-TITLE", TERRA)
        sh.text((ox + 2.0 * s, oy - 4.4 * s), str(row[0]), 2.4 * s, "RMR-NUMBER",
                "RMR-PRES-TITLE", SAND)
        sh.text((ox, oy - fh - 5.0), str(row[1]), 2.2 * s, "RMR-LABEL",
                "RMR-A-TEXT", INK)
    sh.text((bx, y + 4.0), "Six captioned slots from *RMR-MOOD-SPECS*", 1.8,
            "RMR-NOTE", "RMR-A-TEXT", SLATE)


def draw_pres_commands(sh):
    x, y, w, h = 576.0, 74.0, 240.0, 158.0
    ty = _panel(sh, x, y, w, h, "PRESENTATION SUITE  |  10 NEW COMMANDS")

    entries = (
        ("RMR-AXO", "Extrudes a plan outline into a", "30 degree axonometric mass."),
        ("RMR-ROOMVIEW", "One point interior perspective", "with a floor grid."),
        ("RMR-BUILDUP", "Layered wall, floor or roof", "build-up with leaders."),
        ("RMR-SWATCH", "Material swatch board from", "the hatch library."),
        ("RMR-COLOURBOARD", "Brand palette and every layer", "colour with RGB values."),
        ("RMR-MOODBOARD", "Captioned image frames for", "client presentations."),
        ("RMR-AREACHART", "Area distribution bars with", "percentages and a total."),
        ("RMR-PROGRAMME", "Programme bar chart with a", "week grid and stage names."),
        ("RMR-BRANDING", "RooMNRooF masthead filled", "from the project data."),
        ("RMR-PRESENTSHEET", "Complete presentation sheet", "in one command."),
    )
    ly = ty - 4.0
    for name, line1, line2 in entries:
        sh.text((x + 10.0, ly), name, 2.3, "RMR-MARK", "RMR-A-TEXT", TEAL)
        sh.text((x + 10.0, ly - 3.4), line1, 1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)
        sh.text((x + 10.0, ly - 6.3), line2, 1.8, "RMR-NOTE", "RMR-A-TEXT", SLATE)
        ly -= 12.6


def build_presentation():
    global SHEET_TITLE, SHEET_SUBTITLE, SHEET_NOTE
    SHEET_TITLE = "PRESENTATION SUITE SHEET"
    SHEET_SUBTITLE = ("MASSING, PERSPECTIVES, BUILD-UPS, BOARDS, CHARTS "
                      "AND BRANDING")
    SHEET_NOTE = ("The 9.0 presentation suite: the drawings that sell the design "
                  "before a single technical sheet is read.")
    doc = build_document()
    sh = Sheet(doc)
    draw_frame(sh)
    draw_header(sh)
    draw_pres_axo(sh)
    draw_pres_roomview(sh)
    draw_pres_buildup(sh)
    draw_pres_swatch(sh)
    draw_pres_colourboard(sh)
    draw_pres_programme(sh)
    draw_pres_chart(sh)
    draw_pres_moodboard(sh)
    draw_pres_commands(sh)
    draw_title_block(sh)
    return doc


# --------------------------------------------------------------------------- #
# 10.0 QUANTITY AND AUTOMATION SHEET PANELS
# --------------------------------------------------------------------------- #
RATES = DATA["rates"]
ELEMENTS = DATA["elements"]
PROGRAMME = DATA["programme"]
BRAND_RGB = {name: tuple(v) for name, v in DATA["brand"].items()}

# a worked takeoff: (code, quantity) priced against *RMR-RATE-SPECS*
TAKEOFF = (("M200", 86.40), ("F100", 118.20), ("C100", 118.20), ("X100", 236.40),
           ("D100", 9.0), ("W100", 11.0), ("S100", 142.60), ("P100", 24.50))

# a small measured survey: (number, easting, northing, level)
SURVEY_PTS = (
    ("1", 0.00, 0.00, 12.40), ("2", 8.60, 0.40, 12.38), ("3", 17.20, 0.10, 12.41),
    ("4", 25.90, 1.20, 12.30), ("5", 25.40, 9.80, 12.22), ("6", 24.80, 18.60, 12.18),
    ("7", 16.10, 19.10, 12.25), ("8", 7.40, 18.90, 12.31), ("9", 0.30, 18.20, 12.36),
    ("10", 12.80, 9.40, 12.44), ("11", 21.40, 9.90, 12.29), ("12", 4.20, 9.60, 12.42),
)


def _rate(code):
    for spec in RATES:
        if spec[0] == code:
            return spec
    return (code, code, "M2", 0.0)


def _money(value):
    return "{:,.2f}".format(value)


def draw_qty_rates(sh):
    x, y, w, h = 20.0, 396.0, 286.0, 140.0
    ty = _panel(sh, x, y, w, h,
                "RATE LIBRARY  |  RMR-RATES  |  *RMR-RATE-SPECS*")
    rows = []
    for spec in RATES:
        unit = {"M2": "m2", "M3": "m3", "M": "m"}.get(str(spec[2]).upper(),
                                                      str(spec[2]))
        rows.append([spec[0], spec[1][:26], unit, "%.2f" % float(spec[3])])
    _table(sh, x + 10.0, ty, ("CODE", "DESCRIPTION", "UNIT", "RATE"),
           (34.0, 138.0, 28.0, 40.0), rows, text=2.1)
    return ty


def draw_qty_survey(sh):
    x, y, w, h = 316.0, 396.0, 250.0, 140.0
    ty = _panel(sh, x, y, w, h,
                "MEASURED SURVEY  |  RMR-SURVEY  |  CSV POINT IMPORT")

    # plot box: 26.0 x 19.0 m of site inside 210 x 92
    px0, py0 = x + 12.0, y + 16.0
    pw, ph = 200.0, 92.0
    sh.rect((px0, py0), pw, ph, "RMR-A-FRAME", SLATE)
    k = min(pw / 26.0, ph / 19.0)

    pts = []
    for number, east, north, level in SURVEY_PTS:
        qx = px0 + 6.0 + east * k
        qy = py0 + 6.0 + north * k
        pts.append((qx, qy))
        sh.circle((qx, qy), 1.5, "RMR-00-REF", TERRA)
        sh.text((qx + 2.6, qy + 1.4), number, 2.0, "RMR-NUMBER",
                "RMR-A-TEXT", TERRA)
        sh.text((qx + 2.6, qy - 4.6), "%.2f" % level, 1.7, "RMR-MARK",
                "RMR-A-TEXT", SLATE)
    # the traverse string, drawn as the command draws it
    ring = [pts[0], pts[1], pts[2], pts[3], pts[4], pts[5], pts[6], pts[7],
            pts[8], pts[0]]
    sh.poly(ring, [0.0] * len(ring), True, "RMR-00-REF", TEAL)
    inner = [pts[9], pts[10], pts[11]]
    sh.poly(inner, [0.0] * len(inner), False, "RMR-00-REF", BLUE)

    sh.text((x + 12.0, ty - 3.0),
            "12 points  |  extent 25.90 x 19.10 m  |  levels 12.18 to 12.44 m",
            2.0, "RMR-NOTE", "RMR-A-TEXT", INK)
    for i, line in enumerate((
            "RMR-SURVEY reads number,east,north,level from a CSV,",
            "normalises the coordinates to the first point, drops the",
            "blank rows, then plots a numbered marker with its level",
            "and a traverse polyline on RMR-00-REF.")):
        sh.text((x + 12.0, y + 12.0 - i * 4.2), line, 2.0, "RMR-NOTE",
                "RMR-A-TEXT", SLATE)
    return ty


def draw_qty_takeoff(sh):
    x, y, w, h = 576.0, 396.0, 240.0, 140.0
    ty = _panel(sh, x, y, w, h,
                "QUANTITY TAKEOFF  |  RMR-QUANTITY  |  RATE DRIVEN")
    rows = []
    total = 0.0
    for code, qty in TAKEOFF:
        spec = _rate(code)
        cost = qty * float(spec[3])
        total += cost
        rows.append([code, "%.2f" % qty, "%.2f" % float(spec[3]),
                     _money(cost)])
    cy = _table(sh, x + 10.0, ty, ("CODE", "QTY", "RATE", "COST"),
                (34.0, 42.0, 42.0, 62.0), rows, text=2.0)
    sh.solid((x + 10.0, cy - 7.6), 180.0, 7.6, "RMR-PRES-TITLE", SAND)
    sh.text((x + 11.6, cy - 5.4), "TOTAL", 2.2, "RMR-HEAD", "RMR-A-TEXT", INK)
    sh.text((x + 45.6, cy - 5.4), _money(total), 2.2, "RMR-NUMBER",
            "RMR-A-TEXT", TERRA)
    return cy


def draw_qty_costplan(sh):
    x, y, w, h = 20.0, 242.0, 250.0, 144.0
    ty = _panel(sh, x, y, w, h,
                "ELEMENTAL COST PLAN  |  RMR-COSTPLAN")
    total = sum(float(spec[1]) for spec in ELEMENTS)
    sh.text((x + 10.0, ty - 4.0),
            "%d elements  |  total %s" % (len(ELEMENTS), _money(total)),
            2.1, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    rowy = ty - 12.0
    rowh = 10.0
    bar_x = x + 74.0
    bar_w = 96.0
    for spec in ELEMENTS:
        name = spec[0]
        value = float(spec[1])
        share = value / total if total else 0.0
        rgb = BRAND_RGB[str(spec[2]).upper()]
        sh.text((x + 10.0, rowy), name, 2.2, "RMR-LABEL", "RMR-A-TEXT", INK)
        sh.solid((bar_x, rowy - 1.0), bar_w * share, 5.0, "RMR-M-FILL", rgb)
        sh.rect((bar_x, rowy - 1.0), bar_w * share, 5.0, "RMR-A-FRAME", SLATE)
        sh.text((bar_x + bar_w + 4.0, rowy),
                "%s  %.1f%%" % (_money(value), 100.0 * share), 2.0,
                "RMR-BODY", "RMR-A-TEXT", INK)
        rowy -= rowh
    sh.text((x + 10.0, rowy - 3.0), "TOTAL %s" % _money(total), 2.8,
            "RMR-NUMBER", "RMR-A-TEXT", TERRA)
    sh.text((x + 10.0, rowy - 9.0),
            "Allowances live in *RMR-ELEMENT-SPECS*: edit the list and",
            2.0, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((x + 10.0, rowy - 13.2),
            "RMR-COSTPLAN, RMR-PERQM, RMR-CASHFLOW and RMR-QSREPORT",
            2.0, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((x + 10.0, rowy - 17.4), "all read the same numbers.",
            2.0, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    return ty


def draw_qty_perqm(sh):
    x, y, w, h = 280.0, 242.0, 250.0, 144.0
    ty = _panel(sh, x, y, w, h, "COST PER M2  |  RMR-PERQM")
    total = sum(float(spec[1]) for spec in ELEMENTS)
    gifa, bench = 124.0, 2200.0
    perqm = total / gifa
    diff = 100.0 * (perqm - bench) / bench
    over = perqm > bench
    tone = TERRA if over else TEAL

    sh.text((x + 10.0, ty - 4.0),
            "GIFA %.2f m2   |   cost %s" % (gifa, _money(total)),
            2.1, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((x + 10.0, ty - 26.0), "%s" % _money(perqm), 15.0, "RMR-NUMBER",
            "RMR-A-TEXT", tone)
    sh.text((x + 10.0, ty - 33.0), "PER SQUARE METRE", 2.4, "RMR-HEAD",
            "RMR-A-TEXT", SLATE)

    wide = 160.0
    axis_y = ty - 44.0
    top = max(perqm, bench)
    sh.solid((x + 10.0, axis_y), wide * (perqm / top), 6.0, "RMR-M-FILL", tone)
    sh.rect((x + 10.0, axis_y), wide * (perqm / top), 6.0, "RMR-A-FRAME", SLATE)
    sh.solid((x + 10.0, axis_y - 10.0), wide * (bench / top), 6.0,
             "RMR-M-FILL", SAND)
    sh.rect((x + 10.0, axis_y - 10.0), wide * (bench / top), 6.0,
            "RMR-A-FRAME", SLATE)
    sh.text((x + 174.0, axis_y + 0.6), "THIS PROJECT", 2.0, "RMR-LABEL",
            "RMR-A-TEXT", INK)
    sh.text((x + 174.0, axis_y - 9.4), "BENCHMARK", 2.0, "RMR-LABEL",
            "RMR-A-TEXT", INK)
    sh.text((x + 10.0, axis_y - 21.0),
            "%s benchmark by %.1f%%" % ("Over" if over else "Under", abs(diff)),
            2.6, "RMR-HEAD", "RMR-A-TEXT", tone)
    sh.text((x + 10.0, axis_y - 27.0),
            "RMR-PERQM asks for the cost, the area and a benchmark,",
            2.0, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((x + 10.0, axis_y - 31.2),
            "then draws this dashboard in the current text height.",
            2.0, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    return ty


def draw_qty_cashflow(sh):
    x, y, w, h = 540.0, 242.0, 276.0, 144.0
    ty = _panel(sh, x, y, w, h, "CASH FLOW  |  RMR-CASHFLOW")
    total = sum(float(spec[1]) for spec in ELEMENTS)
    dur = float(sum(int(spec[2]) for spec in PROGRAMME))
    weeks = max(int(spec[1]) + int(spec[2]) for spec in PROGRAMME)
    weekly = [0.0] * weeks
    for spec in PROGRAMME:
        start, span = int(spec[1]), int(spec[2])
        stage = total * (span / dur) if dur else 0.0
        for i in range(span):
            if start + i < weeks:
                weekly[start + i] += stage / span

    cumulative, run = [], 0.0
    for value in weekly:
        run += value
        cumulative.append(run)
    peak = max(weekly) if weekly else 0.0
    maxc = cumulative[-1] if cumulative else 0.0

    sh.text((x + 10.0, ty - 4.0),
            "%d weeks  |  total %s  |  peak week %s"
            % (weeks, _money(total), _money(peak)), 2.1, "RMR-NOTE",
            "RMR-A-TEXT", SLATE)

    ox, oy = x + 12.0, ty - 22.0
    colw = 5.6
    maxh = 62.0
    sh.line((ox, oy - maxh * 0.35), (ox + weeks * colw, oy - maxh * 0.35),
            "RMR-00-REF", SLATE)
    for i, value in enumerate(weekly):
        bh = maxh * 0.35 * (value / peak if peak else 0.0)
        sh.solid((ox + i * colw, oy - maxh * 0.35), colw * 0.7, bh,
                 "RMR-M-FILL", GOLD)
    pts = [(ox + i * colw, oy - maxh * (value / maxc if maxc else 0.0))
           for i, value in enumerate(cumulative)]
    sh.poly(pts, [0.0] * len(pts), False, "RMR-M-WALL", TERRA)
    sh.text((ox, oy + 4.0), "WEEKLY SPEND", 2.0, "RMR-LABEL", "RMR-A-TEXT", GOLD)
    sh.text((ox + 96.0, oy + 4.0), "CUMULATIVE S CURVE", 2.0, "RMR-LABEL",
            "RMR-A-TEXT", TERRA)
    sh.text((ox, oy - maxh - 6.0),
            "CUMULATIVE TO %s" % _money(maxc), 2.4, "RMR-NUMBER",
            "RMR-A-TEXT", TERRA)
    for i, spec in enumerate(PROGRAMME):
        sh.text((ox, oy - maxh - 14.0 - i * 4.0),
                "%-22s wk %2d  %2d wks  %s"
                % (spec[0][:22], int(spec[1]), int(spec[2]),
                   _money(total * (int(spec[2]) / dur if dur else 0.0))),
                1.9, "RMR-BODY", "RMR-A-TEXT", SLATE)
    return ty


def draw_qty_csv(sh):
    x, y, w, h = 20.0, 74.0, 286.0, 158.0
    ty = _panel(sh, x, y, w, h,
                "CSV IMPORT  |  RMR-CSVIMPORT  |  ANY TABLE INTO CAD")
    rows = [["ROOM", "LEVEL", "FLOOR", "WALLS", "CEILING", "AREA"],
            ["LIVING", "00", "F200", "X100", "C100", "32.40"],
            ["KITCHEN", "00", "F100", "X100", "C100", "18.60"],
            ["DINING", "00", "F200", "X100", "C100", "14.20"],
            ["BED 01", "00", "F200", "X100", "C100", "21.80"],
            ["BED 02", "00", "F200", "X100", "C100", "16.40"],
            ["BATH", "00", "F100", "X100", "C100", "8.20"],
            ["HALL", "00", "F100", "X100", "C100", "12.40"],
            ["TOTAL", "00", "", "", "", "124.00"]]
    cy = _table(sh, x + 10.0, ty, rows[0],
                (52.0, 40.0, 44.0, 44.0, 48.0, 44.0), rows[1:], text=2.1)
    sh.text((x + 10.0, cy - 6.0),
            "The first row becomes the header band, the rest become",
            2.0, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((x + 10.0, cy - 10.2),
            "body rows, 41 rows maximum, columns auto-sized.",
            2.0, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    return cy


def draw_qty_validate(sh):
    x, y, w, h = 316.0, 74.0, 240.0, 158.0
    ty = _panel(sh, x, y, w, h,
                "VALIDATION AND QS REPORT  |  RMR-VALIDATE / RMR-QSREPORT")
    sh.solid((x + 10.0, ty - 10.0), 210.0, 9.0, "RMR-PRES-TITLE", TEAL)
    sh.text((x + 14.0, ty - 7.4), "VERDICT: PASS", 2.6, "RMR-HEAD",
            "RMR-A-TEXT", SAND)
    lines = [
        "RooMNRooF quantity validation",
        "  %d rates checked" % len(RATES),
        "  0 unrated blocks in the drawing",
        "  Verdict: PASS",
        "",
        "Every rate carries a known unit (m, m2, m3, nr, item)",
        "and a value above zero. Blocks that are not part of",
        "the standard are listed so they can be priced.",
        "",
        "RMR-QSREPORT writes the same numbers to a text file:",
        "  rate library, elemental cost plan, cost per m2,",
        "  and the programme cash flow with project details.",
    ]
    for i, line in enumerate(lines):
        if line == "":
            continue
        sh.text((x + 10.0, ty - 18.0 - i * 5.0), line, 2.0,
                "RMR-HEAD" if i == 0 else "RMR-BODY", "RMR-A-TEXT",
                TERRA if i == 0 else INK)
    return ty


def draw_qty_automation(sh):
    x, y, w, h = 576.0, 74.0, 240.0, 158.0
    ty = _panel(sh, x, y, w, h,
                "AUTOMATION  |  RMR-ALIAS / TOOLPALETTE / AUTO / BATCH")
    steps = [a[0] for a in DATA["auto"]]
    sh.text((x + 10.0, ty - 4.0), "RMR-AUTO runs *RMR-AUTO-SEQUENCE*:",
            2.0, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    for i, label in enumerate(steps):
        sh.text((x + 10.0, ty - 12.0 - i * 4.6), "%d  %s" % (i + 1, label),
                2.0, "RMR-BODY", "RMR-A-TEXT", INK)
    ay = ty - 12.0 - len(steps) * 4.6 - 4.0
    sh.text((x + 10.0, ay), "RMR-ALIAS writes RooMNRooF.pgp:", 2.0,
            "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((x + 10.0, ay - 5.0), "RAXO, *RMR-AXO      RQTY, *RMR-QUANTITY",
            2.0, "RMR-BODY", "RMR-A-TEXT", TEAL)
    sh.text((x + 10.0, ay - 10.0),
            "RMR-TOOLPALETTE writes RooMNRooF.mnu: 14 pull-downs.",
            2.0, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((x + 10.0, ay - 15.0),
            "RMR-BATCH writes RooMNRooF-Batch.scr for a whole folder.",
            2.0, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    return ty


def build_quantity():
    global SHEET_TITLE, SHEET_SUBTITLE, SHEET_NOTE
    SHEET_TITLE = "QUANTITY AND AUTOMATION SHEET"
    SHEET_SUBTITLE = ("SURVEY, TAKEOFF, RATE LIBRARY, COST PLAN, COST PER M2, "
                      "CASH FLOW, CSV AND REPORT")
    SHEET_NOTE = ("The 10.0 suite: the numbers behind the drawing, plus the "
                  "aliases, menu and automation that run the standard.")
    doc = build_document()
    sh = Sheet(doc)
    draw_frame(sh)
    draw_header(sh)
    draw_qty_rates(sh)
    draw_qty_survey(sh)
    draw_qty_takeoff(sh)
    draw_qty_costplan(sh)
    draw_qty_perqm(sh)
    draw_qty_cashflow(sh)
    draw_qty_csv(sh)
    draw_qty_validate(sh)
    draw_qty_automation(sh)
    draw_title_block(sh)
    return doc


# --------------------------------------------------------------------------- #
# 11.0 STRUCTURAL AND MEP SHEET PANELS
# --------------------------------------------------------------------------- #
RMR_COLUMNS = DATA["columns"]
RMR_BEAMS = DATA["beams"]
RMR_REBAR = DATA["rebar"]
RMR_DUCTS = DATA["ducts"]
RMR_PIPES = DATA["pipes"]
RMR_ZONES = DATA["service_zones"]
RMR_LAYER_ZONES = DATA["service_layer_zones"]


def _rgb(key):
    return tuple(DATA["brand"][str(key).upper()])


def draw_mep_frame(sh):
    x, y, w, h = 20.0, 396.0, 286.0, 140.0
    ty = _panel(sh, x, y, w, h,
                "RMR_COLUMNS AND RMR_BEAMS  |  RMR-COLUMN / RMR-BEAM")

    # a 3 x 2 column grid at 6 m centres, drawn at 12 units per metre
    k = 12.0
    ox, oy = x + 14.0, y + 34.0
    marks = ["C1", "C2", "C3"]
    for ix in range(3):
        for iy in range(2):
            cx = ox + ix * 6.0 * k
            cy = oy + iy * 5.0 * k
            spec = RMR_COLUMNS[ix if iy == 0 else ix + 3]
            half_w = float(spec[1]) / 1000.0 * k / 2.0
            half_d = float(spec[2]) / 1000.0 * k / 2.0
            sh.solid((cx - half_w, cy - half_d), half_w * 2.0, half_d * 2.0,
                     "RMR-S-COLUMN", _rgb(spec[3]))
            sh.rect((cx - half_w, cy - half_d), half_w * 2.0, half_d * 2.0,
                    "RMR-S-COLUMN", INK)
            sh.line((cx - half_w * 2.0, cy), (cx + half_w * 2.0, cy),
                    "RMR-S-COLUMN", SLATE)
            sh.line((cx, cy - half_d * 2.0), (cx, cy + half_d * 2.0),
                    "RMR-S-COLUMN", SLATE)
            sh.circle((cx + 3.4, cy + 3.4), 2.4, "RMR-A-GRID", SLATE)
            sh.text((cx + 2.0, cy + 2.0), spec[0], 2.6, "RMR-NUMBER",
                    "RMR-A-GRID", INK)
            sh.text((cx - half_w, cy - half_d - 4.0),
                    "%s x %s" % (spec[1], spec[2]), 1.9, "RMR-MARK",
                    "RMR-A-TEXT", SLATE)

    # two beams spanning between the columns
    bx, by = x + 150.0, y + 74.0
    for i, spec in enumerate((RMR_BEAMS[1], RMR_BEAMS[3])):
        y0 = by - i * 26.0
        half = float(spec[1]) / 1000.0 * k / 2.0
        x0, x1 = bx, bx + 108.0
        sh.poly([(x0, y0 + half), (x1, y0 + half), (x1, y0 - half),
                 (x0, y0 - half)], [0.0] * 4, True, "RMR-S-BEAM", _rgb(spec[4]))
        sh.rect((x0, y0 - half), x1 - x0, half * 2.0, "RMR-S-BEAM", INK)
        sh.text((x0 + 2.0, y0 - half - 4.2),
                "%s  %s x %s  SPAN %.1f m" % (spec[0], spec[1], spec[2],
                                              float(spec[3]) / 1000.0),
                2.0, "RMR-LABEL", "RMR-A-TEXT", INK)
    sh.text((x + 14.0, ty - 4.0),
            "Sizes come from *RMR-COLUMN-SPECS* and *RMR-BEAM-SPECS*.",
            2.0, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((x + 14.0, ty - 8.4),
            "RMR-BEAM warns when a span passes the mark's limit.",
            2.0, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    return ty


def draw_mep_foundation(sh):
    x, y, w, h = 316.0, 396.0, 250.0, 140.0
    ty = _panel(sh, x, y, w, h,
                "FOUNDATIONS AND RMR_REBAR  |  RMR-FOUNDATION / RMR-RMR_REBAR")

    # three pads on a strip, drawn at 14 units per metre
    k = 14.0
    ox, oy = x + 14.0, y + 78.0
    half = 0.90 * k / 2.0
    for i in range(3):
        cx = ox + 24.0 + i * 3.0 * k
        sh.solid((cx - half, oy - half), half * 2.0, half * 2.0,
                 "RMR-S-FOUND", SLATE)
        sh.rect((cx - half, oy - half), half * 2.0, half * 2.0,
                "RMR-S-FOUND", INK)
        sh.rect((cx - half + 1.4, oy - half + 1.4), half * 2.0 - 2.8,
                half * 2.0 - 2.8, "RMR-S-HIDDEN", SLATE)
        sh.text((cx - half, oy - half - 4.2), "PAD 900 X 900 X 450 DP", 1.9,
                "RMR-NOTE", "RMR-A-TEXT", INK)
    sh.line((ox, oy), (ox + 24.0 + 2 * 3.0 * k + 14.0, oy),
            "RMR-S-HIDDEN", SLATE)
    sh.text((ox, oy + 3.0), "STRIP 900 WIDE X 450 DP", 1.9, "RMR-LABEL",
            "RMR-A-TEXT", INK)

    # three rebar runs with hooks and a bar mark
    ry = y + 34.0
    for i, spec in enumerate((RMR_REBAR[1], RMR_REBAR[3], RMR_REBAR[0])):
        yy = ry + (2 - i) * 9.0
        sh.line((x + 14.0, yy), (x + 210.0, yy), "RMR-S-RMR_REBAR", INK)
        sh.line((x + 14.0, yy), (x + 14.0, yy + 4.0), "RMR-S-RMR_REBAR", INK)
        sh.line((x + 210.0, yy), (x + 210.0, yy - 4.0), "RMR-S-RMR_REBAR", INK)
        sh.circle((x + 112.0 + i * 12.0, yy + 5.0), 2.4, "RMR-A-GRID", SLATE)
        sh.text((x + 110.4 + i * 12.0, yy + 3.4), spec[0], 2.4, "RMR-NUMBER",
                "RMR-A-GRID", INK)
        sh.text((x + 14.0, yy - 6.0), "%s @ %s" % (spec[1], spec[2]), 2.0,
                "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((x + 14.0, ty - 4.0),
            "Pads, strips and bars all label themselves as they are drawn.",
            2.0, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    return ty


def draw_mep_slab(sh):
    x, y, w, h = 576.0, 396.0, 240.0, 140.0
    ty = _panel(sh, x, y, w, h,
                "SLAB PANELS AND SETTING OUT  |  RMR-SLABPANEL / RMR-SETOUT")

    # a slab split into six panels on a 1200 module
    px, py, pw, ph = x + 14.0, y + 66.0, 200.0, 60.0
    sh.rect((px, py), pw, ph, "RMR-S-SLAB", INK)
    for i in range(1, 6):
        sh.line((px + i * pw / 6.0, py), (px + i * pw / 6.0, py + ph),
                "RMR-S-SLAB", SLATE)
    for i in range(6):
        sh.text((px + i * pw / 6.0 + 6.0, py + ph / 2.0 - 2.0),
                "P%02d" % (i + 1), 2.6, "RMR-NUMBER", "RMR-A-TEXT", INK)
    sh.text((px, py - 5.0), "6 PANELS  |  MODULE 1200 mm  |  200 mm THICK",
            2.0, "RMR-LABEL", "RMR-A-TEXT", TERRA)

    rows = [["P01", "1200", "6000", "200"], ["P02", "1200", "6000", "200"],
            ["P03", "1200", "6000", "200"]]
    _table(sh, x + 14.0, py - 12.0, ("PANEL", "LENGTH", "WIDTH", "THICK"),
           (34.0, 44.0, 44.0, 44.0), rows, text=2.0)
    sh.text((x + 14.0, y + 14.0),
            "RMR-SETOUT labels each point S1, S2 ... with its easting and",
            2.0, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((x + 14.0, y + 9.8),
            "northing, then writes a POINT,EASTING,NORTHING CSV.",
            2.0, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    return ty


def draw_mep_duct(sh):
    x, y, w, h = 20.0, 242.0, 250.0, 144.0
    ty = _panel(sh, x, y, w, h, "DUCTWORK  |  RMR-DUCT  |  *RMR-DUCT-SPECS*")

    # a duct run: two straight legs and a mitred corner
    ox, oy = x + 14.0, y + 96.0
    pts = [(ox, oy), (ox + 120.0, oy), (ox + 120.0, oy - 46.0)]
    k = 10.0
    for i, spec in enumerate((RMR_DUCTS[4], RMR_DUCTS[2], RMR_DUCTS[1])):
        half = float(spec[1]) / 1000.0 * k / 2.0
        yy = oy - i * 34.0
        leg = [(ox, yy), (ox + 96.0, yy), (ox + 96.0, yy - 20.0)]
        sh.poly([(p[0], p[1] + half) for p in leg] +
                [(p[0], p[1] - half) for p in reversed(leg)],
                [0.0] * 6, True, "RMR-E-DUCT", _rgb(spec[3]))
        sh.poly([(p[0], p[1] + half) for p in leg], [0.0] * 3, False,
                "RMR-E-DUCT", INK)
        sh.poly([(p[0], p[1] - half) for p in leg], [0.0] * 3, False,
                "RMR-E-DUCT", INK)
        sh.text((ox + 4.0, yy + half + 2.4),
                "%s  |  %.1f m" % (spec[0], 9.6 + i * 0.6), 2.0, "RMR-LABEL",
                "RMR-P-ANNO", TEAL)
    sh.text((x + 14.0, ty - 4.0),
            "Six sizes, mitred corners, a hatched body, a size label and a",
            2.0, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((x + 14.0, ty - 8.4),
            "flow arrow at the end of every run.",
            2.0, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    return ty


def draw_mep_pipe(sh):
    x, y, w, h = 280.0, 242.0, 250.0, 144.0
    ty = _panel(sh, x, y, w, h,
                "PIPEWORK AND CONTAINMENT  |  RMR-PIPE / RMR-TRAY")

    ox, oy = x + 14.0, y + 96.0
    k = 10.0
    for i, spec in enumerate((RMR_PIPES[5], RMR_PIPES[3], RMR_PIPES[1])):
        half = float(spec[1]) / 1000.0 * k / 2.0
        yy = oy - i * 24.0
        leg = [(ox, yy), (ox + 104.0, yy), (ox + 104.0, yy - 14.0)]
        sh.poly([(p[0], p[1] + half) for p in leg] +
                [(p[0], p[1] - half) for p in reversed(leg)],
                [0.0] * 6, True, "RMR-E-PIPE", _rgb(spec[2]))
        sh.poly([(p[0], p[1] + half) for p in leg], [0.0] * 3, False,
                "RMR-E-PIPE", INK)
        sh.poly([(p[0], p[1] - half) for p in leg], [0.0] * 3, False,
                "RMR-E-PIPE", INK)
        sh.text((ox + 4.0, yy + half + 2.2),
                "0%s mm  1:80 FALL  |  11.4 m" % spec[1], 2.0, "RMR-LABEL",
                "RMR-P-ANNO", BLUE)

    # a cable tray with rungs below the pipework
    ty0 = y + 26.0
    half = 0.30 * k / 2.0
    sh.line((ox, ty0 + half), (ox + 150.0, ty0 + half), "RMR-E-TRAY", GOLD)
    sh.line((ox, ty0 - half), (ox + 150.0, ty0 - half), "RMR-E-TRAY", GOLD)
    for i in range(11):
        rx = ox + 6.0 + i * 14.0
        sh.line((rx, ty0 - half), (rx, ty0 + half), "RMR-E-TRAY", GOLD)
    sh.text((ox + 2.0, ty0 + half + 2.4), "CABLE TRAY 300", 2.0, "RMR-LABEL",
            "RMR-P-ANNO", GOLD)
    sh.text((x + 14.0, y + 12.0),
            "Rungs are walked along every segment at the spacing you set.",
            2.0, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    return ty


def draw_mep_lighting(sh):
    x, y, w, h = 540.0, 242.0, 276.0, 144.0
    ty = _panel(sh, x, y, w, h, "LIGHTING  |  RMR-LIGHTING")

    ox, oy, pw, ph = x + 14.0, y + 58.0, 200.0, 62.0
    sh.rect((ox, oy), pw, ph, "RMR-E-LIGHT", SLATE)
    cols, rows = 5, 2
    index = 0
    for ix in range(cols):
        for iy in range(rows):
            index += 1
            cx = ox + (ix + 0.5) * pw / cols
            cy = oy + (iy + 0.5) * ph / rows
            sh.rect((cx - 3.0, cy - 3.0), 6.0, 6.0, "RMR-E-LIGHT", GOLD)
            sh.line((cx - 3.0, cy - 3.0), (cx + 3.0, cy + 3.0),
                    "RMR-E-LIGHT", GOLD)
            sh.text((cx + 4.4, cy - 1.6), "A%d" % index, 2.0, "RMR-NUMBER",
                    "RMR-P-ANNO", INK)
    sh.circle((ox - 6.0, oy - 6.0), 2.6, "RMR-E-POWER", GOLD)
    sh.line((ox - 6.0, oy - 6.0), (ox - 10.0, oy - 2.0), "RMR-E-POWER", GOLD)
    sh.text((ox - 12.0, oy - 12.0), "S/A", 2.0, "RMR-LABEL", "RMR-P-ANNO", INK)
    sh.text((ox, oy - 6.0),
            "10 LUMINAIRES  |  CIRCUIT A  |  0.18 kW  |  2400 x 2400 mm GRID",
            2.0, "RMR-LABEL", "RMR-A-TEXT", TERRA)
    sh.text((x + 14.0, ty - 4.0),
            "Pick two corners, give the spacing and the circuit letter,",
            2.0, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((x + 14.0, ty - 8.4),
            "and the grid, tags, switch and schedule draw themselves.",
            2.0, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    return ty


def draw_mep_sprinkler(sh):
    x, y, w, h = 20.0, 74.0, 286.0, 158.0
    ty = _panel(sh, x, y, w, h, "SPRINKLERS  |  RMR-SPRINKLER")

    ox, oy, pw, ph = x + 14.0, y + 74.0, 200.0, 62.0
    sh.rect((ox, oy), pw, ph, "RMR-E-SPRINK", SLATE)
    cols, rows = 4, 2
    index = 0
    for ix in range(cols):
        for iy in range(rows):
            index += 1
            cx = ox + (ix + 0.5) * pw / cols
            cy = oy + (iy + 0.5) * ph / rows
            sh.circle((cx, cy), 2100.0 / 1000.0 * 10.0, "RMR-E-SPRINK", SAND)
            sh.circle((cx, cy), 2.2, "RMR-E-SPRINK", TERRA)
            sh.line((cx - 3.4, cy), (cx + 3.4, cy), "RMR-E-SPRINK", TERRA)
            sh.line((cx, cy - 3.4), (cx, cy + 3.4), "RMR-E-SPRINK", TERRA)
            sh.text((cx + 4.0, cy - 1.6), "S%02d" % index, 1.8, "RMR-MARK",
                    "RMR-P-ANNO", SLATE)
    sh.text((ox, oy - 6.0),
            "8 HEADS  |  3000 mm GRID  |  2100 mm COVER  |  124.00 m2 PROTECTED",
            2.0, "RMR-LABEL", "RMR-A-TEXT", TERRA)
    sh.text((x + 14.0, y + 52.0),
            "Every head carries its coverage circle so the overlap is",
            2.0, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((x + 14.0, y + 47.8),
            "visible on the plan, not just in a calculation.",
            2.0, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((x + 14.0, y + 41.0),
            "RMR-SPRINKLER reports the protected area in m2 when it finishes.",
            2.0, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    return ty


def draw_mep_zones(sh):
    x, y, w, h = 316.0, 74.0, 240.0, 158.0
    ty = _panel(sh, x, y, w, h,
                "VERTICAL SERVICE RMR_ZONES  |  RMR-CLEARANCE")

    total = max(float(z[2]) for z in RMR_ZONES)
    ox, oy = x + 14.0, ty - 6.0
    wide, maxh = 118.0, 96.0
    yy = oy
    for zone in reversed(RMR_ZONES):
        bottom, top = float(zone[1]), float(zone[2])
        band = maxh * (top - bottom) / total
        sh.solid((ox, yy - band), wide, band, "RMR-M-FILL", _rgb(zone[3]))
        sh.rect((ox, yy - band), wide, band, "RMR-A-FRAME", SLATE)
        sh.text((ox + 3.0, yy - band * 0.45), zone[0], 2.2, "RMR-LABEL",
                "RMR-A-TEXT", INK)
        if band > 10.0:
            sh.text((ox + 3.0, yy - band * 0.85), zone[4][:34], 1.8,
                    "RMR-NOTE", "RMR-A-TEXT", SLATE)
        sh.text((ox + wide + 3.0, yy - band * 0.5),
                "%d - %d mm" % (bottom, top), 2.0, "RMR-NUMBER", "RMR-A-TEXT",
                INK)
        yy -= band
    sh.text((ox, yy - 6.0), "VERDICT: REVIEW  |  2 shared zones", 2.4,
            "RMR-HEAD", "RMR-A-TEXT", TERRA)
    sh.text((ox, yy - 13.0), "HVAC DUCT ZONE carries 2 services", 1.9,
            "RMR-BODY", "RMR-A-TEXT", TERRA)
    sh.text((ox, yy - 17.6), "CEILING ZONE carries 2 services", 1.9,
            "RMR-BODY", "RMR-A-TEXT", TERRA)
    return ty


def draw_mep_schedules(sh):
    x, y, w, h = 576.0, 74.0, 240.0, 158.0
    ty = _panel(sh, x, y, w, h,
                "SCHEDULES  |  RMR-STRUCTSCHED / RMR-MEPSCHED")
    sh.text((x + 14.0, ty - 4.0), "STRUCTURAL ELEMENT SCHEDULE", 2.2,
            "RMR-HEAD", "RMR-A-TEXT", TERRA)
    struct = (("RMR-S-COLUMN", "Columns and vertical structure", "18"),
              ("RMR-S-BEAM", "Beams and primary framing", "24"),
              ("RMR-S-SLAB", "Slabs and structural decks", "6"),
              ("RMR-S-FOUND", "Foundations and footings", "21"),
              ("RMR-S-RMR_REBAR", "Reinforcement and embeds", "34"),
              ("RMR-S-GRID", "Structural grids", "8"))
    cy = _table(sh, x + 14.0, ty - 10.0, ("LAYER", "DESCRIPTION", "COUNT"),
                (30.0, 30.0, 16.0),
                [[r[0][4:], r[1][:14], r[2]] for r in struct], text=1.9)
    sh.text((x + 14.0, cy - 6.0), "SERVICES SCHEDULE", 2.2, "RMR-HEAD",
            "RMR-A-TEXT", TERRA)
    mep = (("RMR-E-DUCT", "Ductwork", "12"), ("RMR-E-GRILLE", "Grilles", "16"),
           ("RMR-E-PIPE", "Pipework", "9"), ("RMR-E-POWER", "Small power", "22"),
           ("RMR-E-LIGHT", "Luminaires", "10"), ("RMR-E-TRAY", "Cable tray", "5"),
           ("RMR-E-DATA", "Data and comms", "7"),
           ("RMR-E-SPRINK", "Sprinklers", "8"))
    _table(sh, x + 14.0, cy - 12.0, ("LAYER", "DESCRIPTION", "COUNT"),
           (30.0, 30.0, 16.0),
           [[r[0][4:], r[1][:14], r[2]] for r in mep], text=1.9)
    return ty


def build_structural_mep():
    global SHEET_TITLE, SHEET_SUBTITLE, SHEET_NOTE
    SHEET_TITLE = "STRUCTURAL AND MEP COORDINATION SHEET"
    SHEET_SUBTITLE = ("RMR_COLUMNS, RMR_BEAMS, FOUNDATIONS, RMR_REBAR, SLAB PANELS, SETTING OUT AND "
                      "DUCTWORK")
    SHEET_NOTE = ("The 11.0 suite: the structure that holds the building up and the services "
                  "that run through it.")
    doc = build_document()
    sh = Sheet(doc)
    draw_frame(sh)
    draw_header(sh)
    draw_mep_frame(sh)
    draw_mep_foundation(sh)
    draw_mep_slab(sh)
    draw_mep_duct(sh)
    draw_mep_pipe(sh)
    draw_mep_lighting(sh)
    draw_mep_sprinkler(sh)
    draw_mep_zones(sh)
    draw_mep_schedules(sh)
    draw_title_block(sh)
    return doc


# --------------------------------------------------------------------------- #
# 12.0 CONSTRUCTION DETAILING SHEET PANELS
# --------------------------------------------------------------------------- #
DETAILS = DATA["details"]
JUNCTIONS = DATA["junctions"]
MATERIALS = DATA["materials"]
FIRE = DATA["fire"]
ACOUSTIC = DATA["acoustic"]
BUILDUP = DATA["buildups"]


def _detrgb(key):
    return tuple(DATA["brand"][str(key).upper()])


def _buildup_rows(wanted):
    return [r for r in BUILDUP if str(r[0]).upper() == str(wanted).upper()]


def draw_det_library(sh):
    x, y, w, h = 20.0, 396.0, 286.0, 140.0
    ty = _panel(sh, x, y, w, h,
                "DETAIL LIBRARY  |  RMR-DETAILLIB  |  *RMR-DETAIL-SPECS*")

    # six captioned frames in three columns, exactly as the command lays them
    cols = 3
    fw, fh = 80.0, 42.0
    gx, gy, bar = 8.0, 9.0, 8.0
    ox, oy = x + 12.0, ty - 6.0
    for i, spec in enumerate(DETAILS[:6]):
        col, row = i % cols, i // cols
        px = ox + col * (fw + gx)
        py = oy - row * (fh + gy + bar)
        sh.solid((px, py - fh), fw, bar, "RMR-PRES-TITLE", TERRA)
        sh.rect((px, py - fh), fw, bar, "RMR-A-FRAME", INK)
        sh.rect((px, py - fh + bar), fw, fh, "RMR-A-DETAIL", SLATE)
        sh.text((px + 2.0, py - fh + 2.4), spec[0], 2.6, "RMR-NUMBER",
                "RMR-PRES-TITLE", SAND)
        sh.text((px + 2.0, py - fh + bar + fh * 0.55),
                spec[1].split(",")[0][:14], 1.9, "RMR-NOTE", "RMR-A-TEXT", SLATE)
        sh.text((px + fw - 14.0, py - fh + 2.4), spec[2], 2.0, "RMR-NUMBER",
                "RMR-PRES-TITLE", SAND)
    sh.text((x + 12.0, y + 12.0),
            "12 details across 5 categories  |  frames are drawn with a",
            2.0, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((x + 12.0, y + 7.8),
            "placeholder cross ready for the detail geometry.",
            2.0, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    return ty


def draw_det_junction(sh):
    x, y, w, h = 316.0, 396.0, 250.0, 140.0
    ty = _panel(sh, x, y, w, h,
                "PARAMETRIC JUNCTION  |  RMR-JUNCTION")

    # an eaves junction: the roof leg horizontal, the external wall leg vertical
    lega = _buildup_rows("ROOF") or _buildup_rows("FLOOR")
    legb = _buildup_rows("EXTWALL")
    k = 0.16                       # drawing units per mm at detail scale
    cx, cy = x + 78.0, y + 104.0
    leglen = 72.0

    yy = cy
    for spec in lega:
        thk = float(spec[3]) * k
        rgb = tuple(int(v) for v in spec[4])
        sh.solid((cx - leglen, yy - thk), leglen, thk, "RMR-M-HATCH", rgb)
        sh.rect((cx - leglen, yy - thk), leglen, thk, "RMR-A-DETAIL", INK)
        yy -= thk
    xx = cx
    for spec in legb:
        thk = float(spec[3]) * k
        rgb = tuple(int(v) for v in spec[4])
        sh.solid((xx, cy - leglen), thk, leglen, "RMR-M-HATCH", rgb)
        sh.rect((xx, cy - leglen), thk, leglen, "RMR-A-DETAIL", INK)
        xx += thk

    # both legs are listed beside the drawing, so thin layers stay readable
    sh.text((x + 140.0, cy + 3.0), "ROOF LEG", 2.0, "RMR-HEAD", "RMR-A-TEXT",
            TERRA)
    ly = cy - 4.0
    for spec in lega:
        sh.text((x + 140.0, ly), "%s  %d mm" % (spec[2][:16], int(spec[3])),
                1.9, "RMR-BODY", "RMR-A-TEXT", INK)
        ly -= 5.6
    sh.text((x + 140.0, ly - 3.0), "EXTERNAL WALL LEG", 2.0, "RMR-HEAD",
            "RMR-A-TEXT", TERRA)
    ly -= 10.0
    for spec in legb:
        sh.text((x + 140.0, ly), "%s  %d mm" % (spec[2][:16], int(spec[3])),
                1.9, "RMR-BODY", "RMR-A-TEXT", INK)
        ly -= 5.6

    ta = sum(float(s[3]) for s in lega)
    tb = sum(float(s[3]) for s in legb)
    sh.text((x + 12.0, y + 26.0), "EAVES  |  roof meeting the external wall",
            2.1, "RMR-LABEL", "RMR-A-TEXT", TERRA)
    sh.text((x + 12.0, y + 21.0),
            "ROOF %d mm total  |  EXTWALL %d mm total" % (ta, tb), 1.9,
            "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((x + 12.0, y + 15.4),
            "Both legs are read from *RMR-BUILDUP-SPECS*, hatched in",
            1.9, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((x + 12.0, y + 11.2), "their own colour and listed with thickness.",
            1.9, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    return ty


def draw_det_tags(sh):
    x, y, w, h = 576.0, 396.0, 240.0, 140.0
    ty = _panel(sh, x, y, w, h, "DETAIL TAGS AND LOCATOR  |  RMR-DETAILTAG / RMR-DETLOC")

    # a locator plan with the detail position ringed
    px, py, pw, ph = x + 12.0, y + 74.0, 96.0, 62.0
    sh.rect((px, py), pw, ph, "RMR-A-DETAIL", SLATE)
    for i in (1, 2):
        sh.line((px + i * pw / 3.0, py), (px + i * pw / 3.0, py + ph),
                "RMR-00-REF", SAND)
        sh.line((px, py + i * ph / 3.0), (px + pw, py + i * ph / 3.0),
                "RMR-00-REF", SAND)
    lx, ly = px + pw * 0.68, py + ph * 0.62
    sh.circle((lx, ly), 4.4, "RMR-A-DETAIL", GOLD)
    sh.line((lx + 3.0, ly + 3.0), (lx + 11.0, ly + 11.0), "RMR-A-DETAIL", GOLD)
    sh.line((lx + 11.0, ly + 11.0), (lx + 34.0, ly + 11.0), "RMR-A-DETAIL", GOLD)
    sh.text((lx + 35.0, ly + 9.0), "D01 LOCATED HERE", 1.9, "RMR-LABEL",
            "RMR-A-TEXT", GOLD)
    sh.text((px, py - 5.0), "LOCATOR PLAN  |  DETAIL D01", 2.0, "RMR-HEAD",
            "RMR-A-TEXT", TERRA)

    # two detail bubbles on leaders
    for i, (bx, by, num) in enumerate(((x + 40.0, y + 52.0, "D01"),
                                       (x + 118.0, y + 52.0, "D02"))):
        sh.line((bx - 30.0, by + 26.0), (bx, by), "RMR-A-DETAIL", TERRA)
        sh.circle((bx - 30.0, by + 26.0), 1.4, "RMR-A-DETAIL", TERRA)
        sh.circle((bx, by), 5.2, "RMR-PRES-KEY", TERRA)
        sh.text((bx - 2.4, by - 2.0), num, 4.4, "RMR-NUMBER", "RMR-A-DETAIL", INK)
        sh.text((bx + 1.6, by - 11.0), "SEE SHEET A-500", 1.8, "RMR-NOTE",
                "RMR-A-TEXT", SLATE)
    sh.text((x + 12.0, y + 12.0),
            "The counter runs on: D01, D02 ... or pick a number from",
            2.0, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((x + 12.0, y + 7.8), "the library and the title follows it.",
            2.0, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    return ty


def draw_det_dims(sh):
    x, y, w, h = 20.0, 242.0, 250.0, 144.0
    ty = _panel(sh, x, y, w, h, "DIMENSION CHAIN AND SCALE BAR  |  RMR-DIMCHAIN / RMR-DETSCALE")

    # a chain of four measured points
    pts = [(x + 16.0, y + 116.0), (x + 66.0, y + 116.0),
           (x + 66.0, y + 92.0), (x + 136.0, y + 92.0)]
    sh.poly(pts, [0.0] * len(pts), False, "RMR-A-DETAIL", INK)
    off = 12.0
    for i in range(len(pts) - 1):
        p1, p2 = pts[i], pts[i + 1]
        dx, dy = p2[0] - p1[0], p2[1] - p1[1]
        length = (dx * dx + dy * dy) ** 0.5
        nx, ny = -dy / length, dx / length
        sh.line((p1[0] + nx * off, p1[1] + ny * off),
                (p2[0] + nx * off, p2[1] + ny * off), "RMR-A-DIMS", INK)
        sh.text(((p1[0] + p2[0]) / 2.0 + nx * (off + 5.0),
                 (p1[1] + p2[1]) / 2.0 + ny * (off + 5.0)),
                "%d" % round(length), 2.0, "RMR-NUMBER", "RMR-A-DIMS", INK)
    for p in pts:
        sh.line((p[0], p[1]), (p[0] - 0.0, p[1] - 9.0), "RMR-A-DIMS", INK)
    sh.text((x + 16.0, y + 74.0), "3 DIMENSIONS  |  CHAIN 120", 2.0, "RMR-LABEL",
            "RMR-A-TEXT", TERRA)

    # a metric scale bar: four segments at 100 mm each
    bx, by, unit, bar = x + 16.0, y + 56.0, 26.0, 8.0
    for i in range(4):
        sh.solid((bx + i * unit, by), unit, bar, "RMR-A-DIMS",
                 INK if i % 2 == 0 else SAND)
    sh.rect((bx, by), unit * 4, bar, "RMR-A-FRAME", INK)
    sh.text((bx, by - 5.0), "0", 2.0, "RMR-NUMBER", "RMR-A-TEXT", INK)
    sh.text((bx + unit * 4 - 8.0, by - 5.0), "400 mm", 2.0, "RMR-NUMBER",
            "RMR-A-TEXT", INK)
    sh.text((bx, by + bar + 3.0), "SCALE 1:5 AT A1", 2.2, "RMR-HEAD",
            "RMR-A-TEXT", TERRA)
    sh.text((x + 16.0, y + 26.0),
            "RMR-DETSCALE sets the scale, then steps the bar in 100 mm",
            1.9, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((x + 16.0, y + 21.8),
            "increments at 1:20 and finer, 500 mm above it.",
            1.9, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    return ty


def draw_det_matkey(sh):
    x, y, w, h = 280.0, 242.0, 250.0, 144.0
    ty = _panel(sh, x, y, w, h, "MATERIALS KEY  |  RMR-MATKEY")

    rows = _buildup_rows("EXTWALL")
    yy = ty - 6.0
    sh.text((x + 12.0, yy), "MATERIALS KEY  |  EXTWALL", 2.6, "RMR-HEAD",
            "RMR-A-TEXT", TERRA)
    yy -= 9.0
    for spec in rows:
        rgb = tuple(int(v) for v in spec[4])
        sh.solid((x + 12.0, yy - 4.2), 4.6, 4.6, "RMR-M-HATCH", rgb)
        sh.rect((x + 12.0, yy - 4.2), 4.6, 4.6, "RMR-A-FRAME", INK)
        sh.text((x + 20.0, yy), spec[2][:24], 2.0, "RMR-LABEL", "RMR-A-TEXT", INK)
        sh.text((x + 132.0, yy), "%d mm" % int(spec[3]), 2.0, "RMR-NUMBER",
                "RMR-A-TEXT", TERRA)
        yy -= 7.4
    sh.text((x + 12.0, yy - 3.0),
            "%d materials  |  pattern %s upward" % (len(rows), rows[0][5]),
            2.0, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((x + 12.0, yy - 8.4),
            "The key is read from the same build-up table the junction",
            1.9, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((x + 12.0, yy - 12.6), "builder draws from, so they cannot disagree.",
            1.9, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    return ty


def draw_det_uvalue(sh):
    x, y, w, h = 540.0, 242.0, 276.0, 144.0
    ty = _panel(sh, x, y, w, h, "THERMAL PERFORMANCE  |  RMR-UVALUE")

    # brick, blockwork, PIR 100, plasterboard
    stack = [MATERIALS[0], MATERIALS[1], MATERIALS[2], MATERIALS[4]]
    stack[2] = [MATERIALS[2][0], MATERIALS[2][1], 100, MATERIALS[2][3]]
    r_total = sum((float(m[2]) / 1000.0) / float(m[1]) for m in stack)
    u = 1.0 / (0.17 + r_total)

    sh.text((x + 12.0, ty - 5.0), "THERMAL PERFORMANCE  |  RMR-UVALUE", 2.8,
            "RMR-HEAD", "RMR-A-TEXT", TERRA)
    yy = ty - 14.0
    for m in stack:
        r = (float(m[2]) / 1000.0) / float(m[1])
        sh.solid((x + 12.0, yy - 5.0), 108.0, 5.4, "RMR-M-FILL", SAND)
        sh.rect((x + 12.0, yy - 5.0), 108.0, 5.4, "RMR-A-FRAME", SLATE)
        sh.text((x + 14.0, yy), m[0][:18], 2.0, "RMR-LABEL", "RMR-A-TEXT", INK)
        sh.text((x + 126.0, yy), "%d" % int(float(m[2])), 1.9, "RMR-NUMBER",
                "RMR-A-TEXT", INK)
        sh.text((x + 150.0, yy), "R %.3f" % r, 1.9, "RMR-BODY", "RMR-A-TEXT", TEAL)
        yy -= 7.6
    sh.text((x + 12.0, yy - 2.0),
            "TOTAL %d mm  |  R %.3f m2K/W"
            % (sum(int(float(m[2])) for m in stack), r_total), 2.2,
            "RMR-NUMBER", "RMR-A-TEXT", TERRA)
    sh.text((x + 12.0, yy - 13.0), "U = %.3f W/m2K" % u, 7.0, "RMR-NUMBER",
            "RMR-A-TEXT", TEAL)
    sh.text((x + 12.0, yy - 19.0), "Includes Rsi 0.13 and Rse 0.04", 1.9,
            "RMR-NOTE", "RMR-A-TEXT", SLATE)
    return ty


def draw_det_fire(sh):
    x, y, w, h = 20.0, 74.0, 286.0, 158.0
    ty = _panel(sh, x, y, w, h, "FIRE AND ACOUSTIC  |  RMR-FIRESTOP / RMR-ACOUSTIC")

    # a compartment line with two labelled segments
    pts = [(x + 16.0, y + 128.0), (x + 130.0, y + 128.0),
           (x + 130.0, y + 96.0)]
    sh.poly([(p[0], p[1] + 2.4) for p in pts] +
            [(p[0], p[1] - 2.4) for p in reversed(pts)],
            [0.0] * 6, True, "RMR-A-FIRE", _detrgb("TERRA"))
    sh.text((x + 20.0, y + 134.0), "FD60  One hour fire resisting", 2.0,
            "RMR-LABEL", "RMR-A-FIRE", INK)

    # an acoustic partition with its rating bubble
    ax, ay = x + 170.0, y + 112.0
    sh.line((ax, ay), (ax + 90.0, ay), "RMR-A-ACOUSTIC", BLUE)
    sh.circle((ax + 45.0, ay), 6.0, "RMR-A-ACOUSTIC", BLUE)
    sh.text((ax + 39.0, ay - 2.0), "Rw 48", 2.6, "RMR-NUMBER", "RMR-A-ACOUSTIC",
            INK)
    sh.text((ax, ay - 10.0), "Party wall, dwelling to dwelling", 1.9, "RMR-NOTE",
            "RMR-A-ACOUSTIC", SLATE)

    rows = [[f[0], "%s min" % f[1], f[3][:26]] for f in FIRE]
    cy = _table(sh, x + 16.0, y + 86.0, ("RATING", "MINUTES", "APPLICATION"),
                (34.0, 34.0, 84.0), rows, text=1.9)
    sh.text((x + 16.0, cy - 5.0),
            "RMR-FIRESTOP draws the band and labels every segment;",
            1.9, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    sh.text((x + 16.0, cy - 9.2),
            "RMR-ACOUSTIC marks the partition and can draw the table.",
            1.9, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    return ty


def draw_det_speclink(sh):
    x, y, w, h = 316.0, 74.0, 240.0, 158.0
    ty = _panel(sh, x, y, w, h, "SPECIFICATION LINK AND INDEX  |  RMR-SPECLINK / RMR-DETINDEX")

    sh.solid((x + 12.0, y + 138.0), 216.0, 9.0, "RMR-PRES-TITLE", TEAL)
    sh.text((x + 14.0, y + 141.0), "DETAIL D01  |  REFER TO SPECIFICATION", 2.2,
            "RMR-HEAD", "RMR-PRES-TITLE", SAND)
    yy = y + 128.0
    for clause in DATA["specs"][:3]:
        sh.text((x + 12.0, yy), "%s  %s" % (clause[0], clause[2][:26]), 2.0,
                "RMR-LABEL", "RMR-A-TEXT", TERRA)
        sh.text((x + 12.0, yy - 4.4), clause[3][:56], 1.8, "RMR-BODY",
                "RMR-A-TEXT", INK)
        yy -= 12.0

    idx = [[d[0], d[1][:24], d[2], d[3]] for d in DETAILS[:6]]
    _table(sh, x + 12.0, y + 84.0, ("NO", "TITLE", "SCALE", "CATEGORY"),
           (16.0, 96.0, 24.0, 40.0), idx, text=1.8)
    return ty


def draw_det_sheet(sh):
    x, y, w, h = 576.0, 74.0, 240.0, 158.0
    ty = _panel(sh, x, y, w, h, "DETAIL SHEET AND CHECK  |  RMR-DETSHEET / RMR-CHECKDETAIL")

    # the compliance verdict first, then an A1 sheet in miniature below it
    sh.solid((x + 12.0, y + 8.0), 216.0, 8.0, "RMR-PRES-TITLE", TEAL)
    sh.text((x + 14.0, y + 10.0), "RMR-CHECKDETAIL  VERDICT: PASS", 2.4,
            "RMR-HEAD", "RMR-PRES-TITLE", SAND)
    sh.text((x + 12.0, y + 22.0), "12 detail markers on RMR-A-DETAIL", 1.9,
            "RMR-BODY", "RMR-A-TEXT", INK)
    sh.text((x + 12.0, y + 17.4), "12 details in the library, all tagged", 1.9,
            "RMR-BODY", "RMR-A-TEXT", INK)
    sh.text((x + 12.0, y + 12.8), "RMR-TITLEBLOCK present", 1.9, "RMR-BODY",
            "RMR-A-TEXT", INK)

    k = 0.155
    sw, sh_h = 841.0 * k, 594.0 * k
    sx, sy = x + 14.0, y + 52.0
    sh.rect((sx, sy), sw, sh_h, "RMR-A-FRAME", INK)
    sh.rect((sx + 1.6, sy + 1.6), sw - 3.2, sh_h - 3.2, "RMR-A-FRAME", TEAL)
    sh.solid((sx + 1.6, sy + sh_h - 10.4), sw - 3.2, 8.0, "RMR-PRES-TITLE",
             TERRA)
    sh.text((sx + 3.0, sy + sh_h - 8.2), "CONSTRUCTION DETAILS", 1.9,
            "RMR-TITLE", "RMR-PRES-TITLE", SAND)
    fw, fh = 38.0, 22.0
    for i in range(6):
        col, row = i % 3, i // 3
        fx = sx + 4.0 + col * (fw + 2.0)
        fy = sy + sh_h - 14.0 - (row + 1) * (fh + 5.0)
        sh.rect((fx, fy), fw, fh, "RMR-A-DETAIL", SLATE)
        sh.solid((fx, fy), fw, 4.0, "RMR-PRES-TITLE", TERRA)
        sh.text((fx + 1.2, fy + 0.6), DETAILS[i][0], 1.8, "RMR-NUMBER",
                "RMR-PRES-TITLE", SAND)
    sh.text((x + 12.0, y + 44.0), "RMR-DETSHEET  |  A1 detail sheet in one command",
            1.9, "RMR-NOTE", "RMR-A-TEXT", SLATE)
    return ty


def build_detailing():
    global SHEET_TITLE, SHEET_SUBTITLE, SHEET_NOTE
    SHEET_TITLE = "CONSTRUCTION DETAILING SHEET"
    SHEET_SUBTITLE = ("DETAIL LIBRARY, PARAMETRIC JUNCTIONS, TAGS, DIMENSION CHAINS, "
                      "MATERIALS KEY")
    SHEET_NOTE = ("The 12.0 suite: every junction, tag, key and number a detail sheet "
                  "needs, drawn from one set of tables.")
    doc = build_document()
    sh = Sheet(doc)
    draw_frame(sh)
    draw_header(sh)
    draw_det_library(sh)
    draw_det_junction(sh)
    draw_det_tags(sh)
    draw_det_dims(sh)
    draw_det_matkey(sh)
    draw_det_uvalue(sh)
    draw_det_fire(sh)
    draw_det_speclink(sh)
    draw_det_sheet(sh)
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
    dlv = build_delivery()
    dlv_path = os.path.join(OUT_DIR, "RooMNRooF_PRO_Delivery_Suite.dxf")
    dlv.saveas(dlv_path)
    print("DXF  :", dlv_path, os.path.getsize(dlv_path), "bytes")
    try:
        print("PNG  :", render_png(dlv, os.path.join(OUT_DIR, "RooMNRooF_PRO_Delivery_Suite.png"),
                                   dpi=150))
    except Exception as exc:
        print("Delivery PNG render skipped:", exc)
    print("walls: %d | finishes: %d | sheets: %d"
          % (len(DATA["walls"]), len(DATA["finishes"]), len(DATA["sheets"])))
    site = build_site()
    site_path = os.path.join(OUT_DIR, "RooMNRooF_PRO_Site_Services_Suite.dxf")
    site.saveas(site_path)
    print("DXF  :", site_path, os.path.getsize(site_path), "bytes")
    try:
        print("PNG  :", render_png(site, os.path.join(OUT_DIR, "RooMNRooF_PRO_Site_Services_Suite.png"),
                                   dpi=150))
    except Exception as exc:
        print("Site PNG render skipped:", exc)
    print("levels: %d | keynotes: %d | cities: %d"
          % (len(DATA["levels"]), len(DATA["keynotes"]), len(DATA["cities"])))
    coord = build_coordination()
    coord_path = os.path.join(OUT_DIR, "RooMNRooF_PRO_Coordination_Suite.dxf")
    coord.saveas(coord_path)
    print("DXF  :", coord_path, os.path.getsize(coord_path), "bytes")
    try:
        print("PNG  :", render_png(coord, os.path.join(OUT_DIR, "RooMNRooF_PRO_Coordination_Suite.png"),
                                   dpi=150))
    except Exception as exc:
        print("Coordination PNG render skipped:", exc)
    print("zone bands: %d" % len(DATA["zones"]))
    documentation = build_documentation()
    doc_path = os.path.join(OUT_DIR, "RooMNRooF_PRO_Documentation_Suite.dxf")
    documentation.saveas(doc_path)
    print("DXF  :", doc_path, os.path.getsize(doc_path), "bytes")
    try:
        print("PNG  :", render_png(documentation, os.path.join(
            OUT_DIR, "RooMNRooF_PRO_Documentation_Suite.png"), dpi=150))
    except Exception as exc:
        print("Documentation PNG render skipped:", exc)
    print("clauses: %d | abbrevs: %d | revisions: %d | checklist: %d"
          % (len(DATA["specs"]), len(DATA["abbrevs"]),
             len(DATA["revisions"]), len(DATA["checklist"])))
    presentation = build_presentation()
    pres_path = os.path.join(OUT_DIR, "RooMNRooF_PRO_Presentation_Suite.dxf")
    presentation.saveas(pres_path)
    print("DXF  :", pres_path, os.path.getsize(pres_path), "bytes")
    try:
        print("PNG  :", render_png(presentation, os.path.join(
            OUT_DIR, "RooMNRooF_PRO_Presentation_Suite.png"), dpi=150))
    except Exception as exc:
        print("Presentation PNG render skipped:", exc)
    print("buildups: %d | programme: %d | mood slots: %d"
          % (len(DATA["buildups"]), len(DATA["programme"]), len(DATA["mood"])))

    quantity = build_quantity()
    qty_path = os.path.join(OUT_DIR, "RooMNRooF_PRO_Quantity_Suite.dxf")
    quantity.saveas(qty_path)
    print("DXF  :", qty_path, os.path.getsize(qty_path), "bytes")
    try:
        print("PNG  :", render_png(quantity, os.path.join(
            OUT_DIR, "RooMNRooF_PRO_Quantity_Suite.png"), dpi=150))
    except Exception as exc:
        print("Quantity PNG render skipped:", exc)
    print("rates: %d | elements: %d | automation steps: %d | takeoff: %d"
          % (len(DATA["rates"]), len(DATA["elements"]), len(DATA["auto"]),
             len(TAKEOFF)))
    mep = build_structural_mep()
    mep_path = os.path.join(OUT_DIR, "RooMNRooF_PRO_Structural_MEP_Suite.dxf")
    mep.saveas(mep_path)
    print("DXF  :", mep_path, os.path.getsize(mep_path), "bytes")
    try:
        print("PNG  :", render_png(mep, os.path.join(
            OUT_DIR, "RooMNRooF_PRO_Structural_MEP_Suite.png"), dpi=150))
    except Exception as exc:
        print("Structural MEP PNG render skipped:", exc)
    print("columns: %d | beams: %d | rebar: %d | ducts: %d | pipes: %d | zones: %d"
          % (len(DATA["columns"]), len(DATA["beams"]), len(DATA["rebar"]),
             len(DATA["ducts"]), len(DATA["pipes"]),
             len(DATA["service_zones"])))

    detailing = build_detailing()
    det_path = os.path.join(OUT_DIR, "RooMNRooF_PRO_Detailing_Suite.dxf")
    detailing.saveas(det_path)
    print("DXF  :", det_path, os.path.getsize(det_path), "bytes")
    try:
        print("PNG  :", render_png(detailing, os.path.join(
            OUT_DIR, "RooMNRooF_PRO_Detailing_Suite.png"), dpi=150))
    except Exception as exc:
        print("Detailing PNG render skipped:", exc)
    print("details: %d | junctions: %d | materials: %d | fire: %d | acoustic: %d"
          % (len(DATA["details"]), len(DATA["junctions"]), len(DATA["materials"]),
             len(DATA["fire"]), len(DATA["acoustic"])))
    return 0


if __name__ == "__main__":
    sys.exit(main())
