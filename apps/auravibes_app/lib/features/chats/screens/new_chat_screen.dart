// Required: Existing thresholds and limits use numeric values.
// Required: UI callbacks stay local to their widgets.
import 'dart:async';

import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/features/agents/widgets/compact_agent_selector.dart';
import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/chats/notifiers/new_chat_state.dart';
import 'package:auravibes_app/features/chats/usecases/send_new_message_usecase.dart';
import 'package:auravibes_app/features/chats/widgets/chat_input_widget.dart';
import 'package:auravibes_app/features/chats/widgets/chat_reasoning_control.dart';
import 'package:auravibes_app/features/chats/widgets/chat_reasoning_controls.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selection_providers.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:auravibes_app/features/models/widgets/compact_workspace_model_selector.dart';
import 'package:auravibes_app/features/tools/widgets/tools_management_modal.dart';
import 'package:auravibes_app/features/workspaces/models/switch_status.dart';
import 'package:auravibes_app/features/workspaces/notifiers/workspace_switcher.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
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
    final state = ref.watch(newChatProvider(workspaceId));
    final hasNoProviders = _hasNoModelProviders(ref, workspaceId);
    final actions = _NewChatActions(
      context: context,
      ref: ref,
      workspaceId: workspaceId,
    );

    return _NewChatBody(
      data: .new(
        workspaceId: workspaceId,
        state: state,
        hasNoProviders: hasNoProviders,
        draftStatus: draftStatus,
        actions: actions,
      ),
    );
  }
}

bool _hasNoModelProviders(WidgetRef ref, String workspaceId) =>
    ref
        .watch(listModelsGroupedByProviderProvider(workspaceId: workspaceId))
        .asData
        ?.value
        .isEmpty ??
    false;

class const _NewChatActions({
  required final BuildContext context,
  required final WidgetRef ref,
  required final String workspaceId,
}) {
  void onToolsPress() {
    if (workspaceId.isEmpty || !context.mounted) return;

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
  required final bool hasNoProviders,
  required final ValueNotifier<bool> draftStatus,
  required final _NewChatActions actions,
});

class const _NewChatBody({required final _NewChatBodyData data})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraScreen(
    child: AuraLoadingOverlay(
      isLoading: data.state.isLoading,
      child: _NewChatInputArea(data: data),
      message: LocaleKeys.chats_screens_new_chat_starting.tr(),
    ),
    appBar: AuraAppBarWithDrawer(
      title: _WorkspaceSelector(
        workspaceId: data.workspaceId,
        draftStatus: data.draftStatus,
      ),
    ),
  );
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
    );
  }
}

