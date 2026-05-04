enum WorkoutStatus { active, completed, cancelled }

extension WorkoutStatusX on WorkoutStatus {
  String get dbValue {
    switch (this) {
      case WorkoutStatus.active:
        return 'active';
      case WorkoutStatus.completed:
        return 'completed';
      case WorkoutStatus.cancelled:
        return 'cancelled';
    }
  }

  String get displayName {
    switch (this) {
      case WorkoutStatus.active:
        return 'Active';
      case WorkoutStatus.completed:
        return 'Completed';
      case WorkoutStatus.cancelled:
        return 'Cancelled';
    }
  }
}

WorkoutStatus workoutStatusFromDbValue(String? value) {
  if (value == null) {
    return WorkoutStatus.active;
  }

  return WorkoutStatus.values.firstWhere(
    (status) => status.dbValue == value,
    orElse: () => WorkoutStatus.active,
  );
}
