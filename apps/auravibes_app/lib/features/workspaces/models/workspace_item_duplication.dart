import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';

class const WorkspaceItemDuplication({
  required final WorkspaceDuplicateKind kind,
  required final String sourceId,
  required final int expectedRevision,
  required final String targetId,
  required final String requestId,
  required final String name,
  final String? parentId,
  final bool copyRecords = false,
}) {
  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'sourceId': sourceId,
    'expectedRevision': expectedRevision,
    'targetId': targetId,
    'requestId': requestId,
    'name': name,
    'parentId': parentId,
    'copyRecords': copyRecords,
  };

  WorkspaceItemDuplication withOptions(
    String title, {
    required bool copyRecords,
  }) => .new(
    kind: kind,
    sourceId: sourceId,
    expectedRevision: expectedRevision,
    targetId: targetId,
    requestId: requestId,
    name: title,
    parentId: parentId,
    copyRecords: copyRecords,
  );

  void validate() {
    if (!_validIds() || !_validOptions()) throw const WorkspaceTableException();
  }

  bool _validIds() =>
      sourceId.isNotEmpty &&
      sourceId.length <= _maximumSourceId &&
      targetId.isNotEmpty &&
      targetId != sourceId &&
      targetId.length <= _maximumId &&
      requestId.isNotEmpty &&
      requestId.length <= _maximumId;
  bool _validOptions() =>
      expectedRevision > 0 &&
      name.trim().isNotEmpty &&
      name.trim().length <= _maximumName &&
      !(kind != .table && copyRecords) &&
      _validParent(parentId);
}

abstract interface class WorkspaceItemDuplicationRepository {
  Future<void> copy(WorkspaceItemDuplication request);
}

enum WorkspaceDuplicateKind { table, view, workflow }

const _maximumId = 100;
const _maximumName = 200;

const _maximumSourceId = 200;
bool _validParent(String? id) =>
    id == null || (id.isNotEmpty && id.length <= _maximumSourceId);
