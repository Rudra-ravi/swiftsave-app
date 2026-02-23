# CI/CD setup (GitHub Actions)

This repository uses two workflows:

- `CI` (`.github/workflows/ci.yml`)
  - Runs on PRs and pushes to `main`.
  - Executes: `flutter analyze`, `flutter test`, linux build gate, Android compile/assemble gates.
- `Release` (`.github/workflows/release.yml`)
  - Runs on tag pushes (`v*`) or manual dispatch.
  - Publishes GitHub release artifacts for Android, Linux, Windows, and macOS.

## Release tag strategy

- `vX.Y.Z-rc.N` -> prerelease (release candidate)
- `vX.Y.Z` -> stable release

## Published artifacts

- Android: `.apk`, `.aab`
- Linux: `.tar.gz`, `.AppImage`, `.deb`, `.rpm`
- Windows: portable `.zip`, installer `.exe`
- macOS: `.zip`, `.dmg`

Linux package formats (`.AppImage`, `.deb`, `.rpm`) are generated with Fastforge using:
- `linux/packaging/appimage/make_config.yaml`
- `linux/packaging/deb/make_config.yaml`
- `linux/packaging/rpm/make_config.yaml`
- `distribute_options.yaml`

## Required secrets

### Android stable releases

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

RC builds allow fallback signing for faster validation.

### Optional macOS stable signing/notarization

- `MACOS_SIGN_IDENTITY`
- `MACOS_APPLE_ID`
- `MACOS_APP_PASSWORD`
- `MACOS_TEAM_ID`

If these are missing, release still succeeds but macOS artifacts remain unsigned.

## Tool bundle publishing

The release workflow can publish desktop tool bundles and `tools-manifest.json`.

Expected optional folder structure in repo:

```text
tool-bundles/
  linux/
  windows/
  macos/
```

Each file may have a matching `.sha256` file. The workflow aggregates these into `dist/tools-manifest.json`.

## Typical release flow

1. Ensure CI is green.
2. Create and push tag:

```bash
git tag v1.1.0-rc.1
# or
# git tag v1.1.0

git push origin --tags
```

3. Verify artifacts attached in GitHub Releases.
