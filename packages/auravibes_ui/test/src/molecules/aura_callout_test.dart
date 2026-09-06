import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders an icon, title, and description', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(
          body: AuraCallout(
            title: 'Heads up',
            description: 'This needs attention.',
            icon: Icons.info,
            tint: AuraTint.warning,
          ),
        ),
        theme: ThemeData(extensions: [AuraTheme.light]),
      ),
    );

    expect(find.text('Heads up'), findsOneWidget);
    expect(find.text('This needs attention.'), findsOneWidget);
    expect(find.byIcon(Icons.info), findsOneWidget);
  });
}
