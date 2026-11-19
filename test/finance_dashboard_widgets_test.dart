import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host_bora/app/modules/dashboard/widgets/finance_dashboard_widgets.dart';

Widget _page({
  required Brightness brightness,
  required bool monthly,
  required bool big,
  required bool wide,
}) {
  final amount = big ? '1,234,567,890,123' : '5,100,000';
  final tap = ValueNotifier<bool>(monthly);
  return MaterialApp(
    theme: ThemeData(brightness: brightness),
    home: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        child: ValueListenableBuilder<bool>(
          valueListenable: tap,
          builder: (context, m, _) {
            final trend = IncomeTrendPanel(
              title: 'Mwenendo wa mapato',
              subtitle: 'Novemba ikilinganishwa na Oktoba',
              weeklyTab: 'Kwa wiki',
              monthlyTab: 'Kwa mwezi',
              monthly: m,
              onSelect: (v) => tap.value = v,
              current: m ? [1, 2, 3, 4, 5] : [0, 2000000, 1500000, 0],
              previous: m ? null : [900000, 0, 0, 3000000],
              labels: m
                  ? ['Jul', 'Ago', 'Sep', 'Okt', 'Nov']
                  : ['Wiki 1', 'Wiki 2', 'Wiki 3', 'Wiki 4'],
              currentLegend: m ? 'Mapato ya mwezi' : 'Novemba',
              previousLegend: m ? null : 'Oktoba',
            );
            final summary = MonthSummaryPanel(
              title: 'Muhtasari wa mwezi',
              totalLabel: 'Jumla ya mapato',
              totalValue: 'TSh $amount',
              avgLabel: 'Wastani kwa siku',
              avgValue: 'TSh $amount',
              note: 'Wastani wa siku 19 za Novemba.',
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FinanceHeading(
                  title: 'Dashibodi ya fedha',
                  intro: 'Mapato, matumizi na faida yako kwa mwezi huu.',
                ),
                const SizedBox(height: 18),
                FinanceHeroCard(
                  period: 'Novemba 2026',
                  profitLabel: 'Faida halisi',
                  currency: 'TSh',
                  profitAmount: amount,
                  incomeLabel: 'Mapato',
                  incomeValue: 'TSh $amount',
                  expenseLabel: 'Matumizi',
                  expenseValue: 'TSh $amount',
                ),
                const SizedBox(height: 12),
                FinanceActions(
                  addIncomeLabel: 'Ongeza mapato',
                  addExpenseLabel: 'Ingiza gharama',
                  onAddIncome: () {},
                  onAddExpense: () {},
                ),
                const SizedBox(height: 20),
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 12, child: trend),
                      const SizedBox(width: 20),
                      Expanded(flex: 10, child: summary),
                    ],
                  )
                else ...[
                  trend,
                  const SizedBox(height: 16),
                  summary,
                ],
              ],
            );
          },
        ),
      ),
    ),
  );
}

void main() {
  for (final size in const [Size(320, 700), Size(390, 844), Size(900, 800)]) {
    for (final brightness in Brightness.values) {
      for (final big in const [false, true]) {
        testWidgets('lays out at ${size.width}w $brightness big=$big', (
          tester,
        ) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(
            _page(
              brightness: brightness,
              monthly: false,
              big: big,
              wide: size.width >= 700,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          // Switch to the monthly tab and make sure it still lays out.
          await tester.tap(find.text('Kwa mwezi'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('Mapato ya mwezi'), findsOneWidget);
          expect(find.text('Oktoba'), findsNothing);
        });
      }
    }
  }
}
