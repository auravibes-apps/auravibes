import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:cryptography/cryptography.dart';
import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../../accounts/auth_user_lock.dart';
import '../../workspace_context/workspace_context_store.dart';
import '../../workspace_state/repositories/workspace_state_repository.dart';
import '../../workspace_state/domain/workspace_table_constraints.dart';
import '../../workspace_state/usecases/workspace_state_usecases.dart';
import '../../workspace_state/workspace_table_access.dart';
import '../../workspace_views/workspace_view_store.dart';

typedef _CommandAuthority = ({
  Future<void> Function(Transaction) guard,
  WorkspaceReferenceScope references,
});

typedef _RecordReadScope = ({
  Session session,
  WorkspaceMember member,
  String tableId,
  List<Map<String, Object?>> columns,
  WorkspaceReferenceScope references,
});

typedef _CommandExecution = ({
  Session session,
  ConversationTurn turn,
  String operationId,
  String contextSelectionId,
  Map<String, dynamic> arguments,
  WorkspaceMember member,
  WorkspaceContextSelection selection,
  _CommandAuthority authority,
});

typedef _PrepareCommandRequest = ({
  Session session,
  ConversationTurn turn,
  String operationId,
  Map<String, dynamic> arguments,
});

typedef _ResolvedCommandContext = ({
  _PrepareCommandRequest request,
  String operationId,
  String contextSelectionId,
  WorkspaceMember member,
  WorkspaceContextSelection selection,
});

typedef _ReadyCommandContext = ({
  _ResolvedCommandContext resolved,
  List<Map<String, Object?>> created,
});

typedef _TableExecution = ({
  _CommandExecution command,
  WorkspaceResource table,
});

typedef _ViewCommandScope = ({
  _CommandExecution command,
  WorkspaceMember member,
  WorkspaceViewStore store,
});

typedef _ViewSelection = ({
  bool create,
  bool isRead,
  WorkspaceView? current,
  Object? content,
});

typedef _ViewSaveRequest = ({
  _CommandExecution command,
  WorkspaceViewStore store,
  Map<String, Object?> data,
  WorkspaceView? current,
  bool create,
});

typedef _ItemCreation = ({
  String? parent,
  bool isTable,
  String id,
  String label,
});

typedef _ResolvedColumn = ({
  Object? previousId,
  List<Map<String, dynamic>> columns,
  Map<String, Object?> value,
});

typedef _CommandGuardRequest = ({
  Session session,
  ConversationTurn turn,
  String conversationId,
  String epoch,
  Transaction transaction,
});

