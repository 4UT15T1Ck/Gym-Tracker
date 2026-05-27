import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_tracker/core/data/preferences_store.dart';
import 'package:gym_tracker/core/repositories/workout_repository.dart';
import 'package:gym_tracker/core/services/dashboard_service.dart';
import 'package:injectable/injectable.dart';

@LazySingleton()
class HomeDashboardCubit extends Cubit<HomeDashboardState> {
  final WorkoutRepository _workoutRepository;
  final DashboardService _dashboardService;

  HomeDashboardCubit(
    this._workoutRepository,
    this._dashboardService,
  ) : super(const HomeDashboardState());

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final summary = await _dashboardService.loadSummary();
      emit(
        state.copyWith(
          isLoading: false,
          username: PreferencesStore.username,
          summary: summary,
        ),
      );
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: error.toString()));
    }
  }

  Future<String?> startEmptyWorkout() async {
    try {
      final detail = await _workoutRepository.startWorkout(name: 'Empty Workout');
      await load();
      return detail.workout.id;
    } catch (error) {
      emit(state.copyWith(errorMessage: error.toString()));
      return null;
    }
  }

  Future<String?> startSuggestedRoutine() async {
    try {
      final suggestion = state.summary?.suggestedRoutine;
      if (suggestion == null) return null;
      final detail = await _workoutRepository.startWorkout(
        name: suggestion.name,
        routineId: suggestion.routineId,
      );
      if (suggestion.notes?.trim().isNotEmpty == true) {
        await _workoutRepository.updateWorkoutMeta(
          workoutId: detail.workout.id,
          notes: suggestion.notes!.trim(),
        );
      }
      await load();
      return detail.workout.id;
    } catch (error) {
      emit(state.copyWith(errorMessage: error.toString()));
      return null;
    }
  }
}

class HomeDashboardState extends Equatable {
  final bool isLoading;
  final String username;
  final DashboardSummary? summary;
  final String? errorMessage;

  const HomeDashboardState({
    this.isLoading = false,
    this.username = 'Alex',
    this.summary,
    this.errorMessage,
  });

  HomeDashboardState copyWith({
    bool? isLoading,
    String? username,
    DashboardSummary? summary,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HomeDashboardState(
      isLoading: isLoading ?? this.isLoading,
      username: username ?? this.username,
      summary: summary ?? this.summary,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, username, summary, errorMessage];
}
