// Required: Existing test and UI helpers keep compact return flow.
// Required: UI callbacks stay local to their widgets.
// Required: Existing code repeats lookups where extraction adds noise.
// Required: Feature widgets keep closely related private widgets together.
// Required: Existing helpers remain top-level for local feature use.

import 'dart:async';

import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/exceptions/compaction_exception.dart';
import 'package:auravibes_app/features/agents/widgets/compact_agent_selector.dart';
import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/chats/models/cloud_conversation_state.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_queued_draft.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_result.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/providers/aura_agent_service_provider.dart';
import 'package:auravibes_app/features/chats/providers/cloud_conversation_stream.dart';
import 'package:auravibes_app/features/chats/providers/cloud_turn_provider.dart';
import 'package:auravibes_app/features/chats/providers/compaction_execution.dart';
import 'package:auravibes_app/features/chats/providers/conversation_streaming_runtime.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_app/features/chats/services/chat_attachment_modality.dart';
import 'package:auravibes_app/features/chats/usecases/compact_conversation_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/conversation_busy_state.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_turn_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/send_message_usecase.dart';
import 'package:auravibes_app/features/chats/widgets/chat_input_widget.dart';
import 'package:auravibes_app/features/chats/widgets/chat_messages_widget.dart';
import 'package:auravibes_app/features/chats/widgets/chat_queued_messages_indicator.dart';
import 'package:auravibes_app/features/chats/widgets/chat_tool_approval_card.dart';
import 'package:auravibes_app/features/chats/widgets/conversation_context_usage_pill.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selection_providers.dart';
import 'package:auravibes_app/features/models/widgets/compact_workspace_model_selector.dart';
import 'package:auravibes_app/features/skills/widgets/conversation_skill_selector_modal.dart';
import 'package:auravibes_app/features/tools/widgets/tools_management_modal.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/app_error_widget.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_engine/auravibes_engine.dart'
    show AgentIterationContext;
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';

final _logger = Logger('chat_conversation_screen');

class const ChatConversationScreen({
  required final String workspaceId,
  required final String chatId,
  super.key,
  final bool showInputComposer = true,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ChatConversationScreen(
      workspaceId: workspaceId,
      chatId: chatId,
      showInputComposer: showInputComposer,
    );
  }
}

class const _ChatConversationScreen({
  required final String workspaceId,
  required final String chatId,
  required final bool showInputComposer,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationAsync = ref.watch(
      conversationChatProvider(workspaceId, chatId),
    );

    if (conversationAsync.isLoading && !conversationAsync.hasValue) {
      return const AuraScreen(child: Center(child: AuraSpinner()));
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
        null || ConversationFound() =>
          LocaleKeys.chats_screens_chat_conversation_error_not_found.tr(),
      };

      return AuraScreen(
        child: AppErrorWidget(error: errorMessage, stackTrace: .empty),
      );
    }

    return _LoadedChatConversation(
      workspaceId: workspaceId,
      conversation: conversationResult.conversation,
      showInputComposer: showInputComposer,
    );
  }
}

