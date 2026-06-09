// ignore_for_file: no-magic-number
// Required: Tests use numeric fixtures and dimensions.
// ignore_for_file: no-empty-block
// Required: Tests use intentional no-op callbacks.

import 'package:auravibes_ui/src/molecules/aura_checkbox.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraCheckbox', () {
    testWidgets('does not use Material Checkbox widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraCheckbox(value: false, onChanged: (_) {}),
          ),
          theme: ThemeData(extensions: [AuraTheme.light]),
        ),
      );

      expect(find.byType(Checkbox), findsNothing);
      expect(find.byType(GestureDetector), findsOneWidget);
    });

    testWidgets('calls onChanged with toggled value when tapped', (
      tester,
    ) async {
      bool? selectedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraCheckbox(
              value: false,
              onChanged: (value) => selectedValue = value,
            ),
          ),
          theme: ThemeData(extensions: [AuraTheme.light]),
        ),
      );

      await tester.tap(find.byType(AuraCheckbox));
      await tester.pumpAndSettle();

      expect(selectedValue, isTrue);
    });

    testWidgets('does not call onChanged when disabled', (tester) async {
      bool? selectedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraCheckbox(
              value: false,
              onChanged: (value) => selectedValue = value,
              disabled: true,
            ),
          ),
          theme: ThemeData(extensions: [AuraTheme.light]),
        ),
      );

      await tester.tap(find.byType(AuraCheckbox));
      await tester.pumpAndSettle();

      expect(selectedValue, isNull);
    });
  });

  group('AuraCheckboxListTile', () {
    testWidgets('renders title and subtitle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraCheckboxListTile(
              value: false,
              onChanged: (_) {},
              title: const Text('Optional'),
              subtitle: const Text('Can be omitted'),
            ),
          ),
          theme: ThemeData(extensions: [AuraTheme.light]),
        ),
      );

      expect(find.text('Optional'), findsOneWidget);
      expect(find.text('Can be omitted'), findsOneWidget);
      expect(find.byType(AuraCheckbox), findsOneWidget);
    });

    testWidgets('calls onChanged when row is tapped', (tester) async {
      bool? selectedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraCheckboxListTile(
              value: false,
              onChanged: (value) => selectedValue = value,
              title: const Text('Optional'),
            ),
          ),
          theme: ThemeData(extensions: [AuraTheme.light]),
        ),
      );

      await tester.tap(find.byType(AuraCheckboxListTile));
      await tester.pumpAndSettle();

      expect(selectedValue, isTrue);
    });
  });
}
