import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_flame_samples/samples/basic_movement/basic_movement_game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BasicMovementPlayer', () {
    testWithGame<BasicMovementGame>(
      'moves right when direction is set and clamps at the edge',
      BasicMovementGame.new,
      (game) async {
        final player = game.player;
        final startX = player.position.x;

        player.onKeyEvent(
          const KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.arrowRight,
            logicalKey: LogicalKeyboardKey.arrowRight,
            timeStamp: Duration.zero,
          ),
          {LogicalKeyboardKey.arrowRight},
        );

        game.update(0.5);
        expect(player.position.x, greaterThan(startX));
        expect(
          player.position.x,
          closeTo(startX + basicMovementSpeed * 0.5, 0.01),
        );

        // Drive far enough that clamping must engage.
        for (var i = 0; i < 40; i++) {
          game.update(0.5);
        }
        expect(
          player.position.x,
          closeTo(basicMovementWorldWidth - player.radius, 0.01),
        );
        expect(player.position.y, closeTo(basicMovementWorldHeight / 2, 0.01));
      },
    );

    testWithGame<BasicMovementGame>(
      'moves toward a pointer target',
      BasicMovementGame.new,
      (game) async {
        final player = game.player;
        final target = Vector2(100, 100);
        player.moveToward(target);

        for (var i = 0; i < 40; i++) {
          game.update(0.1);
        }

        expect(player.position.x, closeTo(target.x, 0.5));
        expect(player.position.y, closeTo(target.y, 0.5));
        expect(player.pointerTarget, isNull);
      },
    );
  });
}
