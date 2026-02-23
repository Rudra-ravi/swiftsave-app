# Project Agent Notes

## Documentation Contract
- Keep `README.md` focused on setup/usage and keep `ARCHITECTURE.md` focused on system design/runtime flows.
- If adding or moving core modules (engine, tools, onboarding, queue/service layers), update `ARCHITECTURE.md` in the same change.

## Prevention Notes

### Build Verification
- If a fix touches Android Gradle config, then run both `./gradlew :app:compileDebugKotlin` and `./gradlew :app:assembleDebug` before claiming success.
- If `dart analyze` and `flutter test` pass, then still run one Android build gate to catch plugin JVM-target mismatches.

### Release Packaging
- If Linux release packaging uses Fastforge AppImage targets, then ensure `appimagetool` is installed on CI and available on `PATH` before running `fastforge package`.

### Gradle Safety
- If aligning Java/Kotlin targets across plugins, then avoid `Project.afterEvaluate` hooks and use project-safe configuration timing (`gradle.projectsEvaluated` or lazy task configuration).

### Workspace Hygiene
- If the repository is already dirty, then change only files required for the current fix and do not revert unrelated user edits.
- If a user requests a single CI/release pipeline, then keep exactly one workflow file in `.github/workflows` by merging or removing duplicates.
- If the user updates target platforms mid-task, then restate the final platform matrix and apply it consistently across release workflow, docs, and UI/platform checks.

### Runtime Reliability
- If code runs in a background isolate, then do not call UI-activity plugins (for example wakelock or FFmpegKit event-channel flows) there.
- If download progress must update UI cards/stats, then bridge plugin progress events to `FlutterBackgroundService.invoke('progress', ...)`.
- If a queue item exposes an `Open` action, then resolve a concrete downloaded file path (`filename`/`filenames`) instead of using the output directory.

### Plugin API Drift
- If using `flutter_local_notifications` v20+, then call `initialize`/`show` with named parameters (`settings:`, `id:`, `notificationDetails:`) to avoid compile-time failures.

### Localization Gate
- If adding new UI labels, then add matching ARB keys for `app_en.arb`, `app_es.arb`, and `app_hi.arb` and regenerate l10n before `flutter analyze`.

### Service Channel Safety
- If using `FlutterBackgroundService.invoke` from shared services, then wrap calls in `MissingPluginException` guards and avoid invoking from background isolate code paths.

### Tooling Discipline
- If applying code patches, then call the `apply_patch` tool directly and never invoke patching through `exec_command`.

### Small-Screen Layout
- If adding chips/badges inside constrained `Row` content, then wrap with `Flexible` + `FittedBox(scaleDown)` to prevent `RenderFlex overflow` on narrow widths.
