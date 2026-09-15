// Required: Existing thresholds and limits use numeric values.
import 'package:auravibes_app/features/chats/widgets/tool_call_response_modal.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:material_ui/material_ui.dart';

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
}) extends StatelessWidget {
  /// Maximum number of lines to show in the preview.
  static const int maxPreviewLines = 3;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textStyle = _toolCallResponsePreviewTextStyle(context);
        final textPainter = TextPainter(
          text: TextSpan(text: content, style: textStyle),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: maxPreviewLines,
        )..layout(maxWidth: constraints.maxWidth);
        final hasOverflow = textPainter.didExceedMaxLines;
        textPainter.dispose();

        return Column(
          crossAxisAlignment: .start,
          children: [
            _ToolCallResponsePreviewText(
              content: content,
              textStyle: textStyle,
            ),
            if (hasOverflow && showExpandButton)
              _ToolCallResponseExpandButton(
                onPressed: () => ToolCallResponseModal.show(
                  context,
                  toolName: toolName,
                  content: content,
                ),
              ),
          ],
        );
      },
    );
  }
}

TextStyle _toolCallResponsePreviewTextStyle(BuildContext context) => .new(
  color: context.auraColors.onSurface.withValues(alpha: 0.8),
  fontSize: 13,
  height: 1.4,
);

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
