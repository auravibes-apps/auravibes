import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';

/// Modal dialog that displays tool call response content in markdown format.
///
/// Shows the full response content in a scrollable view with markdown
/// rendering. Used when tool call responses exceed the preview limit
/// in the chat view.
class ToolCallResponseModal extends StatelessWidget {
  const ToolCallResponseModal({
    required this.toolName,
    required this.content,
    super.key,
  });

  /// The name of the tool that generated the response.
  final String toolName;

  /// The markdown content to display.
  final String content;

  /// Shows the tool call response modal as a dialog.
  static Future<void> show(
    BuildContext context, {
    required String toolName,
    required String content,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => ToolCallResponseModal(
        toolName: toolName,
        content: content,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.auraTheme.borderRadius.xl),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with tool name and close button
            _buildHeader(context),

            // Scrollable markdown content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(context.auraTheme.spacing.md),
                child: SizedBox(
                  width: double.infinity,
                  child: AuraText(
                    child: GptMarkdown(
                      content,
                    ),
                  ),
                ),
              ),
            ),

            // Footer with close button
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.auraTheme.spacing.md),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: context.auraColors.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          AuraIcon(
            Icons.terminal,
            color: context.auraColors.primary,
          ),
          SizedBox(width: context.auraTheme.spacing.sm),
          Expanded(
            child: AuraText(
              style: AuraTextStyle.heading6,
              child: Text(toolName),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const AuraIcon(Icons.close),
            style: IconButton.styleFrom(
              foregroundColor: context.auraColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.auraTheme.spacing.md),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: context.auraColors.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: AuraButton(
          variant: AuraButtonVariant.outlined,
          onPressed: () => Navigator.of(context).pop(),
          child: const TextLocale(LocaleKeys.common_close),
        ),
      ),
    );
  }
}
