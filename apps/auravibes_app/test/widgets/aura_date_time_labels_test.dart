import 'package:auravibes_app/widgets/aura_date_time_labels.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('date picker uses Spanish app-owned labels', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.runAsync(
      () => tester.pumpWidget(
        TestableApp(
          child: Builder(
            builder: (context) => Scaffold(
              body: AuraDateTimeInput(
                value: .new(2026, 11, 3),
                labels: AuraDateTimeLabels.forContext(context),
              ),
            ),
          ),
          startLocale: const Locale('es'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.runAsync(() async {
      await tester.tap(find.byType(AuraDateTimeInput));
      await tester.pump(const Duration(milliseconds: 200));
    });
    final _ = await tester.pumpAndSettle();
    expect(find.text('Seleccionar fecha y hora'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
    expect(
      find.bySemanticsLabel('D${String.fromCharCode(0xed)}a 3'),
      findsOneWidget,
    );
    handle.dispose();
  });
}
