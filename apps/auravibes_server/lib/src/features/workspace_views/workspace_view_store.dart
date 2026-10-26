import 'dart:convert';

import 'package:auravibes_server/src/features/workspace_state/domain/workspace_resource_validation.dart';
import 'package:auravibes_server/src/features/workspace_state/workspace_history_receipts.dart';
import 'package:auravibes_server/src/features/workspace_state/workspace_revision_capture.dart';
import 'package:auravibes_server/src/features/workspace_state/workspace_table_access.dart';
import 'package:auravibes_server/src/features/workspace_state/workspace_table_duplication.dart';
import 'package:auravibes_server/src/features/workspace_views/workspace_connected_validation.dart';
import 'package:auravibes_server/src/features/workspace_views/workspace_view_validation.dart';
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:cryptography/cryptography.dart';
import 'package:serverpod/serverpod.dart';

class const WorkspaceViewStore(
  final Session session,
  final WorkspaceMember member,
  final Transaction transaction,
) {
  _ViewContext get _context => _ViewContext(session, member, transaction);
  Future<List<WorkspaceView>> list(String? parentId, bool allFolders) =>
      _ViewReader(_context).list(parentId, allFolders);
  Future<WorkspaceView> read(String id) => _ViewReader(_context).read(id);
  Future<List<String>> history(String id) => _ViewReader(_context).history(id);
  Future<WorkspaceView> duplicate(DuplicateWorkspaceItemRequest request) =>
      _ViewDuplicator(_context).copy(request);
  Future<WorkspaceView> save(WorkspaceViewSaveRequest request) =>
      _ViewWriter(_context).save(request);
  Future<void> authorizeMove(WorkspaceViewMove move) =>
      _ViewMover(_context).authorize(move);
  Future<WorkspaceView> move(WorkspaceViewMove move) =>
      _ViewMover(_context).move(move);
}

class const _ViewContext(
  final Session session,
  final WorkspaceMember member,
  final Transaction transaction,
) {
  Future<WorkspaceResource?> resource(WorkspaceResourceKind kind, String id) =>
      WorkspaceResource.db.findFirstRow(
        session,
        where: _ResourceKey(member.workspaceId, kind, id).matches,
        transaction: transaction,
      );
  Future<WorkspaceView?> view(String id, {bool includeDeleted = false}) =>
      WorkspaceView.db.findFirstRow(
        session,
        where: _ViewKey(member.workspaceId, id, includeDeleted).matches,
        transaction: transaction,
      );
  Expression workspace(WorkspaceViewTable row) =>
      row.workspaceId.equals(member.workspaceId) & row.deletedAt.equals(null);
}

class const _ViewReader(final _ViewContext context) {
  Future<List<WorkspaceView>> list(String? parentId, bool allFolders) async {
    final rows = await WorkspaceView.db.find(
      context.session,
      where: context.workspace,
      transaction: context.transaction,
    );

    return await _visibleRows(rows, parentId, allFolders);
  }

  Future<WorkspaceView> read(String id) async {
    final row = await _requiredRow(id);
    if (!await _visible(_data(row.data))) _denied();

    return row.copyWith(history: '[]');
  }

  Future<List<String>> history(String id) async {
    final row = await _requiredRow(id);
    if (!await _visible(_data(row.data))) _denied();
    final result = <String>[];
    for (final snapshot in _history(row)) {
      if (await _visible(snapshot)) result.add(jsonEncode(snapshot));
    }

    return result;
  }

  Future<List<WorkspaceView>> _visibleRows(
    List<WorkspaceView> rows,
    String? parentId,
    bool allFolders,
  ) async {
    final result = <WorkspaceView>[];
    for (final row in rows) {
      if (await _visibleChild(row, parentId, allFolders)) {
        result.add(row.copyWith(history: '[]'));
      }
    }

    return result;
  }

  Future<bool> _visibleChild(
    WorkspaceView row,
    String? parentId,
    bool allFolders,
  ) async {
    final data = _data(row.data);

    return (allFolders || data['parentId'] == parentId) && await _visible(data);
  }

  Future<WorkspaceView> _requiredRow(String id) async {
    final row = await context.view(id);
    if (row == null) _denied();

    return row;
  }

