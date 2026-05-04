import 'package:gym_tracker/core/enums/set_type_enum.dart';
import 'package:gym_tracker/core/models/equipment_model.dart';
import 'package:gym_tracker/core/models/exercise_model.dart';
import 'package:gym_tracker/core/models/muscle_model.dart';
import 'package:gym_tracker/core/models/routine_exercise_model.dart';
import 'package:gym_tracker/core/models/routine_model.dart';
import 'package:gym_tracker/core/models/routine_set_model.dart';
import 'package:gym_tracker/core/models/workout_exercise_model.dart';
import 'package:gym_tracker/core/models/workout_model.dart';
import 'package:gym_tracker/core/models/workout_set_model.dart';

class RoutineDetail {
  final Routine routine;
  final List<RoutineExerciseDetail> exercises;

  const RoutineDetail({required this.routine, required this.exercises});
}

class RoutineExerciseDetail {
  final RoutineExercise routineExercise;
  final Exercise exercise;
  final List<RoutineSet> sets;

  const RoutineExerciseDetail({
    required this.routineExercise,
    required this.exercise,
    required this.sets,
  });
}

class WorkoutDetail {
  final Workout workout;
  final List<WorkoutExerciseDetail> exercises;

  const WorkoutDetail({required this.workout, required this.exercises});
}

class WorkoutExerciseDetail {
  final WorkoutExercise workoutExercise;
  final Exercise exercise;
  final List<WorkoutSet> sets;

  const WorkoutExerciseDetail({
    required this.workoutExercise,
    required this.exercise,
    required this.sets,
  });
}

class WorkoutSummary {
  final String id;
  final String name;
  final DateTime startTime;
  final DateTime endTime;
  final double volume;
  final int totalSets;
  final int totalExercises;
  final List<String> exerciseNames;

  const WorkoutSummary({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.volume,
    required this.totalSets,
    required this.totalExercises,
    required this.exerciseNames,
  });
}

class RoutineInput {
  final String name;
  final String? notes;
  final List<RoutineExerciseInput> exercises;

  const RoutineInput({
    required this.name,
    this.notes,
    this.exercises = const [],
  });
}

class RoutineExerciseInput {
  final String exerciseId;
  final int order;
  final int? targetRestSeconds;
  final List<RoutineSetInput> sets;

  const RoutineExerciseInput({
    required this.exerciseId,
    required this.order,
    this.targetRestSeconds,
    required this.sets,
  });
}

class RoutineSetInput {
  final SetType setType;
  final double? targetWeight;
  final int? targetReps;
  final int? targetDurationSeconds;
  final double? targetDistance;
  final double? targetRpe;

  const RoutineSetInput({
    required this.setType,
    this.targetWeight,
    this.targetReps,
    this.targetDurationSeconds,
    this.targetDistance,
    this.targetRpe,
  });
}

class ExerciseDetail {
  final Exercise exercise;
  final Muscle primaryMuscle;
  final List<Muscle> secondaryMuscles;
  final Equipment? equipment;
  final ExerciseStats? stats;

  const ExerciseDetail({
    required this.exercise,
    required this.primaryMuscle,
    required this.secondaryMuscles,
    this.equipment,
    this.stats,
  });
}

class ExerciseStats {
  final WorkoutSet? personalBest;
  final List<ExerciseHistoryEntry> recentHistory;
  final List<({DateTime date, double maxWeight})> weightOverTime;
  final List<({DateTime date, double volume})> volumeOverTime;
  final int totalSessions;

  const ExerciseStats({
    this.personalBest,
    required this.recentHistory,
    required this.weightOverTime,
    required this.volumeOverTime,
    required this.totalSessions,
  });
}

class ExerciseHistoryEntry {
  final String workoutId;
  final String workoutName;
  final DateTime performedAt;
  final List<WorkoutSet> sets;

  const ExerciseHistoryEntry({
    required this.workoutId,
    required this.workoutName,
    required this.performedAt,
    required this.sets,
  });
}
