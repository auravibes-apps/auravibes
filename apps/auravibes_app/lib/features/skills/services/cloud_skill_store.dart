import 'dart:convert';

import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/domain/entities/skill_credential_entity.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/entities/skill_template_tool_entity.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_resource_store.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:characters/characters.dart';
import 'package:uuid/v7.dart';

typedef _CredentialCreateData = ({
  SkillCredentialEntity entity,
  Map<String, String> secret,
});

typedef _ToolResourceUpdateRequest = ({
  String id,
  WorkspaceResource resource,
  SkillTemplateToolEntity updated,
  String skillSlug,
});

typedef _CredentialAttributeRequest = ({
  MapEntry<String, String> entry,
  Map<String, SkillCredentialAttributeDefinition> fields,
  Map<String, String> secret,
  Map<String, String> metadata,
});

typedef _CredentialCreateRequest = ({
  String id,
  SkillCredentialToCreate value,
  ({Map<String, String> secret, Map<String, String> metadata}) attributes,
  DateTime now,
});

typedef _CredentialSecretUpdateRequest = ({
  String id,
  WorkspaceResource resource,
  SkillCredentialToUpdate value,
  SkillCredentialEntity updated,
  int? secretRevision,
});

typedef _CredentialMutationRequest = ({
  String id,
  int resourceRevision,
  Map<String, Object?> data,
  String secret,
  int? secretRevision,
});

typedef _ConversationSkillRequest = ({
  String id,
  String conversationId,
  String skillId,
  bool isAppSkill,
});

typedef _AppSkillEnabledRequest = ({
  String id,
  bool enabled,
  String? slug,
  String? title,
  String? description,
  String? content,
});

typedef _SetAppSkillEnabled = Future<void> Function(
  _AppSkillEnabledRequest request,
);

final _blankSkill = SkillEntity(
  source: SkillSource.user,
  id: '',
  workspaceId: '',
  kind: .template,
  title: '',
  slug: '',
  description: '',
  content: '',
  isEnabled: false,
  isCredentialOptional: false,
  createdAt: .new(1970),
  updatedAt: .new(1970),
);

final _blankTool = SkillTemplateToolEntity(
  id: '',
  skillId: '',
  templateType: .url,
  title: '',
  description: '',
  slug: '',
  templateJson: '',
  inputsJson: '',
  isEnabled: false,
  requiresCredential: false,
  createdAt: .new(1970),
  updatedAt: .new(1970),
);

final _blankDefinition = SkillCredentialDefinitionEntity(
  id: '',
  workspaceId: '',
  title: '',
  slug: '',
  attributesJson: '',
  createdAt: .new(1970),
  updatedAt: .new(1970),
);

final _blankCredential = SkillCredentialEntity(
  id: '',
  workspaceId: '',
  credentialDefinitionId: '',
  name: '',
  attributes: const {},
  isEnabled: false,
  createdAt: .new(1970),
  updatedAt: .new(1970),
);

const _blankCredentialForEdit = SkillCredentialForEdit(
  id: '',
  workspaceId: '',
  credentialDefinitionId: '',
  name: '',
  nonSecretAttributes: {},
  secretAttributes: {},
  isEnabled: false,
);

class CloudSkillStore(
  final CloudWorkspaceResourceStore _store,
  final String workspaceId,
);

extension CloudSkillStoreSkillApi on CloudSkillStore {
  Future<List<SkillEntity>> skills() => _apiSkills();

  Future<SkillEntity?> skill(String id) => _apiSkill(id);

  Future<SkillEntity> createSkill(SkillToCreate value) =>
      _apiCreateSkill(value);

  Future<SkillEntity> updateSkill(String id, SkillToUpdate value) =>
      _apiUpdateSkill(id, value);

  Future<void> deleteSkill(String id) => _apiDeleteSkill(id);
}

extension CloudSkillStoreDefinitionApi on CloudSkillStore {
  Future<List<SkillCredentialDefinitionEntity>> definitions() =>
      _apiDefinitions();

  Future<SkillCredentialDefinitionEntity?> definition(String id) =>
      _apiDefinition(id);

  Future<SkillCredentialDefinitionEntity> createDefinition(
    SkillCredentialDefinitionToCreate value,
  ) => _apiCreateDefinition(value);

  Future<SkillCredentialDefinitionEntity> updateDefinition(
    String id,
    SkillCredentialDefinitionToUpdate value,
  ) => _apiUpdateDefinition(id, value);

  Future<void> deleteDefinition(String id) => _apiDeleteDefinition(id);
}

extension CloudSkillStoreToolApi on CloudSkillStore {
  Future<SkillTemplateToolEntity?> tool(String id) => _apiTool(id);

  Future<SkillTemplateToolEntity> createTool(
    String skillId,
    SkillTemplateToolToCreate value,
  ) => _apiCreateTool(skillId, value);

  Future<SkillTemplateToolEntity> updateTool(
    String id,
    SkillTemplateToolToUpdate value,
  ) => _apiUpdateTool(id, value);

  Future<List<SkillTemplateToolEntity>> tools(String skillId) =>
      _apiTools(skillId);

  Future<void> deleteTool(String id) => _apiDeleteTool(id);
}

extension CloudSkillStoreCredentialApi on CloudSkillStore {
  Future<List<SkillCredentialEntity>> credentials(String definitionId) =>
      _apiCredentials(definitionId);

  Future<SkillCredentialEntity> createCredential(
    SkillCredentialToCreate value,
  ) => _apiCreateCredential(value);

  Future<SkillCredentialForEdit?> credentialForEdit(String id) =>
      _apiCredentialForEdit(id);

