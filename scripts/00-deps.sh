#!/bin/bash
# Prerequisites: Rosetta 2, Xcode command line tools, Homebrew packages and fonts.
source "$(dirname "$0")/lib.sh"

[ "$(uname -m)" = arm64 ] || die "this project targets Apple Silicon Macs"
command -v brew >/dev/null || die "install Homebrew first: https://brew.sh"
xcode-select -p >/dev/null 2>&1 || die "install the Xcode command line tools: xcode-select --install"
if ! arch -x86_64 /usr/bin/true 2>/dev/null; then
    info "installing Rosetta 2"
    softwareupdate --install-rosetta --agree-to-license
fi

info "Homebrew build tools (Wine cross-compiler, headers)"
brew install mingw-w64 bison freetype gnutls nettle libtasn1 p11-kit gmp node

info "GNU userland used by the Inventor-for-Linux scripts"
brew install bash coreutils gnu-sed findutils grep gawk util-linux gnu-getopt \
             sevenzip winetricks cabextract hivex

info "fonts Inventor's UI expects (metric-compatible replacements)"
brew install --cask font-liberation font-noto-sans font-noto-serif font-noto-sans-mono \
    font-noto-sans-symbols font-noto-sans-symbols-2 font-noto-sans-math font-dejavu \
    font-carlito font-caladea || true