/// Host-owned commands reuse ordinary resource authorization and mutation
/// rules.
class const WorkspaceConversationCommands({
  final Future<void> Function()? beforeMutation,
  final Future<void> Function()? beforeReadVerification,
}) {
  static const _items = _WorkspaceConversationItemCommands();

  Future<Object?> call(
    Session session,
    ConversationTurn turn,
    String operationId,
    Map<String, dynamic> arguments,
  ) async {
    final command = await _prepare((
      session: session,
      turn: turn,
      operationId: operationId,
      arguments: arguments,
    ));
    final isRead =
        arguments['action'] == 'read' || arguments['action'] == 'listCreated';
    if (!isRead) await beforeMutation?.call();
    final result = arguments['action'] == 'listCreated'
        ? await _listCreated(command)
        : await _execute(command);
    if (isRead) {
      await beforeReadVerification?.call();
      await _verifyReadSelection(session, turn, command);
    }

    return _includeSelectionId(result, command);
  }

  Future<_CommandExecution> _prepare(_PrepareCommandRequest request) =>
      _WorkspaceCommandPreparation(this, request).build();

  Future<void> _verifyReadSelection(
    Session session,
    ConversationTurn turn,
    _CommandExecution command,
  ) async {
    final member = await _member(session, turn);
    if (member.revision != command.member.revision ||
        member.role != command.member.role) {
      _denied();
    }
    final current = await _selection(session, turn);
    if (current?.id != command.contextSelectionId) _denied();
  }

  Future<void> _guard(
    _CommandGuardRequest request,
  ) async {
    final current = jsonDecode(
      await WorkspaceContextStore(
        request.session,
        request.turn.workspaceId,
        request.conversationId,
        request.turn.initiatorUserId,
      ).readInTransaction(request.transaction),
    ) as Map<String, dynamic>;
    if (current['id'] != request.epoch) _denied();
  }

  Future<List<Map<String, Object?>>> _created(
    Session session,
    ConversationTurn turn,
    String epoch,
  ) async {
    final calls = await _CommandCallHistory(turn).find(session);

    return [
      for (final call in calls) ?_creationForSelection(call, epoch),
    ];
  }

  Future<Map<String, Object?>> _listCreated(_CommandExecution command) async {
    final cursor = command.arguments['cursor'];
    if (cursor != null &&
        (cursor is! String || cursor.isEmpty || cursor.length > 512)) {
      throw const FormatException('Invalid cursor.');
    }
    final calls = await _CommandCallHistory(command.turn).find(
      command.session,
      cursor: cursor as String?,
      limit: 101,
    );
    final created = [
      for (final call in calls.take(100))
        ?_creationForSelection(call, command.contextSelectionId),
    ];
    final items = <Map<String, Object?>>[];
    for (final entry in created) {
      await _verifyReadSelection(command.session, command.turn, command);
      final kind = entry['kind'];
      final id = entry['id'];
      if (id is! String || !{'folder', 'table', 'view'}.contains(kind)) {
        continue;
      }
      final item = await _createdItem(command, created, kind! as String, id);
      if (item == null) continue;
      items.add(item);
    }
    return {
      'items': items,
      'nextCursor': calls.length > 100 ? calls[99].stableId : null,
    };
  }

  Future<Map<String, Object?>?> _createdItem(
    _CommandExecution command,
    List<Map<String, Object?>> created,
    String kind,
    String id,
  ) async {
    final arguments = <String, dynamic>{
      'action': 'read',
      if (kind == 'table') 'tableId': id else 'id': id,
    };
    final read = (
      session: command.session,
      turn: command.turn,
      operationId: command.operationId,
      contextSelectionId: command.contextSelectionId,
      arguments: arguments,
      member: command.member,
      selection: workspaceCreatedContext(command.selection, created, arguments),
      authority: command.authority,
    );
    try {
      final data = await _execute(read) as Map<String, dynamic>;
      return {
        'id': id,
        'kind': kind,
        for (final key in ['name', 'revision', 'schemaRevision'])
          if (data.containsKey(key)) key: data[key],
      };
    } on CloudWorkspaceException catch (error) {
      if (error.code == .permissionDenied) return null;
      rethrow;
    }
  }

  Future<Object?> _execute(_CommandExecution command) async {
    final selection = command.selection;
    final action = command.arguments['action'];
    if (selection.kind == 'directory' && action == 'read') {
      if ((command.arguments['id'] ?? '') != '' ||
          (command.arguments['tableId'] ?? '') != '' ||
          command.arguments['parentId'] != null) {
        _denied();
      }
      return {'kind': 'directory', 'id': '', 'parentId': null};
    }
    if (selection.kind == 'view') return _items.view(command);
    if (selection.kind == 'folder' && !_createsItem(action)) {
      return _items.folder(command);
    }
    if (_createsItem(action)) return _items.createItem(command);

    return _executeTable(command);
  }

  Future<Object?> _executeTable(_CommandExecution command) =>
      _WorkspaceConversationTableRouter().execute(command);

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

    return member;
  }

  Future<({WorkspaceContextSelection? selection, String id})?> _selection(
    Session session,
    ConversationTurn turn,
  ) async {
    final conversation = await Conversation.db.findById(
      session,
      turn.conversationId,
    );
    if (conversation == null ||
        conversation.workspaceId != turn.workspaceId ||
        conversation.deletedAt != null) {
      _denied();
    }
    final result = jsonDecode(
      await WorkspaceContextStore(
        session,
        turn.workspaceId,
        conversation.stableId,
        turn.initiatorUserId,
      ).read(),
    ) as Map<String, dynamic>;
    final id = result['id'];
    if (id is! String) return null;

    return (
      id: id,
      selection: WorkspaceContextSelection.decode(
        result['selection'],
        '${turn.workspaceId}',
        conversation.stableId,
      ),
    );
  }
}

class _WorkspaceCommandPreparation {
  const _WorkspaceCommandPreparation(this.commands, this.request);

  final WorkspaceConversationCommands commands;
  final _PrepareCommandRequest request;

  Future<_CommandExecution> build() async {
    final resolved = await _resolve();
    final created = request.arguments['action'] == 'listCreated'
        ? <Map<String, Object?>>[]
        : await commands._created(
            request.session,
            request.turn,
            resolved.contextSelectionId,
          );

    return _execution((resolved: resolved, created: created));
  }

