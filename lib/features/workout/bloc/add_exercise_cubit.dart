import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_tracker/core/models/equipment_model.dart';
import 'package:gym_tracker/core/models/exercise_model.dart';
import 'package:gym_tracker/core/models/muscle_model.dart';
import 'package:gym_tracker/core/repositories/exercise_repository.dart';
import 'package:gym_tracker/core/repositories/workout_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class AddExerciseCubit extends Cubit<AddExerciseState> {
  final ExerciseRepository _exerciseRepository;
  final WorkoutRepository _workoutRepository;

  AddExerciseCubit(this._exerciseRepository, this._workoutRepository) : super(const AddExerciseState());

  Future<void> load({List<String> initiallySelectedIds = const []}) async {
    emit(state.copyWith(isLoading: true, selectedIds: initiallySelectedIds.toSet(), clearError: true));
    try {
      final muscles = await _exerciseRepository.getMuscles();
      final equipment = await _exerciseRepository.getEquipment();
      final exercises = await _exerciseRepository.getExercises();
      final recent = await _recentExercises(exercises);
      emit(
        state.copyWith(
          isLoading: false,
          exercises: exercises,
          muscles: muscles,
          equipment: equipment,
          recentExercises: recent,
        ),
      );
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: error.toString()));
    }
  }

  Future<void> setQuery(String query) async {
    emit(state.copyWith(query: query));
    await _reloadFiltered();
  }

  Future<void> setMuscle(String? muscleId) async {
    emit(state.copyWith(muscleId: muscleId, clearMuscle: muscleId == null));
    await _reloadFiltered();
  }

  Future<void> setEquipment(String? equipmentId) async {
    emit(state.copyWith(equipmentId: equipmentId, clearEquipment: equipmentId == null));
    await _reloadFiltered();
  }

  void toggle(Exercise exercise, {bool multiSelect = true}) {
    final selected = Set<String>.from(state.selectedIds);
    if (!multiSelect) selected.clear();
    if (selected.contains(exercise.id)) {
      selected.remove(exercise.id);
    } else {
      selected.add(exercise.id);
    }
    emit(state.copyWith(selectedIds: selected));
  }

  List<Exercise> selectedExercises() {
    return state.exercises.where((exercise) => state.selectedIds.contains(exercise.id)).toList();
  }

  Future<void> _reloadFiltered() async {
    final exercises = await _exerciseRepository.getExercises(
      muscleId: state.muscleId,
      equipmentId: state.equipmentId,
      query: state.query.trim().isEmpty ? null : state.query.trim(),
    );
    emit(state.copyWith(exercises: exercises));
  }

  Future<List<Exercise>> _recentExercises(List<Exercise> allExercises) async {
    final history = await _workoutRepository.getWorkoutHistory(limit: 20);
    final ids = <String>[];
    for (final workout in history) {
      final detail = await _workoutRepository.getWorkoutDetail(workout.id);
      for (final exercise in detail.exercises) {
        if (!ids.contains(exercise.exercise.id)) ids.add(exercise.exercise.id);
      }
      if (ids.length >= 10) break;
    }
    return allExercises.where((exercise) => ids.contains(exercise.id)).toList();
  }
}

class AddExerciseState extends Equatable {
  final bool isLoading;
  final List<Exercise> exercises;
  final List<Exercise> recentExercises;
  final List<Muscle> muscles;
  final List<Equipment> equipment;
  final Set<String> selectedIds;
  final String query;
  final String? muscleId;
  final String? equipmentId;
  final String? errorMessage;

  const AddExerciseState({
    this.isLoading = false,
    this.exercises = const [],
    this.recentExercises = const [],
    this.muscles = const [],
    this.equipment = const [],
    this.selectedIds = const {},
    this.query = '',
    this.muscleId,
    this.equipmentId,
    this.errorMessage,
  });

  AddExerciseState copyWith({
    bool? isLoading,
    List<Exercise>? exercises,
    List<Exercise>? recentExercises,
    List<Muscle>? muscles,
    List<Equipment>? equipment,
    Set<String>? selectedIds,
    String? query,
    String? muscleId,
    String? equipmentId,
    String? errorMessage,
    bool clearMuscle = false,
    bool clearEquipment = false,
    bool clearError = false,
  }) {
    return AddExerciseState(
      isLoading: isLoading ?? this.isLoading,
      exercises: exercises ?? this.exercises,
      recentExercises: recentExercises ?? this.recentExercises,
      muscles: muscles ?? this.muscles,
      equipment: equipment ?? this.equipment,
      selectedIds: selectedIds ?? this.selectedIds,
      query: query ?? this.query,
      muscleId: clearMuscle ? null : muscleId ?? this.muscleId,
      equipmentId: clearEquipment ? null : equipmentId ?? this.equipmentId,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        exercises,
        recentExercises,
        muscles,
        equipment,
        selectedIds,
        query,
        muscleId,
        equipmentId,
        errorMessage,
      ];
}
