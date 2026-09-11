// Required: Existing thresholds and limits use numeric values.
import 'package:auravibes_app/features/chats/widgets/tool_call_response_modal.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';

/// A preview widget for tool call responses that shows a collapsed view.
///
/// Displays up to 3 lines of the response text. If the content exceeds
/// 3 lines (considering line wraps), a "Show more" button appears that
/// opens a modal with the full markdown-rendered content.
class const ToolCallResponsePreview({
  /// The name of the tool that generated the response.
  required final String toolName,

  /// The raw response content to display.
  required final String content,
  super.key,
  final bool showExpandButton = true,
}) extends StatefulWidget {
  /// Maximum number of lines to show in the preview.
  static const int maxPreviewLines = 3;

  @override
  State<ToolCallResponsePreview> createState() =>
      _ToolCallResponsePreviewState();
}

class _ToolCallResponsePreviewState extends State<ToolCallResponsePreview> {
  bool _exceedsMaxLines = false;
  final GlobalKey _textKey = .new();

  @override
  void initState() {
    super.initState();
    // Schedule measurement after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureTextOverflow();
    });
  }

  @override
  void didUpdateWidget(ToolCallResponsePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
      // Re-measure when content changes.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _measureTextOverflow();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        _ToolCallResponsePreviewText(
          content: widget.content,
          textKey: _textKey,
        ),
        if (_exceedsMaxLines && widget.showExpandButton)
          _ToolCallResponseExpandButton(onPressed: _showFullContent),
      ],
    );
  }

  void _measureTextOverflow() {
    final exceedsMaxLines = _textOverflow();
    if (exceedsMaxLines == null || exceedsMaxLines == _exceedsMaxLines) {
      return;
    }

    setState(() {
      _exceedsMaxLines = exceedsMaxLines;
    });
  }

  bool? _textOverflow() {
    final context = _textKey.currentContext;
    if (context == null) return null;

    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox) return null;

    return _doesTextOverflow(context, renderObject);
  }

  bool _doesTextOverflow(BuildContext context, RenderBox renderObject) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: widget.content,
        style: DefaultTextStyle.of(context).style,
      ),
      textDirection: .ltr,
      maxLines: ToolCallResponsePreview.maxPreviewLines,
    )..layout(maxWidth: renderObject.constraints.maxWidth);

    return textPainter.didExceedMaxLines;
  }

  void _showFullContent() {
    ToolCallResponseModal.show(
      context,
      toolName: widget.toolName,
      content: widget.content,
    );
  }
}

class const _ToolCallResponsePreviewText({
  required final String content,
  required final GlobalKey textKey,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      content,
      key: textKey,
      style: .new(
        color: context.auraColors.onSurface.withValues(alpha: 0.8),
        fontSize: 13,
        height: 1.4,
      ),
      overflow: .ellipsis,
      maxLines: ToolCallResponsePreview.maxPreviewLines,
    );
  }
}

class const _ToolCallResponseExpandButton({
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: context.auraTheme.fromSpacing(.xs)),
    child: _ToolCallResponseExpandAction(onPressed: onPressed),
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
