import 'package:gym_tracker/core/enums/set_type_enum.dart';
import 'package:gym_tracker/core/models/workout_exercise_model.dart';
import 'package:gym_tracker/core/models/workout_model.dart';
import 'package:gym_tracker/core/models/workout_set_model.dart';
import 'package:gym_tracker/core/repositories/repository_models.dart';

abstract class WorkoutRepository {
  Future<WorkoutDetail> startWorkout({required String name, String? routineId});

  Future<WorkoutDetail?> getActiveWorkout();

  Future<WorkoutDetail> getWorkoutDetail(String workoutId);

  Future<Workout> completeWorkout(String workoutId);

  Future<void> cancelWorkout(String workoutId);

  Future<List<WorkoutSummary>> getWorkoutHistory({
    int limit = 20,
    int offset = 0,
    DateTime? from,
    DateTime? to,
  });

  Future<Workout> updateWorkoutMeta({
    required String workoutId,
    String? name,
    String? notes,
  });

  Future<WorkoutExercise> addExerciseToWorkout({
    required String workoutId,
    required String exerciseId,
    int? restSeconds,
  });

  Future<void> reorderWorkoutExercises({
    required String workoutId,
    required List<String> orderedIds,
  });

  Future<void> removeExerciseFromWorkout(String workoutExerciseId);

  Future<WorkoutSet> addSet({
    required String workoutExerciseId,
    SetType setType = SetType.working,
  });

  Future<WorkoutSet> updateSet(WorkoutSet set);

  Future<({WorkoutSet set, double newVolume})> completeSet(String setId);

  Future<({WorkoutSet set, double newVolume})> uncompleteSet(String setId);

  Future<double> removeSet(String setId);

  Future<void> reorderSets({
    required String workoutExerciseId,
    required List<String> orderedIds,
  });

  Future<DateTime?> getLastCompletedSetTime(String workoutExerciseId);
}
