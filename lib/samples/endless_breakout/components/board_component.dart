import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/breakout_config.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/breakout_physics.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/brick_grid.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/components/neon.dart';

/// Renders the walls, the deadline and every brick in [grid].
class BoardComponent extends PositionComponent {
  /// Creates a board renderer for [grid].
  new({required this.grid})
    : super(size: Vector2(breakoutWorldWidth, breakoutWorldHeight));

  /// Grid being rendered.
  final BrickGrid grid;

  double _time = 0;

  final Paint _wallPaint = Paint()
    ..color = neonCyan.withValues(alpha: 0.5)
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke;
  final Paint _wallGlow = neonGlow(neonCyan, alpha: 0.35)
    ..strokeWidth = 4
    ..style = PaintingStyle.stroke;
  final Paint _strokePaint = Paint()
    ..strokeWidth = 1.5
    ..style = PaintingStyle.stroke;
  final Paint _fillPaint = Paint();
  final Paint _markPaint = Paint()..color = neonWhite;
  final Map<Color, Paint> _glowCache = {};

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    _renderWalls(canvas);
    _renderDeadline(canvas);
    for (final (cell, brick) in grid.bricks) {
      _renderBrick(canvas, brickRect(cell), brick);
    }
  }

  void _renderWalls(Canvas canvas) {
    final path = Path()
      ..moveTo(1, breakoutWorldHeight)
      ..lineTo(1, breakoutCeilingY)
      ..lineTo(breakoutWorldWidth - 1, breakoutCeilingY)
      ..lineTo(breakoutWorldWidth - 1, breakoutWorldHeight);
    canvas
      ..drawPath(path, _wallGlow)
      ..drawPath(path, _wallPaint);
  }

  void _renderDeadline(Canvas canvas) {
    final rowsLeft = breakoutDeadlineRow - 1 - grid.lowestOccupiedRow;
    final danger = !grid.isEmpty && rowsLeft <= 3;
    final pulse = danger ? 0.55 + 0.45 * math.sin(_time * 10).abs() : 0.45;
    final paint = Paint()
      ..color = neonRed.withValues(alpha: pulse)
      ..strokeWidth = danger ? 2.5 : 1.5;
    const dash = 8.0;
    for (var x = 4.0; x < breakoutWorldWidth - 4; x += dash * 2) {
      canvas.drawLine(
        Offset(x, breakoutDeadlineY),
        Offset(math.min(x + dash, breakoutWorldWidth - 4), breakoutDeadlineY),
        paint,
      );
    }
  }

  void _renderBrick(Canvas canvas, Rect rect, Brick brick) {
    final color = brickColor(brick);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(3));
    final glow = brick.kind == BrickKind.item
        ? neonGlow(
            color,
            sigma: 3,
            alpha: 0.45 + 0.4 * math.sin(_time * 6).abs(),
          )
        : _glowCache.putIfAbsent(
            color,
            () => neonGlow(color, sigma: 3, alpha: 0.45),
          );
    _fillPaint.color = color.withValues(alpha: 0.28);
    _strokePaint.color = color;
    canvas
      ..drawRRect(rrect, glow)
      ..drawRRect(rrect, _fillPaint)
      ..drawRRect(rrect, _strokePaint);

    final center = rect.center;
    switch (brick.kind) {
      case BrickKind.item:
        final diamond = Path()
          ..moveTo(center.dx, center.dy - 4)
          ..lineTo(center.dx + 4, center.dy)
          ..lineTo(center.dx, center.dy + 4)
          ..lineTo(center.dx - 4, center.dy)
          ..close();
        canvas.drawPath(diamond, _markPaint);
      case BrickKind.explosive:
        canvas
          ..drawCircle(center, 4, _markPaint)
          ..drawCircle(center, 2, Paint()..color = neonPurple);
      case BrickKind.normal:
      case BrickKind.hard:
        break;
    }
  }
}