  Future<SkillCredentialEntity> updateCredential(
    String id,
    SkillCredentialToUpdate value,
  ) => _apiUpdateCredential(id, value);

  Future<void> deleteCredential(String id) => _apiDeleteCredential(id);
}

extension CloudSkillStoreSkillOperations on CloudSkillStore {
  Future<List<SkillCredentialDefinitionEntity>> _apiDefinitions() async =>
      (await _active(.skillDefinition)).map(_definition).toList();

  Future<SkillEntity?> _apiSkill(String id) async =>
      (await _active(.skill))
          .where((item) => item.resourceId == id)
          .map(_skill)
          .firstOrNull;

  Future<SkillEntity> _apiCreateSkill(SkillToCreate value) async {
    final now = DateTime.now().toUtc();
    final id = const UuidV7().generate();
    final entity = _skillFromCreate(id, value, now);
    await _store.create(kind: .skill, id: id, data: _skillData(entity));

    return entity;
  }

  Future<SkillEntity> _apiUpdateSkill(String id, SkillToUpdate value) async {
    final resource = await _required(.skill, id);
    final current = _skill(resource);
    final updated = _updatedSkill(current, value);
    await _store.update(
      kind: .skill,
      id: id,
      revision: resource.revision,
      data: _skillData(updated),
    );

    return updated;
  }

  Future<void> _apiDeleteSkill(String id) => _delete(.skill, id);
}

extension CloudSkillStoreToolOperations on CloudSkillStore {
  Future<List<SkillTemplateToolEntity>> _apiTools(String skillId) async =>
      (await _active(.skillTemplateTool))
          .where((item) => _data(item)['skillId'] == skillId)
          .map(_tool)
          .toList();

  Future<SkillTemplateToolEntity?> _apiTool(String id) async =>
      (await _active(.skillTemplateTool))
          .where((item) => item.resourceId == id)
          .map(_tool)
          .firstOrNull;

  Future<SkillTemplateToolEntity> _apiCreateTool(
    String skillId,
    SkillTemplateToolToCreate value,
  ) async {
    final skillSlug = await _skillSlug(skillId);
    final now = DateTime.now().toUtc();
    final id = const UuidV7().generate();
    final entity = _toolFromCreate((
      id: id,
      skillId: skillId,
      value: value,
      now: now,
    ));
    await _createToolResource(entity, skillSlug);

    return entity;
  }

  Future<SkillTemplateToolEntity> _apiUpdateTool(
    String id,
    SkillTemplateToolToUpdate value,
  ) async {
    final resource = await _required(.skillTemplateTool, id);

    return _updateToolValue(id, resource, value);
  }

  Future<SkillTemplateToolEntity> _updateToolValue(
    String id,
    WorkspaceResource resource,
    SkillTemplateToolToUpdate value,
  ) async {
    final current = _tool(resource);
    final skillSlug = await _skillSlug(current.skillId);
    final updated = _updatedTool(current, value);
    await _updateToolResource((
      id: id,
      resource: resource,
      updated: updated,
      skillSlug: skillSlug,
    ));

    return updated;
  }

  Future<void> _apiDeleteTool(String id) => _delete(.skillTemplateTool, id);
}

extension CloudSkillStoreDefinitionOperations on CloudSkillStore {
  Future<List<SkillEntity>> _apiSkills() async =>
      (await _active(.skill)).map(_skill).toList();

  Future<SkillCredentialDefinitionEntity?> _apiDefinition(String id) async =>
      (await _active(.skillDefinition))
          .where((item) => item.resourceId == id)
          .map(_definition)
          .firstOrNull;

  Future<SkillCredentialDefinitionEntity> _apiCreateDefinition(
    SkillCredentialDefinitionToCreate value,
  ) async {
    final now = DateTime.now().toUtc();
    final id = const UuidV7().generate();
    final entity = _definitionFromCreate(id, value, now);
    await _store.create(
      kind: .skillDefinition,
      id: id,
      data: _definitionData(entity),
    );

    return entity;
  }

  Future<SkillCredentialDefinitionEntity> _apiUpdateDefinition(
    String id,
    SkillCredentialDefinitionToUpdate value,
  ) async {
    final resource = await _required(.skillDefinition, id);
    final current = _definition(resource);
    final updated = _updatedDefinition(current, value);
    await _store.update(
      kind: .skillDefinition,
      id: id,
      revision: resource.revision,
      data: _definitionData(updated),
    );

    return updated;
  }

  Future<void> _apiDeleteDefinition(String id) => _delete(.skillDefinition, id);
}

extension CloudSkillStoreCredentialOperations on CloudSkillStore {
  Future<List<SkillCredentialEntity>> _apiCredentials(
    String definitionId,
  ) async =>
      (await _active(.serviceConnection))
          .where((item) => _isCredentialForDefinition(item, definitionId))
          .map(_credential)
          .toList();

  Future<SkillCredentialEntity> _apiCreateCredential(
    SkillCredentialToCreate value,
  ) async {
    final input = await _credentialCreateData(value);
    final response = await _createCredentialResource(
      input.entity,
      input.secret,
    );

    return _credentialWithResponse(input.entity, response);
  }

  Future<SkillCredentialForEdit?> _apiCredentialForEdit(String id) async {
    final resource = await _credentialResource(id);
    if (resource == null) return null;
    final credential = _credential(resource);
    final definition = await this.definition(credential.credentialDefinitionId);
    if (definition == null) return null;
    final fields = SkillCredentialAttributeDefinition.parseMap(
      definition.attributesJson,
    );

    return _credentialForEdit(credential, fields);
  }

