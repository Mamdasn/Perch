#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
export CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/module-cache"
swift build --disable-sandbox --cache-path "$PWD/.build/cache" -c release
APP="dist/Notchpop.app"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"
swiftc Sources/Notchpop/BrandIcon.swift scripts/RenderIcon.swift -o .build/render-icon
.build/render-icon .build/Notchpop.iconset
iconutil -c icns .build/Notchpop.iconset -o "$APP/Contents/Resources/Notchpop.icns"
cp .build/release/Notchpop "$APP/Contents/MacOS/Notchpop"
cp Info.plist "$APP/Contents/Info.plist"
codesign --force --sign "${SIGNING_IDENTITY:--}" "$APP"
codesign --verify --strict "$APP"

INSTALL_PATH="/Applications/Notchpop.app"
# Finish the build before stopping the installed app.
if pgrep -x Notchpop >/dev/null; then
    pkill -x Notchpop
    for attempt in {1..50}; do
        pgrep -x Notchpop >/dev/null || break
        sleep 0.1
    done
    if pgrep -x Notchpop >/dev/null; then
        echo "Notchpop is still running. Quit it and run this script again." >&2
        exit 1
    fi
fi
ditto "$APP" "$INSTALL_PATH"
codesign --verify --strict "$INSTALL_PATH"
open "$INSTALL_PATH"
echo "Built, installed, and opened $INSTALL_PATH"
