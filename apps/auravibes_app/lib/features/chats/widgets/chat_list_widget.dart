// Required: Existing test and UI helpers keep compact return flow.
// Required: UI callbacks stay local to their widgets.
// Required: Feature widgets keep closely related private widgets together.
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_result.dart';
import 'package:auravibes_app/features/chats/providers/cloud_conversation_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_conversation_usecase.dart';
import 'package:auravibes_app/features/chats/widgets/delete_conversation_confirm_dialog.dart';
import 'package:auravibes_app/features/chats/widgets/rename_conversation_dialog.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/utils/relative_time_formatter.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const ChatListWidget({required final String workspaceId, super.key})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatListAsync = ref.watch(
      conversationsStreamProvider(workspaceId: workspaceId),
    );

    return switch (chatListAsync) {
      AsyncData(value: final chats) => _ChatListLoaded(
        chats: chats,
        workspaceId: workspaceId,
      ),
      AsyncLoading() => const Center(child: AuraSpinner()),
      AsyncError() => const Center(
        child: AuraText(
          child: TextLocale(LocaleKeys.workspace_management_unexpected_error),
        ),
      ),
    };
  }
}

class const _ChatListEmptyState({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: _ChatListEmptyStateColumn(workspaceId: workspaceId),
    ),
  );
}

class const _ChatListEmptyStateColumn({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: .center,
    children: [
      const AuraIcon(Icons.chat_outlined, size: .extraLarge),
      const SizedBox(height: 16),
      const AuraText(
        child: TextLocale(
          LocaleKeys.home_screen_conversation_states_no_chats_yet,
        ),
        style: .heading3,
      ),
      const SizedBox(height: 8),
      const AuraText(
        child: TextLocale(
          LocaleKeys.home_screen_conversation_states_start_first_conversation,
        ),
        textAlign: .center,
      ),
      const SizedBox(height: 16),
      _ChatListStartButton(workspaceId: workspaceId),
    ],
  );
}

class const _ChatListStartButton({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => NewChatRoute(workspaceId: workspaceId).go(context),
    child: const TextLocale(LocaleKeys.home_screen_actions_start_new_chat),
  );
}

class const _ChatTile({
  required final ConversationEntity chat,
  required final String workspaceId,
}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ChatTile> createState() => _ChatTileState();
}

class _ChatTileState extends ConsumerState<_ChatTile> {
  final _menuController = AuraPopupMenuController();

  @override
  void dispose() {
    _menuController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chat = widget.chat;

    return _ChatTileProvider(
      chat: chat,
      workspaceId: widget.workspaceId,
      controller: _menuController,
      onDelete: () => _handleDelete(context),
      onTogglePin: () => _togglePin(chat),
      onRename: () => _handleRename(context),
      onMenuToggle: _menuController.toggle,
      onTap: () => _openConversation(context),
    );
  }

  Future<void> _handleRename(BuildContext context) async {
    final title = await RenameConversationDialog.show(
      context,
      title: widget.chat.title,
    );
    if (title == null) return;

    await ref
        .read(
          conversationChatProvider(widget.workspaceId, widget.chat.id).notifier,
        )
        .rename(widget.chat, title);
  }

  Future<void> _handleDelete(BuildContext context) async {
    final chat = widget.chat;
    final confirmed = await DeleteConversationConfirmDialog.show(context);
    if (!confirmed) return;

    await _deleteChat(chat);
  }

  Future<void> _deleteChat(ConversationEntity chat) async {
    final cloud = await ref.read(
      cloudConversationUsecaseProvider(chat.workspaceId).future,
    );
    if (cloud != null) {
      await cloud.delete(chat);

      return;
    }

    final _ = await ref
        .read(conversationRepositoryProvider)
        .deleteConversation(chat.id);

    return;
  }