  Future<bool> _visible(Map<String, Object?> data) async {
    if (data['tableId'] == '') {
      try {
        return await WorkspaceConnectedValidation.visible(
          context.session,
          context.member,
          data['connected'],
        );
      } on CloudWorkspaceException {
        return false;
      }
    }
    final table = await context.resource(.table, data['tableId'] as String);
    if (table == null) return false;

    return await WorkspaceTableAccess(transaction: context.transaction)
            .visible(context.session, context.member, table) !=
        null;
  }
}

class const _ViewWriter(final _ViewContext context) {
  Future<WorkspaceView> save(WorkspaceViewSaveRequest request) async {
    _requireOwner();
    WorkspaceViewValidation.requestId(request.requestId);
    final input = await _input(request);
    await _requireLive(request.viewId);
    await WorkspaceRevisionCapture(
      context.session,
      context.transaction,
    ).requireView(request);
    final replay = await _ViewReceipts(context).replay(request);
    if (replay != null) return replay;

    return await _saveNew(request, input);
  }

  Future<WorkspaceView> _saveNew(
    WorkspaceViewSaveRequest request,
    WorkspaceViewInput input,
  ) async {
    final current = await context.view(request.viewId);
    _checkRevision(current, request.expectedRevision);
    final saved = await _persist(
      _next(request, input, current),
      current == null,
    );
    await _ViewReceipts(context).save(request, saved);

    return saved;
  }

  Future<WorkspaceViewInput> _input(WorkspaceViewSaveRequest request) async {
    final input = WorkspaceViewValidation.parse(
      request.definition,
      request.viewId,
    );
    await _checkBindings(input);
    await WorkspaceConnectedValidation.access(
      context.session,
      context.member,
      input.data['connected'],
    );

    return input;
  }

  Future<void> _requireLive(String id) async {
    final existing = await context.view(id, includeDeleted: true);
    if (existing?.deletedAt != null) _denied();
  }

  void _requireOwner() {
    if (context.member.role != 'owner') _denied();
  }

  Future<void> _checkBindings(WorkspaceViewInput input) async {
    if (input.tableId.isEmpty) {
      if (input.data['connected'] == null) _denied();
      await _checkParent(input.parentId);
      return;
    }
    await _checkOwnedBindings(input);
  }

  Future<void> _checkOwnedBindings(WorkspaceViewInput input) async {
    final table = await context.resource(.table, input.tableId);
    if (table == null) _denied();
    WorkspaceViewValidation.columns(
      input,
      _data(table.data)['columns'] as List<dynamic>,
    );
    await _checkParent(input.parentId);
  }

  Future<void> _checkParent(String? parentId) async {
    if (parentId != null && await context.resource(.folder, parentId) == null) {
      throw CloudWorkspaceException(
        code: CloudWorkspaceErrorCode.validationFailed,
      );
    }
  }

  Future<WorkspaceView> _persist(WorkspaceView row, bool create) async {
    final saved = create
        ? await WorkspaceView.db.insertRow(
            context.session,
            row,
            transaction: context.transaction,
          )
        : await WorkspaceView.db.updateRow(
            context.session,
            row,
            transaction: context.transaction,
          );

    return saved.copyWith(history: '[]');
  }

  WorkspaceView _next(
    WorkspaceViewSaveRequest request,
    WorkspaceViewInput input,
    WorkspaceView? current,
  ) {
    final data = {...input.data, 'revision': request.expectedRevision + 1};

    return WorkspaceView(
      id: current?.id,
      workspaceId: context.member.workspaceId,
      stableId: request.viewId,
      data: jsonEncode(data),
      revision: request.expectedRevision + 1,
      history: jsonEncode([..._history(current), data]),
    );
  }
}

class const _ViewMover(final _ViewContext context) {
  Future<void> authorize(WorkspaceViewMove move) async {
    if (context.member.role != 'owner') _denied();
    final current = await _row(move.id);
    final data = _data(current.data);
    final _ = _metadataName(current, move.name);
    await _ancestry(data, move.parentId);
  }

  Future<WorkspaceView> move(WorkspaceViewMove move) async {
    await authorize(move);
    final current = await _row(move.id);
    _checkRevision(current, move.expectedRevision);

    return await _persist(current, move);
  }

  Future<WorkspaceView> _row(String id) async {
    final row = await context.view(id);
    if (row == null) _denied();

    return row;
  }

  Future<void> _ancestry(Map<String, Object?> data, String? parent) async {
    if (data['tableId'] == '') {
      await WorkspaceConnectedValidation.access(
        context.session,
        context.member,
        data['connected'],
      );
    } else {
      await _source(data['tableId'] as String);
    }
    await _parent(data['parentId'] as String?);
    await _parent(parent);
  }

