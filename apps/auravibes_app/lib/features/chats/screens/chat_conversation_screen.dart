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
import 'package:auravibes_app/features/chats/usecases/cloud_turn_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/compact_conversation_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/conversation_busy_state.dart';
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

typedef _LoadedRuntimeRequest = ({
  BuildContext context,
  WidgetRef ref,
  String workspaceId,
  ConversationEntity conversation,
});

typedef _ConversationWatchRequest = ({
  WidgetRef ref,
  bool isCloud,
  String workspaceId,
  String conversationId,
});

typedef _PendingCallsRequest = ({
  WidgetRef ref,
  bool isCloud,
  CloudConversationState? cloudConversation,
  String workspaceId,
  String conversationId,
});

typedef _InputBusyRequest = ({
  bool isCloud,
  CloudConversationState? cloudConversation,
  ConversationBusyState? busyState,
  DateTime? rateLimitRetryAt,
});

typedef _ConversationContextRequest = ({
  BuildContext context,
  WidgetRef ref,
  String workspaceId,
  String conversationId,
});

typedef _ContinueCallbackRequest = ({
  BuildContext context,
  WidgetRef ref,
  String workspaceId,
  String conversationId,
  bool isInputBusy,
});

typedef _ModelSwitchRequest = ({
  BuildContext context,
  WidgetRef ref,
  String workspaceId,
  String conversationId,
  String? modelId,
});

typedef _MissingModelModalitiesRequest = ({
  WidgetRef ref,
  String workspaceId,
  String conversationId,
  String modelId,
});

typedef _SetConversationModelRequest = ({
  WidgetRef ref,
  String workspaceId,
  String conversationId,
  String? modelId,
});

typedef _ContinueErrorRequest = ({
  BuildContext context,
  String conversationId,
  Exception error,
  StackTrace stackTrace,
});

typedef _CloudContinueRequest = ({
  WidgetRef ref,
  CloudTurnUsecase cloud,
  String workspaceId,
  String conversationId,
});

typedef _SendMessageRequest = ({
  BuildContext context,
  WidgetRef ref,
  String workspaceId,
  String conversationId,
  ChatDraft draft,
});

typedef _ManualCompactRequest = ({
  BuildContext context,
  WidgetRef ref,
  String workspaceId,
  String conversationId,
});

typedef _CloudStopRequest = ({
  WidgetRef ref,
  CloudTurnUsecase cloud,
  String workspaceId,
  String conversationId,
});

typedef _LoadedConversationStateRequest = ({
  WidgetRef ref,
  String workspaceId,
  ConversationEntity conversation,
});

typedef _LoadedActivityRequest = ({
  _LoadedChatConversationDependencies dependencies,
  _LoadedChatConversationCoreState core,
  List<PendingToolCall> pendingCalls,
  bool isInputBusy,
});

typedef _LoadedConversationConnectionWatch = ({
  bool isCloud,
  CloudConversationState? cloudConversation,
});

typedef _LoadedConversationActivityWatch = ({
  ConversationBusyState? busyState,
  DateTime? rateLimitRetryAt,
  List<ConversationQueuedDraft> queuedDrafts,
});

typedef _LoadedConversationDisplayWatch = ({
  List<String> modalitiesInput,
  bool isCompacting,
});

typedef _LoadedConversationWatchParts = ({
  _LoadedConversationStateRequest request,
  _LoadedConversationConnectionWatch connection,
  _LoadedConversationActivityWatch activity,
  _LoadedConversationDisplayWatch display,
});

typedef _LoadedRuntimeStateRequest = ({
  _LoadedChatConversationCallbackState callbacks,
  _LoadedChatConversationState state,
  ValueNotifier<bool> stopRequested,
  String conversationId,
});

typedef _LoadedRuntimeStateBuildRequest = _LoadedRuntimeStateRequest;

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

    return _ConversationAsyncView(
      workspaceId: workspaceId,
      conversationAsync: conversationAsync,
      showInputComposer: showInputComposer,
    );
  }
}

