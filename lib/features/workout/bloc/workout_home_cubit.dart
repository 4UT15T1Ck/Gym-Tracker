import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_tracker/core/repositories/repository_models.dart';
import 'package:gym_tracker/core/repositories/routine_repository.dart';
import 'package:gym_tracker/core/repositories/workout_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton()
class WorkoutHomeCubit extends Cubit<WorkoutHomeState> {
  final RoutineRepository _routineRepository;
  final WorkoutRepository _workoutRepository;

  WorkoutHomeCubit(this._routineRepository, this._workoutRepository) : super(const WorkoutHomeState());

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final routines = await _routineRepository.getRoutines();
      final details = <RoutineDetail>[];
      for (final routine in routines) {
        details.add(await _routineRepository.getRoutineDetail(routine.id));
      }
      emit(state.copyWith(isLoading: false, routines: details));
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: error.toString()));
    }
  }

  Future<String> startEmptyWorkout() async {
    final detail = await _workoutRepository.startWorkout(name: 'Empty Workout');
    return detail.workout.id;
  }

  Future<String> startRoutine(RoutineDetail routine) async {
    final detail = await _workoutRepository.startWorkout(
      name: routine.routine.name,
      routineId: routine.routine.id,
    );
    if (routine.routine.notes?.trim().isNotEmpty == true) {
      await _workoutRepository.updateWorkoutMeta(
        workoutId: detail.workout.id,
        notes: routine.routine.notes!.trim(),
      );
    }
    return detail.workout.id;
  }

  Future<void> deleteRoutine(String routineId) async {
    try {
      await _routineRepository.deleteRoutine(routineId);
      await load();
    } catch (error) {
      emit(state.copyWith(errorMessage: error.toString()));
    }
  }
}

class WorkoutHomeState extends Equatable {
  final bool isLoading;
  final List<RoutineDetail> routines;
  final String? errorMessage;

  const WorkoutHomeState({
    this.isLoading = false,
    this.routines = const [],
    this.errorMessage,
  });

  WorkoutHomeState copyWith({
    bool? isLoading,
    List<RoutineDetail>? routines,
    String? errorMessage,
    bool clearError = false,
  }) {
    return WorkoutHomeState(
      isLoading: isLoading ?? this.isLoading,
      routines: routines ?? this.routines,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, routines, errorMessage];
}
