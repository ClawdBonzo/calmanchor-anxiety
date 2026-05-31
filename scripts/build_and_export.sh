#!/bin/bash
# Archive + export CalmAnchor for App Store. Requires ASC API key env vars:
#   ASC_KEY_PATH ASC_KEY_ID ASC_ISSUER_ID  (App Store Connect API key, App Manager)
set -euo pipefail
cd "$(dirname "$0")/.."
ARCH=/tmp/CalmAnchor.xcarchive ; OUT=/tmp/CalmAnchor_export
rm -rf "$ARCH" "$OUT"
xcodebuild -project CalmAnchor.xcodeproj -scheme CalmAnchor -configuration Release \
  -destination 'generic/platform=iOS' -archivePath "$ARCH" archive \
  DEVELOPMENT_TEAM=3N9RY9EG8V -allowProvisioningUpdates \
  -authenticationKeyPath "$ASC_KEY_PATH" -authenticationKeyID "$ASC_KEY_ID" \
  -authenticationKeyIssuerID "$ASC_ISSUER_ID"
xcodebuild -exportArchive -archivePath "$ARCH" -exportPath "$OUT" \
  -exportOptionsPlist build/ExportOptions.plist -allowProvisioningUpdates \
  -authenticationKeyPath "$ASC_KEY_PATH" -authenticationKeyID "$ASC_KEY_ID" \
  -authenticationKeyIssuerID "$ASC_ISSUER_ID"
echo "IPA: $OUT/CalmAnchor.ipa"
echo "Upload (only with explicit go):"
echo "  mkdir -p ~/.appstoreconnect/private_keys && cp \"\$ASC_KEY_PATH\" ~/.appstoreconnect/private_keys/"
echo "  xcrun altool --upload-app -f $OUT/CalmAnchor.ipa -t ios --apiKey \$ASC_KEY_ID --apiIssuer \$ASC_ISSUER_ID"
