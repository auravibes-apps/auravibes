import 'package:auravibes_app/features/skills/usecases/build_loaded_skill_manifests_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart'
    show ToolSpec, buildSkillCommandToolSpecs, listSkillCredentialsToolName;
import 'package:riverpod/riverpod.dart';

abstract final class SkillToolNames {
  static const String listCredentials = listSkillCredentialsToolName;
}

class const BuildDynamicSkillToolSpecsUsecase(
  final BuildLoadedSkillManifestsUsecase _buildLoadedSkillManifestsUsecase,
) {
  Future<List<ToolSpec>> call({
    required String conversationId,
    required String workspaceId,
  }) async {
    assert(conversationId.isNotEmpty, 'conversationId must not be empty');
    assert(workspaceId.isNotEmpty, 'workspaceId must not be empty');

    final manifests = await _buildLoadedSkillManifestsUsecase.call(
      conversationId: conversationId,
      workspaceId: workspaceId,
    );

    return buildSkillCommandToolSpecs(manifests: manifests);
  }
}

final buildDynamicSkillToolSpecsUsecaseProvider =
    Provider<BuildDynamicSkillToolSpecsUsecase>((ref) {
      return BuildDynamicSkillToolSpecsUsecase(
        ref.watch(buildLoadedSkillManifestsUsecaseProvider),
      );
    });
