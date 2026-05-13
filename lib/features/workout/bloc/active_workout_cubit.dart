import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_tracker/common/utils/getit_utils.dart';
import 'package:gym_tracker/core/enums/set_type_enum.dart';
import 'package:gym_tracker/core/models/exercise_model.dart';
import 'package:gym_tracker/core/models/workout_set_model.dart';
import 'package:gym_tracker/core/repositories/exercise_repository.dart';
import 'package:gym_tracker/core/repositories/repository_models.dart';
import 'package:gym_tracker/core/repositories/workout_repository.dart';
import 'package:gym_tracker/core/services/notification_service.dart';
import 'package:gym_tracker/features/shell/bloc/shell_active_workout_cubit.dart';
import 'package:gym_tracker/features/workout/bloc/rest_timer_bloc.dart';
import 'package:gym_tracker/features/workout/helpers/workout_log_notifications.dart';
import 'package:injectable/injectable.dart';

@LazySingleton()
class ActiveWorkoutCubit extends Cubit<ActiveWorkoutState> {
  final WorkoutRepository _workoutRepository;
  final ExerciseRepository _exerciseRepository;
  String? _workoutId;
  String? _shownInitialProgressForWorkoutId;

  ActiveWorkoutCubit(this._workoutRepository, this._exerciseRepository) : super(const ActiveWorkoutState());

  String? get currentWorkoutId => _workoutId;

  Future<void> load(String workoutId) async {
    final sameWorkout = _workoutId == workoutId;
    if (!sameWorkout) {
      _shownInitialProgressForWorkoutId = null;
    }
    _workoutId = workoutId;
    final now = DateTime.now();
    final keepRest = sameWorkout && state.restEndsAt != null && state.restEndsAt!.isAfter(now);
    if (!keepRest) {
      getIt<RestTimerBloc>().add(const CancelRestTimer());
    }
    emit(state.copyWith(isLoading: true, isFinishing: false, didFinish: false, clearError: true, clearRest: !keepRest));
    await _refreshImmediate();
    final detail = state.detail;
    if (detail != null &&
        _workoutId != null &&
        _shownInitialProgressForWorkoutId != _workoutId &&
        getIt.isRegistered<NotificationService>()) {
      final snap = workoutInProgressSnapshot(detail, DateTime.now());
      if (snap != null) {
        _shownInitialProgressForWorkoutId = _workoutId;
        unawaited(
          getIt<NotificationService>().showWorkoutInProgress(
            workoutId: _workoutId!,
            routineName: snap.routineName,
            exerciseName: snap.exerciseName,
            setNumber: snap.setNumber,
            totalSets: snap.totalSets,
            elapsed: snap.elapsed,
          ),
        );
      }
    }

    if (keepRest &&
        state.restEndsAt != null &&
        state.activeRestWorkoutExerciseId != null &&
        state.detail != null &&
        getIt.isRegistered<RestTimerBloc>() &&
        getIt<RestTimerBloc>().state is! RestTimerRunning) {
      final rem = state.restEndsAt!.difference(DateTime.now()).inSeconds;
      if (rem > 0) {
        final next = nextIncompleteSet(state.detail!);
        if (next != null) {
          getIt<RestTimerBloc>().add(
            StartRestTimer(
              workoutId: _workoutId!,
              workoutExerciseId: state.activeRestWorkoutExerciseId!,
              totalSeconds: rem,
              nextExercise: next.exerciseName,
              nextSet: next.setNumber,
            ),
          );
        }
      }
    }
  }

  Future<void> addSet(String workoutExerciseId) async {
    await _workoutRepository.addSet(workoutExerciseId: workoutExerciseId);
    await _refreshImmediate();
  }

