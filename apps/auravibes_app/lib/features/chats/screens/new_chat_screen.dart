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

class NewChatScreen extends ConsumerWidget {
  const NewChatScreen({required this.workspaceId, super.key});

  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availability = ref.watch(workspaceAvailabilityProvider(workspaceId));
    if (availability case AsyncData(value: WorkspaceAuthenticationRequired())) {
      return _NewChatUnavailable(workspaceId: workspaceId);
    }
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

    final selectedModelId = state.modelId;
    final selectedModelAsync = selectedModelId == null
        ? null
        : ref.watch(
            workspaceModelSelectionByIdProvider(workspaceId, selectedModelId),
          );
    final modalitiesInput =
        selectedModelAsync?.value?.workspaceModelSelection.modalitiesInput ??
        const <String>[];

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
          final _ = showAuraSnackBar(
            context: context,
            content: const TextLocale(
              LocaleKeys.chats_screens_chat_conversation_send_error,
            ),
            variant: AuraSnackBarVariant.error,
          );
        }
        Error.throwWithStackTrace(error, stackTrace);
      }
    }

    return AuraScreen(
      child: AuraLoadingOverlay(
        isLoading: state.isLoading,
        child: AuraColumn(
          children: [
            Expanded(
              child: hasNoProviders
                  ? _NoModelProviderPrompt(workspaceId: workspaceId)
                  : const SizedBox.shrink(),
            ),
            ChatInputWidget(
              workspaceId: workspaceId,
              onSendMessage: handleSendMessage,
              onToolsPress: onToolsPress,
              modelSheetControl: CompactWorkspaceModelSelector(
                workspaceId: workspaceId,
                workspaceModelSelectionId: state.modelId,
                onChanged: (modelId) => ref
                    .read(newChatProvider(workspaceId).notifier)
                    .setModelId(modelId),
                sheetMode: true,
              ),
              agentSheetControl: CompactAgentSelector(
                workspaceId: workspaceId,
                agentId: state.agentId,
                onChanged: (agentId) => ref
                    .read(newChatProvider(workspaceId).notifier)
                    .setAgentId(agentId),
                sheetMode: true,
              ),
              modelCompactControl: CompactWorkspaceModelSelector(
                workspaceId: workspaceId,
                workspaceModelSelectionId: state.modelId,
                onChanged: (modelId) => ref
                    .read(newChatProvider(workspaceId).notifier)
                    .setModelId(modelId),
                compactMode: true,
              ),
              agentCompactControl: CompactAgentSelector(
                workspaceId: workspaceId,
                agentId: state.agentId,
                onChanged: (agentId) => ref
                    .read(newChatProvider(workspaceId).notifier)
                    .setAgentId(agentId),
                compactMode: true,
              ),
              modalitiesInput: modalitiesInput,
              disabled: state.isLoading || state.modelId == null,
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

class _NewChatUnavailable extends StatelessWidget {
  const _NewChatUnavailable({required this.workspaceId});

  final String workspaceId;

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
                  TextLocale(
                    LocaleKeys.workspace_management_cloud_unavailable,
                  ),
                ],
                spacing: .sm,
                mainAxisSize: MainAxisSize.min,
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

class _WorkspaceSelector extends ConsumerWidget {
  const _WorkspaceSelector({required this.workspaceId});

  final String workspaceId;

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
          onChanged: (value) {
            if (value != null && value != workspaceId) {
              ref
                  .read(workspaceSwitcherProvider.notifier)
                  .switchToWorkspace(value);
            }
          },
          semanticLabel: LocaleKeys.workspace_management_title.tr(),
        ),
        AsyncLoading() => const AuraDropdownSelector<String>(
          options: [],
          placeholder: AuraSpinner(size: AuraSpinnerSize.small),
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
}

class _NoModelProviderPrompt extends StatelessWidget {
  const _NoModelProviderPrompt({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: AuraColumn(
                children: [
                  const AuraIcon(
                    Icons.hub_outlined,
                    size: AuraIconSize.extraLarge,
                  ),
                  const AuraText(
                    child: TextLocale(
                      LocaleKeys.models_screens_list_empty_title,
                    ),
                    style: AuraTextStyle.heading3,
                    textAlign: TextAlign.center,
                  ),
                  const AuraText(
                    child: TextLocale(
                      LocaleKeys.models_screens_list_empty_subtitle,
                    ),
                    textAlign: TextAlign.center,
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
                mainAxisAlignment: MainAxisAlignment.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
