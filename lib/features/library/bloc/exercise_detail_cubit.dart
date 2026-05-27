import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_tracker/core/repositories/exercise_repository.dart';
import 'package:gym_tracker/core/repositories/repository_models.dart';
import 'package:injectable/injectable.dart';

@injectable
class ExerciseDetailCubit extends Cubit<ExerciseDetailState> {
  final ExerciseRepository _repository;

  ExerciseDetailCubit(this._repository) : super(const ExerciseDetailState());

  Future<void> load(String exerciseId) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final detail = await _repository.getExerciseDetail(exerciseId);
      emit(state.copyWith(isLoading: false, detail: detail));
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: error.toString()));
    }
  }
}

class ExerciseDetailState extends Equatable {
  final bool isLoading;
  final ExerciseDetail? detail;
  final String? errorMessage;

  const ExerciseDetailState({
    this.isLoading = false,
    this.detail,
    this.errorMessage,
  });

  ExerciseDetailState copyWith({
    bool? isLoading,
    ExerciseDetail? detail,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ExerciseDetailState(
      isLoading: isLoading ?? this.isLoading,
      detail: detail ?? this.detail,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, detail, errorMessage];
}
