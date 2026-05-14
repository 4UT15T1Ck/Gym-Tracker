import 'package:gym_tracker/core/dao/body_measurement_dao.dart';
import 'package:gym_tracker/core/models/body_measure_entry_model.dart';
import 'package:gym_tracker/core/repositories/body_measurement_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

@LazySingleton(as: BodyMeasurementRepository)
class BodyMeasurementRepositoryImpl implements BodyMeasurementRepository {
  final BodyMeasurementDao _dao;
  final Database _db;
  final Uuid _uuid;

  BodyMeasurementRepositoryImpl(this._dao, this._db, this._uuid);

  @override
  Future<List<BodyMeasureEntry>> getEntries() => _dao.getAll();

  @override
  Future<BodyMeasureEntry?> getLatestEntry() => _dao.getLatest();

  @override
  Future<BodyMeasureEntry> addEntry({
    required DateTime date,
    double? weight,
    double? bodyFatPercent,
    Map<String, double> customMeasurements = const {},
  }) async {
    final entry = BodyMeasureEntry(
      id: _uuid.v4(),
      date: date,
      weight: weight,
      bodyFatPercent: bodyFatPercent,
      customMeasurements: customMeasurements,
    );
    await _db.transaction((txn) => _dao.insert(entry, txn));
    return entry;
  }

  @override
  Future<void> deleteEntry(String id) async {
    await _db.transaction((txn) async {
      await txn.delete(
        BodyMeasureEntry.tableName,
        where: '${BodyMeasureEntry.columnId} = ?',
        whereArgs: [id],
      );
    });
  }
}
