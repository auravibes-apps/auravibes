// Required: Existing thresholds and limits use numeric values.
// Required: UI callbacks stay local to their widgets.
import 'dart:async';

import 'package:auravibes_app/features/chats/notifiers/new_chat_state.dart';
import 'package:auravibes_app/features/chats/widgets/chat_input_widget.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:auravibes_app/features/models/widgets/compact_workspace_model_selector.dart';
import 'package:auravibes_app/features/tools/widgets/tools_management_modal.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class NewChatScreen extends ConsumerWidget {
  const NewChatScreen({required this.workspaceId, super.key});

  final String workspaceId;

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

    void handleSendMessage(String message) {
      unawaited(
        (() async {
          try {
            final conversation = await ref
                .read(newChatProvider(workspaceId).notifier)
                .startConversation(message);

            if (context.mounted) {
              ConversationRoute(
                workspaceId: workspaceId,
                chatId: conversation.id,
              ).replace(context);
            }
          } on Exception catch (e) {
            if (context.mounted) {
              final _ = showAuraSnackBar(
                context: context,
                content: Text('Error: $e'),
                variant: AuraSnackBarVariant.error,
              );
            }
          }
        })(),
      );
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
              onSendMessage: handleSendMessage,
              onToolsPress: onToolsPress,
              modelControl: CompactWorkspaceModelSelector(
                workspaceId: workspaceId,
                workspaceModelSelectionId: state.modelId,
                onChanged: (modelId) => ref
                    .read(newChatProvider(workspaceId).notifier)
                    .setModelId(modelId),
              ),
              disabled: state.isLoading || state.modelId == null,
            ),
          ],
        ),
        message: LocaleKeys.chats_screens_new_chat_starting.tr(),
      ),
      appBar: const AuraAppBarWithDrawer(
        title: TextLocale(LocaleKeys.home_screen_actions_start_new_chat),
      ),
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
