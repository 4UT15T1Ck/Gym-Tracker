# Database & Models

<!--
  FILE PURPOSE   : Schema definitions, entity columns, relationships, domain models, and DAO contracts.

  WHAT BELONGS   : DB engine config, entity tables, column specs, enums, DAOs, seed strategy,
                   and migration rules.

  WHAT DOES NOT  : Implementation status (→ todo.md), feature-level screen design (→ features_architecture.md),
                   tech library config (→ technical_reference.md).

  UPDATE WHEN    : Any entity column, relationship, enum value, DAO method, or domain model changes.
                   Always bump DB version and write a migration alongside the schema change.

  FORMAT: 
            ### `EntityName` — table `table_name`

            | Column | Type | Notes |
            |---|---|---|
            | ... | ... | ... |

            FK / relationship note if any.
-->

---

## Database Configuration

- **Engine**: sqflite (SQLite)
- **Module**: `core/data/db_module.dart` (`DatabaseModule`)
- **Name**: `gym_tracker.db`
- **Current version**: 1
- **Foreign keys**: Enabled via `PRAGMA foreign_keys = ON` in `onConfigure`
- **DI**: `@singleton @preResolve` — resolved asynchronously before app starts

### Registered Tables

| Table | Entity | Feature |
|---|---|---|
| `muscles` | `Muscle` | library |
| `equipment` | `Equipment` | library |
| `exercises` | `Exercise` | library |
| `exercise_secondary_muscles` | `ExerciseSecondaryMuscle` | library |
| `routines` | `Routine` | routines |
| `routine_exercises` | `RoutineExercise` | routines |
| `routine_sets` | `RoutineSet` | routines |
| `workouts` | `Workout` | workout |
| `workout_exercises` | `WorkoutExercise` | workout |
| `workout_sets` | `WorkoutSet` | workout |

### Migration Rule

For every schema change:
1. Bump `_databaseVersion` in `db_module.dart`.
2. Add an `onUpgrade` callback with the migration SQL.
3. Never drop and recreate tables in production.

---

## Entities

### `Muscle` — table `muscles`

| Column | Type | Notes |
|---|---|---|
| `id` | TEXT (PK) | UUID |
| `name` | TEXT NOT NULL | |

---

### `Equipment` — table `equipment`

| Column | Type | Notes |
|---|---|---|
| `id` | TEXT (PK) | UUID |
| `name` | TEXT NOT NULL | |

---

### `Exercise` — table `exercises`

| Column | Type | Notes |
|---|---|---|
| `id` | TEXT (PK) | UUID |
| `name` | TEXT NOT NULL | |
| `tracking_type` | TEXT NOT NULL | CHECK constraint: `weight_reps`, `reps_only`, `duration`, `duration_distance`, `weight_duration` |
| `short_description` | TEXT | nullable |
| `instructions` | TEXT NOT NULL | JSON array string, default `'[]'` |
| `primary_muscle_id` | TEXT NOT NULL (FK → muscles.id) | RESTRICT on delete |
| `equipment_id` | TEXT (FK → equipment.id) | SET NULL on delete |
| `image_url` | TEXT | nullable |
| `video_url` | TEXT | nullable |

---

### `ExerciseSecondaryMuscle` — table `exercise_secondary_muscles`

| Column | Type | Notes |
|---|---|---|
| `exercise_id` | TEXT NOT NULL (FK → exercises.id) | CASCADE on delete |
| `muscle_id` | TEXT NOT NULL (FK → muscles.id) | CASCADE on delete |

Composite PK: `(exercise_id, muscle_id)`

---

### `Routine` — table `routines`

| Column | Type | Notes |
|---|---|---|
| `id` | TEXT (PK) | UUID |
| `name` | TEXT NOT NULL | |
| `notes` | TEXT | nullable |

---

### `RoutineExercise` — table `routine_exercises`

