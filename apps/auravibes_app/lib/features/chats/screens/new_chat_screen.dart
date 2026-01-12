import 'package:auravibes_app/domain/entities/workspace_tool.dart'
    show ToolPermissionMode;
import 'package:auravibes_app/features/chats/widgets/chat_input_widget.dart';
import 'package:auravibes_app/features/models/widgets/select_chat_model.dart';
import 'package:auravibes_app/features/tools/providers/conversation_tools_provider.dart';
import 'package:auravibes_app/features/tools/widgets/tools_management_modal.dart';
import 'package:auravibes_app/features/workspaces/providers/selected_workspace.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/providers/messages_manager_provider.dart';
import 'package:auravibes_app/router/app_router.dart';
import 'package:auravibes_app/services/tools/user_tools_entity.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class NewChatScreen extends HookConsumerWidget {
  const NewChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modelIdState = useState<String?>(null);
    final isLoading = useState(false);
    final onToolsPress = useCallback(() async {
      // Try to get conversation info
      final workspaceId = await ref.read(
        selectedWorkspaceProvider.selectAsync((data) => data.id),
      );

      if (workspaceId.isNotEmpty && context.mounted) {
        showDialog<void>(
          context: context,
          builder: (context) => ToolsManagementModal(workspaceId: workspaceId),
        );
      }
    }, []);

    Future<void> handleSendMessage(String message) async {
      if (modelIdState.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a chat model')),
        );
        return;
      }

      isLoading.value = true;

      try {
        final workspaceId = await ref.read(
          selectedWorkspaceProvider.selectAsync((w) => w.id),
        );
        if (modelIdState.value == null) {
          throw Exception('no model id value');
        }

        // Get enabled tools from the list
        // Extract UserToolType from BuiltInTool identifiers

        final toolsList = await ref.watch(
          conversationToolsProvider(
            workspaceId: workspaceId,
          ).future,
        );
        final enabledToolStates = toolsList
            .where((tool) => tool.isEnabled)
            .toList();
        final tools = enabledToolStates
            .map((tool) => tool.tool.buildInType)
            .whereType<UserToolType>()
            .toList();

        final conversationToolPermissions = <String, ToolPermissionMode>{};
        for (final toolState in enabledToolStates) {
          if (toolState.permissionMode != toolState.tool.permissionMode) {
            conversationToolPermissions[toolState.tool.id] =
                toolState.permissionMode;
          }
        }

        final createdConversation = await ref
            .read(messagesManagerProvider.notifier)
            .addConversation(
              workspaceId: workspaceId,
              modelId: modelIdState.value!,
              message: message,
              toolTypes: tools,
              conversationToolPermissions:
                  conversationToolPermissions.isNotEmpty
                  ? conversationToolPermissions
                  : null,
            );

        if (context.mounted) {
          CoversationRoute(chatId: createdConversation.id).replace(context);
        }
      } on Exception catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        isLoading.value = false;
      }
    }

    return AuraScreen(
      appBar: AuraAppBar(
        title: const TextLocale(LocaleKeys.home_screen_actions_start_new_chat),
        bottom: SelectCredentialsModelWidget(
          credentialsModelId: modelIdState.value,
          selectCredentialsModelId: (value) {
            modelIdState.value = value;
          },
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: ChatInputWidget(
              disabled: isLoading.value || modelIdState.value == null,
              onSendMessage: handleSendMessage,
              onToolsPress: onToolsPress,
            ),
          ),
          if (isLoading.value)
            ColoredBox(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
