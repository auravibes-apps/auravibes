// Required: Existing thresholds and limits use numeric values.
// Required: UI callbacks stay local to their widgets.
import 'dart:async';

import 'package:auravibes_app/features/chats/notifiers/new_chat_state.dart';
import 'package:auravibes_app/features/chats/widgets/chat_input_widget.dart';
import 'package:auravibes_app/features/models/widgets/select_workspace_model_selection_widget.dart';
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
      child: Column(
        children: [
          SelectWorkspaceModelSelectionWidget(
            workspaceId: workspaceId,
            selectWorkspaceModelSelectionId: (value) {
              ref.read(newChatProvider(workspaceId).notifier).setModelId(value);
            },
            onProviderChanged: (provider) {
              ref
                  .read(newChatProvider(workspaceId).notifier)
                  .setProvider(provider);
            },
            workspaceModelSelectionId: state.modelId,
            selectedProviderId: state.providerId,
          ),
          Expanded(
            child: AuraLoadingOverlay(
              isLoading: state.isLoading,
              child: Center(
                child: ChatInputWidget(
                  onSendMessage: handleSendMessage,
                  onToolsPress: onToolsPress,
                  disabledHint: state.modelId == null
                      ? const TextLocale(
                          LocaleKeys.chats_screens_new_chat_no_model_selected,
                        )
                      : null,
                  disabled: state.isLoading || state.modelId == null,
                ),
              ),
              message: LocaleKeys.chats_screens_new_chat_starting.tr(),
            ),
          ),
        ],
      ),
      appBar: const AuraAppBarWithDrawer(
        title: TextLocale(LocaleKeys.home_screen_actions_start_new_chat),
      ),
    );
  }
}
