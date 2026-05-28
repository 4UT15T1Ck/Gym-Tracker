import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_tracker/common/routes/routes.dart';
import 'package:gym_tracker/common/utils/workout_start_guard.dart';
import 'package:gym_tracker/common/widgets/app_haptics.dart';
import 'package:gym_tracker/common/widgets/motion_tokens.dart';
import 'package:gym_tracker/common/widgets/tap_scale.dart';
import 'package:gym_tracker/features/workout/bloc/workout_home_cubit.dart';

class WorkoutHomeScreen extends StatelessWidget {
  const WorkoutHomeScreen({super.key});

  static const _bgColor = Color(0xFF080A0F);
  static const _cardColor = Color(0xFF151A23);
  static const _mutedText = Color(0xFF8C94A5);
  static const _accent = Color(0xFF4A8DFF);
  static const _accentSoft = Color(0xFF8FB7EA);
  static const _accentTextDark = Color(0xFF0E335A);
  static const _outline = Color(0xFF7A8393);

  static AlertDialog _styledDialog({
    required String title,
    required String content,
    required List<Widget> actions,
  }) {
    return AlertDialog(
      backgroundColor: _cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _outline),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(content, style: const TextStyle(color: _mutedText)),
      actions: actions,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkoutHomeCubit, WorkoutHomeState>(
      builder: (context, state) {
        final theme = Theme.of(context);
        final bottomInset = MediaQuery.of(context).padding.bottom;
        return ColoredBox(
          color: _bgColor,
          child: SafeArea(
            bottom: false,
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 14, 16, bottomInset + 16),
              children: [
                Text(
                  'Workout',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 34,
                  ),
                ),
                const SizedBox(height: 12),
                TapScale(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: _cardColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      textStyle: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    onPressed: () async {
                      final id = await guardedStartWorkout(
                        context,
                        onStart: () => context
                            .read<WorkoutHomeCubit>()
                            .startEmptyWorkout(),
                      );
                      if (!context.mounted || id == null) return;
                      Navigator.of(context).pushNamed(
                        Routes.activeWorkout,
                        arguments: ActiveWorkoutRouteArgs(workoutId: id),
                      );
                    },
                    icon: const Icon(Icons.add, size: 22),
                    label: const Text('Start Empty Workout'),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Routines',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    TapScale(
                      child: IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: _accentTextDark,
                          fixedSize: const Size(30, 30),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          await Navigator.of(
                            context,
                          ).pushNamed(Routes.createRoutine);
                          if (context.mounted) {
                            context.read<WorkoutHomeCubit>().load();
                          }
                        },
                        icon: const Icon(Icons.add, size: 22),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TapScale(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: _outline, width: 2),
                            minimumSize: const Size.fromHeight(45),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          onPressed: () async {
                            await Navigator.of(
                              context,
                            ).pushNamed(Routes.createRoutine);
                            if (context.mounted) {
                              context.read<WorkoutHomeCubit>().load();
                            }
                          },
                          icon: const Icon(Icons.edit_note, size: 22),
                          label: const Text('New Routine'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TapScale(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: _outline, width: 2),
                            minimumSize: const Size.fromHeight(45),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          onPressed: () => Navigator.of(
                            context,
                          ).pushNamed(Routes.exerciseList),
                          icon: const Icon(Icons.search, size: 22),
                          label: const Text('Explore'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'My Routines (${state.routines.length})',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: _mutedText,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_up, color: _mutedText),
                  ],
                ),
                const SizedBox(height: 10),
                if (state.isLoading) const LinearProgressIndicator(),
                if (state.routines.isEmpty && !state.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      'No routines yet. Create one to start faster.',
                      style: TextStyle(color: _mutedText),
                    ),
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
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: _cardColor,
                        borderRadius: BorderRadius.circular(24),
                      ),
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
                              padding: const EdgeInsets.fromLTRB(16, 16, 12, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          routine.routine.name,
                                          style: theme.textTheme.headlineSmall
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 20,
                                              ),
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        icon: const Icon(
                                          Icons.more_horiz,
                                          color: Colors.white,
                                        ),
                                        onSelected: (value) async {
                                          if (value == 'edit') {
                                            final saved =
                                                await Navigator.of(
                                                  context,
                                                ).pushNamed<bool>(
                                                  Routes.editRoutine,
                                                  arguments:
                                                      EditRoutineRouteArgs(
                                                        detail: routine,
                                                      ),
                                                );
                                            if (saved == true &&
                                                context.mounted) {
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
                                              builder: (context) => _styledDialog(
                                                title: 'Delete Routine?',
                                                content:
                                                    'This action cannot be undone.',
                                                actions: [
                                                  TextButton(
                                                    style: TextButton.styleFrom(
                                                      foregroundColor:
                                                          _mutedText,
                                                    ),
                                                    onPressed: () =>
                                                        Navigator.of(
                                                          context,
                                                        ).pop(false),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  FilledButton(
                                                    style:
                                                        FilledButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.red,
                                                          foregroundColor:
                                                              Colors.white,
                                                        ),
                                                    onPressed: () =>
                                                        Navigator.of(
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
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
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
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: _mutedText,
                                      height: 1.35,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: _accent,
                                foregroundColor: _accentSoft,
                                minimumSize: const Size.fromHeight(45),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                textStyle: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              onPressed: () async {
                                final id = await guardedStartWorkout(
                                  context,
                                  onStart: () => context
                                      .read<WorkoutHomeCubit>()
                                      .startRoutine(routine),
                                );
                                if (!context.mounted || id == null) return;
                                Navigator.of(context).pushNamed(
                                  Routes.activeWorkout,
                                  arguments: ActiveWorkoutRouteArgs(
                                    workoutId: id,
                                  ),
                                );
                              },
                              child: const Text(
                                'Start Routine',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                if (state.errorMessage != null) Text(state.errorMessage!),
              ],
            ),
          ),
        );
      },
    );
  }
}
