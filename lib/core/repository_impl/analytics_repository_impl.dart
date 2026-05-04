import 'package:gym_tracker/core/dao/analytics_dao.dart';
import 'package:gym_tracker/core/models/muscle_model.dart';
import 'package:gym_tracker/core/models/workout_model.dart';
import 'package:gym_tracker/core/repositories/analytics_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: AnalyticsRepository)
class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final AnalyticsDao _analyticsDao;

  AnalyticsRepositoryImpl(this._analyticsDao);

  @override
  Future<List<({DateTime date, double volume})>> getVolumeHistory({
    int days = 30,
  }) async {
    final maps = await _analyticsDao.getVolumeHistory(days: days);

    return maps.map((map) => (
      date: DateTime.fromMillisecondsSinceEpoch(map[Workout.columnStartTime] as int),
      volume: (map[Workout.columnVolume] as num).toDouble(),
    )).toList();
  }

  @override
  Future<List<({DateTime weekStart, int count})>> getWorkoutFrequency({
    int weeks = 12,
  }) async {
    const weekMs = 7 * 24 * 60 * 60 * 1000; // 604800000ms = 1 week in UTC

    final maps = await _analyticsDao.getWorkoutFrequency(weeks: weeks, weekMs: weekMs);

    return maps.map((map) {
      final bucket = map['week_bucket'] as int;
      final weekStart = DateTime.fromMillisecondsSinceEpoch(bucket * weekMs);
      return (
        weekStart: weekStart,
        count: map['count'] as int,
      );
    }).toList();
  }

  @override
  Future<Map<String, int>> getMuscleGroupBreakdown({int days = 30}) async {
    final maps = await _analyticsDao.getMuscleGroupBreakdown(days: days);

    // Safe as long as muscle names are unique — true for seeded data,
    // revisit if user-created muscles are added.
    return {for (var map in maps) map[Muscle.columnName] as String: map['set_count'] as int};
  }
}
