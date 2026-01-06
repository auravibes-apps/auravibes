import 'package:auravibes_ui/src/atoms/auravibes_text.dart';
import 'package:auravibes_ui/src/colors/oklch.dart';
import 'package:auravibes_ui/src/molecules/auravibes_badge.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraBadge', () {
    testWidgets('renders badge with custom child correctly', (tester) async {
      const childText = 'Custom';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraBadge(
              child: Text(childText),
            ),
          ),
        ),
      );

      expect(find.text(childText), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
    });

    testWidgets('applies primary variant styling correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraBadge(
              child: Text('Primary'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, DesignColors.primaryBase);
    });

    testWidgets('applies secondary variant styling correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraBadge(
              variant: AuraBadgeVariant.secondary,
              child: Text('Secondary'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, DesignColors.secondaryBase);
    });

    testWidgets('applies success variant styling correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraBadge(
              variant: AuraBadgeVariant.success,
              child: Text('Success'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color?.toOklch().hue, HueColorValues.success);
    });

    testWidgets('applies warning variant styling correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraBadge(
              variant: AuraBadgeVariant.warning,
              child: Text('Warning'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color?.toOklch().hue, HueColorValues.warning);
    });

    testWidgets('applies error variant styling correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraBadge(
              variant: AuraBadgeVariant.error,
              child: Text('Error'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color?.toOklch().hue, HueColorValues.error);
    });

    testWidgets('applies outlined variant styling correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraBadge(
              variant: AuraBadgeVariant.outlined,
              child: Text('Outlined'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, Colors.transparent);
      expect(decoration.border, isNotNull);
    });

    testWidgets('applies soft variant styling correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraBadge(
              variant: AuraBadgeVariant.soft,
              child: Text('Soft'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, DesignColors.primaryBase.withValues(alpha: 0.1));
    });

    testWidgets('applies small size correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraBadge(
              size: AuraBadgeSize.small,
              child: Text('Small'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      expect(
        container.padding,
        const EdgeInsets.symmetric(
          horizontal: DesignSpacing.xs,
          vertical: 2,
        ),
      );
    });

    testWidgets('applies medium size correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraBadge(
              child: Text('Medium'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      expect(
        container.padding,
        const EdgeInsets.symmetric(
          horizontal: DesignSpacing.sm,
          vertical: DesignSpacing.xs,
        ),
      );
    });

    testWidgets('applies semantic label correctly', (tester) async {
      const semanticLabel = 'Status badge';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraBadge(
              semanticLabel: semanticLabel,
              child: Text('Status'),
            ),
          ),
        ),
      );

      final semanticsWidgets = find.byType(Semantics);
      final targetSemantics = semanticsWidgets.evaluate().firstWhere(
        (element) =>
            (element.widget as Semantics).properties.label == semanticLabel,
        orElse: () => throw StateError(
          'No Semantics widget found with label: $semanticLabel',
        ),
      );
      expect(targetSemantics, isNotNull);
    });

    group('AuraBadge.text constructor', () {
      testWidgets('renders text badge correctly', (tester) async {
        const badgeText = 'New';

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AuraBadge.text(
                child: const Text(badgeText),
              ),
            ),
          ),
        );

        expect(find.text(badgeText), findsOneWidget);
        expect(find.byType(AuraText), findsOneWidget);
      });
    });

    group('AuraBadge.count constructor', () {
      testWidgets('renders count badge correctly', (tester) async {
        const count = 5;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AuraBadge.count(
                count: count,
              ),
            ),
          ),
        );

        expect(find.text(count.toString()), findsOneWidget);
        expect(find.byType(AuraText), findsOneWidget);
      });

      testWidgets('shows max count with plus when exceeding maxCount', (
        tester,
      ) async {
        const count = 150;
        const maxCount = 99;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AuraBadge.count(
                count: count,
              ),
            ),
          ),
        );

        expect(find.text('$maxCount+'), findsOneWidget);
      });

      testWidgets('applies default semantic label for count', (tester) async {
        const count = 3;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AuraBadge.count(
                count: count,
              ),
            ),
          ),
        );

        final semanticsWidgets = find.byType(Semantics);
        final targetSemantics = semanticsWidgets.evaluate().firstWhere(
          (element) =>
              (element.widget as Semantics).properties.label ==
              '$count notifications',
          orElse: () => throw StateError(
            'No Semantics widget found with label: $count notifications',
          ),
        );
        expect(targetSemantics, isNotNull);
      });
    });

    group('AuraBadge.dot constructor', () {
      testWidgets('renders dot badge correctly', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AuraBadge.dot(),
            ),
          ),
        );

        final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
        expect(sizedBox.width, 6);
        expect(sizedBox.height, 6);
      });

      testWidgets('applies default semantic label for dot', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AuraBadge.dot(),
            ),
          ),
        );

        expect(find.bySemanticsLabel('notification indicator'), findsOneWidget);
      });
    });

    group('AuraBadgeVariant enum', () {
      test('has all expected values', () {
        expect(AuraBadgeVariant.values, hasLength(9));
        expect(AuraBadgeVariant.values, contains(AuraBadgeVariant.primary));
        expect(AuraBadgeVariant.values, contains(AuraBadgeVariant.secondary));
        expect(AuraBadgeVariant.values, contains(AuraBadgeVariant.success));
        expect(AuraBadgeVariant.values, contains(AuraBadgeVariant.warning));
        expect(AuraBadgeVariant.values, contains(AuraBadgeVariant.error));
        expect(AuraBadgeVariant.values, contains(AuraBadgeVariant.info));
        expect(AuraBadgeVariant.values, contains(AuraBadgeVariant.neutral));
        expect(AuraBadgeVariant.values, contains(AuraBadgeVariant.outlined));
        expect(AuraBadgeVariant.values, contains(AuraBadgeVariant.soft));
      });
    });

    group('AuraBadgeSize enum', () {
      test('has all expected values', () {
        expect(AuraBadgeSize.values, hasLength(3));
        expect(AuraBadgeSize.values, contains(AuraBadgeSize.small));
        expect(AuraBadgeSize.values, contains(AuraBadgeSize.medium));
        expect(AuraBadgeSize.values, contains(AuraBadgeSize.large));
      });
    });
  });

  group('AuraPositionedBadge', () {
    testWidgets('renders positioned badge correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraPositionedBadge(
              badge: AuraBadge.dot(),
              child: Icon(Icons.notifications),
            ),
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(AuraPositionedBadge),
          matching: find.byType(Stack),
        ),
        findsOneWidget,
      );
      expect(find.byType(Positioned), findsOneWidget);
      expect(find.byIcon(Icons.notifications), findsOneWidget);
      expect(find.byType(AuraBadge), findsOneWidget);
    });

    testWidgets('positions badge at top-right by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraPositionedBadge(
              badge: AuraBadge.dot(),
              child: Icon(Icons.notifications),
            ),
          ),
        ),
      );

      final positioned = tester.widget<Positioned>(find.byType(Positioned));
      expect(positioned.top, -8.0);
      expect(positioned.right, -8.0);
      expect(positioned.bottom, isNull);
      expect(positioned.left, isNull);
    });

    testWidgets('positions badge at top-left correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraPositionedBadge(
              badge: AuraBadge.dot(),
              position: AuraBadgePosition.topLeft,
              child: Icon(Icons.notifications),
            ),
          ),
        ),
      );

      final positioned = tester.widget<Positioned>(find.byType(Positioned));
      expect(positioned.top, -8.0);
      expect(positioned.left, -8.0);
      expect(positioned.bottom, isNull);
      expect(positioned.right, isNull);
    });

    testWidgets('positions badge at bottom-right correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraPositionedBadge(
              badge: AuraBadge.dot(),
              position: AuraBadgePosition.bottomRight,
              child: Icon(Icons.notifications),
            ),
          ),
        ),
      );

      final positioned = tester.widget<Positioned>(find.byType(Positioned));
      expect(positioned.bottom, -8.0);
      expect(positioned.right, -8.0);
      expect(positioned.top, isNull);
      expect(positioned.left, isNull);
    });

    testWidgets('positions badge at bottom-left correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraPositionedBadge(
              badge: AuraBadge.dot(),
              position: AuraBadgePosition.bottomLeft,
              child: Icon(Icons.notifications),
            ),
          ),
        ),
      );

      final positioned = tester.widget<Positioned>(find.byType(Positioned));
      expect(positioned.bottom, -8.0);
      expect(positioned.left, -8.0);
      expect(positioned.top, isNull);
      expect(positioned.right, isNull);
    });

    testWidgets('applies custom offset correctly', (tester) async {
      const customOffset = Offset(5, 10);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraPositionedBadge(
              badge: AuraBadge.dot(),
              offset: customOffset,
              child: Icon(Icons.notifications),
            ),
          ),
        ),
      );

      final positioned = tester.widget<Positioned>(find.byType(Positioned));
      expect(positioned.top, -8.0 + customOffset.dy);
      expect(positioned.right, -8.0 + customOffset.dx);
    });

    group('AuraBadgePosition enum', () {
      test('has all expected values', () {
        expect(AuraBadgePosition.values, hasLength(4));
        expect(AuraBadgePosition.values, contains(AuraBadgePosition.topLeft));
        expect(AuraBadgePosition.values, contains(AuraBadgePosition.topRight));
        expect(
          AuraBadgePosition.values,
          contains(AuraBadgePosition.bottomLeft),
        );
        expect(
          AuraBadgePosition.values,
          contains(AuraBadgePosition.bottomRight),
        );
      });
    });
  });
}
