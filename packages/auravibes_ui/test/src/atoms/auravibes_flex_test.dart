import 'package:auravibes_ui/src/atoms/aura_edge_insets_geometry.dart';
import 'package:auravibes_ui/src/atoms/aura_flex.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraFlex', () {
    testWidgets('renders children with default spacing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraFlex.column(children: [Text('Item 1'), Text('Item 2')]),
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.byType(Flex), findsOneWidget);
      final auraFlex = tester.widget<AuraFlex>(find.byType(AuraFlex));
      expect(tester.widget<Flex>(find.byType(Flex)).direction, Axis.vertical);
      expect(auraFlex.spacing, AuraSpacing.base);
    });

    testWidgets('applies custom crossAxisAlignment', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraFlex.column(
              children: [SizedBox.shrink()],
              crossAxisAlignment: CrossAxisAlignment.start,
            ),
          ),
        ),
      );

      final column = tester.widget<Flex>(find.byType(Flex));
      expect(column.crossAxisAlignment, CrossAxisAlignment.start);
    });

    testWidgets('applies custom mainAxisAlignment', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraFlex.column(
              children: [SizedBox.shrink()],
              mainAxisAlignment: MainAxisAlignment.end,
            ),
          ),
        ),
      );

      final column = tester.widget<Flex>(find.byType(Flex));
      expect(column.mainAxisAlignment, MainAxisAlignment.end);
    });

    testWidgets('applies custom mainAxisSize', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraFlex.column(
              children: [SizedBox.shrink()],
              mainAxisSize: MainAxisSize.min,
            ),
          ),
        ),
      );

      final column = tester.widget<Flex>(find.byType(Flex));
      expect(column.mainAxisSize, MainAxisSize.min);
    });

    testWidgets('applies tokenized padding', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(
            body: AuraFlex.column(
              children: [SizedBox.shrink()],
              padding: AuraEdgeInsetsGeometry.medium,
            ),
          ),
          theme: ThemeData(extensions: [AuraTheme.light]),
        ),
      );

      final padding = tester.widget<Padding>(find.byType(Padding));
      final edgeInsets = padding.padding as EdgeInsets;
      expect(edgeInsets.left, AuraTheme.light.spacing.md);
      expect(edgeInsets.top, AuraTheme.light.spacing.md);
      expect(edgeInsets.right, AuraTheme.light.spacing.md);
      expect(edgeInsets.bottom, AuraTheme.light.spacing.md);
    });
  });

  group('AuraFlex', () {
    testWidgets('renders children with default spacing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraFlex.row(children: [Text('Item 1'), Text('Item 2')]),
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.byType(Flex), findsOneWidget);
      final auraFlex = tester.widget<AuraFlex>(find.byType(AuraFlex));
      expect(tester.widget<Flex>(find.byType(Flex)).direction, Axis.horizontal);
      expect(auraFlex.spacing, AuraSpacing.base);
    });

    testWidgets('applies custom crossAxisAlignment', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraFlex.row(
              children: [SizedBox.shrink()],
              crossAxisAlignment: CrossAxisAlignment.end,
            ),
          ),
        ),
      );

      final row = tester.widget<Flex>(find.byType(Flex));
      expect(row.crossAxisAlignment, CrossAxisAlignment.end);
    });

    testWidgets('applies custom mainAxisAlignment', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraFlex.row(
              children: [SizedBox.shrink()],
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
            ),
          ),
        ),
      );

      final row = tester.widget<Flex>(find.byType(Flex));
      expect(row.mainAxisAlignment, MainAxisAlignment.spaceBetween);
    });

    testWidgets('applies custom mainAxisSize', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraFlex.row(
              children: [SizedBox.shrink()],
              mainAxisSize: MainAxisSize.min,
            ),
          ),
        ),
      );

      final row = tester.widget<Flex>(find.byType(Flex));
      expect(row.mainAxisSize, MainAxisSize.min);
    });

    testWidgets('applies tokenized padding', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(
            body: AuraFlex.row(
              children: [SizedBox.shrink()],
              padding: AuraEdgeInsetsGeometry.small,
            ),
          ),
          theme: ThemeData(extensions: [AuraTheme.light]),
        ),
      );

      final padding = tester.widget<Padding>(find.byType(Padding));
      final edgeInsets = padding.padding as EdgeInsets;
      expect(edgeInsets.left, AuraTheme.light.spacing.sm);
      expect(edgeInsets.top, AuraTheme.light.spacing.sm);
      expect(edgeInsets.right, AuraTheme.light.spacing.sm);
      expect(edgeInsets.bottom, AuraTheme.light.spacing.sm);
    });
  });
}
