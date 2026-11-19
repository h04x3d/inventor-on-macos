#!/bin/bash
# Install Inventor from Autodesk's offline installer files into a Wine prefix.
# Usage: 40-install-inventor.sh <folder with the Inventor_*_db_*.exe/.7z files>
source "$(dirname "$0")/lib.sh"
SRC="${1:?usage: $0 <folder with the offline installer files>}"
[ -d "$SRC" ] || die "no such folder: $SRC"
# Safari saves the .7z part as .dms - accept either
for f in "$SRC"/*.dms; do [ -e "$f" ] && ln -f "$f" "${f%.dms}.7z" 2>/dev/null || true; done

info "starting .NET ngen watchdog (ngen deadlocks under Wine on macOS)"
"$REPO_DIR/scripts/ngen-watchdog.sh" > "$INVMAC_HOME/ngen-watchdog.log" 2>&1 &
WD=$!; trap 'kill $WD 2>/dev/null' EXIT

cd "$PORT_DIR" && source mac-env.sh
INV_NONINTERACTIVE=1 bash scripts/install.sh --skip-packages --skip-wine --no-desktop "$SRC" \
    2>&1 | tee "$INVMAC_HOME/install.log"
