// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_ui/src/atoms/aura_selectable_text.dart';
import 'package:auravibes_ui/src/atoms/aura_text.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final AuraTypographyScale typography = AuraTheme.light.typography;

void main() {
  group('AuraSelectableText', () {
    testWidgets('renders text with configured styles and properties', (
      tester,
    ) async {
      await tester.pumpWidget(
        AuraThemeScope(
          theme: .light,
          child: MaterialApp(
            home: const Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  mainAxisSize: .min,
                  children: [
                    AuraSelectableText('Selectable text'),
                    AuraSelectableText('Test'),
                    AuraSelectableText('Heading 1', style: .heading1),
                    AuraSelectableText('Heading 2', style: .heading2),
                    AuraSelectableText('Heading 3', style: .heading3),
                    AuraSelectableText('Body Large', style: .bodyLarge),
                    AuraSelectableText('Body Small', style: .bodySmall),
                    AuraSelectableText('Caption', style: .caption),
                    AuraSelectableText('Code text', style: .code),
                    AuraSelectableText('Error text', tint: .error),
                    AuraSelectableText('Centered text', textAlign: .center),
                    AuraSelectableText('Limited lines', maxLines: 2),
                    AuraSelectableText('Cursor test'),
                    AuraSelectableText('Custom cursor', cursorTint: .secondary),
                    AuraSelectableText('Wide cursor', cursorWidth: 4),
                    AuraSelectableText('Min lines', minLines: 2),
                  ],
                ),
              ),
            ),
            theme: ThemeData.light().copyWith(),
          ),
        ),
      );

      expect(find.text('Selectable text'), findsOneWidget);
      expect(find.byType(SelectableText), findsNWidgets(16));

      SelectableText selectableText(String text) =>
          tester.widget<SelectableText>(
            find.ancestor(
              of: find.text(text),
              matching: find.byType(SelectableText),
            ),
          );

      final defaultStyle = tester.widget<AuraSelectableText>(
        find.byWidgetPredicate(
          (widget) => widget is AuraSelectableText && widget.data == 'Test',
        ),
      );
      expect(defaultStyle.style, AuraTextStyle.body);
      expect(
        selectableText('Heading 1').style?.fontSize,
        typography.fontSize5Xl,
      );
      expect(
        selectableText('Heading 1').style?.fontWeight,
        typography.fontWeightBold,
      );
      expect(
        selectableText('Heading 2').style?.fontSize,
        typography.fontSize4Xl,
      );
      expect(
        selectableText('Heading 3').style?.fontSize,
        typography.fontSize3Xl,
      );
      expect(
        selectableText('Body Large').style?.fontSize,
        typography.fontSizeLg,
      );
      expect(
        selectableText('Body Small').style?.fontSize,
        typography.fontSizeSm,
      );
      expect(selectableText('Caption').style?.fontSize, typography.fontSizeXs);
      expect(
        selectableText('Code text').style?.fontFamily,
        typography.monoFontFamily,
      );
      expect(
        selectableText('Error text').style?.color,
        AuraTheme.light.colors.error,
      );
      expect(selectableText('Centered text').textAlign, TextAlign.center);
      expect(selectableText('Limited lines').maxLines, 2);
      expect(
        selectableText('Cursor test').cursorColor,
        AuraTheme.light.colors.primary,
      );
      expect(
        selectableText('Custom cursor').cursorColor,
        AuraTheme.light.colors.secondary,
      );
      expect(selectableText('Wide cursor').cursorWidth, 4);
      expect(selectableText('Min lines').minLines, 2);
    });

    testWidgets('handles onTap callback', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        AuraThemeScope(
          theme: .light,
          child: MaterialApp(
            home: Scaffold(
              body: AuraSelectableText(
                'Tap me',
                onTap: () {
                  tapped = true;
                },
              ),
            ),
            theme: ThemeData.light().copyWith(),
          ),
        ),
      );

      await tester.tap(find.text('Tap me'));
      expect(tapped, true);
    });

    testWidgets('sizes actionable text from the active interaction theme', (
      tester,
    ) async {
      var minimumTargetSize = 48.0;
      var tapped = false;

      Widget buildApp() => AuraThemeScope(
        theme: AuraTheme.light.copyWith(
          interactionSizes: .new(minimumTargetSize: minimumTargetSize),
        ),
        child: MaterialApp(
          home: Scaffold(
            body: AuraSelectableText('Tap me', onTap: () => tapped = true),
          ),
          theme: ThemeData.light().copyWith(),
        ),
      );

      await tester.pumpWidget(buildApp());
      final selectableText = find.byType(SelectableText);
      expect(tester.getSize(selectableText).height, 48);

      minimumTargetSize = 64;
      await tester.pumpWidget(buildApp());
      final _ = await tester.pumpAndSettle();

      expect(tester.getSize(selectableText).height, 64);
      await tester.tap(selectableText);
      expect(tapped, isTrue);
    });
  });
}
