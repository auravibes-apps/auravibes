import 'package:auravibes_ui/src/atoms/auravibes_selectable_text.dart';
import 'package:auravibes_ui/src/atoms/auravibes_text.dart';
import 'package:auravibes_ui/src/tokens/auravibes_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraSelectableText', () {
    testWidgets('renders text correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
          home: const Scaffold(
            body: AuraSelectableText('Selectable text'),
          ),
        ),
      );

      expect(find.text('Selectable text'), findsOneWidget);
      expect(find.byType(SelectableText), findsOneWidget);
    });

    testWidgets('has default style as body', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                const widget = AuraSelectableText('Test');
                expect(widget.style, AuraTextStyle.body);
                return widget;
              },
            ),
          ),
        ),
      );
    });

    testWidgets('applies heading1 style', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
          home: const Scaffold(
            body: AuraSelectableText(
              'Heading 1',
              style: AuraTextStyle.heading1,
            ),
          ),
        ),
      );

      final selectableText = tester.widget<SelectableText>(
        find.byType(SelectableText),
      );
      expect(selectableText.style?.fontSize, DesignTypography.fontSize5Xl);
      expect(selectableText.style?.fontWeight, DesignTypography.fontWeightBold);
    });

    testWidgets('applies heading2 style', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
          home: const Scaffold(
            body: AuraSelectableText(
              'Heading 2',
              style: AuraTextStyle.heading2,
            ),
          ),
        ),
      );

      final selectableText = tester.widget<SelectableText>(
        find.byType(SelectableText),
      );
      expect(selectableText.style?.fontSize, DesignTypography.fontSize4Xl);
    });

    testWidgets('applies heading3 style', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
          home: const Scaffold(
            body: AuraSelectableText(
              'Heading 3',
              style: AuraTextStyle.heading3,
            ),
          ),
        ),
      );

      final selectableText = tester.widget<SelectableText>(
        find.byType(SelectableText),
      );
      expect(selectableText.style?.fontSize, DesignTypography.fontSize3Xl);
    });

    testWidgets('applies bodyLarge style', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
          home: const Scaffold(
            body: AuraSelectableText(
              'Body Large',
              style: AuraTextStyle.bodyLarge,
            ),
          ),
        ),
      );

      final selectableText = tester.widget<SelectableText>(
        find.byType(SelectableText),
      );
      expect(selectableText.style?.fontSize, DesignTypography.fontSizeLg);
    });

    testWidgets('applies bodySmall style', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
          home: const Scaffold(
            body: AuraSelectableText(
              'Body Small',
              style: AuraTextStyle.bodySmall,
            ),
          ),
        ),
      );

      final selectableText = tester.widget<SelectableText>(
        find.byType(SelectableText),
      );
      expect(selectableText.style?.fontSize, DesignTypography.fontSizeSm);
    });

    testWidgets('applies caption style', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
          home: const Scaffold(
            body: AuraSelectableText(
              'Caption',
              style: AuraTextStyle.caption,
            ),
          ),
        ),
      );

      final selectableText = tester.widget<SelectableText>(
        find.byType(SelectableText),
      );
      expect(selectableText.style?.fontSize, DesignTypography.fontSizeXs);
    });

    testWidgets('applies code style', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
          home: const Scaffold(
            body: AuraSelectableText(
              'Code text',
              style: AuraTextStyle.code,
            ),
          ),
        ),
      );

      final selectableText = tester.widget<SelectableText>(
        find.byType(SelectableText),
      );
      expect(
        selectableText.style?.fontFamily,
        DesignTypography.monoFontFamily,
      );
    });

    testWidgets('applies colorVariant', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
          home: const Scaffold(
            body: AuraSelectableText(
              'Error text',
              colorVariant: AuraColorVariant.error,
            ),
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
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
          home: const Scaffold(
            body: AuraSelectableText(
              'Centered text',
              textAlign: TextAlign.center,
            ),
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
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
          home: const Scaffold(
            body: AuraSelectableText(
              'Limited lines',
              maxLines: 2,
            ),
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
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
          home: Scaffold(
            body: AuraSelectableText(
              'Tap me',
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap me'));
      expect(tapped, true);
    });

    testWidgets('uses default cursor color from theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
          home: const Scaffold(
            body: AuraSelectableText('Cursor test'),
          ),
        ),
      );

      final selectableText = tester.widget<SelectableText>(
        find.byType(SelectableText),
      );
      expect(selectableText.cursorColor, AuraTheme.light.colors.primary);
    });

    testWidgets('respects custom cursorColor', (tester) async {
      const customCursorColor = Color(0xFF00FF00);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
          home: const Scaffold(
            body: AuraSelectableText(
              'Custom cursor',
              cursorColor: customCursorColor,
            ),
          ),
        ),
      );

      final selectableText = tester.widget<SelectableText>(
        find.byType(SelectableText),
      );
      expect(selectableText.cursorColor, customCursorColor);
    });

    testWidgets('respects cursorWidth', (tester) async {
      const customWidth = 4.0;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
          home: const Scaffold(
            body: AuraSelectableText(
              'Wide cursor',
              cursorWidth: customWidth,
            ),
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
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
          home: const Scaffold(
            body: AuraSelectableText(
              'Min lines',
              minLines: 2,
            ),
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
