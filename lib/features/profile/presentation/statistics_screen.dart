import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_tracker/features/profile/bloc/statistics_cubit.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StatisticsCubit, StatisticsState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Statistics')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
                if (state.isLoading) const LinearProgressIndicator(),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Counter(label: 'Workouts', value: '${state.totalWorkouts}'),
                    _Counter(label: 'Sets', value: '${state.totalSets}'),
                    _Counter(label: 'Reps', value: '${state.totalReps}'),
                    _Counter(label: 'Volume', value: '${state.totalVolume.toStringAsFixed(0)} kg'),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Volume Over Time', style: Theme.of(context).textTheme.titleMedium),
                _SimpleBars(values: state.volumeHistory),
                const SizedBox(height: 24),
                Text('Personal Records', style: Theme.of(context).textTheme.titleMedium),
                if (state.prs.isEmpty) const Text('No PRs yet.'),
                ...state.prs.map((pr) => ListTile(leading: const Icon(Icons.emoji_events), title: Text(pr))),
            ],
          ),
        );
      },
    );
  }
}

class _Counter extends StatelessWidget {
  final String label;
  final String value;

  const _Counter({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: Theme.of(context).textTheme.titleLarge),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}

class _SimpleBars extends StatelessWidget {
  final List<({DateTime date, double volume})> values;

  const _SimpleBars({required this.values});

  @override
  Widget build(BuildContext context) {
    final maxValue = values.fold<double>(1, (max, value) => value.volume > max ? value.volume : max);
    return SizedBox(
      height: 210,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: values.take(30).map((value) {
          final label = '${value.date.month}/${value.date.day}';
          return Expanded(
            child: InkWell(
              onTap: () => showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(label),
                  content: Text('Volume: ${value.volume.toStringAsFixed(0)} kg'),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('${value.volume.toStringAsFixed(0)}kg', maxLines: 1, overflow: TextOverflow.ellipsis),
                    Container(
                      height: 8 + (value.volume / maxValue) * 130,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 4),
                    Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
