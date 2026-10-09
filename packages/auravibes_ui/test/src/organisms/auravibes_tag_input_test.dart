import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app(Widget child) => AuraThemeScope(
    theme: .light,
    child: MaterialApp(
      home: Scaffold(body: child),
      theme: .new(),
    ),
  );

  testWidgets('removes tags only outside a read-only interaction scope', (
    tester,
  ) async {
    var editableTags = <String>['planning', 'release'];
    var readOnlyChanges = 0;
    await tester.pumpWidget(
      app(
        Column(
          children: [
            StatefulBuilder(
              builder: (context, setState) => AuraTagInput(
                value: editableTags,
                onChanged: (value) => setState(() => editableTags = value),
                removeLabel: (tag) => 'Remove editable $tag',
                key: const ValueKey('editable'),
              ),
            ),
            AuraInteractionScope(
              policy: const AuraInteractionPolicy.readOnly(),
              child: AuraTagInput(
                value: const ['planning'],
                onChanged: (_) => readOnlyChanges++,
                removeLabel: (tag) => 'Remove read-only $tag',
                key: const ValueKey('read-only'),
              ),
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.byTooltip('Remove editable planning'));
    final _ = await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('editable')),
        matching: find.text('planning'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('editable')),
        matching: find.text('release'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Remove read-only planning'));
    final _ = await tester.pumpAndSettle();
    expect(readOnlyChanges, 0);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('read-only')),
        matching: find.text('planning'),
      ),
      findsOneWidget,
    );
  });
}