class const _LoadedChatConversation({
  required final String workspaceId,
  required final ConversationEntity conversation,
  required final bool showInputComposer,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stopRequested = useState(false);

    void onToolsPressCallback() {
      _showToolsModal(
        context: context,
        workspaceId: workspaceId,
        conversationId: conversation.id,
      );
    }

    final onToolsPress = useCallback(onToolsPressCallback, [
      ref,
      workspaceId,
      conversation.id,
    ]);

    void onStopCallback() {
      stopRequested.value = true;
      unawaited(_stopConversation(context, ref, workspaceId, conversation.id));
    }

    final onStop = useCallback(onStopCallback, [ref, stopRequested]);

    final onSendMessage = useCallback<Future<void> Function(ChatDraft)>(
      (draft) =>
          _sendMessage(context, ref, workspaceId, conversation.id, draft),
      [ref],
    );

    void onCompactCallback() {
      unawaited(_manualCompact(context, ref, workspaceId, conversation.id));
    }

    final onCompact = useCallback(onCompactCallback, [ref, conversation.id]);

    final isCloud = _isCloudWorkspace(ref, workspaceId);
    final cloudConversation = _watchCloudConversation(
      ref,
      isCloud: isCloud,
      workspaceId: workspaceId,
      conversationId: conversation.id,
    );
    final busyState = _conversationBusyStateValue(
      ref.watch(conversationBusyStateProvider(workspaceId, conversation.id)),
    );
    final rateLimitRetryAt = ref.watch(
      conversationRateLimitRetryProvider.select(
        (retries) => retries[conversation.id],
      ),
    );
    final queuedDrafts = ref.watch(
      conversationQueuedDraftsProvider(workspaceId, conversation.id),
    );
    final selectedModelId = conversation.modelId;
    final modalitiesInput = _watchModelModalities(
      ref,
      workspaceId: workspaceId,
      modelId: selectedModelId,
    );
    final pendingCalls = _watchPendingCalls(
      ref,
      isCloud: isCloud,
      cloudConversation: cloudConversation,
      workspaceId: workspaceId,
      conversationId: conversation.id,
    );
    final hasPendingApprovals = pendingCalls.isNotEmpty;
    final compactionState = ref.watch(
      compactionExecutionStateProvider(conversation.id),
    );
    final isCompacting =
        compactionState?.status == CompactionExecutionStatus.running;
    final isInputBusy = _isInputBusy(
      isCloud: isCloud,
      cloudConversation: cloudConversation,
      busyState: busyState,
      rateLimitRetryAt: rateLimitRetryAt,
    );
    final isGenerating = _isGenerating(
      isCloud: isCloud,
      cloudConversation: cloudConversation,
      busyState: busyState,
    );
    Dispose? resetStopRequested() {
      stopRequested.value = false;

      return null;
    }

    useEffect(resetStopRequested, [conversation.id]);
    Dispose? resetStopRequestedWhenIdle() {
      if (!isInputBusy) {
        stopRequested.value = false;
      }

      return null;
    }

    useEffect(resetStopRequestedWhenIdle, [conversation.id, isInputBusy]);
    final hidesStoppedRun = stopRequested.value && isInputBusy;

    return _LoadedChatConversationView(
      workspaceId: workspaceId,
      conversation: conversation,
      pendingCalls: pendingCalls,
      isGenerating: isGenerating,
      hidesStoppedRun: hidesStoppedRun,
      rateLimitRetryAt: rateLimitRetryAt,
      queuedDrafts: queuedDrafts,
      hasPendingApprovals: hasPendingApprovals,
      showInputComposer: showInputComposer,
      modalitiesInput: modalitiesInput,
      isInputBusy: isInputBusy,
      isCompacting: isCompacting,
      onSendMessage: onSendMessage,
      onToolsPress: onToolsPress,
      onStop: onStop,
      onCompact: onCompact,
      onModelChanged: (modelId) =>
          _onModelChanged(context, ref, workspaceId, conversation.id, modelId),
      onModelSelectionChanged: (modelId) =>
          _onModelSelectionChanged(ref, workspaceId, conversation.id, modelId),
      onAgentChanged: (agentId) =>
          _onAgentChanged(ref, workspaceId, conversation.id, agentId),
      onSkillsPress: () => _showSkillsModal(
        context: context,
        workspaceId: workspaceId,
        conversationId: conversation.id,
      ),
      onContinueAgent: _continueAgentCallback(
        context: context,
        ref: ref,
        workspaceId: workspaceId,
        conversationId: conversation.id,
        isInputBusy: isInputBusy,
      ),
      leading: _leading(context),
    );
  }

  void _onModelChanged(
    BuildContext context,
    WidgetRef ref,
    String workspaceId,
    String conversationId,
    String? modelId,
  ) {
    unawaited(
      _setModelWithAttachmentWarning(
        context: context,
        ref: ref,
        workspaceId: workspaceId,
        conversationId: conversationId,
        modelId: modelId,
      ),
    );
  }

  void _onModelSelectionChanged(
    WidgetRef ref,
    String workspaceId,
    String conversationId,
    String? modelId,
  ) {
    unawaited(
      ref
          .read(conversationChatProvider(workspaceId, conversationId).notifier)
          .setModel(modelId),
    );
  }

  void _onAgentChanged(
    WidgetRef ref,
    String workspaceId,
    String conversationId,
    String? agentId,
  ) {
    unawaited(
      ref
          .read(conversationChatProvider(workspaceId, conversationId).notifier)
          .setAgent(agentId),
    );
  }

  Widget? _leading(BuildContext context) {
    if (showInputComposer) return null;

    return AuraIconButton(
      icon: Icons.arrow_back,
      onPressed: () => Navigator.of(context).pop(),
    );
  }
}