  Future<SkillCredentialEntity> _apiUpdateCredential(
    String id,
    SkillCredentialToUpdate value,
  ) async {
    final resource = await _required(.serviceConnection, id);
    final current = _credential(resource);
    final updated = _updatedCredential(current, value);

    return await _persistCredentialUpdate((
      id: id,
      resource: resource,
      value: value,
      updated: updated,
    ));
  }

  Future<void> _apiDeleteCredential(String id) async {
    final resource = await _required(.serviceConnection, id);
    final secretRevision = _data(resource)['secretRevision'] as int?;
    if (secretRevision == null) {
      await _deleteCredentialResource(id, resource.revision);

      return;
    }
    await _deleteCredentialSecret(id, resource.revision, secretRevision);
  }
}

extension CloudSkillStoreRuntimeOperations on CloudSkillStore {
  _SetAppSkillEnabled get setAppSkillEnabled => _appSkillEnabledHandler(this);

  Future<void> _setAppSkillEnabled(_AppSkillEnabledRequest request) =>
      _setAppSkillEnabledForRequest(this, request);

  Future<void> Function(
    String conversationId,
    String skillId, {
    required bool selected,
    required bool isAppSkill,
  })
  get setConversationSkill => _setConversationSkillHandler(this);

  Future<bool> credentialReady(SkillEntity skill) async {
    final credentialDefinitionId = skill.credentialDefinitionId;
    if (skill.isCredentialOptional || credentialDefinitionId == null) {
      return true;
    }

    return (await credentials(credentialDefinitionId)).isNotEmpty;
  }

  /// Matches the server's cloud template-tool materialization policy.
  Future<bool> userSkillReady(SkillEntity skill) async {
    if (!skill.isEnabled) return false;
    final hasCredential = await _hasSkillCredential(skill);

    return (await tools(skill.id)).any(
      (tool) => tool.isEnabled && (!tool.requiresCredential || hasCredential),
    );
  }

  Future<List<({String skillId})>> selectionResources(
    String conversationId,
  ) async =>
      (await _active(.conversationSkillSelection))
          .map(_data)
          .where((data) => data['conversationId'] == conversationId)
          .map((data) => (skillId: data['skillId'] as String))
          .toList();

  Future<bool> isAppSkillEnabled(String id) async {
    final setting = (await _active(.skillSetting))
        .where((item) => item.resourceId == id)
        .firstOrNull;

    return setting == null
        ? id == 'skills_manager' || id == agentsSkillSlug
        : _data(setting)['isEnabled'] as bool;
  }
}

extension _CloudSkillStoreCredentialCreation on CloudSkillStore {
  Future<String> _skillSlug(String skillId) async {
    final skill = await _required(.skill, skillId);

    return _data(skill)['slug'] as String;
  }

  Future<void> _createToolResource(
    SkillTemplateToolEntity entity,
    String skillSlug,
  ) => _store.create(
    kind: .skillTemplateTool,
    id: entity.id,
    data: _toolData(entity, skillSlug: skillSlug),
  );

  Future<void> _updateToolResource(_ToolResourceUpdateRequest request) =>
      _store.update(
        kind: .skillTemplateTool,
        id: request.id,
        revision: request.resource.revision,
        data: _toolData(request.updated, skillSlug: request.skillSlug),
      );

  Future<_CredentialCreateData> _credentialCreateData(
    SkillCredentialToCreate value,
  ) async {
    final now = DateTime.now().toUtc();
    final id = const UuidV7().generate();
    final attributes = await _credentialAttributes(value);

    return (
      entity: _credentialFromCreate((
        id: id,
        value: value,
        attributes: attributes,
        now: now,
      )),
      secret: attributes.secret,
    );
  }

  Future<({Map<String, String> secret, Map<String, String> metadata})>
  _credentialAttributes(SkillCredentialToCreate value) async {
    final definition = await this.definition(value.credentialDefinitionId);
    if (definition == null) {
      throw StateError('Credential definition not found');
    }
    final fields = SkillCredentialAttributeDefinition.parseMap(
      definition.attributesJson,
    );

    return _partitionCredentialAttributes(fields, value.attributes);
  }

  SkillCredentialEntity _credentialWithResponse(
    SkillCredentialEntity entity,
    MutateWorkspaceCredentialResponse response,
  ) => entity.copyWith(
    keySuffix: response.displaySuffix,
    updatedAt: response.resource.updatedAt,
  );
}

extension _CloudSkillStoreSkillMapping on CloudSkillStore {
  /// Builds a user skill from create input in identity, text, and state steps.
  SkillEntity _skillFromCreate(String id, SkillToCreate value, DateTime now) {
    final base = _blankSkill.copyWith(
      source: SkillSource.user,
      id: id,
      workspaceId: workspaceId,
    );
    final identity = _skillCreateIdentity(base, value);
    final text = _skillCreateText(identity, value);

    return _skillCreateState(text, value, now);
  }

  SkillEntity _skillCreateIdentity(SkillEntity skill, SkillToCreate value) =>
      skill.copyWith(
        kind: value.kind,
        title: value.title.trim(),
        slug: generateSkillSlug(value.title),
      );

  SkillEntity _skillCreateText(SkillEntity skill, SkillToCreate value) =>
      skill.copyWith(
        description: value.description,
        content: value.content,
        isEnabled: value.isEnabled,
      );

  SkillEntity _skillCreateState(
    SkillEntity skill,
    SkillToCreate value,
    DateTime now,
  ) => skill.copyWith(
    isCredentialOptional: value.isCredentialOptional,
    createdAt: now,
    updatedAt: now,
    credentialDefinitionId: value.credentialDefinitionId,
  );
}

