import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
        theme: ThemeData(extensions: [AuraTheme.light]),
      ),
    );

    expect(find.text('print("Hello")'), findsOneWidget);
    expect(find.bySemanticsLabel('Example code'), findsOneWidget);
  });
}