bool _isCloudWorkspace(WidgetRef ref, String workspaceId) =>
    ref.watch(workspaceSessionForRouteProvider(workspaceId)).value?.cloud !=
    null;

CloudConversationState? _watchCloudConversation(
  WidgetRef ref, {
  required bool isCloud,
  required String workspaceId,
  required String conversationId,
}) {
  if (!isCloud) return null;
  return ref
      .watch(
        cloudConversationStateProvider((
          workspaceId: workspaceId,
          conversationId: conversationId,
        )),
      )
      .value;
}

List<String> _watchModelModalities(
  WidgetRef ref, {
  required String workspaceId,
  required String? modelId,
}) {
  if (modelId == null) return const [];
  final selectedModelAsync = ref.watch(
    workspaceModelSelectionByIdProvider(workspaceId, modelId),
  );
  return selectedModelAsync.value?.workspaceModelSelection.modalitiesInput ??
      const <String>[];
}

List<PendingToolCall> _watchPendingCalls(
  WidgetRef ref, {
  required bool isCloud,
  required CloudConversationState? cloudConversation,
  required String workspaceId,
  required String conversationId,
}) {
  if (isCloud) return CloudMessageTools.pendingToolCalls(cloudConversation);
  return ref
          .watch(pendingToolCallsProvider(workspaceId, conversationId))
          .value ??
      const [];
}

bool _isInputBusy({
  required bool isCloud,
  required CloudConversationState? cloudConversation,
  required ConversationBusyState? busyState,
  required DateTime? rateLimitRetryAt,
}) {
  if (rateLimitRetryAt != null) return true;
  if (isCloud) return _isCloudInputBusy(cloudConversation);
  return busyState?.isBusy ?? false;
}

bool _isCloudInputBusy(CloudConversationState? state) {
  final executionState = state?.conversation.executionState;
  return executionState == 'running' || executionState == 'awaitingApproval';
}

bool _isGenerating({
  required bool isCloud,
  required CloudConversationState? cloudConversation,
  required ConversationBusyState? busyState,
}) {
  if (isCloud) {
    return cloudConversation?.conversation.executionState == 'running';
  }
  return busyState?.isStreaming == true;
}

VoidCallback? _continueAgentCallback({
  required BuildContext context,
  required WidgetRef ref,
  required String workspaceId,
  required String conversationId,
  required bool isInputBusy,
}) {
  if (isInputBusy) return null;
  return () =>
      unawaited(_continueAgent(context, ref, workspaceId, conversationId));
}

