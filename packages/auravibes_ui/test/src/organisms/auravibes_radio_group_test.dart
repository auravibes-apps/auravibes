import 'package:auravibes_ui/src/molecules/auravibes_radio.dart';
import 'package:auravibes_ui/src/organisms/auravibes_radio_group.dart';
import 'package:auravibes_ui/src/tokens/auravibes_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraRadioGroup', () {
    testWidgets('renders all options', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AuraTheme.light],
          ),
          home: Scaffold(
            body: AuraRadioGroup<String>(
              value: null,
              onChanged: (_) {},
              options: const [
                AuraRadioOption(value: 'option1', label: Text('Option 1')),
                AuraRadioOption(value: 'option2', label: Text('Option 2')),
                AuraRadioOption(value: 'option3', label: Text('Option 3')),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Option 1'), findsOneWidget);
      expect(find.text('Option 2'), findsOneWidget);
      expect(find.text('Option 3'), findsOneWidget);
      expect(find.byType(AuraRadio<String>), findsNWidgets(3));
    });

    testWidgets('renders nothing when options is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AuraTheme.light],
          ),
          home: Scaffold(
            body: AuraRadioGroup<String>(
              value: null,
              onChanged: (_) {},
              options: const [],
            ),
          ),
        ),
      );

      expect(find.byType(AuraRadio<String>), findsNothing);
    });

    testWidgets('shows correct selection', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AuraTheme.light],
          ),
          home: Scaffold(
            body: AuraRadioGroup<String>(
              value: 'option2',
              onChanged: (_) {},
              options: const [
                AuraRadioOption(value: 'option1', label: Text('Option 1')),
                AuraRadioOption(value: 'option2', label: Text('Option 2')),
              ],
            ),
          ),
        ),
      );

      // Verify both radios exist and groupValue is correct
      final radios = tester.widgetList<AuraRadio<String>>(
        find.byType(AuraRadio<String>),
      );
      expect(radios.length, 2);

      // All radios should have the same groupValue
      for (final radio in radios) {
        expect(radio.groupValue, 'option2');
      }
    });

    testWidgets('calls onChanged when option is tapped', (tester) async {
      String? selectedValue;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AuraTheme.light],
          ),
          home: Scaffold(
            body: AuraRadioGroup<String>(
              value: null,
              onChanged: (value) => selectedValue = value,
              options: const [
                AuraRadioOption(value: 'option1', label: Text('Option 1')),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AuraRadio<String>));
      await tester.pumpAndSettle();

      expect(selectedValue, 'option1');
    });

    testWidgets('renders with label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AuraTheme.light],
          ),
          home: Scaffold(
            body: AuraRadioGroup<String>(
              value: null,
              onChanged: (_) {},
              options: const [
                AuraRadioOption(value: 'option1', label: Text('Option 1')),
              ],
              label: const Text('Select an option'),
            ),
          ),
        ),
      );

      expect(find.text('Select an option'), findsOneWidget);
    });

    testWidgets('renders options with subtitles', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AuraTheme.light],
          ),
          home: Scaffold(
            body: AuraRadioGroup<String>(
              value: null,
              onChanged: (_) {},
              options: const [
                AuraRadioOption(
                  value: 'option1',
                  label: Text('Option 1'),
                  subtitle: Text('Subtitle 1'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Option 1'), findsOneWidget);
      expect(find.text('Subtitle 1'), findsOneWidget);
    });

    testWidgets('renders horizontal layout', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AuraTheme.light],
          ),
          home: Scaffold(
            body: SizedBox(
              width: 800,
              child: AuraRadioGroup<String>(
                value: null,
                onChanged: (_) {},
                direction: Axis.horizontal,
                options: const [
                  AuraRadioOption(value: 'option1', label: Text('Option 1')),
                  AuraRadioOption(value: 'option2', label: Text('Option 2')),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Wrap), findsOneWidget);
    });

    testWidgets('applies colorVariant to all radios', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AuraTheme.light],
          ),
          home: Scaffold(
            body: AuraRadioGroup<String>(
              value: null,
              onChanged: (_) {},
              colorVariant: AuraColorVariant.secondary,
              options: const [
                AuraRadioOption(value: 'option1', label: Text('Option 1')),
              ],
            ),
          ),
        ),
      );

      final radio = tester.widget<AuraRadio<String>>(
        find.byType(AuraRadio<String>),
      );
      expect(radio.colorVariant, AuraColorVariant.secondary);
    });
  });

  group('AuraRadioListTile', () {
    testWidgets('does NOT use Material RadioListTile', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AuraTheme.light],
          ),
          home: Scaffold(
            body: AuraRadioListTile<String>(
              value: 'option1',
              groupValue: null,
              onChanged: (_) {},
              title: const Text('Option 1'),
            ),
          ),
        ),
      );

      // The custom implementation should NOT use RadioListTile
      expect(find.byType(RadioListTile<String>), findsNothing);
      // It SHOULD use the custom AuraRadio widget
      expect(find.byType(AuraRadio<String>), findsOneWidget);
    });

    testWidgets('renders with title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AuraTheme.light],
          ),
          home: Scaffold(
            body: AuraRadioListTile<String>(
              value: 'option1',
              groupValue: null,
              onChanged: (_) {},
              title: const Text('Option 1'),
            ),
          ),
        ),
      );

      expect(find.text('Option 1'), findsOneWidget);
      expect(find.byType(AuraRadio<String>), findsOneWidget);
    });

    testWidgets('renders with subtitle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AuraTheme.light],
          ),
          home: Scaffold(
            body: AuraRadioListTile<String>(
              value: 'option1',
              groupValue: null,
              onChanged: (_) {},
              title: const Text('Option 1'),
              subtitle: const Text('Subtitle text'),
            ),
          ),
        ),
      );

      expect(find.text('Option 1'), findsOneWidget);
      expect(find.text('Subtitle text'), findsOneWidget);
    });

    testWidgets('shows as selected when value matches groupValue', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AuraTheme.light],
          ),
          home: Scaffold(
            body: AuraRadioListTile<String>(
              value: 'option1',
              groupValue: 'option1',
              onChanged: (_) {},
              title: const Text('Option 1'),
            ),
          ),
        ),
      );

      final radio = tester.widget<AuraRadio<String>>(
        find.byType(AuraRadio<String>),
      );
      expect(radio.groupValue, 'option1');
    });

    testWidgets('calls onChanged when tapped', (tester) async {
      String? selectedValue;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AuraTheme.light],
          ),
          home: Scaffold(
            body: AuraRadioListTile<String>(
              value: 'option1',
              groupValue: null,
              onChanged: (value) => selectedValue = value,
              title: const Text('Option 1'),
            ),
          ),
        ),
      );

      // Tap on the AuraRadio widget inside the AuraRadioListTile
      await tester.tap(find.byType(AuraRadio<String>));
      await tester.pumpAndSettle();

      expect(selectedValue, 'option1');
    });

    testWidgets('is disabled when disabled is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AuraTheme.light],
          ),
          home: Scaffold(
            body: AuraRadioListTile<String>(
              value: 'option1',
              groupValue: null,
              onChanged: (_) {},
              title: const Text('Option 1'),
              disabled: true,
            ),
          ),
        ),
      );

      final radio = tester.widget<AuraRadio<String>>(
        find.byType(AuraRadio<String>),
      );
      expect(radio.disabled, isTrue);
    });

    testWidgets('applies colorVariant', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AuraTheme.light],
          ),
          home: Scaffold(
            body: AuraRadioListTile<String>(
              value: 'option1',
              groupValue: 'option1',
              onChanged: (_) {},
              title: const Text('Option 1'),
              colorVariant: AuraColorVariant.secondary,
            ),
          ),
        ),
      );

      final radio = tester.widget<AuraRadio<String>>(
        find.byType(AuraRadio<String>),
      );
      expect(radio.colorVariant, AuraColorVariant.secondary);
    });
  });
}
