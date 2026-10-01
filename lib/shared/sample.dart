import 'package:flame/game.dart';

/// Metadata and factory for a Flame sample shown in the catalog.
class Sample {
  /// Creates a sample definition.
  const new({
    required this.id,
    required this.title,
    required this.description,
    required this.gameBuilder,
  });

  /// Unique route id used in `/samples/:id`.
  final String id;

  /// Short title shown in the catalog list.
  final String title;

  /// Longer explanation shown on the sample screen.
  final String description;

  /// Builds a fresh [FlameGame] instance for this sample.
  final FlameGame Function() gameBuilder;
}
