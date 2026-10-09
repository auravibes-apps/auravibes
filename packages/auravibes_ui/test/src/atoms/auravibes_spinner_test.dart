import 'package:auravibes_ui/src/atoms/aura_spinner.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraSpinner', () {
    testWidgets('renders default spinner correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AuraSpinner())),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(SizedBox), findsOneWidget);

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
      expect(sizedBox.width, 24.0);
      expect(sizedBox.height, 24.0);

      final progressIndicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(progressIndicator.color, DesignColors.primaryBase);
      expect(progressIndicator.semanticsLabel, isNull);
    });

    testWidgets('applies expected dimensions for small and large sizes', (
      tester,
    ) async {
      const cases = <({String label, AuraSpinnerSize size, double dimension})>[
        (label: 'large', size: AuraSpinnerSize.large, dimension: 32.0),
        (label: 'small', size: AuraSpinnerSize.small, dimension: 16.0),
      ];

      for (final (:label, :size, :dimension) in cases) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: AuraSpinner(size: size)),
          ),
        );

        final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
        expect(sizedBox.width, dimension, reason: label);
        expect(sizedBox.height, dimension, reason: label);
      }
    });

    testWidgets('applies custom indicator overrides', (tester) async {
      const customColor = Colors.red;
      const customStrokeWidth = 4.0;
      const semanticLabel = 'Loading content';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraSpinner(
              color: customColor,
              strokeWidth: customStrokeWidth,
              semanticLabel: semanticLabel,
            ),
          ),
        ),
      );

      final progressIndicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(progressIndicator.color, customColor);
      expect(progressIndicator.strokeWidth, customStrokeWidth);
      expect(progressIndicator.semanticsLabel, semanticLabel);
    });

    group('AuraSpinnerSize enum', () {
      test('has all expected values', () {
        expect(AuraSpinnerSize.values, hasLength(5));
        expect(AuraSpinnerSize.values, contains(AuraSpinnerSize.extraSmall));
        expect(AuraSpinnerSize.values, contains(AuraSpinnerSize.small));
        expect(AuraSpinnerSize.values, contains(AuraSpinnerSize.medium));
        expect(AuraSpinnerSize.values, contains(AuraSpinnerSize.large));
        expect(AuraSpinnerSize.values, contains(AuraSpinnerSize.extraLarge));
      });
    });
  });

  group('AuraLoadingOverlay', () {
    testWidgets('shows loading overlay with and without a message', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AuraLoadingOverlay())),
      );

      expect(find.byType(AuraSpinner), findsOneWidget);
      expect(
        find.byType(Container),
        findsOneWidget,
      ); // Inner container only (overlay uses ColoredBox).

      const childText = 'Content';
      const message = 'Loading data...';
      const customBackgroundColor = Colors.red;
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraLoadingOverlay(
              child: Text(childText),
              message: message,
              backgroundColor: customBackgroundColor,
            ),
          ),
        ),
      );

      expect(find.text(childText), findsOneWidget);
      expect(find.byType(AuraSpinner), findsOneWidget);
      expect(find.byType(AuraLoadingOverlay), findsOneWidget);
      final loadingOverlay = tester.widget<AuraLoadingOverlay>(
        find.byType(AuraLoadingOverlay),
      );
      expect(loadingOverlay.isLoading, isTrue);

      expect(find.text(message), findsOneWidget);
      final coloredBox = tester.widget<ColoredBox>(
        find.descendant(
          of: find.byType(AuraLoadingOverlay),
          matching: find.byType(ColoredBox),
        ),
      );
      expect(coloredBox.color, customBackgroundColor);
    });

    testWidgets('hides loading overlay and preserves optional child', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AuraLoadingOverlay(isLoading: false)),
        ),
      );

      expect(find.byType(AuraSpinner), findsNothing);
      expect(find.byType(SizedBox), findsOneWidget);

      const childText = 'Content';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraLoadingOverlay(isLoading: false, child: Text(childText)),
          ),
        ),
      );

      expect(find.text(childText), findsOneWidget);
      expect(find.byType(AuraSpinner), findsNothing);
    });
  });
}
