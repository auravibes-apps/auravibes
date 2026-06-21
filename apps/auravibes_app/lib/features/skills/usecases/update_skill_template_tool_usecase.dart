import 'package:auravibes_app/data/repositories/skill_credential_definitions_repository.dart';
import 'package:auravibes_app/data/repositories/skill_template_tools_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/domain/entities/skill_template_tool_entity.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/usecases/validate_skill_template_tool_usecase.dart';
import 'package:riverpod/riverpod.dart';

class UpdateSkillTemplateToolUsecase {
  const UpdateSkillTemplateToolUsecase(
    this._skillTemplateToolsRepository, {
    required this.validateSkillTemplateToolUsecase,
    this.skillsRepository,
    this.skillCredentialDefinitionsRepository,
  });

  final SkillTemplateToolsRepository _skillTemplateToolsRepository;
  final SkillsRepository? skillsRepository;
  final SkillCredentialDefinitionsRepository?
  skillCredentialDefinitionsRepository;
  final ValidateSkillTemplateToolUsecase validateSkillTemplateToolUsecase;

  Future<SkillTemplateToolEntity> call(
    String toolId,
    SkillTemplateToolToUpdate tool,
  ) async {
    final templateJson = tool.templateJson;
    final inputsJson = tool.inputsJson;
    var toolToUpdate = tool;
    if (templateJson != null || inputsJson != null) {
      final existing = await _skillTemplateToolsRepository.getToolById(toolId);
      if (existing == null) {
        throw StateError('Skill template tool not found: $toolId');
      }
      final credentialDefinitions = await _credentialDefinitions(
        existing.skillId,
      );
      validateSkillTemplateToolUsecase.call(
        templateJson: templateJson ?? existing.templateJson,
        inputsJson: inputsJson ?? existing.inputsJson,
        credentialDefinitions: credentialDefinitions,
      );
      if (templateJson != null) {
        toolToUpdate = tool.copyWith(
          templateJson: validateSkillTemplateToolUsecase.canonicalTemplateJson(
            templateJson,
          ),
        );
      }
    }

    return _skillTemplateToolsRepository.updateTool(toolId, toolToUpdate);
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

final updateSkillTemplateToolUsecaseProvider =
    Provider<UpdateSkillTemplateToolUsecase>((ref) {
      return UpdateSkillTemplateToolUsecase(
        ref.watch(skillTemplateToolsRepositoryProvider),
        validateSkillTemplateToolUsecase: ref.watch(
          validateSkillTemplateToolUsecaseProvider,
        ),
        skillsRepository: ref.watch(skillsRepositoryProvider),
        skillCredentialDefinitionsRepository: ref.watch(
          skillCredentialDefinitionsRepositoryProvider,
        ),
      );
    });
