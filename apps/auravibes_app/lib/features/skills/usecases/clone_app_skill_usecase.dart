import 'dart:convert';

import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/entities/skill_template_tool_entity.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:auravibes_app/features/skills/usecases/create_skill_credential_definition_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/create_skill_template_tool_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/create_skill_usecase.dart';
import 'package:auravibes_app/services/skills/app_skill_registry.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:riverpod/misc.dart';
import 'package:riverpod/riverpod.dart';

typedef _CloneToolRequest = ({
  String workspaceId,
  String skillId,
  String skillTitle,
  AppSkillToolDefinition tool,
});

typedef _CloneCredentialRequest = ({
  String workspaceId,
  String skillTitle,
  String toolTitle,
  SkillTemplateDefinition definition,
});

class const CloneAppSkillUsecase(
  final AppSkillRegistry _appSkillRegistry,
  final SkillsRepository? _skillsRepository,
  final CreateSkillUsecase _createSkillUsecase,
  final CreateSkillCredentialDefinitionUsecase
  _createCredentialDefinitionUsecase,
  final CreateSkillTemplateToolUsecase _createToolUsecase, {
  final CloudSkillStore? cloudStore,
}) {
  Future<SkillEntity> call(String workspaceId, String appSkillSlug) async {
    final appSkill = _cloneableAppSkill(appSkillSlug);
    final title = await _copyTitle(workspaceId, appSkill.title);
    final skill = await _createClone(workspaceId, title, appSkill);
    await _cloneTools(workspaceId, skill, title, appSkill.tools);

    return skill;
  }
}

extension _CloneAppSkillDefinitions on CloneAppSkillUsecase {
  AppSkillDefinition _cloneableAppSkill(String slug) {
    final appSkill =
        _appSkillRegistry.getBySlug(slug) ??
        _appSkillRegistry.getByIdentifier(slug);
    if (appSkill == null) throw StateError('App skill not found: $slug');
    if (appSkill.kind != AppSkillDefinitionKind.template) {
      throw StateError('Native app skills cannot be cloned.');
    }

    return appSkill;
  }

  Future<SkillEntity> _createClone(
    String workspaceId,
    String title,
    AppSkillDefinition appSkill,
  ) => _createSkillUsecase.call(
    workspaceId,
    .new(
      kind: SkillKind.template,
      title: title,
      description: appSkill.description,
      content: appSkill.content,
    ),
  );

  Future<void> _cloneTools(
    String workspaceId,
    SkillEntity skill,
    String skillTitle,
    List<AppSkillToolDefinition> tools,
  ) async {
    for (final tool in tools) {
      await _cloneTool((
        workspaceId: workspaceId,
        skillId: skill.id,
        skillTitle: skillTitle,
        tool: tool,
      ));
    }
  }

  Future<void> _cloneTool(_CloneToolRequest request) async {
    final definition = _requiredToolDefinition(request.tool);
    final credentialDefinitionId = await _cloneCredentialDefinition((
      workspaceId: request.workspaceId,
      skillTitle: request.skillTitle,
      toolTitle: request.tool.title,
      definition: definition,
    ));
    final _ = await _createToolUsecase.call(
      request.skillId,
      _toolValue(request.tool, definition, credentialDefinitionId),
    );
  }

  SkillTemplateDefinition _requiredToolDefinition(AppSkillToolDefinition tool) {
    final definition = tool.definition;
    if (definition != null) return definition;

    throw StateError(
      'App skill tool has no declarative definition: ${tool.slug}',
    );
  }

  SkillTemplateToolToCreate _toolValue(
    AppSkillToolDefinition tool,
    SkillTemplateDefinition definition,
    String? credentialDefinitionId,
  ) => .new(
    templateType: SkillTemplateToolType.url,
    title: tool.title,
    description: tool.description,
    definitionJson: definition.toJsonString(),
    templateJson: definition.legacyTemplateJson,
    inputsJson: definition.legacyInputsJson,
    credentialDefinitionId: credentialDefinitionId,
    requiresCredential: tool.requiresCredential,
  );

  Future<String?> _cloneCredentialDefinition(
    _CloneCredentialRequest request,
  ) async {
    final definition = request.definition;
    if (definition.credentialDefinitions.isEmpty) return null;

    final attributes = jsonEncode(_credentialAttributes(definition));
    final created = await _createCredentialDefinitionUsecase.call(
      request.workspaceId,
      .new(
        title: '${request.skillTitle} ${request.toolTitle} credentials',
        attributesJson: attributes,
      ),
    );

    return created.id;
  }

  Map<String, Map<String, Object>> _credentialAttributes(
    SkillTemplateDefinition definition,
  ) => {
    for (final entry in definition.credentialDefinitions.entries)
      entry.key: {
        'description': entry.value.description,
        'optional': entry.value.optional,
        'secret': entry.value.secret,
      },
  };

  Future<String> _copyTitle(String workspaceId, String originalTitle) async {
    for (var suffix = 1; ; suffix++) {
      final title = suffix == 1
          ? '$originalTitle Copy'
          : '$originalTitle Copy $suffix';
      if (!await _titleExists(workspaceId, title)) return title;
    }
  }

  Future<bool> _titleExists(String workspaceId, String title) async {
    final cloud = cloudStore;
    if (cloud != null) {
      return (await cloud.skills()).any((skill) => skill.title == title);
    }
    final repository = _skillsRepository;
    if (repository == null) throw StateError('Skill store is unavailable');

    return await repository.getSkillByTitle(workspaceId, title) != null;
  }
}

final ProviderFamily<CloneAppSkillUsecase, String>
cloneAppSkillUsecaseProvider = Provider.family<CloneAppSkillUsecase, String>((
  ref,
  workspaceId,
) {
  final cloud = ref.watch(cloudSkillStoreProvider(workspaceId));

  return CloneAppSkillUsecase(
    ref.watch(appSkillRegistryProvider),
    cloud == null ? ref.watch(skillsRepositoryProvider) : null,
    ref.watch(createSkillUsecaseProvider(workspaceId)),
    ref.watch(createSkillCredentialDefinitionUsecaseProvider(workspaceId)),
    ref.watch(createSkillTemplateToolUsecaseProvider(workspaceId)),
    cloudStore: cloud,
  );
});
