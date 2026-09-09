import 'package:auravibes_app/features/markdown/widgets/markdown_editor_toolbar.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:textf/textf.dart';

const _minimumEditorLines = 12;
const _limitCounterHeight = 20.0;

class const MarkdownEditorScreen({
  required final String initialMarkdown,
  final int? maxCharacters,
  super.key,
}) extends StatefulWidget {
  @override
  State<MarkdownEditorScreen> createState() => _MarkdownEditorScreenState();
}

class _MarkdownEditorScreenState extends State<MarkdownEditorScreen> {
  final _controller = TextfEditingController();
  final _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialMarkdown;
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _MarkdownEditorView(
      controller: _controller,
      focusNode: _focusNode,
      isFocused: _isFocused,
      maxCharacters: widget.maxCharacters,
      onUnfocus: _unfocusInput,
      onCancel: () => _cancel(context),
      onSave: () => _save(context),
    );
  }

  void _cancel(BuildContext context) => Navigator.of(context).pop();

  void _save(BuildContext context) =>
      Navigator.of(context).pop(_controller.text);

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _unfocusInput() {
    FocusManager.instance.primaryFocus?.unfocus();
  }
}

class const _MarkdownEditorView({
  required final TextEditingController controller,
  required final FocusNode focusNode,
  required final bool isFocused,
  required final int? maxCharacters,
  required final VoidCallback onUnfocus,
  required final VoidCallback onCancel,
  required final VoidCallback onSave,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) {
    return AuraScreen(
      child: _MarkdownEditorBody(
        controller: controller,
        focusNode: focusNode,
        isFocused: isFocused,
      ),
      appBar: _MarkdownEditorAppBar(
        controller: controller,
        maxCharacters: maxCharacters,
        onUnfocus: onUnfocus,
        onCancel: onCancel,
        onSave: onSave,
      ),
    );
  }
}

class const _MarkdownEditorBody({
  required final TextEditingController controller,
  required final FocusNode focusNode,
  required final bool isFocused,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) {
    return TextFieldTapRegion(
      child: _MarkdownEditorSurface(
        controller: controller,
        focusNode: focusNode,
        isFocused: isFocused,
      ),
    );
  }
}

class const _MarkdownEditorSurface({
  required final TextEditingController controller,
  required final FocusNode focusNode,
  required final bool isFocused,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _MarkdownEditorSurfaceContainer(
    backgroundColor: _markdownBackgroundColor(context, isFocused),
    controller: controller,
    focusNode: focusNode,
    isFocused: isFocused,
  );
}

Color _markdownBackgroundColor(BuildContext context, bool isFocused) {
  final colors = context.auraColors;

  return isFocused ? colors.primary.withValues(alpha: 0.06) : colors.surface;
}

class const _MarkdownEditorSurfaceContainer({
  required final Color backgroundColor,
  required final TextEditingController controller,
  required final FocusNode focusNode,
  required final bool isFocused,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => Container(
    decoration: BoxDecoration(color: backgroundColor),
    child: _MarkdownEditorColumn(
      controller: controller,
      focusNode: focusNode,
      isFocused: isFocused,
    ),
  );
}

class const _MarkdownEditorColumn({
  required final TextEditingController controller,
  required final FocusNode focusNode,
  required final bool isFocused,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      _MarkdownEditorFocusIndicator(isFocused: isFocused),
      Expanded(
        child: _MarkdownEditorInput(
          controller: controller,
          focusNode: focusNode,
        ),
      ),
      _MarkdownEditorToolbar(controller: controller, focusNode: focusNode),
    ],
  );
}

class const _MarkdownEditorFocusIndicator({required final bool isFocused})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AnimatedContainer(
    color: isFocused
        ? context.auraColors.primary
        : context.auraColors.outlineVariant,
    height: 1,
    duration: const Duration(milliseconds: 150),
  );
}

class const _MarkdownEditorInput({
  required final TextEditingController controller,
  required final FocusNode focusNode,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GestureDetector(
    child: _MarkdownEditorInputList(
      controller: controller,
      focusNode: focusNode,
    ),
    onTap: focusNode.requestFocus,
    behavior: .translucent,
  );
}

class const _MarkdownEditorInputList({
  required final TextEditingController controller,
  required final FocusNode focusNode,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.symmetric(vertical: 12),
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: AuraColumn(
          children: [
            _MarkdownTextField(controller: controller, focusNode: focusNode),
          ],
          spacing: .md,
          crossAxisAlignment: .start,
        ),
      ),
    ],
  );
}

class const _MarkdownTextField({
  required final TextEditingController controller,
  required final FocusNode focusNode,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.auraColors;
    final textStyle = _markdownTextStyle(colors, context.auraTheme.typography);

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      decoration: _markdownInputDecoration(context, colors, textStyle),
      keyboardType: .multiline,
      style: textStyle,
      maxLines: null,
      minLines: _minimumEditorLines,
    );
  }
}

