# Automating Inventor on macOS

Inventor's COM API works under Wine exactly as on Windows. These examples are
plain C# compiled by the .NET Framework compiler that the installer already put
in the prefix, so nothing extra has to be installed.

```sh
# Inventor must be running
examples/automation/run.sh Bracket.cs            # builds and saves D:\Examples\gusset-bracket.ipt
examples/automation/run.sh View.cs               # isometric view + zoom to fit
examples/automation/run.sh View.cs top           # top view
```

`D:` is `~/Inventor` on the Mac, so the bracket ends up in
`~/Inventor/Examples/gusset-bracket.ipt`.

## Bracket.cs

An 80 x 60 x 50 mm L-bracket in 6 mm aluminium plate:

1. L-section sketched on the XY plane, extruded 50 mm symmetric
2. bend radii: 6 mm inside, 12 mm outside (edges picked by geometry)
3. two triangular 6 mm gussets on offset work planes
4. four M8 clearance holes (8.5 mm), cut through all; centres are given in
   model space and mapped with `PlanarSketch.ModelToSketchSpace`
5. 8 mm corner rounds on both flanges, material Aluminum 6061, iso view, save

Things worth knowing when writing your own:

- API units are **centimetres**.
- Arcs are stored counter-clockwise: an arc you draw clockwise with
  `AddByThreePoints` has its `StartSketchPoint`/`EndSketchPoint` swapped, so
  connect the next line to the right end (or the profile silently closes with
  straight lines).
- `Marshal.GetActiveObject("Inventor.Application")` works across Wine
  processes (the Running Object Table is served by Wine's rpcss).
- Wine can only see `C:` and `D:` (the prefix is sandboxed), so keep sources
  and outputs there.
