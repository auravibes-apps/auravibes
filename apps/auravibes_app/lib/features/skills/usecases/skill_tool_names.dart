import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/usecases/list_app_skill_credential_candidates_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/list_available_skills_usecase.dart';
import 'package:auravibes_app/services/skills/app_skill_registry.dart';
import 'package:auravibes_engine/auravibes_engine.dart'
    show ToolSpec, buildSkillCommandToolSpecs, listSkillCredentialsToolName;
import 'package:riverpod/riverpod.dart';

abstract final class SkillToolNames {
  static const String listCredentials = listSkillCredentialsToolName;
}

class BuildDynamicSkillToolSpecsUsecase {
  const BuildDynamicSkillToolSpecsUsecase(
    ListAvailableSkillsUsecase Function(String workspaceId) _,
    // Legacy constructor stays stable while implementation becomes fixed.
    // ignore: avoid_unused_parameters
    AppSkillRegistry _,
    // Legacy constructor stays stable while implementation becomes fixed.
    // ignore: avoid_unused_parameters
    ListAppSkillCredentialCandidatesUsecase _,
  );

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
      return BuildDynamicSkillToolSpecsUsecase(
        (workspaceId) =>
            ref.watch(listAvailableSkillsUsecaseProvider(workspaceId)),
        ref.watch(appSkillRegistryProvider),
        ref.watch(listAppSkillCredentialCandidatesUsecaseProvider),
      );
    });
