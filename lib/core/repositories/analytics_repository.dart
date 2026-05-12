
abstract class AnalyticsRepository {
  Future<List<({DateTime date, double volume})>> getVolumeHistory({
    int days = 30,
  });

  Future<List<({DateTime weekStart, int count})>> getWorkoutFrequency({
    int weeks = 12,
  });

  Future<Map<String, int>> getMuscleGroupBreakdown({int days = 30});
}
