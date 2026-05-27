import 'package:gym_tracker/core/models/muscle_model.dart';
import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';

@lazySingleton
class MuscleDao {
  final Database _db;

  MuscleDao(this._db);

  Future<List<Muscle>> getAll() async {
    final maps = await _db.query(
      Muscle.tableName,
      orderBy: '${Muscle.columnName} ASC',
    );
    return maps.map((map) => Muscle.fromMap(map)).toList();
  }

  Future<Muscle?> getById(String id) async {
    final maps = await _db.query(
      Muscle.tableName,
      where: '${Muscle.columnId} = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Muscle.fromMap(maps.first);
  }

  Future<List<Muscle>> getByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final placeholders = List.filled(ids.length, '?').join(',');
    final maps = await _db.query(
      Muscle.tableName,
      where: '${Muscle.columnId} IN ($placeholders)',
      whereArgs: ids,
    );
    return maps.map((map) => Muscle.fromMap(map)).toList();
  }
}
