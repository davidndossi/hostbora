import 'package:flutter_test/flutter_test.dart';
import 'package:host_bora/app/data/local/service/property_count_store.dart';

void main() {
  test('property badge is hidden when count is empty', () {
    expect(PropertyCountStore.labelFor(0), isNull);
    expect(PropertyCountStore.labelFor(-1), isNull);
  });

  test('property badge shows the exact count through 99', () {
    expect(PropertyCountStore.labelFor(1), '1');
    expect(PropertyCountStore.labelFor(99), '99');
  });

  test('property badge caps above 99', () {
    expect(PropertyCountStore.labelFor(100), '99+');
    expect(PropertyCountStore.labelFor(250), '99+');
  });
}
