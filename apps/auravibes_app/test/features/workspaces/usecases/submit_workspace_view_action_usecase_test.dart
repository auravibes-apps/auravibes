import 'package:auravibes_app/features/workspaces/models/workspace_record_change.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/submit_workspace_view_action_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart'
    show A2uiSavedActionType;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'default mode asks before applying one atomic owned record edit',
    () async {
      final fixture = _Fixture();
      final called = await fixture.usecase.call(
        request: const .new(
          workspaceId: 'workspace',
          viewId: 'view',
          expectedRevision: 2,
          formValues: {
            'answers': {'title': 'Updated'},
          },
          recordId: 'record',
          requestId: 'form-submit',
        ),
        approve: ({required view, required action, required values}) async {
          expect(view.id, 'view');
          expect(action.type, A2uiSavedActionType.updateSelectedRecord);
          expect(values, {fixture.title.id: 'Updated'});

          return true;
        },
      );

      expect(called, isTrue);
      expect(fixture.batch.applied?.single.record.id, 'record');
      expect(fixture.batch.applied?.single.values, {
        fixture.title.id: 'Updated',
      });
      expect(fixture.batch.requestId, 'form-submit');
    },
  );

  test('allow-all is explicit and skips the approval callback', () async {
    final fixture = _Fixture();
    final _ = await fixture.usecase.call(
      request: const .new(
        workspaceId: 'workspace',
        viewId: 'view',
        expectedRevision: 2,
        formValues: {
          'answers': {'title': 'Updated'},
        },
        recordId: 'record',
        mode: .allowAll,
      ),
      approve: ({required view, required action, required values}) async =>
          fail('allow-all must not ask'),
    );

    expect(fixture.batch.applied, hasLength(1));
  });

  test(
    'allow-all still rejects a saved view changed before mutation',
    () async {
      final fixture = _Fixture();
      fixture.views.changeAfterFirstRead = true;
      await expectLater(
        fixture.usecase.call(
          request: const .new(
            workspaceId: 'workspace',
            viewId: 'view',
            expectedRevision: 2,
            formValues: {
              'answers': {'title': 'Updated'},
            },
            recordId: 'record',
            mode: .allowAll,
          ),
          approve: ({required view, required action, required values}) async =>
              fail('allow-all must not ask'),
        ),
        throwsA(isA<WorkspaceTableException>()),
      );
      expect(fixture.batch.applied, isNull);
    },
  );

  test('invalid form values and stale views never mutate', () async {
    final fixture = _Fixture();
    await expectLater(
      fixture.usecase.call(
        request: const .new(
          workspaceId: 'workspace',
          viewId: 'view',
          expectedRevision: 1,
          formValues: {
            'answers': {'title': 'Updated'},
          },
          recordId: 'record',
        ),
        approve: ({required view, required action, required values}) async =>
            true,
      ),
      throwsA(isA<WorkspaceTableException>()),
    );
    await expectLater(
      fixture.usecase.call(
        request: const .new(
          workspaceId: 'workspace',
          viewId: 'view',
          expectedRevision: 2,
          formValues: {
            'answers': {'title': 42},
          },
          recordId: 'record',
        ),
        approve: ({required view, required action, required values}) async =>
            true,
      ),
      throwsA(isA<WorkspaceViewFormValidationException>()),
    );
    expect(fixture.batch.applied, isNull);
  });
}

class _Fixture {
  final _FixtureParts parts = .create();

  WorkspaceColumn get title => parts.title;
  WorkspaceView get view => parts.view;
  _Views get views => parts.views;
  _Batch get batch => parts.batch;
  SubmitWorkspaceViewActionUsecase get usecase => parts.usecase;
}

class const _FixtureParts({
  required final WorkspaceColumn title,
  required final WorkspaceView view,
  required final _Views views,
  required final _Batch batch,
  required final SubmitWorkspaceViewActionUsecase usecase,
}) {
  factory create() {
    const title = WorkspaceColumn(id: 'title', name: 'Title');
    final table = WorkspaceTable(
      id: 'table',
      name: 'Items',
      labelColumnId: title.id,
      columns: [title],
      revision: 1,
      schemaRevision: 3,
    );
    final view = WorkspaceView(
      id: 'view',
      name: 'Edit item',
      tableId: table.id,
      bindings: {'field0': title.id},
      columnTypes: {title.id: 'text'},
      definition: .fromJson({
        'version': 1,
        'components': [
          {
            'id': 'root',
            'component': 'Column',
            'children': ['title'],
          },
          {
            'id': 'title',
            'component': 'TextField',
            'label': 'Title',
            'value': {'path': '/answers/title'},
          },
        ],
      }),
      revision: 2,
      action: .fromJson({
        'version': 1,
        'type': 'updateSelectedRecord',
        'inputs': {title.id: '/answers/title'},
      }),
    );
    final views = _Views(view);
    final tables = _Tables(table);
    final batch = _Batch();
    final usecase = SubmitWorkspaceViewActionUsecase(
      views: views,
      tables: tables,
      editRecords: .new(batch),
      executeConnector: (_) async =>
          throw StateError('unexpected Connector action'),
    );

    return .new(
      title: title,
      view: view,
      views: views,
      batch: batch,
      usecase: usecase,
    );
  }
}

class _Views(final WorkspaceView view) implements WorkspaceViewRepository {
  bool changeAfterFirstRead = false;
  var _reads = 0;
  @override
  Future<WorkspaceView> read(String id) async {
    _reads++;
    if (changeAfterFirstRead && _reads > 1) return view.withRevision(3);

    return view;
  }

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

class _Tables(final WorkspaceTable value)
    extends Fake
    implements OrganizeWorkspaceTablesUsecase {
  @override
  Future<WorkspaceTable> table(String id) async => value;
  @override
  Future<WorkspaceRecord> record(String tableId, String id) async =>
      WorkspaceRecord(
        id: id,
        tableId: tableId,
        values: {value.labelColumnId: 'Before'},
        revision: 1,
      );
}

class _Batch implements WorkspaceRecordBatchRepository {
  List<WorkspaceRecordChange>? applied;
  String? requestId;
  @override
  Future<void> apply(
    List<WorkspaceRecordChange> changes, {
    required String requestId,
  }) async {
    applied = changes;
    this.requestId = requestId;
  }
}