class const _LoadedChatConversationView({
  required final String workspaceId,
  required final ConversationEntity conversation,
  required final List<PendingToolCall> pendingCalls,
  required final bool isGenerating,
  required final bool hidesStoppedRun,
  required final DateTime? rateLimitRetryAt,
  required final List<ConversationQueuedDraft> queuedDrafts,
  required final bool hasPendingApprovals,
  required final bool showInputComposer,
  required final List<String> modalitiesInput,
  required final bool isInputBusy,
  required final bool isCompacting,
  required final Future<void> Function(ChatDraft) onSendMessage,
  required final VoidCallback onToolsPress,
  required final VoidCallback onStop,
  required final VoidCallback onCompact,
  required final ValueChanged<String?> onModelChanged,
  required final ValueChanged<String?> onModelSelectionChanged,
  required final ValueChanged<String?> onAgentChanged,
  required final VoidCallback onSkillsPress,
  required final VoidCallback? onContinueAgent,
  required final Widget? leading,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final conversationId = conversation.id;
    final retryAt = rateLimitRetryAt;
    return AuraScreen(
      child: AuraColumn(
        children: [
          _ChatControlsBar(
            workspaceId: workspaceId,
            conversationId: conversationId,
          ),
          Expanded(
            child: _ChatList(
              workspaceId: workspaceId,
              conversationId: conversationId,
              pendingToolCalls: pendingCalls,
              showThinking: isGenerating && !hidesStoppedRun,
            ),
          ),
          if (retryAt != null && !hidesStoppedRun)
            _RateLimitRetryIndicator(retryAt: retryAt),
          if (queuedDrafts.isNotEmpty)
            ChatQueuedMessagesIndicator(
              conversationId: conversationId,
              queuedDrafts: queuedDrafts,
            ),
          if (hasPendingApprovals)
            ChatToolApprovalCard(
              workspaceId: workspaceId,
              conversationId: conversationId,
              pendingCalls: pendingCalls,
            ),
          if (showInputComposer)
            _ChatComposer(
              workspaceId: workspaceId,
              conversation: conversation,
              modalitiesInput: modalitiesInput,
              isInputBusy: isInputBusy,
              hasPendingApprovals: hasPendingApprovals,
              isCompacting: isCompacting,
              hidesStoppedRun: hidesStoppedRun,
              onSendMessage: onSendMessage,
              onToolsPress: onToolsPress,
              onStop: onStop,
              onCompact: onCompact,
              onModelChanged: onModelChanged,
              onModelSelectionChanged: onModelSelectionChanged,
              onAgentChanged: onAgentChanged,
              onSkillsPress: onSkillsPress,
              onContinueAgent: onContinueAgent,
            ),
        ],
      ),
      appBar: AuraAppBarWithDrawer(
        title: Text(conversation.title),
        leading: leading,
      ),
    );
  }
}

class const _ChatComposer({
  required final String workspaceId,
  required final ConversationEntity conversation,
  required final List<String> modalitiesInput,
  required final bool isInputBusy,
  required final bool hasPendingApprovals,
  required final bool isCompacting,
  required final bool hidesStoppedRun,
  required final Future<void> Function(ChatDraft) onSendMessage,
  required final VoidCallback onToolsPress,
  required final VoidCallback onStop,
  required final VoidCallback onCompact,
  required final ValueChanged<String?> onModelChanged,
  required final ValueChanged<String?> onModelSelectionChanged,
  required final ValueChanged<String?> onAgentChanged,
  required final VoidCallback onSkillsPress,
  required final VoidCallback? onContinueAgent,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final conversationId = conversation.id;
    return Offstage(
      offstage: hasPendingApprovals,
      child: ChatInputWidget(
        workspaceId: workspaceId,
        onSendMessage: onSendMessage,
        onToolsPress: onToolsPress,
        modelSheetControl: CompactWorkspaceModelSelector(
          workspaceId: workspaceId,
          workspaceModelSelectionId: conversation.modelId,
          onChanged: onModelChanged,
          sheetMode: true,
        ),
        agentSheetControl: CompactAgentSelector(
          workspaceId: workspaceId,
          agentId: conversation.agentId,
          onChanged: onAgentChanged,
          sheetMode: true,
        ),
        modelCompactControl: CompactWorkspaceModelSelector(
          workspaceId: workspaceId,
          workspaceModelSelectionId: conversation.modelId,
          onChanged: onModelSelectionChanged,
          compactMode: true,
        ),
        agentCompactControl: CompactAgentSelector(
          workspaceId: workspaceId,
          agentId: conversation.agentId,
          onChanged: onAgentChanged,
          compactMode: true,
        ),
        modalitiesInput: modalitiesInput,
        onSkillsPress: onSkillsPress,
        onContinueAgent: onContinueAgent,
        isBusy: isInputBusy,
        showStopButton: isInputBusy && !hidesStoppedRun,
        onStop: onStop,
        onCompact: onCompact,
        isCompacting: isCompacting,
      ),
    );
  }
}

