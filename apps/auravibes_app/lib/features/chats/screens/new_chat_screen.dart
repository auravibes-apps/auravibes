// Required: Existing thresholds and limits use numeric values.
// Required: UI callbacks stay local to their widgets.

import 'dart:async';

import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/features/agents/widgets/compact_agent_selector.dart';
import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/chats/notifiers/new_chat_state.dart';
import 'package:auravibes_app/features/chats/usecases/send_new_message_usecase.dart';
import 'package:auravibes_app/features/chats/widgets/chat_input_widget.dart';
import 'package:auravibes_app/features/chats/widgets/chat_readiness_summary.dart';
import 'package:auravibes_app/features/chats/widgets/chat_reasoning_control.dart';
import 'package:auravibes_app/features/chats/widgets/chat_reasoning_controls.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selection_providers.dart';
import 'package:auravibes_app/features/models/widgets/compact_workspace_model_selector.dart';
import 'package:auravibes_app/features/tools/widgets/tools_management_modal.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/draft_exit_guard.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/draft_exit_scope.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

final _logger = Logger('new_chat_screen');

class const NewChatScreen({required final String workspaceId, super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TickerMode(
    enabled: true,
    child: _NewChatContent(workspaceId: workspaceId),
  );
}

class const _NewChatContent({required final String workspaceId})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availability = ref.watch(workspaceAvailabilityProvider(workspaceId));
    if (availability case AsyncData(value: WorkspaceAuthenticationRequired())) {
      return _NewChatUnavailable(workspaceId: workspaceId);
    }

    return _NewChatAvailable(
      workspaceId: workspaceId,
      key: ValueKey<String>(workspaceId),
    );
  }
}

class const _NewChatAvailable({required final String workspaceId, super.key})
    extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draftStatus = useState(false);
    final guard = useMemoized(DraftExitGuard.new);
    final data = _newChatBodyData(
      _newChatBodyRequest(context, ref, workspaceId, draftStatus),
    );
    _bindNewChatGuard((
      guard: guard,
      ref: ref,
      workspaceId: workspaceId,
      draftStatus: draftStatus,
    ));

    return DraftExitScope(
      guard: guard,
      child: _NewChatBody(data: data),
    );
  }
}

typedef _NewChatBodyRequest = ({
  BuildContext context,
  WidgetRef ref,
  String workspaceId,
  NewChatState state,
  ValueNotifier<bool> draftStatus,
});

_NewChatBodyRequest _newChatBodyRequest(
  BuildContext context,
  WidgetRef ref,
  String workspaceId,
  ValueNotifier<bool> draftStatus,
) => (
  context: context,
  ref: ref,
  workspaceId: workspaceId,
  state: ref.watch(newChatProvider(workspaceId)),
  draftStatus: draftStatus,
);

typedef _NewChatGuardRequest = ({
  DraftExitGuard guard,
  WidgetRef ref,
  String workspaceId,
  ValueNotifier<bool> draftStatus,
});

_NewChatBodyData _newChatBodyData(_NewChatBodyRequest request) =>
    _NewChatBodyData(
      workspaceId: request.workspaceId,
      state: request.state,
      draftStatus: request.draftStatus,
      actions: .new(
        context: request.context,
        ref: request.ref,
        workspaceId: request.workspaceId,
        draftStatus: request.draftStatus,
      ),
    );

void _bindNewChatGuard(_NewChatGuardRequest request) {
  request.guard.bind(
    readers: (
      isDirty: () => request.draftStatus.value,
      isSaving: () =>
          request.ref.read(newChatProvider(request.workspaceId)).isLoading,
    ),
    confirm: _confirmNewChatWorkspaceDiscard,
  );
}

