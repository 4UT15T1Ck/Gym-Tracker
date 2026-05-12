# Features Architecture

<!--
  FILE PURPOSE   : Per-feature breakdown of layers, contracts, components, and design decisions.

  WHAT BELONGS   : Domain models, repository interfaces, DAO groupings, screen Cubit/BLoC triads,
                   shared components, and key design decisions per feature.

  WHAT DOES NOT  : Implementation status (→ todo.md), active work detail (→ current_work.md),
                   tech configuration (→ technical_reference.md), overall layer rules (→ general_architecture.md).

  UPDATE WHEN    : A new screen, DAO, model, component, or repository contract is added or changed.
  
  FORMAT:
            ## N. <Feature Name>

            ### Domain Layer
            **Models**: ...
            **Repository Interfaces**: ...

            ### Data Layer
            ...

            ### Presentation Layer
            ...
-->

---

## 1. Exercise Library (`features/library/`)

### Domain Layer

**Models** (`core/models/`):

| Model | Description |
|---|---|
| `Exercise` | Main exercise entity — name, tracking type, instructions, image/video URLs |
| `Muscle` | Muscle group entity — id, name |
| `Equipment` | Equipment entity — id, name |
| `ExerciseSecondaryMuscle` | Join table — exercise ↔ secondary muscle mapping |

**Enums** (`core/enums/`):

| Enum | Values |
|---|---|
| `ExerciseTrackingType` | `weightReps`, `repsOnly`, `duration`, `durationDistance`, `weightDuration` |

**Repository Interface** (`core/repositories/exercise_repository.dart`):
- `ExerciseRepository` — filtered exercise queries, exercise detail assembly, muscle/equipment lists

**Composite Read Models** (`core/repositories/repository_models.dart`):
- `ExerciseDetail` — Exercise + primary Muscle + secondary Muscles + Equipment + ExerciseStats
- `ExerciseStats` — personal best, recent history, weight/volume over time, total sessions
- `ExerciseHistoryEntry` — workout context for a performed exercise

### Data Layer

**DAOs** (`core/dao/`):
- `ExerciseDao` — `getAll()`, `getById()`, `getByIds()`, `getFiltered()`, `getSecondaryMuscleIds()`
- `MuscleDao` — `getAll()`, `getById()`, `getByIds()`
- `EquipmentDao` — `getAll()`, `getById()`
- `ExerciseStatsDao` — `getPersonalBest()`, `getRecentHistoryWorkouts()`, `getRecentHistorySets()`, `getWeightOverTime()`, `getVolumeOverTime()`, `getTotalSessions()`

**Repository Impl** (`core/repository_impl/exercise_repository_impl.dart`):
- `ExerciseRepositoryImpl` — assembles `ExerciseDetail` from multiple DAOs; builds `ExerciseStats`

### Presentation Layer

**Status**: Feature folder empty — screens not yet implemented.

Planned screens:
- **Exercise List** — filterable by muscle, equipment, tracking type, search query
- **Exercise Detail** — full exercise info + stats + history

---

## 2. Routine Feature (within `core/`)

### Domain Layer

**Models** (`core/models/`):

| Model | Description |
|---|---|
| `Routine` | Routine entity — name, notes |
| `RoutineExercise` | Join table — routine ↔ exercise mapping with order and rest time |
| `RoutineSet` | Template set — set type, target weight/reps/duration/distance/RPE, order |

**Enums** (`core/enums/`):

| Enum | Values |
|---|---|
| `SetType` | `warmUp`, `working`, `dropSet`, `amrap`, `failure` |

**Repository Interface** (`core/repositories/routine_repository.dart`):
- `RoutineRepository` — CRUD routines, add/remove/reorder exercises, add/remove/reorder sets, save/draft/copy, sync completed sets back to template

**Composite Read Models**:
- `RoutineDetail` — Routine + list of `RoutineExerciseDetail`
- `RoutineExerciseDetail` — RoutineExercise + Exercise + list of RoutineSet
- `RoutineInput` / `RoutineExerciseInput` / `RoutineSetInput` — input DTOs for create/update flows

### Data Layer

