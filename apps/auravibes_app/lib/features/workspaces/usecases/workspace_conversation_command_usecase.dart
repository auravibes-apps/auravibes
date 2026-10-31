import 'dart:convert';

import 'package:auravibes_app/data/repositories/workspace_view_mapper.dart';
import 'package:auravibes_app/features/workflows/adapters/workflow_repository.dart';
import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_folder.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_record_query.dart';
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
  final WorkflowRepository? workflows,
  final String? workspaceId,
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
    'workflow' => _WorkflowCommand(owner, input).call(),
    _ => _TableCommand(owner, input).call(),
  };

  Future<Map<String, Object?>> _directory() async {
    final arguments = input.arguments;
    if (arguments['action'] == 'readDirectory') return await _search(arguments);
    _checkRootRead(arguments);

    return {
      'kind': 'directory',
      'id': '',
      'parentId': null,
      'items': await _directoryItems(owner, null),
    };
  }

  Future<Map<String, Object?>> _search(Map<String, dynamic> arguments) =>
      readWorkspaceDirectory(
        path: _optionalString(arguments, 'path'),
        pathRegex: _optionalString(arguments, 'pathRegex'),
        nameRegex: _optionalString(arguments, 'nameRegex'),
        listChildren: (parentId) => _directoryItems(owner, parentId),
      );

  void _checkRootRead(Map<String, dynamic> arguments) {
    _Arguments.action(arguments, 'read');
    if ((arguments['id'] ?? '') != '' ||
        (arguments['tableId'] ?? '') != '' ||
        arguments['parentId'] != null) {
      _Arguments.denied();
    }
  }
}

String? _optionalString(Map<String, dynamic> arguments, String key) {
  final value = arguments[key];
  if (value == null) return null;
  if (value is! String) throw const FormatException('Invalid directory query.');

  return value;
}

Future<List<Map<String, Object?>>> _directoryItems(
  WorkspaceConversationCommandUsecase owner,
  String? parentId,
) async {
  final workflowRepository = owner.workflows;
  final workspaceId = owner.workspaceId;
  final workflows = workflowRepository == null || workspaceId == null
      ? const <WorkspaceWorkflow>[]
      : await workflowRepository.getWorkflows(workspaceId);

  return [
    ..._folderEntries(
      await owner.folders?.list(parentId: parentId) ?? const [],
    ),
    ..._tableEntries(await owner.tables.list(parentId: parentId)),
    ..._viewEntries(await owner.views?.list(parentId: parentId) ?? const []),
    ..._fileEntries(await owner.files?.list(parentId: parentId) ?? const []),
    ..._workflowEntries(workflows, parentId),
  ];
}

Iterable<Map<String, Object?>> _folderEntries(List<WorkspaceFolder> folders) =>
    folders.map(
      (item) => _directoryEntry('folder', item.id, item.name, item.revision),
    );

Iterable<Map<String, Object?>> _tableEntries(List<WorkspaceTable> tables) =>
    tables.map(
      (item) => _directoryEntry('table', item.id, item.name, item.revision),
    );

Iterable<Map<String, Object?>> _viewEntries(List<WorkspaceView> views) => views
    .map((item) => _directoryEntry('view', item.id, item.name, item.revision));

Iterable<Map<String, Object?>> _fileEntries(List<WorkspaceFile> files) => files
    .map((item) => _directoryEntry('file', item.id, item.name, item.revision));

Iterable<Map<String, Object?>> _workflowEntries(
  List<WorkspaceWorkflow> workflows,
  String? parentId,
) => workflows
    .where((item) => item.parentId == parentId && item.deletedAt == null)
    .map(
      (item) => _directoryEntry('workflow', item.id, item.name, item.revision),
    );

Map<String, Object?> _directoryEntry(
  String kind,
  String id,
  String name,
  int revision,
) => {'kind': kind, 'id': id, 'name': name, 'revision': revision};

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

const _maximumToolFileBytes = 65536;

void _checkFileAsset(WorkspaceAsset asset) {
  if (asset.sizeBytes > _maximumToolFileBytes ||
      !{'text/plain', 'application/json'}.contains(asset.mimeType)) {
    throw const WorkspaceTableException();
  }
}

