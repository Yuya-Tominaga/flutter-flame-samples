import 'package:flutter_flame_samples/samples/endless_breakout/breakout_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the best score and settings on the device.
///
/// Missing keys mean the player has never changed the value, so the
/// documented initial values apply.
class BreakoutPreferences {
  /// Wraps an already-loaded [SharedPreferences] instance.
  new(this._prefs);

  /// Loads the platform preferences store.
  static Future<BreakoutPreferences> load() async {
    return BreakoutPreferences(await SharedPreferences.getInstance());
  }

  static const _bestScoreKey = 'endless_breakout.best_score';
  static const _soundEnabledKey = 'endless_breakout.sound_enabled';
  static const _sensitivityKey = 'endless_breakout.paddle_sensitivity';

  final SharedPreferences _prefs;

  /// Highest score ever recorded on this device.
  int get bestScore => _prefs.getInt(_bestScoreKey) ?? 0;

  /// Whether sound effects are enabled.
  bool get soundEnabled => _prefs.getBool(_soundEnabledKey) ?? true;

  /// Drag-to-paddle movement ratio.
  double get paddleSensitivity =>
      _prefs.getDouble(_sensitivityKey) ?? breakoutDefaultSensitivity;

  /// Stores [score] as the best score.
  Future<void> setBestScore(int score) async {
    if (score < 0) {
      throw ArgumentError.value(score, 'score', 'must be >= 0');
    }
    _ensureWritten(await _prefs.setInt(_bestScoreKey, score), _bestScoreKey);
  }

  /// Removes the stored best score.
  Future<void> resetBestScore() async {
    _ensureWritten(await _prefs.remove(_bestScoreKey), _bestScoreKey);
  }

  /// Stores whether sound effects are enabled.
  Future<void> setSoundEnabled({required bool enabled}) async {
    _ensureWritten(
      await _prefs.setBool(_soundEnabledKey, enabled),
      _soundEnabledKey,
    );
  }

  /// Stores the paddle sensitivity.
  Future<void> setPaddleSensitivity(double value) async {
    if (value < breakoutMinSensitivity || value > breakoutMaxSensitivity) {
      throw ArgumentError.value(value, 'value', 'out of range');
    }
    _ensureWritten(
      await _prefs.setDouble(_sensitivityKey, value),
      _sensitivityKey,
    );
  }

  void _ensureWritten(bool written, String key) {
    if (!written) {
      throw StateError('Failed to persist preference "$key"');
    }
  }
}
