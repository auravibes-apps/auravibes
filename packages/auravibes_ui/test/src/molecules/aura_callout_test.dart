import 'package:auravibes_ui/ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('renders an icon, title, and description', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(
          body: AuraCallout(
            title: 'Heads up',
            description: 'This needs attention.',
            icon: Icons.info,
            tint: .warning,
          ),
        ),
        theme: .new(extensions: [AuraTheme.light]),
      ),
    );

    expect(find.text('Heads up'), findsOneWidget);
    expect(find.text('This needs attention.'), findsOneWidget);
    expect(find.byIcon(Icons.info), findsOneWidget);
  });
}
