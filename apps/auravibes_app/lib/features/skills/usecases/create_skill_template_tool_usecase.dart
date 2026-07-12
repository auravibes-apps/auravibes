import 'package:auravibes_app/data/repositories/skill_credential_definitions_repository.dart';
import 'package:auravibes_app/data/repositories/skill_template_tools_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/domain/entities/skill_template_tool_entity.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:riverpod/riverpod.dart';

class CreateSkillTemplateToolUsecase {
  const CreateSkillTemplateToolUsecase(
    this._skillTemplateToolsRepository, {
    this.skillsRepository,
    this.skillCredentialDefinitionsRepository,
  });

  final SkillTemplateToolsRepository _skillTemplateToolsRepository;
  final SkillsRepository? skillsRepository;
  final SkillCredentialDefinitionsRepository?
  skillCredentialDefinitionsRepository;

  Future<SkillTemplateToolEntity> call(
    String skillId,
    SkillTemplateToolToCreate tool,
  ) async {
    final credentialDefinitions = await _credentialDefinitions(skillId);
    validateSkillTemplateTool(
      templateJson: tool.templateJson,
      inputsJson: tool.inputsJson,
      credentialDefinitions: credentialDefinitions,
    );

    return _skillTemplateToolsRepository.createTool(
      skillId,
      tool.copyWith(
        templateJson: canonicalSkillUrlTemplateJson(tool.templateJson),
      ),
    );
  }

  Future<Map<String, SkillCredentialAttributeDefinition>>
  _credentialDefinitions(String skillId) async {
    final skillsRepository = this.skillsRepository;
    final credentialDefinitionsRepository =
        skillCredentialDefinitionsRepository;
    if (skillsRepository == null || credentialDefinitionsRepository == null) {
      return const {};
    }
    final skill = await skillsRepository.getSkillById(skillId);
    final credentialDefinitionId = skill?.credentialDefinitionId;
    if (credentialDefinitionId == null) return const {};
    final definition = await credentialDefinitionsRepository.getDefinitionById(
      credentialDefinitionId,
    );
    if (definition == null) return const {};

    return SkillCredentialAttributeDefinition.parseMap(
      definition.attributesJson,
    );
  }
}

final createSkillTemplateToolUsecaseProvider =
    Provider<CreateSkillTemplateToolUsecase>((ref) {
      return CreateSkillTemplateToolUsecase(
        ref.watch(skillTemplateToolsRepositoryProvider),
        skillsRepository: ref.watch(skillsRepositoryProvider),
        skillCredentialDefinitionsRepository: ref.watch(
          skillCredentialDefinitionsRepositoryProvider,
        ),
      );
    });
