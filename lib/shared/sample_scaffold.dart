import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_flame_samples/shared/sample.dart';
import 'package:go_router/go_router.dart';

/// Shared scaffold that wraps a [GameWidget] with navigation chrome.
class SampleScaffold extends StatefulWidget {
  /// Creates a scaffold for the given [sample].
  const new({required this.sample, super.key});

  /// Sample to display.
  final Sample sample;

  @override
  State<SampleScaffold> createState() => _SampleScaffoldState();
}

class _SampleScaffoldState extends State<SampleScaffold> {
  late final FlameGame _game = widget.sample.gameBuilder();
  final FocusNode _gameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final orientations = widget.sample.preferredOrientations;
    if (orientations.isNotEmpty) {
      unawaited(SystemChrome.setPreferredOrientations(orientations));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _gameFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    if (widget.sample.preferredOrientations.isNotEmpty) {
      unawaited(SystemChrome.setPreferredOrientations(const []));
    }
    _gameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sample = widget.sample;
    return Scaffold(
      appBar: AppBar(
        title: Text(sample.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to catalog',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(sample.description),
            ),
          ),
          Expanded(
            child: Focus(
              focusNode: _gameFocusNode,
              child: GameWidget(
                game: _game,
                overlayBuilderMap: switch (_game) {
                  final HasSampleOverlays game => game.overlayBuilderMap,
                  _ => null,
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
