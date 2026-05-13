import 'package:gym_tracker/core/models/body_measure_entry_model.dart';
import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';

@Injectable()
class BodyMeasurementDao {
  final Database _db;

  BodyMeasurementDao(this._db);

  Future<List<BodyMeasureEntry>> getAll() async {
    final maps = await _db.query(
      BodyMeasureEntry.tableName,
      orderBy: '${BodyMeasureEntry.columnDate} DESC',
    );
    return maps.map(BodyMeasureEntry.fromMap).toList();
  }

  Future<BodyMeasureEntry?> getLatest() async {
    final maps = await _db.query(
      BodyMeasureEntry.tableName,
      orderBy: '${BodyMeasureEntry.columnDate} DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return BodyMeasureEntry.fromMap(maps.first);
  }

  Future<void> insert(BodyMeasureEntry entry, DatabaseExecutor db) async {
    await db.insert(
      BodyMeasureEntry.tableName,
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String id) async {
    await _db.delete(
      BodyMeasureEntry.tableName,
      where: '${BodyMeasureEntry.columnId} = ?',
      whereArgs: [id],
    );
  }
}
