import 'dart:io';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_history_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_item_duplication_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_trash_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_view_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_item_duplication.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_record_query.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/usecases/duplicate_workspace_item_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_trash_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'permanent purge blocks duplicate Table and View replay and identity reuse',
    () async {
      final database = AppDatabase(connection: NativeDatabase.memory());
      addTearDown(database.close);
      final _ = await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: const .new('purge-copy'),
              name: 'Copies',
              type: .local,
            ),
          );
      final tables = LocalWorkspaceTableRepository(database, 'purge-copy');
      final source = await tables.create(name: 'Source', labelName: 'Title');
      final views = LocalWorkspaceViewRepository(database, 'purge-copy');
      final view = await views.save(
        .create(
          name: 'Source View',
          table: source,
          columnIds: [source.labelColumnId],
        ),
        requestId: 'source-view',
      );
      final copies = LocalWorkspaceItemDuplicationRepository(
        database,
        'purge-copy',
      );
      final trash = ManageWorkspaceTrashUsecase(
        LocalWorkspaceTrashRepository(database, 'purge-copy'),
      );
      final history = LocalWorkspaceHistoryRepository(database, 'purge-copy');
      for (final kind in WorkspaceDuplicateKind.values) {
        final request = WorkspaceItemDuplication(
          kind: kind,
          sourceId: kind == .table ? source.id : view.id,
          expectedRevision: kind == .table ? source.revision : view.revision,
          targetId: 'purged-${kind.name}',
          requestId: 'copy-${kind.name}',
          name: 'Copy',
        );
        await copies.copy(request);
        final batch = await trash.apply(
          .new(
            kind: kind == .table ? .table : .view,
            id: request.targetId,
            revision: 1,
          ),
          approve: (_) async => true,
        );
        if (batch == null) fail('Expected Trash batch');
        await history.permanentlyDelete(batch.target);
        await expectLater(
          copies.copy(request),
          throwsA(isA<WorkspaceTableException>()),
        );
        await expectLater(
          copies.copy(
            .new(
              kind: kind,
              sourceId: request.sourceId,
              expectedRevision: request.expectedRevision,
              targetId: request.targetId,
              requestId: 'new-${kind.name}',
              name: 'Copy',
            ),
          ),
          throwsA(isA<WorkspaceTableException>()),
        );
      }
    },
  );
  test(
    'table duplication copies schema, not records, unless explicitly chosen',
    () async {
      final database = AppDatabase(connection: NativeDatabase.memory());
      addTearDown(database.close);
      final _ = await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: const .new('copy'),
              name: 'Copy',
              type: .local,
            ),
          );
      final repository = LocalWorkspaceTableRepository(database, 'copy');
      final tables = OrganizeWorkspaceTablesUsecase(repository);
      final source = await tables.create(name: 'Source', labelName: 'Title');
      final record = await tables.createRecord(
        table: source,
        values: {source.labelColumnId: 'Original'},
      );
      final empty = await repository.duplicate(
        .new(
          kind: .table,
          sourceId: source.id,
          expectedRevision: source.revision,
          targetId: 'copy-empty',
          requestId: 'empty',
          name: 'Empty',
        ),
      );
      expect(empty.id, isNot(source.id));
      expect(empty.labelColumnId, isNot(source.labelColumnId));
      expect(empty.columns.single.name, 'Title');
      expect(await tables.records(empty.id), isEmpty);
      final full = await repository.duplicate(
        .new(
          kind: .table,
          sourceId: source.id,
          expectedRevision: source.revision,
          targetId: 'copy-full',
          requestId: 'full',
          name: 'Full',
          copyRecords: true,
        ),
      );
      final copied = await tables.records(full.id);
      expect(copied.single.id, isNot(record.id));
      expect(copied.single.values, {full.labelColumnId: 'Original'});
      final _ = await repository.duplicate(
        .new(
          kind: .table,
          sourceId: source.id,
          expectedRevision: source.revision,
          targetId: 'copy-full',
          requestId: 'full',
          name: 'Full',
          copyRecords: true,
        ),
      );
      expect(await tables.records(full.id), hasLength(1));
    },
  );
  test(
    'configured View copy retains bindings and replays after source edits',
    () async {
      final database = AppDatabase(connection: NativeDatabase.memory());
      addTearDown(database.close);
      final _ = await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: const .new('views'),
              name: 'Views',
              type: .local,
            ),
          );
      final tables = LocalWorkspaceTableRepository(database, 'views');
      final table = await tables.create(name: 'Items', labelName: 'Title');
      final views = LocalWorkspaceViewRepository(database, 'views');
      final source = await views.save(
        WorkspaceView.create(
              name: 'Configured',
              table: table,
              columnIds: [table.labelColumnId],
            )
            .withQuery(const WorkspaceRecordQuery(search: 'needle', limit: 12))
            .withSummaryColumns([table.labelColumnId]),
        requestId: 'source',
      );
      final usecase = DuplicateWorkspaceItemUsecase(
        LocalWorkspaceItemDuplicationRepository(database, 'views'),
      );
      final request = WorkspaceItemDuplication(
        kind: .view,
        sourceId: source.id,
        expectedRevision: source.revision,
        targetId: 'view-copy',
        requestId: 'copy',
        name: 'Copy',
      );
      expect(await usecase(request, approve: () async => false), isFalse);
      expect(await views.list(), hasLength(1));
      final _ = await usecase(request, approve: () async => true);
      final copied = await views.read('view-copy');
      expect(copied.tableId, source.tableId);
      expect(copied.bindings, source.bindings);
      expect(copied.columnTypes, source.columnTypes);
      expect(copied.summaryColumnIds, [table.labelColumnId]);
      expect(copied.query.search, 'needle');
      expect(copied.query.limit, 12);
      expect(copied.definition.toJson(), source.definition.toJson());
      final changed = source.edited(
        name: 'Changed',
        definition: source.definition,
        bindings: source.bindings,
        columnTypes: source.columnTypes,
      );
      final _ = await views.save(changed, requestId: 'edit');
      final _ = await usecase(request, approve: () async => true);
      expect((await views.read('view-copy')).name, 'Copy');
      await expectLater(
        usecase(
          .new(
            kind: .view,
            sourceId: source.id,
            expectedRevision: source.revision,
            targetId: 'stale-copy',
            requestId: 'stale',
            name: 'Stale',
          ),
          approve: () async => true,
        ),
        throwsA(
          isA<WorkspaceTableException>().having(
            (error) => error.conflict,
            'conflict',
            true,
          ),
        ),
      );
      expect(await views.list(), hasLength(2));
    },
  );
  test(
    'copies retain targets and rollback unavailable links across reopen',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'workspace-duplicate-',
      );
      final file = File('${directory.path}/workspace.sqlite');
      var database = AppDatabase(connection: NativeDatabase(file));
      addTearDown(() async {
        await database.close();
        final _ = await directory.delete(recursive: true);
      });
      final _ = await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: const .new('persistent'),
              name: 'Persistent',
              type: .local,
            ),
          );
      var tables = LocalWorkspaceTableRepository(database, 'persistent');
      var source = await tables.create(
        name: 'Self references',
        labelName: 'Title',
      );
      var original = await tables.createRecord(
        table: source,
        values: {source.labelColumnId: 'Original'},
      );
      source = await tables.saveColumn(
        table: source,
        column: .new(
          id: 'related',
          name: 'Related',
          type: .reference,
          targetTableId: source.id,
        ),
      );
      original = await tables.updateRecord(
        table: source,
        record: original,
        values: {source.labelColumnId: 'Original', 'related': original.id},
      );
      WorkspaceItemDuplication request(String target) => .new(
        kind: .table,
        sourceId: source.id,
        expectedRevision: source.revision,
        targetId: target,
        requestId: target,
        name: target,
        copyRecords: true,
      );
      var copies = DuplicateWorkspaceItemUsecase(
        LocalWorkspaceItemDuplicationRepository(database, 'persistent'),
      );
      final _ = await copies(request('first-copy'), approve: () async => true);
      final first = await tables.table('first-copy');
      final copiedRecord = (await tables.records(first.id))
          .singleWhere((row) => row.values[first.labelColumnId] == 'Original');
      expect(first.columns.last.targetTableId, source.id);
      expect(copiedRecord.values[first.columns.last.id], original.id);
      expect(copiedRecord.id, isNot(original.id));
      final _ = await tables.createRecord(
        table: source,
        values: {source.labelColumnId: 'Referrer', 'related': original.id},
      );
      final trash = ManageWorkspaceTrashUsecase(
        LocalWorkspaceTrashRepository(database, 'persistent'),
      );
      final batch = await trash.apply(
        .new(
          kind: .record,
          id: original.id,
          revision: original.revision,
          tableId: source.id,
        ),
        approve: (_) async => true,
      );
      await expectLater(
        copies(
          request('retry-copy'),
          approve: () async => fail('Allow-all must skip approval'),
          mode: .allowAll,
        ),
        throwsA(isA<WorkspaceTableException>()),
      );
      expect(
        (await tables.list()).map((table) => table.id),
        isNot(contains('retry-copy')),
      );
      final _ = await trash.restore(
        batch?.id ?? (throw StateError('Expected a trash batch')),
      );
      final _ = await copies(request('retry-copy'), approve: () async => true);
      await database.close();
      database = AppDatabase(connection: NativeDatabase(file));
      tables = LocalWorkspaceTableRepository(database, 'persistent');
      copies = DuplicateWorkspaceItemUsecase(
        LocalWorkspaceItemDuplicationRepository(database, 'persistent'),
      );
      final _ = await copies(
        request('retry-copy'),
        approve: () async => fail('Allow-all must skip approval'),
        mode: .allowAll,
      );
      expect(await tables.records('retry-copy'), hasLength(2));
      expect(
        (await tables.table('retry-copy')).columns.last.targetTableId,
        source.id,
      );
    },
  );
  test(
    'record copies preserve missing values when defaults were added later',
    () async {
      final database = AppDatabase(connection: NativeDatabase.memory());
      addTearDown(database.close);
      final _ = await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: const .new('defaults'),
              name: 'Defaults',
              type: .local,
            ),
          );
      final tables = LocalWorkspaceTableRepository(database, 'defaults');
      var table = await tables.create(name: 'Source', labelName: 'Title');
      final original = await tables.createRecord(
        table: table,
        values: {table.labelColumnId: 'Missing amount'},
      );
      table = await tables.saveColumn(
        table: table,
        column: const .new(
          id: 'amount',
          name: 'Amount',
          type: .number,
          defaultValue: 42,
        ),
      );
      final copies = DuplicateWorkspaceItemUsecase(
        LocalWorkspaceItemDuplicationRepository(database, 'defaults'),
      );
      final _ = await copies(
        .new(
          kind: .table,
          sourceId: table.id,
          expectedRevision: table.revision,
          targetId: 'copy-defaults',
          requestId: 'copy-defaults',
          name: 'Copy',
          copyRecords: true,
        ),
        approve: () async => true,
      );
      final copy = await tables.table('copy-defaults');
      final record = (await tables.records(copy.id)).single;
      expect(
        (await tables.record(table.id, original.id)).values['amount'],
        isNull,
      );
      expect(copy.columns.last.defaultValue, 42);
      expect(record.values[copy.columns.last.id], isNull);
    },
  );
  test(
    'dependent schema copies remap own columns and retain external targets',
    () async {
      final database = AppDatabase(connection: NativeDatabase.memory());
      addTearDown(database.close);
      final _ = await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: const .new('relations'),
              name: 'Relations',
              type: .local,
            ),
          );
      final tables = LocalWorkspaceTableRepository(database, 'relations');
      final regions = await tables.create(name: 'Regions', labelName: 'Region');
      final region = await tables.createRecord(
        table: regions,
        values: {regions.labelColumnId: 'North'},
      );
      var contacts = await tables.create(name: 'Contacts', labelName: 'Name');
      contacts = await tables.saveColumn(
        table: contacts,
        column: .new(
          id: 'contact-region',
          name: 'Region',
          type: .reference,
          targetTableId: regions.id,
        ),
      );
      final contact = await tables.createRecord(
        table: contacts,
        values: {contacts.labelColumnId: 'One', 'contact-region': region.id},
      );
      var source = await tables.create(name: 'Related', labelName: 'Title');
      source = await tables.saveColumn(
        table: source,
        column: .new(
          id: 'parent',
          name: 'Region',
          type: .reference,
          targetTableId: regions.id,
        ),
      );
      source = await tables.saveColumn(
        table: source,
        column: .new(
          id: 'dependent',
          name: 'Contact',
          type: .reference,
          targetTableId: contacts.id,
          dependsOnColumnId: 'parent',
          targetMatchColumnId: 'contact-region',
        ),
      );
      final _ = await tables.createRecord(
        table: source,
        values: {
          source.labelColumnId: 'Selected',
          'parent': region.id,
          'dependent': contact.id,
        },
      );
      final copies = DuplicateWorkspaceItemUsecase(
        LocalWorkspaceItemDuplicationRepository(database, 'relations'),
      );
      final _ = await copies(
        .new(
          kind: .table,
          sourceId: source.id,
          expectedRevision: source.revision,
          targetId: 'related-copy',
          requestId: 'related-copy',
          name: 'Related copy',
          copyRecords: true,
        ),
        approve: () async => true,
      );
      final copy = await tables.table('related-copy');
      final parent = copy.columns.singleWhere(
        (column) => column.name == 'Region',
      );
      final dependent = copy.columns.singleWhere(
        (column) => column.name == 'Contact',
      );
      expect(parent.id, isNot('parent'));
      expect(parent.targetTableId, regions.id);
      expect(dependent.dependsOnColumnId, parent.id);
      expect(dependent.targetTableId, contacts.id);
      expect(dependent.targetMatchColumnId, 'contact-region');
      final values = (await tables.records(copy.id)).single.values;
      expect(values[parent.id], region.id);
      expect(values[dependent.id], contact.id);
    },
  );
}
