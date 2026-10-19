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
codesign --force --sign - "$APP"
echo "Built $APP"
