import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_tracker/core/models/equipment_model.dart';
import 'package:gym_tracker/core/models/exercise_model.dart';
import 'package:gym_tracker/core/models/muscle_model.dart';
import 'package:gym_tracker/core/repositories/exercise_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class ExerciseListCubit extends Cubit<ExerciseListState> {
  final ExerciseRepository _repository;

  ExerciseListCubit(this._repository) : super(const ExerciseListState());

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final muscles = await _repository.getMuscles();
      final equipment = await _repository.getEquipment();
      final exercises = await _repository.getExercises();
      emit(
        state.copyWith(
          isLoading: false,
          muscles: muscles,
          equipment: equipment,
          exercises: exercises,
        ),
      );
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: error.toString()));
    }
  }

  Future<void> search(String query) async {
    emit(state.copyWith(query: query));
    await _reload();
  }

  Future<void> setMuscle(String? id) async {
    emit(state.copyWith(muscleId: id, clearMuscle: id == null));
    await _reload();
  }

  Future<void> setEquipment(String? id) async {
    emit(state.copyWith(equipmentId: id, clearEquipment: id == null));
    await _reload();
  }

  Future<void> _reload() async {
    final exercises = await _repository.getExercises(
      query: state.query.trim().isEmpty ? null : state.query.trim(),
      muscleId: state.muscleId,
      equipmentId: state.equipmentId,
    );
    emit(state.copyWith(exercises: exercises));
  }
}

class ExerciseListState extends Equatable {
  final bool isLoading;
  final String query;
  final String? muscleId;
  final String? equipmentId;
  final List<Exercise> exercises;
  final List<Muscle> muscles;
  final List<Equipment> equipment;
  final String? errorMessage;

  const ExerciseListState({
    this.isLoading = false,
    this.query = '',
    this.muscleId,
    this.equipmentId,
    this.exercises = const [],
    this.muscles = const [],
    this.equipment = const [],
    this.errorMessage,
  });

  ExerciseListState copyWith({
    bool? isLoading,
    String? query,
    String? muscleId,
    String? equipmentId,
    List<Exercise>? exercises,
    List<Muscle>? muscles,
    List<Equipment>? equipment,
    String? errorMessage,
    bool clearMuscle = false,
    bool clearEquipment = false,
    bool clearError = false,
  }) {
    return ExerciseListState(
      isLoading: isLoading ?? this.isLoading,
      query: query ?? this.query,
      muscleId: clearMuscle ? null : muscleId ?? this.muscleId,
      equipmentId: clearEquipment ? null : equipmentId ?? this.equipmentId,
      exercises: exercises ?? this.exercises,
      muscles: muscles ?? this.muscles,
      equipment: equipment ?? this.equipment,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, query, muscleId, equipmentId, exercises, muscles, equipment, errorMessage];
}
