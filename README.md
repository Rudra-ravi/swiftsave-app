# SwiftSave

Cross-platform Flutter media downloader powered by `yt-dlp` and FFmpeg.

[![CI](https://github.com/Rudra-ravi/swiftsave-app/actions/workflows/ci.yml/badge.svg)](https://github.com/Rudra-ravi/swiftsave-app/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/Rudra-ravi/swiftsave-app?sort=semver)](https://github.com/Rudra-ravi/swiftsave-app/releases)
[![License](https://img.shields.io/github/license/Rudra-ravi/swiftsave-app)](https://github.com/Rudra-ravi/swiftsave-app/blob/main/LICENSE)

## What It Does

SwiftSave provides a unified app experience for downloading media across platforms while keeping platform-specific runtime behavior isolated under engine and tooling layers.

Key capabilities:
- Unified engine contract via `IDownloadEngine`
- Android runtime through native bridge plugin (`plugins/ytdlp_bridge`)
- Desktop/macOS runtime via local `yt-dlp` + FFmpeg processes
- In-app Tool Manager for install, update, and repair workflows
- Queue/retry/progress orchestration with Android background processing

## Platform Support

| Platform | Status | Runtime Path |
| --- | --- | --- |
| Android | Supported | Native plugin bridge + Python runtime integration |
| Linux | Supported | Process-based `yt-dlp` + FFmpeg |
| Windows | Supported | Process-based `yt-dlp` + FFmpeg |
| macOS | Supported | Process-based `yt-dlp` + FFmpeg |
| iOS | Not currently targeted | N/A |

## Quick Start

### Prerequisites

- Flutter stable
- Dart SDK (via Flutter)
- JDK 17 (required for Android build gates)
- Android SDK (for Android builds/runs)

### Run locally

```bash
flutter pub get
flutter run
```

### Quality gates

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

### Android build gates

```bash
cd android
./gradlew :app:compileDebugKotlin
./gradlew :app:assembleDebug
./gradlew :app:assembleDebug --warning-mode all
```

Gradle forward-compat note:
`--warning-mode all` currently reports deprecations from third-party plugin `build.gradle` files in pub cache (Groovy space-assignment syntax). This repository is kept on current stable Gradle/Flutter defaults while plugin maintainers migrate to Gradle 10-compatible syntax.

### Desktop build gates

```bash
flutter build linux --release
flutter build windows --release
flutter build macos --release
```

## Repository Layout

- `lib/screens/`, `lib/widgets/`, `lib/viewmodels/`: presentation layer
- `lib/models/`, `lib/core/interfaces/`: domain contracts and models
- `lib/services/download/`: orchestration, execution, retries, notifications
- `lib/services/engine/`: platform download engines + parsing
- `lib/services/tools/`: tool install/update/integrity services
- `plugins/ytdlp_bridge/`: Android bridge plugin implementation

Architecture details: see `ARCHITECTURE.md`.

## Releases

Release automation is implemented in `.github/workflows/release.yml`.

- Tag `vX.Y.Z` for stable releases
- Tag `vX.Y.Z-rc.N` for prereleases
- Artifacts include Android, Linux, Windows, and macOS packages
- macOS signing/notarization is applied only when required secrets are configured

## CI

CI is defined in `.github/workflows/ci.yml` and runs:
- analyze
- tests
- Linux build gate
- Android Kotlin compile and assemble gates

## Community

- Contributing: `CONTRIBUTING.md`
- Code of Conduct: `CODE_OF_CONDUCT.md`
- Security Policy: `SECURITY.md`
- Support: `SUPPORT.md`

## Responsible Use

Use this project only in ways that comply with copyright law, local regulations, and platform/service terms.

## License

MIT License. See `LICENSE`.