  Future<void> _source(String id) async {
    final table = await context.resource(.table, id);
    if (table == null) _denied();
    final visible = await WorkspaceTableAccess(transaction: context.transaction)
        .visible(context.session, context.member, table);
    if (visible == null) _denied();
  }

  Future<void> _parent(String? id) async {
    if (id == null) return;
    if (await context.resource(.folder, id) == null) {
      throw CloudWorkspaceException(code: .validationFailed);
    }
  }

  Future<WorkspaceView> _persist(
    WorkspaceView current,
    WorkspaceViewMove move,
  ) async {
    if (_sameMetadata(current, move)) return current.copyWith(history: '[]');
    final saved = await WorkspaceView.db.updateRow(
      context.session,
      _movedRow(current, move),
      transaction: context.transaction,
    );

    return saved.copyWith(history: '[]');
  }
}

class const _ResourceKey(
  final int workspaceId,
  final WorkspaceResourceKind kind,
  final String id,
) {
  Expression matches(WorkspaceResourceTable row) =>
      row.workspaceId.equals(workspaceId) &
      row.resourceKind.equals(kind) &
      row.resourceId.equals(id) &
      row.deletedAt.equals(null);
}

Map<String, Object?> _data(String source) =>
    Map<String, Object?>.from(jsonDecode(source) as Map);
List<Map<String, Object?>> _history(WorkspaceView? row) => row == null
    ? []
    : (jsonDecode(row.history) as List<dynamic>)
          .map((value) => Map<String, Object?>.from(value as Map))
          .toList();
void _checkRevision(WorkspaceView? row, int expected) {
  if ((row?.revision ?? 0) != expected) {
    throw CloudWorkspaceException(code: CloudWorkspaceErrorCode.conflict);
  }
}

Never _denied() => throw CloudWorkspaceException(
  code: CloudWorkspaceErrorCode.permissionDenied,
);

const _endpoint = 'workspaceView.save';

class const _ViewReceipts(
  final _ViewContext context, {
  final String endpoint = _endpoint,
}) {
  Future<WorkspaceView?> replay(WorkspaceViewSaveRequest request) async =>
      await replayHash(request.requestId, await _requestHash(request));
  Future<void> save(
    WorkspaceViewSaveRequest request,
    WorkspaceView saved,
  ) async =>
      await saveHash(request.requestId, await _requestHash(request), saved);

  Future<WorkspaceView?> replayHash(String requestId, String hash) async {
    final receipt = await _find(requestId);
    if (receipt == null) return null;
    if (receipt.requestHash != hash) _receiptConflict();

    return WorkspaceView.fromJson(
      jsonDecode(receipt.responseJson) as Map<String, dynamic>,
    );
  }

  Future<void> saveHash(
    String requestId,
    String hash,
    WorkspaceView saved,
  ) async {
    final _ = await WorkspaceMutationReceipt.db.insertRow(
      context.session,
      _receipt(requestId, hash, saved),
      transaction: context.transaction,
    );
  }

  Future<WorkspaceMutationReceipt?> _find(String id) => WorkspaceMutationReceipt
      .db
      .findFirstRow(
        context.session,
        where: _ReceiptKey(context, id, endpoint).matches,
        transaction: context.transaction,
      )
      .then(WorkspaceHistoryReceipts.available);

  WorkspaceMutationReceipt _receipt(
    String requestId,
    String hash,
    WorkspaceView saved,
  ) => .new(
    workspaceId: context.member.workspaceId,
    scopeKey: _scope(context),
    actorUserId: context.member.userId,
    endpoint: endpoint,
    requestId: requestId,
    requestHash: hash,
    responseJson: jsonEncode(saved.toJson()),
    createdAt: DateTime.now().toUtc(),
  );
}

class const _ReceiptKey(
  final _ViewContext context,
  final String requestId,
  final String endpoint,
) {
  Expression matches(WorkspaceMutationReceiptTable row) =>
      _matchesScope(row) &
      row.actorUserId.equals(context.member.userId) &
      row.requestId.equals(requestId);
  Expression _matchesScope(WorkspaceMutationReceiptTable row) =>
      row.workspaceId.equals(context.member.workspaceId) &
      row.scopeKey.equals(_scope(context)) &
      row.endpoint.equals(endpoint);
}

String _scope(_ViewContext context) =>
    WorkspaceResourceValidation.receiptScopeKey(context.member.workspaceId);
