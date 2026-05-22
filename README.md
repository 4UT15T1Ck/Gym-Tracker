# Gym Tracker

Flutter fitness tracker for planning routines, logging active workouts, browsing exercises, and reviewing training progress.

## Current App Surface

- Home dashboard with a redesigned dark card-based UI (header, quick start, weekly streak, last workout, recent PRs, and muscle recovery) while keeping the same existing business logic and flows.
- Workout tab for starting an empty workout, creating routines, editing/deleting routines, and starting workouts from routines.
- Active workout flow with exercise/set management, set completion, rest timer controls, and in-progress workout banner.
- Exercise library with search/filter support and exercise detail stats.
- Profile area with progress chart, statistics, muscle map, body measurements, workout calendar/history, and workout detail review.
- Local SQLite storage seeded from `assets/seed_data.json`.

## Tech Stack

- Dart SDK `^3.10.7` (Flutter via installed SDK)
- `flutter_bloc` + `equatable` for presentation state
- `get_it` + `injectable` for dependency injection
- `sqflite` for local persistence
- `shared_preferences` for lightweight profile settings
- `flutter_local_notifications`, `timezone`, `flutter_timezone`, and `vibration` for workout/rest timer feedback

## Setup

1. Install dependencies:

   ```bash
   flutter pub get
   ```

2. Generate injectable registrations after any DI annotation change:

   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

3. Run the app:

   ```bash
   flutter run
   ```

## Useful Commands

```bash
flutter analyze
flutter test
dart format lib test
```

Note: `lib/common/utils/getit_utils.config.dart` is generated and ignored by git. Regenerate it locally instead of editing it by hand.

## Documentation Map

- `docs/architecture/general_architecture.md` - package layout, layer rules, DI, and navigation.
- `docs/architecture/features_architecture.md` - feature-by-feature component map.
- `docs/architecture/database_and_models.md` - SQLite schema, models, DAOs, and migration rules.
- `docs/architecture/DATA_ACCESS_LAYER.md` - deeper DAO/repository reference.
- `docs/technical/technical_reference.md` - package configuration and implementation patterns.
- `docs/progress/todo.md` - implementation status checklist.
- `docs/progress/current_work.md` - current focus and next engineering follow-ups.
- `docs/progress/progress_log.md` - append-only project history.
