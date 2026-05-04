import 'package:gym_tracker/core/models/workout_exercise_model.dart';
import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';

@injectable
class WorkoutExerciseDao {
  final Database _db;

  WorkoutExerciseDao(this._db);

  Future<List<WorkoutExercise>> getByWorkoutId(String workoutId) async {
    final maps = await _db.query(
      WorkoutExercise.tableName,
      where: '${WorkoutExercise.columnWorkoutId} = ?',
      whereArgs: [workoutId],
      orderBy: '"${WorkoutExercise.columnOrder}" ASC',
    );
    return maps.map((map) => WorkoutExercise.fromMap(map)).toList();
  }

  Future<List<WorkoutExercise>> getByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final placeholders = List.filled(ids.length, '?').join(',');
    final maps = await _db.query(
      WorkoutExercise.tableName,
      where: '${WorkoutExercise.columnId} IN ($placeholders)',
      whereArgs: ids,
    );
    return maps.map((map) => WorkoutExercise.fromMap(map)).toList();
  }

  Future<WorkoutExercise?> getById(String id, [DatabaseExecutor? db]) async {
    final executor = db ?? _db;
    final maps = await executor.query(
      WorkoutExercise.tableName,
      where: '${WorkoutExercise.columnId} = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return WorkoutExercise.fromMap(maps.first);
  }

  Future<void> insert(WorkoutExercise we, DatabaseExecutor db) async {
    await db.insert(
      WorkoutExercise.tableName,
      we.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateOrder(String id, int newOrder, DatabaseExecutor db) async {
    await db.update(
      WorkoutExercise.tableName,
      {WorkoutExercise.columnOrder: newOrder},
      where: '${WorkoutExercise.columnId} = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(String id, DatabaseExecutor db) async {
    await db.delete(
      WorkoutExercise.tableName,
      where: '${WorkoutExercise.columnId} = ?',
      whereArgs: [id],
    );
  }

  Future<int> getMaxOrder(String workoutId, DatabaseExecutor db) async {
    final result = await db.rawQuery('''
      SELECT COALESCE(MAX("${WorkoutExercise.columnOrder}"), -1) as max_order
      FROM ${WorkoutExercise.tableName}
      WHERE ${WorkoutExercise.columnWorkoutId} = ?
    ''', [workoutId]);
    return result.first['max_order'] as int? ?? -1;
  }
}