class const _ConversationAsyncView({
  required final String workspaceId,
  required final AsyncValue<ConversationResult> conversationAsync,
  required final bool showInputComposer,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => _ConversationAsyncStateView(
    state: _conversationAsyncState(conversationAsync),
    workspaceId: workspaceId,
    showInputComposer: showInputComposer,
  );
}

class const _ConversationAsyncStateView({
  required final _ConversationAsyncState state,
  required final String workspaceId,
  required final bool showInputComposer,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => state.buildWidget(
    workspaceId: workspaceId,
    showInputComposer: showInputComposer,
  )(context);
}

sealed class const _ConversationAsyncState() {
  Widget Function(BuildContext) buildWidget({
    required String workspaceId,
    required bool showInputComposer,
  });
}

class const _ConversationLoadingState() extends _ConversationAsyncState {
  @override
  Widget Function(BuildContext) buildWidget({
    required String workspaceId,
    required bool showInputComposer,
  }) =>
      (_) => const _ConversationLoading();
}

class const _ConversationLoadErrorState({
  required final Object error,
  required final StackTrace stackTrace,
}) extends _ConversationAsyncState {
  @override
  Widget Function(BuildContext) buildWidget({
    required String workspaceId,
    required bool showInputComposer,
  }) =>
      (_) => _ConversationLoadError(error: error, stackTrace: stackTrace);
}

class const _ConversationFoundState({
  required final ConversationEntity conversation,
}) extends _ConversationAsyncState {
  @override
  Widget Function(BuildContext) buildWidget({
    required String workspaceId,
    required bool showInputComposer,
  }) =>
      (_) => _LoadedChatConversation(
        workspaceId: workspaceId,
        conversation: conversation,
        showInputComposer: showInputComposer,
      );
}

class const _ConversationResultState({
  required final ConversationResult? result,
}) extends _ConversationAsyncState {
  @override
  Widget Function(BuildContext) buildWidget({
    required String workspaceId,
    required bool showInputComposer,
  }) =>
      (_) => _ConversationResultError(result: result);
}

_ConversationAsyncState _conversationAsyncState(
  AsyncValue<ConversationResult> state,
) {
  if (state.isLoading && !state.hasValue) {
    return const _ConversationLoadingState();
  }

  return state.hasError && !state.hasValue
      ? _conversationLoadErrorState(state)
      : _conversationResultState(state.value);
}

_ConversationLoadErrorState _conversationLoadErrorState(
  AsyncValue<ConversationResult> state,
) => _ConversationLoadErrorState(
  error: state.error ?? StateError('Conversation load failed'),
  stackTrace: state.stackTrace ?? StackTrace.empty,
);

_ConversationAsyncState _conversationResultState(ConversationResult? result) =>
    switch (result) {
      ConversationFound(:final conversation) => _ConversationFoundState(
        conversation: conversation,
      ),
      ConversationNotFound() ||
      ConversationWorkspaceMismatch() ||
      null => _ConversationResultState(result: result),
    };

class const _ConversationLoading() extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const AuraScreen(child: Center(child: AuraSpinner()));
}

class const _ConversationLoadError({
  required final Object error,
  required final StackTrace stackTrace,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraScreen(
    child: AppErrorWidget(error: error, stackTrace: stackTrace),
  );
}

class const _ConversationResultError({
  required final ConversationResult? result,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraScreen(
    child: AppErrorWidget(
      error: _conversationResultErrorMessage(result),
      stackTrace: .empty,
    ),
  );
}

String _conversationResultErrorMessage(ConversationResult? result) =>
    switch (result) {
      ConversationWorkspaceMismatch() =>
        LocaleKeys.chats_screens_chat_conversation_error_workspace_mismatch
            .tr(),
      ConversationNotFound() || null || ConversationFound() =>
        LocaleKeys.chats_screens_chat_conversation_error_not_found.tr(),
    };

class const _LoadedChatConversation({
  required final String workspaceId,
  required final ConversationEntity conversation,
  required final bool showInputComposer,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _LoadedChatConversationRuntime(
    workspaceId: workspaceId,
    conversation: conversation,
    showInputComposer: showInputComposer,
  );
}

class const _LoadedChatConversationRuntime({
  required final String workspaceId,
  required final ConversationEntity conversation,
  required final bool showInputComposer,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      _LoadedChatConversationRender(
        workspaceId: workspaceId,
        conversation: conversation,
        runtimeState: _useLoadedChatConversationRuntimeState((
          context: context,
          ref: ref,
          workspaceId: workspaceId,
          conversation: conversation,
        )),
        showInputComposer: showInputComposer,
        leading: showInputComposer ? null : const _ChatConversationBackButton(),
      );
}

class const _ChatConversationBackButton() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraIconButton(
    icon: Icons.arrow_back,
    onPressed: () => Navigator.of(context).pop(),
  );
}

typedef _LoadedChatConversationCallbackState = ({
  _LoadedChatConversationHookState hooks,
  _LoadedChatConversationSelectorCallbacks selectors,
});

class const _LoadedChatConversationHookState({
  required final VoidCallback onToolsPress,
  required final VoidCallback onStop,
  required final Future<void> Function(ChatDraft) onSendMessage,
  required final VoidCallback onCompact,
});

typedef _LoadedChatConversationCoreCallbacks = ({
  VoidCallback onToolsPress,
  VoidCallback onStop,
  Future<void> Function(ChatDraft) onSendMessage,
  VoidCallback onCompact,
});

typedef _LoadedChatConversationSelectorCallbacks = ({
  ValueChanged<String?> onModelChanged,
  ValueChanged<String?> onModelSelectionChanged,
  ValueChanged<String?> onAgentChanged,
  VoidCallback onSkillsPress,
  VoidCallback? Function({required bool isInputBusy}) continueAgent,
});

_LoadedChatConversationCallbackState _useLoadedChatConversationCallbacks({
  required _LoadedChatConversationCallbacks callbacks,
}) {
  final hooks = _useLoadedChatConversationHookState(callbacks);

  return (hooks: hooks, selectors: callbacks.selectors);
}

_LoadedChatConversationHookState _useLoadedChatConversationHookState(
  _LoadedChatConversationCallbacks callbacks,
) {
  return _LoadedChatConversationHookState(
    onToolsPress: _useToolsPressCallback(callbacks),
    onStop: _useStopCallback(callbacks),
    onSendMessage: _useSendMessageCallback(callbacks),
    onCompact: _useCompactCallback(callbacks),
  );
}

VoidCallback _useToolsPressCallback(
  _LoadedChatConversationCallbacks callbacks,
) => useCallback(callbacks.core.onToolsPress, [
  callbacks.ref,
  callbacks.workspaceId,
  callbacks.conversationId,
]);

VoidCallback _useStopCallback(_LoadedChatConversationCallbacks callbacks) =>
    useCallback(callbacks.core.onStop, [
      callbacks.ref,
      callbacks.stopRequested,
    ]);

Future<void> Function(ChatDraft) _useSendMessageCallback(
  _LoadedChatConversationCallbacks callbacks,
) => useCallback<Future<void> Function(ChatDraft)>(
  callbacks.core.onSendMessage,
  [callbacks.ref],
);

VoidCallback _useCompactCallback(_LoadedChatConversationCallbacks callbacks) =>
    useCallback(callbacks.core.onCompact, [
      callbacks.ref,
      callbacks.conversationId,
    ]);

Dispose? _resetStoppedRun(ValueNotifier<bool> stopRequested) {
  stopRequested.value = false;

  return null;
}

Dispose? _resetStoppedRunWhenIdle(
  ValueNotifier<bool> stopRequested,
  bool isInputBusy,
) {
  if (!isInputBusy) {
    stopRequested.value = false;
  }

  return null;
}

bool _useStoppedRunState(
  ValueNotifier<bool> stopRequested,
  String conversationId,
  bool isInputBusy,
) {
  useEffect(() => _resetStoppedRun(stopRequested), [conversationId]);
  useEffect(() => _resetStoppedRunWhenIdle(stopRequested, isInputBusy), [
    conversationId,
    isInputBusy,
  ]);

  return stopRequested.value && isInputBusy;
}

typedef _LoadedChatConversationCallbacks = ({
  WidgetRef ref,
  String workspaceId,
  String conversationId,
  ValueNotifier<bool> stopRequested,
  _LoadedChatConversationCoreCallbacks core,
  _LoadedChatConversationSelectorCallbacks selectors,
});

_LoadedChatConversationCallbacks _createLoadedChatConversationCallbacks(
  _LoadedRuntimeRequest request,
  ValueNotifier<bool> stopRequested,
) => (
  ref: request.ref,
  workspaceId: request.workspaceId,
  conversationId: request.conversation.id,
  stopRequested: stopRequested,
  core: _loadedConversationCoreCallbacks(request, stopRequested),
  selectors: _loadedConversationSelectorCallbacks(request),
);

_LoadedChatConversationCoreCallbacks _loadedConversationCoreCallbacks(
  _LoadedRuntimeRequest request,
  ValueNotifier<bool> stopRequested,
) => (
  onToolsPress: _loadedConversationToolsPress(request),
  onStop: _loadedConversationStop(request, stopRequested),
  onSendMessage: _loadedConversationSendMessage(request),
  onCompact: _loadedConversationCompact(request),
);

_LoadedChatConversationSelectorCallbacks _loadedConversationSelectorCallbacks(
  _LoadedRuntimeRequest request,
) => (
  onModelChanged: _loadedConversationModelChanged(request),
  onModelSelectionChanged: _modelSelectionChanged(request),
  onAgentChanged: _agentChanged(request),
  onSkillsPress: _loadedConversationSkillsPress(request),
  continueAgent: _loadedConversationContinue(request),
);

VoidCallback _loadedConversationToolsPress(_LoadedRuntimeRequest request) =>
    () => _showToolsModal(
      context: request.context,
      workspaceId: request.workspaceId,
      conversationId: request.conversation.id,
    );

VoidCallback _loadedConversationStop(
  _LoadedRuntimeRequest request,
  ValueNotifier<bool> stopRequested,
) => () {
  stopRequested.value = true;
  _runLoadedConversationStop(request);
};

void _runLoadedConversationStop(_LoadedRuntimeRequest request) =>
    unawaited(_stopConversation(_loadedConversationContextRequest(request)));

_ConversationContextRequest _loadedConversationContextRequest(
  _LoadedRuntimeRequest request,
) => (
  context: request.context,
  ref: request.ref,
  workspaceId: request.workspaceId,
  conversationId: request.conversation.id,
);

Future<void> Function(ChatDraft) _loadedConversationSendMessage(
  _LoadedRuntimeRequest request,
) =>
    (draft) => _sendMessage((
      context: request.context,
      ref: request.ref,
      workspaceId: request.workspaceId,
      conversationId: request.conversation.id,
      draft: draft,
    ));

VoidCallback _loadedConversationCompact(_LoadedRuntimeRequest request) =>
    () => unawaited(
      _manualCompact((
        context: request.context,
        ref: request.ref,
        workspaceId: request.workspaceId,
        conversationId: request.conversation.id,
      )),
    );

ValueChanged<String?> _loadedConversationModelChanged(
  _LoadedRuntimeRequest request,
) =>
    (modelId) => unawaited(
      _setModelWithAttachmentWarning((
        context: request.context,
        ref: request.ref,
        workspaceId: request.workspaceId,
        conversationId: request.conversation.id,
        modelId: modelId,
      )),
    );

VoidCallback _loadedConversationSkillsPress(_LoadedRuntimeRequest request) =>
    () => _showSkillsModal(
      context: request.context,
      workspaceId: request.workspaceId,
      conversationId: request.conversation.id,
    );

VoidCallback? Function({required bool isInputBusy}) _loadedConversationContinue(
  _LoadedRuntimeRequest request,
) =>
    ({required isInputBusy}) => _continueAgentCallback(
      _loadedConversationContinueRequest(request, isInputBusy),
    );

_ContinueCallbackRequest _loadedConversationContinueRequest(
  _LoadedRuntimeRequest request,
  bool isInputBusy,
) => (
  context: request.context,
  ref: request.ref,
  workspaceId: request.workspaceId,
  conversationId: request.conversation.id,
  isInputBusy: isInputBusy,
);

ValueChanged<String?> _modelSelectionChanged(_LoadedRuntimeRequest request) =>
    (modelId) => unawaited(
      request.ref
          .read(
            conversationChatProvider(
              request.workspaceId,
              request.conversation.id,
            ).notifier,
          )
          .setModel(modelId),
    );

ValueChanged<String?> _agentChanged(_LoadedRuntimeRequest request) =>
    (agentId) => unawaited(
      request.ref
          .read(
            conversationChatProvider(
              request.workspaceId,
              request.conversation.id,
            ).notifier,
          )
          .setAgent(agentId),
    );

typedef _LoadedChatConversationDependencies = _LoadedConversationWatchParts;

class const _LoadedChatConversationCoreState({
  required final bool isCloud,
  required final CloudConversationState? cloudConversation,
  required final ConversationBusyState? busyState,
  required final DateTime? rateLimitRetryAt,
  required final List<ConversationQueuedDraft> queuedDrafts,
  required final List<String> modalitiesInput,
});

_LoadedChatConversationCoreState _watchLoadedChatConversationCore(
  _LoadedChatConversationDependencies dependencies,
) {
  final activity = dependencies.activity;

  return _LoadedChatConversationCoreState(
    isCloud: dependencies.connection.isCloud,
    cloudConversation: dependencies.connection.cloudConversation,
    busyState: activity.busyState,
    rateLimitRetryAt: activity.rateLimitRetryAt,
    queuedDrafts: activity.queuedDrafts,
    modalitiesInput: dependencies.display.modalitiesInput,
  );
}

class const _LoadedChatConversationActivityState({
  required final List<PendingToolCall> pendingCalls,
  required final bool hasPendingApprovals,
  required final bool isInputBusy,
  required final bool isCompacting,
  required final bool isGenerating,
});

_LoadedChatConversationActivityState _watchLoadedChatConversationActivity(
  _LoadedChatConversationDependencies dependencies,
  _LoadedChatConversationCoreState core,
) {
  final pendingCalls = _watchLoadedPendingCalls(dependencies, core);
  final isInputBusy = _watchLoadedInputBusy(core);

  return _loadedChatConversationActivityState((
    dependencies: dependencies,
    core: core,
    pendingCalls: pendingCalls,
    isInputBusy: isInputBusy,
  ));
}

List<PendingToolCall> _watchLoadedPendingCalls(
  _LoadedChatConversationDependencies dependencies,
  _LoadedChatConversationCoreState core,
) => _watchPendingActivityCalls(
  dependencies,
  isCloud: core.isCloud,
  cloudConversation: core.cloudConversation,
);

bool _watchLoadedInputBusy(_LoadedChatConversationCoreState core) =>
    _watchInputBusyActivity((
      isCloud: core.isCloud,
      cloudConversation: core.cloudConversation,
      busyState: core.busyState,
      rateLimitRetryAt: core.rateLimitRetryAt,
    ));

_LoadedChatConversationActivityState _loadedChatConversationActivityState(
  _LoadedActivityRequest request,
) => _LoadedChatConversationActivityState(
  pendingCalls: request.pendingCalls,
  hasPendingApprovals: request.pendingCalls.isNotEmpty,
  isInputBusy: request.isInputBusy,
  isCompacting: request.dependencies.display.isCompacting,
  isGenerating: _isGeneratingFromCore(request.core),
);

bool _isGeneratingFromCore(_LoadedChatConversationCoreState core) =>
    _isGenerating(
      isCloud: core.isCloud,
      cloudConversation: core.cloudConversation,
      busyState: core.busyState,
    );

List<PendingToolCall> _watchPendingActivityCalls(
  _LoadedChatConversationDependencies dependencies, {
  required bool isCloud,
  required CloudConversationState? cloudConversation,
}) {
  final request = dependencies.request;

  return _watchPendingCalls((
    ref: request.ref,
    isCloud: isCloud,
    cloudConversation: cloudConversation,
    workspaceId: request.workspaceId,
    conversationId: request.conversation.id,
  ));
}

bool _watchInputBusyActivity(_InputBusyRequest request) =>
    _isInputBusy(request);

class const _LoadedChatConversationState({
  required final List<PendingToolCall> pendingCalls,
  required final bool hasPendingApprovals,
  required final DateTime? rateLimitRetryAt,
  required final List<ConversationQueuedDraft> queuedDrafts,
  required final List<String> modalitiesInput,
  required final bool isInputBusy,
  required final bool isCompacting,
  required final bool isGenerating,
});

class const _LoadedChatConversationData({
  required final String workspaceId,
  required final ConversationEntity conversation,
  required final _LoadedChatConversationState state,
  required final bool hidesStoppedRun,
  required final bool showInputComposer,
  required final _LoadedChatConversationCallbackState callbacks,
  required final Widget? leading,
});

class const _LoadedChatConversationRuntimeState({
  required final _LoadedChatConversationCallbackState callbacks,
  required final _LoadedChatConversationState state,
  required final bool hidesStoppedRun,
});

_LoadedChatConversationRuntimeState _useLoadedChatConversationRuntimeState(
  _LoadedRuntimeRequest request,
) {
  final stopRequested = useState(false);
  final callbacks = _useLoadedConversationCallbacksForRequest(
    request,
    stopRequested,
  );
  final state = _watchLoadedChatConversationState(
    _loadedConversationStateRequest(request),
  );

  return _loadedChatConversationRuntimeState(
    _loadedRuntimeStateRequest((
      callbacks: callbacks,
      state: state,
      stopRequested: stopRequested,
      conversationId: request.conversation.id,
    )),
  );
}

_LoadedChatConversationCallbackState _useLoadedConversationCallbacksForRequest(
  _LoadedRuntimeRequest request,
  ValueNotifier<bool> stopRequested,
) => _useLoadedChatConversationCallbacks(
  callbacks: _createLoadedChatConversationCallbacks(request, stopRequested),
);

_LoadedRuntimeStateRequest _loadedRuntimeStateRequest(
  _LoadedRuntimeStateBuildRequest request,
) => (
  callbacks: request.callbacks,
  state: request.state,
  stopRequested: request.stopRequested,
  conversationId: request.conversationId,
);

_LoadedConversationStateRequest _loadedConversationStateRequest(
  _LoadedRuntimeRequest request,
) => (
  ref: request.ref,
  workspaceId: request.workspaceId,
  conversation: request.conversation,
);

_LoadedChatConversationRuntimeState _loadedChatConversationRuntimeState(
  _LoadedRuntimeStateRequest request,
) => _LoadedChatConversationRuntimeState(
  callbacks: request.callbacks,
  state: request.state,
  hidesStoppedRun: _useStoppedRunState(
    request.stopRequested,
    request.conversationId,
    request.state.isInputBusy,
  ),
);

class const _LoadedChatConversationRender({
  required final String workspaceId,
  required final ConversationEntity conversation,
  required final _LoadedChatConversationRuntimeState runtimeState,
  required final bool showInputComposer,
  required final Widget? leading,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _LoadedChatConversationView(
    data: .new(
      workspaceId: workspaceId,
      conversation: conversation,
      state: runtimeState.state,
      hidesStoppedRun: runtimeState.hidesStoppedRun,
      showInputComposer: showInputComposer,
      callbacks: runtimeState.callbacks,
      leading: leading,
    ),
  );
}

_LoadedChatConversationState _watchLoadedChatConversationState(
  _LoadedConversationStateRequest request,
) {
  final dependencies = _watchLoadedChatConversationDependencies(request);
  final core = _watchLoadedChatConversationCore(dependencies);
  final activity = _watchLoadedChatConversationActivity(dependencies, core);

  return _loadedChatConversationState(core: core, activity: activity);
}

_LoadedChatConversationDependencies _watchLoadedChatConversationDependencies(
  _LoadedConversationStateRequest request,
) => _watchLoadedConversationParts(request);

_LoadedConversationWatchParts _watchLoadedConversationParts(
  _LoadedConversationStateRequest request,
) => (
  request: request,
  connection: _watchLoadedConversationConnection(request),
  activity: _watchLoadedConversationActivity(request),
  display: _watchLoadedConversationDisplay(request),
);

_LoadedConversationConnectionWatch _watchLoadedConversationConnection(
  _LoadedConversationStateRequest request,
) {
  final isCloud = _isCloudWorkspace(request.ref, request.workspaceId);

  return (
    isCloud: isCloud,
    cloudConversation: _watchCloudConversation((
      ref: request.ref,
      isCloud: isCloud,
      workspaceId: request.workspaceId,
      conversationId: request.conversation.id,
    )),
  );
}

_LoadedConversationActivityWatch _watchLoadedConversationActivity(
  _LoadedConversationStateRequest request,
) => (
  busyState: _watchConversationBusyState(request),
  rateLimitRetryAt: _watchConversationRateLimit(request),
  queuedDrafts: _watchConversationQueuedDrafts(request),
);

_LoadedConversationDisplayWatch _watchLoadedConversationDisplay(
  _LoadedConversationStateRequest request,
) => (
  modalitiesInput: _watchConversationModalities(request),
  isCompacting: _watchConversationCompacting(request),
);

ConversationBusyState? _watchConversationBusyState(
  _LoadedConversationStateRequest request,
) => _conversationBusyStateValue(
  request.ref.watch(
    conversationBusyStateProvider(request.workspaceId, request.conversation.id),
  ),
);

DateTime? _watchConversationRateLimit(
  _LoadedConversationStateRequest request,
) => request.ref.watch(
  conversationRateLimitRetryProvider.select(
    (retries) => retries[request.conversation.id],
  ),
);

List<ConversationQueuedDraft> _watchConversationQueuedDrafts(
  _LoadedConversationStateRequest request,
) => request.ref.watch(
  conversationQueuedDraftsProvider(
    request.workspaceId,
    request.conversation.id,
  ),
);

List<String> _watchConversationModalities(
  _LoadedConversationStateRequest request,
) => _watchModelModalities(
  request.ref,
  workspaceId: request.workspaceId,
  modelId: request.conversation.modelId,
);

bool _watchConversationCompacting(_LoadedConversationStateRequest request) =>
    request.ref
        .watch(compactionExecutionStateProvider(request.conversation.id))
        ?.status ==
    CompactionExecutionStatus.running;

_LoadedChatConversationState _loadedChatConversationState({
  required _LoadedChatConversationCoreState core,
  required _LoadedChatConversationActivityState activity,
}) => _LoadedChatConversationState(
  pendingCalls: activity.pendingCalls,
  hasPendingApprovals: activity.hasPendingApprovals,
  rateLimitRetryAt: core.rateLimitRetryAt,
  queuedDrafts: core.queuedDrafts,
  modalitiesInput: core.modalitiesInput,
  isInputBusy: activity.isInputBusy,
  isCompacting: activity.isCompacting,
  isGenerating: activity.isGenerating,
);

bool _isCloudWorkspace(WidgetRef ref, String workspaceId) =>
    ref.watch(workspaceSessionForRouteProvider(workspaceId)).value?.cloud !=
    null;

CloudConversationState? _watchCloudConversation(
  _ConversationWatchRequest request,
) {
  if (!request.isCloud) return null;

  return request.ref
      .watch(
        cloudConversationStateProvider((
          workspaceId: request.workspaceId,
          conversationId: request.conversationId,
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

List<PendingToolCall> _watchPendingCalls(_PendingCallsRequest request) {
  return request.isCloud
      ? CloudMessageTools.pendingToolCalls(request.cloudConversation)
      : _watchLocalPendingCalls(request);
}

List<PendingToolCall> _watchLocalPendingCalls(_PendingCallsRequest request) =>
    request.ref
        .watch(
          pendingToolCallsProvider(request.workspaceId, request.conversationId),
        )
        .value ??
    const [];

bool _isInputBusy(_InputBusyRequest request) =>
    request.rateLimitRetryAt != null ||
    (request.isCloud
        ? _isCloudInputBusy(request.cloudConversation)
        : request.busyState?.isBusy ?? false);

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

VoidCallback? _continueAgentCallback(_ContinueCallbackRequest request) {
  if (request.isInputBusy) return null;

  return () => unawaited(
    _continueAgent((
      context: request.context,
      ref: request.ref,
      workspaceId: request.workspaceId,
      conversationId: request.conversationId,
    )),
  );
}

class const _LoadedChatConversationView({
  required final _LoadedChatConversationData data,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraScreen(
      child: _ChatConversationBody(data: data),
      appBar: _ChatConversationAppBar(
        title: data.conversation.title,
        leading: data.leading,
      ),
    );
  }
}

class const _ChatConversationAppBar({
  required final String title,
  required final Widget? leading,
}) extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) =>
      AuraAppBarWithDrawer(title: Text(title), leading: leading);
}

class const _ChatConversationBody({
  required final _LoadedChatConversationData data,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      _ChatConversationControls(data: data),
      _ChatConversationMessageList(data: data),
      if (_hasChatConversationStatus(data)) _ChatConversationStatus(data: data),
      if (data.showInputComposer) _ChatComposer(data: data),
    ],
  );
}

class const _ChatConversationMessageList({
  required final _LoadedChatConversationData data,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Expanded(
    child: _ChatList(
      workspaceId: data.workspaceId,
      conversationId: data.conversation.id,
      pendingToolCalls: data.state.pendingCalls,
      showThinking: data.state.isGenerating && !data.hidesStoppedRun,
    ),
  );
}

class const _ChatConversationControls({
  required final _LoadedChatConversationData data,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _ChatControlsBar(
    workspaceId: data.workspaceId,
    conversationId: data.conversation.id,
  );
}

class const _ChatConversationStatus({
  required final _LoadedChatConversationData data,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final retryAt = data.state.rateLimitRetryAt;

    return AuraColumn(
      children: [
        if (retryAt != null && !data.hidesStoppedRun)
          _RateLimitRetryIndicator(retryAt: retryAt),
        if (data.state.queuedDrafts.isNotEmpty)
          _QueuedMessagesStatus(data: data),
        if (data.state.hasPendingApprovals) _ApprovalStatus(data: data),
      ],
      mainAxisSize: .min,
    );
  }
}

class const _QueuedMessagesStatus({
  required final _LoadedChatConversationData data,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ChatQueuedMessagesIndicator(
    conversationId: data.conversation.id,
    queuedDrafts: data.state.queuedDrafts,
  );
}

class const _ApprovalStatus({required final _LoadedChatConversationData data})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ChatToolApprovalCard(
    workspaceId: data.workspaceId,
    conversationId: data.conversation.id,
    pendingCalls: data.state.pendingCalls,
  );
}

bool _hasChatConversationStatus(_LoadedChatConversationData data) {
  final state = data.state;

  return (state.rateLimitRetryAt != null && !data.hidesStoppedRun) ||
      state.queuedDrafts.isNotEmpty ||
      state.hasPendingApprovals;
}

class const _ChatComposer({required final _LoadedChatConversationData data})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Offstage(
    offstage: data.state.hasPendingApprovals,
    child: _ChatComposerInput(
      data: data,
      onContinueAgent: data.callbacks.selectors.continueAgent(
        isInputBusy: data.state.isInputBusy,
      ),
    ),
  );
}

class _ChatComposerInput extends StatelessWidget {
  new({required this.data, required this.onContinueAgent})
    : input = ChatInputWidget(
        workspaceId: data.workspaceId,
        onSendMessage: data.callbacks.hooks.onSendMessage,
        onToolsPress: data.callbacks.hooks.onToolsPress,
        modelSheetControl: _ChatComposerModelSheetControl(
          workspaceId: data.workspaceId,
          workspaceModelSelectionId: data.conversation.modelId,
          onChanged: data.callbacks.selectors.onModelChanged,
        ),
        agentSheetControl: _ChatComposerAgentSheetControl(
          workspaceId: data.workspaceId,
          agentId: data.conversation.agentId,
          onChanged: data.callbacks.selectors.onAgentChanged,
        ),
        modelCompactControl: _ChatComposerModelCompactControl(
          workspaceId: data.workspaceId,
          workspaceModelSelectionId: data.conversation.modelId,
          onChanged: data.callbacks.selectors.onModelSelectionChanged,
        ),
        agentCompactControl: _ChatComposerAgentCompactControl(
          workspaceId: data.workspaceId,
          agentId: data.conversation.agentId,
          onChanged: data.callbacks.selectors.onAgentChanged,
        ),
        modalitiesInput: data.state.modalitiesInput,
        onSkillsPress: data.callbacks.selectors.onSkillsPress,
        onContinueAgent: onContinueAgent,
        isBusy: data.state.isInputBusy,
        showStopButton: data.state.isInputBusy && !data.hidesStoppedRun,
        onStop: data.callbacks.hooks.onStop,
        onCompact: data.callbacks.hooks.onCompact,
        isCompacting: data.state.isCompacting,
      );

  final _LoadedChatConversationData data;
  final VoidCallback? onContinueAgent;
  final ChatInputWidget input;

  @override
  Widget build(BuildContext context) => input;
}

class const _ChatComposerModelSheetControl({
  required final String workspaceId,
  required final String? workspaceModelSelectionId,
  required final ValueChanged<String?> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CompactWorkspaceModelSelector(
    workspaceId: workspaceId,
    workspaceModelSelectionId: workspaceModelSelectionId,
    onChanged: onChanged,
    sheetMode: true,
  );
}

class const _ChatComposerAgentSheetControl({
  required final String workspaceId,
  required final String? agentId,
  required final ValueChanged<String?> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CompactAgentSelector(
    workspaceId: workspaceId,
    agentId: agentId,
    onChanged: onChanged,
    sheetMode: true,
  );
}

class const _ChatComposerModelCompactControl({
  required final String workspaceId,
  required final String? workspaceModelSelectionId,
  required final ValueChanged<String?> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CompactWorkspaceModelSelector(
    workspaceId: workspaceId,
    workspaceModelSelectionId: workspaceModelSelectionId,
    onChanged: onChanged,
    compactMode: true,
  );
}

class const _ChatComposerAgentCompactControl({
  required final String workspaceId,
  required final String? agentId,
  required final ValueChanged<String?> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CompactAgentSelector(
    workspaceId: workspaceId,
    agentId: agentId,
    onChanged: onChanged,
    compactMode: true,
  );
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
      child: _ChatControlsContent(
        workspaceId: workspaceId,
        conversationId: conversationId,
      ),
    );
  }
}

class const _ChatControlsContent({
  required final String workspaceId,
  required final String conversationId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    bottom: false,
    child: _ChatControlsPadding(
      workspaceId: workspaceId,
      conversationId: conversationId,
    ),
  );
}

class const _ChatControlsPadding({
  required final String workspaceId,
  required final String conversationId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      top: context.auraTheme.fromSpacing(.sm),
      right: context.auraTheme.fromSpacing(.sm),
    ),
    child: _ChatControlsAlignment(
      workspaceId: workspaceId,
      conversationId: conversationId,
    ),
  );
}

class const _ChatControlsAlignment({
  required final String workspaceId,
  required final String conversationId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: ConversationContextUsagePill(
      workspaceId: workspaceId,
      conversationId: conversationId,
    ),
  );
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
      child: _RateLimitRetryContent(remainingSeconds: remainingSeconds),
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

class const _RateLimitRetryContent({required final int remainingSeconds})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const AuraSpinner(size: .small),
      const AuraSizedBox(width: .sm),
      Flexible(child: _RateLimitRetryText(remainingSeconds: remainingSeconds)),
    ],
  );
}

class const _RateLimitRetryText({required final int remainingSeconds})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraText(
    child: Text(
      LocaleKeys.chats_screens_chat_conversation_rate_limit_retry.tr(
        namedArgs: {'seconds': remainingSeconds.toString()},
      ),
    ),
    style: .bodySmall,
  );
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

Future<void> _setModelWithAttachmentWarning(_ModelSwitchRequest request) async {
  final modelId = request.modelId;
  if (modelId == null) {
    await _setModelAfterAttachmentCheck(request, null);

    return;
  }

  if (!await _canSetModelWithAttachmentWarning(request, modelId)) return;

  await _setModelAfterAttachmentCheck(request, modelId);
}

Future<bool> _canSetModelWithAttachmentWarning(
  _ModelSwitchRequest request,
  String modelId,
) async {
  final missing = await _missingModelModalities((
    ref: request.ref,
    workspaceId: request.workspaceId,
    conversationId: request.conversationId,
    modelId: modelId,
  ));
  if (!request.context.mounted) return false;

  return await _confirmModelSwitch(request.context, missing);
}

Future<void> _setModelAfterAttachmentCheck(
  _ModelSwitchRequest request,
  String? modelId,
) => _setConversationModel((
  ref: request.ref,
  workspaceId: request.workspaceId,
  conversationId: request.conversationId,
  modelId: modelId,
));

Future<Set<String>> _missingModelModalities(
  _MissingModelModalitiesRequest request,
) async {
  final supported = await _modelModalities(
    request.ref,
    request.workspaceId,
    request.modelId,
  );
  final messages = _conversationMessages(
    request.ref,
    request.workspaceId,
    request.conversationId,
  );

  return _missingAttachmentModalities(messages, supported);
}

Future<List<String>> _modelModalities(
  WidgetRef ref,
  String workspaceId,
  String modelId,
) async {
  final selectedModel = await ref.read(
    workspaceModelSelectionByIdProvider(workspaceId, modelId).future,
  );

  return selectedModel?.workspaceModelSelection.modalitiesInput ?? const [];
}

List<MessageEntity> _conversationMessages(
  WidgetRef ref,
  String workspaceId,
  String conversationId,
) =>
    ref.read(chatMessagesProvider(workspaceId, conversationId)).value ??
    const [];

Future<void> _setConversationModel(_SetConversationModelRequest request) =>
    request.ref
        .read(
          conversationChatProvider(
            request.workspaceId,
            request.conversationId,
          ).notifier,
        )
        .setModel(request.modelId);

Set<String> _missingAttachmentModalities(
  Iterable<MessageEntity> messages,
  List<String> supported,
) => messages
    .expand((message) => message.attachments)
    .where(
      (attachment) => !ChatAttachmentModality.supports(
        attachment.modality,
        supported,
        mimeType: attachment.mimeType,
      ),
    )
    .map((attachment) => attachment.modality.name)
    .toSet();

Future<bool> _confirmModelSwitch(
  BuildContext context,
  Set<String> missing,
) async {
  if (missing.isEmpty || !context.mounted) return true;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => _ConfirmModelSwitchDialog(missing: missing),
  );

  return confirmed == true;
}

class const _ConfirmModelSwitchDialog({required final Set<String> missing})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      LocaleKeys.chats_screens_chat_conversation_switch_model_unsupported_title
          .tr(),
    ),
    content: Text(
      LocaleKeys.chats_screens_chat_conversation_switch_model_unsupported_body
          .tr(namedArgs: {'modalities': missing.join(', ')}),
    ),
    actions: const [_ModelSwitchCancelButton(), _ModelSwitchConfirmButton()],
  );
}

class const _ModelSwitchCancelButton() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => Navigator.of(context).pop(false),
    child: Text(
      LocaleKeys.chats_screens_chat_conversation_switch_model_cancel.tr(),
    ),
  );
}

