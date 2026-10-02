import 'package:flutter_flame_samples/samples/samples.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sample ids are unique', () {
    final ids = samples.map((sample) => sample.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('findSampleById returns registered samples and null for unknown', () {
    expect(findSampleById('basic-movement'), isNotNull);
    expect(findSampleById('does-not-exist'), isNull);
  });
}
