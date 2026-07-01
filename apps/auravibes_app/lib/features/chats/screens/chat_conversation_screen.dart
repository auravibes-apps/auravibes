// Required: Existing test and UI helpers keep compact return flow.
// Required: UI callbacks stay local to their widgets.
// Required: Existing code repeats lookups where extraction adds noise.
// Required: Feature widgets keep closely related private widgets together.
// Required: Existing helpers remain top-level for local feature use.

import 'dart:async';

import 'package:auravibes_agent/auravibes_agent.dart'
    show AgentIterationContext, AgentIterationOrigin;
import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/exceptions/compaction_exception.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_result.dart';
import 'package:auravibes_app/features/chats/providers/compaction_execution.dart';
import 'package:auravibes_app/features/chats/providers/context_usage_level.dart';
import 'package:auravibes_app/features/chats/providers/conversation_streaming_runtime.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_app/features/chats/usecases/compact_conversation_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/conversation_busy_state.dart';
import 'package:auravibes_app/features/chats/usecases/send_message_usecase.dart';
import 'package:auravibes_app/features/chats/widgets/chat_input_widget.dart';
import 'package:auravibes_app/features/chats/widgets/chat_messages_widget.dart';
import 'package:auravibes_app/features/chats/widgets/chat_queued_messages_indicator.dart';
import 'package:auravibes_app/features/chats/widgets/chat_thinking_indicator.dart';
import 'package:auravibes_app/features/chats/widgets/chat_tool_approval_card.dart';
import 'package:auravibes_app/features/chats/widgets/conversation_context_usage_pill.dart';
import 'package:auravibes_app/features/models/widgets/compact_workspace_model_selector.dart';
import 'package:auravibes_app/features/skills/widgets/conversation_skill_selector_modal.dart';
import 'package:auravibes_app/features/tools/widgets/tools_management_modal.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/services/agent_harness/aura_agent_service.dart';
import 'package:auravibes_app/widgets/app_error_widget.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

final _logger = Logger('chat_conversation_screen');

class ChatConversationScreen extends ConsumerWidget {
  const ChatConversationScreen({
    required this.workspaceId,
    required this.chatId,
    super.key,
  });

  final String workspaceId;
  final String chatId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProviderScope(
      overrides: [conversationSelectedProvider.overrideWithValue(chatId)],
      child: _ChatConversationScreen(workspaceId: workspaceId),
    );
  }
}

@Dependencies([
  ConversationChatNotifier,
  chatMessages,
  contextUsage,
  conversationCompactionExecutionState,
  conversationBusyState,
  conversationQueuedDrafts,
  conversationSelected,
  messageConversationById,
  pendingToolCalls,
])
class _ChatConversationScreen extends HookConsumerWidget {
  const _ChatConversationScreen({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationAsync = ref.watch(conversationChatProvider(workspaceId));

    if (conversationAsync.isLoading && !conversationAsync.hasValue) {
      return const AuraScreen(
        child: Center(child: AuraSpinner()),
      );
    }

    if (conversationAsync.hasError && !conversationAsync.hasValue) {
      return AuraScreen(
        child: AppErrorWidget(
          error:
              conversationAsync.error ?? StateError('Conversation load failed'),
          stackTrace: conversationAsync.stackTrace ?? StackTrace.empty,
        ),
      );
    }

    final conversationResult = conversationAsync.value;
    if (conversationResult == null ||
        conversationResult is! ConversationFound) {
      final errorMessage = switch (conversationResult) {
        ConversationWorkspaceMismatch() =>
          LocaleKeys.chats_screens_chat_conversation_error_workspace_mismatch
              .tr(),
        ConversationNotFound() =>
          LocaleKeys.chats_screens_chat_conversation_error_not_found.tr(),
        _ => LocaleKeys.chats_screens_chat_conversation_error_not_found.tr(),
      };

      return AuraScreen(
        child: AppErrorWidget(
          error: errorMessage,
          stackTrace: StackTrace.empty,
        ),
      );
    }

    return _LoadedChatConversation(
      workspaceId: workspaceId,
      conversation: conversationResult.conversation,
    );
  }
}

@Dependencies([
  ConversationChatNotifier,
  chatMessages,
  contextUsage,
  conversationCompactionExecutionState,
  conversationBusyState,
  conversationQueuedDrafts,
  conversationSelected,
  messageConversationById,
  pendingToolCalls,
])
class _LoadedChatConversation extends HookConsumerWidget {
  const _LoadedChatConversation({
    required this.workspaceId,
    required this.conversation,
  });

