import 'dart:ui' as ui;

import 'package:auravibes_ui/src/atoms/aura_loading_circle.dart';
import 'package:auravibes_ui/src/organisms/aura_switch.dart';
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
                onChanged: (_) {
                  final _ = Object();
                },
              ),
            ),
          ),
        );

        final auraSwitch = tester.widget<AuraSwitch>(find.byType(AuraSwitch));
        expect(find.byType(AuraSwitch), findsOneWidget);
        expect(find.byType(GestureDetector), findsOneWidget);
        expect(find.byType(FocusableActionDetector), findsOneWidget);
        expect(find.byType(AnimatedContainer), findsWidgets);
        expect(auraSwitch.value, isFalse);
        expect(auraSwitch.size, AuraSwitchSize.base);
        final focusableActionDetector = tester.widget<FocusableActionDetector>(
          find.descendant(
            of: find.byType(AuraSwitch),
            matching: find.byType(FocusableActionDetector),
          ),
        );
        expect(focusableActionDetector.mouseCursor, SystemMouseCursors.click);
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

        final auraSwitch = tester.widget<AuraSwitch>(find.byType(AuraSwitch));
        expect(auraSwitch.value, isTrue);
        await tester.tap(find.byType(AuraSwitch));
        await tester.pump();

        expect(receivedValue, isFalse);
      });

      testWidgets('does not call onChanged when onChanged is null', (
        tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: AuraSwitch(value: false, onChanged: null)),
          ),
        );

        // Should not throw when tapped.
        await tester.tap(find.byType(AuraSwitch));
        await tester.pump();

        // Widget should still render correctly.
        expect(find.byType(AuraSwitch), findsOneWidget);
        final focusableActionDetector = tester.widget<FocusableActionDetector>(
          find.descendant(
            of: find.byType(AuraSwitch),
            matching: find.byType(FocusableActionDetector),
          ),
        );
        expect(focusableActionDetector.enabled, isFalse);
      });
    });

    group('Size variants', () {
      testWidgets('renders with sm size correctly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AuraSwitch(
                value: false,
                onChanged: (_) {
                  final _ = Object();
                },
                size: .sm,
              ),
            ),
          ),
        );

        final auraSwitch = tester.widget<AuraSwitch>(find.byType(AuraSwitch));
        expect(auraSwitch.size, AuraSwitchSize.sm);

        // Verify the switch renders with smaller dimensions.
        final animatedContainer = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer).first,
        );
        final constraints = animatedContainer.constraints;
        // Sm size should have width of 36.0.
        expect(constraints?.maxWidth, 36.0);
      });

      testWidgets('renders with lg size correctly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AuraSwitch(
                value: false,
                onChanged: (_) {
                  final _ = Object();
                },
                size: .lg,
              ),
            ),
          ),
        );

        final auraSwitch = tester.widget<AuraSwitch>(find.byType(AuraSwitch));
        expect(auraSwitch.size, AuraSwitchSize.lg);

        // Verify the switch renders with larger dimensions.
        final animatedContainer = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer).first,
        );
        final constraints = animatedContainer.constraints;
        // Lg size should have width of 52.0.
        expect(constraints?.maxWidth, 52.0);
      });
    });

    group('Focus state', () {
      testWidgets('shows focus ring when focus highlight is active', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AuraSwitch(
                value: false,
                onChanged: (_) {
                  final _ = Object();
                },
              ),
            ),
          ),
        );

        final focusableActionDetector = tester.widget<FocusableActionDetector>(
          find.descendant(
            of: find.byType(AuraSwitch),
            matching: find.byType(FocusableActionDetector),
          ),
        );
        focusableActionDetector.onShowFocusHighlight?.call(true);
        await tester.pump();

        final focusedTrack = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer).first,
        );
        final focusedDecoration = switch (focusedTrack.decoration) {
          final BoxDecoration decoration => decoration,
          _ => fail('Expected a box decoration.'),
        };

        expect(focusedDecoration.border, isNull);
        expect(focusedDecoration.boxShadow, hasLength(1));

        focusableActionDetector.onShowFocusHighlight?.call(false);
        await tester.pump();

        final unfocusedTrack = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer).first,
        );
        final unfocusedDecoration = switch (unfocusedTrack.decoration) {
          final BoxDecoration decoration => decoration,
          _ => fail('Expected a box decoration.'),
        };

        expect(unfocusedDecoration.boxShadow, isNull);
      });
    });

    group('Disabled state', () {
      testWidgets('disabled switch exposes state and ignores taps', (
        tester,
      ) async {
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

        final auraSwitch = tester.widget<AuraSwitch>(find.byType(AuraSwitch));
        expect(auraSwitch.disabled, isTrue);
        final focusableActionDetector = tester.widget<FocusableActionDetector>(
          find.descendant(
            of: find.byType(AuraSwitch),
            matching: find.byType(FocusableActionDetector),
          ),
        );
        expect(focusableActionDetector.mouseCursor, SystemMouseCursors.basic);
        await tester.tap(find.byType(AuraSwitch));
        await tester.pump();
        expect(wasChanged, isFalse);
      });
    });

    group('Loading state', () {
      testWidgets('loading switch is visible, disabled, and ignores taps', (
        tester,
      ) async {
        var wasChanged = false;
        final semantics = tester.ensureSemantics();
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

        expect(find.byType(AuraLoadingCircle), findsOneWidget);
        final focusableActionDetector = tester.widget<FocusableActionDetector>(
          find.descendant(
            of: find.byType(AuraSwitch),
            matching: find.byType(FocusableActionDetector),
          ),
        );
        expect(focusableActionDetector.mouseCursor, SystemMouseCursors.basic);
        final flags = tester
            .getSemantics(find.byType(AuraSwitch))
            .flagsCollection;
        expect(flags.isToggled, ui.Tristate.isFalse);
        expect(flags.isEnabled, ui.Tristate.isFalse);
        await tester.tap(find.byType(AuraSwitch));
        await tester.pump();
        expect(wasChanged, isFalse);
        semantics.dispose();
      });

      testWidgets('does not show loading indicator when isLoading is false', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AuraSwitch(
                value: false,
                onChanged: (_) {
                  final _ = Object();
                },
              ),
            ),
          ),
        );

        expect(find.byType(AuraLoadingCircle), findsNothing);
      });
    });

    group('Accessibility', () {
      testWidgets('exposes toggled semantics state', (tester) async {
        final semantics = tester.ensureSemantics();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AuraSwitch(
                value: true,
                onChanged: (_) {
                  final _ = Object();
                },
              ),
            ),
          ),
        );

        final node = tester.getSemantics(find.byType(AuraSwitch));
        final flags = node.flagsCollection;

        expect(flags.isToggled, ui.Tristate.isTrue);
        expect(flags.isEnabled, ui.Tristate.isTrue);

        semantics.dispose();
      });

      testWidgets('responds to activate intent', (tester) async {
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

        final _ = Actions.invoke(
          tester.element(find.byType(GestureDetector)),
          const ActivateIntent(),
        );

        expect(receivedValue, isTrue);
      });

      testWidgets('keeps at least a 44 pixel hit target', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AuraSwitch(
                value: false,
                onChanged: (_) {
                  final _ = Object();
                },
                size: .sm,
              ),
            ),
          ),
        );

        final size = tester.getSize(find.byType(AuraSwitch));

        expect(size.width, greaterThanOrEqualTo(44));
        expect(size.height, greaterThanOrEqualTo(44));
      });
    });

    group('Animation', () {
      testWidgets('animates thumb position when value changes', (tester) async {
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

        // Get initial position.
        final animatedPositionedBefore = tester.widget<AnimatedPositioned>(
          find.byType(AnimatedPositioned),
        );
        final initialLeft = animatedPositionedBefore.left;

        // Tap to toggle.
        await tester.tap(find.byType(AuraSwitch));
        final _ = await tester.pumpAndSettle();

        // Get final position.
        final animatedPositionedAfter = tester.widget<AnimatedPositioned>(
          find.byType(AnimatedPositioned),
        );
        final finalLeft = animatedPositionedAfter.left;

        // Position should have changed.
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
