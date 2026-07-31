# Cursor_Int_Prep

Interview prep tracker for Principal-level engineering interviews — a Flutter Android app with hierarchical skill tracking, weighted progress, streaks, and daily reminders.

## App: Prep Tracker

Located in [`interview_prep_tracker/`](interview_prep_tracker/).

### Features (MVP)

- **Hierarchical checklist**: Phase → Topic → Item (DSA, LLD, System Design, Specialized, Behavioral)
- **Weighted progress**: Critical topics (e.g. Trees & Graphs) move the overall % more than low-weight areas
- **Today's focus**: Surfaces the highest-priority incomplete item
- **Status tracking**: Not Started / In Progress / Done / Needs Revision
- **Practice counters** per item with notes
- **Confidence rating** (1–5) per topic
- **Streak tracking** with 28-day heatmap calendar
- **Daily reminders** at 9 PM (configurable to 8–10 PM in Review tab)
- **Premium dark AMOLED UI** optimized for OnePlus Nord 5

### Install on your phone (OnePlus Nord 5)

1. Download the APK from the latest PR artifacts or build locally (see below).
2. On your Nord 5: **Settings → Security → Install unknown apps** → allow your file manager/browser.
3. Transfer and open `app-arm64-v8a-release.apk` (smallest, ~20 MB for arm64 phones).
4. Tap **Install**.

### Build APK locally

```bash
cd interview_prep_tracker
flutter pub get
flutter build apk --release --split-per-abi
```

APK output: `interview_prep_tracker/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`

### Run in development

```bash
cd interview_prep_tracker
flutter pub get
flutter run   # with phone connected via USB debugging
```

### Tech stack

- Flutter 3.x + Material 3 (dark AMOLED theme)
- Riverpod (state management)
- SQLite via sqflite (offline-first)
- flutter_local_notifications (daily reminders)
- google_fonts + flutter_animate (premium UI polish)

### Customizing checklist data

Edit `interview_prep_tracker/assets/seed/checklist.json`, then clear app data on device to re-seed (or uninstall/reinstall).
