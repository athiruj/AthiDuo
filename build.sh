#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"
BUILD_DIR="${ATHIDUO_BUILD_DIR:-.build}"
OUTPUT_DIR="${ATHIDUO_OUTPUT_DIR:-build}"
SIGNING_IDENTITY="${ATHIDUO_SIGNING_IDENTITY:--}"

swift build -c release --scratch-path "$BUILD_DIR" --arch arm64
BIN_DIR="$(swift build -c release --scratch-path "$BUILD_DIR" --arch arm64 --show-bin-path)"

mkdir -p "$OUTPUT_DIR"
APP="$(cd "$OUTPUT_DIR" && pwd)/AthiDuo.app"
if [[ -e "$APP" ]]; then
  printf 'Refusing to replace existing app: %s\n' "$APP" >&2
  exit 2
fi
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources/en.lproj"
cp "$BIN_DIR/AthiDuo" "$APP/Contents/MacOS/AthiDuo"
xcrun strip -S "$APP/Contents/MacOS/AthiDuo"
ditto --norsrc --noextattr "$BIN_DIR/AthiDuo_AthiDuo.bundle" "$APP/Contents/Resources/AthiDuo_AthiDuo.bundle"
cp Sources/MacDuo/Resources/en.lproj/InfoPlist.strings "$APP/Contents/Resources/en.lproj/InfoPlist.strings"
cp LICENSE ATTRIBUTION.md "$APP/Contents/Resources/"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleDevelopmentRegion</key><string>en</string>
<key>CFBundleLocalizations</key><array><string>en</string></array>
<key>CFBundleName</key><string>AthiDuo</string>
<key>CFBundleDisplayName</key><string>AthiDuo</string>
<key>CFBundleIdentifier</key><string>com.athi.athiduo</string>
<key>CFBundleExecutable</key><string>AthiDuo</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.1.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>26.0</string>
<key>LSUIElement</key><true/>
<key>NSHighResolutionCapable</key><true/>
<key>NSScreenCaptureUsageDescription</key><string>AthiDuo creates a temporary animated snapshot of your desktop while you move the lid. Frames stay in memory on this Mac.</string>
</dict></plist>
PLIST

codesign --force --sign "$SIGNING_IDENTITY" --identifier com.athi.athiduo "$APP"
codesign --verify --strict "$APP"
plutil -lint "$APP/Contents/Info.plist"
printf 'Built %s\n' "$APP"
if [[ "$SIGNING_IDENTITY" == "-" ]]; then
  printf 'Ad-hoc build: macOS may ask for Screen Recording permission after a rebuild.\n'
fi
