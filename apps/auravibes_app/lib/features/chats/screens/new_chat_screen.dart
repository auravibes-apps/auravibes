// Required: Existing thresholds and limits use numeric values.
// Required: UI callbacks stay local to their widgets.
import 'dart:async';

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
    final groupedModelsAsync = ref.watch(
      listModelsGroupedByProviderProvider(workspaceId: workspaceId),
    );
    final hasNoProviders = groupedModelsAsync.asData?.value.isEmpty ?? false;

    void onToolsPress() {
      if (workspaceId.isNotEmpty && context.mounted) {
        unawaited(
          showDialog<void>(
            context: context,
            builder: (context) =>
                ToolsManagementModal(workspaceId: workspaceId),
          ),
        );
      }
    }

    Future<void> handleSendMessage(ChatDraft draft) async {
      try {
        final conversation = await ref
            .read(newChatProvider(workspaceId).notifier)
            .startConversation(
              draft,
              ref.read(sendNewMessageUsecaseProvider(workspaceId)),
            );

        if (context.mounted) {
          ConversationRoute(
            workspaceId: workspaceId,
            chatId: conversation.id,
          ).replace(context);
        }
      } on Exception catch (error, stackTrace) {
        _logger.severe(
          'Failed to start conversation for workspace $workspaceId',
          error,
          stackTrace,
        );
        if (context.mounted) {
          final _ = AuraSnackBars.show(
            context: context,
            content: const TextLocale(
              LocaleKeys.chats_screens_chat_conversation_send_error,
            ),
            variant: .error,
          );
        }
        Error.throwWithStackTrace(error, stackTrace);
      }
    }

    return _NewChatBody(
      workspaceId: workspaceId,
      isLoading: state.isLoading,
      hasNoProviders: hasNoProviders,
      modelId: state.modelId,
      agentId: state.agentId,
      onSendMessage: handleSendMessage,
      onToolsPress: onToolsPress,
      onModelChanged: (modelId) =>
          ref.read(newChatProvider(workspaceId).notifier).setModelId(modelId),
      onAgentChanged: (agentId) =>
          ref.read(newChatProvider(workspaceId).notifier).setAgentId(agentId),
    );
  }
}

class const _NewChatBody({
  required final String workspaceId,
  required final bool isLoading,
  required final bool hasNoProviders,
  required final String? modelId,
  required final String? agentId,
  required final Future<void> Function(ChatDraft) onSendMessage,
  required final VoidCallback onToolsPress,
  required final ValueChanged<String?> onModelChanged,
  required final ValueChanged<String?> onAgentChanged,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedModelAsync = switch (modelId) {
      null => null,
      final selectedModelId => ref.watch(
        workspaceModelSelectionByIdProvider(workspaceId, selectedModelId),
      ),
    };
    final modalitiesInput =
        selectedModelAsync?.value?.workspaceModelSelection.modalitiesInput ??
        const <String>[];

    return AuraScreen(
      child: AuraLoadingOverlay(
        isLoading: isLoading,
        child: AuraColumn(
          children: [
            Expanded(
              child: hasNoProviders
                  ? _NoModelProviderPrompt(workspaceId: workspaceId)
                  : const SizedBox.shrink(),
            ),
            ChatInputWidget(
              workspaceId: workspaceId,
              onSendMessage: onSendMessage,
              onToolsPress: onToolsPress,
              modelSheetControl: CompactWorkspaceModelSelector(
                workspaceId: workspaceId,
                workspaceModelSelectionId: modelId,
                onChanged: onModelChanged,
                sheetMode: true,
              ),
              agentSheetControl: CompactAgentSelector(
                workspaceId: workspaceId,
                agentId: agentId,
                onChanged: onAgentChanged,
                sheetMode: true,
              ),
              modelCompactControl: CompactWorkspaceModelSelector(
                workspaceId: workspaceId,
                workspaceModelSelectionId: modelId,
                onChanged: onModelChanged,
                compactMode: true,
              ),
              agentCompactControl: CompactAgentSelector(
                workspaceId: workspaceId,
                agentId: agentId,
                onChanged: onAgentChanged,
                compactMode: true,
              ),
              modalitiesInput: modalitiesInput,
              disabled: isLoading || modelId == null,
            ),
          ],
        ),
        message: LocaleKeys.chats_screens_new_chat_starting.tr(),
      ),
      appBar: AuraAppBarWithDrawer(
        title: _WorkspaceSelector(workspaceId: workspaceId),
      ),
    );
  }
}

class const _NewChatUnavailable({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraScreen(
      child: AuraColumn(
        children: [
          const Expanded(
            child: Center(
              child: AuraColumn(
                children: [
                  AuraIcon(Icons.cloud_off_outlined),
                  TextLocale(LocaleKeys.workspace_management_cloud_unavailable),
                ],
                spacing: .sm,
                mainAxisSize: .min,
              ),
            ),
          ),
          ChatInputWidget(
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
          ),
        ],
      ),
      appBar: AuraAppBarWithDrawer(
        title: _WorkspaceSelector(workspaceId: workspaceId),
      ),
    );
  }
}

class const _WorkspaceSelector({required final String workspaceId})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaces = ref.watch(allWorkspacesProvider);

    return SizedBox(
      width: 240,
      child: switch (workspaces) {
        AsyncData(:final value) => AuraDropdownSelector<String>(
          options: [
            for (final workspace in value)
              AuraDropdownOption(
                value: workspace.id,
                child: Text(workspace.name),
              ),
          ],
          key: const Key('new_chat_workspace_selector'),
          value: workspaceId,
          onChanged: (value) => _switchWorkspace(ref, value),
          semanticLabel: LocaleKeys.workspace_management_title.tr(),
        ),
        AsyncLoading() => const AuraDropdownSelector<String>(
          options: [],
          placeholder: AuraSpinner(size: .small),
          isEnabled: false,
        ),
        AsyncError() => AuraDropdownSelector<String>(
          options: [
            AuraDropdownOption(value: workspaceId, child: Text(workspaceId)),
          ],
          value: workspaceId,
          isEnabled: false,
        ),
      },
    );
  }

  void _switchWorkspace(WidgetRef ref, String? value) {
    if (value == null || value == workspaceId) return;
    ref.read(workspaceSwitcherProvider.notifier).switchToWorkspace(value);
  }
}

class const _NoModelProviderPrompt({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: .new(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: AuraColumn(
                children: [
                  const AuraIcon(Icons.hub_outlined, size: .extraLarge),
                  const AuraText(
                    child: TextLocale(
                      LocaleKeys.models_screens_list_empty_title,
                    ),
                    style: .heading3,
                    textAlign: .center,
                  ),
                  const AuraText(
                    child: TextLocale(
                      LocaleKeys.models_screens_list_empty_subtitle,
                    ),
                    textAlign: .center,
                  ),
                  AuraButton(
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
                ],
                mainAxisAlignment: .center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
