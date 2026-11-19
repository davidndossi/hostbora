import 'package:flutter_test/flutter_test.dart';
import 'package:host_bora/app/modules/add_listing/models/apartment_unit_draft.dart';

void main() {
  test('unit ref is u_<stamp>_<floor>', () {
    expect(ApartmentUnitDraft.newRef(stamp: '1781373144293857', floor: 0),
        'u_1781373144293857_0');
    expect(ApartmentUnitDraft.newRef(stamp: '1781373144293857', floor: 2),
        'u_1781373144293857_2');
  });

  test('generated ref matches the u_<digits>_<floor> shape', () {
    final ref = ApartmentUnitDraft.newRef(floor: 1);
    expect(RegExp(r'^u_\d+_\d+$').hasMatch(ref), isTrue);
    expect(ref.endsWith('_1'), isTrue);
  });

  test('min rent duration is 1 month for rent and 1 day for bnb', () {
    expect(ApartmentUnitDraft.minDurationForMode('rent'), '1 Month');
    expect(ApartmentUnitDraft.minDurationForMode('bnb'), '1 Day');
    expect(
      ApartmentUnitDraft.minDurationForMode('', frequency: 'Per Month'),
      '1 Month',
    );
    expect(
      ApartmentUnitDraft.minDurationForMode('', frequency: 'Per Day'),
      '1 Day',
    );
  });
}