  Future<void> _togglePin(ConversationEntity chat) async {
    if (!chat.isPinned) {
      final conversations = await ref.read(
        conversationsStreamProvider(workspaceId: chat.workspaceId).future,
      );
      if (!ConversationLimits.hasPinnedCapacity(conversations)) return;
    }
    if (await _toggleCloudPin(chat)) return;
    await _toggleLocalPin(chat);
  }

  Future<bool> _toggleCloudPin(ConversationEntity chat) async {
    final cloud = await ref.read(
      cloudConversationUsecaseProvider(chat.workspaceId).future,
    );
    if (cloud == null) return false;

    await _updateCloudPin(cloud, chat);
    if (!mounted) return true;
    ref.invalidate(conversationsStreamProvider(workspaceId: chat.workspaceId));

    return true;
  }

  Future<void> _updateCloudPin(
    CloudConversationUsecase cloud,
    ConversationEntity chat,
  ) async {
    final patch = ConversationPatch(isPinned: !chat.isPinned);
    try {
      final _ = await cloud.update(chat, patch);
    } on CloudAppException catch (error) {
      if (error.code != 'validationFailed') rethrow;
    }
  }

  Future<void> _toggleLocalPin(ConversationEntity chat) async {
    if (!mounted) return;
    final patch = ConversationPatch(isPinned: !chat.isPinned);
    try {
      final _ = await ref
          .read(conversationRepositoryProvider)
          .patchConversation(chat.id, patch);
    } on ConversationPinLimitException {
      return;
    }
  }

  void _openConversation(BuildContext context) {
    ConversationRoute(
      workspaceId: widget.workspaceId,
      chatId: widget.chat.id,
    ).go(context);
  }
}

class const _ChatTileProvider({
  required final ConversationEntity chat,
  required final String workspaceId,
  required final AuraPopupMenuController controller,
  required final VoidCallback onDelete,
  required final VoidCallback onTogglePin,
  required final VoidCallback onRename,
  required final VoidCallback onMenuToggle,
  required final VoidCallback onTap,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modelDisplayName = _chatModelDisplayName(ref, workspaceId, chat);
    final title = ref.watch(streamingTitleProvider(chat.id)) ?? chat.title;

    return _ChatTileView(
      chat: chat,
      modelDisplayName: modelDisplayName,
      title: title,
      controller: controller,
      onDelete: onDelete,
      onTogglePin: onTogglePin,
      onRename: onRename,
      onMenuToggle: onMenuToggle,
      onTap: onTap,
    );
  }
}

String? _chatModelDisplayName(
  WidgetRef ref,
  String workspaceId,
  ConversationEntity chat,
) => ref
    .watch(listWorkspaceModelSelectionsProvider(workspaceId: workspaceId))
    .asData
    ?.value
    .where((cm) => cm.workspaceModelSelection.id == chat.modelId)
    .firstOrNull
    ?.workspaceModelSelection
    .modelId;

class const _ChatListLoaded({
  required final List<ConversationEntity> chats,
  required final String workspaceId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (chats.isEmpty) {
      return _ChatListEmptyState(workspaceId: workspaceId);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) =>
          _ChatTile(chat: chats[index], workspaceId: workspaceId),
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemCount: chats.length,
    );
  }
}

