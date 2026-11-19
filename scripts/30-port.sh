#!/bin/bash
# The Inventor-for-Linux project does the heavy lifting (offline ODIS install,
# .NET, WebView2, licensing, launcher). Pin it and apply the macOS patch.
source "$(dirname "$0")/lib.sh"
if [ ! -d "$PORT_DIR/.git" ]; then
    git clone -q "$LINUX_REPO" "$PORT_DIR"
fi
cd "$PORT_DIR"
if ! git log --oneline -1 | grep -q 'inventor-on-macos'; then
    git checkout -q -B macos "$LINUX_COMMIT"
    git apply "$REPO_DIR/patches/inventor-for-linux/0001-macos-support.patch"
    git add -A && git -c user.name=inventor-on-macos -c user.email=inventor-on-macos@localhost \
        commit -qm "inventor-on-macos: macOS support"
fi
info "Linux project ready in $PORT_DIR (branch macos)"
