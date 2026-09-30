#!/usr/bin/env python3
"""
Starter drawing templates as DXF (Templates/RNR_<KIND>_Starter.dxf) mirroring TemplateService.Kinds:
layers (filtered per discipline), linetypes, text/dim styles, units (mm), LTSCALE, an A1 paper-space
layout with the RooMNRooF title block and one scaled viewport.

These are DXF STARTER FILES, not .dwt. Use them by opening + SAVEAS "AutoCAD Drawing Template (*.dwt)",
or run RNRTEMPLATE (C# plugin) which writes native .dwt for the running AutoCAD version.
"""
import fnmatch
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rnr_dxf  # noqa: E402
from rnr_dxf import ROOT, STYLES, Pen, new_doc  # noqa: E402

FILTERS = {f["name"]: f["expr"] for f in json.load(open(os.path.join(ROOT, "Standards", "RNR_LayerFilters.json")))["filters"]}

# kind: (filters, sheet, discipline title, dimstyle, scale)  -- keep in sync with TemplateService.Kinds
KINDS = {
    "MASTER": (["ALL"], "A1", "STRUCTURAL", "RNR_STRUCT", 100),
    "ARCHITECTURAL": (["ARCHITECTURE", "ANNOTATION", "REFERENCE", "MEP"], "A1", "ARCHITECTURAL", "RNR_ARCH", 100),
    "STRUCTURAL": (["STRUCTURE", "ANNOTATION", "REFERENCE"], "A1", "STRUCTURAL", "RNR_STRUCT", 100),
    "RCC": (["STRUCTURE", "ANNOTATION", "REFERENCE"], "A1", "RCC DETAILS", "RNR_STRUCT", 25),
    "CIVIL": (["CIVIL", "ANNOTATION", "REFERENCE"], "A1", "CIVIL", "RNR_CIVIL", 200),
    "SITE": (["SITE", "ANNOTATION", "REFERENCE", "MEP"], "A1", "SITE", "RNR_CIVIL", 500),
    "MEP": (["MEP", "ANNOTATION", "REFERENCE"], "A1", "MEP", "RNR_ARCH", 100),
}


def layer_ok(name, filters):
    if "ALL" in filters or name in ("0", "Defpoints"):
        return True
    for f in filters:
        expr = FILTERS.get(f)
        if expr is None or expr == "*":
            return True
        if any(fnmatch.fnmatchcase(name, e.strip()) for e in expr.split(",")):
            return True
    return False


def build(kind):
    filters, sheet, disc, dim, scale = KINDS[kind]
    doc = new_doc(ltscale=1.0)          # paper-space linetype scaling handles model scale
    doc.header["$PSLTSCALE"] = 1
    doc.header["$DIMSTYLE"] = dim
    doc.header["$TEXTSTYLE"] = "RNR_TEXT"
    doc.header["$CELTSCALE"] = 1.0
    keep_z = {"Z-VPORT", "Z-CONST"}
    for lay in list(doc.layers):
        n = lay.dxf.name
        if n.startswith(("A-", "S-", "C-", "P-", "E-", "M-", "ANNO-", "XREF", "Z-")) and not (
                layer_ok(n, filters) or n in keep_z or n.startswith("ANNO-")):
            doc.layers.remove(n)
    for d in doc.dimstyles:
        d.dxf.dimscale = scale
    doc.header["$CLAYER"] = "0"

    # paper-space layout with title block + viewport
    sw, sh = STYLES["sheets"][sheet]
    lay = doc.layouts.new(f"{sheet}-{kind}")
    for name in list(doc.layouts.names()):
        if name not in ("Model", f"{sheet}-{kind}"):
            doc.layouts.delete(name)
    lay.page_setup(size=(sw, sh), margins=(0, 0, 0, 0), units="mm", device="DWG To PDF.pc3")
    p = Pen(doc, msp=lay, scale=1.0)
    x0, y0, w, h = p.title_block(0, 0, sheet, f"{kind} DRAWING TITLE", f"{kind[:1]}-000", f"1:{scale}", disc,
                                   project=("<PROJECT NAME>", "<CLIENT>", "<CONSULTANT>"))
    vw, vh = w, h
    cx, cy = x0 + vw / 2, y0 + vh / 2
    vp = lay.add_viewport(center=(cx, cy), size=(vw, vh), view_center_point=(vw * scale / 2, vh * scale / 2),
                          view_height=vh * scale, dxfattribs={"layer": "Z-VPORT"})
    vp.dxf.status = 2
    p.text(f"VIEWPORT 1:{scale}", (x0 + 2, y0 + 2), 2.0, "Z-VPORT", align="LEFT")
    # model-space origin marker on non-plot layer to help first zoom
    doc.modelspace().add_text(f"RooMNRooF {kind} starter - draw at 1:1 in mm; plot 1:{scale}",
                              height=2.5 * scale, dxfattribs={"layer": "Z-CONST", "style": "RNR_TEXT"})
    path = os.path.join(ROOT, "Templates", f"RNR_{kind}_Starter.dxf")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    doc.saveas(path)
    return doc, path, len([l for l in doc.layers])


def main():
    png = "--no-png" not in sys.argv
    for k in KINDS:
        doc, path, nl = build(k)
        if png:
            import matplotlib
            matplotlib.use("Agg")
            import matplotlib.pyplot as plt
            from ezdxf.addons.drawing import Frontend, RenderContext
            from ezdxf.addons.drawing.config import BackgroundPolicy, Configuration
            from ezdxf.addons.drawing.matplotlib import MatplotlibBackend
            if k == "ARCHITECTURAL":
                fig = plt.figure(figsize=(8.41, 5.94))
                ax = fig.add_axes([0, 0, 1, 1])
                Frontend(RenderContext(doc), MatplotlibBackend(ax),
                         config=Configuration(background_policy=BackgroundPolicy.WHITE)).draw_layout(
                    doc.layouts.get(f"A1-{k}"), finalize=True)
                fig.savefig(os.path.join(ROOT, "Templates", "Starter_layout_preview.png"), dpi=120)
                plt.close(fig)
        print(f"wrote {os.path.relpath(path, ROOT)}  ({nl} layers)")


if __name__ == "__main__":
    main()
