# Troubleshooting

Logs: `~/inventor-mac/inventor-mac-port/logs/` (`app-launch.log` for the app,
plus the Linux project's install logs), Inventor's own logs under
`~/.wine-inventor2027/drive_c/users/$USER/AppData/Local/Autodesk/`.

| Symptom | Cause / fix |
|---|---|
| Install sits at ".NET Framework 4.x" for a long time | ngen deadlock. `40-install-inventor.sh` runs `scripts/ngen-watchdog.sh`; if you install by hand, run it yourself in another terminal |
| `ERROR ... /etc/os-release` at the start of the install | harmless – the Linux scripts look for the distribution; ignore |
| "Licensing Error" on first start; agent exits with `c0000135` | DXMT DLLs loaded with the wrong load order. `d3d11`, `dxgi`, `d3d10core` must be `native` in `HKCU\Software\Wine\DllOverrides` and the prefix copies must not carry the builtin marker (`install_dxvk` does this) |
| Loading screen sits there, no sign-in window | the licence dialog is an invisible WebView2 page (often behind the splash). Run `scripts/sign-in.sh` |
| Browser says "You're signed in" but Inventor keeps waiting | the *Open Product* link went to another app. `swift scripts/set-url-handler.swift "$HOME/Applications/Autodesk Inventor 2027.app" adskidmgr`, then run `scripts/sign-in.sh` again |
| Fusion / other native Autodesk apps can't finish *their* browser sign-in | same `adskidmgr://` scheme – point it back to `/Library/Application Support/Autodesk/AdskIdentityManager/<version>/Autodesk Identity Manager.app` with `set-url-handler.swift`, sign in there, then switch back |
| Inventor crashes right after sign-in, `UriFormatException` in the log | fonts registered as `\??\unix\...`; make sure the patched `common.sh` is used (it maps the macOS font folders to drive letters) and relaunch |
| 3D viewport empty | check the log for `Failed to create metal view` → the Wine runtime is missing the winemac.drv patch or `winemetal.so` |
| Home tab is blank | known limitation (WebView2, see how-it-works.md). Use *File → New/Open* |
| Fuzzy UI | Retina mode: `HKCU\Software\Wine\Mac Driver\RetinaMode=y` and `LogPixels=192`; change `INV_DPI` (e.g. 168 = 175 %) for more room |
| A Save/Open panel refuses a folder | the Windows side only sees `C:` and `~/Inventor` (`D:`); save inside `~/Inventor` |
| Want Wine's own file dialogs back | `HKCU\Software\Wine\Mac Driver` → `NativeFileDialogs` = `n` |
| "Could not find file ...\\Design Data\\XLS\\en-US\\Thread.xlsx" in an old Pack and Go project | the pack carries pre-2020 `thread.xls`; copy `thread.xlsx`/`clearance.xlsx` from `C:\\Users\\Public\\Documents\\Autodesk\\Inventor 2027\\Design Data\\XLS\\en-US` into it, or use the Default project |
| `wineserver: sock_get_ntstatus() can't map error: Host is down` | harmless network probing noise |

Useful while debugging: `tools/` has tiny Win32 programs (build with `make -C
tools`) to list windows, dump child-window trees with owning processes, move
and hit-test windows from inside Wine.