class const _ChatControlsBar({
  required final String workspaceId,
  required final String conversationId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: auraColors.surfaceVariant,
        border: Border(bottom: .new(color: auraColors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(
            top: context.auraTheme.fromSpacing(.sm),
            right: context.auraTheme.fromSpacing(.sm),
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: ConversationContextUsagePill(
              workspaceId: workspaceId,
              conversationId: conversationId,
            ),
          ),
        ),
      ),
    );
  }
}

class const _RateLimitRetryIndicator({required final DateTime retryAt})
    extends StatefulWidget {
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
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(_RateLimitRetryIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.retryAt == widget.retryAt) return;

    _timer?.cancel();
    _startTimer();
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
          const AuraSpinner(size: .small),
          const AuraSizedBox(width: .sm),
          Flexible(
            child: AuraText(
              child: Text(
                LocaleKeys.chats_screens_chat_conversation_rate_limit_retry.tr(
                  namedArgs: {'seconds': remainingSeconds.toString()},
                ),
              ),
              style: .bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  void _startTimer() {
    _timer = .periodic(const Duration(seconds: 1), _onTimerTick);
  }

  void _onTimerTick(Timer timer) {
    if (!mounted) return;
    setState(() {
      final _ = Object();
    });
  }

  int _remainingSeconds() {
    final remaining = widget.retryAt.difference(.now());
    if (remaining <= .zero) return 0;

    return remaining.inSeconds + 1;
  }
}

ConversationBusyState? _conversationBusyStateValue(
  AsyncValue<ConversationBusyState> state,
) {
  return switch (state) {
    AsyncData(:final value) => value,
    AsyncLoading(:final value?, hasValue: true) => value,
    AsyncLoading() || AsyncError() => null,
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

Future<void> _setModelWithAttachmentWarning({
  required BuildContext context,
  required WidgetRef ref,
  required String workspaceId,
  required String conversationId,
  required String? modelId,
}) async {
  if (modelId == null) {
    await ref
        .read(conversationChatProvider(workspaceId, conversationId).notifier)
        .setModel(null);

    return;
  }

  final selectedModel = await ref.read(
    workspaceModelSelectionByIdProvider(workspaceId, modelId).future,
  );
  final supported =
      selectedModel?.workspaceModelSelection.modalitiesInput ?? [];
  final messages =
      ref.read(chatMessagesProvider(workspaceId, conversationId)).value ??
      const [];
  final missing = _missingAttachmentModalities(messages, supported);
  if (!await _confirmModelSwitch(context, missing)) return;

  await ref
      .read(conversationChatProvider(workspaceId, conversationId).notifier)
      .setModel(modelId);
}

Set<String> _missingAttachmentModalities(
  Iterable<MessageEntity> messages,
  List<String> supported,
) {
  final missing = <String>{};
  for (final message in messages) {
    for (final attachment in message.attachments) {
      if (!ChatAttachmentModality.supports(
        attachment.modality,
        supported,
        mimeType: attachment.mimeType,
      )) {
        final _ = missing.add(attachment.modality.name);
      }
    }
  }
  return missing;
}

Future<bool> _confirmModelSwitch(
  BuildContext context,
  Set<String> missing,
) async {
  if (missing.isEmpty || !context.mounted) return true;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        LocaleKeys
            .chats_screens_chat_conversation_switch_model_unsupported_title
            .tr(),
      ),
      content: Text(
        LocaleKeys.chats_screens_chat_conversation_switch_model_unsupported_body
            .tr(namedArgs: {'modalities': missing.join(', ')}),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            LocaleKeys.chats_screens_chat_conversation_switch_model_cancel.tr(),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            LocaleKeys.chats_screens_chat_conversation_switch_model_confirm
                .tr(),
          ),
        ),
      ],
    ),
  );
  return confirmed == true;
}

