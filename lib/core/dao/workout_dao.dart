import 'package:gym_tracker/core/enums/workout_status_enum.dart';
import 'package:gym_tracker/core/models/exercise_model.dart';
import 'package:gym_tracker/core/models/workout_exercise_model.dart';
import 'package:gym_tracker/core/models/workout_model.dart';
import 'package:gym_tracker/core/models/workout_set_model.dart';
import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';

@lazySingleton
class WorkoutDao {
  final Database _db;

  WorkoutDao(this._db);

  Future<Workout?> getById(String id, [DatabaseExecutor? db]) async {
    final executor = db ?? _db;
    final maps = await executor.query(
      Workout.tableName,
      where: '${Workout.columnId} = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Workout.fromMap(maps.first);
  }

  Future<Workout?> getActive([DatabaseExecutor? db]) async {
    final executor = db ?? _db;
    final maps = await executor.query(
      Workout.tableName,
      where: '${Workout.columnStatus} = ?',
      whereArgs: [WorkoutStatus.active.dbValue],
      orderBy: '${Workout.columnStartTime} DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Workout.fromMap(maps.first);
  }

  Future<List<Map<String, dynamic>>> getHistory({
    int limit = 20,
    int offset = 0,
    DateTime? from,
    DateTime? to,
  }) async {
    final buffer = StringBuffer('''
      SELECT
        w.${Workout.columnId},
        w.${Workout.columnName},
        w.${Workout.columnStartTime},
        w.${Workout.columnEndTime},
        w.${Workout.columnVolume},
        COUNT(DISTINCT we.${WorkoutExercise.columnId}) as total_exercises,
        COUNT(ws.${WorkoutSet.columnId}) as total_sets
      FROM ${Workout.tableName} w
      LEFT JOIN ${WorkoutExercise.tableName} we ON we.${WorkoutExercise.columnWorkoutId} = w.${Workout.columnId}
      LEFT JOIN ${WorkoutSet.tableName} ws ON ws.${WorkoutSet.columnWorkoutExerciseId} = we.${WorkoutExercise.columnId}
        AND ws.${WorkoutSet.columnIsCompleted} = 1
      WHERE w.${Workout.columnStatus} = ?
    ''');

    final whereArgs = <dynamic>[WorkoutStatus.completed.dbValue];

    if (from != null) {
      buffer.write(' AND w.${Workout.columnStartTime} >= ?');
      whereArgs.add(from.millisecondsSinceEpoch);
    }
    if (to != null) {
      buffer.write(' AND w.${Workout.columnStartTime} <= ?');
      whereArgs.add(to.millisecondsSinceEpoch);
    }

    buffer.write(' GROUP BY w.${Workout.columnId}');
    buffer.write(' ORDER BY w.${Workout.columnStartTime} DESC');
    buffer.write(' LIMIT ? OFFSET ?');
    whereArgs.add(limit);
    whereArgs.add(offset);

    return await _db.rawQuery(buffer.toString(), whereArgs);
  }

  Future<Map<String, List<String>>> getExerciseNamesForWorkouts(
    List<String> workoutIds, {
    int limit = 4,
  }) async {
    if (workoutIds.isEmpty) return {};
    final placeholders = List.filled(workoutIds.length, '?').join(',');
    final maps = await _db.rawQuery('''
      SELECT we.${WorkoutExercise.columnWorkoutId}, e.${Exercise.columnName}
      FROM ${WorkoutExercise.tableName} we
      JOIN ${Exercise.tableName} e ON e.${Exercise.columnId} = we.${WorkoutExercise.columnExerciseId}
      WHERE we.${WorkoutExercise.columnWorkoutId} IN ($placeholders)
        AND we."${WorkoutExercise.columnOrder}" < ?
      ORDER BY we.${WorkoutExercise.columnWorkoutId}, we."${WorkoutExercise.columnOrder}" ASC
    ''', [...workoutIds, limit]);

    final result = <String, List<String>>{};
    for (final map in maps) {
      final workoutId = map[WorkoutExercise.columnWorkoutId] as String;
      final exerciseName = map[Exercise.columnName] as String;
      result.putIfAbsent(workoutId, () => []).add(exerciseName);
    }

    return result;
  }

  Future<List<({String workoutId, String exerciseId, String primaryMuscleId})>> getWorkoutMuscleGroups(
    List<String> workoutIds,
  ) async {
    if (workoutIds.isEmpty) return [];
    final placeholders = List.filled(workoutIds.length, '?').join(',');
    final maps = await _db.rawQuery('''
      SELECT
        we.${WorkoutExercise.columnWorkoutId} as workout_id,
        we.${WorkoutExercise.columnExerciseId} as exercise_id,
        e.${Exercise.columnPrimaryMuscleId} as primary_muscle_id
      FROM ${WorkoutExercise.tableName} we
      JOIN ${Exercise.tableName} e ON e.${Exercise.columnId} = we.${WorkoutExercise.columnExerciseId}
      WHERE we.${WorkoutExercise.columnWorkoutId} IN ($placeholders)
      ORDER BY we.${WorkoutExercise.columnWorkoutId}, we."${WorkoutExercise.columnOrder}" ASC
    ''', workoutIds);

    return maps
        .map(
          (map) => (
            workoutId: map['workout_id'] as String,
            exerciseId: map['exercise_id'] as String,
            primaryMuscleId: map['primary_muscle_id'] as String,
          ),
        )
        .toList();
  }

  Future<void> insert(Workout workout, DatabaseExecutor db) async {
    await db.insert(
      Workout.tableName,
      workout.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<void> updateStatus(String id, WorkoutStatus status, DatabaseExecutor db) async {
    await db.update(
      Workout.tableName,
      {Workout.columnStatus: status.dbValue},
      where: '${Workout.columnId} = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateVolume(String id, double volume, DatabaseExecutor db) async {
    await db.update(
      Workout.tableName,
      {Workout.columnVolume: volume},
      where: '${Workout.columnId} = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateMeta({
    required String id,
    String? name,
    String? notes,
    bool clearNotes = false,
    DatabaseExecutor? db,
  }) async {
    final executor = db ?? _db;
    final updates = <String, dynamic>{};
    if (name != null) updates[Workout.columnName] = name;
    if (clearNotes) {
      updates[Workout.columnNotes] = null;
    } else if (notes != null) {
      updates[Workout.columnNotes] = notes;
    }

    if (updates.isNotEmpty) {
      await executor.update(
        Workout.tableName,
        updates,
        where: '${Workout.columnId} = ?',
        whereArgs: [id],
      );
    }
  }

  Future<void> updateEndTime(String id, DateTime endTime, DatabaseExecutor db) async {
    await db.update(
      Workout.tableName,
      {Workout.columnEndTime: endTime.millisecondsSinceEpoch},
      where: '${Workout.columnId} = ?',
      whereArgs: [id],
    );
  }
}