  Future<_ResolvedCommandContext> _resolve() async {
    final operationId = await _commandOperationId(
      request.turn,
      request.operationId,
    );
    final member = await commands._member(request.session, request.turn);
    final selected = await _selected();

    return (
      request: request,
      operationId: operationId,
      contextSelectionId: selected.id,
      member: member,
      selection: selected.selection!,
    );
  }

  Future<({String id, WorkspaceContextSelection? selection})>
  _selected() async {
    final event = await commands._selection(request.session, request.turn);
    if (event == null || event.selection == null) _denied();

    return (id: event.id, selection: event.selection);
  }

  _CommandExecution _execution(_ReadyCommandContext ready) {
    final resolved = ready.resolved;
    final request = resolved.request;
    final operationId = resolved.operationId;
    final contextSelectionId = resolved.contextSelectionId;
    final member = resolved.member;
    final created = ready.created;
    final selection = workspaceCreatedContext(
      resolved.selection,
      created,
      request.arguments,
    );

    return (
      session: request.session,
      turn: request.turn,
      operationId: operationId,
      contextSelectionId: contextSelectionId,
      arguments: request.arguments,
      member: member,
      selection: selection,
      authority: _authority(ready, selection),
    );
  }

  _CommandAuthority _authority(
    _ReadyCommandContext ready,
    WorkspaceContextSelection selection,
  ) {
    final resolved = ready.resolved;
    final request = resolved.request;
    final selectionId = resolved.contextSelectionId;
    final references = WorkspaceReferenceScope(
      resolved.selection,
      ready.created,
    );

    return (
      guard: (transaction) async {
        final authUser = await const AuthUserLock().lock(
          request.session,
          userId: request.turn.initiatorUserId,
          transaction: transaction,
        );
        if (authUser == null) {
          throw CloudWorkspaceException(code: .authenticationRequired);
        }
        await commands._guard((
          session: request.session,
          turn: request.turn,
          conversationId: selection.conversationId,
          epoch: selectionId,
          transaction: transaction,
        ));
      },
      references: references,
    );
  }
}

class _WorkspaceConversationViewCommands {
  const _WorkspaceConversationViewCommands();

  Future<Object?> view(_CommandExecution command) =>
      command.session.db.transaction((transaction) async {
        await command.authority.guard(transaction);
        await _authorizedWorkspace(command, transaction);
        final member = await _transactionMember(command, transaction);
        final store = WorkspaceViewStore(command.session, member, transaction);

        return _applyView((command: command, member: member, store: store));
      });

  Future<Object?> _applyView(_ViewCommandScope scope) async {
    final command = scope.command;
    final selected = await _selectView(scope);
    if (selected.isRead) return selected.content;
    final table = await _viewTable(
      command,
      scope.member,
      selected.current,
      selected.create,
    );
    _verifyViewSchemaRevision(command, table);

    return _persistSelectedView(scope, selected, table);
  }

  void _verifyViewSchemaRevision(
    _CommandExecution command,
    WorkspaceResource table,
  ) {
    if (command.arguments['schemaRevision'] != _data(table)['schemaRevision']) {
      _conflict();
    }
  }

  Future<Object?> _persistSelectedView(
    _ViewCommandScope scope,
    _ViewSelection selected,
    WorkspaceResource table,
  ) {
    final command = scope.command;
    final current = selected.current;
    final data = selected.create
        ? _newView(table, command.operationId, command.arguments)
        : _updatedView(table, current!, command.arguments);

    return _saveView((
      command: command,
      store: scope.store,
      data: data,
      current: current,
      create: selected.create,
    ));
  }

  Future<_ViewSelection> _selectView(_ViewCommandScope scope) async {
    final command = scope.command;
    final arguments = command.arguments;
    final action = arguments['action'];
    final create = action == 'createView';
    if (!create && arguments['id'] != command.selection.itemId) {
      _denied();
    }
    final current = create
        ? null
        : await scope.store.read(command.selection.itemId);
    if (action == 'read') {
      return (
        create: create,
        isRead: true,
        current: current,
        content: jsonDecode(current!.data),
      );
    }
    if (!create && action != 'saveView') {
      throw const FormatException('Invalid View action.');
    }

    return (create: create, isRead: false, current: current, content: null);
  }

  Future<WorkspaceResource> _viewTable(
    _CommandExecution command,
    WorkspaceMember member,
    WorkspaceView? current,
    bool create,
  ) async {
    final source = create
        ? command.selection.itemId
        : (jsonDecode(current!.data) as Map<String, dynamic>)['tableId']
              as String;

    return _WorkspaceConversationTableReader().visible(
      command.session,
      member,
      .table,
      source,
    );
  }

