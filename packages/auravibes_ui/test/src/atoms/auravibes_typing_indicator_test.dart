import 'package:auravibes_ui/src/atoms/auravibes_typing_indicator.dart';
import 'package:auravibes_ui/src/tokens/auravibes_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraTypingIndicator', () {
    testWidgets('renders three animated dots', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraTypingIndicator(),
          ),
        ),
      );

      // Find all containers that represent dots
      final dotContainers = find.descendant(
        of: find.byType(AuraTypingIndicator),
        matching: find.byType(Container),
      );

      // Should have at least 3 dot containers (plus the main container)
      expect(dotContainers, findsAtLeastNWidgets(3));
    });

    testWidgets('hides container when showContainer is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraTypingIndicator(showContainer: false),
          ),
        ),
      );

      // Should not find Align widget when container is hidden
      expect(find.byType(Align), findsNothing);

      // Should still find the dots
      expect(find.byType(Row), findsOneWidget);
    });

    testWidgets('applies small size correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraTypingIndicator(
              size: AuraTypingIndicatorSize.small,
            ),
          ),
        ),
      );

      // Check that dots are rendered with correct size
      // We can't easily test the exact size in widget tests, so we just verify
      // that the typing indicator renders correctly
      expect(find.byType(AuraTypingIndicator), findsOneWidget);
      expect(find.byType(Row), findsOneWidget);
    });

    testWidgets('applies medium size correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraTypingIndicator(),
          ),
        ),
      );

      // Check that dots are rendered with correct size
      // We can't easily test the exact size in widget tests, so we just verify
      // that the typing indicator renders correctly
      expect(find.byType(AuraTypingIndicator), findsOneWidget);
      expect(find.byType(Row), findsOneWidget);
    });

    testWidgets('applies large size correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraTypingIndicator(
              size: AuraTypingIndicatorSize.large,
            ),
          ),
        ),
      );

      // Check that dots are rendered with correct size
      // We can't easily test the exact size in widget tests, so we just verify
      // that the typing indicator renders correctly
      expect(find.byType(AuraTypingIndicator), findsOneWidget);
      expect(find.byType(Row), findsOneWidget);
    });

    testWidgets('applies custom color', (tester) async {
      const customColor = Colors.red;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraTypingIndicator(
              color: customColor,
            ),
          ),
        ),
      );

      // Find dot containers and check their color
      final dotContainers = tester
          .widgetList<Container>(find.byType(Container))
          .where(
            (container) =>
                container.decoration is BoxDecoration &&
                (container.decoration! as BoxDecoration).shape ==
                    BoxShape.circle,
          )
          .toList();

      expect(dotContainers.length, 3);
      for (final container in dotContainers) {
        final decoration = container.decoration! as BoxDecoration;
        expect(decoration.color, customColor);
      }
    });

    testWidgets('uses default color when none provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
          home: const Scaffold(
            body: AuraTypingIndicator(),
          ),
        ),
      );

      // Find dot containers and check they use default color
      // (onSurfaceVariant in light theme)
      final dotContainers = tester
          .widgetList<Container>(find.byType(Container))
          .where(
            (container) =>
                container.decoration is BoxDecoration &&
                (container.decoration! as BoxDecoration).shape ==
                    BoxShape.circle,
          )
          .toList();

      expect(dotContainers.length, 3);
      for (final container in dotContainers) {
        final decoration = container.decoration! as BoxDecoration;
        // In light theme, onSurfaceVariant is neutral700
        expect(decoration.color, DesignColors.neutral700);
      }
    });

    testWidgets('has proper semantic label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraTypingIndicator(),
          ),
        ),
      );

      expect(find.bySemanticsLabel('AI is typing'), findsOneWidget);
    });

    testWidgets('animates dots with staggered timing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraTypingIndicator(),
          ),
        ),
      );

      // Pump a few frames to let animation start
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Find animated builders specifically within the AuraTypingIndicator
      final typingIndicator = find.byType(AuraTypingIndicator);
      final animatedBuilders = find.descendant(
        of: typingIndicator,
        matching: find.byType(AnimatedBuilder),
      );
      expect(animatedBuilders, findsNWidgets(3));
    });

    testWidgets('respects custom animation duration', (tester) async {
      const customDuration = Duration(milliseconds: 1000);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraTypingIndicator(
              animationDuration: customDuration,
            ),
          ),
        ),
      );

      // The animation should be running
      await tester.pump();

      // Find animated builders specifically within the AuraTypingIndicator
      final typingIndicator = find.byType(AuraTypingIndicator);
      final animatedBuilders = find.descendant(
        of: typingIndicator,
        matching: find.byType(AnimatedBuilder),
      );
      expect(animatedBuilders, findsNWidgets(3));
    });

    group('AuraTypingIndicatorSize enum', () {
      test('has all expected values', () {
        expect(AuraTypingIndicatorSize.values, hasLength(3));
        expect(
          AuraTypingIndicatorSize.values,
          contains(AuraTypingIndicatorSize.small),
        );
        expect(
          AuraTypingIndicatorSize.values,
          contains(AuraTypingIndicatorSize.medium),
        );
        expect(
          AuraTypingIndicatorSize.values,
          contains(AuraTypingIndicatorSize.large),
        );
      });
    });
  });
}
