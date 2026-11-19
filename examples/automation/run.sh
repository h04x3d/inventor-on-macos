#!/bin/bash
# Compile a C# example with the .NET Framework compiler inside the Wine prefix and
# run it against the running Inventor (it attaches through COM).
# Usage: examples/automation/run.sh Bracket.cs [args...]
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../../scripts/lib.sh"
SRC="${1:?usage: $0 <Example.cs> [args...]}"; shift
NAME="$(basename "$SRC" .cs)"
export WINEPREFIX="$PREFIX_DIR" WINEDEBUG=-all
C="$WINEPREFIX/drive_c/automation"          # Wine only sees C: and D: (sandboxed prefix)
mkdir -p "$C"
cp "$HERE/$NAME.cs" "$C/"
cp "$WINEPREFIX/drive_c/Program Files/Autodesk/Inventor 2027/Bin/Public Assemblies/Autodesk.Inventor.Interop.dll" "$C/"
wine() { x86 "$WINE_RUNTIME/bin/wine" "$@"; }
wine 'C:\windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe' /nologo /platform:x64 \
    /r:'C:\automation\Autodesk.Inventor.Interop.dll' /out:"C:\\automation\\$NAME.exe" "C:\\automation\\$NAME.cs"
wine "C:\\automation\\$NAME.exe" "$@"
