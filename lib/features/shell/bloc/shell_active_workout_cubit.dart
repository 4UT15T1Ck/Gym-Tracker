import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_tracker/core/repositories/repository_models.dart';
import 'package:gym_tracker/core/repositories/workout_repository.dart';
import 'package:gym_tracker/core/services/notification_service.dart';
import 'package:gym_tracker/features/workout/bloc/rest_timer_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

@lazySingleton
class ShellActiveWorkoutCubit extends Cubit<ShellActiveWorkoutState> {
  final WorkoutRepository _workoutRepository;
  final RestTimerBloc _restTimerBloc;
  final NotificationService _notificationService;
  StreamSubscription<WorkoutDetail?>? _activeWorkoutSubscription;
  Timer? _elapsedTicker;

  /// From Log Workout (+15 / −15): overrides DB-derived rest until expiry.
  DateTime? _restOverrideEndsAt;
  String? _restOverrideExerciseName;

  /// After Skip on log screen: hide rest until the user completes another set.
  DateTime? _skippedRestAfterCompletedAt;

  ShellActiveWorkoutCubit(
    this._workoutRepository,
    this._restTimerBloc,
    this._notificationService,
  ) : super(ShellActiveWorkoutState.initial());

  Future<void> load() async {
    _activeWorkoutSubscription ??= _workoutRepository.activeWorkoutChanges
        .skip(1)
        .distinct()
        .debounceTime(const Duration(milliseconds: 50))
        .listen(_applyActiveWorkout);
    await refreshNow();
  }

  Future<void> refreshNow() async {
    final active = await _workoutRepository.getActiveWorkout();
    _applyActiveWorkout(active);
  }

  Future<void> discardActiveWorkout() async {
    final detail = state.detail;
    if (detail == null) return;
    _clearRestSessionOverrides();
    _restTimerBloc.add(const CancelRestTimer());
    await _notificationService.cancelAllWorkoutNotifications();
    await _workoutRepository.cancelWorkout(detail.workout.id);
    _applyActiveWorkout(null);
  }

  /// Keeps FAB aligned with [ActiveWorkoutCubit] rest timer (+15 / −15 / new rest after a set).
  void syncRestOverride(DateTime endsAt, String exerciseName) {
    _restOverrideEndsAt = endsAt;
    _restOverrideExerciseName = exerciseName;
    emit(
      state.copyWith(
        now: DateTime.now(),
        restEndsAt: endsAt,
        clearRest: false,
        currentExerciseName: exerciseName,
      ),
    );
  }

  void clearRestOverride() {
    _restOverrideEndsAt = null;
    _restOverrideExerciseName = null;
  }

  Future<void> onSkippedRestAfterCompletion(DateTime? latestCompletedAt) async {
    clearRestOverride();
    _skippedRestAfterCompletedAt = latestCompletedAt;
    await refreshNow();
  }

  void _clearRestSessionOverrides() {
    clearRestOverride();
    _skippedRestAfterCompletedAt = null;
  }

