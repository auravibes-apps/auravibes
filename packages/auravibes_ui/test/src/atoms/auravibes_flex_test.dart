import 'package:auravibes_ui/src/atoms/aura_column.dart';
import 'package:auravibes_ui/src/atoms/aura_edge_insets_geometry.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraColumn', () {
    testWidgets('renders children with default spacing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraColumn(
              children: [
                Text('Item 1'),
                Text('Item 2'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.byType(Column), findsOneWidget);
      final auraColumn = tester.widget<AuraColumn>(find.byType(AuraColumn));
      expect(auraColumn.spacing, AuraSpacing.base);
    });

    testWidgets('applies custom crossAxisAlignment', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraColumn(
              children: [SizedBox.shrink()],
              crossAxisAlignment: CrossAxisAlignment.start,
            ),
          ),
        ),
      );

      final column = tester.widget<Column>(find.byType(Column));
      expect(column.crossAxisAlignment, CrossAxisAlignment.start);
    });

    testWidgets('applies custom mainAxisAlignment', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraColumn(
              children: [SizedBox.shrink()],
              mainAxisAlignment: MainAxisAlignment.end,
            ),
          ),
        ),
      );

      final column = tester.widget<Column>(find.byType(Column));
      expect(column.mainAxisAlignment, MainAxisAlignment.end);
    });

    testWidgets('applies custom mainAxisSize', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraColumn(
              children: [SizedBox.shrink()],
              mainAxisSize: MainAxisSize.min,
            ),
          ),
        ),
      );

      final column = tester.widget<Column>(find.byType(Column));
      expect(column.mainAxisSize, MainAxisSize.min);
    });

    testWidgets('applies tokenized padding', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(
            body: AuraColumn(
              children: [SizedBox.shrink()],
              padding: AuraEdgeInsetsGeometry.medium,
            ),
          ),
          theme: ThemeData(extensions: [AuraTheme.light]),
        ),
      );

      final padding = tester.widget<Padding>(find.byType(Padding));
      final edgeInsets = padding.padding as EdgeInsets;
      expect(edgeInsets.left, 16);
      expect(edgeInsets.top, 16);
      expect(edgeInsets.right, 16);
      expect(edgeInsets.bottom, 16);
    });
  });

  group('AuraRow', () {
    testWidgets('renders children with default spacing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraRow(
              children: [
                Text('Item 1'),
                Text('Item 2'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.byType(Row), findsOneWidget);
      final auraRow = tester.widget<AuraRow>(find.byType(AuraRow));
      expect(auraRow.spacing, AuraSpacing.base);
    });

    testWidgets('applies custom crossAxisAlignment', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraRow(
              children: [SizedBox.shrink()],
              crossAxisAlignment: CrossAxisAlignment.end,
            ),
          ),
        ),
      );

      final row = tester.widget<Row>(find.byType(Row));
      expect(row.crossAxisAlignment, CrossAxisAlignment.end);
    });

    testWidgets('applies custom mainAxisAlignment', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraRow(
              children: [SizedBox.shrink()],
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
            ),
          ),
        ),
      );

      final row = tester.widget<Row>(find.byType(Row));
      expect(row.mainAxisAlignment, MainAxisAlignment.spaceBetween);
    });

    testWidgets('applies custom mainAxisSize', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraRow(
              children: [SizedBox.shrink()],
              mainAxisSize: MainAxisSize.min,
            ),
          ),
        ),
      );

      final row = tester.widget<Row>(find.byType(Row));
      expect(row.mainAxisSize, MainAxisSize.min);
    });

    testWidgets('applies tokenized padding', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(
            body: AuraRow(
              children: [SizedBox.shrink()],
              padding: AuraEdgeInsetsGeometry.small,
            ),
          ),
          theme: ThemeData(extensions: [AuraTheme.light]),
        ),
      );

      final padding = tester.widget<Padding>(find.byType(Padding));
      final edgeInsets = padding.padding as EdgeInsets;
      expect(edgeInsets.left, 8);
      expect(edgeInsets.top, 8);
      expect(edgeInsets.right, 8);
      expect(edgeInsets.bottom, 8);
    });
  });
}
