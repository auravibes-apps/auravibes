import 'package:auravibes_ui/src/atoms/aura_linear_progress_indicator.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraLinearProgressIndicator', () {
    testWidgets('renders determinate, tinted and semantic variants', (
      tester,
    ) async {
      await tester.pumpWidget(
        AuraThemeScope(
          theme: .light,
          child: MaterialApp(
            home: const Scaffold(
              body: Column(
                crossAxisAlignment: .stretch,
                children: [
                  KeyedSubtree(
                    key: ValueKey('default'),
                    child: AuraLinearProgressIndicator(value: 0.5),
                  ),
                  KeyedSubtree(
                    key: ValueKey('below'),
                    child: AuraLinearProgressIndicator(value: -1),
                  ),
                  KeyedSubtree(
                    key: ValueKey('above'),
                    child: AuraLinearProgressIndicator(value: 2),
                  ),
                  KeyedSubtree(
                    key: ValueKey('height'),
                    child: AuraLinearProgressIndicator(value: 0.5, height: 8),
                  ),
                  KeyedSubtree(
                    key: ValueKey('tint'),
                    child: AuraLinearProgressIndicator(
                      value: 0.5,
                      tint: .error,
                      backgroundAlpha: 0.25,
                    ),
                  ),
                  KeyedSubtree(
                    key: ValueKey('semantics'),
                    child: AuraLinearProgressIndicator(
                      value: 0.5,
                      semanticLabel: 'Context usage',
                      semanticValue: '50%',
                    ),
                  ),
                ],
              ),
            ),
            theme: ThemeData.light().copyWith(),
          ),
        ),
      );

      final defaultProgress = find.byKey(const ValueKey('default'));
      expect(
        find.descendant(
          of: defaultProgress,
          matching: find.byType(LinearProgressIndicator),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: defaultProgress,
          matching: find.byType(FractionallySizedBox),
        ),
        findsOneWidget,
      );

      final belowProgress = find.byKey(const ValueKey('below'));
      final belowFill = tester.widget<FractionallySizedBox>(
        find.descendant(
          of: belowProgress,
          matching: find.byType(FractionallySizedBox),
        ),
      );
      expect(belowFill.widthFactor, 0);

      final aboveProgress = find.byKey(const ValueKey('above'));
      final aboveFill = tester.widget<FractionallySizedBox>(
        find.descendant(
          of: aboveProgress,
          matching: find.byType(FractionallySizedBox),
        ),
      );
      expect(aboveFill.widthFactor, 1);

      final heightProgress = find.byKey(const ValueKey('height'));
      final sizedBox = tester.widget<SizedBox>(
        find.descendant(of: heightProgress, matching: find.byType(SizedBox)),
      );
      expect(sizedBox.height, 8);

      final tintProgress = find.byKey(const ValueKey('tint'));
      final coloredBoxes = tester
          .widgetList<ColoredBox>(
            find.descendant(
              of: tintProgress,
              matching: find.byType(ColoredBox),
            ),
          )
          .toList();
      expect(coloredBoxes, hasLength(2));
      final [background, fill] = coloredBoxes;
      expect(
        background.color,
        AuraTheme.light.colors.surfaceVariant.withValues(alpha: 0.25),
      );
      expect(fill.color, AuraTheme.light.colors.error);

      final semanticProgress = find.byKey(const ValueKey('semantics'));
      final semantics = tester.widget<Semantics>(
        find.descendant(of: semanticProgress, matching: find.byType(Semantics)),
      );
      expect(semantics.properties.label, 'Context usage');
      expect(semantics.properties.value, '50%');
    });
  });
}
