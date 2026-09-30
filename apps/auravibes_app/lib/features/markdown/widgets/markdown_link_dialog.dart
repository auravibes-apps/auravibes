import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';

abstract final class MarkdownLinkDialog {
  static Future<({String text, String destination})?> show(
    BuildContext context, {
    required String selectedText,
    required String selectedDestination,
  }) => showDialog<({String text, String destination})>(
    context: context,
    builder: (_) => _MarkdownLinkDialog(
      selectedText: selectedText,
      selectedDestination: selectedDestination,
    ),
  );
}

class _MarkdownLinkDialog extends StatefulWidget {
  const new({required this.selectedText, required this.selectedDestination});

  final String selectedText;
  final String selectedDestination;

  @override
  State<_MarkdownLinkDialog> createState() => _MarkdownLinkDialogState();
}

class _MarkdownLinkDialogState extends State<_MarkdownLinkDialog> {
  final _textController = TextEditingController();
  final _destinationController = TextEditingController();
  bool _showDestinationError = false;

  @override
  void initState() {
    super.initState();
    _textController.text = widget.selectedText;
    _destinationController.text = widget.selectedDestination;
  }

  @override
  void dispose() {
    _textController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const TextLocale(LocaleKeys.markdown_editor_link_dialog_title),
    content: Column(
      mainAxisSize: .min,
      children: [
        _LinkTextField(controller: _textController),
        _LinkDestinationField(
          controller: _destinationController,
          showError: _showDestinationError,
          onChanged: _onDestinationChanged,
          onSubmitted: _confirm,
        ),
      ],
    ),
    actions: [
      const _LinkCancelButton(),
      TextButton(
        onPressed: _confirm,
        child: const TextLocale(LocaleKeys.common_confirm),
      ),
    ],
  );

  void _onDestinationChanged(String _) {
    if (_showDestinationError) {
      setState(() => _showDestinationError = false);
    }
  }

  void _confirm() {
    final destination = _destinationController.text.trim();
    if (destination.isEmpty) {
      setState(() => _showDestinationError = true);

      return;
    }

    Navigator.of(context)
        .pop((text: _textController.text, destination: destination));
  }
}

class const _LinkTextField({required final TextEditingController controller})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    decoration: .new(
      labelText: LocaleKeys.markdown_editor_link_text_label.tr(
        context: context,
      ),
      hintText: LocaleKeys.markdown_editor_toolbar_link_text_placeholder.tr(
        context: context,
      ),
    ),
  );
}

class const _LinkDestinationField({
  required final TextEditingController controller,
  required final bool showError,
  required final ValueChanged<String> onChanged,
  required final VoidCallback onSubmitted,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    decoration: .new(
      labelText: LocaleKeys.markdown_editor_link_destination_label.tr(
        context: context,
      ),
      hintText: LocaleKeys.markdown_editor_toolbar_link_url_placeholder.tr(
        context: context,
      ),
      errorText: showError
          ? LocaleKeys.markdown_editor_link_destination_required.tr(
              context: context,
            )
          : null,
    ),
    keyboardType: .url,
    autofocus: true,
    onChanged: onChanged,
    onSubmitted: (_) => onSubmitted(),
  );
}

class const _LinkCancelButton() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => Navigator.of(context).pop(),
    child: const TextLocale(LocaleKeys.common_cancel),
  );
}
