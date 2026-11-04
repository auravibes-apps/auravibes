import 'dart:typed_data';

import 'package:auravibes_app/features/chats/services/chat_attachment_modality.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset_input.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_column_validation.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_record_change.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_record_query.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/usecases/query_workspace_records_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_view_validation.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps capacity failures to their own localized copy', () {
    expect(
      const WorkspaceTableException(limitKind: .columns).localizationKey,
      LocaleKeys.workspace_items_limit_columns,
    );
    expect(
      const WorkspaceTableException(limitKind: .queryPageSize).localizationKey,
      LocaleKeys.workspace_items_limit_query_page,
    );
    expect(
      const WorkspaceTableException(limitKind: .summaryColumns).localizationKey,
      LocaleKeys.workspace_items_limit_summary_columns,
    );
    expect(
      const WorkspaceTableException(limitKind: .recordBatch).localizationKey,
      LocaleKeys.workspace_items_limit_record_batch,
    );
    expect(
      const WorkspaceAssetException(.sizeLimitExceeded).localizationKey,
      LocaleKeys.workspace_assets_size_limit_exceeded,
    );
  });

  test('classifies a table column overflow', () {
    final columns = _columns(101);

    expect(
      () => WorkspaceColumnValidation.columns(columns, 'column-0'),
      throwsA(
        isA<WorkspaceTableException>().having(
          (error) => error.limitKind,
          'limitKind',
          WorkspaceTableLimit.columns,
        ),
      ),
    );
  });

  test('classifies an over-limit record query page', () {
    final usecase = QueryWorkspaceRecordsUsecase(_NeverQueryRepository());

    expect(
      () => usecase('table', const WorkspaceRecordQuery(limit: 101)),
      throwsA(
        isA<WorkspaceTableException>().having(
          (error) => error.limitKind,
          'limitKind',
          WorkspaceTableLimit.queryPageSize,
        ),
      ),
    );
  });

  test('classifies an over-limit saved view page', () {
    final table = _table();
    final view = WorkspaceView.create(
      name: 'Paged view',
      table: table,
      columnIds: const ['column-0'],
    ).withQuery(const WorkspaceRecordQuery(limit: 101));

    expect(
      () => WorkspaceViewValidation.check(view, table),
      throwsA(
        isA<WorkspaceTableException>().having(
          (error) => error.limitKind,
          'limitKind',
          WorkspaceTableLimit.queryPageSize,
        ),
      ),
    );
  });

  test('classifies an over-limit summary column selection', () {
    final table = _table(columnCount: 51);
    final view = WorkspaceView.create(
      name: 'Summary',
      table: table,
      columnIds: const ['column-0'],
    ).withSummaryColumns([for (var i = 0; i < 51; i++) 'column-$i']);

    expect(
      () => WorkspaceViewValidation.check(view, table),
      throwsA(
        isA<WorkspaceTableException>().having(
          (error) => error.limitKind,
          'limitKind',
          WorkspaceTableLimit.summaryColumns,
        ),
      ),
    );
  });

  test('classifies an over-limit record batch', () {
    final table = _table();
    final changes = [
      for (var i = 0; i < WorkspaceRecordChange.maxOperations + 1; i++)
        WorkspaceRecordChange(
          table: table,
          record: .new(
            id: 'record-$i',
            tableId: table.id,
            values: const {},
            revision: 1,
          ),
          values: const {},
        ),
    ];

    expect(
      () => WorkspaceRecordChange.validate(changes),
      throwsA(
        isA<WorkspaceTableException>().having(
          (error) => error.limitKind,
          'limitKind',
          WorkspaceTableLimit.recordBatch,
        ),
      ),
    );
  });

  test('classifies an oversized workspace asset', () {
    final bytes = Uint8List(ChatAttachmentModality.maxChatAttachmentBytes + 1);

    expect(
      () => WorkspaceAssetInput.validate('notes.txt', bytes),
      throwsA(
        isA<WorkspaceAssetException>().having(
          (error) => error.failure,
          'failure',
          WorkspaceAssetFailure.sizeLimitExceeded,
        ),
      ),
    );
  });
}

WorkspaceTable _table({int columnCount = 1}) {
  final columns = _columns(columnCount);

  return WorkspaceTable(
    id: 'table',
    name: 'Table',
    labelColumnId: 'column-0',
    columns: columns,
    revision: 1,
    schemaRevision: 1,
  );
}

List<WorkspaceColumn> _columns(int columnCount) => [
  for (var index = 0; index < columnCount; index++)
    WorkspaceColumn(id: 'column-$index', name: 'Column $index'),
];

class _NeverQueryRepository implements WorkspaceRecordQueryRepository {
  @override
  Future<WorkspaceRecordPage> query(
    String tableId,
    WorkspaceRecordQuery query,
  ) async => const WorkspaceRecordPage(records: [], hasMore: false);

  @override
  Future<Map<String, Object?>> summarize(
    String tableId,
    WorkspaceRecordQuery query,
    List<String> columnIds,
  ) async => const {};
}
