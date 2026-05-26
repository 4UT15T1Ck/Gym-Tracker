import 'package:equatable/equatable.dart';

class ExerciseSecondaryMuscle extends Equatable {
  static const String tableName = 'exercise_secondary_muscles';
  static const String columnExerciseId = 'exercise_id';
  static const String columnMuscleId = 'muscle_id';

  final String exerciseId;
  final String muscleId;

  const ExerciseSecondaryMuscle({
    required this.exerciseId,
    required this.muscleId,
  });

  Map<String, dynamic> toMap() => {
    columnExerciseId: exerciseId,
    columnMuscleId: muscleId,
  };

  factory ExerciseSecondaryMuscle.fromMap(Map<String, dynamic> map) =>
      ExerciseSecondaryMuscle(
        exerciseId: map[columnExerciseId] as String,
        muscleId: map[columnMuscleId] as String,
      );

  @override
  List<Object?> get props => [exerciseId, muscleId];
}