  Future<Object?> _saveView(_ViewSaveRequest request) async {
    final command = request.command;
    final turn = command.turn;
    final operationId = command.operationId;
    final arguments = command.arguments;
    final saved = await request.store.save(
      WorkspaceViewSaveRequest(
        workspaceId: turn.workspaceId,
        requestId: _requestId(turn, operationId),
        viewId: request.create
            ? _stableId(operationId, 'view')
            : request.current!.stableId,
        expectedRevision: request.create ? 0 : _revision(arguments),
        definition: jsonEncode(request.data),
      ),
    );

    return {'id': saved.stableId, 'kind': 'view', 'revision': saved.revision};
  }

  Map<String, Object?> _newView(
    WorkspaceResource table,
    String operationId,
    Map<String, dynamic> arguments,
  ) {
    _current(table, arguments);
    final ids = _viewColumnIds(arguments);
    final bindings = _viewBindings(ids);

    return {
      'id': _stableId(operationId, 'view'),
      'name': _string(arguments, 'name'),
      'tableId': table.resourceId,
      'parentId': _data(table)['parentId'],
      'revision': 0,
      'bindings': bindings,
      'columnTypes': _viewColumnTypes(table, bindings),
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
}

class _WorkspaceConversationItemCommands {
  const _WorkspaceConversationItemCommands();

  Future<Object?> view(_CommandExecution command) =>
      const _WorkspaceConversationViewCommands().view(command);

  Future<Object?> folder(_CommandExecution command) async {
    final arguments = command.arguments;
    final selection = command.selection;
    if (arguments['id'] != selection.itemId) _denied();
    final folder = await _WorkspaceConversationTableReader().visible(
      command.session,
      command.member,
      .folder,
      selection.itemId,
    );
    if (arguments['action'] == 'read') {
      return {
        'id': folder.resourceId,
        'name': _data(folder)['name'],
        'revision': folder.revision,
      };
    }
    if (arguments['action'] != 'renameFolder') {
      throw const FormatException('Invalid folder action.');
    }
    await _renameFolder(command, folder);

    return {'id': folder.resourceId, 'kind': 'folder'};
  }

  Future<Map<String, Object?>> createItem(_CommandExecution command) =>
      _WorkspaceItemCreator().create(command);

  Future<void> _renameFolder(
    _CommandExecution command,
    WorkspaceResource folder,
  ) => WorkspaceStateUseCases(WorkspaceStateRepository()).patch(
    command.session,
    userId: command.turn.initiatorUserId,
    guard: command.authority.guard,
    aiInvolved: true,
    conversationId: command.selection.conversationId,
    request: PatchWorkspaceStateRequest(
      workspaceId: command.turn.workspaceId,
      requestId: _requestId(command.turn, command.operationId),
      operations: [
        WorkspacePatchOperation(
          operation: .update,
          resourceKind: .folder,
          resourceId: folder.resourceId,
          expectedRevision: _revision(command.arguments),
          fieldMask: [],
          data: jsonEncode({
            'parentId': _data(folder)['parentId'],
            'name': _string(command.arguments, 'name'),
          }),
        ),
      ],
    ),
  );
}

class _WorkspaceItemCreator {
  Future<Map<String, Object?>> create(_CommandExecution command) async {
    final item = _itemCreation(command);
    await _save(command, item);

    return _createdItemResult(item);
  }

  Future<void> _save(_CommandExecution command, _ItemCreation item) =>
      WorkspaceStateUseCases(WorkspaceStateRepository()).patch(
        command.session,
        userId: command.turn.initiatorUserId,
        guard: command.authority.guard,
        aiInvolved: true,
        conversationId: command.selection.conversationId,
        request: PatchWorkspaceStateRequest(
          workspaceId: command.turn.workspaceId,
          requestId: _requestId(command.turn, command.operationId),
          operations: [_newItemOperation(command, item)],
        ),
      );
}

class _WorkspaceConversationTableReader {
  const _WorkspaceConversationTableReader();

  Future<WorkspaceResource> visible(
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
      row,
    );
    if (visible == null) _denied();

    return visible;
  }

  Future<WorkspaceResource> raw(
    Session session,
    WorkspaceResource visible,
  ) async {
    final raw = await WorkspaceResource.db.findById(session, visible.id!);
    if (raw == null || raw.workspaceId != visible.workspaceId) _denied();

    return raw;
  }

  Future<Map<String, Object?>> read(_TableExecution execution) async {
    final command = execution.command;
    final table = execution.table;
    final raw = await this.raw(command.session, table);
    final data = _data(table);
    final scope = (
      session: command.session,
      member: command.member,
      tableId: table.resourceId,
      columns: _columns(raw),
      references: command.authority.references,
    );

    return {
      'id': table.resourceId,
      'name': data['name'],
      'revision': table.revision,
      'schemaRevision': data['schemaRevision'],
      'labelColumnId': data['labelColumnId'],
      'columns': _readableColumns(table, command.authority.references),
      'records': await _readableRecords(scope, command.selection.recordIds),
    };
  }

  List<Map<String, Object?>> _columns(WorkspaceResource table) =>
      (_data(table)['columns'] as List).cast<Map<String, Object?>>();

  List<Map<String, Object?>> _readableColumns(
    WorkspaceResource table,
    WorkspaceReferenceScope references,
  ) => [
    for (final column in _columns(table)) references.readableColumn(column),
  ];

  Future<List<Map<String, Object?>>> _readableRecords(
    _RecordReadScope scope,
    List<String> recordIds,
  ) async => [for (final id in recordIds) await _record(scope, id)];

  Future<Map<String, Object?>> _record(
    _RecordReadScope scope,
    String id,
  ) async {
    final record = await visible(
      scope.session,
      scope.member,
      .tableRecord,
      id,
    );
    final data = _data(record);
    if (data['tableId'] != scope.tableId) _denied();
    final values = (data['values'] as Map).cast<String, Object?>();
    final readable = scope.references.projectValues(scope.columns, values);

    return {
      'id': id,
      'revision': record.revision,
      'values': readable.values,
      'restrictedReferenceColumns': readable.restricted,
    };
  }
}

class _WorkspaceConversationTableOperations {
  const _WorkspaceConversationTableOperations();

