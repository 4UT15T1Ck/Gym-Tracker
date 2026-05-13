import 'package:gym_tracker/core/enums/tracking_type_enum.dart';
import 'package:gym_tracker/core/models/exercise_model.dart';
import 'package:gym_tracker/core/models/exercise_second_muscle_model.dart';
import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';

@injectable
class ExerciseDao {
  final Database _db;

  ExerciseDao(this._db);

  Future<List<Exercise>> getAll() async {
    final maps = await _db.query(
      Exercise.tableName,
      orderBy: '${Exercise.columnName} ASC',
    );
    return maps.map((map) => Exercise.fromMap(map)).toList();
  }

  Future<Exercise?> getById(String id, [DatabaseExecutor? db]) async {
    final executor = db ?? _db;
    final maps = await executor.query(
      Exercise.tableName,
      where: '${Exercise.columnId} = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Exercise.fromMap(maps.first);
  }

  Future<List<Exercise>> getByIds(List<String> ids, [DatabaseExecutor? db]) async {
    if (ids.isEmpty) return [];
    final executor = db ?? _db;
    final placeholders = List.filled(ids.length, '?').join(',');
    final maps = await executor.query(
      Exercise.tableName,
      where: '${Exercise.columnId} IN ($placeholders)',
      whereArgs: ids,
    );
    return maps.map((map) => Exercise.fromMap(map)).toList();
  }

  Future<List<Exercise>> getFiltered({
    String? muscleId,
    String? equipmentId,
    ExerciseTrackingType? trackingType,
    String? query,
  }) async {
    final buffer = StringBuffer('SELECT DISTINCT e.* FROM ${Exercise.tableName} e');
    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];

    if (muscleId != null) {
      buffer.write(
        ' LEFT JOIN ${ExerciseSecondaryMuscle.tableName} esm ON esm.${ExerciseSecondaryMuscle.columnExerciseId} = e.${Exercise.columnId}',
      );
      whereConditions.add(
        '(e.${Exercise.columnPrimaryMuscleId} = ? OR esm.${ExerciseSecondaryMuscle.columnMuscleId} = ?)',
      );
      whereArgs.add(muscleId);
      whereArgs.add(muscleId);
    }

    if (equipmentId != null) {
      whereConditions.add('e.${Exercise.columnEquipmentId} = ?');
      whereArgs.add(equipmentId);
    }

    if (trackingType != null) {
      whereConditions.add('e.${Exercise.columnTrackingType} = ?');
      whereArgs.add(trackingType.dbValue);
    }

    if (query != null && query.isNotEmpty) {
      whereConditions.add('e.${Exercise.columnName} LIKE ?');
      whereArgs.add('%$query%');
    }

    if (whereConditions.isNotEmpty) {
      buffer.write(' WHERE ${whereConditions.join(' AND ')}');
    }

    buffer.write(' ORDER BY e.${Exercise.columnName} ASC');

    final maps = await _db.rawQuery(buffer.toString(), whereArgs);
    return maps.map((map) => Exercise.fromMap(map)).toList();
  }

  Future<List<String>> getSecondaryMuscleIds(String exerciseId) async {
    final maps = await _db.query(
      ExerciseSecondaryMuscle.tableName,
      columns: [ExerciseSecondaryMuscle.columnMuscleId],
      where: '${ExerciseSecondaryMuscle.columnExerciseId} = ?',
      whereArgs: [exerciseId],
    );
    return maps
        .map((map) => map[ExerciseSecondaryMuscle.columnMuscleId] as String)
        .toList();
  }

  Future<Map<String, List<String>>> getAllSecondaryMuscleMap() async {
    final maps = await _db.query(ExerciseSecondaryMuscle.tableName);
    final result = <String, List<String>>{};
    for (final map in maps) {
      final exerciseId = map[ExerciseSecondaryMuscle.columnExerciseId] as String;
      final muscleId = map[ExerciseSecondaryMuscle.columnMuscleId] as String;
      result.putIfAbsent(exerciseId, () => []).add(muscleId);
    }
    return result;
  }
}
