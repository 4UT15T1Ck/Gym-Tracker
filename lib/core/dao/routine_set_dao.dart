import 'package:gym_tracker/core/models/routine_set_model.dart';
import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';

@lazySingleton
class RoutineSetDao {
  final Database _db;

  RoutineSetDao(this._db);

  Future<List<RoutineSet>> getByRoutineExerciseId(
    String routineExerciseId, [
    DatabaseExecutor? db,
  ]) async {
    final executor = db ?? _db;
    final maps = await executor.query(
      RoutineSet.tableName,
      where: '${RoutineSet.columnRoutineExerciseId} = ?',
      whereArgs: [routineExerciseId],
      orderBy: '"${RoutineSet.columnOrder}" ASC',
    );
    return maps.map((map) => RoutineSet.fromMap(map)).toList();
  }

  Future<List<RoutineSet>> getByRoutineExerciseIds(
    List<String> ids, [
    DatabaseExecutor? db,
  ]) async {
    if (ids.isEmpty) return [];
    final executor = db ?? _db;
    final placeholders = List.filled(ids.length, '?').join(',');
    final maps = await executor.query(
      RoutineSet.tableName,
      where: '${RoutineSet.columnRoutineExerciseId} IN ($placeholders)',
      whereArgs: ids,
      orderBy: '${RoutineSet.columnRoutineExerciseId}, "${RoutineSet.columnOrder}" ASC',
    );
    return maps.map((map) => RoutineSet.fromMap(map)).toList();
  }

  Future<void> insert(RoutineSet set, DatabaseExecutor db) async {
    await db.insert(
      RoutineSet.tableName,
      set.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(RoutineSet set, DatabaseExecutor db) async {
    await db.update(
      RoutineSet.tableName,
      set.toMap(),
      where: '${RoutineSet.columnId} = ?',
      whereArgs: [set.id],
    );
  }

  Future<void> updateOrder(String id, int newOrder, DatabaseExecutor db) async {
    await db.update(
      RoutineSet.tableName,
      {RoutineSet.columnOrder: newOrder},
      where: '${RoutineSet.columnId} = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(String id, DatabaseExecutor db) async {
    await db.delete(
      RoutineSet.tableName,
      where: '${RoutineSet.columnId} = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteByRoutineExerciseId(String routineExerciseId, DatabaseExecutor db) async {
    await db.delete(
      RoutineSet.tableName,
      where: '${RoutineSet.columnRoutineExerciseId} = ?',
      whereArgs: [routineExerciseId],
    );
  }

  Future<int> getMaxOrder(String routineExerciseId, DatabaseExecutor db) async {
    final result = await db.rawQuery(
      'SELECT COALESCE(MAX("${RoutineSet.columnOrder}"), -1) as max_order FROM ${RoutineSet.tableName} WHERE ${RoutineSet.columnRoutineExerciseId} = ?',
      [routineExerciseId],
    );
    return result.first['max_order'] as int? ?? -1;
  }
}
