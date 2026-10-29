import 'package:auravibes_app/features/workspaces/models/workspace_item_duplication.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

class const DuplicateWorkspaceItemUsecase(
  final WorkspaceItemDuplicationRepository repository,
) {
  Future<bool> call(
    WorkspaceItemDuplication request, {
    required Future<bool> Function() approve,
    ConversationToolAccessMode mode = .defaultMode,
  }) async {
    request.validate();
    if (mode == .defaultMode && !await approve()) return false;
    try {
      await repository.copy(request);
    } on WorkspaceTableException catch (error, stackTrace) {
      if (error.denied || error.conflict || error.unsupportedCopy) rethrow;
      Error.throwWithStackTrace(
        const WorkspaceTableException(unsupportedCopy: true),
        stackTrace,
      );
    }

    return true;
  }
}
