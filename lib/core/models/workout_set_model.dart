import 'package:equatable/equatable.dart';
import 'package:gym_tracker/core/enums/set_type_enum.dart';

class WorkoutSet extends Equatable {
  static const String tableName = 'workout_sets';
  static const String columnId = 'id';
  static const String columnWorkoutExerciseId = 'workout_exercise_id';
  static const String columnSetType = 'set_type';
  static const String columnWeight = 'weight';
  static const String columnReps = 'reps';
  static const String columnDurationSeconds = 'duration_seconds';
  static const String columnDistance = 'distance';
  static const String columnRpe = 'rpe';
  static const String columnCompletedAt = 'completed_at';
  static const String columnOrder = 'order';
  static const String columnIsCompleted = 'is_completed';

  final String id;
  final String workoutExerciseId;
  final SetType setType;
  final double? weight;
  final int? reps;
  final int? durationSeconds;
  final double? distance;
  final double? rpe;
  final DateTime? completedAt;
  final int order;
  final bool isCompleted;

  const WorkoutSet({
    required this.id,
    required this.workoutExerciseId,
    required this.setType,
    this.weight,
    this.reps,
    this.durationSeconds,
    this.distance,
    this.rpe,
    this.completedAt,
    required this.order,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() => {
    columnId: id,
    columnWorkoutExerciseId: workoutExerciseId,
    columnSetType: setType.dbValue,
    columnWeight: weight,
    columnReps: reps,
    columnDurationSeconds: durationSeconds,
    columnDistance: distance,
    columnRpe: rpe,
    columnCompletedAt: completedAt?.millisecondsSinceEpoch,
    columnOrder: order,
    columnIsCompleted: isCompleted ? 1 : 0,
  };

  factory WorkoutSet.fromMap(Map<String, dynamic> map) => WorkoutSet(
    id: map[columnId] as String,
    workoutExerciseId: map[columnWorkoutExerciseId] as String,
    setType: setTypeFromDbValue(map[columnSetType] as String?),
    weight: _asDouble(map[columnWeight]),
    reps: map[columnReps] as int?,
    durationSeconds: map[columnDurationSeconds] as int?,
    distance: _asDouble(map[columnDistance]),
    rpe: _asDouble(map[columnRpe]),
    completedAt: map[columnCompletedAt] != null
        ? DateTime.fromMillisecondsSinceEpoch(map[columnCompletedAt] as int)
        : null,
    order: map[columnOrder] as int,
    isCompleted: map[columnIsCompleted] == 1,
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

  @override
  List<Object?> get props => [
        id,
        workoutExerciseId,
        setType,
        weight,
        reps,
        durationSeconds,
        distance,
        rpe,
        completedAt,
        order,
        isCompleted,
      ];
}
