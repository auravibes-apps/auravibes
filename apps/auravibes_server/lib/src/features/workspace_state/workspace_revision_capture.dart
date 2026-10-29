import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'workspace_history_retention.dart';

class const WorkspaceRevisionCapture(
  final Session session,
  final Transaction transaction,
) {
  Future<void> save(
    WorkspaceResource resource, {
    String? actorUserId,
    bool? aiInvolved,
    String? operation,
    String? conversationId,
  }) async {
    if (!_historical(resource.resourceKind)) return;
    final key = _RevisionKey.resource(resource);
    if (await _existing(key) != null) return;
    await _insert(
      resource,
      actorUserId: actorUserId,
      aiInvolved: aiInvolved,
      operation: operation,
      conversationId: conversationId,
    );
    await WorkspaceHistoryRetention(
      session,
      resource.workspaceId,
      transaction,
    ).prune();
  }

  Future<void> requireView(WorkspaceViewSaveRequest request) async {
    final key = _RevisionKey(request.workspaceId, .view, request.viewId, 0);
    if (await _existing(key) != null) {
      throw CloudWorkspaceException(code: .conflict);
    }
  }

  Future<void> requirePatch(PatchWorkspaceStateRequest request) async {
    for (final operation in request.operations) {
      _requirePolicyOperation(operation);
      final key = _RevisionKey(
        request.workspaceId,
        operation.resourceKind,
        operation.resourceId,
        0,
      );
      if (await _existing(key) != null) {
        throw CloudWorkspaceException(code: .conflict);
      }
    }
  }

  Future<void> _insert(
    WorkspaceResource resource, {
    String? actorUserId,
    bool? aiInvolved,
    String? operation,
    String? conversationId,
  }) async {
    final data = await _data(resource);
    final _ = await WorkspaceRevision.db.insertRow(
      session,
      _snapshot(
        resource,
        data,
        actorUserId: actorUserId,
        aiInvolved: aiInvolved,
        operation: operation,
        conversationId: conversationId,
      ),
      transaction: transaction,
    );
  }

  Future<WorkspaceRevision?> _existing(_RevisionKey key) => WorkspaceRevision.db
      .findFirstRow(session, where: key.matches, transaction: transaction);

  Future<String> _data(WorkspaceResource resource) async {
    if (resource.resourceKind != .tableRecord) return resource.data;
    final data = jsonDecode(resource.data) as Map<String, dynamic>;
    final table = await _table(resource.workspaceId, data['tableId'] as String);
    _provenance(data, table);

    return jsonEncode(data);
  }

  Future<WorkspaceResource> _table(int workspaceId, String id) async {
    final table = await WorkspaceResource.db.findFirstRow(
      session,
      where: (row) => _tableMatches(row, workspaceId, id),
      transaction: transaction,
    );

    return table ?? (throw CloudWorkspaceException(code: .validationFailed));
  }
}

class const _RevisionKey(
  final int workspaceId,
  final WorkspaceResourceKind kind,
  final String id,
  final int revision,
) {
  factory resource(WorkspaceResource resource) => .new(
    resource.workspaceId,
    resource.resourceKind,
    resource.resourceId,
    resource.revision,
  );
  Expression matches(WorkspaceRevisionTable row) =>
      row.workspaceId.equals(workspaceId) &
      row.resourceKind.equals(kind) &
      row.resourceId.equals(id) &
      row.revision.equals(revision);
}

bool _historical(WorkspaceResourceKind kind) =>
    kind == .table || kind == .tableRecord;
WorkspaceRevision _snapshot(
  WorkspaceResource resource,
  String data, {
  String? actorUserId,
  bool? aiInvolved,
  String? operation,
  String? conversationId,
}) => WorkspaceRevision(
  workspaceId: resource.workspaceId,
  resourceKind: resource.resourceKind,
  resourceId: resource.resourceId,
  revision: resource.revision,
  data: data,
  capturedAt: DateTime.now().toUtc(),
  actorUserId: actorUserId,
  aiInvolved: aiInvolved,
  operation: operation,
  conversationId: conversationId,
);
Expression _tableMatches(
  WorkspaceResourceTable row,
  int workspaceId,
  String id,
) =>
    row.workspaceId.equals(workspaceId) &
    row.resourceKind.equals(.table) &
    row.resourceId.equals(id);
Map<String, Object?> _referenceTargets(WorkspaceResource table) {
  final columns = _columns(table);

  return {
    for (final column in columns.where(_reference))
      column['id'] as String: column['targetTableId'],
  };
}

bool _reference(Map<String, dynamic> column) => column['type'] == 'reference';

void _provenance(Map<String, dynamic> data, WorkspaceResource table) {
  data['historyReferenceTargets'] = _referenceTargets(table);
  data['historyAttachmentColumns'] = _attachmentColumns(table);
}

List<String> _attachmentColumns(WorkspaceResource table) {
  final columns = _columns(table);

  return columns
      .where((column) => column['type'] == 'attachment')
      .map((column) => column['id'] as String)
      .toList();
}

void _requirePolicyOperation(WorkspacePatchOperation operation) {
  if (operation.resourceKind == .workspaceSetting &&
      operation.resourceId == WorkspaceHistoryRetention.resourceId &&
      operation.operation == .delete) {
    throw CloudWorkspaceException(code: .validationFailed);
  }
}

List<Map<String, dynamic>> _columns(WorkspaceResource table) =>
    ((jsonDecode(table.data) as Map<String, dynamic>)['columns'] as List)
        .cast<Map<String, dynamic>>();
