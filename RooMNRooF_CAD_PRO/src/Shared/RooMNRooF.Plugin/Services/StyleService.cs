using System;
using System.IO;
using System.Linq;
using Autodesk.AutoCAD.DatabaseServices;
using RooMNRooF.Core.Logging;
using RooMNRooF.Core.Models;
using RooMNRooF.Plugin.Core;

namespace RooMNRooF.Plugin.Services
{
    public static class StyleService
    {
        public static string LinFile => Path.Combine(Rnr.StandardsDir, "RooMNRooF.lin");

        /// <summary>Returns linetype id; loads RNR_* from RooMNRooF.lin or others from acadiso.lin. Falls back to Continuous.</summary>
        public static ObjectId EnsureLinetype(Database db, Transaction tr, string name)
        {
            var ltt = (LinetypeTable)tr.GetObject(db.LinetypeTableId, OpenMode.ForRead);
            if (ltt.Has(name)) return ltt[name];
            try
            {
                string file = name.StartsWith("RNR_", StringComparison.OrdinalIgnoreCase) ? LinFile : "acadiso.lin";
                db.LoadLineTypeFile(name, file);
                ltt = (LinetypeTable)tr.GetObject(db.LinetypeTableId, OpenMode.ForRead);
                if (ltt.Has(name)) return ltt[name];
            }
            catch (System.Exception ex)
            {
                RnrLog.Warn($"Linetype {name} could not be loaded: {ex.Message}");
            }
            Rnr.Msg($"Linetype {name} unavailable - Continuous used.");
            return ltt["Continuous"];
        }

        public static void LoadAllLinetypes(Database db, Transaction tr)
        {
            foreach (var n in Rnr.Repo.Layers.Layers.Select(l => l.Linetype).Distinct(StringComparer.OrdinalIgnoreCase))
                EnsureLinetype(db, tr, n);
            foreach (var n in new[] { "CENTER", "HIDDEN", "DASHED", "PHANTOM" }) EnsureLinetype(db, tr, n);
        }

        public static ObjectId EnsureTextStyle(Database db, Transaction tr, TextStyleDef def)
        {
            var tst = (TextStyleTable)tr.GetObject(db.TextStyleTableId, OpenMode.ForRead);
            TextStyleTableRecord rec;
            if (tst.Has(def.Name)) rec = (TextStyleTableRecord)tr.GetObject(tst[def.Name], OpenMode.ForWrite);
            else
            {
                rec = new TextStyleTableRecord { Name = def.Name };
                tst.UpgradeOpen();
                tst.Add(rec);
                tr.AddNewlyCreatedDBObject(rec, true);
            }
            rec.FileName = def.Font;
            rec.TextSize = def.Height;           // 0 = height asked at creation (annotative text uses paper height)
            rec.XScale = def.WidthFactor;
            rec.Annotative = def.Annotative ? AnnotativeStates.True : AnnotativeStates.False;
            rec.SetPaperOrientation(def.Annotative);
            return rec.ObjectId;
        }

        public static ObjectId TextStyleId(Database db, Transaction tr, string name)
        {
            var tst = (TextStyleTable)tr.GetObject(db.TextStyleTableId, OpenMode.ForRead);
            if (tst.Has(name)) return tst[name];
            var def = Rnr.Repo.Styles.TextStyles.FirstOrDefault(t => t.Name == name);
            return def != null ? EnsureTextStyle(db, tr, def) : db.Textstyle;
        }

