# swiftsave-app

Cross-platform Flutter downloader powered by `yt-dlp` and FFmpeg.

Primary targets:
- Android
- Linux
- Windows
- macOS

## Highlights

- Unified download engine abstraction (`IDownloadEngine`)
- Android runtime via native bridge (`plugins/ytdlp_bridge`)
- Desktop/macOS runtime via process wrapper (`yt-dlp` + FFmpeg)
- In-app Tool Manager for install/update/repair of desktop tools
- Queue, retries, background processing on Android
- GitHub Release artifacts for all primary targets

## Project Layout

- `lib/services/engine/`: platform download engines + parser
- `lib/services/tools/`: registry + tool install/integrity services
- `lib/screens/tools/`: Tool Manager UI
- `lib/screens/onboarding/`: first-run setup wizard
- `plugins/ytdlp_bridge/`: Android bridge and Python runtime integration

## Local Development

```bash
flutter pub get
flutter analyze
flutter test
```

### Android gates

```bash
cd android
./gradlew :app:compileDebugKotlin
./gradlew :app:assembleDebug
```

### Desktop/macOS gates

```bash
flutter build linux --release
flutter build windows --release
flutter build macos --release
```

## CI/CD

- CI workflow: `.github/workflows/ci.yml`
  - analyze + tests + linux build gate + android compile/assemble gates
- Release workflow: `.github/workflows/release.yml`
  - tag-driven artifacts for Android, Linux, Windows, macOS
  - prerelease for `vX.Y.Z-rc.N`
  - stable release for `vX.Y.Z`
  - optional macOS signing/notarization when secrets are configured
  - tool-bundle manifest publishing (`tools-manifest.json`)

## Responsible Use

You are responsible for legal compliance, copyright compliance, and each platform's terms of service.

## License

MIT. See `LICENSE`.
