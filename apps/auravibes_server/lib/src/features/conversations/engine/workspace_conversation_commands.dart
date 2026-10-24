import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:cryptography/cryptography.dart';
import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../../workspace_state/repositories/workspace_state_repository.dart';
import '../../workspace_state/usecases/workspace_state_usecases.dart';
import '../../workspace_state/workspace_table_access.dart';
import '../../workspace_views/workspace_view_store.dart';

/// Host-owned commands reuse ordinary resource authorization and mutation rules.
class const WorkspaceConversationCommands() {
  Future<Object?> call(
    Session session,
    ConversationTurn turn,
    String operationId,
    Map<String, dynamic> arguments,
  ) async {
    operationId = (await Sha256().hash(
      utf8.encode('${turn.requestId}:$operationId'),
    )).bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    final member = await _member(session, turn);
    final selection = await _selection(session, turn);
    if (selection == null) _denied();
    final action = arguments['action'];
    if (selection!.kind == 'view')
      return _view(session, turn, operationId, selection, arguments);
    if (selection.kind == 'folder' &&
        action != 'createFolder' &&
        action != 'createTable')
      return _folder(session, turn, member, selection, operationId, arguments);
    if (action == 'createFolder' || action == 'createTable') {
      return _createItem(session, turn, operationId, selection!, arguments);
    }
    if (selection!.kind != 'table' || arguments['tableId'] != selection.itemId)
      _denied();
    final table = await _visible(session, member, .table, selection.itemId);
    if (action == 'read') return _read(session, member, table, selection);
    if (action == 'createView')
      return _view(session, turn, operationId, selection, arguments);
    final operation = await _operation(
      session,
      member,
      table,
      selection,
      operationId,
      arguments,
    );
    await WorkspaceStateUseCases(WorkspaceStateRepository()).patch(
      session,
      userId: turn.initiatorUserId,
      request: PatchWorkspaceStateRequest(
        workspaceId: turn.workspaceId,
        requestId: _requestId(turn, operationId),
        operations: [operation],
      ),
    );
    return {'id': operation.resourceId, 'kind': operation.resourceKind.name};
  }

