#!/bin/bash
set -eo pipefail

REPO_BASE="../.."

BUILD_DIR="./build"
APP_BUNDLE="$BUILD_DIR/macpaper.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RSC_DIR="$CONTENTS_DIR/Resources"

MP_VER_STRING="v2.1.1"
MP_VER_SHORT_STRING="v2.1.1"

rm -rf ./build

mkdir -p $MACOS_DIR
mkdir -p $RSC_DIR

echo "building to ${BUILD_DIR}"
# compile app
swiftc \
    -target x86_64-apple-macos12.0 \
    -framework SwiftUI -framework AppKit -framework AVKit \
    -framework AVFoundation -framework UniformTypeIdentifiers \
    -framework Combine -O \
    main/*.swift \
    -o build/macpaper.app/Contents/MacOS/macpaper_amd64

echo "compiled macpaper (amd64)"

swiftc \
    -target arm64-apple-macos12.0 \
    -framework SwiftUI -framework AppKit -framework AVKit \
    -framework AVFoundation -framework UniformTypeIdentifiers \
    -framework Combine -O \
    main/*.swift \
    -o build/macpaper.app/Contents/MacOS/macpaper_arm64 2>/dev/null

echo "compiled macpaper (arm64)"

lipo -create \
    "$MACOS_DIR/macpaper_amd64" \
    "$MACOS_DIR/macpaper_arm64" \
    -o "$MACOS_DIR/macpaper"

echo "compiled macpaper (universal)"
rm "$MACOS_DIR/macpaper_amd64" "$MACOS_DIR/macpaper_arm64"
echo ""

# compile glasswp (disabled - functionality is in macpaper.swift)
# swiftc \
#     -target x86_64-apple-macos12.0 \
#     -framework AppKit -framework AVFoundation \
#     ../glasswp/glasswp.swift \
#     -o "build/macpaper.app/Contents/MacOS/glasswp_amd64"
#
# echo "compiled glasswp (amd64)"
#
# swiftc \
#     -target arm64-apple-macos12.0 \
#     -framework AppKit -framework AVFoundation \
#     ../glasswp/glasswp.swift \
#     -o "build/macpaper.app/Contents/MacOS/glasswp_arm64"
#
# echo "compiled glasswp (arm64)"
#     
# lipo -create "$MACOS_DIR/glasswp_amd64" "$MACOS_DIR/glasswp_arm64" -o "$MACOS_DIR/macpaper Wallpaper Service (glasswp)"
#
# echo "compiled glasswp (universal)"
# rm "$MACOS_DIR/glasswp_amd64" "$MACOS_DIR/glasswp_arm64"
# echo ""

# compile macpaper-bin
gcc -target x86_64-apple-macos12.0 \
    obj/macpaper.c -o build/macpaper.app/Contents/MacOS/macpaper-bin_amd64

echo "compiled macpaper-bin (arm64)"

gcc -target arm64-apple-macos12.0 \
    obj/macpaper.c -o build/macpaper.app/Contents/MacOS/macpaper-bin_arm64

echo "compiled macpaper-bin (arm64)"

lipo -create "$MACOS_DIR/macpaper-bin_amd64" "$MACOS_DIR/macpaper-bin_arm64" -o "$MACOS_DIR/macpaper-bin"

echo "compiled macpaper-bin (universal)"
rm "$MACOS_DIR/macpaper-bin_amd64" "$MACOS_DIR/macpaper-bin_arm64"
echo ""

echo "almost done!"

echo "adding macpaper's Info.plist"
cat > "$CONTENTS_DIR/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>macpaper</string>
    <key>CFBundleIdentifier</key>
    <string>com.naomisphere.macpaper</string>
    <key>CFBundleName</key>
    <string>macpaper</string>
    <key>CFBundleDisplayName</key>
    <string>macpaper</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${MP_VER_SHORT_STRING}</string>
    <key>CFBundleVersion</key>
    <string>${MP_VER_STRING}</string>
    <key>CFBundleIconFile</key>
    <string>macpaper.icns</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>NSRequiresAquaSystemAppearance</key>
    <false/>
</dict>
</plist>
EOF

echo "adding app resources"
cp ../artwork/icns/macpaper.icns "$RSC_DIR"
cp ../artwork/png/tear.png "${RSC_DIR}/.macpaper_tear.png"
cp ../artwork/png/tear.png "${RSC_DIR}/StatusBarIcon.png"
cp ./updater.sh "${RSC_DIR}/.updater.sh"
cp ../img/png/kofi_symbol.png build/macpaper.app/Contents/Resources/.kofi.png 2>/dev/null || true

echo "adding localization strings"
cp -r ../lang/*.lproj "$RSC_DIR"

echo ""
echo "..done!"
echo "${BUILD_DIR}/macpaper.app"
