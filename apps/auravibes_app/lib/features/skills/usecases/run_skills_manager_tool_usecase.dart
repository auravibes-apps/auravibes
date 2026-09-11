// ignore_for_file: implementation_imports
import 'dart:convert';

import 'package:auravibes_app/data/repositories/skill_credential_definitions_repository.dart';
import 'package:auravibes_app/data/repositories/skill_template_tools_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/entities/skill_template_tool_entity.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:auravibes_app/features/skills/usecases/build_app_skill_native_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/create_skill_credential_definition_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/create_skill_template_tool_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/create_skill_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/update_skill_credential_definition_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/update_skill_template_tool_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/update_skill_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:riverpod/src/providers/provider.dart';

const Set<String> _userSkillToolSlugs = {
  SkillToolSlugs.listUserSkills,
  SkillToolSlugs.getUserSkill,
  SkillToolSlugs.createUserSkill,
  SkillToolSlugs.updateUserSkill,
  SkillToolSlugs.deleteUserSkill,
};
const Set<String> _templateToolSlugs = {
  SkillToolSlugs.listSkillTemplateTools,
  SkillToolSlugs.getSkillTemplateTool,
  SkillToolSlugs.createSkillTemplateTool,
  SkillToolSlugs.updateSkillTemplateTool,
  SkillToolSlugs.deleteSkillTemplateTool,
};
const Set<String> _credentialDefinitionToolSlugs = {
  SkillToolSlugs.listSkillCredentialDefinitions,
  SkillToolSlugs.getSkillCredentialDefinition,
  SkillToolSlugs.createSkillCredentialDefinition,
  SkillToolSlugs.updateSkillCredentialDefinition,
  SkillToolSlugs.deleteSkillCredentialDefinition,
};

typedef _SkillTemplateToolCreation = ({String skillId, String title});
typedef _SkillManagerToolRequest = ({
  String workspaceId,
  String toolSlug,
  Map<String, dynamic> arguments,
});

class const RunSkillsManagerToolUsecase(
  final SkillsRepository? _skillsRepository,
  final SkillTemplateToolsRepository? _skillTemplateToolsRepository,
  final SkillCredentialDefinitionsRepository?
  _skillCredentialDefinitionsRepository,
  final CreateSkillUsecase _createSkillUsecase,
  final UpdateSkillUsecase _updateSkillUsecase,
  final CreateSkillTemplateToolUsecase _createSkillTemplateToolUsecase,
  final UpdateSkillTemplateToolUsecase _updateSkillTemplateToolUsecase,
  final CreateSkillCredentialDefinitionUsecase
  _createSkillCredentialDefinitionUsecase,
  final UpdateSkillCredentialDefinitionUsecase
  _updateSkillCredentialDefinitionUsecase, {
  final CloudSkillStore? cloudStore,
}) {
  Future<Object> call({
    required String workspaceId,
    required String toolSlug,
    required Map<String, dynamic> arguments,
  }) {
    if (_userSkillToolSlugs.contains(toolSlug)) {
      return _callUserSkillTool(workspaceId, toolSlug, arguments);
    }
    if (_templateToolSlugs.contains(toolSlug)) {
      return _callTemplateTool(workspaceId, toolSlug, arguments);
    }
    if (_credentialDefinitionToolSlugs.contains(toolSlug)) {
      return _callCredentialDefinitionTool(workspaceId, toolSlug, arguments);
    }

    throw UnsupportedError('Unsupported skills manager tool: $toolSlug');
  }
}

extension _RunSkillsManagerRouting on RunSkillsManagerToolUsecase {
  Future<Object> _callUserSkillTool(
    String workspaceId,
    String toolSlug,
    Map<String, dynamic> arguments,
  ) => switch (toolSlug) {
    SkillToolSlugs.listUserSkills => _listUserSkills(workspaceId),
    SkillToolSlugs.getUserSkill => _getUserSkillResult(workspaceId, arguments),
    SkillToolSlugs.createUserSkill => _createUserSkill(workspaceId, arguments),
    SkillToolSlugs.updateUserSkill => _updateUserSkill(workspaceId, arguments),
    SkillToolSlugs.deleteUserSkill => _deleteUserSkill(workspaceId, arguments),
    _ => throw UnsupportedError('Unsupported skills manager tool: $toolSlug'),
  };

