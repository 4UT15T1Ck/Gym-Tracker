import 'package:gym_tracker/core/models/equipment_model.dart';
import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';

@lazySingleton
class EquipmentDao {
  final Database _db;

  EquipmentDao(this._db);

  Future<List<Equipment>> getAll() async {
    final maps = await _db.query(
      Equipment.tableName,
      orderBy: '${Equipment.columnName} ASC',
    );
    return maps.map((map) => Equipment.fromMap(map)).toList();
  }

  Future<Equipment?> getById(String id) async {
    final maps = await _db.query(
      Equipment.tableName,
      where: '${Equipment.columnId} = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Equipment.fromMap(maps.first);
  }
}