class const _NewChatInputAreaContent({
  required final _NewChatBodyData data,
  required final List<String> modalitiesInput,
  required final List<ReasoningOption> reasoningOptions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      Expanded(
        child: data.hasNoProviders
            ? _NoModelProviderPrompt(workspaceId: data.workspaceId)
            : const SizedBox.shrink(),
      ),
      _NewChatInput.fromData(data, modalitiesInput, reasoningOptions),
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
    List<ReasoningOption> reasoningOptions,
  ) : this(
        child: ChatInputWidget(
          workspaceId: data.workspaceId,
          onSendMessage: data.actions.handleSendMessage,
          onToolsPress: data.actions.onToolsPress,
          modelSheetControl: _NewChatModelSheetControl(data: data),
          agentSheetControl: _NewChatAgentSheetControl(data: data),
          modelCompactControl: _NewChatModelCompactControl(data: data),
          agentCompactControl: _NewChatAgentCompactControl(data: data),
          onDraftStatusChanged: (hasDraft) => data.draftStatus.value = hasDraft,
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
          disabled: data.state.isLoading || data.state.modelId == null,
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

class const _NewChatModelCompactControl({required final _NewChatBodyData data})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CompactWorkspaceModelSelector(
    workspaceId: data.workspaceId,
    workspaceModelSelectionId: data.state.modelId,
    onChanged: data.actions.setModelId,
    compactMode: true,
  );
}

class const _NewChatAgentCompactControl({required final _NewChatBodyData data})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CompactAgentSelector(
    workspaceId: data.workspaceId,
    agentId: data.state.agentId,
    onChanged: data.actions.setAgentId,
    compactMode: true,
  );
}

class const _NewChatUnavailable({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraScreen(
    child: _NewChatUnavailableBody(workspaceId: workspaceId),
    appBar: AuraAppBarWithDrawer(
      title: _WorkspaceSelector(
        workspaceId: workspaceId,
        draftStatus: .new(false),
      ),
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
    modelCompactControl: const SizedBox.shrink(),
    agentCompactControl: const SizedBox.shrink(),
    disabled: true,
  );
}

class const _WorkspaceSelector({
  required final String workspaceId,
  required final ValueNotifier<bool> draftStatus,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaces = ref.watch(allWorkspacesProvider);
    final switchState = ref.watch(workspaceSwitcherProvider);
    final switchWorkspace = _workspaceSwitchAction(context, ref, this);

    return _WorkspaceSelectorView(
      isSwitching: switchState.status == .loading,
      workspaces: workspaces,
      workspaceId: workspaceId,
      onChanged: (value) => unawaited(switchWorkspace(value)),
    );
  }
}

Future<void> Function(String?) _workspaceSwitchAction(
  BuildContext context,
  WidgetRef ref,
  _WorkspaceSelector selector,
) {
  final confirmedTargetWorkspaceId = useState<String?>(null);
  final request = (
    context: context,
    ref: ref,
    selector: selector,
    confirmedTargetWorkspaceId: confirmedTargetWorkspaceId,
  );
  Future<void> switchWorkspace(String? targetWorkspaceId) =>
      _switchNewChatWorkspace(request, targetWorkspaceId);
  _listenForWorkspaceSwitchErrors(context, ref, switchWorkspace);

  return switchWorkspace;
}

class const _WorkspaceSelectorView({
  required final bool isSwitching,
  required final AsyncValue<List<WorkspaceEntity>> workspaces,
  required final String workspaceId,
  required final ValueChanged<String?> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    key: const ValueKey<String>('workspace_selector'),
    child: SizedBox(
      width: 240,
      child: isSwitching
          ? const _WorkspaceSwitchingIndicator()
          : _WorkspaceSelectorValue(
              workspaces: workspaces,
              workspaceId: workspaceId,
              onChanged: onChanged,
            ),
    ),
    identifier: 'workspace_selector',
  );
}

class const _WorkspaceSwitchingIndicator() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Row(
    children: [
      AuraSpinner(size: .small),
      SizedBox(width: 8),
      Flexible(
        child: TextLocale(LocaleKeys.workspace_management_switch_loading),
      ),
    ],
  );
}

typedef _WorkspaceSwitchRequest = ({
  BuildContext context,
  WidgetRef ref,
  _WorkspaceSelector selector,
  ValueNotifier<String?> confirmedTargetWorkspaceId,
});

Future<void> _switchNewChatWorkspace(
  _WorkspaceSwitchRequest request,
  String? targetWorkspaceId,
) async {
  if (targetWorkspaceId == null ||
      targetWorkspaceId == request.selector.workspaceId) {
    return;
  }
  if (!await _confirmWorkspaceSwitch(request, targetWorkspaceId)) return;
  request.ref.read(workspaceSwitcherProvider.notifier)
    ..clearError()
    ..switchToWorkspace(targetWorkspaceId);
}

Future<bool> _confirmWorkspaceSwitch(
  _WorkspaceSwitchRequest request,
  String targetWorkspaceId,
) async {
  if (!request.selector.draftStatus.value ||
      request.confirmedTargetWorkspaceId.value == targetWorkspaceId) {
    return true;
  }
  if (!await _confirmNewChatWorkspaceDiscard(request.context) ||
      !request.context.mounted) {
    return false;
  }
  request.confirmedTargetWorkspaceId.value = targetWorkspaceId;

  return true;
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

void _listenForWorkspaceSwitchErrors(
  BuildContext context,
  WidgetRef ref,
  Future<void> Function(String?) switchWorkspace,
) {
  ref.listen(workspaceSwitcherProvider, (_, next) {
    if (next case WorkspaceSwitchState(
      status: .error,
      errorLocalizationKey: final String errorKey,
      targetWorkspaceId: final String targetWorkspaceId,
    )) {
      _showWorkspaceSwitchError(
        context,
        errorKey,
        targetWorkspaceId,
        switchWorkspace,
      );
    }
  });
}

void _showWorkspaceSwitchError(
  BuildContext context,
  String errorKey,
  String targetWorkspaceId,
  Future<void> Function(String?) switchWorkspace,
) {
  final _ = AuraSnackBars.show(
    context: context,
    content: TextLocale(errorKey),
    variant: .error,
    actionLabel: LocaleKeys.workspace_management_switch_retry.tr(),
    onAction: () => unawaited(switchWorkspace(targetWorkspaceId)),
  );
}

class const _WorkspaceSelectorValue({
  required final AsyncValue<List<WorkspaceEntity>> workspaces,
  required final String workspaceId,
  required final ValueChanged<String?> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (workspaces) {
    AsyncData(:final value) => _WorkspaceOptions(
      workspaces: value,
      workspaceId: workspaceId,
      onChanged: onChanged,
    ),
    AsyncLoading() => const _WorkspaceSelectorLoading(),
    AsyncError() => _WorkspaceSelectorError(workspaceId: workspaceId),
  };
}

class const _WorkspaceSelectorLoading() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const AuraDropdownSelector<String>(
    options: [],
    placeholder: AuraSpinner(size: .small),
    isEnabled: false,
  );
}

class const _WorkspaceSelectorError({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraDropdownSelector<String>(
    options: [AuraDropdownOption(value: workspaceId, child: Text(workspaceId))],
    value: workspaceId,
    isEnabled: false,
  );
}

class const _WorkspaceOptions({
  required final List<WorkspaceEntity> workspaces,
  required final String workspaceId,
  required final ValueChanged<String?> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraDropdownSelector<String>(
    options: [
      for (final workspace in workspaces)
        AuraDropdownOption(value: workspace.id, child: Text(workspace.name)),
    ],
    key: const Key('new_chat_workspace_selector'),
    value: workspaceId,
    onChanged: onChanged,
    semanticLabel: LocaleKeys.workspace_management_title.tr(),
  );
}

class const _NoModelProviderPrompt({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      _NoModelProviderPromptLayout(workspaceId: workspaceId);
}

class const _NoModelProviderPromptLayout({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => _NoModelProviderPromptScroll(
      workspaceId: workspaceId,
      minHeight: constraints.maxHeight,
    ),
  );
}

class const _NoModelProviderPromptScroll({
  required final String workspaceId,
  required final double minHeight,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: ConstrainedBox(
      constraints: .new(minHeight: minHeight),
      child: _NoModelProviderPromptCenter(workspaceId: workspaceId),
    ),
  );
}

class const _NoModelProviderPromptCenter({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: _NoModelProviderPromptContent(workspaceId: workspaceId),
    ),
  );
}

class const _NoModelProviderPromptContent({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      _NoModelProviderColumn(workspaceId: workspaceId);
}

class const _NoModelProviderColumn({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      const AuraIcon(Icons.hub_outlined, size: .extraLarge),
      const AuraText(
        child: TextLocale(LocaleKeys.models_screens_list_empty_title),
        style: .heading3,
        textAlign: .center,
      ),
      const AuraText(
        child: TextLocale(LocaleKeys.models_screens_list_empty_subtitle),
        textAlign: .center,
      ),
      _AddModelProviderButton(workspaceId: workspaceId),
    ],
    mainAxisAlignment: .center,
  );
}

class const _AddModelProviderButton({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    key: const ValueKey<String>('workspace_add_model_provider'),
    child: AuraButton(
      onPressed: () => unawaited(
        ServiceConnectionCreateRoute(
          workspaceId: workspaceId,
          type: 'modelProvider',
        ).push<void>(context),
      ),
      child: const TextLocale(
        LocaleKeys.models_screens_add_provider_open_button,
      ),
    ),
    identifier: 'workspace_add_model_provider',
  );
}
