import 'package:gym_tracker/core/enums/set_type_enum.dart';

class RoutineSet {
  static const String tableName = 'routine_sets';
  static const String columnId = 'id';
  static const String columnRoutineExerciseId = 'routine_exercise_id';
  static const String columnSetType = 'set_type';
  static const String columnTargetWeight = 'target_weight';
  static const String columnTargetReps = 'target_reps';
  static const String columnTargetDurationSeconds = 'target_duration_seconds';
  static const String columnTargetDistance = 'target_distance';
  static const String columnTargetRpe = 'target_rpe';
  static const String columnOrder = 'order';

  final String id;
  final String routineExerciseId;
  final SetType setType;
  final double? targetWeight;
  final int? targetReps;
  final int? targetDurationSeconds;
  final double? targetDistance;
  final double? targetRpe;
  final int order;

  RoutineSet({
    required this.id,
    required this.routineExerciseId,
    required this.setType,
    this.targetWeight,
    this.targetReps,
    this.targetDurationSeconds,
    this.targetDistance,
    this.targetRpe,
    required this.order,
  });

  Map<String, dynamic> toMap() => {
    columnId: id,
    columnRoutineExerciseId: routineExerciseId,
    columnSetType: setType.dbValue,
    columnTargetWeight: targetWeight,
    columnTargetReps: targetReps,
    columnTargetDurationSeconds: targetDurationSeconds,
    columnTargetDistance: targetDistance,
    columnTargetRpe: targetRpe,
    columnOrder: order,
  };

  factory RoutineSet.fromMap(Map<String, dynamic> map) => RoutineSet(
    id: map[columnId] as String,
    routineExerciseId: map[columnRoutineExerciseId] as String,
    setType: setTypeFromDbValue(map[columnSetType] as String?),
    targetWeight: _asDouble(map[columnTargetWeight]),
    targetReps: map[columnTargetReps] as int?,
    targetDurationSeconds: map[columnTargetDurationSeconds] as int?,
    targetDistance: _asDouble(map[columnTargetDistance]),
    targetRpe: _asDouble(map[columnTargetRpe]),
    order: map[columnOrder] as int,
  );

  static double? _asDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }
}
