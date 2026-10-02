import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/breakout_config.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/breakout_items.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/components/neon.dart';

/// Falling item capsule. Movement is driven by the game.
class CapsuleComponent extends PositionComponent {
  /// Creates a capsule for [kind] centred at [position].
  new({required this.kind, required Vector2 position})
    : _label = TextPaint(
        style: TextStyle(
          color: neonWhite,
          fontSize: kind.label.length > 1 ? 8 : 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      super(
        position: position,
        size: Vector2(breakoutCapsuleWidth, breakoutCapsuleHeight),
        anchor: Anchor.center,
      );

  /// Item granted when caught.
  final ItemKind kind;

  final TextPaint _label;
  late final Paint _glow = neonGlow(kind.color);
  late final Paint _fill = Paint()..color = kind.color.withValues(alpha: 0.6);
  late final Paint _stroke = Paint()
    ..color = kind.color
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  /// World-space bounds of the capsule.
  Rect get rect => Rect.fromCenter(
    center: Offset(position.x, position.y),
    width: size.x,
    height: size.y,
  );

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
    _label.render(canvas, kind.label, size / 2, anchor: Anchor.center);
  }
}
