import 'package:flutter_test/flutter_test.dart';
import 'package:host_bora/app/data/local/service/portfolio_ai_context.dart';
import 'package:host_bora/app/modules/ai_manager/genui/host_genui_layout.dart';

void main() {
  String money(num amount) => 'TSh ${amount.round()}';

  final ctx = PortfolioAiContext(
    workspace: 'rent',
    monthLabel: 'Oct 2026',
    propertyCount: 2,
    totalUnits: 5,
    occupiedUnits: 4,
    occupancyPercent: 80,
    activeTenants: 4,
    monthIncome: 400000,
    monthExpenses: 50000,
    monthNet: 350000,
    arrearsTenantCount: 1,
    arrearsTotal: 80000,
    leasesExpiring30Days: 1,
    activeBookingsToday: 0,
    checkInsToday: 0,
    checkOutsToday: 0,
    maintenanceTasks: 2,
    propertyNames: const ['Sunrise', 'Harbour'],
  );

  test('questions stay questions and commands stay commands', () {
    expect(HostGenUiLayout.shouldTreatAsAction("What's my occupancy?"), isFalse);
    expect(HostGenUiLayout.shouldTreatAsAction('Show my tenants'), isFalse);
    expect(HostGenUiLayout.shouldTreatAsAction('Add a booking'), isTrue);
    expect(HostGenUiLayout.shouldTreatAsAction('Send reminder'), isTrue);
    expect(HostGenUiLayout.shouldTreatAsAction('Open inventory'), isTrue);
    expect(HostGenUiLayout.shouldTreatAsAction('Tuma kikumbusho'), isTrue);
  });

  test('occupancy question becomes a summary card from portfolio data', () {
    final layout = HostGenUiLayout.fromQuestion(
      question: "What's my occupancy rate?",
      ctx: ctx,
      formatMoney: money,
      isSw: false,
    );
    expect(layout, isNotNull);
    expect(layout!.title, 'Occupancy');
    expect(layout.metrics.first.value, '80.0%');
    expect(
      layout.actions.map((a) => a.action),
      contains(HostGenUiActions.openTenants),
    );
  });

  test('model JSON is parsed and unknown actions are dropped', () {
    final layout = HostGenUiLayout.parseModel(
      '''
```json
{"title":"Income","body":"October looks steady.","metrics":[{"label":"Income","value":"TSh 400000"}],"actions":[{"label":"Pay","action":"OPEN_PAYMENTS"},{"label":"Hack","action":"DELETE_ALL"}]}
```
''',
      isSw: false,
    );
    expect(layout.title, 'Income');
    expect(layout.metrics, hasLength(1));
    expect(layout.actions, hasLength(1));
    expect(layout.actions.single.action, HostGenUiActions.openPayments);
  });

  test('prose from the model becomes a note card', () {
    final layout = HostGenUiLayout.parseModel(
      'I do not have that figure yet.',
      isSw: false,
    );
    expect(layout.title, 'Answer');
    expect(layout.body, 'I do not have that figure yet.');
    expect(layout.metrics, isEmpty);
  });
}