  Future<void> moveExercise(String workoutExerciseId, int delta) async {
    final detail = state.detail;
    final workoutId = _workoutId;
    if (detail == null || workoutId == null) return;
    final exercises = [...detail.exercises]..sort((a, b) => a.workoutExercise.order.compareTo(b.workoutExercise.order));
    final index = exercises.indexWhere((item) => item.workoutExercise.id == workoutExerciseId);
    final target = index + delta;
    if (index < 0 || target < 0 || target >= exercises.length) return;
    final ids = exercises.map((item) => item.workoutExercise.id).toList();
    final moved = ids.removeAt(index);
    ids.insert(target, moved);
    await _workoutRepository.reorderWorkoutExercises(workoutId: workoutId, orderedIds: ids);
    await _refreshImmediate();
  }

  Future<void> removeExercise(String workoutExerciseId) async {
    final clearActiveRest = state.activeRestWorkoutExerciseId == workoutExerciseId;
    if (clearActiveRest) getIt<RestTimerBloc>().add(const CancelRestTimer());
    await _workoutRepository.removeExerciseFromWorkout(workoutExerciseId);
    await _refreshImmediate(clearRest: clearActiveRest);
  }

  Future<void> addExercises(List<Exercise> exercises) async {
    final id = _workoutId;
    if (id == null) return;
    for (final exercise in exercises) {
      final workoutExercise = await _workoutRepository.addExerciseToWorkout(
        workoutId: id,
        exerciseId: exercise.id,
        restSeconds: 90,
      );
      await _workoutRepository.addSet(workoutExerciseId: workoutExercise.id);
    }
    await _refreshImmediate();
  }

  Future<void> updateSetValue(
    WorkoutSet set, {
    double? weight,
    int? reps,
    bool clearWeight = false,
    bool clearReps = false,
  }) async {
    final updated = WorkoutSet(
      id: set.id,
      workoutExerciseId: set.workoutExerciseId,
      setType: set.setType,
      weight: clearWeight ? null : weight ?? set.weight,
      reps: clearReps ? null : reps ?? set.reps,
      durationSeconds: set.durationSeconds,
      distance: set.distance,
      rpe: set.rpe,
      completedAt: set.completedAt,
      order: set.order,
      isCompleted: set.isCompleted,
    );
    await _workoutRepository.updateSet(updated);
    await _refreshImmediate();
  }

  Future<void> updateSetType(WorkoutSet set, SetType setType) async {
    final updated = WorkoutSet(
      id: set.id,
      workoutExerciseId: set.workoutExerciseId,
      setType: setType,
      weight: set.weight,
      reps: set.reps,
      durationSeconds: set.durationSeconds,
      distance: set.distance,
      rpe: set.rpe,
      completedAt: set.completedAt,
      order: set.order,
      isCompleted: set.isCompleted,
    );
    await _workoutRepository.updateSet(updated);
    await _refreshImmediate();
  }

  Future<void> removeSet(WorkoutSet set) async {
    final clearActiveRest = state.activeRestWorkoutExerciseId == set.workoutExerciseId;
    if (clearActiveRest) getIt<RestTimerBloc>().add(const CancelRestTimer());
    await _workoutRepository.removeSet(set.id);
    await _refreshImmediate(clearRest: clearActiveRest);
  }

  Future<void> toggleSet(WorkoutSet set) async {
    if (set.isCompleted) {
      getIt<RestTimerBloc>().add(const CancelRestTimer());
      await _workoutRepository.uncompleteSet(set.id);
      await _refreshImmediate(clearRest: state.activeRestWorkoutExerciseId == set.workoutExerciseId);
      return;
    }

    await _workoutRepository.completeSet(set.id);
    final matchingExercises = state.detail?.exercises.where(
      (item) => item.workoutExercise.id == set.workoutExerciseId,
    );
    final exercise = matchingExercises == null || matchingExercises.isEmpty ? null : matchingExercises.first;
    final restSeconds = exercise?.workoutExercise.restSeconds ?? 90;

    await _refreshImmediate(clearRest: true);

    final detail = state.detail;
    final workoutId = _workoutId;
    if (detail == null || workoutId == null) return;

    final now = DateTime.now();
    final completedSnap = completedSetSnapshot(detail, set.workoutExerciseId, set.id, now);
    final next = nextIncompleteSet(detail);

    if (completedSnap != null && getIt.isRegistered<NotificationService>()) {
      unawaited(
        getIt<NotificationService>().showWorkoutInProgress(
          workoutId: workoutId,
          routineName: completedSnap.routineName,
          exerciseName: completedSnap.exerciseName,
          setNumber: completedSnap.setNumber,
          totalSets: completedSnap.totalSets,
          elapsed: completedSnap.elapsed,
        ),
      );
    }

    if (restSeconds <= 0 || next == null) {
      return;
    }

    getIt<RestTimerBloc>().add(
      StartRestTimer(
        workoutId: workoutId,
        workoutExerciseId: set.workoutExerciseId,
        totalSeconds: restSeconds,
        nextExercise: next.exerciseName,
        nextSet: next.setNumber,
      ),
    );
  }