class const _ModelSwitchConfirmButton() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => Navigator.of(context).pop(true),
    child: Text(
      LocaleKeys.chats_screens_chat_conversation_switch_model_confirm.tr(),
    ),
  );
}

Future<void> _continueAgent(_ConversationContextRequest request) async {
  if (!_canContinueConversation(request)) return;

  await _continueAgentTurnWithErrorHandling(request);
}

Future<void> _continueAgentTurnWithErrorHandling(
  _ConversationContextRequest request,
) async {
  try {
    await _continueAgentTurn(request);
  } on Exception catch (error, stackTrace) {
    _reportContinueAgentFailure(request, error, stackTrace);
  }
}

void _reportContinueAgentFailure(
  _ConversationContextRequest request,
  Exception error,
  StackTrace stackTrace,
) {
  if (!request.context.mounted) return;

  _reportContinueAgentError((
    context: request.context,
    conversationId: request.conversationId,
    error: error,
    stackTrace: stackTrace,
  ));
}

bool _canContinueConversation(_ConversationContextRequest request) =>
    _canContinueAgent(
      _conversationBusyStateValue(
        request.ref.read(
          conversationBusyStateProvider(
            request.workspaceId,
            request.conversationId,
          ),
        ),
      ),
      request.ref.read(
        conversationRateLimitRetryProvider,
      )[request.conversationId],
    );

