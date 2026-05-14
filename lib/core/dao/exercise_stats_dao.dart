import 'package:gym_tracker/core/enums/workout_status_enum.dart';
import 'package:gym_tracker/core/models/exercise_model.dart';
import 'package:gym_tracker/core/models/workout_exercise_model.dart';
import 'package:gym_tracker/core/models/workout_model.dart';
import 'package:gym_tracker/core/models/workout_set_model.dart';
import 'package:gym_tracker/core/repositories/repository_models.dart';
import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';

@injectable
class ExerciseStatsDao {
  final Database _db;

  ExerciseStatsDao(this._db);

  Future<WorkoutSet?> getPersonalBest(String exerciseId) async {
    final maps = await _db.rawQuery('''
      SELECT ws.*
      FROM ${WorkoutSet.tableName} ws
      JOIN ${WorkoutExercise.tableName} we ON we.${WorkoutExercise.columnId} = ws.${WorkoutSet.columnWorkoutExerciseId}
      JOIN ${Workout.tableName} w ON w.${Workout.columnId} = we.${WorkoutExercise.columnWorkoutId}
      WHERE we.${WorkoutExercise.columnExerciseId} = ?
        AND ws.${WorkoutSet.columnIsCompleted} = 1
        AND ws.${WorkoutSet.columnWeight} IS NOT NULL
        AND ws.${WorkoutSet.columnReps} IS NOT NULL
        AND w.${Workout.columnStatus} = ?
      ORDER BY (ws.${WorkoutSet.columnWeight} * ws.${WorkoutSet.columnReps}) DESC
      LIMIT 1
    ''', [exerciseId, WorkoutStatus.completed.dbValue]);
    if (maps.isEmpty) return null;
    return WorkoutSet.fromMap(maps.first);
  }

  Future<List<ExerciseHistoryEntry>> getRecentHistory(
    String exerciseId, {
    int limit = 10,
  }) async {
    final maps = await _db.rawQuery('''
      SELECT
        w.${Workout.columnId} as workout_id,
        w.${Workout.columnName} as workout_name,
        w.${Workout.columnStartTime} as start_time,
        ws.*
      FROM ${Workout.tableName} w
      JOIN ${WorkoutExercise.tableName} we ON we.${WorkoutExercise.columnWorkoutId} = w.${Workout.columnId}
      JOIN ${WorkoutSet.tableName} ws ON ws.${WorkoutSet.columnWorkoutExerciseId} = we.${WorkoutExercise.columnId}
      WHERE we.${WorkoutExercise.columnExerciseId} = ?
        AND w.${Workout.columnStatus} = ?
        AND ws.${WorkoutSet.columnIsCompleted} = 1
      ORDER BY w.${Workout.columnStartTime} DESC, ws."${WorkoutSet.columnOrder}" ASC
      LIMIT ?
    ''', [exerciseId, WorkoutStatus.completed.dbValue, limit * 10]);

    final grouped = <String, List<WorkoutSet>>{};
    final workoutInfo = <String, ({String name, DateTime startTime})>{};

    for (final map in maps) {
      final workoutId = map['workout_id'] as String;
      final workoutName = map['workout_name'] as String;
      final startTime = DateTime.fromMillisecondsSinceEpoch(map['start_time'] as int);

      workoutInfo.putIfAbsent(
        workoutId,
        () => (name: workoutName, startTime: startTime),
      );

      final setMap = Map<String, dynamic>.from(map);
      setMap.remove('workout_id');
      setMap.remove('workout_name');
      setMap.remove('start_time');

      final set = WorkoutSet.fromMap(setMap);
      grouped.putIfAbsent(workoutId, () => []).add(set);
    }

    final entries = grouped.entries.take(limit).map((entry) {
      final info = workoutInfo[entry.key]!;
      return ExerciseHistoryEntry(
        workoutId: entry.key,
        workoutName: info.name,
        performedAt: info.startTime,
        sets: entry.value,
      );
    }).toList();

    return entries;
  }