  Future<Object> _callTemplateTool(
    String workspaceId,
    String toolSlug,
    Map<String, dynamic> arguments,
  ) {
    if (toolSlug == SkillToolSlugs.listSkillTemplateTools) {
      return _listSkillTemplateTools(workspaceId, arguments);
    }
    if (toolSlug == SkillToolSlugs.getSkillTemplateTool) {
      return _getSkillTemplateToolResult(workspaceId, arguments);
    }

    return _callTemplateMutationTool((
      workspaceId: workspaceId,
      toolSlug: toolSlug,
      arguments: arguments,
    ));
  }

  Future<Object> _callTemplateMutationTool(_SkillManagerToolRequest request) {
    final toolSlug = request.toolSlug;

    return switch (toolSlug) {
      SkillToolSlugs.createSkillTemplateTool => _createSkillTemplateTool(
        request,
      ),
      SkillToolSlugs.updateSkillTemplateTool => _updateSkillTemplateTool(
        request,
      ),
      SkillToolSlugs.deleteSkillTemplateTool => _deleteSkillTemplateTool(
        request,
      ),
      _ => throw UnsupportedError('Unsupported skills manager tool: $toolSlug'),
    };
  }

  Future<Object> _callCredentialDefinitionTool(
    String workspaceId,
    String toolSlug,
    Map<String, dynamic> arguments,
  ) {
    if (toolSlug == SkillToolSlugs.listSkillCredentialDefinitions) {
      return _listSkillCredentialDefinitions(workspaceId);
    }
    if (toolSlug == SkillToolSlugs.getSkillCredentialDefinition) {
      return _getSkillCredentialDefinitionResult(workspaceId, arguments);
    }

    return _callCredentialMutationTool(workspaceId, toolSlug, arguments);
  }

  Future<Object> _callCredentialMutationTool(
    String workspaceId,
    String toolSlug,
    Map<String, dynamic> arguments,
  ) => switch (toolSlug) {
    SkillToolSlugs.createSkillCredentialDefinition =>
      _createSkillCredentialDefinition(workspaceId, arguments),
    SkillToolSlugs.updateSkillCredentialDefinition =>
      _updateSkillCredentialDefinition(workspaceId, arguments),
    SkillToolSlugs.deleteSkillCredentialDefinition =>
      _deleteSkillCredentialDefinition(workspaceId, arguments),
    _ => throw UnsupportedError('Unsupported skills manager tool: $toolSlug'),
  };
}

extension _RunSkillsManagerMutations on RunSkillsManagerToolUsecase {
  Future<({bool provided, String? id})> _credentialDefinitionUpdate(
    Map<String, dynamic> arguments,
  ) async {
    final provided = arguments.containsKey('credentialDefinitionId');

    return (
      provided: provided,
      id: provided
          ? await _resolveCredentialDefinitionId(
              arguments['credentialDefinitionId'],
            )
          : null,
    );
  }

  SkillToUpdate _userSkillUpdateValue(
    Map<String, dynamic> arguments,
    ({bool provided, String? id}) credential,
  ) => .new(
    title: _optionalString(arguments, 'title'),
    description: _optionalString(arguments, 'description'),
    content: _optionalString(arguments, 'content'),
    credentialDefinitionId: credential.id,
    clearCredentialDefinition: credential.provided && credential.id == null,
    isCredentialOptional: _optionalBool(arguments, 'isCredentialOptional'),
    isEnabled: _optionalBool(arguments, 'isEnabled'),
  );

  SkillToCreate _userSkillCreateValue(
    Map<String, dynamic> arguments,
    String? credentialDefinitionId,
  ) => .new(
    kind: SkillKind.template,
    title: _requiredString(arguments, 'title'),
    description: _requiredString(arguments, 'description'),
    content: _requiredString(arguments, 'content'),
    credentialDefinitionId: credentialDefinitionId,
    isCredentialOptional:
        _optionalBool(arguments, 'isCredentialOptional') ?? false,
    isEnabled: _optionalBool(arguments, 'isEnabled') ?? true,
  );

  SkillTemplateToolToCreate _skillTemplateToolCreateValue(
    Map<String, dynamic> arguments,
    String title,
  ) => .new(
    templateType: SkillTemplateToolType.url,
    title: title,
    description: _requiredString(arguments, 'description'),
    templateJson: _jsonObjectString(arguments, 'template'),
    inputsJson: _jsonObjectString(arguments, 'inputs'),
    requiresCredential: _optionalBool(arguments, 'requiresCredential') ?? false,
    isEnabled: _optionalBool(arguments, 'isEnabled') ?? true,
  );