  final String workspaceId;
  final ConversationEntity conversation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stopRequested = useState(false);

    final onToolsPress = useCallback(
      () {
        _showToolsModal(
          context: context,
          workspaceId: workspaceId,
          conversationId: conversation.id,
        );
      },
      [ref, workspaceId, conversation.id],
    );

    final onStop = useCallback(
      () {
        stopRequested.value = true;
        unawaited(_stopConversation(context, ref));
      },
      [ref, stopRequested],
    );

    final onSendMessage = useCallback<void Function(String)>(
      (message) {
        unawaited(_sendMessage(context, ref, message));
      },
      [ref],
    );

    final onCompact = useCallback(
      () {
        unawaited(_manualCompact(context, ref, conversation.id));
      },
      [ref, conversation.id],
    );

    final busyState = _conversationBusyStateValue(
      ref.watch(conversationBusyStateProvider),
    );
    final rateLimitRetryAt = ref.watch(
      conversationRateLimitRetryProvider.select(
        (retries) => retries[conversation.id],
      ),
    );
    final queuedDrafts = ref.watch(conversationQueuedDraftsProvider);
    final pendingCalls = ref.watch(pendingToolCallsProvider).value ?? const [];
    final hasPendingApprovals = pendingCalls.isNotEmpty;
    final compactionState = ref.watch(
      compactionExecutionStateProvider(conversation.id),
    );
    final isCompacting =
        compactionState?.status == CompactionExecutionStatus.running;
    final isInputBusy =
        (busyState?.isBusy ?? false) || rateLimitRetryAt != null;
    useEffect(
      () {
        stopRequested.value = false;

        return null;
      },
      [conversation.id],
    );
    useEffect(
      () {
        if (!isInputBusy) {
          stopRequested.value = false;
        }

        return null;
      },
      [conversation.id, isInputBusy],
    );
    final hidesStoppedRun = stopRequested.value && isInputBusy;

    return AuraScreen(
      child: AuraColumn(
        children: [
          const _ChatControlsBar(),
          Expanded(child: _ChatList(pendingToolCalls: pendingCalls)),
          if (busyState?.isStreaming == true && !hidesStoppedRun)
            const ChatThinkingIndicator(),
          if (rateLimitRetryAt != null && !hidesStoppedRun)
            _RateLimitRetryIndicator(retryAt: rateLimitRetryAt),
          if (queuedDrafts.isNotEmpty)
            ChatQueuedMessagesIndicator(queuedDrafts: queuedDrafts),
          if (hasPendingApprovals) const ChatToolApprovalCard(),
          Offstage(
            offstage: hasPendingApprovals,
            child: ChatInputWidget(
              onSendMessage: onSendMessage,
              onToolsPress: onToolsPress,
              modelControl: CompactWorkspaceModelSelector(
                workspaceId: workspaceId,
                workspaceModelSelectionId: conversation.modelId,
                onChanged: (modelId) {
                  unawaited(
                    ref
                        .read(conversationChatProvider(workspaceId).notifier)
                        .setModel(modelId),
                  );
                },
              ),
              onSkillsPress: () => _showSkillsModal(
                context: context,
                workspaceId: workspaceId,
                conversationId: conversation.id,
              ),
              onContinueAgent: isInputBusy
                  ? null
                  : () => unawaited(
                      _continueAgent(context, ref, conversation.id),
                    ),
              isBusy: isInputBusy,
              showStopButton: isInputBusy && !hidesStoppedRun,
              onStop: onStop,
              onCompact: onCompact,
              isCompacting: isCompacting,
            ),
          ),
        ],
      ),
      appBar: AuraAppBarWithDrawer(
        title: Text(conversation.title),
      ),
    );
  }
}

