import 'dart:math';

import 'package:flutter_flame_samples/samples/endless_breakout/breakout_config.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/brick_grid.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/level_table.dart';

/// Generates new brick rows according to the level's tendencies.
class RowGenerator {
  /// Creates a generator drawing from [random].
  new(this.random, {this.columns = breakoutColumns});

  /// Source of randomness.
  final Random random;

  /// Number of cells per row.
  final int columns;

  /// Generates one row for [settings].
  ///
  /// Every row contains at least one brick and at most one item brick.
  List<Brick?> generate(LevelSettings settings) {
    final row = List<Brick?>.generate(columns, (_) => _generateCell(settings));

    if (row.every((brick) => brick == null)) {
      row[random.nextInt(columns)] = Brick(BrickKind.normal);
    }

    if (random.nextDouble() < breakoutItemRowChance) {
      final occupied = [
        for (var column = 0; column < columns; column++)
          if (row[column] != null) column,
      ];
      row[occupied[random.nextInt(occupied.length)]] = Brick(BrickKind.item);
    }

    return row;
  }

  Brick? _generateCell(LevelSettings settings) {
    if (random.nextDouble() < settings.emptyChance) {
      return null;
    }
    final roll = random.nextDouble();
    if (roll < settings.explosiveChance) {
      return Brick(BrickKind.explosive);
    }
    if (roll < settings.explosiveChance + settings.hardChance) {
      final durability = random.nextDouble() < settings.tripleHardChance
          ? 3
          : 2;
      return Brick(BrickKind.hard, durability: durability);
    }
    return Brick(BrickKind.normal);
  }
}
