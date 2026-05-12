import 'package:gym_tracker/core/dao/equipment_dao.dart';
import 'package:gym_tracker/core/dao/exercise_dao.dart';
import 'package:gym_tracker/core/dao/exercise_stats_dao.dart';
import 'package:gym_tracker/core/dao/muscle_dao.dart';
import 'package:gym_tracker/core/enums/tracking_type_enum.dart';
import 'package:gym_tracker/core/models/equipment_model.dart';
import 'package:gym_tracker/core/models/exercise_model.dart';
import 'package:gym_tracker/core/models/muscle_model.dart';
import 'package:gym_tracker/core/models/workout_set_model.dart';
import 'package:gym_tracker/core/repositories/exercise_repository.dart';
import 'package:gym_tracker/core/repositories/repository_models.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: ExerciseRepository)
class ExerciseRepositoryImpl implements ExerciseRepository {
  final ExerciseDao _exerciseDao;
  final MuscleDao _muscleDao;
  final EquipmentDao _equipmentDao;
  final ExerciseStatsDao _exerciseStatsDao;

  ExerciseRepositoryImpl(
    this._exerciseDao,
    this._muscleDao,
    this._equipmentDao,
    this._exerciseStatsDao,
  );

  @override
  Future<List<Exercise>> getExercises({
    String? muscleId,
    String? equipmentId,
    ExerciseTrackingType? trackingType,
    String? query,
  }) async {
    return await _exerciseDao.getFiltered(
      muscleId: muscleId,
      equipmentId: equipmentId,
      trackingType: trackingType,
      query: query,
    );
  }

  @override
  Future<ExerciseDetail> getExerciseDetail(
    String exerciseId, {
    bool includeStats = true,
  }) async {
    final exercise = await _exerciseDao.getById(exerciseId);
    if (exercise == null) {
      throw Exception('Exercise not found: $exerciseId');
    }

    final secondaryMuscleIds = await _exerciseDao.getSecondaryMuscleIds(exerciseId);

    final futures = await Future.wait([
      _muscleDao.getById(exercise.primaryMuscleId),
      _muscleDao.getByIds(secondaryMuscleIds),
      if (exercise.equipmentId != null)
        _equipmentDao.getById(exercise.equipmentId!)
      else
        Future.value(null),
    ]);

    final primaryMuscle = futures[0] as Muscle?;
    final secondaryMuscles = futures[1] as List<Muscle>;
    final equipment = futures[2] as Equipment?;

    if (primaryMuscle == null) {
      throw Exception('Primary muscle not found: ${exercise.primaryMuscleId}');
    }

    ExerciseStats? stats;
    if (includeStats) {
      stats = await _buildExerciseStats(exerciseId);
    }

    return ExerciseDetail(
      exercise: exercise,
      primaryMuscle: primaryMuscle,
      secondaryMuscles: secondaryMuscles,
      equipment: equipment,
      stats: stats,
    );
  }

  @override
  Future<List<Muscle>> getMuscles() async {
    return await _muscleDao.getAll();
  }

  @override
  Future<List<Equipment>> getEquipment() async {
    return await _equipmentDao.getAll();
  }

  Future<ExerciseStats> _buildExerciseStats(String exerciseId) async {
    final results = await Future.wait([
      _exerciseStatsDao.getPersonalBest(exerciseId),
      _exerciseStatsDao.getRecentHistory(exerciseId),
      _exerciseStatsDao.getWeightOverTime(exerciseId),
      _exerciseStatsDao.getVolumeOverTime(exerciseId),
      _exerciseStatsDao.getTotalSessions(exerciseId),
    ]);

    final personalBest = results[0] as WorkoutSet?;
    final recentHistory = results[1] as List<ExerciseHistoryEntry>;
    final weightOverTimeMaps = results[2] as List<Map<String, dynamic>>;
    final volumeOverTimeMaps = results[3] as List<Map<String, dynamic>>;
    final totalSessions = results[4] as int;

    final weightOverTime = weightOverTimeMaps
        .map((map) => (
              date: DateTime.fromMillisecondsSinceEpoch(
                map['start_time'] as int,
              ),
              maxWeight: (map['max_weight'] as num).toDouble(),
            ))
        .toList();

    final volumeOverTime = volumeOverTimeMaps
        .map((map) => (
              date: DateTime.fromMillisecondsSinceEpoch(
                map['start_time'] as int,
              ),
              volume: (map['volume'] as num).toDouble(),
            ))
        .toList();

    return ExerciseStats(
      personalBest: personalBest,
      recentHistory: recentHistory,
      weightOverTime: weightOverTime,
      volumeOverTime: volumeOverTime,
      totalSessions: totalSessions,
    );
  }

}
