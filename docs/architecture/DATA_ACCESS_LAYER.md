# Data Access Layer Documentation

This document provides a comprehensive overview of the Data Access Layer (DAL) architecture, including all DAOs (Data Access Objects) and Repository implementations.

## Architecture Overview

The DAL follows a strict separation of concerns:

- **DAO Layer**: Handles raw SQL queries and returns typed model objects. No business logic, no model assembly.
- **Repository Layer**: Calls DAOs, assembles composite read models, owns transactions, and implements business logic.
- **DatabaseExecutor**: Used for transactional writes, allowing DAOs to participate in external transactions.

### Key Principles

1. **No SQL in repositories** - All SQL must be in DAOs
2. **No model assembly in DAOs** - DAOs return simple model objects only
3. **Batch queries use `IN (?)`** - Avoid N+1 query problems
4. **Multi-step writes use transactions** - Ensure atomicity with `db.transaction(...)`
5. **Volume computation inside transactions** - `computeVolume` called within the same transaction as set changes
6. **Optional DatabaseExecutor parameter** - Methods accept `[DatabaseExecutor? db]` for transaction isolation

---

## DAO Layer

### MuscleDao

**Purpose**: Fetch muscle data from the database.

**Functions**:

#### `getAll()`
- **What**: Returns all muscles from the database.
- **How**: Queries the `muscles` table with no filters.
- **Why**: Needed for displaying muscle selection lists (e.g., when filtering exercises by muscle).
- **For**: Exercise filtering UI, muscle selection dropdowns.

#### `getById(String id)`
- **What**: Returns a single muscle by its ID.
- **How**: Queries the `muscles` table with a WHERE clause on the primary key.
- **Why**: Needed when assembling `ExerciseDetail` to get the primary muscle of an exercise.
- **For**: Exercise detail pages, exercise editing.

#### `getByIds(List<String> ids)`
- **What**: Returns multiple muscles by their IDs in a single batch query.
- **How**: Uses `IN (?)` clause with placeholders to fetch all muscles in one query.
- **Why**: Avoids N+1 queries when fetching secondary muscles for multiple exercises.
- **For**: Batch muscle fetching in exercise lists, exercise detail assembly.

---

### EquipmentDao

**Purpose**: Fetch equipment data from the database.

**Functions**:

#### `getAll()`
- **What**: Returns all equipment from the database.
- **How**: Queries the `equipment` table with no filters.
- **Why**: Needed for displaying equipment selection lists (e.g., when filtering exercises by equipment).
- **For**: Exercise filtering UI, equipment selection dropdowns.

#### `getById(String id)`
- **What**: Returns a single equipment by its ID.
- **How**: Queries the `equipment` table with a WHERE clause on the primary key.
- **Why**: Needed when assembling `ExerciseDetail` to get the equipment used by an exercise.
- **For**: Exercise detail pages, exercise editing.

---

### ExerciseDao

**Purpose**: Fetch exercise data from the database with optional filtering.

**Functions**:

#### `getAll()`
- **What**: Returns all exercises from the database.
- **How**: Queries the `exercises` table with no filters.
- **Why**: Needed for displaying full exercise lists (e.g., when adding exercises to a routine).
- **For**: Exercise selection UI, exercise browser.

#### `getById(String id)`
- **What**: Returns a single exercise by its ID.
- **How**: Queries the `exercises` table with a WHERE clause on the primary key.
- **Why**: Needed when fetching specific exercise details.
- **For**: Exercise detail pages, exercise editing.

#### `getByIds(List<String> ids)`
- **What**: Returns multiple exercises by their IDs in a single batch query.
- **How**: Uses `IN (?)` clause with placeholders to fetch all exercises in one query.
- **Why**: Avoids N+1 queries when fetching exercises for workouts or routines.
- **For**: Workout detail assembly, routine detail assembly.

#### `getFiltered({String? muscleId, String? equipmentId, ExerciseTrackingType? trackingType, String? query})`
- **What**: Returns exercises filtered by optional criteria (muscle, equipment, tracking type, name search).
- **How**: Dynamically builds SQL query with LEFT JOIN to `exercise_secondary_muscles` when filtering by muscle. Uses `WHERE` clauses for each filter. Searches exercise name with `LIKE %query%` when query is provided.
- **Why**: Allows users to find exercises that match specific criteria (e.g., "show me chest exercises with dumbbells").
- **For**: Exercise search/filter UI, exercise browser with filters.

#### `getSecondaryMuscleIds(String exerciseId)`
- **What**: Returns the IDs of secondary muscles for a given exercise.
- **How**: Queries the `exercise_secondary_muscles` table filtering by exercise ID.
- **Why**: Needed when assembling `ExerciseDetail` to show which secondary muscles are worked.
- **For**: Exercise detail pages, muscle targeting information.

---

### RoutineDao

**Purpose**: CRUD operations for routines.

**Functions**:

#### `getAll()`
- **What**: Returns all routines from the database.
- **How**: Queries the `routines` table with no filters.
- **Why**: Needed for displaying the user's routine list.
- **For**: Routine selection UI, routine list page.

#### `getById(String id)`
- **What**: Returns a single routine by its ID.
- **How**: Queries the `routines` table with a WHERE clause on the primary key.
- **Why**: Needed when fetching specific routine details.
- **For**: Routine detail pages, routine editing.

#### `insert(Routine routine, DatabaseExecutor db)`
- **What**: Inserts a new routine into the database.
- **How**: Uses `db.insert()` with the routine's `toMap()` result.
- **Why**: Creates new routines when users create them.
- **For**: Routine creation flow.

#### `update(Routine routine, DatabaseExecutor db)`
- **What**: Updates an existing routine in the database.
- **How**: Uses `db.update()` with the routine's `toMap()` result and WHERE clause on ID.
- **Why**: Allows users to edit routine metadata (name, notes).
- **For**: Routine editing flow.

