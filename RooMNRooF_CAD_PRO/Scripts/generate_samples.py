#!/usr/bin/env python3
"""
Generate the sample 3-storey residential project as DXF drawings (Samples/SampleProject/*.dxf)
plus PNG previews (Samples/SampleProject/previews/*.png) rendered by ezdxf+matplotlib.

All dimensions are in mm; drawings are drawn 1:1 in model space and annotated for 1:100 plotting.
Member sizes / reinforcement shown are SAMPLE PLACEHOLDER VALUES for drafting demonstration only —
they are not a structural design.

Usage:  python Scripts/generate_samples.py [--no-png]
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rnr_dxf import ROOT, Pen, new_doc  # noqa: E402

OUT = os.path.join(ROOT, "Samples", "SampleProject")
PREV = os.path.join(OUT, "previews")

GX = [0, 4500, 8500, 13000]           # grid A..D  (x)
GY = [0, 4200, 7700, 11500]           # grid 1..4  (y)
XL = ["A", "B", "C", "D"]
YL = ["1", "2", "3", "4"]
COL = (300, 450)
FLOOR_H = 3000
LEVELS = [("PLINTH", 0), ("GF", 450), ("FF", 3450), ("SF", 6450), ("ROOF", 9450), ("PARAPET", 10450)]
S = 100.0


def grid(p, ext=1500, dims=True):
    x0, x1, y0, y1 = GX[0] - ext, GX[-1] + ext, GY[0] - ext, GY[-1] + ext
    r = 5 * S
    for x, lab in zip(GX, XL):
        p.line((x, y0), (x, y1), "S-GRID")
        p.bubble((x, y1 + r), lab)
        p.bubble((x, y0 - r), lab)
    for y, lab in zip(GY, YL):
        p.line((x0, y), (x1, y), "S-GRID")
        p.bubble((x0 - r, y), lab)
        p.bubble((x1 + r, y), lab)
    if dims:
        for i in range(len(GX) - 1):
            p.dim((GX[i], y1), (GX[i + 1], y1), 0, "ANNO-DIMS", angle=0)
        p.dim((GX[0], y1), (GX[-1], y1), 700, "ANNO-DIMS", angle=0)
        for i in range(len(GY) - 1):
            p.dim((x0, GY[i]), (x0, GY[i + 1]), 0, "ANNO-DIMS", angle=90)
        p.dim((x0, GY[0]), (x0, GY[-1]), -700, "ANNO-DIMS", angle=90)


def columns(p, label=True, hatch=True):
    marks = {}
    for i, x in enumerate(GX):
        for j, y in enumerate(GY):
            corner = i in (0, 3) and j in (0, 3)
            mark = "C1" if corner else ("C2" if (i in (0, 3) or j in (0, 3)) else "C3")
            marks[(i, j)] = mark
            w, h = COL
            pts = [(x - w / 2, y - h / 2), (x + w / 2, y - h / 2), (x + w / 2, y + h / 2), (x - w / 2, y + h / 2)]
            p.poly(pts, "S-COL")
            if hatch:
                p.hatch(pts, "RCC", "S-HATCH", 0.5)
            if label:
                p.text(mark, (x + 350, y + 350), 2.5, "S-COL-TEXT", align="LEFT")
    return marks


def north(p, c):
    r = 8 * S
    p.circle(c, r, "ANNO-NORTH")
    p.poly([(c[0], c[1] + r), (c[0] - r * 0.4, c[1] - r * 0.6), (c[0], c[1] - r * 0.2),
            (c[0] + r * 0.4, c[1] - r * 0.6)], "ANNO-NORTH")
    p.text("N", (c[0], c[1] + r * 1.4), 4, "ANNO-NORTH")


def title(p, x, y, text, scale="1:100"):
    p.text(text, (x, y), 5, "ANNO-TEXT", align="LEFT", style="RNR_HEADING")
    p.line((x, y - 250), (x + len(text) * 420, y - 250), "ANNO-TEXT", lineweight=50)
    p.text(f"SCALE {scale}", (x, y - 800), 2.5, "ANNO-TEXT", align="LEFT")


def sheet(name, sheet_title, dwgno, discipline, size="A3"):
    doc = new_doc()
    p = Pen(doc, scale=S)
    # sheet frame positioned so the building sits in the drawing area
    area = p.title_block(-10000, -10000, size, sheet_title, dwgno, "1:100", discipline)
    return doc, p, area


def save(doc, name, previews):
    path = os.path.join(OUT, name + ".dxf")
    doc.saveas(path)
    if previews:
        render(doc, os.path.join(PREV, name + ".png"))
    return path


def render(doc, png):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    from ezdxf.addons.drawing import Frontend, RenderContext
    from ezdxf.addons.drawing.config import BackgroundPolicy, Configuration
    from ezdxf.addons.drawing.matplotlib import MatplotlibBackend
    fig = plt.figure(figsize=(16.54, 11.69))
    ax = fig.add_axes([0, 0, 1, 1])
    cfg = Configuration(background_policy=BackgroundPolicy.WHITE)
    Frontend(RenderContext(doc), MatplotlibBackend(ax), config=cfg).draw_layout(doc.modelspace(), finalize=True)
    fig.savefig(png, dpi=110)
    plt.close(fig)


# --------------------------------------------------------------------------------------------
# Architecture
# --------------------------------------------------------------------------------------------
WALL_EXT, WALL_INT = 250, 125


def wall_rect(p, x0, y0, x1, y1, t, hatch=True):
    """Double-line wall between two points (axis-aligned), centered on the axis."""
    if abs(y1 - y0) < 1e-6:
        pts = [(x0, y0 - t / 2), (x1, y0 - t / 2), (x1, y0 + t / 2), (x0, y0 + t / 2)]
    else:
        pts = [(x0 - t / 2, y0), (x0 + t / 2, y0), (x0 + t / 2, y1), (x0 - t / 2, y1)]
    p.poly(pts, "A-WALL")
    if hatch:
        p.hatch(pts, "Brick", "A-HATCH", 0.4)


def door(p, x, y, w, horizontal=True, flip=1):
    """Door opening marker on a wall axis at (x,y): leaf + swing arc."""
    if horizontal:
        p.line((x, y), (x, y + flip * w), "A-DOOR")
        p.arc((x, y), w, 0 if flip > 0 else 270, 90 if flip > 0 else 360, "A-DOOR")
    else:
        p.line((x, y), (x + flip * w, y), "A-DOOR")
        p.arc((x, y), w, 0 if flip > 0 else 180, 90 if flip > 0 else 270, "A-DOOR")


def window(p, x0, y0, x1, y1, t=WALL_EXT):
    if abs(y1 - y0) < 1e-6:
        for d in (-t / 2, -t / 6, t / 6, t / 2):
            p.line((x0, y0 + d), (x1, y0 + d), "A-WINDOW")
    else:
        for d in (-t / 2, -t / 6, t / 6, t / 2):
            p.line((x0 + d, y0), (x0 + d, y1), "A-WINDOW")


def room_tag(p, name, x, y, w, h):
    area = w * h / 1e6
    p.text(name, (x, y + 180), 3, "A-ROOM", style="RNR_HEADING")
    p.text(f"{w / 1000:.2f} x {h / 1000:.2f} m  ({area:.1f} m2)", (x, y - 250), 2, "A-ROOM")


def floor_plan(p, rooms, stair=True):
    X, Y = GX, GY
    # external walls (windows interrupt drawn over)
    for a, b in [((X[0], Y[0]), (X[-1], Y[0])), ((X[0], Y[-1]), (X[-1], Y[-1]))]:
        wall_rect(p, a[0], a[1], b[0], b[1], WALL_EXT)
    for a, b in [((X[0], Y[0]), (X[0], Y[-1])), ((X[-1], Y[0]), (X[-1], Y[-1]))]:
        wall_rect(p, a[0], a[1], b[0], b[1], WALL_EXT)
    # internal walls on grid lines
    for x in X[1:-1]:
        wall_rect(p, x, Y[0], x, Y[-1], WALL_INT)
    for y in Y[1:-1]:
        wall_rect(p, X[0], y, X[-1], y, WALL_INT)
    # windows in exterior walls: centred in each bay
    for i in range(3):
        cx = (X[i] + X[i + 1]) / 2
        window(p, cx - 750, Y[0], cx + 750, Y[0])
        window(p, cx - 750, Y[-1], cx + 750, Y[-1])
        cy = (Y[i] + Y[i + 1]) / 2
        window(p, X[0], cy - 600, X[0], cy + 600)
        window(p, X[-1], cy - 600, X[-1], cy + 600)
    # doors: one per room on its lower/left internal wall
    for i in range(3):
        for j in range(3):
            if j > 0:
                door(p, X[i] + 600, Y[j], 900 if (i, j) != (1, 1) else 1000, True, 1)
    for name, (i, j) in rooms.items():
        w, h = X[i + 1] - X[i], Y[j + 1] - Y[j]
        room_tag(p, name, (X[i] + X[i + 1]) / 2, (Y[j] + Y[j + 1]) / 2, w - WALL_INT, h - WALL_INT)
    if stair:
        stair_plan(p, X[1] + 200, Y[1] + 150, X[2] - X[1] - 400, Y[2] - Y[1] - 300)


def stair_plan(p, x, y, w, h, n=9):
    """Dog-leg stair in a box: two flights with landing at top."""
    half = w / 2
    land = 1100
    run = (h - land) / n
    for k in range(n + 1):
        yy = y + k * run
        p.line((x, yy), (x + half - 50, yy), "A-STAIR")
        p.line((x + half + 50, yy), (x + w, yy), "A-STAIR")
    p.rect(x, y, w, h, "A-STAIR")
    p.line((x + half - 50, y), (x + half - 50, y + h - land), "A-STAIR")
    p.line((x + half + 50, y), (x + half + 50, y + h - land), "A-STAIR")
    p.line((x, y + h - land), (x + w, y + h - land), "A-STAIR")
    p.poly([(x + half / 2, y + 200), (x + half / 2, y + h - land - 200)], "A-STAIR", closed=False)
    p.poly([(x + half / 2 - 120, y + h - land - 420), (x + half / 2, y + h - land - 200),
            (x + half / 2 + 120, y + h - land - 420)], "A-STAIR", closed=False)
    p.text("UP", (x + half / 2, y + 500), 2.5, "A-TEXT")
    p.text("LANDING", (x + w / 2, y + h - land / 2), 2.5, "A-TEXT")


def arch_plan(level, rooms, dwgno, stair=True, previews=True):
    doc, p, _ = sheet(f"A-{level}", f"{level} FLOOR PLAN", dwgno, "ARCHITECTURAL")
    grid(p)
    columns(p, label=False, hatch=True)
    floor_plan(p, rooms, stair)
    north(p, (GX[-1] + 5000, GY[-1] + 1000))
    title(p, GX[0], GY[0] - 4000, f"{level} FLOOR PLAN")
    return save(doc, f"{dwgno}_{level}_Floor_Plan", previews)


def roof_plan(previews):
    doc, p, _ = sheet("A-ROOF", "ROOF PLAN", "A-104", "ARCHITECTURAL")
    grid(p)
    X, Y = GX, GY
    p.rect(X[0] - 125, Y[0] - 125, X[-1] - X[0] + 250, Y[-1] - Y[0] + 250, "A-ROOF")
    p.rect(X[0] + 125, Y[0] + 125, X[-1] - X[0] - 250, Y[-1] - Y[0] - 250, "A-ROOF")
    p.text("125 PARAPET WALL 1000 HIGH", ((X[0] + X[-1]) / 2, Y[-1] + 600), 2.5, "A-TEXT")
    # stair cover + overhead tank
    p.rect(X[1], Y[1], X[2] - X[1], Y[2] - Y[1], "A-ROOF")
    p.text("STAIR COVER (MUMTY)", ((X[1] + X[2]) / 2, (Y[1] + Y[2]) / 2), 2.5, "A-TEXT")
    p.rect(X[2] + 800, Y[2] + 800, 2500, 2000, "S-TANK")
    p.text("OVERHEAD WATER TANK", (X[2] + 2050, Y[2] + 1800), 2.2, "A-TEXT")
    # slope arrows to drains
    for (cx, cy) in [(X[0] + 600, Y[0] + 600), (X[-1] - 600, Y[0] + 600)]:
        p.circle((cx, cy), 120, "P-DRAIN")
        p.text("RWP 100", (cx + 250, cy), 2, "P-DRAIN", align="LEFT")
    for sx in (X[0] + 3000, X[-1] - 3000):
        p.poly([(sx, Y[-1] - 1500), (sx, Y[0] + 1500)], "A-ROOF", closed=False)
        p.poly([(sx - 150, Y[0] + 1800), (sx, Y[0] + 1500), (sx + 150, Y[0] + 1800)], "A-ROOF", closed=False)
        p.text("SLOPE 1:100", (sx + 200, (Y[0] + Y[-1]) / 2), 2, "A-TEXT", align="LEFT", rot=90)
    title(p, X[0], Y[0] - 4000, "ROOF PLAN")
    return save(doc, "A-104_Roof_Plan", previews)


# --------------------------------------------------------------------------------------------
# Structure
# --------------------------------------------------------------------------------------------
def column_layout(previews):
    doc, p, _ = sheet("S-COL", "COLUMN LAYOUT PLAN", "S-201", "STRUCTURAL")
    grid(p)
    columns(p)
    title(p, GX[0], GY[0] - 4000, "COLUMN LAYOUT PLAN")
    rows = [("C1", "300x450", "8-T16", "T10@150/100"), ("C2", "300x450", "8-T20", "T10@150/100"),
            ("C3", "300x450", "10-T20", "T10@125/100")]
    p.table(GX[-1] + 4000, GY[-1], "COLUMN SCHEDULE (SAMPLE VALUES)", ["MARK", "SIZE", "MAIN", "TIES"], rows)
    return save(doc, "S-201_Column_Layout", previews)


def beam_layout(level, dwgno, previews):
    doc, p, _ = sheet(f"S-BEAM-{level}", f"{level} BEAM LAYOUT PLAN", dwgno, "STRUCTURAL")
    grid(p, dims=True)
    columns(p, label=False)
    bw = 250
    n = 1
    for j, y in enumerate(GY):
        for i in range(3):
            x0, x1 = GX[i] + COL[0] / 2, GX[i + 1] - COL[0] / 2
            p.line((x0, y - bw / 2), (x1, y - bw / 2), "S-BEAM")
            p.line((x0, y + bw / 2), (x1, y + bw / 2), "S-BEAM")
            mark = f"GB{n}" if level == "PLINTH" else f"B{n}"
            p.text(f"{mark} 250x450" if level != "PLINTH" else f"{mark} 250x400", ((x0 + x1) / 2, y + 350), 2.2,
                   "S-BEAM-TEXT")
            n += 1
    for i, x in enumerate(GX):
        for j in range(3):
            y0, y1 = GY[j] + COL[1] / 2, GY[j + 1] - COL[1] / 2
            p.line((x - bw / 2, y0), (x - bw / 2, y1), "S-BEAM")
            p.line((x + bw / 2, y0), (x + bw / 2, y1), "S-BEAM")
            mark = f"GB{n}" if level == "PLINTH" else f"B{n}"
            p.text(mark, (x - 350, (y0 + y1) / 2), 2.2, "S-BEAM-TEXT", rot=90)
            n += 1
    title(p, GX[0], GY[0] - 4000, f"{level} BEAM LAYOUT PLAN")
    p.mtext("NOTES:\\P1. Beam sizes/reinforcement are SAMPLE PLACEHOLDERS.\\P2. All dimensions in mm.\\P"
            "3. Refer to beam schedule for reinforcement.", (GX[-1] + 4000, GY[-1]), 2.5, "S-TEXT", 12000)
    return save(doc, f"{dwgno}_{level}_Beam_Layout", previews)


def slab_layout(previews):
    doc, p, _ = sheet("S-SLAB", "TYPICAL FLOOR SLAB LAYOUT", "S-204", "STRUCTURAL")
    grid(p)
    columns(p, label=False)
    k = 1
    for i in range(3):
        for j in range(3):
            if (i, j) == (1, 1):
                x0, y0, x1, y1 = GX[1], GY[1], GX[2], GY[2]
                p.line((x0 + 200, y0 + 200), (x1 - 200, y1 - 200), "S-SLAB-OPEN")
                p.line((x0 + 200, y1 - 200), (x1 - 200, y0 + 200), "S-SLAB-OPEN")
                p.text("STAIR OPENING", ((x0 + x1) / 2, (y0 + y1) / 2 + 300), 2.5, "S-TEXT")
                continue
            cx, cy = (GX[i] + GX[i + 1]) / 2, (GY[j] + GY[j + 1]) / 2
            lx, ly = GX[i + 1] - GX[i], GY[j + 1] - GY[j]
            p.line((cx - lx * 0.3, cy), (cx + lx * 0.3, cy), "S-REBAR-DIST")
            p.line((cx, cy - ly * 0.3), (cx, cy + ly * 0.3), "S-REBAR-DIST")
            p.circle((cx, cy), 450, "S-SLAB")
            p.text(f"S{k}", (cx, cy + 90), 2.5, "S-TEXT")
            p.text("125 THK", (cx, cy - 200), 1.8, "S-TEXT")
            p.text("T10@150 B/W", (cx + lx * 0.12, cy + 600), 1.8, "S-REBAR-TEXT", align="LEFT")
            k += 1
    title(p, GX[0], GY[0] - 4000, "TYPICAL FLOOR SLAB LAYOUT (FF/SF/ROOF)")
    return save(doc, "S-204_Slab_Layout", previews)


def foundation_plan(previews):
    doc, p, _ = sheet("S-FDN", "FOUNDATION LAYOUT PLAN", "S-200", "STRUCTURAL")
    grid(p)
    sizes = {"C1": (1800, "F1"), "C2": (2100, "F2"), "C3": (2400, "F3")}
    marks = columns(p, label=False)
    for (i, j), m in marks.items():
        a, fm = sizes[m]
        x, y = GX[i], GY[j]
        p.crect(x, y, a, a, "S-FTG")
        p.crect(x, y, a - 600, a - 600, "S-FTG", linetype="RNR_HIDDEN")
        p.text(fm, (x + a / 2 + 150, y - a / 2 + 200), 2.5, "S-TEXT", align="LEFT")
    rows = [("F1", "1800x1800", "450", "T12@150 B/W"), ("F2", "2100x2100", "500", "T12@125 B/W"),
            ("F3", "2400x2400", "550", "T16@150 B/W")]
    p.table(GX[-1] + 4000, GY[-1], "FOOTING SCHEDULE (SAMPLE VALUES)", ["MARK", "SIZE", "DEPTH", "BOTTOM MESH"], rows)
    title(p, GX[0], GY[0] - 4000, "FOUNDATION LAYOUT PLAN")
    return save(doc, "S-200_Foundation_Layout", previews)


def section_bar(p, c, r=8):
    p.solid_circle(c, r, "S-REBAR")


def details(previews):
    doc, p, _ = sheet("S-DET", "TYPICAL STRUCTURAL DETAILS", "S-301", "STRUCTURAL")
    s = 25.0  # detail at 1:25 -> enlarge geometry x4 relative to 1:100 sheet
    k = 4.0
    # --- column section C3 300x450, 10-T20, T10 ties, cover 40
    ox, oy = 0, 6000
    w, h, cv = 300 * k, 450 * k, 40 * k
    p.rect(ox, oy, w, h, "S-COL")
    p.hatch([(ox, oy), (ox + w, oy), (ox + w, oy + h), (ox, oy + h)], "Concrete", "S-HATCH", 4)
    p.rect(ox + cv, oy + cv, w - 2 * cv, h - 2 * cv, "S-STIRRUP")
    bx = [ox + cv + 40, ox + w - cv - 40]
    for yy in [oy + cv + 40 + (h - 2 * cv - 80) * t / 4 for t in range(5)]:
        for xx in bx:
            section_bar(p, (xx, yy), 10 * k)
    p.dim((ox, oy), (ox + w, oy), -500, "S-DIMS", angle=0)
    p.dim((ox + w, oy), (ox + w, oy + h), 500, "S-DIMS", angle=90)
    p.text("C3 - COLUMN SECTION", (ox + w / 2, oy - 1600), 3.5, "S-TEXT", style="RNR_HEADING")
    p.text("10-T20 MAIN, T10 TIES @125, COVER 40", (ox + w / 2, oy - 2100), 2.2, "S-REBAR-TEXT")

    # --- beam section 250x450, 3-T16 bot, 2-T16 top, T10@150
    ox = 4500
    w, h, cv = 250 * k, 450 * k, 25 * k
    p.rect(ox, oy, w, h, "S-BEAM")
    p.hatch([(ox, oy), (ox + w, oy), (ox + w, oy + h), (ox, oy + h)], "Concrete", "S-HATCH", 4)
    p.rect(ox + cv, oy + cv, w - 2 * cv, h - 2 * cv, "S-STIRRUP")
    for t in range(3):
        section_bar(p, (ox + cv + 50 + (w - 2 * cv - 100) * t / 2, oy + cv + 50), 8 * k)
    for t in range(2):
        section_bar(p, (ox + cv + 50 + (w - 2 * cv - 100) * t, oy + h - cv - 50), 8 * k)
    p.dim((ox, oy), (ox + w, oy), -500, "S-DIMS", angle=0)
    p.dim((ox + w, oy), (ox + w, oy + h), 500, "S-DIMS", angle=90)
    p.text("B1 - BEAM SECTION", (ox + w / 2, oy - 1600), 3.5, "S-TEXT", style="RNR_HEADING")
    p.text("2-T16 TOP, 3-T16 BOT, T10@150", (ox + w / 2, oy - 2100), 2.2, "S-REBAR-TEXT")

    # --- footing section F3 2400 x 550 with column stub, PCC 75
    ox, oy = 8500, 5000
    fw, fd, pcc = 2400 * 2, 550 * 2, 75 * 2
    p.rect(ox - 150, oy - pcc, fw + 300, pcc, "S-FTG")
    p.hatch([(ox - 150, oy - pcc), (ox + fw + 150, oy - pcc), (ox + fw + 150, oy), (ox - 150, oy)], "PCC",
            "S-HATCH", 2)
    ft = [(ox, oy), (ox + fw, oy), (ox + fw, oy + fd), (ox, oy + fd)]
    p.poly(ft, "S-FTG")
    p.hatch(ft, "RCC", "S-HATCH", 2)
    cx = ox + fw / 2
    p.rect(cx - 300, oy + fd, 600, 2200, "S-COL")
    p.line((ox + 100, oy + 150), (ox + fw - 100, oy + 150), "S-REBAR", lineweight=50)
    for t in range(11):
        section_bar(p, (ox + 150 + (fw - 300) * t / 10, oy + 190), 16)
    p.dim((ox, oy), (ox + fw, oy), -700, "S-DIMS", angle=0)
    p.dim((ox + fw, oy), (ox + fw, oy + fd), 600, "S-DIMS", angle=90)
    p.hatch([(ox - 800, oy - pcc - 300), (ox + fw + 800, oy - pcc - 300), (ox + fw + 800, oy - pcc),
             (ox - 800, oy - pcc)], "Earth", "S-HATCH", 3)
    p.text("F3 - FOOTING SECTION", (cx, oy - 1900), 3.5, "S-TEXT", style="RNR_HEADING")
    p.text("T16@150 B/W, 75 PCC (1:3:6) BELOW", (cx, oy - 2400), 2.2, "S-REBAR-TEXT")

    # --- stair section: 9 risers 167, going 250, waist 150
    ox, oy = 0, -1500
    R, G, n = 167, 250, 9
    pts = [(ox, oy)]
    for t in range(n):
        pts += [(ox + t * G, oy + (t + 1) * R), (ox + (t + 1) * G, oy + (t + 1) * R)]
    pts += [(ox + n * G + 1200, oy + n * R), (ox + n * G + 1200, oy + n * R - 150)]
    import math
    ang = math.atan2(R, G)
    off = 150 / math.cos(ang)
    pts += [(ox + n * G, oy + n * R - off), (ox, oy - off)]
    p.poly(pts, "S-STAIR")
    p.hatch(pts, "RCC", "S-HATCH", 0.6)
    p.line((ox + 60, oy - off + 60), (ox + n * G, oy + n * R - off + 60), "S-REBAR", lineweight=50)
    p.text("STAIR SECTION - 9R @167, T 250, WAIST 150", (ox + 1800, oy - 1300), 3.0, "S-TEXT", style="RNR_HEADING")
    p.text("MAIN T12@150, DIST T10@200 (SAMPLE)", (ox + 1800, oy - 1800), 2.2, "S-REBAR-TEXT")

    p.text("ALL DETAILS: SAMPLE REPRESENTATIONS FOR DRAFTING DEMONSTRATION ONLY - NOT A STRUCTURAL DESIGN",
           (4500, 10500), 3, "S-TEXT", style="RNR_HEADING")
    return save(doc, "S-301_Typical_Details", previews)


def section_elev(previews):
    doc, p, _ = sheet("A-SECT", "SECTION & ELEVATION", "A-201", "ARCHITECTURAL", "A2")
    # elevation (front, grid 1) at origin
    X = GX
    top = LEVELS[-1][1]
    p.line((X[0] - 2000, 0), (X[-1] + 2000, 0), "A-ELEV", lineweight=70)
    p.rect(X[0] - 125, 0, X[-1] - X[0] + 250, top, "A-ELEV")
    for nm, lv in LEVELS[1:-1]:
        p.line((X[0] - 125, lv), (X[-1] + 125, lv), "A-ELEV")
    for nm, lv in LEVELS:
        p.line((X[-1] + 600, lv), (X[-1] + 1800, lv), "ANNO-LEVEL")
        p.poly([(X[-1] + 800, lv), (X[-1] + 950, lv + 200), (X[-1] + 650, lv + 200)], "ANNO-LEVEL")
        p.text(f"{nm} +{lv / 1000:.3f}", (X[-1] + 1100, lv + 120), 2.2, "ANNO-LEVEL", align="LEFT")
    for fl in range(3):
        base = LEVELS[1][1] + fl * FLOOR_H
        for i in range(3):
            cx = (X[i] + X[i + 1]) / 2
            p.rect(cx - 750, base + 900, 1500, 1200, "A-WINDOW")
            p.line((cx, base + 900), (cx, base + 2100), "A-WINDOW")
    p.rect(X[1] + 1400, LEVELS[1][1], 1200, 2100, "A-DOOR")
    title(p, X[0], -2500, "FRONT ELEVATION (GRID 1)")
    # section A-A offset to the right
    ox = X[-1] + 9000
    Y = GY
    p.line((ox - 2000, 0), (ox + Y[-1] + 2000, 0), "A-SECT", lineweight=70)
    for nm, lv in LEVELS[2:5]:
        pts = [(ox - 125, lv - 125), (ox + Y[-1] + 125, lv - 125), (ox + Y[-1] + 125, lv), (ox - 125, lv)]
        p.poly(pts, "A-SECT")
        p.hatch(pts, "RCC", "A-HATCH", 0.5)
    for y in Y:
        for fl in range(3):
            lv = LEVELS[1][1] + fl * FLOOR_H
            p.rect(ox + y - 125, lv, 250, FLOOR_H - 125, "A-SECT")
    p.rect(ox - 125, LEVELS[4][1], 125, 1000, "A-SECT")
    p.rect(ox + Y[-1], LEVELS[4][1], 125, 1000, "A-SECT")
    # plinth + footings
    p.rect(ox - 125, 0, Y[-1] + 250, LEVELS[1][1], "A-SECT")
    for y in Y:
        p.crect(ox + y, -1500, 2100, 500, "S-FTG")
        p.rect(ox + y - 150, -1250, 300, 1250, "S-COL")
    p.hatch([(ox - 2000, -1900), (ox + Y[-1] + 2000, -1900), (ox + Y[-1] + 2000, -1750), (ox - 2000, -1750)],
            "Earth", "A-HATCH", 1)
    title(p, ox, -2500, "SECTION A-A")
    return save(doc, "A-201_Section_Elevation", previews)


def schedules(previews):
    doc, p, _ = sheet("SCHED", "SCHEDULES", "G-001", "GENERAL")
    x, y = 0, 12000
    W, H = p.table(x, y, "DOOR SCHEDULE", ["MARK", "SIZE (WxH)", "TYPE", "QTY"],
                   [("D1", "1000x2100", "MAIN - SOLID WOOD", 1), ("D2", "900x2100", "FLUSH", 18),
                    ("D3", "750x2100", "PVC (TOILET)", 6)])
    p.table(x + W + 2000, y, "WINDOW SCHEDULE", ["MARK", "SIZE (WxH)", "TYPE", "QTY"],
            [("W1", "1500x1200", "SLIDING ALUM.", 18), ("W2", "1200x1200", "SLIDING ALUM.", 18),
             ("V1", "600x450", "VENT", 6)])
    y2 = y - H - 3000
    W2, H2 = p.table(x, y2, "BEAM SCHEDULE (SAMPLE VALUES)", ["MARK", "SIZE", "TOP", "BOTTOM", "STIRRUP"],
                     [("B1-B12", "250x450", "2-T16", "3-T16", "T10@150"), ("B13-B24", "250x450", "2-T16", "3-T20",
                                                                            "T10@150"),
                      ("GB1-GB24", "250x400", "2-T16", "2-T16", "T10@200")], colw_paper=22)
    p.table(x + W2 + 2000, y2, "BAR BENDING SCHEDULE - EXTRACT (SAMPLE)",
            ["MARK", "DIA", "SHAPE", "NO.", "LEN (mm)", "WT (kg)"],
            [("B1-01", "T16", "STRAIGHT", 24, 4650, round(24 * 4.65 * 1.578, 1)),
             ("B1-02", "T16", "L-BAR", 36, 4950, round(36 * 4.95 * 1.578, 1)),
             ("B1-03", "T10", "STIRRUP", 360, 1300, round(360 * 1.3 * 0.617, 1))], colw_paper=20)
    p.mtext("Unit weights: d^2/162.2 kg/m (T10=0.617, T16=1.578).\\PQuantities are CAD-derived estimates "
            "for drafting/estimation support only.", (x, y2 - H2 - 1500), 2.5, "ANNO-TEXT", 25000)
    return save(doc, "G-001_Schedules", previews)


def main():
    previews = "--no-png" not in sys.argv
    os.makedirs(PREV, exist_ok=True)
    out = []
    gf = {"LIVING": (0, 2), "DINING": (1, 2), "KITCHEN": (2, 2), "BED-1": (0, 0), "GUEST": (2, 0),
          "TOILET": (0, 1), "PARKING/LOBBY": (1, 0), "STORE": (2, 1)}
    typ = {"MASTER BED": (0, 2), "FAMILY LIVING": (1, 2), "BED-2": (2, 2), "BED-3": (0, 0), "BED-4": (2, 0),
           "TOILET": (0, 1), "BALCONY/LOBBY": (1, 0), "TOILET-2": (2, 1)}
    out.append(arch_plan("GROUND", gf, "A-101", previews=previews))
    out.append(arch_plan("FIRST", typ, "A-102", previews=previews))
    out.append(arch_plan("SECOND", typ, "A-103", previews=previews))
    out.append(roof_plan(previews))
    out.append(section_elev(previews))
    out.append(foundation_plan(previews))
    out.append(column_layout(previews))
    out.append(beam_layout("PLINTH", "S-202", previews))
    out.append(beam_layout("TYPICAL", "S-203", previews))
    out.append(slab_layout(previews))
    out.append(details(previews))
    out.append(schedules(previews))
    for o in out:
        print("wrote", os.path.relpath(o, ROOT))


if __name__ == "__main__":
    main()
