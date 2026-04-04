import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/enums/tool_grant_level.dart';
import 'package:auravibes_app/features/chats/providers/messages_providers.dart';
import 'package:auravibes_app/features/chats/usecases/handle_tool_approval_iteration_usecase.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Widget that shows confirmation buttons for a pending tool call.
///
/// Displays two rows of buttons:
/// - Row 1 (Allow options): "Allow Once" | "Allow for Conversation"
/// - Row 2 (Deny options): "Skip" | "Stop All"
class ToolCallConfirmationWidget extends ConsumerWidget {
  const ToolCallConfirmationWidget({
    required this.toolCall,
    required this.messageId,
    super.key,
  });

  final MessageToolCallEntity toolCall;
  final String messageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auraColors = context.auraColors;
    final spacing = context.auraTheme.spacing;

    return Container(
      padding: EdgeInsets.all(spacing.sm),
      decoration: BoxDecoration(
        color: auraColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(context.auraTheme.borderRadius.md),
        border: Border.all(
          color: auraColors.warning.withValues(alpha: 0.5),
        ),
      ),
      child: AuraColumn(
        spacing: AuraSpacing.sm,
        children: [
          // Row 1: Allow options
          AuraRow(
            children: [
              Expanded(
                child: AuraButton(
                  size: AuraButtonSize.small,
                  variant: AuraButtonVariant.outlined,
                  onPressed: () => _onAllowOnce(ref),
                  child: const TextLocale(
                    LocaleKeys.tool_confirmation_allow_once,
                  ),
                ),
              ),
              Expanded(
                child: AuraButton(
                  size: AuraButtonSize.small,
                  variant: AuraButtonVariant.outlined,
                  onPressed: () => _onAllowForConversation(ref),
                  child: const TextLocale(
                    LocaleKeys.tool_confirmation_allow_conversation,
                  ),
                ),
              ),
            ],
          ),
          // Row 2: Deny options
          AuraRow(
            children: [
              Expanded(
                child: AuraButton(
                  size: AuraButtonSize.small,
                  variant: AuraButtonVariant.outlined,
                  colorVariant: .primary,
                  onPressed: () => _onSkip(ref),
                  child: const TextLocale(LocaleKeys.tool_confirmation_skip),
                ),
              ),
              Expanded(
                child: AuraButton(
                  size: AuraButtonSize.small,
                  variant: AuraButtonVariant.outlined,
                  colorVariant: .error,
                  onPressed: () => _onStopAll(ref),
                  child: const TextLocale(
                    LocaleKeys.tool_confirmation_stop_all,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _onAllowOnce(WidgetRef ref) async {
    await ref
        .read(handleToolApprovalIterationUsecaseProvider)
        .approveToolCall(
          toolCallId: toolCall.id,
          messageId: messageId,
          level: ToolGrantLevel.once,
        );
    ref.invalidate(chatMessagesControllerProvider);
  }

  Future<void> _onAllowForConversation(WidgetRef ref) async {
    await ref
        .read(handleToolApprovalIterationUsecaseProvider)
        .approveToolCall(
          toolCallId: toolCall.id,
          messageId: messageId,
          level: ToolGrantLevel.conversation,
        );
    ref.invalidate(chatMessagesControllerProvider);
  }

  Future<void> _onSkip(WidgetRef ref) async {
    await ref
        .read(handleToolApprovalIterationUsecaseProvider)
        .skipToolCall(
          toolCallId: toolCall.id,
          messageId: messageId,
        );
    ref.invalidate(chatMessagesControllerProvider);
  }

  Future<void> _onStopAll(WidgetRef ref) async {
    await ref
        .read(handleToolApprovalIterationUsecaseProvider)
        .stopAllToolCalls(
          messageId: messageId,
        );
    ref.invalidate(chatMessagesControllerProvider);
  }
}
