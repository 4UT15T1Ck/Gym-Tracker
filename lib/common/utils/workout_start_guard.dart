import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_tracker/features/shell/bloc/shell_active_workout_cubit.dart';

enum _WorkoutStartAction { cancel, resume, startNew }

/// Returns the workout id to open, or null when the user cancels.
Future<String?> guardedStartWorkout(
  BuildContext context, {
  required Future<String?> Function() onStart,
}) async {
  const bgColor = Color(0xFF151A23);
  const mutedText = Color(0xFF8C94A5);
  const accent = Color(0xFF4A8DFF);
  const outline = Color(0xFF283041);

  final shellCubit = context.read<ShellActiveWorkoutCubit>();

  if (!shellCubit.state.hasActiveWorkout) {
    final workoutId = await onStart();
    await shellCubit.refreshNow();
    return workoutId;
  }

  final action = await showDialog<_WorkoutStartAction>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: outline),
      ),
      title: const Text(
        'Workout in progress',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
      content: const Text(
        'You already have an active workout. Resume it or discard it before starting a new one.',
        style: TextStyle(color: mutedText),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(dialogContext).pop(_WorkoutStartAction.cancel),
          style: TextButton.styleFrom(foregroundColor: mutedText),
          child: const Text('Cancel'),
        ),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: outline),
          ),
          onPressed: () =>
              Navigator.of(dialogContext).pop(_WorkoutStartAction.resume),
          child: const Text('Resume'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
          ),
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