  Future<Object?> _view(
    Session session,
    ConversationTurn turn,
    String operationId,
    WorkspaceContextSelection selection,
    Map<String, dynamic> arguments,
  ) => session.db.transaction((transaction) async {
    final workspace = await CloudWorkspace.db.findById(
      session,
      turn.workspaceId,
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (workspace == null) _denied();
    final member = await WorkspaceMember.db.findFirstRow(
      session,
      where: (row) =>
          row.workspaceId.equals(turn.workspaceId) &
          row.userId.equals(turn.initiatorUserId) &
          row.removedAt.equals(null),
      transaction: transaction,
    );
    if (member == null) _denied();
    final store = WorkspaceViewStore(session, member!, transaction);
    final create = arguments['action'] == 'createView';
    if (!create && arguments['id'] != selection.itemId) _denied();
    final current = create ? null : await store.read(selection.itemId);
    if (arguments['action'] == 'read') return jsonDecode(current!.data);
    if (!create && arguments['action'] != 'saveView')
      throw const FormatException('Invalid View action.');
    final source = create
        ? selection.itemId
        : (jsonDecode(current!.data) as Map<String, dynamic>)['tableId']
              as String;
    final table = await _visible(session, member, .table, source);
    if (arguments['schemaRevision'] != _data(table)['schemaRevision'])
      _conflict();
    final data = create
        ? _newView(table, operationId, arguments)
        : {
            ...jsonDecode(current!.data) as Map<String, dynamic>,
            'name': _string(arguments, 'name'),
            'bindings': _map(arguments, 'bindings'),
            'definition': _map(arguments, 'definition'),
          };
    final saved = await store.save(
      WorkspaceViewSaveRequest(
        workspaceId: turn.workspaceId,
        requestId: _requestId(turn, operationId),
        viewId: create ? _stableId(operationId, 'view') : current!.stableId,
        expectedRevision: create ? 0 : _revision(arguments),
        definition: jsonEncode(data),
      ),
    );
    return {'id': saved.stableId, 'kind': 'view', 'revision': saved.revision};
  });

  Map<String, Object?> _newView(
    WorkspaceResource table,
    String operationId,
    Map<String, dynamic> arguments,
  ) {
    _current(table, arguments);
    final ids = arguments['columnIds'];
    if (ids is! List<Object?> || ids.any((id) => id is! String))
      throw const FormatException('Invalid columns.');
    final columns = (_data(table)['columns'] as List<Object?>)
        .cast<Map<String, dynamic>>();
    return {
      'id': _stableId(operationId, 'view'),
      'name': _string(arguments, 'name'),
      'tableId': table.resourceId,
      'parentId': _data(table)['parentId'],
      'revision': 0,
      'bindings': {
        for (var index = 0; index < ids.length; index++)
          'field$index': ids[index],
      },
      'columnTypes': {
        for (final column in columns)
          if (ids.contains(column['id']))
            column['id'] as String: column['type'],
      },
      'definition': {
        'version': 1,
        'components': [
          {
            'id': 'root',
            'component': 'Table',
            'columns': {'path': '/columns'},
            'rows': {'path': '/rows'},
          },
        ],
      },
    };
  }

  Future<Object?> _folder(
    Session session,
    ConversationTurn turn,
    WorkspaceMember member,
    WorkspaceContextSelection selection,
    String operationId,
    Map<String, dynamic> arguments,
  ) async {
    if (arguments['id'] != selection.itemId) _denied();
    final folder = await _visible(session, member, .folder, selection.itemId);
    if (arguments['action'] == 'read')
      return {
        'id': folder.resourceId,
        'name': _data(folder)['name'],
        'revision': folder.revision,
      };
    if (arguments['action'] != 'renameFolder')
      throw const FormatException('Invalid folder action.');
    await WorkspaceStateUseCases(WorkspaceStateRepository()).patch(
      session,
      userId: turn.initiatorUserId,
      request: PatchWorkspaceStateRequest(
        workspaceId: turn.workspaceId,
        requestId: _requestId(turn, operationId),
        operations: [
          WorkspacePatchOperation(
            operation: .update,
            resourceKind: .folder,
            resourceId: folder.resourceId,
            expectedRevision: _revision(arguments),
            fieldMask: ['name'],
            data: jsonEncode({'name': _string(arguments, 'name')}),
          ),
        ],
      ),
    );
    return {'id': folder.resourceId, 'kind': 'folder'};
  }

  Future<WorkspaceMember> _member(
    Session session,
    ConversationTurn turn,
  ) async {
    final member = await WorkspaceMember.db.findFirstRow(
      session,
      where: (row) =>
          row.workspaceId.equals(turn.workspaceId) &
          row.userId.equals(turn.initiatorUserId) &
          row.removedAt.equals(null),
    );
    if (member == null) _denied();
    return member!;
  }

  Future<WorkspaceContextSelection?> _selection(
    Session session,
    ConversationTurn turn,
  ) async {
    final conversation = await Conversation.db.findById(
      session,
      turn.conversationId,
    );
    if (conversation == null ||
        conversation.deletedAt != null ||
        conversation.workspaceId != turn.workspaceId)
      _denied();
    final users = await ConversationMessage.db.find(
      session,
      where: (row) =>
          row.workspaceId.equals(turn.workspaceId) &
          row.conversationId.equals(turn.conversationId) &
          row.role.equals('user'),
      orderByList: (row) => [row.id.desc()],
    );
    for (final message in users) {
      final metadata = jsonDecode(message.metadataJson ?? '{}');
      if (metadata is! Map<String, dynamic>) continue;
      final model = metadata['modelMetadata'];
      if (model is! Map<String, dynamic> ||
          !model.containsKey(workspaceContextMetadataKey))
        continue;
      return WorkspaceContextSelection.decode(
        model[workspaceContextMetadataKey],
        '${turn.workspaceId}',
        conversation!.stableId,
      );
    }
    return null;
  }

  Future<WorkspaceResource> _visible(
    Session session,
    WorkspaceMember member,
    WorkspaceResourceKind kind,
    String id,
  ) async {
    final row = await WorkspaceResource.db.findFirstRow(
      session,
      where: (row) =>
          row.workspaceId.equals(member.workspaceId) &
          row.resourceKind.equals(kind) &
          row.resourceId.equals(id) &
          row.deletedAt.equals(null),
    );
    if (row == null) _denied();
    final visible = await const WorkspaceTableAccess().visible(
      session,
      member,
      row!,
    );
    if (visible == null) _denied();
    return visible!;
  }

  Future<Map<String, Object?>> _read(
    Session session,
    WorkspaceMember member,
    WorkspaceResource table,
    WorkspaceContextSelection selection,
  ) async {
    final data = _data(table);
    final columns = (data['columns'] as List<Object?>)
        .cast<Map<String, dynamic>>();
    return {
      'id': table.resourceId,
      'name': data['name'],
      'revision': table.revision,
      'schemaRevision': data['schemaRevision'],
      'columns': [
        for (final column in columns) {...column}..remove('targetTableId'),
      ],
      'records': [
        for (final id in selection.recordIds)
          await _record(session, member, table.resourceId, id),
      ],
    };
  }

  Future<Map<String, Object?>> _record(
    Session session,
    WorkspaceMember member,
    String tableId,
    String id,
  ) async {
    final record = await _visible(session, member, .tableRecord, id);
    final data = _data(record);
    if (data['tableId'] != tableId) _denied();
    return {'id': id, 'revision': record.revision, 'values': data['values']};
  }

  Future<WorkspacePatchOperation> _operation(
    Session session,
    WorkspaceMember member,
    WorkspaceResource table,
    WorkspaceContextSelection selection,
    String operationId,
    Map<String, dynamic> arguments,
  ) async {
    final data = _data(table);
    if (arguments['schemaRevision'] != data['schemaRevision']) _conflict();
    return switch (arguments['action']) {
      'updateRecord' => _updateRecord(
        session,
        member,
        table,
        selection,
        arguments,
      ),
      'createRecord' => _createRecord(table, operationId, arguments),
      'renameTable' => _renameTable(table, arguments),
      'saveColumn' => _saveColumn(table, operationId, arguments),
      _ => throw const FormatException('Unsupported workspace action.'),
    };
  }

  Future<WorkspacePatchOperation> _updateRecord(
    Session session,
    WorkspaceMember member,
    WorkspaceResource table,
    WorkspaceContextSelection selection,
    Map<String, dynamic> arguments,
  ) async {
    final id = _string(arguments, 'id');
    if (!selection.recordIds.contains(id)) _denied();
    final current = await _visible(session, member, .tableRecord, id);
    if (_data(current)['tableId'] != table.resourceId) _denied();
    return WorkspacePatchOperation(
      operation: .update,
      resourceKind: .tableRecord,
      resourceId: id,
      expectedRevision: _revision(arguments),
      data: jsonEncode({
        'tableId': table.resourceId,
        'schemaRevision': arguments['schemaRevision'],
        'values': _map(arguments, 'values'),
      }),
      fieldMask: ['tableId', 'schemaRevision', 'values'],
    );
  }

  WorkspacePatchOperation _createRecord(
    WorkspaceResource table,
    String operationId,
    Map<String, dynamic> arguments,
  ) {
    _current(table, arguments);
    return WorkspacePatchOperation(
      operation: .create,
      resourceKind: .tableRecord,
      resourceId: _stableId(operationId, 'record'),
      data: jsonEncode({
        'tableId': table.resourceId,
        'schemaRevision': arguments['schemaRevision'],
        'values': _map(arguments, 'values'),
      }),
      fieldMask: [],
    );
  }

  WorkspacePatchOperation _renameTable(
    WorkspaceResource table,
    Map<String, dynamic> arguments,
  ) {
    _current(table, arguments);
    return WorkspacePatchOperation(
      operation: .update,
      resourceKind: .table,
      resourceId: table.resourceId,
      expectedRevision: table.revision,
      data: jsonEncode({'name': _string(arguments, 'name')}),
      fieldMask: ['name'],
    );
  }

  WorkspacePatchOperation _saveColumn(
    WorkspaceResource table,
    String operationId,
    Map<String, dynamic> arguments,
  ) {
    _current(table, arguments);
    final data = _data(table);
    final column = _map(arguments, 'column');
    final columns = (data['columns'] as List<Object?>)
        .cast<Map<String, dynamic>>();
    final id = column['id'];
    if (id is! String) throw const FormatException('Column ID is required.');
    if (id.isNotEmpty && !columns.any((existing) => existing['id'] == id))
      _conflict();
    final saved = {
      ...column,
      'id': id.isEmpty ? _stableId(operationId, 'column') : id,
    };
    return WorkspacePatchOperation(
      operation: .update,
      resourceKind: .table,
      resourceId: table.resourceId,
      expectedRevision: table.revision,
      data: jsonEncode({
        'columns': [
          for (final existing in columns)
            if (existing['id'] == id) saved else existing,
          if (id.isEmpty) saved,
        ],
        'schemaRevision': (data['schemaRevision'] as int) + 1,
      }),
      fieldMask: ['columns', 'schemaRevision'],
    );
  }

  Future<Map<String, Object?>> _createItem(
    Session session,
    ConversationTurn turn,
    String operationId,
    WorkspaceContextSelection selection,
    Map<String, dynamic> arguments,
  ) async {
    if (selection.kind != 'directory' && selection.kind != 'folder') _denied();
    final parent = selection.kind == 'directory' ? null : selection.itemId;
    if (arguments['parentId'] != parent) _denied();
    final table = arguments['action'] == 'createTable';
    final id = _stableId(operationId, table ? 'table' : 'folder');
    final label = _stableId(operationId, 'label');
    await WorkspaceStateUseCases(WorkspaceStateRepository()).patch(
      session,
      userId: turn.initiatorUserId,
      request: PatchWorkspaceStateRequest(
        workspaceId: turn.workspaceId,
        requestId: _requestId(turn, operationId),
        operations: [
          WorkspacePatchOperation(
            operation: .create,
            resourceKind: table ? .table : .folder,
            resourceId: id,
            data: jsonEncode({
              'name': _string(arguments, 'name'),
              'parentId': parent,
              if (table) ...{
                'labelColumnId': label,
                'schemaRevision': 1,
                'columns': [
                  {
                    'id': label,
                    'name': _string(arguments, 'labelName'),
                    'type': 'text',
                  },
                ],
              },
            }),
            fieldMask: [],
          ),
        ],
      ),
    );
    return {'id': id, 'kind': table ? 'table' : 'folder'};
  }
}

Map<String, dynamic> _data(WorkspaceResource row) =>
    jsonDecode(row.data) as Map<String, dynamic>;
String _requestId(ConversationTurn turn, String id) =>
    _stableId(id, 'workspace');
String _stableId(String id, String kind) => '$id.$kind';
String _string(Map<String, dynamic> arguments, String key) {
  final value = arguments[key];
  if (value is! String)
    throw const FormatException('Invalid workspace request.');
  return value;
}

int _revision(Map<String, dynamic> arguments) {
  final value = arguments['revision'];
  if (value is! int || value < 1)
    throw const FormatException('Expected revision is required.');
  return value;
}

Map<String, dynamic> _map(Map<String, dynamic> arguments, String key) {
  final value = arguments[key];
  if (value is! Map<String, dynamic>)
    throw const FormatException('Invalid workspace request.');
  return value;
}

void _current(WorkspaceResource table, Map<String, dynamic> arguments) {
  if (_revision(arguments) != table.revision) _conflict();
}

Never _denied() => throw CloudWorkspaceException(code: .permissionDenied);
Never _conflict() => throw CloudWorkspaceException(code: .conflict);
