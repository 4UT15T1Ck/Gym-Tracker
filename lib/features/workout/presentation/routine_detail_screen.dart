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

  static const _bgColor = Color(0xFF080A0F);
  static const _cardColor = Color(0xFF151A23);
  static const _mutedText = Color(0xFF8C94A5);
  static const _accent = Color(0xFF4A8DFF);

  static AlertDialog _styledDialog({
    required String title,
    required String content,
    required List<Widget> actions,
  }) {
    return AlertDialog(
      backgroundColor: _cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF283041)),
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
    return BlocBuilder<RoutineDetailCubit, RoutineDetailState>(
      builder: (context, state) {
        final detail = state.detail;
        final theme = Theme.of(context);
        return Scaffold(
          backgroundColor: _bgColor,
          body: state.isLoading && detail == null
              ? const Center(child: CircularProgressIndicator())
              : state.errorMessage != null && detail == null
              ? Center(child: Text(state.errorMessage!))
              : detail == null
              ? const Center(child: Text('Routine not found.'))
              : RefreshIndicator(
                  onRefresh: () => context.read<RoutineDetailCubit>().reload(),
                  child: SafeArea(
                    bottom: false,
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        14,
                        16,
                        MediaQuery.of(context).padding.bottom + 16,
                      ),
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.arrow_back_ios_new,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                detail.routine.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
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
                                  final saved = await Navigator.of(context)
                                      .pushNamed<bool>(
                                        Routes.editRoutine,
                                        arguments: EditRoutineRouteArgs(
                                          detail: detail,
                                        ),
                                      );
                                  if (context.mounted && saved == true) {
                                    await context
                                        .read<RoutineDetailCubit>()
                                        .reload();
                                    if (!context.mounted) return;
                                    await AppHaptics.success(context);
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context)
                                      ..hideCurrentSnackBar()
                                      ..showSnackBar(
                                        const SnackBar(
                                          content: Text('Routine updated'),
                                          duration: Duration(
                                            milliseconds: 1100,
                                          ),
                                        ),
                                      );
                                  }
                                } else if (value == 'delete') {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => _styledDialog(
                                      title: 'Delete Routine?',
                                      content: 'This action cannot be undone.',
                                      actions: [
                                        TextButton(
                                          style: TextButton.styleFrom(
                                            foregroundColor: _mutedText,
                                          ),
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          style: FilledButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
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
                                          duration: Duration(
                                            milliseconds: 1100,
                                          ),
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
                        const SizedBox(height: 12),
                        if (state.isLoading) const LinearProgressIndicator(),
                        TapScale(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: _accent,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(45),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onPressed: state.isLoading
                                ? null
                                : () async {
                                    final id = await guardedStartWorkout(
                                      context,
                                      onStart: () => context
                                          .read<RoutineDetailCubit>()
                                          .startWorkoutFromCurrentRoutine(),
                                    );
                                    if (!context.mounted || id == null) return;
                                    Navigator.of(context).pushNamed(
                                      Routes.activeWorkout,
                                      arguments: ActiveWorkoutRouteArgs(
                                        workoutId: id,
                                      ),
                                    );
                                  },
                            icon: const Icon(Icons.play_arrow, size: 20),
                            label: const Text('Start Routine'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (detail.routine.notes != null &&
                            detail.routine.notes!.trim().isNotEmpty) ...[
                          Text(
                            'Notes',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            detail.routine.notes!,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: _mutedText,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        Text(
                          'Exercises (${detail.exercises.length})',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: _mutedText,
                            fontWeight: FontWeight.w700,
                          ),
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
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: _cardColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      ed.exercise.name,
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Rest: ${ed.routineExercise.targetRestSeconds ?? '—'} s',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(color: _mutedText),
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
                                        padding: const EdgeInsets.only(
                                          bottom: 4,
                                        ),
                                        child: Text(
                                          'Set ${i + 1} · ${s.setType.displayName} · $w · $r',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(color: Colors.white),
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
                ),
        );
      },
    );
  }
}