  SkillTemplateToolToUpdate _skillTemplateToolUpdateValue(
    Map<String, dynamic> arguments,
  ) => .new(
    title: _optionalString(arguments, 'title'),
    description: _optionalString(arguments, 'description'),
    templateJson: _optionalJsonObjectString(arguments, 'template'),
    inputsJson: _optionalJsonObjectString(arguments, 'inputs'),
    requiresCredential: _optionalBool(arguments, 'requiresCredential'),
    isEnabled: _optionalBool(arguments, 'isEnabled'),
  );

  Future<Object> _updateUserSkill(
    String workspaceId,
    Map<String, dynamic> arguments,
  ) async {
    _rejectCredentialDefinitionSlug(arguments);
    final skill = await _getUserSkill(
      workspaceId,
      _requiredString(arguments, 'skillSlug'),
    );
    final credential = await _credentialDefinitionUpdate(arguments);
    final updated = await _updateSkillUsecase.call(
      skill.id,
      _userSkillUpdateValue(arguments, credential),
    );

    return _skillResult('updated', updated, includeDetails: true);
  }

  Future<List<SkillEntity>> _userSkills(String workspaceId) async {
    final cloud = cloudStore;
    if (cloud != null) return await cloud.skills();

    return await _skillsRepositoryOrThrow().getWorkspaceSkills(workspaceId);
  }

  Future<bool> _deleteUserSkillData(SkillEntity skill) async {
    final cloud = cloudStore;
    if (cloud != null) return await _deleteSkill(cloud, skill.id);

    return await _skillsRepositoryOrThrow().deleteSkill(skill.id);
  }
}

extension _RunSkillsManagerUserSkills on RunSkillsManagerToolUsecase {
  Future<Object> _getUserSkillResult(
    String workspaceId,
    Map<String, dynamic> arguments,
  ) async {
    final skill = await _getUserSkill(
      workspaceId,
      _requiredString(arguments, 'skillSlug'),
    );

    return _skillResult('found', skill, includeDetails: true);
  }

  Future<Object> _createUserSkill(
    String workspaceId,
    Map<String, dynamic> arguments,
  ) async {
    _rejectCredentialDefinitionSlug(arguments);
    final credentialDefinitionId = await _resolveCredentialDefinitionId(
      arguments['credentialDefinitionId'],
    );
    final skill = await _createSkillUsecase.call(
      workspaceId,
      _userSkillCreateValue(arguments, credentialDefinitionId),
    );

    return _skillResult('created', skill, includeDetails: true);
  }

  Future<Object> _listUserSkills(String workspaceId) async {
    final skills = await _userSkills(workspaceId);

    return {'skills': _userSkillResults(skills)};
  }

  List<Map<String, Object?>> _userSkillResults(List<SkillEntity> skills) => [
    for (final skill in skills.where(
      (skill) => skill.source == SkillSource.user,
    ))
      _skillResult('found', skill),
  ];

  Future<Object> _deleteUserSkill(
    String workspaceId,
    Map<String, dynamic> arguments,
  ) async {
    final skill = await _getUserSkill(
      workspaceId,
      _requiredString(arguments, 'skillSlug'),
    );
    final deleted = await _deleteUserSkillData(skill);

    return _skillDeletionResult(deleted, skill);
  }
}

extension _RunSkillsManagerTemplateTools on RunSkillsManagerToolUsecase {
  Future<Object> _listSkillTemplateTools(
    String workspaceId,
    Map<String, dynamic> arguments,
  ) async {
    final skill = await _getUserSkill(
      workspaceId,
      _requiredString(arguments, 'skillSlug'),
    );
    final tools = await _skillTemplateTools(skill.id);

    return {'skillSlug': skill.slug, 'tools': _templateToolResults(tools)};
  }

  List<Map<String, Object?>> _templateToolResults(
    List<SkillTemplateToolEntity> tools,
  ) => [for (final tool in tools) _toolResult('found', tool)];

  Future<Object> _getSkillTemplateToolResult(
    String workspaceId,
    Map<String, dynamic> arguments,
  ) async {
    final tool = await _getSkillTemplateTool(workspaceId, arguments);

    return _toolResult('found', tool, includeDetails: true);
  }

