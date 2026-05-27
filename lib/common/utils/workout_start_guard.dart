import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_tracker/features/shell/bloc/shell_active_workout_cubit.dart';

enum _WorkoutStartAction { cancel, resume, startNew }

/// Returns the workout id to open, or null when the user cancels.
Future<String?> guardedStartWorkout(
  BuildContext context, {
  required Future<String?> Function() onStart,
}) async {
  final shellCubit = context.read<ShellActiveWorkoutCubit>();

  if (!shellCubit.state.hasActiveWorkout) {
    final workoutId = await onStart();
    await shellCubit.refreshNow();
    return workoutId;
  }

  final action = await showDialog<_WorkoutStartAction>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Workout in progress'),
      content: const Text(
        'You already have an active workout. Resume it or discard it before starting a new one.',
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(dialogContext).pop(_WorkoutStartAction.cancel),
          child: const Text('Cancel'),
        ),
        OutlinedButton(
          onPressed: () =>
              Navigator.of(dialogContext).pop(_WorkoutStartAction.resume),
          child: const Text('Resume'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(dialogContext).pop(_WorkoutStartAction.startNew),
          child: const Text('Start New'),
        ),
      ],
    ),
  );

  if (action == null || action == _WorkoutStartAction.cancel) {
    return null;
  }

  if (action == _WorkoutStartAction.resume) {
    return shellCubit.state.workoutId;
  }

  await shellCubit.discardActiveWorkout();
  final workoutId = await onStart();
  await shellCubit.refreshNow();
  return workoutId;
}
