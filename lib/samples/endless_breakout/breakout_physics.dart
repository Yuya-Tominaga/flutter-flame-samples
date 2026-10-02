import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/breakout_config.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/brick_grid.dart';

/// World-space rectangle of the brick drawn in [cell].
Rect brickRect(GridCell cell) {
  final left =
      breakoutBoardSideMargin +
      cell.column * breakoutCellWidth +
      breakoutBrickGap / 2;
  final top = breakoutBoardTop + cell.row * breakoutRowHeight;
  return Rect.fromLTWH(
    left,
    top,
    breakoutCellWidth - breakoutBrickGap,
    breakoutRowHeight - breakoutBrickGap,
  );
}

/// Unit direction after the ball hits the paddle at [hitX].
///
/// The centre sends the ball straight up; the edges tilt it up to
/// [breakoutMaxPaddleAngle] from vertical.
Vector2 paddleBounceDirection({
  required double hitX,
  required double paddleCenterX,
  required double paddleWidth,
}) {
  final offset = ((hitX - paddleCenterX) / (paddleWidth / 2)).clamp(-1.0, 1.0);
  final angle = offset * breakoutMaxPaddleAngle;
  return Vector2(math.sin(angle), -math.cos(angle));
}

/// Returns [direction] normalised and tilted no further than
/// [breakoutMaxTiltAngle] from vertical, keeping its quadrant.
Vector2 clampTilt(Vector2 direction) {
  if (direction.isZero()) {
    throw ArgumentError.value(direction, 'direction', 'must be non-zero');
  }
  final tilt = math.atan2(direction.x.abs(), direction.y.abs());
  if (tilt <= breakoutMaxTiltAngle) {
    return direction.normalized();
  }
  final signX = direction.x < 0 ? -1.0 : 1.0;
  final signY = direction.y < 0 ? -1.0 : 1.0;
  return Vector2(
    signX * math.sin(breakoutMaxTiltAngle),
    signY * math.cos(breakoutMaxTiltAngle),
  );
}

/// Axis along which a ball should bounce off a rectangle.
enum BounceAxis {
  /// Flip the horizontal component.
  horizontal,

  /// Flip the vertical component.
  vertical,
}

/// Overlap between a ball and a rectangle.
typedef BallContact = ({BounceAxis axis, double distanceSquared});

/// Contact between a ball at [center] with [radius] and [rect], or `null`.
///
/// The bounce axis is the one with the smaller penetration depth.
BallContact? ballContact(Vector2 center, double radius, Rect rect) {
  final closestX = center.x.clamp(rect.left, rect.right);
  final closestY = center.y.clamp(rect.top, rect.bottom);
  final dx = center.x - closestX;
  final dy = center.y - closestY;
  final distanceSquared = dx * dx + dy * dy;
  if (distanceSquared >= radius * radius) {
    return null;
  }
  final overlapX = math.min(
    center.x + radius - rect.left,
    rect.right - (center.x - radius),
  );
  final overlapY = math.min(
    center.y + radius - rect.top,
    rect.bottom - (center.y - radius),
  );
  return (
    axis: overlapX < overlapY ? BounceAxis.horizontal : BounceAxis.vertical,
    distanceSquared: distanceSquared,
  );
}

/// Returns [direction] reflected off [rect] along [axis], pointing away from
/// the rectangle's centre.
Vector2 bounceAway(
  Vector2 direction,
  Vector2 center,
  Rect rect,
  BounceAxis axis,
) {
  return switch (axis) {
    BounceAxis.horizontal => Vector2(
      center.x < rect.center.dx ? -direction.x.abs() : direction.x.abs(),
      direction.y,
    ),
    BounceAxis.vertical => Vector2(
      direction.x,
      center.y < rect.center.dy ? -direction.y.abs() : direction.y.abs(),
    ),
  };
}
