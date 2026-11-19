// Gusseted L-bracket, built in the running Inventor through its COM API.
// Units: Inventor's API uses centimetres.
using System;
using System.Runtime.InteropServices;
using Inventor;

class Bracket
{
    static Application app;
    static TransientGeometry tg;

    // plate thickness, base length, upright height, width, gusset thickness
    const double T = 0.6, L = 8.0, H = 6.0, W = 5.0, G = 0.6;
    const double HoleDia = 0.85;   // M8 clearance

    static void Main(string[] args)
    {
        app = (Application)Marshal.GetActiveObject("Inventor.Application");
        tg = app.TransientGeometry;
        string outPath = args.Length > 0 ? args[0] : @"D:\Examples\gusset-bracket.ipt";
        foreach (Document d in app.Documents)
            if (string.Equals(d.FullFileName, outPath, StringComparison.OrdinalIgnoreCase)) { d.Close(true); break; }

        var doc = (PartDocument)app.Documents.Add(DocumentTypeEnum.kPartDocumentObject,
            app.FileManager.GetTemplateFile(DocumentTypeEnum.kPartDocumentObject), true);
        var cd = doc.ComponentDefinition;
        var xy = cd.WorkPlanes[3];

        // 1. L-section, extruded symmetric about XY
        var sk = cd.Sketches.Add(xy);
        Polyline(sk, new double[,] { { 0, 0 }, { L, 0 }, { L, T }, { T, T }, { T, H }, { 0, H } });
        var ed = cd.Features.ExtrudeFeatures.CreateExtrudeDefinition(sk.Profiles.AddForSolid(), PartFeatureOperationEnum.kNewBodyOperation);
        ed.SetDistanceExtent(W, PartFeatureExtentDirectionEnum.kSymmetricExtentDirection);
        cd.Features.ExtrudeFeatures.Add(ed);
        Log("L-section");

        // 2. bend radii (inside = T, outside = 2T)
        Fillet(cd, "inside bend", T, e => IsZLine(e, T, T));
        Fillet(cd, "outside bend", 2 * T, e => IsZLine(e, 0, 0));

        // 3. two triangular gussets
        foreach (double z in new[] { -1.7, 1.7 })
        {
            var plane = cd.WorkPlanes.AddByPlaneAndOffset(xy, z);
            plane.Visible = false;
            var gs = cd.Sketches.Add(plane);
            Polyline(gs, new double[,] { { T * 0.9, T * 0.9 }, { 4.6, T * 0.9 }, { T * 0.9, 4.2 } });
            var gd = cd.Features.ExtrudeFeatures.CreateExtrudeDefinition(gs.Profiles.AddForSolid(), PartFeatureOperationEnum.kJoinOperation);
            gd.SetDistanceExtent(G, PartFeatureExtentDirectionEnum.kSymmetricExtentDirection);
            cd.Features.ExtrudeFeatures.Add(gd);
        }
        Log("gussets");

        // 4. mounting holes: two in the base (along Y), two in the upright (along X)
        Holes(cd, cd.WorkPlanes[2], new[] { tg.CreatePoint(6.4, 0, -1.2), tg.CreatePoint(6.4, 0, 1.2) });
        Holes(cd, cd.WorkPlanes[1], new[] { tg.CreatePoint(0, 4.9, -1.2), tg.CreatePoint(0, 4.9, 1.2) });
        Log("holes");

        // 5. round the free corners of both flanges
        Fillet(cd, "flange corners", 0.8, e => IsLineAlong(e, 1) && Near(Math.Abs(e.StartVertex.Point.Z), W / 2) && Near(e.StartVertex.Point.X, L)
                                           || IsLineAlong(e, 0) && Near(Math.Abs(e.StartVertex.Point.Z), W / 2) && Near(e.StartVertex.Point.Y, H));

        try
        {
            foreach (AssetLibrary lib in app.AssetLibraries)
                foreach (Asset m in lib.MaterialAssets)
                    if (m.DisplayName == "Aluminum 6061") { doc.ActiveMaterial = m.CopyTo(doc); goto done; }
            done:;
        }
        catch (Exception ex) { Log("material skipped: " + ex.Message); }

        var cam = app.ActiveView.Camera;
        cam.ViewOrientationType = ViewOrientationTypeEnum.kIsoTopRightViewOrientation;
        cam.Fit(); cam.Apply();
        System.IO.Directory.CreateDirectory(System.IO.Path.GetDirectoryName(outPath));
        doc.SaveAs(outPath, false);
        var mp = cd.MassProperties; var rb = cd.RangeBox;
        Log(string.Format("saved {0}: {1:F0} g, {2:F1} x {3:F1} x {4:F1} mm", outPath, mp.Mass * 1000,
            (rb.MaxPoint.X - rb.MinPoint.X) * 10, (rb.MaxPoint.Y - rb.MinPoint.Y) * 10, (rb.MaxPoint.Z - rb.MinPoint.Z) * 10));
    }

