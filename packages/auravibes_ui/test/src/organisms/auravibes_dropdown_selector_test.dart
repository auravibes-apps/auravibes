import 'package:auravibes_ui/src/molecules/auravibes_dropdown_option.dart';
import 'package:auravibes_ui/src/organisms/auravibes_dropdown_selector.dart';
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
                placeholder: const Text('Select an option'),
                options: const [],
                onChanged: (_) {},
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
                value: 'Selected',
                options: const [
                  AuraDropdownOption(
                    value: 'Selected',
                    child: Text('Selected'),
                  ),
                ],
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
                placeholder: const Text('Select'),
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
                value: 'Option 2',
                placeholder: const Text('Select'),
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
                placeholder: const Text('Select'),
                options: const [
                  AuraDropdownOption(
                    value: 'Option 1',
                    child: Text('Option 1'),
                  ),
                ],
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Select'));
      await tester.pump();
      expect(find.text('Option 1'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(find.text('Option 1'), findsNothing);
    });

    testWidgets('renders with custom optionBuilder', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Portal(
              child: AuraDropdownSelector<String>(
                placeholder: const Text('Select'),
                options: const [
                  AuraDropdownOption(
                    value: 'Option 1',
                    child: Text('Option 1'),
                  ),
                ],
                optionBuilder: (context, option) =>
                    Text('Custom: ${option.value}'),
                onChanged: (_) {},
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
                placeholder: const Text('Select'),
                options: const [
                  AuraDropdownOption(
                    value: 'Option 1',
                    leading: Icon(Icons.star),
                    child: Text('Option 1'),
                  ),
                ],
                onChanged: (_) {},
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
                placeholder: const Text('Select'),
                isEnabled: false,
                options: const [
                  AuraDropdownOption(
                    value: 'Option 1',
                    child: Text('Option 1'),
                  ),
                ],
                onChanged: (_) {},
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
                    placeholder: const Text('Select'),
                    options: const [
                      AuraDropdownOption(
                        value: 'Option 1',
                        child: Text('Option 1'),
                      ),
                    ],
                    onChanged: (_) {},
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

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(find.text('Option 1'), findsNothing);
    });
  });
}
