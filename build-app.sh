#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
export CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/module-cache"
swift build --disable-sandbox --cache-path "$PWD/.build/cache" -c release
APP="dist/Perch.app"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"
swiftc Sources/Perch/BrandIcon.swift scripts/RenderIcon.swift -o .build/render-icon
.build/render-icon .build/Perch.iconset
iconutil -c icns .build/Perch.iconset -o "$APP/Contents/Resources/Perch.icns"
cp .build/release/Perch "$APP/Contents/MacOS/Perch"
cp Info.plist "$APP/Contents/Info.plist"
codesign --force --sign "${SIGNING_IDENTITY:--}" "$APP"
codesign --verify --strict "$APP"

INSTALL_PATH="/Applications/Perch.app"
# Finish the build before stopping the installed app.
if pgrep -x Perch >/dev/null; then
    pkill -x Perch
    for attempt in {1..50}; do
        pgrep -x Perch >/dev/null || break
        sleep 0.1
    done
    if pgrep -x Perch >/dev/null; then
        echo "Perch is still running. Quit it and run this script again." >&2
        exit 1
    fi
fi
ditto "$APP" "$INSTALL_PATH"
codesign --verify --strict "$INSTALL_PATH"
open "$INSTALL_PATH"
echo "Built, installed, and opened $INSTALL_PATH"
