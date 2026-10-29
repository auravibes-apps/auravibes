import 'dart:convert';

import 'package:auravibes_app/features/workspaces/models/workspace_content_report.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_content_report_action.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_history_blocked_exception.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_history_policy.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_revision.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_trash_target.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_resource_store.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart' as cloud;
import 'package:uuid/v7.dart';

typedef _Connection = ({cloud.Client client, int workspaceId});

class const CloudWorkspaceHistoryRepository(
  final CloudWorkspaceResourceStore store,
) implements WorkspaceHistoryRepository {
  @override
  Future<WorkspaceHistoryPolicy> policy() async {
    final connection = await _connection();
    final encoded = await CloudAppErrors.guardCall(
      .state,
      () => connection.client.workspaceHistory.policy(connection.workspaceId),
    );

    return _policy(encoded);
  }

  @override
  Future<void> configure(WorkspaceHistoryPolicy current, int? days) async {
    final connection = await _connection();
    final request = cloud.WorkspaceHistoryPolicyRequest(
      workspaceId: connection.workspaceId,
      days: days,
      expectedRevision: current.revision,
      requestId: const UuidV7().generate(),
    );
    await CloudAppErrors.guardCall(
      .state,
      () => connection.client.workspaceHistory.configurePolicy(request),
    );
  }

  @override
  Future<List<WorkspaceRevision>> history(WorkspaceTrashTarget target) async {
    final connection = await _connection();
    final rows = await _read(connection, target);

    return rows.map((encoded) => _snapshot(encoded, target)).toList();
  }

  @override
  Future<String> submitReport(WorkspaceTrashTarget target) async {
    final connection = await _connection();
    final reportId = const UuidV7().generate();
    await _submitReport(connection, target, reportId);

    return reportId;
  }

  @override
  Future<List<WorkspaceContentReport>> reports() async {
    final connection = await _connection();
    final rows = await CloudAppErrors.guardCall(
      .state,
      () =>
          connection.client.workspaceContentReport.list(connection.workspaceId),
    );

    return rows.map(_contentReport).toList();
  }

  @override
  Future<WorkspaceContentReport> resolveReport(
    String reportId,
    WorkspaceContentReportAction action,
  ) async {
    final connection = await _connection();
    final encoded = await CloudAppErrors.guardCall(
      .state,
      () => connection.client.workspaceContentReport.resolve(
        connection.workspaceId,
        reportId,
        action.name,
      ),
    );

    return _contentReport(encoded);
  }

  @override
  Future<void> restore(WorkspaceTrashTarget target, int revision) async {
    final connection = await _connection();
    await _restore(connection, target, revision);
  }

  @override
  Future<void> permanentlyDelete(WorkspaceTrashTarget target) async {
    final connection = await _connection();
    final details = await CloudAppErrors.guardCall(
      .state,
      () => _purge(connection, target),
    );
    if (details != null) throw WorkspaceHistoryBlockedException.decode(details);
  }

  Future<_Connection> _connection() async {
    final client = await store.client;
    final workspaceId = await store.cloudWorkspaceId;
    if (client == null || workspaceId == null) {
      throw const WorkspaceTableException(denied: true);
    }

    return (client: client, workspaceId: workspaceId);
  }
}

Future<void> _submitReport(
  _Connection connection,
  WorkspaceTrashTarget target,
  String reportId,
) async {
  final encoded = await CloudAppErrors.guardCall(
    .state,
    () => connection.client.workspaceContentReport.submit(
      connection.workspaceId,
      jsonEncode(target.toJson()),
      reportId,
    ),
  );
  _verifyReceipt(encoded, reportId);
}

void _verifyReceipt(String encoded, String reportId) {
  final receipt = jsonDecode(encoded) as Map<String, dynamic>;
  if (receipt['receiptId'] != reportId || receipt['status'] != 'submitted') {
    throw const WorkspaceTableException();
  }
}