extension _CloudSkillStoreSkillUpdateMapping on CloudSkillStore {
  SkillEntity _updatedSkill(SkillEntity current, SkillToUpdate value) =>
      _skillUpdateState(
        _skillUpdateText(_skillUpdateIdentity(current, value), value),
        value,
      );

  SkillEntity _skillUpdateIdentity(SkillEntity current, SkillToUpdate value) {
    final title = value.title;

    return current.copyWith(
      title: title?.trim() ?? current.title,
      slug: title == null ? current.slug : generateSkillSlug(title),
    );
  }

  SkillEntity _skillUpdateText(SkillEntity skill, SkillToUpdate value) =>
      skill.copyWith(
        description: value.description ?? skill.description,
        content: value.content ?? skill.content,
        credentialDefinitionId: _skillCredentialDefinitionId(skill, value),
      );

  SkillEntity _skillUpdateState(SkillEntity skill, SkillToUpdate value) =>
      skill.copyWith(
        isCredentialOptional:
            value.isCredentialOptional ?? skill.isCredentialOptional,
        isEnabled: value.isEnabled ?? skill.isEnabled,
        updatedAt: DateTime.now().toUtc(),
      );

  String? _skillCredentialDefinitionId(
    SkillEntity current,
    SkillToUpdate value,
  ) => value.clearCredentialDefinition
      ? null
      : value.credentialDefinitionId ?? current.credentialDefinitionId;
}

extension _CloudSkillStoreToolMapping on CloudSkillStore {
  SkillTemplateToolEntity _toolFromCreate(
    ({String id, String skillId, SkillTemplateToolToCreate value, DateTime now})
    request,
  ) {
    final value = request.value;
    return _toolCreateState(
      _toolCreateText(
        _toolCreateIdentity(
          _blankTool.copyWith(id: request.id, skillId: request.skillId),
          value,
        ),
        value,
      ),
      value,
      request.now,
    );
  }

  SkillTemplateToolEntity _toolCreateIdentity(
    SkillTemplateToolEntity tool,
    SkillTemplateToolToCreate value,
  ) => tool.copyWith(
    templateType: value.templateType,
    title: value.title,
    slug: generateSkillSlug(value.title),
  );

  SkillTemplateToolEntity _toolCreateText(
    SkillTemplateToolEntity tool,
    SkillTemplateToolToCreate value,
  ) => tool.copyWith(
    description: value.description,
    templateJson: canonicalSkillUrlTemplateJson(value.templateJson),
    inputsJson: value.inputsJson,
  );

  SkillTemplateToolEntity _toolCreateState(
    SkillTemplateToolEntity tool,
    SkillTemplateToolToCreate value,
    DateTime now,
  ) => tool.copyWith(
    isEnabled: value.isEnabled,
    requiresCredential: value.requiresCredential,
    createdAt: now,
    updatedAt: now,
  );

  SkillTemplateToolEntity _updatedTool(
    SkillTemplateToolEntity current,
    SkillTemplateToolToUpdate value,
  ) => _toolUpdateState(
    _toolUpdateText(_toolUpdateIdentity(current, value), value),
    value,
  );

  SkillTemplateToolEntity _toolUpdateIdentity(
    SkillTemplateToolEntity current,
    SkillTemplateToolToUpdate value,
  ) {
    final title = value.title;

    return current.copyWith(
      title: title ?? current.title,
      slug: title == null ? current.slug : generateSkillSlug(title),
    );
  }

  SkillTemplateToolEntity _toolUpdateText(
    SkillTemplateToolEntity tool,
    SkillTemplateToolToUpdate value,
  ) {
    final templateJson = value.templateJson;

    return tool.copyWith(
      description: value.description ?? tool.description,
      templateJson: templateJson == null
          ? tool.templateJson
          : canonicalSkillUrlTemplateJson(templateJson),
      inputsJson: value.inputsJson ?? tool.inputsJson,
    );
  }

  SkillTemplateToolEntity _toolUpdateState(
    SkillTemplateToolEntity tool,
    SkillTemplateToolToUpdate value,
  ) => tool.copyWith(
    isEnabled: value.isEnabled ?? tool.isEnabled,
    requiresCredential: value.requiresCredential ?? tool.requiresCredential,
    updatedAt: DateTime.now().toUtc(),
  );
}

extension _CloudSkillStoreDefinitionMapping on CloudSkillStore {
  SkillCredentialDefinitionEntity _definitionFromCreate(
    String id,
    SkillCredentialDefinitionToCreate value,
    DateTime now,
  ) {
    final definition = _blankDefinition.copyWith(
      id: id,
      workspaceId: workspaceId,
      title: value.title.trim(),
      slug: generateSkillSlug(value.title),
    );

    return definition.copyWith(
      attributesJson: value.attributesJson,
      createdAt: now,
      updatedAt: now,
    );
  }

  SkillCredentialDefinitionEntity _updatedDefinition(
    SkillCredentialDefinitionEntity current,
    SkillCredentialDefinitionToUpdate value,
  ) {
    return _updatedDefinitionState(
      _updatedDefinitionIdentity(current, value),
      value,
    );
  }

  SkillCredentialDefinitionEntity _updatedDefinitionIdentity(
    SkillCredentialDefinitionEntity current,
    SkillCredentialDefinitionToUpdate value,
  ) {
    final title = value.title;

    return current.copyWith(
      title: title?.trim() ?? current.title,
      slug: title == null ? current.slug : generateSkillSlug(title),
    );
  }

  SkillCredentialDefinitionEntity _updatedDefinitionState(
    SkillCredentialDefinitionEntity definition,
    SkillCredentialDefinitionToUpdate value,
  ) => definition.copyWith(
    attributesJson: value.attributesJson ?? definition.attributesJson,
    updatedAt: DateTime.now().toUtc(),
  );
}

