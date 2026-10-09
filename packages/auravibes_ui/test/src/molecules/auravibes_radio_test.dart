import 'package:auravibes_ui/src/molecules/aura_radio_option.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraRadioOption', () {
    test('creates required and optional parameters', () {
      const defaultOption = AuraRadioOption<String>(
        value: 'test',
        label: Text('Test Label'),
      );
      const detailedOption = AuraRadioOption<String>(
        value: 'test',
        label: Text('Test Label'),
        subtitle: Text('Subtitle'),
        disabled: true,
      );

      expect(defaultOption.value, 'test');
      expect(defaultOption.label, isA<Text>());
      expect(defaultOption.subtitle, isNull);
      expect(defaultOption.disabled, isFalse);
      expect(detailedOption.subtitle, isA<Text>());
      expect(detailedOption.disabled, isTrue);
    });
  });

  group('AuraRadio', () {
    testWidgets('renders selection and interaction states', (tester) async {
      String? selectedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              mainAxisSize: .min,
              children: [
                AuraRadio<String>(
                  value: 'option1',
                  groupValue: 'option2',
                  onChanged: (value) => selectedValue = value,
                  key: const ValueKey('unselected'),
                ),
                const AuraRadio<String>(
                  value: 'option1',
                  groupValue: 'option1',
                  onChanged: _ignoreSelection,
                  key: ValueKey('selected-tinted'),
                  tint: .secondary,
                ),
              ],
            ),
          ),
        ),
      );

      Finder radio(String key) => find.byKey(ValueKey<String>(key));
      Finder within(Finder radio, Finder matching) =>
          find.descendant(of: radio, matching: matching);
      Semantics semantics(String key) => tester
          .widgetList<Semantics>(within(radio(key), find.byType(Semantics)))
          .firstWhere((semantics) => semantics.properties.checked != null);

      expect(find.byType(Radio<String>), findsNothing);
      expect(find.byType(AuraRadio<String>), findsNWidgets(2));
      expect(find.byType(CustomPaint), findsWidgets);
      expect(
        within(radio('unselected'), find.byType(GestureDetector)),
        findsOneWidget,
      );
      expect(
        within(radio('unselected'), find.byType(FocusableActionDetector)),
        findsOneWidget,
      );
      expect(
        within(radio('selected-tinted'), find.byType(CustomPaint)),
        findsWidgets,
      );
      expect(semantics('unselected').properties.checked, isFalse);
      expect(semantics('selected-tinted').properties.checked, isTrue);

      final opacity = tester.widget<Opacity>(
        within(radio('unselected'), find.byType(Opacity)),
      );
      expect(opacity.opacity, 1.0);

      await tester.tap(
        within(radio('unselected'), find.byType(GestureDetector)),
      );
      final _ = await tester.pumpAndSettle();

      expect(selectedValue, 'option1');
    });

    testWidgets('disabled variants ignore taps and reduce opacity', (
      tester,
    ) async {
      String? disabledValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              mainAxisSize: .min,
              children: [
                AuraRadio<String>(
                  value: 'option1',
                  groupValue: null,
                  onChanged: (value) => disabledValue = value,
                  key: const ValueKey('disabled'),
                  disabled: true,
                ),
                const AuraRadio<String>(
                  value: 'option1',
                  groupValue: null,
                  onChanged: null,
                  key: ValueKey('no-callback'),
                ),
              ],
            ),
          ),
        ),
      );

      Finder radio(String key) => find.byKey(ValueKey<String>(key));
      Finder gestureDetector(String key) => find.descendant(
        of: radio(key),
        matching: find.byType(GestureDetector),
      );
      Opacity opacity(String key) => tester.widget<Opacity>(
        find.descendant(of: radio(key), matching: find.byType(Opacity)),
      );

      await tester.tap(gestureDetector('disabled'));
      final _ = await tester.pumpAndSettle();
      await tester.tap(gestureDetector('no-callback'));
      final _ = await tester.pumpAndSettle();

      expect(disabledValue, isNull);
      expect(
        tester.widget<AuraRadio<String>>(radio('no-callback')).onChanged,
        isNull,
      );
      expect(opacity('disabled').opacity, 0.6);
      expect(opacity('no-callback').opacity, 0.6);
    });

    testWidgets('selects with keyboard activation', (tester) async {
      String? selectedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraRadio<String>(
              value: 'option1',
              groupValue: null,
              onChanged: (value) => selectedValue = value,
            ),
          ),
        ),
      );

      final _ = await tester.sendKeyEvent(.tab);
      await tester.pump();
      final _ = await tester.sendKeyEvent(.space);
      final _ = await tester.pumpAndSettle();

      expect(selectedValue, 'option1');
    });
  });
}

void _ignoreSelection(String? _) {
  final _ = Object();
}
