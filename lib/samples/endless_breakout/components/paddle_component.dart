import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/breakout_config.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/components/neon.dart';

/// Player paddle. [position] is the centre of its top edge.
class PaddleComponent extends PositionComponent {
  /// Creates a paddle centred horizontally.
  new()
    : super(
        position: Vector2(breakoutWorldWidth / 2, breakoutPaddleTop),
        size: Vector2(breakoutPaddleWidth, breakoutPaddleHeight),
        anchor: Anchor.topCenter,
      );

  /// Whether laser cannons are drawn on the paddle ends.
  bool showCannons = false;

  final Paint _fill = Paint()..color = neonCyan.withValues(alpha: 0.35);
  final Paint _stroke = Paint()
    ..color = neonCyan
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke;
  final Paint _glow = neonGlow(neonCyan, sigma: 6);
  final Paint _cannon = Paint()..color = neonRed;

  /// World-space bounds of the paddle.
  Rect get rect =>
      Rect.fromLTWH(position.x - size.x / 2, position.y, size.x, size.y);

  /// Moves the paddle horizontally by [dx], keeping it between the walls.
  void moveBy(double dx) {
    position.x = _clampX(position.x + dx);
  }

  /// Changes the paddle width, keeping it between the walls.
  void setWidth(double width) {
    size.x = width;
    position.x = _clampX(position.x);
  }

  /// Restores the initial size and position.
  void reset() {
    showCannons = false;
    size.setValues(breakoutPaddleWidth, breakoutPaddleHeight);
    position.setValues(breakoutWorldWidth / 2, breakoutPaddleTop);
  }

  double _clampX(double x) =>
      x.clamp(size.x / 2, breakoutWorldWidth - size.x / 2);

  @override
  void render(Canvas canvas) {
    final rrect = RRect.fromRectAndRadius(
      size.toRect(),
      Radius.circular(size.y / 2),
    );
    canvas
      ..drawRRect(rrect, _glow)
      ..drawRRect(rrect, _fill)
      ..drawRRect(rrect, _stroke);
    if (showCannons) {
      canvas
        ..drawRect(const Rect.fromLTWH(4, -6, 4, 8), _cannon)
        ..drawRect(Rect.fromLTWH(size.x - 8, -6, 4, 8), _cannon);
    }
  }
}
