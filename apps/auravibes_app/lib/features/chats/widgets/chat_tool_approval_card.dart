import 'dart:math' as math;

import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/enums/tool_grant_level.dart';
import 'package:auravibes_app/features/chats/notifiers/chat_messages_notifier.dart';
import 'package:auravibes_app/features/chats/providers/messages_providers.dart';
import 'package:auravibes_app/features/chats/providers/tool_display_name_provider.dart';
import 'package:auravibes_app/features/tools/usecases/approve_tool_call_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/skip_tool_call_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/stop_all_pending_tool_calls_usecase.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/utils/tool_name_formatter.dart';
import 'package:auravibes_app/utils/try_decode_tool_metadata.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ChatToolApprovalCard extends HookConsumerWidget {
  const ChatToolApprovalCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCalls = ref.watch(pendingToolCallsProvider);
    if (pendingCalls.isEmpty) return const SizedBox.shrink();

    final currentIndex = useState(0);
    final lastIndex = pendingCalls.length - 1;
    useEffect(
      () {
        if (currentIndex.value > lastIndex) {
          currentIndex.value = lastIndex;
        }
        return null;
      },
      [lastIndex],
    );

    final clamped = math.min(currentIndex.value, lastIndex);

    final item = pendingCalls[clamped];
    final total = pendingCalls.length;

    return _ApprovalCardContent(
      current: item,
      currentIndex: clamped,
      totalCount: total,
      hasPrev: clamped > 0,
      hasNext: clamped < total - 1,
      onPrev: () => currentIndex.value = clamped - 1,
      onNext: () => currentIndex.value = clamped + 1,
    );
  }
}

class _ApprovalCardContent extends ConsumerWidget {
  const _ApprovalCardContent({
    required this.current,
    required this.currentIndex,
    required this.totalCount,
    required this.hasPrev,
    required this.hasNext,
    required this.onPrev,
    required this.onNext,
  });

  final PendingToolCall current;
  final int currentIndex;
  final int totalCount;
  final bool hasPrev;
  final bool hasNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auraColors = context.auraColors;
    final spacing = context.auraTheme.spacing;
    final toolCall = current.toolCall;

    final displayNameAsync = ref.watch(
      toolDisplayNameProvider(toolCall.name),
    );
    final displayName = displayNameAsync.maybeWhen(
      data: (name) => name,
      orElse: () => ToolNameFormatter.formatDisplayName(
        ToolNameFormatter.parse(toolCall.name),
      ),
    );

    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(spacing.md),
      decoration: BoxDecoration(
        color: auraColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(
          context.auraTheme.borderRadius.lg,
        ),
        border: Border.all(
          color: auraColors.warning.withValues(alpha: 0.3),
        ),
      ),
      padding: EdgeInsets.all(spacing.md),
      child: AuraColumn(
        spacing: AuraSpacing.sm,
        children: [
          _NavigationHeader(
            currentIndex: currentIndex,
            totalCount: totalCount,
            hasPrev: hasPrev,
            hasNext: hasNext,
            onPrev: onPrev,
            onNext: onNext,
          ),
          _ToolCallInfo(
            displayName: displayName,
            argumentsRaw: toolCall.argumentsRaw,
          ),
          _ConfirmationButtons(
            toolCall: toolCall,
            messageId: current.messageId,
          ),
        ],
      ),
    );
  }
}

class _NavigationHeader extends StatelessWidget {
  const _NavigationHeader({
    required this.currentIndex,
    required this.totalCount,
    required this.hasPrev,
    required this.hasNext,
    required this.onPrev,
    required this.onNext,
  });

  final int currentIndex;
  final int totalCount;
  final bool hasPrev;
  final bool hasNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;

