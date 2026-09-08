// ignore_for_file: type=lint, type=warning
import 'package:auravibes_app/features/chats/notifiers/chat_a2ui_runtime.dart';
import 'package:auravibes_app/features/chats/widgets/chat_a2ui_historical_surface.dart';
import 'package:auravibes_app/features/chats/widgets/chat_a2ui_form_scope.dart';
import 'package:auravibes_app/features/chats/widgets/chat_a2ui_warning.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

class ChatA2uiSurfaceHost extends StatelessWidget {
  const new message({
    required this.runtime,
    required this.messageId,
    required this.payloads,
    this.issuesBySurface = const {},
    this.messageIssues = const [],
    this.interactive = true,
    super.key,
  }) : _historical = false;

  const new live({
    required this.runtime,
    required this.messageId,
    this.interactive = true,
    super.key,
  }) : payloads = const [],
       issuesBySurface = const {},
       messageIssues = const [],
       _historical = false;

  const new historical({
    required this.messageId,
    required this.payloads,
    super.key,
  }) : runtime = null,
       interactive = false,
       issuesBySurface = const {},
       messageIssues = const [],
       _historical = true;

  final ChatA2uiRuntime? runtime;
  final String messageId;
  final Iterable<String> payloads;
  final Map<String, List<String>> issuesBySurface;
  final List<String> messageIssues;
  final bool interactive;
  final bool _historical;

  @override
  Widget build(BuildContext context) {
    if (_historical) {
      return ChatA2uiHistoricalSurface(
        messageId: messageId,
        payloads: payloads,
      );
    }
    final currentRuntime = runtime;
    final currentMessageId = messageId;
    if (currentRuntime == null) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: currentRuntime,
      builder: (context, _) {
        final ids = currentRuntime
            .surfaceSlotsFor(currentMessageId)
            .toList(growable: false);
        final readyIds = ids
            .where((id) => currentRuntime.isReadySurface(currentMessageId, id))
            .toList(growable: false);
        final messageHasWarning = currentRuntime
            .a2uiMessageIssuesFor(currentMessageId)
            .isNotEmpty;
        if (ids.isEmpty) {
          if (issuesBySurface.isNotEmpty || messageIssues.isNotEmpty) {
            return AuraFlex.column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final entry in issuesBySurface.entries)
                  ChatA2uiWarning(
                    details: chatA2uiDiagnosticDetails(
                      conversationId: currentRuntime.conversationId,
                      messageId: currentMessageId,
                      surfaceId: '$currentMessageId:${entry.key}',
                      issues: entry.value,
                    ),
                    uiPayloads: payloads,
                  ),
                if (messageIssues.isNotEmpty)
                  ChatA2uiWarning(
                    details: chatA2uiDiagnosticDetails(
                      conversationId: currentRuntime.conversationId,
                      messageId: currentMessageId,
                      issues: messageIssues,
                    ),
                    uiPayloads: payloads,
                  ),
              ],
            );
          }
          if (messageHasWarning ||
              currentRuntime.hasSurfaceIssue(currentMessageId)) {
            return ChatA2uiWarning(
              details: chatA2uiDiagnosticDetails(
                conversationId: currentRuntime.conversationId,
                messageId: currentMessageId,
                issues: currentRuntime.a2uiMessageIssuesFor(currentMessageId),
              ),
              uiPayloads: currentRuntime.diagnosticPayloadsFor(
                currentMessageId,
              ),
            );
          }
          if (payloads.isEmpty) return const SizedBox.shrink();

          return ChatA2uiSurfaceHost.historical(
            key: ValueKey(currentMessageId),
            messageId: currentMessageId,
            payloads: payloads,
          );
        }
        if (readyIds.isEmpty &&
            !currentRuntime.hasSurfaceIssue(currentMessageId)) {
          return const SizedBox.shrink();
        }

        return AuraFlex.column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final id in ids) ...[
              if (readyIds.contains(id))
                AuraInteractionScope(
                  policy:
                      currentRuntime.isInteractiveSurface(
                            currentMessageId,
                            id,
                          ) &&
                          interactive
                      ? const AuraInteractionPolicy.interactive()
                      : const AuraInteractionPolicy.readOnly(),
                  child: ChatA2uiFormScope(
                    runtime: currentRuntime,
                    surfaceId: id,
                    child: TickerMode(
                      enabled: currentRuntime.isCurrentMessage(
                        currentMessageId,
                      ),
                      child: Surface(
                        key: ValueKey(id),
                        surfaceContext: currentRuntime.controller.contextFor(
                          id,
                        ),
                        actionDelegate: const ReadOnlyChatA2uiActionDelegate(),
                      ),
                    ),
                  ),
                ),
              if (currentRuntime.issuesForSurface(id).isNotEmpty)
                ChatA2uiWarning(
                  details: chatA2uiDiagnosticDetails(
                    conversationId: currentRuntime.conversationId,
                    messageId: currentMessageId,
                    surfaceId: id,
                    issues: currentRuntime
                        .issuesForSurface(id)
                        .map((issue) => issue.name),
                  ),
                  uiPayloads: currentRuntime.diagnosticPayloadsFor(
                    currentMessageId,
                  ),
                ),
              if (currentRuntime.hasSubmissionIssue(id))
                const ChatA2uiFormWarning(),
              if (readyIds.contains(id) &&
                  currentRuntime.isInteractiveSurface(currentMessageId, id) &&
                  interactive)
                AuraButton(
                  key: ValueKey('a2ui_submit_$id'),
                  isFullWidth: true,
                  onPressed: () => currentRuntime.submitForm(
                    id,
                    messageText: chatA2uiText(
                      context,
                      LocaleKeys.chats_screens_chat_conversation_form_submitted,
                      'Form answers submitted',
                    ),
                  ),
                  disabled: !currentRuntime.canSubmitForm(currentMessageId, id),
                  semanticLabel: chatA2uiText(
                    context,
                    LocaleKeys.chats_screens_chat_conversation_submit_answers,
                    'Submit answers',
                  ),
                  child: Text(
                    currentRuntime.formSubmitLabel(id) ??
                        chatA2uiText(
                          context,
                          LocaleKeys
                              .chats_screens_chat_conversation_submit_answers,
                          'Submit answers',
                        ),
                  ),
                ),
              if (readyIds.contains(id) &&
                  currentRuntime.isInteractiveSurface(currentMessageId, id) &&
                  interactive &&
                  currentRuntime.formResetLabel(id) != null)
                AuraButton(
                  key: ValueKey('a2ui_reset_$id'),
                  variant: AuraButtonVariant.outlined,
                  onPressed: () => currentRuntime.resetForm(id),
                  child: Text(currentRuntime.formResetLabel(id)!),
                ),
            ],
            if (messageHasWarning)
              ChatA2uiWarning(
                details: chatA2uiDiagnosticDetails(
                  conversationId: currentRuntime.conversationId,
                  messageId: currentMessageId,
                  issues: currentRuntime.a2uiMessageIssuesFor(currentMessageId),
                ),
                uiPayloads: currentRuntime.diagnosticPayloadsFor(
                  currentMessageId,
                ),
              ),
          ],
        );
      },
    );
  }
}
