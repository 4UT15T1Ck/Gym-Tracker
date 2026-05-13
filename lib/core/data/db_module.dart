import 'package:gym_tracker/core/data/seed_helper.dart';
import 'package:gym_tracker/core/models/body_measure_entry_model.dart';
import 'package:gym_tracker/core/models/equipment_model.dart';
import 'package:gym_tracker/core/models/exercise_model.dart';
import 'package:gym_tracker/core/models/exercise_second_muscle_model.dart';
import 'package:gym_tracker/core/models/muscle_model.dart';
import 'package:gym_tracker/core/models/routine_exercise_model.dart';
import 'package:gym_tracker/core/models/routine_model.dart';
import 'package:gym_tracker/core/models/routine_set_model.dart';
import 'package:gym_tracker/core/models/workout_exercise_model.dart';
import 'package:gym_tracker/core/models/workout_model.dart';
import 'package:gym_tracker/core/models/workout_set_model.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

const String _databaseName = 'gym_tracker.db';
const int _databaseVersion = 1;

@module
abstract class DatabaseModule {
  @preResolve
  @singleton
  Future<Database> initDatabase() async {
    final path = join(await getDatabasesPath(), _databaseName);

    return openDatabase(
      path,
      version: _databaseVersion,
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

Future<void> _createTables(DatabaseExecutor db) async {
  await db.execute('''
    CREATE TABLE ${Muscle.tableName} (
      ${Muscle.columnId} TEXT PRIMARY KEY,
      ${Muscle.columnName} TEXT NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE ${Equipment.tableName} (
      ${Equipment.columnId} TEXT PRIMARY KEY,
      ${Equipment.columnName} TEXT NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE ${Exercise.tableName} (
      ${Exercise.columnId} TEXT PRIMARY KEY,
      ${Exercise.columnName} TEXT NOT NULL,
      ${Exercise.columnTrackingType} TEXT NOT NULL CHECK (
        ${Exercise.columnTrackingType} IN (
          'weight_reps',
          'reps_only',
          'duration',
          'duration_distance',
          'weight_duration'
        )
      ),
      ${Exercise.columnShortDescription} TEXT,
      ${Exercise.columnInstructions} TEXT NOT NULL DEFAULT '[]',
      ${Exercise.columnPrimaryMuscleId} TEXT NOT NULL,
      ${Exercise.columnEquipmentId} TEXT,
      ${Exercise.columnImageUrl} TEXT,
      ${Exercise.columnVideoUrl} TEXT,
      FOREIGN KEY (${Exercise.columnPrimaryMuscleId}) REFERENCES ${Muscle.tableName}(${Muscle.columnId})
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
      FOREIGN KEY (${Exercise.columnEquipmentId}) REFERENCES ${Equipment.tableName}(${Equipment.columnId})
        ON UPDATE CASCADE
        ON DELETE SET NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE ${ExerciseSecondaryMuscle.tableName} (
      ${ExerciseSecondaryMuscle.columnExerciseId} TEXT NOT NULL,
      ${ExerciseSecondaryMuscle.columnMuscleId} TEXT NOT NULL,
      PRIMARY KEY (
        ${ExerciseSecondaryMuscle.columnExerciseId},
        ${ExerciseSecondaryMuscle.columnMuscleId}
      ),
      FOREIGN KEY (${ExerciseSecondaryMuscle.columnExerciseId}) REFERENCES ${Exercise.tableName}(${Exercise.columnId})
        ON UPDATE CASCADE
        ON DELETE CASCADE,
      FOREIGN KEY (${ExerciseSecondaryMuscle.columnMuscleId}) REFERENCES ${Muscle.tableName}(${Muscle.columnId})
        ON UPDATE CASCADE
        ON DELETE CASCADE
    )
  ''');

  await db.execute('''
    CREATE TABLE ${Routine.tableName} (
      ${Routine.columnId} TEXT PRIMARY KEY,
      ${Routine.columnName} TEXT NOT NULL,
      ${Routine.columnNotes} TEXT
    )
  ''');

  await db.execute('''
    CREATE TABLE ${RoutineExercise.tableName} (
      ${RoutineExercise.columnId} TEXT PRIMARY KEY,
      ${RoutineExercise.columnRoutineId} TEXT NOT NULL,
      ${RoutineExercise.columnExerciseId} TEXT NOT NULL,
      "${RoutineExercise.columnOrder}" INTEGER NOT NULL,
      ${RoutineExercise.columnTargetRestSeconds} INTEGER,
      FOREIGN KEY (${RoutineExercise.columnRoutineId}) REFERENCES ${Routine.tableName}(${Routine.columnId})
        ON UPDATE CASCADE
        ON DELETE CASCADE,
      FOREIGN KEY (${RoutineExercise.columnExerciseId}) REFERENCES ${Exercise.tableName}(${Exercise.columnId})
        ON UPDATE CASCADE
        ON DELETE RESTRICT
    )
  ''');

  await db.execute('''
    CREATE TABLE ${RoutineSet.tableName} (
      ${RoutineSet.columnId} TEXT PRIMARY KEY,
      ${RoutineSet.columnRoutineExerciseId} TEXT NOT NULL,
      ${RoutineSet.columnSetType} TEXT NOT NULL CHECK (
        ${RoutineSet.columnSetType} IN (
          'warm_up',
          'working',
          'drop_set',
          'amrap',
          'failure'
        )
      ),
      ${RoutineSet.columnTargetWeight} REAL,
      ${RoutineSet.columnTargetReps} INTEGER,
      ${RoutineSet.columnTargetDurationSeconds} INTEGER,
      ${RoutineSet.columnTargetDistance} REAL,
      ${RoutineSet.columnTargetRpe} REAL,
      "${RoutineSet.columnOrder}" INTEGER NOT NULL,
      FOREIGN KEY (${RoutineSet.columnRoutineExerciseId}) REFERENCES ${RoutineExercise.tableName}(${RoutineExercise.columnId})
        ON UPDATE CASCADE
        ON DELETE CASCADE
    )
  ''');

  await db.execute('''
    CREATE TABLE ${Workout.tableName} (
      ${Workout.columnId} TEXT PRIMARY KEY,
      ${Workout.columnRoutineId} TEXT,
      ${Workout.columnName} TEXT NOT NULL,
      ${Workout.columnStartTime} INTEGER NOT NULL,
      ${Workout.columnEndTime} INTEGER,
      ${Workout.columnStatus} TEXT NOT NULL DEFAULT 'active' CHECK (
        ${Workout.columnStatus} IN ('active', 'completed', 'cancelled')
      ),
      ${Workout.columnNotes} TEXT,
      ${Workout.columnVolume} REAL NOT NULL DEFAULT 0,
      FOREIGN KEY (${Workout.columnRoutineId}) REFERENCES ${Routine.tableName}(${Routine.columnId})
        ON UPDATE CASCADE
        ON DELETE SET NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE ${WorkoutExercise.tableName} (
      ${WorkoutExercise.columnId} TEXT PRIMARY KEY,
      ${WorkoutExercise.columnWorkoutId} TEXT NOT NULL,
      ${WorkoutExercise.columnExerciseId} TEXT NOT NULL,
      "${WorkoutExercise.columnOrder}" INTEGER NOT NULL,
      ${WorkoutExercise.columnRestSeconds} INTEGER,
      FOREIGN KEY (${WorkoutExercise.columnWorkoutId}) REFERENCES ${Workout.tableName}(${Workout.columnId})
        ON UPDATE CASCADE
        ON DELETE CASCADE,
      FOREIGN KEY (${WorkoutExercise.columnExerciseId}) REFERENCES ${Exercise.tableName}(${Exercise.columnId})
        ON UPDATE CASCADE
        ON DELETE RESTRICT
    )
  ''');

  await db.execute('''
    CREATE TABLE ${WorkoutSet.tableName} (
      ${WorkoutSet.columnId} TEXT PRIMARY KEY,
      ${WorkoutSet.columnWorkoutExerciseId} TEXT NOT NULL,
      ${WorkoutSet.columnSetType} TEXT NOT NULL CHECK (
        ${WorkoutSet.columnSetType} IN (
          'warm_up',
          'working',
          'drop_set',
          'amrap',
          'failure'
        )
      ),
      ${WorkoutSet.columnWeight} REAL,
      ${WorkoutSet.columnReps} INTEGER,
      ${WorkoutSet.columnDurationSeconds} INTEGER,
      ${WorkoutSet.columnDistance} REAL,
      ${WorkoutSet.columnRpe} REAL,
      ${WorkoutSet.columnCompletedAt} INTEGER,
      "${WorkoutSet.columnOrder}" INTEGER NOT NULL,
      ${WorkoutSet.columnIsCompleted} INTEGER NOT NULL DEFAULT 0 CHECK (
        ${WorkoutSet.columnIsCompleted} IN (0, 1)
      ),
      FOREIGN KEY (${WorkoutSet.columnWorkoutExerciseId}) REFERENCES ${WorkoutExercise.tableName}(${WorkoutExercise.columnId})
        ON UPDATE CASCADE
        ON DELETE CASCADE
    )
  ''');

  await db.execute('''
    CREATE TABLE ${BodyMeasureEntry.tableName} (
      ${BodyMeasureEntry.columnId} TEXT PRIMARY KEY,
      ${BodyMeasureEntry.columnDate} INTEGER NOT NULL,
      ${BodyMeasureEntry.columnWeight} REAL,
      ${BodyMeasureEntry.columnBodyFatPercent} REAL,
      ${BodyMeasureEntry.columnCustomMeasurementsJson} TEXT NOT NULL DEFAULT '{}'
    )
  ''');
}

Future<void> _createIndexes(DatabaseExecutor db) async {
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_${Exercise.tableName}_${Exercise.columnPrimaryMuscleId} ON ${Exercise.tableName}(${Exercise.columnPrimaryMuscleId})',
  );
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_${Exercise.tableName}_${Exercise.columnEquipmentId} ON ${Exercise.tableName}(${Exercise.columnEquipmentId})',
  );
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_${ExerciseSecondaryMuscle.tableName}_${ExerciseSecondaryMuscle.columnMuscleId} ON ${ExerciseSecondaryMuscle.tableName}(${ExerciseSecondaryMuscle.columnMuscleId})',
  );
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_${RoutineExercise.tableName}_${RoutineExercise.columnRoutineId} ON ${RoutineExercise.tableName}(${RoutineExercise.columnRoutineId})',
  );
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_${RoutineExercise.tableName}_${RoutineExercise.columnExerciseId} ON ${RoutineExercise.tableName}(${RoutineExercise.columnExerciseId})',
  );
  await db.execute(
    'CREATE UNIQUE INDEX IF NOT EXISTS idx_${RoutineExercise.tableName}_${RoutineExercise.columnRoutineId}_order ON ${RoutineExercise.tableName}(${RoutineExercise.columnRoutineId}, "${RoutineExercise.columnOrder}")',
  );
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_${RoutineSet.tableName}_${RoutineSet.columnRoutineExerciseId} ON ${RoutineSet.tableName}(${RoutineSet.columnRoutineExerciseId})',
  );
  await db.execute(
    'CREATE UNIQUE INDEX IF NOT EXISTS idx_${RoutineSet.tableName}_${RoutineSet.columnRoutineExerciseId}_order ON ${RoutineSet.tableName}(${RoutineSet.columnRoutineExerciseId}, "${RoutineSet.columnOrder}")',
  );
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_${Workout.tableName}_${Workout.columnRoutineId} ON ${Workout.tableName}(${Workout.columnRoutineId})',
  );
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_${WorkoutExercise.tableName}_${WorkoutExercise.columnWorkoutId} ON ${WorkoutExercise.tableName}(${WorkoutExercise.columnWorkoutId})',
  );
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_${WorkoutExercise.tableName}_${WorkoutExercise.columnExerciseId} ON ${WorkoutExercise.tableName}(${WorkoutExercise.columnExerciseId})',
  );
  await db.execute(
    'CREATE UNIQUE INDEX IF NOT EXISTS idx_${WorkoutExercise.tableName}_${WorkoutExercise.columnWorkoutId}_order ON ${WorkoutExercise.tableName}(${WorkoutExercise.columnWorkoutId}, "${WorkoutExercise.columnOrder}")',
  );
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_${WorkoutSet.tableName}_${WorkoutSet.columnWorkoutExerciseId} ON ${WorkoutSet.tableName}(${WorkoutSet.columnWorkoutExerciseId})',
  );
  await db.execute(
    'CREATE UNIQUE INDEX IF NOT EXISTS idx_${WorkoutSet.tableName}_${WorkoutSet.columnWorkoutExerciseId}_order ON ${WorkoutSet.tableName}(${WorkoutSet.columnWorkoutExerciseId}, "${WorkoutSet.columnOrder}")',
  );
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_${BodyMeasureEntry.tableName}_${BodyMeasureEntry.columnDate} ON ${BodyMeasureEntry.tableName}(${BodyMeasureEntry.columnDate})',
  );
}