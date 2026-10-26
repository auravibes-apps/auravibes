import 'package:auravibes_app/features/workspaces/models/workspace_record_change.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_view_action_provider.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/submit_workspace_view_action_usecase.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_view_surface.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
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

  testWidgets('form approval can be cancelled and partial outcome is visible', (
    tester,
  ) async {
    final calls = <Map<String, Object?>>[];
    final usecase = _usecase(
      executeConnector:
          ({
            required workspaceId,
            required viewId,
            required expectedRevision,
            required action,
            required formValues,
            required arguments,
            required operationId,
          }) async {
            calls.add(arguments);

            return {'status': 'partial', 'retryBlocked': true};
          },
    );
    await _pump(tester, usecase);

    await tester.enterText(find.byType(EditableText), 'approved query');
    await tester.tap(
      find.byKey(const ValueKey('workspace_view_action_submit')),
    );
    final _ = await tester.pumpAndSettle();
    expect(find.text('Review submission'), findsOneWidget);
    expect(
      find.text('Review this submission before it is applied.'),
      findsOneWidget,
    );
    await tester.tap(
      find.descendant(of: find.byType(Dialog), matching: find.text('Cancel')),
    );
    final _ = await tester.pumpAndSettle();
    expect(calls, isEmpty);

    await tester.tap(
      find.byKey(const ValueKey('workspace_view_action_submit')),
    );
    final _ = await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: find.byType(Dialog), matching: find.text('Submit')),
    );
    final _ = await tester.pumpAndSettle();

    expect(calls, [
      {'query': 'approved query'},
    ]);
    expect(
      find.text(
        'The service reported partial completion. '
        'Review the connected service before trying again.',
      ),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('invalid form values show an actionable message', (tester) async {
    var calls = 0;
    await _pump(
      tester,
      _usecase(
        executeConnector:
            ({
              required workspaceId,
              required viewId,
              required expectedRevision,
              required action,
              required formValues,
              required arguments,
              required operationId,
            }) async {
              calls++;

              return {'status': 'completed'};
            },
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('workspace_view_action_submit')),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.text('Check the form values and try again.'), findsOneWidget);
    expect(calls, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Future<void> _pump(
  WidgetTester tester,
  SubmitWorkspaceViewActionUsecase usecase,
) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(
      TestableApp(
        child: WorkspaceViewSurface(data: _data(), workspaceId: 'workspace'),
        overrides: [
          workspaceViewActionUsecaseProvider('workspace')
              .overrideWith((ref) async => usecase),
        ],
        workspaceId: 'workspace',
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 30));
  });
  final _ = await tester.pumpAndSettle();
}

WorkspaceViewData _data() {
  final connector = connectorDefinitions.firstWhere(
    (candidate) => candidate.identifier == 'synthetic',
  );
  final tool = connector.tools.firstWhere(
    (candidate) => candidate.slug == 'search',
  );
  final view = WorkspaceView(
    id: 'view',
    name: 'Search form',
    tableId: '',
    bindings: const {'source': ''},
    columnTypes: const {},
    definition: .fromJson(_formDefinition, requiresUserAction: true),
    revision: 1,
    action: .fromJson({
      'version': 1,
      'type': 'connectorWrite',
      'toolId': connectorToolId(connector, tool),
      'revision': connectorToolRevision(connector, tool),
      'connectionId': 'service:synthetic-submit',
      'inputs': {'query': '/answers/query'},
    }),
  );

  return WorkspaceViewData(
    view: view,
    table: const WorkspaceTable(
      id: '',
      name: 'Live',
      labelColumnId: '',
      columns: [],
      revision: 1,
      schemaRevision: 0,
    ),
    records: const [],
    needsRepair: false,
  );
}

const Map<String, Object?> _formDefinition = {
  'version': 1,
  'components': [
    {
      'id': 'root',
      'component': 'Column',
      'children': ['query'],
    },
    {
      'id': 'query',
      'component': 'TextField',
      'label': 'Search query',
      'required': true,
      'value': {'path': '/answers/query'},
    },
  ],
};

SubmitWorkspaceViewActionUsecase _usecase({
  required WorkspaceConnectorActionExecutor executeConnector,
}) => SubmitWorkspaceViewActionUsecase(
  views: _Views(_data().view),
  tables: _Tables(),
  editRecords: .new(_Batch()),
  executeConnector: executeConnector,
);

class _Views(final WorkspaceView view) implements WorkspaceViewRepository {
  @override
  Future<WorkspaceView> read(String id) async => view;
  @override
  Future<List<WorkspaceView>> list({
    String? parentId,
    bool allFolders = false,
  }) async => [view];
  @override
  Future<WorkspaceView> save(
    WorkspaceView view, {
    required String requestId,
  }) async => view;
  @override
  Future<List<WorkspaceView>> history(String id) async => [view];
}

class _Tables extends Fake implements OrganizeWorkspaceTablesUsecase {
  @override
  String toString() => 'Workspace tables fake';
}

class _Batch implements WorkspaceRecordBatchRepository {
  @override
  Future<void> apply(
    List<WorkspaceRecordChange> changes, {
    required String requestId,
  }) => Future<void>.value();
}
