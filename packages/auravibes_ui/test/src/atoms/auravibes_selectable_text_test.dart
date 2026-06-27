// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_ui/src/atoms/aura_selectable_text.dart';
import 'package:auravibes_ui/src/atoms/aura_text.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final AuraTypographyScale typography = AuraTheme.light.typography;

void main() {
  group('AuraSelectableText', () {
    testWidgets('renders text correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(
            body: AuraSelectableText('Selectable text'),
          ),
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
        ),
      );

      expect(find.text('Selectable text'), findsOneWidget);
      expect(find.byType(SelectableText), findsOneWidget);
    });

    testWidgets('has default style as body', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                const widget = AuraSelectableText('Test');
                expect(widget.style, AuraTextStyle.body);

                return widget;
              },
            ),
          ),
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
        ),
      );
    });

    testWidgets('applies heading1 style', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(
            body: AuraSelectableText(
              'Heading 1',
              style: AuraTextStyle.heading1,
            ),
          ),
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
        ),
      );

      final selectableText = tester.widget<SelectableText>(
        find.byType(SelectableText),
      );
      expect(selectableText.style?.fontSize, typography.fontSize5Xl);
      expect(selectableText.style?.fontWeight, typography.fontWeightBold);
    });

    testWidgets('applies heading2 style', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(
            body: AuraSelectableText(
              'Heading 2',
              style: AuraTextStyle.heading2,
            ),
          ),
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
        ),
      );

      final selectableText = tester.widget<SelectableText>(
        find.byType(SelectableText),
      );
      expect(selectableText.style?.fontSize, typography.fontSize4Xl);
    });

    testWidgets('applies heading3 style', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(
            body: AuraSelectableText(
              'Heading 3',
              style: AuraTextStyle.heading3,
            ),
          ),
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
        ),
      );

      final selectableText = tester.widget<SelectableText>(
        find.byType(SelectableText),
      );
      expect(selectableText.style?.fontSize, typography.fontSize3Xl);
    });

    testWidgets('applies bodyLarge style', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(
            body: AuraSelectableText(
              'Body Large',
              style: AuraTextStyle.bodyLarge,
            ),
          ),
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
        ),
      );

      final selectableText = tester.widget<SelectableText>(
        find.byType(SelectableText),
      );
      expect(selectableText.style?.fontSize, typography.fontSizeLg);
    });

    testWidgets('applies bodySmall style', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(
            body: AuraSelectableText(
              'Body Small',
              style: AuraTextStyle.bodySmall,
            ),
          ),
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
        ),
      );

      final selectableText = tester.widget<SelectableText>(
        find.byType(SelectableText),
      );
      expect(selectableText.style?.fontSize, typography.fontSizeSm);
    });

    testWidgets('applies caption style', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(
            body: AuraSelectableText(
              'Caption',
              style: AuraTextStyle.caption,
            ),
          ),
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
        ),
      );

      final selectableText = tester.widget<SelectableText>(
        find.byType(SelectableText),
      );
      expect(selectableText.style?.fontSize, typography.fontSizeXs);
    });

    testWidgets('applies code style', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(
            body: AuraSelectableText(
              'Code text',
              style: AuraTextStyle.code,
            ),
          ),
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
        ),
      );

      final selectableText = tester.widget<SelectableText>(
        find.byType(SelectableText),
      );
      expect(
        selectableText.style?.fontFamily,
        typography.monoFontFamily,
      );
    });

    testWidgets('applies tint', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(
            body: AuraSelectableText(
              'Error text',
              tint: AuraTint.error,
            ),
          ),
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
        ),
      );

      final selectableText = tester.widget<SelectableText>(
        find.byType(SelectableText),
      );
      expect(selectableText.style?.color, AuraTheme.light.colors.error);
    });

    testWidgets('respects textAlign', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(
            body: AuraSelectableText(
              'Centered text',
              textAlign: TextAlign.center,
            ),
          ),
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
        ),
      );

      final selectableText = tester.widget<SelectableText>(
        find.byType(SelectableText),
      );
      expect(selectableText.textAlign, TextAlign.center);
    });

    testWidgets('respects maxLines', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(
            body: AuraSelectableText(
              'Limited lines',
              maxLines: 2,
            ),
          ),
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
        ),
      );

      final selectableText = tester.widget<SelectableText>(
        find.byType(SelectableText),
      );
      expect(selectableText.maxLines, 2);
    });

    testWidgets('handles onTap callback', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraSelectableText(
              'Tap me',
              onTap: () {
                tapped = true;
              },
            ),
          ),
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
        ),
      );

      await tester.tap(find.text('Tap me'));
      expect(tapped, true);
    });

    testWidgets('uses default cursor color from theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(
            body: AuraSelectableText('Cursor test'),
          ),
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
        ),
      );

      final selectableText = tester.widget<SelectableText>(
        find.byType(SelectableText),
      );
      expect(selectableText.cursorColor, AuraTheme.light.colors.primary);
    });

    testWidgets('respects custom cursorTint', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(
            body: AuraSelectableText(
              'Custom cursor',
              cursorTint: AuraTint.secondary,
            ),
          ),
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
        ),
      );

      final selectableText = tester.widget<SelectableText>(
        find.byType(SelectableText),
      );
      expect(selectableText.cursorColor, AuraTheme.light.colors.secondary);
    });

    testWidgets('respects cursorWidth', (tester) async {
      const customWidth = 4.0;

      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(
            body: AuraSelectableText(
              'Wide cursor',
              cursorWidth: customWidth,
            ),
          ),
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
        ),
      );

      final selectableText = tester.widget<SelectableText>(
        find.byType(SelectableText),
      );
      expect(selectableText.cursorWidth, customWidth);
    });

    testWidgets('respects minLines', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(
            body: AuraSelectableText(
              'Min lines',
              minLines: 2,
            ),
          ),
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
        ),
      );

      final selectableText = tester.widget<SelectableText>(
        find.byType(SelectableText),
      );
      expect(selectableText.minLines, 2);
    });
  });
}
