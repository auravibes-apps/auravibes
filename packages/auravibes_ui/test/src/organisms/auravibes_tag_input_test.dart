import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app(Widget child) => MaterialApp(
    home: Scaffold(body: child),
    theme: ThemeData(extensions: [AuraTheme.light]),
  );

  testWidgets('removes a tag through an accessible local control', (
    tester,
  ) async {
    var tags = <String>['planning', 'release'];
    await tester.pumpWidget(
      app(
        StatefulBuilder(
          builder: (context, setState) => AuraTagInput(
            value: tags,
            onChanged: (value) => setState(() => tags = value),
            removeLabel: (tag) => 'Remove $tag',
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Remove planning'));
    final _ = await tester.pumpAndSettle();

    expect(find.text('planning'), findsNothing);
    expect(find.text('release'), findsOneWidget);
  });

  testWidgets('does not remove tags in a read-only interaction scope', (
    tester,
  ) async {
    var changes = 0;
    await tester.pumpWidget(
      app(
        AuraInteractionScope(
          policy: const AuraInteractionPolicy.readOnly(),
          child: AuraTagInput(
            value: const ['planning'],
            onChanged: (_) => changes++,
            removeLabel: (tag) => 'Remove $tag',
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Remove planning'));
    final _ = await tester.pumpAndSettle();

    expect(changes, 0);
  });
}
