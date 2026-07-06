#!/bin/bash
# Build, ad-hoc sign, and install FluidVoice to /Applications for local/dev use.
# ponytail: ad-hoc signing only, fine for a personal source build, not for distribution.
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
DERIVED_DATA="${PROJECT_DIR}/DerivedData"
APP_BUILD="${DERIVED_DATA}/Build/Products/Release/FluidVoice.app"
APP_DEST="/Applications/FluidVoice.app"

echo "Building..."
xcodebuild -project "${PROJECT_DIR}/Fluid.xcodeproj" -scheme Fluid -destination 'platform=macOS' \
  -derivedDataPath "${DERIVED_DATA}" build CODE_SIGNING_ALLOWED=NO

echo "Embedding frameworks..."
mkdir -p "${APP_BUILD}/Contents/Frameworks"
cp -R "${DERIVED_DATA}/Build/Products/Release/PackageFrameworks/MediaRemoteAdapter.framework" \
  "${APP_BUILD}/Contents/Frameworks/"

echo "Signing..."
codesign --force --sign - "${APP_BUILD}/Contents/Frameworks/MediaRemoteAdapter.framework"
codesign --force --sign - --entitlements "${PROJECT_DIR}/Fluid.entitlements" "${APP_BUILD}"

echo "Installing to ${APP_DEST}..."
pkill -f "${APP_DEST}/Contents/MacOS/FluidVoice" 2>/dev/null || true
rm -rf "${APP_DEST}"
cp -R "${APP_BUILD}" "${APP_DEST}"

open "${APP_DEST}"
echo "Done."
