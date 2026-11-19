#!/bin/bash
# First sign-in helper.
#
# Autodesk's licence dialog is a WebView2 page drawn by a separate process into a
# child window; Wine's macOS driver can't show cross-process child windows, so
# the dialog is blank/invisible (see docs/how-it-works.md). The page itself works,
# so this script enables Chromium's DevTools port on localhost, starts Inventor,
# presses "Sign in with your Autodesk ID" for you and turns the port off again.
# Autodesk then opens the sign-in page in your normal browser; finish there and
# click "Open Product" - the adskidmgr:// link comes back to the Inventor app.
source "$(dirname "$0")/lib.sh"
command -v node >/dev/null || die "needs Node.js 18+: brew install node"
cd "$PORT_DIR" && source mac-env.sh
W="$WINE_RUNTIME/bin"
K='HKLM\Software\Policies\Microsoft\Edge\WebView2\AdditionalBrowserArguments'
ARGS='--no-sandbox --enable-unsafe-swiftshader --use-angle=swiftshader'
setargs() { for app in '*' AdskLicensingAgent.exe AdskIdentityManager.exe; do
    x86 "$W/wine" reg add "$K" /v "$app" /t REG_SZ /d "$1" /f >/dev/null 2>&1; done; }

info "enabling WebView2 DevTools on 127.0.0.1:9222 for the licensing dialog"
x86 "$W/wineserver" -k 2>/dev/null || true; sleep 2
setargs "$ARGS --remote-debugging-port=9222"; x86 "$W/wineserver" -w

info "starting Inventor"
"$INVMAC_HOME/app/run.sh" launch >/dev/null 2>&1 &
for i in $(seq 1 90); do
    sleep 4
    if node "$REPO_DIR/tools/webview-click.mjs" lgs.html 'Sign in with your Autodesk ID' >/dev/null 2>&1; then
        info "pressed 'Sign in with your Autodesk ID' - finish signing in in your browser, then click 'Open Product'"
        break
    fi
    [ "$i" = 90 ] && echo "no licence dialog appeared (already signed in?)"
done
setargs "$ARGS"   # takes effect next launch
info "DevTools port disabled for the next start"
