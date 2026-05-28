import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_tracker/common/routes/routes.dart';
import 'package:gym_tracker/common/utils/date_formatters.dart';
import 'package:gym_tracker/features/profile/bloc/workout_history_cubit.dart';

class WorkoutHistoryScreen extends StatelessWidget {
  const WorkoutHistoryScreen({super.key});
  static const _bgColor = Color(0xFF080A0F);
  static const _cardColor = Color(0xFF151A23);
  static const _mutedText = Color(0xFF8C94A5);
  static const _accent = Color(0xFF4A8DFF);
  static const _outline = Color(0xFF283041);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkoutHistoryCubit, WorkoutHistoryState>(
      builder: (context, state) {
        final theme = Theme.of(context);
        return Scaffold(
          backgroundColor: _bgColor,
          body: SafeArea(
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
                        'Workout History',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _outline),
                  ),
                  child: _CalendarSummary(
                    selectedDate: state.selectedDate,
                    trainedDayKeys: state.trainedDayKeys,
                    onSelected: context.read<WorkoutHistoryCubit>().selectDate,
                  ),
                ),
                if (state.isLoading)
                  const LinearProgressIndicator(minHeight: 2),
                const SizedBox(height: 12),
                Text(
                  DateFormatters.shortDate(state.selectedDate),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                if (state.selectedWorkouts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No workouts logged for this day.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _mutedText,
                        ),
                      ),
                    ),
                  ),
                ...state.selectedWorkouts.map(
                  (workout) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _outline),
                    ),
                    child: ListTile(
                      title: Text(
                        workout.name,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${DateFormatters.shortDate(workout.startTime)} · '
                        '${DateFormatters.duration(workout.startTime, workout.endTime)} · '
                        '${workout.volume.toStringAsFixed(0)} kg',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _mutedText,
                        ),
                      ),
                      trailing: Text(
                        '${workout.totalSets} sets',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onTap: () => Navigator.of(context).pushNamed(
                        Routes.workoutDetail,
                        arguments: WorkoutDetailRouteArgs(
                          workoutId: workout.id,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
    final daysInMonth = DateTime(
      selectedDate.year,
      selectedDate.month + 1,
      0,
    ).day;
    final availableWidth = MediaQuery.of(context).size.width - 56;
    final size = ((availableWidth - (6 * 6)) / 7).clamp(30.0, 42.0);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(daysInMonth, (index) {
        final day = DateTime(selectedDate.year, selectedDate.month, index + 1);
        final key = DateTime(
          day.year,
          day.month,
          day.day,
        ).millisecondsSinceEpoch;
        final trained = trainedDayKeys.contains(key);
        final selected = day == selectedDate;
        return InkWell(
          customBorder: const CircleBorder(),
          onTap: () => onSelected(day),
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? WorkoutHistoryScreen._accent : null,
              border: Border.all(
                color: trained
                    ? WorkoutHistoryScreen._accent
                    : WorkoutHistoryScreen._outline,
                width: trained ? 2 : 1,
              ),
            ),
            child: Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 12,
                color: selected
                    ? Colors.white
                    : WorkoutHistoryScreen._mutedText,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        );
      }),
    );
  }
}
