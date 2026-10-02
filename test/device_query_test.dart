import 'package:device_preview/presets.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_flame_samples/preview/device_query.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolvePreviewDevice maps known ids', () {
    expect(resolvePreviewDevice('iphone-16'), DevicePresets.iPhone16);
    expect(resolvePreviewDevice('pixel-9'), DevicePresets.pixel9);
  });

  test('resolvePreviewDevice throws for unknown ids', () {
    expect(
      () => resolvePreviewDevice('unknown-phone'),
      throwsA(isA<StateError>()),
    );
  });

  test('resolvePreviewOrientation accepts portrait and landscape', () {
    expect(resolvePreviewOrientation(null), Orientation.portrait);
    expect(resolvePreviewOrientation('portrait'), Orientation.portrait);
    expect(resolvePreviewOrientation('landscape'), Orientation.landscape);
  });

  test('resolvePreviewOrientation throws for unknown values', () {
    expect(
      () => resolvePreviewOrientation('upside-down'),
      throwsA(isA<StateError>()),
    );
  });
}
