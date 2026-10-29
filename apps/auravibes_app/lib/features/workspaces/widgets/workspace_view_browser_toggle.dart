import 'package:auravibes_app/features/chats/widgets/conversation_sidebar_toggle_button.dart';
import 'package:auravibes_app/features/workspaces/notifiers/workspace_open_view_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceViewBrowserToggle({
  required final String workspaceId,
  required final String conversationId,
  required final bool isPanelVisible,
  required final int? tabCount,
  required final VoidCallback onPressed,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open =
        ref.watch(workspaceOpenViewProvider(workspaceId, conversationId)) !=
        null;

    return ConversationSidebarToggleButton(
      isPanelVisible: isPanelVisible || open,
      tabCount: tabCount,
      onPressed: () => _toggle(ref, open),
    );
  }

  void _toggle(WidgetRef ref, bool open) {
    if (!open) {
      onPressed();

      return;
    }
    ref
        .read(workspaceOpenViewProvider(workspaceId, conversationId).notifier)
        .close();
    if (isPanelVisible) onPressed();
  }
}
