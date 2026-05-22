# Features Architecture

<!--
  FILE PURPOSE   : Per-feature breakdown of layers, contracts, components, and design decisions.

  WHAT BELONGS   : Domain models, repository interfaces, DAO groupings, screen Cubit/BLoC triads,
                   shared components, and key design decisions per feature.

  WHAT DOES NOT  : Implementation status (-> todo.md), active work detail (-> current_work.md),
                   tech configuration (-> technical_reference.md), overall layer rules (-> general_architecture.md).

  UPDATE WHEN    : A new screen, DAO, model, component, or repository contract is added or changed.
-->

---

## 1. Shell And Navigation (`features/shell/`, `common/routes/`)

### Presentation Components

| Component | Responsibility |
|---|---|
| `MainShellScreen` | Owns bottom navigation and preserves tab state via `IndexedStack` |
| `ShellActiveWorkoutCubit` | Tracks the active workout, elapsed time, current exercise, and rest override state |
| `_ActiveWorkoutFab` | Floating active-workout banner with resume and discard actions |
| `Routes` | Central route table and route-scoped BlocProvider wiring |
| `route_args.dart` | Strongly typed route arguments for workout, routine, exercise, and detail routes |

### Design Notes

- Shell tabs are Home, Workout, and Profile.
- Tapping a tab refreshes the corresponding top-level Cubit.
- Active workout state is global so the banner and active workout screen stay in sync.
- Notifications deep-link into `/active-workout` through `NotificationService.navigatorKey`.

---

## 2. Home Dashboard (`features/home/`, `core/services/dashboard_service.dart`)

### Domain And Services

| Component | Responsibility |
|---|---|
| `DashboardService` | Aggregates workout history, routines, exercises, PRs, recovery, and routine suggestion data |
| `DashboardSummary` | View model for dashboard sections |
| `MuscleRecoverySummary` | Muscle group recovery status and label |
| `SuggestedRoutineSummary` | Routine recommendation and reason |
| `RecentPrSummary` | Lightweight personal record card data |

### Presentation Layer

| Component | Responsibility |
|---|---|
| `HomeDashboardCubit` | Loads dashboard summary, starts empty workout, starts suggested routine |
| `HomeDashboardScreen` | Renders greeting, quick start, suggested routine, weekly strip, last workout, PRs, and recovery cards |

### Design Notes

- Recovery groups are normalized by `MuscleGroupUtils`.
- Dashboard loading batches muscle lookup data before deriving recovery and suggestions.
- Suggested routine requires enough history and at least two routines.

---

## 3. Exercise Library (`features/library/`)

### Domain Layer

**Models** (`core/models/`):

| Model | Description |
|---|---|
| `Exercise` | Exercise entity with tracking type, instructions, optional media, muscle, and equipment references |
| `Muscle` | Seeded muscle entity |
| `Equipment` | Seeded equipment entity |
| `ExerciseSecondaryMuscle` | Exercise-to-secondary-muscle join entity |

**Enums**:

| Enum | Values |
|---|---|
| `ExerciseTrackingType` | `weightReps`, `repsOnly`, `duration`, `durationDistance`, `weightDuration` |

**Repository Interface**:

- `ExerciseRepository` - exercise queries, exercise detail assembly, muscles, equipment, secondary muscle lookup, top PR records.

**Composite Read Models**:

- `ExerciseDetail`
- `ExerciseStats`
- `ExerciseHistoryEntry`
- personal record summary records used by dashboard/profile surfaces

### Data Layer

| DAO | Responsibility |
|---|---|
| `ExerciseDao` | All exercises, filtered search, batch lookup, secondary muscle IDs |
| `MuscleDao` | Muscle lookup |
| `EquipmentDao` | Equipment lookup |
| `ExerciseStatsDao` | Personal bests, history, weight/volume over time, total sessions |

### Presentation Layer

| Component | Responsibility |
|---|---|
| `ExerciseListCubit` | Loads filters, searches exercises, filters by muscle/equipment |
| `ExerciseListScreen` | Exercise browser and navigation to detail |
| `ExerciseDetailCubit` | Loads a single `ExerciseDetail` |
| `ExerciseDetailScreen` | Exercise instructions, metadata, stats, and history |

---

## 4. Workout And Routine (`features/workout/`)

### Routine Domain

| Model | Description |
|---|---|
| `Routine` | Routine metadata |
| `RoutineExercise` | Ordered exercise in a routine, with target rest |
| `RoutineSet` | Template set with target values |
| `RoutineInput` / `RoutineExerciseInput` / `RoutineSetInput` | Create/update DTOs |

Repository:

- `RoutineRepository` - routine CRUD, add/remove/reorder exercises, add/remove/reorder sets, drafts/copy, sync completed workout sets back to routine.

DAOs:

