import 'package:auravibes_app/features/workspaces/models/workspace_directory_move_item.dart';
import 'package:auravibes_app/features/workspaces/usecases/move_workspace_directory_items_usecase.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_directory_move_dialog.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceDirectoryMoveButton({
  required final String workspaceId,
  required final List<WorkspaceDirectoryMoveItem> items,
  required final ValueChanged<String?> onMoved,
  super.key,
}) extends StatelessWidget {
  bool get _disabled =>
      items.isEmpty ||
      items.length > MoveWorkspaceDirectoryItemsUsecase.maxItems ||
      items.any((item) => !item.canManage);
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => _show(context),
    child: const TextLocale(LocaleKeys.workspace_items_move),
    disabled: _disabled,
    identifier: 'directory_move',
  );
  void _show(BuildContext context) {
    final child = WorkspaceDirectoryMoveDialog(
      workspaceId: workspaceId,
      items: items,
      onMoved: onMoved,
    );
    if (MediaQuery.sizeOf(context).width < 600) {
      _sheet(context, child);

      return;
    }
    final _ = showDialog<void>(
      context: context,
      builder: (_) => Dialog(child: child),
      barrierDismissible: false,
    );
  }

  void _sheet(BuildContext context, Widget child) {
    final _ = showModalBottomSheet<void>(
      context: context,
      builder: (_) => child,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
    );
  }
}
