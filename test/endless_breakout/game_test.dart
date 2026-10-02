import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/breakout_audio.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/breakout_config.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/breakout_items.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/breakout_physics.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/brick_grid.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/endless_breakout_game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

List<Brick?> _row(Map<int, BrickKind> bricks) => List<Brick?>.generate(
  breakoutColumns,
  (column) => bricks[column] == null ? null : Brick(bricks[column]!),
);

double _columnCenter(int column) =>
    brickRect((row: 0, column: column)).center.dx;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('screen flow', () {
    testWithGame<EndlessBreakoutGame>(
      'starts on the title; a new game has 5 rows, 3 lives and a waiting ball',
      createTestGame,
      (game) async {
        expect(game.phase, BreakoutPhase.title);
        expect(
          game.overlays.isActive(EndlessBreakoutGame.titleOverlay),
          isTrue,
        );

        game.startNewGame();

        expect(game.phase, BreakoutPhase.ready);
        expect(game.overlays.activeOverlays, isEmpty);
        expect(game.grid.rowCount, breakoutInitialRows);
        expect(game.lives, breakoutInitialLives);
        expect(game.balls, hasLength(1));
        expect(game.balls.single.attached, isTrue);
      },
    );

    testWithGame<EndlessBreakoutGame>(
      'title sub screens switch overlays',
      createTestGame,
      (game) async {
        game.openHowToPlay();
        expect(game.overlays.activeOverlays, [
          EndlessBreakoutGame.howToPlayOverlay,
        ]);
        game
          ..closeTitleSubScreen()
          ..openSettings();
        expect(game.overlays.activeOverlays, [
          EndlessBreakoutGame.settingsOverlay,
        ]);
        game.startNewGame();
        expect(game.openSettings, throwsStateError);
      },
    );

    testWithGame<EndlessBreakoutGame>(
      'the waiting ball follows the paddle and launches straight up on tap',
      createTestGame,
      (game) async {
        game
          ..startNewGame()
          ..movePaddleBy(-50);
        final ball = game.balls.single;
        expect(ball.position.x, game.paddle.position.x);

        game.launchBall();
        expect(game.phase, BreakoutPhase.playing);
        expect(ball.attached, isFalse);
        expect(ball.direction, Vector2(0, -1));
      },
    );

    testWithGame<EndlessBreakoutGame>(
      'paddle sensitivity scales drag movement',
      createTestGame,
      (game) async {
        await game.setPaddleSensitivity(2);
        game.startNewGame();
        final start = game.paddle.position.x;
        game.movePaddleBy(10);
        expect(game.paddle.position.x, start + 20);
      },
    );
  });

  group('pause', () {
    testWithGame<EndlessBreakoutGame>(
      'pausing freezes the simulation and resuming continues it',
      createTestGame,
      (game) async {
        game
          ..startNewGame()
          ..launchBall();
        run(game, 0.5);
        final elapsed = game.elapsed;
        final ballY = game.balls.single.position.y;

        game.pauseGame();
        expect(game.phase, BreakoutPhase.paused);
        expect(
          game.overlays.isActive(EndlessBreakoutGame.pauseOverlay),
          isTrue,
        );
        run(game, 2);
        expect(game.elapsed, elapsed);
        expect(game.balls.single.position.y, ballY);

        game.resumeGame();
        expect(game.phase, BreakoutPhase.playing);
        expect(
          game.overlays.isActive(EndlessBreakoutGame.pauseOverlay),
          isFalse,
        );
        run(game, 0.1);
        expect(game.elapsed, greaterThan(elapsed));
      },
    );

    testWithGame<EndlessBreakoutGame>(
      'leaving the app pauses automatically',
      createTestGame,
      (game) async {
        game
          ..startNewGame()
          ..lifecycleStateChange(AppLifecycleState.inactive);
        expect(game.phase, BreakoutPhase.paused);
        game.resumeGame();
        expect(game.phase, BreakoutPhase.ready);
      },
    );

    testWithGame<EndlessBreakoutGame>(
      'lifecycle changes on the title do not pause',
      createTestGame,
      (game) async {
        game.lifecycleStateChange(AppLifecycleState.paused);
        expect(game.phase, BreakoutPhase.title);
      },
    );
  });

  group('descent and difficulty', () {
    testWithGame<EndlessBreakoutGame>(
      'a row is added every 10 seconds at level 1',
      createTestGame,
      (game) async {
        game
          ..startNewGame()
          ..launchBall();
        final topBefore = game.grid.brickAt(0, 0);
        runWithAutopilot(game, 9.9);
        expect(game.grid.brickAt(0, 0), same(topBefore));
        runWithAutopilot(game, 0.2);
        expect(game.grid.brickAt(0, 0), isNot(same(topBefore)));
        expect(game.grid.brickAt(1, 0), same(topBefore));
      },
    );

    testWithGame<EndlessBreakoutGame>(
      'the descent timer is frozen while the ball waits on the paddle',
      createTestGame,
      (game) async {
        game.startNewGame();
        run(game, 30);
        expect(game.descentTimer, 0);
        expect(game.grid.rowCount, breakoutInitialRows);
      },
    );

    testWithGame<EndlessBreakoutGame>(
      'level rises after 60 seconds with a banner sound and faster ball',
      createTestGame,
      (game) async {
        final audio = game.audio as RecordingAudio;
        game
          ..startNewGame()
          ..launchBall();
        final baseSpeed = game.ballSpeed;
        game.grid.clear();
        runWithAutopilot(game, 60.1);
        expect(game.level, 2);
        expect(audio.played, contains(BreakoutSound.levelUp));
        expect(game.ballSpeed, closeTo(baseSpeed * 1.1, 1e-9));
      },
    );

    testWithGame<EndlessBreakoutGame>(
      'a brick reaching the deadline ends the game',
      createTestGame,
      (game) async {
        final audio = game.audio as RecordingAudio;
        game.startNewGame();
        game.grid.clear();
        for (var i = 0; i < breakoutDeadlineRow; i++) {
          game.grid.pushRow(_row({7: BrickKind.normal}));
        }
        game.launchBall();
        runWithAutopilot(game, 10.1);

        expect(game.phase, BreakoutPhase.gameOver);
        expect(
          game.overlays.isActive(EndlessBreakoutGame.gameOverOverlay),
          isTrue,
        );
        expect(game.balls, isEmpty);
        expect(audio.played.last, BreakoutSound.gameOver);
      },
    );
  });

  group('lives', () {
    testWithGame<EndlessBreakoutGame>(
      'losing the ball costs a life and waits for a new launch',
      createTestGame,
      (game) async {
        game
          ..startNewGame()
          ..launchBall()
          ..applyItem(ItemKind.long);
        game.balls.single.position.y = breakoutWorldHeight + 20;
        game.update(1 / 60);

        expect(game.lives, breakoutInitialLives - 1);
        expect(game.phase, BreakoutPhase.ready);
        expect(game.balls.single.attached, isTrue);
        expect(game.effects.isActive(ItemKind.long), isFalse);
        expect(game.paddle.size.x, breakoutPaddleWidth);
      },
    );

    testWithGame<EndlessBreakoutGame>(
      'with multi-ball only the last ball falling costs a life',
      createTestGame,
      (game) async {
        game
          ..startNewGame()
          ..launchBall()
          ..applyItem(ItemKind.multiBall);
        expect(game.balls, hasLength(3));

        game.balls[1].position.y = breakoutWorldHeight + 20;
        game.balls[2].position.y = breakoutWorldHeight + 20;
        game.update(1 / 60);
        expect(game.balls, hasLength(1));
        expect(game.lives, breakoutInitialLives);
        expect(game.phase, BreakoutPhase.playing);

        game.balls.single.position.y = breakoutWorldHeight + 20;
        game.update(1 / 60);
        expect(game.lives, breakoutInitialLives - 1);
      },
    );

    testWithGame<EndlessBreakoutGame>(
      'losing every life ends the game and stores the best score',
      createTestGame,
      (game) async {
        game.startNewGame();
        game.grid
          ..clear()
          ..pushRow(_row({0: BrickKind.normal}));
        game.launchBall();
        game.balls.single
          ..position.setValues(_columnCenter(0), 140)
          ..direction = Vector2(0, -1);
        run(game, 0.5);
        expect(
          game.score,
          10 + breakoutRowClearBonus + breakoutBoardClearBonus,
        );

        for (var i = 0; i < breakoutInitialLives; i++) {
          game.launchBall();
          for (final ball in game.balls) {
            ball.position.y = breakoutWorldHeight + 20;
          }
          game.update(1 / 60);
        }

        expect(game.phase, BreakoutPhase.gameOver);
        expect(game.lastScoreWasBest, isTrue);
        expect(game.bestScore.value, game.score);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt('endless_breakout.best_score'), game.score);
      },
    );
  });

  group('bricks and scoring', () {
    testWithGame<EndlessBreakoutGame>(
      'hard bricks take one hit per durability and score 10 per hit',
      createTestGame,
      (game) async {
        game.startNewGame();
        final hard = Brick(BrickKind.hard, durability: 2);
        game.grid
          ..clear()
          ..pushRow([hard, ...List<Brick?>.filled(breakoutColumns - 1, null)]);
        game.launchBall();
        final ball = game.balls.single
          ..position.setValues(_columnCenter(0), 140)
          ..direction = Vector2(0, -1);
        run(game, 0.3);
        expect(hard.durability, 1);
        expect(game.score, 10);

        ball
          ..position.setValues(_columnCenter(0), 140)
          ..direction = Vector2(0, -1);
        run(game, 0.3);
        expect(game.grid.isEmpty, isTrue);
        expect(
          game.score,
          20 + breakoutRowClearBonus + breakoutBoardClearBonus,
        );
      },
    );

    testWithGame<EndlessBreakoutGame>(
      'explosive bricks break their neighbours and award bonuses',
      createTestGame,
      (game) async {
        final audio = game.audio as RecordingAudio;
        game.startNewGame();
        game.grid
          ..clear()
          ..pushRow(_row({0: BrickKind.normal, 2: BrickKind.normal}))
          ..pushRow(
            _row({
              0: BrickKind.normal,
              1: BrickKind.explosive,
              2: BrickKind.normal,
            }),
          )
          ..pushRow(
            _row({
              0: BrickKind.normal,
              1: BrickKind.normal,
              2: BrickKind.normal,
            }),
          );
        game.launchBall();
        game.balls.single
          ..position.setValues(_columnCenter(1), 160)
          ..direction = Vector2(0, -1);
        run(game, 0.3);

        expect(game.grid.isEmpty, isTrue);
        // 8 bricks: 5 at x1 then 3 at x1.5, plus 3 row clears and a board
        // clear.
        expect(
          game.score,
          5 * 10 + 3 * 15 + 3 * breakoutRowClearBonus + breakoutBoardClearBonus,
        );
        expect(game.comboMultiplier, 1.5);
        expect(audio.played, contains(BreakoutSound.explosion));

        runWithAutopilot(game, 3);
        expect(game.comboMultiplier, 1);
        expect(audio.played, contains(BreakoutSound.paddle));
      },
    );
  });

  group('items', () {
    testWithGame<EndlessBreakoutGame>(
      'long widens the paddle until it expires',
      createTestGame,
      (game) async {
        game
          ..startNewGame()
          ..launchBall()
          ..applyItem(ItemKind.long);
        expect(
          game.paddle.size.x,
          breakoutPaddleWidth * breakoutLongPaddleFactor,
        );
        runWithAutopilot(game, 14.9);
        expect(
          game.paddle.size.x,
          breakoutPaddleWidth * breakoutLongPaddleFactor,
        );
        runWithAutopilot(game, 0.2);
        expect(game.paddle.size.x, breakoutPaddleWidth);
      },
    );

    testWithGame<EndlessBreakoutGame>(
      'slow reduces the ball speed',
      createTestGame,
      (game) async {
        game
          ..startNewGame()
          ..launchBall();
        final normal = game.ballSpeed;
        game.applyItem(ItemKind.slow);
        expect(game.ballSpeed, closeTo(normal * breakoutSlowFactor, 1e-9));
      },
    );

    testWithGame<EndlessBreakoutGame>(
      'pierce smashes through a column without bouncing',
      createTestGame,
      (game) async {
        game
          ..startNewGame()
          ..launchBall()
          ..applyItem(ItemKind.pierce);
        final ball = game.balls.single..position.x = _columnCenter(1);
        expect(ball.piercing, isTrue);
        // Long enough to reach row 0, short enough to not touch the ceiling.
        run(game, 1.9);

        expect(ball.direction.y, lessThan(0));
        for (var row = 0; row < breakoutInitialRows; row++) {
          expect(game.grid.brickAt(row, 1), isNull, reason: 'row $row');
          expect(game.grid.brickAt(row, 0), isNotNull);
          expect(game.grid.brickAt(row, 2), isNotNull);
        }
      },
    );

    testWithGame<EndlessBreakoutGame>(
      'laser fires bolts from the paddle that break bricks',
      createTestGame,
      (game) async {
        final audio = game.audio as RecordingAudio;
        game
          ..startNewGame()
          ..launchBall()
          ..applyItem(ItemKind.laser);
        game.balls.single.position.x = _columnCenter(0);
        game.update(1 / 60);
        expect(game.lasers, hasLength(2));
        expect(audio.played, contains(BreakoutSound.laser));

        run(game, 1);
        const bottom = breakoutInitialRows - 1;
        final left =
            (game.paddle.rect.left + 6 - breakoutBoardSideMargin) ~/
            breakoutCellWidth;
        final right =
            (game.paddle.rect.right - 6 - breakoutBoardSideMargin) ~/
            breakoutCellWidth;
        expect(game.grid.brickAt(bottom, left), isNull);
        expect(game.grid.brickAt(bottom, right), isNull);
        expect(game.grid.brickAt(bottom, 7), isNotNull);
      },
    );

    testWithGame<EndlessBreakoutGame>('1UP adds a life', createTestGame, (
      game,
    ) async {
      game
        ..startNewGame()
        ..launchBall()
        ..applyItem(ItemKind.extraLife);
      expect(game.lives, breakoutInitialLives + 1);
    });

    // nextDouble 0.4 puts an item brick in every row and nextInt 0 always
    // picks column 0 and the first item kind (long).
    EndlessBreakoutGame createItemRowGame() =>
        createTestGame(random: FixedRandom(doubleValue: 0.4));

    void breakBottomItemBrick(EndlessBreakoutGame game) {
      game
        ..startNewGame()
        ..launchBall();
      game.balls.single
        ..position.setValues(_columnCenter(0), 200)
        ..direction = Vector2(0, -1);
      run(game, 0.2);
    }

    testWithGame<EndlessBreakoutGame>(
      'item bricks drop a capsule that applies its item when caught',
      createItemRowGame,
      (game) async {
        breakBottomItemBrick(game);
        expect(game.capsules, hasLength(1));
        final capsule = game.capsules.single;
        expect(capsule.kind, ItemKind.long);

        capsule.position.y = breakoutPaddleTop - 10;
        game.paddle.position.x = capsule.position.x;
        run(game, 0.2);
        expect(game.capsules, isEmpty);
        expect(game.effects.isActive(ItemKind.long), isTrue);
      },
    );

    testWithGame<EndlessBreakoutGame>(
      'missed capsules vanish without effect',
      createItemRowGame,
      (game) async {
        breakBottomItemBrick(game);
        game.capsules.single.position.y = breakoutWorldHeight + 10;
        run(game, 0.1);
        expect(game.capsules, isEmpty);
        expect(game.effects.isActive(ItemKind.long), isFalse);
      },
    );
  });

  group('settings', () {
    testWithGame<EndlessBreakoutGame>(
      'disabling sound stops effects from playing and persists',
      createTestGame,
      (game) async {
        final audio = game.audio as RecordingAudio;
        await game.setSoundEnabled(enabled: false);
        game
          ..startNewGame()
          ..launchBall()
          ..applyItem(ItemKind.extraLife);
        expect(audio.played, isEmpty);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('endless_breakout.sound_enabled'), isFalse);
      },
    );

    testWithGame<EndlessBreakoutGame>(
      'best score is loaded from and reset in preferences',
      () {
        SharedPreferences.setMockInitialValues({
          'endless_breakout.best_score': 4321,
        });
        return createTestGame();
      },
      (game) async {
        expect(game.bestScore.value, 4321);
        await game.resetBestScore();
        expect(game.bestScore.value, 0);
      },
    );
  });
}
