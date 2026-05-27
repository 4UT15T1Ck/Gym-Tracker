import 'package:equatable/equatable.dart';
import 'package:gym_tracker/core/enums/workout_status_enum.dart';

class Workout extends Equatable {
  static const String tableName = 'workouts';
  static const String columnId = 'id';
  static const String columnRoutineId = 'routine_id';
  static const String columnName = 'name';
  static const String columnStartTime = 'start_time';
  static const String columnEndTime = 'end_time';
  static const String columnStatus = 'status';
  static const String columnNotes = 'notes';
  static const String columnVolume = 'volume';

  final String id;
  final String? routineId;
  final String name;
  final DateTime startTime;
  final DateTime? endTime;
  final WorkoutStatus status;
  final String? notes;
  final double volume;

  const Workout({
    required this.id,
    this.routineId,
    required this.name,
    required this.startTime,
    this.endTime,
    this.status = WorkoutStatus.active,
    this.notes,
    this.volume = 0.0,
  });

  Map<String, dynamic> toMap() => {
    columnId: id,
    columnRoutineId: routineId,
    columnName: name,
    columnStartTime: startTime.millisecondsSinceEpoch,
    columnEndTime: endTime?.millisecondsSinceEpoch,
    columnStatus: status.dbValue,
    columnNotes: notes,
    columnVolume: volume,
  };

  factory Workout.fromMap(Map<String, dynamic> map) => Workout(
    id: map[columnId] as String,
    routineId: map[columnRoutineId] as String?,
    name: map[columnName] as String,
    startTime: DateTime.fromMillisecondsSinceEpoch(map[columnStartTime] as int),
    endTime: map[columnEndTime] != null
        ? DateTime.fromMillisecondsSinceEpoch(map[columnEndTime] as int)
        : null,
    status: workoutStatusFromDbValue(map[columnStatus] as String?),
    notes: map[columnNotes] as String?,
    volume: _asDouble(map[columnVolume]) ?? 0.0,
  );

  static double? _asDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  @override
  List<Object?> get props => [
        id,
        routineId,
        name,
        startTime,
        endTime,
        status,
        notes,
        volume,
      ];
}