class const _ChatTileView({
  required final ConversationEntity chat,
  required final String? modelDisplayName,
  required final String title,
  required final AuraPopupMenuController controller,
  required final VoidCallback onDelete,
  required final VoidCallback onTogglePin,
  required final VoidCallback onRename,
  required final VoidCallback onMenuToggle,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraCard(
    child: _ChatTileRow(
      chat: chat,
      modelDisplayName: modelDisplayName,
      title: title,
      controller: controller,
      onDelete: onDelete,
      onTogglePin: onTogglePin,
      onRename: onRename,
      onMenuToggle: onMenuToggle,
    ),
    onTap: onTap,
    style: .border,
  );
}

class const _ChatTileRow({
  required final ConversationEntity chat,
  required final String? modelDisplayName,
  required final String title,
  required final AuraPopupMenuController controller,
  required final VoidCallback onDelete,
  required final VoidCallback onTogglePin,
  required final VoidCallback onRename,
  required final VoidCallback onMenuToggle,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: .start,
    children: [
      Expanded(
        child: _ChatTileInfo(chat: chat, title: title),
      ),
      _ChatTileModelBadge(displayName: modelDisplayName),
      _ChatTileMenu(
        chat: chat,
        controller: controller,
        onDelete: onDelete,
        onTogglePin: onTogglePin,
        onRename: onRename,
        onToggle: onMenuToggle,
      ),
    ],
  );
}

class const _ChatTileModelBadge({required final String? displayName})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final displayName = this.displayName;
    if (displayName == null) return const SizedBox(width: 8);

    return Row(
      mainAxisSize: .min,
      children: [
        const SizedBox(width: 8),
        AuraBadge.text(child: Text(displayName), variant: .info),
        const SizedBox(width: 8),
      ],
    );
  }
}

class const _ChatTileInfo({
  required final ConversationEntity chat,
  required final String title,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      _ChatTileTitleRow(chat: chat, title: title),
      const SizedBox(height: 4),
      AuraText(
        child: Text(
          RelativeTimeFormatter.format(chat.updatedAt),
          overflow: .ellipsis,
        ),
        style: .bodySmall,
      ),
    ],
    crossAxisAlignment: .start,
  );
}

class const _ChatTileTitleRow({
  required final ConversationEntity chat,
  required final String title,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraRow(
    children: [
      if (chat.isPinned) ...[
        const AuraIcon(Icons.push_pin_outlined, size: .small, tint: .warning),
        const SizedBox(width: 8),
      ],
      Expanded(
        child: AuraText(
          child: Text(title, overflow: .ellipsis),
          style: .heading6,
        ),
      ),
    ],
  );
}

class const _ChatTileMenu({
  required final ConversationEntity chat,
  required final AuraPopupMenuController controller,
  required final VoidCallback onDelete,
  required final VoidCallback onTogglePin,
  required final VoidCallback onRename,
  required final VoidCallback onToggle,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraPopupMenu(
      child: AuraIconButton(
        icon: Icons.more_vert,
        onPressed: onToggle,
        size: .small,
        tooltip: LocaleKeys.chats_screens_chat_conversation_options_tooltip
            .tr(),
      ),
      items: [
        _chatTilePinItem(chat, onTogglePin),
        ..._chatTileMenuItems(onRename: onRename, onDelete: onDelete),
      ],
      controller: controller,
    );
  }
}

AuraPopupMenuItem _chatTilePinItem(
  ConversationEntity chat,
  VoidCallback onTogglePin,
) => AuraPopupMenuItem(
  title: TextLocale(
    chat.isPinned
        ? LocaleKeys.chats_screens_chat_conversation_unpin
        : LocaleKeys.chats_screens_chat_conversation_pin,
  ),
  onTap: onTogglePin,
  leading: AuraIcon(chat.isPinned ? Icons.push_pin : Icons.push_pin_outlined),
);

List<AuraPopupMenuItem> _chatTileMenuItems({
  required VoidCallback onRename,
  required VoidCallback onDelete,
}) => [_chatTileRenameItem(onRename), _chatTileDeleteItem(onDelete)];

AuraPopupMenuItem _chatTileRenameItem(VoidCallback onRename) =>
    AuraPopupMenuItem(
      title: const TextLocale(
        LocaleKeys.chats_screens_chat_conversation_rename,
      ),
      onTap: onRename,
      leading: const AuraIcon(Icons.edit_outlined),
    );

AuraPopupMenuItem _chatTileDeleteItem(VoidCallback onDelete) =>
    AuraPopupMenuItem(
      title: const TextLocale(LocaleKeys.common_delete),
      onTap: onDelete,
      leading: const AuraIcon(Icons.delete_outline),
      variant: .error,
    );
