import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  final RestTimerBloc _restTimerBloc;
  final ShellActiveWorkoutCubit _shellCubit;
  final NotificationService _notificationService;
  late final StreamSubscription<RestTimerState> _restTimerSubscription;
  String? _workoutId;
  String? _shownInitialProgressForWorkoutId;

  ActiveWorkoutCubit(
    this._workoutRepository,
    this._exerciseRepository,
    this._restTimerBloc,
    this._shellCubit,
    this._notificationService,
  ) : super(const ActiveWorkoutState()) {
    _restTimerSubscription = _restTimerBloc.stream.listen(_onRestTimerState);
  }

  String? get currentWorkoutId => _workoutId;

  Future<void> load(String workoutId) async {
    final sameWorkout = _workoutId == workoutId;
    if (!sameWorkout) {
      _shownInitialProgressForWorkoutId = null;
    }
    _workoutId = workoutId;
    final now = DateTime.now();
    final keepRest =
        sameWorkout &&
        state.restEndsAt != null &&
        state.restEndsAt!.isAfter(now);
    if (!keepRest) {
      _restTimerBloc.add(const CancelRestTimer());
    }
    emit(
      state.copyWith(
        isLoading: true,
        isFinishing: false,
        didFinish: false,
        clearError: true,
        clearRest: !keepRest,
      ),
    );
    await _refreshImmediate();
    final detail = state.detail;
    if (detail != null &&
        _workoutId != null &&
        _shownInitialProgressForWorkoutId != _workoutId) {
      final snap = workoutInProgressSnapshot(detail, DateTime.now());
      if (snap != null) {
        _shownInitialProgressForWorkoutId = _workoutId;
        unawaited(
          _notificationService.showWorkoutInProgress(
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
        _restTimerBloc.state is! RestTimerRunning) {
      final rem = state.restEndsAt!.difference(DateTime.now()).inSeconds;
      if (rem > 0) {
        final next = nextIncompleteSet(state.detail!);
        if (next != null) {
          _restTimerBloc.add(
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
    try {
      await _workoutRepository.addSet(workoutExerciseId: workoutExerciseId);
      await _refreshImmediate();
    } catch (error) {
      _emitMutationError(error);
    }
  }

  Future<void> moveExercise(String workoutExerciseId, int delta) async {
    try {
      final detail = state.detail;
      final workoutId = _workoutId;
      if (detail == null || workoutId == null) return;
      final exercises = [...detail.exercises]
        ..sort(
          (a, b) => a.workoutExercise.order.compareTo(b.workoutExercise.order),
        );
      final index = exercises.indexWhere(
        (item) => item.workoutExercise.id == workoutExerciseId,
      );
      final target = index + delta;
      if (index < 0 || target < 0 || target >= exercises.length) return;
      final ids = exercises.map((item) => item.workoutExercise.id).toList();
      final moved = ids.removeAt(index);
      ids.insert(target, moved);
      await _workoutRepository.reorderWorkoutExercises(
        workoutId: workoutId,
        orderedIds: ids,
      );
      await _refreshImmediate();
    } catch (error) {
      _emitMutationError(error);
    }
  }

  Future<void> removeExercise(String workoutExerciseId) async {
    try {
      final clearActiveRest =
          state.activeRestWorkoutExerciseId == workoutExerciseId;
      if (clearActiveRest) _restTimerBloc.add(const CancelRestTimer());
      await _workoutRepository.removeExerciseFromWorkout(workoutExerciseId);
      await _refreshImmediate(clearRest: clearActiveRest);
    } catch (error) {
      _emitMutationError(error);
    }
  }

  Future<void> addExercises(List<Exercise> exercises) async {
    try {
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
    } catch (error) {
      _emitMutationError(error);
    }
  }

  Future<void> updateSetValue(
    WorkoutSet set, {
    double? weight,
    int? reps,
    bool clearWeight = false,
    bool clearReps = false,
  }) async {
    try {
      final currentSet = _findSet(set.id) ?? set;
      final updated = WorkoutSet(
        id: currentSet.id,
        workoutExerciseId: currentSet.workoutExerciseId,
        setType: currentSet.setType,
        weight: clearWeight ? null : weight ?? currentSet.weight,
        reps: clearReps ? null : reps ?? currentSet.reps,
        durationSeconds: currentSet.durationSeconds,
        distance: currentSet.distance,
        rpe: currentSet.rpe,
        completedAt: currentSet.completedAt,
        order: currentSet.order,
        isCompleted: currentSet.isCompleted,
      );
      if (updated.isCompleted && !_hasValidWeightAndReps(updated)) {
        emit(state.copyWith(errorMessage: _setValidationMessage(updated)));
        return;
      }
      await _workoutRepository.updateSet(updated);
      await _refreshImmediate();
    } catch (error) {
      _emitMutationError(error);
    }
  }

  Future<void> updateSetType(WorkoutSet set, SetType setType) async {
    try {
      final currentSet = _findSet(set.id) ?? set;
      final updated = WorkoutSet(
        id: currentSet.id,
        workoutExerciseId: currentSet.workoutExerciseId,
        setType: setType,
        weight: currentSet.weight,
        reps: currentSet.reps,
        durationSeconds: currentSet.durationSeconds,
        distance: currentSet.distance,
        rpe: currentSet.rpe,
        completedAt: currentSet.completedAt,
        order: currentSet.order,
        isCompleted: currentSet.isCompleted,
      );
      await _workoutRepository.updateSet(updated);
      await _refreshImmediate();
    } catch (error) {
      _emitMutationError(error);
    }
  }

  Future<void> removeSet(WorkoutSet set) async {
    try {
      final clearActiveRest =
          state.activeRestWorkoutExerciseId == set.workoutExerciseId;
      if (clearActiveRest) _restTimerBloc.add(const CancelRestTimer());
      await _workoutRepository.removeSet(set.id);
      await _refreshImmediate(clearRest: clearActiveRest);
    } catch (error) {
      _emitMutationError(error);
    }
  }

  Future<void> toggleSet(WorkoutSet set) async {
    try {
      final currentSet = _findSet(set.id) ?? set;
      if (currentSet.isCompleted) {
        _restTimerBloc.add(const CancelRestTimer());
        await _workoutRepository.uncompleteSet(currentSet.id);
        final clearActiveRest =
            state.activeRestWorkoutExerciseId == currentSet.workoutExerciseId;
        await _refreshImmediate(clearRest: clearActiveRest);
        return;
      }

      if (!_hasValidWeightAndReps(currentSet)) {
        emit(state.copyWith(errorMessage: _setValidationMessage(currentSet)));
        return;
      }

      await _workoutRepository.completeSet(currentSet.id);
      final matchingExercises = state.detail?.exercises.where(
        (item) => item.workoutExercise.id == currentSet.workoutExerciseId,
      );
      final exercise = matchingExercises == null || matchingExercises.isEmpty
          ? null
          : matchingExercises.first;
      final restSeconds = exercise?.workoutExercise.restSeconds ?? 90;

      await _refreshImmediate(clearRest: true);

      final detail = state.detail;
      final workoutId = _workoutId;
      if (detail == null || workoutId == null) return;

      final now = DateTime.now();
      final completedSnap = completedSetSnapshot(
        detail,
        currentSet.workoutExerciseId,
        currentSet.id,
        now,
      );
      final next = nextIncompleteSet(detail);

      if (completedSnap != null) {
        unawaited(
          _notificationService.showWorkoutInProgress(
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

      _restTimerBloc.add(
        StartRestTimer(
          workoutId: workoutId,
          workoutExerciseId: currentSet.workoutExerciseId,
          totalSeconds: restSeconds,
          nextExercise: next.exerciseName,
          nextSet: next.setNumber,
        ),
      );
    } on StateError {
      final currentSet = _findSet(set.id) ?? set;
      emit(state.copyWith(errorMessage: _setValidationMessage(currentSet)));
    } catch (error) {
      _emitMutationError(error);
    }
  }

  Future<void> finish() async {
    final id = _workoutId;
    if (id == null) return;
    try {
      final guardError = _finishGuardError();
      if (guardError != null) {
        // Re-emit even when message is unchanged so UI snackbar shows every tap.
        emit(state.copyWith(clearError: true));
        emit(state.copyWith(errorMessage: guardError));
        return;
      }
      final invalidCompletedSet = _firstInvalidCompletedSet();
      if (invalidCompletedSet != null) {
        emit(state.copyWith(clearError: true));
        emit(
          state.copyWith(
            errorMessage: _setValidationMessage(invalidCompletedSet),
          ),
        );
        return;
      }
      _restTimerBloc.add(const CancelRestTimer());
      await _notificationService.cancelAllWorkoutNotifications();
      _shownInitialProgressForWorkoutId = null;
      emit(state.copyWith(isFinishing: true, clearError: true));
      await _workoutRepository.completeWorkout(id);
    } on StateError catch (error) {
      emit(state.copyWith(isFinishing: false, errorMessage: error.message));
      return;
    } catch (error) {
      _emitMutationError(error);
      return;
    }
    emit(state.copyWith(isFinishing: false, didFinish: true));
  }

  Future<void> cancel() async {
    final id = _workoutId;
    if (id == null) return;
    try {
      _restTimerBloc.add(const CancelRestTimer());
      await _notificationService.cancelAllWorkoutNotifications();
      _shownInitialProgressForWorkoutId = null;
      await _workoutRepository.cancelWorkout(id);
    } catch (error) {
      _emitMutationError(error);
    }
  }

  void addRestSeconds(int seconds) {
    if (seconds <= 0) return;
    _restTimerBloc.add(AdjustRestTimer(seconds));
  }

  void subtractRestSeconds(int seconds) {
    if (seconds <= 0) return;
    _restTimerBloc.add(AdjustRestTimer(-seconds));
  }

  void skipRest() {
    _restTimerBloc.add(const SkipRestTimer());
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
    unawaited(_shellCubit.onSkippedRestAfterCompletion(baseline));
    _syncShellRest();
  }

  void completeRestTimerNaturally() {
    final baseline = _latestCompletedAt(state.detail);
    emit(state.copyWith(clearRest: true));
    unawaited(_shellCubit.onSkippedRestAfterCompletion(baseline));
    _syncShellRest();
  }

  void clearRestFromTimerWithoutSkip() {
    emit(state.copyWith(clearRest: true));
    _shellCubit.clearRestOverride();
    unawaited(_shellCubit.refreshNow());
    _syncShellRest();
  }

  void _onRestTimerState(RestTimerState timerState) {
    if (timerState is RestTimerRunning) {
      final alreadySynced =
          state.restEndsAt == timerState.restEndsAt &&
          state.activeRestWorkoutExerciseId == timerState.workoutExerciseId;
      if (!alreadySynced) {
        applyRestFromTimer(timerState.restEndsAt, timerState.workoutExerciseId);
      }
      return;
    }

    if (timerState is RestTimerFinished) {
      if (timerState.reason == RestTimerFinishReason.skipped) {
        completeRestTimerSkipped();
      } else {
        completeRestTimerNaturally();
      }
      return;
    }

    if (timerState is RestTimerCancelled) {
      clearRestFromTimerWithoutSkip();
    }
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
      final previous = await _exerciseRepository.getPreviousSetLabels(
        detail.exercises
            .map((workoutExercise) => workoutExercise.exercise.id)
            .toSet()
            .toList(),
      );
      emit(
        state.copyWith(
          isLoading: false,
          detail: detail,
          previousByExerciseId: previous,
          restEndsAt: restEndsAt,
          activeRestWorkoutExerciseId: activeRestWorkoutExerciseId,
          clearError: true,
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

  WorkoutSet? _findSet(String setId) {
    final detail = state.detail;
    if (detail == null) return null;
    for (final exercise in detail.exercises) {
      for (final set in exercise.sets) {
        if (set.id == setId) return set;
      }
    }
    return null;
  }

  WorkoutSet? _firstInvalidCompletedSet() {
    final detail = state.detail;
    if (detail == null) return null;
    for (final exercise in detail.exercises) {
      for (final set in exercise.sets) {
        if (set.isCompleted && !_hasValidWeightAndReps(set)) {
          return set;
        }
      }
    }
    return null;
  }

  String? _finishGuardError() {
    final detail = state.detail;
    if (detail == null) return 'Workout data is not ready yet.';

    if (detail.exercises.isEmpty) {
      return 'Workout cannot be saved without exercises.';
    }

    final completedSets = detail.exercises
        .expand((exercise) => exercise.sets)
        .where((set) => set.isCompleted)
        .toList();
    if (completedSets.isEmpty) {
      return 'Workout cannot be saved without any completed sets.';
    }

    final totalCompletedReps = completedSets.fold<int>(
      0,
      (sum, set) => sum + (set.reps ?? 0),
    );
    if (totalCompletedReps <= 0) {
      return 'Workout cannot be saved without any completed reps.';
    }

    final elapsedSeconds =
        DateTime.now().difference(detail.workout.startTime).inMilliseconds /
        1000.0;
    final minimumRequiredSeconds = totalCompletedReps * 0.5;
    if (elapsedSeconds < minimumRequiredSeconds) {
      return 'Workout duration is too short for completed reps. Minimum ${minimumRequiredSeconds.toStringAsFixed(0)}s required.';
    }

    return null;
  }

  String _setValidationMessage(WorkoutSet targetSet) {
    final detail = state.detail;
    if (detail == null) {
      return 'Set needs weight and reps greater than 0';
    }
    for (final exercise in detail.exercises) {
      final sets = [...exercise.sets]
        ..sort((a, b) => a.order.compareTo(b.order));
      final setIndex = sets.indexWhere((set) => set.id == targetSet.id);
      if (setIndex >= 0) {
        return '${exercise.exercise.name} set ${setIndex + 1} needs weight and reps greater than 0';
      }
    }
    return 'Set needs weight and reps greater than 0';
  }

  static bool _hasValidWeightAndReps(WorkoutSet set) {
    final weight = set.weight;
    final reps = set.reps;
    return weight != null && weight > 0 && reps != null && reps > 0;
  }

  void _emitMutationError(Object error) {
    emit(
      state.copyWith(isFinishing: false, errorMessage: _errorMessage(error)),
    );
  }

  static String _errorMessage(Object error) {
    if (error is StateError) {
      return error.message;
    }
    return error.toString();
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
    final ends = state.restEndsAt;
    final label = _resolveRestExerciseName();
    if (ends != null && ends.isAfter(DateTime.now())) {
      _shellCubit.syncRestOverride(ends, label ?? '');
      return;
    }
    _shellCubit.clearRestOverride();
  }

  @override
  Future<void> close() async {
    await _restTimerSubscription.cancel();
    return super.close();
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
      activeRestWorkoutExerciseId: clearRest
          ? null
          : activeRestWorkoutExerciseId ?? this.activeRestWorkoutExerciseId,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  int get completedSets {
    final items =
        detail?.exercises.expand((exercise) => exercise.sets) ??
        const Iterable<WorkoutSet>.empty();
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
