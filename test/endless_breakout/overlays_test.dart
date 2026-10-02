import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_flame_samples/samples/endless_breakout/endless_breakout_game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

Future<EndlessBreakoutGame> _pumpGame(WidgetTester tester) async {
  final game = createTestGame();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: GameWidget<FlameGame>(
          game: game,
          overlayBuilderMap: game.overlayBuilderMap,
        ),
      ),
    ),
  );
  // FlameGame keeps producing frames, so pumpAndSettle never completes.
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  return game;
}

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.tap(find.text(text));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('title opens how-to-play and settings and starts a game', (
    tester,
  ) async {
    final game = await _pumpGame(tester);
    expect(find.text('ENDLESS'), findsOneWidget);
    expect(find.text('BEST  0'), findsOneWidget);

    await _tapText(tester, 'HOW TO PLAY');
    expect(find.text('CONTROLS'), findsOneWidget);
    await _tapText(tester, 'BACK');

    await _tapText(tester, 'SETTINGS');
    expect(find.text('Sound effects'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(game.preferences.soundEnabled, isFalse);
    await _tapText(tester, 'BACK');

    await _tapText(tester, 'START');
    expect(game.phase, BreakoutPhase.ready);
    expect(find.text('START'), findsNothing);
  });

  testWidgets('pause overlay resumes and quits to the title', (tester) async {
    final game = await _pumpGame(tester);
    await _tapText(tester, 'START');

    game.pauseGame();
    await tester.pump();
    expect(find.text('PAUSED'), findsOneWidget);
    await _tapText(tester, 'RESUME');
    expect(game.phase, BreakoutPhase.ready);
    expect(find.text('PAUSED'), findsNothing);

    game.pauseGame();
    await tester.pump();
    await _tapText(tester, 'QUIT TO TITLE');
    expect(game.phase, BreakoutPhase.title);
    expect(find.text('ENDLESS'), findsOneWidget);
  });

  testWidgets('reset best score asks for confirmation', (tester) async {
    SharedPreferences.setMockInitialValues({
      'endless_breakout.best_score': 900,
    });
    final game = await _pumpGame(tester);
    expect(find.text('BEST  900'), findsOneWidget);

    await _tapText(tester, 'SETTINGS');
    await _tapText(tester, 'RESET BEST SCORE');
    await _tapText(tester, 'Cancel');
    expect(game.bestScore.value, 900);

    await _tapText(tester, 'RESET BEST SCORE');
    await _tapText(tester, 'Reset');
    expect(game.bestScore.value, 0);
    expect(find.text('Best score: 0'), findsOneWidget);
  });
}