class const _NewChatActions({
  required final BuildContext context,
  required final WidgetRef ref,
  required final String workspaceId,
  required final ValueNotifier<bool> draftStatus,
}) {
  void onToolsPress() {
    if (workspaceId.isEmpty || !context.mounted) return;

    FocusManager.instance.primaryFocus?.unfocus();
    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) => ToolsManagementModal(workspaceId: workspaceId),
      ),
    );
  }

  void setModelId(String? modelId) {
    if (modelId == null) {
      ref.read(newChatProvider(workspaceId).notifier)
        ..setModelId(null)
        ..setReasoningConfiguration(null);

      return;
    }

    ref.read(newChatProvider(workspaceId).notifier).setModelId(modelId);
    unawaited(_clearInvalidReasoningConfiguration(modelId));
  }

  void setAgentId(String? agentId) {
    ref.read(newChatProvider(workspaceId).notifier).setAgentId(agentId);
  }

  void setReasoningConfiguration(ReasoningConfiguration? value) {
    ref
        .read(newChatProvider(workspaceId).notifier)
        .setReasoningConfiguration(value);
  }

  Future<void> handleSendMessage(ChatDraft draft) async {
    try {
      await _openNewConversation(draft);
    } on Exception catch (error, stackTrace) {
      _showNewChatSendError((
        context: context,
        workspaceId: workspaceId,
        error: error,
        stackTrace: stackTrace,
      ));
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> _clearInvalidReasoningConfiguration(String modelId) async {
    try {
      final selectedModel = await ref.read(
        workspaceModelSelectionByIdProvider(workspaceId, modelId).future,
      );
      _clearInvalidReasoningConfigurationFor(modelId, selectedModel);
    } on Object {
      // Keep explicit configuration when catalog is temporarily unavailable.
    }
  }

  void _clearInvalidReasoningConfigurationFor(
    String modelId,
    WorkspaceModelSelectionWithConnectionEntity? selectedModel,
  ) {
    final state = ref.read(newChatProvider(workspaceId));
    final configuration = state.reasoningConfiguration;
    if (state.modelId != modelId || configuration == null) return;
    if (_isInvalidReasoningConfiguration(configuration, selectedModel)) {
      _resetReasoningConfiguration();
    }
  }

  bool _isInvalidReasoningConfiguration(
    ReasoningConfiguration configuration,
    WorkspaceModelSelectionWithConnectionEntity? selectedModel,
  ) =>
      selectedModel == null ||
      !configuration.isValidFor(
        selectedModel.workspaceModelSelection.reasoningOptions,
      );

  void _resetReasoningConfiguration() => ref
      .read(newChatProvider(workspaceId).notifier)
      .setReasoningConfiguration(null);

  Future<void> _openNewConversation(ChatDraft draft) async {
    final conversation = await _startNewConversation(ref, workspaceId, draft);
    if (!context.mounted) return;

    draftStatus.value = false;
    ConversationRoute(
      workspaceId: workspaceId,
      chatId: conversation.id,
    ).replace(context);
  }
}

Future<ConversationEntity> _startNewConversation(
  WidgetRef ref,
  String workspaceId,
  ChatDraft draft,
) => ref
    .read(newChatProvider(workspaceId).notifier)
    .startConversation(
      draft,
      ref.read(sendNewMessageUsecaseProvider(workspaceId)),
    );

typedef _NewChatSendError = ({
  BuildContext context,
  String workspaceId,
  Object error,
  StackTrace stackTrace,
});

void _showNewChatSendError(_NewChatSendError request) {
  final (:context, :workspaceId, :error, :stackTrace) = request;
  _logger.severe(
    'Failed to start conversation for workspace $workspaceId',
    error,
    stackTrace,
  );
  if (!context.mounted) return;

  final _ = AuraSnackBars.show(
    context: context,
    content: const TextLocale(
      LocaleKeys.chats_screens_chat_conversation_send_error,
    ),
    variant: .error,
  );
}

class _NewChatBodyData({
  required final String workspaceId,
  required final NewChatState state,
  required final ValueNotifier<bool> draftStatus,
  required final _NewChatActions actions,
});

class const _NewChatBody({required final _NewChatBodyData data})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraScreen(
      child: AuraLoadingOverlay(
        isLoading: data.state.isLoading,
        child: _NewChatInputArea(data: data),
        message: LocaleKeys.chats_screens_new_chat_starting.tr(),
      ),
      appBar: const AuraAppBarWithDrawer(
        title: TextLocale(LocaleKeys.menu_new_chat),
      ),
    );
  }
}

class const _NewChatInputArea({required final _NewChatBodyData data})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modalitiesInput = _watchNewChatModalities(
      ref,
      data.workspaceId,
      data.state.modelId,
    );
    final reasoningOptions = _watchNewChatReasoningOptions(
      ref,
      data.workspaceId,
      data.state.modelId,
    );

    return _NewChatInputAreaContent(
      data: data,
      modalitiesInput: modalitiesInput,
      reasoningOptions: reasoningOptions,
      modelAvailable: _selectedModelAvailable(
        ref,
        data.workspaceId,
        data.state.modelId,
      ),
    );
  }
}

class const _NewChatInputAreaContent({
  required final _NewChatBodyData data,
  required final List<String> modalitiesInput,
  required final List<ReasoningOption> reasoningOptions,
  required final bool modelAvailable,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      Expanded(
        child: SingleChildScrollView(
          child: ChatReadinessSummary(workspaceId: data.workspaceId),
        ),
      ),
      _NewChatInput.fromData(
        data,
        modalitiesInput,
        reasoningOptions,
        modelAvailable: modelAvailable,
      ),
    ],
  );
}

List<ReasoningOption> _watchNewChatReasoningOptions(
  WidgetRef ref,
  String workspaceId,
  String? modelId,
) {
  if (modelId == null) return const [];

  return ref
          .watch(workspaceModelSelectionByIdProvider(workspaceId, modelId))
          .value
          ?.workspaceModelSelection
          .reasoningOptions ??
      const <ReasoningOption>[];
}

List<String> _watchNewChatModalities(
  WidgetRef ref,
  String workspaceId,
  String? modelId,
) {
  if (modelId == null) return const [];

  final selectedModel = ref.watch(
    workspaceModelSelectionByIdProvider(workspaceId, modelId),
  );

  return selectedModel.value?.workspaceModelSelection.modalitiesInput ??
      const <String>[];
}