#### `delete(String id)`
- **What**: Deletes a routine from the database.
- **How**: Uses `_db.delete()` with WHERE clause on ID. CASCADE deletes handle child records.
- **Why**: Allows users to delete routines they no longer need.
- **For**: Routine deletion flow.

---

### RoutineExerciseDao

**Purpose**: Manage exercises within routines (the mapping between routines and exercises).

**Functions**:

#### `getByRoutineId(String routineId)`
- **What**: Returns all exercises for a given routine.
- **How**: Queries the `routine_exercises` table with WHERE clause on routine ID, ordered by the `order` column.
- **Why**: Needed when assembling `RoutineDetail` to show which exercises are in a routine.
- **For**: Routine detail pages, routine editing.

#### `insert(RoutineExercise routineExercise, DatabaseExecutor db)`
- **What**: Inserts a new exercise into a routine.
- **How**: Uses `db.insert()` with the routine exercise's `toMap()` result.
- **Why**: Adds exercises when users add them to a routine.
- **For**: Adding exercises to routines.

#### `updateOrder(String id, int newOrder, DatabaseExecutor db)`
- **What**: Updates only the order column of a routine exercise.
- **How**: Uses `db.update()` with only the `order` field in the update map.
- **Why**: Allows reordering exercises without overwriting other fields (avoids full row replacement bug).
- **For**: Reordering exercises in a routine.

#### `delete(String id, DatabaseExecutor db)`
- **What**: Deletes a single exercise from a routine.
- **How**: Uses `db.delete()` with WHERE clause on ID. CASCADE deletes handle child sets.
- **Why**: Allows users to remove exercises from routines.
- **For**: Removing exercises from routines.

#### `deleteByRoutineId(String routineId, DatabaseExecutor db)`
- **What**: Deletes all exercises for a given routine.
- **How**: Uses `db.delete()` with WHERE clause on routine ID.
- **Why**: Needed when deleting a routine or clearing all exercises.
- **For**: Routine deletion, clearing routine exercises.

#### `getMaxOrder(String routineId, DatabaseExecutor db)`
- **What**: Returns the maximum order value for exercises in a routine, or -1 if empty.
- **How**: Uses raw SQL with `COALESCE(MAX("order"), -1)` aggregation.
- **Why**: Needed when adding a new exercise to determine the next order value (avoids fetching all exercises).
- **For**: Adding exercises to routines efficiently.

---

### RoutineSetDao

**Purpose**: Manage sets within routine exercises (the template sets for exercises in a routine).

**Functions**:

#### `getByRoutineExerciseId(String routineExerciseId)`
- **What**: Returns all sets for a given routine exercise.
- **How**: Queries the `routine_sets` table with WHERE clause on routine exercise ID, ordered by the `order` column.
- **Why**: Needed when assembling `RoutineDetail` to show the template sets for each exercise.
- **For**: Routine detail pages, routine editing.

#### `getByRoutineExerciseIds(List<String> routineExerciseIds)`
- **What**: Returns sets for multiple routine exercises in a single batch query.
- **How**: Uses `IN (?)` clause with placeholders, ordered by routine exercise ID and order.
- **Why**: Avoids N+1 queries when fetching sets for all exercises in a routine.
- **For**: Routine detail assembly, starting a workout from a routine.

#### `insert(RoutineSet routineSet, DatabaseExecutor db)`
- **What**: Inserts a new set into a routine exercise.
- **How**: Uses `db.insert()` with the routine set's `toMap()` result.
- **Why**: Adds template sets when users add exercises to routines.
- **For**: Adding sets to routine exercises.

#### `update(RoutineSet routineSet, DatabaseExecutor db)`
- **What**: Updates an existing routine set in the database.
- **How**: Uses `db.update()` with the routine set's `toMap()` result and WHERE clause on ID.
- **Why**: Allows users to edit set parameters (weight, reps, etc.).
- **For**: Editing routine sets.

#### `updateOrder(String id, int newOrder, DatabaseExecutor db)`
- **What**: Updates only the order column of a routine set.
- **How**: Uses `db.update()` with only the `order` field in the update map.
- **Why**: Allows reordering sets without overwriting other fields (avoids full row replacement bug that would overwrite `setType`).
- **For**: Reordering sets in a routine exercise.

#### `delete(String id, DatabaseExecutor db)`
- **What**: Deletes a single set from a routine exercise.
- **How**: Uses `db.delete()` with WHERE clause on ID.
- **Why**: Allows users to remove sets from routine exercises.
- **For**: Removing sets from routine exercises.

#### `deleteByRoutineExerciseId(String routineExerciseId, DatabaseExecutor db)`
- **What**: Deletes all sets for a given routine exercise.
- **How**: Uses `db.delete()` with WHERE clause on routine exercise ID.
- **Why**: Needed when deleting an exercise from a routine.
- **For**: Removing exercises from routines (cleanup).

---

### WorkoutDao

**Purpose**: CRUD operations for workouts and workout history queries.

**Functions**:

#### `getById(String id, [DatabaseExecutor? db])`
- **What**: Returns a single workout by its ID. Accepts optional DatabaseExecutor for transaction isolation.
- **How**: Queries the `workouts` table with WHERE clause on primary key. Uses `db ?? _db` to support both transaction and non-transaction calls.
- **Why**: Needed when fetching specific workout details, both inside and outside transactions.
- **For**: Workout detail pages, workout completion flow.

#### `getActive()`
- **What**: Returns the currently active workout (status = active), or null if none exists.
- **How**: Queries the `workouts` table with WHERE clause on status, limited to 1 result.
- **Why**: Needed to check if a workout is currently in progress.
- **For**: Starting/stopping workouts, active workout indicator.

#### `getHistory({int limit, int offset, DateTime? from, DateTime? to})`
- **What**: Returns workout history with aggregated statistics (total exercises, total sets) for pagination and date filtering.
- **How**: Uses raw SQL with LEFT JOINs to `workout_exercises` and `workout_sets`, GROUP BY workout ID, with COUNT aggregations. Supports independent `from` and `to` date filters.
- **Why**: Provides the data needed for the workout history page with pagination and date range filtering.
- **For**: Workout history page, workout statistics.

