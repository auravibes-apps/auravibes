import 'dart:convert';

import 'package:auravibes_app/data/repositories/workspace_view_mapper.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_folder.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table_constraints.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_assets_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_views_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_files_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_folders_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

typedef _CommandInput = ({
  WorkspaceContextSelection selection,
  Map<String, dynamic> arguments,
  WorkspaceReferenceScope references,
  String? conversationId,
});

/// Executes selected content through the same validated boundaries as editors.
class const WorkspaceConversationCommandUsecase({
  required final OrganizeWorkspaceTablesUsecase tables,
  final OrganizeWorkspaceFoldersUsecase? folders,
  final ManageWorkspaceViewsUsecase? views,
  final OrganizeWorkspaceFilesUsecase? files,
  final ManageWorkspaceAssetsUsecase? assets,
}) {
  Future<Map<String, Object?>> call({
    required WorkspaceContextSelection selection,
    required Map<String, dynamic> arguments,
    WorkspaceReferenceScope? references,
    String? conversationId,
  }) => _ItemCommand(this, (
    selection: selection,
    arguments: arguments,
    references: references ?? WorkspaceReferenceScope(selection, const []),
    conversationId: conversationId,
  )).call();

  Future<void> authorizeReceipt(Map<String, Object?> result) =>
      _ReceiptAuthorization(this, result).call();
}

class const _ItemCommand(
  final WorkspaceConversationCommandUsecase owner,
  final _CommandInput input,
) {
  bool get creating =>
      input.arguments['action'] == 'createFolder' ||
      input.arguments['action'] == 'createTable';

  Future<Map<String, Object?>> call() =>
      creating && input.selection.kind != 'view'
      ? _ItemCreation(owner, input).call()
      : _existing();

  Future<Map<String, Object?>> _existing() => switch (input.selection.kind) {
    'directory' => _directory(),
    'folder' => _FolderCommand(owner, input).call(),
    'file' => _FileCommand(owner, input).call(),
    'view' => _ViewCommand(owner, input).call(),
    _ => _TableCommand(owner, input).call(),
  };

  Future<Map<String, Object?>> _directory() async {
    _Arguments.action(input.arguments, 'read');
    if ((input.arguments['id'] ?? '') != '' ||
        (input.arguments['tableId'] ?? '') != '' ||
        input.arguments['parentId'] != null) {
      _Arguments.denied();
    }

    return {'kind': 'directory', 'id': '', 'parentId': null};
  }
}

class const _ReceiptAuthorization(
  final WorkspaceConversationCommandUsecase owner,
  final Map<String, Object?> result,
) {
  String get id {
    final id = result['id'];
    if (id is! String) _Arguments.denied();

    return id;
  }

  Future<void> call() => switch (result['kind']) {
    'record' => _record(),
    'table' => _table(),
    'folder' => _folder(),
    'view' => _view(),
    _ => _Arguments.denied(),
  };

  Future<void> _record() async {
    final table = await owner.tables.table(
      _Arguments.string(result, 'tableId'),
    );
    if (!table.canEditRecords) _Arguments.denied();
    final _ = await owner.tables.record(table.id, id);
  }

  Future<void> _table() async {
    final table = await owner.tables.table(id);
    if (!table.canManage) _Arguments.denied();
  }

  Future<void> _folder() async {
    final manager = owner.folders;
    if (manager == null) _Arguments.denied();
    final folders = await manager.list(parentId: result['parentId'] as String?);
    _requireFolder(folders);
  }

  void _requireFolder(List<WorkspaceFolder> folders) {
    final target = id;
    if (!folders.any((folder) => folder.id == target && folder.canManage)) {
      _Arguments.denied();
    }
  }

  Future<void> _view() async {
    final manager = owner.views;
    if (manager == null) _Arguments.denied();
    final data = await manager.open(id);
    if (!data.view.canManage) _Arguments.denied();
  }
}

