import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_tracker/core/repositories/repository_models.dart';
import 'package:gym_tracker/core/repositories/workout_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class WorkoutDetailCubit extends Cubit<WorkoutDetailState> {
  final WorkoutRepository _repository;

  WorkoutDetailCubit(this._repository) : super(const WorkoutDetailState());

  Future<void> load(String workoutId) async {
    emit(state.copyWith(isLoading: true));
    final detail = await _repository.getWorkoutDetail(workoutId);
    emit(state.copyWith(isLoading: false, detail: detail));
  }
}

class WorkoutDetailState extends Equatable {
  final bool isLoading;
  final WorkoutDetail? detail;

  const WorkoutDetailState({this.isLoading = false, this.detail});

  WorkoutDetailState copyWith({bool? isLoading, WorkoutDetail? detail}) {
    return WorkoutDetailState(
      isLoading: isLoading ?? this.isLoading,
      detail: detail ?? this.detail,
    );
  }

  @override
  List<Object?> get props => [isLoading, detail];
}
