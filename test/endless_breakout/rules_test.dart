import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/breakout_config.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/breakout_items.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/breakout_physics.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/brick_grid.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/level_table.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/row_generator.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/score_keeper.dart';
import 'package:flutter_test/flutter_test.dart';

List<Brick?> _row(Map<int, BrickKind> bricks) => List<Brick?>.generate(
  breakoutColumns,
  (column) => bricks[column] == null ? null : Brick(bricks[column]!),
);

void main() {
  group('level table', () {
    test('level rises every 60 seconds and caps at 6', () {
      expect(levelForElapsed(0), 1);
      expect(levelForElapsed(59.9), 1);
      expect(levelForElapsed(60), 2);
      expect(levelForElapsed(299.9), 5);
      expect(levelForElapsed(300), 6);
      expect(levelForElapsed(10000), 6);
    });

    test('settings follow the spec table', () {
      expect(
        [for (var l = 1; l <= 7; l++) levelSettingsFor(l).descentInterval],
        [10, 9, 8, 7, 6, 5, 5],
      );
      expect(
        [for (var l = 1; l <= 7; l++) levelSettingsFor(l).ballSpeedMultiplier],
        [1.0, 1.1, 1.2, 1.3, 1.4, 1.5, 1.5],
      );
      expect(levelSettingsFor(1).hardChance, 0);
      expect(levelSettingsFor(2).hardChance, greaterThan(0));
      expect(levelSettingsFor(2).explosiveChance, 0);
      expect(levelSettingsFor(3).explosiveChance, greaterThan(0));
      expect(
        levelSettingsFor(5).emptyChance,
        lessThan(levelSettingsFor(4).emptyChance),
      );
    });

    test('rejects invalid input', () {
      expect(() => levelForElapsed(-1), throwsArgumentError);
      expect(() => levelSettingsFor(0), throwsArgumentError);
    });
  });

  group('ScoreKeeper', () {
    test('multiplier grows by 0.5 every 5 broken bricks up to 4x', () {
      final keeper = ScoreKeeper();
      expect(keeper.multiplier, 1);
      for (var i = 0; i < 5; i++) {
        keeper.addBrickPoints(durabilityPoints: 1, broke: true);
      }
      expect(keeper.score, 50);
      expect(keeper.multiplier, 1.5);
      expect(keeper.addBrickPoints(durabilityPoints: 1, broke: true), 15);

      for (var i = 0; i < 100; i++) {
        keeper.addBrickPoints(durabilityPoints: 1, broke: true);
      }
      expect(keeper.multiplier, breakoutMaxComboMultiplier);
    });

    test('hits that do not break a brick score but do not build combo', () {
      final keeper = ScoreKeeper()
        ..addBrickPoints(durabilityPoints: 1, broke: false);
      expect(keeper.score, 10);
      expect(keeper.combo, 0);
    });

    test('bonuses ignore the multiplier and combo resets', () {
      final keeper = ScoreKeeper();
      for (var i = 0; i < 10; i++) {
        keeper.addBrickPoints(durabilityPoints: 1, broke: true);
      }
      final before = keeper.score;
      keeper.addBonus(breakoutRowClearBonus);
      expect(keeper.score, before + breakoutRowClearBonus);
      keeper.resetCombo();
      expect(keeper.multiplier, 1);
    });
  });

  group('BrickGrid', () {
    test('pushRow inserts at the top and shifts rows down', () {
      final grid = BrickGrid()
        ..pushRow(_row({0: BrickKind.normal}))
        ..pushRow(_row({1: BrickKind.item}));
      expect(grid.brickAt(0, 1)?.kind, BrickKind.item);
      expect(grid.brickAt(1, 0)?.kind, BrickKind.normal);
      expect(grid.lowestOccupiedRow, 1);
    });

    test('reports the deadline once a brick reaches the deadline row', () {
      final grid = BrickGrid();
      for (var i = 0; i < breakoutDeadlineRow; i++) {
        grid.pushRow(_row({7: BrickKind.normal}));
      }
      expect(grid.hasReachedDeadline, isFalse);
      grid.pushRow(_row({7: BrickKind.normal}));
      expect(grid.hasReachedDeadline, isTrue);
    });

    test('removing the lowest bricks trims empty rows', () {
      final grid = BrickGrid()
        ..pushRow(_row({0: BrickKind.normal}))
        ..pushRow(_row({0: BrickKind.normal}))
        ..remove(1, 0);
      expect(grid.lowestOccupiedRow, 0);
      grid.remove(0, 0);
      expect(grid.isEmpty, isTrue);
    });

    test('occupiedNeighbours returns up to 8 surrounding bricks', () {
      final full = {
        for (var c = 0; c < breakoutColumns; c++) c: BrickKind.normal,
      };
      final grid = BrickGrid()
        ..pushRow(_row(full))
        ..pushRow(_row(full))
        ..pushRow(_row(full));
      expect(grid.occupiedNeighbours((row: 1, column: 3)).length, 8);
      expect(grid.occupiedNeighbours((row: 0, column: 0)).length, 3);
    });

    test('only hard bricks may have extra durability', () {
      expect(() => Brick(BrickKind.normal, durability: 2), throwsArgumentError);
      expect(Brick(BrickKind.hard, durability: 3).durability, 3);
    });
  });

  group('RowGenerator', () {
    test('rows always contain a brick and at most one item', () {
      final generator = RowGenerator(math.Random(1));
      for (var level = 1; level <= 6; level++) {
        for (var i = 0; i < 200; i++) {
          final row = generator.generate(levelSettingsFor(level));
          expect(row.length, breakoutColumns);
          expect(row.whereType<Brick>(), isNotEmpty);
          expect(
            row
                .whereType<Brick>()
                .where((b) => b.kind == BrickKind.item)
                .length,
            lessThanOrEqualTo(1),
          );
        }
      }
    });

    test('level 1 has only normal and item bricks', () {
      final generator = RowGenerator(math.Random(2));
      for (var i = 0; i < 300; i++) {
        final kinds = generator
            .generate(levelSettingsFor(1))
            .whereType<Brick>()
            .map((b) => b.kind);
        expect(kinds, everyElement(isIn([BrickKind.normal, BrickKind.item])));
      }
    });

    test(
      'later levels produce hard bricks with 2-3 durability and explosives',
      () {
        final generator = RowGenerator(math.Random(3));
        final bricks = [
          for (var i = 0; i < 300; i++)
            ...generator.generate(levelSettingsFor(6)).whereType<Brick>(),
        ];
        final hard = bricks.where((b) => b.kind == BrickKind.hard);
        expect(hard, isNotEmpty);
        expect(hard.map((b) => b.durability).toSet(), {2, 3});
        expect(bricks.where((b) => b.kind == BrickKind.explosive), isNotEmpty);
      },
    );
  });

  group('physics', () {
    // Vector2 stores Float32 components.
    const tolerance = 1e-6;

    test('paddle centre sends the ball straight up, edges tilt 60 degrees', () {
      final center = paddleBounceDirection(
        hitX: 100,
        paddleCenterX: 100,
        paddleWidth: 72,
      );
      expect(center.x, closeTo(0, tolerance));
      expect(center.y, closeTo(-1, tolerance));

      final edge = paddleBounceDirection(
        hitX: 200,
        paddleCenterX: 100,
        paddleWidth: 72,
      );
      expect(
        math.atan2(edge.x, -edge.y),
        closeTo(breakoutMaxPaddleAngle, tolerance),
      );
    });

    test('clampTilt limits the angle from vertical to 75 degrees', () {
      final clamped = clampTilt(Vector2(-1, 0.01));
      expect(clamped.length, closeTo(1, tolerance));
      expect(clamped.x, lessThan(0));
      expect(clamped.y, greaterThan(0));
      expect(
        math.atan2(clamped.x.abs(), clamped.y.abs()),
        closeTo(breakoutMaxTiltAngle, tolerance),
      );
      final untouched = clampTilt(Vector2(0.3, -1));
      expect(untouched, Vector2(0.3, -1).normalized());
    });

    test('ballContact picks the shallower axis', () {
      const rect = Rect.fromLTWH(0, 0, 40, 18);
      final below = ballContact(Vector2(20, 22), 6, rect);
      expect(below?.axis, BounceAxis.vertical);
      final side = ballContact(Vector2(44, 9), 6, rect);
      expect(side?.axis, BounceAxis.horizontal);
      expect(ballContact(Vector2(20, 40), 6, rect), isNull);
    });
  });

  group('items', () {
    test('timed effects extend when picked up again and expire', () {
      final effects = ActiveEffects()
        ..activate(ItemKind.long)
        ..tick(10)
        ..activate(ItemKind.long);
      expect(effects.remaining(ItemKind.long), closeTo(20, 1e-9));
      expect(effects.tick(19.9), isEmpty);
      expect(effects.tick(0.2), [ItemKind.long]);
      expect(effects.isActive(ItemKind.long), isFalse);
    });

    test('instant items cannot be activated as timed effects', () {
      expect(
        () => ActiveEffects().activate(ItemKind.extraLife),
        throwsArgumentError,
      );
    });

    test('pickItem respects weights and can return every item', () {
      final random = math.Random(4);
      final counts = <ItemKind, int>{};
      for (var i = 0; i < 13000; i++) {
        final kind = pickItem(random);
        counts[kind] = (counts[kind] ?? 0) + 1;
      }
      expect(counts.keys.toSet(), ItemKind.values.toSet());
      expect(counts[ItemKind.long], greaterThan(counts[ItemKind.slow]!));
      expect(counts[ItemKind.slow], greaterThan(counts[ItemKind.extraLife]!));
    });
  });
}
