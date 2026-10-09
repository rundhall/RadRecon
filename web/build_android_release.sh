#!/bin/bash
set -e

# Használat:
#   ./build_android_release.sh          -> normál build
#   ./build_android_release.sh --clean  -> flutter clean-nel indít (lassabb, csak ha kell)

if [[ "$1" == "--clean" ]]; then
  echo "0) Flutter clean..."
  flutter clean
fi

echo "1) Flutter pub get..."
flutter pub get

echo "2) Android App Bundle build (Play Store-hoz)..."
flutter build appbundle --release

echo ""
echo "Kesz: build/app/outputs/bundle/release/app-release.aab"
echo "Ezt toltsd fel a Play Console-ba (Production vagy Open testing track)."