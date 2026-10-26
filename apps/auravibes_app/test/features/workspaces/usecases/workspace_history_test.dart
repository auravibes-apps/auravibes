import 'dart:io';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_csv_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_history_attribution.dart';
import 'package:auravibes_app/data/repositories/local_workspace_history_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_record_query_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_reference_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_trash_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_view_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_csv_input.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_history_blocked_exception.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_history_policy.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_record_change.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_trash_target.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_history_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_trash_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_views_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'history keeps stored values and restore creates a new revision',
    () async {
      final database = AppDatabase(connection: NativeDatabase.memory());
      addTearDown(database.close);
      final _ = await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: const .new('local'),
              name: 'Local',
              type: .local,
            ),
          );
      final tables = OrganizeWorkspaceTablesUsecase(
        LocalWorkspaceTableRepository(database, 'local'),
      );
      final history = LocalWorkspaceHistoryRepository(database, 'local');
      final table = await tables.create(name: 'Data', labelName: 'Name');
      final first = await tables.createRecord(
        table: table,
        values: {table.labelColumnId: 'First'},
      );
      final second = await tables.updateRecord(
        table: table,
        record: first,
        values: {table.labelColumnId: 'Second'},
      );
      final revisions = await history.history(
        .new(
          kind: .record,
          id: first.id,
          tableId: table.id,
          revision: second.revision,
        ),
      );
      expect(revisions.map((revision) => revision.target.revision), [2, 1]);
      expect(revisions.last.data['values'], {table.labelColumnId: 'First'});
      expect(revisions.last.data['historyAttachmentColumns'], isEmpty);
      await history.restore(
        .new(
          kind: .record,
          id: first.id,
          tableId: table.id,
          revision: second.revision,
        ),
        1,
      );
      final restored = await tables.record(table.id, first.id);
      expect(restored.revision, 3);
      expect(restored.values[table.labelColumnId], 'First');
    },
  );

  test(
    'reports reference attributed revisions and stay metadata-only',
    () async {
      final fixture = await _fixture();
      final table = await fixture.tables.create(
        name: 'Data',
        labelName: 'Name',
      );
      final first = await fixture.tables.createRecord(
        table: table,
        values: {table.labelColumnId: 'Private record text'},
      );
      final current = await fixture.tables.updateRecord(
        table: table,
        record: first,
        values: {table.labelColumnId: 'AI edited text'},
      );
      final target = WorkspaceTrashTarget(
        kind: .record,
        id: current.id,
        revision: current.revision,
        tableId: table.id,
      );
      final attribution = LocalWorkspaceHistoryAttribution(fixture.database);
      await attribution.aiRevision(
        workspaceId: 'local',
        kind: 'record',
        resourceId: current.id,
        revision: current.revision,
        conversationId: 'conversation-local-1',
      );

      final revisions = await fixture.history.history(target);
      expect(revisions.firstOrNull?.actorUserId, 'local_user');
      expect(revisions.firstOrNull?.aiInvolved, isTrue);
      expect(revisions.firstOrNull?.operation, 'updated');
      expect(revisions.firstOrNull?.conversationId, 'conversation-local-1');
      expect(revisions.lastOrNull?.aiInvolved, isFalse);
      await expectLater(
        fixture.history.submitReport(
          .new(
            kind: .record,
            id: first.id,
            revision: first.revision,
            tableId: table.id,
          ),
        ),
        throwsA(isA<WorkspaceTableException>()),
      );

      final dismissedId = await fixture.history.submitReport(target);
      final submitted = (await fixture.history.reports()).single;
      expect(submitted.reportId, dismissedId);
      expect(submitted.status, 'submitted');
      expect(submitted.target.id, target.id);
      expect(submitted.target.revision, target.revision);
      expect(submitted.conversationId, 'conversation-local-1');
      final stored = await fixture.database
          .select(fixture.database.workspaceContentReports)
          .getSingle();
      expect(stored.toJson().keys, isNot(contains('data')));
      expect(stored.toJson().keys, isNot(contains('values')));

      final dismissed = await fixture.history.resolveReport(
        dismissedId,
        .dismiss,
      );
      expect(dismissed.status, 'dismissed');
      expect(dismissed.reviewerUserId, 'local_user');
      expect(dismissed.reviewedAt, isNotNull);

      final removedId = await fixture.history.submitReport(target);
      final removed = await fixture.history.resolveReport(removedId, .remove);
      expect(removed.status, 'removed');
      expect(
        (await LocalWorkspaceTrashRepository(
          fixture.database,
          'local',
        ).list()).single.target.id,
        current.id,
      );

      await fixture.database.customStatement(
        'DELETE FROM workspaces WHERE id = ?',
        ['local'],
      );
      expect(
        await fixture.database
            .select(fixture.database.workspaceContentReports)
            .get(),
        isEmpty,
      );
    },
  );

  test(
    'history persists across reopen and CSV preview leaves no revisions',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'workspace-history-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/workspace.sqlite');
      var database = AppDatabase(connection: NativeDatabase(file));
      final _ = await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: const .new('local'),
              name: 'Local',
              type: .local,
            ),
          );
      final tables = OrganizeWorkspaceTablesUsecase(
        LocalWorkspaceTableRepository(database, 'local'),
      );
      final table = await tables.create(name: 'Data', labelName: 'Name');
      final record = await tables.createRecord(
        table: table,
        values: {table.labelColumnId: 'Persistent'},
      );
      final csv = LocalWorkspaceCsvRepository(database, 'local');
      final preview = WorkspaceCsvPreview(
        table: table,
        values: [
          {table.labelColumnId: 'Preview'},
        ],
        errors: const [],
        requestId: 'preview',
      );
      final beforePreview = await database
          .select(database.workspaceRevisions)
          .get();
      await csv.write(preview, previewOnly: true);
      final afterPreview = await database
          .select(database.workspaceRevisions)
          .get();
      expect(
        afterPreview.map(
          (row) => (id: row.resourceId, revision: row.revision, data: row.data),
        ),
        beforePreview.map(
          (row) => (id: row.resourceId, revision: row.revision, data: row.data),
        ),
      );
      expect((await tables.records(table.id)).map((row) => row.id), [
        record.id,
      ]);
      await csv.write(preview, previewOnly: false);
      final imported = (await tables.records(table.id))
          .singleWhere((row) => row.id != record.id);
      final importedHistory =
          await LocalWorkspaceHistoryRepository(database, 'local').history(
            .new(
              kind: .record,
              id: imported.id,
              tableId: table.id,
              revision: 1,
            ),
          );
      expect(importedHistory.single.data['values'], {
        table.labelColumnId: 'Preview',
      });
      await database.close();
      database = AppDatabase(connection: NativeDatabase(file));
      addTearDown(database.close);
      final history = LocalWorkspaceHistoryRepository(database, 'local');
      final rows = await history.history(
        .new(kind: .record, id: record.id, tableId: table.id, revision: 1),
      );
      expect(rows.single.data['values'], {table.labelColumnId: 'Persistent'});
      final _ = await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: const .new('other'),
              name: 'Other',
              type: .local,
            ),
          );
      await expectLater(
        LocalWorkspaceHistoryRepository(database, 'other').history(
          .new(kind: .record, id: record.id, tableId: table.id, revision: 1),
        ),
        throwsA(isA<WorkspaceTableException>()),
      );
    },
  );

  test(
    'default asks; allow-all skips approval without skipping constraints',
    () async {
      final fixture = await _fixture();
      final table = await fixture.tables.create(
        name: 'Data',
        labelName: 'Name',
      );
      final first = await fixture.tables.createRecord(
        table: table,
        values: {table.labelColumnId: 'A'},
      );
      final second = await fixture.tables.updateRecord(
        table: table,
        record: first,
        values: {table.labelColumnId: 'B'},
      );
      final target = WorkspaceTrashTarget(
        kind: .record,
        id: first.id,
        revision: second.revision,
        tableId: table.id,
      );
      final usecase = ManageWorkspaceHistoryUsecase(fixture.history);
      var asks = 0;
      expect(
        await usecase.restore(
          target,
          1,
          approve: () async {
            asks++;

            return false;
          },
        ),
        isFalse,
      );
      expect(asks, 1);
      expect((await fixture.tables.record(table.id, first.id)).revision, 2);
      expect(
        await usecase.restore(
          target,
          1,
          mode: .allowAll,
          approve: () async => throw StateError('must not ask'),
        ),
        isTrue,
      );
      await expectLater(
        usecase.restore(
          target,
          1,
          mode: .allowAll,
          approve: () async => throw StateError('must not ask'),
        ),
        throwsA(isA<WorkspaceTableException>()),
      );
    },
  );

  test(
    'bulk snapshots retain original values and rolled back batches add none',
    () async {
      final fixture = await _fixture();
      final tables = fixture.tables;
      var table = await tables.create(name: 'Unique', labelName: 'Name');
      table = await tables.saveColumn(
        table: table,
        column: .fromJson({...table.columns.single.toJson(), 'unique': true}),
      );
      final first = await tables.createRecord(
        table: table,
        values: {table.labelColumnId: 'A'},
      );
      final second = await tables.createRecord(
        table: table,
        values: {table.labelColumnId: 'B'},
      );
      final batch = LocalWorkspaceRecordBatchRepository(
        fixture.database,
        'local',
      );
      final swap = <WorkspaceRecordChange>[
        .new(table: table, record: first, values: {table.labelColumnId: 'B'}),
        .new(table: table, record: second, values: {table.labelColumnId: 'A'}),
      ];
      await batch.apply(swap, requestId: 'swap');
      final revisions = await fixture.history.history(
        .new(kind: .record, id: first.id, tableId: table.id, revision: 2),
      );
      expect(revisions.map((row) => row.data['values']), [
        {table.labelColumnId: 'B'},
        {table.labelColumnId: 'A'},
      ]);
      final current = await tables.record(table.id, first.id);
      final duplicate = <WorkspaceRecordChange>[
        .new(table: table, record: current, values: {table.labelColumnId: 'A'}),
      ];
      await expectLater(
        batch.apply(duplicate, requestId: 'duplicate'),
        throwsA(isA<WorkspaceTableException>()),
      );
      expect(
        (await fixture.history.history(
          .new(kind: .record, id: first.id, tableId: table.id, revision: 2),
        )).length,
        2,
      );
      await expectLater(
        fixture.history.restore(
          .new(kind: .record, id: first.id, tableId: table.id, revision: 2),
          1,
        ),
        throwsA(isA<WorkspaceTableException>()),
      );
      expect(
        (await tables.record(table.id, first.id)).values[table.labelColumnId],
        'B',
      );
      expect((await tables.record(table.id, second.id)).revision, 2);
    },
  );

  test(
    'schema restore creates new schema revision and stale record restore fails',
    () async {
      final fixture = await _fixture();
      var table = await fixture.tables.create(name: 'Data', labelName: 'Name');
      table = await fixture.tables.renameLabel(table: table, name: 'Renamed');
      await fixture.history.restore(
        .new(kind: .table, id: table.id, revision: table.revision),
        1,
      );
      final restored = await fixture.tables.table(table.id);
      expect(restored.columns.single.name, 'Name');
      expect(restored.revision, 3);
      expect(restored.schemaRevision, greaterThan(table.schemaRevision));
      final first = await fixture.tables.createRecord(
        table: restored,
        values: {restored.labelColumnId: 'A'},
      );
      final second = await fixture.tables.updateRecord(
        table: restored,
        record: first,
        values: {restored.labelColumnId: 'B'},
      );
      await expectLater(
        fixture.history.restore(
          .new(
            kind: .record,
            id: first.id,
            tableId: table.id,
            revision: first.revision,
          ),
          1,
        ),
        throwsA(isA<WorkspaceTableException>()),
      );
      expect(
        (await fixture.tables.record(table.id, first.id)).revision,
        second.revision,
      );
    },
  );

  test('permanent deletion protects external history', () async {
    final fixture = await _fixture();
    final targetTable = await fixture.tables.create(
      name: 'Targets',
      labelName: 'Name',
    );
    final target = await fixture.tables.createRecord(
      table: targetTable,
      values: {targetTable.labelColumnId: 'Target'},
    );
    var sourceTable = await fixture.tables.create(
      name: 'Sources',
      labelName: 'Name',
    );
    sourceTable = await fixture.tables.saveColumn(
      table: sourceTable,
      column: .new(
        id: '',
        name: 'Link',
        type: .reference,
        targetTableId: targetTable.id,
      ),
    );
    final source = await fixture.tables.createRecord(
      table: sourceTable,
      values: {sourceTable.columns.last.id: target.id},
    );
    final _ = await fixture.tables.updateRecord(
      table: sourceTable,
      record: source,
      values: {sourceTable.labelColumnId: 'Cleared'},
    );
    final trash = ManageWorkspaceTrashUsecase(
      LocalWorkspaceTrashRepository(fixture.database, 'local'),
    );
    final batch = await trash.apply(
      .new(
        kind: .record,
        id: target.id,
        tableId: targetTable.id,
        revision: target.revision,
      ),
      approve: (_) async => true,
    );
    if (batch == null) fail('Expected Trash batch');
    await expectLater(
      fixture.history.permanentlyDelete(batch.target),
      throwsA(isA<WorkspaceHistoryBlockedException>()),
    );
    expect((await trash.list()).length, 1);
    final unreferenced = await fixture.tables.createRecord(
      table: targetTable,
      values: {targetTable.labelColumnId: 'Independent'},
    );
    final own = await trash.apply(
      .new(
        kind: .record,
        id: unreferenced.id,
        tableId: targetTable.id,
        revision: unreferenced.revision,
      ),
      approve: (_) async => true,
    );
    if (own == null) fail('Expected Trash batch');
    await fixture.history.permanentlyDelete(own.target);
    expect((await trash.list()).map((batch) => batch.target.id), [target.id]);
  });
  test(
    'restore rejects newly required values without rewriting current content',
    () async {
      final fixture = await _fixture();
      var table = await fixture.tables.create(name: 'Data', labelName: 'Name');
      table = await fixture.tables.saveColumn(
        table: table,
        column: const .new(id: '', name: 'Extra'),
      );
      final extra = table.columns.last;
      final original = await fixture.tables.createRecord(
        table: table,
        values: {table.labelColumnId: 'Original'},
      );
      final current = await fixture.tables.updateRecord(
        table: table,
        record: original,
        values: {table.labelColumnId: 'Current', extra.id: 'Required now'},
      );
      table = await fixture.tables.saveColumn(
        table: table,
        column: .fromJson({...extra.toJson(), 'required': true}),
      );
      await expectLater(
        fixture.history.restore(
          .new(
            kind: .record,
            id: original.id,
            tableId: table.id,
            revision: current.revision,
          ),
          1,
        ),
        throwsA(isA<WorkspaceTableException>()),
      );
      expect((await fixture.tables.record(table.id, original.id)).values, {
        table.labelColumnId: 'Current',
        extra.id: 'Required now',
      });
      expect(
        (await fixture.history.history(
          .new(
            kind: .record,
            id: original.id,
            tableId: table.id,
            revision: current.revision,
          ),
        )).length,
        2,
      );
    },
  );

  test('purged Views reject replay and identity reuse', () async {
    final fixture = await _fixture();
    final views = ManageWorkspaceViewsUsecase(
      LocalWorkspaceViewRepository(fixture.database, 'local'),
      fixture.tables,
      .new(LocalWorkspaceRecordQueryRepository(fixture.database, 'local')),
      .new(LocalWorkspaceReferenceRepository(fixture.database, 'local')),
    );
    final table = await fixture.tables.create(name: 'Data', labelName: 'Name');
    final original = await views.create(
      name: 'Overview',
      table: table,
      columnIds: [table.labelColumnId],
    );
    final saved = await views.save(original, requestId: 'view-save');
    final trash = ManageWorkspaceTrashUsecase(
      LocalWorkspaceTrashRepository(fixture.database, 'local'),
    );
    final batch = await trash.apply(
      .new(kind: .view, id: saved.id, revision: saved.revision),
      approve: (_) async => true,
    );
    if (batch == null) fail('Expected Trash batch');
    await fixture.history.permanentlyDelete(batch.target);
    expect(await views.list(allFolders: true), isEmpty);
    await expectLater(
      views.save(original, requestId: 'view-save'),
      throwsA(isA<WorkspaceTableException>()),
    );
    await expectLater(
      views.save(original.withRevision(0), requestId: 'view-recreate'),
      throwsA(isA<WorkspaceTableException>()),
    );
    expect(await trash.list(), isEmpty);
  });

  test('retention expiry preserves data and replay guards', () async {
    final fixture = await _fixture();
    final targetTable = await fixture.tables.create(
      name: 'Targets',
      labelName: 'Name',
    );
    final target = await fixture.tables.createRecord(
      table: targetTable,
      values: {targetTable.labelColumnId: 'Target'},
    );
    var sourceTable = await fixture.tables.create(
      name: 'Sources',
      labelName: 'Name',
    );
    sourceTable = await fixture.tables.saveColumn(
      table: sourceTable,
      column: .new(
        id: '',
        name: 'Link',
        type: .reference,
        targetTableId: targetTable.id,
      ),
    );
    final source = await fixture.tables.createRecord(
      table: sourceTable,
      values: {sourceTable.columns.last.id: target.id},
    );
    final current = await fixture.tables.updateRecord(
      table: sourceTable,
      record: source,
      values: {sourceTable.labelColumnId: 'Cleared'},
    );
    final trash = ManageWorkspaceTrashUsecase(
      LocalWorkspaceTrashRepository(fixture.database, 'local'),
    );
    final batch = await trash.apply(
      .new(
        kind: .record,
        id: target.id,
        tableId: targetTable.id,
        revision: target.revision,
      ),
      approve: (_) async => true,
    );
    if (batch == null) fail('Expected Trash batch');
    final old = DateTime.now().toUtc().subtract(const Duration(days: 3));
    final _ = await fixture.database
        .update(fixture.database.workspaceRevisions)
        .write(WorkspaceRevisionsCompanion(capturedAt: .new(old)));
    final targetHistory = WorkspaceTrashTarget(
      kind: .record,
      id: source.id,
      revision: current.revision,
      tableId: sourceTable.id,
    );
    final usecase = ManageWorkspaceHistoryUsecase(fixture.history);
    final unset = await usecase.policy();
    expect(unset.days, isNull);
    expect((await usecase.history(targetHistory)).length, 2);
    await expectLater(
      fixture.history.permanentlyDelete(batch.target),
      throwsA(isA<WorkspaceHistoryBlockedException>()),
    );
    expect(
      await usecase.configurePolicy(unset, 1, approve: () async => false),
      isFalse,
    );
    expect((await usecase.history(targetHistory)).length, 2);
    expect(
      await usecase.configurePolicy(unset, 1, approve: () async => true),
      isTrue,
    );
    expect((await usecase.policy()).days, 1);
    expect(await usecase.history(targetHistory), isEmpty);
    expect(
      (await fixture.tables.record(
        sourceTable.id,
        source.id,
      )).values[sourceTable.labelColumnId],
      'Cleared',
    );
    await expectLater(
      usecase.configurePolicy(
        unset,
        2,
        mode: .allowAll,
        approve: () async => throw StateError('must not ask'),
      ),
      throwsA(isA<WorkspaceTableException>()),
    );
    await fixture.history.permanentlyDelete(batch.target);
    expect(await trash.list(), isEmpty);
    final policy = await usecase.policy();
    expect(
      await usecase.configurePolicy(
        policy,
        null,
        mode: .allowAll,
        approve: () async => throw StateError('must not ask'),
      ),
      isTrue,
    );
    expect((await usecase.policy()).days, isNull);
    expect(
      () => WorkspaceHistoryPolicy.parse('9007199254740992'),
      throwsA(isA<WorkspaceHistoryPolicyException>()),
    );
    expect(
      () => WorkspaceHistoryPolicy.parse('0'),
      throwsA(isA<WorkspaceHistoryPolicyException>()),
    );
  });
}

Future<
  ({
    AppDatabase database,
    OrganizeWorkspaceTablesUsecase tables,
    LocalWorkspaceHistoryRepository history,
  })
>
_fixture() async {
  final database = AppDatabase(connection: NativeDatabase.memory());
  addTearDown(database.close);
  final _ = await database
      .into(database.workspaces)
      .insert(
        WorkspacesCompanion.insert(
          id: const .new('local'),
          name: 'Local',
          type: .local,
        ),
      );

  return (
    database: database,
    tables: OrganizeWorkspaceTablesUsecase(
      LocalWorkspaceTableRepository(database, 'local'),
    ),
    history: LocalWorkspaceHistoryRepository(database, 'local'),
  );
}