Future<void> _continueAgentTurn(_ConversationContextRequest request) async {
  final cloud = await request.ref.read(
    cloudTurnUsecaseProvider(request.workspaceId).future,
  );
  if (cloud == null) {
    await _continueLocalAgent(request.ref, request.conversationId);

    return;
  }

  await _continueCloudAgent((
    ref: request.ref,
    cloud: cloud,
    workspaceId: request.workspaceId,
    conversationId: request.conversationId,
  ));
}

Future<void> _continueLocalAgent(WidgetRef ref, String conversationId) async {
  final _ = await ref
      .read(auraAgentServiceProvider)
      .agent
      .continueTurn(
        conversationId: conversationId,
        context: const AgentIterationContext(origin: .manualContinue),
      );
}

void _reportContinueAgentError(_ContinueErrorRequest request) {
  _logContinueAgentError(request);
  _reportContinueAgentFlutterError(request);
  _showContinueAgentError(request.context);
}

void _logContinueAgentError(_ContinueErrorRequest request) {
  _logger.severe(
    'Failed to continue agent for conversation ${request.conversationId}',
    request.error,
    request.stackTrace,
  );
}

void _reportContinueAgentFlutterError(_ContinueErrorRequest request) {
  FlutterError.reportError(
    .new(
      library: 'chat_conversation_screen',
      exception: request.error,
      stack: request.stackTrace,
      context: ErrorDescription('while manually continuing a conversation'),
    ),
  );
}