    return Row(
      children: [
        Icon(
          Icons.build_outlined,
          size: 16,
          color: auraColors.warning,
        ),
        SizedBox(width: context.auraTheme.spacing.xs),
        Expanded(
          child: Text(
            LocaleKeys.tool_approval_pending_count.tr(
              args: [(currentIndex + 1).toString(), totalCount.toString()],
            ),
            style: TextStyle(
              fontSize: DesignTypography.fontSizeSm,
              fontWeight: FontWeight.w600,
              color: auraColors.onSurface,
            ),
          ),
        ),
        _NavButton(
          icon: Icons.chevron_left,
          onPressed: hasPrev ? onPrev : null,
        ),
        SizedBox(width: context.auraTheme.spacing.xs),
        _NavButton(
          icon: Icons.chevron_right,
          onPressed: hasNext ? onNext : null,
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    final isEnabled = onPressed != null;

    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 18,
          color: isEnabled
              ? auraColors.onSurface
              : auraColors.onSurfaceVariant.withValues(alpha: 0.3),
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(
          minWidth: 32,
          minHeight: 32,
        ),
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}

class _ToolCallInfo extends StatelessWidget {
  const _ToolCallInfo({
    required this.displayName,
    required this.argumentsRaw,
  });

  final String displayName;
  final String argumentsRaw;

  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    final decodedArgs = tryDecodeToolMetadata(argumentsRaw);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.auraTheme.spacing.sm),
      decoration: BoxDecoration(
        color: auraColors.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(context.auraTheme.borderRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displayName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: DesignTypography.fontSizeSm,
              color: auraColors.onSurface,
            ),
          ),
          if (decodedArgs != null) ...[
            SizedBox(height: context.auraTheme.spacing.xs),
            Text(
              decodedArgs,
              style: TextStyle(
                fontSize: DesignTypography.fontSizeXs,
                color: auraColors.onSurfaceVariant,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _ConfirmationButtons extends ConsumerWidget {
  const _ConfirmationButtons({
    required this.toolCall,
    required this.messageId,
  });

  final MessageToolCallEntity toolCall;
  final String messageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuraColumn(
      spacing: AuraSpacing.sm,
      children: [
        AuraRow(
          children: [
            Expanded(
              child: AuraButton(
                size: AuraButtonSize.small,
                variant: AuraButtonVariant.outlined,
                onPressed: () => _onAllowOnce(ref, context),
                child: const TextLocale(
                  LocaleKeys.tool_confirmation_allow_once,
                ),
              ),
            ),
            Expanded(
              child: AuraButton(
                size: AuraButtonSize.small,
                variant: AuraButtonVariant.outlined,
                onPressed: () => _onAllowForConversation(ref, context),
                child: const TextLocale(
                  LocaleKeys.tool_confirmation_allow_conversation,
                ),
              ),
            ),
          ],
        ),
        AuraRow(
          children: [
            Expanded(
              child: AuraButton(
                size: AuraButtonSize.small,
                variant: AuraButtonVariant.outlined,
                colorVariant: .primary,
                onPressed: () => _onSkip(ref, context),
                child: const TextLocale(LocaleKeys.tool_confirmation_skip),
              ),
            ),
            Expanded(
              child: AuraButton(
                size: AuraButtonSize.small,
                variant: AuraButtonVariant.outlined,
                colorVariant: .error,
                onPressed: () => _onStopAll(ref, context),
                child: const TextLocale(
                  LocaleKeys.tool_confirmation_stop_all,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _onAllowOnce(WidgetRef ref, BuildContext context) async {
    await _runAction(
      ref,
      context,
      errorMessage: 'Failed to approve tool call.',
      action: () {
        return ref
            .read(approveToolCallUsecaseProvider)
            .call(
              toolCallId: toolCall.id,
              messageId: messageId,
              level: ToolGrantLevel.once,
            );
      },
    );
  }

  Future<void> _onAllowForConversation(
    WidgetRef ref,
    BuildContext context,
  ) async {
    await _runAction(
      ref,
      context,
      errorMessage: 'Failed to approve tool call for this conversation.',
      action: () {
        return ref
            .read(approveToolCallUsecaseProvider)
            .call(
              toolCallId: toolCall.id,
              messageId: messageId,
              level: ToolGrantLevel.conversation,
            );
      },
    );
  }

  Future<void> _onSkip(WidgetRef ref, BuildContext context) async {
    await _runAction(
      ref,
      context,
      errorMessage: 'Failed to skip tool call.',
      action: () {
        return ref
            .read(skipToolCallUsecaseProvider)
            .call(
              toolCallId: toolCall.id,
              messageId: messageId,
            );
      },
    );
  }

  Future<void> _onStopAll(WidgetRef ref, BuildContext context) async {
    await _runAction(
      ref,
      context,
      errorMessage: 'Failed to stop pending tool calls.',
      action: () {
        return ref
            .read(stopAllPendingToolCallsUsecaseProvider)
            .call(
              messageId: messageId,
            );
      },
    );
  }

  Future<void> _runAction(
    WidgetRef ref,
    BuildContext context, {
    required String errorMessage,
    required Future<void> Function() action,
  }) async {
    try {
      await action();
      ref.invalidate(chatMessagesProvider);
    } on Exception catch (error) {
      debugPrint('Tool approval action failed: $error');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$errorMessage $error')),
      );
    }
  }
}
