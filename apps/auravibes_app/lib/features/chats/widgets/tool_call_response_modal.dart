// Required: Existing thresholds and limits use numeric values.
// Required: Existing code repeats lookups where extraction adds noise.
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';

/// Modal dialog that displays tool call response content in markdown format.
///
/// Shows the full response content in a scrollable view with markdown
/// rendering. Used when tool call responses exceed the preview limit
/// in the chat view.
class const ToolCallResponseModal({
  /// The name of the tool that generated the response.
  required final String toolName,

  /// The markdown content to display.
  required final String content,
  super.key,
}) extends StatelessWidget {
  static const _dividerOpacity = 0.2;

  /// Shows the tool call response modal as a dialog.
  static Future<void> show(
    BuildContext context, {
    required String toolName,
    required String content,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) =>
          ToolCallResponseModal(toolName: toolName, content: content),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(context.auraTheme.fromBorderRadius(.xl)),
        ),
      ),
      child: Container(
        width: MediaQuery.sizeOf(context).width * 0.9,
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with tool name and close button.
            _ToolCallResponseModalHeader(toolName: toolName),

            // Scrollable markdown content.
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(context.auraTheme.fromSpacing(.md)),
                child: SizedBox(
                  width: double.infinity,
                  child: AuraText(child: GptMarkdown(content)),
                ),
              ),
            ),

            // Footer with close button.
            const _ToolCallResponseModalFooter(),
          ],
        ),
      ),
    );
  }
}

class const _ToolCallResponseModalHeader({required final String toolName})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.auraTheme.fromSpacing(.md)),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: context.auraColors.outline.withValues(
              alpha: ToolCallResponseModal._dividerOpacity,
            ),
          ),
        ),
      ),
      child: Row(
        children: [
          const AuraIcon(Icons.terminal, tint: AuraTint.primary),
          const AuraSizedBox(width: .sm),
          Expanded(
            child: AuraText(
              child: Text(toolName),
              style: AuraTextStyle.heading6,
            ),
          ),
          AuraIconButton(
            icon: Icons.close,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class const _ToolCallResponseModalFooter() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.auraTheme.fromSpacing(.md)),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: context.auraColors.outline.withValues(
              alpha: ToolCallResponseModal._dividerOpacity,
            ),
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: AuraButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const TextLocale(LocaleKeys.common_close),
          variant: AuraButtonVariant.outlined,
        ),
      ),
    );
  }
}