void _showContinueAgentError(BuildContext context) {
  if (!context.mounted) return;

  final _ = AuraSnackBars.show(
    context: context,
    content: Text(
      LocaleKeys.chats_screens_chat_conversation_continue_error.tr(),
    ),
    variant: .error,
  );
}

bool _canContinueAgent(
  ConversationBusyState? busyState,
  DateTime? rateLimitRetryAt,
) => busyState?.isBusy != true && rateLimitRetryAt == null;

Future<void> _continueCloudAgent(_CloudContinueRequest request) async {
  final state = _readCloudConversationState(
    request.ref,
    request.workspaceId,
    request.conversationId,
  );
  if (state == null || !_canContinueCloudState(state)) return;

  final _ = await request.cloud.continueSharedConversation(
    conversationId: request.conversationId,
    projectionRevision: state.conversation.projectionRevision,
  );
}

CloudConversationState? _readCloudConversationState(
  WidgetRef ref,
  String workspaceId,
  String conversationId,
) => ref
    .read(
      cloudConversationStateProvider((
        workspaceId: workspaceId,
        conversationId: conversationId,
      )),
    )
    .value;

bool _canContinueCloudState(CloudConversationState state) {
  final executionState = state.conversation.executionState;

  return executionState == 'idle' || executionState == 'failed';
}

