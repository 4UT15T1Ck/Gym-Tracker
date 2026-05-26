import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_tracker/common/routes/routes.dart';
import 'package:gym_tracker/common/widgets/app_haptics.dart';
import 'package:gym_tracker/common/widgets/motion_tokens.dart';
import 'package:gym_tracker/common/widgets/tap_scale.dart';
import 'package:gym_tracker/features/shell/bloc/shell_active_workout_cubit.dart';
import 'package:gym_tracker/features/workout/bloc/workout_home_cubit.dart';

class WorkoutHomeScreen extends StatelessWidget {
  const WorkoutHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkoutHomeCubit, WorkoutHomeState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TapScale(
              child: FilledButton.icon(
                onPressed: () async {
                  final id = await context
                      .read<WorkoutHomeCubit>()
                      .startEmptyWorkout();
                  if (context.mounted) {
                    context.read<ShellActiveWorkoutCubit>().refreshNow();
                  }
                  if (!context.mounted) return;
                  Navigator.of(context).pushNamed(
                    Routes.activeWorkout,
                    arguments: ActiveWorkoutRouteArgs(workoutId: id),
                  );
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Empty Workout'),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TapScale(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Navigator.of(
                          context,
                        ).pushNamed(Routes.createRoutine);
                        if (context.mounted) {
                          context.read<WorkoutHomeCubit>().load();
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('New Routine'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TapScale(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          Navigator.of(context).pushNamed(Routes.exerciseList),
                      icon: const Icon(Icons.search),
                      label: const Text('Explore'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Routines (${state.routines.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (state.isLoading) const LinearProgressIndicator(),
            if (state.routines.isEmpty && !state.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('No routines yet. Create one to start faster.'),
              ),
            ...state.routines.indexed.map((entry) {
              final index = entry.$1;
              final routine = entry.$2;
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: MotionTokens.resolve(
                  context,
                  Duration(milliseconds: 220 + (index * 30)),
                ),
                curve: MotionTokens.standardCurve,
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - value) * 10),
                    child: child,
                  ),
                ),
                child: Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      InkWell(
                        onTap: () async {
                          await Navigator.of(context).pushNamed(
                            Routes.routineDetail,
                            arguments: RoutineDetailRouteArgs(
                              routineId: routine.routine.id,
                            ),
                          );
                          if (context.mounted) {
                            context.read<WorkoutHomeCubit>().load();
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      routine.routine.name,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_horiz),
                                    onSelected: (value) async {
                                      if (value == 'edit') {
                                        final saved =
                                            await Navigator.of(
                                              context,
                                            ).pushNamed<bool>(
                                              Routes.editRoutine,
                                              arguments: EditRoutineRouteArgs(
                                                detail: routine,
                                              ),
                                            );
                                        if (saved == true && context.mounted) {
                                          context
                                              .read<WorkoutHomeCubit>()
                                              .load();
                                          await AppHaptics.success(context);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                              ..hideCurrentSnackBar()
                                              ..showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Routine updated',
                                                  ),
                                                  duration: Duration(
                                                    milliseconds: 1100,
                                                  ),
                                                ),
                                              );
                                          }
                                        }
                                      } else if (value == 'delete') {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text(
                                              'Delete Routine?',
                                            ),
                                            content: const Text(
                                              'This action cannot be undone.',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(
                                                  context,
                                                ).pop(false),
                                                child: const Text('Cancel'),
                                              ),
                                              FilledButton(
                                                style: FilledButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                ),
                                                onPressed: () => Navigator.of(
                                                  context,
                                                ).pop(true),
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true &&
                                            context.mounted) {
                                          await context
                                              .read<WorkoutHomeCubit>()
                                              .deleteRoutine(
                                                routine.routine.id,
                                              );
                                          if (!context.mounted) return;
                                          await AppHaptics.success(context);
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context)
                                            ..hideCurrentSnackBar()
                                            ..showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Routine deleted',
                                                ),
                                                duration: Duration(
                                                  milliseconds: 1100,
                                                ),
                                              ),
                                            );
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
                              const SizedBox(height: 4),
                              Text(
                                routine.exercises
                                    .map((e) => e.exercise.name)
                                    .join(', '),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: FilledButton(
                          onPressed: () async {
                            final id = await context
                                .read<WorkoutHomeCubit>()
                                .startRoutine(routine);
                            if (context.mounted) {
                              context
                                  .read<ShellActiveWorkoutCubit>()
                                  .refreshNow();
                            }
                            if (!context.mounted) return;
                            Navigator.of(context).pushNamed(
                              Routes.activeWorkout,
                              arguments: ActiveWorkoutRouteArgs(workoutId: id),
                            );
                          },
                          child: const Text('Start Routine'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            if (state.errorMessage != null) Text(state.errorMessage!),
          ],
        );
      },
    );
  }
}
