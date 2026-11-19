#!/bin/bash
# Build "~/Applications/Autodesk Inventor 2027.app": a tiny AppleScript applet that
# starts Inventor, opens .ipt/.iam/... files and receives adskidmgr:// sign-in links.
source "$(dirname "$0")/lib.sh"
APP="$HOME/Applications/Autodesk Inventor 2027.app"
mkdir -p "$HOME/Applications" "$INVMAC_HOME/app"
sed "s#@INVMAC_HOME@#$INVMAC_HOME#g" "$REPO_DIR/app/run.sh" > "$INVMAC_HOME/app/run.sh"
chmod +x "$INVMAC_HOME/app/run.sh"
TMP="$(mktemp -d)"; sed "s#@RUNNER@#$INVMAC_HOME/app/run.sh#g" "$REPO_DIR/app/Inventor.applescript" > "$TMP/Inventor.applescript"
rm -rf "$APP"; osacompile -o "$APP" "$TMP/Inventor.applescript"
P="$APP/Contents/Info.plist"; PB=/usr/libexec/PlistBuddy
$PB -c "Set :CFBundleIdentifier com.github.inventor-on-macos.launcher" \
    -c "Add :CFBundleURLTypes array" -c "Add :CFBundleURLTypes:0 dict" \
    -c "Add :CFBundleURLTypes:0:CFBundleURLName string 'Autodesk Sign-In'" \
    -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes array" -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes:0 string adskidmgr" \
    -c "Add :CFBundleDocumentTypes array" -c "Add :CFBundleDocumentTypes:0 dict" \
    -c "Add :CFBundleDocumentTypes:0:CFBundleTypeName string 'Inventor document'" \
    -c "Add :CFBundleDocumentTypes:0:CFBundleTypeRole string Editor" \
    -c "Add :CFBundleDocumentTypes:0:CFBundleTypeExtensions array" "$P"
i=0; for e in ipt iam idw ipn dwg; do $PB -c "Add :CFBundleDocumentTypes:0:CFBundleTypeExtensions:$i string $e" "$P"; i=$((i+1)); done
codesign -fs - "$APP"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP"
# Autodesk's browser sign-in returns through adskidmgr:// - send it to this app,
# not to a native macOS Autodesk Identity Manager (Fusion etc.) if one is installed.
swift "$REPO_DIR/scripts/set-url-handler.swift" "$APP" adskidmgr
info "created $APP"
