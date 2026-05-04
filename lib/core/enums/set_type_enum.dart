enum SetType { warmUp, working, dropSet, amrap, failure }

extension SetTypeX on SetType {
  String get dbValue {
    switch (this) {
      case SetType.warmUp:
        return 'warm_up';
      case SetType.working:
        return 'working';
      case SetType.dropSet:
        return 'drop_set';
      case SetType.amrap:
        return 'amrap';
      case SetType.failure:
        return 'failure';
    }
  }

  String get displayName {
    switch (this) {
      case SetType.warmUp:
        return 'Warm-up';
      case SetType.working:
        return 'Working';
      case SetType.dropSet:
        return 'Drop Set';
      case SetType.amrap:
        return 'AMRAP';
      case SetType.failure:
        return 'Failure';
    }
  }
}

SetType setTypeFromDbValue(String? value) {
  if (value == null) {
    return SetType.working;
  }

  return SetType.values.firstWhere(
    (setType) => setType.dbValue == value,
    orElse: () => SetType.working,
  );
}
