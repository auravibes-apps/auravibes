import 'package:auravibes_app/features/chats/widgets/responsive_conversation_layout.dart';
import 'package:auravibes_app/features/workspaces/notifiers/workspace_open_view_notifier.dart';
import 'package:auravibes_app/features/workspaces/screens/workspace_view_screen.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceViewChatLayout({
  required final String workspaceId,
  required final String conversationId,
  required final Widget mainContent,
  required final ResponsiveConversationSidePanel fallbackSidePanel,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = workspaceOpenViewProvider(workspaceId, conversationId);
    final id = ref.watch(provider);
    void close() => ref.read(provider.notifier).close();

    return ResponsiveConversationLayout(
      mainContent: mainContent,
      sidePanel: _panel(id, close),
    );
  }

  ResponsiveConversationSidePanel _panel(String? id, VoidCallback close) =>
      id == null
      ? fallbackSidePanel
      : ResponsiveConversationSidePanel(
          visible: true,
          mounted: true,
          widthPercent: fallbackSidePanel.widthPercent,
          onWidthChanged: fallbackSidePanel.onWidthChanged,
          onClose: close,
          builder: () => _view(id, close),
        );
  Widget _view(String id, VoidCallback close) =>
      WorkspaceViewScreen(workspaceId: workspaceId, viewId: id, onBack: close);
}
