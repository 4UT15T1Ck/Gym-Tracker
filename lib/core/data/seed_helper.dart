import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:gym_tracker/core/models/equipment_model.dart';
import 'package:gym_tracker/core/models/exercise_model.dart';
import 'package:gym_tracker/core/models/exercise_second_muscle_model.dart';
import 'package:gym_tracker/core/models/muscle_model.dart';
import 'package:sqflite/sqflite.dart';

Future<void> seedDatabaseFromJson(Database db) async {
  final String jsonString = await rootBundle.loadString(
    'assets/seed_data.json',
  );
  final Map<String, dynamic> data = Map<String, dynamic>.from(
    jsonDecode(jsonString) as Map,
  );

  final List<Map<String, dynamic>> muscleJson = _asJsonMapList(
    data[Muscle.tableName],
  );
  final List<Map<String, dynamic>> equipmentJson = _asJsonMapList(
    data[Equipment.tableName],
  );
  final List<Map<String, dynamic>> exerciseJson = _asJsonMapList(
    data[Exercise.tableName],
  );

  final List<Muscle> muscles = muscleJson
      .map((item) => Muscle.fromJson(item))
      .toList(growable: false);

  final List<Equipment> equipment = equipmentJson
      .map((item) => Equipment.fromJson(item))
      .toList(growable: false);

  final List<Exercise> exercises = exerciseJson
      .map((item) => Exercise.fromJson(item))
      .toList(growable: false);

  final List<ExerciseSecondaryMuscle> secondaryMuscles = exerciseJson
      .expand(_parseSecondaryMuscles)
      .toList(growable: false);

  final batch = db.batch();

  for (final muscle in muscles) {
    batch.insert(
      Muscle.tableName,
      muscle.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  for (final equip in equipment) {
    batch.insert(
      Equipment.tableName,
      equip.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  for (final exercise in exercises) {
    batch.insert(
      Exercise.tableName,
      exercise.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  for (final secondaryMuscle in secondaryMuscles) {
    batch.insert(
      ExerciseSecondaryMuscle.tableName,
      secondaryMuscle.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  await batch.commit(noResult: true);
}

List<Map<String, dynamic>> _asJsonMapList(dynamic rawList) {
  if (rawList is! List) {
    return const [];
  }

  return rawList
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList(growable: false);
}

List<ExerciseSecondaryMuscle> _parseSecondaryMuscles(
  Map<String, dynamic> exerciseJson,
) {
  final String? exerciseId = exerciseJson[Exercise.columnId]?.toString();
  if (exerciseId == null || exerciseId.isEmpty) {
    return const [];
  }

  final dynamic rawSecondaryMuscles = exerciseJson['secondary_muscle_ids'];

  if (rawSecondaryMuscles is! List) {
    return const [];
  }

  return rawSecondaryMuscles
      .map(_parseSecondaryMuscleId)
      .whereType<String>()
      .map(
        (muscleId) =>
            ExerciseSecondaryMuscle(exerciseId: exerciseId, muscleId: muscleId),
      )
      .toList(growable: false);
}

String? _parseSecondaryMuscleId(dynamic rawValue) {
  if (rawValue == null) {
    return null;
  }

  if (rawValue is String || rawValue is num) {
    final value = rawValue.toString().trim();
    return value.isEmpty ? null : value;
  }

  if (rawValue is Map) {
    final dynamic id =
        rawValue[ExerciseSecondaryMuscle.columnMuscleId] ??
        rawValue[Muscle.columnId] ??
        rawValue['id'];

    if (id == null) {
      return null;
    }

    final value = id.toString().trim();
    return value.isEmpty ? null : value;
  }

  return null;
}
