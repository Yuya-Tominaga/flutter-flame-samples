import 'package:device_preview/presets.dart';
import 'package:flutter/widgets.dart';

/// Explicit map from URL query device ids to [DevicePreset]s.
///
/// Only referenced presets are compiled in; do not use [DevicePresets.byId].
const Map<String, DevicePreset> previewDevicePresets = {
  'iphone-16': DevicePresets.iPhone16,
  'iphone-se3': DevicePresets.iPhoneSe3,
  'ipad-pro-11': DevicePresets.iPadPro11M4,
  'pixel-9': DevicePresets.pixel9,
  'galaxy-s25': DevicePresets.galaxyS25,
};

/// Resolves a device query id to a [DevicePreset].
///
/// Throws [StateError] when [deviceId] is unknown.
DevicePreset resolvePreviewDevice(String deviceId) {
  final preset = previewDevicePresets[deviceId];
  if (preset == null) {
    throw StateError(
      'Unknown device id: $deviceId. '
      'Supported: ${previewDevicePresets.keys.join(', ')}',
    );
  }
  return preset;
}

/// Resolves an orientation query value.
///
/// Accepted values: `portrait` (default) and `landscape`.
/// Throws [StateError] for any other value.
Orientation resolvePreviewOrientation(String? raw) {
  final value = raw ?? 'portrait';
  switch (value) {
    case 'portrait':
      return Orientation.portrait;
    case 'landscape':
      return Orientation.landscape;
    default:
      throw StateError(
        'Unknown orientation: $value. Supported: portrait, landscape',
      );
  }
}
