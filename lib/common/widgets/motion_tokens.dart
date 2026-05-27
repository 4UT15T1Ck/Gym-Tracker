import 'package:flutter/material.dart';

class MotionTokens {
  const MotionTokens._();

  static const Duration fast = Duration(milliseconds: 140);
  static const Duration base = Duration(milliseconds: 220);
  static const Duration emphasis = Duration(milliseconds: 320);
  static const Duration successPulse = Duration(milliseconds: 700);

  static const Curve standardCurve = Curves.easeOutCubic;

  static const double pressScale = 0.97;

  static bool reduceMotion(BuildContext context) {
    return MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  }

  static Duration resolve(BuildContext context, Duration value) {
    return reduceMotion(context) ? Duration.zero : value;
  }
}