extension _CloudSkillStoreCredentialMapping on CloudSkillStore {
  bool _isCredentialForDefinition(WorkspaceResource item, String definitionId) {
    final data = _data(item);

    return data['kind'] == 'skillCredential' &&
        data['credentialDefinitionId'] == definitionId &&
        data['isEnabled'] == true &&
        data['hasSecret'] == true;
  }

  ({Map<String, String> secret, Map<String, String> metadata})
  _partitionCredentialAttributes(
    Map<String, SkillCredentialAttributeDefinition> fields,
    Map<String, String> attributes,
  ) {
    final secret = <String, String>{};
    final metadata = <String, String>{};
    for (final entry in attributes.entries) {
      _addCredentialAttribute((
        entry: entry,
        fields: fields,
        secret: secret,
        metadata: metadata,
      ));
    }

    return (secret: secret, metadata: metadata);
  }

  void _addCredentialAttribute(_CredentialAttributeRequest request) {
    final entry = request.entry;
    (request.fields[entry.key]?.secret == false
            ? request.metadata
            : request.secret)[entry.key] =
        entry.value;
  }
}

extension _CloudSkillStoreCredentialEntityMapping on CloudSkillStore {
  SkillCredentialEntity _credentialFromCreate(
    _CredentialCreateRequest request,
  ) {
    return _credentialCreateState(
      _credentialCreateIdentity(
        request.id,
        request.value,
        request.attributes.metadata,
      ),
      request.attributes.secret,
      request.now,
    );
  }

  SkillCredentialEntity _credentialCreateIdentity(
    String id,
    SkillCredentialToCreate value,
    Map<String, String> metadata,
  ) => _blankCredential.copyWith(
    id: id,
    workspaceId: workspaceId,
    credentialDefinitionId: value.credentialDefinitionId,
    name: value.name,
    attributes: metadata,
  );

  SkillCredentialEntity _credentialCreateState(
    SkillCredentialEntity credential,
    Map<String, String> secret,
    DateTime now,
  ) => credential.copyWith(
    isEnabled: true,
    createdAt: now,
    updatedAt: now,
    keySuffix: _suffix(secret.values),
  );

  Future<MutateWorkspaceCredentialResponse> _createCredentialResource(
    SkillCredentialEntity entity,
    Map<String, String> secret,
  ) => _store.mutateCredential(
    operation: .create,
    kind: .serviceConnection,
    id: entity.id,
    data: _credentialData(entity, secretRevision: null),
    secretKind: .skillCredential,
    scope: .workspace,
    secret: _encodedSecret(secret),
  );

  String? _encodedSecret(Map<String, String> secret) =>
      secret.isEmpty ? null : jsonEncode(secret);

  Future<WorkspaceResource?> _credentialResource(String id) async =>
      (await _active(.serviceConnection))
          .where((item) => item.resourceId == id && _isSkillCredential(item))
          .firstOrNull;
}

extension _CloudSkillStoreCredentialState on CloudSkillStore {
  bool _isSkillCredential(WorkspaceResource item) =>
      _data(item)['kind'] == 'skillCredential';

  SkillCredentialForEdit _credentialForEdit(
    SkillCredentialEntity credential,
    Map<String, SkillCredentialAttributeDefinition> fields,
  ) => _credentialForEditValue(workspaceId, credential, fields);

  SkillCredentialEntity _updatedCredential(
    SkillCredentialEntity current,
    SkillCredentialToUpdate value,
  ) => current.copyWith(
    name: value.name ?? current.name,
    attributes: {...current.attributes, ...value.nonSecretAttributes},
    keySuffix: value.secretAttributes.isEmpty
        ? current.keySuffix
        : _suffix(value.secretAttributes.values),
    updatedAt: DateTime.now().toUtc(),
  );

  Future<SkillCredentialEntity> _persistCredentialUpdate(
    ({
      String id,
      WorkspaceResource resource,
      SkillCredentialToUpdate value,
      SkillCredentialEntity updated,
    })
    request,
  ) async {
    final secretRevision = _credentialSecretRevision(request.resource);
    if (_writesCredentialSecret(request.value)) {
      return _updateCredentialSecret(
        _credentialSecretUpdateRequest(request, secretRevision),
      );
    }

    await _updateCredentialMetadata(
      request.resource,
      request.updated,
      secretRevision,
    );

    return request.updated;
  }

  _CredentialSecretUpdateRequest _credentialSecretUpdateRequest(
    ({
      String id,
      WorkspaceResource resource,
      SkillCredentialToUpdate value,
      SkillCredentialEntity updated,
    })
    request,
    int? secretRevision,
  ) => (
    id: request.id,
    resource: request.resource,
    value: request.value,
    updated: request.updated,
    secretRevision: secretRevision,
  );

  int? _credentialSecretRevision(WorkspaceResource resource) =>
      _data(resource)['secretRevision'] as int?;

  Future<SkillCredentialEntity> _updateCredentialSecret(
    _CredentialSecretUpdateRequest request,
  ) async {
    final response = await _updateCredentialResource(request);

    return _credentialWithResponse(request.updated, response);
  }

  bool _writesCredentialSecret(SkillCredentialToUpdate value) =>
      value.secretAttributes.isNotEmpty ||
      value.clearSecretAttributeNames.isNotEmpty;
}

