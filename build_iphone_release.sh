#!/bin/bash
set -e

# Ha van App Store Connect API kulcsod, töltsd ki ezt a kettőt,
# és a script automatikusan feltölti a build végén.
# Ha üresen hagyod, a script csak megépíti az ipa-t, a feltöltést
# Transporterrel kézzel kell elvégezned.
API_KEY_ID=""
API_ISSUER_ID=""

if [[ "$1" == "--clean" ]]; then
  echo "0) Flutter clean..."
  flutter clean
fi

echo "1) Flutter pub get..."
flutter pub get

echo "2) Flutter IPA build..."
flutter build ipa --release

IPA_PATH=$(ls build/ios/ipa/*.ipa | head -n 1)
echo "Elkészült: $IPA_PATH"

if [[ -n "$API_KEY_ID" && -n "$API_ISSUER_ID" ]]; then
  echo "3) Feltöltés App Store Connectbe..."
  xcrun altool --upload-app -f "$IPA_PATH" -t ios --apiKey "$API_KEY_ID" --apiIssuer "$API_ISSUER_ID"
  echo "Feltöltve. Nézd az App Store Connect > TestFlight fület a feldolgozás állapotáért."
else
  echo "3) API kulcs nincs beállítva a scriptben."
  echo "   Nyisd meg a Transporter appot, húzd bele: $IPA_PATH"
fi