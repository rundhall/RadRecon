#!/bin/bash
set -e

# Használat:
#   ./build_macos_dmg.sh          -> build, aláírás, DMG, notarizáció, letöltési mappa
#   ./build_macos_dmg.sh --clean  -> flutter clean-nel indít

APP_NAME="rad_recon"
DMG_NAME="RadRecon"
SIGN_IDENTITY="Developer ID Application: Retr-O-Sc Sport Egyesulet (6N9598RDL4)"
NOTARY_PROFILE="notary-profile"
APP_PATH="build/macos/Build/Products/Release/${APP_NAME}.app"
STAGING_DIR="build/dmg_staging"
DMG_PATH="${DMG_NAME}.dmg"
DOWNLOAD_DIR="landingpage/downloads"

if ! command -v create-dmg >/dev/null 2>&1; then
  echo "A create-dmg nincs telepítve. Telepítés: brew install create-dmg"
  exit 1
fi

if [[ "$1" == "--clean" ]]; then
  echo "0) Flutter clean..."
  flutter clean
fi

echo "1) Flutter pub get..."
flutter pub get

echo "2) Flutter build..."
flutter build macos --release

echo "3) Code signing (app)..."
codesign --deep --force --verify --verbose --sign "$SIGN_IDENTITY" --options runtime "$APP_PATH"

echo "4) Verify signature (app)..."
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

echo "5) DMG készítése..."
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
ditto "$APP_PATH" "$STAGING_DIR/${APP_NAME}.app"
rm -f "$DMG_PATH"
create-dmg --volname "$DMG_NAME" --app-drop-link 450 150 "$DMG_PATH" "$STAGING_DIR"

echo "6) Code signing (DMG)..."
codesign --force --sign "$SIGN_IDENTITY" "$DMG_PATH"

echo "7) Notarizáció (ez eltarthat pár percig)..."
xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait

echo "8) Staple és ellenőrzés..."
xcrun stapler staple "$DMG_PATH"
xcrun stapler validate "$DMG_PATH"

echo "9) Másolás a letöltési mappába..."
mkdir -p "$DOWNLOAD_DIR"
cp -f "$DMG_PATH" "$DOWNLOAD_DIR/$DMG_PATH"

echo ""
echo "Kész: $DMG_PATH"
echo "Letöltési mappa: $DOWNLOAD_DIR/$DMG_PATH"
echo "Ha nincs notarizációs profil: xcrun notarytool store-credentials \"$NOTARY_PROFILE\" --apple-id <email> --team-id 6N9598RDL4 --password <jelszó>"