  Future<Object> _createSkillTemplateTool(
    _SkillManagerToolRequest request,
  ) async {
    final creation = await _prepareSkillTemplateToolCreation(
      request.workspaceId,
      request.arguments,
    );
    final tool = await _createSkillTemplateToolEntity(
      creation.skillId,
      request.arguments,
      creation.title,
    );

    return _toolResult('created', tool, includeDetails: true);
  }

  Future<Object> _updateSkillTemplateTool(
    _SkillManagerToolRequest request,
  ) async {
    final tool = await _getSkillTemplateTool(
      request.workspaceId,
      request.arguments,
    );
    final updated = await _updateSkillTemplateToolUsecase.call(
      tool.id,
      _skillTemplateToolUpdateValue(request.arguments),
    );

    return _toolResult('updated', updated, includeDetails: true);
  }

  Future<Object> _deleteSkillTemplateTool(
    _SkillManagerToolRequest request,
  ) async {
    final deletion = await _deleteSkillTemplateToolData(
      request.workspaceId,
      request.arguments,
    );

    return _toolDeletionResult(deletion.deleted, deletion.tool);
  }
}

extension _RunSkillsManagerTemplateToolSupport on RunSkillsManagerToolUsecase {
  Future<_SkillTemplateToolCreation> _prepareSkillTemplateToolCreation(
    String workspaceId,
    Map<String, dynamic> arguments,
  ) async {
    final skill = await _getUserSkill(
      workspaceId,
      _requiredString(arguments, 'skillSlug'),
    );
    final title = _requiredString(arguments, 'title');
    await _ensureSkillTemplateTitleAvailable(skill.id, title);

    return (skillId: skill.id, title: title);
  }

  Future<({bool deleted, SkillTemplateToolEntity tool})>
  _deleteSkillTemplateToolData(
    String workspaceId,
    Map<String, dynamic> arguments,
  ) async {
    final tool = await _getSkillTemplateTool(workspaceId, arguments);
    final deleted = await _deleteTemplateTool(tool.id);

    return (deleted: deleted, tool: tool);
  }

  Future<bool> _deleteTemplateTool(String toolId) {
    final cloud = cloudStore;
    if (cloud != null) return _deleteTool(cloud, toolId);

    return _skillTemplateToolsRepositoryOrThrow().deleteTool(toolId);
  }

  void _throwIfDuplicateSkillTemplateTool(SkillTemplateToolEntity? duplicate) {
    if (duplicate == null) return;

    throw StateError('A skill template tool with this title already exists.');
  }

  Future<List<SkillTemplateToolEntity>> _skillTemplateTools(
    String skillId,
  ) async {
    final cloud = cloudStore;
    if (cloud != null) return await cloud.tools(skillId);

    return await _skillTemplateToolsRepositoryOrThrow().getSkillTools(skillId);
  }

  Future<void> _ensureSkillTemplateTitleAvailable(
    String skillId,
    String title,
  ) async {
    final duplicate = await _toolBySlug(skillId, generateSkillSlug(title));
    _throwIfDuplicateSkillTemplateTool(duplicate);
  }

  Future<SkillTemplateToolEntity> _createSkillTemplateToolEntity(
    String skillId,
    Map<String, dynamic> arguments,
    String title,
  ) => _createSkillTemplateToolUsecase.call(
    skillId,
    _skillTemplateToolCreateValue(arguments, title),
  );
}

extension _RunSkillsManagerCredentials on RunSkillsManagerToolUsecase {
  Future<Object> _listSkillCredentialDefinitions(String workspaceId) async {
    final cloud = cloudStore;
    final definitions = cloud != null
        ? await cloud.definitions()
        : await _skillCredentialDefinitionsRepositoryOrThrow().getDefinitions(
            workspaceId,
          );

    return {
      'definitions': [
        for (final definition in definitions)
          _credentialDefinitionResult('found', definition),
      ],
    };
  }

  Future<Object> _getSkillCredentialDefinitionResult(
    String workspaceId,
    Map<String, dynamic> arguments,
  ) async {
    final definition = await _getSkillCredentialDefinition(
      workspaceId,
      _requiredString(arguments, 'definitionSlug'),
    );

    return _credentialDefinitionResult('found', definition);
  }

  Future<Object> _createSkillCredentialDefinition(
    String workspaceId,
    Map<String, dynamic> arguments,
  ) async {
    final title = await _credentialDefinitionTitle(workspaceId, arguments);
    final definition = await _createSkillCredentialDefinitionUsecase.call(
      workspaceId,
      _credentialDefinitionCreateValue(arguments, title),
    );

    return _credentialDefinitionResult('created', definition);
  }

