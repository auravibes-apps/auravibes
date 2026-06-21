// Required: Tests use intentional no-op callbacks.

import 'package:auravibes_ui/src/molecules/aura_checkbox.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraCheckbox', () {
    testWidgets('does not use Material Checkbox widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraCheckbox(
              value: false,
              onChanged: (_) {
                final _ = Object();
              },
            ),
          ),
          theme: ThemeData(extensions: [AuraTheme.light]),
        ),
      );

      expect(find.byType(Checkbox), findsNothing);
      expect(find.byType(FocusableActionDetector), findsOneWidget);
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
      final _ = await tester.pumpAndSettle();

      expect(selectedValue, isTrue);
    });

    testWidgets(
      'calls onChanged with toggled value when activated by keyboard',
      (
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

        expect(await tester.sendKeyEvent(LogicalKeyboardKey.tab), isTrue);
        await tester.pump();
        expect(await tester.sendKeyEvent(LogicalKeyboardKey.space), isTrue);
        expect(await tester.pumpAndSettle(), greaterThanOrEqualTo(1));

        expect(selectedValue, isTrue);
      },
    );

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
      final _ = await tester.pumpAndSettle();

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
              onChanged: (_) {
                final _ = Object();
              },
              title: const Text('Optional'),
              subtitle: const Text('Can be omitted'),
            ),
          ),
          theme: ThemeData(extensions: [AuraTheme.light]),
        ),
      );

      expect(find.text('Optional'), findsOneWidget);
      expect(find.text('Can be omitted'), findsOneWidget);
      expect(find.byType(FocusableActionDetector), findsOneWidget);
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
      final _ = await tester.pumpAndSettle();

      expect(selectedValue, isTrue);
    });

    testWidgets('calls onChanged when row is activated by keyboard', (
      tester,
    ) async {
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

      expect(await tester.sendKeyEvent(LogicalKeyboardKey.tab), isTrue);
      await tester.pump();
      expect(await tester.sendKeyEvent(LogicalKeyboardKey.enter), isTrue);
      expect(await tester.pumpAndSettle(), greaterThanOrEqualTo(1));

      expect(selectedValue, isTrue);
    });
  });
}
