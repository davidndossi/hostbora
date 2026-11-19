import 'package:flutter_test/flutter_test.dart';
import 'package:host_bora/app/core/utils/tenant_rent_billing.dart';

void main() {
  const start = '2026-07-01';
  const end = '2026-12-31';
  const monthly = 450000.0;

  test('prepaid six months covers November in full', () {
    final collected = TenantRentBilling.collectedInCalendarMonth(
      rentAmountValue: monthly,
      rentFrequency: 'Per Month',
      leaseStartIso: start,
      leaseEndIso: end,
      paidTotal: 2700000,
      monthStart: DateTime(2026, 11, 1),
      nextMonthStart: DateTime(2026, 12, 1),
    );
    expect(collected, 450000);
  });

  test('four months prepaid leaves November unpaid', () {
    final collected = TenantRentBilling.collectedInCalendarMonth(
      rentAmountValue: monthly,
      rentFrequency: 'Per Month',
      leaseStartIso: start,
      leaseEndIso: end,
      paidTotal: 1800000,
      monthStart: DateTime(2026, 11, 1),
      nextMonthStart: DateTime(2026, 12, 1),
    );
    expect(collected, 0);
  });

  test('partial leftover credits November', () {
    final collected = TenantRentBilling.collectedInCalendarMonth(
      rentAmountValue: monthly,
      rentFrequency: 'Per Month',
      leaseStartIso: start,
      leaseEndIso: end,
      paidTotal: 2000000,
      monthStart: DateTime(2026, 11, 1),
      nextMonthStart: DateTime(2026, 12, 1),
    );
    expect(collected, 200000);
  });

  test('same-month payment covers a November-start lease', () {
    final collected = TenantRentBilling.collectedInCalendarMonth(
      rentAmountValue: monthly,
      rentFrequency: 'Per Month',
      leaseStartIso: '2026-11-01',
      leaseEndIso: '2026-12-31',
      paidTotal: 450000,
      monthStart: DateTime(2026, 11, 1),
      nextMonthStart: DateTime(2026, 12, 1),
    );
    expect(collected, 450000);
  });

  test('nothing collected after the lease ends', () {
    final collected = TenantRentBilling.collectedInCalendarMonth(
      rentAmountValue: monthly,
      rentFrequency: 'Per Month',
      leaseStartIso: start,
      leaseEndIso: end,
      paidTotal: 2700000,
      monthStart: DateTime(2027, 1, 1),
      nextMonthStart: DateTime(2027, 2, 1),
    );
    expect(collected, 0);
  });
}
