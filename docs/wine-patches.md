# winemac.drv patch

`patches/wine/0001-winemac.drv-inventor-on-macos.patch` applies to stock Wine
11.20 (the winum series doesn't touch `dlls/winemac.drv`). It is LGPL-2.1, like
Wine.

| Area | Files | Problem | Change |
|---|---|---|---|
| DXMT entry points | `dxmt.c` (new), `Makefile.in`, `macdrv.h` | DXMT's `winemetal.so` `dlsym`s `macdrv_functions`; without it: *"Failed to create metal view, it seems like your Wine has no exported symbols needed by DXMT"* – no 3D viewport | Export `macdrv_functions` with DXMT's layout. `get_win_data` returns a shim with the old `{hwnd, cocoa_window, cocoa_view, client_cocoa_view}` layout; the view is a Wine 11 client surface view (the same mechanism Wine's Vulkan/GL use), so child windows such as the viewport are positioned correctly |
| Viewport follows the window | `dxmt.c`, `window.c` | win32u only keeps surfaces it "uses" in sync; DXMT's view stayed at its first size/position and stayed visible on hidden tabs (white or stale areas) | `dxmt_window_pos_changed()` from `macdrv_WindowPosChanged` updates/hides the views of the window and its descendants |
| Blank viewport after resize | `cocoa_window.m` | `newMetalViewWithDevice:` returns the view's *cached* Metal view; DXMT creates a "new" one and releases the "old" one on every swapchain resize, which removed and freed the shared view | DXMT gets ref-counted create/release that never remove the shared view |
| Dragging a self-drawn title bar | `window.c`, `cocoa_window.m` | Inventor sends `SC_MOVE\|HTCLIENT` (`0xF011`); Wine only accepted `HTCAPTION`, and its modal move loop gets no mouse moves on macOS | Accept any mouse `SC_MOVE`; for these windows run `performWindowDragWithEvent:` with the last mouse-down – a native drag, with edge snapping/tiling |
| Native window management | `macdrv_cocoa.h`, `window.c`, `cocoa_window.m` | Windows whose app draws the frame (caption+thickframe, no non-client area) became borderless Cocoa windows: no resizing, tiling, full screen | New `app_drawn_frame` feature → `Titled \| FullSizeContentView \| Resizable`, transparent hidden title bar, hidden traffic lights; full screen allowed even when maximized; `constrainFrameRect` left alone so Wine/macOS don't fight over the maximized rect |
| White line at the top | `surface.c` | Maximized, the app leaves a 5 px border unpainted (off-screen on Windows); the top strip showed under the menu bar | Extend the client's edge pixels over that border when flushing |
| App name | `macdrv_main.c`, `cocoa_app.m`, `macdrv_cocoa.h` | Menu bar/Dock said "wine" | `AppName` Mac Driver setting (per app via `AppDefaults\<exe>\Mac Driver`), default = exe name; sets the process name and LaunchServices display name |

Debug output: set `DXMT_SHIM_DEBUG=1` before launching to log DXMT view
creation/updates, `SC_*` system commands and the edge fill.

## Rebuilding just the driver

```sh
cd ~/inventor-mac/build64
arch -x86_64 make dlls/winemac.drv/all
R=~/inventor-mac/wine/winum-11.20-2-x86_64/lib/wine/x86_64-unix
cp dlls/winemac.drv/winemac.so $R/winemac.so
install_name_tool -add_rpath @loader_path/../../ $R/winemac.so
codesign -fs - $R/winemac.so
```
Quit Inventor (and `wineserver -k`) before replacing it.
