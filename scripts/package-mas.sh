#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="PaperPad Notes & Clipboard"
DIST_DIR="$ROOT_DIR/dist"
APP_PATH="$DIST_DIR/$APP_NAME.app"
PKG_PATH="$DIST_DIR/PaperPad-Notes-and-Clipboard.pkg"
ENTITLEMENTS="$ROOT_DIR/Packaging/PaperPad.entitlements"

: "${APP_SIGN_IDENTITY:?Set APP_SIGN_IDENTITY to your Mac App Distribution identity}"
: "${INSTALLER_SIGN_IDENTITY:?Set INSTALLER_SIGN_IDENTITY to your Mac Installer Distribution identity}"
: "${PROVISIONING_PROFILE:?Set PROVISIONING_PROFILE to the App Store provisioning profile path}"

"$ROOT_DIR/scripts/build-app.sh"

cp "$PROVISIONING_PROFILE" "$APP_PATH/Contents/embedded.provisionprofile"

codesign --force \
  --sign "$APP_SIGN_IDENTITY" \
  --entitlements "$ENTITLEMENTS" \
  --options runtime \
  "$APP_PATH"

codesign --verify --deep --strict --verbose=2 "$APP_PATH"

rm -f "$PKG_PATH"
productbuild \
  --component "$APP_PATH" /Applications \
  --sign "$INSTALLER_SIGN_IDENTITY" \
  "$PKG_PATH"

pkgutil --check-signature "$PKG_PATH"

echo "$PKG_PATH"