class const _FileCommand(
  final WorkspaceConversationCommandUsecase owner,
  final _CommandInput input,
) {
  Future<Map<String, Object?>> call() async {
    _Arguments.action(input.arguments, 'read');
    if (input.arguments['id'] != input.selection.itemId) _Arguments.denied();
    final files =
        owner.files ?? (throw const WorkspaceTableException(denied: true));
    final assets =
        owner.assets ?? (throw const WorkspaceTableException(denied: true));
    final file = await files.file(input.selection.itemId);
    final asset = await assets.describe(file.assetId);
    if (asset.sizeBytes > 65536 ||
        !{'text/plain', 'application/json'}.contains(asset.mimeType)) {
      throw const WorkspaceTableException();
    }
    final preview = await assets.preview(file.assetId);
    if (preview.asset.id != asset.id ||
        preview.asset.sizeBytes > 65536 ||
        !{'text/plain', 'application/json'}.contains(preview.asset.mimeType)) {
      throw const WorkspaceTableException();
    }

    final current = await files.file(file.id);
    if (current.revision != file.revision || current.assetId != file.assetId) {
      throw const WorkspaceTableException(denied: true);
    }

    return workspaceFileToolResult(
      id: file.id,
      name: file.name,
      mimeType: preview.asset.mimeType,
      revision: file.revision,
      content: utf8.decode(preview.bytes),
    );
  }
}

class const _FolderCommand(
  final WorkspaceConversationCommandUsecase owner,
  final _CommandInput input,
) {
  OrganizeWorkspaceFoldersUsecase get manager =>
      owner.folders ?? (throw const WorkspaceTableException());

  Future<Map<String, Object?>> call() async {
    final folder = await _selected();
    if (input.arguments['action'] == 'read') {
      return _Snapshots.folderContent(folder);
    }

    return await _rename(folder);
  }

  Future<WorkspaceFolder> _selected() async {
    final folder = await _find();
    if (folder == null || input.arguments['id'] != folder.id) {
      _Arguments.denied();
    }

    return folder;
  }

  Future<WorkspaceFolder?> _find() async {
    final selection = input.selection;
    final folders = await manager.list(parentId: selection.parentId);

    return folders.where((value) => value.id == selection.itemId).firstOrNull;
  }

  Future<Map<String, Object?>> _rename(WorkspaceFolder folder) async {
    _Arguments.action(input.arguments, 'renameFolder');
    if (input.arguments['revision'] != folder.revision) _Arguments.conflict();
    final updated = await manager.updateMetadata(
      folder: folder,
      name: _Arguments.string(input.arguments, 'name'),
      parentId: folder.parentId,
    );

    return _Snapshots.folder(updated);
  }
}

class const _ViewCommand(
  final WorkspaceConversationCommandUsecase owner,
  final _CommandInput input,
) {
  ManageWorkspaceViewsUsecase get manager =>
      owner.views ?? (throw const WorkspaceTableException(denied: true));

  Future<Map<String, Object?>> call() async {
    final selected = input.selection.itemId;
    final arguments = input.arguments;
    if (arguments['id'] != selected) _Arguments.denied();
    final data = await manager.open(selected);
    if (arguments['action'] == 'read') {
      return WorkspaceViewMapper.toJson(data.view);
    }

    return await _ViewEdit(manager, data, arguments).save();
  }
}

class const _ViewEdit(
  final ManageWorkspaceViewsUsecase manager,
  final WorkspaceViewData data,
  final Map<String, dynamic> arguments,
) {
  Future<Map<String, Object?>> save() async {
    _current();
    final saved = await manager.save(_edited());

    return _Snapshots.view(saved);
  }

  void _current() {
    _Arguments.action(arguments, 'saveView');
    if (arguments['revision'] != data.view.revision ||
        arguments['schemaRevision'] != data.table.schemaRevision) {
      _Arguments.conflict();
    }
  }

  WorkspaceView _edited() {
    final bindings = _Arguments.map(
      arguments,
      'bindings',
    ).cast<String, String>();

    return data.view.edited(
      name: _Arguments.string(arguments, 'name'),
      definition: .fromJson(_Arguments.map(arguments, 'definition')),
      bindings: bindings,
      columnTypes: _types(bindings),
    );
  }

  Map<String, String> _types(Map<String, String> bindings) => {
    for (final column in data.table.columns)
      if (bindings.values.contains(column.id)) column.id: column.type.name,
  };
}

class const _ItemCreation(
  final WorkspaceConversationCommandUsecase owner,
  final _CommandInput input,
) {
  String? get parent =>
      input.selection.kind == 'directory' ? null : input.selection.itemId;

  Future<Map<String, Object?>> call() {
    _destination();

    return input.arguments['action'] == 'createFolder' ? _folder() : _table();
  }

  void _destination() {
    if (!['directory', 'folder'].contains(input.selection.kind) ||
        input.arguments['parentId'] != parent) {
      _Arguments.denied();
    }
  }

  Future<Map<String, Object?>> _folder() async {
    final manager = owner.folders;
    if (manager == null) throw const WorkspaceTableException();
    final folder = await manager.create(
      name: _Arguments.string(input.arguments, 'name'),
      parentId: parent,
    );

    return _Snapshots.folder(folder);
  }

  Future<Map<String, Object?>> _table() async {
    final table = await owner.tables.create(
      name: _Arguments.string(input.arguments, 'name'),
      labelName: _Arguments.string(input.arguments, 'labelName'),
      parentId: parent,
      aiConversationId: input.conversationId,
    );

    return _Snapshots.table(table);
  }
}

