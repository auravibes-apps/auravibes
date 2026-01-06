import 'package:auravibes_ui/src/colors/oklch.dart';
import 'package:auravibes_ui/src/molecules/auravibes_connection_status.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraConnectionStatus', () {
    testWidgets('renders online status correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraConnectionStatus(
              status: AuraConnectionState.online,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(AuraConnectionStatus),
          matching: find.byType(Container),
        ),
      );

      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color?.toOklch().hue, HueColorValues.success);
    });

    testWidgets('renders offline status correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraConnectionStatus(
              status: AuraConnectionState.offline,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(AuraConnectionStatus),
          matching: find.byType(Container),
        ),
      );

      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color?.toOklch().hue, HueColorValues.error);
    });

    testWidgets('renders connecting status with animation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraConnectionStatus(
              status: AuraConnectionState.connecting,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(AuraConnectionStatus),
          matching: find.byType(Container),
        ),
      );

      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color?.toOklch().hue, HueColorValues.warning);

      // Should have AnimatedBuilder for pulsing animation
      // Find AnimatedBuilder specifically within AuraConnectionStatus
      final connectionStatusFinder = find.byType(AuraConnectionStatus);
      final animatedBuilderInStatus = find.descendant(
        of: connectionStatusFinder,
        matching: find.byType(AnimatedBuilder),
      );
      expect(animatedBuilderInStatus, findsOneWidget);
    });

    testWidgets('shows label when showLabel is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraConnectionStatus(
              status: AuraConnectionState.online,
              showLabel: true,
            ),
          ),
        ),
      );

      expect(find.text('Online'), findsOneWidget);
      expect(find.byType(Row), findsOneWidget);
    });

    testWidgets('hides label when showLabel is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraConnectionStatus(
              status: AuraConnectionState.online,
            ),
          ),
        ),
      );

      expect(find.text('Online'), findsNothing);
      expect(
        find.byType(Row),
        findsOneWidget,
      ); // Row still exists but only has indicator
    });

    testWidgets('uses custom label when provided', (tester) async {
      const customLabel = 'Custom Status';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraConnectionStatus(
              status: AuraConnectionState.online,
              showLabel: true,
              customLabel: customLabel,
            ),
          ),
        ),
      );

      expect(find.text(customLabel), findsOneWidget);
      expect(find.text('Online'), findsNothing);
    });

    testWidgets('applies small size correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraConnectionStatus(
              status: AuraConnectionState.online,
              size: AuraConnectionStatusSize.small,
            ),
          ),
        ),
      );

      // Check that the component renders correctly with small size
      expect(find.byType(AuraConnectionStatus), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
    });

    testWidgets('applies medium size correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraConnectionStatus(
              status: AuraConnectionState.online,
            ),
          ),
        ),
      );

      // Check that the component renders correctly with medium size
      expect(find.byType(AuraConnectionStatus), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
    });

    testWidgets('applies large size correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraConnectionStatus(
              status: AuraConnectionState.online,
              size: AuraConnectionStatusSize.large,
            ),
          ),
        ),
      );

      // Check that the component renders correctly with large size
      expect(find.byType(AuraConnectionStatus), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
    });

    testWidgets('has proper semantic labels', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AuraConnectionStatus(status: AuraConnectionState.online),
                AuraConnectionStatus(status: AuraConnectionState.offline),
                AuraConnectionStatus(status: AuraConnectionState.connecting),
              ],
            ),
          ),
        ),
      );

      expect(
        find.bySemanticsLabel('Connection status: Online'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Connection status: Offline'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Connection status: Connecting'),
        findsOneWidget,
      );
    });

    testWidgets('updates animation when status changes', (tester) async {
      const widget = MaterialApp(
        home: Scaffold(
          body: AuraConnectionStatus(
            status: AuraConnectionState.online,
          ),
        ),
      );

      await tester.pumpWidget(widget);

      // Initially no animation for online status
      // (look within AuraConnectionStatus only)
      final connectionStatusFinder = find.byType(AuraConnectionStatus);
      final animatedBuilderInStatus = find.descendant(
        of: connectionStatusFinder,
        matching: find.byType(AnimatedBuilder),
      );
      expect(animatedBuilderInStatus, findsNothing);

      // Change to connecting status
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraConnectionStatus(
              status: AuraConnectionState.connecting,
            ),
          ),
        ),
      );

      // Should now have animation (look within AuraConnectionStatus only)
      final connectionStatusFinder2 = find.byType(AuraConnectionStatus);
      final animatedBuilderInStatus2 = find.descendant(
        of: connectionStatusFinder2,
        matching: find.byType(AnimatedBuilder),
      );
      expect(animatedBuilderInStatus2, findsOneWidget);
    });

    testWidgets('label color matches status color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraConnectionStatus(
              status: AuraConnectionState.online,
              showLabel: true,
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('Online'));
      expect(text.style?.color?.toOklch().hue, HueColorValues.success);
    });

    group('AuraConnectionState enum', () {
      test('has all expected values', () {
        expect(AuraConnectionState.values, hasLength(3));
        expect(
          AuraConnectionState.values,
          contains(AuraConnectionState.online),
        );
        expect(
          AuraConnectionState.values,
          contains(AuraConnectionState.offline),
        );
        expect(
          AuraConnectionState.values,
          contains(AuraConnectionState.connecting),
        );
      });
    });

    group('AuraConnectionStatusSize enum', () {
      test('has all expected values', () {
        expect(AuraConnectionStatusSize.values, hasLength(3));
        expect(
          AuraConnectionStatusSize.values,
          contains(AuraConnectionStatusSize.small),
        );
        expect(
          AuraConnectionStatusSize.values,
          contains(AuraConnectionStatusSize.medium),
        );
        expect(
          AuraConnectionStatusSize.values,
          contains(AuraConnectionStatusSize.large),
        );
      });
    });

    group('default labels', () {
      testWidgets('shows correct default labels for each status', (
        tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  AuraConnectionStatus(
                    status: AuraConnectionState.online,
                    showLabel: true,
                  ),
                  AuraConnectionStatus(
                    status: AuraConnectionState.offline,
                    showLabel: true,
                  ),
                  AuraConnectionStatus(
                    status: AuraConnectionState.connecting,
                    showLabel: true,
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Online'), findsOneWidget);
        expect(find.text('Offline'), findsOneWidget);
        expect(find.text('Connecting...'), findsOneWidget);
      });
    });
  });
}