@Dependencies([contextUsage])
class _ChatControlsBar extends StatelessWidget {
  const _ChatControlsBar();

  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: auraColors.surfaceVariant,
        border: Border(
          bottom: BorderSide(color: auraColors.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(
            top: context.auraTheme.fromSpacing(.sm),
            right: context.auraTheme.fromSpacing(.sm),
          ),
          child: const Align(
            alignment: Alignment.centerRight,
            child: ConversationContextUsagePill(),
          ),
        ),
      ),
    );
  }
}

class _RateLimitRetryIndicator extends StatefulWidget {
  const _RateLimitRetryIndicator({required this.retryAt});

  final DateTime retryAt;

  @override
  State<_RateLimitRetryIndicator> createState() =>
      _RateLimitRetryIndicatorState();
}

class _RateLimitRetryIndicatorState extends State<_RateLimitRetryIndicator> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(_RateLimitRetryIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.retryAt == widget.retryAt) return;

    _timer?.cancel();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remainingSeconds = _remainingSeconds();

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: context.auraTheme.fromSpacing(.xs),
        horizontal: context.auraTheme.fromSpacing(.md),
      ),
      child: Row(
        children: [
          const AuraSpinner(size: AuraSpinnerSize.small),
          const AuraSizedBox(width: .sm),
          Flexible(
            child: AuraText(
              child: Text(
                LocaleKeys.chats_screens_chat_conversation_rate_limit_retry.tr(
                  namedArgs: {'seconds': remainingSeconds.toString()},
                ),
              ),
              style: AuraTextStyle.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        final _ = Object();
      });
    });
  }

  int _remainingSeconds() {
    final remaining = widget.retryAt.difference(DateTime.now());
    if (remaining <= Duration.zero) return 0;

    return remaining.inSeconds + 1;
  }
}

ConversationBusyState? _conversationBusyStateValue(
  AsyncValue<ConversationBusyState> state,
) {
  return switch (state) {
    AsyncData(:final value) => value,
    AsyncLoading(:final value?, hasValue: true) => value,
    _ => null,
  };
}

void _showSkillsModal({
  required BuildContext context,
  required String workspaceId,
  required String conversationId,
}) {
  if (!context.mounted) return;

  unawaited(
    showDialog<void>(
      context: context,
      builder: (context) => ConversationSkillSelectorModal(
        workspaceId: workspaceId,
        conversationId: conversationId,
      ),
    ),
  );
}

void _showToolsModal({
  required BuildContext context,
  required String workspaceId,
  required String conversationId,
}) {
  if (!context.mounted) return;

  unawaited(
    showDialog<void>(
      context: context,
      builder: (context) => ToolsManagementModal(
        workspaceId: workspaceId,
        conversationId: conversationId,
      ),
    ),
  );
}

@Dependencies([conversationBusyState])
Future<void> _continueAgent(
  BuildContext context,
  WidgetRef ref,
  String conversationId,
) async {
  final busyState = _conversationBusyStateValue(
    ref.read(conversationBusyStateProvider),
  );
  final rateLimitRetryAt = ref.read(
    conversationRateLimitRetryProvider,
  )[conversationId];
  if ((busyState?.isBusy ?? false) || rateLimitRetryAt != null) return;

  try {
    final _ = await ref
        .read(auraAgentServiceProvider)
        .agent
        .continueTurn(
          conversationId: conversationId,
          context: const AgentIterationContext(
            origin: AgentIterationOrigin.manualContinue,
          ),
        );
  } on Exception catch (error, stackTrace) {
    _logger.severe(
      'Failed to continue agent for conversation $conversationId',
      error,
      stackTrace,
    );
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'chat_conversation_screen',
        context: ErrorDescription('while manually continuing a conversation'),
      ),
    );
    if (!context.mounted) return;

    final _ = showAuraSnackBar(
      context: context,
      content: Text(
        LocaleKeys.chats_screens_chat_conversation_continue_error.tr(),
      ),
      variant: AuraSnackBarVariant.error,
    );
  }
}

