import 'package:gym_tracker/common/utils/muscle_group_utils.dart';
import 'package:gym_tracker/core/models/routine_model.dart';
import 'package:gym_tracker/core/repositories/exercise_repository.dart';
import 'package:gym_tracker/core/repositories/repository_models.dart';
import 'package:gym_tracker/core/repositories/routine_repository.dart';
import 'package:gym_tracker/core/repositories/workout_repository.dart';

class DashboardService {
  final WorkoutRepository _workoutRepository;
  final RoutineRepository _routineRepository;
  final ExerciseRepository _exerciseRepository;

  DashboardService(
    this._workoutRepository,
    this._routineRepository,
    this._exerciseRepository,
  );

  Future<DashboardSummary> loadSummary() async {
    final now = DateTime.now();

    // Pre-fetch muscle lookup data — 2 queries, shared across all methods.
    final muscles = await _exerciseRepository.getMuscles();
    final muscleIdToName = {for (final m in muscles) m.id: m.name};
    final secondaryMap = await _exerciseRepository.getAllSecondaryMuscleIds();

    final history = await _workoutRepository.getWorkoutHistory(limit: 30);
    final routines = await _routineRepository.getRoutines();
    final thisWeek = _thisWeekDays(history, now);
    final streak = _streakDays(history, now);
    final lastWorkout = history.isNotEmpty ? history.first : null;
    final lastWorkoutTags = lastWorkout == null
        ? <String>[]
        : await _muscleTagsForWorkout(lastWorkout.id, muscleIdToName);
    final recentRecoveryHistory = history
        .where(
          (workout) => workout.startTime.isAfter(
            now.subtract(const Duration(hours: 96)),
          ),
        )
        .toList();
    final recovery = await _recovery(recentRecoveryHistory, now, muscleIdToName, secondaryMap);
    // Single query — replaces the 20-exercise getExerciseDetail loop.
    final recentPrs = await _recentPrs();
    final suggestion = await _suggestion(
      history: history,
      routines: routines,
      recovery: recovery,
      muscleIdToName: muscleIdToName,
    );

    return DashboardSummary(
      thisWeekTrainedDays: thisWeek,
      streakDays: streak,
      lastWorkout: lastWorkout,
      lastWorkoutMuscleTags: lastWorkoutTags,
      recentPrs: recentPrs,
      recovery: recovery,
      suggestedRoutine: suggestion,
    );
  }

  Future<List<String>> _muscleTagsForWorkout(
    String workoutId,
    Map<String, String> muscleIdToName,
  ) async {
    final tags = <String>{};
    final muscleRows = await _workoutRepository.getWorkoutMuscleGroups([workoutId]);
    for (final row in muscleRows) {
      final muscleName = muscleIdToName[row.primaryMuscleId];
      if (muscleName != null) {
        final group = MuscleGroupUtils.groupForMuscleName(muscleName);
        if (group != null) tags.add(group);
      }
    }
    return tags.take(4).toList();
  }

  List<bool> _thisWeekDays(List<WorkoutSummary> history, DateTime now) {
    final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final days = List<bool>.filled(7, false);
    for (final workout in history) {
      final workoutDay = DateTime(workout.startTime.year, workout.startTime.month, workout.startTime.day);
      final offset = workoutDay.difference(start).inDays;
      if (offset >= 0 && offset < 7) days[offset] = true;
    }
    return days;
  }

