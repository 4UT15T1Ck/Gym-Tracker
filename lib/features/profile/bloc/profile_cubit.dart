import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_tracker/core/data/preferences_store.dart';
import 'package:gym_tracker/core/repositories/analytics_repository.dart';
import 'package:gym_tracker/core/repositories/repository_models.dart';
import 'package:gym_tracker/core/repositories/workout_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton()
class ProfileCubit extends Cubit<ProfileState> {
  final WorkoutRepository _workoutRepository;

  ProfileCubit(this._workoutRepository, AnalyticsRepository analyticsRepository) : super(const ProfileState());

  Future<void> load() async {
    emit(state.copyWith(isLoading: true));
    final history = await _workoutRepository.getWorkoutHistory(limit: 500);
    final chartBars = await _buildChartBars(history, state.chartMetric, state.chartRange);
    emit(
      state.copyWith(
        isLoading: false,
        username: PreferencesStore.username,
        initials: PreferencesStore.initials,
        totalWorkouts: history.length,
        chartBars: chartBars,
      ),
    );
  }

  Future<void> updateChart(ProfileChartMetric metric, ProfileChartRange range) async {
    emit(state.copyWith(chartMetric: metric, chartRange: range));
    await load();
  }

  Future<void> updateName(String value) async {
    await PreferencesStore.setProfile(username: value);
    await load();
  }

  Future<List<ProfileChartBar>> _buildChartBars(
    List<WorkoutSummary> history,
    ProfileChartMetric metric,
    ProfileChartRange range,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final bucketCount = range == ProfileChartRange.week ? 7 : 10;
    final bucketDays = range == ProfileChartRange.week ? 1 : 3;
    final firstDay = range == ProfileChartRange.week
        ? today.subtract(Duration(days: now.weekday - 1))
        : DateTime(now.year, now.month);
    final buckets = List.generate(bucketCount, (index) {
      final start = firstDay.add(Duration(days: index * bucketDays));
      return ProfileChartBar(
        label: _bucketLabel(start, bucketDays),
        start: start,
        end: start.add(Duration(days: bucketDays - 1)),
        value: 0,
      );
    });

    for (final workout in history) {
      final workoutDay = DateTime(workout.startTime.year, workout.startTime.month, workout.startTime.day);
      final offset = workoutDay.difference(firstDay).inDays;
      if (offset < 0) continue;
      var index = offset ~/ bucketDays;
      if (range == ProfileChartRange.month &&
          workoutDay.year == firstDay.year &&
          workoutDay.month == firstDay.month &&
          index >= bucketCount) {
        index = bucketCount - 1;
      }
      if (index < 0 || index >= buckets.length) continue;
      final value = await _valueForWorkout(workout, metric);
      final current = buckets[index];
      buckets[index] = current.copyWith(value: current.value + value);
    }
    return buckets;
  }

  Future<double> _valueForWorkout(WorkoutSummary workout, ProfileChartMetric metric) async {
    switch (metric) {
      case ProfileChartMetric.duration:
        return workout.endTime.difference(workout.startTime).inMinutes.toDouble();
      case ProfileChartMetric.volume:
        return workout.volume;
      case ProfileChartMetric.reps:
        final detail = await _workoutRepository.getWorkoutDetail(workout.id);
        var reps = 0;
        for (final exercise in detail.exercises) {
          for (final set in exercise.sets) {
            if (set.isCompleted) reps += set.reps ?? 0;
          }
        }
        return reps.toDouble();
    }
  }

  String _bucketLabel(DateTime start, int bucketDays) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (bucketDays == 1) return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][start.weekday - 1];
    final daysInMonth = DateTime(start.year, start.month + 1, 0).day;
    final endDay = (start.day + bucketDays - 1).clamp(1, daysInMonth);
    return '${months[start.month - 1]} ${start.day}-$endDay';
  }
}

enum ProfileChartMetric { duration, volume, reps }

enum ProfileChartRange { week, month }

class ProfileChartBar extends Equatable {
  final String label;
  final DateTime start;
  final DateTime end;
  final double value;

  const ProfileChartBar({
    required this.label,
    required this.start,
    required this.end,
    required this.value,
  });

  ProfileChartBar copyWith({double? value}) {
    return ProfileChartBar(
      label: label,
      start: start,
      end: end,
      value: value ?? this.value,
    );
  }

  @override
  List<Object?> get props => [label, start, end, value];
}

class ProfileState extends Equatable {
  final bool isLoading;
  final String username;
  final String initials;
  final int totalWorkouts;
  final ProfileChartMetric chartMetric;
  final ProfileChartRange chartRange;
  final List<ProfileChartBar> chartBars;

  const ProfileState({
    this.isLoading = false,
    this.username = 'Alex',
    this.initials = 'A',
    this.totalWorkouts = 0,
    this.chartMetric = ProfileChartMetric.volume,
    this.chartRange = ProfileChartRange.week,
    this.chartBars = const [],
  });

  ProfileState copyWith({
    bool? isLoading,
    String? username,
    String? initials,
    int? totalWorkouts,
    ProfileChartMetric? chartMetric,
    ProfileChartRange? chartRange,
    List<ProfileChartBar>? chartBars,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      username: username ?? this.username,
      initials: initials ?? this.initials,
      totalWorkouts: totalWorkouts ?? this.totalWorkouts,
      chartMetric: chartMetric ?? this.chartMetric,
      chartRange: chartRange ?? this.chartRange,
      chartBars: chartBars ?? this.chartBars,
    );
  }

  @override
  List<Object?> get props => [isLoading, username, initials, totalWorkouts, chartMetric, chartRange, chartBars];
}