class const _FileCommand(
  final WorkspaceConversationCommandUsecase owner,
  final _CommandInput input,
) {
  OrganizeWorkspaceFilesUsecase get _files =>
      owner.files ?? (throw const WorkspaceTableException(denied: true));

  Future<Map<String, Object?>> call() async {
    _authorizeInput();
    final files = _files;
    final assets =
        owner.assets ?? (throw const WorkspaceTableException(denied: true));
    final file = await files.file(input.selection.itemId);
    final preview = await _preview(assets, file);
    await _reauthorize(files, file);

    return _result(file, preview);
  }

  void _authorizeInput() {
    _Arguments.action(input.arguments, 'read');
    if (input.arguments['id'] != input.selection.itemId) _Arguments.denied();
  }

  Map<String, Object?> _result(
    WorkspaceFile file,
    WorkspaceAssetPreview preview,
  ) => workspaceFileToolResult(
    id: file.id,
    name: file.name,
    mimeType: preview.asset.mimeType,
    revision: file.revision,
    content: utf8.decode(preview.bytes),
  );

  Future<WorkspaceAssetPreview> _preview(
    ManageWorkspaceAssetsUsecase assets,
    WorkspaceFile file,
  ) async {
    final asset = await assets.describe(file.assetId);
    _checkFileAsset(asset);
    final preview = await assets.preview(file.assetId);
    if (preview.asset.id != asset.id) throw const WorkspaceTableException();
    _checkFileAsset(preview.asset);

    return preview;
  }

  Future<void> _reauthorize(
    OrganizeWorkspaceFilesUsecase files,
    WorkspaceFile file,
  ) async {
    final current = await files.file(file.id);
    if (current.revision != file.revision || current.assetId != file.assetId) {
      throw const WorkspaceTableException(denied: true);
    }
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
      return {
        ..._Snapshots.folderContent(folder),
        'items': await _directoryItems(owner, folder.id),
      };
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

class const _WorkflowCommand(
  final WorkspaceConversationCommandUsecase owner,
  final _CommandInput input,
) {
  Future<Map<String, Object?>> call() async {
    _Arguments.action(input.arguments, 'read');
    final id = input.selection.itemId;
    if (input.arguments['id'] != id) _Arguments.denied();
    final repository = owner.workflows;
    final workspaceId = owner.workspaceId;
    if (repository == null || workspaceId == null) _Arguments.denied();
    final workflow = await repository.getWorkflow(id);
    if (workflow == null ||
        workflow.deletedAt != null ||
        workflow.workspaceId != workspaceId) {
      _Arguments.denied();
    }

    return {
      'kind': 'workflow',
      'id': workflow.id,
      'name': workflow.name,
      'description': workflow.description,
      'parentId': workflow.parentId,
      'revision': workflow.revision,
      'definition': workflow.definition.toJson(),
    };
  }
}

class const _ViewEdit(
  final ManageWorkspaceViewsUsecase manager,
  final WorkspaceViewData data,
  final Map<String, dynamic> arguments,
) {
  Future<Map<String, Object?>> save() async {
    _current();
    if (!_hasViewEditArguments(arguments)) {
      throw const WorkspaceTableException();
    }
    final saved = await manager.save(
      _ViewMutation(data.view, data.table, arguments).apply(),
    );

    return _Snapshots.view(saved);
  }

  void _current() {
    _Arguments.action(arguments, 'saveView');
    if (arguments['revision'] != data.view.revision ||
        arguments['schemaRevision'] != data.table.schemaRevision) {
      _Arguments.conflict();
    }
  }
}

class const _ViewMutation(
  final WorkspaceView view,
  final WorkspaceTable table,
  final Map<String, dynamic> arguments,
) {
  WorkspaceView apply() => _withFilters().edited(
    name: _name(),
    definition: _definition(),
    bindings: _bindings(),
    columnTypes: _columnTypes(),
  );

  WorkspaceView _withFilters() => view
      .withQuery(_resolvedViewQuery(view.query, arguments))
      .withSummaryColumns(_summary())
      .withAction(_action());

  String _name() => arguments.containsKey('name')
      ? _Arguments.string(arguments, 'name')
      : view.name;

  Map<String, String> _bindings() => arguments.containsKey('bindings')
      ? _stringMap(arguments['bindings'])
      : view.bindings;

  List<String> _summary() => arguments.containsKey('summaryColumnIds')
      ? _stringList(arguments['summaryColumnIds'])
      : view.summaryColumnIds;

  A2uiSavedAction? _action() => _resolvedViewAction(view.action, arguments);

  A2uiSavedDefinition _definition() => _resolvedViewDefinition(
    view.definition,
    arguments,
    requiresUserAction: _action() != null,
  );

  Map<String, String> _columnTypes() {
    final query = _resolvedViewQuery(view.query, arguments);
    final dependencies = <String>{
      ..._bindings().values,
      ..._summary(),
      ?query.filterColumnId,
      ?query.sortColumnId,
    };

    return {
      for (final column in table.columns)
        if (dependencies.contains(column.id)) column.id: column.type.name,
    };
  }
}

bool _hasViewEditArguments(Map<String, dynamic> arguments) => const [
  'name',
  'bindings',
  'definition',
  'updateComponents',
  'removeComponentIds',
  'query',
  'summaryColumnIds',
  'viewAction',
].any(arguments.containsKey);

WorkspaceRecordQuery _resolvedViewQuery(
  WorkspaceRecordQuery current,
  Map<String, dynamic> arguments,
) {
  final raw = arguments['query'];
  if (raw == null) return current;
  final merged = <String, Object?>{
    ...current.toJson(),
    ..._Arguments.map(arguments, 'query'),
  };

  return WorkspaceRecordQuery.fromJson(merged);
}

A2uiSavedAction? _resolvedViewAction(
  A2uiSavedAction? current,
  Map<String, dynamic> arguments,
) {
  if (!arguments.containsKey('viewAction')) return current;
  if (arguments['viewAction'] == null) return null;

  return A2uiSavedAction.fromJson(_Arguments.map(arguments, 'viewAction'));
}

A2uiSavedDefinition _resolvedViewDefinition(
  A2uiSavedDefinition current,
  Map<String, dynamic> arguments, {
  required bool requiresUserAction,
}) {
  final hasDefinition = arguments.containsKey('definition');
  final hasPatch = _hasDefinitionPatch(arguments);
  if (hasDefinition && hasPatch) throw const WorkspaceTableException();
  if (hasDefinition) {
    return .fromJson(
      _Arguments.map(arguments, 'definition'),
      requiresUserAction: requiresUserAction,
    );
  }
  if (hasPatch) {
    return _patchDefinition(current, arguments, requiresUserAction);
  }

  return .fromJson(current.toJson(), requiresUserAction: requiresUserAction);
}

bool _hasDefinitionPatch(Map<String, dynamic> arguments) =>
    arguments.containsKey('updateComponents') ||
    arguments.containsKey('removeComponentIds');

A2uiSavedDefinition _patchDefinition(
  A2uiSavedDefinition current,
  Map<String, dynamic> arguments,
  bool requiresUserAction,
) => current.applyPatch(
  updateComponents: _componentMaps(arguments['updateComponents']),
  removeComponentIds: arguments.containsKey('removeComponentIds')
      ? _stringList(arguments['removeComponentIds'])
      : null,
  requiresUserAction: requiresUserAction,
);

Map<String, String> _stringMap(Object? value) {
  if (value is! Map ||
      value.entries.any(
        (entry) => entry.key is! String || entry.value is! String,
      )) {
    throw const WorkspaceTableException();
  }

  return value.cast<String, String>();
}

List<String> _stringList(Object? value) {
  if (value is! List || value.any((item) => item is! String)) {
    throw const WorkspaceTableException();
  }

  return value.cast<String>();
}

List<Map<String, Object?>>? _componentMaps(Object? value) {
  if (value == null) return null;
  if (value is! List || value.any((item) => item is! Map)) {
    throw const WorkspaceTableException();
  }

  return [
    for (final item in value.cast<Map<Object?, Object?>>())
      Map<String, Object?>.from(item),
  ];
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

  Future<WorkspaceView> _create() {
    final arguments = command.input.arguments;
    final name = _Arguments.string(arguments, 'name');
    if (!_hasCustomCreationArgs(arguments)) {
      return manager.create(
        name: name,
        table: table,
        columnIds: _ids(),
        parentId: table.parentId,
      );
    }

    return manager.save(_ViewMutation(_draft(name), table, arguments).apply());
  }

  WorkspaceView _draft(String name) => WorkspaceView.create(
    name: name,
    table: table,
    columnIds: _ids(),
    parentId: table.parentId,
  );

  bool _hasCustomCreationArgs(Map<String, dynamic> arguments) => const [
    'bindings',
    'definition',
    'query',
    'summaryColumnIds',
    'viewAction',
  ].any(arguments.containsKey);

  List<String> _ids() => _stringList(command.input.arguments['columnIds']);
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
    for (final id in await _recordIds())
      _RecordProjection(
        table,
        command.input.references,
      ).read(await command.owner.tables.record(table.id, id)),
  ];

  Future<List<String>> _recordIds() async {
    final id = command.input.arguments['id'];
    if (id == null) return await _allRecordIds();
    if (id is! String) _Arguments.denied();
    final _ = await command.owner.tables.record(table.id, id);

    return [id];
  }

  Future<List<String>> _allRecordIds() async =>
      (await command.owner.tables.records(table.id))
          .map((record) => record.id)
          .toList();
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
