import 'package:gym_tracker/core/enums/set_type_enum.dart';
import 'package:gym_tracker/core/models/routine_exercise_model.dart';
import 'package:gym_tracker/core/models/routine_model.dart';
import 'package:gym_tracker/core/models/routine_set_model.dart';
import 'package:gym_tracker/core/repositories/repository_models.dart';

abstract class RoutineRepository {
  Future<List<Routine>> getRoutines();

  Future<RoutineDetail> getRoutineDetail(String routineId);

  Future<RoutineDetail> updateRoutine({
    required String routineId,
    required RoutineInput input,
  });

  Future<void> deleteRoutine(String routineId);

  Future<RoutineDetail> saveRoutine(RoutineInput input);

  Future<RoutineInput> getRoutineDraft(
    String sourceRoutineId, {
    bool asCopy = false,
  });

  Future<RoutineExercise> addExerciseToRoutine({
    required String routineId,
    required String exerciseId,
    int? targetRestSeconds,
  });

  Future<void> reorderRoutineExercises({
    required String routineId,
    required List<String> orderedIds,
  });

  Future<void> removeExerciseFromRoutine(String routineExerciseId);

  Future<RoutineSet> addSetToRoutineExercise({
    required String routineExerciseId,
    required SetType setType,
    double? targetWeight,
    int? targetReps,
    int? targetDurationSeconds,
    double? targetDistance,
    double? targetRpe,
  });

  Future<RoutineSet> updateRoutineSet(RoutineSet set);

  Future<void> removeRoutineSet(String routineSetId);

  Future<void> reorderRoutineSets({
    required String routineExerciseId,
    required List<String> orderedIds,
  });

  Future<void> syncCompletedSetsToRoutine({
    required String workoutId,
    required String routineId,
  });
}
