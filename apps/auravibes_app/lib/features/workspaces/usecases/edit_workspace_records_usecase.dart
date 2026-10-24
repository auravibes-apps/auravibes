import 'package:auravibes_app/features/workspaces/models/workspace_record_change.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:uuid/v7.dart';

class const EditWorkspaceRecordsUsecase(
  final WorkspaceRecordBatchRepository repository,
) {
  Future<bool> apply(
    List<WorkspaceRecordChange> changes, {
    required Future<bool> Function(List<WorkspaceRecordChange>) approve,
    ConversationToolAccessMode mode = .defaultMode,
    String? requestId,
  }) async {
    final snapshot = _snapshot(changes);
    WorkspaceRecordChange.validate(snapshot);
    if (mode == .defaultMode && !await approve(snapshot)) return false;
    await repository.apply(
      snapshot,
      requestId: requestId ?? const UuidV7().generate(),
    );

    return true;
  }

  List<WorkspaceRecordChange> _snapshot(List<WorkspaceRecordChange> changes) =>
      List.unmodifiable(changes.map(_copy));
  WorkspaceRecordChange _copy(WorkspaceRecordChange change) =>
      .new(table: change.table, record: change.record, values: change.values);
}