  int _streakDays(List<WorkoutSummary> history, DateTime now) {
    final trainedDays = {
      for (final workout in history)
        DateTime(workout.startTime.year, workout.startTime.month, workout.startTime.day).millisecondsSinceEpoch,
    };
    var cursor = DateTime(now.year, now.month, now.day);
    var streak = 0;
    while (trainedDays.contains(cursor.millisecondsSinceEpoch)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Future<List<MuscleRecoverySummary>> _recovery(
    List<WorkoutSummary> history,
    DateTime now,
    Map<String, String> muscleIdToName,
    Map<String, List<String>> secondaryMap,
  ) async {
    final lastTrainedByGroup = <String, DateTime>{};
    final workoutStartById = {
      for (final workout in history) workout.id: workout.startTime,
    };
    final muscleRows = await _workoutRepository.getWorkoutMuscleGroups(
      history.map((workout) => workout.id).toList(),
    );

    for (final row in muscleRows) {
      final workoutStartTime = workoutStartById[row.workoutId];
      if (workoutStartTime == null) continue;

      final groups = <String>{};
      final primaryName = muscleIdToName[row.primaryMuscleId];
      if (primaryName != null) {
        final g = MuscleGroupUtils.groupForMuscleName(primaryName);
        if (g != null) groups.add(g);
      }

      for (final muscleId in secondaryMap[row.exerciseId] ?? <String>[]) {
        final name = muscleIdToName[muscleId];
        if (name != null) {
          final g = MuscleGroupUtils.groupForMuscleName(name);
          if (g != null) groups.add(g);
        }
      }

      for (final group in groups) {
        final current = lastTrainedByGroup[group];
        if (current == null || workoutStartTime.isAfter(current)) {
          lastTrainedByGroup[group] = workoutStartTime;
        }
      }
    }

    return MuscleGroupUtils.groups.map((group) {
      final lastTrained = lastTrainedByGroup[group];
      return MuscleRecoverySummary(
        group: group,
        lastTrainedAt: lastTrained,
        status: MuscleGroupUtils.statusFor(lastTrained, now),
        sinceLabel: MuscleGroupUtils.sinceLabel(lastTrained, now),
      );
    }).toList();
  }

  Future<List<RecentPrSummary>> _recentPrs() async {
    final records = await _exerciseRepository.getTopPersonalRecords(limit: 3);
    return records
        .where((pr) => pr.weight != null)
        .map((pr) => RecentPrSummary(
              exerciseName: pr.exerciseName,
              weight: pr.weight!,
              reps: pr.reps,
              achievedAt: pr.achievedAt,
            ))
        .toList();
  }

  Future<SuggestedRoutineSummary?> _suggestion({
    required List<WorkoutSummary> history,
    required List<Routine> routines,
    required List<MuscleRecoverySummary> recovery,
    required Map<String, String> muscleIdToName,
  }) async {
    if (history.length < 3 || routines.length < 2) return null;
    final recoveryByGroup = {for (final item in recovery) item.group: item};

    SuggestedRoutineSummary? best;
    var bestScore = -1;
    for (final routine in routines) {
      final detail = await _routineRepository.getRoutineDetail(routine.id);
      final groups = <String>{};
      for (final routineExercise in detail.exercises) {
        // Primary muscle — resolved from ID, no getExerciseDetail call.
        final muscleName = muscleIdToName[routineExercise.exercise.primaryMuscleId];
        if (muscleName != null) {
          final group = MuscleGroupUtils.groupForMuscleName(muscleName);
          if (group != null) groups.add(group);
        }
      }
      final score = groups.fold<int>(
        0,
        (sum, group) => sum + (recoveryByGroup[group]?.status.score ?? 0),
      );
      if (score > bestScore) {
        bestScore = score;
        final readyGroups = groups.where((g) {
          final status = recoveryByGroup[g]?.status;
          return status == RecoveryStatus.ready || status == RecoveryStatus.fresh;
        }).toList();
        best = SuggestedRoutineSummary(
          routineId: detail.routine.id,
          name: detail.routine.name,
          notes: detail.routine.notes,
          reason: readyGroups.isEmpty
              ? '${detail.routine.name} is the best available routine'
              : '${detail.routine.name} - ${readyGroups.take(2).join(' and ')} are ready',
        );
      }
    }
    return best;
  }
}

class DashboardSummary {
  final List<bool> thisWeekTrainedDays;
  final int streakDays;
  final WorkoutSummary? lastWorkout;
  final List<String> lastWorkoutMuscleTags;
  final List<RecentPrSummary> recentPrs;
  final List<MuscleRecoverySummary> recovery;
  final SuggestedRoutineSummary? suggestedRoutine;

  const DashboardSummary({
    required this.thisWeekTrainedDays,
    required this.streakDays,
    required this.lastWorkout,
    required this.lastWorkoutMuscleTags,
    required this.recentPrs,
    required this.recovery,
    required this.suggestedRoutine,
  });
}

class MuscleRecoverySummary {
  final String group;
  final DateTime? lastTrainedAt;
  final RecoveryStatus status;
  final String sinceLabel;

  const MuscleRecoverySummary({
    required this.group,
    required this.lastTrainedAt,
    required this.status,
    required this.sinceLabel,
  });
}

class RecentPrSummary {
  final String exerciseName;
  final double weight;
  final int? reps;
  final DateTime? achievedAt;

  const RecentPrSummary({
    required this.exerciseName,
    required this.weight,
    required this.reps,
    required this.achievedAt,
  });
}

class SuggestedRoutineSummary {
  final String routineId;
  final String name;
  final String? notes;
  final String reason;

  const SuggestedRoutineSummary({
    required this.routineId,
    required this.name,
    this.notes,
    required this.reason,
  });
}