  Future<String> _credentialDefinitionTitle(
    String workspaceId,
    Map<String, dynamic> arguments,
  ) async {
    final title = _requiredString(arguments, 'title');
    await _ensureCredentialDefinitionTitleAvailable(
      workspaceId,
      generateSkillSlug(title),
    );

    return title;
  }

  Future<void> _ensureCredentialDefinitionTitleAvailable(
    String workspaceId,
    String slug,
  ) async {
    final duplicate = await _definitionBySlug(workspaceId, slug);
    if (duplicate != null) {
      throw StateError(
        'A skill credential definition with this title already exists.',
      );
    }
  }

  Future<Object> _updateSkillCredentialDefinition(
    String workspaceId,
    Map<String, dynamic> arguments,
  ) async {
    final definition = await _getSkillCredentialDefinition(
      workspaceId,
      _requiredString(arguments, 'definitionSlug'),
    );
    final updated = await _updateSkillCredentialDefinitionUsecase.call(
      definition.id,
      .new(
        title: _optionalString(arguments, 'title'),
        attributesJson: _optionalJsonObjectString(arguments, 'attributes'),
      ),
    );

    return _credentialDefinitionResult('updated', updated);
  }

  Future<Object> _deleteSkillCredentialDefinition(
    String workspaceId,
    Map<String, dynamic> arguments,
  ) async {
    final definition = await _getSkillCredentialDefinition(
      workspaceId,
      _requiredString(arguments, 'definitionSlug'),
    );
    final deleted = await _deleteCredentialDefinitionById(definition.id);

    return _credentialDefinitionDeletionResult(deleted, definition);
  }

  Future<bool> _deleteCredentialDefinitionById(String definitionId) =>
      _deleteCredentialDefinition(
        definitionId,
        cloud: cloudStore,
        repository: _skillCredentialDefinitionsRepository,
      );
}

extension _RunSkillsManagerCredentialValues on RunSkillsManagerToolUsecase {
  SkillCredentialDefinitionToCreate _credentialDefinitionCreateValue(
    Map<String, dynamic> arguments,
    String title,
  ) => .new(
    title: title,
    attributesJson: _jsonObjectString(arguments, 'attributes'),
  );
}

extension _RunSkillsManagerLookups on RunSkillsManagerToolUsecase {
  Future<SkillEntity> _getUserSkill(String workspaceId, String slug) async {
    final skill = await _loadUserSkill(workspaceId, slug);
    if (skill == null || skill.source != SkillSource.user) {
      throw StateError('User skill not found: $slug');
    }

    return skill;
  }

  Future<SkillEntity?> _loadUserSkill(String workspaceId, String slug) async {
    final cloud = cloudStore;
    if (cloud != null) {
      return (await cloud.skills())
          .where((item) => item.slug == slug)
          .firstOrNull;
    }
    final repository = _skillsRepository;
    if (repository != null) {
      return await repository.getSkillBySlug(workspaceId, slug);
    }

    throw StateError('Skill store is unavailable');
  }

  Future<bool> _deleteCredentialDefinition(
    String definitionId, {
    required CloudSkillStore? cloud,
    required SkillCredentialDefinitionsRepository? repository,
  }) async {
    if (cloud != null) {
      await cloud.deleteDefinition(definitionId);

      return true;
    }
    if (repository != null) {
      return await repository.deleteDefinition(definitionId);
    }

    throw StateError('Credential definition store is unavailable');
  }

  Future<SkillTemplateToolEntity> _getSkillTemplateTool(
    String workspaceId,
    Map<String, dynamic> arguments,
  ) async {
    final skill = await _getUserSkill(
      workspaceId,
      _requiredString(arguments, 'skillSlug'),
    );
    final tool = await _toolBySlug(
      skill.id,
      _requiredString(arguments, 'toolSlug'),
    );
    if (tool == null) {
      throw StateError('Skill template tool not found.');
    }

    return tool;
  }

  Future<SkillCredentialDefinitionEntity> _getSkillCredentialDefinition(
    String workspaceId,
    String slug,
  ) async {
    final definition = await _definitionBySlug(workspaceId, slug);
    if (definition == null) {
      throw StateError('Skill credential definition not found: $slug');
    }

    return definition;
  }
}

