import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_tracker/common/utils/date_formatters.dart';
import 'package:gym_tracker/core/enums/set_type_enum.dart';
import 'package:gym_tracker/features/profile/bloc/workout_detail_cubit.dart';

class WorkoutDetailScreen extends StatelessWidget {
  const WorkoutDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkoutDetailCubit, WorkoutDetailState>(
      builder: (context, state) {
        final detail = state.detail;
        return Scaffold(
          appBar: AppBar(title: Text(detail?.workout.name ?? 'Workout')),
          body: detail == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(DateFormatters.duration(detail.workout.startTime, detail.workout.endTime)),
                    Text('${detail.workout.volume.toStringAsFixed(0)} kg total'),
                    const SizedBox(height: 16),
                    ...detail.exercises.map(
                      (exercise) => Card(
                        child: ExpansionTile(
                          title: Text(exercise.exercise.name),
                          children: exercise.sets
                              .map(
                                (set) => ListTile(
                                  title: Text('${set.weight?.toStringAsFixed(1) ?? '-'} kg x ${set.reps ?? '-'}'),
                                  subtitle: Text(set.setType.displayName),
                                  trailing: Icon(set.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
