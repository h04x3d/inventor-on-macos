using System; using System.Runtime.InteropServices; using Inventor;
class V { static void Main(string[] a) {
  var app = (Application)Marshal.GetActiveObject("Inventor.Application");
  var cam = app.ActiveView.Camera;
  cam.ViewOrientationType = a.Length > 0 && a[0] == "top" ? ViewOrientationTypeEnum.kTopViewOrientation : ViewOrientationTypeEnum.kIsoTopRightViewOrientation;
  cam.Fit(); cam.Apply(); app.ActiveView.Update(); Console.WriteLine("view set"); } }
