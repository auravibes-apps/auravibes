import 'package:auravibes_app/data/repositories/skill_credential_definitions_repository.dart';
import 'package:auravibes_app/data/repositories/skill_credentials_repository.dart';
import 'package:auravibes_app/data/repositories/skill_template_tools_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/domain/entities/skill_credential_entity.dart';
import 'package:auravibes_app/features/skills/models/skill_url_template.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/usecases/run_skill_url_template_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart' as package_skills;
import 'package:riverpod/riverpod.dart';

class RunSkillTemplateToolUsecase {
  const RunSkillTemplateToolUsecase(
    this._skillTemplateToolsRepository,
    this._skillsRepository,
    this._skillCredentialDefinitionsRepository,
    this._skillCredentialsRepository,
    this._runSkillUrlTemplateUsecase,
  );

  final SkillTemplateToolsRepository _skillTemplateToolsRepository;
  final SkillsRepository _skillsRepository;
  final SkillCredentialDefinitionsRepository
  _skillCredentialDefinitionsRepository;
  final SkillCredentialsRepository _skillCredentialsRepository;
  final package_skills.RunSkillUrlTemplate _runSkillUrlTemplateUsecase;

  Future<Object?> call({
    required String workspaceId,
    required String skillSlug,
    required String toolSlug,
    required Map<String, dynamic> arguments,
  }) async {
    final skill = await _skillsRepository.getSkillBySlug(
      workspaceId,
      skillSlug,
    );
    if (skill == null || !skill.isEnabled) return null;

    final tool = await _skillTemplateToolsRepository.getToolBySlug(
      skill.id,
      toolSlug,
    );
    if (tool == null || !tool.isEnabled) return null;

    final credential = await _resolveCredential(
      workspaceId: workspaceId,
      credentialDefinitionId: skill.credentialDefinitionId,
      credentialId: arguments['credentialId'] as String?,
      requiresCredential: tool.requiresCredential,
    );
    final credentialDefinitions = await _credentialDefinitions(
      skill.credentialDefinitionId,
    );
    final credentialAttributes = credential == null
        ? const <String, String>{}
        : await _skillCredentialsRepository.readCredentialAttributes(
            credential.id,
          );
    final template = SkillUrlTemplate.fromJsonString(tool.templateJson);
    final inputDefinitions = SkillTemplateInputDefinition.parseMap(
      tool.inputsJson,
    );
    final response = await _runSkillUrlTemplateUsecase
        .call(
          template: template,
          inputs: arguments,
          credentials: credentialAttributes,
          inputDefinitions: inputDefinitions,
          credentialDefinitions: credentialDefinitions,
        )
        .value;

    return response.body;
  }

  Future<SkillCredentialEntity?> _resolveCredential({
    required String workspaceId,
    required String? credentialDefinitionId,
    required String? credentialId,
    required bool requiresCredential,
  }) async {
    if (credentialDefinitionId == null) {
      if (requiresCredential) {
        throw StateError('Skill tool requires a credential definition.');
      }

      return null;
    }

    if (credentialId == null || credentialId.trim().isEmpty) {
      if (requiresCredential) {
        throw StateError('Skill tool requires a credentialId argument.');
      }

      return null;
    }

    final credential = await _skillCredentialsRepository.getCredentialById(
      credentialId.trim(),
    );
    if (credential == null ||
        credential.workspaceId != workspaceId ||
        credential.credentialDefinitionId != credentialDefinitionId ||
        !credential.isEnabled) {
      throw StateError('Skill credential is not available for this tool.');
    }

    return credential;
  }

  Future<Map<String, SkillCredentialAttributeDefinition>>
  _credentialDefinitions(String? credentialDefinitionId) async {
    if (credentialDefinitionId == null) return const {};
    final definition = await _skillCredentialDefinitionsRepository
        .getDefinitionById(credentialDefinitionId);
    if (definition == null) {
      throw StateError('Skill credential definition not found.');
    }

    return SkillCredentialAttributeDefinition.parseMap(
      definition.attributesJson,
    );
  }
}

final runSkillTemplateToolUsecaseProvider =
    Provider<RunSkillTemplateToolUsecase>((ref) {
      return RunSkillTemplateToolUsecase(
        ref.watch(skillTemplateToolsRepositoryProvider),
        ref.watch(skillsRepositoryProvider),
        ref.watch(skillCredentialDefinitionsRepositoryProvider),
        ref.watch(skillCredentialsRepositoryProvider),
        ref.watch(runSkillUrlTemplateUsecaseProvider),
      );
    });
