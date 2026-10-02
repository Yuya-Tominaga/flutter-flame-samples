import 'package:flutter_flame_samples/samples/endless_breakout/breakout_config.dart';

/// Brick variants from the spec.
enum BrickKind {
  /// Breaks in one hit.
  normal,

  /// Needs 2–3 hits; the colour shows the remaining durability.
  hard,

  /// Drops an item capsule when broken.
  item,

  /// Breaks the 8 surrounding bricks when broken.
  explosive,
}

/// A single brick in the grid.
class Brick {
  /// Creates a brick of [kind] with [durability] hits remaining.
  new(this.kind, {this.durability = 1}) {
    if (durability < 1) {
      throw ArgumentError.value(durability, 'durability', 'must be >= 1');
    }
    if (kind != BrickKind.hard && durability != 1) {
      throw ArgumentError.value(
        durability,
        'durability',
        'only hard bricks can have more than 1 durability',
      );
    }
  }

  /// Variant of this brick.
  final BrickKind kind;

  /// Remaining hits before the brick breaks.
  int durability;
}

/// Row/column address of a grid cell.
typedef GridCell = ({int row, int column});

/// Grid of bricks where row 0 is the top row.
///
/// New rows are inserted at the top, pushing every existing row down by one.
class BrickGrid {
  /// Creates an empty grid with [columns] columns.
  new({this.columns = breakoutColumns});

  /// Number of columns.
  final int columns;

  final List<List<Brick?>> _rows = [];

  /// Number of rows currently tracked (including empty rows above bricks).
  int get rowCount => _rows.length;

  /// Brick at [row]/[column], or `null` for an empty or out-of-range cell.
  Brick? brickAt(int row, int column) {
    if (row < 0 || row >= _rows.length || column < 0 || column >= columns) {
      return null;
    }
    return _rows[row][column];
  }

  /// Inserts [row] at the top and shifts every existing row down by one.
  void pushRow(List<Brick?> row) {
    if (row.length != columns) {
      throw ArgumentError.value(row.length, 'row.length', 'expected $columns');
    }
    _rows.insert(0, List<Brick?>.of(row));
    _trimEmptyBottomRows();
  }

  /// Removes every row.
  void clear() => _rows.clear();

  /// Removes the brick at [row]/[column].
  void remove(int row, int column) {
    if (brickAt(row, column) == null) {
      throw StateError('No brick at ($row, $column)');
    }
    _rows[row][column] = null;
    _trimEmptyBottomRows();
  }

  /// Whether [row] contains no bricks.
  bool isRowEmpty(int row) {
    if (row < 0 || row >= _rows.length) {
      return true;
    }
    return _rows[row].every((brick) => brick == null);
  }

  /// Whether the grid contains no bricks at all.
  bool get isEmpty => _rows.isEmpty;

  /// Index of the lowest row containing a brick, or -1 when empty.
  int get lowestOccupiedRow => _rows.length - 1;

  /// Whether any brick has reached [breakoutDeadlineRow].
  bool get hasReachedDeadline => lowestOccupiedRow >= breakoutDeadlineRow;

  /// All occupied cells with their bricks.
  Iterable<(GridCell, Brick)> get bricks sync* {
    for (var row = 0; row < _rows.length; row++) {
      for (var column = 0; column < columns; column++) {
        final brick = _rows[row][column];
        if (brick != null) {
          yield ((row: row, column: column), brick);
        }
      }
    }
  }

  /// The up to 8 occupied cells surrounding [cell].
  Iterable<GridCell> occupiedNeighbours(GridCell cell) sync* {
    for (var dr = -1; dr <= 1; dr++) {
      for (var dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) {
          continue;
        }
        final row = cell.row + dr;
        final column = cell.column + dc;
        if (brickAt(row, column) != null) {
          yield (row: row, column: column);
        }
      }
    }
  }

  void _trimEmptyBottomRows() {
    while (_rows.isNotEmpty && _rows.last.every((brick) => brick == null)) {
      _rows.removeLast();
    }
  }
}