  Future<WorkspacePatchOperation> operation(_TableExecution execution) async {
    final command = execution.command;
    final table = execution.table;
    final data = _data(table);
    if (command.arguments['schemaRevision'] != data['schemaRevision']) {
      _conflict();
    }

    return switch (command.arguments['action']) {
      'updateRecord' => _WorkspaceConversationRecordUpdater().update(execution),
      'createRecord' => _createRecord(execution),
      'renameTable' => _renameTable(execution),
      'saveColumn' => _WorkspaceConversationColumnSaver().save(execution),
      _ => throw const FormatException('Unsupported workspace action.'),
    };
  }

  WorkspacePatchOperation _createRecord(_TableExecution execution) {
    final command = execution.command;
    final table = execution.table;
    final arguments = command.arguments;
    _current(table, arguments);
    final values = WorkspaceTableConstraints.defaults(
      _data(table),
      _map(arguments, 'values'),
    );
    if (!command.authority.references.valuesAllowed(
      _WorkspaceConversationTableReader()._columns(table),
      values,
      const {},
    )) {
      _denied();
    }

    return WorkspacePatchOperation(
      operation: .create,
      resourceKind: .tableRecord,
      resourceId: _stableId(command.operationId, 'record'),
      data: jsonEncode({
        'tableId': table.resourceId,
        'schemaRevision': arguments['schemaRevision'],
        'values': values,
      }),
      fieldMask: [],
    );
  }

  WorkspacePatchOperation _renameTable(_TableExecution execution) {
    final table = execution.table;
    final arguments = execution.command.arguments;
    _current(table, arguments);

    return WorkspacePatchOperation(
      operation: .update,
      resourceKind: .table,
      resourceId: table.resourceId,
      expectedRevision: table.revision,
      data: jsonEncode({
        ..._tableData(table),
        'name': _string(arguments, 'name'),
      }),
      fieldMask: [],
    );
  }
}

class _WorkspaceConversationRecordUpdater {
  Future<WorkspacePatchOperation> update(_TableExecution execution) async {
    final id = _string(execution.command.arguments, 'id');
    final values = await _updatedValues(execution, id);

    return _recordOperation(execution, id, values);
  }

  Future<Map<String, Object?>> _updatedValues(
    _TableExecution execution,
    String id,
  ) async {
    final current = await _selectedRecord(execution, id);
    final stored = await _WorkspaceConversationTableReader().raw(
      execution.command.session,
      current,
    );
    final previous = (_data(stored)['values'] as Map).cast<String, Object?>();
    final input = _map(execution.command.arguments, 'values');

    return _mergeAllowedValues(execution, previous, input);
  }

