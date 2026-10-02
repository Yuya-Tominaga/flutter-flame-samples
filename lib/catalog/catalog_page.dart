import 'package:flutter/material.dart';
import 'package:flutter_flame_samples/samples/samples.dart';
import 'package:go_router/go_router.dart';

/// Catalog page that lists every registered sample.
class CatalogPage extends StatelessWidget {
  /// Creates the catalog page.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Flame Samples')),
      body: ListView.separated(
        itemCount: samples.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final sample = samples[index];
          return ListTile(
            title: Text(sample.title),
            subtitle: Text(sample.description),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/samples/${sample.id}'),
          );
        },
      ),
    );
  }
}
