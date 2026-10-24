import 'package:auravibes_app/features/workspaces/models/workspace_csv_input.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/features/workspaces/services/workspace_csv_file_service.dart';
import 'package:auravibes_app/features/workspaces/usecases/export_workspace_csv_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_csv_codec.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_csv_rows.dart';

class const WorkspaceCsvUsecase(final WorkspaceCsvRepository _repository) {
  Future<WorkspaceCsvInput?> pick() async {
    final source = await const WorkspaceCsvFileService().pick();

    return source == null ? null : read(source);
  }

  Future<bool> exportFile(String tableId) async {
    final source = await ExportWorkspaceCsvUsecase(_repository)(tableId);

    return await const WorkspaceCsvFileService().save(source);
  }

  WorkspaceCsvInput read(String source) =>
      const WorkspaceCsvCodec().read(source);

  Future<WorkspaceCsvPreview> preview({
    required WorkspaceTable table,
    required WorkspaceCsvInput input,
    required Map<int, String> mapping,
  }) async {
    final current = await _repository.table(table.id);
    if (current.schemaRevision != table.schemaRevision) {
      throw const WorkspaceTableException(conflict: true);
    }
    _validateMapping(current, input, mapping);
    final preview = await WorkspaceCsvRows(_repository, current)(
      input,
      mapping,
    );
    if (preview.errors.isNotEmpty) return preview;

    return await _validate(preview);
  }

  Future<void> commit(WorkspaceCsvPreview preview) {
    preview.validate();

    return _repository.write(preview, previewOnly: false);
  }

  Future<WorkspaceCsvPreview> _validate(WorkspaceCsvPreview preview) async {
    try {
      await _repository.write(preview, previewOnly: true);
    } on WorkspaceTableException catch (error) {
      if (error.denied || error.conflict) rethrow;

      return _failed(preview);
    } on CloudAppException catch (error) {
      if (error.code != 'validationFailed') rethrow;

      return _failed(preview);
    }

    return preview;
  }
}

void _validateMapping(
  WorkspaceTable table,
  WorkspaceCsvInput input,
  Map<int, String> mapping,
) {
  if (!table.canEditRecords) throw const WorkspaceTableException(denied: true);
  if (!_validRows(input) || !_validMapping(table, input, mapping)) {
    throw const WorkspaceCsvException('workspace_csv.invalid_mapping');
  }
}

bool _validRows(WorkspaceCsvInput input) =>
    input.rows.isNotEmpty &&
    input.rows.length <= WorkspaceCsvPreview.maxOperations &&
    input.rows.every((row) => row.length == input.headers.length);

bool _validMapping(
  WorkspaceTable table,
  WorkspaceCsvInput input,
  Map<int, String> mapping,
) =>
    _uniqueMapping(mapping) &&
    mapping.entries.every((entry) => _mappedColumn(table, input, entry));

bool _uniqueMapping(Map<int, String> mapping) =>
    mapping.isNotEmpty && mapping.values.toSet().length == mapping.length;

bool _mappedColumn(
  WorkspaceTable table,
  WorkspaceCsvInput input,
  MapEntry<int, String> entry,
) =>
    entry.key >= 0 &&
    entry.key < input.headers.length &&
    table.columns.any((column) => column.id == entry.value);

WorkspaceCsvPreview _failed(WorkspaceCsvPreview preview) => WorkspaceCsvPreview(
  table: preview.table,
  values: preview.values,
  errors: const [
    WorkspaceCsvError(
      row: 0,
      localizationKey: 'workspace_csv.validation_failed',
    ),
  ],
  requestId: preview.requestId,
);