extension _RunSkillsManagerRepositories on RunSkillsManagerToolUsecase {
  Future<String?> _resolveCredentialDefinitionId(Object? definitionId) async {
    if (definitionId == null || '$definitionId'.trim().isEmpty) return null;
    final id = '$definitionId'.trim();
    final definition =
        await cloudStore?.definition(id) ??
        await _skillCredentialDefinitionsRepository?.getDefinitionById(id);
    if (definition == null) {
      throw StateError('Skill credential definition not found: $id');
    }

    return definition.id;
  }

  String? _optionalJsonObjectString(
    Map<String, dynamic> arguments,
    String key,
  ) {
    if (!arguments.containsKey(key)) return null;

    return _jsonObjectString(arguments, key);
  }

  Future<SkillCredentialDefinitionEntity?> _definitionBySlug(
    String workspaceId,
    String slug,
  ) async {
    final cloud = cloudStore;
    if (cloud != null) {
      return (await cloud.definitions())
          .where((item) => item.slug == slug)
          .firstOrNull;
    }
    final repository = _skillCredentialDefinitionsRepository;
    if (repository == null) {
      throw StateError('Credential definition store is unavailable');
    }

    return await repository.getDefinitionBySlug(workspaceId, slug);
  }

  SkillsRepository _skillsRepositoryOrThrow() {
    final repository = _skillsRepository;
    if (repository == null) throw StateError('Skill store is unavailable');

    return repository;
  }

  SkillTemplateToolsRepository _skillTemplateToolsRepositoryOrThrow() {
    final repository = _skillTemplateToolsRepository;
    if (repository == null) {
      throw StateError('Skill template tool store is unavailable');
    }

    return repository;
  }

  SkillCredentialDefinitionsRepository
  _skillCredentialDefinitionsRepositoryOrThrow() {
    final repository = _skillCredentialDefinitionsRepository;
    if (repository == null) {
      throw StateError('Credential definition store is unavailable');
    }

    return repository;
  }

  Future<bool> _deleteSkill(CloudSkillStore cloud, String skillId) async {
    await cloud.deleteSkill(skillId);

    return true;
  }

  Future<bool> _deleteTool(CloudSkillStore cloud, String toolId) async {
    await cloud.deleteTool(toolId);

    return true;
  }
}

extension _RunSkillsManagerResults on RunSkillsManagerToolUsecase {
  Map<String, Object?> _skillResult(
    String status,
    SkillEntity skill, {
    bool includeDetails = false,
  }) {
    return {
      'status': status,
      'skillId': skill.id,
      'slug': skill.slug,
      'title': skill.title,
      if (includeDetails) ..._skillDetails(skill),
      ..._skillCredentialFields(skill, includeDetails),
    };
  }

  Map<String, Object?> _toolResult(
    String status,
    SkillTemplateToolEntity tool, {
    bool includeDetails = false,
  }) {
    return {
      'status': status,
      'toolId': tool.id,
      'skillId': tool.skillId,
      'slug': tool.slug,
      'title': tool.title,
      if (includeDetails) ..._toolDetails(tool),
      ..._toolCredentialFields(tool),
    };
  }

  Map<String, Object?> _credentialDefinitionResult(
    String status,
    SkillCredentialDefinitionEntity definition,
  ) {
    return {
      'status': status,
      'definitionId': definition.id,
      'slug': definition.slug,
      'title': definition.title,
      'attributes': _credentialDefinitionAttributes(definition),
    };
  }

  Map<String, Object?> _credentialDefinitionAttributes(
    SkillCredentialDefinitionEntity definition,
  ) {
    final attributes = SkillCredentialAttributeDefinition.parseMap(
      definition.attributesJson,
    );

    return {
      for (final entry in attributes.entries)
        entry.key: {
          'description': entry.value.description,
          'optional': entry.value.optional,
          'secret': entry.value.secret,
        },
    };
  }
}

extension _RunSkillsManagerResultDetails on RunSkillsManagerToolUsecase {
  Map<String, Object?> _skillCredentialFields(
    SkillEntity skill,
    bool includeDetails,
  ) => {
    if (includeDetails || skill.credentialDefinitionId != null)
      'credentialDefinitionId': skill.credentialDefinitionId,
    'isCredentialOptional': skill.isCredentialOptional,
  };

  Map<String, Object?> _toolCredentialFields(SkillTemplateToolEntity tool) => {
    'requiresCredential': tool.requiresCredential,
  };

