import 'package:flutter_test/flutter_test.dart';
import 'package:host_bora/app/data/local/db/income_local_data_source.dart';
import 'package:host_bora/app/data/local/db/tenant_local_data_source.dart';
import 'package:host_bora/app/modules/rent/tenant_ledger_occupancy/utils/tenant_ledger_finance.dart';

void main() {
  TenantRecord tenant({
    int id = 5,
    String name = 'Asha',
    String propertyRef = 'local_1793515703540',
  }) {
    return TenantRecord(
      id: id,
      propertyLabel: 'Victoria House',
      propertyRef: propertyRef,
      apartmentUnitId: 'u_1',
      unitLabel: 'Mbele',
      tenantName: name,
      gender: '',
      rentAmountValue: 450000,
      rentFrequency: 'Per Month',
      phoneNumber: '',
      email: '',
      isWhatsapp: false,
      leaseStartIso: '2026-11-01',
      leaseEndIso: '2027-05-01',
      contractFilePath: '',
      contractFileName: '',
      createdAtMs: 1,
    );
  }

  IncomeRecord income({
    String name = 'Asha',
    String notes = '',
    int tenantId = 0,
    String propertyRef = 'other_ref',
  }) {
    return IncomeRecord(
      id: 1,
      tenantName: name,
      amountValue: 450000,
      datePaidIso: '2026-11-01',
      category: 'Lease',
      notes: notes,
      apartment: 'Victoria House',
      apartmentUnit: 'Mbele',
      propertyRef: propertyRef,
      workspaceType: 'rent',
      currencyCode: 'TZS',
      inputAmountValue: 450000,
      createdAtMs: 1,
      tenantId: tenantId,
    );
  }

  test('income matches only when tenant_id equals tenant id', () {
    expect(
      TenantLedgerFinance.incomeMatchesTenant(
        income(tenantId: 5),
        tenant(),
      ),
      isTrue,
    );
    expect(
      TenantLedgerFinance.incomeMatchesTenant(
        income(tenantId: 9, name: 'Asha'),
        tenant(),
      ),
      isFalse,
    );
  });

  test('legacy notes tenantId tag still matches when column is empty', () {
    expect(
      TenantLedgerFinance.incomeMatchesTenant(
        income(name: '', notes: 'M-Pesa\ntenantId:5'),
        tenant(),
      ),
      isTrue,
    );
    expect(
      TenantLedgerFinance.incomeMatchesTenant(
        income(name: '', notes: 'tenantId:15'),
        tenant(),
      ),
      isFalse,
    );
  });

  test('same tenant name does not match without tenant_id', () {
    expect(
      TenantLedgerFinance.incomeMatchesTenant(income(), tenant()),
      isFalse,
    );
  });

  test('legacy payment matches by name and listing without tenant_id', () {
    expect(
      TenantLedgerFinance.incomeMatchesTenant(
        income(propertyRef: 'local_1793515703540'),
        tenant(),
      ),
      isTrue,
    );
  });

  test('legacy payment matches by name, property, and unit when refs are empty',
      () {
    expect(
      TenantLedgerFinance.incomeMatchesTenant(
        income(propertyRef: ''),
        tenant(propertyRef: ''),
      ),
      isTrue,
    );
  });

  test('1 Jul to 31 Dec is 6 inclusive months', () {
    expect(
      TenantLedgerFinance.monthsBetween(
        DateTime(2026, 7, 1),
        DateTime(2026, 12, 31),
      ),
      6,
    );
    expect(
      TenantLedgerFinance.leaseDurationUnits(
        TenantRecord(
          id: 5,
          propertyLabel: 'Victoria House',
          propertyRef: 'local_1',
          apartmentUnitId: 'u_1',
          unitLabel: 'Mbele',
          tenantName: 'Asha',
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
        ),
      ),
      6,
    );
    expect(
      TenantLedgerFinance.monthsBetween(
        DateTime(2026, 7, 1),
        DateTime(2026, 11, 1),
      ),
      4,
    );
  });
}