Future<List<String>> _read(
  _Connection connection,
  WorkspaceTrashTarget target,
) => CloudAppErrors.guardCall(
  .state,
  () => connection.client.workspaceHistory.history(
    connection.workspaceId,
    jsonEncode(target.toJson()),
  ),
);
WorkspaceContentReport _contentReport(String encoded) =>
    _reportFromJson(jsonDecode(encoded) as Map<String, dynamic>);

WorkspaceContentReport _reportFromJson(Map<String, dynamic> row) => .new(
  reportId: row['reportId'] as String,
  target: _reportTarget(row),
  status: row['status'] as String,
  submittedAt: _requiredDate(row['submittedAt'] as String),
  conversationId: row['conversationId'] as String?,
  reviewerUserId: row['reviewerUserId'] as String?,
  reviewedAt: _optionalDate(row['reviewedAt']),
);

WorkspaceTrashTarget _reportTarget(Map<String, dynamic> row) => .new(
  kind: row['kind'] == 'record' ? .record : .table,
  id: row['resourceId'] as String,
  revision: row['revision'] as int,
  tableId: row['tableId'] as String?,
);

DateTime _requiredDate(String value) => DateTime.parse(value).toUtc();
DateTime? _optionalDate(Object? value) =>
    value == null ? null : DateTime.parse(value as String).toUtc();

Future<void> _restore(
  _Connection connection,
  WorkspaceTrashTarget target,
  int revision,
) => CloudAppErrors.guardCall(
  .state,
  () => connection.client.workspaceHistory.restore(
    _request(connection, target, revision),
  ),
);
WorkspaceRevision _snapshot(String encoded, WorkspaceTrashTarget target) {
  final row = jsonDecode(encoded) as Map<String, dynamic>;

  return _revisionFromJson(row, target);
}

WorkspaceRevision _revisionFromJson(
  Map<String, dynamic> row,
  WorkspaceTrashTarget target,
) {
  final metadata = _revisionMetadata(row);

  return WorkspaceRevision(
    target: _target(target, row['revision'] as int),
    data: row['data'] as Map<String, dynamic>,
    actorUserId: metadata.actorUserId,
    aiInvolved: metadata.aiInvolved,
    operation: metadata.operation,
    conversationId: metadata.conversationId,
    capturedAt: metadata.capturedAt,
  );
}

typedef _RevisionMetadata = ({
  String? actorUserId,
  bool? aiInvolved,
  String? operation,
  String? conversationId,
  DateTime? capturedAt,
});

_RevisionMetadata _revisionMetadata(Map<String, dynamic> row) => (
  actorUserId: row['actorUserId'] as String?,
  aiInvolved: row['aiInvolved'] as bool?,
  operation: row['operation'] as String?,
  conversationId: row['conversationId'] as String?,
  capturedAt: _optionalDate(row['capturedAt']),
);

WorkspaceTrashTarget _target(WorkspaceTrashTarget target, int revision) => .new(
  kind: target.kind,
  id: target.id,
  tableId: target.tableId,
  revision: revision,
);

cloud.WorkspaceHistoryRestoreRequest _request(
  _Connection connection,
  WorkspaceTrashTarget target,
  int revision,
) => cloud.WorkspaceHistoryRestoreRequest(
  workspaceId: connection.workspaceId,
  targetJson: jsonEncode(target.toJson()),
  revision: revision,
  requestId: const UuidV7().generate(),
);

WorkspaceHistoryPolicy _policy(String encoded) {
  final data = jsonDecode(encoded) as Map<String, dynamic>;

  return WorkspaceHistoryPolicy(
    days: data['days'] as int?,
    revision: data['revision'] as int,
    canManage: data['canManage'] as bool,
  );
}

Future<String?> _purge(
  _Connection connection,
  WorkspaceTrashTarget target,
) async {
  try {
    await connection.client.workspaceHistory.permanentlyDelete(
      connection.workspaceId,
      jsonEncode(target.toJson()),
    );

    return null;
  } on cloud.CloudWorkspaceException catch (error) {
    final details = error.blockingResourcesJson;
    if (details != null) return details;
    rethrow;
  }
}
