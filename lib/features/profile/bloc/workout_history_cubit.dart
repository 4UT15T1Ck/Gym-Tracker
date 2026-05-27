import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_tracker/core/repositories/repository_models.dart';
import 'package:gym_tracker/core/repositories/workout_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class WorkoutHistoryCubit extends Cubit<WorkoutHistoryState> {
  final WorkoutRepository _repository;

  WorkoutHistoryCubit(this._repository) : super(WorkoutHistoryState());

  Future<void> load() async {
    emit(state.copyWith(isLoading: true));
    final workouts = await _repository.getWorkoutHistory(limit: 100);
    emit(state.copyWith(isLoading: false, workouts: workouts));
  }

  void selectDate(DateTime date) {
    emit(state.copyWith(selectedDate: DateTime(date.year, date.month, date.day)));
  }
}

class WorkoutHistoryState extends Equatable {
  final bool isLoading;
  final List<WorkoutSummary> workouts;
  final DateTime selectedDate;

  WorkoutHistoryState({
    this.isLoading = false,
    this.workouts = const [],
    DateTime? selectedDate,
  }) : selectedDate = selectedDate ?? _today();

  List<WorkoutSummary> get selectedWorkouts {
    return workouts.where((workout) {
      final day = DateTime(workout.startTime.year, workout.startTime.month, workout.startTime.day);
      return day == selectedDate;
    }).toList();
  }

  Set<int> get trainedDayKeys {
    return workouts
        .map((workout) => DateTime(workout.startTime.year, workout.startTime.month, workout.startTime.day).millisecondsSinceEpoch)
        .toSet();
  }

  WorkoutHistoryState copyWith({
    bool? isLoading,
    List<WorkoutSummary>? workouts,
    DateTime? selectedDate,
  }) {
    return WorkoutHistoryState(
      isLoading: isLoading ?? this.isLoading,
      workouts: workouts ?? this.workouts,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  List<Object?> get props => [isLoading, workouts, selectedDate];
}
