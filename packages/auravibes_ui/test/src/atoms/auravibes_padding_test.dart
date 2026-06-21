import 'package:auravibes_ui/src/atoms/aura_edge_insets_geometry.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraEdgeInsetsGeometry', () {
    test('only constructor sets individual sides', () {
      const padding = AuraEdgeInsetsGeometry.only(
        left: .sm,
        top: .md,
        right: .lg,
        bottom: .xl,
      );
      expect(padding.left, AuraSpacing.sm);
      expect(padding.top, AuraSpacing.md);
      expect(padding.right, AuraSpacing.lg);
      expect(padding.bottom, AuraSpacing.xl);
    });

    test('horizontal constructor sets left and right', () {
      const padding = AuraEdgeInsetsGeometry.horizontal(.md);
      expect(padding.left, AuraSpacing.md);
      expect(padding.right, AuraSpacing.md);
      expect(padding.top, AuraSpacing.none);
      expect(padding.bottom, AuraSpacing.none);
    });

    test('vertical constructor sets top and bottom', () {
      const padding = AuraEdgeInsetsGeometry.vertical(.md);
      expect(padding.top, AuraSpacing.md);
      expect(padding.bottom, AuraSpacing.md);
      expect(padding.left, AuraSpacing.none);
      expect(padding.right, AuraSpacing.none);
    });

    test('all constructor sets all sides', () {
      const padding = AuraEdgeInsetsGeometry.large;
      expect(padding.left, AuraSpacing.lg);
      expect(padding.top, AuraSpacing.lg);
      expect(padding.right, AuraSpacing.lg);
      expect(padding.bottom, AuraSpacing.lg);
    });

    test('symmetric constructor sets horizontal and vertical', () {
      const padding = AuraEdgeInsetsGeometry.symmetric(
        horizontal: .sm,
        vertical: .md,
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
      expect(AuraEdgeInsetsGeometry.base.top, AuraSpacing.base);
      expect(AuraEdgeInsetsGeometry.base.right, AuraSpacing.base);
      expect(AuraEdgeInsetsGeometry.base.bottom, AuraSpacing.base);
    });

    test('medium constant uses md spacing', () {
      expect(AuraEdgeInsetsGeometry.medium.left, AuraSpacing.md);
      expect(AuraEdgeInsetsGeometry.medium.top, AuraSpacing.md);
      expect(AuraEdgeInsetsGeometry.medium.right, AuraSpacing.md);
      expect(AuraEdgeInsetsGeometry.medium.bottom, AuraSpacing.md);
    });

    test('large constant uses lg spacing', () {
      expect(AuraEdgeInsetsGeometry.large.left, AuraSpacing.lg);
      expect(AuraEdgeInsetsGeometry.large.top, AuraSpacing.lg);
      expect(AuraEdgeInsetsGeometry.large.right, AuraSpacing.lg);
      expect(AuraEdgeInsetsGeometry.large.bottom, AuraSpacing.lg);
    });

    test('small constant uses sm spacing', () {
      expect(AuraEdgeInsetsGeometry.small.left, AuraSpacing.sm);
      expect(AuraEdgeInsetsGeometry.small.top, AuraSpacing.sm);
      expect(AuraEdgeInsetsGeometry.small.right, AuraSpacing.sm);
      expect(AuraEdgeInsetsGeometry.small.bottom, AuraSpacing.sm);
    });

    test('equality works for same values', () {
      const a = AuraEdgeInsetsGeometry.medium;
      const b = AuraEdgeInsetsGeometry.medium;
      expect(a, b);
    });

    test('equality fails for different values', () {
      const a = AuraEdgeInsetsGeometry.medium;
      const b = AuraEdgeInsetsGeometry.large;
      expect(a, isNot(b));
    });

    test('hashCode is consistent', () {
      const a = AuraEdgeInsetsGeometry.medium;
      const b = AuraEdgeInsetsGeometry.medium;
      expect(a.hashCode, b.hashCode);
    });
  });

  group('AuraPadding', () {
    testWidgets('renders child with default padding', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(
            body: AuraPadding(
              child: Text('Padded'),
            ),
          ),
          theme: ThemeData(extensions: [AuraTheme.light]),
        ),
      );

      expect(find.text('Padded'), findsOneWidget);
      expect(find.byType(Padding), findsOneWidget);
    });

    testWidgets('renders child with custom padding', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(
            body: AuraPadding(
              child: Text('Large Padded'),
              padding: AuraEdgeInsetsGeometry.large,
            ),
          ),
          theme: ThemeData(extensions: [AuraTheme.light]),
        ),
      );

      expect(find.text('Large Padded'), findsOneWidget);
      final paddingWidget = tester.widget<Padding>(find.byType(Padding));
      final edgeInsets = paddingWidget.padding as EdgeInsets;
      expect(edgeInsets.left, 24);
      expect(edgeInsets.top, 24);
      expect(edgeInsets.right, 24);
      expect(edgeInsets.bottom, 24);
    });

    testWidgets('applies correct padding values through context', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(
            body: AuraPadding(
              child: SizedBox(width: 100, height: 100),
              padding: AuraEdgeInsetsGeometry.medium,
            ),
          ),
          theme: ThemeData(extensions: [AuraTheme.light]),
        ),
      );

      final paddingWidget = tester.widget<Padding>(find.byType(Padding));
      final edgeInsets = paddingWidget.padding as EdgeInsets;
      expect(edgeInsets.left, 16);
      expect(edgeInsets.top, 16);
      expect(edgeInsets.right, 16);
      expect(edgeInsets.bottom, 16);
    });
  });
}