  Map<String, Object?> _skillDetails(SkillEntity skill) => {
    'description': skill.description,
    'content': skill.content,
    'isEnabled': skill.isEnabled,
  };

  Map<String, Object?> _toolDetails(SkillTemplateToolEntity tool) => {
    'description': tool.description,
    'template': jsonDecode(tool.templateJson),
    'inputs': jsonDecode(tool.inputsJson),
    'isEnabled': tool.isEnabled,
  };

  Map<String, Object?> _skillDeletionResult(bool deleted, SkillEntity skill) =>
      {
        'status': deleted ? 'deleted' : 'not_deleted',
        'skillId': skill.id,
        'slug': skill.slug,
      };

  Map<String, Object?> _toolDeletionResult(
    bool deleted,
    SkillTemplateToolEntity tool,
  ) => {
    'status': deleted ? 'deleted' : 'not_deleted',
    'toolId': tool.id,
    'skillId': tool.skillId,
    'slug': tool.slug,
  };

  Map<String, Object?> _credentialDefinitionDeletionResult(
    bool deleted,
    SkillCredentialDefinitionEntity definition,
  ) => {
    'status': deleted ? 'deleted' : 'not_deleted',
    'definitionId': definition.id,
    'slug': definition.slug,
  };
}

extension _RunSkillsManagerInputValidation on RunSkillsManagerToolUsecase {
  String _requiredString(Map<String, dynamic> arguments, String key) {
    final value = arguments[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('$key is required.');
    }

    return value.trim();
  }

  String? _optionalString(Map<String, dynamic> arguments, String key) {
    final value = arguments[key];
    if (value == null) return null;
    if (value is! String) throw FormatException('$key must be a string.');

    return value.trim();
  }

  bool? _optionalBool(Map<String, dynamic> arguments, String key) {
    final value = arguments[key];
    if (value == null) return null;
    if (value is! bool) throw FormatException('$key must be a boolean.');

    return value;
  }

  void _rejectCredentialDefinitionSlug(Map<String, dynamic> arguments) {
    if (!arguments.containsKey('credentialDefinitionSlug')) return;
    throw const FormatException(
      'credentialDefinitionSlug is unsupported. Use credentialDefinitionId.',
    );
  }

  String _jsonObjectString(Map<String, dynamic> arguments, String key) {
    final value = arguments[key];
    if (value is! Map) throw FormatException('$key must be a JSON object.');

    return jsonEncode(value);
  }

  Future<SkillTemplateToolEntity?> _toolBySlug(String skillId, String slug) {
    final cloud = cloudStore;

    return cloud == null
        ? _repositoryToolBySlug(skillId, slug)
        : _cloudToolBySlug(cloud, skillId, slug);
  }

  Future<SkillTemplateToolEntity?> _repositoryToolBySlug(
    String skillId,
    String slug,
  ) {
    final repository = _skillTemplateToolsRepository;
    if (repository == null) {
      throw StateError('Skill template tool store is unavailable');
    }

    return repository.getToolBySlug(skillId, slug);
  }

  Future<SkillTemplateToolEntity?> _cloudToolBySlug(
    CloudSkillStore cloud,
    String skillId,
    String slug,
  ) async =>
      (await cloud.tools(skillId))
          .where((item) => item.slug == slug)
          .firstOrNull;
}

final ProviderFamily<RunSkillsManagerToolUsecase, String>
runSkillsManagerToolUsecaseProvider =
    Provider.family<RunSkillsManagerToolUsecase, String>((ref, workspaceId) {
      final cloud = ref.watch(cloudSkillStoreProvider(workspaceId));

      return RunSkillsManagerToolUsecase(
        cloud == null ? ref.watch(skillsRepositoryProvider) : null,
        cloud == null ? ref.watch(skillTemplateToolsRepositoryProvider) : null,
        cloud == null
            ? ref.watch(skillCredentialDefinitionsRepositoryProvider)
            : null,
        ref.watch(createSkillUsecaseProvider(workspaceId)),
        ref.watch(updateSkillUsecaseProvider(workspaceId)),
        ref.watch(createSkillTemplateToolUsecaseProvider(workspaceId)),
        ref.watch(updateSkillTemplateToolUsecaseProvider(workspaceId)),
        ref.watch(createSkillCredentialDefinitionUsecaseProvider(workspaceId)),
        ref.watch(updateSkillCredentialDefinitionUsecaseProvider(workspaceId)),
        cloudStore: cloud,
      );
    });