#### `getExerciseNamesForWorkouts(List<String> workoutIds, {int limit})`
- **What**: Returns a map of workout IDs to lists of exercise names (up to `limit` per workout) in a single batch query.
- **How**: Uses raw SQL with JOIN to exercises table, WHERE `IN (?)` for workout IDs, and `WHERE "order" < limit` to filter at the SQL level (avoids fetching all rows and truncating in Dart).
- **Why**: Avoids N+1 queries when populating exercise names for the workout history list.
- **For**: Workout history page (showing which exercises were in each workout).

#### `insert(Workout workout, DatabaseExecutor db)`
- **What**: Inserts a new workout into the database.
- **How**: Uses `db.insert()` with the workout's `toMap()` result. Returns void (caller already has the UUID).
- **Why**: Creates new workouts when users start them.
- **For**: Starting a workout.

#### `updateStatus(String id, WorkoutStatus status, DatabaseExecutor db)`
- **What**: Updates the status of a workout (active, completed, cancelled).
- **How**: Uses `db.update()` with only the status field.
- **Why**: Transitions workouts between states (start → complete → cancel).
- **For**: Completing/cancelling workouts.

#### `updateVolume(String id, double volume, DatabaseExecutor db)`
- **What**: Updates the total volume of a workout.
- **How**: Uses `db.update()` with only the volume field.
- **Why**: Recalculates and stores the total volume when sets are completed/uncompleted/removed.
- **For**: Volume tracking, workout statistics.

#### `updateMeta({required String id, String? name, String? notes, DatabaseExecutor? db})`
- **What**: Updates workout metadata (name, notes). Accepts optional DatabaseExecutor.
- **How**: Uses `db ?? _db` pattern, updates only non-null fields.
- **Why**: Allows users to edit workout name and notes mid-workout.
- **For**: Workout editing flow.

#### `updateEndTime(String id, DateTime endTime, DatabaseExecutor db)`
- **What**: Updates the end time of a workout.
- **How**: Uses `db.update()` with only the end time field.
- **Why**: Records when a workout was completed or cancelled.
- **For**: Workout completion/cancellation flow.

---

### WorkoutExerciseDao

**Purpose**: Manage exercises within active workouts.

**Functions**:

#### `getByWorkoutId(String workoutId)`
- **What**: Returns all exercises for a given workout.
- **How**: Queries the `workout_exercises` table with WHERE clause on workout ID, ordered by the `order` column.
- **Why**: Needed when assembling `WorkoutDetail` to show which exercises are in a workout.
- **For**: Workout detail pages, active workout UI.

#### `getByIds(List<String> ids)`
- **What**: Returns multiple workout exercises by their IDs in a single batch query.
- **How**: Uses `IN (?)` clause with placeholders.
- **Why**: Avoids N+1 queries when fetching workout exercises in bulk.
- **For**: Batch workout exercise fetching.

#### `getById(String id, [DatabaseExecutor? db])`
- **What**: Returns a single workout exercise by its ID. Accepts optional DatabaseExecutor for transaction isolation.
- **How**: Queries the `workout_exercises` table with WHERE clause on primary key. Uses `db ?? _db` pattern.
- **Why**: Needed when fetching specific workout exercise details inside transactions (e.g., for volume recalculation).
- **For**: Set completion/removal flow (to get workout ID).

#### `insert(WorkoutExercise workoutExercise, DatabaseExecutor db)`
- **What**: Inserts a new exercise into a workout.
- **How**: Uses `db.insert()` with the workout exercise's `toMap()` result.
- **Why**: Adds exercises when users add them to a workout (ad-hoc exercises).
- **For**: Adding ad-hoc exercises to workouts.

#### `updateOrder(String id, int newOrder, DatabaseExecutor db)`
- **What**: Updates only the order column of a workout exercise.
- **How**: Uses `db.update()` with only the `order` field in the update map.
- **Why**: Allows reordering exercises without overwriting other fields.
- **For**: Reordering exercises in a workout.

#### `delete(String id, DatabaseExecutor db)`
- **What**: Deletes a single exercise from a workout.
- **How**: Uses `db.delete()` with WHERE clause on ID. CASCADE deletes handle child sets.
- **Why**: Allows users to remove exercises from workouts.
- **For**: Removing exercises from workouts.

#### `getMaxOrder(String workoutId, DatabaseExecutor db)`
- **What**: Returns the maximum order value for exercises in a workout, or -1 if empty.
- **How**: Uses raw SQL with `COALESCE(MAX("order"), -1)` aggregation.
- **Why**: Needed when adding a new exercise to determine the next order value.
- **For**: Adding exercises to workouts efficiently.

---

### WorkoutSetDao

**Purpose**: Manage sets within workout exercises (the actual performed sets).

**Functions**:

#### `getByWorkoutExerciseId(String workoutExerciseId)`
- **What**: Returns all sets for a given workout exercise.
- **How**: Queries the `workout_sets` table with WHERE clause on workout exercise ID, ordered by the `order` column.
- **Why**: Needed when assembling `WorkoutDetail` to show the performed sets for each exercise.
- **For**: Workout detail pages, active workout UI.

#### `getByWorkoutExerciseIds(List<String> workoutExerciseIds)`
- **What**: Returns sets for multiple workout exercises in a single batch query.
- **How**: Uses `IN (?)` clause with placeholders, ordered by workout exercise ID and order.
- **Why**: Avoids N+1 queries when fetching sets for all exercises in a workout.
- **For**: Workout detail assembly, active workout loading.

#### `getById(String id, [DatabaseExecutor? db])`
- **What**: Returns a single workout set by its ID. Accepts optional DatabaseExecutor for transaction isolation.
- **How**: Queries the `workout_sets` table with WHERE clause on primary key. Uses `db ?? _db` pattern.
- **Why**: Needed when fetching specific set details inside transactions (e.g., for completion/uncompletion).
- **For**: Set completion/uncompletion flow.

