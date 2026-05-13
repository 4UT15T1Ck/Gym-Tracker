enum RecoveryStatus { sore, recovering, ready, fresh }

extension RecoveryStatusX on RecoveryStatus {
  String get label {
    switch (this) {
      case RecoveryStatus.sore:
        return 'Sore';
      case RecoveryStatus.recovering:
        return 'Recovering';
      case RecoveryStatus.ready:
        return 'Ready';
      case RecoveryStatus.fresh:
        return 'Fresh';
    }
  }

  int get score {
    switch (this) {
      case RecoveryStatus.sore:
        return 0;
      case RecoveryStatus.recovering:
        return 1;
      case RecoveryStatus.ready:
        return 3;
      case RecoveryStatus.fresh:
        return 4;
    }
  }
}

class MuscleGroupUtils {
  static const groups = ['Chest', 'Back', 'Shoulder', 'Arm', 'Core', 'Leg'];

  // Direct map of every seeded muscle name (lowercased) → group.
  static const _nameToGroup = <String, String>{
    'chest': 'Chest',
    'upper back': 'Back',
    'lower back': 'Back',
    'lats': 'Back',
    'traps': 'Back',
    'shoulders': 'Shoulder',
    'triceps': 'Arm',
    'biceps': 'Arm',
    'forearms': 'Arm',
    'core': 'Core',
    'quadriceps': 'Leg',
    'hamstrings': 'Leg',
    'glutes': 'Leg',
    'calves': 'Leg',
  };

  static String? groupForMuscleName(String muscleName) {
    return _nameToGroup[muscleName.toLowerCase()];
  }

  static RecoveryStatus statusFor(DateTime? lastTrainedAt, DateTime now) {
    if (lastTrainedAt == null) return RecoveryStatus.fresh;
    final hours = now.difference(lastTrainedAt).inHours;
    if (hours < 24) return RecoveryStatus.sore;
    if (hours < 48) return RecoveryStatus.recovering;
    if (hours < 72) return RecoveryStatus.ready;
    return RecoveryStatus.fresh;
  }

  static String sinceLabel(DateTime? lastTrainedAt, DateTime now) {
    if (lastTrainedAt == null) return 'No recent training';
    final diff = now.difference(lastTrainedAt);
    if (diff.inHours < 24) return 'Trained ${diff.inHours}h ago';
    return 'Trained ${diff.inDays}d ago';
  }
}