@Dependencies([conversationSelected])
Future<void> _stopConversation(BuildContext context, WidgetRef ref) async {
  final conversationId = ref.read(conversationSelectedProvider);
  try {
    await ref
        .read(auraAgentServiceProvider)
        .agent
        .stop(
          conversationId: conversationId,
        );
  } catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'chat_conversation_screen',
        context: ErrorDescription('while stopping a conversation'),
      ),
    );
    if (!context.mounted) return;

    final _ = showAuraSnackBar(
      context: context,
      content: Text(
        LocaleKeys.chats_screens_chat_conversation_stop_error.tr(),
      ),
      variant: AuraSnackBarVariant.error,
    );
  }
}

@Dependencies([conversationSelected])
Future<void> _sendMessage(
  BuildContext context,
  WidgetRef ref,
  String message,
) async {
  final conversationId = ref.read(conversationSelectedProvider);
  try {
    await ref
        .read(sendMessageUsecaseProvider)
        .call(conversationId: conversationId, content: message);
  } on Exception catch (error, stackTrace) {
    _logger.severe(
      'Failed to send message for conversation $conversationId',
      error,
      stackTrace,
    );
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'chat_conversation_screen',
        context: ErrorDescription('while sending a message'),
      ),
    );
    if (!context.mounted) return;

    final _ = showAuraSnackBar(
      context: context,
      content: Text(
        LocaleKeys.chats_screens_chat_conversation_send_error.tr(),
      ),
      variant: AuraSnackBarVariant.error,
    );
  }
}

Future<void> _manualCompact(
  BuildContext context,
  WidgetRef ref,
  String conversationId,
) async {
  try {
    final _ = await ref.read(compactConversationUsecaseProvider)(
      conversationId: conversationId,
      trigger: CompactionTrigger.manual,
    );
    if (!context.mounted) return;

    final _ = showAuraSnackBar(
      context: context,
      content: Text(LocaleKeys.compaction_manual_success.tr()),
      variant: AuraSnackBarVariant.success,
    );
  } on CompactionException {
    if (!context.mounted) return;

    final _ = showAuraSnackBar(
      context: context,
      content: Text(LocaleKeys.compaction_manual_failure.tr()),
      variant: AuraSnackBarVariant.error,
    );
  }
}

@Dependencies([
  chatMessages,
  conversationCompactionExecutionState,
  messageConversationById,
])
class _ChatList extends ConsumerWidget {
  const _ChatList({required this.pendingToolCalls});

  final List<PendingToolCall> pendingToolCalls;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatMessages = ref.watch(chatMessagesProvider);
    final isLoading = chatMessages.isLoading && chatMessages.value == null;

    if (isLoading) {
      return const Center(child: AuraSpinner());
    }

    final asyncError = chatMessages.asError;
    if (asyncError != null) {
      return AppErrorWidget(
        error: asyncError.error,
        stackTrace: asyncError.stackTrace,
      );
    }

    final messages = chatMessages.value ?? const <MessageEntity>[];
    final messageIds = List<String>.unmodifiable(
      messages.map((message) => message.id),
    );
    final messageEntitiesById = {
      for (final message in messages) message.id: message,
    };

    return ChatMessagesWidget(
      messages: messageIds,
      messageEntitiesById: messageEntitiesById,
      pendingToolCalls: pendingToolCalls,
    );
  }
}
