import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/breakout_config.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/components/neon.dart';

/// Laser bolt fired by the paddle. [position] is the tip of the bolt.
class LaserBoltComponent extends PositionComponent {
  /// Creates a bolt whose tip is at [position].
  new({required Vector2 position})
    : super(
        position: position,
        size: Vector2(breakoutLaserWidth, breakoutLaserHeight),
        anchor: Anchor.topCenter,
      );

  static final Paint _core = Paint()..color = const Color(0xFFFFD0D0);
  static final Paint _glow = neonGlow(neonRed, sigma: 3, alpha: 0.9);

  @override
  void render(Canvas canvas) {
    final rect = size.toRect();
    canvas
      ..drawRect(rect.inflate(1.5), _glow)
      ..drawRect(rect, _core);
  }
}
