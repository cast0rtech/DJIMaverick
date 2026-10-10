#!/bin/bash
set -e

echo "=== 1. INICIANDO COMPILACIÓN DE DJI MAVERICK GCS (UNIVERSAL iOS & iPadOS) ==="
PROJECT_DIR="/Users/castordfedez/Desktop/DJIMaverick"
APP_DIR="$PROJECT_DIR/DJIMaverickApp"
BUILD_DIR="$APP_DIR/build_release"
PAYLOAD_DIR="$BUILD_DIR/Payload"
BUNDLE_DIR="$PAYLOAD_DIR/DJIMaverick.app"
OUTPUT_IPA="$PROJECT_DIR/DJIMaverick.ipa"

rm -rf "$BUILD_DIR" "$OUTPUT_IPA"
mkdir -p "$BUNDLE_DIR"

echo "--> Compilando código fuente Swift para dispositivo iOS/iPadOS (arm64 Release)..."
SDK_PATH=$(xcrun --sdk iphoneos --show-sdk-path)

# Compilar objetos Swift con optimizaciones Release
xcrun --sdk iphoneos swiftc \
    -target arm64-apple-ios17.0 \
    -sdk "$SDK_PATH" \
    -O \
    -parse-as-library \
    -emit-executable \
    -module-name DJIMaverickApp \
    -o "$BUNDLE_DIR/DJIMaverick" \
    "$APP_DIR/Sources/TelemetryState.swift" \
    "$APP_DIR/Sources/PhotogrammetryEngine.swift" \
    "$APP_DIR/Sources/MissionModels.swift" \
    "$APP_DIR/Sources/ModuleViews.swift" \
    "$APP_DIR/Sources/TacticalHUDMapView.swift" \
    "$APP_DIR/Sources/ContentView.swift" \
    "$APP_DIR/Sources/DJIMaverickApp.swift" \
    -Xlinker -rpath -Xlinker /usr/lib/swift \
    -framework SwiftUI \
    -framework UIKit \
    -framework Foundation

echo "--> Generando Info.plist y metadatos de aplicación universal..."
cat << 'EOF' > "$BUNDLE_DIR/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>DJIMaverick</string>
    <key>CFBundleIdentifier</key>
    <string>com.dji.maverick.gcs</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>DJIMaverick</string>
    <key>CFBundleDisplayName</key>
    <string>DJI Maverick GCS</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>MinimumOSVersion</key>
    <string>17.0</string>
    <key>UIDeviceFamily</key>
    <array>
        <integer>1</integer>
        <integer>2</integer>
    </array>
    <key>UILaunchScreen</key>
    <dict/>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>UISupportedInterfaceOrientations~ipad</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationPortraitUpsideDown</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>DJI Maverick requiere coordenadas GPS para funciones de Follow-Me y retorno de aeronave.</string>
    <key>NSBluetoothAlwaysUsageDescription</key>
    <string>DJI Maverick utiliza Bluetooth para comunicarse con el control y la aeronave.</string>
</dict>
</plist>
EOF

echo "APPL????" > "$BUNDLE_DIR/PkgInfo"

echo "--> Firmando paquete de aplicación con firma Ad-Hoc..."
codesign -s - --deep --force "$BUNDLE_DIR"

echo "--> Empaquetando archivo IPA (Payload comprimido)..."
cd "$BUILD_DIR"
zip -r -9 "$OUTPUT_IPA" Payload > /dev/null

echo "--> Limpiando archivos intermedios..."
rm -rf "$BUILD_DIR"

echo "=== COMPILACIÓN COMPLETADA EXITOSAMENTE ==="
ls -lh "$OUTPUT_IPA"
codesign -dvvv "$OUTPUT_IPA" 2>&1 | head -n 5 || true