| Column | Type | Notes |
|---|---|---|
| `id` | TEXT (PK) | UUID |
| `routine_id` | TEXT NOT NULL (FK → routines.id) | CASCADE on delete |
| `exercise_id` | TEXT NOT NULL (FK → exercises.id) | RESTRICT on delete |
| `order` | INTEGER NOT NULL | display order within routine |
| `target_rest_seconds` | INTEGER | nullable; rest time between sets |

Unique index: `(routine_id, order)`

---

### `RoutineSet` — table `routine_sets`

| Column | Type | Notes |
|---|---|---|
| `id` | TEXT (PK) | UUID |
| `routine_exercise_id` | TEXT NOT NULL (FK → routine_exercises.id) | CASCADE on delete |
| `set_type` | TEXT NOT NULL | CHECK: `warm_up`, `working`, `drop_set`, `amrap`, `failure` |
| `target_weight` | REAL | nullable |
| `target_reps` | INTEGER | nullable |
| `target_duration_seconds` | INTEGER | nullable |
| `target_distance` | REAL | nullable |
| `target_rpe` | REAL | nullable |
| `order` | INTEGER NOT NULL | display order within exercise |

Unique index: `(routine_exercise_id, order)`

---

### `Workout` — table `workouts`

| Column | Type | Notes |
|---|---|---|
| `id` | TEXT (PK) | UUID |
| `routine_id` | TEXT (FK → routines.id) | SET NULL on delete; nullable |
| `name` | TEXT NOT NULL | |
| `start_time` | INTEGER NOT NULL | epoch ms |
| `end_time` | INTEGER | epoch ms; nullable until completed |
| `status` | TEXT NOT NULL | CHECK: `active`, `completed`, `cancelled`; default `active` |
| `notes` | TEXT | nullable |
| `volume` | REAL NOT NULL | total workout volume; default 0 |

---

### `WorkoutExercise` — table `workout_exercises`

| Column | Type | Notes |
|---|---|---|
| `id` | TEXT (PK) | UUID |
| `workout_id` | TEXT NOT NULL (FK → workouts.id) | CASCADE on delete |
| `exercise_id` | TEXT NOT NULL (FK → exercises.id) | RESTRICT on delete |
| `order` | INTEGER NOT NULL | display order within workout |
| `rest_seconds` | INTEGER | nullable |

Unique index: `(workout_id, order)`

---

### `WorkoutSet` — table `workout_sets`

| Column | Type | Notes |
|---|---|---|
| `id` | TEXT (PK) | UUID |
| `workout_exercise_id` | TEXT NOT NULL (FK → workout_exercises.id) | CASCADE on delete |
| `set_type` | TEXT NOT NULL | CHECK: `warm_up`, `working`, `drop_set`, `amrap`, `failure` |
| `weight` | REAL | nullable |
| `reps` | INTEGER | nullable |
| `duration_seconds` | INTEGER | nullable |
| `distance` | REAL | nullable |
| `rpe` | REAL | nullable |
| `completed_at` | INTEGER | epoch ms; nullable |
| `order` | INTEGER NOT NULL | display order within exercise |
| `is_completed` | INTEGER NOT NULL | 0 or 1; default 0 |

Unique index: `(workout_exercise_id, order)`

---

## Supporting Enums

| Enum | Values | File |
|---|---|---|
| `ExerciseTrackingType` | `weightReps`, `repsOnly`, `duration`, `durationDistance`, `weightDuration` | `tracking_type_enum.dart` |
| `SetType` | `warmUp`, `working`, `dropSet`, `amrap`, `failure` | `set_type_enum.dart` |
| `WorkoutStatus` | `active`, `completed`, `cancelled` | `workout_status_enum.dart` |

All enums use extensions with `dbValue` (snake_case string for DB storage) and `displayName` (human-readable). Conversion functions: `trackingTypeFromDbValue()`, `setTypeFromDbValue()`, `workoutStatusFromDbValue()`.

---

## Indexes

