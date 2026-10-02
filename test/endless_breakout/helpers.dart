import 'dart:math';

import 'package:flutter_flame_samples/samples/endless_breakout/breakout_audio.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/endless_breakout_game.dart';

/// Records played sounds instead of using platform audio.
class RecordingAudio implements BreakoutAudio {
  final List<BreakoutSound> played = [];
  bool _loaded = false;

  @override
  Future<void> load() async => _loaded = true;

  @override
  void play(BreakoutSound sound) {
    if (!_loaded) {
      throw StateError('played $sound before load');
    }
    played.add(sound);
  }

  @override
  Future<void> dispose() async {}
}

/// Random source returning fixed values.
///
/// With the defaults every generated row is 8 normal bricks and no item.
class FixedRandom implements Random {
  new({this.doubleValue = 0.99, this.intValue = 0});

  final double doubleValue;
  final int intValue;

  @override
  double nextDouble() => doubleValue;

  @override
  int nextInt(int max) => intValue;

  @override
  bool nextBool() => false;
}

/// Creates a game with deterministic rows and recorded audio.
///
/// Overlays are registered the same way `GameWidget` does, so the game can be
/// driven without a widget tree.
EndlessBreakoutGame createTestGame({Random? random}) {
  final game = EndlessBreakoutGame(
    random: random ?? FixedRandom(),
    audio: RecordingAudio(),
  );
  for (final MapEntry(key: name, value: builder)
      in game.overlayBuilderMap.entries) {
    game.overlays.addEntry(name, (context, _) => builder(context, game));
  }
  return game;
}

/// Advances [game] by [seconds] in [step] increments, keeping the paddle under
/// the first ball so it is never lost.
void runWithAutopilot(
  EndlessBreakoutGame game,
  double seconds, {
  double step = 1 / 60,
}) {
  var remaining = seconds;
  while (remaining > 1e-9) {
    final dt = remaining < step ? remaining : step;
    final balls = game.balls;
    if (balls.isNotEmpty) {
      game.paddle.position.x = balls.first.position.x;
    }
    game.update(dt);
    remaining -= dt;
  }
}

/// Advances [game] by [seconds] in [step] increments without assistance.
void run(EndlessBreakoutGame game, double seconds, {double step = 1 / 60}) {
  var remaining = seconds;
  while (remaining > 1e-9) {
    final dt = remaining < step ? remaining : step;
    game.update(dt);
    remaining -= dt;
  }
}
