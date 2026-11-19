import 'package:flutter_test/flutter_test.dart';
import 'package:host_bora/app/core/utils/month_rent_collection.dart';
import 'package:host_bora/app/core/utils/unlinked_payments.dart';
import 'package:host_bora/app/data/local/db/income_local_data_source.dart';
import 'package:host_bora/app/data/local/db/tenant_local_data_source.dart';

void main() {
  TenantRecord tenant({
    required int id,
    required String name,
    String start = '2026-07-01',
    String end = '2027-08-31',
  }) {
    return TenantRecord(
      id: id,
      propertyLabel: 'Victoria House',
      propertyRef: 'local_1',
      apartmentUnitId: 'u_1',
      unitLabel: 'Mbele',
      tenantName: name,
      gender: '',
      rentAmountValue: 450000,
      rentFrequency: 'Per Month',
      phoneNumber: '',
      email: '',
      isWhatsapp: false,
      leaseStartIso: start,
      leaseEndIso: end,
      contractFilePath: '',
      contractFileName: '',
      createdAtMs: 1,
    );
  }

  IncomeRecord income({
    int id = 1,
    int tenantId = 0,
    String name = '',
    double amount = 2400000,
    String date = '2026-11-10',
    String workspace = 'rent',
    String ref = '',
  }) {
    return IncomeRecord(
      id: id,
      tenantName: name,
      amountValue: amount,
      datePaidIso: date,
      category: 'Lease',
      notes: '',
      apartment: '',
      apartmentUnit: '',
      propertyRef: ref,
      workspaceType: workspace,
      currencyCode: 'TZS',
      inputAmountValue: amount,
      createdAtMs: 1,
      tenantId: tenantId,
    );
  }

  final tenants = [
    tenant(id: 1, name: 'Usta Rukaka', end: '2026-11-10'),
    tenant(id: 2, name: 'Aboubakar', start: '2026-11-01'),
  ];

  group('UnlinkedPayments.find', () {
    test('lists rent payments no tenant owns', () async {
      final found = await UnlinkedPayments.find(
        tenants: tenants,
        incomes: [
          income(id: 1),
          income(id: 2, date: '2026-06-30'),
        ],
      );
      expect(found.map((r) => r.id), [1, 2]);
    });

    test('skips linked, name-matched and BnB payments', () async {
      final found = await UnlinkedPayments.find(
        tenants: tenants,
        incomes: [
          income(id: 1, tenantId: 2),
          income(id: 2, name: 'Aboubakar', ref: 'local_1'),
          income(id: 3, workspace: 'bnb'),
          income(id: 4),
        ],
      );
      expect(found.map((r) => r.id), [4]);
    });
  });

  group('rent collection with unlinked payments', () {
    test('a 2.4M unlinked payment no longer reads as 267% collected', () {
      final month = MonthRentCollection.fromRecords(
        tenants: tenants,
        incomes: [
          income(id: 1),
          income(id: 2, amount: 2700000, date: '2026-06-30'),
        ],
        now: DateTime(2026, 11, 18),
      );
      expect(month.expected, 900000);
      expect(month.collected, 0);
      expect(month.pct, 0);
    });

    test('unlinked cash dated this month is other income, not collected', () {
      final month = MonthRentCollection.fromRecords(
        tenants: tenants,
        incomes: [
          income(id: 1, amount: 2400000, date: '2026-11-10'),
          income(id: 2, amount: 700000, date: '2026-10-10'),
        ],
        now: DateTime(2026, 11, 18),
      );
      expect(month.collected, 0);
      expect(month.pct, 0);
      // Only the November payment; October belongs to October.
      expect(month.otherIncome, 2400000);
      // Dashboard income counts it so it matches the weekly chart.
      expect(month.totalIncome, 2400000);
    });

    test('linking the payment allocates it per tenant, capped per month', () {
      final month = MonthRentCollection.fromRecords(
        tenants: tenants,
        incomes: [income(id: 1, tenantId: 2)],
        now: DateTime(2026, 11, 18),
      );
      // 2.4M against Aboubakar covers only his 450K for November.
      expect(month.collected, 450000);
      expect(month.pct, 50);
    });

    test('unlinked BnB income still counts as collected', () {
      final month = MonthRentCollection.fromRecords(
        tenants: tenants,
        incomes: [income(id: 1, amount: 100000, workspace: 'bnb')],
        now: DateTime(2026, 11, 18),
      );
      expect(month.collected, 100000);
    });
  });
}
