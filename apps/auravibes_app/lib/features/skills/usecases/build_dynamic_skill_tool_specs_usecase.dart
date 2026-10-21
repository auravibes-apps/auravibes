import 'package:auravibes_engine/auravibes_engine.dart'
    show ToolSpec, buildSkillCommandToolSpecs;
import 'package:riverpod/riverpod.dart';

class const BuildDynamicSkillToolSpecsUsecase() {
  Future<List<ToolSpec>> call({
    required String conversationId,
    required String workspaceId,
  }) async {
    assert(conversationId.isNotEmpty, 'conversationId must not be empty');
    assert(workspaceId.isNotEmpty, 'workspaceId must not be empty');

    return buildSkillCommandToolSpecs();
  }
}

final buildDynamicSkillToolSpecsUsecaseProvider =
    Provider<BuildDynamicSkillToolSpecsUsecase>((ref) {
      return const BuildDynamicSkillToolSpecsUsecase();
    });