#### `insert(WorkoutSet workoutSet, DatabaseExecutor db)`
- **What**: Inserts a new set into a workout exercise.
- **How**: Uses `db.insert()` with the workout set's `toMap()` result.
- **Why**: Adds sets when users add them to exercises or when starting a workout from a routine.
- **For**: Adding sets to workout exercises.

#### `update(WorkoutSet workoutSet, DatabaseExecutor db)`
- **What**: Updates an existing workout set in the database.
- **How**: Uses `db.update()` with the workout set's `toMap()` result and WHERE clause on ID.
- **Why**: Allows users to edit set parameters (weight, reps, etc.) mid-workout.
- **For**: Editing workout sets.

#### `updateOrder(String id, int newOrder, DatabaseExecutor db)`
- **What**: Updates only the order column of a workout set.
- **How**: Uses `db.update()` with only the `order` field in the update map.
- **Why**: Allows reordering sets without overwriting other fields (avoids full row replacement bug that would overwrite `setType`).
- **For**: Reordering sets in a workout exercise.

#### `delete(String id, DatabaseExecutor db)`
- **What**: Deletes a single set from a workout exercise.
- **How**: Uses `db.delete()` with WHERE clause on ID.
- **Why**: Allows users to remove sets from workout exercises.
- **For**: Removing sets from workout exercises.

#### `computeVolume(String workoutId, DatabaseExecutor db)`
- **What**: Calculates the total volume for a workout (sum of weight × reps for all completed sets).
- **How**: Uses raw SQL with SUM aggregation on completed sets only.
- **Why**: Recalculates volume when sets are completed/uncompleted/removed to keep statistics accurate.
- **For**: Volume tracking, workout statistics.

#### `getLastCompletedAt(String workoutExerciseId)`
- **What**: Returns the timestamp of the last completed set for a workout exercise, or null if none.
- **How**: Uses raw SQL with MAX aggregation on completed sets.
- **Why**: Needed for showing "last completed" information in the UI.
- **For**: Workout exercise UI, progress tracking.

#### `getMaxOrder(String workoutExerciseId, DatabaseExecutor db)`
- **What**: Returns the maximum order value for sets in a workout exercise, or -1 if empty.
- **How**: Uses raw SQL with `COALESCE(MAX("order"), -1)` aggregation.
- **Why**: Needed when adding a new set to determine the next order value.
- **For**: Adding sets to workout exercises efficiently.

---

### ExerciseStatsDao

**Purpose**: Query exercise-level statistics for analytics and personal best tracking.

**Functions**:

#### `getPersonalBest(String exerciseId)`
- **What**: Returns the personal best record for an exercise (highest weight for a given rep range).
- **How**: Uses raw SQL to find the maximum weight achieved for completed sets of the exercise.
- **Why**: Shows users their best performance for motivation and tracking.
- **For**: Exercise detail page, personal best display.

#### `getRecentHistoryWorkouts(String exerciseId, {int limit})`
- **What**: Returns recent workouts that include the given exercise.
- **How**: Uses raw SQL with JOIN to workouts, ordered by start time descending.
- **Why**: Shows users when they last performed this exercise.
- **For**: Exercise detail page, workout history context.

#### `getRecentHistorySets(String exerciseId, {int limit})`
- **What**: Returns recent completed sets for the given exercise.
- **How**: Uses raw SQL ordered by completion time descending.
- **Why**: Shows users their recent performance for the exercise.
- **For**: Exercise detail page, performance tracking.

#### `getWeightOverTime(String exerciseId, {int days})`
- **What**: Returns weight progression data over time for the exercise.
- **How**: Uses raw SQL with date grouping and MAX weight aggregation.
- **Why**: Shows users their strength progression over time.
- **For**: Exercise analytics, progress charts.

#### `getVolumeOverTime(String exerciseId, {int days})`
- **What**: Returns volume progression data over time for the exercise.
- **How**: Uses raw SQL with date grouping and SUM volume aggregation.
- **Why**: Shows users their volume progression over time.
- **For**: Exercise analytics, progress charts.

#### `getTotalSessions(String exerciseId)`
- **What**: Returns the total number of workout sessions that include the given exercise.
- **How**: Uses raw SQL with COUNT DISTINCT on workout IDs.
- **Why**: Shows users how frequently they perform this exercise.
- **For**: Exercise detail page, frequency tracking.

---

### AnalyticsDao

**Purpose**: High-level aggregate queries for analytics dashboards.

**Functions**:

#### `getVolumeHistory({required int days})`
- **What**: Returns volume data points for the last N days.
- **How**: Uses raw SQL to query completed workouts with start time and volume, filtered by date cutoff.
- **Why**: Provides data for volume-over-time charts.
- **For**: Analytics dashboard, volume trends.

#### `getWorkoutFrequency({required int weeks, required int weekMs})`
- **What**: Returns workout frequency data grouped by week buckets.
- **How**: Uses raw SQL with integer division by `weekMs` to create week buckets, COUNT aggregation per bucket. Uses UTC week calculation (not locale-aware).
- **Why**: Provides data for workout frequency charts.
- **For**: Analytics dashboard, workout consistency tracking.

#### `getMuscleGroupBreakdown({required int days})`
- **What**: Returns set counts grouped by primary muscle for the last N days.
- **How**: Uses raw SQL with JOIN through exercises to muscles, COUNT aggregation, GROUP BY muscle ID.
- **Why**: Shows users which muscle groups they've been working on.
- **For**: Analytics dashboard, muscle balance tracking.

---

## Repository Layer

### ExerciseRepositoryImpl

**Purpose**: Assemble exercise-related data from multiple DAOs into composite read models.

**Injected Dependencies**: `ExerciseDao`, `MuscleDao`, `EquipmentDao`, `ExerciseStatsDao`, `WorkoutExerciseDao`

