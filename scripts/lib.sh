# Shared settings for inventor-on-macos scripts. Source, don't run.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Everything gets built/installed under here (the Linux project's macOS
# settings in mac-env.sh expect this default).
INVMAC_HOME="${INVMAC_HOME:-$HOME/inventor-mac}"
BREW="${BREW:-/opt/homebrew}"

WINE_VERSION=11.20
WINE_URL="https://dl.winehq.org/wine/source/11.x/wine-$WINE_VERSION.tar.xz"
WINUM_REPO=https://github.com/Harvi654/winum.git
WINUM_COMMIT=98a6feda5d55b739c9fdfd363b060631a2004447          # winum-11.20-2 series
GCENX_URL="https://github.com/Gcenx/macOS_Wine_builds/releases/download/$WINE_VERSION/wine-devel-$WINE_VERSION-osx64.tar.xz"
DXMT_VERSION=v0.80
DXMT_URL="https://github.com/3Shain/dxmt/releases/download/$DXMT_VERSION/dxmt-$DXMT_VERSION-builtin.tar.gz"
LINUX_REPO=https://github.com/Harvi654/Autodesk-Inventor-for-Linux.git
LINUX_COMMIT=f6c571068759ffd02089118148e7d0ce87f5221a

WINE_NAME="winum-$WINE_VERSION-2-x86_64"
WINE_RUNTIME="$INVMAC_HOME/wine/$WINE_NAME"
PORT_DIR="$INVMAC_HOME/inventor-mac-port"
DL="$INVMAC_HOME/dl"
GCENX_LIB="$INVMAC_HOME/gcenx-lib"          # symlink: no spaces for configure
PREFIX_DIR="${WINEPREFIX:-$HOME/.wine-inventor2027}"

info() { printf '\033[1m==> %s\033[0m\n' "$*"; }
die()  { printf '\033[31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }
x86()  { arch -x86_64 "$@"; }                # Wine is x86_64 and runs under Rosetta 2
