import 'package:gym_tracker/common/utils/date_formatters.dart';
import 'package:gym_tracker/core/repositories/repository_models.dart';

/// First incomplete set in workout order (for "next" line + scheduled rest notification).
({String exerciseName, int setNumber})? nextIncompleteSet(WorkoutDetail detail) {
  final exercises = [...detail.exercises]..sort((a, b) => a.workoutExercise.order.compareTo(b.workoutExercise.order));
  for (final we in exercises) {
    final sets = [...we.sets]..sort((a, b) => a.order.compareTo(b.order));
    for (var i = 0; i < sets.length; i++) {
      if (!sets[i].isCompleted) {
        return (exerciseName: we.exercise.name, setNumber: i + 1);
      }
    }
  }
  return null;
}

/// Snapshot for "workout in progress" notification (current / first incomplete set).
WorkoutInProgressSnapshot? workoutInProgressSnapshot(WorkoutDetail detail, DateTime now) {
  final exercises = [...detail.exercises]..sort((a, b) => a.workoutExercise.order.compareTo(b.workoutExercise.order));
  for (final we in exercises) {
    final sets = [...we.sets]..sort((a, b) => a.order.compareTo(b.order));
    for (var i = 0; i < sets.length; i++) {
      if (!sets[i].isCompleted) {
        return WorkoutInProgressSnapshot(
          routineName: detail.workout.name,
          exerciseName: we.exercise.name,
          setNumber: i + 1,
          totalSets: sets.length,
          elapsed: DateFormatters.elapsed(now.difference(detail.workout.startTime)),
        );
      }
    }
  }
  if (exercises.isEmpty) return null;
  final we = exercises.last;
  final sets = [...we.sets]..sort((a, b) => a.order.compareTo(b.order));
  if (sets.isEmpty) return null;
  return WorkoutInProgressSnapshot(
    routineName: detail.workout.name,
    exerciseName: we.exercise.name,
    setNumber: sets.length,
    totalSets: sets.length,
    elapsed: DateFormatters.elapsed(now.difference(detail.workout.startTime)),
  );
}

/// The set that was just completed (by id), for notification after a check-in.
WorkoutInProgressSnapshot? completedSetSnapshot(
  WorkoutDetail detail,
  String workoutExerciseId,
  String completedSetId,
  DateTime now,
) {
  WorkoutExerciseDetail? we;
  for (final e in detail.exercises) {
    if (e.workoutExercise.id == workoutExerciseId) {
      we = e;
      break;
    }
  }
  if (we == null) return null;
  final sets = [...we.sets]..sort((a, b) => a.order.compareTo(b.order));
  final idx = sets.indexWhere((s) => s.id == completedSetId);
  if (idx < 0) return null;
  final set = sets[idx];
  if (!set.isCompleted) return null;
  return WorkoutInProgressSnapshot(
    routineName: detail.workout.name,
    exerciseName: we.exercise.name,
    setNumber: idx + 1,
    totalSets: sets.length,
    elapsed: DateFormatters.elapsed(now.difference(detail.workout.startTime)),
  );
}

class WorkoutInProgressSnapshot {
  final String routineName;
  final String exerciseName;
  final int setNumber;
  final int totalSets;
  final String elapsed;

  const WorkoutInProgressSnapshot({
    required this.routineName,
    required this.exerciseName,
    required this.setNumber,
    required this.totalSets,
    required this.elapsed,
  });
}
