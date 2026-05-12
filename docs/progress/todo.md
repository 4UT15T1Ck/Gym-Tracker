# Project TODO

Legend: ✅ Done | 🔄 In Progress | ⚠️ Stub/Partial | ❌ Not Started

ENTRY FORMAT: | XX | Item description | ❌ | Short approach note — what the implementation should do |

---

## Core / Infrastructure

| # | Item | Status | Notes |
|---|---|---|---|
| C1 | sqflite database setup | ✅ | DatabaseModule v1, 10 tables, foreign keys enabled |
| C2 | get_it + injectable DI | ✅ | GetItUtils entry point, DatabaseModule, UuidModule |
| C3 | Seed data (muscles, equipment, exercises) | ✅ | seed_data.json loaded on onCreate via batch insert |
| C4 | Database indexes | ✅ | Standard + unique indexes on order columns |
| C5 | UUID generation module | ✅ | UuidModule provides Uuid singleton |
| C6 | DB migrations | ❌ | Needed before any schema change; add onUpgrade callback |

---

## Exercise Library Feature

| # | Item | Status | Notes |
|---|---|---|---|
| E1 | Muscle, Equipment, Exercise domain models | ✅ | toMap/fromMap, static column constants |
| E2 | ExerciseSecondaryMuscle join model | ✅ | Composite PK |
| E3 | MuscleDao | ✅ | getAll, getById, getByIds |
| E4 | EquipmentDao | ✅ | getAll, getById |
| E5 | ExerciseDao — full query set | ✅ | getAll, getById, getByIds, getFiltered, getSecondaryMuscleIds |
| E6 | ExerciseStatsDao | ✅ | Personal best, history, weight/volume over time, total sessions |
| E7 | ExerciseRepository interface | ✅ | getExercises, getExerciseDetail, getMuscles, getEquipment |
| E8 | ExerciseRepositoryImpl | ✅ | Assembles ExerciseDetail from multiple DAOs |
| E9 | Exercise List Screen (BLoC) | ❌ | Filterable by muscle, equipment, tracking type, search |
| E10 | Exercise Detail Screen (BLoC) | ❌ | Full exercise info + stats + history charts |

---

## Routine Feature

| # | Item | Status | Notes |
|---|---|---|---|
| R1 | Routine, RoutineExercise, RoutineSet domain models | ✅ | |
| R2 | RoutineDao | ✅ | CRUD |
| R3 | RoutineExerciseDao | ✅ | CRUD + reorder + getMaxOrder |
| R4 | RoutineSetDao | ✅ | CRUD + batch fetch + reorder |
| R5 | RoutineRepository interface | ✅ | Full CRUD, exercise/set management, sync, draft/copy |
| R6 | RoutineRepositoryImpl | ✅ | Transaction management, batch operations |
| R7 | Routine List Screen (BLoC) | ❌ | Display all routines |
| R8 | Routine Detail / Edit Screen (BLoC) | ❌ | Exercise and set management |
| R9 | Routine input models (RoutineInput, etc.) | ✅ | Create/update DTOs |

---

## Workout Feature

| # | Item | Status | Notes |
|---|---|---|---|
| W1 | Workout, WorkoutExercise, WorkoutSet domain models | ✅ | |
| W2 | WorkoutDao | ✅ | CRUD + history with aggregation + exercise name batching |
| W3 | WorkoutExerciseDao | ✅ | CRUD + batch + reorder + getMaxOrder |
| W4 | WorkoutSetDao | ✅ | CRUD + batch + volume compute + reorder |
| W5 | WorkoutRepository interface | ✅ | Full lifecycle, volume tracking, history |
| W6 | WorkoutRepositoryImpl | ✅ | Transaction-based volume recalculation, history assembly |
| W7 | Active Workout Screen (BLoC) | ❌ | Live workout tracking with exercise/set management |
| W8 | Workout History Screen (BLoC) | ❌ | Paginated list with date filtering |
| W9 | Workout Detail Screen (BLoC) | ❌ | Completed workout review |
| W10 | Start Workout from Routine flow | ❌ | Backend ready (startWorkout with routineId); needs UI |

---

## Analytics Feature

| # | Item | Status | Notes |
|---|---|---|---|
| A1 | AnalyticsDao | ✅ | Volume history, workout frequency, muscle group breakdown |
| A2 | AnalyticsRepository interface | ✅ | |
| A3 | AnalyticsRepositoryImpl | ✅ | Week-bucket calculation for frequency |
| A4 | Analytics Dashboard Screen (BLoC) | ❌ | Charts: volume trends, frequency, muscle balance |

---

## Profile Feature

| # | Item | Status | Notes |
|---|---|---|---|
| P1 | Profile Screen | ❌ | Feature folder empty; no design yet |

---

## Common / Shared

| # | Item | Status | Notes |
|---|---|---|---|
| S1 | GetIt DI setup | ✅ | getit_utils.dart + generated config |
| S2 | Navigation / Routes | ❌ | Routes folder empty; define app routing |
| S3 | Shared Widgets | ❌ | Widgets folder empty; build reusable components |
| S4 | Extensions | ❌ | Extensions folder empty |
| S5 | App Theme | ⚠️ | Basic MaterialApp with deepPurple seed color; needs full theme |
| S6 | App entry point (main.dart) | ⚠️ | Initializes DI, placeholder Scaffold as home |