extension _CloudSkillStoreCredentialPersistence on CloudSkillStore {
  Future<MutateWorkspaceCredentialResponse> _updateCredentialResource(
    _CredentialSecretUpdateRequest request,
  ) => _mutateCredentialUpdate((
    id: request.id,
    resourceRevision: request.resource.revision,
    data: _credentialData(request.updated, secretRevision: null),
    secret: _updatedSecret(request.value),
    secretRevision: request.secretRevision,
  ));

  Future<MutateWorkspaceCredentialResponse> _mutateCredentialUpdate(
    _CredentialMutationRequest request,
  ) => _store.mutateCredential(
    operation: .update,
    kind: .serviceConnection,
    id: request.id,
    data: request.data,
    resourceRevision: request.resourceRevision,
    secretKind: .skillCredential,
    scope: .workspace,
    secret: request.secret,
    secretRevision: request.secretRevision,
  );

  String _updatedSecret(SkillCredentialToUpdate value) => jsonEncode({
    'set': value.secretAttributes,
    'clear': value.clearSecretAttributeNames.toList(),
  });

  Future<void> _updateCredentialMetadata(
    WorkspaceResource resource,
    SkillCredentialEntity updated,
    int? secretRevision,
  ) => _store.update(
    kind: .serviceConnection,
    id: resource.resourceId,
    revision: resource.revision,
    data: _credentialData(updated, secretRevision: secretRevision),
  );

  Future<void> _deleteCredentialResource(String id, int revision) =>
      _store.delete(kind: .serviceConnection, id: id, revision: revision);

  Future<void> _deleteCredentialSecret(
    String id,
    int revision,
    int secretRevision,
  ) async {
    final _ = await _store.mutateCredential(
      operation: .delete,
      kind: .serviceConnection,
      id: id,
      resourceRevision: revision,
      secretKind: .skillCredential,
      scope: .workspace,
      secret: null,
      clearSecret: true,
      secretRevision: secretRevision,
    );
  }
}

extension _CloudSkillStoreAppSkillMapping on CloudSkillStore {
  SkillEntity _appSkillFromValues(
    ({
      String id,
      bool enabled,
      String? slug,
      String? title,
      String? description,
      String? content,
      DateTime now,
    })
    request,
  ) {
    return _appSkillState((
      skill: _appSkillIdentity(
        id: request.id,
        slug: request.slug,
        title: request.title,
      ),
      enabled: request.enabled,
      description: request.description,
      content: request.content,
      now: request.now,
    ));
  }

  SkillEntity _appSkillIdentity({
    required String id,
    required String? slug,
    required String? title,
  }) => _blankSkill.copyWith(
    source: SkillSource.app,
    id: id,
    workspaceId: workspaceId,
    kind: SkillKind.native,
    title: title ?? id,
    slug: slug ?? id,
  );

  SkillEntity _appSkillState(
    ({
      SkillEntity skill,
      bool enabled,
      String? description,
      String? content,
      DateTime now,
    })
    request,
  ) => request.skill.copyWith(
    description: request.description ?? '',
    content: request.content ?? '',
    isEnabled: request.enabled,
    isCredentialOptional: true,
    createdAt: request.now,
    updatedAt: request.now,
  );
}

extension _CloudSkillStoreAppSkillOperations on CloudSkillStore {
  Future<void> _createAppSkill(
    ({
      String id,
      bool enabled,
      String? slug,
      String? title,
      String? description,
      String? content,
    })
    request,
  ) async {
    final appSkill = _appSkillFromValues((
      id: request.id,
      enabled: request.enabled,
      slug: request.slug,
      title: request.title,
      description: request.description,
      content: request.content,
      now: DateTime.now().toUtc(),
    ));
    await _storeAppSkill(request.id, appSkill);
  }

  Future<void> _storeAppSkill(String id, SkillEntity appSkill) => _store.create(
    kind: .skill,
    id: id,
    data: {..._skillData(appSkill), 'source': SkillSource.app.name},
  );

  Future<void> _setAppSkillSetting(String id, bool enabled) async {
    final existing = await _appSkillSetting(id);
    final data = {'id': id, 'skillId': id, 'isEnabled': enabled};
    if (existing == null) {
      await _createAppSkillSetting(id, data);

      return;
    }
    await _updateAppSkillSetting(existing, data);
  }

  Future<WorkspaceResource?> _appSkillSetting(String id) async =>
      (await _active(.skillSetting))
          .where((item) => item.resourceId == id)
          .firstOrNull;

  Future<void> _createAppSkillSetting(String id, Map<String, Object?> data) =>
      _store.create(kind: .skillSetting, id: id, data: data);

  Future<void> _updateAppSkillSetting(
    WorkspaceResource existing,
    Map<String, Object?> data,
  ) => _store.update(
    kind: .skillSetting,
    id: existing.resourceId,
    revision: existing.revision,
    data: data,
  );
}

extension _CloudSkillStoreConversationMapping on CloudSkillStore {
  Future<WorkspaceResource?> _conversationSkill(String id) async =>
      (await _active(.conversationSkillSelection))
          .where((item) => item.resourceId == id)
          .firstOrNull;

  Future<void> _deleteConversationSkill(
    String id,
    WorkspaceResource? existing,
  ) async {
    if (existing == null) return;
    await _store.delete(
      kind: .conversationSkillSelection,
      id: id,
      revision: existing.revision,
    );
  }

  Future<void> _createConversationSkill(_ConversationSkillRequest request) =>
      _store.create(
        kind: .conversationSkillSelection,
        id: request.id,
        data: {
          'id': request.id,
          'conversationId': request.conversationId,
          'skillId': request.skillId,
          if (request.isAppSkill) 'source': 'app',
        },
      );

  Future<bool> _hasSkillCredential(SkillEntity skill) async {
    final credentialDefinitionId = skill.credentialDefinitionId;
    if (credentialDefinitionId == null) return false;

    return (await credentials(credentialDefinitionId)).isNotEmpty;
  }