  Future<void> finish() async {
    final id = _workoutId;
    if (id == null) return;
    getIt<RestTimerBloc>().add(const CancelRestTimer());
    if (getIt.isRegistered<NotificationService>()) {
      await getIt<NotificationService>().cancelAllWorkoutNotifications();
    }
    _shownInitialProgressForWorkoutId = null;
    emit(state.copyWith(isFinishing: true));
    await _workoutRepository.completeWorkout(id);
    emit(state.copyWith(isFinishing: false, didFinish: true));
  }

  Future<void> cancel() async {
    final id = _workoutId;
    if (id == null) return;
    getIt<RestTimerBloc>().add(const CancelRestTimer());
    if (getIt.isRegistered<NotificationService>()) {
      await getIt<NotificationService>().cancelAllWorkoutNotifications();
    }
    _shownInitialProgressForWorkoutId = null;
    await _workoutRepository.cancelWorkout(id);
  }

  void addRestSeconds(int seconds) {
    if (seconds <= 0) return;
    getIt<RestTimerBloc>().add(AdjustRestTimer(seconds));
  }

  void subtractRestSeconds(int seconds) {
    if (seconds <= 0) return;
    getIt<RestTimerBloc>().add(AdjustRestTimer(-seconds));
  }

  void skipRest() {
    getIt<RestTimerBloc>().add(const SkipRestTimer());
  }

  void applyRestFromTimer(DateTime restEndsAt, String workoutExerciseId) {
    emit(
      state.copyWith(
        restEndsAt: restEndsAt,
        activeRestWorkoutExerciseId: workoutExerciseId,
        clearRest: false,
      ),
    );
    _syncShellRest();
  }

  void completeRestTimerSkipped() {
    final baseline = _latestCompletedAt(state.detail);
    emit(state.copyWith(clearRest: true));
    unawaited(getIt<ShellActiveWorkoutCubit>().onSkippedRestAfterCompletion(baseline));
    _syncShellRest();
  }

  void completeRestTimerNaturally() {
    final baseline = _latestCompletedAt(state.detail);
    emit(state.copyWith(clearRest: true));
    unawaited(getIt<ShellActiveWorkoutCubit>().onSkippedRestAfterCompletion(baseline));
    _syncShellRest();
  }

  void clearRestFromTimerWithoutSkip() {
    emit(state.copyWith(clearRest: true));
    getIt<ShellActiveWorkoutCubit>().clearRestOverride();
    unawaited(getIt<ShellActiveWorkoutCubit>().refreshNow());
    _syncShellRest();
  }

  Future<void> _refreshImmediate({
    DateTime? restEndsAt,
    String? activeRestWorkoutExerciseId,
    bool clearRest = false,
  }) async {
    await _refresh(
      restEndsAt: restEndsAt,
      activeRestWorkoutExerciseId: activeRestWorkoutExerciseId,
      clearRest: clearRest,
    );
  }

