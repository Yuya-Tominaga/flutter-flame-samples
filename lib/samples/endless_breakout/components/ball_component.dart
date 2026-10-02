import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/breakout_config.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/components/neon.dart';

/// A ball. Movement and collisions are driven by the game.
class BallComponent extends PositionComponent {
  /// Creates a ball at [position] moving along [direction].
  new({required Vector2 position, Vector2? direction, this.attached = false})
    : direction = direction ?? Vector2(0, -1),
      super(
        position: position,
        size: Vector2.all(breakoutBallRadius * 2),
        anchor: Anchor.center,
      );

  /// Unit vector of the travel direction.
  Vector2 direction;

  /// Whether the ball is waiting on the paddle for a launch tap.
  bool attached;

  /// Whether the pierce effect colours the ball.
  bool piercing = false;

  final Paint _core = Paint()..color = neonWhite;
  final Paint _glow = neonGlow(neonCyan, sigma: 5, alpha: 0.9);
  final Paint _pierceGlow = neonGlow(const Color(0xFFFFB000), sigma: 6);

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    canvas
      ..drawCircle(
        center,
        breakoutBallRadius + 2,
        piercing ? _pierceGlow : _glow,
      )
      ..drawCircle(center, breakoutBallRadius, _core);
  }
}
