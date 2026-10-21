import 'package:auravibes_ui/src/atoms/aura_column.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('forwards AuraColumn and AuraRow layout configuration', (
    tester,
  ) async {
    await tester.pumpWidget(
      AuraThemeScope(
        theme: .light,
        child: MaterialApp(
          home: const Scaffold(
            body: SingleChildScrollView(
              child: Column(
                mainAxisSize: .min,
                children: [
                  AuraColumn(
                    children: [Text('Column item 1'), Text('Column item 2')],
                    key: ValueKey('column-default'),
                  ),
                  AuraColumn(
                    children: [SizedBox.shrink()],
                    crossAxisAlignment: .start,
                    key: ValueKey('column-cross-axis'),
                  ),
                  AuraColumn(
                    children: [SizedBox.shrink()],
                    mainAxisAlignment: .end,
                    key: ValueKey('column-main-axis-alignment'),
                  ),
                  AuraColumn(
                    children: [SizedBox.shrink()],
                    mainAxisSize: .min,
                    key: ValueKey('column-main-axis-size'),
                  ),
                  AuraColumn(
                    children: [SizedBox.shrink()],
                    padding: .medium,
                    key: ValueKey('column-padding'),
                  ),
                  AuraRow(
                    children: [Text('Row item 1'), Text('Row item 2')],
                    key: ValueKey('row-default'),
                  ),
                  AuraRow(
                    children: [SizedBox.shrink()],
                    crossAxisAlignment: .end,
                    key: ValueKey('row-cross-axis'),
                  ),
                  AuraRow(
                    children: [SizedBox.shrink()],
                    mainAxisAlignment: .spaceBetween,
                    key: ValueKey('row-main-axis-alignment'),
                  ),
                  AuraRow(
                    children: [SizedBox.shrink()],
                    mainAxisSize: .min,
                    key: ValueKey('row-main-axis-size'),
                  ),
                  AuraRow(
                    children: [SizedBox.shrink()],
                    padding: .small,
                    key: ValueKey('row-padding'),
                  ),
                ],
              ),
            ),
          ),
          theme: .new(),
        ),
      ),
    );

    Finder within(String key, Finder matching) => find.descendant(
      of: find.byKey(ValueKey<String>(key)),
      matching: matching,
    );
    Column column(String key) =>
        tester.widget<Column>(within(key, find.byType(Column)));
    Row row(String key) => tester.widget<Row>(within(key, find.byType(Row)));

    final defaultColumn = tester.widget<AuraColumn>(
      find.byKey(const ValueKey('column-default')),
    );
    expect(
      within('column-default', find.text('Column item 1')),
      findsOneWidget,
    );
    expect(
      within('column-default', find.text('Column item 2')),
      findsOneWidget,
    );
    expect(defaultColumn.spacing, AuraSpacing.base);
    expect(
      column('column-cross-axis').crossAxisAlignment,
      CrossAxisAlignment.start,
    );
    expect(
      column('column-main-axis-alignment').mainAxisAlignment,
      MainAxisAlignment.end,
    );
    expect(column('column-main-axis-size').mainAxisSize, MainAxisSize.min);

    final columnPadding = tester.widget<Padding>(
      within('column-padding', find.byType(Padding)),
    );
    final columnInsets = columnPadding.padding as EdgeInsets;
    expect(columnInsets.left, AuraTheme.light.spacing.md);
    expect(columnInsets.top, AuraTheme.light.spacing.md);
    expect(columnInsets.right, AuraTheme.light.spacing.md);
    expect(columnInsets.bottom, AuraTheme.light.spacing.md);

    final defaultRow = tester.widget<AuraRow>(
      find.byKey(const ValueKey('row-default')),
    );
    expect(within('row-default', find.text('Row item 1')), findsOneWidget);
    expect(within('row-default', find.text('Row item 2')), findsOneWidget);
    expect(defaultRow.spacing, AuraSpacing.base);
    expect(row('row-cross-axis').crossAxisAlignment, CrossAxisAlignment.end);
    expect(
      row('row-main-axis-alignment').mainAxisAlignment,
      MainAxisAlignment.spaceBetween,
    );
    expect(row('row-main-axis-size').mainAxisSize, MainAxisSize.min);

    final rowPadding = tester.widget<Padding>(
      within('row-padding', find.byType(Padding)),
    );
    final rowInsets = rowPadding.padding as EdgeInsets;
    expect(rowInsets.left, AuraTheme.light.spacing.sm);
    expect(rowInsets.top, AuraTheme.light.spacing.sm);
    expect(rowInsets.right, AuraTheme.light.spacing.sm);
    expect(rowInsets.bottom, AuraTheme.light.spacing.sm);
  });
}
