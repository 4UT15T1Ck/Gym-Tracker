import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_tracker/core/enums/tracking_type_enum.dart';
import 'package:gym_tracker/features/library/bloc/exercise_detail_cubit.dart';

class ExerciseDetailScreen extends StatelessWidget {
  const ExerciseDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExerciseDetailCubit, ExerciseDetailState>(
      builder: (context, state) {
        final detail = state.detail;
        return Scaffold(
          appBar: AppBar(title: Text(detail?.exercise.name ?? 'Exercise')),
          body: detail == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      height: 160,
                      alignment: Alignment.center,
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.fitness_center, size: 48),
                    ),
                    const SizedBox(height: 16),
                    Text(detail.exercise.name, style: Theme.of(context).textTheme.headlineSmall),
                    Text(detail.exercise.trackingType.displayName),
                    Text('Primary: ${detail.primaryMuscle.name}'),
                    if (detail.secondaryMuscles.isNotEmpty)
                      Text('Secondary: ${detail.secondaryMuscles.map((m) => m.name).join(', ')}'),
                    if (detail.equipment != null) Text('Equipment: ${detail.equipment!.name}'),
                    const SizedBox(height: 16),
                    if (detail.exercise.shortDescription != null) Text(detail.exercise.shortDescription!),
                    const SizedBox(height: 16),
                    Text('Instructions', style: Theme.of(context).textTheme.titleMedium),
                    ...detail.exercise.instructions.indexed.map((entry) => ListTile(
                          leading: CircleAvatar(child: Text('${entry.$1 + 1}')),
                          title: Text(entry.$2),
                        )),
                    const SizedBox(height: 16),
                    Text('Stats', style: Theme.of(context).textTheme.titleMedium),
                    Text('Total sessions: ${detail.stats?.totalSessions ?? 0}'),
                    Text('Personal best: ${detail.stats?.personalBest?.weight?.toStringAsFixed(1) ?? '-'} kg'),
                    ...?detail.stats?.recentHistory.take(5).map(
                          (entry) => ListTile(
                            title: Text(entry.workoutName),
                            subtitle: Text('${entry.sets.length} sets'),
                          ),
                        ),
                  ],
                ),
        );
      },
    );
  }
}
