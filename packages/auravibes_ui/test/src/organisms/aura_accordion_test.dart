import 'package:auravibes_ui/ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('toggles expanded content', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(
          body: AuraAccordion(
            items: [
              AuraAccordionItem(title: 'Details', child: Text('Content')),
            ],
          ),
        ),
        theme: .new(extensions: [AuraTheme.light]),
      ),
    );

    expect(find.text('Content'), findsNothing);

    await tester.tap(find.text('Details'));
    await tester.pump();
    expect(find.text('Content'), findsOneWidget);

    await tester.tap(find.text('Details'));
    await tester.pump();
    expect(find.text('Content'), findsNothing);
  });
}