**Functions**:

#### `getExercises({String? muscleId, String? equipmentId, ExerciseTrackingType? trackingType, String? query})`
- **What**: Returns filtered list of exercises.
- **How**: Calls `ExerciseDao.getFiltered` with the provided filters.
- **Why**: Provides the exercise list for the exercise browser with filtering.
- **For**: Exercise search/filter UI.

#### `getExerciseDetail(String exerciseId)`
- **What**: Returns a composite `ExerciseDetail` containing the exercise, primary muscle, secondary muscles, equipment, and stats.
- **How**: 
  1. Fetches exercise by ID
  2. Fetches primary muscle by exercise's primary muscle ID
  3. Fetches secondary muscle IDs, then fetches those muscles
  4. Fetches equipment by exercise's equipment ID
  5. Calls `_buildExerciseStats` to get personal best and recent history
  6. Assembles all into `ExerciseDetail`
- **Why**: Provides a complete view of an exercise for the detail page.
- **For**: Exercise detail page.

#### `_buildExerciseStats(Exercise exercise)`
- **What**: Builds the `ExerciseStats` model for an exercise.
- **How**:
  1. Gets personal best from `ExerciseStatsDao`
  2. Gets recent workout history from `ExerciseStatsDao`
  3. Gets recent sets from `ExerciseStatsDao`
  4. Maps workout exercise IDs to workout IDs using `WorkoutExerciseDao.getByIds`
  5. Groups sets by workout and assembles `ExerciseHistoryEntry` objects
- **Why**: Provides rich statistics and history for the exercise detail page.
- **For**: Exercise detail page (private helper).

---

### RoutineRepositoryImpl

**Purpose**: Manage routines, exercises within routines, and sets within routine exercises.

**Injected Dependencies**: `RoutineDao`, `RoutineExerciseDao`, `RoutineSetDao`, `ExerciseDao`, `WorkoutExerciseDao`, `WorkoutSetDao`, `Database`, `Uuid`

**Functions**:

#### `getRoutines()`
- **What**: Returns all routines.
- **How**: Calls `RoutineDao.getAll()`.
- **Why**: Provides the routine list for the routine selection page.
- **For**: Routine list page.

#### `getRoutineDetail(String routineId)`
- **What**: Returns a composite `RoutineDetail` containing the routine and all exercises with their sets.
- **How**:
  1. Fetches routine by ID
  2. Fetches routine exercises by routine ID
  3. Fetches routine sets for all exercises in batch
  4. Fetches exercises for all routine exercises in batch
  5. Groups sets by routine exercise ID
  6. Assembles `RoutineExerciseDetail` objects
  7. Assembles into `RoutineDetail`
- **Why**: Provides a complete view of a routine for the detail/edit page.
- **For**: Routine detail page, routine editing.

#### `createRoutine(RoutineInput input)`
- **What**: Creates a new routine with exercises and sets.
- **How**:
  1. Generates UUID for routine
  2. Creates `Routine` object
  3. Starts transaction
  4. Inserts routine
  5. For each exercise input: generates UUID, creates `RoutineExercise`, inserts it
  6. For each set input: generates UUID, creates `RoutineSet`, inserts it
- **Why**: Allows users to create new routines from scratch.
- **For**: Routine creation flow.

#### `updateRoutine({required String routineId, required RoutineInput input})`
- **What**: Updates an existing routine with new exercises and sets.
- **How**:
  1. Fetches current routine detail
  2. Updates routine metadata
  3. Starts transaction
  4. Deletes all existing routine exercises (CASCADE deletes sets)
  5. Inserts new exercises and sets from input
- **Why**: Allows users to edit routines completely (replace-all approach).
- **For**: Routine editing flow.

#### `deleteRoutine(String routineId)`
- **What**: Deletes a routine.
- **How**: Calls `RoutineDao.delete()` (CASCADE handles cleanup).
- **Why**: Allows users to delete routines.
- **For**: Routine deletion flow.

#### `saveRoutine(RoutineInput input)`
- **What**: Saves a routine (creates if no ID, updates if ID exists).
- **How**: Checks if input has an ID, calls `createRoutine` or `updateRoutine` accordingly.
- **Why**: Provides a single save method for both create and update scenarios.
- **For**: Routine save form.

#### `getRoutineDraft(String sourceRoutineId, {bool asCopy})`
- **What**: Returns a `RoutineInput` draft based on an existing routine.
- **How**:
  1. Fetches routine detail
  2. Maps to `RoutineInput`
  3. Appends " Copy" to name if `asCopy` is true
- **Why**: Provides a starting point for editing or duplicating routines.
- **For**: Routine edit flow, routine duplication.

#### `addExerciseToRoutine({required String routineId, required String exerciseId, int? targetRestSeconds})`
- **What**: Adds an exercise to a routine.
- **How**:
  1. Starts transaction
  2. Gets max order from `RoutineExerciseDao.getMaxOrder`
  3. Generates UUID, creates `RoutineExercise` with order = max + 1
  4. Inserts routine exercise
- **Why**: Allows users to add exercises to routines efficiently (single query for max order).
- **For**: Adding exercises to routines.

#### `removeExerciseFromRoutine(String routineExerciseId)`
- **What**: Removes an exercise from a routine.
- **How**: Calls `RoutineExerciseDao.delete()` (CASCADE deletes sets).
- **Why**: Allows users to remove exercises from routines.
- **For**: Removing exercises from routines.

#### `reorderRoutineExercises({required String routineId, required List<String> orderedIds})`
- **What**: Reorders exercises within a routine.
- **How**:
  1. Starts transaction
  2. Iterates through ordered IDs with index
  3. Calls `RoutineExerciseDao.updateOrder` for each
- **Why**: Allows users to reorder exercises in a routine.
- **For**: Reordering routine exercises.

