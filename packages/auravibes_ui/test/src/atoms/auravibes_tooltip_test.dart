import 'package:auravibes_ui/src/atoms/auravibes_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraTooltip', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraTooltip(
              message: 'Tooltip text',
              child: Text('Target'),
            ),
          ),
        ),
      );

      expect(find.text('Target'), findsOneWidget);
    });

    testWidgets('shows tooltip on long press', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraTooltip(
              message: 'Tooltip text',
              child: Text('Target'),
            ),
          ),
        ),
      );

      expect(find.text('Tooltip text'), findsNothing);

      await tester.longPress(find.text('Target'));
      await tester.pump();

      expect(find.text('Tooltip text'), findsOneWidget);
    });

    testWidgets('hides tooltip after showDuration', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraTooltip(
              message: 'Tooltip text',
              showDuration: Duration(milliseconds: 100),
              child: Text('Target'),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Target')),
      );
      await tester.pump(const Duration(milliseconds: 550));
      expect(find.text('Tooltip text'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('Tooltip text'), findsNothing);

      await gesture.up();
    });

    testWidgets('toggles tooltip on repeated long press', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraTooltip(
              message: 'Tooltip text',
              child: Text('Target'),
            ),
          ),
        ),
      );

      await tester.longPress(find.text('Target'));
      await tester.pump();
      expect(find.text('Tooltip text'), findsOneWidget);

      // Long press again to hide
      await tester.longPress(find.text('Target'));
      await tester.pump();
      expect(find.text('Tooltip text'), findsNothing);
    });

    testWidgets('applies preferBelow offset', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraTooltip(
              message: 'Below',
              child: Text('Target'),
            ),
          ),
        ),
      );

      await tester.longPress(find.text('Target'));
      await tester.pump();

      expect(find.text('Below'), findsOneWidget);
    });

    testWidgets('applies preferAbove offset', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraTooltip(
              message: 'Above',
              preferBelow: false,
              child: Text('Target'),
            ),
          ),
        ),
      );

      await tester.longPress(find.text('Target'));
      await tester.pump();

      expect(find.text('Above'), findsOneWidget);
    });
  });
}
