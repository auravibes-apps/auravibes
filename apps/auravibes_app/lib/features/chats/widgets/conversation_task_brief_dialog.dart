import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:material_ui/material_ui.dart';

typedef ConversationTaskBriefEditResult = ({bool clear, String? value});

abstract final class ConversationTaskBriefDialog {
  static Future<ConversationTaskBriefEditResult?> show(
    BuildContext context, {
    required String? taskBrief,
  }) {
    FocusManager.instance.primaryFocus?.unfocus();

    return showDialog<ConversationTaskBriefEditResult>(
      context: context,
      builder: (_) => _ConversationTaskBriefDialog(taskBrief: taskBrief),
    );
  }
}

class const _ConversationTaskBriefDialog({required final String? taskBrief})
    extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController(text: taskBrief ?? '');
    final canSave = useState((taskBrief ?? '').trim().isNotEmpty);

    return AlertDialog(
      scrollable: true,
      title: const TextLocale(
        LocaleKeys.chats_screens_chat_conversation_task_brief_title,
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          children: [
            const TextLocale(
              LocaleKeys.chats_screens_chat_conversation_task_brief_description,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              minLines: 5,
              maxLines: 10,
              autofocus: true,
              textCapitalization: .sentences,
              decoration: InputDecoration(
                labelText: LocaleKeys
                    .chats_screens_chat_conversation_task_brief_field_label
                    .tr(context: context),
                hintText: LocaleKeys
                    .chats_screens_chat_conversation_task_brief_field_hint
                    .tr(context: context),
                alignLabelWithHint: true,
              ),
              onChanged: (value) => canSave.value = value.trim().isNotEmpty,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => _cancel(context),
          child: TextLocale(LocaleKeys.common_cancel),
        ),
        if (taskBrief != null)
          TextButton(
            onPressed: () => _clear(context),
            child: const TextLocale(
              LocaleKeys.chats_screens_chat_conversation_task_brief_clear,
            ),
          ),
        TextButton(
          onPressed: canSave.value
              ? () => _save(context, controller.text)
              : null,
          child: const TextLocale(LocaleKeys.common_save),
        ),
      ],
    );
  }
}

void _cancel(BuildContext context) => Navigator.of(context).pop();

void _clear(BuildContext context) =>
    Navigator.of(context).pop((clear: true, value: null));

void _save(BuildContext context, String value) =>
    Navigator.of(context).pop((clear: false, value: value));
