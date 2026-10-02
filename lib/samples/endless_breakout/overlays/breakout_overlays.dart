import 'package:flutter/material.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/breakout_config.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/breakout_items.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/components/neon.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/endless_breakout_game.dart';

/// Title screen with best score and entry points to the other screens.
class TitleOverlay extends StatelessWidget {
  /// Creates the title overlay.
  const new({required this.game, super.key});

  /// Game driven by this overlay.
  final EndlessBreakoutGame game;

  @override
  Widget build(BuildContext context) {
    return _NeonScreen(
      children: [
        const _NeonText('ENDLESS', color: neonCyan, fontSize: 40),
        const _NeonText('BREAKOUT', color: neonPink, fontSize: 40),
        const SizedBox(height: 24),
        ValueListenableBuilder<int>(
          valueListenable: game.bestScore,
          builder: (context, best, _) =>
              _NeonText('BEST  $best', color: neonGreen, fontSize: 18),
        ),
        const SizedBox(height: 32),
        _NeonButton(label: 'START', onPressed: game.startNewGame),
        _NeonButton(label: 'HOW TO PLAY', onPressed: game.openHowToPlay),
        _NeonButton(label: 'SETTINGS', onPressed: game.openSettings),
      ],
    );
  }
}

/// Rules, controls, bricks and items.
class HowToPlayOverlay extends StatelessWidget {
  /// Creates the how-to-play overlay.
  const new({required this.game, super.key});

  /// Game driven by this overlay.
  final EndlessBreakoutGame game;

  @override
  Widget build(BuildContext context) {
    return _NeonScreen(
      scrollable: true,
      children: [
        const _NeonText('HOW TO PLAY', color: neonCyan, fontSize: 26),
        const SizedBox(height: 16),
        const _Section(
          title: 'CONTROLS',
          lines: [
            'Drag anywhere on the lower half to move the paddle.',
            'Tap to launch the ball.',
            'Use the pause button at the top right to pause.',
          ],
        ),
        const _Section(
          title: 'RULES',
          lines: [
            'The bricks drop one row at regular intervals.',
            'You lose a life when every ball falls.',
            'Game over at 0 lives or when a brick reaches the red line.',
            'The level rises every 60 seconds.',
          ],
        ),
        _Section(
          title: 'BRICKS',
          entries: [
            (neonCyan, 'Normal: breaks in one hit'),
            (hardBrickColor(3), 'Hard: 2-3 hits, colour shows hits left'),
            (neonGreen, 'Item: drops a capsule'),
            (neonPurple, 'Explosive: breaks the 8 around it'),
          ],
        ),
        _Section(
          title: 'ITEMS',
          entries: [
            for (final kind in ItemKind.values)
              (kind.color, '${kind.label}: ${_itemDescription(kind)}'),
          ],
        ),
        const _Section(
          title: 'SCORE',
          lines: [
            '10 points per hit. Combo x0.5 every 5 bricks (max x4).',
            'Combo resets when the ball touches the paddle.',
            'Row clear bonus +$breakoutRowClearBonus.',
            'Board clear bonus +$breakoutBoardClearBonus.',
          ],
        ),
        const SizedBox(height: 8),
        _NeonButton(label: 'BACK', onPressed: game.closeTitleSubScreen),
      ],
    );
  }

  static String _itemDescription(ItemKind kind) => switch (kind) {
    ItemKind.long => 'wider paddle',
    ItemKind.multiBall => 'ball splits into 3',
    ItemKind.slow => 'slower balls',
    ItemKind.pierce => 'balls smash through bricks',
    ItemKind.laser => 'paddle fires lasers',
    ItemKind.extraLife => 'one extra life',
  };
}

/// Sound toggle, paddle sensitivity and best score reset.
class SettingsOverlay extends StatefulWidget {
  /// Creates the settings overlay.
  const new({required this.game, super.key});

  /// Game driven by this overlay.
  final EndlessBreakoutGame game;

  @override
  State<SettingsOverlay> createState() => _SettingsOverlayState();
}

class _SettingsOverlayState extends State<SettingsOverlay> {
  late double _sensitivity = widget.game.preferences.paddleSensitivity;

  EndlessBreakoutGame get _game => widget.game;

