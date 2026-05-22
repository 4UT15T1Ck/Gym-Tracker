# Technical Reference

<!--
  FILE PURPOSE   : Configuration, setup, and usage patterns for libraries and technical concerns.

  WHAT BELONGS   : Library versions, initialization, configuration, code patterns, and constraints to follow.

  WHAT DOES NOT  : Implementation status (-> todo.md), feature design (-> features_architecture.md),
                   schema details (-> database_and_models.md), active work (-> current_work.md).

  UPDATE WHEN    : A new library is added, a configuration changes, or a usage pattern is established.
-->

---

## 1. Dependency Injection

**Libraries**: `get_it: ^9.2.1`, `injectable: ^2.5.1`, `injectable_generator: ^2.7.0`

### Entry Point

```dart
final getIt = GetIt.instance;

@injectableInit
Future<void> configureDependencies() => getIt.init();

class GetItUtils {
  static Future<void> setup() async {
    await configureDependencies();
    // Manual singleton registrations live here when lifecycle wiring is custom.
  }
}
```

### Registration Patterns

| Pattern | Use |
|---|---|
| `@preResolve @singleton` | Async database singleton |
| `@LazySingleton(as: SomeRepository)` | Repository implementations |
| `@LazySingleton()` | Global Cubits reused by the shell |
| `@injectable` | DAOs and route-scoped Cubits |
| Manual `getIt.register...` | Services or Blocs needing custom callbacks/lifecycle |

### Code Generation

Run after DI annotation changes:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Generated file: `lib/common/utils/getit_utils.config.dart`

Do not edit the generated file by hand.

---

## 2. Database

**Libraries**: `sqflite: ^2.4.2`, `path: ^1.9.1`

### Configuration

```dart
return openDatabase(
  path,
  version: 1,
  onConfigure: (db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  },
  onCreate: (db, version) async {
    await _createTables(db);
    await _createIndexes(db);
    await seedDatabaseFromJson(db);
  },
);
```

### Key Patterns

- Foreign keys are enabled in `onConfigure`.
- Model classes define static table and column constants.
- Models use manual `toMap()` / `fromMap()` for SQLite rows.
- DAO writes accept `DatabaseExecutor` so repository transactions can reuse the same DAO method.
- Some DAO reads accept optional `[DatabaseExecutor? db]` for transaction isolation.
- Batch reads use dynamic placeholders for `IN (...)`.
- The SQL column name `order` is always quoted as `"order"`.

### Migration Rule

For a schema change:

1. Bump `_databaseVersion`.
2. Add `onUpgrade`.
3. Write additive migration SQL.
4. Do not drop/recreate user tables in production.

---

## 3. Seed Data

**Asset**: `assets/seed_data.json`

Seed data is loaded in `DatabaseModule.onCreate()` by `seedDatabaseFromJson()`.

Seeded data:

- muscles
- equipment
- exercises
- exercise secondary muscle mappings

Seed inserts use `ConflictAlgorithm.replace`.

---

## 4. State Management

**Libraries**: `flutter_bloc: ^9.1.1`, `equatable: ^2.0.7`

### Cubit Pattern

- Use Cubit for method-driven screen state.
- State classes extend `Equatable`.
- Use `copyWith` for state transitions.
- Keep async calls and error handling inside the Cubit.
- Screens render with `BlocBuilder`.
- One-shot UI side effects use `BlocListener` when needed.

### Bloc Pattern

Use Bloc for event-driven flows. Current example:

- `RestTimerBloc` handles start, tick, adjust, skip, and cancel events.

---

## 5. Notifications And Rest Timer

**Libraries**: `flutter_local_notifications: ^17.2.3`, `timezone: ^0.9.4`, `flutter_timezone: ^4.1.0`, `vibration: ^2.0.0`

### Startup

`main.dart` initializes notifications only on Android/iOS:

```dart
if (Platform.isAndroid || Platform.isIOS) {
  final notificationService = getIt<NotificationService>();
  await notificationService.init();
  await notificationService.requestPermission();
}
```

### Channels

| Channel | Purpose |
|---|---|
| `rest_timer` | High-importance rest complete alert |
| `workout_in_progress` | Ongoing workout notification |

### Routing

Notification taps route to `/active-workout` with `ActiveWorkoutRouteArgs`.

### Timer Rules

- App countdown state lives in `RestTimerBloc`.
- OS notifications are scheduled for the end timestamp only.
- Skip/cancel paths cancel scheduled rest notifications.
- Workout completion/cancellation clears workout notifications.

---

## 6. Preferences

**Library**: `shared_preferences: ^2.5.3`

`PreferencesStore` stores lightweight profile identity:

| Key | Purpose |
|---|---|
| `profile.username` | Display name, defaults to `Alex` |
| `profile.initials` | Optional initials override |

Initialize before DI-dependent Cubits load:

```dart
await PreferencesStore.init();
```

---

## 7. UUID Generation

**Library**: `uuid: ^4.5.1`

`UuidModule` provides a singleton `Uuid`.

Repositories generate IDs before inserts:

```dart
final id = _uuid.v4();
```

---

## 8. Repository And Transaction Patterns

### Read-Modify-Write

```dart
await _db.transaction((txn) async {
  final set = await _workoutSetDao.getById(setId, txn);
  await _workoutSetDao.update(updatedSet, txn);
});
```

### Multi-Step Writes

```dart
await _db.transaction((txn) async {
  await _routineDao.insert(routine, txn);
  for (final exercise in exercises) {
    await _routineExerciseDao.insert(exercise, txn);
  }
});
```

### Volume Recalculation

Workout volume is recomputed inside the same transaction as set completion, uncompletion, or removal.

---

## 9. Routing

Routes are centralized in `common/routes/routes.dart`.

Use typed argument classes from `route_args.dart`:

- `ActiveWorkoutRouteArgs`
- `AddExerciseRouteArgs`
- `ExerciseDetailRouteArgs`
- `WorkoutDetailRouteArgs`
- `RoutineDetailRouteArgs`
- `EditRoutineRouteArgs`

Provider rules:

- Use `BlocProvider.value` for singleton Cubits.
- Use `BlocProvider(create:)` for route-scoped Cubits.

---

## 10. Project Configuration

### Runtime Dependencies

| Package | Version | Purpose |
|---|---|---|
| `flutter_bloc` | ^9.1.1 | State management |
| `equatable` | ^2.0.7 | State equality |
| `get_it` | ^9.2.1 | Service locator |
| `injectable` | ^2.5.1 | DI annotations |
| `sqflite` | ^2.4.2 | SQLite persistence |
| `path` | ^1.9.1 | Database path joining |
| `uuid` | ^4.5.1 | Primary key generation |
| `shared_preferences` | ^2.5.3 | Lightweight preferences |
| `flutter_local_notifications` | ^17.2.3 | Local notifications |
| `timezone` | ^0.9.4 | Zoned notification scheduling |
| `flutter_timezone` | ^4.1.0 | Device timezone lookup |
| `vibration` | ^2.0.0 | Rest timer haptic feedback |

### Dev Dependencies

| Package | Version | Purpose |
|---|---|---|
| `flutter_test` | SDK | Widget/unit tests |
| `flutter_lints` | ^6.0.0 | Lint rules |
| `build_runner` | ^2.5.4 | Code generation runner |
| `injectable_generator` | ^2.7.0 | Injectable code generation |

### SDK And Assets

- Dart SDK: `^3.10.7`
- Material icons enabled: `uses-material-design: true`
- Seed data asset: `assets/seed_data.json`
