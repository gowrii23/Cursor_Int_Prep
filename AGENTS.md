# AGENTS.md

Guidance for AI agents working in this repository.

## Repository overview

**Cursor_Int_Prep** contains a Flutter mobile app (`interview_prep_tracker/`) for tracking Principal-level interview preparation across DSA, LLD, System Design, Specialized, and Behavioral phases.

## Development commands

| Task | Command | Notes |
|------|---------|-------|
| Install deps | `cd interview_prep_tracker && flutter pub get` | Run from repo root |
| Analyze | `cd interview_prep_tracker && flutter analyze` | Static analysis |
| Test | `cd interview_prep_tracker && flutter test` | Widget tests |
| Run (device) | `cd interview_prep_tracker && flutter run` | Requires USB debugging or emulator |
| Build APK | `cd interview_prep_tracker && flutter build apk --release --split-per-abi` | Use `app-arm64-v8a-release.apk` for Nord 5 |
| Build universal APK | `cd interview_prep_tracker && flutter build apk --release` | Larger, all ABIs |

## Project structure

```
interview_prep_tracker/
├── lib/
│   ├── main.dart              # App entry
│   ├── models/                # Phase, Topic, ChecklistItem
│   ├── data/                  # SQLite + repository
│   ├── services/              # Notifications, progress calculator
│   ├── providers/             # Riverpod providers
│   ├── screens/               # Today, Phases, Progress, Review tabs
│   ├── widgets/               # Progress ring, cards, heatmap
│   └── theme/                 # AMOLED dark Material 3 theme
└── assets/seed/checklist.json # Seed checklist data
```

## Cursor Cloud specific instructions

- **Flutter SDK** is installed at `~/flutter` and added to PATH in `~/.bashrc`.
- **Android SDK** is at `~/Android/sdk` with `ANDROID_HOME` set.
- **No backend services** — the app is fully offline/local SQLite.
- **APK builds** require Android SDK + core library desugaring (already configured in `android/app/build.gradle.kts`).
- After changing `pubspec.yaml`, run `flutter pub get` in `interview_prep_tracker/`.
- To update seed checklist: edit `assets/seed/checklist.json`. Existing installs need app data cleared to re-import.
- Nord 5 is arm64 — prefer `--split-per-abi` builds and distribute `app-arm64-v8a-release.apk`.
- Release APK for download is committed at `releases/prep-tracker-v1.0.0-arm64.apk`.