  Future<List<Map<String, dynamic>>> getWeightOverTime(String exerciseId) async {
    return await _db.rawQuery('''
      SELECT w.${Workout.columnStartTime}, MAX(ws.${WorkoutSet.columnWeight}) as max_weight
      FROM ${WorkoutSet.tableName} ws
      JOIN ${WorkoutExercise.tableName} we ON we.${WorkoutExercise.columnId} = ws.${WorkoutSet.columnWorkoutExerciseId}
      JOIN ${Workout.tableName} w ON w.${Workout.columnId} = we.${WorkoutExercise.columnWorkoutId}
      WHERE we.${WorkoutExercise.columnExerciseId} = ?
        AND ws.${WorkoutSet.columnIsCompleted} = 1
        AND ws.${WorkoutSet.columnWeight} IS NOT NULL
        AND w.${Workout.columnStatus} = ?
      GROUP BY w.${Workout.columnId}
      ORDER BY w.${Workout.columnStartTime} ASC
    ''', [exerciseId, WorkoutStatus.completed.dbValue]);
  }

  Future<List<Map<String, dynamic>>> getVolumeOverTime(String exerciseId) async {
    return await _db.rawQuery('''
      SELECT w.${Workout.columnStartTime},
        COALESCE(SUM(ws.${WorkoutSet.columnWeight} * ws.${WorkoutSet.columnReps}), 0.0) as volume
      FROM ${WorkoutSet.tableName} ws
      JOIN ${WorkoutExercise.tableName} we ON we.${WorkoutExercise.columnId} = ws.${WorkoutSet.columnWorkoutExerciseId}
      JOIN ${Workout.tableName} w ON w.${Workout.columnId} = we.${WorkoutExercise.columnWorkoutId}
      WHERE we.${WorkoutExercise.columnExerciseId} = ?
        AND ws.${WorkoutSet.columnIsCompleted} = 1
        AND ws.${WorkoutSet.columnWeight} IS NOT NULL
        AND ws.${WorkoutSet.columnReps} IS NOT NULL
        AND w.${Workout.columnStatus} = ?
      GROUP BY w.${Workout.columnId}
      ORDER BY w.${Workout.columnStartTime} ASC
    ''', [exerciseId, WorkoutStatus.completed.dbValue]);
  }

  Future<int> getTotalSessions(String exerciseId) async {
    final result = await _db.rawQuery('''
      SELECT COUNT(DISTINCT w.${Workout.columnId}) as total_sessions
      FROM ${Workout.tableName} w
      JOIN ${WorkoutExercise.tableName} we ON we.${WorkoutExercise.columnWorkoutId} = w.${Workout.columnId}
      WHERE we.${WorkoutExercise.columnExerciseId} = ?
        AND w.${Workout.columnStatus} = ?
    ''', [exerciseId, WorkoutStatus.completed.dbValue]);
    return result.first['total_sessions'] as int? ?? 0;
  }

  /// Returns the top [limit] personal records across all exercises,
  /// ordered by most recently achieved.
  Future<List<Map<String, dynamic>>> getTopPersonalRecords({int limit = 3}) async {
    return await _db.rawQuery('''
      SELECT e.${Exercise.columnName} as exercise_name,
             MAX(ws.${WorkoutSet.columnWeight} * COALESCE(ws.${WorkoutSet.columnReps}, 1)) as best_volume,
             ws.${WorkoutSet.columnWeight} as weight,
             ws.${WorkoutSet.columnReps} as reps,
             ws.${WorkoutSet.columnCompletedAt} as completed_at
      FROM ${WorkoutSet.tableName} ws
      JOIN ${WorkoutExercise.tableName} we ON we.${WorkoutExercise.columnId} = ws.${WorkoutSet.columnWorkoutExerciseId}
      JOIN ${Workout.tableName} w ON w.${Workout.columnId} = we.${WorkoutExercise.columnWorkoutId}
      JOIN ${Exercise.tableName} e ON e.${Exercise.columnId} = we.${WorkoutExercise.columnExerciseId}
      WHERE ws.${WorkoutSet.columnIsCompleted} = 1
        AND ws.${WorkoutSet.columnWeight} IS NOT NULL
        AND w.${Workout.columnStatus} = ?
      GROUP BY we.${WorkoutExercise.columnExerciseId}
      ORDER BY ws.${WorkoutSet.columnCompletedAt} DESC
      LIMIT ?
    ''', [WorkoutStatus.completed.dbValue, limit]);
  }
}