Future<void> _stopConversation(_ConversationContextRequest request) async {
  final cloud = await _cloudTurnForStop(request);
  await _stopConversationWithTurn(request, cloud);
}

Future<void> _stopConversationWithTurn(
  _ConversationContextRequest request,
  CloudTurnUsecase? cloud,
) async {
  if (cloud != null) {
    await _stopCloudConversationForRequest(request, cloud);

    return;
  }
  await _stopLocalConversationAndReport(request);
}

Future<CloudTurnUsecase?> _cloudTurnForStop(
  _ConversationContextRequest request,
) => request.ref.read(cloudTurnUsecaseProvider(request.workspaceId).future);

Future<void> _stopCloudConversationForRequest(
  _ConversationContextRequest request,
  CloudTurnUsecase cloud,
) => _stopCloudConversation((
  ref: request.ref,
  cloud: cloud,
  workspaceId: request.workspaceId,
  conversationId: request.conversationId,
));

Future<void> _stopLocalConversationAndReport(
  _ConversationContextRequest request,
) async {
  final failure = await _stopLocalConversation(
    request.ref,
    request.conversationId,
  );
  if (failure == null) return;
  if (!request.context.mounted) return;

  _reportStopFailure(request.context, request.conversationId, failure);
}

class const _StopConversationFailure({
  required final Object error,
  required final StackTrace stackTrace,
});

