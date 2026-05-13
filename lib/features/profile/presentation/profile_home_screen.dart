import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_tracker/common/routes/routes.dart';
import 'package:gym_tracker/features/profile/bloc/profile_cubit.dart';

class ProfileHomeScreen extends StatelessWidget {
  const ProfileHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
              Row(
                children: [
                  CircleAvatar(radius: 32, child: Text(state.initials)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(state.username, style: Theme.of(context).textTheme.titleLarge),
                        Text('${state.totalWorkouts} workouts'),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      final controller = TextEditingController(text: state.username);
                      final name = await showDialog<String>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Profile name'),
                          content: TextField(controller: controller, autofocus: true),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                            FilledButton(onPressed: () => Navigator.of(context).pop(controller.text), child: const Text('Save')),
                          ],
                        ),
                      );
                      if (!context.mounted || name == null) return;
                      context.read<ProfileCubit>().updateName(name);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _MainChart(state: state),
              const SizedBox(height: 24),
              Text('Dashboard', style: Theme.of(context).textTheme.titleMedium),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.5,
                children: [
                  _DashboardCard(icon: Icons.bar_chart, title: 'Statistics', subtitle: 'Volume, reps, PRs', route: Routes.statistics),
                  _DashboardCard(icon: Icons.accessibility_new, title: 'Muscle Map', subtitle: 'Training balance', route: Routes.muscleMap),
                  _DashboardCard(icon: Icons.straighten, title: 'Measures', subtitle: 'Body metrics', route: Routes.measures),
                  _DashboardCard(icon: Icons.calendar_month, title: 'Calendar', subtitle: 'Workout history', route: Routes.workoutHistory),
                ],
              ),
              if (state.isLoading) const LinearProgressIndicator(),
          ],
        );
      },
    );
  }
}

class _MainChart extends StatelessWidget {
  final ProfileState state;

  const _MainChart({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProfileCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text('Progress', style: Theme.of(context).textTheme.titleMedium)),
            SegmentedButton<ProfileChartRange>(
              segments: const [
                ButtonSegment(value: ProfileChartRange.week, label: Text('Week')),
                ButtonSegment(value: ProfileChartRange.month, label: Text('Month')),
              ],
              selected: {state.chartRange},
              onSelectionChanged: (value) => cubit.updateChart(state.chartMetric, value.first),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _LabeledBarChart(
          bars: state.chartBars,
          metric: state.chartMetric,
        ),
        const SizedBox(height: 12),
        SegmentedButton<ProfileChartMetric>(
          segments: const [
            ButtonSegment(value: ProfileChartMetric.duration, label: Text('Duration')),
            ButtonSegment(value: ProfileChartMetric.volume, label: Text('Volume')),
            ButtonSegment(value: ProfileChartMetric.reps, label: Text('Reps')),
          ],
          selected: {state.chartMetric},
          onSelectionChanged: (value) => cubit.updateChart(value.first, state.chartRange),
        ),
      ],
    );
  }
}

class _LabeledBarChart extends StatelessWidget {
  final List<ProfileChartBar> bars;
  final ProfileChartMetric metric;

  const _LabeledBarChart({
    required this.bars,
    required this.metric,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = bars.fold<double>(1, (max, bar) => bar.value > max ? bar.value : max);
    return SizedBox(
      height: 220,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: bars.map((bar) {
          final height = 24 + (bar.value / maxValue) * 120;
          return Expanded(
            child: InkWell(
              onTap: () => showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(bar.label),
                  content: Text('${_metricLabel(metric)}: ${_valueLabel(metric, bar.value)}'),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(_valueLabel(metric, bar.value), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Container(
                      height: height,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(bar.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _metricLabel(ProfileChartMetric metric) {
    switch (metric) {
      case ProfileChartMetric.duration:
        return 'Duration';
      case ProfileChartMetric.volume:
        return 'Volume';
      case ProfileChartMetric.reps:
        return 'Reps';
    }
  }

  String _valueLabel(ProfileChartMetric metric, double value) {
    switch (metric) {
      case ProfileChartMetric.duration:
        return '${value.toStringAsFixed(0)}m';
      case ProfileChartMetric.volume:
        return '${value.toStringAsFixed(0)}kg';
      case ProfileChartMetric.reps:
        return value.toStringAsFixed(0);
    }
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed(route),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon),
              const Spacer(),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Text(subtitle),
            ],
          ),
        ),
      ),
    );
  }
}
