import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/domain/entities/skill_credential_entity.dart';
import 'package:auravibes_app/domain/repositories/skill_credential_definitions_repository.dart';
import 'package:auravibes_app/domain/repositories/skill_credentials_repository.dart';
import 'package:auravibes_app/domain/repositories/skill_template_tools_repository.dart';
import 'package:auravibes_app/domain/repositories/skills_repository.dart';
import 'package:auravibes_app/features/skills/models/skill_url_template.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/usecases/resolve_skill_url_template_usecase.dart';
import 'package:auravibes_app/services/url/url_service.dart';
import 'package:riverpod/riverpod.dart';

class RunSkillTemplateToolUsecase {
  const RunSkillTemplateToolUsecase(
    this._skillTemplateToolsRepository,
    this._skillsRepository,
    this._skillCredentialDefinitionsRepository,
    this._skillCredentialsRepository,
    this._resolveSkillUrlTemplateUsecase,
    this._urlService,
  );

  final SkillTemplateToolsRepository _skillTemplateToolsRepository;
  final SkillsRepository _skillsRepository;
  final SkillCredentialDefinitionsRepository
  _skillCredentialDefinitionsRepository;
  final SkillCredentialsRepository _skillCredentialsRepository;
  final ResolveSkillUrlTemplateUsecase _resolveSkillUrlTemplateUsecase;
  final UrlService _urlService;

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
    final template = SkillUrlTemplate.fromJsonString(tool.templateJson);
    final inputDefinitions = SkillTemplateInputDefinition.parseMap(
      tool.inputsJson,
    );
    final request = _resolveSkillUrlTemplateUsecase.call(
      template: template,
      inputs: arguments,
      credentials: credential?.attributes ?? const {},
      inputDefinitions: inputDefinitions,
      credentialDefinitions: credentialDefinitions,
    );
    final response = await _urlService.execute(request).value;

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
        ref.watch(resolveSkillUrlTemplateUsecaseProvider),
        UrlService(),
      );
    });
