import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_tracker/core/enums/set_type_enum.dart';
import 'package:gym_tracker/core/models/exercise_model.dart';
import 'package:gym_tracker/core/models/routine_set_model.dart';
import 'package:gym_tracker/core/repositories/repository_models.dart';
import 'package:gym_tracker/core/repositories/routine_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class CreateRoutineCubit extends Cubit<CreateRoutineState> {
  final RoutineRepository _routineRepository;

  CreateRoutineCubit(this._routineRepository) : super(const CreateRoutineState());

  void prepareNew() {
    emit(const CreateRoutineState());
  }

  void prepareEdit(RoutineDetail detail) {
    emit(CreateRoutineState.fromRoutineDetail(detail));
  }

  void updateTitle(String title) => emit(state.copyWith(title: title));

  void updateNotes(String notes) => emit(state.copyWith(notes: notes));

  void addExercises(List<Exercise> exercises) {
    final existingIds = state.exercises.map((item) => item.exercise.id).toSet();
    final additions = exercises
        .where((exercise) => !existingIds.contains(exercise.id))
        .map(
          (exercise) => DraftRoutineExercise(
            exercise: exercise,
            restSeconds: 90,
            sets: const [DraftRoutineSet(setType: SetType.working, targetReps: 10)],
          ),
        )
        .toList();
    emit(state.copyWith(exercises: [...state.exercises, ...additions]));
  }

  void removeExercise(int index) {
    final items = [...state.exercises]..removeAt(index);
    emit(state.copyWith(exercises: items));
  }

  void moveExercise(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= state.exercises.length) return;
    final items = [...state.exercises];
    final item = items.removeAt(index);
    items.insert(target, item);
    emit(state.copyWith(exercises: items));
  }

  void updateRestSeconds(int exerciseIndex, int? seconds) {
    final items = [...state.exercises];
    items[exerciseIndex] = items[exerciseIndex].copyWith(restSeconds: seconds, updateRestSeconds: true);
    emit(state.copyWith(exercises: items));
  }

  void addSet(int exerciseIndex) {
    final items = [...state.exercises];
    final exercise = items[exerciseIndex];
    items[exerciseIndex] = exercise.copyWith(
      sets: [...exercise.sets, const DraftRoutineSet(setType: SetType.working, targetReps: 10)],
    );
    emit(state.copyWith(exercises: items));
  }

  void removeSet(int exerciseIndex, int setIndex) {
    final items = [...state.exercises];
    final exercise = items[exerciseIndex];
    final sets = [...exercise.sets]..removeAt(setIndex);
    items[exerciseIndex] = exercise.copyWith(sets: sets);
    emit(state.copyWith(exercises: items));
  }

  void updateSet({
    required int exerciseIndex,
    required int setIndex,
    SetType? setType,
    double? targetWeight,
    int? targetReps,
    bool clearWeight = false,
    bool clearReps = false,
  }) {
    final items = [...state.exercises];
    final exercise = items[exerciseIndex];
    final sets = [...exercise.sets];
    sets[setIndex] = sets[setIndex].copyWith(
      setType: setType,
      targetWeight: targetWeight,
      targetReps: targetReps,
      clearWeight: clearWeight,
      clearReps: clearReps,
    );
    items[exerciseIndex] = exercise.copyWith(sets: sets);
    emit(state.copyWith(exercises: items));
  }

  Future<void> save() async {
    if (state.title.trim().isEmpty) {
      emit(state.copyWith(errorMessage: 'Routine title is required'));
      return;
    }
    emit(state.copyWith(isSaving: true, clearError: true));
    try {
      final input = _buildRoutineInput();
      final editingId = state.routineIdBeingEdited;
      if (editingId != null) {
        await _routineRepository.updateRoutine(routineId: editingId, input: input);
      } else {
        await _routineRepository.saveRoutine(input);
      }
      emit(state.copyWith(isSaving: false, didSave: true));
    } catch (error) {
      emit(state.copyWith(isSaving: false, errorMessage: error.toString()));
    }
  }

  RoutineInput _buildRoutineInput() {
    final notesTrim = state.notes.trim();
    return RoutineInput(
      name: state.title.trim(),
      notes: notesTrim.isEmpty ? null : notesTrim,
      exercises: state.exercises.indexed.map((entry) {
        final index = entry.$1;
        final item = entry.$2;
        return RoutineExerciseInput(
          exerciseId: item.exercise.id,
          order: index,
          targetRestSeconds: item.restSeconds,
          sets: item.sets.map((set) {
            return RoutineSetInput(
              setType: set.setType,
              targetWeight: set.targetWeight,
              targetReps: set.targetReps,
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}

class CreateRoutineState extends Equatable {
  final String title;
  final String notes;
  final List<DraftRoutineExercise> exercises;
  final String? routineIdBeingEdited;
  final bool isSaving;
  final bool didSave;
  final String? errorMessage;

  const CreateRoutineState({
    this.title = '',
    this.notes = '',
    this.exercises = const [],
    this.routineIdBeingEdited,
    this.isSaving = false,
    this.didSave = false,
    this.errorMessage,
  });

  bool get isEditing => routineIdBeingEdited != null;

  factory CreateRoutineState.fromRoutineDetail(RoutineDetail detail) {
    final exercises = detail.exercises.map((ed) {
      final sets = [...ed.sets]..sort((a, b) => a.order.compareTo(b.order));
      return DraftRoutineExercise(
        exercise: ed.exercise,
        restSeconds: ed.routineExercise.targetRestSeconds,
        sets: sets
            .map(
              (RoutineSet rs) => DraftRoutineSet(
                setType: rs.setType,
                targetWeight: rs.targetWeight,
                targetReps: rs.targetReps,
              ),
            )
            .toList(),
      );
    }).toList();
    return CreateRoutineState(
      title: detail.routine.name,
      notes: detail.routine.notes ?? '',
      exercises: exercises,
      routineIdBeingEdited: detail.routine.id,
    );
  }

  CreateRoutineState copyWith({
    String? title,
    String? notes,
    List<DraftRoutineExercise>? exercises,
    String? routineIdBeingEdited,
    bool? isSaving,
    bool? didSave,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CreateRoutineState(
      title: title ?? this.title,
      notes: notes ?? this.notes,
      exercises: exercises ?? this.exercises,
      routineIdBeingEdited: routineIdBeingEdited ?? this.routineIdBeingEdited,
      isSaving: isSaving ?? this.isSaving,
      didSave: didSave ?? this.didSave,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [title, notes, exercises, routineIdBeingEdited, isSaving, didSave, errorMessage];
}

class DraftRoutineExercise extends Equatable {
  final Exercise exercise;
  final int? restSeconds;
  final List<DraftRoutineSet> sets;

  const DraftRoutineExercise({
    required this.exercise,
    required this.restSeconds,
    required this.sets,
  });

  DraftRoutineExercise copyWith({
    List<DraftRoutineSet>? sets,
    int? restSeconds,
    bool updateRestSeconds = false,
  }) {
    return DraftRoutineExercise(
      exercise: exercise,
      restSeconds: updateRestSeconds ? restSeconds : this.restSeconds,
      sets: sets ?? this.sets,
    );
  }

  @override
  List<Object?> get props => [exercise, restSeconds, sets];
}

class DraftRoutineSet extends Equatable {
  final SetType setType;
  final double? targetWeight;
  final int? targetReps;

  const DraftRoutineSet({
    required this.setType,
    this.targetWeight,
    this.targetReps,
  });

  DraftRoutineSet copyWith({
    SetType? setType,
    double? targetWeight,
    int? targetReps,
    bool clearWeight = false,
    bool clearReps = false,
  }) {
    return DraftRoutineSet(
      setType: setType ?? this.setType,
      targetWeight: clearWeight ? null : targetWeight ?? this.targetWeight,
      targetReps: clearReps ? null : targetReps ?? this.targetReps,
    );
  }

  @override
  List<Object?> get props => [setType, targetWeight, targetReps];
}
