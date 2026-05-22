# Project TODO

Legend: ✅ Done | 🔄 In Progress | ⚠️ Stub/Partial | ❌ Not Started

ENTRY FORMAT: | XX | Item description | Status | Short approach note |

---

## Core / Infrastructure

| # | Item | Status | Notes |
|---|---|---|---|
| C1 | sqflite database setup | ✅ | DatabaseModule v1, foreign keys enabled, seed on create |
| C2 | get_it + injectable DI | ✅ | GetItUtils entry point plus manual singleton wiring where lifecycle is custom |
| C3 | Seed data | ✅ | `assets/seed_data.json` loads muscles, equipment, exercises, secondary muscles |
| C4 | Database indexes | ✅ | Standard and unique order indexes |
| C5 | UUID generation module | ✅ | `UuidModule` provides a singleton UUID generator |
| C6 | DB migrations | ❌ | Add `onUpgrade` before any schema change |
| C7 | Shared preferences store | ✅ | Username/initials stored through `PreferencesStore` |
| C8 | Local notifications | ✅ | Workout in-progress and rest-timer notification service |

---

## Shell / Navigation

| # | Item | Status | Notes |
|---|---|---|---|
| S1 | GetIt DI setup | ✅ | `getit_utils.dart` and generated config entry point |
| S2 | Navigation / Routes | ✅ | Central `Routes.onGenerateRoute` and typed route args |
| S3 | Shared widgets | ❌ | Feature-local widgets exist; shared `common/widgets` extraction not done |
| S4 | Extensions | ❌ | No shared extension layer yet |
| S5 | App theme | ⚠️ | Dark Material 3 seed theme exists; full design system not defined |
| S6 | App entry point | ✅ | Preferences, DI, notifications, Cubit preloads, `MainApp` |
| S7 | Bottom navigation shell | ✅ | Home, Workout, Profile tabs with active workout banner |

---

## Home Dashboard

| # | Item | Status | Notes |
|---|---|---|---|
| H1 | Dashboard aggregation service | ✅ | Summary, streak, PRs, recovery, suggested routine |
| H2 | HomeDashboardCubit | ✅ | Loads dashboard and starts empty/suggested workouts |
| H3 | Home dashboard screen | ✅ | Quick start, suggestion, weekly strip, last workout, PRs, recovery |

---

## Exercise Library Feature

| # | Item | Status | Notes |
|---|---|---|---|
| E1 | Muscle, Equipment, Exercise domain models | ✅ | `toMap`/`fromMap`, static table/column constants |
| E2 | ExerciseSecondaryMuscle join model | ✅ | Composite PK |
| E3 | MuscleDao | ✅ | `getAll`, `getById`, `getByIds` |
| E4 | EquipmentDao | ✅ | `getAll`, `getById` |
| E5 | ExerciseDao query set | ✅ | All, by ID, by IDs, filtered, secondary muscle IDs |
| E6 | ExerciseStatsDao | ✅ | Personal best, history, weight/volume over time, total sessions |
| E7 | ExerciseRepository interface | ✅ | Exercise queries and detail assembly |
| E8 | ExerciseRepositoryImpl | ✅ | Assembles `ExerciseDetail` and stats |
| E9 | Exercise List Screen + Cubit | ✅ | Search and filtering by muscle/equipment |
| E10 | Exercise Detail Screen + Cubit | ✅ | Exercise metadata, instructions, stats/history |

---

## Routine Feature

| # | Item | Status | Notes |
|---|---|---|---|
| R1 | Routine, RoutineExercise, RoutineSet models | ✅ | Template routine entities |
| R2 | RoutineDao | ✅ | CRUD |
| R3 | RoutineExerciseDao | ✅ | CRUD, reorder, max order |
| R4 | RoutineSetDao | ✅ | CRUD, batch fetch, reorder |
| R5 | RoutineRepository interface | ✅ | Full CRUD, exercise/set management, sync, draft/copy |
| R6 | RoutineRepositoryImpl | ✅ | Transactions and batch operations |
| R7 | Routine list screen | ✅ | Implemented in Workout tab as routine cards |
| R8 | Routine detail / edit screens | ✅ | Detail route plus create/edit form |
| R9 | Routine input models | ✅ | Create/update DTOs |

---

## Workout Feature

| # | Item | Status | Notes |
|---|---|---|---|
| W1 | Workout, WorkoutExercise, WorkoutSet models | ✅ | Active/completed workout entities |
| W2 | WorkoutDao | ✅ | CRUD, active lookup, history aggregation |
| W3 | WorkoutExerciseDao | ✅ | CRUD, batch fetch, reorder, max order |
| W4 | WorkoutSetDao | ✅ | CRUD, batch fetch, volume compute, reorder |
| W5 | WorkoutRepository interface | ✅ | Lifecycle, volume tracking, history |
| W6 | WorkoutRepositoryImpl | ✅ | Transaction-based volume recalculation and history assembly |
| W7 | Active Workout Screen + Cubit | ✅ | Live exercise/set management and finish/cancel |
| W8 | Workout History Screen + Cubit | ✅ | History/calendar surface in Profile |
| W9 | Workout Detail Screen + Cubit | ✅ | Completed workout review |
| W10 | Start Workout from Routine flow | ✅ | Routine cards/detail can launch active workouts |
| W11 | Rest Timer Bloc | ✅ | Start, tick, adjust, skip, cancel, notification/vibration hooks |

---

## Analytics Feature

| # | Item | Status | Notes |
|---|---|---|---|
| A1 | AnalyticsDao | ✅ | Volume history, frequency, muscle breakdown |
| A2 | AnalyticsRepository interface | ✅ | Aggregate data contract |
| A3 | AnalyticsRepositoryImpl | ✅ | Week-bucket calculation and typed records |
| A4 | Analytics screens | ✅ | Statistics, profile chart, muscle map |

---

## Profile Feature

| # | Item | Status | Notes |
|---|---|---|---|
| P1 | Profile home screen | ✅ | Profile header, chart, dashboard cards |
| P2 | ProfileCubit | ✅ | Name update, total workouts, chart buckets |
| P3 | Body measurement model/table | ✅ | `body_measure_entries` table and model |
| P4 | Body measurement repository/DAO | ✅ | Add, list, latest, delete |
| P5 | Measures screen + Cubit | ✅ | Add/delete weight and body fat entries |
| P6 | Statistics screen + Cubit | ✅ | Aggregate training statistics |
| P7 | Muscle map screen + Cubit | ✅ | Training balance by muscle/group |
| P8 | Workout history/detail screens | ✅ | History list and completed workout review |

---

## Documentation / Tooling Follow-ups

| # | Item | Status | Notes |
|---|---|---|---|
| DOC1 | README refresh | ✅ | Current app surface, setup, docs map |
| DOC2 | Architecture docs refresh | 🔄 | Align docs with implemented presentation/services |
| DI1 | Regenerate DI config | ❌ | Run build_runner after docs-only pass |
| TST1 | Replace default widget test | ❌ | Current test scaffold should be updated for `MainApp` |
