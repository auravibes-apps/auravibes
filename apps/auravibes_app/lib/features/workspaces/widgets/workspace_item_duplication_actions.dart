import 'package:auravibes_app/features/workspaces/models/workspace_item_duplication.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_duplication_dialog.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/v7.dart';

abstract final class WorkspaceItemDuplicationActions {
  static Future<String?> open(
    BuildContext context,
    String workspaceId,
    Object source,
  ) async {
    final id = await WorkspaceItemDuplicationDialog.open(
      context,
      workspaceId,
      _request(source),
    );
    if (context.mounted && id != null) {
      final _ = AuraSnackBars.show(
        context: context,
        content: const TextLocale(LocaleKeys.workspace_items_duplicate_created),
        variant: .success,
      );
    }

    return id;
  }

  static WorkspaceItemDuplication _request(Object source) =>
      _draft(_source(source));
}

typedef _CopySource = ({
  WorkspaceDuplicateKind kind,
  String id,
  String name,
  int revision,
  String? parentId,
});
_CopySource _source(Object source) => switch (source) {
  WorkspaceTable(:final id, :final name, :final revision, :final parentId) => (
    kind: WorkspaceDuplicateKind.table,
    id: id,
    name: name,
    revision: revision,
    parentId: parentId,
  ),
  WorkspaceView(:final id, :final name, :final revision, :final parentId) => (
    kind: WorkspaceDuplicateKind.view,
    id: id,
    name: name,
    revision: revision,
    parentId: parentId,
  ),
  _ => throw const WorkspaceTableException(),
};
WorkspaceItemDuplication _draft(_CopySource source) => .new(
  kind: source.kind,
  sourceId: source.id,
  expectedRevision: source.revision,
  targetId: const UuidV7().generate(),
  requestId: const UuidV7().generate(),
  name: source.name,
  parentId: source.parentId,
);