Future<_StopConversationFailure?> _stopLocalConversation(
  WidgetRef ref,
  String conversationId,
) async {
  final parentFailure = await _stopAgentConversation(
    ref,
    conversationId,
    logName: 'conversation',
  );
  final childFailure = await _stopChildConversations(ref, conversationId);

  return parentFailure ?? childFailure;
}

Future<_StopConversationFailure?> _stopChildConversations(
  WidgetRef ref,
  String conversationId,
) {
  final childIds = ref
      .read(activeSubAgentRuntimeProvider.notifier)
      .childrenOf(conversationId);

  return _stopChildConversationsInOrder(ref, conversationId, childIds);
}

Future<_StopConversationFailure?> _stopChildConversationsInOrder(
  WidgetRef ref,
  String parentId,
  Iterable<String> childIds,
) async {
  _StopConversationFailure? firstFailure;
  for (final childId in childIds) {
    final failure = await _stopChildConversation(
      ref,
      parentId: parentId,
      childId: childId,
    );
    firstFailure ??= failure;
  }

  return firstFailure;
}

Future<_StopConversationFailure?> _stopChildConversation(
  WidgetRef ref, {
  required String parentId,
  required String childId,
}) async {
  try {
    return await _stopAgentConversation(
      ref,
      childId,
      logName: 'child conversation',
    );
  } finally {
    ref
        .read(activeSubAgentRuntimeProvider.notifier)
        .finish(parentId: parentId, childId: childId, status: .stopped);
  }
}

