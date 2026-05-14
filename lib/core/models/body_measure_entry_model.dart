import 'dart:convert';

class BodyMeasureEntry {
  static const String tableName = 'body_measure_entries';
  static const String columnId = 'id';
  static const String columnDate = 'date';
  static const String columnWeight = 'weight';
  static const String columnBodyFatPercent = 'body_fat_percent';
  static const String columnCustomMeasurementsJson = 'custom_measurements_json';

  final String id;
  final DateTime date;
  final double? weight;
  final double? bodyFatPercent;
  final Map<String, double> customMeasurements;

  const BodyMeasureEntry({
    required this.id,
    required this.date,
    this.weight,
    this.bodyFatPercent,
    this.customMeasurements = const {},
  });

  Map<String, dynamic> toMap() => {
        columnId: id,
        columnDate: date.millisecondsSinceEpoch,
        columnWeight: weight,
        columnBodyFatPercent: bodyFatPercent,
        columnCustomMeasurementsJson: jsonEncode(customMeasurements),
      };

  factory BodyMeasureEntry.fromMap(Map<String, dynamic> map) {
    return BodyMeasureEntry(
      id: map[columnId] as String,
      date: DateTime.fromMillisecondsSinceEpoch(map[columnDate] as int),
      weight: _asDouble(map[columnWeight]),
      bodyFatPercent: _asDouble(map[columnBodyFatPercent]),
      customMeasurements: _parseCustom(map[columnCustomMeasurementsJson]),
    );
  }

  static Map<String, double> _parseCustom(dynamic rawValue) {
    if (rawValue == null) return const {};
    try {
      final decoded = jsonDecode(rawValue.toString());
      if (decoded is Map) {
        return decoded.map(
          (key, value) => MapEntry(key.toString(), _asDouble(value) ?? 0),
        );
      }
    } on FormatException {
      return const {};
    }
    return const {};
  }

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
