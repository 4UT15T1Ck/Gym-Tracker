import 'package:gym_tracker/core/models/routine_model.dart';
import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';

@lazySingleton
class RoutineDao {
  final Database _db;

  RoutineDao(this._db);

  Future<List<Routine>> getAll() async {
    final maps = await _db.query(
      Routine.tableName,
      orderBy: '${Routine.columnName} ASC',
    );
    return maps.map((map) => Routine.fromMap(map)).toList();
  }

  Future<Routine?> getById(String id, [DatabaseExecutor? db]) async {
    final executor = db ?? _db;
    final maps = await executor.query(
      Routine.tableName,
      where: '${Routine.columnId} = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Routine.fromMap(maps.first);
  }

  Future<String> insert(Routine routine, DatabaseExecutor db) async {
    await db.insert(
      Routine.tableName,
      routine.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return routine.id;
  }

  Future<void> update(Routine routine, DatabaseExecutor db) async {
    await db.update(
      Routine.tableName,
      routine.toMap(),
      where: '${Routine.columnId} = ?',
      whereArgs: [routine.id],
    );
  }

  Future<void> delete(String id, DatabaseExecutor db) async {
    await db.delete(
      Routine.tableName,
      where: '${Routine.columnId} = ?',
      whereArgs: [id],
    );
  }
}
