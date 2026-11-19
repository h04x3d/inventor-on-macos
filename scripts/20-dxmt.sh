#!/bin/bash
# DXMT (Direct3D 11 -> Metal). Its winemetal bridge goes into the Wine runtime
# as a builtin; d3d11/dxgi/d3d10core are installed into the prefix as *native*
# DLLs later (by the Linux project's install_dxvk, patched), so Wine's own
# wined3d stays the builtin that WebView2 needs.
source "$(dirname "$0")/lib.sh"
D="$DL/dxmt"
if [ ! -d "$D/$DXMT_VERSION" ]; then
    curl -fL --retry 3 -o "$DL/dxmt.tar.gz" "$DXMT_URL"
    mkdir -p "$D" && tar -xzf "$DL/dxmt.tar.gz" -C "$D"
fi
[ -d "$D/$DXMT_VERSION" ] || die "unexpected DXMT archive layout in $D"
cp "$D/$DXMT_VERSION/x86_64-windows/winemetal.dll" "$WINE_RUNTIME/lib/wine/x86_64-windows/"
cp "$D/$DXMT_VERSION/i386-windows/winemetal.dll"   "$WINE_RUNTIME/lib/wine/i386-windows/"
cp "$D/$DXMT_VERSION/x86_64-unix/winemetal.so"     "$WINE_RUNTIME/lib/wine/x86_64-unix/"
codesign -fs - "$WINE_RUNTIME/lib/wine/x86_64-unix/winemetal.so"
info "DXMT $DXMT_VERSION installed (DXMT_DIR=$D/$DXMT_VERSION)"