        public static ObjectId EnsureDimStyle(Database db, Transaction tr, DimStyleDef def)
        {
            var dst = (DimStyleTable)tr.GetObject(db.DimStyleTableId, OpenMode.ForRead);
            DimStyleTableRecord rec;
            if (dst.Has(def.Name)) rec = (DimStyleTableRecord)tr.GetObject(dst[def.Name], OpenMode.ForWrite);
            else
            {
                rec = new DimStyleTableRecord { Name = def.Name };
                dst.UpgradeOpen();
                dst.Add(rec);
                tr.AddNewlyCreatedDBObject(rec, true);
            }
            rec.Dimtxsty = TextStyleId(db, tr, def.TextStyle);
            rec.Dimtxt = def.TextHeight;
            rec.Dimasz = def.ArrowSize;
            // Architectural/structural convention: oblique ticks via DIMTSZ (no arrow block dependency)
            rec.Dimtsz = string.IsNullOrEmpty(def.Arrow) ? 0 : def.ArrowSize;
            rec.Dimexo = def.ExtOffset;
            rec.Dimexe = def.ExtBeyond;
            rec.Dimdec = def.Decimals;
            rec.Dimgap = 0.8;
            rec.Dimtad = 1;       // text above line
            rec.Dimtih = false;
            rec.Dimtoh = false;
            rec.Dimlunit = 2;     // decimal
            rec.Dimzin = 8;       // suppress trailing zeros
            rec.Dimclrd = Autodesk.AutoCAD.Colors.Color.FromColorIndex(Autodesk.AutoCAD.Colors.ColorMethod.ByLayer, 256);
            rec.Dimclre = Autodesk.AutoCAD.Colors.Color.FromColorIndex(Autodesk.AutoCAD.Colors.ColorMethod.ByLayer, 256);
            rec.Dimclrt = Autodesk.AutoCAD.Colors.Color.FromColorIndex(Autodesk.AutoCAD.Colors.ColorMethod.ByLayer, 256);
            rec.Annotative = AnnotativeStates.True;
            return rec.ObjectId;
        }

        public static ObjectId DimStyleId(Database db, Transaction tr, string name)
        {
            var dst = (DimStyleTable)tr.GetObject(db.DimStyleTableId, OpenMode.ForRead);
            if (dst.Has(name)) return dst[name];
            var def = Rnr.Repo.Styles.DimStyles.FirstOrDefault(d => d.Name == name);
            return def != null ? EnsureDimStyle(db, tr, def) : db.Dimstyle;
        }

        public static ObjectId EnsureMLeaderStyle(Database db, Transaction tr, MLeaderStyleDef def)
        {
            var dict = (DBDictionary)tr.GetObject(db.MLeaderStyleDictionaryId, OpenMode.ForRead);
            if (dict.Contains(def.Name)) return dict.GetAt(def.Name);
            var style = new MLeaderStyle
            {
                TextStyleId = TextStyleId(db, tr, def.TextStyle),
                TextHeight = def.TextHeight,
                ArrowSize = def.ArrowSize,
                LandingGap = def.LandingGap,
                Annotative = AnnotativeStates.True,
            };
            var id = style.PostMLeaderStyleToDb(db, def.Name);
            tr.AddNewlyCreatedDBObject(style, true);
            return id;
        }

        /// <summary>Adds the RooMNRooF annotation scales if not present (ObjectContextManager).</summary>
        public static int EnsureAnnotationScales(Database db)
        {
            var ocm = db.ObjectContextManager;
            var occ = ocm.GetContextCollection("ACDB_ANNOTATIONSCALES");
            int n = 0;
            foreach (var s in Rnr.Repo.Styles.AnnotationScales)
            {
                var name = s;
                if (occ.HasContext(name)) continue;
                var parts = s.Split(':');
                if (parts.Length != 2 || !double.TryParse(parts[0], out var paper) || !double.TryParse(parts[1], out var drawing)) continue;
                var sc = new AnnotationScale { Name = name, PaperUnits = paper, DrawingUnits = drawing };
                occ.AddContext(sc);
                n++;
            }
            return n;
        }

        /// <summary>Applies every text/dim/mleader style, linetypes and annotation scales.</summary>
        public static void ApplyAll(Database db, Transaction tr)
        {
            LoadAllLinetypes(db, tr);
            foreach (var t in Rnr.Repo.Styles.TextStyles) EnsureTextStyle(db, tr, t);
            foreach (var d in Rnr.Repo.Styles.DimStyles) EnsureDimStyle(db, tr, d);
            foreach (var m in Rnr.Repo.Styles.MleaderStyles) EnsureMLeaderStyle(db, tr, m);
            EnsureAnnotationScales(db);
        }

        /// <summary>Sets metric drafting units (explicit user action only - never silent).</summary>
        public static void SetMetricUnits(Database db)
        {
            db.Insunits = UnitsValue.Millimeters;
            db.Lunits = 2;
            db.Luprec = 0;
            db.Measurement = MeasurementValue.Metric;
            db.Ltscale = 1;
            db.Psltscale = true;
            db.Msltscale = true;
        }
    }
}
