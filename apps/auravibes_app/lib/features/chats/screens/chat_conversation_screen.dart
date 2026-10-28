// Required: Existing test and UI helpers keep compact return flow.
// Required: UI callbacks stay local to their widgets.
// Required: Existing code repeats lookups where extraction adds noise.
// Required: Feature widgets keep closely related private widgets together.
// Required: Existing helpers remain top-level for local feature use.

import 'dart:async';

import 'package:auravibes_app/data/repositories/side_panel_preferences_repository.dart';
import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/entities/provider_recovery_metadata.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/domain/exceptions/compaction_exception.dart';
import 'package:auravibes_app/features/agents/widgets/compact_agent_selector.dart';
import 'package:auravibes_app/features/browser/models/browser_session_state.dart';
import 'package:auravibes_app/features/browser/models/sidebar_tool_result_tab.dart';
import 'package:auravibes_app/features/browser/providers/browser_session_notifier.dart';
import 'package:auravibes_app/features/browser/providers/sidebar_workspace_tab_count.dart';
import 'package:auravibes_app/features/browser/screens/browser_panel.dart';
import 'package:auravibes_app/features/chats/agent_adapters/agent_transcript_context_decode_exception.dart';
import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/chats/models/cloud_conversation_state.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_queued_draft.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_result.dart';
import 'package:auravibes_app/features/chats/notifiers/mcp_elicitation_notifier.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/providers/aura_agent_service_provider.dart';
import 'package:auravibes_app/features/chats/providers/background_work_continuation_provider.dart';
import 'package:auravibes_app/features/chats/providers/cloud_conversation_stream.dart';
import 'package:auravibes_app/features/chats/providers/cloud_turn_provider.dart';
import 'package:auravibes_app/features/chats/providers/compaction_execution.dart';
import 'package:auravibes_app/features/chats/providers/conversation_agent_language_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_archive_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/providers/conversation_streaming_runtime.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_app/features/chats/services/chat_attachment_modality.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_turn_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/compact_conversation_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/conversation_busy_state.dart';
import 'package:auravibes_app/features/chats/usecases/message_persisted_exception.dart';
import 'package:auravibes_app/features/chats/usecases/send_message_usecase.dart';
import 'package:auravibes_app/features/chats/widgets/active_sub_agent_status_widget.dart';
import 'package:auravibes_app/features/chats/widgets/background_work_continuation_status.dart';
import 'package:auravibes_app/features/chats/widgets/background_work_detach_controls.dart';
import 'package:auravibes_app/features/chats/widgets/background_work_header_button.dart';
import 'package:auravibes_app/features/chats/widgets/chat_input_widget.dart';
import 'package:auravibes_app/features/chats/widgets/chat_mcp_elicitation_card.dart';
import 'package:auravibes_app/features/chats/widgets/chat_messages_widget.dart';
import 'package:auravibes_app/features/chats/widgets/chat_queued_messages_indicator.dart';
import 'package:auravibes_app/features/chats/widgets/chat_reasoning_controls.dart';
import 'package:auravibes_app/features/chats/widgets/chat_tool_approval_card.dart';
import 'package:auravibes_app/features/chats/widgets/conversation_context_usage_pill.dart';
import 'package:auravibes_app/features/chats/widgets/model_usage_header_button.dart';
import 'package:auravibes_app/features/chats/widgets/responsive_conversation_layout.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selection_providers.dart';
import 'package:auravibes_app/features/models/widgets/compact_workspace_model_selector.dart';
import 'package:auravibes_app/features/skills/widgets/conversation_skill_selector_modal.dart';
import 'package:auravibes_app/features/tools/widgets/tools_management_modal.dart';
import 'package:auravibes_app/features/workspaces/notifiers/workspace_open_view_notifier.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_view_browser_toggle.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_view_chat_button.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_view_chat_layout.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_view_tool_observer.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/utils/number_formatter.dart';
import 'package:auravibes_app/widgets/app_error_widget.dart';
import 'package:auravibes_app/widgets/app_screen.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_engine/auravibes_engine.dart'
    show
        AgentIterationDecision,
        ConversationToolAccessMode,
        ReasoningConfiguration,
        ReasoningOption,
        SelectedModelNotFoundException;
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

typedef _BackgroundWorkStatusPresence = ({
  bool hasDetachableToolCalls,
  bool hasBackgroundWorks,
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
  String languageCode,
});

typedef _SendMessageRequest = ({
  BuildContext context,
  WidgetRef ref,
  String workspaceId,
  String conversationId,
  ChatDraft draft,
});

