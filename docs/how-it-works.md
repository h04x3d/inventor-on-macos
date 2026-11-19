# How it works

```
 Inventor.exe, ODIS installer, licensing, .NET 4.8, WebView2   (Windows x64 binaries)
        │
 Wine 11.20 + winum patch series (Inventor fixes from the Linux project)
 + inventor-on-macos winemac.drv patch                          (built x86_64)
        │                          │
 winemac.drv (Cocoa windows)   DXMT: Direct3D 11 → Metal (3D viewport)
        │                          │
 Rosetta 2  ───────────────────────┴──►  macOS on Apple Silicon
```

No virtual machine and no Windows desktop: every Inventor window is a native
macOS window, with its own entry in the Dock, menu bar, Mission Control and
window tiling.

## Building blocks

| Piece | Source | Why |
|---|---|---|
| Wine 11.20 | winehq.org | Windows API on macOS |
| [winum](https://github.com/Harvi654/winum) patch series | Harvi654 | 66 Wine fixes found while getting Inventor working on Linux |
| Runtime libraries | [Gcenx macOS Wine builds](https://github.com/Gcenx/macOS_Wine_builds) | prebuilt freetype, gnutls, MoltenVK, wine-mono, wine-gecko for macOS |
| [DXMT](https://github.com/3Shain/dxmt) v0.80 | 3Shain | Direct3D 11 on Metal – Inventor's viewport |
| [Autodesk-Inventor-for-Linux](https://github.com/Harvi654/Autodesk-Inventor-for-Linux) | Harvi654 & contributors | offline ODIS install, .NET, WebView2, licensing services, launcher |
| this repository | | macOS build, winemac.drv patch, macOS glue for the Linux scripts, app bundle |

Wine is built for x86_64 and runs under Rosetta 2. The Linux project's scripts
run unchanged apart from a small patch, with GNU coreutils/sed/grep/... first on
`PATH` (`mac-env.sh`).

## What had to change for macOS

### In the Linux project's scripts (`patches/inventor-for-linux`)

* **`mac-env.sh`** – GNU tools first on `PATH`, bundled Wine, DXMT instead of DXVK.
* **Display driver** – `Graphics=mac` instead of `x11`; Retina mode on and
  Windows scaling 200 % (`LogPixels=192`) so the UI is sharp at the same size.
* **DXMT as *native* DLLs** – DXMT's `d3d11/dxgi/d3d10core` carry Wine's
  "builtin" marker; Wine refuses builtin-marked files under a `native` load
  order (Inventor's licensing agent died with `c0000135`). Installing them as
  builtins instead would replace wined3d for *every* process, and WebView2
  needs wined3d. So the marker is blanked in the prefix copies, they load as
  native, and `msedgewebview2.exe` keeps Wine's builtin wined3d.
* **Fonts** – macOS system font folders (`/System/Library/Fonts`,
  `/Library/Fonts`, `~/Library/Fonts`) get drive letters. Without them Wine
  registers fonts as `\??\unix\...` paths, which WPF can't turn into a URI:
  Inventor crashed building its ribbon (`UriFormatException` in
  `GlyphTypeface`).
* **Product key** – ODIS passes the product key to each MSI; the Linux tool left
  it out. Inventor didn't mind, Inventor CAM's licensing step fails without it
  ("Default product key cannot be empty"), so the image's default key is passed.
* **Process detection** – the installer looked at `/proc`; on macOS it uses `ps`.
* **App name** – `AppName=Autodesk Inventor` for `Inventor.exe` (see below).

### In Wine's macOS driver (`patches/wine`)

See [wine-patches.md](wine-patches.md) for the details. In short:

1. **DXMT export** – DXMT looks up a `macdrv_functions` table that upstream
   Wine doesn't export, and expects an older internal window struct. The patch
   exports a compatible table backed by Wine 11's client surfaces, keeps the
   Metal view in sync with window moves/resizes/visibility, and stops DXMT's
   create/release pattern from removing the shared Metal view (blank viewport
   after every resize).
2. **Native window management for self-drawn frames** – Inventor draws its own
   title bar. Such windows become real titled macOS windows with a transparent,
   hidden title bar, so macOS tiling, full screen and Split View apply; dragging
   Inventor's title bar hands the drag to macOS (with edge snapping); edges
   resize natively.
3. **Maximized border** – Inventor maximizes past the screen edges by an
   unpainted border, like any Windows app with a custom frame. On macOS the top
   strip landed under the menu bar as a white line; the edge pixels are now
   extended over it, and macOS no longer fights the app's placement.
4. **Native file dialogs** – Open/Save/folder dialogs are the real macOS
   panels (sheet on the window, Format popup), not Wine's XP-style dialog.
5. **App name** – the menu bar, Dock and app switcher show the program's name
   (`AppName` setting, default: the `.exe` name) instead of "wine".

### Installer survival

* **.NET ngen deadlocks** – `ngen.exe executeQueuedItems` hangs forever under
  Wine on macOS (no CPU used). `scripts/ngen-watchdog.sh` kills such runs and
  idle `mscorsvw.exe` workers during the install; the install then completes.
  Native images are an optimisation only.

### Licensing and sign-in

Inventor 2027 licenses through the Autodesk Licensing Service plus Identity
Manager. Both run fine. The licence dialog, the Identity Manager window and the
Home tab are **WebView2** pages, which is where macOS differs:

WebView2 renders in `msedgewebview2.exe` and draws into a *child window of
another process* (the Qt window of `AdskLicensingAgent.exe`, or Inventor's main
window). On Linux, Wine gives such a child its own X11 window. macOS has no
equivalent – one app can't draw into another app's window – so these panes stay
blank. The page itself works, so `scripts/sign-in.sh` drives it through
Chromium's DevTools port: it presses *Sign in with your Autodesk ID*, Autodesk
opens the sign-in in your normal browser, and the final *Open Product* link
(`adskidmgr://...`) is routed to the Inventor app, which hands it to the
Identity Manager inside Wine. After that the sign-in is remembered.

## Files on your Mac

| Path | What |
|---|---|
| `~/inventor-mac/wine/winum-11.20-2-x86_64` | the Wine runtime |
| `~/inventor-mac/inventor-mac-port` | the Linux project, patched (logs in `logs/`) |
| `~/.wine-inventor2027` | the Windows prefix (~19 GB) – Inventor lives here |
| `~/Inventor` | your files; Inventor sees this as `D:` |
| `~/Applications/Autodesk Inventor 2027.app` | launcher, file + sign-in handler |