Future<void> _continueAgent(
  BuildContext context,
  WidgetRef ref,
  String workspaceId,
  String conversationId,
) async {
  final busyState = _conversationBusyStateValue(
    ref.read(conversationBusyStateProvider(workspaceId, conversationId)),
  );
  final rateLimitRetryAt = ref.read(
    conversationRateLimitRetryProvider,
  )[conversationId];
  if (!_canContinueAgent(busyState, rateLimitRetryAt)) return;

  try {
    final cloud = await ref.read(cloudTurnUsecaseProvider(workspaceId).future);
    if (cloud != null) {
      await _continueCloudAgent(
        ref,
        cloud,
        workspaceId: workspaceId,
        conversationId: conversationId,
      );

      return;
    }
    final _ = await ref
        .read(auraAgentServiceProvider)
        .agent
        .continueTurn(
          conversationId: conversationId,
          context: const AgentIterationContext(origin: .manualContinue),
        );
  } on Exception catch (error, stackTrace) {
    _logger.severe(
      'Failed to continue agent for conversation $conversationId',
      error,
      stackTrace,
    );
    FlutterError.reportError(
      .new(
        library: 'chat_conversation_screen',
        exception: error,
        stack: stackTrace,
        context: ErrorDescription('while manually continuing a conversation'),
      ),
    );
    if (!context.mounted) return;

    final _ = AuraSnackBars.show(
      context: context,
      content: Text(
        LocaleKeys.chats_screens_chat_conversation_continue_error.tr(),
      ),
      variant: .error,
    );
  }
}

bool _canContinueAgent(
  ConversationBusyState? busyState,
  DateTime? rateLimitRetryAt,
) => busyState?.isBusy != true && rateLimitRetryAt == null;

Future<void> _continueCloudAgent(
  WidgetRef ref,
  CloudTurnUsecase cloud, {
  required String workspaceId,
  required String conversationId,
}) async {
  final state = ref
      .read(
        cloudConversationStateProvider((
          workspaceId: workspaceId,
          conversationId: conversationId,
        )),
      )
      .value;
  if (!_canContinueCloudState(state)) return;
  final _ = await cloud.continueSharedConversation(
    conversationId: conversationId,
    projectionRevision: state!.conversation.projectionRevision,
  );
}

bool _canContinueCloudState(CloudConversationState? state) {
  if (state == null) return false;
  final executionState = state.conversation.executionState;
  return executionState == 'idle' || executionState == 'failed';
}

