import 'package:flutter/material.dart';
import 'package:flutter_flame_samples/catalog/catalog_page.dart';
import 'package:flutter_flame_samples/samples/samples.dart';
import 'package:flutter_flame_samples/shared/sample_scaffold.dart';
import 'package:go_router/go_router.dart';

/// Builds the application [GoRouter] with hash-friendly paths.
GoRouter createRouter() {
  return GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const CatalogPage()),
      GoRoute(
        path: '/samples/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'];
          if (id == null) {
            return const _UnknownSamplePage(id: '(missing)');
          }
          final sample = findSampleById(id);
          if (sample == null) {
            return _UnknownSamplePage(id: id);
          }
          return SampleScaffold(sample: sample);
        },
      ),
    ],
  );
}

class _UnknownSamplePage extends StatelessWidget {
  const new({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sample not found')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Unknown sample id: $id'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('Back to catalog'),
            ),
          ],
        ),
      ),
    );
  }
}
