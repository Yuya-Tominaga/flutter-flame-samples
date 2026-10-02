import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/breakout_audio.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/breakout_config.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/breakout_items.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/breakout_physics.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/breakout_preferences.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/brick_grid.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/components/ball_component.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/components/board_component.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/components/capsule_component.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/components/hud_component.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/components/input_layer.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/components/laser_bolt_component.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/components/level_banner.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/components/neon.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/components/paddle_component.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/level_table.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/overlays/breakout_overlays.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/row_generator.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/score_keeper.dart';
import 'package:flutter_flame_samples/shared/sample.dart';

/// High-level state of the game.
enum BreakoutPhase {
  /// Title, how-to-play or settings screen.
  title,

  /// Ball waiting on the paddle for a launch tap. Descent timer is frozen.
  ready,

  /// Ball in play.
  playing,

  /// Paused from [ready] or [playing].
  paused,

  /// Game over screen.
  gameOver,
}

/// Endless brick breaker where rows creep down towards a deadline.
class EndlessBreakoutGame extends FlameGame implements HasSampleOverlays {
  /// Creates the game.
  ///
  /// [random] drives row generation and item drops; [audio] plays effects.
  new({math.Random? random, BreakoutAudio? audio})
    : random = random ?? math.Random(),
      audio = audio ?? FlameBreakoutAudio(),
      super(
        camera: CameraComponent.withFixedResolution(
          width: breakoutWorldWidth,
          height: breakoutWorldHeight,
        ),
      );

  /// Overlay name for the title screen.
  static const titleOverlay = 'title';

  /// Overlay name for the how-to-play screen.
  static const howToPlayOverlay = 'howToPlay';

  /// Overlay name for the settings screen.
  static const settingsOverlay = 'settings';

  /// Overlay name for the pause screen.
  static const pauseOverlay = 'pause';

  /// Overlay name for the game over screen.
  static const gameOverOverlay = 'gameOver';

  /// Source of randomness for rows and items.
  final math.Random random;

  /// Sound effect player.
  final BreakoutAudio audio;

  /// Persisted best score and settings. Available after [onLoad].
  late final BreakoutPreferences preferences;

  /// Best score shown on the title and game over screens.
  final ValueNotifier<int> bestScore = ValueNotifier(0);

  /// Brick layout.
  final BrickGrid grid = BrickGrid();

  /// Remaining time of timed item effects.
  final ActiveEffects effects = ActiveEffects();

  /// The paddle.
  final PaddleComponent paddle = PaddleComponent();

  late final RowGenerator _rowGenerator = RowGenerator(random);
  final math.Random _fxRandom = math.Random();
  final List<BallComponent> _balls = [];
  final List<CapsuleComponent> _capsules = [];
  final List<LaserBoltComponent> _lasers = [];

  ScoreKeeper _score = ScoreKeeper();
  BreakoutPhase _phase = BreakoutPhase.title;
  BreakoutPhase _phaseBeforePause = BreakoutPhase.ready;
  int _lives = breakoutInitialLives;
  int _level = 1;
  double _elapsed = 0;
  double _descentTimer = 0;
  double _laserCooldown = 0;
  bool _lastScoreWasBest = false;

  /// Current phase.
  BreakoutPhase get phase => _phase;

  /// Whether a game is running (ball waiting or in play).
  bool get isInPlay =>
      _phase == BreakoutPhase.ready || _phase == BreakoutPhase.playing;

  /// Current score.
  int get score => _score.score;

  /// Current combo multiplier.
  double get comboMultiplier => _score.multiplier;

  /// Remaining lives.
  int get lives => _lives;

  /// Current level.
  int get level => _level;

  /// Seconds of active play in this game.
  double get elapsed => _elapsed;

  /// Seconds accumulated towards the next descent.
  double get descentTimer => _descentTimer;

  /// Whether the last finished game set a new best score.
  bool get lastScoreWasBest => _lastScoreWasBest;

  /// Balls currently on the field.
  List<BallComponent> get balls => List.unmodifiable(_balls);

  /// Capsules currently falling.
  List<CapsuleComponent> get capsules => List.unmodifiable(_capsules);

  /// Laser bolts currently flying.
  List<LaserBoltComponent> get lasers => List.unmodifiable(_lasers);

  /// Ball speed for the current level and effects.
  double get ballSpeed {
    final slow = effects.isActive(ItemKind.slow) ? breakoutSlowFactor : 1.0;
    return breakoutBaseBallSpeed *
        levelSettingsFor(_level).ballSpeedMultiplier *
        slow;
  }

