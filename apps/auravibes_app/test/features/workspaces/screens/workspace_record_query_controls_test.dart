import 'package:auravibes_app/features/workspaces/models/workspace_record_query.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_record_query_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_record_browser.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_app.dart';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  for (final width in [400.0, 1200.0]) {
    testWidgets('typed filter drafts apply only after submission at $width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = .new(width, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const table = WorkspaceTable(
        id: 'table',
        name: 'Values',
        labelColumnId: 'label',
        columns: [
          WorkspaceColumn(id: 'label', name: 'Title'),
          WorkspaceColumn(id: 'quantity', name: 'Quantity', type: .number),
          WorkspaceColumn(id: 'cost', name: 'Cost', type: .money),
        ],
        revision: 1,
        schemaRevision: 1,
      );
      final queries = <WorkspaceRecordQuery>[];
      await tester.runAsync(
        () => tester.pumpWidget(
          TestableApp(
            child: WorkspaceRecordBrowser(
              workspaceId: 'one',
              table: table,
              onRecord: (_) => fail('Unexpected record navigation'),
            ),
            overrides: [
              workspaceRecordQueryProvider.overrideWith((ref, arguments) async {
                queries.add(arguments.$3);

                return const WorkspaceRecordPage(records: [], hasMore: false);
              }),
            ],
            workspaceId: 'one',
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();
      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is AuraIconButton &&
              widget.identifier == 'workspace_query_controls',
        ),
      );
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.byType(AuraDropdownSelector<String>).first);
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text('Quantity').first);
      final _ = await tester.pumpAndSettle();
      final apply = find.byWidgetPredicate(
        (widget) =>
            widget is AuraButton &&
            widget.identifier == 'workspace_filter_apply',
      );
      expect(apply, findsOneWidget);
      final input = find.byWidgetPredicate(
        (widget) =>
            widget is AuraInput &&
            widget.identifier == 'workspace_filter_value',
      );
      await tester.enterText(input, '2.0');
      final _ = await tester.pumpAndSettle();
      expect(queries.last.filterColumnId, isNull);
      await tester.ensureVisible(apply);
      final _ = await tester.pumpAndSettle();
      await tester.tap(apply);
      final _ = await tester.pumpAndSettle();
      expect(queries.last.filterColumnId, 'quantity');
      expect(queries.last.filterValue, '2.0');
      expect(find.text('Has value'), findsNothing);
      final selector = find.byType(AuraDropdownSelector<String>).first;
      await tester.ensureVisible(selector);
      final _ = await tester.pumpAndSettle();
      await tester.tap(selector);
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text('Cost').first);
      final _ = await tester.pumpAndSettle();
      expect(tester.widget<AuraButton>(apply).disabled, isFalse);
      expect(queries.last.filterColumnId, isNull);
      final amount = find.byWidgetPredicate(
        (widget) =>
            widget is AuraInput &&
            widget.identifier == 'workspace_filter_value',
      );
      await tester.ensureVisible(amount);
      final _ = await tester.pumpAndSettle();
      await tester.enterText(amount, '9007199254740993.123456789');
      final currency = find.byWidgetPredicate(
        (widget) =>
            widget is AuraInput &&
            widget.identifier == 'workspace_filter_value_currency',
      );
      await tester.ensureVisible(currency);
      final _ = await tester.pumpAndSettle();
      await tester.enterText(currency, 'USD');
      final _ = await tester.pumpAndSettle();
      expect(queries.last.filterColumnId, isNull);
      await tester.ensureVisible(apply);
      final _ = await tester.pumpAndSettle();
      await tester.tap(apply);
      final _ = await tester.pumpAndSettle();
      expect(queries.last.filterColumnId, 'cost');
      expect(
        queries.last.filterValue,
        '{"amount":"9007199254740993.123456789","currency":"USD"}',
      );
      final clear = find.byWidgetPredicate(
        (widget) =>
            widget is AuraButton &&
            widget.identifier == 'workspace_filter_clear',
      );
      await tester.ensureVisible(clear);
      final _ = await tester.pumpAndSettle();
      await tester.tap(clear);
      final _ = await tester.pumpAndSettle();
      expect(queries.last.filterColumnId, isNull);
    });
  }
}
