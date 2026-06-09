import 'dart:convert';

import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/entities/skill_template_tool_entity.dart';
import 'package:auravibes_app/domain/repositories/skill_credential_definitions_repository.dart';
import 'package:auravibes_app/domain/repositories/skill_template_tools_repository.dart';
import 'package:auravibes_app/domain/repositories/skills_repository.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/usecases/build_app_skill_native_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/create_skill_credential_definition_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/create_skill_template_tool_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/create_skill_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/delete_skill_credential_definition_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/delete_skill_template_tool_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/delete_skill_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/generate_skill_slug_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/update_skill_credential_definition_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/update_skill_template_tool_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/update_skill_usecase.dart';
import 'package:riverpod/riverpod.dart';

class RunSkillsManagerToolUsecase {
  const RunSkillsManagerToolUsecase(
    this._skillsRepository,
    this._skillTemplateToolsRepository,
    this._skillCredentialDefinitionsRepository,
    this._createSkillUsecase,
    this._updateSkillUsecase,
    this._deleteSkillUsecase,
    this._createSkillTemplateToolUsecase,
    this._updateSkillTemplateToolUsecase,
    this._deleteSkillTemplateToolUsecase,
    this._createSkillCredentialDefinitionUsecase,
    this._updateSkillCredentialDefinitionUsecase,
    this._deleteSkillCredentialDefinitionUsecase,
    this._generateSlug,
  );

  final SkillsRepository _skillsRepository;
  final SkillTemplateToolsRepository _skillTemplateToolsRepository;
  final SkillCredentialDefinitionsRepository
  _skillCredentialDefinitionsRepository;
  final CreateSkillUsecase _createSkillUsecase;
  final UpdateSkillUsecase _updateSkillUsecase;
  final DeleteSkillUsecase _deleteSkillUsecase;
  final CreateSkillTemplateToolUsecase _createSkillTemplateToolUsecase;
  final UpdateSkillTemplateToolUsecase _updateSkillTemplateToolUsecase;
  final DeleteSkillTemplateToolUsecase _deleteSkillTemplateToolUsecase;
  final CreateSkillCredentialDefinitionUsecase
  _createSkillCredentialDefinitionUsecase;
  final UpdateSkillCredentialDefinitionUsecase
  _updateSkillCredentialDefinitionUsecase;
  final DeleteSkillCredentialDefinitionUsecase
  _deleteSkillCredentialDefinitionUsecase;
  final GenerateSkillSlugUsecase _generateSlug;

  Future<Object> call({
    required String workspaceId,
    required String toolSlug,
    required Map<String, dynamic> arguments,
  }) {
    return switch (toolSlug) {
      listUserSkillsToolSlug => _listUserSkills(workspaceId),
      getUserSkillToolSlug => _getUserSkillResult(workspaceId, arguments),
      createUserSkillToolSlug => _createUserSkill(workspaceId, arguments),
      updateUserSkillToolSlug => _updateUserSkill(workspaceId, arguments),
      deleteUserSkillToolSlug => _deleteUserSkill(workspaceId, arguments),
      listSkillTemplateToolsToolSlug => _listSkillTemplateTools(
        workspaceId,
        arguments,
      ),
      getSkillTemplateToolToolSlug => _getSkillTemplateToolResult(
        workspaceId,
        arguments,
      ),
      createSkillTemplateToolSlug => _createSkillTemplateTool(
        workspaceId,
        arguments,
      ),
      updateSkillTemplateToolSlug => _updateSkillTemplateTool(
        workspaceId,
        arguments,
      ),
      deleteSkillTemplateToolSlug => _deleteSkillTemplateTool(
        workspaceId,
        arguments,
      ),
      listSkillCredentialDefinitionsToolSlug => _listSkillCredentialDefinitions(
        workspaceId,
      ),
      getSkillCredentialDefinitionToolSlug =>
        _getSkillCredentialDefinitionResult(workspaceId, arguments),
      createSkillCredentialDefinitionToolSlug =>
        _createSkillCredentialDefinition(workspaceId, arguments),
      updateSkillCredentialDefinitionToolSlug =>
        _updateSkillCredentialDefinition(workspaceId, arguments),
      deleteSkillCredentialDefinitionToolSlug =>
        _deleteSkillCredentialDefinition(workspaceId, arguments),
      _ => throw UnsupportedError('Unsupported skills manager tool: $toolSlug'),
    };
  }

