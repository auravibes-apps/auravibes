import 'package:auravibes_ui/src/atoms/auravibes_tooltip.dart';
import 'package:auravibes_ui/src/tokens/auravibes_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraTooltip', () {
    // Test 1: Verify Material Tooltip is NOT used (this should FAIL initially)
    testWidgets('does NOT use Material Tooltip widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
          home: const Scaffold(
            body: AuraTooltip(
              message: 'Test tooltip',
              child: Text('Hover me'),
            ),
          ),
        ),
      );

      // This should find ZERO Material Tooltip widgets - custom implementation
      expect(find.byType(Tooltip), findsNothing);
    });

    testWidgets('renders child correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
          home: const Scaffold(
            body: AuraTooltip(
              message: 'Test tooltip',
              child: Text('Hover me'),
            ),
          ),
        ),
      );

      expect(find.text('Hover me'), findsOneWidget);
    });

    testWidgets('has default colorVariant as onSurface', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                const tooltip = AuraTooltip(
                  message: 'Test',
                  child: SizedBox(),
                );
                expect(tooltip.colorVariant, AuraColorVariant.onSurface);
                return tooltip;
              },
            ),
          ),
        ),
      );
    });

    // Test custom overlay behavior - hover (desktop)
    testWidgets('shows custom tooltip overlay on hover (desktop)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
          home: const Scaffold(
            body: Center(
              child: AuraTooltip(
                message: 'Hover tooltip',
                child: Text('Hover me'),
              ),
            ),
          ),
        ),
      );

      // Find the child widget
      final childFinder = find.text('Hover me');
      expect(childFinder, findsOneWidget);

      // Get the center of the child and simulate hover with mouse
      final center = tester.getCenter(childFinder);
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.moveTo(center);
      await tester.pump();

      // Should show the tooltip message overlay
      expect(find.text('Hover tooltip'), findsOneWidget);

      // Move mouse away to exit hover
      await gesture.moveTo(Offset.zero);
      await tester.pumpAndSettle();
    });

    // Test custom overlay behavior - tap (mobile)
    testWidgets('shows custom tooltip overlay on tap (mobile)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
          home: const Scaffold(
            body: Center(
              child: AuraTooltip(
                message: 'Tap tooltip',
                child: Text('Tap me'),
              ),
            ),
          ),
        ),
      );

      // Find and tap the child widget
      final childFinder = find.text('Tap me');
      expect(childFinder, findsOneWidget);

      await tester.tap(childFinder);
      await tester.pump();

      // Should show the tooltip message overlay
      expect(find.text('Tap tooltip'), findsOneWidget);

      // Tap elsewhere to dismiss
      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();
    });

    // Test custom overlay with different color variants
    testWidgets('uses custom colorVariant primary', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
          home: const Scaffold(
            body: Center(
              child: AuraTooltip(
                message: 'Primary tooltip',
                colorVariant: AuraColorVariant.primary,
                child: Icon(Icons.info),
              ),
            ),
          ),
        ),
      );

      // Hover to show tooltip
      final iconFinder = find.byIcon(Icons.info);
      final center = tester.getCenter(iconFinder);
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.moveTo(center);
      await tester.pump();

      expect(find.text('Primary tooltip'), findsOneWidget);
    });

    testWidgets('uses custom colorVariant error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
          home: const Scaffold(
            body: Center(
              child: AuraTooltip(
                message: 'Error tooltip',
                colorVariant: AuraColorVariant.error,
                child: Icon(Icons.error),
              ),
            ),
          ),
        ),
      );

      final iconFinder = find.byIcon(Icons.error);
      final center = tester.getCenter(iconFinder);
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.moveTo(center);
      await tester.pump();

      expect(find.text('Error tooltip'), findsOneWidget);
    });

    testWidgets('uses custom colorVariant success', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
          home: const Scaffold(
            body: Center(
              child: AuraTooltip(
                message: 'Success tooltip',
                colorVariant: AuraColorVariant.success,
                child: Icon(Icons.check),
              ),
            ),
          ),
        ),
      );

      final iconFinder = find.byIcon(Icons.check);
      final center = tester.getCenter(iconFinder);
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.moveTo(center);
      await tester.pump();

      expect(find.text('Success tooltip'), findsOneWidget);
    });

    testWidgets('uses custom colorVariant warning', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
          home: const Scaffold(
            body: Center(
              child: AuraTooltip(
                message: 'Warning tooltip',
                colorVariant: AuraColorVariant.warning,
                child: Icon(Icons.warning),
              ),
            ),
          ),
        ),
      );

      final iconFinder = find.byIcon(Icons.warning);
      final center = tester.getCenter(iconFinder);
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.moveTo(center);
      await tester.pump();

      expect(find.text('Warning tooltip'), findsOneWidget);
    });

    testWidgets('uses custom colorVariant info', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
          home: const Scaffold(
            body: Center(
              child: AuraTooltip(
                message: 'Info tooltip',
                colorVariant: AuraColorVariant.info,
                child: Icon(Icons.info_outline),
              ),
            ),
          ),
        ),
      );

      final iconFinder = find.byIcon(Icons.info_outline);
      final center = tester.getCenter(iconFinder);
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.moveTo(center);
      await tester.pump();

      expect(find.text('Info tooltip'), findsOneWidget);
    });

    // Test custom duration parameters
    testWidgets('respects custom showDuration', (tester) async {
      const customDuration = Duration(seconds: 5);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
          home: const Scaffold(
            body: Center(
              child: AuraTooltip(
                message: 'Long tooltip',
                showDuration: customDuration,
                child: Text('Hover'),
              ),
            ),
          ),
        ),
      );

      // Verify the parameter is stored correctly by accessing the widget
      final tooltipFinder = find.byType(AuraTooltip);
      final tooltip = tester.widget<AuraTooltip>(tooltipFinder);
      expect(tooltip.showDuration, customDuration);
    });

    testWidgets('respects custom waitDuration', (tester) async {
      const customWait = Duration(milliseconds: 500);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                // Create tooltip to test parameter storage
                return const AuraTooltip(
                  message: 'Delayed tooltip',
                  waitDuration: customWait,
                  child: Text('Hover'),
                );
              },
            ),
          ),
        ),
      );

      // Verify the parameter is stored correctly
      final tooltipFinder = find.byType(AuraTooltip);
      final tooltip = tester.widget<AuraTooltip>(tooltipFinder);
      expect(tooltip.waitDuration, customWait);
    });

    testWidgets('respects preferBelow setting', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
          home: const Scaffold(
            body: Center(
              child: AuraTooltip(
                message: 'Above tooltip',
                preferBelow: false,
                child: Text('Hover'),
              ),
            ),
          ),
        ),
      );

      final tooltipFinder = find.byType(AuraTooltip);
      final tooltip = tester.widget<AuraTooltip>(tooltipFinder);
      expect(tooltip.preferBelow, false);
    });

    testWidgets('respects custom verticalOffset', (tester) async {
      const customOffset = 32.0;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
          home: const Scaffold(
            body: Center(
              child: AuraTooltip(
                message: 'Offset tooltip',
                verticalOffset: customOffset,
                child: Text('Hover'),
              ),
            ),
          ),
        ),
      );

      final tooltipFinder = find.byType(AuraTooltip);
      final tooltip = tester.widget<AuraTooltip>(tooltipFinder);
      expect(tooltip.verticalOffset, customOffset);
    });

    testWidgets('respects custom margin', (tester) async {
      const customMargin = 24.0;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
          home: const Scaffold(
            body: Center(
              child: AuraTooltip(
                message: 'Margin tooltip',
                margin: customMargin,
                child: Text('Hover'),
              ),
            ),
          ),
        ),
      );

      final tooltipFinder = find.byType(AuraTooltip);
      final tooltip = tester.widget<AuraTooltip>(tooltipFinder);
      expect(tooltip.margin, customMargin);
    });

    testWidgets('respects custom padding', (tester) async {
      const customPadding = EdgeInsets.all(16);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
          home: const Scaffold(
            body: Center(
              child: AuraTooltip(
                message: 'Padded tooltip',
                padding: customPadding,
                child: Text('Hover'),
              ),
            ),
          ),
        ),
      );

      final tooltipFinder = find.byType(AuraTooltip);
      final tooltip = tester.widget<AuraTooltip>(tooltipFinder);
      expect(tooltip.padding, customPadding);
    });

    testWidgets('respects custom borderRadius', (tester) async {
      const customRadius = BorderRadius.all(Radius.circular(16));

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
          home: const Scaffold(
            body: Center(
              child: AuraTooltip(
                message: 'Rounded tooltip',
                borderRadius: customRadius,
                child: Text('Hover'),
              ),
            ),
          ),
        ),
      );

      final tooltipFinder = find.byType(AuraTooltip);
      final tooltip = tester.widget<AuraTooltip>(tooltipFinder);
      expect(tooltip.borderRadius, customRadius);
    });

    // Test auto-dismiss after showDuration
    testWidgets('auto-dismisses after showDuration', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
          home: const Scaffold(
            body: Center(
              child: AuraTooltip(
                message: 'Auto dismiss tooltip',
                showDuration: Duration(milliseconds: 500),
                child: Text('Hover'),
              ),
            ),
          ),
        ),
      );

      final childFinder = find.text('Hover');

      // Get center and simulate hover
      final center = tester.getCenter(childFinder);
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.moveTo(center);
      await tester.pump();

      // Should show tooltip
      expect(find.text('Auto dismiss tooltip'), findsOneWidget);

      // Wait for auto-dismiss
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();

      // Should be dismissed
      expect(find.text('Auto dismiss tooltip'), findsNothing);
    });

    // Test waitDuration delay
    testWidgets('delays show based on waitDuration', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
          home: const Scaffold(
            body: Center(
              child: AuraTooltip(
                message: 'Delayed show tooltip',
                waitDuration: Duration(milliseconds: 500),
                child: Text('Hover'),
              ),
            ),
          ),
        ),
      );

      final childFinder = find.text('Hover');
      final center = tester.getCenter(childFinder);
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);

      // Hover but not long enough
      await gesture.moveTo(center);
      await tester.pump(const Duration(milliseconds: 300));

      // Should NOT show yet
      expect(find.text('Delayed show tooltip'), findsNothing);

      // Continue hovering past waitDuration
      await tester.pump(const Duration(milliseconds: 300));

      // Should now show
      expect(find.text('Delayed show tooltip'), findsOneWidget);
    });

    // Test that MouseRegion is used for hover detection
    testWidgets('uses MouseRegion for hover detection', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
          home: const Scaffold(
            body: Center(
              child: AuraTooltip(
                message: 'Mouse region tooltip',
                child: Text('Hover me'),
              ),
            ),
          ),
        ),
      );

      // Should have MouseRegion for hover detection
      expect(find.byType(MouseRegion), findsWidgets);
    });

    // Test that GestureDetector is used for tap detection
    testWidgets('uses GestureDetector for tap detection', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
          home: const Scaffold(
            body: Center(
              child: AuraTooltip(
                message: 'Gesture tooltip',
                child: Text('Tap me'),
              ),
            ),
          ),
        ),
      );

      // Should have GestureDetector for tap detection
      expect(find.byType(GestureDetector), findsWidgets);
    });
  });
}
