import 'package:device_preview/device_preview.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_flame_samples/app/app.dart';
import 'package:flutter_flame_samples/app/router.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

/// Local debug entrypoint.
///
/// Device simulation is available from the Flutter DevTools device_preview tab
/// in debug and profile builds.
void main() {
  setUrlStrategy(const HashUrlStrategy());
  DevicePreview.enable();
  runApp(FlameSamplesApp(router: createRouter()));
}