  Future<List<WorkspaceResource>> _active(WorkspaceResourceKind kind) async =>
      (await _store.watch(kind).first)
          .where((item) => item.deletedAt == null)
          .toList();

  Future<WorkspaceResource> _required(
    WorkspaceResourceKind kind,
    String id,
  ) async => (await _active(kind)).firstWhere((item) => item.resourceId == id);

  Future<void> _delete(WorkspaceResourceKind kind, String id) async {
    final resource = await _required(kind, id);
    await _store.delete(kind: kind, id: id, revision: resource.revision);
  }

  Map<String, dynamic> _data(WorkspaceResource value) =>
      jsonDecode(value.data) as Map<String, dynamic>;
}

extension _CloudSkillStoreSkillParsing on CloudSkillStore {
  SkillEntity _skill(WorkspaceResource value) {
    final data = _data(value);
    final identity = _skillIdentity(value, data);
    final text = _skillText(identity, data);

    return _skillState(text, value, data);
  }

  SkillEntity _skillIdentity(
    WorkspaceResource value,
    Map<String, dynamic> data,
  ) {
    final skill = _skillSource(value, data);

    return skill.copyWith(
      kind: SkillKind.values.byName(data['kind'] as String),
      title: data['title'] as String,
      slug: data['slug'] as String,
    );
  }

  SkillEntity _skillSource(
    WorkspaceResource value,
    Map<String, dynamic> data,
  ) => _blankSkill.copyWith(
    source: SkillSource.values.byName(
      data['source'] as String? ?? SkillSource.user.name,
    ),
    id: value.resourceId,
    workspaceId: workspaceId,
  );

  SkillEntity _skillText(SkillEntity skill, Map<String, dynamic> data) =>
      skill.copyWith(
        description: data['description'] as String,
        content: data['content'] as String,
        isEnabled: data['isEnabled'] as bool,
      );

  SkillEntity _skillState(
    SkillEntity skill,
    WorkspaceResource value,
    Map<String, dynamic> data,
  ) => skill.copyWith(
    isCredentialOptional: data['isCredentialOptional'] as bool? ?? false,
    createdAt: value.createdAt,
    updatedAt: value.updatedAt,
    credentialDefinitionId: data['credentialDefinitionId'] as String?,
  );

  Map<String, Object?> _skillData(SkillEntity value) => {
    'id': value.id,
    'kind': value.kind.name,
    'title': value.title,
    'slug': value.slug,
    'description': value.description,
    'content': value.content,
    'isEnabled': value.isEnabled,
    'isCredentialOptional': value.isCredentialOptional,
    'skillDefinitionId': ?value.credentialDefinitionId,
    'credentialDefinitionId': ?value.credentialDefinitionId,
  };
}

extension _CloudSkillStoreToolParsing on CloudSkillStore {
  SkillTemplateToolEntity _tool(WorkspaceResource value) {
    final data = _data(value);
    final identity = _toolIdentity(value, data);
    final text = _toolText(identity, data);

    return _toolState(text, value, data);
  }

  SkillTemplateToolEntity _toolIdentity(
    WorkspaceResource value,
    Map<String, dynamic> data,
  ) {
    final tool = _toolSource(value, data);

    return tool.copyWith(
      title: data['title'] as String,
      description: data['description'] as String,
      slug: data['slug'] as String,
    );
  }

  SkillTemplateToolEntity _toolSource(
    WorkspaceResource value,
    Map<String, dynamic> data,
  ) => _blankTool.copyWith(
    id: value.resourceId,
    skillId: data['skillId'] as String,
    templateType: SkillTemplateToolType.values.byName(
      data['templateType'] as String,
    ),
  );

  SkillTemplateToolEntity _toolText(
    SkillTemplateToolEntity tool,
    Map<String, dynamic> data,
  ) => tool.copyWith(
    templateJson: data['templateJson'] as String,
    inputsJson: data['inputsJson'] as String,
    isEnabled: data['isEnabled'] as bool,
  );

  SkillTemplateToolEntity _toolState(
    SkillTemplateToolEntity tool,
    WorkspaceResource value,
    Map<String, dynamic> data,
  ) => tool.copyWith(
    requiresCredential: data['requiresCredential'] as bool,
    createdAt: value.createdAt,
    updatedAt: value.updatedAt,
  );

  Map<String, Object?> _toolData(
    SkillTemplateToolEntity value, {
    required String skillSlug,
  }) => {..._toolIdentityData(value, skillSlug), ..._toolContentData(value)};
}

extension _CloudSkillStoreDefinitionCredential on CloudSkillStore {
  SkillCredentialDefinitionEntity _definition(WorkspaceResource value) {
    final data = _data(value);

    return _definitionState(_definitionIdentity(value, data), value, data);
  }

  SkillCredentialDefinitionEntity _definitionIdentity(
    WorkspaceResource value,
    Map<String, dynamic> data,
  ) => _blankDefinition.copyWith(
    id: value.resourceId,
    workspaceId: workspaceId,
    title: data['title'] as String,
    slug: data['slug'] as String,
  );

  SkillCredentialDefinitionEntity _definitionState(
    SkillCredentialDefinitionEntity definition,
    WorkspaceResource value,
    Map<String, dynamic> data,
  ) => definition.copyWith(
    attributesJson: data['attributesJson'] as String,
    createdAt: value.createdAt,
    updatedAt: value.updatedAt,
  );

  Map<String, Object?> _definitionData(SkillCredentialDefinitionEntity value) =>
      {
        'id': value.id,
        'title': value.title,
        'slug': value.slug,
        'attributesJson': value.attributesJson,
      };
}

