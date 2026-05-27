import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_tracker/core/repositories/exercise_repository.dart';
import 'package:gym_tracker/core/repositories/workout_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class MuscleMapCubit extends Cubit<MuscleMapState> {
  final WorkoutRepository _workoutRepository;
  final ExerciseRepository _exerciseRepository;

  MuscleMapCubit(this._workoutRepository, this._exerciseRepository) : super(const MuscleMapState());

  Future<void> load({int? days}) async {
    final selectedDays = days ?? state.days;
    emit(state.copyWith(isLoading: true, days: selectedDays));
    final from = DateTime.now().subtract(Duration(days: selectedDays));

    // 2 queries total — replaces N×M getExerciseDetail calls.
    final muscles = await _exerciseRepository.getMuscles();
    final muscleIdToName = {for (final m in muscles) m.id: m.name};
    final secondaryMap = await _exerciseRepository.getAllSecondaryMuscleIds();

    final history = await _workoutRepository.getWorkoutHistory(limit: 500, from: from);
    final muscleCounts = <String, double>{
      for (final muscle in muscles)
        if (!_isCardio(muscle.name)) muscle.name: 0,
    };

    for (final workout in history) {
      final detail = await _workoutRepository.getWorkoutDetail(workout.id);
      for (final workoutExercise in detail.exercises) {
        final completedSets = workoutExercise.sets.where((s) => s.isCompleted).length;

        // Primary muscle — resolved from ID, no extra query.
        final primaryName = muscleIdToName[workoutExercise.exercise.primaryMuscleId];
        if (primaryName != null) {
          _addCount(muscleCounts, primaryName, completedSets.toDouble());
        }

        // Secondary muscles — resolved from pre-fetched map.
        for (final muscleId in secondaryMap[workoutExercise.exercise.id] ?? <String>[]) {
          final name = muscleIdToName[muscleId];
          if (name != null) {
            _addCount(muscleCounts, name, completedSets * 0.5);
          }
        }
      }
    }
    emit(state.copyWith(isLoading: false, muscleCounts: muscleCounts));
  }

  void _addCount(Map<String, double> muscleCounts, String muscleName, double count) {
    if (count <= 0 || _isCardio(muscleName)) return;
    muscleCounts[muscleName] = (muscleCounts[muscleName] ?? 0) + count;
  }

  bool _isCardio(String muscleName) => muscleName.toLowerCase().contains('cardio');
}

class MuscleMapState extends Equatable {
  final bool isLoading;
  final int days;
  final Map<String, double> muscleCounts;

  const MuscleMapState({
    this.isLoading = false,
    this.days = 7,
    this.muscleCounts = const {},
  });

  MuscleMapState copyWith({
    bool? isLoading,
    int? days,
    Map<String, double>? muscleCounts,
  }) {
    return MuscleMapState(
      isLoading: isLoading ?? this.isLoading,
      days: days ?? this.days,
      muscleCounts: muscleCounts ?? this.muscleCounts,
    );
  }

  @override
  List<Object?> get props => [isLoading, days, muscleCounts];
}
