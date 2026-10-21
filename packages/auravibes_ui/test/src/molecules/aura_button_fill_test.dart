import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final dark in [false, true]) {
    for (final variant in [
      AuraButtonVariant.primary,
      AuraButtonVariant.secondary,
      AuraButtonVariant.elevated,
      AuraButtonVariant.text,
    ]) {
      testWidgets('button fill and label: dark=$dark, variant=$variant', (
        tester,
      ) async {
        final colors = AuraComputedColorScheme(
          primaryHue: 300,
          brightness: dark ? .dark : .light,
        );
        final theme = (dark ? AuraTheme.dark : AuraTheme.light).copyWith(
          colors: colors,
        );
        await tester.pumpWidget(
          AuraThemeScope(
            theme: theme,
            child: MaterialApp(
              home: Scaffold(
                body: AuraButton(
                  onPressed: () {
                    return;
                  },
                  child: const Text('Action'),
                  variant: variant,
                ),
              ),
            ),
          ),
        );
        final pressable = tester.widget<AuraPressable>(
          find.byType(AuraPressable),
        );
        final decoration = pressable.decoration as BoxDecoration?;
        final inline = variant == AuraButtonVariant.text;
        final tint = variant == AuraButtonVariant.secondary
            ? AuraTint.secondary
            : AuraTint.primary;
        expect(
          decoration?.color,
          inline ? Colors.transparent : colors.fillFor(tint),
        );
        expect(
          DefaultTextStyle.of(tester.element(find.text('Action'))).style.color,
          inline ? colors.primary : colors.onFill(tint),
        );
      });
    }
  }
}