extension _CloudSkillStoreCredentialEntityParsing on CloudSkillStore {
  SkillCredentialEntity _credential(WorkspaceResource value) {
    final data = _data(value);

    return _credentialState(_credentialIdentity(value, data), value, data);
  }

  SkillCredentialEntity _credentialIdentity(
    WorkspaceResource value,
    Map<String, dynamic> data,
  ) => _blankCredential.copyWith(
    id: value.resourceId,
    workspaceId: workspaceId,
    credentialDefinitionId: data['credentialDefinitionId'] as String,
    name: data['name'] as String,
  );

  SkillCredentialEntity _credentialState(
    SkillCredentialEntity credential,
    WorkspaceResource value,
    Map<String, dynamic> data,
  ) => credential.copyWith(
    attributes: Map<String, String>.from(data['attributes'] as Map),
    isEnabled: data['isEnabled'] as bool,
    createdAt: value.createdAt,
    updatedAt: value.updatedAt,
    keySuffix: data['keySuffix'] as String?,
  );

  Map<String, Object?> _credentialData(
    SkillCredentialEntity value, {
    required int? secretRevision,
  }) => {
    'id': value.id,
    'kind': 'skillCredential',
    'credentialDefinitionId': value.credentialDefinitionId,
    'name': value.name,
    'attributes': value.attributes,
    'isEnabled': value.isEnabled,
    'keySuffix': ?value.keySuffix,
    'secretRevision': ?secretRevision,
  };

  String? _suffix(Iterable<String> values) {
    final value = values.where((item) => item.isNotEmpty).firstOrNull;
    if (value == null) return null;

    const suffixLength = 6;

    return value.characters.length <= suffixLength
        ? value
        : value.characters
              .getRange(value.characters.length - suffixLength)
              .toString();
  }
}

Map<String, Object?> _toolIdentityData(
  SkillTemplateToolEntity value,
  String skillSlug,
) => {
  'id': value.id,
  'skillId': value.skillId,
  'skillSlug': skillSlug,
  'toolSlug': value.slug,
  'templateType': value.templateType.name,
  'title': value.title,
  'description': value.description,
  'slug': value.slug,
};

Map<String, Object?> _toolContentData(SkillTemplateToolEntity value) => {
  'templateJson': value.templateJson,
  'inputsJson': value.inputsJson,
  'isEnabled': value.isEnabled,
  'requiresCredential': value.requiresCredential,
};

SkillCredentialForEdit _credentialForEditValue(
  String workspaceId,
  SkillCredentialEntity credential,
  Map<String, SkillCredentialAttributeDefinition> fields,
) => _credentialForEditState(
  _credentialForEditIdentity(workspaceId, credential),
  fields,
  credential,
);

SkillCredentialForEdit _credentialForEditIdentity(
  String workspaceId,
  SkillCredentialEntity credential,
) => _blankCredentialForEdit.copyWith(
  id: credential.id,
  workspaceId: workspaceId,
  credentialDefinitionId: credential.credentialDefinitionId,
  name: credential.name,
  nonSecretAttributes: credential.attributes,
);

SkillCredentialForEdit _credentialForEditState(
  SkillCredentialForEdit edit,
  Map<String, SkillCredentialAttributeDefinition> fields,
  SkillCredentialEntity credential,
) => edit.copyWith(
  secretAttributes: _secretStatesValue(fields, credential),
  isEnabled: credential.isEnabled,
  keySuffix: credential.keySuffix,
);

Map<String, SkillCredentialSecretState> _secretStatesValue(
  Map<String, SkillCredentialAttributeDefinition> fields,
  SkillCredentialEntity credential,
) => {
  for (final entry in fields.entries.where((item) => item.value.secret))
    entry.key: SkillCredentialSecretState(
      hasValue: credential.keySuffix != null,
      keySuffix: credential.keySuffix,
    ),
};

_SetAppSkillEnabled _appSkillEnabledHandler(CloudSkillStore store) =>
    store._setAppSkillEnabled;

Future<void> _setAppSkillEnabledForRequest(
  CloudSkillStore store,
  _AppSkillEnabledRequest request,
) async {
  if (await store.skill(request.id) == null) {
    await store._createAppSkill(request);
  }
  await store._setAppSkillSetting(request.id, request.enabled);
}

typedef _SetConversationSkill = Future<void> Function(
  String conversationId,
  String skillId, {
  required bool selected,
  required bool isAppSkill,
});

_SetConversationSkill _setConversationSkillHandler(CloudSkillStore store) =>
    (conversationId, skillId, {required selected, required isAppSkill}) =>
        _setConversationSkillForRequest(store, (
          id: '$conversationId:$skillId',
          conversationId: conversationId,
          skillId: skillId,
          isAppSkill: isAppSkill,
          selected: selected,
        ));

Future<void> _setConversationSkillForRequest(
  CloudSkillStore store,
  ({
    String id,
    String conversationId,
    String skillId,
    bool isAppSkill,
    bool selected,
  })
  request,
) async {
  final existing = await store._conversationSkill(request.id);
  if (!request.selected) {
    await store._deleteConversationSkill(request.id, existing);

    return;
  }
  if (existing != null) return;

  await store._createConversationSkill(_conversationSkillRequest(request));
}

_ConversationSkillRequest _conversationSkillRequest(
  ({
    String id,
    String conversationId,
    String skillId,
    bool isAppSkill,
    bool selected,
  })
  request,
) => (
  id: request.id,
  conversationId: request.conversationId,
  skillId: request.skillId,
  isAppSkill: request.isAppSkill,
);
