import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'motion_tokens.dart';

class SuccessPulseOverlay extends StatefulWidget {
  final String message;
  final IconData icon;
  final Duration duration;

  const SuccessPulseOverlay({
    super.key,
    required this.message,
    required this.icon,
    required this.duration,
  });

  static Future<void> show(
    BuildContext context, {
    String message = 'Done',
    IconData icon = Icons.check_circle_rounded,
    Duration duration = MotionTokens.successPulse,
  }) async {
    if (MotionTokens.reduceMotion(context)) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => SuccessPulseOverlay(
        message: message,
        icon: icon,
        duration: duration,
      ),
    );
    overlay.insert(entry);
    await Future<void>.delayed(duration);
    entry.remove();
  }

  @override
  State<SuccessPulseOverlay> createState() => _SuccessPulseOverlayState();
}

class _SuccessPulseOverlayState extends State<SuccessPulseOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IgnorePointer(
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              final fadeIn = (t / 0.2).clamp(0.0, 1.0);
              final fadeOut = ((1.0 - t) / 0.2).clamp(0.0, 1.0);
              final opacity = t < 0.8 ? fadeIn : fadeOut;
              final pulse = 0.94 + (0.08 * math.sin(t * math.pi));
              return Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: pulse,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(widget.icon, color: scheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            widget.message,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