  @override
  Map<String, OverlayWidgetBuilder<FlameGame>> get overlayBuilderMap => {
    titleOverlay: (context, _) => TitleOverlay(game: this),
    howToPlayOverlay: (context, _) => HowToPlayOverlay(game: this),
    settingsOverlay: (context, _) => SettingsOverlay(game: this),
    pauseOverlay: (context, _) => PauseOverlay(game: this),
    gameOverOverlay: (context, _) => GameOverOverlay(game: this),
  };

  @override
  Color backgroundColor() => neonBackground;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.anchor = Anchor.topLeft;
    preferences = await BreakoutPreferences.load();
    bestScore.value = preferences.bestScore;
    await audio.load();
    await world.addAll([
      BoardComponent(grid: grid),
      paddle,
      InputLayer(),
      HudComponent(),
    ]);
    overlays.add(titleOverlay);
  }

  @override
  void onRemove() {
    unawaited(audio.dispose());
    bestScore.dispose();
    super.onRemove();
  }

  @override
  void lifecycleStateChange(AppLifecycleState state) {
    super.lifecycleStateChange(state);
    if (state != AppLifecycleState.resumed) {
      pauseGame();
    }
  }

  @override
  void update(double dt) {
    if (_phase == BreakoutPhase.paused) {
      return;
    }
    final step = math.min(dt, breakoutMaxFrameDelta);
    super.update(step);
    switch (_phase) {
      case BreakoutPhase.ready:
        _keepBallOnPaddle();
      case BreakoutPhase.playing:
        _stepPlaying(step);
      case BreakoutPhase.title:
      case BreakoutPhase.paused:
      case BreakoutPhase.gameOver:
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // Screen flow
  // ---------------------------------------------------------------------------

  /// Starts a fresh game from the title or game over screen.
  void startNewGame() {
    _clearField();
    _score = ScoreKeeper();
    _lives = breakoutInitialLives;
    _level = 1;
    _elapsed = 0;
    _descentTimer = 0;
    _lastScoreWasBest = false;
    for (var i = 0; i < breakoutInitialRows; i++) {
      grid.pushRow(_rowGenerator.generate(levelSettingsFor(1)));
    }
    _spawnAttachedBall();
    _phase = BreakoutPhase.ready;
    overlays.clear();
  }

  /// Returns to the title screen, abandoning any running game.
  void backToTitle() {
    _clearField();
    _phase = BreakoutPhase.title;
    overlays
      ..clear()
      ..add(titleOverlay);
  }

  /// Opens the how-to-play screen from the title.
  void openHowToPlay() => _switchTitleOverlay(howToPlayOverlay);

  /// Opens the settings screen from the title.
  void openSettings() => _switchTitleOverlay(settingsOverlay);

  /// Returns from how-to-play or settings to the title.
  void closeTitleSubScreen() => _switchTitleOverlay(titleOverlay);

  void _switchTitleOverlay(String name) {
    if (_phase != BreakoutPhase.title) {
      throw StateError('Title screens are only available on the title');
    }
    overlays
      ..clear()
      ..add(name);
  }

  /// Pauses a running game. Does nothing outside of play.
  void pauseGame() {
    if (!isInPlay) {
      return;
    }
    _phaseBeforePause = _phase;
    _phase = BreakoutPhase.paused;
    overlays.add(pauseOverlay);
  }

  /// Resumes a paused game.
  void resumeGame() {
    if (_phase != BreakoutPhase.paused) {
      throw StateError('resumeGame called while $_phase');
    }
    _phase = _phaseBeforePause;
    overlays.remove(pauseOverlay);
  }

  // ---------------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------------

  /// Persists the sound effect toggle.
  Future<void> setSoundEnabled({required bool enabled}) =>
      preferences.setSoundEnabled(enabled: enabled);

  /// Persists the paddle sensitivity.
  Future<void> setPaddleSensitivity(double value) =>
      preferences.setPaddleSensitivity(value);

  /// Clears the stored best score.
  Future<void> resetBestScore() async {
    await preferences.resetBestScore();
    bestScore.value = preferences.bestScore;
  }

  // ---------------------------------------------------------------------------
  // Input
  // ---------------------------------------------------------------------------

  /// Launches the waiting ball straight up. Does nothing unless [phase] is
  /// [BreakoutPhase.ready].
  void launchBall() {
    if (_phase != BreakoutPhase.ready) {
      return;
    }
    for (final ball in _balls) {
      ball
        ..attached = false
        ..direction = Vector2(0, -1);
    }
    _phase = BreakoutPhase.playing;
  }

  /// Moves the paddle by a drag displacement of [dx] world units.
  void movePaddleBy(double dx) {
    if (!isInPlay) {
      return;
    }
    paddle.moveBy(dx * preferences.paddleSensitivity);
    if (_phase == BreakoutPhase.ready) {
      _keepBallOnPaddle();
    }
  }

  // ---------------------------------------------------------------------------
  // Simulation
  // ---------------------------------------------------------------------------

  void _stepPlaying(double dt) {
    _elapsed += dt;
    _updateLevel();

    _descentTimer += dt;
    final interval = levelSettingsFor(_level).descentInterval;
    if (_descentTimer >= interval) {
      _descentTimer -= interval;
      _descend();
      if (_phase != BreakoutPhase.playing) {
        return;
      }
    }

    effects.tick(dt).forEach(_onEffectExpired);
    _syncEffectVisuals();
    _fireLasers(dt);

    _stepBalls(dt);
    if (_phase != BreakoutPhase.playing) {
      return;
    }
    _stepCapsules(dt);
    _stepLasers(dt);
  }

  void _updateLevel() {
    final reached = levelForElapsed(_elapsed);
    if (reached > _level) {
      _level = reached;
      _spawn(LevelBanner(level: _level));
      _play(BreakoutSound.levelUp);
    }
  }

  void _descend() {
    grid.pushRow(_rowGenerator.generate(levelSettingsFor(_level)));
    if (grid.hasReachedDeadline) {
      _gameOver();
    }
  }

  void _stepBalls(double dt) {
    final distance = ballSpeed * dt;
    final steps = math.max(1, (distance / (breakoutBallRadius / 2)).ceil());
    final stepDistance = distance / steps;
    for (final ball in List.of(_balls)) {
      for (var i = 0; i < steps; i++) {
        ball.position.addScaled(ball.direction, stepDistance);
        _collideWalls(ball);
        _collidePaddle(ball);
        _collideBricks(ball);
        if (ball.position.y - breakoutBallRadius > breakoutWorldHeight) {
          _balls.remove(ball);
          ball.removeFromParent();
          break;
        }
      }
    }
    if (_balls.isEmpty) {
      _loseLife();
    }
  }

  void _collideWalls(BallComponent ball) {
    final p = ball.position;
    const r = breakoutBallRadius;
    if (p.x - r < 0) {
      p.x = r;
      ball.direction = clampTilt(
        Vector2(ball.direction.x.abs(), ball.direction.y),
      );
    } else if (p.x + r > breakoutWorldWidth) {
      p.x = breakoutWorldWidth - r;
      ball.direction = clampTilt(
        Vector2(-ball.direction.x.abs(), ball.direction.y),
      );
    }
    if (p.y - r < breakoutCeilingY) {
      p.y = breakoutCeilingY + r;
      ball.direction = clampTilt(
        Vector2(ball.direction.x, ball.direction.y.abs()),
      );
    }
  }

  void _collidePaddle(BallComponent ball) {
    if (ball.direction.y <= 0) {
      return;
    }
    final rect = paddle.rect;
    if (ball.position.y > rect.center.dy) {
      return;
    }
    if (ballContact(ball.position, breakoutBallRadius, rect) == null) {
      return;
    }
    ball
      ..direction = paddleBounceDirection(
        hitX: ball.position.x,
        paddleCenterX: paddle.position.x,
        paddleWidth: paddle.size.x,
      )
      ..position.y = rect.top - breakoutBallRadius;
    _score.resetCombo();
    _play(BreakoutSound.paddle);
  }

  void _collideBricks(BallComponent ball) {
    final center = ball.position;
    const r = breakoutBallRadius;
    final minColumn =
        ((center.x - r - breakoutBoardSideMargin) / breakoutCellWidth).floor();
    final maxColumn =
        ((center.x + r - breakoutBoardSideMargin) / breakoutCellWidth).floor();
    final minRow = ((center.y - r - breakoutBoardTop) / breakoutRowHeight)
        .floor();
    final maxRow = ((center.y + r - breakoutBoardTop) / breakoutRowHeight)
        .floor();

    final piercing = effects.isActive(ItemKind.pierce);
    GridCell? nearestCell;
    BallContact? nearestContact;
    for (var row = minRow; row <= maxRow; row++) {
      for (var column = minColumn; column <= maxColumn; column++) {
        if (grid.brickAt(row, column) == null) {
          continue;
        }
        final cell = (row: row, column: column);
        final contact = ballContact(center, r, brickRect(cell));
        if (contact == null) {
          continue;
        }
        if (piercing) {
          _destroyBricks(cell);
        } else if (nearestContact == null ||
            contact.distanceSquared < nearestContact.distanceSquared) {
          nearestCell = cell;
          nearestContact = contact;
        }
      }
    }
    if (nearestCell == null || nearestContact == null) {
      return;
    }
    ball.direction = clampTilt(
      bounceAway(
        ball.direction,
        center,
        brickRect(nearestCell),
        nearestContact.axis,
      ),
    );
    _damageBrick(nearestCell);
  }

  void _damageBrick(GridCell cell) {
    final brick = grid.brickAt(cell.row, cell.column);
    if (brick == null) {
      throw StateError('No brick to damage at $cell');
    }
    if (brick.durability > 1) {
      brick.durability--;
      _score.addBrickPoints(durabilityPoints: 1, broke: false);
      _spawnBurst(brickRect(cell).center, brickColor(brick), count: 4);
      _play(BreakoutSound.brickHit);
      return;
    }
    _destroyBricks(cell);
  }

  /// Destroys the brick at [origin] and anything caught in explosions.
  void _destroyBricks(GridCell origin) {
    final queue = Queue<GridCell>()..add(origin);
    final affectedRows = <int>{};
    var exploded = false;
    while (queue.isNotEmpty) {
      final cell = queue.removeFirst();
      final brick = grid.brickAt(cell.row, cell.column);
      if (brick == null) {
        continue;
      }
      _score.addBrickPoints(durabilityPoints: brick.durability, broke: true);
      grid.remove(cell.row, cell.column);
      affectedRows.add(cell.row);
      final center = brickRect(cell).center;
      _spawnBurst(center, brickColor(brick), count: 10);
      switch (brick.kind) {
        case BrickKind.item:
          _spawnCapsule(Vector2(center.dx, center.dy));
        case BrickKind.explosive:
          exploded = true;
          queue.addAll(grid.occupiedNeighbours(cell));
        case BrickKind.normal:
        case BrickKind.hard:
          break;
      }
    }
    for (final row in affectedRows) {
      if (grid.isRowEmpty(row)) {
        _score.addBonus(breakoutRowClearBonus);
      }
    }
    if (grid.isEmpty) {
      _score.addBonus(breakoutBoardClearBonus);
    }
    _play(exploded ? BreakoutSound.explosion : BreakoutSound.brickBreak);
  }

  void _stepCapsules(double dt) {
    final paddleRect = paddle.rect;
    for (final capsule in List.of(_capsules)) {
      capsule.position.y += breakoutCapsuleSpeed * dt;
      if (capsule.rect.overlaps(paddleRect)) {
        _removeCapsule(capsule);
        applyItem(capsule.kind);
      } else if (capsule.rect.top > breakoutWorldHeight) {
        _removeCapsule(capsule);
      }
    }
  }

  void _removeCapsule(CapsuleComponent capsule) {
    _capsules.remove(capsule);
    capsule.removeFromParent();
  }

  /// Applies the effect of a caught capsule of [kind].
  @visibleForTesting
  void applyItem(ItemKind kind) {
    _play(BreakoutSound.item);
    switch (kind) {
      case ItemKind.long:
        effects.activate(kind);
        paddle.setWidth(breakoutPaddleWidth * breakoutLongPaddleFactor);
      case ItemKind.multiBall:
        _splitBall();
      case ItemKind.slow:
      case ItemKind.pierce:
        effects.activate(kind);
      case ItemKind.laser:
        if (!effects.isActive(kind)) {
          _laserCooldown = 0;
        }
        effects.activate(kind);
      case ItemKind.extraLife:
        _lives++;
    }
    _syncEffectVisuals();
  }

  void _onEffectExpired(ItemKind kind) {
    if (kind == ItemKind.long) {
      paddle.setWidth(breakoutPaddleWidth);
    }
  }

  void _syncEffectVisuals() {
    final piercing = effects.isActive(ItemKind.pierce);
    for (final ball in _balls) {
      ball.piercing = piercing;
    }
    paddle.showCannons = effects.isActive(ItemKind.laser);
  }

  void _splitBall() {
    if (_balls.isEmpty) {
      throw StateError('Multi-ball caught with no ball in play');
    }
    final source = _balls.first;
    for (final angle in [-breakoutMultiBallSpread, breakoutMultiBallSpread]) {
      final direction = clampTilt(source.direction.clone()..rotate(angle));
      final ball = BallComponent(
        position: source.position.clone(),
        direction: direction,
      );
      _balls.add(ball);
      _spawn(ball);
    }
  }

  void _fireLasers(double dt) {
    if (!effects.isActive(ItemKind.laser)) {
      return;
    }
    _laserCooldown -= dt;
    if (_laserCooldown > 0) {
      return;
    }
    _laserCooldown += breakoutLaserInterval;
    final rect = paddle.rect;
    for (final x in [rect.left + 6, rect.right - 6]) {
      final bolt = LaserBoltComponent(position: Vector2(x, rect.top - 6));
      _lasers.add(bolt);
      _spawn(bolt);
    }
    _play(BreakoutSound.laser);
  }

  void _stepLasers(double dt) {
    final distance = breakoutLaserSpeed * dt;
    final steps = math.max(1, (distance / (breakoutRowHeight / 2)).ceil());
    final stepDistance = distance / steps;
    for (final bolt in List.of(_lasers)) {
      for (var i = 0; i < steps; i++) {
        bolt.position.y -= stepDistance;
        final cell = _brickCellAt(bolt.position);
        if (cell != null) {
          _removeLaser(bolt);
          _damageBrick(cell);
          break;
        }
        if (bolt.position.y < breakoutCeilingY) {
          _removeLaser(bolt);
          break;
        }
      }
    }
  }

  void _removeLaser(LaserBoltComponent bolt) {
    _lasers.remove(bolt);
    bolt.removeFromParent();
  }

  GridCell? _brickCellAt(Vector2 point) {
    final column = ((point.x - breakoutBoardSideMargin) / breakoutCellWidth)
        .floor();
    final row = ((point.y - breakoutBoardTop) / breakoutRowHeight).floor();
    if (grid.brickAt(row, column) == null) {
      return null;
    }
    final cell = (row: row, column: column);
    return brickRect(cell).contains(Offset(point.x, point.y)) ? cell : null;
  }

  void _loseLife() {
    _lives--;
    _score.resetCombo();
    effects.clear();
    paddle.setWidth(breakoutPaddleWidth);
    _clearProjectiles();
    if (_lives <= 0) {
      _gameOver();
      return;
    }
    _play(BreakoutSound.lifeLost);
    _spawnAttachedBall();
    _syncEffectVisuals();
    _phase = BreakoutPhase.ready;
  }

  void _gameOver() {
    _phase = BreakoutPhase.gameOver;
    _play(BreakoutSound.gameOver);
    _clearBalls();
    _clearProjectiles();
    effects.clear();
    _lastScoreWasBest = score > bestScore.value;
    if (_lastScoreWasBest) {
      bestScore.value = score;
      unawaited(preferences.setBestScore(score));
    }
    overlays.add(gameOverOverlay);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _spawnAttachedBall() {
    final ball = BallComponent(position: Vector2.zero(), attached: true);
    _balls.add(ball);
    _spawn(ball);
    _keepBallOnPaddle();
  }

  void _keepBallOnPaddle() {
    for (final ball in _balls) {
      if (ball.attached) {
        ball.position.setValues(
          paddle.position.x,
          paddle.position.y - breakoutBallRadius,
        );
      }
    }
  }

  void _spawnCapsule(Vector2 position) {
    final capsule = CapsuleComponent(
      kind: pickItem(random),
      position: position,
    );
    _capsules.add(capsule);
    _spawn(capsule);
  }

  void _spawnBurst(Offset center, Color color, {required int count}) {
    _spawn(
      ParticleSystemComponent(
        position: Vector2(center.dx, center.dy),
        particle: Particle.generate(
          count: count,
          lifespan: 0.45,
          generator: (_) {
            final angle = _fxRandom.nextDouble() * math.pi * 2;
            final speed = 40 + _fxRandom.nextDouble() * 120;
            return AcceleratedParticle(
              speed: Vector2(math.cos(angle), math.sin(angle)) * speed,
              acceleration: Vector2(0, 260),
              child: CircleParticle(radius: 1.6, paint: Paint()..color = color),
            );
          },
        ),
      ),
    );
  }

  /// Adds [component] to the world without waiting for its `onLoad`.
  void _spawn(Component component) {
    final loading = world.add(component);
    if (loading is Future<void>) {
      unawaited(loading);
    }
  }

  void _play(BreakoutSound sound) {
    if (preferences.soundEnabled) {
      audio.play(sound);
    }
  }

  void _clearBalls() {
    for (final ball in _balls) {
      ball.removeFromParent();
    }
    _balls.clear();
  }

  void _clearProjectiles() {
    for (final capsule in _capsules) {
      capsule.removeFromParent();
    }
    _capsules.clear();
    for (final bolt in _lasers) {
      bolt.removeFromParent();
    }
    _lasers.clear();
  }

  void _clearField() {
    _clearBalls();
    _clearProjectiles();
    effects.clear();
    grid.clear();
    paddle.reset();
  }
}