  void _startElapsedTicker() {
    _elapsedTicker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      _applyActiveWorkout(state.detail, now: DateTime.now());
    });
  }

  void _stopElapsedTicker() {
    _elapsedTicker?.cancel();
    _elapsedTicker = null;
  }

  void _applyActiveWorkout(WorkoutDetail? active, {DateTime? now}) {
    final clockNow = now ?? DateTime.now();
    if (active == null) {
      _clearRestSessionOverrides();
      _stopElapsedTicker();
      emit(ShellActiveWorkoutState.initial(now: clockNow));
      return;
    }

    _startElapsedTicker();
    final tLatest = _maxCompletedAt(active);

    if (_restOverrideEndsAt != null && !_restOverrideEndsAt!.isAfter(clockNow)) {
      clearRestOverride();
      _skippedRestAfterCompletedAt = tLatest;
    }

    if (_skippedRestAfterCompletedAt != null &&
        tLatest != null &&
        !_sameCompletionInstant(tLatest, _skippedRestAfterCompletedAt!)) {
      _skippedRestAfterCompletedAt = null;
    }

    final computed = _latestRestInfo(active, clockNow);

    final DateTime? effectiveRestEnd;
    final String exerciseName;

    if (_restOverrideEndsAt != null && _restOverrideEndsAt!.isAfter(clockNow)) {
      effectiveRestEnd = _restOverrideEndsAt;
      exerciseName =
          _nonEmptyOr(_restOverrideExerciseName, computed?.exerciseName) ?? _resolveCurrentExerciseName(active);
    } else if (_skippedRestAfterCompletedAt != null &&
        tLatest != null &&
        _sameCompletionInstant(tLatest, _skippedRestAfterCompletedAt!)) {
      effectiveRestEnd = null;
      exerciseName = _resolveCurrentExerciseName(active);
    } else {
      effectiveRestEnd = computed?.restEndsAt;
      exerciseName = computed?.exerciseName ?? _resolveCurrentExerciseName(active);
    }

    emit(
      ShellActiveWorkoutState(
        detail: active,
        now: clockNow,
        restEndsAt: effectiveRestEnd,
        currentExerciseName: exerciseName,
      ),
    );
  }

  static bool _sameCompletionInstant(DateTime a, DateTime b) => (a.difference(b).inMilliseconds).abs() < 750;

  static String? _nonEmptyOr(String? a, String? b) {
    if (a != null && a.trim().isNotEmpty) return a;
    return b;
  }

  static DateTime? _maxCompletedAt(WorkoutDetail detail) {
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

  ({DateTime restEndsAt, String exerciseName})? _latestRestInfo(WorkoutDetail detail, DateTime now) {
    DateTime? latestCompletedAt;
    WorkoutExerciseDetail? latestExercise;

    for (final exercise in detail.exercises) {
      for (final set in exercise.sets) {
        final completedAt = set.completedAt;
        if (completedAt == null) continue;
        if (latestCompletedAt == null || completedAt.isAfter(latestCompletedAt)) {
          latestCompletedAt = completedAt;
          latestExercise = exercise;
        }
      }
    }

    if (latestCompletedAt == null || latestExercise == null) return null;
    final restSeconds = latestExercise.workoutExercise.restSeconds ?? 90;
    final restEndsAt = latestCompletedAt.add(Duration(seconds: restSeconds));
    if (!restEndsAt.isAfter(now)) return null;

    return (restEndsAt: restEndsAt, exerciseName: latestExercise.exercise.name);
  }

  String _resolveCurrentExerciseName(WorkoutDetail detail) {
    if (detail.exercises.isEmpty) return 'No exercise yet';
    for (final exercise in detail.exercises) {
      final hasIncompleteSet = exercise.sets.any((set) => !set.isCompleted);
      if (hasIncompleteSet || exercise.sets.isEmpty) {
        return exercise.exercise.name;
      }
    }
    return detail.exercises.last.exercise.name;
  }

  @override
  Future<void> close() async {
    await _activeWorkoutSubscription?.cancel();
    _stopElapsedTicker();
    return super.close();
  }
}

class ShellActiveWorkoutState extends Equatable {
  final WorkoutDetail? detail;
  final DateTime now;
  final DateTime? restEndsAt;
  final String currentExerciseName;

  const ShellActiveWorkoutState({
    required this.detail,
    required this.now,
    required this.restEndsAt,
    required this.currentExerciseName,
  });

  factory ShellActiveWorkoutState.initial({DateTime? now}) => ShellActiveWorkoutState(
        detail: null,
        now: now ?? DateTime.now(),
        restEndsAt: null,
        currentExerciseName: '',
      );

  bool get hasActiveWorkout => detail != null;

  String get workoutId => detail!.workout.id;

  bool get isResting => restEndsAt != null;

  Duration get elapsed => now.difference(detail!.workout.startTime);

  Duration get restRemaining {
    final end = restEndsAt;
    if (end == null) return Duration.zero;
    final diff = end.difference(now);
    return diff.isNegative ? Duration.zero : diff;
  }

  ShellActiveWorkoutState copyWith({
    WorkoutDetail? detail,
    DateTime? now,
    DateTime? restEndsAt,
    bool clearRest = false,
    String? currentExerciseName,
  }) {
    return ShellActiveWorkoutState(
      detail: detail ?? this.detail,
      now: now ?? this.now,
      restEndsAt: clearRest ? null : restEndsAt ?? this.restEndsAt,
      currentExerciseName: currentExerciseName ?? this.currentExerciseName,
    );
  }

  @override
  List<Object?> get props => [detail, now, restEndsAt, currentExerciseName];
}