  Future<void> _setSound({required bool enabled}) async {
    await _game.setSoundEnabled(enabled: enabled);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset best score?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await _game.resetBestScore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final soundEnabled = _game.preferences.soundEnabled;
    return _NeonScreen(
      children: [
        const _NeonText('SETTINGS', color: neonCyan, fontSize: 26),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text(
            'Sound effects',
            style: TextStyle(color: neonWhite),
          ),
          value: soundEnabled,
          activeThumbColor: neonCyan,
          onChanged: (value) => _setSound(enabled: value),
        ),
        const SizedBox(height: 8),
        Text(
          'Paddle sensitivity  x${_sensitivity.toStringAsFixed(2)}',
          style: const TextStyle(color: neonWhite),
        ),
        Slider(
          value: _sensitivity,
          min: breakoutMinSensitivity,
          max: breakoutMaxSensitivity,
          divisions: 6,
          activeColor: neonCyan,
          label: 'x${_sensitivity.toStringAsFixed(2)}',
          onChanged: (value) => setState(() => _sensitivity = value),
          onChangeEnd: _game.setPaddleSensitivity,
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<int>(
          valueListenable: _game.bestScore,
          builder: (context, best, _) => Text(
            'Best score: $best',
            style: const TextStyle(color: neonWhite),
          ),
        ),
        _NeonButton(
          label: 'RESET BEST SCORE',
          color: neonRed,
          onPressed: _confirmReset,
        ),
        const SizedBox(height: 8),
        _NeonButton(label: 'BACK', onPressed: _game.closeTitleSubScreen),
      ],
    );
  }
}

/// Pause menu.
class PauseOverlay extends StatelessWidget {
  /// Creates the pause overlay.
  const new({required this.game, super.key});

  /// Game driven by this overlay.
  final EndlessBreakoutGame game;

  @override
  Widget build(BuildContext context) {
    return _NeonScreen(
      children: [
        const _NeonText('PAUSED', color: neonCyan, fontSize: 32),
        const SizedBox(height: 24),
        _NeonButton(label: 'RESUME', onPressed: game.resumeGame),
        _NeonButton(label: 'QUIT TO TITLE', onPressed: game.backToTitle),
      ],
    );
  }
}

/// Final score next to the best score, with retry / title choices.
class GameOverOverlay extends StatelessWidget {
  /// Creates the game over overlay.
  const new({required this.game, super.key});

  /// Game driven by this overlay.
  final EndlessBreakoutGame game;

  @override
  Widget build(BuildContext context) {
    return _NeonScreen(
      children: [
        const _NeonText('GAME OVER', color: neonPink, fontSize: 34),
        const SizedBox(height: 24),
        _NeonText('SCORE  ${game.score}', color: neonCyan, fontSize: 22),
        ValueListenableBuilder<int>(
          valueListenable: game.bestScore,
          builder: (context, best, _) =>
              _NeonText('BEST  $best', color: neonGreen, fontSize: 18),
        ),
        if (game.lastScoreWasBest)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: _NeonText('NEW BEST!', color: neonGreen, fontSize: 16),
          ),
        const SizedBox(height: 24),
        _NeonButton(label: 'RETRY', onPressed: game.startNewGame),
        _NeonButton(label: 'TITLE', onPressed: game.backToTitle),
      ],
    );
  }
}

class _NeonScreen extends StatelessWidget {
  const new({required this.children, this.scrollable = false});

  final List<Widget> children;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final column = Column(mainAxisSize: MainAxisSize.min, children: children);
    return Material(
      color: neonBackground.withValues(alpha: 0.82),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: scrollable ? SingleChildScrollView(child: column) : column,
            ),
          ),
        ),
      ),
    );
  }
}

class _NeonText extends StatelessWidget {
  const new(this.text, {required this.color, required this.fontSize});

  final String text;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        letterSpacing: 3,
        shadows: [Shadow(color: color, blurRadius: 14)],
      ),
    );
  }
}

class _NeonButton extends StatelessWidget {
  const new({
    required this.label,
    required this.onPressed,
    this.color = neonCyan,
  });

  final String label;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SizedBox(
        width: 240,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color, width: 2),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shadowColor: color,
            elevation: 8,
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const new({
    required this.title,
    this.lines = const [],
    this.entries = const [],
  });

  final String title;
  final List<String> lines;
  final List<(Color, String)> entries;

  @override
  Widget build(BuildContext context) {
    const bodyStyle = TextStyle(color: neonWhite, fontSize: 13, height: 1.4);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: neonPink,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          for (final line in lines) Text('• $line', style: bodyStyle),
          for (final (color, text) in entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.4),
                      border: Border.all(color: color, width: 1.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(text, style: bodyStyle)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
