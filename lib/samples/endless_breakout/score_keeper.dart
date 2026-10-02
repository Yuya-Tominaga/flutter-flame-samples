import 'dart:math' as math;

import 'package:flutter_flame_samples/samples/endless_breakout/breakout_config.dart';

/// Tracks score and the combo multiplier.
///
/// Brick points are multiplied by the multiplier in effect *before* the brick
/// counts towards the combo. Row / board clear bonuses are not multiplied.
class ScoreKeeper {
  int _score = 0;
  int _combo = 0;

  /// Current score.
  int get score => _score;

  /// Bricks broken since the ball last touched the paddle.
  int get combo => _combo;

  /// Current combo multiplier.
  double get multiplier => math.min(
    breakoutMaxComboMultiplier,
    1 + breakoutComboIncrement * (_combo ~/ breakoutComboStep),
  );

  /// Adds [durabilityPoints] × 10 brick points with the current multiplier.
  ///
  /// When [broke] is true the brick also counts towards the combo.
  /// Returns the points gained.
  int addBrickPoints({required int durabilityPoints, required bool broke}) {
    if (durabilityPoints < 1) {
      throw ArgumentError.value(durabilityPoints, 'durabilityPoints');
    }
    final gained = (durabilityPoints * breakoutPointsPerDurability * multiplier)
        .round();
    _score += gained;
    if (broke) {
      _combo++;
    }
    return gained;
  }

  /// Adds a fixed bonus that ignores the combo multiplier.
  void addBonus(int points) {
    if (points < 0) {
      throw ArgumentError.value(points, 'points');
    }
    _score += points;
  }

  /// Resets the combo when the ball touches the paddle or is lost.
  void resetCombo() => _combo = 0;
}