Future<_StopConversationFailure?> _stopAgentConversation(
  WidgetRef ref,
  String conversationId, {
  required String logName,
}) async {
  try {
    await _stopAgent(ref, conversationId);

    return null;
  } on Object catch (error, stackTrace) {
    return _stopAgentFailure((
      conversationId: conversationId,
      logName: logName,
      error: error,
      stackTrace: stackTrace,
    ));
  }
}

Future<void> _stopAgent(WidgetRef ref, String conversationId) => ref
    .read(auraAgentServiceProvider)
    .agent
    .stop(conversationId: conversationId);

typedef _StopAgentFailureRequest = ({
  String conversationId,
  String logName,
  Object error,
  StackTrace stackTrace,
});

_StopConversationFailure _stopAgentFailure(_StopAgentFailureRequest request) {
  _logger.severe(
    'Failed to stop ${request.logName} ${request.conversationId}',
    request.error,
    request.stackTrace,
  );

  return _StopConversationFailure(
    error: request.error,
    stackTrace: request.stackTrace,
  );
}

void _reportStopFailure(
  BuildContext context,
  String conversationId,
  _StopConversationFailure failure,
) {
  _logger.severe(
    'Stop conversation completed with errors for $conversationId',
    failure.error,
    failure.stackTrace,
  );
  if (!context.mounted) return;

  final _ = AuraSnackBars.show(
    context: context,
    content: Text(LocaleKeys.chats_screens_chat_conversation_stop_error.tr()),
    variant: .error,
  );
}

Future<void> _stopCloudConversation(_CloudStopRequest request) async {
  final state = _readCloudConversationState(
    request.ref,
    request.workspaceId,
    request.conversationId,
  );
  if (state == null || !_canStopCloudState(state)) return;

  final _ = await request.cloud.stopSharedConversation(
    conversationId: request.conversationId,
    projectionRevision: state.conversation.projectionRevision,
  );
}

bool _canStopCloudState(CloudConversationState state) {
  final executionState = state.conversation.executionState;

  return executionState == 'running' || executionState == 'awaitingApproval';
}

Future<void> _sendMessage(_SendMessageRequest request) async {
  try {
    await _sendMessageUsecase(request);
  } on Exception catch (error, stackTrace) {
    _reportSendMessageFailure(request, error, stackTrace);
  }
}

Future<void> _sendMessageUsecase(_SendMessageRequest request) => request.ref
    .read(sendMessageUsecaseProvider(request.workspaceId))
    .call(conversationId: request.conversationId, draft: request.draft);

void _reportSendMessageFailure(
  _SendMessageRequest request,
  Exception error,
  StackTrace stackTrace,
) {
  _logger.severe(
    'Failed to send message for conversation ${request.conversationId}',
    error,
    stackTrace,
  );
  if (!request.context.mounted) return;

  _showSendMessageError(request.context);
}

void _showSendMessageError(BuildContext context) {
  if (!context.mounted) return;

  final _ = AuraSnackBars.show(
    context: context,
    content: Text(LocaleKeys.chats_screens_chat_conversation_send_error.tr()),
    variant: .error,
  );
}

Future<void> _manualCompact(_ManualCompactRequest request) async {
  try {
    await _runManualCompaction(request);
    _showManualCompactSuccess(request.context);
  } on CompactionException {
    _showManualCompactFailure(request.context);
  }
}

Future<void> _runManualCompaction(_ManualCompactRequest request) async {
  final _ = await request.ref.read(
    compactConversationUsecaseProvider(request.workspaceId),
  )(conversationId: request.conversationId, trigger: CompactionTrigger.manual);
}

void _showManualCompactSuccess(BuildContext context) {
  if (!context.mounted) return;

  final _ = AuraSnackBars.show(
    context: context,
    content: Text(LocaleKeys.compaction_manual_success.tr()),
    variant: .success,
  );
}

void _showManualCompactFailure(BuildContext context) {
  if (!context.mounted) return;

  final _ = AuraSnackBars.show(
    context: context,
    content: Text(LocaleKeys.compaction_manual_failure.tr()),
    variant: .error,
  );
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

    return _ChatListContent(
      chatMessages: chatMessages,
      workspaceId: workspaceId,
      conversationId: conversationId,
      pendingToolCalls: pendingToolCalls,
      showThinking: showThinking,
    );
  }
}

class const _ChatListContent({
  required final AsyncValue<List<MessageEntity>> chatMessages,
  required final String workspaceId,
  required final String conversationId,
  required final List<PendingToolCall> pendingToolCalls,
  required final bool showThinking,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (_isChatMessagesLoading(chatMessages)) return const _ChatListLoading();

    return _ChatListErrorOrResult(
      chatMessages: chatMessages,
      workspaceId: workspaceId,
      conversationId: conversationId,
      pendingToolCalls: pendingToolCalls,
      showThinking: showThinking,
    );
  }
}

class const _ChatListErrorOrResult({
  required final AsyncValue<List<MessageEntity>> chatMessages,
  required final String workspaceId,
  required final String conversationId,
  required final List<PendingToolCall> pendingToolCalls,
  required final bool showThinking,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final asyncError = chatMessages.asError;
    if (asyncError != null) {
      return _ChatListError(
        error: asyncError.error,
        stackTrace: asyncError.stackTrace,
      );
    }

    return _ChatListResult(
      workspaceId: workspaceId,
      conversationId: conversationId,
      messages: chatMessages.value ?? const <MessageEntity>[],
      pendingToolCalls: pendingToolCalls,
      showThinking: showThinking,
    );
  }
}

bool _isChatMessagesLoading(AsyncValue<List<MessageEntity>> state) =>
    state.isLoading && state.value == null;

class const _ChatListLoading() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Center(child: AuraSpinner());
}

class const _ChatListError({
  required final Object error,
  required final StackTrace stackTrace,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      AppErrorWidget(error: error, stackTrace: stackTrace);
}

class const _ChatListResult({
  required final String workspaceId,
  required final String conversationId,
  required final Iterable<MessageEntity> messages,
  required final List<PendingToolCall> pendingToolCalls,
  required final bool showThinking,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final messageData = _chatMessageData(messages);

    return ChatMessagesWidget(
      workspaceId: workspaceId,
      conversationId: conversationId,
      messages: messageData.ids,
      messageEntitiesById: messageData.entitiesById,
      pendingToolCalls: pendingToolCalls,
      showThinking: showThinking,
    );
  }
}

class const _ChatMessageData({
  required final List<String> ids,
  required final Map<String, MessageEntity> entitiesById,
});

_ChatMessageData _chatMessageData(Iterable<MessageEntity> messages) {
  final ids = List<String>.unmodifiable(messages.map((message) => message.id));
  final entitiesById = <String, MessageEntity>{
    for (final message in messages) message.id: message,
  };

  return _ChatMessageData(ids: ids, entitiesById: entitiesById);
}