Future<void> _stopConversation(
  BuildContext context,
  WidgetRef ref,
  String workspaceId,
  String conversationId,
) async {
  final cloud = await ref.read(cloudTurnUsecaseProvider(workspaceId).future);
  if (cloud != null) {
    await _stopCloudConversation(
      ref,
      cloud,
      workspaceId: workspaceId,
      conversationId: conversationId,
    );

    return;
  }
  final childIds = ref
      .read(activeSubAgentRuntimeProvider.notifier)
      .childrenOf(conversationId);
  Object? stopError;
  StackTrace? stopStackTrace;
  try {
    await ref
        .read(auraAgentServiceProvider)
        .agent
        .stop(conversationId: conversationId);
  } on Object catch (error, stackTrace) {
    stopError = error;
    stopStackTrace = stackTrace;
    _logger.severe(
      'Failed to stop conversation $conversationId',
      error,
      stackTrace,
    );
  }

  for (final childId in childIds) {
    try {
      await ref
          .read(auraAgentServiceProvider)
          .agent
          .stop(conversationId: childId);
    } on Object catch (error, stackTrace) {
      stopError ??= error;
      stopStackTrace ??= stackTrace;
      _logger.severe(
        'Failed to stop child conversation $childId',
        error,
        stackTrace,
      );
    } finally {
      ref
          .read(activeSubAgentRuntimeProvider.notifier)
          .finish(parentId: conversationId, childId: childId, status: .stopped);
    }
  }

  if (stopError != null) {
    _logger.severe(
      'Stop conversation completed with errors for $conversationId',
      stopError,
      stopStackTrace,
    );
    if (!context.mounted) return;

    final _ = AuraSnackBars.show(
      context: context,
      content: Text(LocaleKeys.chats_screens_chat_conversation_stop_error.tr()),
      variant: .error,
    );
  }
}

Future<void> _stopCloudConversation(
  WidgetRef ref,
  CloudTurnUsecase cloud, {
  required String workspaceId,
  required String conversationId,
}) async {
  final state = ref
      .read(
        cloudConversationStateProvider((
          workspaceId: workspaceId,
          conversationId: conversationId,
        )),
      )
      .value;
  if (!_canStopCloudState(state)) return;
  final _ = await cloud.stopSharedConversation(
    conversationId: conversationId,
    projectionRevision: state!.conversation.projectionRevision,
  );
}

bool _canStopCloudState(CloudConversationState? state) {
  if (state == null) return false;
  final executionState = state.conversation.executionState;
  return executionState == 'running' || executionState == 'awaitingApproval';
}

Future<void> _sendMessage(
  BuildContext context,
  WidgetRef ref,
  String workspaceId,
  String conversationId,
  ChatDraft draft,
) async {
  try {
    await ref
        .read(sendMessageUsecaseProvider(workspaceId))
        .call(conversationId: conversationId, draft: draft);
  } on Exception catch (error, stackTrace) {
    _logger.severe(
      'Failed to send message for conversation $conversationId',
      error,
      stackTrace,
    );
    if (!context.mounted) return;

    final _ = AuraSnackBars.show(
      context: context,
      content: Text(LocaleKeys.chats_screens_chat_conversation_send_error.tr()),
      variant: .error,
    );
  }
}

Future<void> _manualCompact(
  BuildContext context,
  WidgetRef ref,
  String workspaceId,
  String conversationId,
) async {
  try {
    switch (await ref.read(compactConversationUsecaseProvider(workspaceId))(
      conversationId: conversationId,
      trigger: CompactionTrigger.manual,
    )) {
      case _:
        break;
    }
    if (!context.mounted) return;

    final _ = AuraSnackBars.show(
      context: context,
      content: Text(LocaleKeys.compaction_manual_success.tr()),
      variant: .success,
    );
  } on CompactionException {
    if (!context.mounted) return;

    final _ = AuraSnackBars.show(
      context: context,
      content: Text(LocaleKeys.compaction_manual_failure.tr()),
      variant: .error,
    );
  }
}

class const _ChatList({
  required final String workspaceId,
  required final String conversationId,
  required final List<PendingToolCall> pendingToolCalls,
  final bool showThinking = false,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatMessages = ref.watch(
      chatMessagesProvider(workspaceId, conversationId),
    );
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
      workspaceId: workspaceId,
      conversationId: conversationId,
      messages: messageIds,
      messageEntitiesById: messageEntitiesById,
      pendingToolCalls: pendingToolCalls,
      showThinking: showThinking,
    );
  }
}
