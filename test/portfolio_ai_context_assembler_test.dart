import 'package:flutter_test/flutter_test.dart';
import 'package:host_bora/app/data/local/db/expense_local_data_source.dart';
import 'package:host_bora/app/data/local/db/income_local_data_source.dart';
import 'package:host_bora/app/data/local/db/property_local_data_source.dart';
import 'package:host_bora/app/data/local/db/tenant_local_data_source.dart';
import 'package:host_bora/app/data/local/service/portfolio_ai_context_assembler.dart';
import 'package:host_bora/app/data/local/service/portfolio_ai_local_resolver.dart';
import 'package:host_bora/app/modules/ai_manager/genui/host_genui_layout.dart';

void main() {
  final now = DateTime(2026, 11, 8);

  PropertyRecord property({
    required int id,
    required String name,
    required String ref,
    int units = 2,
  }) {
    return PropertyRecord(
      id: id,
      propertyName: name,
      propertyType: 'Apartment',
      propertyLocation: 'Dar',
      propertyRef: ref,
      tenants: 1,
      units: units,
      ownerUserId: 'u1',
      workspaceType: 'rent',
      createdAtMs: 1,
    );
  }

  TenantRecord tenant({
    required int id,
    required String name,
    required String ref,
    required String unit,
    double rent = 450000,
  }) {
    return TenantRecord(
      id: id,
      propertyLabel: 'Dar · Harbour',
      propertyRef: ref,
      apartmentUnitId: 'u_$id',
      unitLabel: unit,
      tenantName: name,
      gender: '',
      rentAmountValue: rent,
      rentFrequency: 'Per Month',
      phoneNumber: '070100100$id',
      email: '',
      isWhatsapp: true,
      leaseStartIso: '2026-11-01',
      leaseEndIso: '2027-10-31',
      contractFilePath: '',
      contractFileName: '',
      createdAtMs: 1,
    );
  }

  IncomeRecord income({
    required int id,
    required String name,
    required String ref,
    required double amount,
    String date = '2026-11-05',
  }) {
    return IncomeRecord(
      id: id,
      tenantName: name,
      amountValue: amount,
      datePaidIso: date,
      category: 'Lease',
      notes: '',
      apartment: 'Dar · Harbour',
      apartmentUnit: '',
      propertyRef: ref,
      workspaceType: 'rent',
      currencyCode: 'TZS',
      inputAmountValue: amount,
      createdAtMs: 1,
      tenantId: id,
    );
  }

  ExpenseRecord expense({
    required int id,
    required String category,
    required double amount,
    String date = '2026-11-03',
    String apartment = 'Dar · Harbour',
  }) {
    return ExpenseRecord(
      id: id,
      tenantName: '',
      amountValue: amount,
      datePaidIso: date,
      category: category,
      notes: '',
      apartment: apartment,
      apartmentUnit: '',
      workspaceType: 'rent',
      currencyCode: 'TZS',
      inputAmountValue: amount,
      createdAtMs: 1,
    );
  }

  test('merges local rows with extra remote payments and expenses', () {
    final ctx = PortfolioAiContextAssembler.assemble(
      workspace: 'rent',
      now: now,
      includedRemote: true,
      properties: [
        property(id: 1, name: 'Harbour', ref: 'local_1', units: 2),
        property(id: 2, name: 'Sunrise', ref: 'local_2', units: 2),
      ],
      tenants: [
        tenant(id: 1, name: 'Amina', ref: 'local_1', unit: 'A1'),
        tenant(id: 2, name: 'Juma', ref: 'local_1', unit: 'A2'),
        tenant(id: 3, name: 'Neema', ref: 'local_2', unit: 'B1'),
      ],
      incomes: [
        income(id: 1, name: 'Amina', ref: 'local_1', amount: 450000),
        income(id: 2, name: 'Juma', ref: 'local_1', amount: 450000),
        // Remote-only payment not yet in SQLite.
        income(id: -9, name: 'Neema', ref: 'local_2', amount: 200000)
            .copyWithBackend('pay-remote-1'),
      ],
      expenses: [
        expense(id: 1, category: 'Plumbing', amount: 50000),
        expense(id: 2, category: 'Utilities', amount: 20000),
        expense(
          id: 3,
          category: 'Plumbing',
          amount: 10000,
          date: '2026-10-12',
        ),
        expense(
          id: -4,
          category: 'Security',
          amount: 15000,
        ).copyWithBackendExpense('exp-remote-1'),
      ],
    );

    expect(ctx.includedRemote, isTrue);
    expect(ctx.propertyCount, 2);
    expect(ctx.totalUnits, 4);
    expect(ctx.occupiedUnits, 3);
    expect(ctx.occupancyPercent, 75);
    expect(ctx.monthExpected, 1350000);
    expect(ctx.monthIncome, 1100000);
    expect(ctx.collectionRatePercent, closeTo(81.48, 0.1));
    expect(ctx.monthExpenses, 85000);
    expect(ctx.prevMonthExpenses, 10000);
    expect(ctx.expenseCategories.map((e) => e.category), containsAll(['Plumbing', 'Utilities', 'Security']));
    expect(ctx.properties, hasLength(2));
    expect(ctx.properties.first.occupancyPercent, 100);
    expect(ctx.properties.last.occupancyPercent, 50);
  });

  test('occupancy, expense, and collection questions use the enriched snapshot', () {
    final ctx = PortfolioAiContextAssembler.assemble(
      workspace: 'rent',
      now: now,
      properties: [
        property(id: 1, name: 'Harbour', ref: 'local_1'),
        property(id: 2, name: 'Sunrise', ref: 'local_2'),
      ],
      tenants: [
        tenant(id: 1, name: 'Amina', ref: 'local_1', unit: 'A1'),
        tenant(id: 3, name: 'Neema', ref: 'local_2', unit: 'B1'),
      ],
      incomes: [
        income(id: 1, name: 'Amina', ref: 'local_1', amount: 450000),
      ],
      expenses: [
        expense(id: 1, category: 'Plumbing', amount: 40000),
      ],
    );

    String money(num n) => 'TSh ${n.round()}';

    final occupancy = PortfolioAiLocalResolver.resolve(
      question: 'Compare occupancy by property',
      ctx: ctx,
      formatMoney: money,
      isSw: false,
    );
    expect(occupancy.matched, isTrue);
    expect(occupancy.text, contains('Harbour'));
    expect(occupancy.text, contains('Sunrise'));

    final expenses = PortfolioAiLocalResolver.resolve(
      question: 'Break down my expenses',
      ctx: ctx,
      formatMoney: money,
      isSw: false,
    );
    expect(expenses.text, contains('Plumbing'));

    final collection = PortfolioAiLocalResolver.resolve(
      question: 'What is my rent collection rate?',
      ctx: ctx,
      formatMoney: money,
      isSw: false,
    );
    expect(collection.text.toLowerCase(), contains('collection'));
    expect(collection.text, contains('expected'));

    final layout = HostGenUiLayout.fromQuestion(
      question: 'Compare occupancy by property',
      ctx: ctx,
      formatMoney: money,
      isSw: false,
    );
    expect(layout, isNotNull);
    expect(layout!.title, 'Occupancy');
    expect(layout.rows, isNotEmpty);
  });
}

extension on IncomeRecord {
  IncomeRecord copyWithBackend(String id) {
    return IncomeRecord(
      id: this.id,
      tenantName: tenantName,
      amountValue: amountValue,
      datePaidIso: datePaidIso,
      category: category,
      notes: notes,
      apartment: apartment,
      apartmentUnit: apartmentUnit,
      propertyRef: propertyRef,
      bookingId: bookingId,
      workspaceType: workspaceType,
      currencyCode: currencyCode,
      inputAmountValue: inputAmountValue,
      createdAtMs: createdAtMs,
      backendPaymentId: id,
      tenantId: tenantId,
    );
  }
}

extension on ExpenseRecord {
  ExpenseRecord copyWithBackendExpense(String id) {
    return ExpenseRecord(
      id: this.id,
      tenantName: tenantName,
      amountValue: amountValue,
      datePaidIso: datePaidIso,
      category: category,
      notes: notes,
      apartment: apartment,
      apartmentUnit: apartmentUnit,
      workspaceType: workspaceType,
      currencyCode: currencyCode,
      inputAmountValue: inputAmountValue,
      createdAtMs: createdAtMs,
      backendExpenseId: id,
    );
  }
}