#### `addSetToRoutineExercise({required String routineExerciseId, required RoutineSetInput input})`
- **What**: Adds a set to a routine exercise.
- **How**:
  1. Starts transaction
  2. Gets max order from `RoutineSetDao.getMaxOrder`
  3. Generates UUID, creates `RoutineSet` with order = max + 1
  4. Inserts routine set
- **Why**: Allows users to add template sets to routine exercises.
- **For**: Adding sets to routine exercises.

#### `removeRoutineSet(String routineSetId)`
- **What**: Removes a set from a routine exercise.
- **How**: Calls `RoutineSetDao.delete()`.
- **Why**: Allows users to remove template sets from routine exercises.
- **For**: Removing sets from routine exercises.

#### `reorderRoutineSets({required String routineExerciseId, required List<String> orderedIds})`
- **What**: Reorders sets within a routine exercise.
- **How**:
  1. Starts transaction
  2. Iterates through ordered IDs with index
  3. Calls `RoutineSetDao.updateOrder` for each (not full update to avoid overwriting `setType`)
- **Why**: Allows users to reorder sets in a routine exercise.
- **For**: Reordering routine sets.

#### `syncCompletedSetsToRoutine({required String workoutId, required String routineId})`
- **What**: Syncs completed sets from a workout back to the routine template.
- **How**:
  1. Fetches routine detail and workout detail
  2. Starts transaction
  3. For each workout exercise: finds matching routine exercise by exercise ID
  4. Skips if no match (ad-hoc exercise)
  5. For each completed set: updates corresponding routine set with actual values
- **Why**: Allows users to update their routine templates based on actual workout performance.
- **For**: Updating routine templates from workouts.

#### `_getWorkoutDetail(String workoutId)`
- **What**: Private helper to fetch workout detail (used by sync).
- **How**:
  1. Uses injected `WorkoutExerciseDao` and `WorkoutSetDao` (not inline construction)
  2. Fetches workout exercises, sets, exercises in batch
  3. Assembles `WorkoutDetail`
- **Why**: Provides workout data for syncing without bypassing DI.
- **For**: Sync helper (private).

---

### WorkoutRepositoryImpl

**Purpose**: Manage workouts, exercises within workouts, and performed sets.

**Injected Dependencies**: `WorkoutDao`, `WorkoutExerciseDao`, `WorkoutSetDao`, `ExerciseDao`, `RoutineExerciseDao`, `RoutineSetDao`, `Database`, `Uuid`

**Functions**:

#### `startWorkout({required String name, String? routineId})`
- **What**: Starts a new workout, optionally copying exercises from a routine.
- **How**:
  1. Starts transaction
  2. Generates UUID, creates `Workout` with active status
  3. Inserts workout
  4. If routineId provided: fetches routine exercises and sets in batch
  5. For each routine exercise: creates `WorkoutExercise`, inserts it
  6. For each routine set: creates `WorkoutSet`, inserts it
  7. Assembles `WorkoutDetail` inline (not calling external method to stay in transaction)
- **Why**: Allows users to start a workout, optionally from a routine template.
- **For**: Starting a workout.

#### `getActiveWorkout()`
- **What**: Returns the currently active workout detail, or null if none.
- **How**:
  1. Gets active workout from `WorkoutDao.getActive()`
  2. If found, calls `getWorkoutDetail` to assemble full detail
- **Why**: Provides the active workout for the workout UI.
- **For**: Active workout page.

#### `getWorkoutDetail(String workoutId)`
- **What**: Returns a composite `WorkoutDetail` containing the workout and all exercises with their sets.
- **How**:
  1. Fetches workout by ID
  2. Fetches workout exercises by workout ID
  3. Fetches workout sets for all exercises in batch
  4. Fetches exercises for all workout exercises in batch
  5. Groups sets by workout exercise ID
  6. Assembles `WorkoutExerciseDetail` objects
  7. Assembles into `WorkoutDetail`
- **Why**: Provides a complete view of a workout for the detail page.
- **For**: Workout detail page, active workout UI.

#### `completeWorkout(String workoutId)`
- **What**: Marks a workout as completed.
- **How**:
  1. Starts transaction
  2. Updates status to completed
  3. Updates end time to now
  4. Fetches workout using `WorkoutDao.getById` with `txn` (for isolation)
- **Why**: Allows users to complete a workout.
- **For**: Completing a workout.

#### `cancelWorkout(String workoutId)`
- **What**: Cancels a workout (marks as cancelled without completion).
- **How**:
  1. Starts transaction
  2. Updates status to cancelled
  3. Updates end time to now
- **Why**: Allows users to abort a workout mid-session.
- **For**: Cancelling a workout.

#### `updateWorkoutMeta({required String workoutId, String? name, String? notes})`
- **What**: Updates workout metadata (name, notes).
- **How**: Calls `WorkoutDao.updateMeta` with the provided fields.
- **Why**: Allows users to edit workout name and notes mid-workout.
- **For**: Workout editing flow.

#### `addExerciseToWorkout({required String workoutId, required String exerciseId})`
- **What**: Adds an ad-hoc exercise to a workout (not from routine).
- **How**:
  1. Starts transaction
  2. Gets max order from `WorkoutExerciseDao.getMaxOrder`
  3. Generates UUID, creates `WorkoutExercise` with order = max + 1
  4. Inserts workout exercise
- **Why**: Allows users to add exercises on-the-fly during a workout.
- **For**: Adding ad-hoc exercises to workouts.

#### `removeExerciseFromWorkout(String workoutExerciseId)`
- **What**: Removes an exercise from a workout.
- **How**: Calls `WorkoutExerciseDao.delete()` (CASCADE deletes sets).
- **Why**: Allows users to remove exercises from workouts.
- **For**: Removing exercises from workouts.

#### `reorderExercises({required String workoutId, required List<String> orderedIds})`
- **What**: Reorders exercises within a workout.
- **How**:
  1. Starts transaction
  2. Iterates through ordered IDs with index
  3. Calls `WorkoutExerciseDao.updateOrder` for each
