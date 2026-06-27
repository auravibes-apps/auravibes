import 'package:auravibes_app/features/markdown/widgets/markdown_editor_toolbar.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:textf/textf.dart';

class MarkdownEditorScreen extends StatefulWidget {
  const MarkdownEditorScreen({
    required this.initialMarkdown,
    this.maxCharacters,
    super.key,
  });

  final String initialMarkdown;
  final int? maxCharacters;

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
    final maxCharacters = widget.maxCharacters;
    final auraColors = context.auraColors;
    final editorBackgroundColor = _isFocused
        ? auraColors.primary.withValues(alpha: 0.06)
        : auraColors.surface;
    final typography = context.auraTheme.typography;

    return AuraScreen(
      child: TextFieldTapRegion(
        child: Container(
          decoration: BoxDecoration(
            color: editorBackgroundColor,
          ),
          child: Column(
            children: [
              AnimatedContainer(
                color: _isFocused
                    ? auraColors.primary
                    : auraColors.outlineVariant,
                height: 1,
                duration: const Duration(milliseconds: 150),
              ),
              Expanded(
                child: GestureDetector(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: AuraColumn(
                          children: [
                            TextFormField(
                              controller: _controller,
                              focusNode: _focusNode,
                              decoration: InputDecoration(
                                hintText: LocaleKeys
                                    .markdown_editor_editor_label
                                    .tr(
                                      context: context,
                                    ),
                                hintStyle: TextStyle(
                                  color: auraColors.onSurfaceVariant.withValues(
                                    alpha: 0.6,
                                  ),
                                  fontSize: typography.fontSizeBase,
                                  fontWeight: typography.fontWeightRegular,
                                  height: typography.lineHeightBase,
                                  fontFamily: typography.bodyFontFamily,
                                ),
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                              ),
                              keyboardType: TextInputType.multiline,
                              style: TextStyle(
                                color: auraColors.onSurface,
                                fontSize: typography.fontSizeBase,
                                fontWeight: typography.fontWeightRegular,
                                height: typography.lineHeightBase,
                                fontFamily: typography.bodyFontFamily,
                              ),
                              maxLines: null,
                              minLines: 12,
                            ),
                          ],
                          spacing: .md,
                          crossAxisAlignment: CrossAxisAlignment.start,
                        ),
                      ),
                    ],
                  ),
                  onTap: _focusInput,
                  behavior: HitTestBehavior.translucent,
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  width: double.infinity,
                  child: MarkdownEditorToolbar(
                    controller: _controller,
                    focusNode: _focusNode,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      appBar: AuraAppBar(
        title: GestureDetector(
          child: const TextLocale(LocaleKeys.markdown_editor_title),
          onTap: _unfocusInput,
          behavior: HitTestBehavior.opaque,
        ),
        actions: [
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, _) {
              final maxCharacters = widget.maxCharacters;
              final isOverLimit =
                  maxCharacters != null &&
                  value.text.characters.length > maxCharacters;

              return AuraIconButton(
                icon: Icons.save_outlined,
                onPressed: isOverLimit
                    ? null
                    : () => Navigator.of(context).pop(_controller.text),
                tooltip: LocaleKeys.common_save.tr(context: context),
              );
            },
          ),
        ],
        bottom: _buildLimitCounter(maxCharacters),
        leading: AuraIconButton(
          icon: Icons.close,
          onPressed: () => Navigator.of(context).pop(),
          tooltip: LocaleKeys.common_cancel.tr(context: context),
        ),
      ),
    );
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _focusInput() {
    _focusNode.requestFocus();
  }

  void _unfocusInput() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  PreferredSizeWidget? _buildLimitCounter(int? maxCharacters) {
    if (maxCharacters == null) return null;

    return PreferredSize(
      preferredSize: const Size.fromHeight(20),
      child: GestureDetector(
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (context, value, _) {
            final characterCount = value.text.characters.length;
            final isOverLimit = characterCount > maxCharacters;
            final tint = isOverLimit ? AuraTint.error : null;

            return Center(
              child: AuraText(
                child: Text('$characterCount/$maxCharacters'),
                style: AuraTextStyle.caption,
                tint: tint,
              ),
            );
          },
        ),
        onTap: _unfocusInput,
        behavior: HitTestBehavior.opaque,
      ),
    );
  }
}
