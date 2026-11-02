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

    return _TaskBriefDialogLayout(
      controller: controller,
      canSave: canSave,
      hasBrief: taskBrief != null,
    );
  }
}

class const _TaskBriefDialogLayout({
  required final TextEditingController controller,
  required final ValueNotifier<bool> canSave,
  required final bool hasBrief,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      const _TaskBriefCancelButton(),
      if (hasBrief) const _TaskBriefClearButton(),
      _TaskBriefSaveButton(controller: controller, canSave: canSave.value),
    ];

    return AlertDialog(
      title: const TextLocale(
        LocaleKeys.chats_screens_chat_conversation_task_brief_title,
      ),
      content: _TaskBriefContent(controller: controller, canSave: canSave),
      actions: actions,
      scrollable: true,
    );
  }
}

class const _TaskBriefContent({
  required final TextEditingController controller,
  required final ValueNotifier<bool> canSave,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 560),
    child: _TaskBriefEditor(controller: controller, canSave: canSave),
  );
}

class const _TaskBriefEditor({
  required final TextEditingController controller,
  required final ValueNotifier<bool> canSave,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    crossAxisAlignment: .stretch,
    children: [
      const TextLocale(
        LocaleKeys.chats_screens_chat_conversation_task_brief_description,
      ),
      const SizedBox(height: 16),
      _TaskBriefField(controller: controller, canSave: canSave),
    ],
  );
}

class const _TaskBriefField({
  required final TextEditingController controller,
  required final ValueNotifier<bool> canSave,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    decoration: _taskBriefDecoration(context),
    textCapitalization: .sentences,
    autofocus: true,
    maxLines: 10,
    minLines: 5,
    onChanged: (value) => canSave.value = value.trim().isNotEmpty,
  );
}

InputDecoration _taskBriefDecoration(BuildContext context) => .new(
  labelText: LocaleKeys.chats_screens_chat_conversation_task_brief_field_label
      .tr(context: context),
  hintText: LocaleKeys.chats_screens_chat_conversation_task_brief_field_hint.tr(
    context: context,
  ),
  alignLabelWithHint: true,
);

class const _TaskBriefCancelButton() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => _cancel(context),
    child: const TextLocale(LocaleKeys.common_cancel),
  );
}

class const _TaskBriefClearButton() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => _clear(context),
    child: const TextLocale(
      LocaleKeys.chats_screens_chat_conversation_task_brief_clear,
    ),
  );
}

class const _TaskBriefSaveButton({
  required final TextEditingController controller,
  required final bool canSave,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: canSave ? () => _save(context, controller.text) : null,
    child: const TextLocale(LocaleKeys.common_save),
  );
}

void _cancel(BuildContext context) => Navigator.of(context).pop();

void _clear(BuildContext context) =>
    Navigator.of(context).pop((clear: true, value: null));

void _save(BuildContext context, String value) =>
    Navigator.of(context).pop((clear: false, value: value));
