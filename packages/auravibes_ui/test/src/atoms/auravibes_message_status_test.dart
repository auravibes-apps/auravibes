import 'package:auravibes_ui/src/atoms/auravibes_message_status.dart';
import 'package:auravibes_ui/src/colors/oklch.dart';
import 'package:auravibes_ui/src/tokens/auravibes_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraMessageStatus', () {
    testWidgets('renders sending status with correct icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
          home: const Scaffold(
            body: AuraMessageStatus(
              status: AuraMessageDeliveryStatus.sending,
              showAnimation: false, // Disable animation for stable testing
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.access_time), findsOneWidget);

      final icon = tester.widget<Icon>(find.byIcon(Icons.access_time));
      // In light theme, sending status uses onSurfaceVariant with 60% opacity
      final expectedColor = DesignColors.neutral700.withValues(alpha: 0.6);
      expect(icon.color, expectedColor);
    });

    testWidgets('renders sent status with correct icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
          home: const Scaffold(
            body: AuraMessageStatus(
              status: AuraMessageDeliveryStatus.sent,
              showAnimation: false, // Disable animation for stable testing
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.done), findsOneWidget);

      final icon = tester.widget<Icon>(find.byIcon(Icons.done));
      // In light theme, sent status uses onSurfaceVariant (neutral700)
      expect(icon.color, DesignColors.neutral700);
    });

    testWidgets('renders delivered status with correct icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraMessageStatus(
              status: AuraMessageDeliveryStatus.delivered,
              showAnimation: false, // Disable animation for stable testing
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.done_all), findsOneWidget);

      final icon = tester.widget<Icon>(find.byIcon(Icons.done_all));
      expect(icon.color?.toOklch().hue, HueColorValues.info);
    });

    testWidgets('renders read status with correct icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraMessageStatus(
              status: AuraMessageDeliveryStatus.read,
              showAnimation: false, // Disable animation for stable testing
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.done_all), findsOneWidget);

      final icon = tester.widget<Icon>(find.byIcon(Icons.done_all));
      expect(icon.color?.toOklch().hue, HueColorValues.success);
    });

    testWidgets('renders error status with correct icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraMessageStatus(
              status: AuraMessageDeliveryStatus.error,
              showAnimation: false, // Disable animation for stable testing
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      final icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
      expect(icon.color?.toOklch().hue, HueColorValues.error);
    });

    testWidgets('applies small size correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraMessageStatus(
              status: AuraMessageDeliveryStatus.sent,
              size: AuraMessageStatusSize.small,
              showAnimation: false, // Disable animation for stable testing
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.done));
      expect(icon.size, 12.0);
    });

    testWidgets('applies medium size correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraMessageStatus(
              status: AuraMessageDeliveryStatus.sent,
              showAnimation: false, // Disable animation for stable testing
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.done));
      expect(icon.size, 16.0);
    });

    testWidgets('applies large size correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraMessageStatus(
              status: AuraMessageDeliveryStatus.sent,
              size: AuraMessageStatusSize.large,
              showAnimation: false, // Disable animation for stable testing
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.done));
      expect(icon.size, 20.0);
    });

    testWidgets('applies custom color when provided', (tester) async {
      const customColor = Colors.purple;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraMessageStatus(
              status: AuraMessageDeliveryStatus.sent,
              color: customColor,
              showAnimation: false, // Disable animation for stable testing
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.done));
      expect(icon.color, customColor);
    });

    testWidgets('has proper semantic labels', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AuraMessageStatus(
                  status: AuraMessageDeliveryStatus.sending,
                  showAnimation: false, // Disable animation for stable testing
                ),
                AuraMessageStatus(
                  status: AuraMessageDeliveryStatus.sent,
                  showAnimation: false,
                ),
                AuraMessageStatus(
                  status: AuraMessageDeliveryStatus.delivered,
                  showAnimation: false,
                ),
                AuraMessageStatus(
                  status: AuraMessageDeliveryStatus.read,
                  showAnimation: false,
                ),
                AuraMessageStatus(
                  status: AuraMessageDeliveryStatus.error,
                  showAnimation: false,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Message is being sent'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Message sent successfully'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Message delivered'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Message read by recipient'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Message failed to send'), findsOneWidget);
    });

    testWidgets('shows animation when enabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraMessageStatus(
              status: AuraMessageDeliveryStatus.sent,
            ),
          ),
        ),
      );

      // Should find the widget with animation enabled
      final widget = tester.widget<AuraMessageStatus>(
        find.byType(AuraMessageStatus),
      );
      expect(widget.showAnimation, true);

      // Wait for animation to complete to avoid hanging
      await tester.pumpAndSettle();
    });

    testWidgets('hides animation when disabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraMessageStatus(
              status: AuraMessageDeliveryStatus.sent,
              showAnimation: false,
            ),
          ),
        ),
      );

      // Should find the widget with animation disabled
      final widget = tester.widget<AuraMessageStatus>(
        find.byType(AuraMessageStatus),
      );
      expect(widget.showAnimation, false);

      // Icon should be directly visible without animation wrapper
      expect(find.byIcon(Icons.done), findsOneWidget);
    });

    testWidgets('shows rotation animation for sending status', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraMessageStatus(
              status: AuraMessageDeliveryStatus.sending,
            ),
          ),
        ),
      );

      // Should find the widget with sending status and animation enabled
      final widget = tester.widget<AuraMessageStatus>(
        find.byType(AuraMessageStatus),
      );
      expect(widget.status, AuraMessageDeliveryStatus.sending);
      expect(widget.showAnimation, true);
      expect(find.byIcon(Icons.access_time), findsOneWidget);

      // Pump some frames to let animation run briefly
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Immediately clean up by disabling animation
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraMessageStatus(
              status: AuraMessageDeliveryStatus.sending,
              showAnimation: false,
            ),
          ),
        ),
      );

      // Wait for widget update
      await tester.pump();
    });

    testWidgets('updates animation when status changes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraMessageStatus(
              status: AuraMessageDeliveryStatus.sending,
            ),
          ),
        ),
      );

      // Initial state should be sending
      var widget = tester.widget<AuraMessageStatus>(
        find.byType(AuraMessageStatus),
      );
      expect(widget.status, AuraMessageDeliveryStatus.sending);
      expect(find.byIcon(Icons.access_time), findsOneWidget);

      // Change status to stop the repeating animation
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraMessageStatus(
              status: AuraMessageDeliveryStatus.sent,
            ),
          ),
        ),
      );

      // Status should have changed
      widget = tester.widget<AuraMessageStatus>(find.byType(AuraMessageStatus));
      expect(widget.status, AuraMessageDeliveryStatus.sent);
      expect(find.byIcon(Icons.done), findsOneWidget);

      // Wait for animation to complete
      await tester.pumpAndSettle();
    });

    testWidgets('applies correct padding for different sizes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AuraMessageStatus(
                  status: AuraMessageDeliveryStatus.sent,
                  size: AuraMessageStatusSize.small,
                  showAnimation: false,
                ),
                AuraMessageStatus(
                  status: AuraMessageDeliveryStatus.sent,
                  showAnimation: false,
                ),
                AuraMessageStatus(
                  status: AuraMessageDeliveryStatus.sent,
                  size: AuraMessageStatusSize.large,
                  showAnimation: false,
                ),
              ],
            ),
          ),
        ),
      );

      final containers = tester.widgetList<Container>(find.byType(Container));

      // Check padding for each size
      expect(containers.elementAt(0).padding, const EdgeInsets.all(2));
      expect(containers.elementAt(1).padding, const EdgeInsets.all(4));
      expect(containers.elementAt(2).padding, const EdgeInsets.all(6));
    });

    group('AuraMessageDeliveryStatus enum', () {
      test('has all expected values', () {
        expect(AuraMessageDeliveryStatus.values, hasLength(5));
        expect(
          AuraMessageDeliveryStatus.values,
          contains(AuraMessageDeliveryStatus.sending),
        );
        expect(
          AuraMessageDeliveryStatus.values,
          contains(AuraMessageDeliveryStatus.sent),
        );
        expect(
          AuraMessageDeliveryStatus.values,
          contains(AuraMessageDeliveryStatus.delivered),
        );
        expect(
          AuraMessageDeliveryStatus.values,
          contains(AuraMessageDeliveryStatus.read),
        );
        expect(
          AuraMessageDeliveryStatus.values,
          contains(AuraMessageDeliveryStatus.error),
        );
      });
    });

    group('AuraMessageStatusSize enum', () {
      test('has all expected values', () {
        expect(AuraMessageStatusSize.values, hasLength(3));
        expect(
          AuraMessageStatusSize.values,
          contains(AuraMessageStatusSize.small),
        );
        expect(
          AuraMessageStatusSize.values,
          contains(AuraMessageStatusSize.medium),
        );
        expect(
          AuraMessageStatusSize.values,
          contains(AuraMessageStatusSize.large),
        );
      });
    });
  });
}
