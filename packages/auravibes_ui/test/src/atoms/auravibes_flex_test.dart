import 'package:auravibes_ui/src/atoms/auravibes_flex.dart';
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
    });

    testWidgets('applies custom crossAxisAlignment', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraColumn(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [SizedBox.shrink()],
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
              mainAxisAlignment: MainAxisAlignment.end,
              children: [SizedBox.shrink()],
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
              mainAxisSize: MainAxisSize.min,
              children: [SizedBox.shrink()],
            ),
          ),
        ),
      );

      final column = tester.widget<Column>(find.byType(Column));
      expect(column.mainAxisSize, MainAxisSize.min);
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
    });

    testWidgets('applies custom crossAxisAlignment', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraRow(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [SizedBox.shrink()],
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [SizedBox.shrink()],
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
              mainAxisSize: MainAxisSize.min,
              children: [SizedBox.shrink()],
            ),
          ),
        ),
      );

      final row = tester.widget<Row>(find.byType(Row));
      expect(row.mainAxisSize, MainAxisSize.min);
    });
  });
}
