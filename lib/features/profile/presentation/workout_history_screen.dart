import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_tracker/common/routes/routes.dart';
import 'package:gym_tracker/common/utils/date_formatters.dart';
import 'package:gym_tracker/features/profile/bloc/workout_history_cubit.dart';

class WorkoutHistoryScreen extends StatelessWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkoutHistoryCubit, WorkoutHistoryState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Workout History')),
          body: ListView(
            padding: const EdgeInsets.all(12),
            children: [
                _CalendarSummary(
                  selectedDate: state.selectedDate,
                  trainedDayKeys: state.trainedDayKeys,
                  onSelected: context.read<WorkoutHistoryCubit>().selectDate,
                ),
                if (state.isLoading) const LinearProgressIndicator(),
                const SizedBox(height: 12),
                Text(DateFormatters.shortDate(state.selectedDate), style: Theme.of(context).textTheme.titleMedium),
                if (state.selectedWorkouts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('No workouts logged for this day.')),
                  ),
                ...state.selectedWorkouts.map(
                  (workout) => Card(
                    child: ListTile(
                      title: Text(workout.name),
                      subtitle: Text(
                        '${DateFormatters.shortDate(workout.startTime)} · '
                        '${DateFormatters.duration(workout.startTime, workout.endTime)} · '
                        '${workout.volume.toStringAsFixed(0)} kg',
                      ),
                      trailing: Text('${workout.totalSets} sets'),
                      onTap: () => Navigator.of(context).pushNamed(
                        Routes.workoutDetail,
                        arguments: WorkoutDetailRouteArgs(workoutId: workout.id),
                      ),
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

class _CalendarSummary extends StatelessWidget {
  final DateTime selectedDate;
  final Set<int> trainedDayKeys;
  final ValueChanged<DateTime> onSelected;

  const _CalendarSummary({
    required this.selectedDate,
    required this.trainedDayKeys,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(daysInMonth, (index) {
        final day = DateTime(selectedDate.year, selectedDate.month, index + 1);
        final key = DateTime(day.year, day.month, day.day).millisecondsSinceEpoch;
        final trained = trainedDayKeys.contains(key);
        final selected = day == selectedDate;
        return InkWell(
          customBorder: const CircleBorder(),
          onTap: () => onSelected(day),
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? Theme.of(context).colorScheme.primary : null,
              border: Border.all(
                color: trained ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline,
                width: trained ? 2 : 1,
              ),
            ),
            child: Text('${day.day}', style: const TextStyle(fontSize: 12)),
          ),
        );
      }),
    );
  }
}
