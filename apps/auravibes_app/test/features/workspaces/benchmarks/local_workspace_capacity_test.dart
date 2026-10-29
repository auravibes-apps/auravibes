import 'dart:convert';
import 'dart:io';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_record_query_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_record_change.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_record_query.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/query_workspace_records_usecase.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

const _rowCount = 1000;
const _columnCount = 100;
const _querySamples = 10;
const _bulkCount = 50;

void main() {
  test(
    'measure synthetic local table operations and current boundaries',
    () async {
      final database = AppDatabase(connection: NativeDatabase.memory());
      addTearDown(database.close);
      final _ = await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: const .new('capacity'),
              name: 'Synthetic capacity',
              type: .local,
            ),
          );
      final tables = OrganizeWorkspaceTablesUsecase(
        LocalWorkspaceTableRepository(database, 'capacity'),
      );
      var table = await tables.create(name: 'Synthetic', labelName: 'Title');
      final schemaTimer = Stopwatch()..start();
      for (var index = 1; index < _columnCount; index++) {
        table = await tables.saveColumn(
          table: table,
          column: .new(id: '', name: 'Column $index'),
        );
      }
      schemaTimer.stop();
      expect(table.columns, hasLength(_columnCount));
      expect(
        () => tables.saveColumn(
          table: table,
          column: const WorkspaceColumn(id: '', name: 'Too many'),
        ),
        throwsA(isA<WorkspaceTableException>()),
      );

      final insertTimer = Stopwatch()..start();
      for (var index = 0; index < _rowCount; index++) {
        final _ = await tables.createRecord(
          table: table,
          values: {
            table.labelColumnId: 'row-${index.toString().padLeft(4, '0')}',
          },
        );
      }
      insertTimer.stop();
      final query = QueryWorkspaceRecordsUsecase(
        LocalWorkspaceRecordQueryRepository(database, 'capacity'),
      );
      final queryTimes = <int>[];
      WorkspaceRecordPage? lastPage;
      for (var sample = 0; sample < _querySamples; sample++) {
        final timer = Stopwatch()..start();
        final page = await query(
          table.id,
          const WorkspaceRecordQuery(limit: 100),
        );
        timer.stop();
        queryTimes.add(timer.elapsedMicroseconds);
        expect(page.records, hasLength(100));
        expect(page.hasMore, isTrue);
        lastPage = page;
      }
      final page = lastPage ?? (throw StateError('No query samples'));
      final searched = await query(table.id, const .new(search: 'row-000'));
      expect(searched.records, hasLength(10));
      expect(
        () => query(table.id, const WorkspaceRecordQuery(limit: 101)),
        throwsA(isA<WorkspaceTableException>()),
      );
      final changes = [
        for (var index = 0; index < _bulkCount; index++)
          WorkspaceRecordChange(
            table: table,
            record: page.records[index],
            values: {table.labelColumnId: 'updated-$index'},
          ),
      ];
      final bulkTimer = Stopwatch()..start();
      await LocalWorkspaceRecordBatchRepository(
        database,
        'capacity',
      ).apply(changes, requestId: 'capacity-bulk');
      bulkTimer.stop();
      expect(
        (await tables.record(
          table.id,
          page.records.first.id,
        )).values[table.labelColumnId],
        'updated-0',
      );
      queryTimes.sort();
      debugPrint(
        jsonEncode({
          'workload': 'synthetic_local_workspace',
          'storage': 'sqlite-memory',
          'os': Platform.operatingSystem,
          'dart': Platform.version.split(' ').first,
          'columns': _columnCount,
          'records': _rowCount,
          'nonEmptyColumnsPerRecord': 1,
          'queryPageSize': 100,
          'querySamples': _querySamples,
          'bulkRecords': _bulkCount,
          'schemaUs': schemaTimer.elapsedMicroseconds,
          'insertUs': insertTimer.elapsedMicroseconds,
          'queryMedianUs':
              (queryTimes[queryTimes.length ~/ 2 - 1] +
                  queryTimes[queryTimes.length ~/ 2]) ~/
              2,
          'queryP95Us': queryTimes.last,
          'bulkUs': bulkTimer.elapsedMicroseconds,
        }),
      );
    },
    timeout: const Timeout(.new(minutes: 3)),
    skip: Platform.environment['AURAVIBES_WORKSPACE_CAPACITY'] == '1'
        ? false
        : 'Set AURAVIBES_WORKSPACE_CAPACITY=1 to run synthetic measurement',
  );
}
