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
  Widget build(BuildContext context) => Dialog(
    shape: _toolCallResponseDialogShape(context),
    child: _ToolCallResponseModalBody(toolName: toolName, content: content),
  );
}

ShapeBorder _toolCallResponseDialogShape(BuildContext context) =>
    RoundedRectangleBorder(
      borderRadius: BorderRadius.all(
        .circular(context.auraTheme.fromBorderRadius(.xl)),
      ),
    );

class const _ToolCallResponseModalBody({
  required final String toolName,
  required final String content,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Container(
      width: size.width * 0.9,
      constraints: .new(maxWidth: 600, maxHeight: size.height * 0.85),
      child: Column(
        mainAxisSize: .min,
        children: [
          _ToolCallResponseModalHeader(toolName: toolName),
          _ToolCallResponseModalMarkdown(content: content),
          const _ToolCallResponseModalFooter(),
        ],
      ),
    );
  }
}

class const _ToolCallResponseModalMarkdown({required final String content})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Flexible(
    child: SingleChildScrollView(
      padding: EdgeInsets.all(context.auraTheme.fromSpacing(.md)),
      child: SizedBox(
        width: .infinity,
        child: AuraText(child: GptMarkdown(content)),
      ),
    ),
  );
}

class const _ToolCallResponseModalHeader({required final String toolName})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(context.auraTheme.fromSpacing(.md)),
    decoration: _toolCallResponseHeaderDecoration(context),
    child: _ToolCallResponseModalHeaderRow(toolName: toolName),
  );
}

class const _ToolCallResponseModalHeaderRow({required final String toolName})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const AuraIcon(Icons.terminal, tint: .primary),
      const AuraSizedBox(width: .sm),
      Expanded(
        child: AuraText(child: Text(toolName), style: .heading6),
      ),
      AuraIconButton(
        icon: Icons.close,
        onPressed: () => Navigator.of(context).pop(),
      ),
    ],
  );
}

class const _ToolCallResponseModalFooter() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(context.auraTheme.fromSpacing(.md)),
    decoration: _toolCallResponseFooterDecoration(context),
    child: const _ToolCallResponseModalCloseButton(),
  );
}

class const _ToolCallResponseModalCloseButton() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    width: .infinity,
    child: AuraButton(
      onPressed: () => Navigator.of(context).pop(),
      child: const TextLocale(LocaleKeys.common_close),
      variant: .outlined,
    ),
  );
}

BoxDecoration _toolCallResponseHeaderDecoration(BuildContext context) =>
    BoxDecoration(
      border: Border(
        bottom: .new(
          color: context.auraColors.outline.withValues(
            alpha: ToolCallResponseModal._dividerOpacity,
          ),
        ),
      ),
    );

BoxDecoration _toolCallResponseFooterDecoration(BuildContext context) =>
    BoxDecoration(
      border: Border(
        top: .new(
          color: context.auraColors.outline.withValues(
            alpha: ToolCallResponseModal._dividerOpacity,
          ),
        ),
      ),
    );
