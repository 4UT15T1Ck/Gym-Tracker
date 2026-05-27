import 'package:equatable/equatable.dart';

class WorkoutExercise extends Equatable {
  static const String tableName = 'workout_exercises';
  static const String columnId = 'id';
  static const String columnWorkoutId = 'workout_id';
  static const String columnExerciseId = 'exercise_id';
  static const String columnOrder = 'order';
  static const String columnRestSeconds = 'rest_seconds';

  final String id;
  final String workoutId;
  final String exerciseId;
  final int order;
  final int? restSeconds;

  const WorkoutExercise({
    required this.id,
    required this.workoutId,
    required this.exerciseId,
    required this.order,
    this.restSeconds,
  });

  Map<String, dynamic> toMap() => {
    columnId: id,
    columnWorkoutId: workoutId,
    columnExerciseId: exerciseId,
    columnOrder: order,
    columnRestSeconds: restSeconds,
  };

  factory WorkoutExercise.fromMap(Map<String, dynamic> map) => WorkoutExercise(
    id: map[columnId] as String,
    workoutId: map[columnWorkoutId] as String,
    exerciseId: map[columnExerciseId] as String,
    order: map[columnOrder] as int,
    restSeconds: map[columnRestSeconds] as int?,
  );

  @override
  List<Object?> get props => [id, workoutId, exerciseId, order, restSeconds];
}
