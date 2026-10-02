import 'package:flutter_flame_samples/samples/basic_movement/basic_movement_game.dart';
import 'package:flutter_flame_samples/shared/sample.dart';

/// Registry of all samples shown in the catalog.
///
/// Add a new [Sample] here to make it appear in the list and routes.
final List<Sample> samples = [
  const Sample(
    id: 'basic-movement',
    title: 'Basic Movement',
    description: 'Move the circle with WASD / arrow keys, or tap / drag on the playfield.',
    gameBuilder: BasicMovementGame.new,
  ),
];

/// Finds a sample by [id], or returns `null` when unknown.
Sample? findSampleById(String id) {
  for (final sample in samples) {
    if (sample.id == id) {
      return sample;
    }
  }
  return null;
}