| Table | Index | Type |
|---|---|---|
| `exercises` | `primary_muscle_id` | standard |
| `exercises` | `equipment_id` | standard |
| `exercise_secondary_muscles` | `muscle_id` | standard |
| `routine_exercises` | `routine_id` | standard |
| `routine_exercises` | `exercise_id` | standard |
| `routine_exercises` | `(routine_id, order)` | unique |
| `routine_sets` | `routine_exercise_id` | standard |
| `routine_sets` | `(routine_exercise_id, order)` | unique |
| `workouts` | `routine_id` | standard |
| `workout_exercises` | `workout_id` | standard |
| `workout_exercises` | `exercise_id` | standard |
| `workout_exercises` | `(workout_id, order)` | unique |
| `workout_sets` | `workout_exercise_id` | standard |
| `workout_sets` | `(workout_exercise_id, order)` | unique |

---

## DAOs

### `MuscleDao`
- `getAll()`, `getById(id)`, `getByIds(ids)`

### `EquipmentDao`
- `getAll()`, `getById(id)`

### `ExerciseDao`
- `getAll()`, `getById(id)`, `getByIds(ids)`, `getFiltered({muscleId, equipmentId, trackingType, query})`, `getSecondaryMuscleIds(exerciseId)`

### `ExerciseStatsDao`
- `getPersonalBest(exerciseId)`, `getRecentHistoryWorkouts(exerciseId, {limit})`, `getRecentHistorySets(exerciseId, {limit})`, `getWeightOverTime(exerciseId, {days})`, `getVolumeOverTime(exerciseId, {days})`, `getTotalSessions(exerciseId)`

### `RoutineDao`
- `getAll()`, `getById(id)`, `insert(routine, db)`, `update(routine, db)`, `delete(id)`

### `RoutineExerciseDao`
- `getByRoutineId(routineId)`, `insert(re, db)`, `updateOrder(id, order, db)`, `delete(id, db)`, `deleteByRoutineId(routineId, db)`, `getMaxOrder(routineId, db)`

### `RoutineSetDao`
- `getByRoutineExerciseId(id)`, `getByRoutineExerciseIds(ids)`, `insert(set, db)`, `update(set, db)`, `updateOrder(id, order, db)`, `delete(id, db)`, `deleteByRoutineExerciseId(id, db)`

### `WorkoutDao`
- `getById(id, [db])`, `getActive()`, `getHistory({limit, offset, from, to})`, `getExerciseNamesForWorkouts(ids, {limit})`, `insert(workout, db)`, `updateStatus(id, status, db)`, `updateVolume(id, volume, db)`, `updateMeta({id, name, notes, db})`, `updateEndTime(id, endTime, db)`

### `WorkoutExerciseDao`
- `getByWorkoutId(workoutId)`, `getByIds(ids)`, `getById(id, [db])`, `insert(we, db)`, `updateOrder(id, order, db)`, `delete(id, db)`, `getMaxOrder(workoutId, db)`

### `WorkoutSetDao`
- `getByWorkoutExerciseId(id)`, `getByWorkoutExerciseIds(ids)`, `getById(id, [db])`, `insert(set, db)`, `update(set, db)`, `updateOrder(id, order, db)`, `delete(id, db)`, `computeVolume(workoutId, db)`, `getLastCompletedAt(weId)`, `getMaxOrder(weId, db)`

### `AnalyticsDao`
- `getVolumeHistory({days})`, `getWorkoutFrequency({weeks, weekMs})`, `getMuscleGroupBreakdown({days})`

---

## Seed Data

| Source | Trigger | Seeds |
|---|---|---|
| `assets/seed_data.json` | `onCreate` in `DatabaseModule` | Muscles, Equipment, Exercises, ExerciseSecondaryMuscles |

Seeding is handled by `seedDatabaseFromJson()` in `core/data/seed_helper.dart`. Uses batch insert with `ConflictAlgorithm.replace`. Parses secondary muscles from `secondary_muscle_ids` array in exercise JSON.
