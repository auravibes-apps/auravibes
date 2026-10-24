import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/data/repositories/workspace_view_mapper.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_folders_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_views_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

/// Executes selected content through the same validated boundaries as editors.
class const WorkspaceConversationCommandUsecase({
  required final OrganizeWorkspaceTablesUsecase tables,
  final OrganizeWorkspaceFoldersUsecase? folders,
  final ManageWorkspaceViewsUsecase? views,
}) {
  Future<Map<String, Object?>> call({
    required WorkspaceContextSelection selection,
    required Map<String, dynamic> arguments,
  }) async {
    final action = arguments['action'];
    if (selection.kind == 'folder' &&
        action != 'createFolder' &&
        action != 'createTable')
      return _folder(selection, arguments);
    if (selection.kind == 'view') return _view(selection, arguments);
    if (action == 'createTable' || action == 'createFolder') {
      return _createItem(selection, arguments);
    }
    final tableId = arguments['tableId'];
    if (selection.kind != 'table' || tableId != selection.itemId) {
      throw const WorkspaceTableException(denied: true);
    }
    final table = await tables.table(selection.itemId);
    return switch (arguments['action']) {
      'read' => _read(table, selection),
      'updateRecord' => _update(table, selection, arguments),
      'createRecord' => _createRecord(table, arguments),
      'renameTable' => _renameTable(table, arguments),
      'saveColumn' => _saveColumn(table, arguments),
      'createView' => _createView(table, arguments),
      _ => throw const WorkspaceTableException(),
    };
  }

  Future<Map<String, Object?>> _folder(
    WorkspaceContextSelection selection,
    Map<String, dynamic> arguments,
  ) async {
    final usecase = folders;
    if (usecase == null) throw const WorkspaceTableException();
    final candidates = await usecase.list(parentId: selection.parentId);
    final folder = candidates
        .where((candidate) => candidate.id == selection.itemId)
        .firstOrNull;
    if (folder == null || arguments['id'] != folder.id)
      throw const WorkspaceTableException(denied: true);
    if (arguments['action'] == 'read')
      return {
        'id': folder.id,
        'name': folder.name,
        'revision': folder.revision,
      };
    if (arguments['action'] != 'renameFolder')
      throw const WorkspaceTableException();
    if (arguments['revision'] != folder.revision)
      throw const WorkspaceTableException(conflict: true);
    final updated = await usecase.updateMetadata(
      folder: folder,
      name: _string(arguments, 'name'),
      parentId: folder.parentId,
    );
    return {'id': updated.id, 'kind': 'folder', 'revision': updated.revision};
  }

  Future<Map<String, Object?>> _view(
    WorkspaceContextSelection selection,
    Map<String, dynamic> arguments,
  ) async {
    final usecase = views;
    if (usecase == null || arguments['id'] != selection.itemId)
      throw const WorkspaceTableException(denied: true);
    final data = await usecase.open(selection.itemId);
    if (arguments['action'] == 'read')
      return WorkspaceViewMapper.toJson(data.view);
    if (arguments['action'] != 'saveView')
      throw const WorkspaceTableException();
    if (arguments['revision'] != data.view.revision ||
        arguments['schemaRevision'] != data.table.schemaRevision) {
      throw const WorkspaceTableException(conflict: true);
    }
    final bindings = _map(arguments, 'bindings').cast<String, String>();
    final types = {
      for (final column in data.table.columns)
        if (bindings.values.contains(column.id)) column.id: column.type.name,
    };
    final saved = await usecase.save(
      data.view.edited(
        name: _string(arguments, 'name'),
        definition: A2uiSavedDefinition.fromJson(_map(arguments, 'definition')),
        bindings: bindings,
        columnTypes: types,
      ),
    );
    return {'id': saved.id, 'kind': 'view', 'revision': saved.revision};
  }

  Future<Map<String, Object?>> _createItem(
    WorkspaceContextSelection selection,
    Map<String, dynamic> arguments,
  ) async {
    if (selection.kind != 'directory' && selection.kind != 'folder') {
      throw const WorkspaceTableException(denied: true);
    }
    final parent = selection.kind == 'directory' ? null : selection.itemId;
    if (arguments['parentId'] != parent)
      throw const WorkspaceTableException(denied: true);
    final name = _string(arguments, 'name');
    if (arguments['action'] == 'createFolder') {
      final usecase = folders;
      if (usecase == null) throw const WorkspaceTableException();
      final folder = await usecase.create(name: name, parentId: parent);
      return {'id': folder.id, 'kind': 'folder', 'revision': folder.revision};
    }
    final table = await tables.create(
      name: name,
      labelName: _string(arguments, 'labelName'),
      parentId: parent,
    );
    return _tableResult(table);
  }

  Future<Map<String, Object?>> _createRecord(
    WorkspaceTable table,
    Map<String, dynamic> arguments,
  ) async {
    _currentTable(table, arguments);
    final record = await tables.createRecord(
      table: table,
      values: _map(arguments, 'values'),
    );
    return {'id': record.id, 'kind': 'record', 'revision': record.revision};
  }

  Future<Map<String, Object?>> _renameTable(
    WorkspaceTable table,
    Map<String, dynamic> arguments,
  ) async {
    _currentTable(table, arguments);
    return _tableResult(
      await tables.updateMetadata(
        table: table,
        name: _string(arguments, 'name'),
        parentId: table.parentId,
      ),
    );
  }

  Future<Map<String, Object?>> _saveColumn(
    WorkspaceTable table,
    Map<String, dynamic> arguments,
  ) async {
    _currentTable(table, arguments);
    final column = WorkspaceColumn.fromJson(_map(arguments, 'column'));
    return _tableResult(await tables.saveColumn(table: table, column: column));
  }

  Future<Map<String, Object?>> _createView(
    WorkspaceTable table,
    Map<String, dynamic> arguments,
  ) async {
    _currentTable(table, arguments);
    final usecase = views;
    final ids = arguments['columnIds'];
    if (usecase == null ||
        ids is! List<Object?> ||
        ids.any((id) => id is! String)) {
      throw const WorkspaceTableException();
    }
    final view = await usecase.create(
      name: _string(arguments, 'name'),
      table: table,
      columnIds: ids.cast<String>(),
      parentId: table.parentId,
    );
    return {'id': view.id, 'kind': 'view', 'revision': view.revision};
  }

  Future<Map<String, Object?>> _read(
    WorkspaceTable table,
    WorkspaceContextSelection selection,
  ) async => {
    'id': table.id,
    'name': table.name,
    'revision': table.revision,
    'schemaRevision': table.schemaRevision,
    'columns': [
      for (final column in table.columns)
        {...column.toJson()}..remove('targetTableId'),
    ],
    'records': [
      for (final id in selection.recordIds)
        _record(await tables.record(table.id, id)),
    ],
  };

  Future<Map<String, Object?>> _update(
    WorkspaceTable table,
    WorkspaceContextSelection selection,
    Map<String, dynamic> arguments,
  ) async {
    final id = arguments['id'];
    if (id is! String || !selection.recordIds.contains(id)) {
      throw const WorkspaceTableException(denied: true);
    }
    final current = await tables.record(table.id, id);
    if (arguments['revision'] != current.revision ||
        arguments['schemaRevision'] != table.schemaRevision) {
      throw const WorkspaceTableException(conflict: true);
    }
    final values = arguments['values'];
    if (values is! Map<String, Object?>) {
      throw const WorkspaceTableException();
    }
    final updated = await tables.updateRecord(
      table: table,
      record: current,
      values: values,
    );
    return {'id': updated.id, 'revision': updated.revision};
  }
}

Map<String, Object?> _record(WorkspaceRecord record) => {
  'id': record.id,
  'revision': record.revision,
  'values': {
    for (final entry in record.values.entries)
      if (!record.restrictedReferenceColumns.contains(entry.key))
        entry.key: entry.value,
  },
};

void _currentTable(WorkspaceTable table, Map<String, dynamic> arguments) {
  if (table.revision != arguments['revision'] ||
      table.schemaRevision != arguments['schemaRevision']) {
    throw const WorkspaceTableException(conflict: true);
  }
}

Map<String, Object?> _tableResult(WorkspaceTable table) => {
  'id': table.id,
  'kind': 'table',
  'revision': table.revision,
  'schemaRevision': table.schemaRevision,
};
String _string(Map<String, dynamic> arguments, String key) {
  final value = arguments[key];
  if (value is! String) throw const WorkspaceTableException();
  return value;
}

Map<String, Object?> _map(Map<String, dynamic> arguments, String key) {
  final value = arguments[key];
  if (value is! Map<String, Object?>) throw const WorkspaceTableException();
  return value;
}
