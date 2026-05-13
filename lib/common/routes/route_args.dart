import 'package:gym_tracker/core/repositories/repository_models.dart';

class ActiveWorkoutRouteArgs {
  final String workoutId;

  const ActiveWorkoutRouteArgs({required this.workoutId});
}

class AddExerciseRouteArgs {
  final bool multiSelect;
  final List<String> initiallySelectedExerciseIds;

  const AddExerciseRouteArgs({
    this.multiSelect = true,
    this.initiallySelectedExerciseIds = const [],
  });
}

class ExerciseDetailRouteArgs {
  final String exerciseId;

  const ExerciseDetailRouteArgs({required this.exerciseId});
}

class WorkoutDetailRouteArgs {
  final String workoutId;

  const WorkoutDetailRouteArgs({required this.workoutId});
}

class RoutineDetailRouteArgs {
  final String routineId;

  const RoutineDetailRouteArgs({required this.routineId});
}

class EditRoutineRouteArgs {
  final RoutineDetail detail;

  const EditRoutineRouteArgs({required this.detail});
}