  Future<WorkspaceResource> _selectedRecord(
    _TableExecution execution,
    String id,
  ) async {
    final command = execution.command;
    if (!command.selection.recordIds.contains(id)) _denied();
    final current = await _WorkspaceConversationTableReader().visible(
      command.session,
      command.member,
      .tableRecord,
      id,
    );
    if (_data(current)['tableId'] != execution.table.resourceId) _denied();

    return current;
  }

  Map<String, Object?> _mergeAllowedValues(
    _TableExecution execution,
    Map<String, Object?> previous,
    Map<String, dynamic> input,
  ) {
    final allowed = execution.command.authority.references.valuesAllowed(
      _WorkspaceConversationTableReader()._columns(execution.table),
      input,
      previous,
    );
    if (!allowed) _denied();

    return {...previous, ...input};
  }

  WorkspacePatchOperation _recordOperation(
    _TableExecution execution,
    String id,
    Map<String, Object?> values,
  ) {
    final command = execution.command;
    final table = execution.table;

    return WorkspacePatchOperation(
      operation: .update,
      resourceKind: .tableRecord,
      resourceId: id,
      expectedRevision: _revision(command.arguments),
      data: jsonEncode({
        'tableId': table.resourceId,
        'schemaRevision': command.arguments['schemaRevision'],
        'values': values,
      }),
      fieldMask: [],
    );
  }
}

class _WorkspaceConversationColumnSaver {
  WorkspacePatchOperation save(_TableExecution execution) {
    _current(execution.table, execution.command.arguments);
    final data = _data(execution.table);
    final resolved = _resolveColumn(execution);

    return _columnOperation(execution, data, resolved);
  }

  _ResolvedColumn _resolveColumn(_TableExecution execution) {
    final data = _data(execution.table);
    final columns = (data['columns'] as List<Object?>)
        .cast<Map<String, dynamic>>();
    final input = _map(execution.command.arguments, 'column');
    final previous = _previousColumn(columns, input['id']);
    final column = {...previous, ...input};
    _authorizeColumn(execution, column, previous);
    final id = _validColumnId(column, columns);

    return (
      previousId: id,
      columns: columns,
      value: _columnValue(execution, column, id),
    );
  }

  Map<String, Object?> _previousColumn(
    List<Map<String, dynamic>> columns,
    Object? id,
  ) =>
      columns.where((column) => column['id'] == id).firstOrNull ??
      <String, Object?>{};

  void _authorizeColumn(
    _TableExecution execution,
    Map<String, Object?> column,
    Map<String, Object?> previous,
  ) {
    if (!execution.command.authority.references.columnAllowed(
      column,
      previous,
    )) {
      _denied();
    }
  }

  String _validColumnId(
    Map<String, Object?> column,
    List<Map<String, dynamic>> columns,
  ) {
    final id = column['id'];
    if (id is! String) throw const FormatException('Column ID is required.');
    if (id.isNotEmpty && !columns.any((existing) => existing['id'] == id)) {
      _conflict();
    }

    return id;
  }

  Map<String, Object?> _columnValue(
    _TableExecution execution,
    Map<String, Object?> column,
    String id,
  ) => {
    ...column,
    'id': id.isEmpty ? _stableId(execution.command.operationId, 'column') : id,
  };

  WorkspacePatchOperation _columnOperation(
    _TableExecution execution,
    Map<String, dynamic> data,
    _ResolvedColumn resolved,
  ) => WorkspacePatchOperation(
    operation: .update,
    resourceKind: .table,
    resourceId: execution.table.resourceId,
    expectedRevision: execution.table.revision,
    data: jsonEncode(_columnData(execution.table, data, resolved)),
    fieldMask: [],
  );

  Map<String, Object?> _columnData(
    WorkspaceResource table,
    Map<String, dynamic> data,
    _ResolvedColumn resolved,
  ) => {
    ..._tableData(table),
    'columns': [
      for (final existing in resolved.columns)
        if (existing['id'] == resolved.previousId) resolved.value else existing,
      if (resolved.previousId == '') resolved.value,
    ],
    'schemaRevision': (data['schemaRevision'] as int) + 1,
  };
}

class _WorkspaceConversationTableRouter {
  Future<Object?> execute(_CommandExecution command) async {
    final visible = await _selectedTable(command);
    if (command.arguments['action'] == 'read') {
      return _WorkspaceConversationTableReader().read((
        command: command,
        table: visible,
      ));
    }

    return _mutate(command, visible);
  }

