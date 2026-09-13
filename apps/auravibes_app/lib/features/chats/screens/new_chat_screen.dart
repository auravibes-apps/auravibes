// Required: Existing thresholds and limits use numeric values.
// Required: UI callbacks stay local to their widgets.
import 'dart:async';

import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/agents/widgets/compact_agent_selector.dart';
import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/chats/notifiers/new_chat_state.dart';
import 'package:auravibes_app/features/chats/usecases/send_new_message_usecase.dart';
import 'package:auravibes_app/features/chats/widgets/chat_input_widget.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selection_providers.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:auravibes_app/features/models/widgets/compact_workspace_model_selector.dart';
import 'package:auravibes_app/features/tools/widgets/tools_management_modal.dart';
import 'package:auravibes_app/features/workspaces/notifiers/workspace_switcher.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';

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

    return _NewChatAvailable(workspaceId: workspaceId);
  }
}

class const _NewChatAvailable({required final String workspaceId})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    ref.read(newChatProvider(workspaceId).notifier).setModelId(modelId);
  }

  void setAgentId(String? agentId) {
    ref.read(newChatProvider(workspaceId).notifier).setAgentId(agentId);
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

class const _NewChatBodyData({
  required final String workspaceId,
  required final NewChatState state,
  required final bool hasNoProviders,
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
      title: _WorkspaceSelector(workspaceId: data.workspaceId),
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

    return _NewChatInputAreaContent(
      data: data,
      modalitiesInput: modalitiesInput,
    );
  }
}

class const _NewChatInputAreaContent({
  required final _NewChatBodyData data,
  required final List<String> modalitiesInput,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      Expanded(
        child: data.hasNoProviders
            ? _NoModelProviderPrompt(workspaceId: data.workspaceId)
            : const SizedBox.shrink(),
      ),
      _NewChatInput.fromData(data, modalitiesInput),
    ],
  );
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
  new fromData(_NewChatBodyData data, List<String> modalitiesInput)
    : this(
        child: ChatInputWidget(
          workspaceId: data.workspaceId,
          onSendMessage: data.actions.handleSendMessage,
          onToolsPress: data.actions.onToolsPress,
          modelSheetControl: _NewChatModelSheetControl(data: data),
          agentSheetControl: _NewChatAgentSheetControl(data: data),
          modelCompactControl: _NewChatModelCompactControl(data: data),
          agentCompactControl: _NewChatAgentCompactControl(data: data),
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
      title: _WorkspaceSelector(workspaceId: workspaceId),
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

class const _WorkspaceSelector({required final String workspaceId})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaces = ref.watch(allWorkspacesProvider);

    return SizedBox(
      width: 240,
      child: _WorkspaceSelectorValue(
        workspaces: workspaces,
        workspaceId: workspaceId,
        onChanged: (value) => _switchWorkspace(ref, value),
      ),
    );
  }

  void _switchWorkspace(WidgetRef ref, String? value) {
    if (value == null || value == workspaceId) return;
    ref.read(workspaceSwitcherProvider.notifier).switchToWorkspace(value);
  }
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
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => unawaited(
      ServiceConnectionCreateRoute(
        workspaceId: workspaceId,
        type: 'modelProvider',
      ).push<void>(context),
    ),
    child: const TextLocale(LocaleKeys.models_screens_add_provider_open_button),
  );
}