Future<String> _requestHash(WorkspaceViewSaveRequest request) async {
  final hash = await Sha256().hash(utf8.encode(jsonEncode(request.toJson())));

  return base64UrlEncode(hash.bytes);
}

Never _receiptConflict() => throw CloudWorkspaceException(
  code: CloudWorkspaceErrorCode.idempotencyConflict,
);

Map<String, Object?> _movedMetadata(
  WorkspaceView current,
  WorkspaceViewMove move,
) => {
  ..._data(current.data),
  'parentId': move.parentId,
  'name': _metadataName(current, move.name),
  'revision': current.revision + 1,
};

const _maximumMetadataNameLength = 200;
String _metadataName(WorkspaceView current, String? proposed) {
  if (proposed == null) return _data(current.data)['name'] as String;
  final name = proposed.trim();
  if (name.isEmpty || name.length > _maximumMetadataNameLength) {
    throw CloudWorkspaceException(code: .validationFailed);
  }

  return name;
}

bool _sameMetadata(WorkspaceView current, WorkspaceViewMove move) {
  final data = _data(current.data);

  return data['parentId'] == move.parentId &&
      data['name'] == _metadataName(current, move.name);
}

class const _ViewKey(
  final int workspaceId,
  final String id,
  final bool includeDeleted,
) {
  Expression matches(WorkspaceViewTable row) =>
      row.workspaceId.equals(workspaceId) &
      row.stableId.equals(id) &
      (includeDeleted ? Constant.bool(true) : row.deletedAt.equals(null));
}

WorkspaceView _movedRow(WorkspaceView current, WorkspaceViewMove move) {
  final data = _movedMetadata(current, move);

  return current.copyWith(
    data: jsonEncode(data),
    revision: current.revision + 1,
    history: jsonEncode([..._history(current), data]),
  );
}

class const _ViewDuplicator(final _ViewContext context) {
  _ViewReceipts get _receipts =>
      .new(context, endpoint: 'workspaceView.duplicate');
  Future<WorkspaceView> copy(DuplicateWorkspaceItemRequest request) async {
    final source = await _source(request);
    final hash = await _copyHash(request);
    final replay = await _replay(request, hash);
    if (replay != null) return replay;
    final saved = await _save(source, request);
    await _receipts.saveHash(request.requestId, hash, saved);

    return saved;
  }

  Future<WorkspaceView> _source(DuplicateWorkspaceItemRequest request) async {
    WorkspaceTableDuplication.validate(request);
    if (context.member.role != 'owner' || request.copyRecords) _denied();

    final source = await _ViewReader(context).read(request.sourceId);
    await _requireTarget(source, request);

    return source;
  }

  Future<void> _requireTarget(
    WorkspaceView source,
    DuplicateWorkspaceItemRequest request,
  ) => WorkspaceRevisionCapture(
    context.session,
    context.transaction,
  ).requireView(_copySaveRequest(source, request));

  Future<WorkspaceView?> _replay(
    DuplicateWorkspaceItemRequest request,
    String hash,
  ) async {
    final replay = await _receipts.replayHash(request.requestId, hash);
    if (replay == null) return null;
    final _ = await _ViewReader(context).read(request.targetId);

    return replay;
  }

  Future<WorkspaceView> _save(
    WorkspaceView source,
    DuplicateWorkspaceItemRequest request,
  ) async {
    _checkRevision(source, request.expectedRevision);
    if (await context.view(request.targetId, includeDeleted: true) != null) {
      _receiptConflict();
    }

    return await _ViewWriter(context).save(_copySaveRequest(source, request));
  }
}

Future<String> _copyHash(DuplicateWorkspaceItemRequest request) async =>
    base64UrlEncode(
      (await Sha256().hash(utf8.encode(jsonEncode(request.toJson())))).bytes,
    );
WorkspaceViewSaveRequest _copySaveRequest(
  WorkspaceView source,
  DuplicateWorkspaceItemRequest request,
) => .new(
  workspaceId: request.workspaceId,
  requestId: request.targetId,
  viewId: request.targetId,
  expectedRevision: 0,
  definition: jsonEncode(_copyDefinition(source, request)),
);
Map<String, Object?> _copyDefinition(
  WorkspaceView source,
  DuplicateWorkspaceItemRequest request,
) => {
  ..._data(source.data),
  'id': request.targetId,
  'name': request.name.trim(),
  'parentId': request.parentId,
  'revision': 0,
};
