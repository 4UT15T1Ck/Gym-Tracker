import 'package:gym_tracker/core/models/routine_exercise_model.dart';
import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';

@lazySingleton
class RoutineExerciseDao {
  final Database _db;

  RoutineExerciseDao(this._db);

  Future<List<RoutineExercise>> getByRoutineId(
    String routineId, [
    DatabaseExecutor? db,
  ]) async {
    final executor = db ?? _db;
    final maps = await executor.query(
      RoutineExercise.tableName,
      where: '${RoutineExercise.columnRoutineId} = ?',
      whereArgs: [routineId],
      orderBy: '"${RoutineExercise.columnOrder}" ASC',
    );
    return maps.map((map) => RoutineExercise.fromMap(map)).toList();
  }

  Future<void> insert(RoutineExercise re, DatabaseExecutor db) async {
    await db.insert(
      RoutineExercise.tableName,
      re.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateOrder(String id, int newOrder, DatabaseExecutor db) async {
    await db.update(
      RoutineExercise.tableName,
      {RoutineExercise.columnOrder: newOrder},
      where: '${RoutineExercise.columnId} = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(String id, DatabaseExecutor db) async {
    await db.delete(
      RoutineExercise.tableName,
      where: '${RoutineExercise.columnId} = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteByRoutineId(String routineId, DatabaseExecutor db) async {
    await db.delete(
      RoutineExercise.tableName,
      where: '${RoutineExercise.columnRoutineId} = ?',
      whereArgs: [routineId],
    );
  }

  Future<int> getMaxOrder(String routineId, DatabaseExecutor db) async {
    final result = await db.rawQuery('''
      SELECT COALESCE(MAX("${RoutineExercise.columnOrder}"), -1) as max_order
      FROM ${RoutineExercise.tableName}
      WHERE ${RoutineExercise.columnRoutineId} = ?
    ''', [routineId]);
    return result.first['max_order'] as int;
  }
}
