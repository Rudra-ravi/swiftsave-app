# Signing Setup

## Android signing (stable release)

Generate keystore:

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA \
  -keysize 2048 -validity 10000 -alias upload -storetype JKS
```

Create base64 secret:

```bash
base64 < ~/upload-keystore.jks | tr -d '\n'
```

Set GitHub secrets:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

Notes:
- Stable tags (`vX.Y.Z`) require signing secrets.
- RC tags (`vX.Y.Z-rc.N`) allow fallback signing for test distribution.

## macOS signing/notarization (optional in this phase)

Configure secrets:

- `MACOS_SIGN_IDENTITY`
- `MACOS_APPLE_ID`
- `MACOS_APP_PASSWORD`
- `MACOS_TEAM_ID`

Behavior:
- RC builds: unsigned artifacts are allowed.
- Stable builds: workflow signs/notarizes only when secrets are present.

## Security

- Never commit `android/key.properties`.
- Never commit keystore files.
- Keep secrets only in GitHub Actions secrets.
