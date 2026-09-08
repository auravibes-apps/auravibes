import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('lays out flexible and fixed items', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(
          body: SizedBox(
            width: 200,
            child: AuraRow(
              children: [
                AuraFlexItem(child: Text('Flexible')),
                AuraSpacer(size: 12),
                Text('Trailing'),
              ],
            ),
          ),
        ),
        theme: .new(extensions: [AuraTheme.light]),
      ),
    );

    expect(find.text('Flexible'), findsOneWidget);
    expect(find.text('Trailing'), findsOneWidget);
  });
}
