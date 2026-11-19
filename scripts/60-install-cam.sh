#!/bin/bash
# Optional: Inventor CAM 2027 (Autodesk's add-in installer, e.g. INHSMP_2027_NA_win_db.sfx.exe).
# Usage: 60-install-cam.sh <path to the downloaded .sfx.exe>   (quit Inventor first)
source "$(dirname "$0")/lib.sh"
SFX="${1:?usage: $0 <Inventor CAM .sfx.exe>}"
[ -f "$SFX" ] || die "no such file: $SFX"
pgrep -f 'Inventor.exe' >/dev/null && die "quit Inventor first"
W="$INVMAC_HOME/cam-image"; OUTER="$W/outer"; IMG="$W/image"
if [ ! -f "$IMG/setup.xml" ]; then
    info "unpacking $(basename "$SFX")"
    mkdir -p "$OUTER" "$IMG"
    7zz x -y -o"$OUTER" "$SFX" >/dev/null
    7zz x -y -o"$IMG" "$OUTER"/*_002_002.7z >/dev/null
fi
cd "$PORT_DIR" && source mac-env.sh
export PATH="$WINE_RUNTIME/bin:$PATH" WINEPREFIX="$PREFIX_DIR"
"$REPO_DIR/scripts/ngen-watchdog.sh" > "$INVMAC_HOME/ngen-watchdog-cam.log" 2>&1 &
WD=$!; trap 'kill $WD 2>/dev/null' EXIT
python3 scripts/install-from-image.py "$IMG" --prefix "$PREFIX_DIR"
info "Inventor CAM installed - it appears as the CAM tab in parts and assemblies"
