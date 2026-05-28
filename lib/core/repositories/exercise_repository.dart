import 'package:gym_tracker/core/enums/tracking_type_enum.dart';
import 'package:gym_tracker/core/models/equipment_model.dart';
import 'package:gym_tracker/core/models/exercise_model.dart';
import 'package:gym_tracker/core/models/muscle_model.dart';
import 'package:gym_tracker/core/repositories/repository_models.dart';

abstract class ExerciseRepository {
  Future<List<Exercise>> getExercises({
    String? muscleId,
    String? equipmentId,
    ExerciseTrackingType? trackingType,
    String? query,
  });

  Future<ExerciseDetail> getExerciseDetail(
    String exerciseId, {
    bool includeStats = true,
  });

  Future<List<Muscle>> getMuscles();

  Future<List<Equipment>> getEquipment();

  /// Returns { exerciseId: [muscleId, ...] } for all exercises.
  Future<Map<String, List<String>>> getAllSecondaryMuscleIds();

  /// Returns the top [limit] personal records across all exercises.
  Future<List<PersonalRecordSummary>> getTopPersonalRecords({int limit = 3});

  Future<Map<String, String>> getPreviousSetLabels(List<String> exerciseIds);
}