    static void Polyline(PlanarSketch sk, double[,] pts)
    {
        int n = pts.GetLength(0);
        SketchLine first = null, prev = null;
        for (int i = 0; i < n; i++)
        {
            var a = tg.CreatePoint2d(pts[i, 0], pts[i, 1]);
            var b = tg.CreatePoint2d(pts[(i + 1) % n, 0], pts[(i + 1) % n, 1]);
            SketchLine l;
            if (prev == null) l = sk.SketchLines.AddByTwoPoints(a, b);
            else if (i == n - 1) l = sk.SketchLines.AddByTwoPoints(prev.EndSketchPoint, first.StartSketchPoint);
            else l = sk.SketchLines.AddByTwoPoints(prev.EndSketchPoint, b);
            if (first == null) first = l;
            prev = l;
        }
    }

    // Cut through-all holes perpendicular to an origin plane, at model-space points.
    static void Holes(PartComponentDefinition cd, WorkPlane plane, Point[] centres)
    {
        var sk = cd.Sketches.Add(plane);
        foreach (var c in centres) sk.SketchCircles.AddByCenterRadius(sk.ModelToSketchSpace(c), HoleDia / 2);
        var hd = cd.Features.ExtrudeFeatures.CreateExtrudeDefinition(sk.Profiles.AddForSolid(), PartFeatureOperationEnum.kCutOperation);
        hd.SetThroughAllExtent(PartFeatureExtentDirectionEnum.kSymmetricExtentDirection);
        cd.Features.ExtrudeFeatures.Add(hd);
    }

    static bool Near(double a, double b) { return Math.Abs(a - b) < 1e-4; }
    static bool IsLineAlong(Edge e, int axis)
    {
        if (e.GeometryType != CurveTypeEnum.kLineSegmentCurve) return false;
        var p = e.StartVertex.Point; var q = e.StopVertex.Point;
        double[] d = { Math.Abs(q.X - p.X), Math.Abs(q.Y - p.Y), Math.Abs(q.Z - p.Z) };
        return d[axis] > 1e-3 && d[(axis + 1) % 3] < 1e-4 && d[(axis + 2) % 3] < 1e-4;
    }
    static bool IsZLine(Edge e, double x, double y)
    {
        return IsLineAlong(e, 2) && Near(e.StartVertex.Point.X, x) && Near(e.StartVertex.Point.Y, y);
    }
    static void Fillet(PartComponentDefinition cd, string name, double r, Func<Edge, bool> pick)
    {
        var col = app.TransientObjects.CreateEdgeCollection();
        foreach (Edge e in cd.SurfaceBodies[1].Edges) if (pick(e)) col.Add(e);
        try { cd.Features.FilletFeatures.AddSimple(col, r); Log("fillet " + name + " (" + col.Count + " edges)"); }
        catch (Exception ex) { Log("fillet " + name + " FAILED (" + col.Count + " edges): " + ex.Message); }
    }
    static void Log(string s) { Console.WriteLine(s); }
}
