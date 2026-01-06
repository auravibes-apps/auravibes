import 'package:auravibes_ui/src/atoms/auravibes_spinner.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraSpinner', () {
    testWidgets('renders spinner correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraSpinner(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('applies medium size correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraSpinner(),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
      expect(sizedBox.width, 24.0);
      expect(sizedBox.height, 24.0);
    });

    testWidgets('applies large size correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraSpinner(
              size: AuraSpinnerSize.large,
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
      expect(sizedBox.width, 32.0);
      expect(sizedBox.height, 32.0);
    });

    testWidgets('applies small size correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraSpinner(
              size: AuraSpinnerSize.small,
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
      expect(sizedBox.width, 16.0);
      expect(sizedBox.height, 16.0);
    });

    testWidgets('applies custom color correctly', (tester) async {
      const customColor = Colors.red;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraSpinner(
              color: customColor,
            ),
          ),
        ),
      );

      final progressIndicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(progressIndicator.color, customColor);
    });

    testWidgets('applies default primary color when no color specified', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraSpinner(),
          ),
        ),
      );

      final progressIndicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(progressIndicator.color, DesignColors.primaryBase);
    });

    testWidgets('applies custom stroke width correctly', (tester) async {
      const customStrokeWidth = 4.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraSpinner(
              strokeWidth: customStrokeWidth,
            ),
          ),
        ),
      );

      final progressIndicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(progressIndicator.strokeWidth, customStrokeWidth);
    });

    testWidgets('applies semantic label correctly', (tester) async {
      const semanticLabel = 'Loading content';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraSpinner(
              semanticLabel: semanticLabel,
            ),
          ),
        ),
      );

      final progressIndicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(progressIndicator.semanticsLabel, semanticLabel);
    });

    testWidgets('applies default semantic label when none provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraSpinner(),
          ),
        ),
      );

      final progressIndicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(progressIndicator.semanticsLabel, 'Loading');
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

  group('AuraSpinnerWithLabel', () {
    testWidgets('renders spinner with label correctly', (tester) async {
      const labelText = 'Loading data...';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraSpinnerWithLabel(
              label: labelText,
            ),
          ),
        ),
      );

      expect(find.byType(AuraSpinner), findsOneWidget);
      expect(find.text(labelText), findsOneWidget);
      expect(find.byType(Column), findsOneWidget);
    });

    testWidgets('renders spinner with label horizontally', (tester) async {
      const labelText = 'Loading...';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraSpinnerWithLabel(
              label: labelText,
              direction: Axis.horizontal,
            ),
          ),
        ),
      );

      expect(find.byType(AuraSpinner), findsOneWidget);
      expect(find.text(labelText), findsOneWidget);
      expect(find.byType(Row), findsOneWidget);
    });

    testWidgets('applies custom spacing correctly', (tester) async {
      const customSpacing = 16.0;
      const labelText = 'Loading...';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraSpinnerWithLabel(
              label: labelText,
              spacing: customSpacing,
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find
            .descendant(
              of: find.byType(Column),
              matching: find.byType(SizedBox),
            )
            .last,
      );
      expect(sizedBox.height, customSpacing);
    });

    testWidgets('applies custom size to spinner', (tester) async {
      const labelText = 'Loading...';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraSpinnerWithLabel(
              label: labelText,
              size: AuraSpinnerSize.large,
            ),
          ),
        ),
      );

      final auraSpinner = tester.widget<AuraSpinner>(find.byType(AuraSpinner));
      expect(auraSpinner.size, AuraSpinnerSize.large);
    });

    testWidgets('applies custom color to spinner', (tester) async {
      const customColor = Colors.green;
      const labelText = 'Loading...';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraSpinnerWithLabel(
              label: labelText,
              color: customColor,
            ),
          ),
        ),
      );

      final auraSpinner = tester.widget<AuraSpinner>(find.byType(AuraSpinner));
      expect(auraSpinner.color, customColor);
    });
  });

  group('AuraLoadingOverlay', () {
    testWidgets('shows overlay when isLoading is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraLoadingOverlay(),
          ),
        ),
      );

      expect(find.byType(AuraSpinner), findsOneWidget);
      expect(
        find.byType(Container),
        findsOneWidget,
      ); // Inner container only (overlay uses ColoredBox)
    });

    testWidgets('hides overlay when isLoading is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraLoadingOverlay(
              isLoading: false,
            ),
          ),
        ),
      );

      expect(find.byType(AuraSpinner), findsNothing);
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('shows child when isLoading is false', (tester) async {
      const childText = 'Content';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraLoadingOverlay(
              isLoading: false,
              child: Text(childText),
            ),
          ),
        ),
      );

      expect(find.text(childText), findsOneWidget);
      expect(find.byType(AuraSpinner), findsNothing);
    });

    testWidgets('shows overlay over child when isLoading is true', (
      tester,
    ) async {
      const childText = 'Content';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraLoadingOverlay(
              child: Text(childText),
            ),
          ),
        ),
      );

      expect(find.text(childText), findsOneWidget);
      expect(find.byType(AuraSpinner), findsOneWidget);
      expect(find.byType(AuraLoadingOverlay), findsOneWidget);

      // Verify the overlay Stack specifically
      // (not the MaterialApp's internal stack)
      final loadingOverlay = tester.widget<AuraLoadingOverlay>(
        find.byType(AuraLoadingOverlay),
      );
      expect(loadingOverlay.isLoading, isTrue);
    });

    testWidgets('shows message when provided', (tester) async {
      const message = 'Loading data...';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraLoadingOverlay(
              message: message,
            ),
          ),
        ),
      );

      expect(find.byType(AuraSpinnerWithLabel), findsOneWidget);
      expect(find.text(message), findsOneWidget);
    });

    testWidgets('applies custom background color', (tester) async {
      const customBackgroundColor = Colors.red;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraLoadingOverlay(
              backgroundColor: customBackgroundColor,
            ),
          ),
        ),
      );

      final coloredBox = tester.widget<ColoredBox>(
        find.descendant(
          of: find.byType(AuraLoadingOverlay),
          matching: find.byType(ColoredBox),
        ),
      );
      expect(coloredBox.color, customBackgroundColor);
    });
  });

  group('AuraInlineSpinner', () {
    testWidgets('renders inline spinner correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraInlineSpinner(),
          ),
        ),
      );

      expect(find.byType(AuraSpinner), findsOneWidget);
    });

    testWidgets('applies small size by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraInlineSpinner(),
          ),
        ),
      );

      final auraSpinner = tester.widget<AuraSpinner>(find.byType(AuraSpinner));
      expect(auraSpinner.size, AuraSpinnerSize.small);
    });

    testWidgets('applies custom size correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraInlineSpinner(
              size: AuraSpinnerSize.medium,
            ),
          ),
        ),
      );

      final auraSpinner = tester.widget<AuraSpinner>(find.byType(AuraSpinner));
      expect(auraSpinner.size, AuraSpinnerSize.medium);
    });
  });

  group('AuraDotsSpinner', () {
    test('creates AuraDotsSpinner with default parameters', () {
      const dotsSpinner = AuraDotsSpinner();
      expect(dotsSpinner.size, AuraSpinnerSize.medium);
      expect(dotsSpinner.dotCount, 3);
      expect(dotsSpinner.semanticLabel, isNull);
      expect(dotsSpinner.color, isNull);
    });

    test('creates AuraDotsSpinner with custom parameters', () {
      const customColor = Colors.blue;
      const semanticLabel = 'Loading dots';
      const dotCount = 5;

      const dotsSpinner = AuraDotsSpinner(
        size: AuraSpinnerSize.large,
        color: customColor,
        dotCount: dotCount,
        semanticLabel: semanticLabel,
      );

      expect(dotsSpinner.size, AuraSpinnerSize.large);
      expect(dotsSpinner.color, customColor);
      expect(dotsSpinner.dotCount, dotCount);
      expect(dotsSpinner.semanticLabel, semanticLabel);
    });
  });
}
