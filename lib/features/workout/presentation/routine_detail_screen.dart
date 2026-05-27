import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_tracker/common/routes/routes.dart';
import 'package:gym_tracker/common/utils/workout_start_guard.dart';
import 'package:gym_tracker/common/widgets/app_haptics.dart';
import 'package:gym_tracker/common/widgets/motion_tokens.dart';
import 'package:gym_tracker/common/widgets/tap_scale.dart';
import 'package:gym_tracker/core/enums/set_type_enum.dart';
import 'package:gym_tracker/features/workout/bloc/routine_detail_cubit.dart';

class RoutineDetailScreen extends StatelessWidget {
  const RoutineDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoutineDetailCubit, RoutineDetailState>(
      builder: (context, state) {
        final detail = state.detail;
        return Scaffold(
          appBar: AppBar(
            title: Text(detail?.routine.name ?? 'Routine'),
            actions: [
              if (detail != null)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz),
                  onSelected: (value) async {
                    if (value == 'edit') {
                      final saved = await Navigator.of(context).pushNamed<bool>(
                        Routes.editRoutine,
                        arguments: EditRoutineRouteArgs(detail: detail),
                      );
                      if (context.mounted && saved == true) {
                        await context.read<RoutineDetailCubit>().reload();
                        if (!context.mounted) return;
                        await AppHaptics.success(context);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            const SnackBar(
                              content: Text('Routine updated'),
                              duration: Duration(milliseconds: 1100),
                            ),
                          );
                      }
                    } else if (value == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Routine?'),
                          content: const Text('This action cannot be undone.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && context.mounted) {
                        await context
                            .read<RoutineDetailCubit>()
                            .deleteRoutine();
                        if (!context.mounted) return;
                        await AppHaptics.success(context);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            const SnackBar(
                              content: Text('Routine deleted'),
                              duration: Duration(milliseconds: 1100),
                            ),
                          );
                        Navigator.of(context).pop();
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit Routine'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete Routine',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          body: state.isLoading && detail == null
              ? const Center(child: CircularProgressIndicator())
              : state.errorMessage != null && detail == null
              ? Center(child: Text(state.errorMessage!))
              : detail == null
              ? const Center(child: Text('Routine not found.'))
              : RefreshIndicator(
                  onRefresh: () => context.read<RoutineDetailCubit>().reload(),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (state.isLoading) const LinearProgressIndicator(),
                      TapScale(
                        child: FilledButton.icon(
                          onPressed: state.isLoading
                              ? null
                              : () async {
                                  final id = await guardedStartWorkout(
                                    context,
                                    onStart: () => context
                                        .read<RoutineDetailCubit>()
                                        .startWorkoutFromCurrentRoutine(),
                                  );
                                  if (!context.mounted || id == null) {
                                    return;
                                  }
                                  Navigator.of(context).pushNamed(
                                    Routes.activeWorkout,
                                    arguments: ActiveWorkoutRouteArgs(
                                      workoutId: id,
                                    ),
                                  );
                                },
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start Routine'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (detail.routine.notes != null &&
                          detail.routine.notes!.trim().isNotEmpty) ...[
                        Text(
                          'Notes',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(detail.routine.notes!),
                        const SizedBox(height: 20),
                      ],
                      Text(
                        'Exercises (${detail.exercises.length})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ...detail.exercises.indexed.map((entry) {
                        final index = entry.$1;
                        final ed = entry.$2;
                        final sets = [...ed.sets]
                          ..sort((a, b) => a.order.compareTo(b.order));
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: MotionTokens.resolve(
                            context,
                            Duration(milliseconds: 220 + (index * 24)),
                          ),
                          curve: MotionTokens.standardCurve,
                          builder: (context, value, child) => Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, (1 - value) * 8),
                              child: child,
                            ),
                          ),
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    ed.exercise.name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Rest: ${ed.routineExercise.targetRestSeconds ?? '—'} s',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 8),
                                  ...sets.indexed.map((entry) {
                                    final i = entry.$1;
                                    final s = entry.$2;
                                    final w = s.targetWeight != null
                                        ? '${s.targetWeight} kg'
                                        : '— kg';
                                    final r = s.targetReps != null
                                        ? '${s.targetReps} reps'
                                        : '— reps';
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        'Set ${i + 1} · ${s.setType.displayName} · $w · $r',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
