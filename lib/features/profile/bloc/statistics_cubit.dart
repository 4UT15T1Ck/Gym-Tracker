import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_tracker/core/repositories/analytics_repository.dart';
import 'package:gym_tracker/core/repositories/exercise_repository.dart';
import 'package:gym_tracker/core/repositories/repository_models.dart';
import 'package:gym_tracker/core/repositories/workout_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class StatisticsCubit extends Cubit<StatisticsState> {
  final WorkoutRepository _workoutRepository;
  final AnalyticsRepository _analyticsRepository;
  final ExerciseRepository _exerciseRepository;

  StatisticsCubit(this._workoutRepository, this._analyticsRepository, this._exerciseRepository)
      : super(const StatisticsState());

  Future<void> load() async {
    emit(state.copyWith(isLoading: true));
    final history = await _workoutRepository.getWorkoutHistory(limit: 500);
    final volumeHistory = await _analyticsRepository.getVolumeHistory(days: 90);

    var totalReps = 0;
    final workoutDetailCache = <String, WorkoutDetail>{};
    for (final workout in history) {
      final detail = workoutDetailCache[workout.id] ??=
          await _workoutRepository.getWorkoutDetail(workout.id);
      for (final exercise in detail.exercises) {
        for (final set in exercise.sets) {
          if (set.isCompleted) totalReps += set.reps ?? 0;
        }
      }
    }

    // Single query replaces the 20-exercise getExerciseDetail loop.
    final prRecords = await _exerciseRepository.getTopPersonalRecords(limit: 20);
    final prs = prRecords
        .where((pr) => pr.weight != null)
        .map((pr) => '${pr.exerciseName}: ${pr.weight!.toStringAsFixed(1)} kg x ${pr.reps ?? '-'}')
        .toList();

    emit(
      state.copyWith(
        isLoading: false,
        totalWorkouts: history.length,
        totalSets: history.fold<int>(0, (sum, workout) => sum + workout.totalSets),
        totalVolume: history.fold<double>(0, (sum, workout) => sum + workout.volume),
        totalReps: totalReps,
        volumeHistory: volumeHistory,
        prs: prs,
      ),
    );
  }
}

class StatisticsState extends Equatable {
  final bool isLoading;
  final int totalWorkouts;
  final int totalSets;
  final int totalReps;
  final double totalVolume;
  final List<({DateTime date, double volume})> volumeHistory;
  final List<String> prs;

  const StatisticsState({
    this.isLoading = false,
    this.totalWorkouts = 0,
    this.totalSets = 0,
    this.totalReps = 0,
    this.totalVolume = 0,
    this.volumeHistory = const [],
    this.prs = const [],
  });

  StatisticsState copyWith({
    bool? isLoading,
    int? totalWorkouts,
    int? totalSets,
    int? totalReps,
    double? totalVolume,
    List<({DateTime date, double volume})>? volumeHistory,
    List<String>? prs,
  }) {
    return StatisticsState(
      isLoading: isLoading ?? this.isLoading,
      totalWorkouts: totalWorkouts ?? this.totalWorkouts,
      totalSets: totalSets ?? this.totalSets,
      totalReps: totalReps ?? this.totalReps,
      totalVolume: totalVolume ?? this.totalVolume,
      volumeHistory: volumeHistory ?? this.volumeHistory,
      prs: prs ?? this.prs,
    );
  }

  @override
  List<Object?> get props => [isLoading, totalWorkouts, totalSets, totalReps, totalVolume, volumeHistory, prs];
}