class const _NewChatInput({required final Widget child})
    extends StatelessWidget {
  new fromData(
    _NewChatBodyData data,
    List<String> modalitiesInput,
    List<ReasoningOption> reasoningOptions, {
    required bool modelAvailable,
  }) : this(
         child: ChatInputWidget(
           workspaceId: data.workspaceId,
           onSendMessage: data.actions.handleSendMessage,
           onToolsPress: data.actions.onToolsPress,
           modelSheetControl: _NewChatModelSheetControl(data: data),
           agentSheetControl: _NewChatAgentSheetControl(data: data),
           modelCompactControl: (onPressed) =>
               _NewChatModelCompactControl(data: data, onCompactTap: onPressed),
           agentCompactControl: (onPressed) =>
               _NewChatAgentCompactControl(data: data, onCompactTap: onPressed),
           onDraftStatusChanged: (hasDraft) =>
               data.draftStatus.value = hasDraft,
           autofocus: true,
           reasoningControl:
               ChatReasoningControls.hasSupportedReasoningOptions(
                 reasoningOptions,
               )
               ? ChatReasoningControl(
                   options: reasoningOptions,
                   value: data.state.reasoningConfiguration,
                   onChanged: data.actions.setReasoningConfiguration,
                 )
               : null,
           modalitiesInput: modalitiesInput,
           disabledHint: data.state.modelId == null
               ? const TextLocale(
                   LocaleKeys.chats_screens_new_chat_no_model_selected,
                 )
               : null,
           disabled: data.state.isLoading || !modelAvailable,
         ),
       );

  @override
  Widget build(BuildContext context) => child;
}

class const _NewChatModelSheetControl({required final _NewChatBodyData data})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CompactWorkspaceModelSelector(
    workspaceId: data.workspaceId,
    workspaceModelSelectionId: data.state.modelId,
    onChanged: data.actions.setModelId,
    sheetMode: true,
  );
}

class const _NewChatAgentSheetControl({required final _NewChatBodyData data})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CompactAgentSelector(
    workspaceId: data.workspaceId,
    agentId: data.state.agentId,
    onChanged: data.actions.setAgentId,
    sheetMode: true,
  );
}

class const _NewChatModelCompactControl({
  required final _NewChatBodyData data,
  required final VoidCallback onCompactTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CompactWorkspaceModelSelector(
    workspaceId: data.workspaceId,
    workspaceModelSelectionId: data.state.modelId,
    onChanged: data.actions.setModelId,
    compactMode: true,
    onCompactTap: onCompactTap,
  );
}

class const _NewChatAgentCompactControl({
  required final _NewChatBodyData data,
  required final VoidCallback onCompactTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CompactAgentSelector(
    workspaceId: data.workspaceId,
    agentId: data.state.agentId,
    onChanged: data.actions.setAgentId,
    onCompactTap: onCompactTap,
    compactMode: true,
  );
}

class const _NewChatUnavailable({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraScreen(
    child: _NewChatUnavailableBody(workspaceId: workspaceId),
    appBar: const AuraAppBarWithDrawer(
      title: TextLocale(LocaleKeys.menu_new_chat),
    ),
  );
}

class const _NewChatUnavailableBody({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      const Expanded(child: _UnavailableMessage()),
      _UnavailableChatInput(workspaceId: workspaceId),
    ],
  );
}

class const _UnavailableMessage() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Center(
    child: AuraColumn(
      children: [
        AuraIcon(Icons.cloud_off_outlined),
        TextLocale(LocaleKeys.workspace_management_cloud_unavailable),
      ],
      spacing: .sm,
      mainAxisSize: .min,
    ),
  );
}

class const _UnavailableChatInput({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ChatInputWidget(
    workspaceId: workspaceId,
    onSendMessage: (_) {
      return;
    },
    onToolsPress: () {
      return;
    },
    modelSheetControl: const SizedBox.shrink(),
    agentSheetControl: const SizedBox.shrink(),
    modelCompactControl: (_) => const SizedBox.shrink(),
    agentCompactControl: (_) => const SizedBox.shrink(),
    disabled: true,
  );
}

Future<bool> _confirmNewChatWorkspaceDiscard(BuildContext context) async {
  final shouldDiscard = await AuraDialogs.confirm(
    context: context,
    title: const TextLocale(
      LocaleKeys.workspace_management_unsaved_changes_title,
    ),
    message: const TextLocale(
      LocaleKeys.workspace_management_unsaved_changes_message,
    ),
    actions: const AuraConfirmDialogActions(
      confirmLabel: TextLocale(LocaleKeys.workspace_management_discard_changes),
      cancelLabel: TextLocale(LocaleKeys.workspace_management_keep_editing),
    ),
  );

  return shouldDiscard == true;
}

bool _selectedModelAvailable(
  WidgetRef ref,
  String workspaceId,
  String? modelId,
) {
  if (modelId == null) return false;

  return ref
          .watch(workspaceModelSelectionByIdProvider(workspaceId, modelId))
          .asData
          ?.value
          ?.modelConnection
          .hasKey ==
      true;
}
