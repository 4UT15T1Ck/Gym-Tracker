import 'package:flutter/material.dart';

import 'motion_tokens.dart';

class AnimatedMetricBar extends StatelessWidget {
  final double value;
  final double maxValue;
  final double minHeight;
  final double maxHeight;
  final Color? color;
  final BorderRadiusGeometry borderRadius;

  const AnimatedMetricBar({
    super.key,
    required this.value,
    required this.maxValue,
    this.minHeight = 8,
    this.maxHeight = 130,
    this.color,
    this.borderRadius = const BorderRadius.vertical(top: Radius.circular(4)),
  });

  @override
  Widget build(BuildContext context) {
    final clampedMax = maxValue <= 0 ? 1 : maxValue;
    final ratio = (value / clampedMax).clamp(0.0, 1.0);
    final height = minHeight + ((maxHeight - minHeight) * ratio);
    return AnimatedContainer(
      duration: MotionTokens.resolve(context, MotionTokens.base),
      curve: MotionTokens.standardCurve,
      height: height,
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.primary,
        borderRadius: borderRadius,
      ),
    );
  }
}
