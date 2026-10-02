import 'dart:math';
import 'dart:ui';

/// Item capsules dropped by item bricks.
enum ItemKind {
  /// Paddle becomes 1.5× wider.
  long(label: 'L', color: Color(0xFF00F5FF), weight: 3, duration: 15),

  /// The ball splits into three.
  multiBall(label: 'M', color: Color(0xFFFF2E88), weight: 3),

  /// Balls slow down.
  slow(label: 'S', color: Color(0xFF7CFF4F), weight: 2, duration: 10),

  /// Balls break through bricks without bouncing.
  pierce(label: 'P', color: Color(0xFFFFB000), weight: 2, duration: 8),

  /// The paddle fires laser bolts automatically.
  laser(label: 'Z', color: Color(0xFFFF4040), weight: 2, duration: 10),

  /// One extra life.
  extraLife(label: '1UP', color: Color(0xFFB98CFF), weight: 1);

  new({
    required this.label,
    required this.color,
    required this.weight,
    this.duration,
  });

  /// Text drawn on the capsule.
  final String label;

  /// Capsule colour.
  final Color color;

  /// Relative drop weight (high = 3, medium = 2, low = 1).
  final int weight;

  /// Effect duration in seconds, or `null` for instant effects.
  final double? duration;
}

/// Picks an item kind proportionally to [ItemKind.weight].
ItemKind pickItem(Random random) {
  final total = ItemKind.values.fold<int>(0, (sum, kind) => sum + kind.weight);
  var roll = random.nextInt(total);
  for (final kind in ItemKind.values) {
    if (roll < kind.weight) {
      return kind;
    }
    roll -= kind.weight;
  }
  throw StateError('Weighted roll $roll exceeded total $total');
}

/// Remaining time of each timed item effect.
class ActiveEffects {
  final Map<ItemKind, double> _remaining = {};

  /// Whether [kind] is currently active.
  bool isActive(ItemKind kind) => _remaining.containsKey(kind);

  /// Seconds left for [kind], or 0 when inactive.
  double remaining(ItemKind kind) => _remaining[kind] ?? 0;

  /// Starts [kind], or extends it by its full duration when already active.
  void activate(ItemKind kind) {
    final duration = kind.duration;
    if (duration == null) {
      throw ArgumentError.value(kind, 'kind', 'is not a timed effect');
    }
    _remaining[kind] = remaining(kind) + duration;
  }

  /// Advances timers by [dt] and returns the effects that expired.
  List<ItemKind> tick(double dt) {
    final expired = <ItemKind>[];
    for (final kind in _remaining.keys.toList()) {
      final left = _remaining[kind]! - dt;
      if (left <= 0) {
        _remaining.remove(kind);
        expired.add(kind);
      } else {
        _remaining[kind] = left;
      }
    }
    return expired;
  }

  /// Cancels every effect.
  void clear() => _remaining.clear();
}
