#!/usr/bin/env python3
"""
RooMNRooF CAD PRO ULTIMATE - Standards generator (single source of truth).

Produces:
  Standards/RNR_Colors.json        ~100 controlled TrueColor definitions
  Standards/RNR_Layers.json        full layer hierarchy (every layer references a color)
  Standards/RNR_LayerFilters.json  layer filter definitions
  Standards/RNR_Members.json       55 structural member definitions
  Standards/RNR_Hatches.json       20 material/hatch definitions
  Standards/RNR_Blocks.json        block / dynamic block metadata
  Standards/RNR_Styles.json        text, dimension, multileader styles, scales, sheets
  Standards/RNR_Rebar.json         bar diameters, unit weights, shape codes
  Standards/RooMNRooF_Project.json default Bangladesh project configuration
  Hatch/*.pat                      custom hatch patterns (AutoCAD PAT format)
  Standards/RooMNRooF.lin          custom linetypes
  AutoLISP/RNR_Data.lsp            generated LISP data tables (layers/colors)

Run:  python3 Scripts/generate_standards.py
The C# plugin and AutoLISP read these files at runtime, so edit THIS file
(or the JSON directly) and keep them in sync via Scripts/validate_standards.py.
"""
import json
import math
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STD = os.path.join(ROOT, "Standards")
HAT = os.path.join(ROOT, "Hatch")
LSP = os.path.join(ROOT, "AutoLISP")

