#!/bin/bash
# Build Wine 11.20 + the winum Inventor patch series + this project's winemac.drv
# patch, as x86_64 (Rosetta), and assemble a runtime on top of Gcenx's macOS Wine
# libraries (freetype, gnutls, MoltenVK, mono, gecko ...).
source "$(dirname "$0")/lib.sh"
mkdir -p "$DL" "$INVMAC_HOME"

info "Gcenx wine-devel $WINE_VERSION (runtime libraries)"
if [ ! -d "$DL/Wine Devel.app" ]; then
    curl -fL --retry 3 -o "$DL/gcenx.tar.xz" "$GCENX_URL"
    tar -xf "$DL/gcenx.tar.xz" -C "$DL"
fi
ln -sfn "$DL/Wine Devel.app/Contents/Resources/wine/lib" "$GCENX_LIB"

info "Wine $WINE_VERSION source + winum patches"
SRC="$INVMAC_HOME/wine-$WINE_VERSION"
if [ ! -d "$SRC" ]; then
    [ -f "$INVMAC_HOME/wine-$WINE_VERSION.tar.xz" ] || curl -fL --retry 3 -o "$INVMAC_HOME/wine-$WINE_VERSION.tar.xz" "$WINE_URL"
    tar -xf "$INVMAC_HOME/wine-$WINE_VERSION.tar.xz" -C "$INVMAC_HOME"
    [ -d "$INVMAC_HOME/winum" ] || git clone -q "$WINUM_REPO" "$INVMAC_HOME/winum"
    git -C "$INVMAC_HOME/winum" checkout -q "$WINUM_COMMIT"
    while read -r p; do
        p="${p%%#*}"; p="${p//[[:space:]]/}"; [ -z "$p" ] && continue
        # one test-only hunk of win32u-fixed-negative-mat2 is already upstream; ignore it
        (cd "$SRC" && patch -p1 -s -N < "$INVMAC_HOME/winum/patches/$p") >/dev/null || echo "   (patch $p: partly already applied)"
    done < "$INVMAC_HOME/winum/patches/series"
    info "inventor-on-macos winemac.drv patch"
    (cd "$SRC" && patch -p1 < "$REPO_DIR/patches/wine/0001-winemac.drv-inventor-on-macos.patch")
fi

info "configure (x86_64, macOS display driver, no X11)"
B="$INVMAC_HOME/build64"; mkdir -p "$B"; cd "$B"
export PATH="$BREW/opt/bison/bin:$PATH"
if [ ! -f Makefile ]; then
    x86 env PKG_CONFIG_LIBDIR=/nonexistent "$SRC/configure" \
        --prefix="$INVMAC_HOME/winum-mac" --enable-archs=x86_64,i386 --disable-tests \
        --without-x --without-wayland --without-gstreamer --without-sdl --without-cups --without-sane \
        --without-gphoto --without-krb5 --without-netapi --without-pcap --without-inotify \
        --with-freetype --with-gnutls --with-vulkan \
        ac_cv_lib_soname_freetype=libfreetype.6.dylib ac_cv_lib_soname_gnutls=libgnutls.30.dylib \
        ac_cv_lib_soname_vulkan=libvulkan.1.dylib \
        FREETYPE_CFLAGS="-I$BREW/opt/freetype/include/freetype2" FREETYPE_LIBS="-L$GCENX_LIB -lfreetype" \
        GNUTLS_CFLAGS="-I$BREW/opt/gnutls/include -I$BREW/opt/nettle/include -I$BREW/opt/libtasn1/include -I$BREW/opt/p11-kit/include/p11-kit-1 -I$BREW/opt/gmp/include" \
        GNUTLS_LIBS="-L$GCENX_LIB -lgnutls" LDFLAGS="-L$GCENX_LIB" CFLAGS=-O2 MACOSX_DEPLOYMENT_TARGET=11.0
fi
# build tools (sfnt2fon) dlopen libfreetype; DYLD_* is stripped by SIP, but dyld
# also searches the current directory
for l in libfreetype.6.dylib libpng16.16.dylib libz.1.dylib libbz2.1.0.dylib libbrotlidec.1.dylib libbrotlicommon.1.dylib; do
    ln -sf "$GCENX_LIB/$l" .
done
ln -sf "$GCENX_LIB/libfreetype.6.dylib" libfreetype.dylib

info "make (this takes a while)"
x86 make -j"$(sysctl -n hw.ncpu)" > build.log 2>&1 || { tail -30 build.log; die "build failed (see $B/build.log)"; }
rm -rf "$INVMAC_HOME/stage"
x86 make install DESTDIR="$INVMAC_HOME/stage" > install.log 2>&1

info "assemble runtime $WINE_RUNTIME"
S="$INVMAC_HOME/stage$INVMAC_HOME/winum-mac"
rm -rf "$WINE_RUNTIME"; mkdir -p "$(dirname "$WINE_RUNTIME")"
cp -a "$DL/Wine Devel.app/Contents/Resources/wine" "$WINE_RUNTIME"
for d in bin lib/wine share/wine; do rsync -a "$S/$d/" "$WINE_RUNTIME/$d/"; done
printf 'winum (macOS build of winum-%s-2 + inventor-on-macos)\nname: %s\n' "$WINE_VERSION" "$WINE_NAME" > "$WINE_RUNTIME/BUILDINFO"
cd "$WINE_RUNTIME/lib/wine/x86_64-unix"
for f in *.so; do
    otool -l "$f" | grep -q "@loader_path/../../" || install_name_tool -add_rpath @loader_path/../../ "$f" 2>/dev/null || true
    codesign -fs - "$f" 2>/dev/null
done
otool -l "$WINE_RUNTIME/bin/wineserver" | grep -q "@loader_path/../lib" || install_name_tool -add_rpath @loader_path/../lib "$WINE_RUNTIME/bin/wineserver"
codesign -fs - "$WINE_RUNTIME/bin/wineserver" "$WINE_RUNTIME/bin/wine"
x86 "$WINE_RUNTIME/bin/wine" --version
