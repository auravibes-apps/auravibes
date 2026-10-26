import 'package:auravibes_app/data/database/drift/app_database.dart';

abstract final class WorkspaceRevisionCapture {
  /// Capture authoritative stored revisions in the writer's transaction.
  static Future<void> install(AppDatabase database) async {
    for (final kind in ['table', 'record']) {
      final table = kind == 'table'
          ? 'workspace_tables'
          : 'workspace_table_records';
      final payload = kind == 'table'
          ? '''
'name', ROW.name, 'parentId', ROW.parent_id,
'labelColumnId', ROW.label_column_id, 'columns', json(ROW.columns_json),
'schemaRevision', ROW.schema_revision
'''
          : r'''
 'tableId', ROW.table_id, 'values', json(ROW.values_json),
 'historyAttachmentColumns', json((SELECT json_group_array(json_extract(value, '$.id'))
 FROM json_each((SELECT columns_json FROM workspace_tables
 WHERE workspace_id = ROW.workspace_id AND id = ROW.table_id))
 WHERE json_extract(value, '$.type') = 'attachment'))
''';
      for (final event in ['INSERT', 'UPDATE']) {
        await database.customStatement('''
DROP TRIGGER IF EXISTS
workspace_${kind}_revision_${event.toLowerCase()}''');
        final old = event == 'UPDATE'
            ? _capture(kind, payload, 'OLD', 'unknown')
            : '';
        await database.customStatement('''
CREATE TRIGGER IF NOT EXISTS workspace_${kind}_revision_${event.toLowerCase()}
AFTER $event ON $table
BEGIN
$old
${_capture(kind, payload, 'NEW', event == 'INSERT' ? 'created' : 'updated')}
DELETE FROM workspace_revisions WHERE workspace_id = NEW.workspace_id
AND revision > 0
AND (CAST(strftime('%s', 'now') AS INTEGER) - captured_at) / 86400 >=
(SELECT days FROM workspace_history_policies WHERE workspace_id = NEW.workspace_id);
DELETE FROM workspace_content_reports WHERE workspace_id = NEW.workspace_id
AND NOT EXISTS (
SELECT 1 FROM workspace_revisions AS retained
WHERE retained.workspace_id = workspace_content_reports.workspace_id
AND retained.kind = workspace_content_reports.kind
AND retained.resource_id = workspace_content_reports.resource_id
AND retained.revision = workspace_content_reports.revision
);
END
''');
      }
    }
    await database.customStatement(
      'DROP TRIGGER IF EXISTS workspace_content_reports_workspace_delete',
    );
    await database.customStatement('''
CREATE TRIGGER IF NOT EXISTS workspace_content_reports_workspace_delete
AFTER DELETE ON workspaces
BEGIN
DELETE FROM workspace_content_reports WHERE workspace_id = OLD.id;
END
''');
  }

  static String _capture(
    String kind,
    String payload,
    String row,
    String operation,
  ) =>
      '''
INSERT OR IGNORE INTO workspace_revisions
(workspace_id, kind, resource_id, revision, data, actor_user_id, ai_involved, operation)
VALUES ($row.workspace_id, '$kind', $row.id, $row.revision,
json_object('id', $row.id, 'revision', $row.revision, ${payload.replaceAll('ROW.', '$row.')}),
'local_user', 0, '$operation');
''';
}
