import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/breakout_config.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/endless_breakout_game.dart';

/// Full-screen input surface: tap launches, bottom-half drag moves the paddle.
///
/// Drags move the paddle by the finger's displacement rather than snapping it
/// under the finger, so the finger never hides the paddle or the ball.
class InputLayer extends PositionComponent
    with TapCallbacks, DragCallbacks, HasGameReference<EndlessBreakoutGame> {
  /// Creates the input layer covering the playfield.
  new() : super(size: Vector2(breakoutWorldWidth, breakoutWorldHeight));

  final Set<int> _paddlePointers = {};

  @override
  void onTapUp(TapUpEvent event) {
    game.launchBall();
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (event.localPosition.y >= breakoutDragZoneTop) {
      _paddlePointers.add(event.pointerId);
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (_paddlePointers.contains(event.pointerId)) {
      game.movePaddleBy(event.localDelta.x);
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _paddlePointers.remove(event.pointerId);
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _paddlePointers.remove(event.pointerId);
  }
}
