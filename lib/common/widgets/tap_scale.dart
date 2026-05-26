import 'package:flutter/material.dart';

import 'motion_tokens.dart';

class TapScale extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final double pressedScale;

  const TapScale({
    super.key,
    required this.child,
    this.enabled = true,
    this.pressedScale = MotionTokens.pressScale,
  });

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || MotionTokens.reduceMotion(context)) {
      return widget.child;
    }
    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        curve: MotionTokens.standardCurve,
        duration: MotionTokens.resolve(context, MotionTokens.fast),
        child: widget.child,
      ),
    );
  }
}
