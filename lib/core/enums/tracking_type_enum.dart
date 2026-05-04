enum ExerciseTrackingType {
  weightReps,
  repsOnly,
  duration,
  durationDistance,
  weightDuration,
}

extension ExerciseTrackingTypeX on ExerciseTrackingType {
  String get dbValue {
    switch (this) {
      case ExerciseTrackingType.weightReps:
        return 'weight_reps';
      case ExerciseTrackingType.repsOnly:
        return 'reps_only';
      case ExerciseTrackingType.duration:
        return 'duration';
      case ExerciseTrackingType.durationDistance:
        return 'duration_distance';
      case ExerciseTrackingType.weightDuration:
        return 'weight_duration';
    }
  }

  String get displayName {
    switch (this) {
      case ExerciseTrackingType.weightReps:
        return 'Weight + Reps';
      case ExerciseTrackingType.repsOnly:
        return 'Reps Only';
      case ExerciseTrackingType.duration:
        return 'Duration';
      case ExerciseTrackingType.durationDistance:
        return 'Duration + Distance';
      case ExerciseTrackingType.weightDuration:
        return 'Weight + Duration';
    }
  }
}

ExerciseTrackingType trackingTypeFromDbValue(String? value) {
  if (value == null) {
    return ExerciseTrackingType.weightReps;
  }

  return ExerciseTrackingType.values.firstWhere(
    (type) => type.dbValue == value,
    orElse: () => ExerciseTrackingType.weightReps,
  );
}
