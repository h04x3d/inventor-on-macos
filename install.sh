#!/bin/bash
# inventor-on-macos: build everything and install Autodesk Inventor 2027.
# Usage: ./install.sh <folder with Autodesk's offline installer files>
#        ./install.sh --from <step> <folder>     (steps: deps wine dxmt port inventor app)
set -euo pipefail
cd "$(dirname "$0")"
FROM=deps
if [ "${1:-}" = --from ]; then FROM="$2"; shift 2; fi
SRC="${1:?usage: ./install.sh [--from step] <folder with the Inventor offline installer files>}"
run=0
for step in deps:00-deps.sh wine:10-build-wine.sh dxmt:20-dxmt.sh port:30-port.sh inventor:40-install-inventor.sh app:50-make-app.sh; do
    name="${step%%:*}"; script="${step#*:}"
    [ "$name" = "$FROM" ] && run=1
    [ $run = 1 ] || continue
    printf '\n\033[1;34m### %s\033[0m\n' "$name"
    if [ "$name" = inventor ]; then bash "scripts/$script" "$SRC"; else bash "scripts/$script"; fi
done
printf '\nDone. Start Inventor from ~/Applications/Autodesk Inventor 2027.app\n'
