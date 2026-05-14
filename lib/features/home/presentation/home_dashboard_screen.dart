import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_tracker/common/routes/routes.dart';
import 'package:gym_tracker/common/utils/date_formatters.dart';
import 'package:gym_tracker/common/utils/muscle_group_utils.dart';
import 'package:gym_tracker/features/home/bloc/home_dashboard_cubit.dart';
import 'package:gym_tracker/features/shell/bloc/shell_active_workout_cubit.dart';

class HomeDashboardScreen extends StatelessWidget {
  final VoidCallback onOpenWorkoutTab;

  const HomeDashboardScreen({super.key, required this.onOpenWorkoutTab});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeDashboardCubit, HomeDashboardState>(
      builder: (context, state) {
        final summary = state.summary;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
              Text(
                'Good morning, ${state.username}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(DateFormatters.shortDate(DateTime.now())),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () async {
                  final id = await context.read<HomeDashboardCubit>().startEmptyWorkout();
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
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: summary?.suggestedRoutine == null
                    ? onOpenWorkoutTab
                    : () async {
                        final id = await context.read<HomeDashboardCubit>().startSuggestedRoutine();
                        if (context.mounted) {
                          context.read<ShellActiveWorkoutCubit>().refreshNow();
                        }
                        if (!context.mounted || id == null) return;
                        Navigator.of(context).pushNamed(
                          Routes.activeWorkout,
                          arguments: ActiveWorkoutRouteArgs(workoutId: id),
                        );
                      },
                icon: const Icon(Icons.auto_awesome),
                label: Text(summary?.suggestedRoutine?.name ?? 'Pick a Routine'),
              ),
              if (summary?.suggestedRoutine != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(summary!.suggestedRoutine!.reason),
                ),
              const SizedBox(height: 24),
              _SectionTitle('This Week'),
              _ThisWeekStrip(days: summary?.thisWeekTrainedDays ?? const []),
              Text('${summary?.streakDays ?? 0} day streak'),
              const SizedBox(height: 24),
              _SectionTitle('Last Workout'),
              if (summary?.lastWorkout == null)
                const Text('Log your first workout to see stats.')
              else
                Card(
                  child: ListTile(
                    title: Text(summary!.lastWorkout!.name),
                    subtitle: Text(
                      '${DateFormatters.shortDate(summary.lastWorkout!.startTime)} · '
                      '${DateFormatters.duration(summary.lastWorkout!.startTime, summary.lastWorkout!.endTime)} · '
                      '${summary.lastWorkout!.volume.toStringAsFixed(0)} kg',
                    ),
                    trailing: Wrap(
                      spacing: 4,
                      children: summary.lastWorkoutMuscleTags.map((tag) => Chip(label: Text(tag))).toList(),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              _SectionTitle('Recent PRs'),
              if (summary?.recentPrs.isEmpty ?? true)
                const Text('No PRs yet.')
              else
                ...summary!.recentPrs.map(
                  (pr) => Card(
                    child: ListTile(
                      leading: const Chip(label: Text('PR')),
                      title: Text(pr.exerciseName),
                      trailing: Text('${pr.weight.toStringAsFixed(1)} kg'),
                      subtitle: Text('${pr.reps ?? '-'} reps'),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              _SectionTitle('Muscle Recovery'),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.6,
                children: (summary?.recovery ?? const []).map((item) {
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 6,
                        backgroundColor: _recoveryColor(item.status),
                      ),
                      title: Text(item.group),
                      subtitle: Text(item.sinceLabel),
                    ),
                  );
                }).toList(),
              ),
              if (state.isLoading) const LinearProgressIndicator(),
              if (state.errorMessage != null) Text(state.errorMessage!),
          ],
        );
      },
    );
  }

  Color _recoveryColor(RecoveryStatus status) {
    switch (status) {
      case RecoveryStatus.sore:
        return Colors.red;
      case RecoveryStatus.recovering:
        return Colors.orange;
      case RecoveryStatus.ready:
        return Colors.teal;
      case RecoveryStatus.fresh:
        return Colors.lightGreen;
    }
  }
}

class _ThisWeekStrip extends StatelessWidget {
  final List<bool> days;

  const _ThisWeekStrip({required this.days});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final trained = index < days.length && days[index];
        final isToday = now.weekday - 1 == index;
        return Column(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isToday ? Theme.of(context).colorScheme.primaryContainer : null,
                border: Border.all(
                  color: trained ? Theme.of(context).colorScheme.primary : Colors.grey,
                  width: trained ? 2 : 1,
                ),
              ),
              child: Text(DateFormatters.weekday(DateTime(2024, 1, index + 1)).substring(0, 1)),
            ),
            Text(DateFormatters.weekday(DateTime(2024, 1, index + 1))),
          ],
        );
      }),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
