import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/breakout_config.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/components/neon.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/endless_breakout_game.dart';

/// Score, combo, level and lives across the top band, plus the pause button.
class HudComponent extends PositionComponent
    with HasGameReference<EndlessBreakoutGame> {
  /// Creates the HUD.
  new()
    : super(size: Vector2(breakoutWorldWidth, breakoutHudHeight), priority: 10);

  static TextPaint _style(Color color, double fontSize) => TextPaint(
    style: TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.2,
      shadows: [Shadow(color: color, blurRadius: 8)],
    ),
  );

  late final TextComponent _score = TextComponent(
    position: Vector2(10, 8),
    textRenderer: _style(neonCyan, 18),
  );
  late final TextComponent _combo = TextComponent(
    position: Vector2(10, 30),
    textRenderer: _style(neonPink, 11),
  );
  late final TextComponent _level = TextComponent(
    position: Vector2(breakoutWorldWidth / 2 + 20, 10),
    anchor: Anchor.topCenter,
    textRenderer: _style(neonGreen, 14),
  );
  late final TextComponent _lives = TextComponent(
    position: Vector2(breakoutWorldWidth - 54, 10),
    anchor: Anchor.topRight,
    textRenderer: _style(neonWhite, 14),
  );

  /// Pause button in the top-right corner.
  late final PauseButton pauseButton = PauseButton(
    position: Vector2(breakoutWorldWidth - 44, 4),
  );

  @override
  Future<void> onLoad() async {
    await addAll([_score, _combo, _level, _lives, pauseButton]);
  }

  @override
  void renderTree(Canvas canvas) {
    if (game.phase == BreakoutPhase.title) {
      return;
    }
    super.renderTree(canvas);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _setText(_score, '${game.score}');
    final multiplier = game.comboMultiplier;
    _setText(
      _combo,
      multiplier > 1 ? 'COMBO x${multiplier.toStringAsFixed(1)}' : '',
    );
    _setText(_level, 'LV ${game.level}');
    _setText(_lives, 'LIFE ${game.lives}');
  }

  void _setText(TextComponent component, String text) {
    if (component.text != text) {
      component.text = text;
    }
  }
}

/// Tappable pause icon.
class PauseButton extends PositionComponent
    with TapCallbacks, HasGameReference<EndlessBreakoutGame> {
  /// Creates the pause button at [position].
  new({required super.position}) : super(size: Vector2.all(40));

  final Paint _paint = Paint()..color = neonCyan;
  final Paint _glow = neonGlow(neonCyan);

  @override
  void onTapUp(TapUpEvent event) {
    game.pauseGame();
  }

  @override
  void render(Canvas canvas) {
    if (!game.isInPlay) {
      return;
    }
    const left = Rect.fromLTWH(13, 11, 5, 18);
    const right = Rect.fromLTWH(22, 11, 5, 18);
    canvas
      ..drawRect(left, _glow)
      ..drawRect(right, _glow)
      ..drawRect(left, _paint)
      ..drawRect(right, _paint);
  }
}