  Future<WorkspaceResource> _selectedTable(
    _CommandExecution command,
  ) async {
    final selection = command.selection;
    if (selection.kind != 'table' ||
        command.arguments['tableId'] != selection.itemId) {
      _denied();
    }

    return _WorkspaceConversationTableReader().visible(
      command.session,
      command.member,
      .table,
      selection.itemId,
    );
  }

  Future<Object?> _mutate(
    _CommandExecution command,
    WorkspaceResource visible,
  ) async {
    final table = await _WorkspaceConversationTableReader().raw(
      command.session,
      visible,
    );
    if (command.arguments['action'] == 'createView') {
      return const _WorkspaceConversationItemCommands().view(command);
    }
    final operation = await _WorkspaceConversationTableOperations().operation(
      (command: command, table: table),
    );
    await _saveOperation(command, operation);

    return _operationResult(operation, table);
  }

  Future<void> _saveOperation(
    _CommandExecution command,
    WorkspacePatchOperation operation,
  ) => WorkspaceStateUseCases(WorkspaceStateRepository()).patch(
    command.session,
    userId: command.turn.initiatorUserId,
    guard: command.authority.guard,
    aiInvolved: true,
    conversationId: command.selection.conversationId,
    request: PatchWorkspaceStateRequest(
      workspaceId: command.turn.workspaceId,
      requestId: _requestId(command.turn, command.operationId),
      operations: [operation],
    ),
  );
}

class _CommandCallHistory {
  const _CommandCallHistory(this.turn);

  final ConversationTurn turn;

  Future<List<ConversationToolCall>> find(
    Session session, {
    String? cursor,
    int? limit,
  }) => ConversationToolCall.db.find(
    session,
    where: (row) => cursor == null
        ? _matches(row)
        : _matches(row) & (row.stableId > cursor),
    orderBy: (row) => row.stableId,
    limit: limit,
  );

  Expression _matches(ConversationToolCallTable row) =>
      _workspace(row) &
      _conversation(row) &
      _workspaceTool(row) &
      _success(row);

  Expression _workspace(ConversationToolCallTable row) =>
      row.workspaceId.equals(turn.workspaceId);

  Expression _conversation(ConversationToolCallTable row) =>
      row.conversationId.equals(turn.conversationId);

  Expression _workspaceTool(ConversationToolCallTable row) =>
      row.name.equals(workspaceCommandToolName);

