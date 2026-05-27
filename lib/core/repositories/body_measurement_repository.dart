import 'package:gym_tracker/core/models/body_measure_entry_model.dart';

abstract class BodyMeasurementRepository {
  Future<List<BodyMeasureEntry>> getEntries();

  Future<BodyMeasureEntry?> getLatestEntry();

  Future<BodyMeasureEntry> addEntry({
    required DateTime date,
    double? weight,
    double? bodyFatPercent,
    Map<String, double> customMeasurements,
  });

  Future<void> deleteEntry(String id);
}
