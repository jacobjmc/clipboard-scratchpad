# PaperPad Notes & Clipboard

SwiftPM macOS menu bar app.

## Development

```bash
swift run
```

```bash
swift test
```

## Local App Bundle

Build a local `.app` bundle in `dist/`:

```bash
./scripts/build-app.sh
```

Output:

```text
dist/PaperPad Notes & Clipboard.app
```

## TestFlight / Mac App Store Package

Before each upload, increase `CFBundleVersion` in `Packaging/Info.plist`.

Build the signed upload package:

```bash
APP_SIGN_IDENTITY="3rd Party Mac Developer Application: JACOB COX (39X5D9F4XY)" \
INSTALLER_SIGN_IDENTITY="3rd Party Mac Developer Installer: JACOB COX (39X5D9F4XY)" \
PROVISIONING_PROFILE="$HOME/Downloads/PaperPad_Mac_App_Store.provisionprofile" \
./scripts/package-mas.sh
```

Upload this file in Transporter:

```text
dist/PaperPad-Notes-and-Clipboard.pkg
```

The package script builds the release binary, creates the `.app`, embeds the provisioning profile, strips extended attributes, signs the app, and signs the `.pkg`.

## App Store Metadata

- Bundle ID: `com.jmcdev.paperpad`
- Version: `CFBundleShortVersionString` in `Packaging/Info.plist`
- Build: `CFBundleVersion` in `Packaging/Info.plist`
- Encryption declaration: `ITSAppUsesNonExemptEncryption = false`
