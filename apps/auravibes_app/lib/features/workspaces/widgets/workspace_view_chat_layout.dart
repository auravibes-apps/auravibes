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
    final forcedOpen = _useForcedOpen(ref);
    void close() {
      forcedOpen.value = false;
      ref
          .read(workspaceOpenViewProvider(workspaceId, conversationId).notifier)
          .close();
      fallbackSidePanel.onClose();
    }

    return _ViewChatContent(this, close, forcedOpen: forcedOpen.value);
  }

  ValueNotifier<bool> _useForcedOpen(WidgetRef ref) {
    final forcedOpen = useMemoized(() => ValueNotifier(false), [
      workspaceId,
      conversationId,
    ]);
    final _ = useValueListenable(forcedOpen);
    useEffect(() => forcedOpen.dispose, [forcedOpen]);
    ref.listen(
      workspaceOpenViewProvider(workspaceId, conversationId),
      (_, next) => forcedOpen.value = next != null,
    );

    return forcedOpen;
  }
}

class const _ViewChatContent(
  final WorkspaceViewChatLayout owner,
  final VoidCallback close, {
  required final bool forcedOpen,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final fallback = owner.fallbackSidePanel;

    return ResponsiveConversationLayout(
      mainContent: owner.mainContent,
      sidePanel: .new(
        visible: fallback.visible || forcedOpen,
        mounted: fallback.mounted || forcedOpen,
        widthPercent: fallback.widthPercent,
        onWidthChanged: fallback.onWidthChanged,
        onClose: close,
        builder: fallback.builder,
      ),
    );
  }
}
