import 'package:flutter_test/flutter_test.dart';
import 'package:host_bora/app/core/utils/overdue_occupants.dart';
import 'package:host_bora/app/data/local/db/income_local_data_source.dart';
import 'package:host_bora/app/data/local/db/property_local_data_source.dart';
import 'package:host_bora/app/data/local/db/tenant_local_data_source.dart';

void main() {
  TenantRecord rentTenant() {
    return const TenantRecord(
      id: 1,
      propertyLabel: 'Nyumba ya Victoria',
      propertyRef: 'local_1',
      apartmentUnitId: 'u_1',
      unitLabel: 'Chumba 1',
      tenantName: 'Amina Kassim',
      gender: '',
      rentAmountValue: 450000,
      rentFrequency: 'Per Month',
      phoneNumber: '0701001001',
      email: '',
      isWhatsapp: true,
      leaseStartIso: '2026-07-01',
      leaseEndIso: '2026-12-31',
      contractFilePath: '',
      contractFileName: '',
      createdAtMs: 1,
    );
  }

  TenantRecord bnbGuest({String checkIn = '2026-10-27'}) {
    return TenantRecord(
      id: 2,
      propertyLabel: 'Nyumba ya Pwani',
      propertyRef: 'local_2',
      apartmentUnitId: 'u_2',
      unitLabel: 'Chumba 2',
      tenantName: 'Peter Mushi',
      gender: '',
      rentAmountValue: 80000,
      rentFrequency: 'Per Stay',
      phoneNumber: '0711001001',
      email: '',
      isWhatsapp: true,
      leaseStartIso: checkIn,
      leaseEndIso: '2026-10-30',
      contractFilePath: '',
      contractFileName: '',
      createdAtMs: 1,
    );
  }

  IncomeRecord income({
    required int tenantId,
    required String name,
    required String ref,
    required double amount,
    String date = '2026-07-01',
  }) {
    return IncomeRecord(
      id: tenantId,
      tenantName: name,
      amountValue: amount,
      datePaidIso: date,
      category: 'Lease',
      notes: '',
      apartment: '',
      apartmentUnit: '',
      propertyRef: ref,
      workspaceType: tenantId == 2 ? 'bnb' : 'rent',
      currencyCode: 'TZS',
      inputAmountValue: amount,
      createdAtMs: 1,
      tenantId: tenantId,
    );
  }

  test('combines overdue rent tenant and unpaid BnB guest', () {
    final rows = OverdueOccupants.fromRecords(
      rentTenants: [rentTenant()],
      bnbTenants: [bnbGuest()],
      incomes: [
        income(
          tenantId: 1,
          name: 'Amina Kassim',
          ref: 'local_1',
          amount: 1800000,
        ),
      ],
      now: DateTime(2026, 11, 8),
    );
    expect(rows, hasLength(2));
    expect(rows.first.name, 'Peter Mushi');
    expect(rows.first.amountOwed, 80000);
    expect(rows.first.daysOverdue, 12);
    expect(rows.first.isBnb, isTrue);
    expect(rows.last.name, 'Amina Kassim');
    expect(rows.last.amountOwed, 450000);
    expect(rows.last.daysOverdue, 7);
    expect(rows.last.placeLine, 'Chumba 1 · Nyumba ya Victoria');
  });

  test('shows the property name instead of a stored property id', () {
    final tenant = TenantRecord(
      id: 1,
      propertyLabel: 'local_1',
      propertyRef: 'local_1',
      apartmentUnitId: 'u_1',
      unitLabel: 'Chumba 1',
      tenantName: 'Amina Kassim',
      gender: '',
      rentAmountValue: 450000,
      rentFrequency: 'Per Month',
      phoneNumber: '0701001001',
      email: '',
      isWhatsapp: true,
      leaseStartIso: '2026-07-01',
      leaseEndIso: '2026-12-31',
      contractFilePath: '',
      contractFileName: '',
      createdAtMs: 1,
    );
    const property = PropertyRecord(
      id: 1,
      propertyName: 'Nyumba ya Victoria',
      propertyType: 'Apartment',
      propertyLocation: 'Mikocheni',
      propertyRef: '',
      tenants: 1,
      units: 1,
      ownerUserId: 'u',
      workspaceType: 'rent',
      createdAtMs: 1,
    );

    final withProperty = OverdueOccupants.fromRecords(
      rentTenants: [tenant],
      bnbTenants: const [],
      incomes: const [],
      properties: const [property],
      now: DateTime(2026, 11, 8),
    );
    expect(withProperty.single.placeLine, 'Chumba 1 · Nyumba ya Victoria');

    // Unknown property: never fall back to the raw id.
    final withoutProperty = OverdueOccupants.fromRecords(
      rentTenants: [tenant],
      bnbTenants: const [],
      incomes: const [],
      now: DateTime(2026, 11, 8),
    );
    expect(withoutProperty.single.placeLine, 'Chumba 1');
  });

  test('prepaid six months is not overdue in November', () {
    final rows = OverdueOccupants.fromRecords(
      rentTenants: [rentTenant()],
      bnbTenants: const [],
      incomes: [
        income(
          tenantId: 1,
          name: 'Amina Kassim',
          ref: 'local_1',
          amount: 2700000,
          date: '2026-06-30',
        ),
      ],
      now: DateTime(2026, 11, 8),
    );
    expect(rows, isEmpty);
  });

  test('future BnB stay is not overdue', () {
    final rows = OverdueOccupants.fromRecords(
      rentTenants: const [],
      bnbTenants: [bnbGuest(checkIn: '2026-12-01')],
      incomes: const [],
      now: DateTime(2026, 11, 8),
    );
    expect(rows, isEmpty);
  });
}