  Expression _success(ConversationToolCallTable row) =>
      row.status.equals('success');
}

Future<String> _commandOperationId(
  ConversationTurn turn,
  String operationId,
) async =>
    (await Sha256().hash(utf8.encode('${turn.requestId}:$operationId'))).bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();

_ItemCreation _itemCreation(_CommandExecution command) {
  final selection = command.selection;
  final arguments = command.arguments;
  final operationId = command.operationId;
  if (selection.kind != 'directory' && selection.kind != 'folder') _denied();
  final parent = selection.kind == 'directory' ? null : selection.itemId;
  if (arguments['parentId'] != parent) _denied();
  final isTable = arguments['action'] == 'createTable';

  return (
    parent: parent,
    isTable: isTable,
    id: _stableId(operationId, isTable ? 'table' : 'folder'),
    label: _stableId(operationId, 'label'),
  );
}

WorkspacePatchOperation _newItemOperation(
  _CommandExecution command,
  _ItemCreation item,
) => WorkspacePatchOperation(
  operation: .create,
  resourceKind: item.isTable ? .table : .folder,
  resourceId: item.id,
  data: jsonEncode(_newItemData(command, item)),
  fieldMask: [],
);

Map<String, Object?> _newItemData(
  _CommandExecution command,
  _ItemCreation item,
) => {
  'name': _string(command.arguments, 'name'),
  'parentId': item.parent,
  if (item.isTable) ...{
    'labelColumnId': item.label,
    'schemaRevision': 1,
    'columns': [
      {
        'id': item.label,
        'name': _string(command.arguments, 'labelName'),
        'type': 'text',
      },
    ],
  },
};

Map<String, Object?> _createdItemResult(_ItemCreation item) => {
  'id': item.id,
  'kind': item.isTable ? 'table' : 'folder',
  'parentId': item.parent,
};

Map<String, Object?> _updatedView(
  WorkspaceResource table,
  WorkspaceView current,
  Map<String, dynamic> arguments,
) => {
  ...jsonDecode(current.data) as Map<String, dynamic>,
  'name': _string(arguments, 'name'),
  'bindings': _map(arguments, 'bindings'),
  'columnTypes': _viewColumnTypes(table, _map(arguments, 'bindings')),
  'definition': _map(arguments, 'definition'),
};

bool _createsItem(Object? action) =>
    action == 'createFolder' || action == 'createTable';

Future<void> _authorizedWorkspace(
  _CommandExecution command,
  Transaction transaction,
) async {
  final workspace = await CloudWorkspace.db.findFirstRow(
    command.session,
    where: (row) =>
        row.id.equals(command.turn.workspaceId) &
        row.deletedAt.equals(null) &
        row.erasureRequestedAt.equals(null),
    transaction: transaction,
    lockMode: LockMode.forUpdate,
  );
  if (workspace == null) _denied();
}

Future<WorkspaceMember> _transactionMember(
  _CommandExecution command,
  Transaction transaction,
) async {
  final session = command.session;
  final turn = command.turn;
  final member = await WorkspaceMember.db.findFirstRow(
    session,
    where: (row) =>
        row.workspaceId.equals(turn.workspaceId) &
        row.userId.equals(turn.initiatorUserId) &
        row.removedAt.equals(null),
    transaction: transaction,
  );
  if (member == null) _denied();

  return member;
}

List<Object?> _viewColumnIds(Map<String, dynamic> arguments) {
  final ids = arguments['columnIds'];
  if (ids is! List<Object?> || ids.any((id) => id is! String)) {
    throw const FormatException('Invalid columns.');
  }

  return ids;
}

Map<String, dynamic> _viewBindings(List<Object?> ids) => {
  for (var index = 0; index < ids.length; index++) 'field$index': ids[index],
};

Map<String, Object?> _operationResult(
  WorkspacePatchOperation operation,
  WorkspaceResource table,
) => {
  'id': operation.resourceId,
  'kind': operation.resourceKind == .tableRecord
      ? 'record'
      : operation.resourceKind.name,
  if (operation.resourceKind == .tableRecord) 'tableId': table.resourceId,
};

Map<String, Object?>? _creationForSelection(
  ConversationToolCall call,
  String selectionId,
) {
  final result = jsonDecode(call.resultJson ?? '{}');
  final arguments = jsonDecode(call.argumentsJson);
  if (_createdForSelection(result, arguments, selectionId)) {
    return result as Map<String, Object?>;
  }

  return null;
}

bool _createdForSelection(
  Object? result,
  Object? arguments,
  String selectionId,
) =>
    result is Map<String, dynamic> &&
    arguments is Map<String, dynamic> &&
    result['contextSelectionId'] == selectionId &&
    (arguments['action'] as String? ?? '').startsWith('create');

Object? _includeSelectionId(Object? result, _CommandExecution command) {
  if (!(command.arguments['action'] as String).startsWith('create')) {
    return result;
  }

  return {
    ...result as Map<String, Object?>,
    'contextSelectionId': command.contextSelectionId,
  };
}

Map<String, dynamic> _data(WorkspaceResource row) =>
    jsonDecode(row.data) as Map<String, dynamic>;
String _requestId(ConversationTurn turn, String id) =>
    _stableId(id, 'workspace');
String _stableId(String id, String kind) => '$id.$kind';
String _string(Map<String, dynamic> arguments, String key) {
  final value = arguments[key];
  if (value is! String) {
    throw const FormatException('Invalid workspace request.');
  }

  return value;
}

int _revision(Map<String, dynamic> arguments) {
  final value = arguments['revision'];
  if (value is! int || value < 1) {
    throw const FormatException('Expected revision is required.');
  }

  return value;
}

Map<String, dynamic> _map(Map<String, dynamic> arguments, String key) {
  final value = arguments[key];
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Invalid workspace request.');
  }

  return value;
}

void _current(WorkspaceResource table, Map<String, dynamic> arguments) {
  if (_revision(arguments) != table.revision) _conflict();
}

Never _denied() => throw CloudWorkspaceException(code: .permissionDenied);
Never _conflict() => throw CloudWorkspaceException(code: .conflict);

Map<String, dynamic> _tableData(WorkspaceResource table) {
  final data = _data(table);

  return {
    for (final key in [
      'name',
      'parentId',
      'labelColumnId',
      'schemaRevision',
      'columns',
      'memberAccess',
    ])
      if (data.containsKey(key)) key: data[key],
  };
}

Map<String, Object?> _viewColumnTypes(
  WorkspaceResource table,
  Map<String, dynamic> bindings,
) {
  final columns = (_data(table)['columns'] as List<Object?>)
      .cast<Map<String, dynamic>>();

  return {
    for (final column in columns)
      if (bindings.values.contains(column['id']))
        column['id'] as String: column['type'],
  };
}
