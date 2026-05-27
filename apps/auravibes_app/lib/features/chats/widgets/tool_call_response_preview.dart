// ignore_for_file: format-comment
// Required: Existing comments use generated or domain-specific formatting.
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
class ToolCallResponsePreview extends StatefulWidget {
  const ToolCallResponsePreview({
    required this.toolName,
    required this.content,
    super.key,
  });

  /// The name of the tool that generated the response.
  final String toolName;

  /// The raw response content to display.
  final String content;

  /// Maximum number of lines to show in the preview.
  static const int maxPreviewLines = 3;

  @override
  State<ToolCallResponsePreview> createState() =>
      _ToolCallResponsePreviewState();
}

class _ToolCallResponsePreviewState extends State<ToolCallResponsePreview> {
  bool _exceedsMaxLines = false;
  final GlobalKey _textKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Schedule measurement after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureTextOverflow();
    });
  }

  @override
  void didUpdateWidget(ToolCallResponsePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
      // Re-measure when content changes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _measureTextOverflow();
      });
    }
  }

  void _measureTextOverflow() {
    final context = _textKey.currentContext;
    if (context == null) return;

    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox) return;

    // Get the text painter to measure if text would overflow
    final textStyle = DefaultTextStyle.of(context).style;
    final textSpan = TextSpan(text: widget.content, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      maxLines: ToolCallResponsePreview.maxPreviewLines,
    )..layout(maxWidth: renderObject.constraints.maxWidth);

    final exceedsMaxLines = textPainter.didExceedMaxLines;
    if (exceedsMaxLines != _exceedsMaxLines) {
      setState(() {
        _exceedsMaxLines = exceedsMaxLines;
      });
    }
  }

  void _showFullContent() {
    ToolCallResponseModal.show(
      context,
      toolName: widget.toolName,
      content: widget.content,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Preview text with max 3 lines
        Text(
          widget.content,
          key: _textKey,
          style: TextStyle(
            color: context.auraColors.onSurface.withValues(alpha: 0.8),
            fontSize: 13,
            height: 1.4,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: ToolCallResponsePreview.maxPreviewLines,
        ),

        // Show more button (only if content exceeds max lines)
        if (_exceedsMaxLines)
          Padding(
            padding: EdgeInsets.only(top: context.auraTheme.spacing.xs),
            child: AuraButton(
              onPressed: _showFullContent,
              child: const AuraRow(
                children: [
                  TextLocale(LocaleKeys.common_show_more),
                  AuraIcon(
                    Icons.open_in_new,
                    size: AuraIconSize.small,
                    color: AuraColorVariant.primary,
                  ),
                ],
                spacing: AuraSpacing.xs,
                mainAxisSize: MainAxisSize.min,
              ),
              variant: AuraButtonVariant.ghost,
              size: AuraButtonSize.small,
            ),
          ),
      ],
    );
  }
}