  Future<void> _refresh({
    DateTime? restEndsAt,
    String? activeRestWorkoutExerciseId,
    bool clearRest = false,
  }) async {
    final id = _workoutId;
    if (id == null) return;
    try {
      final detail = await _workoutRepository.getWorkoutDetail(id);
      final previous = <String, String>{};
      final previousPairs = await Future.wait(
        detail.exercises.map((workoutExercise) async {
          final exerciseDetail = await _exerciseRepository.getExerciseDetail(workoutExercise.exercise.id);
          final recent = exerciseDetail.stats?.recentHistory.isNotEmpty == true ? exerciseDetail.stats!.recentHistory.first : null;
          final firstSet = recent?.sets.isNotEmpty == true ? recent!.sets.first : null;
          final label = firstSet == null
              ? '-'
              : '${firstSet.weight?.toStringAsFixed(1) ?? '-'} kg x ${firstSet.reps ?? '-'}';
          return MapEntry(workoutExercise.exercise.id, label);
        }),
      );
      for (final entry in previousPairs) {
        previous[entry.key] = entry.value;
      }
      emit(
        state.copyWith(
          isLoading: false,
          detail: detail,
          previousByExerciseId: previous,
          restEndsAt: restEndsAt,
          activeRestWorkoutExerciseId: activeRestWorkoutExerciseId,
          clearRest: clearRest,
        ),
      );
      _syncShellRest();
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: error.toString()));
    }
  }

  static DateTime? _latestCompletedAt(WorkoutDetail? detail) {
    if (detail == null) return null;
    DateTime? latest;
    for (final exercise in detail.exercises) {
      for (final set in exercise.sets) {
        final at = set.completedAt;
        if (at != null && (latest == null || at.isAfter(latest))) {
          latest = at;
        }
      }
    }
    return latest;
  }

  String? _resolveRestExerciseName() {
    final id = state.activeRestWorkoutExerciseId;
    final detail = state.detail;
    if (id == null || detail == null) return null;
    for (final exercise in detail.exercises) {
      if (exercise.workoutExercise.id == id) {
        return exercise.exercise.name;
      }
    }
    return null;
  }

  void _syncShellRest() {
    final shell = getIt<ShellActiveWorkoutCubit>();
    final ends = state.restEndsAt;
    final label = _resolveRestExerciseName();
    if (ends != null && ends.isAfter(DateTime.now())) {
      shell.syncRestOverride(ends, label ?? '');
      return;
    }
    shell.clearRestOverride();
  }
}

class ActiveWorkoutState extends Equatable {
  final bool isLoading;
  final bool isFinishing;
  final bool didFinish;
  final WorkoutDetail? detail;
  final Map<String, String> previousByExerciseId;
  final DateTime? restEndsAt;
  final String? activeRestWorkoutExerciseId;
  final String? errorMessage;

  const ActiveWorkoutState({
    this.isLoading = false,
    this.isFinishing = false,
    this.didFinish = false,
    this.detail,
    this.previousByExerciseId = const {},
    this.restEndsAt,
    this.activeRestWorkoutExerciseId,
    this.errorMessage,
  });

  ActiveWorkoutState copyWith({
    bool? isLoading,
    bool? isFinishing,
    bool? didFinish,
    WorkoutDetail? detail,
    Map<String, String>? previousByExerciseId,
    DateTime? restEndsAt,
    String? activeRestWorkoutExerciseId,
    String? errorMessage,
    bool clearError = false,
    bool clearRest = false,
  }) {
    return ActiveWorkoutState(
      isLoading: isLoading ?? this.isLoading,
      isFinishing: isFinishing ?? this.isFinishing,
      didFinish: didFinish ?? this.didFinish,
      detail: detail ?? this.detail,
      previousByExerciseId: previousByExerciseId ?? this.previousByExerciseId,
      restEndsAt: clearRest ? null : restEndsAt ?? this.restEndsAt,
      activeRestWorkoutExerciseId: clearRest ? null : activeRestWorkoutExerciseId ?? this.activeRestWorkoutExerciseId,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  int get completedSets {
    final items = detail?.exercises.expand((exercise) => exercise.sets) ?? const Iterable<WorkoutSet>.empty();
    return items.where((set) => set.isCompleted).length;
  }

  @override
  List<Object?> get props => [
        isLoading,
        isFinishing,
        didFinish,
        detail,
        previousByExerciseId,
        restEndsAt,
        activeRestWorkoutExerciseId,
        errorMessage,
      ];
}
