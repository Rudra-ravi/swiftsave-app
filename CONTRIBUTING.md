# Contributing

Thanks for contributing to this project.

## Development setup

1. Install Flutter, JDK 17, and Android SDK.
2. Run:

```bash
flutter pub get
```

3. Run the app:

```bash
flutter run
```

## Before opening a PR

Run these checks:

```bash
dart format --set-exit-if-changed .
dart analyze
flutter test
```

If your change touches Android Gradle or plugin build config, also run:

```bash
cd android
./gradlew :app:compileDebugKotlin
./gradlew :app:assembleDebug
```

## Pull request guidelines

- Keep PRs focused and small.
- Add or update tests for behavior changes.
- Update docs for user-facing changes.
- Do not commit secrets, keystores, or `key.properties`.

## Reporting bugs

Open a GitHub issue with:

- Device/Android version
- App version/commit
- Steps to reproduce
- Expected behavior
- Actual behavior
- Relevant logs (without secrets)
