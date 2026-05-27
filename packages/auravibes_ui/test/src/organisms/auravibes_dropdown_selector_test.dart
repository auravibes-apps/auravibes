import 'package:auravibes_ui/src/molecules/aura_dropdown_option.dart';
import 'package:auravibes_ui/src/organisms/aura_dropdown_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraDropdownSelector', () {
    testWidgets('renders with placeholder when value is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Portal(
              child: AuraDropdownSelector<String>(
                options: const [],
                onChanged: (_) {},
                placeholder: const Text('Select an option'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Select an option'), findsOneWidget);
    });

    testWidgets('renders with selected value text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Portal(
              child: AuraDropdownSelector<String>(
                options: const [
                  AuraDropdownOption(
                    value: 'Selected',
                    child: Text('Selected'),
                  ),
                ],
                value: 'Selected',
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Selected'), findsOneWidget);
    });

    testWidgets('opens dropdown on tap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Portal(
              child: AuraDropdownSelector<String>(
                options: const [
                  AuraDropdownOption(
                    value: 'Option 1',
                    child: Text('Option 1'),
                  ),
                  AuraDropdownOption(
                    value: 'Option 2',
                    child: Text('Option 2'),
                  ),
                ],
                onChanged: (_) {},
                placeholder: const Text('Select'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Option 1'), findsNothing);

      await tester.tap(find.text('Select'));
      await tester.pump();

      expect(find.text('Option 1'), findsOneWidget);
      expect(find.text('Option 2'), findsOneWidget);
    });

    testWidgets('highlights selected option in dropdown', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Portal(
              child: AuraDropdownSelector<String>(
                options: const [
                  AuraDropdownOption(
                    value: 'Option 1',
                    child: Text('Option 1'),
                  ),
                  AuraDropdownOption(
                    value: 'Option 2',
                    child: Text('Option 2'),
                  ),
                ],
                value: 'Option 2',
                onChanged: (_) {},
                placeholder: const Text('Select'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Option 2'));
      await tester.pump();

      expect(find.text('Option 1'), findsOneWidget);
      expect(find.text('Option 2'), findsNWidgets(2));
    });

    testWidgets('closes dropdown on escape key', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Portal(
              child: AuraDropdownSelector<String>(
                options: const [
                  AuraDropdownOption(
                    value: 'Option 1',
                    child: Text('Option 1'),
                  ),
                ],
                onChanged: (_) {},
                placeholder: const Text('Select'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Select'));
      await tester.pump();
      expect(find.text('Option 1'), findsOneWidget);

      final _ = await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(find.text('Option 1'), findsNothing);
    });

    testWidgets('renders with custom optionBuilder', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Portal(
              child: AuraDropdownSelector<String>(
                options: const [
                  AuraDropdownOption(
                    value: 'Option 1',
                    child: Text('Option 1'),
                  ),
                ],
                onChanged: (_) {},
                placeholder: const Text('Select'),
                optionBuilder: (context, option) =>
                    Text('Custom: ${option.value}'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Select'));
      await tester.pump();

      expect(find.text('Custom: Option 1'), findsOneWidget);
    });

    testWidgets('renders with leading icon in dropdown', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Portal(
              child: AuraDropdownSelector<String>(
                options: const [
                  AuraDropdownOption(
                    value: 'Option 1',
                    child: Text('Option 1'),
                    leading: Icon(Icons.star),
                  ),
                ],
                onChanged: (_) {},
                placeholder: const Text('Select'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Select'));
      await tester.pump();

      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('renders disabled state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Portal(
              child: AuraDropdownSelector<String>(
                options: const [
                  AuraDropdownOption(
                    value: 'Option 1',
                    child: Text('Option 1'),
                  ),
                ],
                onChanged: (_) {},
                placeholder: const Text('Select'),
                isEnabled: false,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Select'));
      await tester.pump();

      expect(find.text('Option 1'), findsNothing);
    });

    testWidgets('closes on escape key', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Portal(
              child: Column(
                children: [
                  AuraDropdownSelector<String>(
                    options: const [
                      AuraDropdownOption(
                        value: 'Option 1',
                        child: Text('Option 1'),
                      ),
                    ],
                    onChanged: (_) {},
                    placeholder: const Text('Select'),
                  ),
                  const SizedBox(height: 100),
                  const Text('Outside'),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Select'));
      await tester.pump();
      expect(find.text('Option 1'), findsOneWidget);

      final _ = await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(find.text('Option 1'), findsNothing);
    });
  });
}
