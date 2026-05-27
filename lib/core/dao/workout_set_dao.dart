import 'package:gym_tracker/core/models/workout_exercise_model.dart';
import 'package:gym_tracker/core/models/workout_set_model.dart';
import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';

@lazySingleton
class WorkoutSetDao {
  final Database _db;

  WorkoutSetDao(this._db);

  Future<List<WorkoutSet>> getByWorkoutExerciseId(
    String workoutExerciseId, [
    DatabaseExecutor? db,
  ]) async {
    final executor = db ?? _db;
    final maps = await executor.query(
      WorkoutSet.tableName,
      where: '${WorkoutSet.columnWorkoutExerciseId} = ?',
      whereArgs: [workoutExerciseId],
      orderBy: '"${WorkoutSet.columnOrder}" ASC',
    );
    return maps.map((map) => WorkoutSet.fromMap(map)).toList();
  }

  Future<List<WorkoutSet>> getByWorkoutExerciseIds(
    List<String> ids, [
    DatabaseExecutor? db,
  ]) async {
    if (ids.isEmpty) return [];
    final executor = db ?? _db;
    final placeholders = List.filled(ids.length, '?').join(',');
    final maps = await executor.query(
      WorkoutSet.tableName,
      where: '${WorkoutSet.columnWorkoutExerciseId} IN ($placeholders)',
      whereArgs: ids,
      orderBy: '${WorkoutSet.columnWorkoutExerciseId}, "${WorkoutSet.columnOrder}" ASC',
    );
    return maps.map((map) => WorkoutSet.fromMap(map)).toList();
  }

  Future<WorkoutSet?> getById(String id, [DatabaseExecutor? db]) async {
    final executor = db ?? _db;
    final maps = await executor.query(
      WorkoutSet.tableName,
      where: '${WorkoutSet.columnId} = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return WorkoutSet.fromMap(maps.first);
  }

  Future<WorkoutSet?> getLastByWorkoutExerciseId(
    String workoutExerciseId, [
    DatabaseExecutor? db,
  ]) async {
    final executor = db ?? _db;
    final maps = await executor.query(
      WorkoutSet.tableName,
      where: '${WorkoutSet.columnWorkoutExerciseId} = ?',
      whereArgs: [workoutExerciseId],
      orderBy: '"${WorkoutSet.columnOrder}" DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return WorkoutSet.fromMap(maps.first);
  }

  Future<void> insert(WorkoutSet set, DatabaseExecutor db) async {
    await db.insert(
      WorkoutSet.tableName,
      set.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(WorkoutSet set, DatabaseExecutor db) async {
    await db.update(
      WorkoutSet.tableName,
      set.toMap(),
      where: '${WorkoutSet.columnId} = ?',
      whereArgs: [set.id],
    );
  }

  Future<void> updateOrder(String id, int newOrder, DatabaseExecutor db) async {
    await db.update(
      WorkoutSet.tableName,
      {WorkoutSet.columnOrder: newOrder},
      where: '${WorkoutSet.columnId} = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(String id, DatabaseExecutor db) async {
    await db.delete(
      WorkoutSet.tableName,
      where: '${WorkoutSet.columnId} = ?',
      whereArgs: [id],
    );
  }

  Future<double> computeVolume(String workoutId, DatabaseExecutor db) async {
    // Volume = weight × reps only. Duration/distance tracking types
    // contribute 0 and are excluded by the IS NOT NULL filters.
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(ws.${WorkoutSet.columnWeight} * ws.${WorkoutSet.columnReps}), 0.0) as volume
      FROM ${WorkoutSet.tableName} ws
      JOIN ${WorkoutExercise.tableName} we ON we.${WorkoutExercise.columnId} = ws.${WorkoutSet.columnWorkoutExerciseId}
      WHERE we.${WorkoutExercise.columnWorkoutId} = ?
        AND ws.${WorkoutSet.columnIsCompleted} = 1
        AND ws.${WorkoutSet.columnWeight} IS NOT NULL
        AND ws.${WorkoutSet.columnReps} IS NOT NULL
    ''', [workoutId]);
    return (result.first['volume'] as num?)?.toDouble() ?? 0.0;
  }

  Future<DateTime?> getLastCompletedAt(String workoutExerciseId) async {
    final maps = await _db.query(
      WorkoutSet.tableName,
      columns: [WorkoutSet.columnCompletedAt],
      where: '${WorkoutSet.columnWorkoutExerciseId} = ?'
        ' AND ${WorkoutSet.columnIsCompleted} = 1'
        ' AND ${WorkoutSet.columnCompletedAt} IS NOT NULL',
      whereArgs: [workoutExerciseId],
      orderBy: '${WorkoutSet.columnCompletedAt} DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    final completedAt = maps.first[WorkoutSet.columnCompletedAt] as int?;
    if (completedAt == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(completedAt);
  }

  Future<int> getMaxOrder(String workoutExerciseId, DatabaseExecutor db) async {
    final result = await db.rawQuery('''
      SELECT COALESCE(MAX("${WorkoutSet.columnOrder}"), -1) as max_order
      FROM ${WorkoutSet.tableName}
      WHERE ${WorkoutSet.columnWorkoutExerciseId} = ?
    ''', [workoutExerciseId]);
    return result.first['max_order'] as int? ?? -1;
  }
}
