// Generates the endless breakout sound effects as 16-bit mono PCM WAV files.
//
// Run from the repository root:
//   dart run tool/generate_endless_breakout_sfx.dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const int _sampleRate = 22050;
const String _outputDirectory = 'assets/audio/endless_breakout';

enum _Wave { square, triangle, sine }

void main() {
  final directory = Directory(_outputDirectory)..createSync(recursive: true);
  final noise = math.Random(42);

  final sounds = <String, List<double>>{
    'paddle.wav': _tone(520, 520, 0.05, _Wave.square, volume: 0.3),
    'brick_hit.wav': _tone(700, 650, 0.05, _Wave.triangle, volume: 0.5),
    'brick_break.wav': _tone(900, 1500, 0.07, _Wave.square, volume: 0.25),
    'explosion.wav': _mix(
      _noise(noise, 0.4, volume: 0.6),
      _tone(90, 40, 0.4, _Wave.sine, volume: 0.6),
    ),
    'item.wav': [
      for (final f in [660.0, 880.0, 1100.0, 1320.0])
        ..._tone(f, f, 0.05, _Wave.triangle, volume: 0.5),
    ],
    'laser.wav': _tone(1800, 900, 0.06, _Wave.square, volume: 0.15),
    'level_up.wav': [
      for (final f in [523.0, 659.0, 784.0])
        ..._tone(f, f, 0.09, _Wave.square, volume: 0.25),
      ..._tone(1047, 1047, 0.22, _Wave.square, volume: 0.25),
    ],
    'life_lost.wav': _tone(600, 150, 0.45, _Wave.triangle, volume: 0.5),
    'game_over.wav': [
      for (final f in [392.0, 330.0, 262.0, 196.0])
        ..._tone(f, f, 0.18, _Wave.square, volume: 0.25),
    ],
  };

  for (final MapEntry(key: name, value: samples) in sounds.entries) {
    final file = File('${directory.path}/$name')
      ..writeAsBytesSync(_encodeWav(samples));
    stdout.writeln('wrote ${file.path} (${samples.length} samples)');
  }
}

List<double> _tone(
  double startHz,
  double endHz,
  double seconds,
  _Wave wave, {
  required double volume,
}) {
  final count = (seconds * _sampleRate).round();
  final samples = List<double>.filled(count, 0);
  var phase = 0.0;
  for (var i = 0; i < count; i++) {
    final t = i / count;
    final frequency = startHz + (endHz - startHz) * t;
    phase = (phase + frequency / _sampleRate) % 1;
    final value = switch (wave) {
      _Wave.square => phase < 0.5 ? 1.0 : -1.0,
      _Wave.triangle => 4 * (phase < 0.5 ? phase : 1 - phase) - 1,
      _Wave.sine => math.sin(phase * 2 * math.pi),
    };
    samples[i] = value * volume * _envelope(i, count);
  }
  return samples;
}

List<double> _noise(
  math.Random random,
  double seconds, {
  required double volume,
}) {
  final count = (seconds * _sampleRate).round();
  return List<double>.generate(count, (i) {
    final decay = math.pow(1 - i / count, 2).toDouble();
    return (random.nextDouble() * 2 - 1) * volume * decay;
  });
}

List<double> _mix(List<double> a, List<double> b) {
  final length = math.max(a.length, b.length);
  return List<double>.generate(length, (i) {
    final sum = (i < a.length ? a[i] : 0.0) + (i < b.length ? b[i] : 0.0);
    return sum.clamp(-1.0, 1.0);
  });
}

/// Short attack and linear release to avoid clicks.
double _envelope(int index, int count) {
  const attack = 0.004 * _sampleRate;
  final attackGain = index < attack ? index / attack : 1.0;
  final releaseGain = 1 - index / count;
  return attackGain * releaseGain;
}

Uint8List _encodeWav(List<double> samples) {
  const bytesPerSample = 2;
  final dataLength = samples.length * bytesPerSample;
  final bytes = ByteData(44 + dataLength);
  void writeAscii(int offset, String text) {
    for (var i = 0; i < text.length; i++) {
      bytes.setUint8(offset + i, text.codeUnitAt(i));
    }
  }

  writeAscii(0, 'RIFF');
  bytes.setUint32(4, 36 + dataLength, Endian.little);
  writeAscii(8, 'WAVE');
  writeAscii(12, 'fmt ');
  bytes
    ..setUint32(16, 16, Endian.little)
    ..setUint16(20, 1, Endian.little)
    ..setUint16(22, 1, Endian.little)
    ..setUint32(24, _sampleRate, Endian.little)
    ..setUint32(28, _sampleRate * bytesPerSample, Endian.little)
    ..setUint16(32, bytesPerSample, Endian.little)
    ..setUint16(34, 16, Endian.little);
  writeAscii(36, 'data');
  bytes.setUint32(40, dataLength, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    final value = (samples[i].clamp(-1.0, 1.0) * 32767).round();
    bytes.setInt16(44 + i * bytesPerSample, value, Endian.little);
  }
  return bytes.buffer.asUint8List();
}
