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
                onChanged: (_) => fail('Unexpected selection'),
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
                onChanged: (_) {
                  final _ = Object();
                },
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
                onChanged: (_) {
                  final _ = Object();
                },
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
                onChanged: (_) {
                  final _ = Object();
                },
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
                onChanged: (_) {
                  final _ = Object();
                },
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

    testWidgets('tabs to trigger and opens with enter', (tester) async {
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
                onChanged: (_) {
                  final _ = Object();
                },
                placeholder: const Text('Select'),
              ),
            ),
          ),
        ),
      );

      expect(await tester.sendKeyEvent(LogicalKeyboardKey.tab), isTrue);
      await tester.pump();
      expect(find.text('Option 1'), findsNothing);

      expect(await tester.sendKeyEvent(LogicalKeyboardKey.enter), isTrue);
      await tester.pump();
      expect(find.text('Option 1'), findsOneWidget);

      final _ = await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.text('Option 1'), findsNothing);
    });

    testWidgets('tab from closed dropdown moves to next visible button', (
      tester,
    ) async {
      var buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Portal(
              child: Row(
                children: [
                  SizedBox(
                    width: 200,
                    child: AuraDropdownSelector<String>(
                      options: const [
                        AuraDropdownOption(
                          value: 'Option 1',
                          child: Text('Option 1'),
                        ),
                      ],
                      onChanged: (_) => fail('Unexpected selection'),
                      placeholder: const Text('Select'),
                    ),
                  ),
                  TextButton(
                    onPressed: () => buttonPressed = true,
                    child: const Text('Next'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(await tester.sendKeyEvent(LogicalKeyboardKey.tab), isTrue);
      await tester.pump();
      expect(find.text('Option 1'), findsNothing);

      expect(await tester.sendKeyEvent(LogicalKeyboardKey.tab), isTrue);
      await tester.pump();
      expect(find.text('Option 1'), findsNothing);

      expect(await tester.sendKeyEvent(LogicalKeyboardKey.enter), isTrue);
      await tester.pump();
      expect(buttonPressed, isTrue);
    });

    testWidgets('tab loops inside open dropdown menu', (tester) async {
      var buttonPressed = false;
      String? selectedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Portal(
              child: Row(
                children: [
                  SizedBox(
                    width: 200,
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
                      onChanged: (value) => selectedValue = value,
                      placeholder: const Text('Select'),
                    ),
                  ),
                  TextButton(
                    onPressed: () => buttonPressed = true,
                    child: const Text('Next'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(await tester.sendKeyEvent(LogicalKeyboardKey.tab), isTrue);
      await tester.pump();

      expect(await tester.sendKeyEvent(LogicalKeyboardKey.enter), isTrue);
      await tester.pump();
      await tester.pump();
      expect(find.text('Option 1'), findsOneWidget);

      expect(await tester.sendKeyEvent(LogicalKeyboardKey.tab), isTrue);
      await tester.pump();
      expect(await tester.sendKeyEvent(LogicalKeyboardKey.tab), isTrue);
      await tester.pump();
      expect(await tester.sendKeyEvent(LogicalKeyboardKey.tab), isTrue);
      await tester.pump();

      expect(await tester.sendKeyEvent(LogicalKeyboardKey.enter), isTrue);
      await tester.pump();

      expect(selectedValue, isNotNull);
      expect(buttonPressed, isFalse);
    });

    testWidgets('keeps dropdown open when header input gets focus', (
      tester,
    ) async {
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
                onChanged: (_) => fail('Unexpected selection'),
                placeholder: const Text('Select'),
                header: const TextField(),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Select'));
      await tester.pump();
      expect(find.text('Option 1'), findsOneWidget);

      await tester.tap(find.byType(TextField));
      await tester.pump();

      expect(find.text('Option 1'), findsOneWidget);
    });

    testWidgets('closes dropdown when empty screen space is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Portal(
              child: Center(
                child: AuraDropdownSelector<String>(
                  options: const [
                    AuraDropdownOption(
                      value: 'Option 1',
                      child: Text('Option 1'),
                    ),
                  ],
                  onChanged: (_) {
                    final _ = Object();
                  },
                  placeholder: const Text('Select'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Select'));
      await tester.pump();
      expect(find.text('Option 1'), findsOneWidget);

      await tester.tapAt(const Offset(10, 10));
      await tester.pump();

      expect(find.text('Option 1'), findsNothing);
    });

    testWidgets('keeps bottom dropdown inside viewport bounds', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Portal(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: 200,
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
                    onChanged: (_) {
                      final _ = Object();
                    },
                    placeholder: const Text('Select'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Select'));
      await tester.pump();

      final optionTop = tester.getTopLeft(find.text('Option 1')).dy;
      final optionBottom = tester.getBottomLeft(find.text('Option 2')).dy;

      expect(optionTop, greaterThanOrEqualTo(0));
      expect(optionBottom, lessThanOrEqualTo(400));
    });

    testWidgets('selects option while outside barrier is active', (
      tester,
    ) async {
      String? selectedValue;

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
                onChanged: (value) {
                  selectedValue = value;
                },
                placeholder: const Text('Select'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Select'));
      await tester.pump();

      await tester.tap(find.text('Option 1'));
      await tester.pump();

      expect(selectedValue, 'Option 1');
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
                onChanged: (_) {
                  final _ = Object();
                },
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
                onChanged: (_) {
                  final _ = Object();
                },
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
                onChanged: (_) {
                  final _ = Object();
                },
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
                    onChanged: (_) {
                      final _ = Object();
                    },
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
