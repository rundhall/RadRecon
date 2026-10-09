#!/bin/bash
set -e

# Használat (Linuxon futtasd, a Flutter nem tud macOS-ről Linuxra fordítani):
#   ./build_linux_release.sh          -> normál build
#   ./build_linux_release.sh --clean  -> flutter clean-nel indít
#
# Kimenet: dist/linux/RadRecon-<verzio>-linux-x64.tar.gz és .deb
# Szükséges csomagok (Ubuntu/Debian):
#   sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev dpkg-dev

APP_NAME="rad_recon"
DISPLAY_NAME="RadRecon"
APP_ID="com.rundhall.rad_recon"
ICON_SRC="assets/icon/icon.png"
BUNDLE="build/linux/x64/release/bundle"
VERSION=$(grep -E '^version:' pubspec.yaml | sed -E 's/version:[[:space:]]*([0-9.]+).*/\1/')
ARCH_TAG="linux-x64"
OUT="dist/linux"

if [[ "$1" == "--clean" ]]; then
  echo "0) Flutter clean..."
  flutter clean
fi

echo "1) Flutter pub get..."
flutter pub get

echo "2) Flutter build linux..."
flutter build linux --release

rm -rf "$OUT"
mkdir -p "$OUT"

cat > "$OUT/${DISPLAY_NAME}.desktop" <<DESK
[Desktop Entry]
Type=Application
Name=${DISPLAY_NAME}
Comment=Gamma dose rate field survey recorder
Exec=/opt/${DISPLAY_NAME}/${APP_NAME}
Icon=${APP_ID}
Categories=Utility;Science;
Terminal=false
DESK

echo "3) tar.gz csomag..."
STAGE="$OUT/${DISPLAY_NAME}-${VERSION}-${ARCH_TAG}"
mkdir -p "$STAGE"
cp -r "$BUNDLE/." "$STAGE/"
cp "$ICON_SRC" "$STAGE/${APP_ID}.png"
cp "$OUT/${DISPLAY_NAME}.desktop" "$STAGE/"
tar -C "$OUT" -czf "$OUT/${DISPLAY_NAME}-${VERSION}-${ARCH_TAG}.tar.gz" "$(basename "$STAGE")"
rm -rf "$STAGE"

echo "4) .deb csomag..."
if command -v dpkg-deb >/dev/null; then
  DEB_ROOT="$OUT/deb"
  mkdir -p "$DEB_ROOT/DEBIAN" "$DEB_ROOT/opt/${DISPLAY_NAME}" \
           "$DEB_ROOT/usr/share/applications" \
           "$DEB_ROOT/usr/share/icons/hicolor/512x512/apps" "$DEB_ROOT/usr/bin"
  cp -r "$BUNDLE/." "$DEB_ROOT/opt/${DISPLAY_NAME}/"
  cp "$OUT/${DISPLAY_NAME}.desktop" "$DEB_ROOT/usr/share/applications/${APP_ID}.desktop"
  cp "$ICON_SRC" "$DEB_ROOT/usr/share/icons/hicolor/512x512/apps/${APP_ID}.png"
  ln -s "/opt/${DISPLAY_NAME}/${APP_NAME}" "$DEB_ROOT/usr/bin/radrecon"
  cat > "$DEB_ROOT/DEBIAN/control" <<CTRL
Package: radrecon
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: amd64
Depends: libgtk-3-0, libsqlite3-0
Maintainer: RadRecon <info@radrecon.hu>
Description: RadRecon gamma dose rate field survey app
 Free, open source field survey recorder for gamma dose rate measurements.
CTRL
  dpkg-deb --build --root-owner-group "$DEB_ROOT" "$OUT/radrecon_${VERSION}_amd64.deb"
  rm -rf "$DEB_ROOT"
else
  echo "   dpkg-deb nincs telepítve, a .deb kimarad."
fi
rm -f "$OUT/${DISPLAY_NAME}.desktop"

echo ""
echo "Kész:"
ls -1 "$OUT"
