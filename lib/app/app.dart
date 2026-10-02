import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Root Material application wired to [router].
class FlameSamplesApp extends StatelessWidget {
  /// Creates the app with the given [router].
  const new({required this.router, super.key});

  /// Application router.
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter Flame Samples',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4CC9F0)),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
