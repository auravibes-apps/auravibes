import 'package:auravibes_app/features/chats/widgets/responsive_conversation_layout.dart';
import 'package:auravibes_app/features/workspaces/notifiers/workspace_open_view_notifier.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceViewChatLayout({
  required final String workspaceId,
  required final String conversationId,
  required final Widget mainContent,
  required final ResponsiveConversationSidePanel fallbackSidePanel,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = workspaceOpenViewProvider(workspaceId, conversationId);
    final forcedOpen = useMemoized(() => ValueNotifier(false), [
      workspaceId,
      conversationId,
    ]);
    useValueListenable(forcedOpen);
    useEffect(() => forcedOpen.dispose, [forcedOpen]);
    ref.listen(provider, (previous, next) {
      forcedOpen.value = next != null;
    });
    void close() {
      forcedOpen.value = false;
      ref.read(provider.notifier).close();
      fallbackSidePanel.onClose();
    }

    return ResponsiveConversationLayout(
      mainContent: mainContent,
      sidePanel: .new(
        visible: fallbackSidePanel.visible || forcedOpen.value,
        mounted: fallbackSidePanel.mounted || forcedOpen.value,
        widthPercent: fallbackSidePanel.widthPercent,
        onWidthChanged: fallbackSidePanel.onWidthChanged,
        onClose: close,
        builder: fallbackSidePanel.builder,
      ),
    );
  }
}
