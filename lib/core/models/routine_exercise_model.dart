class RoutineExercise {
  static const String tableName = 'routine_exercises';
  static const String columnId = 'id';
  static const String columnRoutineId = 'routine_id';
  static const String columnExerciseId = 'exercise_id';
  static const String columnOrder = 'order';
  static const String columnTargetRestSeconds = 'target_rest_seconds';

  final String id;
  final String routineId;
  final String exerciseId;
  final int order;
  final int? targetRestSeconds;

  RoutineExercise({
    required this.id,
    required this.routineId,
    required this.exerciseId,
    required this.order,
    this.targetRestSeconds,
  });

  Map<String, dynamic> toMap() => {
    columnId: id,
    columnRoutineId: routineId,
    columnExerciseId: exerciseId,
    columnOrder: order,
    columnTargetRestSeconds: targetRestSeconds,
  };

  factory RoutineExercise.fromMap(Map<String, dynamic> map) => RoutineExercise(
    id: map[columnId] as String,
    routineId: map[columnRoutineId] as String,
    exerciseId: map[columnExerciseId] as String,
    order: map[columnOrder] as int,
    targetRestSeconds: map[columnTargetRestSeconds] as int?,
  );
}