typedef _RetryMessageRequest = ({
  BuildContext context,
  WidgetRef ref,
  String workspaceId,
  String conversationId,
  MessageEntity message,
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

typedef _LoadedSidePanelValues = ({
  bool isVisible,
  bool isMounted,
  double widthPercent,
  List<SidebarToolResultTab> toolResultTabs,
  String? selectedToolResultTabId,
});
typedef _LoadedConversationSidePanel = ({
  _LoadedSidePanelValues values,
  _LoadedSidePanelActions actions,
});
typedef _LoadedSidePanelRequest = ({
  BuildContext context,
  WidgetRef ref,
  String conversationId,
  _SidePanelHookValues panel,
  _ToolResultTabHookValues tabs,
  AsyncValue<SharedPreferences> preferencesAsync,
  int? browserActionRevision,
  ObjectRef<bool> hasAutoOpenedSidebar,
});

typedef _SidePanelHookValues = ({
  ValueNotifier<bool> visible,
  ValueNotifier<bool> mounted,
  ValueNotifier<double> widthPercent,
  _SidePanelHookFlags flags,
});

typedef _ToolResultTabHookValues = ({
  ValueNotifier<List<SidebarToolResultTab>> tabs,
  ValueNotifier<String?> selectedId,
});
typedef _BrowserActionSidebarEffectRequest = ({
  int? revision,
  AsyncValue<SharedPreferences> preferencesAsync,
  ValueNotifier<String?> selectedTabId,
  ObjectRef<bool> hasAutoOpenedSidebar,
  VoidCallback openSidebar,
});

class _SidePanelHookFlags(final String conversationId) {
  bool preferencesLoaded = false;
  bool visibilityChanged = false;
  bool widthChanged = false;
}

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
      const AppScreen(child: Center(child: AuraSpinner()));
}

class const _ConversationLoadError({
  required final Object error,
  required final StackTrace stackTrace,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AppScreen(
    child: AppErrorWidget(error: error, stackTrace: stackTrace),
  );
}

class const _ConversationResultError({
  required final ConversationResult? result,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AppScreen(
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
  Widget build(BuildContext context, WidgetRef ref) {
    final request = (
      context: context,
      ref: ref,
      workspaceId: workspaceId,
      conversation: conversation,
    );
    _listenForPendingIterationLimitNotice(request);

    final runtimeState = _useLoadedChatConversationRuntimeState(request);

    return _LoadedChatConversationRender(
      workspaceId: workspaceId,
      conversation: conversation,
      runtimeState: runtimeState,
      showInputComposer: showInputComposer,
      leading: showInputComposer ? null : const _ChatConversationBackButton(),
    );
  }
}

void _listenForPendingIterationLimitNotice(_LoadedRuntimeRequest request) {
  final iterationLimitProvider = conversationIterationLimitProvider(
    request.conversation.id,
  );
  if (request.ref.read(iterationLimitProvider)) {
    _schedulePendingIterationLimitNotice(request);
  }
  request.ref.listen(iterationLimitProvider, (_, pending) {
    if (pending) _schedulePendingIterationLimitNotice(request);
  });
}

void _schedulePendingIterationLimitNotice(_LoadedRuntimeRequest request) =>
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _showPendingIterationLimitNotice(request),
    );

void _showPendingIterationLimitNotice(_LoadedRuntimeRequest request) {
  if (!request.context.mounted) return;

  final conversationId = request.conversation.id;
  request.ref
      .read(conversationIterationLimitProvider(conversationId).notifier)
      .consume();
  final conversationContextRequest = (
    context: request.context,
    ref: request.ref,
    workspaceId: request.workspaceId,
    conversationId: conversationId,
  );
  _showIterationLimitNoticeForConversation(
    conversationContextRequest,
    .iterationLimitReached,
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
  required final Future<void> Function(MessageEntity) onRetryMessage,
  required final VoidCallback onCompact,
});

typedef _LoadedChatConversationCoreCallbacks = ({
  VoidCallback onToolsPress,
  VoidCallback onStop,
  Future<void> Function(ChatDraft) onSendMessage,
  Future<void> Function(MessageEntity) onRetryMessage,
  VoidCallback onCompact,
});

typedef _LoadedChatConversationSelectorCallbacks = ({
  ValueChanged<String?> onModelChanged,
  ValueChanged<String?> onModelSelectionChanged,
  ValueChanged<String?> onAgentChanged,
  ValueChanged<ConversationToolAccessMode> onToolAccessModeChanged,
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
    onRetryMessage: _useRetryMessageCallback(callbacks),
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

Future<void> Function(MessageEntity) _useRetryMessageCallback(
  _LoadedChatConversationCallbacks callbacks,
) => useCallback<Future<void> Function(MessageEntity)>(
  callbacks.core.onRetryMessage,
  [callbacks.ref, callbacks.workspaceId, callbacks.conversationId],
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
  onRetryMessage: _loadedConversationRetryMessage(request),
  onCompact: _loadedConversationCompact(request),
);

_LoadedChatConversationSelectorCallbacks _loadedConversationSelectorCallbacks(
  _LoadedRuntimeRequest request,
) => (
  onModelChanged: _loadedConversationModelChanged(request),
  onModelSelectionChanged: _loadedConversationModelChanged(request),
  onAgentChanged: _agentChanged(request),
  onToolAccessModeChanged: _toolAccessModeChanged(request),
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
    (draft) => _sendMessage(_loadedConversationSendRequest(request, draft));

_SendMessageRequest _loadedConversationSendRequest(
  _LoadedRuntimeRequest request,
  ChatDraft draft,
) => (
  context: request.context,
  ref: request.ref,
  workspaceId: request.workspaceId,
  conversationId: request.conversation.id,
  draft: draft.withLanguageCode(request.context.locale.languageCode),
);

Future<void> Function(MessageEntity) _loadedConversationRetryMessage(
  _LoadedRuntimeRequest request,
) =>
    (message) => _retryMessage((
      context: request.context,
      ref: request.ref,
      workspaceId: request.workspaceId,
      conversationId: request.conversation.id,
      message: message,
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

ValueChanged<ConversationToolAccessMode> _toolAccessModeChanged(
  _LoadedRuntimeRequest request,
) =>
    (mode) => unawaited(_setToolAccessMode(request, mode));

Future<void> _setToolAccessMode(
  _LoadedRuntimeRequest request,
  ConversationToolAccessMode mode,
) async {
  try {
    await request.ref
        .read(
          conversationChatProvider(
            request.workspaceId,
            request.conversation.id,
          ).notifier,
        )
        .setToolAccessMode(mode);
  } on Exception catch (error, stackTrace) {
    _handleToolAccessModeError(request, error, stackTrace);
  }
}

void _handleToolAccessModeError(
  _LoadedRuntimeRequest request,
  Exception error,
  StackTrace stackTrace,
) {
  _logger.severe('Failed to update tool approval mode', error, stackTrace);
  if (!request.context.mounted) return;

  final _ = AuraSnackBars.show(
    context: request.context,
    content: const TextLocale(LocaleKeys.common_error_message),
    variant: .error,
  );
}

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
  required final bool isAgentWorking,
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
  isAgentWorking: _isAgentWorkingFromCore(request.core),
);

bool _isAgentWorkingFromCore(_LoadedChatConversationCoreState core) =>
    _isAgentWorking(
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
  required final bool isAgentWorking,
});

class const _LoadedChatConversationData({
  required final String workspaceId,
  required final ConversationEntity conversation,
  required final _LoadedChatConversationState state,
  required final bool hidesStoppedRun,
  required final bool isStopRequested,
  required final bool showInputComposer,
  required final _LoadedChatConversationCallbackState callbacks,
  required final Widget? leading,
});

class const _LoadedChatConversationRuntimeState({
  required final _LoadedChatConversationCallbackState callbacks,
  required final _LoadedChatConversationState state,
  required final bool hidesStoppedRun,
  required final bool isStopRequested,
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
  isStopRequested: request.stopRequested.value,
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
      isStopRequested: runtimeState.isStopRequested,
      showInputComposer: showInputComposer,
      callbacks: runtimeState.callbacks,
      leading: leading,
    ),
    key: ValueKey((workspaceId: workspaceId, conversationId: conversation.id)),
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
  isAgentWorking: activity.isAgentWorking,
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
  if (!request.isCloud) return _watchLocalPendingCalls(request);
  final childStates = _watchCloudChildStates(request);

  return CloudMessageTools.pendingToolCalls(
    request.cloudConversation,
    childStates: childStates,
  );
}

List<CloudConversationState> _watchCloudChildStates(
  _PendingCallsRequest request,
) {
  final childIds = CloudMessageTools.childConversationIds(
    request.cloudConversation,
  );

  return [
    for (final childId in childIds)
      ?request.ref
          .watch(
            cloudConversationStateProvider((
              workspaceId: request.workspaceId,
              conversationId: childId,
            )),
          )
          .value,
  ];
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

bool _isAgentWorking({
  required bool isCloud,
  required CloudConversationState? cloudConversation,
  required ConversationBusyState? busyState,
}) {
  if (isCloud) {
    return cloudConversation?.conversation.executionState == 'running';
  }

  return busyState?.isStreaming == true || busyState?.isAgentWorking == true;
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

void _openSidebarForBrowserAction(
  int? actionRevision,
  ObjectRef<bool> hasAutoOpened,
  ValueNotifier<String?> selectedToolResultTabId,
  VoidCallback onOpen,
) {
  if ((actionRevision ?? 0) == 0 || hasAutoOpened.value) return;
  hasAutoOpened.value = true;
  selectedToolResultTabId.value = null;
  onOpen();
}

Future<void> _persistSidePanelOpen(
  WidgetRef ref, {
  required String conversationId,
  required bool isOpen,
}) async {
  try {
    final preferences = await ref.read(sharedPreferencesProvider.future);
    await SidePanelPreferencesRepository(preferences)
        .saveIsOpen(conversationId: conversationId, isOpen: isOpen);
  } on Object {
    return;
  }
}

Future<void> _persistSidePanelWidth(WidgetRef ref, double widthPercent) async {
  try {
    final preferences = await ref.read(sharedPreferencesProvider.future);
    await SidePanelPreferencesRepository(preferences)
        .saveWidthPercent(widthPercent);
  } on Object {
    return;
  }
}

class const _LoadedChatConversationView({
  required final _LoadedChatConversationData data,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final browserSession = ref
        .watch(browserSessionProvider(data.workspaceId, data.conversation.id))
        .value;
    final sidePanel = _useLoadedConversationSidePanel(
      context: context,
      ref: ref,
      conversationId: data.conversation.id,
      browserActionRevision: browserSession?.agentActionRevision,
    );

    return _LoadedChatConversationScreen(
      data: data,
      browserSession: browserSession,
      sidePanel: sidePanel,
    );
  }
}

_LoadedConversationSidePanel _useLoadedConversationSidePanel({
  required BuildContext context,
  required WidgetRef ref,
  required String conversationId,
  required int? browserActionRevision,
}) {
  final preferencesAsync = ref.watch(sharedPreferencesProvider);
  final panel = _useSidePanelHookValues(conversationId);
  final tabs = _useToolResultTabHookValues();
  final hasAutoOpenedSidebar = useRef(false);

  return _prepareLoadedConversationSidePanel((
    context: context,
    ref: ref,
    conversationId: conversationId,
    panel: panel,
    tabs: tabs,
    preferencesAsync: preferencesAsync,
    browserActionRevision: browserActionRevision,
    hasAutoOpenedSidebar: hasAutoOpenedSidebar,
  ));
}

_LoadedConversationSidePanel _prepareLoadedConversationSidePanel(
  _LoadedSidePanelRequest request,
) {
  _useStoredSidePanelPreferences(
    request.preferencesAsync,
    request.panel,
    request.conversationId,
  );
  _useBrowserActionSidebarEffect((
    revision: request.browserActionRevision,
    preferencesAsync: request.preferencesAsync,
    selectedTabId: request.tabs.selectedId,
    hasAutoOpenedSidebar: request.hasAutoOpenedSidebar,
    openSidebar: () =>
        _setSidePanelOpen(request.ref, request.panel, isOpen: true),
  ));

  return _loadedConversationSidePanelState(request);
}

_SidePanelHookValues _useSidePanelHookValues(String conversationId) => (
  visible: useState(false),
  mounted: useState(false),
  widthPercent: useState(SidePanelPreferencesRepository.defaultWidthPercent),
  flags: useMemoized(() => _SidePanelHookFlags(conversationId), [
    conversationId,
  ]),
);

_ToolResultTabHookValues _useToolResultTabHookValues() => (
  tabs: useState<List<SidebarToolResultTab>>([]),
  selectedId: useState<String?>(null),
);

void _useStoredSidePanelPreferences(
  AsyncValue<SharedPreferences> preferencesAsync,
  _SidePanelHookValues panel,
  String conversationId,
) {
  useEffect(
    () => _restoreSidePanelPreferences(preferencesAsync, panel, conversationId),
    [preferencesAsync.value, preferencesAsync.hasError, conversationId],
  );
}

VoidCallback? _restoreSidePanelPreferences(
  AsyncValue<SharedPreferences> preferencesAsync,
  _SidePanelHookValues panel,
  String conversationId,
) {
  final preferences = preferencesAsync.value;
  if (preferences == null && !preferencesAsync.hasError) return null;
  if (preferences != null) {
    _applySidePanelPreferences(preferences, panel, conversationId);
  }

  return null;
}

void _applySidePanelPreferences(
  SharedPreferences preferences,
  _SidePanelHookValues panel,
  String conversationId,
) {
  final flags = panel.flags;
  if (flags.preferencesLoaded) return;
  flags.preferencesLoaded = true;
  final stored = SidePanelPreferencesRepository(preferences);
  if (!flags.widthChanged) {
    panel.widthPercent.value = stored.widthPercent;
  }
  if (flags.visibilityChanged) return;
  final isOpen = stored.isOpenFor(conversationId);
  panel.mounted.value = isOpen;
  panel.visible.value = isOpen;
}

void _useBrowserActionSidebarEffect(
  _BrowserActionSidebarEffectRequest request,
) {
  useEffect(() => _openBrowserActionSidebar(request), [
    request.revision,
    request.preferencesAsync.value,
    request.preferencesAsync.hasError,
  ]);
}

VoidCallback? _openBrowserActionSidebar(
  _BrowserActionSidebarEffectRequest request,
) {
  if (request.preferencesAsync.value == null &&
      !request.preferencesAsync.hasError) {
    return null;
  }
  _openSidebarForBrowserAction(
    request.revision,
    request.hasAutoOpenedSidebar,
    request.selectedTabId,
    request.openSidebar,
  );

  return null;
}

_LoadedConversationSidePanel _loadedConversationSidePanelState(
  _LoadedSidePanelRequest request,
) => (
  values: _loadedSidePanelValues(request.panel, request.tabs),
  actions: _loadedSidePanelActions(request),
);

_LoadedSidePanelValues _loadedSidePanelValues(
  _SidePanelHookValues panel,
  _ToolResultTabHookValues tabs,
) => (
  isVisible: panel.visible.value,
  isMounted: panel.mounted.value,
  widthPercent: panel.widthPercent.value,
  toolResultTabs: tabs.tabs.value,
  selectedToolResultTabId: tabs.selectedId.value,
);

_LoadedSidePanelActions _loadedSidePanelActions(
  _LoadedSidePanelRequest request,
) => _LoadedSidePanelActions(
  context: request.context,
  ref: request.ref,
  panel: request.panel,
  tabs: request.tabs,
);

void _setSidePanelOpen(
  WidgetRef ref,
  _SidePanelHookValues panel, {
  required bool isOpen,
}) {
  panel.flags.visibilityChanged = true;
  if (isOpen) panel.mounted.value = true;
  panel.visible.value = isOpen;
  unawaited(
    _persistSidePanelOpen(
      ref,
      conversationId: panel.flags.conversationId,
      isOpen: isOpen,
    ),
  );
}

void _toggleSidePanel(
  BuildContext context,
  WidgetRef ref,
  _SidePanelHookValues panel,
) {
  if (!panel.visible.value) {
    FocusScope.of(context).unfocus();
    _setSidePanelOpen(ref, panel, isOpen: true);

    return;
  }
  _setSidePanelOpen(ref, panel, isOpen: false);
}

void _updateSidePanelWidth(
  WidgetRef ref,
  _SidePanelHookValues panel,
  double widthPercent,
) {
  panel.flags.widthChanged = true;
  panel.widthPercent.value = widthPercent;
  unawaited(_persistSidePanelWidth(ref, widthPercent));
}

void _closeToolResult(_ToolResultTabHookValues tabs, String id) {
  tabs.tabs.value = tabs.tabs.value.where((tab) => tab.id != id).toList();
  if (tabs.selectedId.value == id) tabs.selectedId.value = null;
}

class const _LoadedSidePanelActions({
  required final BuildContext context,
  required final WidgetRef ref,
  required final _SidePanelHookValues panel,
  required final _ToolResultTabHookValues tabs,
}) {
  void onToggle() => _toggleSidePanel(context, ref, panel);

  void onClose() => _setSidePanelOpen(ref, panel, isOpen: false);

  void onWidthChanged(double width) => _updateSidePanelWidth(ref, panel, width);

  void onOpenToolResult(SidebarToolResultTab tab) {
    _upsertToolResultTab(tabs, tab);
    _setSelectedToolResult(tabs.selectedId, tab.id);
    FocusScope.of(context).unfocus();
    _setSidePanelOpen(ref, panel, isOpen: true);
  }

  void onCloseToolResult(String id) => _closeToolResult(tabs, id);

  void onSelectToolResult(String? id) =>
      _setSelectedToolResult(tabs.selectedId, id);
}

void _upsertToolResultTab(
  _ToolResultTabHookValues tabs,
  SidebarToolResultTab tab,
) {
  final existingTabs = tabs.tabs.value;
  final updatedTabs = existingTabs.where((existing) => existing.id != tab.id);
  tabs.tabs.value = [...updatedTabs, tab];
}

void _setSelectedToolResult(ValueNotifier<String?> selectedId, String? id) =>
    selectedId.value = id;

class const _LoadedChatConversationScreen({
  required final _LoadedChatConversationData data,
  required final BrowserSessionState? browserSession,
  required final _LoadedConversationSidePanel sidePanel,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceTabs = useValueListenable(
      ref.watch(
        sidebarWorkspaceTabCountProvider((
          workspaceId: data.workspaceId,
          conversationId: data.conversation.id,
        )),
      ),
    );

    return ChatPrimaryScrollController(
      child: AppScreen(
        child: WorkspaceViewToolObserver(
          workspaceId: data.workspaceId,
          conversationId: data.conversation.id,
          child: _LoadedChatConversationLayout(
            data: data,
            sidePanel: sidePanel,
          ),
        ),
        appBar: _ChatConversationAppBar(
          data: data,
          actions: _chatConversationAppBarActions(
            data,
            sidePanel,
            browserSession,
            workspaceTabs,
          ),
        ),
      ),
    );
  }
}

_ChatConversationAppBarActions _chatConversationAppBarActions(
  _LoadedChatConversationData data,
  _LoadedConversationSidePanel sidePanel,
  BrowserSessionState? browserSession,
  int workspaceTabs,
) => .new(
  workspaceId: data.workspaceId,
  conversationId: data.conversation.id,
  sidePanelVisible: sidePanel.values.isVisible,
  tabCount: _browserTabCount(
    browserSession,
    sidePanel.values.toolResultTabs,
    workspaceTabs,
  ),
  onSidebarToggle: sidePanel.actions.onToggle,
);

int? _browserTabCount(
  BrowserSessionState? browserSession,
  List<SidebarToolResultTab> resultTabs,
  int workspaceTabs,
) => browserSession == null && workspaceTabs == 0
    ? null
    : (browserSession?.tabs.length ?? 0) + resultTabs.length + workspaceTabs;

class const _LoadedChatConversationLayout({
  required final _LoadedChatConversationData data,
  required final _LoadedConversationSidePanel sidePanel,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final values = sidePanel.values;
    final actions = sidePanel.actions;

    return WorkspaceViewChatLayout(
      workspaceId: data.workspaceId,
      conversationId: data.conversation.id,
      mainContent: _LoadedChatConversationMain(data: data, actions: actions),
      fallbackSidePanel: _loadedChatConversationSidePanel(
        data,
        values,
        actions,
      ),
    );
  }
}

ResponsiveConversationSidePanel _loadedChatConversationSidePanel(
  _LoadedChatConversationData data,
  _LoadedSidePanelValues values,
  _LoadedSidePanelActions actions,
) => .new(
  visible: values.isVisible,
  mounted: values.isMounted,
  widthPercent: values.widthPercent,
  onWidthChanged: actions.onWidthChanged,
  onClose: actions.onClose,
  builder: () =>
      _LoadedChatBrowserPanel(data: data, values: values, actions: actions),
);

class const _LoadedChatConversationMain({
  required final _LoadedChatConversationData data,
  required final _LoadedSidePanelActions actions,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => _ChatConversationBody(
    data: data,
    onOpenToolResult: (tab) => _open(ref, tab),
  );
  void _open(WidgetRef ref, SidebarToolResultTab tab) {
    ref
        .read(
          workspaceOpenViewProvider(
            data.workspaceId,
            data.conversation.id,
          ).notifier,
        )
        .close();
    actions.onOpenToolResult(tab);
  }
}

class const _ChatConversationAppBar({
  required final _LoadedChatConversationData data,
  required final _ChatConversationAppBarActions actions,
}) extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AuraAppBarWithDrawer(
    title: Text(data.conversation.title),
    actions: actions.widgets,
    leading: data.leading,
  );
}

class _ChatConversationAppBarActions({
  required String workspaceId,
  required String conversationId,
  required bool sidePanelVisible,
  required int? tabCount,
  required VoidCallback onSidebarToggle,
}) {
  final List<Widget> widgets = [
    WorkspaceViewChatButton(
      workspaceId: workspaceId,
      conversationId: conversationId,
    ),
    ModelUsageHeaderButton(conversationId: conversationId),
    BackgroundWorkHeaderButton(
      workspaceId: workspaceId,
      conversationId: conversationId,
    ),
    _ConversationBookmarksButton(
      workspaceId: workspaceId,
      conversationId: conversationId,
    ),
    WorkspaceViewBrowserToggle(
      workspaceId: workspaceId,
      conversationId: conversationId,
      isPanelVisible: sidePanelVisible,
      tabCount: tabCount,
      onPressed: onSidebarToggle,
    ),
  ];
}

class const _ConversationBookmarksButton({
  required final String workspaceId,
  required final String conversationId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraIconButton(
    icon: Icons.bookmark_border,
    onPressed: () => MessageBookmarksRoute(
      workspaceId: workspaceId,
      conversationId: conversationId,
    ).go(context),
    tooltip: LocaleKeys.chats_screens_chats_list_saved_messages.tr(),
  );
}

class const _LoadedChatBrowserPanel({
  required final _LoadedChatConversationData data,
  required final _LoadedSidePanelValues values,
  required final _LoadedSidePanelActions actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => BrowserPanel(
    workspaceId: data.workspaceId,
    conversationId: data.conversation.id,
    toolResultTabs: values.toolResultTabs,
    selectedToolResultTabId: values.selectedToolResultTabId,
    onSelectToolResultTab: actions.onSelectToolResult,
    onCloseToolResultTab: actions.onCloseToolResult,
    onCloseSidebar: actions.onClose,
  );
}

class const _ChatConversationBody({
  required final _LoadedChatConversationData data,
  required final ValueChanged<SidebarToolResultTab> onOpenToolResult,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backgroundWorkStatus = _backgroundWorkStatusPresence(ref, data);
    final hasOtherStatus = _hasChatConversationStatus(data);
    final hasStatusArea = _hasChatConversationStatusArea(
      ref,
      data,
      backgroundWorkStatus,
      hasOtherStatus,
    );

    return _ChatConversationBodyLayout(
      data: data,
      onOpenToolResult: onOpenToolResult,
      backgroundWorkStatus: backgroundWorkStatus,
      hasOtherStatus: hasOtherStatus,
      hasStatusArea: hasStatusArea,
    );
  }
}

bool _hasChatConversationStatusArea(
  WidgetRef ref,
  _LoadedChatConversationData data,
  _BackgroundWorkStatusPresence backgroundWorkStatus,
  bool hasOtherStatus,
) =>
    backgroundWorkStatus.hasDetachableToolCalls ||
    backgroundWorkStatus.hasBackgroundWorks ||
    hasOtherStatus ||
    ref.watch(mcpElicitationProvider(data.conversation.id)).isNotEmpty ||
    data.showInputComposer;

_BackgroundWorkStatusPresence _backgroundWorkStatusPresence(
  WidgetRef ref,
  _LoadedChatConversationData data,
) {
  final key = (
    workspaceId: data.workspaceId,
    conversationId: data.conversation.id,
  );
  final detachableToolCalls = ref.watch(
    backgroundDetachableToolCallsProvider(key),
  );
  final backgroundWorks = ref.watch(backgroundWorkContinuationsProvider(key));

  return (
    hasDetachableToolCalls: detachableToolCalls.isNotEmpty,
    hasBackgroundWorks: backgroundWorks.value?.isNotEmpty ?? false,
  );
}

class const _ChatConversationBodyLayout({
  required final _LoadedChatConversationData data,
  required final ValueChanged<SidebarToolResultTab> onOpenToolResult,
  required final _BackgroundWorkStatusPresence backgroundWorkStatus,
  required final bool hasOtherStatus,
  required final bool hasStatusArea,
}) extends StatelessWidget {
  CloudConversationKey get _conversationKey =>
      (workspaceId: data.workspaceId, conversationId: data.conversation.id);

  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      _ConversationOrientation(data: data),
      _IncompleteImportedAgentContextNotice(data: data),
      _ChatConversationControls(data: data),
      _CloudConversationStreamRecovery(conversationKey: _conversationKey),
      Expanded(
        child: _ChatConversationBodyContent(
          data: data,
          onOpenToolResult: onOpenToolResult,
          statusArea: hasStatusArea
              ? _ChatConversationStatusArea(
                  data: data,
                  backgroundWorkStatus: backgroundWorkStatus,
                  hasOtherStatus: hasOtherStatus,
                )
              : null,
        ),
      ),
    ],
    spacing: .none,
  );
}

class const _ChatConversationBodyContent({
  required final _LoadedChatConversationData data,
  required final ValueChanged<SidebarToolResultTab> onOpenToolResult,
  required final Widget? statusArea,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => AuraColumn(
      children: [
        _ChatConversationMessageList(
          data: data,
          onOpenToolResult: onOpenToolResult,
        ),
        _ScrollableConversationStatus(
          maxHeight: constraints.maxHeight,
          child: statusArea,
        ),
      ],
      spacing: .none,
    ),
  );
}

class const _ScrollableConversationStatus({
  required final double maxHeight,
  required final Widget? child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final child = this.child;
    if (child == null) return const SizedBox.shrink();

    return ConstrainedBox(
      constraints: .new(maxHeight: maxHeight),
      child: SingleChildScrollView(primary: false, child: child),
    );
  }
}

class const _CloudConversationStreamRecovery({
  required final CloudConversationKey conversationKey,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_isCloudWorkspace(ref, conversationKey.workspaceId)) {
      return const SizedBox.shrink();
    }

    final provider = cloudConversationStateProvider(conversationKey);
    final error = ref.watch(provider).error;
    if (error == null) return const SizedBox.shrink();

    return _CloudConversationStreamRecoveryContent(
      error: error,
      onRetry: () => ref.invalidate(provider),
    );
  }
}

class const _CloudConversationStreamRecoveryContent({
  required final Object error,
  required final VoidCallback onRetry,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraPadding(
    child: AuraColumn(
      children: [
        _CloudConversationStreamFailureCallout(error: error),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: AuraButton(
            onPressed: onRetry,
            child: const TextLocale(LocaleKeys.route_state_retry),
          ),
        ),
      ],
      spacing: .sm,
      mainAxisSize: .min,
    ),
    padding: const .horizontal(.md),
  );
}

class const _CloudConversationStreamFailureCallout({
  required final Object error,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final errorMessageKey = switch (error) {
      CloudConversationStreamFailure(:final localizationKey) => localizationKey,
      _ => CloudAppErrors.localizationKey(error),
    };

    return AuraCallout(
      title: LocaleKeys.common_error_title.tr(context: context),
      description: errorMessageKey.tr(context: context),
      icon: Icons.cloud_off_outlined,
      tint: .error,
    );
  }
}

class const _ChatConversationStatusArea({
  required final _LoadedChatConversationData data,
  required final _BackgroundWorkStatusPresence backgroundWorkStatus,
  required final bool hasOtherStatus,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      if (backgroundWorkStatus.hasDetachableToolCalls ||
          backgroundWorkStatus.hasBackgroundWorks)
        _BackgroundWorkStatus(data: data, presence: backgroundWorkStatus),
      ChatMcpElicitationCard(conversationId: data.conversation.id),
      _ChatConversationComposerStatus(
        data: data,
        hasOtherStatus: hasOtherStatus,
      ),
    ],
    mainAxisSize: .min,
  );
}

class const _ChatConversationComposerStatus({
  required final _LoadedChatConversationData data,
  required final bool hasOtherStatus,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (!hasOtherStatus && !data.showInputComposer) {
      return const SizedBox.shrink();
    }

    return _ChatConversationStatusAndComposer(
      data: data,
      key: ValueKey((
        workspaceId: data.workspaceId,
        conversationId: data.conversation.id,
      )),
    );
  }
}

class const _IncompleteImportedAgentContextNotice({
  required final _LoadedChatConversationData data,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_hasIncompleteAgentContext(ref)) return const SizedBox.shrink();

    return const _IncompleteAgentContextNoticeContent();
  }

  bool _hasIncompleteAgentContext(WidgetRef ref) =>
      ref
          .watch(
            conversationArchiveIncompleteContextProvider((
              workspaceId: data.workspaceId,
              conversationId: data.conversation.id,
            )),
          )
          .value ==
      true;
}

class const _IncompleteAgentContextNoticeContent() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraPadding(
    child: AuraCallout(
      title: LocaleKeys.chats_screens_chat_conversation_context_incomplete_title
          .tr(context: context),
      key: const ValueKey<String>('chat_incomplete_agent_context_notice'),
      description: LocaleKeys
          .chats_screens_chat_conversation_context_incomplete_description
          .tr(context: context),
      icon: Icons.warning_amber_outlined,
      tint: .warning,
    ),
    padding: const .horizontal(.md),
  );
}

class const _ChatConversationStatusAndComposer({
  required final _LoadedChatConversationData data,
  super.key,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final draftToLoad = useState<ChatDraft?>(null);
    void editDraft(ChatDraft draft) => draftToLoad.value = draft;

    final onEditDraft = data.showInputComposer ? editDraft : null;

    return _ChatConversationStatusAndComposerView(
      data: data,
      draftToLoad: draftToLoad.value,
      onEditDraft: onEditDraft,
    );
  }
}

class const _ChatConversationStatusAndComposerView({
  required final _LoadedChatConversationData data,
  required final ChatDraft? draftToLoad,
  required final ValueChanged<ChatDraft>? onEditDraft,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      if (_hasChatConversationStatus(data))
        _OtherConversationStatus(data: data, onEditDraft: onEditDraft),
      if (data.showInputComposer)
        _ChatComposer(data: data, draftToLoad: draftToLoad),
    ],
    mainAxisSize: .min,
  );
}

class const _ChatConversationMessageList({
  required final _LoadedChatConversationData data,
  required final ValueChanged<SidebarToolResultTab> onOpenToolResult,
}) extends StatelessWidget {
  Future<void> Function(MessageEntity message)? get _onRetryMessage =>
      data.state.isInputBusy ? null : data.callbacks.hooks.onRetryMessage;

  bool get _showThinking =>
      data.state.isAgentWorking &&
      data.state.rateLimitRetryAt == null &&
      !data.state.isCompacting &&
      !data.hidesStoppedRun;

  @override
  Widget build(BuildContext context) => Expanded(
    child: _ChatList(
      workspaceId: data.workspaceId,
      conversationId: data.conversation.id,
      pendingToolCalls: data.state.pendingCalls,
      isStopRequested: data.isStopRequested,
      onRetryMessage: _onRetryMessage,
      onOpenToolResult: onOpenToolResult,
      showThinking: _showThinking,
    ),
  );
}

class const _ChatConversationControls({
  required final _LoadedChatConversationData data,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      _ChatConversationControlsLayout(
        data: data,
        activity: _conversationActivitySummary(ref, data),
      );
}

typedef _ConversationActivitySummary = ({String activityKey, int childCount});

_ConversationActivitySummary _conversationActivitySummary(
  WidgetRef ref,
  _LoadedChatConversationData data,
) {
  final childCount = _activeConversationChildCount(ref, data.conversation.id);

  return (
    activityKey: _conversationActivityKey((data: data, childCount: childCount)),
    childCount: childCount,
  );
}

class const _ChatConversationControlsLayout({
  required final _LoadedChatConversationData data,
  required final _ConversationActivitySummary activity,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      _ActiveConversationActivityLabel(activity: activity),
      _ChatControlsBar(
        workspaceId: data.workspaceId,
        conversationId: data.conversation.id,
        idleActivitySummary: _IdleConversationActivityLabel(activity: activity),
      ),
    ],
    spacing: activity.activityKey == 'idle' ? .none : .base,
  );
}

class const _ActiveConversationActivityLabel({
  required final _ConversationActivitySummary activity,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => activity.activityKey == 'idle'
      ? const SizedBox.shrink()
      : _ConversationActivityLabel(
          activityKey: activity.activityKey,
          childCount: activity.childCount,
        );
}

class const _IdleConversationActivityLabel({
  required final _ConversationActivitySummary activity,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => activity.activityKey != 'idle'
      ? const SizedBox.shrink()
      : _CompactConversationActivityLabel(
          activityKey: activity.activityKey,
          childCount: activity.childCount,
        );
}

class const _BackgroundWorkStatus({
  required final _LoadedChatConversationData data,
  required final _BackgroundWorkStatusPresence presence,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      if (presence.hasDetachableToolCalls)
        BackgroundWorkDetachControls(
          workspaceId: data.workspaceId,
          conversationId: data.conversation.id,
        ),
      if (presence.hasBackgroundWorks)
        BackgroundWorkContinuationStatus(
          workspaceId: data.workspaceId,
          conversationId: data.conversation.id,
        ),
    ],
    mainAxisSize: .min,
  );
}

class const _OtherConversationStatus({
  required final _LoadedChatConversationData data,
  required final ValueChanged<ChatDraft>? onEditDraft,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final retryAt = data.state.rateLimitRetryAt;

    return AuraColumn(
      children: [
        if (retryAt != null && !data.hidesStoppedRun)
          _RateLimitRetryIndicator(retryAt: retryAt),
        if (data.state.queuedDrafts.isNotEmpty)
          _QueuedMessagesStatus(data: data, onEditDraft: onEditDraft),
        if (data.state.hasPendingApprovals) _ApprovalStatus(data: data),
      ],
      mainAxisSize: .min,
    );
  }
}

class const _QueuedMessagesStatus({
  required final _LoadedChatConversationData data,
  required final ValueChanged<ChatDraft>? onEditDraft,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ChatQueuedMessagesIndicator(
    conversationId: data.conversation.id,
    queuedDrafts: data.state.queuedDrafts,
    onEditDraft: onEditDraft,
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

class const _ChatComposer({
  required final _LoadedChatConversationData data,
  required final ChatDraft? draftToLoad,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modelStatus = _modelStatus(ref);

    return _ChatComposerView(
      data: data,
      modelStatus: modelStatus,
      reasoningSettingsControl: _reasoningSettingsControl(
        ref,
        modelStatus.reasoningOptions,
      ),
      canCompact: _canCompact(ref, modelStatus.available),
      draftToLoad: draftToLoad,
    );
  }

  Widget? _reasoningSettingsControl(
    WidgetRef ref,
    List<ReasoningOption> options,
  ) {
    if (!ChatReasoningControls.hasSupportedReasoningOptions(options)) {
      return null;
    }

    return ChatReasoningControls(
      options: options,
      value: data.conversation.reasoningConfiguration,
      onChanged: (value) =>
          unawaited(_updateReasoningConfiguration(ref, value)),
    );
  }

  Future<void> _updateReasoningConfiguration(
    WidgetRef ref,
    ReasoningConfiguration? value,
  ) {
    final notifier = ref.read(
      conversationChatProvider(data.workspaceId, data.conversation.id).notifier,
    );

    return notifier.setReasoningConfiguration(value);
  }

  _ChatComposerModelStatus _modelStatus(WidgetRef ref) {
    final modelId = data.conversation.modelId;
    final modelState = modelId == null
        ? null
        : ref.watch(
            workspaceModelSelectionByIdProvider(data.workspaceId, modelId),
          );

    return _chatComposerModelStatus(modelId, modelState);
  }

  bool _canCompact(WidgetRef ref, bool modelAvailable) =>
      ref.watch(
        conversationCanCompactProvider(data.workspaceId, data.conversation.id),
      ) &&
      modelAvailable;
}

class _ChatComposerView extends StatelessWidget {
  new({
    required _LoadedChatConversationData data,
    required _ChatComposerModelStatus modelStatus,
    required Widget? reasoningSettingsControl,
    required bool canCompact,
    required ChatDraft? draftToLoad,
  }) : offstage = data.state.hasPendingApprovals,
       input = _ChatComposerInput(
         data: data,
         draftToLoad: draftToLoad,
         canCompact: canCompact,
         reasoningSettingsControl: reasoningSettingsControl,
         modelUnavailable: modelStatus.missing,
         compactDisabledHint: modelStatus.hint,
         continueDisabledHint: modelStatus.hint,
         disabledHint: switch (modelStatus.hint) {
           final hint? => TextLocale(hint),
           null => null,
         },
         disabled: !modelStatus.available,
         onContinueAgent: modelStatus.available
             ? data.callbacks.selectors.continueAgent(
                 isInputBusy: data.state.isInputBusy,
               )
             : null,
       );

  final bool offstage;
  final Widget input;

  @override
  Widget build(BuildContext context) =>
      Offstage(offstage: offstage, child: input);
}

typedef _ChatComposerModelStatus = ({
  bool available,
  bool missing,
  String? hint,
  List<ReasoningOption> reasoningOptions,
});

_ChatComposerModelStatus _chatComposerModelStatus(
  String? modelId,
  AsyncValue<WorkspaceModelSelectionWithConnectionEntity?>? state,
) {
  if (modelId == null) return _requiredModelStatus();

  final selection = state?.value;
  if (selection != null) return _availableModelStatus(selection);

  if (state?.hasValue == true) return _missingModelStatus();

  return _unavailableModelStatus(state?.isLoading == true);
}

_ChatComposerModelStatus _requiredModelStatus() => (
  available: false,
  missing: false,
  hint: LocaleKeys.chats_screens_chat_conversation_model_required,
  reasoningOptions: const [],
);

_ChatComposerModelStatus _availableModelStatus(
  WorkspaceModelSelectionWithConnectionEntity selection,
) => (
  available: true,
  missing: false,
  hint: null,
  reasoningOptions: selection.workspaceModelSelection.reasoningOptions,
);

_ChatComposerModelStatus _missingModelStatus() => (
  available: false,
  missing: true,
  hint: LocaleKeys.chats_screens_chat_conversation_model_missing,
  reasoningOptions: const [],
);

_ChatComposerModelStatus _unavailableModelStatus(bool isLoading) => (
  available: false,
  missing: false,
  hint: isLoading
      ? LocaleKeys.chats_screens_chat_conversation_model_loading
      : LocaleKeys.chats_screens_chat_conversation_model_unavailable,
  reasoningOptions: const [],
);

class _ChatComposerInput extends StatelessWidget {
  new({
    required this.data,
    required this.draftToLoad,
    required this.canCompact,
    required this.reasoningSettingsControl,
    required this.modelUnavailable,
    required this.compactDisabledHint,
    required this.continueDisabledHint,
    required this.disabledHint,
    required this.disabled,
    required this.onContinueAgent,
  }) : input = ChatInputWidget(
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
         modelCompactControl: (onPressed) => _ChatComposerModelCompactControl(
           workspaceId: data.workspaceId,
           workspaceModelSelectionId: data.conversation.modelId,
           onChanged: data.callbacks.selectors.onModelSelectionChanged,
           modelUnavailable: modelUnavailable,
           onCompactTap: onPressed,
         ),
         agentCompactControl: (onPressed) => _ChatComposerAgentCompactControl(
           workspaceId: data.workspaceId,
           agentId: data.conversation.agentId,
           onChanged: data.callbacks.selectors.onAgentChanged,
           onCompactTap: onPressed,
         ),
         conversationId: data.conversation.id,
         toolAccessMode: data.conversation.toolAccessMode,
         onToolAccessModeChanged:
             data.callbacks.selectors.onToolAccessModeChanged,
         topPadding: 0,
         reasoningSettingsControl: reasoningSettingsControl,
         draftToLoad: draftToLoad,
         modalitiesInput: data.state.modalitiesInput,
         onSkillsPress: data.callbacks.selectors.onSkillsPress,
         onContinueAgent: onContinueAgent,
         continueDisabledHint: continueDisabledHint,
         disabledHint: disabledHint,
         compactDisabledHint: compactDisabledHint,
         disabled: disabled,
         isBusy: data.state.isInputBusy,
         showStopButton: data.state.isInputBusy && !data.hidesStoppedRun,
         onStop: data.callbacks.hooks.onStop,
         onCompact: data.callbacks.hooks.onCompact,
         canCompact: canCompact,
         isCompacting: data.state.isCompacting,
       );

  final _LoadedChatConversationData data;
  final ChatDraft? draftToLoad;
  final bool canCompact;
  final Widget? reasoningSettingsControl;
  final bool modelUnavailable;
  final String? compactDisabledHint;
  final String? continueDisabledHint;
  final Widget? disabledHint;
  final bool disabled;
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
  required final bool modelUnavailable,
  required final VoidCallback onCompactTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CompactWorkspaceModelSelector(
    workspaceId: workspaceId,
    workspaceModelSelectionId: workspaceModelSelectionId,
    onChanged: onChanged,
    compactMode: true,
    modelUnavailable: modelUnavailable,
    onCompactTap: onCompactTap,
  );
}

class const _ChatComposerAgentCompactControl({
  required final String workspaceId,
  required final String? agentId,
  required final ValueChanged<String?> onChanged,
  required final VoidCallback onCompactTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CompactAgentSelector(
    workspaceId: workspaceId,
    agentId: agentId,
    onChanged: onChanged,
    onCompactTap: onCompactTap,
    compactMode: true,
  );
}

class const _ChatControlsBar({
  required final String workspaceId,
  required final String conversationId,
  required final Widget idleActivitySummary,
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
        idleActivitySummary: idleActivitySummary,
      ),
    );
  }
}

class const _ChatControlsContent({
  required final String workspaceId,
  required final String conversationId,
  required final Widget idleActivitySummary,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    bottom: false,
    child: _ChatControlsPadding(
      workspaceId: workspaceId,
      conversationId: conversationId,
      idleActivitySummary: idleActivitySummary,
    ),
  );
}

class const _ChatControlsPadding({
  required final String workspaceId,
  required final String conversationId,
  required final Widget idleActivitySummary,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(context.auraTheme.fromSpacing(.md)),
    child: _ChatControlsAlignment(
      workspaceId: workspaceId,
      conversationId: conversationId,
      idleActivitySummary: idleActivitySummary,
    ),
  );
}

class const _ChatControlsAlignment({
  required final String workspaceId,
  required final String conversationId,
  required final Widget idleActivitySummary,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: context.auraTheme.fromSpacing(.sm),
    runSpacing: context.auraTheme.fromSpacing(.xs),
    crossAxisAlignment: .center,
    children: [
      idleActivitySummary,
      ActiveSubAgentStatusWidget(
        workspaceId: workspaceId,
        conversationId: conversationId,
      ),
      ConversationContextUsagePill(
        workspaceId: workspaceId,
        conversationId: conversationId,
      ),
    ],
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
        namedArgs: {
          'seconds': NumberFormatter.count(
            remainingSeconds,
            Localizations.localeOf(context),
          ),
        },
      ),
      style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
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
    ConversationSkillSelectorModal.show(
      context: context,
      workspaceId: workspaceId,
      conversationId: conversationId,
    ),
  );
}

void _showToolsModal({
  required BuildContext context,
  required String workspaceId,
  required String conversationId,
}) {
  if (!context.mounted) return;

  FocusManager.instance.primaryFocus?.unfocus();
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
  FocusManager.instance.primaryFocus?.unfocus();
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
  if (!request.context.mounted) return;
  if (!_canContinueConversation(request)) return;

  final decision = await _continueAgentTurnWithErrorHandling(request);
  _showIterationLimitNoticeForConversation(request, decision);
}

Future<AgentIterationDecision?> _continueAgentTurnWithErrorHandling(
  _ConversationContextRequest request,
) async {
  try {
    return await _continueAgentTurn(request);
  } on Exception catch (error, stackTrace) {
    _reportContinueAgentFailure(request, error, stackTrace);

    return null;
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

Future<AgentIterationDecision?> _continueAgentTurn(
  _ConversationContextRequest request,
) async {
  final cloud = await request.ref.read(
    cloudTurnUsecaseProvider(request.workspaceId).future,
  );
  final context = request.context;
  if (!context.mounted) return null;

  return await _continueAgentTurnWithLanguage(
    request,
    cloud,
    context.locale.languageCode,
  );
}

Future<AgentIterationDecision?> _continueAgentTurnWithLanguage(
  _ConversationContextRequest request,
  CloudTurnUsecase? cloud,
  String languageCode,
) async {
  if (cloud == null) {
    return await _continueLocalAgent(
      request.ref,
      request.conversationId,
      languageCode,
    );
  }

  await _continueCloudAgent((
    ref: request.ref,
    cloud: cloud,
    workspaceId: request.workspaceId,
    conversationId: request.conversationId,
    languageCode: languageCode,
  ));

  return null;
}

Future<AgentIterationDecision> _continueLocalAgent(
  WidgetRef ref,
  String conversationId,
  String languageCode,
) async {
  ref
      .read(conversationAgentLanguageRuntimeProvider)
      .remember(conversationId, languageCode);

  return await ref
      .read(auraAgentServiceProvider)
      .agent
      .continueTurn(
        conversationId: conversationId,
        context: const .new(origin: .manualContinue),
      );
}

Future<void> _retryMessage(_RetryMessageRequest request) async {
  if (!_canRetryMessage(request)) return;

  try {
    final decision = await _runRetryMessage(request);
    _showIterationLimitNoticeForConversation(
      _conversationContextForRetry(request),
      decision,
    );
  } on Exception catch (error, stackTrace) {
    _reportRetryMessageError(request, error, stackTrace);
  }
}

bool _canRetryMessage(_RetryMessageRequest request) {
  if (!_canRetryProviderMessage(request.message)) return false;

  final busyState = request.ref.read(
    conversationBusyStateProvider(request.workspaceId, request.conversationId),
  );
  final rateLimitRetry = request.ref.read(
    conversationRateLimitRetryProvider,
  )[request.conversationId];
  if (!_canContinueAgent(
    _conversationBusyStateValue(busyState),
    rateLimitRetry,
  )) {
    return false;
  }

  return true;
}

bool _canRetryProviderMessage(MessageEntity message) =>
    message.isUser &&
    !message.isForkReference &&
    message.hasValidContent &&
    (message.status == .unfinished ||
        (message.status == .error &&
            ProviderRecoveryMetadata.isRetryEligible(message)));

Future<AgentIterationDecision?> _runRetryMessage(
  _RetryMessageRequest request,
) async {
  final cloud = await request.ref.read(
    cloudTurnUsecaseProvider(request.workspaceId).future,
  );
  if (!request.context.mounted) return null;

  if (cloud == null) {
    return await _retryLocalMessage(request);
  }

  await _retryCloudMessage(request, cloud);

  return null;
}

Future<AgentIterationDecision> _retryLocalMessage(
  _RetryMessageRequest request,
) => request.ref
    .read(sendMessageUsecaseProvider(request.workspaceId))
    .retryUserMessage(
      conversationId: request.conversationId,
      messageId: request.message.id,
      languageCode: request.context.locale.languageCode,
    );

Future<void> _retryCloudMessage(
  _RetryMessageRequest request,
  CloudTurnUsecase cloud,
) => _continueCloudAgent((
  ref: request.ref,
  cloud: cloud,
  workspaceId: request.workspaceId,
  conversationId: request.conversationId,
  languageCode: request.context.locale.languageCode,
));

void _reportRetryMessageError(
  _RetryMessageRequest request,
  Exception error,
  StackTrace stackTrace,
) {
  _logger.severe(
    'Failed to retry message ${request.message.id}',
    error,
    stackTrace,
  );
  if (!request.context.mounted) return;

  final _ = AuraSnackBars.show(
    context: request.context,
    content: Text(LocaleKeys.chats_screens_chat_conversation_retry_error.tr()),
    variant: .error,
  );
}

void _reportContinueAgentError(_ContinueErrorRequest request) {
  _logContinueAgentError(request);
  _reportContinueAgentFlutterError(request);
  _showContinueAgentError(request.context, request.error);
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

void _showContinueAgentError(BuildContext context, Exception error) {
  if (!context.mounted) return;

  final message = switch (error) {
    UnsupportedTranscriptVersionException() =>
      LocaleKeys.chats_screens_chat_conversation_transcript_context_unsupported
          .tr(),
    MalformedTranscriptContextException() =>
      LocaleKeys.chats_screens_chat_conversation_transcript_context_malformed
          .tr(),
    SelectedModelNotFoundException() =>
      LocaleKeys.chats_screens_chat_conversation_model_missing.tr(),
    _ => LocaleKeys.chats_screens_chat_conversation_continue_error.tr(),
  };
  final _ = AuraSnackBars.show(
    context: context,
    content: Text(message),
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
    languageCode: request.languageCode,
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
  if (_hasNonRetryableCloudProviderFailure(state.messages)) return false;

  final executionState = state.conversation.executionState;

  return executionState == 'idle' || executionState == 'failed';
}

bool _hasNonRetryableCloudProviderFailure(
  Iterable<ConversationMessageView> messages,
) {
  ConversationMessageView? latestUserMessage;
  for (final message in messages) {
    if (message.role != 'user' || message.isForkReference) continue;
    if (latestUserMessage == null ||
        message.createdAt.isAfter(latestUserMessage.createdAt)) {
      latestUserMessage = message;
    }
  }

  return latestUserMessage != null &&
      _isNonRetryableCloudProviderFailure(latestUserMessage);
}

bool _isNonRetryableCloudProviderFailure(ConversationMessageView message) {
  if (message.role != 'user' ||
      message.status != 'error' ||
      message.isForkReference) {
    return false;
  }
  final modelMetadata = MessageMetadataEntity.fromJsonString(
    message.metadataJson,
  )?.modelMetadata;

  return ProviderRecoveryMetadata.isProviderErrorMetadata(modelMetadata) &&
      !ProviderRecoveryMetadata.isRetryEligibleMetadata(modelMetadata);
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
    ref.read(activeSubAgentRuntimeProvider.notifier).finish((
      parentId: parentId,
      childId: childId,
      status: .stopped,
      error: null,
      stackTrace: null,
    ));
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
    final decision = await _sendMessageUsecase(request);
    _showIterationLimitNoticeForConversation(
      _conversationContextForSend(request),
      decision,
    );
  } on MessagePersistedException catch (error) {
    _reportSendMessageFailure(request, error, error.stackTrace);
  } on Object catch (error, stackTrace) {
    _reportSendMessageFailure(request, error, stackTrace);
    Error.throwWithStackTrace(error, stackTrace);
  }
}

Future<AgentIterationDecision?> _sendMessageUsecase(
  _SendMessageRequest request,
) => request.ref
    .read(sendMessageUsecaseProvider(request.workspaceId))
    .call(conversationId: request.conversationId, draft: request.draft);

_ConversationContextRequest _conversationContextForRetry(
  _RetryMessageRequest request,
) => (
  context: request.context,
  ref: request.ref,
  workspaceId: request.workspaceId,
  conversationId: request.conversationId,
);

_ConversationContextRequest _conversationContextForSend(
  _SendMessageRequest request,
) => (
  context: request.context,
  ref: request.ref,
  workspaceId: request.workspaceId,
  conversationId: request.conversationId,
);

VoidCallback _conversationContextContinueCallback(
  _ConversationContextRequest request,
) =>
    () => unawaited(_continueAgent(request));

void _showIterationLimitNoticeForConversation(
  _ConversationContextRequest request,
  AgentIterationDecision? decision,
) => _showIterationLimitNoticeIfNeeded(
  context: request.context,
  decision: decision,
  onContinue: _conversationContextContinueCallback(request),
);

void _showIterationLimitNoticeIfNeeded({
  required BuildContext context,
  required AgentIterationDecision? decision,
  required VoidCallback onContinue,
}) {
  if (decision != AgentIterationDecision.iterationLimitReached ||
      !context.mounted) {
    return;
  }

  final _ = AuraSnackBars.show(
    context: context,
    content: const TextLocale(
      LocaleKeys.chats_screens_chat_conversation_iteration_limit_reached,
    ),
    duration: const Duration(seconds: 10),
    actionLabel: LocaleKeys.chats_screens_chat_conversation_continue_agent.tr(),
    onAction: onContinue,
  );
}

void _reportSendMessageFailure(
  _SendMessageRequest request,
  Object error,
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
    final result = await _runManualCompaction(request);
    if (result.status == CompactionExecutionStatus.success) {
      _showManualCompactSuccess(request.context);
    }
  } on CompactionException catch (error) {
    _showManualCompactFailure(request.context, error.localeKey);
  }
}

Future<CompactionExecutionState> _runManualCompaction(
  _ManualCompactRequest request,
) => request.ref.read(compactConversationUsecaseProvider(request.workspaceId))(
  conversationId: request.conversationId,
  trigger: CompactionTrigger.manual,
);

void _showManualCompactSuccess(BuildContext context) {
  if (!context.mounted) return;

  final _ = AuraSnackBars.show(
    context: context,
    content: Text(LocaleKeys.compaction_manual_success.tr()),
    variant: .success,
  );
}

void _showManualCompactFailure(BuildContext context, String localeKey) {
  if (!context.mounted) return;

  final _ = AuraSnackBars.show(
    context: context,
    content: Text(localeKey.tr()),
    variant: .error,
  );
}

class const _ChatList({
  required final String workspaceId,
  required final String conversationId,
  required final List<PendingToolCall> pendingToolCalls,
  required final bool isStopRequested,
  required final Future<void> Function(MessageEntity message)? onRetryMessage,
  required final ValueChanged<SidebarToolResultTab> onOpenToolResult,
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
      isStopRequested: isStopRequested,
      showThinking: showThinking,
      onRetryMessage: onRetryMessage,
      onOpenToolResult: onOpenToolResult,
    );
  }
}

class const _ChatListContent({
  required final AsyncValue<List<MessageEntity>> chatMessages,
  required final String workspaceId,
  required final String conversationId,
  required final List<PendingToolCall> pendingToolCalls,
  required final bool isStopRequested,
  required final bool showThinking,
  required final Future<void> Function(MessageEntity message)? onRetryMessage,
  required final ValueChanged<SidebarToolResultTab> onOpenToolResult,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (_isChatMessagesLoading(chatMessages)) return const _ChatListLoading();

    return _ChatListErrorOrResult(
      chatMessages: chatMessages,
      workspaceId: workspaceId,
      conversationId: conversationId,
      pendingToolCalls: pendingToolCalls,
      isStopRequested: isStopRequested,
      showThinking: showThinking,
      onRetryMessage: onRetryMessage,
      onOpenToolResult: onOpenToolResult,
    );
  }
}

class const _ChatListErrorOrResult({
  required final AsyncValue<List<MessageEntity>> chatMessages,
  required final String workspaceId,
  required final String conversationId,
  required final List<PendingToolCall> pendingToolCalls,
  required final bool isStopRequested,
  required final bool showThinking,
  required final Future<void> Function(MessageEntity message)? onRetryMessage,
  required final ValueChanged<SidebarToolResultTab> onOpenToolResult,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final asyncError = chatMessages.asError;
    if (asyncError != null) {
      return _buildError(asyncError);
    }

    return _buildResult();
  }
}

extension on _ChatListErrorOrResult {
  Widget _buildError(AsyncError<List<MessageEntity>> error) =>
      _ChatListError(error: error.error, stackTrace: error.stackTrace);

  Widget _buildResult() => _ChatListResult(
    workspaceId: workspaceId,
    conversationId: conversationId,
    messages: this.chatMessages.value ?? const <MessageEntity>[],
    pendingToolCalls: this.pendingToolCalls,
    isStopRequested: isStopRequested,
    showThinking: showThinking,
    onRetryMessage: onRetryMessage,
    onOpenToolResult: onOpenToolResult,
  );
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
  required final bool isStopRequested,
  required final bool showThinking,
  required final Future<void> Function(MessageEntity message)? onRetryMessage,
  required final ValueChanged<SidebarToolResultTab> onOpenToolResult,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final messageData = _chatMessageData(messages);

    return ChatMessagesWidget(
      workspaceId: workspaceId,
      conversationId: conversationId,
      messages: messageData.ids,
      onOpenToolResult: onOpenToolResult,
      messageEntitiesById: messageData.entitiesById,
      pendingToolCalls: pendingToolCalls,
      showThinking: showThinking,
      isStopRequested: isStopRequested,
      onRetryMessage: onRetryMessage,
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

class const _ConversationOrientation({
  required final _LoadedChatConversationData data,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parentId = data.conversation.parentConversationId;
    if (data.showInputComposer || parentId == null) {
      return const SizedBox.shrink();
    }

    return _ConversationOrientationContent(
      parentTitle: _conversationParentTitle(
        _conversationParent(ref, data.workspaceId, parentId),
        parentId,
        data.workspaceId,
      ),
      onReturn: _returnToParentConversation(
        context,
        data.workspaceId,
        parentId,
      ),
    );
  }
}

ConversationEntity? _conversationParent(
  WidgetRef ref,
  String workspaceId,
  String parentId,
) => ref
    .watch(
      conversationByIdStreamProvider(workspaceId, conversationId: parentId),
    )
    .asData
    ?.value;

VoidCallback _returnToParentConversation(
  BuildContext context,
  String workspaceId,
  String parentId,
) =>
    () => ConversationRoute(
      workspaceId: workspaceId,
      chatId: parentId,
    ).go(context);

class const _ConversationOrientationContent({
  required final String parentTitle,
  required final VoidCallback onReturn,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      Text(
        'conversation_orientation.delegated'.tr(
          namedArgs: {'parent': parentTitle},
        ),
      ),
      const TextLocale('conversation_orientation.read_only'),
      AuraButton(
        onPressed: onReturn,
        child: const TextLocale('route_state.return_parent'),
      ),
    ],
    mainAxisSize: .min,
  );
}

String _conversationParentTitle(
  ConversationEntity? parent,
  String parentId,
  String workspaceId,
) => parent != null && parent.workspaceId == workspaceId
    ? parent.title
    : parentId;

int _activeConversationChildCount(WidgetRef ref, String conversationId) =>
    ref.watch(
      activeSubAgentRuntimeProvider.select(
        (state) => state[conversationId]?.length ?? 0,
      ),
    );

class const _ConversationActivityLabel({
  required final String activityKey,
  required final int childCount,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    child: Text(_conversationActivityText(activityKey, childCount)),
    liveRegion: true,
  );
}

class const _CompactConversationActivityLabel({
  required final String activityKey,
  required final int childCount,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    child: Text(
      _conversationActivityText(activityKey, childCount),
      style: _compactConversationActivityStyle(context),
      overflow: .ellipsis,
      maxLines: 1,
    ),
    liveRegion: true,
  );
}

String _conversationActivityText(String activityKey, int childCount) =>
    'conversation_activity.$activityKey'.tr(
      namedArgs: {'count': '$childCount'},
    );

TextStyle _compactConversationActivityStyle(BuildContext context) => TextStyle(
  color: context.auraColors.onSurfaceVariant,
  fontSize: context.auraTheme.typography.fontSizeXs,
  fontFamily: context.auraTheme.typography.bodyFontFamily,
);

String _conversationActivityKey(
  ({_LoadedChatConversationData data, int childCount}) request,
) {
  final state = request.data.state;
  if (state.hasPendingApprovals) return 'approval';
  if (request.data.hidesStoppedRun) return 'stopped';

  return _conversationActivityFallbackKey(state, request.childCount);
}

String _conversationActivityFallbackKey(
  _LoadedChatConversationState state,
  int childCount,
) => switch (state) {
  _ when state.rateLimitRetryAt != null => 'retry',
  _ when state.isCompacting => 'compacting',
  _ when childCount > 0 => 'delegated',
  _ when state.isAgentWorking || state.isInputBusy => 'working',
  _ when state.queuedDrafts.isNotEmpty => 'queued',
  _ => 'idle',
};
