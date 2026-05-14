import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_tracker/core/repositories/repository_models.dart';
import 'package:gym_tracker/core/repositories/routine_repository.dart';
import 'package:gym_tracker/core/repositories/workout_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class RoutineDetailCubit extends Cubit<RoutineDetailState> {
  final RoutineRepository _routineRepository;
  final WorkoutRepository _workoutRepository;
  String? _routineId;

  RoutineDetailCubit(this._routineRepository, this._workoutRepository) : super(const RoutineDetailState());

  Future<void> load(String routineId) async {
    _routineId = routineId;
    emit(const RoutineDetailState(isLoading: true));
    try {
      final detail = await _routineRepository.getRoutineDetail(routineId);
      emit(RoutineDetailState(isLoading: false, detail: detail));
    } catch (error) {
      emit(RoutineDetailState(isLoading: false, errorMessage: error.toString()));
    }
  }

  Future<void> reload() async {
    final id = _routineId;
    if (id != null) await load(id);
  }

  /// Starts an active workout from the currently loaded routine. Returns workout id or null.
  Future<String?> startWorkoutFromCurrentRoutine() async {
    final detail = state.detail;
    if (detail == null) return null;
    final started = await _workoutRepository.startWorkout(
      name: detail.routine.name,
      routineId: detail.routine.id,
    );
    return started.workout.id;
  }

  Future<void> deleteRoutine() async {
    final id = _routineId;
    if (id == null) return;
    try {
      await _routineRepository.deleteRoutine(id);
    } catch (error) {
      emit(state.copyWith(errorMessage: error.toString()));
    }
  }
}

class RoutineDetailState extends Equatable {
  final bool isLoading;
  final RoutineDetail? detail;
  final String? errorMessage;

  const RoutineDetailState({
    this.isLoading = false,
    this.detail,
    this.errorMessage,
  });

  RoutineDetailState copyWith({
    bool? isLoading,
    RoutineDetail? detail,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RoutineDetailState(
      isLoading: isLoading ?? this.isLoading,
      detail: detail ?? this.detail,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, detail, errorMessage];
}
