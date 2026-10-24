import 'package:auravibes_app/features/workspaces/models/workspace_record_query.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_reference_page.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_record_query_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_references_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/usecases/browse_workspace_references_usecase.dart';
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
  testWidgets(
    'collection filters use controlled options and authorized labels',
    (tester) async {
      const table = WorkspaceTable(
        id: 'source',
        name: 'Source',
        labelColumnId: 'label',
        columns: [
          WorkspaceColumn(id: 'label', name: 'Title'),
          WorkspaceColumn(
            id: 'tags',
            name: 'Tags',
            type: .multiSelect,
            options: ['One', 'Two'],
          ),
          WorkspaceColumn(
            id: 'links',
            name: 'People',
            type: .reference,
            targetTableId: 'target',
            referenceMultiple: true,
          ),
        ],
        revision: 1,
        schemaRevision: 1,
      );
      const target = WorkspaceTable(
        id: 'target',
        name: 'People',
        labelColumnId: 'label',
        columns: [WorkspaceColumn(id: 'label', name: 'Name')],
        revision: 1,
        schemaRevision: 1,
      );
      final repository = _References();
      final queries = <WorkspaceRecordQuery>[];
      await tester.runAsync(
        () => tester.pumpWidget(
          TestableApp(
            child: WorkspaceRecordBrowser(
              workspaceId: 'one',
              table: table,
              onRecord: (_) => fail('Unexpected direct record open'),
            ),
            overrides: [
              workspaceRecordQueryProvider.overrideWith((ref, arguments) async {
                queries.add(arguments.$3);

                return const WorkspaceRecordPage(records: [], hasMore: false);
              }),
              workspaceReferencesUsecaseProvider('one').overrideWith(
                (ref) async => BrowseWorkspaceReferencesUsecase(repository),
              ),
              workspaceTableProvider(
                'one',
                'target',
              ).overrideWith((ref) async => target),
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
      await tester.tap(find.text('Tags').first);
      final _ = await tester.pumpAndSettle();
      final option = find.byWidgetPredicate(
        (widget) =>
            widget is AuraDropdownSelector<String> &&
            widget.identifier == 'workspace_filter_option',
      );
      expect(option, findsOneWidget);
      await tester.tap(option);
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text('Two').last);
      final _ = await tester.pumpAndSettle();
      final apply = find.byWidgetPredicate(
        (widget) =>
            widget is AuraButton &&
            widget.identifier == 'workspace_filter_apply',
      );
      await tester.ensureVisible(apply);
      final _ = await tester.pumpAndSettle();
      await tester.tap(apply);
      final _ = await tester.pumpAndSettle();
      expect(queries.last.filterValue, 'Two');
      expect(
        queries.last.filterOperator,
        WorkspaceRecordFilterOperator.contains,
      );
      final column = find.byType(AuraDropdownSelector<String>).first;
      await tester.ensureVisible(column);
      final _ = await tester.pumpAndSettle();
      await tester.tap(column);
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text('People').first);
      final _ = await tester.pumpAndSettle();
      final choose = find.byWidgetPredicate(
        (widget) =>
            widget is AuraButton &&
            widget.identifier == 'workspace_filter_reference',
      );
      await tester.ensureVisible(choose);
      final _ = await tester.pumpAndSettle();
      await tester.tap(choose);
      final _ = await tester.pumpAndSettle();
      expect(find.text('Add record'), findsNothing);
      expect(repository.requested, 'target');
      await tester.tap(find.text('Ada').last);
      await tester.tap(find.text('Done'));
      final _ = await tester.pumpAndSettle();
      expect(find.text('private-record-id'), findsNothing);
      await tester.ensureVisible(apply);
      final _ = await tester.pumpAndSettle();
      await tester.tap(apply);
      final _ = await tester.pumpAndSettle();
      expect(queries.last.filterColumnId, 'links');
      expect(queries.last.filterValue, 'private-record-id');
      expect(queries.last.filterOperator, WorkspaceRecordFilterOperator.equals);
    },
  );
}

class _References extends Fake implements WorkspaceReferenceRepository {
  String? requested;
  @override
  Future<WorkspaceReferencePage> tableTargets(
    String tableId, {
    required String search,
    String? afterId,
  }) async {
    requested = tableId;

    return const WorkspaceReferencePage(
      records: [
        WorkspaceRecord(
          id: 'private-record-id',
          tableId: 'target',
          values: {'label': 'Ada'},
          revision: 1,
        ),
      ],
    );
  }

  @override
  Future<WorkspaceRecord> record(String tableId, String id) async =>
      WorkspaceRecord(
        id: id,
        tableId: tableId,
        values: const {'label': 'Ada'},
        revision: 1,
      );
}
