import 'dart:convert';

import 'package:auravibes_app/features/workspaces/models/workspace_record_query.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';

class const WorkspaceCsvInput({
  required final List<String> headers,
  required final List<List<String>> rows,
}) {
  // Reuse the existing cloud request ceiling for in-memory source files.
  static const maxSourceBytes = 524288;
}

class const WorkspaceCsvPreview({
  required final WorkspaceTable table,
  required final List<Map<String, Object?>> values,
  required final List<WorkspaceCsvError> errors,
  required final String requestId,
}) {
  // Existing atomic patch and resource payload protocol ceilings.
  static const maxOperations = 50;
  static const int _maximumResourceBytes = 64 * 1024;

  void validate() {
    if (errors.isNotEmpty ||
        values.isEmpty ||
        values.length > WorkspaceCsvPreview.maxOperations) {
      throw const WorkspaceTableException();
    }
    for (final row in values) {
      final data = jsonEncode({
        'tableId': table.id,
        'schemaRevision': table.schemaRevision,
        'values': row,
      });
      if (utf8.encode(data).length > _maximumResourceBytes) {
        throw const WorkspaceTableException();
      }
    }
  }
}

class const WorkspaceCsvError({
  required final int row,
  required final String localizationKey,
  final String? columnId,
});

abstract interface class WorkspaceCsvRepository {
  Future<WorkspaceTable> table(String id);
  Future<bool> readableDeletedReference(String tableId, String recordId);
  Future<WorkspaceRecordPage> query(String tableId, WorkspaceRecordQuery query);
  Future<void> write(WorkspaceCsvPreview preview, {required bool previewOnly});
}

class const WorkspaceCsvException(final String localizationKey)
    implements Exception;