**DAOs** (`core/dao/`):
- `RoutineDao` — `getAll()`, `getById()`, `insert()`, `update()`, `delete()`
- `RoutineExerciseDao` — `getByRoutineId()`, `insert()`, `updateOrder()`, `delete()`, `deleteByRoutineId()`, `getMaxOrder()`
- `RoutineSetDao` — `getByRoutineExerciseId()`, `getByRoutineExerciseIds()`, `insert()`, `update()`, `updateOrder()`, `delete()`, `deleteByRoutineExerciseId()`

**Repository Impl** (`core/repository_impl/routine_repository_impl.dart`):
- `RoutineRepositoryImpl` — full CRUD, batch operations, transaction management, sync from workout

### Presentation Layer

**Status**: No screens yet — to be implemented in `features/` or a dedicated route.

---

## 3. Workout Feature (`features/workout/`)

### Domain Layer

**Models** (`core/models/`):

| Model | Description |
|---|---|
| `Workout` | Workout session — name, start/end time, status, volume, linked routine |
| `WorkoutExercise` | Exercise within a workout — order, rest seconds |
| `WorkoutSet` | Performed set — weight, reps, duration, distance, RPE, completion status |

**Enums** (`core/enums/`):

| Enum | Values |
|---|---|
| `WorkoutStatus` | `active`, `completed`, `cancelled` |
| `SetType` | `warmUp`, `working`, `dropSet`, `amrap`, `failure` |

**Repository Interface** (`core/repositories/workout_repository.dart`):
- `WorkoutRepository` — start/complete/cancel workout, CRUD exercises and sets, volume tracking, history

**Composite Read Models**:
- `WorkoutDetail` — Workout + list of `WorkoutExerciseDetail`
- `WorkoutExerciseDetail` — WorkoutExercise + Exercise + list of WorkoutSet
- `WorkoutSummary` — lightweight workout card (id, name, times, volume, totals, exercise names)

### Data Layer

**DAOs** (`core/dao/`):
- `WorkoutDao` — `getById()`, `getActive()`, `getHistory()`, `getExerciseNamesForWorkouts()`, `insert()`, `updateStatus()`, `updateVolume()`, `updateMeta()`, `updateEndTime()`
- `WorkoutExerciseDao` — `getByWorkoutId()`, `getByIds()`, `getById()`, `insert()`, `updateOrder()`, `delete()`, `getMaxOrder()`
- `WorkoutSetDao` — `getByWorkoutExerciseId()`, `getByWorkoutExerciseIds()`, `getById()`, `insert()`, `update()`, `updateOrder()`, `delete()`, `computeVolume()`, `getLastCompletedAt()`, `getMaxOrder()`

**Repository Impl** (`core/repository_impl/workout_repository_impl.dart`):
- `WorkoutRepositoryImpl` — full workout lifecycle, transaction-based volume recalculation, history with batch exercise name fetching

### Presentation Layer

**Status**: Feature folder empty — screens not yet implemented.

Planned screens:
- **Active Workout** — live workout tracking with exercise/set management
- **Workout History** — paginated list with date filtering
- **Workout Detail** — completed workout review

---

## 4. Analytics Feature (within `core/`)

### Domain Layer

**Repository Interface** (`core/repositories/analytics_repository.dart`):
- `AnalyticsRepository` — volume history, workout frequency, muscle group breakdown

### Data Layer

**DAOs** (`core/dao/`):
- `AnalyticsDao` — `getVolumeHistory()`, `getWorkoutFrequency()`, `getMuscleGroupBreakdown()`

**Repository Impl** (`core/repository_impl/analytics_repository_impl.dart`):
- `AnalyticsRepositoryImpl` — maps DAO results to typed records; handles week-bucket calculation for frequency

### Presentation Layer

**Status**: Not yet implemented.

---

## 5. Profile Feature (`features/profile/`)

**Status**: Feature folder empty — not yet implemented.

---

## 6. Shared / Common (`common/`)

### Utilities
- `GetItUtils` — DI entry point (`@injectableInit`)
- `UuidModule` — provides `Uuid` instance via injectable `@module`

### Widgets
- `common/widgets/` — shared reusable widgets (empty, to be populated)

### Extensions
- `common/extensions/` — Dart extension methods (empty, to be populated)

### Routes
- `common/routes/` — navigation route definitions (empty, to be populated)