class const _TableCommand(
  final WorkspaceConversationCommandUsecase owner,
  final _CommandInput input,
) {
  Future<Map<String, Object?>> call() async =>
      await _dispatch(await _selected());

  Future<WorkspaceTable> _selected() async {
    final selection = input.selection;
    if (selection.kind != 'table' ||
        input.arguments['tableId'] != selection.itemId) {
      _Arguments.denied();
    }

    return await owner.tables.table(selection.itemId);
  }

  Future<Map<String, Object?>> _dispatch(WorkspaceTable table) =>
      switch (input.arguments['action']) {
        'read' => _TableRead(this, table).call(),
        'updateRecord' => _RecordUpdate(this, table).call(),
        'createRecord' => _RecordCreation(this, table).call(),
        'renameTable' => _rename(table),
        'saveColumn' => _ColumnSave(this, table).call(),
        'createView' => _ViewCreation(this, table).call(),
        _ => throw const WorkspaceTableException(),
      };

  Future<Map<String, Object?>> _rename(WorkspaceTable table) async {
    _Arguments.current(table, input.arguments);

    return _Snapshots.table(
      await owner.tables.updateMetadata(
        table: table,
        name: _Arguments.string(input.arguments, 'name'),
        parentId: table.parentId,
        aiConversationId: input.conversationId,
      ),
    );
  }
}

class const _RecordCreation(
  final _TableCommand command,
  final WorkspaceTable table,
) {
  Future<Map<String, Object?>> call() async {
    _Arguments.current(table, command.input.arguments);
    final created = await command.owner.tables.createRecord(
      table: table,
      values: _values(),
      aiConversationId: command.input.conversationId,
    );

    return _Snapshots.record(table.id, created);
  }

  Map<String, Object?> _values() {
    final values = WorkspaceTableConstraints.defaults(
      table.columns,
      _Arguments.map(command.input.arguments, 'values'),
    );
    if (!command.input.references.valuesAllowed(
      _Snapshots.columns(table),
      values,
      const {},
    )) {
      _Arguments.denied();
    }

    return values;
  }
}

class const _RecordUpdate(
  final _TableCommand command,
  final WorkspaceTable table,
) {
  Future<Map<String, Object?>> call() async {
    final current = await _selected();
    final updated = await command.owner.tables.updateRecord(
      table: table,
      record: current,
      values: _values(current),
      aiConversationId: command.input.conversationId,
    );

    return _Snapshots.record(table.id, updated);
  }

  Future<WorkspaceRecord> _selected() async {
    final id = _Arguments.string(command.input.arguments, 'id');
    if (!command.input.selection.recordIds.contains(id)) _Arguments.denied();
    final current = await command.owner.tables.record(table.id, id);
    _current(current);

    return current;
  }

  void _current(WorkspaceRecord current) {
    final arguments = command.input.arguments;
    if (arguments['revision'] != current.revision ||
        arguments['schemaRevision'] != table.schemaRevision) {
      _Arguments.conflict();
    }
  }

  Map<String, Object?> _values(WorkspaceRecord current) {
    final values = _Arguments.map(command.input.arguments, 'values');
    if (!command.input.references.valuesAllowed(
      _Snapshots.columns(table),
      values,
      current.values,
    )) {
      _Arguments.denied();
    }

    return {...current.values, ...values};
  }
}

class const _ColumnSave(
  final _TableCommand command,
  final WorkspaceTable table,
) {
  Future<Map<String, Object?>> call() async {
    _Arguments.current(table, command.input.arguments);
    final updated = await command.owner.tables.saveColumn(
      table: table,
      column: _column(),
      aiConversationId: command.input.conversationId,
    );

    return _Snapshots.table(updated);
  }

  WorkspaceColumn _column() {
    final input = _Arguments.map(command.input.arguments, 'column');
    final previous = _previous(input['id']);
    final merged = {...previous, ...input};
    if (!command.input.references.columnAllowed(merged, previous)) {
      _Arguments.denied();
    }

    return .fromJson(merged);
  }

  Map<String, Object?> _previous(Object? id) =>
      table.columns.where((column) => column.id == id).firstOrNull?.toJson() ??
      const {};
}

