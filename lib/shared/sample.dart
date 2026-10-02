import 'package:flame/game.dart';
import 'package:flutter/services.dart';

/// Metadata and factory for a Flame sample shown in the catalog.
class Sample {
  /// Creates a sample definition.
  const new({
    required this.id,
    required this.title,
    required this.description,
    required this.gameBuilder,
    this.preferredOrientations = const [],
  });

  /// Unique route id used in `/samples/:id`.
  final String id;

  /// Short title shown in the catalog list.
  final String title;

  /// Longer explanation shown on the sample screen.
  final String description;

  /// Builds a fresh [FlameGame] instance for this sample.
  final FlameGame Function() gameBuilder;

  /// Orientations the device is locked to while the sample is open.
  ///
  /// Empty means the sample does not restrict orientation.
  final List<DeviceOrientation> preferredOrientations;
}

/// Implemented by sample games that show Flutter overlays.
///
/// The sample scaffold registers [overlayBuilderMap] on the [GameWidget].
abstract interface class HasSampleOverlays {
  /// Overlay builders keyed by overlay name.
  Map<String, OverlayWidgetBuilder<FlameGame>> get overlayBuilderMap;
}
