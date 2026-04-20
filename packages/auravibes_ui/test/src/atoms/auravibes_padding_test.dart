import 'package:auravibes_ui/src/atoms/auravibes_padding.dart';
import 'package:auravibes_ui/src/tokens/auravibes_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraEdgeInsetsGeometry', () {
    test('only constructor sets individual sides', () {
      const padding = AuraEdgeInsetsGeometry.only(
        left: AuraSpacing.sm,
        top: AuraSpacing.md,
        right: AuraSpacing.lg,
        bottom: AuraSpacing.xl,
      );
      expect(padding.left, AuraSpacing.sm);
      expect(padding.top, AuraSpacing.md);
      expect(padding.right, AuraSpacing.lg);
      expect(padding.bottom, AuraSpacing.xl);
    });

    test('horizontal constructor sets left and right', () {
      const padding = AuraEdgeInsetsGeometry.horizontal(AuraSpacing.md);
      expect(padding.left, AuraSpacing.md);
      expect(padding.right, AuraSpacing.md);
      expect(padding.top, AuraSpacing.none);
      expect(padding.bottom, AuraSpacing.none);
    });

    test('vertical constructor sets top and bottom', () {
      const padding = AuraEdgeInsetsGeometry.vertical(AuraSpacing.md);
      expect(padding.top, AuraSpacing.md);
      expect(padding.bottom, AuraSpacing.md);
      expect(padding.left, AuraSpacing.none);
      expect(padding.right, AuraSpacing.none);
    });

    test('all constructor sets all sides', () {
      const padding = AuraEdgeInsetsGeometry.all(AuraSpacing.lg);
      expect(padding.left, AuraSpacing.lg);
      expect(padding.top, AuraSpacing.lg);
      expect(padding.right, AuraSpacing.lg);
      expect(padding.bottom, AuraSpacing.lg);
    });

    test('symmetric constructor sets horizontal and vertical', () {
      const padding = AuraEdgeInsetsGeometry.symmetric(
        horizontal: AuraSpacing.sm,
        vertical: AuraSpacing.md,
      );
      expect(padding.left, AuraSpacing.sm);
      expect(padding.right, AuraSpacing.sm);
      expect(padding.top, AuraSpacing.md);
      expect(padding.bottom, AuraSpacing.md);
    });

    test('none constant has no padding', () {
      expect(AuraEdgeInsetsGeometry.none.left, AuraSpacing.none);
      expect(AuraEdgeInsetsGeometry.none.top, AuraSpacing.none);
      expect(AuraEdgeInsetsGeometry.none.right, AuraSpacing.none);
      expect(AuraEdgeInsetsGeometry.none.bottom, AuraSpacing.none);
    });

    test('base constant uses base spacing', () {
      expect(AuraEdgeInsetsGeometry.base.left, AuraSpacing.base);
    });

    test('medium constant uses md spacing', () {
      expect(AuraEdgeInsetsGeometry.medium.left, AuraSpacing.md);
    });

    test('large constant uses lg spacing', () {
      expect(AuraEdgeInsetsGeometry.large.left, AuraSpacing.lg);
    });

    test('small constant uses sm spacing', () {
      expect(AuraEdgeInsetsGeometry.small.left, AuraSpacing.sm);
    });

    test('equality works for same values', () {
      const a = AuraEdgeInsetsGeometry.all(AuraSpacing.md);
      const b = AuraEdgeInsetsGeometry.all(AuraSpacing.md);
      expect(a, b);
    });

    test('equality fails for different values', () {
      const a = AuraEdgeInsetsGeometry.all(AuraSpacing.md);
      const b = AuraEdgeInsetsGeometry.all(AuraSpacing.lg);
      expect(a, isNot(b));
    });

    test('hashCode is consistent', () {
      const a = AuraEdgeInsetsGeometry.all(AuraSpacing.md);
      const b = AuraEdgeInsetsGeometry.all(AuraSpacing.md);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('AuraPadding', () {
    testWidgets('renders child with default padding', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [AuraTheme.light]),
          home: const Scaffold(
            body: AuraPadding(
              child: Text('Padded'),
            ),
          ),
        ),
      );

      expect(find.text('Padded'), findsOneWidget);
      expect(find.byType(Padding), findsOneWidget);
    });

    testWidgets('renders child with custom padding', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [AuraTheme.light]),
          home: const Scaffold(
            body: AuraPadding(
              padding: AuraEdgeInsetsGeometry.all(AuraSpacing.lg),
              child: Text('Large Padded'),
            ),
          ),
        ),
      );

      expect(find.text('Large Padded'), findsOneWidget);
      final paddingWidget = tester.widget<Padding>(find.byType(Padding));
      final edgeInsets = paddingWidget.padding as EdgeInsets;
      expect(edgeInsets.left, AuraTheme.light.spacing.lg);
      expect(edgeInsets.top, AuraTheme.light.spacing.lg);
      expect(edgeInsets.right, AuraTheme.light.spacing.lg);
      expect(edgeInsets.bottom, AuraTheme.light.spacing.lg);
    });

    testWidgets('renders with null child', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [AuraTheme.light]),
          home: const Scaffold(
            body: AuraPadding(child: null),
          ),
        ),
      );

      expect(find.byType(AuraPadding), findsOneWidget);
    });

    testWidgets('applies correct padding values through context', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [AuraTheme.light]),
          home: const Scaffold(
            body: AuraPadding(
              padding: AuraEdgeInsetsGeometry.all(AuraSpacing.md),
              child: SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      final paddingWidget = tester.widget<Padding>(find.byType(Padding));
      final edgeInsets = paddingWidget.padding as EdgeInsets;
      expect(edgeInsets.left, AuraTheme.light.spacing.md);
      expect(edgeInsets.top, AuraTheme.light.spacing.md);
    });
  });
}
