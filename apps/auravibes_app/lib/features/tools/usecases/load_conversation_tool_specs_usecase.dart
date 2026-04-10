import 'package:auravibes_app/domain/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/domain/usecases/tools/mcp/build_combined_tool_specs_usecase.dart';
import 'package:auravibes_app/features/tools/notifiers/conversation_tools_notifier.dart';
import 'package:auravibes_app/features/tools/notifiers/grouped_tools_notifier.dart';
import 'package:auravibes_app/features/tools/providers/mcp_tool_spec_lookup_provider.dart';
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
          getMcpToolSpec: ref.watch(mcpToolSpecLookupProvider).call,
        ),
      );
    });
