import 'dart:ui';

import 'package:flutter_flame_samples/samples/endless_breakout/brick_grid.dart';

/// Playfield background.
const Color neonBackground = Color(0xFF07071A);

/// Primary accent (paddle, normal bricks, walls).
const Color neonCyan = Color(0xFF00F5FF);

/// Secondary accent (titles, hard bricks with 3 durability).
const Color neonPink = Color(0xFFFF2E88);

/// Warning colour (deadline, lasers).
const Color neonRed = Color(0xFFFF3B3B);

/// Item brick colour.
const Color neonGreen = Color(0xFF39FF14);

/// Explosive brick colour.
const Color neonPurple = Color(0xFFB026FF);

/// Ball colour.
const Color neonWhite = Color(0xFFF4F7FF);

/// Hard brick colour for [durability] remaining hits.
Color hardBrickColor(int durability) => switch (durability) {
  >= 3 => neonPink,
  2 => const Color(0xFFFF8A00),
  _ => const Color(0xFFFFE600),
};

/// Display colour of [brick].
Color brickColor(Brick brick) => switch (brick.kind) {
  BrickKind.normal => neonCyan,
  BrickKind.hard => hardBrickColor(brick.durability),
  BrickKind.item => neonGreen,
  BrickKind.explosive => neonPurple,
};

/// Blurred paint used to draw a glow behind a shape.
Paint neonGlow(Color color, {double sigma = 4, double alpha = 0.75}) {
  return Paint()
    ..color = color.withValues(alpha: alpha)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma);
}
