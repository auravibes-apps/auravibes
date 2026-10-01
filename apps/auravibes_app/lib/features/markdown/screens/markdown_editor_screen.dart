import 'dart:async';

import 'package:auravibes_app/features/markdown/widgets/empty_markdown_preview.dart';
import 'package:auravibes_app/features/markdown/widgets/markdown_editor_toolbar.dart';
import 'package:auravibes_app/features/markdown/widgets/markdown_list_input_formatter.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/draft_exit_guard.dart';
import 'package:auravibes_app/widgets/draft_exit_scope.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_app/widgets/unsaved_changes_dialog.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:textf/textf.dart';

const _minimumEditorLines = 12;
const _limitCounterHeight = 20.0;

class const MarkdownEditorScreen({
  required final String initialMarkdown,
  final int? maxCharacters,
  final String? titleKey,
  final String? draftHintKey,
  super.key,
}) extends StatefulWidget {
  @override
  State<MarkdownEditorScreen> createState() => _MarkdownEditorScreenState();
}

class _MarkdownEditorScreenState extends State<MarkdownEditorScreen> {
  final _controller = TextfEditingController();
  final _focusNode = FocusNode();
  final _exitGuard = DraftExitGuard();
  TextEditingValue? _sourceValue;
  bool _isFocused = false;
  bool _isPreview = false;
  bool _allowPop = false;

  bool get _isDirty => _controller.text != widget.initialMarkdown;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialMarkdown;
    _controller.addListener(_onMarkdownChanged);
    _focusNode.addListener(_onFocusChange);
    _focusNode.onKeyEvent = _onEditorKey;
  }

  @override
  void dispose() {
    _controller.removeListener(_onMarkdownChanged);
    _focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _exitGuard.bind(
      isDirty: () => !_allowPop && _isDirty,
      isSaving: () => false,
      confirm: _confirmDiscard,
    );

    return DraftExitScope(
      guard: _exitGuard,
      child: _markdownEditorView(context),
    );
  }

  void _cancel(BuildContext context) => unawaited(_exitGuard.pop(context));

  void _apply(BuildContext context) {
    setState(() => _allowPop = true);
    unawaited(_exitGuard.pop(context, _controller.text));
  }

  void _onMarkdownChanged() {
    setState(() => _allowPop = false);
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _togglePreview() {
    final isPreview = !_isPreview;
    if (isPreview) {
      _enterPreview();
    } else {
      _leavePreview();
    }
    setState(() => _isPreview = isPreview);
    if (!isPreview) _restoreEditorFocus();
  }
}

extension on _MarkdownEditorScreenState {
  void _enterPreview() {
    _sourceValue = _controller.value;
    _focusNode.unfocus();
  }

  void _leavePreview() {
    final sourceValue = _sourceValue;
    if (sourceValue != null && _controller.value != sourceValue) {
      _controller.value = sourceValue;
    }
    _sourceValue = null;
  }

  void _restoreEditorFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  KeyEventResult _onEditorKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent || event.logicalKey != LogicalKeyboardKey.tab) {
      return .ignored;
    }

    final adjusted = MarkdownListInputFormatter.adjustIndentation(
      _controller.value,
      outdent: HardwareKeyboard.instance.isShiftPressed,
    );
    if (adjusted == null) return .ignored;

    _controller.value = adjusted;

    return .handled;
  }

  void _unfocusInput() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Widget _markdownEditorView(BuildContext context) => _MarkdownEditorView(
    controller: _controller,
    focusNode: _focusNode,
    isFocused: _isFocused,
    isPreview: _isPreview,
    titleKey: widget.titleKey ?? LocaleKeys.markdown_editor_title,
    draftHintKey: widget.draftHintKey ?? LocaleKeys.markdown_editor_draft_hint,
    maxCharacters: widget.maxCharacters,
    onTogglePreview: _togglePreview,
    onUnfocus: _unfocusInput,
    onCancel: () => _cancel(context),
    onSave: () => _apply(context),
  );

  Future<bool?> _confirmDiscard(BuildContext context) async {
    final shouldDiscard = await UnsavedChangesDialog.confirm(context);
    if (context.mounted && shouldDiscard != true && !_isPreview) {
      _restoreEditorFocus();
    }

    return shouldDiscard;
  }
}

