# General Architecture

<!--
  FILE PURPOSE   : Single source of truth for app structure, layers, patterns, and wiring.

  WHAT BELONGS   : Package layout, layer rules, BLoC/Cubit pattern, navigation structure, DI setup.

  WHAT DOES NOT  : Feature-level detail (-> features_architecture.md), tech config (-> technical_reference.md),
                   implementation status or TODOs (-> todo.md / current_work.md).

  UPDATE WHEN    : A new layer convention is introduced, navigation structure changes,
                   or a project-wide architectural decision is made.
-->

---

## Package Structure

```text
lib/
|-- app.dart                       # MaterialApp, theme, route generator, global Bloc providers
|-- main.dart                      # Platform init, preferences, DI, notifications, app bootstrap
|-- common/
|   |-- routes/                    # Route names, onGenerateRoute, route argument objects
|   `-- utils/                     # Date formatting, GetIt setup, muscle grouping helpers
|-- core/
|   |-- dao/                       # Data Access Objects, raw SQL via sqflite
|   |-- data/                      # DatabaseModule, seed helper, UUID module, preferences store
|   |-- enums/                     # SetType, ExerciseTrackingType, WorkoutStatus
|   |-- models/                    # DB entity models with toMap/fromMap
|   |-- repositories/              # Repository interfaces and composite read models
|   |-- repository_impl/           # Repository implementations
|   `-- services/                  # Notifications and dashboard aggregation
`-- features/
    |-- home/                      # Home dashboard
    |-- library/                   # Exercise browser and exercise detail
    |-- profile/                   # Profile, stats, measurements, history
    |-- shell/                     # Bottom navigation and active workout banner
    `-- workout/                   # Routine and active workout flows
```

---

## Architectural Layers

### Dependency Flow

```text
Presentation -> Domain contracts -> Data implementations
                  ^                  |
                  `------------------`
```

- Presentation screens use Cubits/Blocs and call repository interfaces.
- Repository interfaces and composite read models live in `core/repositories/`.
- Repository implementations own transactions and compose DAO results.
- DAOs contain SQL and return typed entity models. Presentation does not call DAOs directly.
- Services in `core/services/` aggregate app-level behavior that spans repositories or platform APIs.

### Domain / Repository Interfaces

- Entity models and enums: `core/models/`, `core/enums/`
- Repository contracts: `core/repositories/`
- Composite read models: `RoutineDetail`, `WorkoutDetail`, `ExerciseDetail`, `WorkoutSummary`, stats records in `repository_models.dart`

### Data Layer

- `DatabaseModule` creates the SQLite database, tables, indexes, and seed data.
- DAOs wrap `sqflite` queries.
- Repository implementations combine DAO calls, perform transactions, and generate UUIDs.
- `PreferencesStore` wraps `shared_preferences` for lightweight profile settings.

### Presentation Layer

- Screens live under `features/<feature>/presentation/`.
- State classes and Cubits/Blocs live under `features/<feature>/bloc/`.
- Most screens use `Cubit`; the rest timer uses `Bloc` because it is event/timer driven.
- `app.dart` provides global Cubits for the shell/home/workout/profile surfaces and route-specific providers for detail flows.
- The Home dashboard UI is section-based and composed from private presentation widgets with local style tokens in a single screen file, so visual redesigns can ship without touching shared business logic.

---

## BLoC / Cubit Pattern

```dart
class XxxState extends Equatable {
  final bool isLoading;
  final String? errorMessage;

  const XxxState({this.isLoading = false, this.errorMessage});

  @override
  List<Object?> get props => [isLoading, errorMessage];
}

class XxxCubit extends Cubit<XxxState> {
  XxxCubit(this._repository) : super(const XxxState());

  final XxxRepository _repository;
}
```

- Use `Cubit` for command-style screen state.
- Use `Bloc` when event sequencing is meaningful, such as rest timer start/tick/adjust/skip/cancel.
- Use `BlocBuilder` for rendering and `BlocListener` for one-shot side effects.
- Child widgets receive values and callbacks, not Cubit instances.
- Keep business rules in Cubits, repositories, or services; widgets only coordinate UI interactions.

---

## Dependency Injection

The project uses `get_it` plus `injectable`.

| Registration | Used for |
|---|---|
| `@singleton` / `@preResolve` | Async database singleton |
| `@LazySingleton(as: Interface)` | Repository implementations |
| `@LazySingleton()` | App-level Cubits that should survive tab switches |
| `@injectable` | Route-scoped Cubits and DAOs |
| Manual registration in `GetItUtils.setup()` | Shell active workout Cubit, notification service, rest timer Bloc |

Entry point: `common/utils/getit_utils.dart`

Generated file: `common/utils/getit_utils.config.dart`

Run after DI annotation changes:

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Navigation

Navigation is centralized in `common/routes/routes.dart` via `Routes.onGenerateRoute`.

```text
/
`-- MainShellScreen
    |-- HomeDashboardScreen
    |-- WorkoutHomeScreen
    `-- ProfileHomeScreen

Workout routes
|-- /active-workout
|-- /add-exercise
|-- /create-routine
|-- /routine-detail
`-- /edit-routine

Library routes
|-- /exercise-list
`-- /exercise-detail

Profile routes
|-- /statistics
|-- /muscle-map
|-- /measures
|-- /workout-history
`-- /workout-detail
```

Route argument objects live in `common/routes/route_args.dart`.

Provider ownership rules:

- Singleton/global Cubits are provided with `BlocProvider.value`.
- Route-scoped Cubits are created in the route builder and auto-closed with `BlocProvider(create:)`.
- Active workout uses a singleton Cubit so the shell banner, rest timer, and active workout screen remain synchronized.

---

## App Bootstrap

`main.dart` performs startup in this order:

1. `WidgetsFlutterBinding.ensureInitialized()`
2. `PreferencesStore.init()`
3. `GetItUtils.setup()`
4. Notification initialization and permission request on Android/iOS
5. Initial loads for Home, Workout, and Profile Cubits
6. `runApp(const MainApp())`

`app.dart` configures:

- Dark Material 3 theme from a blue seed color
- Global `navigatorKey` owned by `NotificationService`
- Cupertino page transitions for Android and iOS
- `Routes.onGenerateRoute`
- Initial route `/`

---

## Data Flow Example: Start Workout From Routine

```text
WorkoutHomeScreen
  -> WorkoutHomeCubit.startRoutine()
  -> WorkoutRepository.startWorkout(name, routineId)
  -> WorkoutRepositoryImpl transaction
  -> WorkoutDao inserts workout
  -> RoutineExerciseDao / RoutineSetDao fetch routine template
  -> WorkoutExerciseDao / WorkoutSetDao copy exercises and sets
  -> WorkoutDetail returned
  -> ShellActiveWorkoutCubit.refreshNow()
  -> Navigator pushes /active-workout
```
