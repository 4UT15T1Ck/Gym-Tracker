import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_tracker/core/services/notification_service.dart';
import 'package:injectable/injectable.dart';
import 'package:vibration/vibration.dart';

// --- Events ---

abstract class RestTimerEvent extends Equatable {
  const RestTimerEvent();

  @override
  List<Object?> get props => [];
}

class StartRestTimer extends RestTimerEvent {
  final String workoutId;
  final String workoutExerciseId;
  final int totalSeconds;
  final String nextExercise;
  final int nextSet;

  const StartRestTimer({
    required this.workoutId,
    required this.workoutExerciseId,
    required this.totalSeconds,
    required this.nextExercise,
    required this.nextSet,
  });

  @override
  List<Object?> get props => [
        workoutId,
        workoutExerciseId,
        totalSeconds,
        nextExercise,
        nextSet,
      ];
}

class TickRestTimer extends RestTimerEvent {
  const TickRestTimer();
}

class SkipRestTimer extends RestTimerEvent {
  const SkipRestTimer();
}

class AdjustRestTimer extends RestTimerEvent {
  final int deltaSeconds;

  const AdjustRestTimer(this.deltaSeconds);

  @override
  List<Object?> get props => [deltaSeconds];
}

class CancelRestTimer extends RestTimerEvent {
  const CancelRestTimer();
}

// --- States ---

abstract class RestTimerState extends Equatable {
  const RestTimerState();

  @override
  List<Object?> get props => [];
}

class RestTimerIdle extends RestTimerState {
  const RestTimerIdle();
}

class RestTimerRunning extends RestTimerState {
  final int secondsRemaining;
  final int totalSeconds;
  final String nextExercise;
  final int nextSet;
  final String workoutId;
  final String workoutExerciseId;
  final DateTime restEndsAt;

  const RestTimerRunning({
    required this.secondsRemaining,
    required this.totalSeconds,
    required this.nextExercise,
    required this.nextSet,
    required this.workoutId,
    required this.workoutExerciseId,
    required this.restEndsAt,
  });

  @override
  List<Object?> get props => [
        secondsRemaining,
        totalSeconds,
        nextExercise,
        nextSet,
        workoutId,
        workoutExerciseId,
        restEndsAt,
      ];
}

enum RestTimerFinishReason { natural, skipped }

class RestTimerFinished extends RestTimerState {
  final RestTimerFinishReason reason;

  const RestTimerFinished(this.reason);

  @override
  List<Object?> get props => [reason];
}

class RestTimerCancelled extends RestTimerState {
  const RestTimerCancelled();
}

/// In-app rest countdown; OS notification fires at scheduled end only.
@lazySingleton
class RestTimerBloc extends Bloc<RestTimerEvent, RestTimerState> {
  final NotificationService _notifications;
  Timer? _ticker;

  static const int _minRemainingSeconds = 5;

  RestTimerBloc(this._notifications) : super(const RestTimerIdle()) {
    on<StartRestTimer>(_onStart);
    on<TickRestTimer>(_onTick);
    on<SkipRestTimer>(_onSkip);
    on<AdjustRestTimer>(_onAdjust);
    on<CancelRestTimer>(_onCancel);
  }

  void _cancelTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  Future<void> _onStart(
    StartRestTimer event,
    Emitter<RestTimerState> emit,
  ) async {
    _cancelTicker();
    await _notifications.cancelRestEnd();

    if (event.totalSeconds <= 0) {
      emit(const RestTimerIdle());
      return;
    }

    await _notifications.scheduleRestEnd(
      workoutId: event.workoutId,
      restSeconds: event.totalSeconds,
      nextExercise: event.nextExercise,
      nextSet: event.nextSet,
    );

    final endsAt = DateTime.now().add(Duration(seconds: event.totalSeconds));
    emit(
      RestTimerRunning(
        secondsRemaining: event.totalSeconds,
        totalSeconds: event.totalSeconds,
        nextExercise: event.nextExercise,
        nextSet: event.nextSet,
        workoutId: event.workoutId,
        workoutExerciseId: event.workoutExerciseId,
        restEndsAt: endsAt,
      ),
    );

    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => add(const TickRestTimer()),
    );
  }

  Future<void> _onTick(
    TickRestTimer event,
    Emitter<RestTimerState> emit,
  ) async {
    final current = state;
    if (current is! RestTimerRunning) return;

    final next = current.secondsRemaining - 1;
    if (next <= 0) {
      _cancelTicker();
      await _notifications.cancelRestEnd();
      await _notifications.showRestEnded(workoutId: current.workoutId);
      await _playRestEndedFeedback();
      emit(const RestTimerFinished(RestTimerFinishReason.natural));
      emit(const RestTimerIdle());
      return;
    }

    emit(
      RestTimerRunning(
        secondsRemaining: next,
        totalSeconds: current.totalSeconds,
        nextExercise: current.nextExercise,
        nextSet: current.nextSet,
        workoutId: current.workoutId,
        workoutExerciseId: current.workoutExerciseId,
        restEndsAt: current.restEndsAt,
      ),
    );
  }

  Future<void> _onSkip(
    SkipRestTimer event,
    Emitter<RestTimerState> emit,
  ) async {
    final wasRunning = state is RestTimerRunning;
    _cancelTicker();
    await _notifications.cancelRestEnd();
    if (wasRunning) {
      emit(const RestTimerFinished(RestTimerFinishReason.skipped));
    }
    emit(const RestTimerIdle());
  }

  Future<void> _onAdjust(
    AdjustRestTimer event,
    Emitter<RestTimerState> emit,
  ) async {
    final current = state;
    if (current is! RestTimerRunning) return;

    final adjusted = (current.secondsRemaining + event.deltaSeconds)
        .clamp(_minRemainingSeconds, 86400)
        .toInt();
    if (adjusted == current.secondsRemaining) return;

    await _notifications.cancelRestEnd();
    await _notifications.scheduleRestEnd(
      workoutId: current.workoutId,
      restSeconds: adjusted,
      nextExercise: current.nextExercise,
      nextSet: current.nextSet,
    );

    final endsAt = DateTime.now().add(Duration(seconds: adjusted));
    emit(
      RestTimerRunning(
        secondsRemaining: adjusted,
        totalSeconds: current.totalSeconds,
        nextExercise: current.nextExercise,
        nextSet: current.nextSet,
        workoutId: current.workoutId,
        workoutExerciseId: current.workoutExerciseId,
        restEndsAt: endsAt,
      ),
    );
  }

  Future<void> _onCancel(
    CancelRestTimer event,
    Emitter<RestTimerState> emit,
  ) async {
    _cancelTicker();
    await _notifications.cancelRestEnd();
    emit(const RestTimerCancelled());
    emit(const RestTimerIdle());
  }

  Future<void> _playRestEndedFeedback() async {
    try {
      await HapticFeedback.heavyImpact();
      final has = await Vibration.hasVibrator();
      if (has == true) {
        await Vibration.vibrate(duration: 400);
      }
    } catch (_) {}
    try {
      await SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _cancelTicker();
    return super.close();
  }
}
