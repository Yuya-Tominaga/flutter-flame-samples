import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/breakout_config.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/components/neon.dart';

/// "LEVEL n" banner that pops in, fades out and removes itself.
class LevelBanner extends PositionComponent {
  /// Creates a banner announcing [level].
  new({required int level})
    : _painter = TextPainter(
        text: TextSpan(
          text: 'LEVEL $level',
          style: const TextStyle(
            color: neonGreen,
            fontSize: 40,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            shadows: [Shadow(color: neonGreen, blurRadius: 16)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(),
      super(
        position: Vector2(breakoutWorldWidth / 2, breakoutWorldHeight * 0.42),
        anchor: Anchor.center,
        priority: 20,
      );

  /// Seconds the banner stays on screen.
  static const double lifetime = 1.6;

  final TextPainter _painter;
  double _age = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_age >= lifetime) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final t = (_age / lifetime).clamp(0.0, 1.0);
    final scale = 1 + 0.4 * math.max(0, 1 - t * 5);
    final alpha = t < 0.7 ? 1.0 : (1 - t) / 0.3;
    canvas
      ..save()
      ..scale(scale)
      ..saveLayer(null, Paint()..color = Color.fromRGBO(255, 255, 255, alpha));
    _painter.paint(canvas, Offset(-_painter.width / 2, -_painter.height / 2));
    canvas
      ..restore()
      ..restore();
  }

  @override
  void onRemove() {
    _painter.dispose();
    super.onRemove();
  }
}
