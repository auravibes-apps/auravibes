import 'package:auravibes_app/features/chats/providers/new_chat_controller.dart';
import 'package:auravibes_app/features/chats/widgets/chat_input_widget.dart';
import 'package:auravibes_app/features/models/widgets/select_chat_model.dart';
import 'package:auravibes_app/features/tools/widgets/tools_management_modal.dart';
import 'package:auravibes_app/features/workspaces/providers/selected_workspace.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/app_router.dart';
import 'package:auravibes_app/widgets/app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class NewChatScreen extends ConsumerWidget {
  const NewChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(newChatControllerProvider);

    Future<void> onToolsPress() async {
      final workspaceId = await ref.read(
        selectedWorkspaceProvider.selectAsync((data) => data.id),
      );

      if (workspaceId.isNotEmpty && context.mounted) {
        showDialog<void>(
          context: context,
          builder: (context) => ToolsManagementModal(workspaceId: workspaceId),
        );
      }
    }

    Future<void> handleSendMessage(String message) async {
      try {
        final conversationId = await ref
            .read(newChatControllerProvider.notifier)
            .startConversation(message);

        if (context.mounted) {
          ConversationRoute(chatId: conversationId).replace(context);
        }
      } on Exception catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }

    return AuraScreen(
      appBar: AuraAppBarWithDrawer(
        title: const TextLocale(LocaleKeys.home_screen_actions_start_new_chat),
        bottom: SelectCredentialsModelWidget(
          credentialsModelId: state.modelId,
          selectCredentialsModelId: (value) {
            ref.read(newChatControllerProvider.notifier).setModelId(value);
          },
        ),
      ),
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
    );
  }
}
