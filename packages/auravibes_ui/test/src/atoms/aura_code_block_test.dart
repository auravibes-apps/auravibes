import 'package:auravibes_ui/ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('renders code with an accessible summary', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(
          body: AuraCodeBlock(
            code: 'print("Hello")',
            language: 'dart',
            semanticLabel: 'Example code',
          ),
        ),
        theme: .new(extensions: [AuraTheme.light]),
      ),
    );

    expect(find.text('print("Hello")'), findsOneWidget);
    expect(find.bySemanticsLabel('Example code'), findsOneWidget);
  });
}
