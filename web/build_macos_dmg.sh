#!/bin/bash
set -e

APP_NAME="rad_recon"
DMG_NAME="RadRecon"
SIGN_IDENTITY="Developer ID Application: Retr-O-Sc Sport Egyesulet (6N9598RDL4)"
APP_PATH="build/macos/Build/Products/Release/${APP_NAME}.app"
DMG_PATH="${DMG_NAME}.dmg"

if [[ "$1" == "--clean" ]]; then
  echo "0) Flutter clean..."
  flutter clean
fi

echo "1) Flutter pub get..."
flutter pub get

echo "2) Flutter build..."
flutter build macos --release

echo "3) Code signing..."
codesign --deep --force --verify --verbose --sign "$SIGN_IDENTITY" --options runtime "$APP_PATH"

echo "4) Verify signature..."
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

echo "5) Csomagolás dmg-be..."
rm -f "$DMG_PATH"
create-dmg --volname "$DMG_NAME" --app-drop-link 450 150 "$DMG_PATH" "$APP_PATH"

echo "Kész: $DMG_PATH"
echo "Most jöhet a notarizáció:"
echo "  xcrun notarytool submit $DMG_PATH --keychain-profile \"notary-profile\" --wait"
echo "Utána staple:"
echo "  xcrun stapler staple $DMG_PATH"