- `RoutineDao`
- `RoutineExerciseDao`
- `RoutineSetDao`

### Workout Domain

| Model | Description |
|---|---|
| `Workout` | Workout session, status, time range, volume, optional source routine |
| `WorkoutExercise` | Ordered exercise in a workout |
| `WorkoutSet` | Performed set with actual values and completion status |

Repository:

- `WorkoutRepository` - start/complete/cancel workout, edit metadata, add/remove/reorder exercises and sets, set completion, history.

DAOs:

- `WorkoutDao`
- `WorkoutExerciseDao`
- `WorkoutSetDao`

### Presentation Layer

| Component | Responsibility |
|---|---|
| `WorkoutHomeCubit` | Loads routines, starts empty workouts, starts routines, deletes routines |
| `WorkoutHomeScreen` | Workout tab, quick start, routine list, edit/delete/start routine actions |
| `CreateRoutineCubit` | Draft routine create/edit state, exercise/set edits, save |
| `CreateRoutineScreen` | Routine create/edit form |
| `RoutineDetailCubit` | Loads routine detail, starts workout from current routine, deletes routine |
| `RoutineDetailScreen` | Routine review and launch surface |
| `AddExerciseCubit` | Search/filter/select exercises for routine or active workout flows |
| `AddExerciseScreen` | Reusable exercise picker |
| `ActiveWorkoutCubit` | Active workout editing, set completion, workout finish/cancel, rest timer sync |
| `ActiveWorkoutScreen` | Live workout screen with exercise blocks, editable set rows, timers, and rest controls |
| `RestTimerBloc` | Event-driven rest timer, notifications, vibration, skip/adjust/cancel behavior |

### Design Notes

- Workout volume is recalculated inside repository transactions when sets change.
- Starting a workout from a routine copies routine exercises and sets into workout records.
- Active workout uses singleton state because it participates in shell banner, notification callbacks, and rest timer.

---

## 5. Profile, Progress, And History (`features/profile/`)

### Domain Layer

| Component | Responsibility |
|---|---|
| `AnalyticsRepository` | Volume history, workout frequency, muscle group breakdown |
| `BodyMeasurementRepository` | Body measurement list, latest entry, add, delete |
| `PreferencesStore` | Username and initials |
| `BodyMeasureEntry` | Date, weight, body fat, and custom measurement map |

### Data Layer

| DAO | Responsibility |
|---|---|
| `AnalyticsDao` | SQL aggregates for volume, frequency, and muscle breakdown |
| `BodyMeasurementDao` | Body measurement reads/inserts/deletes |

### Presentation Layer

| Component | Responsibility |
|---|---|
| `ProfileCubit` | Loads profile header, progress chart buckets, name updates |
| `ProfileHomeScreen` | Profile header, chart, and dashboard navigation cards |
| `StatisticsCubit` / `StatisticsScreen` | Aggregate progress/statistics view |
| `MuscleMapCubit` / `MuscleMapScreen` | Muscle group balance view |
| `MeasuresCubit` / `MeasuresScreen` | Body weight/body fat entries |
| `WorkoutHistoryCubit` / `WorkoutHistoryScreen` | Workout history and selected-date summary |
| `WorkoutDetailCubit` / `WorkoutDetailScreen` | Completed workout review |

### Design Notes

- Profile chart can switch metric (`duration`, `volume`, `reps`) and range (`week`, `month`).
- Measurements are stored locally in SQLite and profile identity in shared preferences.
- Workout history data comes from `WorkoutRepository.getWorkoutHistory()`.

---

## 6. Analytics (`core/dao/analytics_dao.dart`, `core/repositories/analytics_repository.dart`)

### Query Surface

| Query | Purpose |
|---|---|
| `getVolumeHistory({days})` | Completed workout volume over time |
| `getWorkoutFrequency({weeks, weekMs})` | Completed workout count by UTC week bucket |
| `getMuscleGroupBreakdown({days})` | Completed set count by primary muscle |

### Usage

- Profile statistics views consume analytics directly.
- Dashboard recovery/suggestion logic uses repository data plus `DashboardService` instead of `AnalyticsDao` directly.

---

## 7. Shared / Common

### Utilities

| Utility | Responsibility |
|---|---|
| `GetItUtils` | DI setup and manual singleton registrations |
| `DateFormatters` | Short date, weekday, duration, elapsed timer labels |
| `MuscleGroupUtils` | Seed muscle name to high-level muscle group mapping and recovery status |

### Services

| Service | Responsibility |
|---|---|
| `NotificationService` | Workout in-progress notification, rest-end notification, notification tap routing |
| `DashboardService` | Cross-repository dashboard aggregation |

### Notes

- Shared widgets are currently feature-local rather than centralized under `common/widgets/`.
- Add a shared widget only when it is used across multiple feature surfaces.
