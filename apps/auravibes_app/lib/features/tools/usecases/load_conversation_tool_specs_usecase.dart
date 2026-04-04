import 'package:auravibes_app/domain/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/domain/usecases/tools/mcp/build_combined_tool_specs_usecase.dart';
import 'package:auravibes_app/features/tools/providers/conversation_tools_controller.dart';
import 'package:auravibes_app/features/tools/providers/grouped_tools_controller.dart';
import 'package:auravibes_app/providers/mcp_connection_controller.dart';
import 'package:langchain/langchain.dart';
import 'package:riverpod/riverpod.dart';

class LoadConversationToolSpecsUsecase {
  const LoadConversationToolSpecsUsecase({
    required ConversationToolsRepository conversationToolsRepository,
    required BuildCombinedToolSpecsUseCase buildCombinedToolSpecsUseCase,
  }) : _conversationToolsRepository = conversationToolsRepository,
       _buildCombinedToolSpecsUseCase = buildCombinedToolSpecsUseCase;

  final ConversationToolsRepository _conversationToolsRepository;
  final BuildCombinedToolSpecsUseCase _buildCombinedToolSpecsUseCase;

  Future<List<ToolSpec>> call({
    required String conversationId,
    required String workspaceId,
  }) async {
    final enabledTools = await _conversationToolsRepository
        .getAvailableToolEntitiesForConversation(
          conversationId,
          workspaceId,
        );

    return _buildCombinedToolSpecsUseCase.call(enabledTools);
  }
}

final loadConversationToolSpecsUsecaseProvider =
    Provider<LoadConversationToolSpecsUsecase>((ref) {
      return LoadConversationToolSpecsUsecase(
        conversationToolsRepository: ref.watch(
          conversationToolsRepositoryProvider,
        ),
        buildCombinedToolSpecsUseCase: BuildCombinedToolSpecsUseCase(
          getToolsGroupById: ref
              .watch(toolsGroupsRepositoryProvider)
              .getToolsGroupById,
          getMcpToolSpec: ({required mcpServerId, required toolName}) {
            return ref
                .read(mcpConnectionControllerProvider.notifier)
                .getToolSpec(
                  mcpServerId: mcpServerId,
                  toolName: toolName,
                );
          },
        ),
      );
    });
