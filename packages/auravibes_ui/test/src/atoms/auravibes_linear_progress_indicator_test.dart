import 'package:auravibes_ui/src/atoms/aura_linear_progress_indicator.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraLinearProgressIndicator', () {
    testWidgets('renders without Material linear progress indicator', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraLinearProgressIndicator(value: 0.5),
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.byType(FractionallySizedBox), findsOneWidget);
    });

    testWidgets('clamps value below zero', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraLinearProgressIndicator(value: -1),
          ),
        ),
      );

      final fill = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox),
      );
      expect(fill.widthFactor, 0);
    });

    testWidgets('clamps value above one', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraLinearProgressIndicator(value: 2),
          ),
        ),
      );

      final fill = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox),
      );
      expect(fill.widthFactor, 1);
    });

    testWidgets('applies height', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraLinearProgressIndicator(
              value: 0.5,
              height: 8,
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
      expect(sizedBox.height, 8);
    });

    testWidgets('resolves color variants', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(
            body: AuraLinearProgressIndicator(
              value: 0.5,
              color: AuraColorVariant.error,
              backgroundColor: AuraColorVariant.onSurfaceVariant,
              backgroundAlpha: 0.25,
            ),
          ),
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
        ),
      );

      final coloredBoxes = tester
          .widgetList<ColoredBox>(
            find.descendant(
              of: find.byType(AuraLinearProgressIndicator),
              matching: find.byType(ColoredBox),
            ),
          )
          .toList();
      expect(coloredBoxes, hasLength(2));
      final [background, fill] = coloredBoxes;
      expect(
        background.color,
        AuraTheme.light.colors.onSurfaceVariant.withValues(alpha: 0.25),
      );
      expect(fill.color, AuraTheme.light.colors.error);
    });

    testWidgets('passes semantic label and value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraLinearProgressIndicator(
              value: 0.5,
              semanticLabel: 'Context usage',
              semanticValue: '50%',
            ),
          ),
        ),
      );

      final semantics = tester.widget<Semantics>(
        find.descendant(
          of: find.byType(AuraLinearProgressIndicator),
          matching: find.byType(Semantics),
        ),
      );
      expect(semantics.properties.label, 'Context usage');
      expect(semantics.properties.value, '50%');
    });
  });
}