TextStyle _markdownTextStyle(
  AuraColorScheme colors,
  AuraTypographyScale typography,
) {
  return .new(
    color: colors.onSurface,
    fontSize: typography.fontSizeBase,
    fontWeight: typography.fontWeightRegular,
    height: typography.lineHeightBase,
    fontFamily: typography.bodyFontFamily,
  );
}

InputDecoration _markdownInputDecoration(
  BuildContext context,
  AuraColorScheme colors,
  TextStyle textStyle,
) {
  return .new(
    hintText: LocaleKeys.markdown_editor_editor_label.tr(context: context),
    hintStyle: textStyle.copyWith(
      color: colors.onSurfaceVariant.withValues(alpha: 0.6),
    ),
    contentPadding: EdgeInsets.zero,
    border: .none,
  );
}

class const _MarkdownEditorToolbar({
  required final TextEditingController controller,
  required final FocusNode focusNode,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        width: .infinity,
        child: MarkdownEditorToolbar(
          controller: controller,
          focusNode: focusNode,
        ),
      ),
    );
  }
}

class const _MarkdownEditorAppBar({
  required final TextEditingController controller,
  required final int? maxCharacters,
  required final VoidCallback onUnfocus,
  required final VoidCallback onCancel,
  required final VoidCallback onSave,
}) extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (maxCharacters == null ? 0 : _limitCounterHeight),
  );

  @override
  Widget build(BuildContext context) {
    return AuraAppBar(
      title: _MarkdownEditorTitle(onUnfocus: onUnfocus),
      actions: [
        _MarkdownSaveButton(
          controller: controller,
          maxCharacters: maxCharacters,
          onSave: onSave,
        ),
      ],
      bottom: _MarkdownOptionalLimitCounter(
        controller: controller,
        maxCharacters: maxCharacters,
        onTap: onUnfocus,
      ),
      leading: _MarkdownEditorCancelButton(onCancel: onCancel),
    );
  }
}

class const _MarkdownSaveButton({
  required final TextEditingController controller,
  required final int? maxCharacters,
  required final VoidCallback onSave,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => _MarkdownSaveListener(
    controller: controller,
    maxCharacters: maxCharacters,
    onSave: onSave,
  );
}

class const _MarkdownSaveListener({
  required final TextEditingController controller,
  required final int? maxCharacters,
  required final VoidCallback onSave,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => ValueListenableBuilder<TextEditingValue>(
    valueListenable: controller,
    builder: (_, value, _) => _MarkdownSaveIcon(
      disabled: _markdownIsOverLimit(value, maxCharacters),
      onSave: onSave,
    ),
  );
}

bool _markdownIsOverLimit(TextEditingValue value, int? maxCharacters) {
  if (maxCharacters == null) return false;

  return value.text.characters.length > maxCharacters;
}

class const _MarkdownEditorTitle({required final VoidCallback onUnfocus})
    extends StatelessWidget {
  @override
  Widget build(BuildContext _) {
    return GestureDetector(
      child: const TextLocale(LocaleKeys.markdown_editor_title),
      onTap: onUnfocus,
      behavior: .opaque,
    );
  }
}

class const _MarkdownEditorCancelButton({required final VoidCallback onCancel})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraIconButton(
      icon: Icons.close,
      onPressed: onCancel,
      tooltip: LocaleKeys.common_cancel.tr(context: context),
    );
  }
}

class const _MarkdownSaveIcon({
  required final bool disabled,
  required final VoidCallback onSave,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraIconButton(
      icon: Icons.save_outlined,
      onPressed: disabled ? null : onSave,
      tooltip: LocaleKeys.common_save.tr(context: context),
    );
  }
}

class const _MarkdownLimitCounter({
  required final TextEditingController controller,
  required final int maxCharacters,
  required final VoidCallback onTap,
}) extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(_limitCounterHeight);

  @override
  Widget build(BuildContext _) => GestureDetector(
    child: _MarkdownLimitValue(
      controller: controller,
      maxCharacters: maxCharacters,
    ),
    onTap: onTap,
    behavior: .opaque,
  );
}

class const _MarkdownOptionalLimitCounter({
  required final TextEditingController controller,
  required final int? maxCharacters,
  required final VoidCallback onTap,
}) extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => maxCharacters == null
      ? Size.zero
      : const Size.fromHeight(_limitCounterHeight);

  @override
  Widget build(BuildContext context) => maxCharacters == null
      ? const SizedBox.shrink()
      : _MarkdownLimitCounter(
          controller: controller,
          maxCharacters: maxCharacters ?? 0,
          onTap: onTap,
        );
}

class const _MarkdownLimitValue({
  required final TextEditingController controller,
  required final int maxCharacters,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => ValueListenableBuilder<TextEditingValue>(
    valueListenable: controller,
    builder: (context, value, _) => _MarkdownLimitText(
      characterCount: value.text.characters.length,
      maxCharacters: maxCharacters,
    ),
  );
}

class const _MarkdownLimitText({
  required final int characterCount,
  required final int maxCharacters,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) {
    return Center(
      child: AuraText(
        child: Text('$characterCount/$maxCharacters'),
        style: .caption,
        tint: characterCount > maxCharacters ? AuraTint.error : null,
      ),
    );
  }
}
