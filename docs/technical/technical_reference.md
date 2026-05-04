# Technical Reference

<!--
  FILE PURPOSE   : Configuration, setup, and usage patterns for every library and technical concern in the project.

  WHAT BELONGS   : Library versions, initialization, configuration, code patterns, and constraints to follow.
  
  WHAT DOES NOT  : Implementation status (→ todo.md), feature design (→ features_architecture.md),
                   schema details (→ database_and_models.md), active work (→ current_work.md).
  
  UPDATE WHEN    : A new library is added, a configuration changes, or a usage pattern is established.

  FORMAT: 
            ## N. Library / Concern Name

            **Library**: `package-name` **Version**: x.y.z

            ### Configuration
            \```dart
            // minimal setup snippet
            \```

            ### Usage Pattern
            - bullet: rule or constraint to follow
-->

---

## 1. Dependency Injection — get_it + injectable

**Libraries**: `get_it: ^9.2.1`, `injectable: ^2.5.1`, `injectable_generator: ^2.7.0` (dev)

### Annotations

| Annotation | Purpose |
|---|---|
| `@singleton` | Singleton — Database, repositories |
| `@preResolve` | Async singleton resolved before `runApp()` (Database) |
| `@injectable` | Factory — new instance per injection (Cubits, use cases) |
| `@module` | Abstract class providing bindings for third-party types |
| `@injectableInit` | Marks the DI entry point for code generation |

### Entry Point

```dart
// common/utils/getit_utils.dart
final getIt = GetIt.instance;

@injectableInit
Future<void> configureDependencies() => getIt.init();

class GetItUtils {
  static Future<void> setup() => configureDependencies();
}
```

### Initialization

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetItUtils.setup();
  runApp(const MyApp());
}
```

### Code Generation

Run after any DI annotation change:
```bash
dart run build_runner build
```

Generated file: `common/utils/getit_utils.config.dart`

---

## 2. Database — sqflite

**Library**: `sqflite: ^2.4.2`, `path: ^1.9.1`

### Configuration

```dart
// core/data/db_module.dart
@module
abstract class DatabaseModule {
  @preResolve
  @singleton
  Future<Database> initDatabase() async {
    final path = join(await getDatabasesPath(), 'gym_tracker.db');
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
  }
}
```

### Key Patterns

- **Foreign keys always ON** — enforced in `onConfigure`.
- **Static column names** — all models define `static const` column name constants. Schema DDL references these constants.
- **`DatabaseExecutor` parameter** — all DAO write methods accept `DatabaseExecutor db` to support both standalone and transactional calls.
- **Optional `DatabaseExecutor` for reads** — `[DatabaseExecutor? db]` pattern for methods that need transaction isolation (uses `db ?? _db`).
- **Batch operations** — use `IN (?)` clauses for batch fetches to avoid N+1 queries.
- **Order column quoting** — `"order"` is a SQL reserved word; always quoted in DDL and queries.

### Seeding

- Seed data loaded from `assets/seed_data.json` via `rootBundle.loadString()`.
- Batch insert with `ConflictAlgorithm.replace`.
- Seeds: muscles, equipment, exercises, exercise secondary muscles.
- File: `core/data/seed_helper.dart`.

---

## 3. State Management — flutter_bloc

**Library**: `flutter_bloc: ^9.1.1`, `equatable: ^2.0.7`

### Pattern

- **Cubit** for simple state with method calls (most screens).
- **Bloc** with explicit events only when event mapping adds clarity.
- State classes extend `Equatable` for efficient rebuilds.

### Usage Rules

- No business logic inside widgets — only display and callback dispatch to cubit.
- Prefer `const` constructors wherever possible.
- Do not pass cubits/blocs down the widget tree — use `BlocProvider` / `context.read<XxxCubit>()`.
- One-shot side effects (navigation, snackbars) via `BlocListener`.
- State and lambdas are passed down — never pass the Cubit itself into child widgets.

---

## 4. UUID Generation

