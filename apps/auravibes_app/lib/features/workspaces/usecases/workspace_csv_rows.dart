import 'package:auravibes_app/features/workspaces/models/workspace_column_validation.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_csv_input.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table_constraints.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_csv_values.dart';
import 'package:uuid/uuid.dart';

class const WorkspaceCsvRows(
  final WorkspaceCsvRepository repository,
  final WorkspaceTable table,
) {
  Future<WorkspaceCsvPreview> call(
    WorkspaceCsvInput input,
    Map<int, String> mapping,
  ) async {
    final result = _ImportRows(table, .new(repository));
    for (var index = 0; index < input.rows.length; index++) {
      await result.add(input.rows[index], mapping, index + _firstDataRow);
    }

    return result.preview();
  }
}

class _ImportRows(
  final WorkspaceTable table,
  final WorkspaceCsvValues decoder,
) {
  final rows = <Map<String, Object?>>[];
  final errors = <WorkspaceCsvError>[];
  Future<void> add(
    List<String> cells,
    Map<int, String> mapping,
    int index,
  ) async {
    final row = _Row(table, decoder, index);
    await row.read(cells, mapping);
    rows.add(row.values);
    errors.addAll(row.errors);
  }

  WorkspaceCsvPreview preview() => WorkspaceCsvPreview(
    table: table,
    values: .unmodifiable(rows),
    errors: .unmodifiable(errors),
    requestId: const Uuid().v4(),
  );
}

class _Row(
  final WorkspaceTable table,
  final WorkspaceCsvValues decoder,
  final int index,
) {
  final errors = <WorkspaceCsvError>[];
  final _values = <String, Object?>{};
  Map<String, Object?> get values =>
      WorkspaceTableConstraints.defaults(table.columns, _values);

  Future<void> read(List<String> cells, Map<int, String> mapping) async {
    for (final entry in mapping.entries) {
      if (cells[entry.key].isEmpty) continue;
      await _decode(entry.value, cells[entry.key]);
    }
    if (!WorkspaceColumnValidation.accepts(table.columns, values)) {
      errors.add(_error(null));
    }
  }

  Future<void> _decode(String id, String cell) async {
    final column = table.columns.firstWhere((column) => column.id == id);
    try {
      _values[id] = await decoder.decode(column, cell);
    } on FormatException {
      errors.add(_error(id));
    }
  }

  WorkspaceCsvError _error(String? id) => WorkspaceCsvError(
    row: index,
    localizationKey: 'workspace_csv.invalid_value',
    columnId: id,
  );
}

const _firstDataRow = 2;
