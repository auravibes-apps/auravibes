import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:material_ui/material_ui.dart';

abstract final class RenameConversationDialog {
  static Future<String?> show(BuildContext context, {required String title}) {
    return showDialog<String>(
      context: context,
      builder: (_) => _RenameConversationDialog(title: title),
    );
  }
}

class const _RenameConversationDialog({required final String title})
    extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController(text: title);
    final canSave = useState(controller.text.trim().isNotEmpty);

    return _RenameConversationDialogView(
      controller: controller,
      canSave: canSave,
      onSubmitted: (value) => _submit(context, value),
    );
  }

  void _submit(BuildContext context, String value) {
    final trimmedTitle = value.trim();
    if (trimmedTitle.isEmpty) return;

    Navigator.of(context).pop(trimmedTitle);
  }
}

class _RenameConversationDialogView extends StatelessWidget {
  const new({
    required this.controller,
    required this.canSave,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final ValueNotifier<bool> canSave;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(LocaleKeys.chats_screens_chat_conversation_rename_title.tr()),
    content: _RenameConversationField(
      controller: controller,
      canSave: canSave,
      onSubmitted: onSubmitted,
    ),
    actions: [
      const _RenameConversationCancelButton(),
      _RenameConversationSaveButton(
        controller: controller,
        canSave: canSave.value,
      ),
    ],
  );
}

class _RenameConversationField extends StatelessWidget {
  const new({
    required this.controller,
    required this.canSave,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final ValueNotifier<bool> canSave;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    decoration: .new(
      labelText: LocaleKeys.chats_screens_chat_conversation_rename_field_label
          .tr(),
    ),
    autofocus: true,
    onChanged: (value) => canSave.value = value.trim().isNotEmpty,
    onSubmitted: onSubmitted,
  );
}

class const _RenameConversationCancelButton() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => Navigator.of(context).pop(),
    child: const TextLocale(LocaleKeys.common_cancel),
  );
}

class _RenameConversationSaveButton extends StatelessWidget {
  const new({required this.controller, required this.canSave});

  final TextEditingController controller;
  final bool canSave;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: canSave
        ? () => Navigator.of(context).pop(controller.text.trim())
        : null,
    child: const TextLocale(LocaleKeys.common_save),
  );
}
