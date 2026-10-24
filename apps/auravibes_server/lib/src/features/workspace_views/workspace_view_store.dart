import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../workspace_state/domain/workspace_resource_validation.dart';
import '../workspace_state/workspace_table_access.dart';
import 'workspace_view_validation.dart';

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
  Future<WorkspaceView?> view(String id) => WorkspaceView.db.findFirstRow(
    session,
    where: (row) => workspace(row) & row.stableId.equals(id),
    transaction: transaction,
  );
  Expression workspace(WorkspaceViewTable row) =>
      row.workspaceId.equals(member.workspaceId);
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
    final input = WorkspaceViewValidation.parse(
      request.definition,
      request.viewId,
    );
    await _checkBindings(input);
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

  void _requireOwner() {
    if (context.member.role != 'owner') _denied();
  }

  Future<void> _checkBindings(WorkspaceViewInput input) async {
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
    await _source(data['tableId'] as String);
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

class const _ViewReceipts(final _ViewContext context) {
  Future<WorkspaceView?> replay(WorkspaceViewSaveRequest request) async {
    final receipt = await _find(request.requestId);
    if (receipt == null) return null;
    if (receipt.requestHash != await _requestHash(request)) _receiptConflict();

    return WorkspaceView.fromJson(
      jsonDecode(receipt.responseJson) as Map<String, dynamic>,
    );
  }

  Future<void> save(
    WorkspaceViewSaveRequest request,
    WorkspaceView saved,
  ) async {
    final receipt = await _receipt(request, saved);
    await WorkspaceMutationReceipt.db.insertRow(
      context.session,
      receipt,
      transaction: context.transaction,
    );
  }

  Future<WorkspaceMutationReceipt?> _find(String id) =>
      WorkspaceMutationReceipt.db.findFirstRow(
        context.session,
        where: _ReceiptKey(context, id).matches,
        transaction: context.transaction,
      );

  Future<WorkspaceMutationReceipt> _receipt(
    WorkspaceViewSaveRequest request,
    WorkspaceView saved,
  ) async => WorkspaceMutationReceipt(
    workspaceId: context.member.workspaceId,
    scopeKey: _scope(context),
    actorUserId: context.member.userId,
    endpoint: _endpoint,
    requestId: request.requestId,
    requestHash: await _requestHash(request),
    responseJson: jsonEncode(saved.toJson()),
    createdAt: DateTime.now().toUtc(),
  );
}

class const _ReceiptKey(final _ViewContext context, final String requestId) {
  Expression matches(WorkspaceMutationReceiptTable row) =>
      _matchesScope(row) &
      row.actorUserId.equals(context.member.userId) &
      row.requestId.equals(requestId);
  Expression _matchesScope(WorkspaceMutationReceiptTable row) =>
      row.workspaceId.equals(context.member.workspaceId) &
      row.scopeKey.equals(_scope(context)) &
      row.endpoint.equals(_endpoint);
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

WorkspaceView _movedRow(WorkspaceView current, WorkspaceViewMove move) {
  final data = _movedMetadata(current, move);

  return current.copyWith(
    data: jsonEncode(data),
    revision: current.revision + 1,
    history: jsonEncode([..._history(current), data]),
  );
}
