import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Logical width of the fixed-resolution playfield.
const double basicMovementWorldWidth = 800;

/// Logical height of the fixed-resolution playfield.
const double basicMovementWorldHeight = 600;

/// Movement speed in world units per second.
const double basicMovementSpeed = 220;

/// Flame sample that moves a circle with keyboard and pointer input.
class BasicMovementGame extends FlameGame with HasKeyboardHandlerComponents {
  /// Creates the basic movement sample game.
  new({BasicMovementPlayer? player})
    : player = player ?? BasicMovementPlayer(),
      super(
        camera: CameraComponent.withFixedResolution(
          width: basicMovementWorldWidth,
          height: basicMovementWorldHeight,
        ),
      );

  /// Controllable player circle.
  final BasicMovementPlayer player;

  @override
  Color backgroundColor() => const Color(0xFF1B1B2F);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.anchor = Anchor.topLeft;
    world
      ..add(BasicMovementPlayfield(player: player))
      ..add(player);
  }
}

/// Full-screen hit target that moves [player] to tap/drag positions.
class BasicMovementPlayfield extends RectangleComponent
    with TapCallbacks, DragCallbacks {
  /// Creates a playfield bound to [player].
  new({required this.player})
    : super(
        size: Vector2(basicMovementWorldWidth, basicMovementWorldHeight),
        paint: Paint()..color = const Color(0xFF16213E),
      );

  /// Player controlled by this playfield.
  final BasicMovementPlayer player;

  @override
  void onTapUp(TapUpEvent event) {
    player.moveToward(event.localPosition);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    player.moveToward(event.localEndPosition);
  }
}

/// Player circle controlled by keyboard and playfield pointer events.
class BasicMovementPlayer extends CircleComponent with KeyboardHandler {
  /// Creates a player at the center of the playfield.
  new({Vector2? position, this.speed = basicMovementSpeed})
    : super(
        radius: 24,
        position:
            position ??
            Vector2(basicMovementWorldWidth / 2, basicMovementWorldHeight / 2),
        anchor: Anchor.center,
        paint: Paint()..color = const Color(0xFF4CC9F0),
      );

  /// Movement speed in world units per second.
  final double speed;

  Vector2 _direction = Vector2.zero();
  Vector2? _pointerTarget;

  /// Current keyboard direction (normalized or zero).
  Vector2 get direction => _direction.clone();

  /// Active pointer follow target, if any.
  Vector2? get pointerTarget => _pointerTarget?.clone();

  /// Sets a world-space point for the player to move toward.
  void moveToward(Vector2 target) {
    _pointerTarget = target.clone();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_pointerTarget != null) {
      final toTarget = _pointerTarget! - position;
      if (toTarget.length <= speed * dt) {
        position.setFrom(_pointerTarget!);
        _pointerTarget = null;
        _direction = Vector2.zero();
      } else {
        _direction = toTarget.normalized();
        position += _direction * speed * dt;
      }
    } else if (!_direction.isZero()) {
      position += _direction.normalized() * speed * dt;
    }

    position.clamp(
      Vector2(radius, radius),
      Vector2(
        basicMovementWorldWidth - radius,
        basicMovementWorldHeight - radius,
      ),
    );
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _pointerTarget = null;
    final x =
        (keysPressed.contains(LogicalKeyboardKey.arrowRight) ||
                keysPressed.contains(LogicalKeyboardKey.keyD)
            ? 1.0
            : 0.0) -
        (keysPressed.contains(LogicalKeyboardKey.arrowLeft) ||
                keysPressed.contains(LogicalKeyboardKey.keyA)
            ? 1.0
            : 0.0);
    final y =
        (keysPressed.contains(LogicalKeyboardKey.arrowDown) ||
                keysPressed.contains(LogicalKeyboardKey.keyS)
            ? 1.0
            : 0.0) -
        (keysPressed.contains(LogicalKeyboardKey.arrowUp) ||
                keysPressed.contains(LogicalKeyboardKey.keyW)
            ? 1.0
            : 0.0);
    _direction = Vector2(x, y);
    return true;
  }
}
