#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
export CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/module-cache"
swift build --disable-sandbox --cache-path "$PWD/.build/cache" -c release
APP="dist/Notchkin.app"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"
swiftc Sources/Notchkin/BrandIcon.swift scripts/RenderIcon.swift -o .build/render-icon
.build/render-icon .build/Notchkin.iconset
iconutil -c icns .build/Notchkin.iconset -o "$APP/Contents/Resources/Notchkin.icns"
cp .build/release/Notchkin "$APP/Contents/MacOS/Notchkin"
cp Info.plist "$APP/Contents/Info.plist"
codesign --force --sign - "$APP"
echo "Built $APP"