class const _ViewCreation(
  final _TableCommand command,
  final WorkspaceTable table,
) {
  ManageWorkspaceViewsUsecase get manager =>
      command.owner.views ?? (throw const WorkspaceTableException());

  Future<Map<String, Object?>> call() async {
    _Arguments.current(table, command.input.arguments);

    return _Snapshots.view(await _create());
  }

  Future<WorkspaceView> _create() => manager.create(
    name: _Arguments.string(command.input.arguments, 'name'),
    table: table,
    columnIds: _ids(),
    parentId: table.parentId,
  );

  List<String> _ids() {
    final ids = command.input.arguments['columnIds'];
    if (ids is! List<Object?> || ids.any((id) => id is! String)) {
      throw const WorkspaceTableException();
    }

    return ids.cast<String>();
  }
}

class const _TableRead(
  final _TableCommand command,
  final WorkspaceTable table,
) {
  Future<Map<String, Object?>> call() async => {
    ..._Snapshots.tableContent(table),
    'columns': [
      for (final column in table.columns)
        command.input.references.readableColumn(column.toJson()),
    ],
    'records': await _rows(),
  };

  Future<List<Map<String, Object?>>> _rows() async => [
    for (final id in command.input.selection.recordIds)
      _RecordProjection(
        table,
        command.input.references,
      ).read(await command.owner.tables.record(table.id, id)),
  ];
}

class const _RecordProjection(
  final WorkspaceTable table,
  final WorkspaceReferenceScope references,
) {
  Map<String, Object?> read(WorkspaceRecord record) {
    final projected = references.projectValues(
      _Snapshots.columns(table),
      _visible(record),
    );

    return {
      'id': record.id,
      'revision': record.revision,
      'values': projected.values,
      'restrictedReferenceColumns': {
        ...record.restrictedReferenceColumns,
        ...projected.restricted,
      }.toList(),
    };
  }

  Map<String, Object?> _visible(WorkspaceRecord record) => {
    for (final entry in record.values.entries)
      if (!record.restrictedReferenceColumns.contains(entry.key))
        entry.key: entry.value,
  };
}

abstract final class _Snapshots {
  static List<Map<String, Object?>> columns(WorkspaceTable table) => [
    for (final column in table.columns) column.toJson(),
  ];
  static Map<String, Object?> table(WorkspaceTable table) => {
    'id': table.id,
    'kind': 'table',
    'revision': table.revision,
    'schemaRevision': table.schemaRevision,
  };
  static Map<String, Object?> tableContent(WorkspaceTable table) => {
    'id': table.id,
    'name': table.name,
    'revision': table.revision,
    'schemaRevision': table.schemaRevision,
    'labelColumnId': table.labelColumnId,
  };
  static Map<String, Object?> folder(WorkspaceFolder folder) => {
    'id': folder.id,
    'kind': 'folder',
    'revision': folder.revision,
    'parentId': folder.parentId,
  };
  static Map<String, Object?> folderContent(WorkspaceFolder folder) => {
    'id': folder.id,
    'name': folder.name,
    'revision': folder.revision,
  };
  static Map<String, Object?> view(WorkspaceView view) => {
    'id': view.id,
    'kind': 'view',
    'revision': view.revision,
  };
  static Map<String, Object?> record(String tableId, WorkspaceRecord record) =>
      {
        'id': record.id,
        'kind': 'record',
        'tableId': tableId,
        'revision': record.revision,
      };
}

abstract final class _Arguments {
  static String string(Map<String, Object?> arguments, String key) {
    final value = arguments[key];
    if (value is! String) throw const WorkspaceTableException();

    return value;
  }

  static Map<String, Object?> map(Map<String, Object?> arguments, String key) {
    final value = arguments[key];
    if (value is! Map<String, Object?>) throw const WorkspaceTableException();

    return value;
  }

  static void current(WorkspaceTable table, Map<String, dynamic> arguments) {
    if (table.revision != arguments['revision'] ||
        table.schemaRevision != arguments['schemaRevision']) {
      conflict();
    }
  }

  static void action(Map<String, Object?> arguments, String action) {
    if (arguments['action'] != action) throw const WorkspaceTableException();
  }

  static Never denied() => throw const WorkspaceTableException(denied: true);
  static Never conflict() =>
      throw const WorkspaceTableException(conflict: true);
}