# --------------------------------------------------------------------------
# ACI approximation (standard AutoCAD 1..255 palette computed algorithmically)
# --------------------------------------------------------------------------
def aci_table():
    t = {1: (255, 0, 0), 2: (255, 255, 0), 3: (0, 255, 0), 4: (0, 255, 255),
         5: (0, 0, 255), 6: (255, 0, 255), 7: (255, 255, 255), 8: (128, 128, 128), 9: (192, 192, 192)}
    for i in range(10, 250):
        hue = ((i - 10) // 10) * 15.0
        sub = (i - 10) % 10
        val = [1.0, 1.0, 0.8, 0.8, 0.6, 0.6, 0.5, 0.5, 0.3, 0.3][sub]
        sat = 1.0 if sub % 2 == 0 else 0.5
        h = hue / 60.0
        c = val * sat
        x = c * (1 - abs(h % 2 - 1))
        m = val - c
        r, g, b = [(c, x, 0), (x, c, 0), (0, c, x), (0, x, c), (x, 0, c), (c, 0, x)][int(h) % 6]
        t[i] = tuple(int(round((v + m) * 255)) for v in (r, g, b))
    for i, gv in zip(range(250, 256), (51, 91, 132, 173, 214, 255)):
        t[i] = (gv, gv, gv)
    return t

ACI = aci_table()

def nearest_aci(rgb):
    best, bd = 7, 1e9
    for k, v in ACI.items():
        d = sum((a - b) ** 2 for a, b in zip(rgb, v))
        if d < bd:
            best, bd = k, d
    return best

# --------------------------------------------------------------------------
# COLORS  (name, rgb, lineweight mm, transparency %, plot behaviour, object category)
# plot behaviour: BLACK = plots black in monochrome and in "color" CTB it keeps colour,
#                 GRAY  = plots screened grey, NOPLOT = reference only
# --------------------------------------------------------------------------
C = {}
def col(cat, name, rgb, lw, tr, plot, obj):
    key = f"{cat[:4]}-{name}".upper().replace(" ", "-")
    C[key] = dict(id=key, category=cat, name=name, rgb=list(rgb),
                  hex="#%02X%02X%02X" % rgb, aci=nearest_aci(rgb), screen="TrueColor",
                  plot=plot, transparency=tr, lineweight=lw, discipline=cat, objectCategory=obj)

A = "ARCHITECTURE"
for n, rgb, lw, tr, p, o in [
    ("Wall Cut", (230, 57, 70), 0.50, 0, "BLACK", "wall"),
    ("Wall Beyond", (244, 162, 97), 0.25, 0, "BLACK", "wall"),
    ("Door", (255, 183, 3), 0.25, 0, "BLACK", "opening"),
    ("Window", (72, 202, 228), 0.25, 0, "BLACK", "opening"),
    ("Glazing", (144, 224, 239), 0.18, 20, "GRAY", "glazing"),
    ("Furniture", (181, 131, 141), 0.18, 0, "GRAY", "furniture"),
    ("Fixture", (106, 153, 78), 0.18, 0, "GRAY", "fixture"),
    ("Floor Pattern", (221, 161, 94), 0.13, 50, "GRAY", "finish"),
    ("Ceiling", (188, 184, 177), 0.13, 30, "GRAY", "ceiling"),
    ("Roof", (188, 108, 37), 0.35, 0, "BLACK", "roof"),
    ("Stair", (255, 143, 171), 0.25, 0, "BLACK", "stair"),
    ("Ramp", (255, 179, 198), 0.25, 0, "BLACK", "ramp"),
    ("Room Tag", (155, 93, 229), 0.18, 0, "BLACK", "annotation"),
    ("Elevation", (0, 187, 249), 0.25, 0, "BLACK", "view"),
    ("Section", (241, 91, 181), 0.35, 0, "BLACK", "view"),
    ("Detail", (254, 228, 64), 0.25, 0, "BLACK", "view"),
]:
    col(A, n, rgb, lw, tr, p, o)

S = "STRUCTURE"
for n, rgb, lw, tr, p, o in [
    ("Column", (214, 40, 40), 0.50, 0, "BLACK", "column"),
    ("Column Text", (247, 127, 0), 0.18, 0, "BLACK", "annotation"),
    ("Beam", (0, 119, 182), 0.35, 0, "BLACK", "beam"),
    ("Beam Hidden", (0, 150, 199), 0.25, 0, "BLACK", "beam"),
    ("Beam Text", (0, 180, 216), 0.18, 0, "BLACK", "annotation"),
    ("Slab", (82, 183, 136), 0.25, 0, "BLACK", "slab"),
    ("Slab Opening", (216, 243, 220), 0.25, 0, "BLACK", "opening"),
    ("Footing", (153, 88, 42), 0.35, 0, "BLACK", "foundation"),
    ("Pile", (111, 29, 27), 0.35, 0, "BLACK", "foundation"),
    ("Pile Cap", (187, 148, 87), 0.35, 0, "BLACK", "foundation"),
    ("Shear Wall", (157, 2, 8), 0.50, 0, "BLACK", "wall"),
    ("Stirrup", (255, 0, 110), 0.25, 0, "BLACK", "rebar"),
    ("Rebar Main", (251, 86, 7), 0.35, 0, "BLACK", "rebar"),
    ("Rebar Dist", (255, 190, 11), 0.25, 0, "BLACK", "rebar"),
    ("Rebar Text", (131, 56, 236), 0.18, 0, "BLACK", "annotation"),
    ("Stair", (239, 71, 111), 0.35, 0, "BLACK", "stair"),
    ("Ramp", (255, 209, 102), 0.25, 0, "BLACK", "ramp"),
    ("Roof", (6, 214, 160), 0.35, 0, "BLACK", "roof"),
    ("Tank", (17, 138, 178), 0.35, 0, "BLACK", "tank"),
    ("Retaining Wall", (7, 59, 76), 0.50, 0, "BLACK", "wall"),
    ("Section", (58, 134, 255), 0.35, 0, "BLACK", "view"),
    ("Detail", (131, 197, 190), 0.25, 0, "BLACK", "view"),
]:
    col(S, n, rgb, lw, tr, p, o)

CV = "CIVIL"
for n, rgb, lw, tr, p, o in [
    ("Site", (96, 108, 56), 0.25, 0, "BLACK", "site"),
    ("Boundary", (220, 47, 2), 0.50, 0, "BLACK", "boundary"),
    ("Road", (73, 80, 87), 0.35, 0, "BLACK", "road"),
    ("Curb", (108, 117, 125), 0.25, 0, "BLACK", "road"),
    ("Drain", (0, 95, 115), 0.35, 0, "BLACK", "drainage"),
    ("Grade", (148, 210, 189), 0.18, 0, "GRAY", "grading"),
    ("Contour Major", (202, 103, 2), 0.25, 0, "GRAY", "contour"),
    ("Contour Minor", (238, 155, 0), 0.13, 30, "GRAY", "contour"),
    ("Utility", (174, 32, 18), 0.25, 0, "BLACK", "utility"),
]:
    col(CV, n, rgb, lw, tr, p, o)

for cat, items in [
    ("PLUMBING", [("Water", (0, 150, 255), 0.25, "pipe"), ("Drain", (0, 100, 0), 0.35, "pipe"),
                  ("Sanitary", (139, 69, 19), 0.35, "pipe"), ("Pipe", (70, 130, 180), 0.25, "pipe"),
                  ("Fixture", (100, 149, 237), 0.18, "fixture")]),
    ("ELECTRICAL", [("Light", (255, 214, 10), 0.18, "device"), ("Power", (255, 87, 51), 0.25, "device"),
                    ("Socket", (199, 0, 57), 0.18, "device"), ("Switch", (144, 12, 63), 0.18, "device"),
                    ("Cable", (88, 24, 69), 0.18, "cable"), ("Panel", (255, 195, 0), 0.35, "equipment")]),
    ("HVAC", [("Supply Duct", (72, 149, 239), 0.25, "duct"), ("Return Duct", (67, 97, 238), 0.25, "duct"),
              ("Equipment", (63, 55, 201), 0.35, "equipment"), ("Diffuser", (76, 201, 240), 0.18, "device")]),
    ("LANDSCAPE", [("Tree", (56, 176, 0), 0.18, "planting"), ("Shrub", (112, 224, 0), 0.13, "planting"),
                   ("Grass", (158, 240, 26), 0.13, "planting"), ("Paving", (204, 213, 174), 0.18, "hardscape"),
                   ("Water Body", (0, 180, 216), 0.18, "water")]),
]:
    for n, rgb, lw, o in items:
        col(cat, n, rgb, lw, 0, "BLACK", o)

for cat, items in [
    ("ANNOTATION", [("Text", (255, 255, 255), 0.18), ("Tag", (255, 214, 165), 0.18), ("Level", (253, 255, 182), 0.18),
                    ("North", (202, 255, 191), 0.25), ("Section Mark", (155, 246, 255), 0.25),
                    ("Detail Mark", (160, 196, 255), 0.25), ("Title", (255, 198, 255), 0.35),
                    ("Leader", (255, 173, 173), 0.18)]),
    ("TEXT", [("Heading", (255, 255, 255), 0.35), ("Body", (230, 230, 230), 0.18), ("Note", (200, 200, 200), 0.18),
              ("Small", (180, 180, 180), 0.13)]),
    ("DIMENSION", [("Arch Dim", (255, 159, 28), 0.18), ("Struct Dim", (46, 196, 182), 0.18),
                   ("Civil Dim", (203, 243, 240), 0.18), ("Level Dim", (255, 191, 105), 0.18)]),
    ("GRID", [("Grid Line", (173, 181, 189), 0.18), ("Grid Bubble", (248, 249, 250), 0.25),
              ("Grid Text", (255, 255, 255), 0.25)]),
]:
    for n, rgb, lw in items:
        col(cat, n, rgb, lw, 0, "BLACK", "annotation")

for cat, items in [
    ("EXISTING", [("Existing Wall", (150, 150, 150), 0.25, 0, "GRAY"), ("Existing Struct", (130, 130, 130), 0.25, 0, "GRAY"),
                  ("Existing Site", (110, 110, 110), 0.18, 0, "GRAY")]),
    ("DEMOLITION", [("Demo Wall", (255, 77, 109), 0.25, 0, "BLACK"), ("Demo Struct", (201, 24, 74), 0.25, 0, "BLACK"),
                    ("Demo Misc", (255, 117, 143), 0.18, 0, "BLACK")]),
    ("PROPOSED", [("New Wall", (0, 245, 212), 0.50, 0, "BLACK"), ("New Struct", (0, 187, 249), 0.50, 0, "BLACK"),
                  ("New Misc", (155, 229, 100), 0.25, 0, "BLACK")]),
    ("REFERENCE", [("Xref", (120, 120, 120), 0.13, 50, "GRAY"), ("Xref Arch", (140, 110, 110), 0.13, 50, "GRAY"),
                   ("Xref Struct", (110, 110, 140), 0.13, 50, "GRAY"), ("Xref MEP", (110, 140, 110), 0.13, 50, "GRAY"),
                   ("Construction", (90, 90, 90), 0.09, 60, "NOPLOT"), ("Viewport", (80, 80, 80), 0.09, 0, "NOPLOT")]),
    ("HATCH", [("Concrete", (160, 160, 160), 0.09, 40, "GRAY"), ("RCC", (140, 140, 160), 0.09, 40, "GRAY"),
               ("Brick", (199, 81, 70), 0.09, 40, "GRAY"), ("Earth", (127, 85, 57), 0.09, 40, "GRAY"),
               ("Sand", (221, 184, 146), 0.09, 40, "GRAY"), ("Stone", (176, 137, 104), 0.09, 40, "GRAY"),
               ("Tile", (230, 204, 178), 0.09, 50, "GRAY"), ("Wood", (156, 102, 68), 0.09, 40, "GRAY"),
               ("Glass", (173, 232, 244), 0.09, 50, "GRAY"), ("Metal", (108, 117, 125), 0.09, 40, "GRAY"),
               ("Insulation", (255, 214, 224), 0.09, 40, "GRAY"), ("Water", (0, 150, 199), 0.09, 50, "GRAY"),
               ("Grass", (128, 185, 24), 0.09, 50, "GRAY")]),
]:
    for n, rgb, lw, tr, p in items:
        col(cat, n, rgb, lw, tr, p, "hatch" if cat == "HATCH" else "general")

# --------------------------------------------------------------------------
# LAYERS
# --------------------------------------------------------------------------
L = []
def lay(name, desc, color, lt="Continuous", disc=None, cls="general", plot=None, status="PROPOSED"):
    c = C[color]
    L.append(dict(name=name, description=desc, colorId=color, rgb=c["rgb"], aci=c["aci"], linetype=lt,
                  lineweight=c["lineweight"], transparency=c["transparency"],
                  plot=(c["plot"] != "NOPLOT") if plot is None else plot,
                  discipline=disc or c["discipline"], objectClass=cls, status=status))

for n, d, c, lt, cls, st in [
    ("A-WALL", "Walls - cut", "ARCH-WALL-CUT", "Continuous", "wall", "PROPOSED"),
    ("A-WALL-EXST", "Walls - existing", "EXIS-EXISTING-WALL", "Continuous", "wall", "EXISTING"),
    ("A-WALL-DEMO", "Walls - demolition", "DEMO-DEMO-WALL", "RNR_DEMO", "wall", "DEMOLITION"),
    ("A-DOOR", "Doors", "ARCH-DOOR", "Continuous", "opening", "PROPOSED"),
    ("A-WINDOW", "Windows", "ARCH-WINDOW", "Continuous", "opening", "PROPOSED"),
    ("A-GLAZ", "Glazing", "ARCH-GLAZING", "Continuous", "glazing", "PROPOSED"),
    ("A-FURN", "Furniture", "ARCH-FURNITURE", "Continuous", "furniture", "PROPOSED"),
    ("A-FIXTURE", "Sanitary / kitchen fixtures", "ARCH-FIXTURE", "Continuous", "fixture", "PROPOSED"),
    ("A-FLOR", "Floor finish patterns", "ARCH-FLOOR-PATTERN", "Continuous", "finish", "PROPOSED"),
    ("A-CEIL", "Reflected ceiling", "ARCH-CEILING", "RNR_HIDDEN", "ceiling", "PROPOSED"),
    ("A-ROOF", "Roof outline", "ARCH-ROOF", "Continuous", "roof", "PROPOSED"),
    ("A-STAIR", "Stairs - architectural", "ARCH-STAIR", "Continuous", "stair", "PROPOSED"),
    ("A-RAMP", "Ramps", "ARCH-RAMP", "Continuous", "ramp", "PROPOSED"),
    ("A-ROOM", "Room tags and areas", "ARCH-ROOM-TAG", "Continuous", "annotation", "PROPOSED"),
    ("A-TEXT", "Architectural text", "TEXT-BODY", "Continuous", "annotation", "PROPOSED"),
    ("A-DIMS", "Architectural dimensions", "DIME-ARCH-DIM", "Continuous", "dimension", "PROPOSED"),
    ("A-HATCH", "Architectural hatch", "HATC-BRICK", "Continuous", "hatch", "PROPOSED"),
    ("A-ELEV", "Elevations", "ARCH-ELEVATION", "Continuous", "view", "PROPOSED"),
    ("A-SECT", "Sections", "ARCH-SECTION", "Continuous", "view", "PROPOSED"),
    ("A-DETAIL", "Details", "ARCH-DETAIL", "Continuous", "view", "PROPOSED"),
]:
    lay(n, d, c, lt, "ARCHITECTURE", cls, status=st)

for n, d, c, lt, cls in [
    ("S-GRID", "Structural grid lines", "GRID-GRID-LINE", "RNR_GRID", "grid"),
    ("S-COL", "Columns", "STRU-COLUMN", "Continuous", "column"),
    ("S-COL-TEXT", "Column marks", "STRU-COLUMN-TEXT", "Continuous", "annotation"),
    ("S-BEAM", "Beams", "STRU-BEAM", "Continuous", "beam"),
    ("S-BEAM-HIDDEN", "Hidden / drop beams below slab", "STRU-BEAM-HIDDEN", "RNR_HIDDEN", "beam"),
    ("S-BEAM-TEXT", "Beam marks", "STRU-BEAM-TEXT", "Continuous", "annotation"),
    ("S-SLAB", "Slabs", "STRU-SLAB", "Continuous", "slab"),
    ("S-SLAB-OPEN", "Slab openings", "STRU-SLAB-OPENING", "Continuous", "opening"),
    ("S-FTG", "Footings", "STRU-FOOTING", "Continuous", "foundation"),
    ("S-PILE", "Piles", "STRU-PILE", "Continuous", "foundation"),
    ("S-PILECAP", "Pile caps", "STRU-PILE-CAP", "Continuous", "foundation"),
    ("S-SW", "Shear walls / core walls", "STRU-SHEAR-WALL", "Continuous", "wall"),
    ("S-STIRRUP", "Stirrups / ties / links", "STRU-STIRRUP", "Continuous", "rebar"),
    ("S-REBAR", "Main reinforcement", "STRU-REBAR-MAIN", "Continuous", "rebar"),
    ("S-REBAR-DIST", "Distribution reinforcement", "STRU-REBAR-DIST", "Continuous", "rebar"),
    ("S-REBAR-TEXT", "Reinforcement notes", "STRU-REBAR-TEXT", "Continuous", "annotation"),
    ("S-STAIR", "Structural stairs", "STRU-STAIR", "Continuous", "stair"),
    ("S-RAMP", "Structural ramps", "STRU-RAMP", "Continuous", "ramp"),
    ("S-ROOF", "Roof structure", "STRU-ROOF", "Continuous", "roof"),
    ("S-TANK", "Water tanks", "STRU-TANK", "Continuous", "tank"),
    ("S-RWALL", "Retaining walls", "STRU-RETAINING-WALL", "Continuous", "wall"),
    ("S-JOINT", "Expansion / construction joints", "STRU-DETAIL", "RNR_JOINT", "joint"),
    ("S-SECTION", "Structural sections", "STRU-SECTION", "Continuous", "view"),
    ("S-DETAIL", "Structural details", "STRU-DETAIL", "Continuous", "view"),
    ("S-DIMS", "Structural dimensions", "DIME-STRUCT-DIM", "Continuous", "dimension"),
    ("S-TEXT", "Structural text", "TEXT-BODY", "Continuous", "annotation"),
    ("S-HATCH", "Structural hatch (concrete)", "HATC-RCC", "Continuous", "hatch"),
]:
    lay(n, d, c, lt, "STRUCTURE", cls)

for n, d, c, lt, cls in [
    ("C-SITE", "Site features", "CIVI-SITE", "Continuous", "site"),
    ("C-BOUNDARY", "Property boundary", "CIVI-BOUNDARY", "RNR_BOUNDARY", "boundary"),
    ("C-ROAD", "Roads", "CIVI-ROAD", "Continuous", "road"),
    ("C-CURB", "Curbs", "CIVI-CURB", "Continuous", "road"),
    ("C-DRAIN", "Surface drains", "CIVI-DRAIN", "Continuous", "drainage"),
    ("C-GRADE", "Grading / spot levels", "CIVI-GRADE", "Continuous", "grading"),
    ("C-CONTOUR", "Contours", "CIVI-CONTOUR-MAJOR", "Continuous", "contour"),
    ("C-UTILITY", "Underground utilities", "CIVI-UTILITY", "RNR_UTILITY", "utility"),
    ("C-LANDSCAPE", "Landscape / hardscape", "LAND-PAVING", "Continuous", "hardscape"),
    ("C-TREE", "Trees and planting", "LAND-TREE", "Continuous", "planting"),
]:
    lay(n, d, c, lt, "CIVIL", cls)

for n, d, c, lt in [
    ("P-WATER", "Water supply", "PLUM-WATER", "RNR_WATER"), ("P-DRAIN", "Storm drain pipe", "PLUM-DRAIN", "RNR_HIDDEN"),
    ("P-SANITARY", "Sanitary / soil pipe", "PLUM-SANITARY", "Continuous"), ("P-PIPE", "General piping", "PLUM-PIPE", "Continuous"),
    ("P-FIXTURE", "Plumbing fixtures", "PLUM-FIXTURE", "Continuous"),
    ("E-LIGHT", "Lighting", "ELEC-LIGHT", "Continuous"), ("E-POWER", "Power", "ELEC-POWER", "Continuous"),
    ("E-SOCKET", "Sockets", "ELEC-SOCKET", "Continuous"), ("E-SWITCH", "Switches", "ELEC-SWITCH", "Continuous"),
    ("E-CABLE", "Cable runs", "ELEC-CABLE", "RNR_HIDDEN"), ("E-PANEL", "Distribution boards", "ELEC-PANEL", "Continuous"),
    ("M-DUCT", "HVAC ducts", "HVAC-SUPPLY-DUCT", "Continuous"), ("M-EQUIP", "HVAC equipment", "HVAC-EQUIPMENT", "Continuous"),
]:
    lay(n, d, c, lt, None, "mep")

for n, d, c, cls in [
    ("ANNO-TEXT", "General annotation text", "ANNO-TEXT", "annotation"), ("ANNO-DIMS", "General dimensions", "DIME-ARCH-DIM", "dimension"),
    ("ANNO-TAGS", "Tags", "ANNO-TAG", "annotation"), ("ANNO-GRID", "Grid bubbles and labels", "GRID-GRID-BUBBLE", "grid"),
    ("ANNO-NORTH", "North arrow", "ANNO-NORTH", "annotation"), ("ANNO-LEVEL", "Level marks", "ANNO-LEVEL", "annotation"),
    ("ANNO-SECTION", "Section marks", "ANNO-SECTION-MARK", "annotation"), ("ANNO-DETAIL", "Detail marks", "ANNO-DETAIL-MARK", "annotation"),
    ("ANNO-TITLE", "Title block", "ANNO-TITLE", "titleblock"), ("ANNO-LEADER", "Leaders / multileaders", "ANNO-LEADER", "annotation"),
    ("ANNO-SCHEDULE", "Schedules / tables", "TEXT-NOTE", "schedule"),
]:
    lay(n, d, c, "Continuous", "ANNOTATION", cls)

for n, d, c in [("XREF", "External references", "REFE-XREF"), ("XREF-ARCH", "Architectural xrefs", "REFE-XREF-ARCH"),
                ("XREF-STRUCT", "Structural xrefs", "REFE-XREF-STRUCT"), ("XREF-MEP", "MEP xrefs", "REFE-XREF-MEP")]:
    lay(n, d, c, "Continuous", "REFERENCE", "xref")
lay("Z-CONST", "Construction lines (no plot)", "REFE-CONSTRUCTION", "RNR_HIDDEN", "REFERENCE", "construction", plot=False)
lay("Z-VPORT", "Viewports (no plot)", "REFE-VIEWPORT", "Continuous", "REFERENCE", "viewport", plot=False)

FILTERS = [
    dict(name="ALL", expr="*"),
    dict(name="ARCHITECTURE", expr="A-*"),
    dict(name="STRUCTURE", expr="S-*"),
    dict(name="CIVIL", expr="C-*"),
    dict(name="RCC", expr="S-COL*,S-BEAM*,S-SLAB*,S-FTG,S-PILE*,S-SW,S-STIRRUP,S-REBAR*,S-STAIR,S-TANK,S-RWALL"),
    dict(name="MEP", expr="P-*,E-*,M-*"),
    dict(name="ANNOTATION", expr="ANNO-*,*-TEXT,*-DIMS"),
    dict(name="SITE", expr="C-*"),
    dict(name="REFERENCE", expr="XREF*,Z-*"),
    dict(name="EXISTING", expr="*-EXST"),
    dict(name="DEMOLITION", expr="*-DEMO"),
    dict(name="PROPOSED", expr="~*-EXST,~*-DEMO"),
]

# --------------------------------------------------------------------------
# STRUCTURAL MEMBERS (55)
# shape: RECT, CIRCLE, LSHAPE, TSHAPE, CROSS, BEAM, SLAB, STAIR, LANDING, RAMP, FOOTING,
#        PILE, PILECAP, WALL, TANK, JOINT, OPENING, STARTER, JOINTBC, CORE
# schedule: COLUMN, BEAM, SLAB, FOOTING, STAIR, WALL, TANK, NONE
# --------------------------------------------------------------------------
P_COL = ["Width", "Depth", "Height"]
P_BEAM = ["Width", "Depth", "Length"]
P_SLAB = ["Length", "Width", "Thickness"]
P_FTG = ["Length", "Width", "Thickness"]
MEM = [
    (1, "COL", "Column", "RECT", "S-COL", "S-COL-TEXT", P_COL, "COLUMN", "C", (300, 300, 3000)),
    (2, "COL-RECT", "Rectangular Column", "RECT", "S-COL", "S-COL-TEXT", P_COL, "COLUMN", "C", (300, 450, 3000)),
    (3, "COL-SQ", "Square Column", "RECT", "S-COL", "S-COL-TEXT", P_COL, "COLUMN", "C", (350, 350, 3000)),
    (4, "COL-CIRC", "Circular Column", "CIRCLE", "S-COL", "S-COL-TEXT", ["Diameter", "Height"], "COLUMN", "CC", (400, 3000)),
    (5, "COL-L", "L-Column", "LSHAPE", "S-COL", "S-COL-TEXT", ["Width", "Depth", "Thickness", "Height"], "COLUMN", "LC", (600, 600, 250, 3000)),
    (6, "COL-T", "T-Column", "TSHAPE", "S-COL", "S-COL-TEXT", ["Width", "Depth", "Thickness", "Height"], "COLUMN", "TC", (750, 500, 250, 3000)),
    (7, "COL-X", "Cross Column", "CROSS", "S-COL", "S-COL-TEXT", ["Width", "Depth", "Thickness", "Height"], "COLUMN", "XC", (750, 750, 250, 3000)),
    (8, "BM", "Beam", "BEAM", "S-BEAM", "S-BEAM-TEXT", P_BEAM, "BEAM", "B", (250, 450, 5000)),
    (9, "BM-PRI", "Primary Beam", "BEAM", "S-BEAM", "S-BEAM-TEXT", P_BEAM, "BEAM", "PB", (300, 600, 6000)),
    (10, "BM-SEC", "Secondary Beam", "BEAM", "S-BEAM", "S-BEAM-TEXT", P_BEAM, "BEAM", "SB", (250, 450, 4500)),
    (11, "BM-EDGE", "Edge Beam", "BEAM", "S-BEAM", "S-BEAM-TEXT", P_BEAM, "BEAM", "EB", (250, 500, 5000)),
    (12, "BM-HID", "Hidden Beam", "BEAM", "S-BEAM-HIDDEN", "S-BEAM-TEXT", P_BEAM, "BEAM", "HB", (600, 200, 4000)),
    (13, "BM-TIE", "Tie Beam", "BEAM", "S-BEAM", "S-BEAM-TEXT", P_BEAM, "BEAM", "TB", (250, 400, 5000)),
    (14, "BM-PLINTH", "Plinth Beam", "BEAM", "S-BEAM", "S-BEAM-TEXT", P_BEAM, "BEAM", "PLB", (250, 450, 5000)),
    (15, "BM-ROOF", "Roof Beam", "BEAM", "S-BEAM", "S-BEAM-TEXT", P_BEAM, "BEAM", "RB", (250, 450, 5000)),
    (16, "SLB", "Slab", "SLAB", "S-SLAB", "S-TEXT", P_SLAB, "SLAB", "S", (5000, 4000, 125)),
    (17, "SLB-FLAT", "Flat Slab", "SLAB", "S-SLAB", "S-TEXT", P_SLAB, "SLAB", "FS", (7000, 7000, 250)),
    (18, "SLB-RIB", "Ribbed Slab", "SLAB", "S-SLAB", "S-TEXT", ["Length", "Width", "Thickness", "RibSpacing", "RibWidth"], "SLAB", "RS", (7000, 6000, 75, 600, 150)),
    (19, "DROP", "Drop Panel", "SLAB", "S-SLAB", "S-TEXT", P_SLAB, "SLAB", "DP", (2400, 2400, 150)),
    (20, "SLB-CANT", "Cantilever Slab", "SLAB", "S-SLAB", "S-TEXT", P_SLAB, "SLAB", "CS", (1200, 4000, 150)),
    (21, "STR", "Stair", "STAIR", "S-STAIR", "S-TEXT", ["Width", "Going", "Riser", "Steps"], "STAIR", "ST", (1200, 250, 150, 20)),
    (22, "STR-DOG", "Dog-Leg Stair", "STAIR", "S-STAIR", "S-TEXT", ["Width", "Going", "Riser", "Steps"], "STAIR", "DST", (1200, 250, 150, 20)),
    (23, "STR-STRT", "Straight Stair", "STAIR", "S-STAIR", "S-TEXT", ["Width", "Going", "Riser", "Steps"], "STAIR", "SST", (1200, 250, 150, 12)),
    (24, "LAND", "Landing", "LANDING", "S-STAIR", "S-TEXT", P_SLAB, "STAIR", "LD", (2550, 1200, 150)),
    (25, "RMP", "Ramp", "RAMP", "S-RAMP", "S-TEXT", ["Length", "Width", "Thickness", "RiseTotal"], "SLAB", "RP", (6000, 3000, 200, 1000)),
    (26, "FTG-ISO", "Isolated Footing", "FOOTING", "S-FTG", "S-TEXT", P_FTG, "FOOTING", "F", (1800, 1800, 450)),
    (27, "FTG-COMB", "Combined Footing", "FOOTING", "S-FTG", "S-TEXT", P_FTG, "FOOTING", "CF", (4500, 1800, 500)),
    (28, "FTG-STRAP", "Strap Footing", "FOOTING", "S-FTG", "S-TEXT", P_FTG, "FOOTING", "SF", (5000, 1500, 500)),
    (29, "RAFT", "Raft Footing", "FOOTING", "S-FTG", "S-TEXT", P_FTG, "FOOTING", "RF", (15000, 12000, 600)),
    (30, "PILE", "Pile", "PILE", "S-PILE", "S-TEXT", ["Diameter", "Length"], "FOOTING", "P", (500, 18000)),
    (31, "PCAP", "Pile Cap", "PILECAP", "S-PILECAP", "S-TEXT", ["Length", "Width", "Thickness", "Piles"], "FOOTING", "PC", (1800, 1800, 900, 4)),
    (32, "FTG-STRIP", "Strip Footing", "FOOTING", "S-FTG", "S-TEXT", P_FTG, "FOOTING", "STF", (6000, 900, 300)),
    (33, "FTG-WALL", "Wall Footing", "FOOTING", "S-FTG", "S-TEXT", P_FTG, "FOOTING", "WF", (6000, 750, 250)),
    (34, "SW", "Shear Wall", "WALL", "S-SW", "S-TEXT", ["Length", "Thickness", "Height"], "WALL", "SW", (3000, 250, 3000)),
    (35, "RW", "Retaining Wall", "WALL", "S-RWALL", "S-TEXT", ["Length", "Thickness", "Height"], "WALL", "RW", (6000, 250, 3000)),
    (36, "TANK", "Water Tank", "TANK", "S-TANK", "S-TEXT", ["Length", "Width", "WallThickness", "Depth"], "TANK", "WT", (3000, 2500, 200, 2000)),
    (37, "TANK-UG", "Underground Tank", "TANK", "S-TANK", "S-TEXT", ["Length", "Width", "WallThickness", "Depth"], "TANK", "UGT", (4000, 3000, 250, 2500)),
    (38, "TANK-ROOF", "Roof Tank", "TANK", "S-TANK", "S-TEXT", ["Length", "Width", "WallThickness", "Depth"], "TANK", "RT", (2500, 2000, 150, 1500)),
    (39, "PARAPET", "Parapet", "WALL", "S-ROOF", "S-TEXT", ["Length", "Thickness", "Height"], "WALL", "PW", (6000, 125, 1000)),
    (40, "PED", "Pedestal", "RECT", "S-FTG", "S-TEXT", P_COL, "COLUMN", "PD", (500, 500, 600)),
    (41, "PLINTH", "Plinth", "SLAB", "S-FTG", "S-TEXT", P_SLAB, "NONE", "PL", (10000, 8000, 150)),
    (42, "CORBEL", "Corbel", "RECT", "S-BEAM", "S-BEAM-TEXT", ["Width", "Projection", "Depth"], "BEAM", "CB", (300, 400, 500)),
    (43, "OPEN", "Structural Opening", "OPENING", "S-SLAB-OPEN", "S-TEXT", ["Length", "Width"], "NONE", "OP", (1000, 1000)),
    (44, "EJ", "Expansion Joint", "JOINT", "S-JOINT", "S-TEXT", ["Length", "Gap"], "NONE", "EJ", (10000, 25)),
    (45, "CJ", "Construction Joint", "JOINT", "S-JOINT", "S-TEXT", ["Length", "Gap"], "NONE", "CJ", (10000, 0)),
    (46, "STARTER", "Column Starter", "STARTER", "S-COL", "S-COL-TEXT", ["Width", "Depth", "Height"], "COLUMN", "CS", (300, 300, 75)),
    (47, "BCJ", "Beam-Column Joint", "JOINTBC", "S-DETAIL", "S-TEXT", ["Width", "Depth"], "NONE", "BCJ", (300, 300)),
    (48, "WAIST", "Stair Waist Slab", "SLAB", "S-STAIR", "S-TEXT", P_SLAB, "STAIR", "WS", (3500, 1200, 150)),
    (49, "FTIE", "Foundation Tie", "BEAM", "S-BEAM", "S-BEAM-TEXT", P_BEAM, "BEAM", "FT", (250, 400, 5000)),
    (50, "GB", "Ground Beam", "BEAM", "S-BEAM", "S-BEAM-TEXT", P_BEAM, "BEAM", "GB", (250, 450, 5000)),
    (51, "GRB", "Grade Beam", "BEAM", "S-BEAM", "S-BEAM-TEXT", P_BEAM, "BEAM", "GRB", (300, 600, 5000)),
    (52, "CORE", "Lift Core", "CORE", "S-SW", "S-TEXT", ["Length", "Width", "Thickness", "DoorWidth"], "WALL", "LC", (2400, 2400, 200, 1000)),
    (53, "BWALL", "Boundary Wall", "WALL", "S-RWALL", "S-TEXT", ["Length", "Thickness", "Height"], "WALL", "BW", (20000, 250, 2100)),
    (54, "CANOPY", "Canopy", "SLAB", "S-SLAB", "S-TEXT", P_SLAB, "SLAB", "CN", (3000, 1200, 125)),
    (55, "SLB-ROOF", "Roof Slab", "SLAB", "S-ROOF", "S-TEXT", P_SLAB, "SLAB", "RS", (5000, 4000, 125)),
]
REBAR_FIELDS = {
    "COLUMN": ["MainBars", "TieDia", "TieSpacing"],
    "BEAM": ["TopBars", "BottomBars", "ExtraBars", "StirrupDia", "StirrupSpacing"],
    "SLAB": ["MainBarsX", "MainBarsY", "TopExtra", "Distribution"],
    "FOOTING": ["BottomX", "BottomY", "TopX", "TopY"],
    "STAIR": ["MainBars", "Distribution"],
    "WALL": ["VerticalBars", "HorizontalBars", "Links"],
    "TANK": ["WallVertical", "WallHorizontal", "BaseBars", "CoverBars"],
    "NONE": [],
}
members = []
for no, code, name, shape, layer, tlayer, params, sched, prefix, defaults in MEM:
    members.append(dict(
        no=no, code=code, name=name, shape=shape, layer=layer, textLayer=tlayer,
        dimLayer="S-DIMS", hatch="RCC" if shape not in ("JOINT", "OPENING", "JOINTBC") else None,
        parameters=[dict(name=p, unit="mm" if p not in ("Steps", "Piles") else "nos", default=d)
                    for p, d in zip(params, defaults)],
        schedule=sched, markPrefix=prefix, concreteGradeDefault="C25",
        rebarFields=REBAR_FIELDS[sched], dimensionBehavior="ALIGNED_OVERALL" if shape in ("RECT", "SLAB", "FOOTING", "PILECAP", "TANK", "CORE") else ("LENGTH_ONLY" if shape in ("BEAM", "WALL", "JOINT", "RAMP") else "DIAMETER" if shape in ("CIRCLE", "PILE") else "NONE"),
        block=f"RNR_{code.replace('-', '_')}",
    ))

# --------------------------------------------------------------------------
# HATCHES (20)  predefined AutoCAD patterns where suitable, custom RNR_* PATs otherwise
# --------------------------------------------------------------------------
HATCHES = [
    ("Concrete", "STRUCTURE", "AR-CONC", 1.0, 0, "HATC-CONCRETE"),
    ("RCC", "STRUCTURE", "RNR_RCC", 10.0, 0, "HATC-RCC"),
    ("Brick", "ARCHITECTURE", "RNR_BRICK", 10.0, 0, "HATC-BRICK"),
    ("Block", "ARCHITECTURE", "AR-B816", 1.0, 0, "HATC-CONCRETE"),
    ("Stone", "ARCHITECTURE", "RNR_STONE", 10.0, 0, "HATC-STONE"),
    ("Granite", "ARCHITECTURE", "AR-SAND", 1.0, 0, "HATC-STONE"),
    ("Marble", "ARCHITECTURE", "RNR_MARBLE", 10.0, 0, "HATC-STONE"),
    ("Tile", "ARCHITECTURE", "RNR_TILE", 1.0, 0, "HATC-TILE"),
    ("Wood", "ARCHITECTURE", "RNR_WOOD", 10.0, 0, "HATC-WOOD"),
    ("Timber", "ARCHITECTURE", "RNR_TIMBER", 10.0, 0, "HATC-WOOD"),
    ("Sand", "CIVIL", "AR-SAND", 1.0, 0, "HATC-SAND"),
    ("Soil", "CIVIL", "RNR_SOIL", 10.0, 0, "HATC-EARTH"),
    ("Earth", "CIVIL", "EARTH", 20.0, 45, "HATC-EARTH"),
    ("Water", "CIVIL", "RNR_WATER", 10.0, 0, "HATC-WATER"),
    ("Grass", "LANDSCAPE", "GRASS", 10.0, 0, "HATC-GRASS"),
    ("Glass", "ARCHITECTURE", "RNR_GLASS", 10.0, 45, "HATC-GLASS"),
    ("Metal", "STRUCTURE", "ANSI32", 10.0, 0, "HATC-METAL"),
    ("Steel", "STRUCTURE", "STEEL", 10.0, 0, "HATC-METAL"),
    ("Aluminium", "ARCHITECTURE", "ANSI33", 10.0, 0, "HATC-METAL"),
    ("Insulation", "ARCHITECTURE", "RNR_INSUL", 10.0, 0, "HATC-INSULATION"),
]
hatches = [dict(name=n, category=cat, pattern=pat, custom=pat.startswith("RNR_"), scale=sc, angle=ang,
                colorId=cid, rgb=C[cid]["rgb"], transparency=C[cid]["transparency"], layerHint="A-HATCH" if cat != "STRUCTURE" else "S-HATCH",
                patFile=f"{pat}.pat" if pat.startswith("RNR_") else None)
           for n, cat, pat, sc, ang, cid in HATCHES]

# Custom PAT definitions (unit = drawing unit at scale 1; scale set above)
# Format per line family: angle, x-origin,y-origin, delta-x,delta-y [,dash...]
PATS = {
    "RNR_RCC": ["45, 0,0, 0,3.175", "45, 1.5875,0, 0,3.175, 1.5875,-1.5875"],
    "RNR_BRICK": ["0, 0,0, 0,6.35", "90, 0,0, 6.35,6.35, 6.35,-6.35"],
    "RNR_STONE": ["0, 0,0, 0,12.7, 12.7,-12.7", "90, 0,0, 12.7,12.7, 12.7,-12.7", "45, 0,0, 0,8.98, 4,-4"],
    "RNR_MARBLE": ["30, 0,0, 3,10, 12,-4, 2,-6", "120, 2,1, 5,11, 8,-9"],
    "RNR_TILE": ["0, 0,0, 0,300", "90, 0,0, 0,300"],
    "RNR_WOOD": ["0, 0,0, 0,2, 20,-3, 8,-2", "0, 6,1, 0,2, 3,-12"],
    "RNR_TIMBER": ["45, 0,0, 0,3", "135, 0,0, 0,12"],
    "RNR_SOIL": ["0, 0,0, 0,6, 1.5,-4.5", "90, 0,0, 0,6, 1.5,-4.5", "45, 3,3, 0,8.485, 1.2,-7.285"],
    "RNR_WATER": ["0, 0,0, 3,6, 8,-4", "0, 5,2, 3,6, 4,-8"],
    "RNR_GLASS": ["45, 0,0, 0,8, 4,-4", "45, 1,0, 0,8, 2,-6"],
    "RNR_INSUL": ["0, 0,0, 0,10", "60, 0,0, 10,17.32, 11.547,-8.453", "120, 0,0, 10,17.32, 11.547,-8.453"],
}

LINETYPES = {
    "RNR_GRID": ("Grid line ____ _ ____ _", "A,12.7,-3.175,1.5875,-3.175"),
    "RNR_HIDDEN": ("Hidden __ __ __", "A,6.35,-3.175"),
    "RNR_DEMO": ("Demolition _ _ _ _", "A,3.175,-3.175"),
    "RNR_BOUNDARY": ("Boundary ____ _ _ ____", "A,19.05,-3.175,1.5875,-3.175,1.5875,-3.175"),
    "RNR_JOINT": ("Joint __ . __ .", "A,9.525,-2.38,0,-2.38"),
    "RNR_UTILITY": ("Utility ___ . . ___", "A,12.7,-2.38,0,-2.38,0,-2.38"),
    "RNR_WATER": ("Water supply ___ __ ___", "A,12.7,-2.38,6.35,-2.38"),
}

# --------------------------------------------------------------------------
# BLOCKS
# --------------------------------------------------------------------------
BLOCKS = [
    ("RNR_DOOR", "Doors", "A-DOOR", True, ["Width:Stretch:600,700,750,800,900,1000,1200", "Flip:Flip", "Hinge:Flip", "Type:Visibility:Single,Double,Sliding"]),
    ("RNR_WINDOW", "Windows", "A-WINDOW", True, ["Width:Stretch:600,900,1200,1500,1800,2400", "WallThk:Stretch:125,250", "Type:Visibility:Sliding,Casement,Fixed"]),
    ("RNR_BED_DOUBLE", "Furniture", "A-FURN", True, ["Size:Lookup:Single 1000x2000,Double 1500x2000,King 1800x2000"]),
    ("RNR_SOFA", "Furniture", "A-FURN", True, ["Seats:Array:1,2,3"]),
    ("RNR_DINING", "Furniture", "A-FURN", True, ["Chairs:Visibility:4,6,8"]),
    ("RNR_CHAIR", "Furniture", "A-FURN", False, []),
    ("RNR_KITCHEN_COUNTER", "Kitchen", "A-FIXTURE", True, ["Length:Stretch:1200-4800"]),
    ("RNR_SINK", "Kitchen", "A-FIXTURE", False, []),
    ("RNR_TOILET", "Bathroom", "A-FIXTURE", True, ["Type:Visibility:Commode,Asian Pan"]),
    ("RNR_BASIN", "Bathroom", "A-FIXTURE", False, []),
    ("RNR_SHOWER", "Bathroom", "A-FIXTURE", False, []),
    ("RNR_BATHTUB", "Bathroom", "A-FIXTURE", False, []),
    ("RNR_WARDROBE", "Furniture", "A-FURN", True, ["Length:Stretch:900-2400"]),
    ("RNR_TV", "Furniture", "A-FURN", False, []),
    ("RNR_DESK", "Furniture", "A-FURN", True, ["Length:Stretch:1000-1800"]),
    ("RNR_CAR", "Site", "C-SITE", True, ["Rotation:Rotate"]),
    ("RNR_TREE", "Landscape", "C-TREE", True, ["Diameter:Scale:2000-8000"]),
    ("RNR_PLANT", "Landscape", "C-TREE", False, []),
    ("RNR_LIGHT", "Electrical", "E-LIGHT", False, []),
    ("RNR_FAN", "Electrical", "E-POWER", False, []),
    ("RNR_AC", "HVAC", "M-EQUIP", False, []),
    ("RNR_LIFT", "Vertical transport", "A-STAIR", True, ["Car:Stretch:1400-2100"]),
    ("RNR_STAIR_ARROW", "Stair", "A-STAIR", False, []),
    ("RNR_NORTH", "Annotation", "ANNO-NORTH", True, ["Rotation:Rotate"]),
    ("RNR_GRIDBUBBLE", "Annotation", "ANNO-GRID", False, []),
    ("RNR_LEVEL", "Annotation", "ANNO-LEVEL", False, []),
    ("RNR_SECTIONMARK", "Annotation", "ANNO-SECTION", False, []),
    ("RNR_DETAILMARK", "Annotation", "ANNO-DETAIL", False, []),
    ("RNR_ELEVMARK", "Annotation", "ANNO-SECTION", False, []),
]
blocks = [dict(name=n, category=c, layer=l, dynamic=d,
               parameters=[dict(zip(("name", "action", "values"), (p.split(":") + [""])[:3])) for p in ps],
               source="Generated by RNRBLOCKS (Blocks.BlockFactory) or Blocks/RNR_Blocks.dxf")
          for n, c, l, d, ps in BLOCKS]

STYLES = dict(
    textStyles=[
        dict(name="RNR_TITLE", font="arial.ttf", height=0, widthFactor=1.0, annotative=True, paperHeight=5.0),
        dict(name="RNR_HEADING", font="arial.ttf", height=0, widthFactor=1.0, annotative=True, paperHeight=3.5),
        dict(name="RNR_TEXT", font="arial.ttf", height=0, widthFactor=0.9, annotative=True, paperHeight=2.5),
        dict(name="RNR_NOTE", font="arialn.ttf", height=0, widthFactor=1.0, annotative=True, paperHeight=2.0),
        dict(name="RNR_ROMANS", font="romans.shx", height=0, widthFactor=0.8, annotative=True, paperHeight=2.5),
    ],
    dimStyles=[
        dict(name="RNR_ARCH", textStyle="RNR_TEXT", textHeight=2.5, arrow="_ARCHTICK", arrowSize=1.5, extOffset=1.5, extBeyond=1.25, decimals=0, layer="A-DIMS"),
        dict(name="RNR_STRUCT", textStyle="RNR_TEXT", textHeight=2.5, arrow="_OBLIQUE", arrowSize=1.5, extOffset=1.5, extBeyond=1.25, decimals=0, layer="S-DIMS"),
        dict(name="RNR_CIVIL", textStyle="RNR_TEXT", textHeight=2.5, arrow="", arrowSize=2.0, extOffset=1.5, extBeyond=1.25, decimals=2, layer="ANNO-DIMS"),
    ],
    mleaderStyles=[dict(name="RNR_LEADER", textStyle="RNR_TEXT", textHeight=2.5, arrowSize=2.0, landingGap=1.0)],
    annotationScales=["1:1", "1:5", "1:10", "1:20", "1:25", "1:50", "1:75", "1:100", "1:150", "1:200", "1:500"],
    sheets={"A0": [1189, 841], "A1": [841, 594], "A2": [594, 420], "A3": [420, 297], "A4": [297, 210]},
    titleBlocks=["ARCHITECTURAL", "STRUCTURAL", "RCC", "CIVIL"],
    titleFields=["PROJECT", "CLIENT", "CONSULTANT", "DWGTITLE", "DWGNO", "REV", "DATE", "SCALE", "DRAWN", "CHECKED", "APPROVED", "SHEET"],
)

# Unit weight of steel bar kg/m = d^2/162.2 (d in mm), rounded 3 dp; steel density 7850 kg/m3
REBAR = dict(
    note="Unit weights = d^2/162.2 kg/m (steel density 7850 kg/m3). Laps, anchorage, bend deductions and cover are PROJECT INPUTS and must be verified by the responsible engineer against BNBC 2020 / ACI 318-19.",
    bars=[dict(mark=f"T{d}", diameter=d, unitWeight=round(d * d / 162.2, 3)) for d in (8, 10, 12, 16, 20, 25, 32)],
    shapeCodes=[
        dict(code="00", description="Straight", formula="A"),
        dict(code="11", description="Single 90 deg bend (L-bar)", formula="A+B-0.5r-d"),
        dict(code="21", description="U-bar", formula="A+B+C-r-2d"),
        dict(code="51", description="Closed link / stirrup", formula="2(A+B)+20d"),
        dict(code="41", description="Cranked bar", formula="A+B+C"),
        dict(code="99", description="Special - user defined", formula="USER"),
    ],
)

PROJECT = dict(
    schema="RooMNRooF.Project/1.0",
    projectName="New Project", client="", consultant="", location="Dhaka, Bangladesh",
    units=dict(length="mm", area="m2", volume="m3", force="kN", stress="MPa", mass="kg"),
    standards=dict(references=["BNBC 2020", "ACI 318-19", "ASCE 7"], note="Reference metadata only. No automatic code-compliance is claimed."),
    colorTheme="RNR_DEFAULT", layerStandard="RNR_Layers.json", textStandard="RNR_TEXT",
    dimensionStandard="RNR_STRUCT", titleBlock="STRUCTURAL", sheetSize="A1", drawingScale="1:100",
    engineering=dict(
        concreteGrade="C25", fckMPa=None, fyMPa=None, clearCoverSlabMm=None, clearCoverBeamMm=None,
        clearCoverColumnMm=None, clearCoverFootingMm=None, lapFactorD=None, anchorageFactorD=None,
        comment="Design values are intentionally null: they must be entered per project by the responsible engineer."),
    boq=dict(areaUnits=["SQM", "SFT"], volumeUnits=["CBM", "CFT"], lengthUnits=["RFT", "M"], massUnits=["KG", "TON"]),
    plot=dict(colorCtb="acad.ctb", monoCtb="monochrome.ctb", grayCtb="grayscale.ctb", device="DWG To PDF.pc3"),
)


def write_json(name, data):
    with open(os.path.join(STD, name), "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)
        f.write("\n")


def main():
    os.makedirs(STD, exist_ok=True)
    os.makedirs(HAT, exist_ok=True)
    write_json("RNR_Colors.json", dict(schema="RooMNRooF.Colors/1.0", palette="RNR_DEFAULT", colors=list(C.values())))
    write_json("RNR_Layers.json", dict(schema="RooMNRooF.Layers/1.0", layers=L))
    write_json("RNR_LayerFilters.json", dict(schema="RooMNRooF.Filters/1.0", filters=FILTERS))
    write_json("RNR_Members.json", dict(schema="RooMNRooF.Members/1.0",
               disclaimer="Drafting definitions only - not structural design.", members=members))
    write_json("RNR_Hatches.json", dict(schema="RooMNRooF.Hatches/1.0", hatches=hatches))
    write_json("RNR_Blocks.json", dict(schema="RooMNRooF.Blocks/1.0", blocks=blocks))
    write_json("RNR_Styles.json", dict(schema="RooMNRooF.Styles/1.0", **STYLES))
    write_json("RNR_Rebar.json", dict(schema="RooMNRooF.Rebar/1.0", **REBAR))
    write_json("RooMNRooF_Project.json", PROJECT)

    for name, lines in PATS.items():
        with open(os.path.join(HAT, name + ".pat"), "w", encoding="ascii", newline="\r\n") as f:
            f.write(f"*{name}, RooMNRooF {name[4:].title()} pattern\n")
            for ln in lines:
                f.write(ln + "\n")
    # combined file too (handy for acad.pat-style search path)
    with open(os.path.join(HAT, "RooMNRooF.pat"), "w", encoding="ascii", newline="\r\n") as f:
        f.write(";; RooMNRooF CAD PRO combined hatch patterns\n")
        for name, lines in PATS.items():
            f.write(f"*{name}, RooMNRooF {name[4:].title()} pattern\n")
            for ln in lines:
                f.write(ln + "\n")
    with open(os.path.join(STD, "RooMNRooF.lin"), "w", encoding="ascii", newline="\r\n") as f:
        f.write(";; RooMNRooF CAD PRO linetypes (use LTSCALE/CELTSCALE or annotative MSLTSCALE)\n")
        for name, (desc, pat) in LINETYPES.items():
            f.write(f"*{name},{desc}\n{pat}\n")

    # LISP data tables so AutoLISP works without JSON parsing
    with open(os.path.join(LSP, "RNR_Data.lsp"), "w", encoding="utf-8", newline="\r\n") as f:
        f.write(";;; RNR_Data.lsp  -- GENERATED by Scripts/generate_standards.py. DO NOT EDIT.\n")
        f.write(";;; (name r g b linetype lineweight(mm*100) transparency plot(T/nil) description)\n")
        f.write("(setq *RNR-LAYERS* '(\n")
        for l in L:
            r, g, b = l["rgb"]
            desc = l["description"].replace('"', "'")
            f.write(f'  ("{l["name"]}" {r} {g} {b} "{l["linetype"]}" {int(round(l["lineweight"]*100))} {l["transparency"]} {"T" if l["plot"] else "nil"} "{desc}")\n')
        f.write("))\n")
        f.write("(setq *RNR-FILTERS* '(\n")
        for flt in FILTERS:
            f.write(f'  ("{flt["name"]}" . "{flt["expr"]}")\n')
        f.write("))\n")
        f.write("(setq *RNR-BARS* '(\n")
        for b in REBAR["bars"]:
            f.write(f'  ({b["diameter"]} . {b["unitWeight"]})\n')
        f.write("))\n(princ)\n")

    print(f"colors={len(C)} layers={len(L)} members={len(members)} hatches={len(hatches)} blocks={len(blocks)} pats={len(PATS)} lts={len(LINETYPES)}")


if __name__ == "__main__":
    main()
