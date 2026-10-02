import 'package:device_preview/device_preview.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_flame_samples/app/app.dart';
import 'package:flutter_flame_samples/app/router.dart';
import 'package:flutter_flame_samples/preview/device_query.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

/// GitHub Pages entrypoint with DevicePreview driven by URL query parameters.
///
/// Example: `?device=iphone-16&orientation=landscape#/`
///
/// Unknown device / orientation ids throw [StateError] (visible in the browser
/// console; the app UI does not render).
Future<void> main() async {
  setUrlStrategy(const HashUrlStrategy());
  // Profile (and debug) builds enable simulation; release stays off.
  DevicePreview.enable();

  final params = Uri.base.queryParameters;
  final deviceId = params['device'];
  if (deviceId != null) {
    final controller = DevicePreview.controller;
    await controller.applyPreset(resolvePreviewDevice(deviceId));
    await controller.setOrientation(
      resolvePreviewOrientation(params['orientation']),
    );
  }

  runApp(FlameSamplesApp(router: createRouter()));
}
