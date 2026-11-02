import 'dart:async';

import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_result.dart';
import 'package:auravibes_app/features/chats/widgets/conversation_task_brief_dialog.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const ConversationTaskBriefButton({
  required final String workspaceId,
  required final ConversationEntity conversation,
  super.key,
}) extends ConsumerWidget {
  String get _tooltipKey => conversation.taskBrief == null
      ? LocaleKeys.chats_screens_chat_conversation_task_brief_add_tooltip
      : LocaleKeys.chats_screens_chat_conversation_task_brief_edit_tooltip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = _tooltipKey.tr(context: context);

    return AuraIconButton(
      icon: conversation.taskBrief == null
          ? Icons.edit_note_outlined
          : Icons.edit_note,
      onPressed: () => unawaited(_edit(context, ref)),
      identifier: 'conversation-task-brief-button',
      semanticLabel: label,
      tooltip: label,
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final result = await ConversationTaskBriefDialog.show(
      context,
      taskBrief: conversation.taskBrief,
    );
    if (!context.mounted || result == null) return;

    try {
      await _save(ref, result);
    } on Object {
      if (context.mounted) _showTaskBriefSaveError(context);
    }
  }

  Future<void> _save(WidgetRef ref, ConversationTaskBriefEditResult result) =>
      ref
          .read(conversationChatProvider(workspaceId, conversation.id).notifier)
          .setTaskBrief(result.clear ? null : result.value);
}

void _showTaskBriefSaveError(BuildContext context) {
  final _ = ScaffoldMessenger.of(context).showSnackBar(
    const .new(
      content: TextLocale(
        LocaleKeys.chats_screens_chat_conversation_task_brief_save_error,
      ),
    ),
  );
}
