import 'package:auravibes_ui/src/atoms/auravibes_loading.dart';
import 'package:auravibes_ui/src/organisms/auravibes_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraSwitch', () {
    group('Basic rendering', () {
      testWidgets('renders switch correctly with default values', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AuraSwitch(
                value: false,
                onChanged: (_) {},
              ),
            ),
          ),
        );

        expect(find.byType(AuraSwitch), findsOneWidget);
        expect(find.byType(GestureDetector), findsOneWidget);
        expect(find.byType(AnimatedContainer), findsWidgets);
      });

      testWidgets('renders switch in on state', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AuraSwitch(
                value: true,
                onChanged: (_) {},
              ),
            ),
          ),
        );

        final auraSwitch = tester.widget<AuraSwitch>(find.byType(AuraSwitch));
        expect(auraSwitch.value, isTrue);
      });

      testWidgets('renders switch in off state', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AuraSwitch(
                value: false,
                onChanged: (_) {},
              ),
            ),
          ),
        );

        final auraSwitch = tester.widget<AuraSwitch>(find.byType(AuraSwitch));
        expect(auraSwitch.value, isFalse);
      });
    });

    group('Interaction', () {
      testWidgets('calls onChanged when tapped', (tester) async {
        var wasChanged = false;
        bool? receivedValue;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AuraSwitch(
                value: false,
                onChanged: (value) {
                  wasChanged = true;
                  receivedValue = value;
                },
              ),
            ),
          ),
        );

        await tester.tap(find.byType(AuraSwitch));
        await tester.pump();

        expect(wasChanged, isTrue);
        expect(receivedValue, isTrue);
      });

      testWidgets('toggles value correctly when tapped (off to on)', (
        tester,
      ) async {
        bool? receivedValue;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AuraSwitch(
                value: false,
                onChanged: (value) => receivedValue = value,
              ),
            ),
          ),
        );

        await tester.tap(find.byType(AuraSwitch));
        await tester.pump();

        expect(receivedValue, isTrue);
      });

      testWidgets('toggles value correctly when tapped (on to off)', (
        tester,
      ) async {
        bool? receivedValue;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AuraSwitch(
                value: true,
                onChanged: (value) => receivedValue = value,
              ),
            ),
          ),
        );

        await tester.tap(find.byType(AuraSwitch));
        await tester.pump();

        expect(receivedValue, isFalse);
      });

      testWidgets('does not call onChanged when disabled', (tester) async {
        var wasChanged = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AuraSwitch(
                value: false,
                onChanged: (_) => wasChanged = true,
                disabled: true,
              ),
            ),
          ),
        );

        await tester.tap(find.byType(AuraSwitch));
        await tester.pump();

        expect(wasChanged, isFalse);
      });

      testWidgets('does not call onChanged when loading', (tester) async {
        var wasChanged = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AuraSwitch(
                value: false,
                onChanged: (_) => wasChanged = true,
                isLoading: true,
              ),
            ),
          ),
        );

        await tester.tap(find.byType(AuraSwitch));
        await tester.pump();

        expect(wasChanged, isFalse);
      });

      testWidgets('does not call onChanged when onChanged is null', (
        tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AuraSwitch(
                value: false,
                onChanged: null,
              ),
            ),
          ),
        );

        // Should not throw when tapped
        await tester.tap(find.byType(AuraSwitch));
        await tester.pump();

        // Widget should still render correctly
        expect(find.byType(AuraSwitch), findsOneWidget);
      });
    });

    group('Size variants', () {
      testWidgets('renders with sm size correctly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AuraSwitch(
                value: false,
                onChanged: (_) {},
                size: AuraSwitchSize.sm,
              ),
            ),
          ),
        );

        final auraSwitch = tester.widget<AuraSwitch>(find.byType(AuraSwitch));
        expect(auraSwitch.size, AuraSwitchSize.sm);

        // Verify the switch renders with smaller dimensions
        final animatedContainer = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer).first,
        );
        final constraints = animatedContainer.constraints;
        // sm size should have width of 36.0
        expect(constraints?.maxWidth, 36.0);
      });

      testWidgets('renders with base size correctly (default)', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AuraSwitch(
                value: false,
                onChanged: (_) {},
              ),
            ),
          ),
        );

        final auraSwitch = tester.widget<AuraSwitch>(find.byType(AuraSwitch));
        expect(auraSwitch.size, AuraSwitchSize.base);
      });

      testWidgets('renders with lg size correctly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AuraSwitch(
                value: false,
                onChanged: (_) {},
                size: AuraSwitchSize.lg,
              ),
            ),
          ),
        );

        final auraSwitch = tester.widget<AuraSwitch>(find.byType(AuraSwitch));
        expect(auraSwitch.size, AuraSwitchSize.lg);

        // Verify the switch renders with larger dimensions
        final animatedContainer = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer).first,
        );
        final constraints = animatedContainer.constraints;
        // lg size should have width of 52.0
        expect(constraints?.maxWidth, 52.0);
      });
    });

    group('Disabled state', () {
      testWidgets('applies disabled property correctly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AuraSwitch(
                value: false,
                onChanged: (_) {},
                disabled: true,
              ),
            ),
          ),
        );

        final auraSwitch = tester.widget<AuraSwitch>(find.byType(AuraSwitch));
        expect(auraSwitch.disabled, isTrue);
      });

      testWidgets('shows basic cursor when disabled', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AuraSwitch(
                value: false,
                onChanged: (_) {},
                disabled: true,
              ),
            ),
          ),
        );

        final mouseRegion = tester.widget<MouseRegion>(
          find.descendant(
            of: find.byType(AuraSwitch),
            matching: find.byType(MouseRegion),
          ),
        );
        expect(mouseRegion.cursor, SystemMouseCursors.basic);
      });

      testWidgets('shows click cursor when enabled', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AuraSwitch(
                value: false,
                onChanged: (_) {},
              ),
            ),
          ),
        );

        final mouseRegion = tester.widget<MouseRegion>(
          find.descendant(
            of: find.byType(AuraSwitch),
            matching: find.byType(MouseRegion),
          ),
        );
        expect(mouseRegion.cursor, SystemMouseCursors.click);
      });
    });

    group('Loading state', () {
      testWidgets('shows loading indicator when isLoading is true', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AuraSwitch(
                value: false,
                onChanged: (_) {},
                isLoading: true,
              ),
            ),
          ),
        );

        expect(find.byType(AuraLoadingCircle), findsOneWidget);
      });

      testWidgets('does not show loading indicator when isLoading is false', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AuraSwitch(
                value: false,
                onChanged: (_) {},
              ),
            ),
          ),
        );

        expect(find.byType(AuraLoadingCircle), findsNothing);
      });

      testWidgets('shows basic cursor when loading', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AuraSwitch(
                value: false,
                onChanged: (_) {},
                isLoading: true,
              ),
            ),
          ),
        );

        final mouseRegion = tester.widget<MouseRegion>(
          find.descendant(
            of: find.byType(AuraSwitch),
            matching: find.byType(MouseRegion),
          ),
        );
        expect(mouseRegion.cursor, SystemMouseCursors.basic);
      });
    });

    group('Animation', () {
      testWidgets('animates thumb position when value changes', (
        tester,
      ) async {
        var currentValue = false;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return MaterialApp(
                home: Scaffold(
                  body: AuraSwitch(
                    value: currentValue,
                    onChanged: (value) {
                      setState(() => currentValue = value);
                    },
                  ),
                ),
              );
            },
          ),
        );

        // Get initial position
        final animatedPositionedBefore = tester.widget<AnimatedPositioned>(
          find.byType(AnimatedPositioned),
        );
        final initialLeft = animatedPositionedBefore.left;

        // Tap to toggle
        await tester.tap(find.byType(AuraSwitch));
        await tester.pumpAndSettle();

        // Get final position
        final animatedPositionedAfter = tester.widget<AnimatedPositioned>(
          find.byType(AnimatedPositioned),
        );
        final finalLeft = animatedPositionedAfter.left;

        // Position should have changed
        expect(finalLeft, isNot(equals(initialLeft)));
      });
    });

    group('AuraSwitchSize enum', () {
      test('has all expected values', () {
        expect(AuraSwitchSize.values, hasLength(3));
        expect(AuraSwitchSize.values, contains(AuraSwitchSize.sm));
        expect(AuraSwitchSize.values, contains(AuraSwitchSize.base));
        expect(AuraSwitchSize.values, contains(AuraSwitchSize.lg));
      });
    });
  });
}
