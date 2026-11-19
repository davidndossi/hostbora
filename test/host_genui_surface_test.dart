import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:host_bora/app/modules/ai_manager/genui/host_genui_layout.dart';
import 'package:host_bora/app/modules/ai_manager/genui/host_genui_session.dart';

void main() {
  testWidgets('GenUI renders a HostAnswer card from portfolio data', (tester) async {
    final session = HostGenUiSession(onAction: (_) {});
    addTearDown(session.dispose);
    final surfaceId = session.show(
      const HostGenUiLayout(
        title: 'Occupancy',
        body: 'Four of five units are filled.',
        metrics: [
          HostGenUiMetric(label: 'Occupancy', value: '80%'),
        ],
        rows: [
          HostGenUiRow(title: 'Sunrise', subtitle: '3 units', trailing: 'Rent'),
        ],
        actions: [
          HostGenUiAction(label: 'Tenants', action: HostGenUiActions.openTenants),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Surface(surfaceContext: session.contextFor(surfaceId)),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Occupancy'), findsWidgets);
    expect(find.text('80%'), findsOneWidget);
    expect(find.text('Sunrise'), findsOneWidget);
    expect(find.text('Tenants'), findsOneWidget);
  });
}
