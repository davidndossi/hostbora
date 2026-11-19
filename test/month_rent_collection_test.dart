import 'package:flutter_test/flutter_test.dart';
import 'package:host_bora/app/core/utils/month_rent_collection.dart';
import 'package:host_bora/app/data/local/db/income_local_data_source.dart';
import 'package:host_bora/app/data/local/db/tenant_local_data_source.dart';
import 'package:host_bora/app/data/model/rewards_dashboard.dart';

void main() {
  TenantRecord tenant() {
    return const TenantRecord(
      id: 1,
      propertyLabel: 'Victoria House',
      propertyRef: 'local_1',
      apartmentUnitId: 'u_1',
      unitLabel: 'Mbele',
      tenantName: 'Usta Rukaka',
      gender: '',
      rentAmountValue: 450000,
      rentFrequency: 'Per Month',
      phoneNumber: '',
      email: '',
      isWhatsapp: false,
      leaseStartIso: '2026-07-01',
      leaseEndIso: '2026-12-31',
      contractFilePath: '',
      contractFileName: '',
      createdAtMs: 1,
    );
  }

  IncomeRecord income() {
    return const IncomeRecord(
      id: 1,
      tenantName: 'Usta Rukaka',
      amountValue: 2700000,
      datePaidIso: '2026-06-30',
      category: 'Lease',
      notes: '',
      apartment: 'Victoria House',
      apartmentUnit: 'Mbele',
      propertyRef: 'local_1',
      workspaceType: 'rent',
      currencyCode: 'TZS',
      inputAmountValue: 2700000,
      createdAtMs: 1,
      tenantId: 1,
    );
  }

  RewardsDashboard dashboard({int pct = 0}) {
    return RewardsDashboard(
      balance: 200,
      smsCredits: 0,
      academyCompleted: false,
      challenges: [
        RewardChallenge(
          key: 'rent_collection',
          title: 'November Rent Collection Challenge',
          description: 'Collect this month\'s rent',
          pct: pct,
          current: 0,
          target: 450000,
          unit: 'TZS',
          complete: false,
        ),
      ],
      earn: const [],
      catalog: const [],
      achievements: const [],
    );
  }

  test('prepaid six months marks November collection complete', () {
    final month = MonthRentCollection.fromRecords(
      tenants: [tenant()],
      incomes: [income()],
      now: DateTime(2026, 11, 2),
    );
    expect(month.expected, 450000);
    expect(month.collected, 450000);
    expect(month.pct, 100);
  });

  test('June prepaid without tenant_id still counts in November', () {
    final month = MonthRentCollection.fromRecords(
      tenants: [tenant()],
      incomes: [
        IncomeRecord(
          id: 1,
          tenantName: 'Usta Rukaka',
          amountValue: 2700000,
          datePaidIso: '2026-06-30',
          category: 'Lease',
          notes: '',
          apartment: 'Victoria House',
          apartmentUnit: 'Mbele',
          propertyRef: 'local_1',
          workspaceType: 'rent',
          currencyCode: 'TZS',
          inputAmountValue: 2700000,
          createdAtMs: 1,
          tenantId: 0,
        ),
      ],
      now: DateTime(2026, 11, 2),
    );
    expect(month.expected, 450000);
    expect(month.collected, 450000);
  });

  test('overlays local collection onto a server 0% challenge', () {
    final updated = MonthRentCollection.fromRecords(
      tenants: [tenant()],
      incomes: [income()],
      now: DateTime(2026, 11, 2),
    ).applyTo(dashboard());
    expect(updated.challenges.single.pct, 100);
    expect(updated.challenges.single.current, 450000);
    expect(updated.challenges.single.complete, isTrue);
    expect(updated.balance, 200);
  });

  test('does not lower a higher server-reported collection percent', () {
    final updated = const MonthRentCollection(
      expected: 450000,
      collected: 225000,
    ).applyTo(dashboard(pct: 80));
    expect(updated.challenges.single.pct, 80);
  });
}
