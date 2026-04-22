import 'package:auravibes_app/domain/entities/tool_spec.dart';
import 'package:auravibes_app/domain/entities/workspace_tool.dart';
import 'package:auravibes_app/domain/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/domain/usecases/tools/mcp/build_combined_tool_specs_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/load_conversation_tool_specs_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'load_conversation_tool_specs_usecase_test.mocks.dart';

@GenerateMocks([
  ConversationToolsRepository,
  BuildCombinedToolSpecsUseCase,
])
void main() {
  group('LoadConversationToolSpecsUsecase', () {
    late MockConversationToolsRepository conversationToolsRepository;
    late MockBuildCombinedToolSpecsUseCase buildCombinedToolSpecsUseCase;
    late LoadConversationToolSpecsUsecase usecase;

    setUp(() {
      conversationToolsRepository = MockConversationToolsRepository();
      buildCombinedToolSpecsUseCase = MockBuildCombinedToolSpecsUseCase();
      usecase = LoadConversationToolSpecsUsecase(
        conversationToolsRepository: conversationToolsRepository,
        buildCombinedToolSpecsUseCase: buildCombinedToolSpecsUseCase,
      );
    });

    test('loads enabled tool entities and maps them to tool specs', () async {
      final enabledTools = [
        WorkspaceToolEntity(
          id: 'tool-row-1',
          workspaceId: 'workspace-1',
          toolId: 'calculator',
          isEnabled: true,
          permissionMode: ToolPermissionMode.alwaysAllow,
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        ),
      ];
      const toolSpecs = [
        ToolSpec(
          name: 'built_in_tool-row-1_calculator',
          description: 'Calculator tool',
          inputJsonSchema: {},
        ),
      ];

      when(
        conversationToolsRepository.getAvailableToolEntitiesForConversation(
          'conversation-1',
          'workspace-1',
        ),
      ).thenAnswer((_) async => enabledTools);
      when(
        buildCombinedToolSpecsUseCase.call(enabledTools),
      ).thenAnswer((_) async => toolSpecs);

      final result = await usecase.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
      );

      expect(result, toolSpecs);
      verify(
        conversationToolsRepository.getAvailableToolEntitiesForConversation(
          'conversation-1',
          'workspace-1',
        ),
      ).called(1);
      verify(buildCombinedToolSpecsUseCase.call(enabledTools)).called(1);
    });
  });
}