**Library**: `uuid: ^4.5.1`

### Configuration

```dart
// core/data/uuid_module.dart
@module
abstract class UuidModule {
  @singleton
  Uuid get uuid => const Uuid();
}
```

### Usage

All new entities use UUID v4 for primary keys:
```dart
final id = _uuid.v4();
final entity = Entity(id: id, ...);
```

Injected via DI into repository constructors that create entities.

---

## 5. Model Serialization Pattern

All models use manual `toMap()` / `fromMap()` for sqflite compatibility:

```dart
class Exercise {
  static const tableName = 'exercises';
  static const columnId = 'id';
  static const columnName = 'name';
  // ...

  Map<String, dynamic> toMap() => {
    columnId: id,
    columnName: name,
    // ...
  };

  factory Exercise.fromMap(Map<String, dynamic> map) => Exercise(
    id: map[columnId] as String,
    name: map[columnName] as String,
    // ...
  );
}
```

### Enum Serialization

Enums use extensions with `dbValue` (snake_case string) and standalone `xxxFromDbValue()` functions:

```dart
enum SetType { warmUp, working, dropSet, amrap, failure }

extension SetTypeX on SetType {
  String get dbValue => switch (this) {
    SetType.warmUp => 'warm_up',
    // ...
  };
}

SetType setTypeFromDbValue(String? value) {
  return SetType.values.firstWhere(
    (t) => t.dbValue == value,
    orElse: () => SetType.working,
  );
}
```

---

## 6. Transaction Patterns

### Read-Modify-Write

Used when a read is needed inside the same transaction:

```dart
await _db.transaction((txn) async {
  final set = await _workoutSetDao.getById(setId, txn);
  // ... modify
  await _workoutSetDao.update(updatedSet, txn);
});
```

### Multi-Step Write

Multiple writes must succeed or fail together:

```dart
await _db.transaction((txn) async {
  await _routineDao.insert(routine, txn);
  for (final exercise in exercises) {
    await _routineExerciseDao.insert(exercise, txn);
  }
});
```

### Volume Recalculation

Volume is always recalculated inside the same transaction as set changes:

```dart
await _db.transaction((txn) async {
  await _workoutSetDao.update(set, txn);
  final newVolume = await _workoutSetDao.computeVolume(workoutId, txn);
  await _workoutDao.updateVolume(workoutId, newVolume, txn);
});
```

---

## 7. Batch Query Pattern

### IN Clause

Avoid N+1 queries with batch fetches:

```dart
final placeholders = List.filled(ids.length, '?').join(',');
final maps = await db.query(
  tableName,
  where: 'id IN ($placeholders)',
  whereArgs: ids,
);
```

### Grouping in Dart

Group batch results by parent ID after fetch:

```dart
final grouped = <String, List<Item>>{};
for (final item in items) {
  grouped.putIfAbsent(item.parentId, () => []).add(item);
}
```

---

## 8. Project Configuration

### `pubspec.yaml` Key Dependencies

| Package | Version | Purpose |
|---|---|---|
| `flutter_bloc` | ^9.1.1 | State management (BLoC/Cubit) |
| `equatable` | ^2.0.7 | Value equality for state classes |
| `get_it` | ^9.2.1 | Service locator for DI |
| `injectable` | ^2.5.1 | DI annotation-based code generation |
| `sqflite` | ^2.4.2 | SQLite database |
| `path` | ^1.9.1 | File path manipulation |
| `uuid` | ^4.5.1 | UUID generation |

### Dev Dependencies

| Package | Version | Purpose |
|---|---|---|
| `build_runner` | ^2.5.4 | Code generation runner |
| `injectable_generator` | ^2.7.0 | Injectable code gen |
| `flutter_lints` | ^6.0.0 | Linting rules |

### SDK

- Dart SDK: `^3.10.7`
- Flutter: `uses-material-design: true`

### Assets

- `assets/seed_data.json` — exercise, muscle, equipment seed data
