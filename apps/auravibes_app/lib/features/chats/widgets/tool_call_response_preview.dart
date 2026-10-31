// Required: Existing thresholds and limits use numeric values.
import 'dart:async';

import 'package:auravibes_app/features/chats/widgets/connector_write_result_notice.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// A preview widget for tool call responses that shows a collapsed view.
///
/// Displays up to 3 lines of the response text. If the content exceeds
/// 3 lines (considering line wraps), a "Show more" button appears that opens
/// the stored content in the sidebar.
class const ToolCallResponsePreview({
  /// The raw response content to display.
  required final String content,
  required final VoidCallback onShowMore,
  super.key,
  final bool showExpandButton = true,
  final String? inspectionStatus,
}) extends StatelessWidget {
  /// Maximum number of lines to show in the preview.
  static const int maxPreviewLines = 3;

  @override
  Widget build(BuildContext context) => _ToolCallResponsePreviewLayout(
    content: content,
    showExpandButton: showExpandButton,
    inspectionStatus: inspectionStatus,
    onShowMore: onShowMore,
  );
}

class const _ToolCallResponsePreviewLayout({
  required final String content,
  required final bool showExpandButton,
  required final String? inspectionStatus,
  required final VoidCallback onShowMore,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: _buildPreviewContent);

  Widget _buildPreviewContent(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    return _ToolCallResponsePreviewContent(
      content: content,
      hasOverflow: _toolCallResponsePreviewHasOverflow(
        context,
        constraints,
        content,
      ),
      showExpandButton: showExpandButton,
      inspectionStatus: inspectionStatus,
      textStyle: _toolCallResponsePreviewTextStyle(context),
      onShowMore: onShowMore,
    );
  }
}

bool _toolCallResponsePreviewHasOverflow(
  BuildContext context,
  BoxConstraints constraints,
  String content,
) {
  final textPainter = _toolCallResponsePreviewTextPainter(
    context,
    constraints,
    content,
  );
  final hasOverflow = textPainter.didExceedMaxLines;
  textPainter.dispose();

  return hasOverflow;
}

TextPainter _toolCallResponsePreviewTextPainter(
  BuildContext context,
  BoxConstraints constraints,
  String content,
) {
  final textStyle = _toolCallResponsePreviewTextStyle(context);

  return TextPainter(
    text: TextSpan(text: content, style: textStyle),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: ToolCallResponsePreview.maxPreviewLines,
  )..layout(maxWidth: constraints.maxWidth);
}

TextStyle _toolCallResponsePreviewTextStyle(BuildContext context) => .new(
  color: context.auraColors.onSurface.withValues(alpha: 0.8),
  fontSize: 13,
  height: 1.4,
);

class const _ToolCallResponsePreviewContent({
  required final String content,
  required final bool hasOverflow,
  required final bool showExpandButton,
  required final String? inspectionStatus,
  required final TextStyle textStyle,
  required final VoidCallback onShowMore,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .start,
    children: [
      ConnectorWriteResultNotice(content: content),
      _ToolCallResponsePreviewText(content: content, textStyle: textStyle),
      if (content.isNotEmpty ||
          (showExpandButton && (hasOverflow || inspectionStatus != null)))
        _ToolCallResponseActions(
          content: content,
          hasOverflow: hasOverflow,
          showExpandButton: showExpandButton,
          inspectionStatus: inspectionStatus,
          onShowMore: onShowMore,
        ),
    ],
  );
}

class const _ToolCallResponseActions({
  required final String content,
  required final bool hasOverflow,
  required final bool showExpandButton,
  required final String? inspectionStatus,
  required final VoidCallback onShowMore,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: context.auraTheme.fromSpacing(.xs),
    runSpacing: context.auraTheme.fromSpacing(.xs),
    children: [
      if (content.isNotEmpty) _ToolCallResponseCopyButton(content: content),
      if ((hasOverflow || inspectionStatus != null) && showExpandButton)
        _ToolCallResponseExpandButton(onShowMore: onShowMore),
    ],
  );
}

class const _ToolCallResponsePreviewText({
  required final String content,
  required final TextStyle textStyle,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      content,
      style: textStyle,
      overflow: .ellipsis,
      maxLines: ToolCallResponsePreview.maxPreviewLines,
    );
  }
}

class const _ToolCallResponseExpandButton({
  required final VoidCallback onShowMore,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: context.auraTheme.fromSpacing(.xs)),
    child: _ToolCallResponseExpandAction(onPressed: onShowMore),
  );
}

class const _ToolCallResponseExpandAction({
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: onPressed,
    child: const AuraRow(
      children: [
        TextLocale(LocaleKeys.common_show_more),
        AuraIcon(Icons.open_in_new, size: .small, tint: .primary),
      ],
      spacing: .xs,
      mainAxisSize: .min,
    ),
    variant: .ghost,
    size: .small,
  );
}

class const _ToolCallResponseCopyButton({required final String content})
    extends StatefulWidget {
  @override
  State<_ToolCallResponseCopyButton> createState() =>
      _ToolCallResponseCopyButtonState();
}

class _ToolCallResponseCopyButtonState
    extends State<_ToolCallResponseCopyButton> {
  var _copied = false;
  var _copyFailed = false;
  var _copyAttempt = 0;
  Timer? _copyConfirmationTimer;

  IconData get _copyIcon => _copied ? Icons.check : Icons.copy_outlined;

  String get _copyTooltip =>
      (_copied
              ? LocaleKeys.chats_screens_chat_conversation_tool_response_copied
              : LocaleKeys.chats_screens_chat_conversation_copy_tool_response)
          .tr();

  @override
  void didUpdateWidget(covariant _ToolCallResponseCopyButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content == widget.content) return;

    _copyAttempt++;
    _copyConfirmationTimer?.cancel();
    _copyConfirmationTimer = null;
    _copied = false;
    _copyFailed = false;
  }

  @override
  void dispose() {
    _copyAttempt++;
    _copyConfirmationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: context.auraTheme.fromSpacing(.xs)),
    child: Column(
      crossAxisAlignment: .start,
      mainAxisSize: .min,
      children: [
        AuraIconButton(
          icon: _copyIcon,
          onPressed: () => unawaited(_copyResponse()),
          size: .small,
          tooltip: _copyTooltip,
        ),
        if (_copyFailed)
          Padding(
            padding: EdgeInsets.only(top: context.auraTheme.fromSpacing(.xs)),
            child: Semantics(
              liveRegion: true,
              child: AuraText(
                child: const TextLocale(
                  'chats_screens_chat_conversation_tool_response_copy_failed',
                ),
                style: .bodySmall,
              ),
            ),
          ),
      ],
    ),
  );

  Future<void> _copyResponse() async {
    final content = widget.content;
    if (content.isEmpty) return;

    final attempt = ++_copyAttempt;
    _copyConfirmationTimer?.cancel();
    _copyConfirmationTimer = null;
    if (_copied || _copyFailed) {
      setState(() {
        _copied = false;
        _copyFailed = false;
      });
    }

    try {
      await Clipboard.setData(.new(text: content));
    } on Object {
      if (!mounted || attempt != _copyAttempt || widget.content != content) {
        return;
      }

      setState(() => _copyFailed = true);
      return;
    }

    if (!mounted || attempt != _copyAttempt || widget.content != content) {
      return;
    }

    setState(() => _copied = true);
    _copyConfirmationTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted || attempt != _copyAttempt || widget.content != content) {
        return;
      }

      setState(() => _copied = false);
    });
  }
}