  Future<Object> _listUserSkills(String workspaceId) async {
    final skills = await _skillsRepository.getWorkspaceSkills(workspaceId);

    return {
      'skills': [
        for (final skill in skills.where(
          (skill) => skill.source == SkillSource.user,
        ))
          _skillResult('found', skill),
      ],
    };
  }

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
      SkillToCreate(
        kind: SkillKind.template,
        title: _requiredString(arguments, 'title'),
        description: _requiredString(arguments, 'description'),
        content: _requiredString(arguments, 'content'),
        credentialDefinitionId: credentialDefinitionId,
        isCredentialOptional:
            _optionalBool(arguments, 'isCredentialOptional') ?? false,
        isEnabled: _optionalBool(arguments, 'isEnabled') ?? true,
      ),
    );

    return _skillResult('created', skill, includeDetails: true);
  }

  Future<Object> _updateUserSkill(
    String workspaceId,
    Map<String, dynamic> arguments,
  ) async {
    _rejectCredentialDefinitionSlug(arguments);
    final skill = await _getUserSkill(
      workspaceId,
      _requiredString(arguments, 'skillSlug'),
    );
    final hasCredentialDefinitionArgument = arguments.containsKey(
      'credentialDefinitionId',
    );
    final credentialDefinitionId = hasCredentialDefinitionArgument
        ? await _resolveCredentialDefinitionId(
            arguments['credentialDefinitionId'],
          )
        : null;
    final updated = await _updateSkillUsecase.call(
      skill.id,
      SkillToUpdate(
        title: _optionalString(arguments, 'title'),
        description: _optionalString(arguments, 'description'),
        content: _optionalString(arguments, 'content'),
        credentialDefinitionId: credentialDefinitionId,
        clearCredentialDefinition:
            hasCredentialDefinitionArgument && credentialDefinitionId == null,
        isCredentialOptional: _optionalBool(arguments, 'isCredentialOptional'),
        isEnabled: _optionalBool(arguments, 'isEnabled'),
      ),
    );

    return _skillResult('updated', updated, includeDetails: true);
  }

  Future<Object> _deleteUserSkill(
    String workspaceId,
    Map<String, dynamic> arguments,
  ) async {
    final skill = await _getUserSkill(
      workspaceId,
      _requiredString(arguments, 'skillSlug'),
    );
    final deleted = await _deleteSkillUsecase.call(skill.id);

    return {
      'status': deleted ? 'deleted' : 'not_deleted',
      'skillId': skill.id,
      'slug': skill.slug,
    };
  }

  Future<Object> _listSkillTemplateTools(
    String workspaceId,
    Map<String, dynamic> arguments,
  ) async {
    final skill = await _getUserSkill(
      workspaceId,
      _requiredString(arguments, 'skillSlug'),
    );
    final tools = await _skillTemplateToolsRepository.getSkillTools(skill.id);

    return {
      'skillSlug': skill.slug,
      'tools': [for (final tool in tools) _toolResult('found', tool)],
    };
  }

  Future<Object> _getSkillTemplateToolResult(
    String workspaceId,
    Map<String, dynamic> arguments,
  ) async {
    final tool = await _getSkillTemplateTool(workspaceId, arguments);

    return _toolResult('found', tool, includeDetails: true);
  }

  Future<Object> _createSkillTemplateTool(
    String workspaceId,
    Map<String, dynamic> arguments,
  ) async {
    final skill = await _getUserSkill(
      workspaceId,
      _requiredString(arguments, 'skillSlug'),
    );
    final title = _requiredString(arguments, 'title');
    final slug = _generateSlug.call(title);
    final duplicate = await _skillTemplateToolsRepository.getToolBySlug(
      skill.id,
      slug,
    );
    if (duplicate != null) {
      throw StateError('A skill template tool with this title already exists.');
    }
    final tool = await _createSkillTemplateToolUsecase.call(
      skill.id,
      SkillTemplateToolToCreate(
        templateType: SkillTemplateToolType.url,
        title: title,
        description: _requiredString(arguments, 'description'),
        templateJson: _jsonObjectString(arguments, 'template'),
        inputsJson: _jsonObjectString(arguments, 'inputs'),
        requiresCredential:
            _optionalBool(arguments, 'requiresCredential') ?? false,
        isEnabled: _optionalBool(arguments, 'isEnabled') ?? true,
      ),
    );

    return _toolResult('created', tool, includeDetails: true);
  }

  Future<Object> _updateSkillTemplateTool(
    String workspaceId,
    Map<String, dynamic> arguments,
  ) async {
    final skill = await _getUserSkill(
      workspaceId,
      _requiredString(arguments, 'skillSlug'),
    );
    final tool = await _skillTemplateToolsRepository.getToolBySlug(
      skill.id,
      _requiredString(arguments, 'toolSlug'),
    );
    if (tool == null) {
      throw StateError('Skill template tool not found.');
    }
    final updated = await _updateSkillTemplateToolUsecase.call(
      tool.id,
      SkillTemplateToolToUpdate(
        title: _optionalString(arguments, 'title'),
        description: _optionalString(arguments, 'description'),
        templateJson: _optionalJsonObjectString(arguments, 'template'),
        inputsJson: _optionalJsonObjectString(arguments, 'inputs'),
        requiresCredential: _optionalBool(arguments, 'requiresCredential'),
        isEnabled: _optionalBool(arguments, 'isEnabled'),
      ),
    );

    return _toolResult('updated', updated, includeDetails: true);
  }

  Future<Object> _deleteSkillTemplateTool(
    String workspaceId,
    Map<String, dynamic> arguments,
  ) async {
    final tool = await _getSkillTemplateTool(workspaceId, arguments);
    final deleted = await _deleteSkillTemplateToolUsecase.call(tool.id);

    return {
      'status': deleted ? 'deleted' : 'not_deleted',
      'toolId': tool.id,
      'skillId': tool.skillId,
      'slug': tool.slug,
    };
  }

  Future<Object> _listSkillCredentialDefinitions(String workspaceId) async {
    final definitions = await _skillCredentialDefinitionsRepository
        .getDefinitions(workspaceId);

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
    final title = _requiredString(arguments, 'title');
    final slug = _generateSlug.call(title);
    final duplicate = await _skillCredentialDefinitionsRepository
        .getDefinitionBySlug(workspaceId, slug);
    if (duplicate != null) {
      throw StateError(
        'A skill credential definition with this title already exists.',
      );
    }
    final definition = await _createSkillCredentialDefinitionUsecase.call(
      workspaceId,
      SkillCredentialDefinitionToCreate(
        title: title,
        attributesJson: _jsonObjectString(arguments, 'attributes'),
      ),
    );

    return _credentialDefinitionResult('created', definition);
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
      SkillCredentialDefinitionToUpdate(
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
    final deleted = await _deleteSkillCredentialDefinitionUsecase.call(
      definition.id,
    );

    return {
      'status': deleted ? 'deleted' : 'not_deleted',
      'definitionId': definition.id,
      'slug': definition.slug,
    };
  }

  Future<SkillEntity> _getUserSkill(String workspaceId, String slug) async {
    final skill = await _skillsRepository.getSkillBySlug(workspaceId, slug);
    if (skill == null || skill.source != SkillSource.user) {
      throw StateError('User skill not found: $slug');
    }

    return skill;
  }

  Future<SkillTemplateToolEntity> _getSkillTemplateTool(
    String workspaceId,
    Map<String, dynamic> arguments,
  ) async {
    final skill = await _getUserSkill(
      workspaceId,
      _requiredString(arguments, 'skillSlug'),
    );
    final tool = await _skillTemplateToolsRepository.getToolBySlug(
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
    final definition = await _skillCredentialDefinitionsRepository
        .getDefinitionBySlug(workspaceId, slug);
    if (definition == null) {
      throw StateError('Skill credential definition not found: $slug');
    }

    return definition;
  }

  Future<String?> _resolveCredentialDefinitionId(Object? definitionId) async {
    if (definitionId == null || '$definitionId'.trim().isEmpty) return null;
    final id = '$definitionId'.trim();
    final definition = await _skillCredentialDefinitionsRepository
        .getDefinitionById(id);
    if (definition == null) {
      throw StateError('Skill credential definition not found: $id');
    }

    return definition.id;
  }

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
      if (includeDetails) ...{
        'description': skill.description,
        'content': skill.content,
        'isEnabled': skill.isEnabled,
      },
      if (includeDetails || skill.credentialDefinitionId != null)
        'credentialDefinitionId': skill.credentialDefinitionId,
      'isCredentialOptional': skill.isCredentialOptional,
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
      if (includeDetails) ...{
        'description': tool.description,
        'template': jsonDecode(tool.templateJson),
        'inputs': jsonDecode(tool.inputsJson),
        'isEnabled': tool.isEnabled,
      },
      'requiresCredential': tool.requiresCredential,
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

  String? _optionalJsonObjectString(
    Map<String, dynamic> arguments,
    String key,
  ) {
    if (!arguments.containsKey(key)) return null;

    return _jsonObjectString(arguments, key);
  }
}

final runSkillsManagerToolUsecaseProvider =
    Provider<RunSkillsManagerToolUsecase>((ref) {
      return RunSkillsManagerToolUsecase(
        ref.watch(skillsRepositoryProvider),
        ref.watch(skillTemplateToolsRepositoryProvider),
        ref.watch(skillCredentialDefinitionsRepositoryProvider),
        ref.watch(createSkillUsecaseProvider),
        ref.watch(updateSkillUsecaseProvider),
        ref.watch(deleteSkillUsecaseProvider),
        ref.watch(createSkillTemplateToolUsecaseProvider),
        ref.watch(updateSkillTemplateToolUsecaseProvider),
        ref.watch(deleteSkillTemplateToolUsecaseProvider),
        ref.watch(
          createSkillCredentialDefinitionUsecaseProvider,
        ),
        ref.watch(
          updateSkillCredentialDefinitionUsecaseProvider,
        ),
        ref.watch(
          deleteSkillCredentialDefinitionUsecaseProvider,
        ),
        ref.watch(generateSkillSlugUsecaseProvider),
      );
    });
