import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_tracker/core/models/body_measure_entry_model.dart';
import 'package:gym_tracker/core/repositories/body_measurement_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class MeasuresCubit extends Cubit<MeasuresState> {
  final BodyMeasurementRepository _repository;

  MeasuresCubit(this._repository) : super(const MeasuresState());

  Future<void> load() async {
    emit(state.copyWith(isLoading: true));
    final entries = await _repository.getEntries();
    emit(state.copyWith(isLoading: false, entries: entries));
  }

  Future<void> add({double? weight, double? bodyFat}) async {
    await _repository.addEntry(date: DateTime.now(), weight: weight, bodyFatPercent: bodyFat);
    await load();
  }

  Future<void> delete(String id) async {
    await _repository.deleteEntry(id);
    await load();
  }
}

class MeasuresState extends Equatable {
  final bool isLoading;
  final List<BodyMeasureEntry> entries;

  const MeasuresState({this.isLoading = false, this.entries = const []});

  MeasuresState copyWith({bool? isLoading, List<BodyMeasureEntry>? entries}) {
    return MeasuresState(
      isLoading: isLoading ?? this.isLoading,
      entries: entries ?? this.entries,
    );
  }

  @override
  List<Object?> get props => [isLoading, entries];
}
