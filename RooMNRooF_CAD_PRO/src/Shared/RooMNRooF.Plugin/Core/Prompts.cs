using System.Linq;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.EditorInput;
using Autodesk.AutoCAD.Geometry;

namespace RooMNRooF.Plugin.Core
{
    /// <summary>Prompt helpers: every helper throws <see cref="RnrCancelled"/> on ESC so commands stay linear.</summary>
    public static class Prompts
    {
        public static double Double(Editor ed, string msg, double def, bool allowZero = false, bool allowNegative = false)
        {
            var o = new PromptDoubleOptions("\n" + msg)
            {
                DefaultValue = def, UseDefaultValue = true, AllowZero = allowZero, AllowNegative = allowNegative, AllowNone = true,
            };
            var r = ed.GetDouble(o);
            if (r.Status == PromptStatus.Cancel) throw new RnrCancelled();
            if (r.Status == PromptStatus.None) return def;
            if (r.Status != PromptStatus.OK) throw new RnrInputException(msg);
            return r.Value;
        }

        public static int Int(Editor ed, string msg, int def, int min = 1, int max = int.MaxValue)
        {
            var o = new PromptIntegerOptions("\n" + msg) { DefaultValue = def, UseDefaultValue = true, AllowNone = true, LowerLimit = min, UpperLimit = max };
            var r = ed.GetInteger(o);
            if (r.Status == PromptStatus.Cancel) throw new RnrCancelled();
            if (r.Status == PromptStatus.None) return def;
            if (r.Status != PromptStatus.OK) throw new RnrInputException(msg);
            return r.Value;
        }

        public static string Text(Editor ed, string msg, string def, bool allowSpaces = true)
        {
            var o = new PromptStringOptions($"\n{msg} <{def}>: ") { AllowSpaces = allowSpaces, DefaultValue = def, UseDefaultValue = true };
            var r = ed.GetString(o);
            if (r.Status == PromptStatus.Cancel) throw new RnrCancelled();
            if (r.Status != PromptStatus.OK) throw new RnrInputException(msg);
            return string.IsNullOrWhiteSpace(r.StringResult) ? def : r.StringResult.Trim();
        }

        public static string Keyword(Editor ed, string msg, string def, params string[] keywords)
        {
            var o = new PromptKeywordOptions("\n" + msg) { AllowNone = true };
            foreach (var k in keywords) o.Keywords.Add(k);
            if (keywords.Contains(def)) o.Keywords.Default = def;
            var r = ed.GetKeywords(o);
            if (r.Status == PromptStatus.Cancel) throw new RnrCancelled();
            if (r.Status == PromptStatus.None) return def;
            if (r.Status != PromptStatus.OK) throw new RnrInputException(msg);
            return r.StringResult;
        }

        public static Point3d Point(Editor ed, string msg, Point3d? basePoint = null)
        {
            var o = new PromptPointOptions("\n" + msg);
            if (basePoint.HasValue) { o.UseBasePoint = true; o.BasePoint = basePoint.Value.TransformBy(ed.CurrentUserCoordinateSystem.Inverse()); }
            var r = ed.GetPoint(o);
            if (r.Status == PromptStatus.Cancel) throw new RnrCancelled();
            if (r.Status != PromptStatus.OK) throw new RnrInputException(msg);
            return r.Value.TransformBy(ed.CurrentUserCoordinateSystem);
        }

        /// <summary>Point prompt where ENTER finishes (returns null).</summary>
        public static Point3d? PointOrNone(Editor ed, string msg, Point3d? basePoint = null)
        {
            var o = new PromptPointOptions("\n" + msg) { AllowNone = true };
            if (basePoint.HasValue) { o.UseBasePoint = true; o.BasePoint = basePoint.Value.TransformBy(ed.CurrentUserCoordinateSystem.Inverse()); }
            var r = ed.GetPoint(o);
            if (r.Status == PromptStatus.Cancel) throw new RnrCancelled();
            if (r.Status != PromptStatus.OK) return null;
            return r.Value.TransformBy(ed.CurrentUserCoordinateSystem);
        }

        public static Point3d Corner(Editor ed, string msg, Point3d basePoint)
        {
            var r = ed.GetCorner(new PromptCornerOptions("\n" + msg, basePoint.TransformBy(ed.CurrentUserCoordinateSystem.Inverse())));
            if (r.Status == PromptStatus.Cancel) throw new RnrCancelled();
            if (r.Status != PromptStatus.OK) throw new RnrInputException(msg);
            return r.Value.TransformBy(ed.CurrentUserCoordinateSystem);
        }

        public static double Angle(Editor ed, string msg, Point3d basePoint, double def = 0)
        {
            var o = new PromptAngleOptions("\n" + msg) { UseBasePoint = true, BasePoint = basePoint.TransformBy(ed.CurrentUserCoordinateSystem.Inverse()), AllowNone = true, DefaultValue = def, UseDefaultValue = true };
            var r = ed.GetAngle(o);
            if (r.Status == PromptStatus.Cancel) throw new RnrCancelled();
            if (r.Status == PromptStatus.None) return def;
            return r.Value;
        }

        public static bool YesNo(Editor ed, string msg, bool def)
        {
            return Keyword(ed, msg + " [Yes/No]", def ? "Yes" : "No", "Yes", "No") == "Yes";
        }

        public static ObjectId Entity(Editor ed, string msg, params System.Type[] allowed)
        {
            var o = new PromptEntityOptions("\n" + msg);
            if (allowed.Length > 0)
            {
                o.SetRejectMessage("\nWrong object type.");
                foreach (var t in allowed) o.AddAllowedClass(t, false);
            }
            var r = ed.GetEntity(o);
            if (r.Status == PromptStatus.Cancel) throw new RnrCancelled();
            if (r.Status != PromptStatus.OK) throw new RnrInputException(msg);
            return r.ObjectId;
        }

        public static ObjectId[] Selection(Editor ed, string msg, SelectionFilter? filter = null)
        {
            var o = new PromptSelectionOptions { MessageForAdding = "\n" + msg };
            var r = filter == null ? ed.GetSelection(o) : ed.GetSelection(o, filter);
            if (r.Status == PromptStatus.Cancel) throw new RnrCancelled();
            if (r.Status != PromptStatus.OK) return new ObjectId[0];
            return r.Value.GetObjectIds();
        }

        /// <summary>Reinforcement prompt with immediate notation validation (loops until valid or ESC).</summary>
        public static string Rebar(Editor ed, string msg, string def)
        {
            while (true)
            {
                var s = Text(ed, msg, def);
                if (s == "-" || RooMNRooF.Core.Rebar.RebarNotation.TryParse(s, out _, out var err)) return s;
                ed.WriteMessage("\n" + Rnr.Prefix + err);
            }
        }
    }
}
