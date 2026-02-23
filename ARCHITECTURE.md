# Architecture

## Overview
`swiftsave-app` is a Flutter application for cross-platform media downloads. The design separates:
- UI and view models (`lib/screens`, `lib/viewmodels`, `lib/widgets`)
- Domain models and interfaces (`lib/models`, `lib/core/interfaces`)
- Platform/runtime execution (`lib/services/engine`, `plugins/ytdlp_bridge`)
- Tool lifecycle for desktop runtimes (`lib/services/tools`)

This split keeps platform differences localized while preserving a shared app experience.

## Layered Structure

### Presentation Layer
- `lib/screens/`: user-facing flows (home, queue, settings, onboarding, tools)
- `lib/widgets/`: reusable view components
- `lib/viewmodels/`: state orchestration for screens and services

### Domain Layer
- `lib/models/`: task, progress, tool metadata, and queue-related models
- `lib/core/interfaces/`: contracts such as `IDownloadEngine`, settings, and tool manager abstractions

### Service Layer
- `lib/services/download/`: orchestration, executor, notifications, retry/progress wiring
- `lib/services/engine/`: concrete download engines and output parsing
- `lib/services/tools/`: download/install/update/integrity logic for external tools
- `lib/services/`: cross-cutting services (background service, secure storage, path resolution, file open)

### Platform Bridge Layer
- Android: `plugins/ytdlp_bridge/` (Kotlin + Python bridge to run `yt-dlp` workflows)
- Desktop/macOS: process-based integration managed by engine + tool services

## Core Flows

### Download Flow
1. UI submits a request from home/playlist flows.
2. View model validates and creates a `DownloadTask`.
3. Orchestrator/queue routes execution to the active `IDownloadEngine`.
4. Engine emits progress events and parsed outputs.
5. Queue/view models update cards, stats, notifications, and open-file actions.

### Tool Management Flow (Desktop/macOS)
1. Tool Manager checks local tool state/manifests.
2. Install/update services fetch required binaries and verify integrity.
3. Engine availability state is refreshed.
4. UI onboarding/tool screens surface readiness and repair actions.

### Android Background Flow
1. Foreground interaction schedules or starts work.
2. Background service executes queued items.
3. Progress is bridged through service events back to app state.
4. Notification manager surfaces user-visible progress and completion.

## Dependency and Build Boundaries
- Flutter UI remains platform-agnostic where possible.
- Platform-specific logic stays in bridge or engine/tool services.
- Release/CI workflows live in `.github/workflows`.
- Android build gates (`compileDebugKotlin`, `assembleDebug`) are required checks for Gradle/plugin compatibility.

## Key Entry Points
- App bootstrap: `lib/main.dart`
- Dependency wiring: `lib/core/di/service_locator.dart`
- Download orchestration: `lib/services/download/download_orchestrator.dart`
- Android bridge plugin: `plugins/ytdlp_bridge/android/src/main/kotlin/com/example/ytdlp_bridge/YtdlpBridgePlugin.kt`

## Operational Notes
- Keep engine interfaces stable; add new platforms behind interface implementations.
- Update localization (`app_en.arb`, `app_es.arb`, `app_hi.arb`) when introducing new user-visible labels.
- Treat `ARCHITECTURE.md` updates as part of any significant structural refactor.
