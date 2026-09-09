import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders a circular accessible placeholder', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(
          body: AuraSkeleton(
            width: 24,
            height: 24,
            circular: true,
            semanticLabel: 'Loading',
          ),
        ),
        theme: .new(extensions: [AuraTheme.light]),
      ),
    );

    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    expect(tester.getSize(find.byType(AuraSkeleton)), const Size(24, 24));
  });
}
