import 'package:auravibes_ui/src/atoms/aura_tooltip.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
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

    testWidgets('passes tooltip controls to native Tooltip', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraTooltip(
              message: 'Tooltip text',
              child: Text('Target'),
              showDuration: Duration(milliseconds: 100),
            ),
          ),
        ),
      );

      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, 'Tooltip text');
      expect(tooltip.showDuration, const Duration(milliseconds: 100));
      expect(tooltip.waitDuration, Duration.zero);
      expect(tooltip.preferBelow, true);
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
              child: Text('Target'),
              preferBelow: false,
            ),
          ),
        ),
      );

      await tester.longPress(find.text('Target'));
      await tester.pump();

      expect(find.text('Above'), findsOneWidget);
    });

    testWidgets('renders primary color variant tooltip', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraTooltip(
              message: 'Primary',
              child: Text('Target'),
              colorVariant: AuraColorVariant.primary,
            ),
          ),
        ),
      );

      await tester.longPress(find.text('Target'));
      await tester.pump();

      expect(find.text('Primary'), findsOneWidget);
    });

    testWidgets('applies Aura styling to native Tooltip', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraTooltip(
              message: 'Tooltip text',
              child: Text('Target'),
              colorVariant: AuraColorVariant.primary,
            ),
          ),
        ),
      );

      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));

      expect(tooltip.decoration, isA<BoxDecoration>());
      expect(
        tooltip.padding,
        const EdgeInsets.symmetric(
          vertical: 4,
          horizontal: 8,
        ),
      );
      expect(tooltip.textStyle?.fontSize, 12);
      expect(tooltip.textStyle?.fontWeight, FontWeight.w500);
    });
  });
}
