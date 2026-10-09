import 'package:auravibes_ui/src/atoms/aura_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraTooltip', () {
    testWidgets('shows styled default tooltip on long press', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraTooltip(
              message: 'Tooltip text',
              child: Text('Target'),
              showDuration: .new(milliseconds: 100),
            ),
          ),
        ),
      );

      expect(find.text('Target'), findsOneWidget);
      expect(find.text('Tooltip text'), findsNothing);

      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, 'Tooltip text');
      expect(tooltip.showDuration, const Duration(milliseconds: 100));
      expect(tooltip.waitDuration, Duration.zero);
      expect(tooltip.preferBelow, isTrue);
      expect(tooltip.decoration, isA<BoxDecoration>());
      expect(
        tooltip.padding,
        const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      );
      expect(tooltip.textStyle?.fontSize, 12);
      expect(tooltip.textStyle?.fontWeight, FontWeight.w500);

      await tester.longPress(find.text('Target'));
      await tester.pump();

      expect(find.text('Tooltip text'), findsOneWidget);
    });

    testWidgets('shows tooltip above target when requested', (tester) async {
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

      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.preferBelow, isFalse);

      await tester.longPress(find.text('Target'));
      await tester.pump();

      expect(find.text('Above'), findsOneWidget);
    });
  });
}
