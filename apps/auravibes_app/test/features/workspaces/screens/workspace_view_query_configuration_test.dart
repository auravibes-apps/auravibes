import 'dart:convert';

import 'package:auravibes_app/features/workspaces/models/workspace_record_query.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_reference_page.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_references_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/usecases/browse_workspace_references_usecase.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_view_query_editor.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_app.dart';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  testWidgets('query selects authorized relationship and presentation', (
    tester,
  ) async {
    const table = WorkspaceTable(
      id: 'source',
      name: 'Source',
      labelColumnId: 'label',
      columns: [
        WorkspaceColumn(id: 'label', name: 'Title'),
        WorkspaceColumn(
          id: 'link',
          name: 'People',
          type: .reference,
          targetTableId: 'target',
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
    final query = ValueNotifier(const WorkspaceRecordQuery());
    final summary = ValueNotifier(<String>{});
    final action = ValueNotifier<A2uiSavedAction?>(null);
    final layout = TextEditingController();
    addTearDown(query.dispose);
    addTearDown(summary.dispose);
    addTearDown(action.dispose);
    addTearDown(layout.dispose);
    final view = WorkspaceView.create(
      name: 'Related',
      table: table,
      columnIds: ['label'],
    );
    final data = WorkspaceViewData(
      view: view,
      table: table,
      records: [],
      needsRepair: false,
    );
    await tester.runAsync(
      () => tester.pumpWidget(
        TestableApp(
          child: Scaffold(
            body: ValueListenableBuilder(
              valueListenable: query,
              builder: (context, value, child) => SingleChildScrollView(
                child: WorkspaceViewQueryEditor(
                  workspaceId: 'one',
                  data: data,
                  query: query,
                  layout: layout,
                  summary: summary,
                  bindings: view.bindings,
                  action: action,
                ),
              ),
            ),
          ),
          overrides: [
            workspaceReferencesUsecaseProvider('one').overrideWith(
              (ref) async => BrowseWorkspaceReferencesUsecase(_References()),
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
    await tester.tap(find.text('Query and presentation'));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.byType(AuraDropdownSelector<String>).first);
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('People').first);
    final _ = await tester.pumpAndSettle();
    await tester.tap(_button('workspace_filter_reference'));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Ada').last);
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Apply selection'));
    final _ = await tester.pumpAndSettle();
    await tester.ensureVisible(_button('workspace_filter_apply'));
    await tester.tap(_button('workspace_filter_apply'));
    final _ = await tester.pumpAndSettle();
    expect(query.value.filterColumnId, 'link');
    expect(query.value.filterValue, 'private-record-id');
    expect(find.text('private-record-id'), findsNothing);
    await tester.ensureVisible(_button('workspace_view_layout_detail'));
    await tester.tap(_button('workspace_view_layout_detail'));
    final definition = A2uiSavedDefinition.fromJson(
      Map<String, Object?>.from(jsonDecode(layout.text) as Map),
    );
    expect(
      definition.components.any(
        (component) => component['id'] == 'detail_field0',
      ),
      isTrue,
    );
    await tester.ensureVisible(_button('workspace_view_layout_form'));
    await tester.tap(_button('workspace_view_layout_form'));
    final formDefinition = A2uiSavedDefinition.fromJson(
      Map<String, Object?>.from(jsonDecode(layout.text) as Map),
      requiresUserAction: action.value != null,
    );
    expect(
      formDefinition.components.any(
        (component) => component['id'] == 'input_field0',
      ),
      isTrue,
    );
    expect(action.value?.type, A2uiSavedActionType.updateSelectedRecord);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Finder _button(String identifier) => find.byWidgetPredicate(
  (widget) => widget is AuraButton && widget.identifier == identifier,
);

class _References extends Fake implements WorkspaceReferenceRepository {
  @override
  Future<WorkspaceReferencePage> tableTargets(
    String tableId, {
    required String search,
    String? afterId,
  }) async => const WorkspaceReferencePage(
    records: [
      WorkspaceRecord(
        id: 'private-record-id',
        tableId: 'target',
        values: {'label': 'Ada'},
        revision: 1,
      ),
    ],
  );
  @override
  Future<WorkspaceRecord> record(String tableId, String id) async =>
      WorkspaceRecord(
        id: id,
        tableId: tableId,
        values: const {'label': 'Ada'},
        revision: 1,
      );
}