- **Why**: Allows users to reorder exercises in a workout.
- **For**: Reordering workout exercises.

#### `addSetToWorkoutExercise({required String workoutExerciseId})`
- **What**: Adds a new set to a workout exercise.
- **How**:
  1. Starts transaction
  2. Gets max order from `WorkoutSetDao.getMaxOrder`
  3. Generates UUID, creates `WorkoutSet` with order = max + 1
  4. Inserts workout set
- **Why**: Allows users to add sets to exercises during a workout.
- **For**: Adding sets to workout exercises.

#### `updateSet(WorkoutSet set)`
- **What**: Updates a workout set's parameters.
- **How**: Calls `WorkoutSetDao.update` with the set object.
- **Why**: Allows users to edit set parameters (weight, reps, etc.) mid-workout.
- **For**: Editing workout sets.

#### `completeSet(String setId)`
- **What**: Marks a set as completed and recalculates workout volume.
- **How**:
  1. Starts transaction
  2. Fetches set using `WorkoutSetDao.getById` with `txn` (for isolation)
  3. Creates updated set with `isCompleted = true` and `completedAt = now`
  4. Updates set
  5. Fetches workout exercise using `WorkoutExerciseDao.getById` with `txn` (for isolation)
  6. Recomputes volume using `WorkoutSetDao.computeVolume` with `txn`
  7. Updates workout volume
- **Why**: Allows users to mark sets as complete and keeps volume statistics accurate.
- **For**: Completing sets during a workout.

#### `uncompleteSet(String setId)`
- **What**: Marks a set as not completed and recalculates workout volume.
- **How**:
  1. Starts transaction
  2. Fetches set using `WorkoutSetDao.getById` with `txn` (for isolation)
  3. Creates updated set with `isCompleted = false` and `completedAt = null`
  4. Updates set
  5. Fetches workout exercise using `WorkoutExerciseDao.getById` with `txn` (for isolation)
  6. Recomputes volume using `WorkoutSetDao.computeVolume` with `txn`
  7. Updates workout volume
- **Why**: Allows users to undo set completion and keeps volume statistics accurate.
- **For**: Uncompleting sets during a workout.

#### `removeSet(String setId)`
- **What**: Removes a set and always recalculates workout volume.
- **How**:
  1. Starts transaction
  2. Fetches set using `WorkoutSetDao.getById` with `txn` (for isolation)
  3. Fetches workout exercise using `WorkoutExerciseDao.getById` with `txn` (for isolation)
  4. Deletes set
  5. Recomputes volume using `WorkoutSetDao.computeVolume` with `txn`
  6. Updates workout volume
- **Why**: Allows users to remove sets and keeps volume statistics accurate (always recompute, regardless of `isCompleted`).
- **For**: Removing sets during a workout.

#### `reorderSets({required String workoutExerciseId, required List<String> orderedIds})`
- **What**: Reorders sets within a workout exercise.
- **How**:
  1. Starts transaction
  2. Iterates through ordered IDs with index
  3. Calls `WorkoutSetDao.updateOrder` for each (not full update to avoid overwriting `setType`)
- **Why**: Allows users to reorder sets in a workout exercise.
- **For**: Reordering workout sets.

#### `getLastCompletedSetTime(String workoutExerciseId)`
- **What**: Returns the timestamp of the last completed set for a workout exercise.
- **How**: Calls `WorkoutSetDao.getLastCompletedAt`.
- **Why**: Shows users when they last completed a set for this exercise.
- **For**: Workout exercise UI, progress tracking.

#### `getWorkoutHistory({int limit, int offset, DateTime? from, DateTime? to})`
- **What**: Returns paginated workout history with exercise names.
- **How**:
  1. Fetches history maps from `WorkoutDao.getHistory`
  2. Fetches exercise names in batch using `WorkoutDao.getExerciseNamesForWorkouts`
  3. Assembles `WorkoutSummary` objects
- **Why**: Provides the workout history list for the history page.
- **For**: Workout history page.

---

### AnalyticsRepositoryImpl

**Purpose**: Provide high-level analytics data by aggregating data from the DAO layer.

**Injected Dependencies**: `AnalyticsDao`

**Functions**:

#### `getVolumeHistory({int days})`
- **What**: Returns volume data points for the last N days.
- **How**: Calls `AnalyticsDao.getVolumeHistory` and maps results to record type.
- **Why**: Provides data for volume-over-time charts.
- **For**: Analytics dashboard, volume trends.

#### `getWorkoutFrequency({int weeks})`
- **What**: Returns workout frequency data grouped by week.
- **How**:
  1. Defines `weekMs` constant (604800000ms = 1 week in UTC)
  2. Calls `AnalyticsDao.getWorkoutFrequency` with the constant
  3. Maps bucket numbers back to week start timestamps
- **Why**: Provides data for workout frequency charts.
- **For**: Analytics dashboard, workout consistency tracking.

#### `getMuscleGroupBreakdown({int days})`
- **What**: Returns set counts grouped by primary muscle for the last N days.
- **How**:
  1. Calls `AnalyticsDao.getMuscleGroupBreakdown`
  2. Maps results to a Map<String, int> with muscle names as keys
  3. Includes comment about muscle name uniqueness assumption
- **Why**: Shows users which muscle groups they've been working on.
- **For**: Analytics dashboard, muscle balance tracking.

---

## Transaction Patterns

### Read-Modify-Write Transactions

Used when a read is needed to determine what to write, and atomicity is required:

```dart
await _db.transaction((txn) async {
  final set = await _workoutSetDao.getById(setId, txn); // read inside txn
  // ... modify
  await _workoutSetDao.update(updatedSet, txn); // write inside txn
});
```

**Examples**: `completeSet`, `uncompleteSet`, `removeSet`, `addExerciseToRoutine`

### Multi-Step Write Transactions

Used when multiple writes must succeed or fail together:

```dart
await _db.transaction((txn) async {
  await _routineDao.insert(routine, txn);
  for (final exercise in exercises) {
    await _routineExerciseDao.insert(exercise, txn);
  }
});
```

