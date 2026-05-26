import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'motion_tokens.dart';

class AppHaptics {
  const AppHaptics._();

  static Future<void> selection([BuildContext? context]) async {
    if (_isDisabled(context)) return;
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  static Future<void> success([BuildContext? context]) async {
    if (_isDisabled(context)) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  static bool _isDisabled(BuildContext? context) {
    return context != null && MotionTokens.reduceMotion(context);
  }
}
