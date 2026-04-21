import 'package:auravibes_app/features/chats/notifiers/new_chat_notifier.dart';
import 'package:auravibes_app/features/chats/widgets/chat_input_widget.dart';
import 'package:auravibes_app/features/models/widgets/select_chat_model.dart';
import 'package:auravibes_app/features/tools/widgets/tools_management_modal.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/app_router.dart';
import 'package:auravibes_app/widgets/app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class NewChatScreen extends ConsumerWidget {
  const NewChatScreen({required this.workspaceId, super.key});

  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(newChatProvider(workspaceId));

    Future<void> onToolsPress() async {
      if (workspaceId.isNotEmpty && context.mounted) {
        showDialog<void>(
          context: context,
          builder: (context) => ToolsManagementModal(workspaceId: workspaceId),
        );
      }
    }

    Future<void> handleSendMessage(String message) async {
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
          showAuraSnackBar(
            context: context,
            content: Text('Error: $e'),
            variant: AuraSnackBarVariant.error,
          );
        }
      }
    }

    return AuraScreen(
      appBar: const AuraAppBarWithDrawer(
        title: TextLocale(LocaleKeys.home_screen_actions_start_new_chat),
      ),
      child: Column(
        children: [
          SelectWorkspaceModelSelectionWidget(
            workspaceId: workspaceId,
            workspaceModelSelectionId: state.modelId,
            selectedProviderId: state.providerId,
            selectWorkspaceModelSelectionId: (value) {
              ref.read(newChatProvider(workspaceId).notifier).setModelId(value);
            },
            onProviderChanged: (provider) {
              ref
                  .read(newChatProvider(workspaceId).notifier)
                  .setProvider(provider);
            },
          ),
          Expanded(
            child: Stack(
              children: [
                Center(
                  child: ChatInputWidget(
                    disabled: state.isLoading || state.modelId == null,
                    onSendMessage: handleSendMessage,
                    onToolsPress: onToolsPress,
                  ),
                ),
                if (state.isLoading)
                  ColoredBox(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