**Examples**: `createRoutine`, `updateRoutine`, `startWorkout`

### Volume Recalculation Pattern

Volume is always recalculated inside the same transaction as set changes:

```dart
await _db.transaction((txn) async {
  await _workoutSetDao.update(set, txn);
  final newVolume = await _workoutSetDao.computeVolume(workoutId, txn);
  await _workoutDao.updateVolume(workoutId, newVolume, txn);
});
```

**Why**: Ensures volume statistics are always consistent with the actual completed sets.

---

## Batch Query Patterns

### IN Clause for Batch Fetches

Used to avoid N+1 queries when fetching multiple related records:

```dart
final ids = items.map((i) => i.id).toList();
final placeholders = List.filled(ids.length, '?').join(',');
final maps = await _db.query(
  tableName,
  where: 'id IN ($placeholders)',
  whereArgs: ids,
);
```

**Examples**: `getByIds` methods in all DAOs, `getExerciseNamesForWorkouts`

### Grouping in Dart After Batch Fetch

Used when the SQL can't easily group by parent ID:

```dart
final items = await dao.getByParentIds(parentIds);
final grouped = <String, List<Item>>{};
for (final item in items) {
  grouped.putIfAbsent(item.parentId, () => []).add(item);
}
```

**Examples**: `getRoutineDetail`, `getWorkoutDetail` (grouping sets by exercise ID)

---

## DatabaseExecutor Pattern

All DAO write methods and some read methods accept `DatabaseExecutor` instead of `Database`:

```dart
Future<void> insert(Item item, DatabaseExecutor db) async {
  await db.insert(tableName, item.toMap());
}
```

**Why**: Allows the same DAO method to be used both outside transactions (pass `_db`) and inside transactions (pass `txn`).

**Optional Parameter Pattern for Reads**:

```dart
Future<Item?> getById(String id, [DatabaseExecutor? db]) async {
  final executor = db ?? _db;
  // ... use executor
}
```

**Why**: Dart doesn't support method overloading, so optional parameters are used to provide both transaction and non-transaction variants.

---

## UUID Generation

All new entities use the `Uuid` package to generate unique IDs:

```dart
final id = _uuid.v4();
final entity = Entity(id: id, ...);
```

**Why**: UUIDs are globally unique and work well with distributed systems and offline-first apps.

**Injected via DI**: The `Uuid` dependency is injected into repository constructors that need to create new entities.

---

## Error Handling

### Null Checks

DAOs return nullable types (`Future<T?>`) for single-record fetches. Repositories check for null and throw exceptions:

```dart
final item = await _dao.getById(id);
if (item == null) {
  throw Exception('Item not found: $id');
}
```

**Why**: Provides clear error messages when expected data is missing.

### Exception Messages

Use descriptive exception messages that include the ID or relevant context:

```dart
throw Exception('Workout not found: $workoutId');
throw Exception('Exercise not found: ${we.exerciseId}');
```

**Why**: Makes debugging easier when errors occur in production.

---

## Performance Considerations

### Avoiding N+1 Queries

- **Problem**: Fetching parent records, then looping to fetch child records causes N+1 queries.
- **Solution**: Use batch fetches with `IN (?)` clauses or SQL joins.
- **Examples**: `getByIds` methods, `getExerciseNamesForWorkouts`

### Index Utilization

The database schema includes indexes on frequently queried columns:

- `(workout_id, order)` on `workout_exercises` and `routine_exercises`
- `(workout_exercise_id, order)` on `workout_sets` and `routine_sets`
- Primary key indexes on all tables

**Why**: Ensures ORDER BY and WHERE clauses on these columns are efficient.

### Transaction Scope

Keep transactions as short as possible to avoid blocking other operations:

- Only include operations that must be atomic
- Avoid doing expensive work (like network calls) inside transactions
- Batch operations inside transactions instead of multiple round-trips

---

## Testing Considerations

### Dependency Injection

All DAOs and repositories use constructor injection with `@injectable`:

```dart
@injectable
class MyRepositoryImpl implements MyRepository {
  final MyDao _dao;
  MyRepositoryImpl(this._dao);
}
```

**Why**: Makes it easy to mock dependencies in tests.

### DatabaseExecutor in Tests

When testing repository methods that use transactions, pass a test database executor:

```dart
final testDb = await openTestDatabase();
final repo = MyRepositoryImpl(myDao, testDb, uuid);
await repo.someMethod(); // Uses testDb
```

**Why**: Allows testing transactional behavior in isolation.

---

## Future Enhancements

### Potential Improvements

1. **Locale-Aware Week Calculation**: `getWorkoutFrequency` currently uses UTC weeks. Could be enhanced to respect user's locale (Monday vs Sunday week start).

2. **Muscle Name Uniqueness**: `getMuscleGroupBreakdown` groups by muscle name. If user-created muscles are added, consider grouping by muscle ID instead and resolving names in Dart.

3. **Caching**: Consider adding a caching layer for frequently accessed data like exercise lists or muscle lists.

4. **Pagination**: Add cursor-based pagination for large datasets to improve performance.

5. **Offline Sync**: If offline sync is needed, consider adding conflict resolution strategies for concurrent edits.

---

## Summary

The Data Access Layer follows a clean architecture with clear separation between DAOs (SQL) and repositories (business logic). Key patterns include:

- **DAOs**: Raw SQL, typed returns, no business logic
- **Repositories**: DAO composition, model assembly, transaction ownership
- **Batch Queries**: `IN (?)` clauses to avoid N+1
- **Transactions**: `db.transaction()` for atomicity
- **DatabaseExecutor**: Optional parameter for transaction isolation
- **UUID Generation**: `Uuid` package for unique IDs
- **Dependency Injection**: `@injectable` for testability

This architecture provides a solid foundation for the fitness tracking app's data layer, with clear boundaries and consistent patterns throughout.
