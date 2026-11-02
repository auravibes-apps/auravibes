import 'dart:async';

import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_result.dart';
import 'package:auravibes_app/features/chats/widgets/conversation_task_brief_dialog.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const ConversationTaskBriefButton({
  required final String workspaceId,
  required final ConversationEntity conversation,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = (conversation.taskBrief == null
            ? LocaleKeys
                  .chats_screens_chat_conversation_task_brief_add_tooltip
            : LocaleKeys
                  .chats_screens_chat_conversation_task_brief_edit_tooltip)
        .tr(context: context);

    return AuraIconButton(
      icon: conversation.taskBrief == null
          ? Icons.edit_note_outlined
          : Icons.edit_note,
      tooltip: label,
      semanticLabel: label,
      identifier: 'conversation-task-brief-button',
      onPressed: () => unawaited(_edit(context, ref)),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final result = await ConversationTaskBriefDialog.show(
      context,
      taskBrief: conversation.taskBrief,
    );
    if (!context.mounted || result == null) return;

    final notifier = ref.read(
      conversationChatProvider(workspaceId, conversation.id).notifier,
    );
    try {
      await notifier.setTaskBrief(result.clear ? null : result.value);
    } on Object {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocaleKeys.chats_screens_chat_conversation_task_brief_save_error
                .tr(context: context),
          ),
        ),
      );
    }
  }
}
