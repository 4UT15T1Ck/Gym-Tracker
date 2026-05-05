import 'package:gym_tracker/core/enums/workout_status_enum.dart';
import 'package:gym_tracker/core/models/exercise_model.dart';
import 'package:gym_tracker/core/models/muscle_model.dart';
import 'package:gym_tracker/core/models/workout_exercise_model.dart';
import 'package:gym_tracker/core/models/workout_model.dart';
import 'package:gym_tracker/core/models/workout_set_model.dart';
import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';

@injectable
class AnalyticsDao {
  final Database _db;

  AnalyticsDao(this._db);

  Future<List<Map<String, dynamic>>> getVolumeHistory({
    required int days,
  }) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return await _db.rawQuery(
      '''
      SELECT w.${Workout.columnStartTime}, w.${Workout.columnVolume}
      FROM ${Workout.tableName} w
      WHERE w.${Workout.columnStatus} = ?
        AND w.${Workout.columnStartTime} >= ?
      ORDER BY w.${Workout.columnStartTime} ASC
    ''',
      [WorkoutStatus.completed.dbValue, cutoff.millisecondsSinceEpoch],
    );
  }

  Future<List<Map<String, dynamic>>> getWorkoutFrequency({
    required int weeks,
    required int weekMs,
  }) async {
    if (weekMs <= 0) throw ArgumentError('weekMs must be positive');
    final cutoff = DateTime.now().subtract(Duration(days: weeks * 7));
    return await _db.rawQuery(
      '''
      SELECT
        (${Workout.columnStartTime} / ?) as week_bucket,
        COUNT(*) as count
      FROM ${Workout.tableName}
      WHERE ${Workout.columnStatus} = ?
        AND ${Workout.columnStartTime} >= ?
      GROUP BY week_bucket
      ORDER BY week_bucket ASC
    ''',
      [weekMs, WorkoutStatus.completed.dbValue, cutoff.millisecondsSinceEpoch],
    );
  }

  Future<List<Map<String, dynamic>>> getMuscleGroupBreakdown({
    required int days,
  }) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return await _db.rawQuery(
      '''
      SELECT m.${Muscle.columnName}, COUNT(ws.${WorkoutSet.columnId}) as set_count
      FROM ${WorkoutSet.tableName} ws
      JOIN ${WorkoutExercise.tableName} we ON we.${WorkoutExercise.columnId} = ws.${WorkoutSet.columnWorkoutExerciseId}
      JOIN ${Workout.tableName} w ON w.${Workout.columnId} = we.${WorkoutExercise.columnWorkoutId}
      JOIN ${Exercise.tableName} e ON e.${Exercise.columnId} = we.${WorkoutExercise.columnExerciseId}
      JOIN ${Muscle.tableName} m ON m.${Muscle.columnId} = e.${Exercise.columnPrimaryMuscleId}
      WHERE ws.${WorkoutSet.columnIsCompleted} = 1
        AND w.${Workout.columnStatus} = ?
        AND w.${Workout.columnStartTime} >= ?
      GROUP BY m.${Muscle.columnId}
      ORDER BY set_count DESC
    ''',
      [WorkoutStatus.completed.dbValue, cutoff.millisecondsSinceEpoch],
    );
  }
}
