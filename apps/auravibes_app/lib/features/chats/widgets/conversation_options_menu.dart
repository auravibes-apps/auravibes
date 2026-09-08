import 'dart:async';

import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/providers/conversation_deletion_provider.dart';
import 'package:auravibes_app/features/chats/widgets/delete_conversation_confirm_dialog.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class const ConversationOptionsMenu({
  required final ConversationEntity conversation,
  super.key,
}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<ConversationOptionsMenu> createState() =>
      _ConversationOptionsMenuState();
}

class _ConversationOptionsMenuState
    extends ConsumerState<ConversationOptionsMenu> {
  final _controller = AuraPopupMenuController();

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuraPopupMenu(
      child: AuraIconButton(
        icon: Icons.more_vert,
        onPressed: _controller.toggle,
        size: AuraIconSize.small,
        tooltip: LocaleKeys.chats_screens_chat_conversation_options_tooltip
            .tr(),
      ),
      items: [
        AuraPopupMenuItem(
          title: const TextLocale(LocaleKeys.common_delete),
          onTap: () => unawaited(_delete(context)),
          leading: const AuraIcon(Icons.delete_outline),
          variant: AuraTileVariant.error,
        ),
      ],
      controller: _controller,
    );
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await DeleteConversationConfirmDialog.show(context);
    if (!confirmed) return;
    final delete = await ref.read(
      conversationDeletionProvider(widget.conversation.workspaceId).future,
    );
    await delete(widget.conversation);
  }
}