class const _MarkdownEditorView({
  required final TextEditingController controller,
  required final FocusNode focusNode,
  required final bool isFocused,
  required final bool isPreview,
  required final String titleKey,
  required final String draftHintKey,
  required final int? maxCharacters,
  required final VoidCallback onTogglePreview,
  required final VoidCallback onUnfocus,
  required final VoidCallback onCancel,
  required final VoidCallback onSave,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => AuraScreen(
    child: Column(
      crossAxisAlignment: .stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: TextLocale(draftHintKey),
        ),
        Expanded(child: _MarkdownEditorBody(view: this)),
      ],
    ),
    appBar: _MarkdownEditorAppBar(view: this),
  );
}

class const _MarkdownEditorBody({required final _MarkdownEditorView view})
    extends StatelessWidget {
  @override
  Widget build(BuildContext _) => IndexedStack(
    index: view.isPreview ? 1 : 0,
    children: [
      TextFieldTapRegion(
        child: _MarkdownEditorSurface(
          controller: view.controller,
          focusNode: view.focusNode,
          isFocused: view.isFocused,
        ),
      ),
      _MarkdownEditorPreview(controller: view.controller),
    ],
  );
}

class const _MarkdownEditorPreview({
  required final TextEditingController controller,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final text = controller.text;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: text.trim().isEmpty
              ? const EmptyMarkdownPreview(
                  label: LocaleKeys.markdown_editor_empty,
                )
              : GptMarkdown(text),
        ),
      ],
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
      _MarkdownEditorInputContent(controller: controller, focusNode: focusNode),
    ],
  );
}

class const _MarkdownEditorInputContent({
  required final TextEditingController controller,
  required final FocusNode focusNode,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: AuraColumn(
      children: [
        _MarkdownTextField(controller: controller, focusNode: focusNode),
      ],
      spacing: .md,
      crossAxisAlignment: .start,
    ),
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
      inputFormatters: const [MarkdownListInputFormatter()],
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

class _MarkdownEditorAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  new({required _MarkdownEditorView view})
    : _maxCharacters = view.maxCharacters,
      _appBar = AuraAppBar(
        title: _MarkdownEditorTitle(
          onUnfocus: view.onUnfocus,
          titleKey: view.titleKey,
        ),
        actions: [
          _MarkdownPreviewToggle(
            isPreview: view.isPreview,
            onToggle: view.onTogglePreview,
          ),
          _MarkdownSaveButton(
            controller: view.controller,
            maxCharacters: view.maxCharacters,
            onSave: view.onSave,
          ),
        ],
        bottom: _MarkdownOptionalLimitCounter(
          controller: view.controller,
          maxCharacters: view.maxCharacters,
          onTap: view.onUnfocus,
        ),
        leading: _MarkdownEditorCancelButton(onCancel: view.onCancel),
      );

  final int? _maxCharacters;
  final AuraAppBar _appBar;

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (_maxCharacters == null ? 0 : _limitCounterHeight),
  );

  @override
  Widget build(BuildContext context) => _appBar;
}

class const _MarkdownPreviewToggle({
  required final bool isPreview,
  required final VoidCallback onToggle,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Semantics(
      child: ExcludeSemantics(
        child: AuraIconButton(
          icon: isPreview ? Icons.edit_outlined : Icons.visibility_outlined,
          onPressed: onToggle,
          tooltip: _markdownPreviewTooltip(context, isPreview),
        ),
      ),
      toggled: isPreview,
      button: true,
      label: _markdownPreviewLabel(context),
      onTap: onToggle,
    );
  }
}

String _markdownPreviewLabel(BuildContext context) =>
    LocaleKeys.markdown_editor_preview_label.tr(context: context);

String _markdownPreviewTooltip(BuildContext context, bool isPreview) =>
    (isPreview
            ? LocaleKeys.markdown_editor_editor_label
            : LocaleKeys.markdown_editor_preview_label)
        .tr(context: context);

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

class const _MarkdownEditorTitle({
  required final VoidCallback onUnfocus,
  required final String titleKey,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) {
    return GestureDetector(
      child: TextLocale(titleKey),
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
      tooltip: LocaleKeys.markdown_editor_apply.tr(context: context),
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
