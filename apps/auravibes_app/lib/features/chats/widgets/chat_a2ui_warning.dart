// ignore_for_file: type=lint, type=warning
import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChatA2uiWarning extends StatefulWidget {
  const new({required this.details, this.uiPayloads = const [], super.key});

  final String details;
  final Iterable<String> uiPayloads;

  @override
  State<ChatA2uiWarning> createState() => _ChatA2uiWarningState();
}

class _ChatA2uiWarningState extends State<ChatA2uiWarning> {
  var _copied = false;

  @override
  Widget build(BuildContext context) {
    final text = chatA2uiText(
      context,
      LocaleKeys.chats_screens_chat_conversation_a2ui_unavailable,
      'This UI could not be loaded.',
    );

    return AuraContainer(
      margin: const AuraEdgeInsetsGeometry.symmetric(vertical: AuraSpacing.sm),
      padding: AuraEdgeInsetsGeometry.small,
      variant: AuraContainerVariant.surfaceVariant,
      semanticLabel: text,
      child: AuraFlex.row(
        children: [
          const ExcludeSemantics(
            child: AuraIcon(
              Icons.warning_amber_rounded,
              tint: AuraTint.warning,
            ),
          ),
          Expanded(
            child: AuraFlex.column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AuraText(child: Text(text), tint: AuraTint.warning),
                if (!kReleaseMode)
                  AuraText(
                    child: Text(widget.details),
                    style: AuraTextStyle.caption,
                  ),
              ],
            ),
          ),
          AuraIconButton(
            icon: _copied ? Icons.check : Icons.copy_outlined,
            onPressed: () => unawaited(_copyDetails()),
            tooltip: chatA2uiText(
              context,
              _copied
                  ? LocaleKeys
                        .chats_screens_chat_conversation_a2ui_diagnostic_copied
                  : LocaleKeys
                        .chats_screens_chat_conversation_copy_a2ui_diagnostic,
              _copied ? 'Diagnostic copied' : 'Copy diagnostic details',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyDetails() async {
    await Clipboard.setData(
      ClipboardData(
        text: _clipboardDiagnostic(widget.details, widget.uiPayloads),
      ),
    );
    if (mounted) setState(() => _copied = true);
  }
}

class ChatA2uiFormWarning extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final text = chatA2uiText(
      context,
      LocaleKeys.chats_screens_chat_conversation_a2ui_form_invalid,
      'Check your answers and try again.',
    );

    return AuraContainer(
      margin: const AuraEdgeInsetsGeometry.symmetric(vertical: AuraSpacing.sm),
      padding: AuraEdgeInsetsGeometry.small,
      variant: AuraContainerVariant.surfaceVariant,
      semanticLabel: text,
      child: AuraFlex.row(
        children: [
          const ExcludeSemantics(
            child: AuraIcon(Icons.info_outline, tint: AuraTint.warning),
          ),
          Expanded(
            child: AuraText(child: Text(text), tint: AuraTint.warning),
          ),
        ],
      ),
    );
  }
}

String chatA2uiDiagnosticDetails({
  required String messageId,
  required Iterable<String> issues,
  String? conversationId,
  String? surfaceId,
}) => [
  'A2UI diagnostic',
  if (conversationId != null) 'conversation: $conversationId',
  'message: $messageId',
  if (surfaceId != null) 'surface: $surfaceId',
  'issues: ${issues.toSet().join(', ')}',
].join('\n');

String chatA2uiText(BuildContext context, String key, String fallback) {
  try {
    return key.tr(context: context);
  } on Object catch (_) {
    return fallback;
  }
}

String _clipboardDiagnostic(String details, Iterable<String> uiPayloads) {
  if (kReleaseMode || uiPayloads.isEmpty) return details;
  const encoder = JsonEncoder.withIndent('  ');

  return [
    details,
    'UI structure:',
    for (final payload in uiPayloads) encoder.convert(jsonDecode(payload)),
  ].join('\n');
}
