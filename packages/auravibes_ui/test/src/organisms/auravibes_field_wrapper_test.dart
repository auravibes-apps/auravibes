// Required: Tests use fixed widget dimensions.

import 'package:auravibes_ui/src/atoms/aura_corner_radius_scope.dart';
import 'package:auravibes_ui/src/colors/aura_brightness.dart';
import 'package:auravibes_ui/src/colors/color_contrast.dart';
import 'package:auravibes_ui/src/organisms/aura_field_wrapper.dart';
import 'package:auravibes_ui/src/tokens/aura_computed_color_scheme.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraFieldWrapper', () {
    test('keeps focus and error contrast across theme hues', () {
      for (final brightness in AuraBrightness.values) {
        for (var hue = 0.0; hue < 360; hue += 15) {
          final colors = AuraComputedColorScheme(
            primaryHue: hue,
            brightness: brightness,
          );
          for (final indicator in [colors.primary, colors.error]) {
            for (final surface in [colors.surface, colors.surfaceVariant]) {
              expect(
                ColorContrast.wcagContrastRatio(indicator, surface),
                greaterThanOrEqualTo(3),
                reason: '${brightness.name}, hue $hue',
              );
            }
          }
        }
      }
    });

    testWidgets('uses scoped outer radius', (tester) async {
      final theme = AuraTheme.light;
      await tester.pumpWidget(
        AuraThemeScope(
          theme: theme,
          child: MaterialApp(
            home: Scaffold(
              body: AuraCornerRadiusScope.select(
                level: .sm,
                child: const AuraFieldWrapper(child: SizedBox()),
              ),
            ),
          ),
        ),
      );

      final decoration = tester
          .widget<AnimatedContainer>(find.byType(AnimatedContainer))
          .decoration;
      expect(
        decoration,
        isA<BoxDecoration>().having(
          (value) => value.borderRadius,
          'borderRadius',
          BorderRadius.circular(theme.fromBorderRadius(.sm)),
        ),
      );
    });

    testWidgets('renders label, hint, and child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraFieldWrapper(
              child: SizedBox(width: 20, height: 20),
              label: Text('Field label'),
              hint: Text('Helpful hint'),
            ),
          ),
        ),
      );

      expect(find.text('Field label'), findsOneWidget);
      expect(find.text('Helpful hint'), findsOneWidget);
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('keeps focus and error outlines visible without glow', (
      tester,
    ) async {
      for (final theme in [AuraTheme.light, AuraTheme.dark]) {
        await tester.pumpWidget(
          AuraThemeScope(
            theme: theme,
            child: const MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    AuraFieldWrapper(
                      child: SizedBox(width: 200, height: 48),
                      key: ValueKey('normal'),
                    ),
                    AuraFieldWrapper(
                      child: SizedBox(width: 200, height: 48),
                      key: ValueKey('focused'),
                      isFocused: true,
                    ),
                    AuraFieldWrapper(
                      child: SizedBox(width: 200, height: 48),
                      key: ValueKey('error'),
                      error: Text('Required'),
                      state: .error,
                    ),
                    AuraFieldWrapper(
                      child: SizedBox(width: 200, height: 48),
                      key: ValueKey('success-focused'),
                      state: .success,
                      isFocused: true,
                    ),
                    AuraFieldWrapper(
                      child: SizedBox(width: 200, height: 48),
                      key: ValueKey('warning-focused'),
                      state: .warning,
                      isFocused: true,
                    ),
                    AuraFieldWrapper(
                      child: SizedBox(width: 200, height: 48),
                      key: ValueKey('disabled'),
                      isEnabled: false,
                      isFocused: true,
                    ),
                    AuraFieldWrapper(
                      child: SizedBox(width: 200, height: 48),
                      key: ValueKey('readonly'),
                      isReadOnly: true,
                      isFocused: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        Finder container(String key) => find.descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.byType(AnimatedContainer),
        );
        AnimatedContainer field(String key) =>
            tester.widget<AnimatedContainer>(container(key));
        for (final key in [
          'normal',
          'focused',
          'error',
          'success-focused',
          'warning-focused',
          'disabled',
          'readonly',
        ]) {
          expect(
            field(key).decoration,
            isA<BoxDecoration>().having(
              (decoration) => decoration.boxShadow,
              'boxShadow',
              isNull,
            ),
          );
        }

        BorderSide? outline(String key) =>
            (field(key).foregroundDecoration as BoxDecoration?)?.border?.top;
        expect(outline('normal'), isNull);
        expect(outline('disabled'), isNull);
        expect(outline('focused')?.color, theme.colors.primary);
        expect(outline('focused')?.width, 2);
        expect(outline('error')?.color, theme.colors.error);
        expect(outline('error')?.width, 2);
        expect(outline('success-focused')?.color, theme.colors.primary);
        expect(outline('warning-focused')?.color, theme.colors.primary);
        expect(outline('readonly')?.color, theme.colors.primary);
        expect(
          ColorContrast.wcagContrastRatio(
            theme.colors.primary,
            theme.colors.surface,
          ),
          greaterThanOrEqualTo(3),
        );
        expect(
          ColorContrast.wcagContrastRatio(
            theme.colors.primary,
            theme.colors.surfaceVariant,
          ),
          greaterThanOrEqualTo(3),
        );
        expect(
          tester.getSize(container('focused')),
          tester.getSize(container('normal')),
        );
        expect(find.text('Required'), findsOneWidget);
      }
    });

    testWidgets('renders error state and handles tap', (tester) async {
      var taps = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraFieldWrapper(
              child: const SizedBox(
                key: .new('field-child'),
                width: 20,
                height: 20,
              ),
              error: const Text('Required'),
              state: .error,
              onTap: () => taps++,
            ),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const Key('field-child')),
        warnIfMissed: false,
      );
      await tester.pump();

      expect(find.text('Required'), findsOneWidget);
      expect(taps, 1);
    });

    testWidgets('does not call tap when disabled', (tester) async {
      var taps = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraFieldWrapper(
              child: const SizedBox(
                key: .new('field-child'),
                width: 20,
                height: 20,
              ),
              isEnabled: false,
              onTap: () => taps++,
            ),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const Key('field-child')),
        warnIfMissed: false,
      );
      await tester.pump();

      expect(taps, 0);
    });
  });
}
