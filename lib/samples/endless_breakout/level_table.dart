import 'package:flutter_flame_samples/samples/endless_breakout/breakout_config.dart';

/// Difficulty parameters for one level.
class LevelSettings {
  /// Creates level settings.
  const new({
    required this.level,
    required this.descentInterval,
    required this.ballSpeedMultiplier,
    required this.emptyChance,
    required this.hardChance,
    required this.tripleHardChance,
    required this.explosiveChance,
  });

  /// 1-based level number.
  final int level;

  /// Seconds between board descents.
  final double descentInterval;

  /// Ball speed relative to [breakoutBaseBallSpeed].
  final double ballSpeedMultiplier;

  /// Probability that a generated cell is empty.
  final double emptyChance;

  /// Probability that a generated brick is hard.
  final double hardChance;

  /// Probability that a hard brick has 3 durability instead of 2.
  final double tripleHardChance;

  /// Probability that a generated brick is explosive.
  final double explosiveChance;
}

/// Probability that a generated row contains one item brick.
const double breakoutItemRowChance = 0.5;

/// Level table from the spec. The last entry applies to every later level.
const List<LevelSettings> breakoutLevels = [
  LevelSettings(
    level: 1,
    descentInterval: 10,
    ballSpeedMultiplier: 1,
    emptyChance: 0.3,
    hardChance: 0,
    tripleHardChance: 0,
    explosiveChance: 0,
  ),
  LevelSettings(
    level: 2,
    descentInterval: 9,
    ballSpeedMultiplier: 1.1,
    emptyChance: 0.3,
    hardChance: 0.15,
    tripleHardChance: 0,
    explosiveChance: 0,
  ),
  LevelSettings(
    level: 3,
    descentInterval: 8,
    ballSpeedMultiplier: 1.2,
    emptyChance: 0.3,
    hardChance: 0.2,
    tripleHardChance: 0.25,
    explosiveChance: 0.05,
  ),
  LevelSettings(
    level: 4,
    descentInterval: 7,
    ballSpeedMultiplier: 1.3,
    emptyChance: 0.3,
    hardChance: 0.35,
    tripleHardChance: 0.4,
    explosiveChance: 0.06,
  ),
  LevelSettings(
    level: 5,
    descentInterval: 6,
    ballSpeedMultiplier: 1.4,
    emptyChance: 0.15,
    hardChance: 0.4,
    tripleHardChance: 0.5,
    explosiveChance: 0.06,
  ),
  LevelSettings(
    level: 6,
    descentInterval: 5,
    ballSpeedMultiplier: 1.5,
    emptyChance: 0.15,
    hardChance: 0.6,
    tripleHardChance: 0.6,
    explosiveChance: 0.07,
  ),
];

/// Highest level with distinct settings.
int get breakoutMaxLevel => breakoutLevels.length;

/// Returns the level reached after [elapsedSeconds] of play.
int levelForElapsed(double elapsedSeconds) {
  if (elapsedSeconds < 0) {
    throw ArgumentError.value(elapsedSeconds, 'elapsedSeconds', 'negative');
  }
  final level = 1 + (elapsedSeconds / breakoutSecondsPerLevel).floor();
  return level > breakoutMaxLevel ? breakoutMaxLevel : level;
}

/// Returns the settings for [level] (1-based, capped at [breakoutMaxLevel]).
LevelSettings levelSettingsFor(int level) {
  if (level < 1) {
    throw ArgumentError.value(level, 'level', 'must be >= 1');
  }
  final capped = level > breakoutMaxLevel ? breakoutMaxLevel : level;
  return breakoutLevels[capped - 1];
}
