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
  attributes: {},
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
) {
  Future<List<SkillCredentialDefinitionEntity>> definitions() async =>
      (await _active(.skillDefinition)).map(_definition).toList();

  Future<SkillEntity?> skill(String id) async =>
      (await _active(.skill))
          .where((item) => item.resourceId == id)
          .map(_skill)
          .firstOrNull;

  Future<SkillEntity> createSkill(SkillToCreate value) async {
    final now = DateTime.now().toUtc();
    final id = const UuidV7().generate();
    final entity = _skillFromCreate(id, value, now);
    await _store.create(kind: .skill, id: id, data: _skillData(entity));

    return entity;
  }

  Future<SkillEntity> updateSkill(String id, SkillToUpdate value) async {
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

  Future<void> deleteSkill(String id) => _delete(.skill, id);

  Future<List<SkillTemplateToolEntity>> tools(String skillId) async =>
      (await _active(.skillTemplateTool))
          .where((item) => _data(item)['skillId'] == skillId)
          .map(_tool)
          .toList();

  Future<SkillTemplateToolEntity?> tool(String id) async =>
      (await _active(.skillTemplateTool))
          .where((item) => item.resourceId == id)
          .map(_tool)
          .firstOrNull;

  Future<SkillTemplateToolEntity> createTool(
    String skillId,
    SkillTemplateToolToCreate value,
  ) async {
    final skillSlug = await _skillSlug(skillId);
    final now = DateTime.now().toUtc();
    final id = const UuidV7().generate();
    final entity = _toolFromCreate(id, skillId, value, now);
    await _createToolResource(entity, skillSlug);

    return entity;
  }

  Future<SkillTemplateToolEntity> updateTool(
    String id,
    SkillTemplateToolToUpdate value,
  ) async {
    final resource = await _required(.skillTemplateTool, id);
    final current = _tool(resource);
    final skillSlug = await _skillSlug(current.skillId);
    final updated = _updatedTool(current, value);
    await _updateToolResource(id, resource, updated, skillSlug);

    return updated;
  }

  Future<void> deleteTool(String id) => _delete(.skillTemplateTool, id);

  Future<List<SkillEntity>> skills() async =>
      (await _active(.skill)).map(_skill).toList();

  Future<SkillCredentialDefinitionEntity?> definition(String id) async =>
      (await _active(.skillDefinition))
          .where((item) => item.resourceId == id)
          .map(_definition)
          .firstOrNull;

  Future<SkillCredentialDefinitionEntity> createDefinition(
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

  Future<SkillCredentialDefinitionEntity> updateDefinition(
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

  Future<void> deleteDefinition(String id) => _delete(.skillDefinition, id);

  Future<List<SkillCredentialEntity>> credentials(String definitionId) async =>
      (await _active(.serviceConnection))
          .where((item) => _isCredentialForDefinition(item, definitionId))
          .map(_credential)
          .toList();

  Future<SkillCredentialEntity> createCredential(
    SkillCredentialToCreate value,
  ) async {
    final input = await _credentialCreateData(value);
    final response = await _createCredentialResource(
      input.entity,
      input.secret,
    );

    return _credentialWithResponse(input.entity, response);
  }

  Future<SkillCredentialForEdit?> credentialForEdit(String id) async {
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

  Future<SkillCredentialEntity> updateCredential(
    String id,
    SkillCredentialToUpdate value,
  ) async {
    final resource = await _required(.serviceConnection, id);
    final current = _credential(resource);
    final updated = _updatedCredential(current, value);

    return await _persistCredentialUpdate(id, resource, value, updated);
  }

  Future<void> deleteCredential(String id) async {
    final resource = await _required(.serviceConnection, id);
    final secretRevision = _data(resource)['secretRevision'] as int?;
    if (secretRevision == null) {
      await _deleteCredentialResource(id, resource.revision);

      return;
    }
    await _deleteCredentialSecret(id, resource.revision, secretRevision);
  }

  Future<void> setAppSkillEnabled(
    String id, {
    required bool enabled,
    String? slug,
    String? title,
    String? description,
    String? content,
  }) async {
    if (await skill(id) == null) {
      await _createAppSkill(
        id: id,
        enabled: enabled,
        slug: slug,
        title: title,
        description: description,
        content: content,
      );
    }
    await _setAppSkillSetting(id, enabled);
  }

  Future<void> setConversationSkill(
    String conversationId,
    String skillId, {
    required bool selected,
    required bool isAppSkill,
  }) async {
    final id = '$conversationId:$skillId';
    final existing = await _conversationSkill(id);
    if (!selected) {
      await _deleteConversationSkill(id, existing);

      return;
    }
    if (existing == null) {
      await _createConversationSkill(
        id: id,
        conversationId: conversationId,
        skillId: skillId,
        isAppSkill: isAppSkill,
      );
    }
  }

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

  Future<void> _updateToolResource(
    String id,
    WorkspaceResource resource,
    SkillTemplateToolEntity updated,
    String skillSlug,
  ) => _store.update(
    kind: .skillTemplateTool,
    id: id,
    revision: resource.revision,
    data: _toolData(updated, skillSlug: skillSlug),
  );

  Future<_CredentialCreateData> _credentialCreateData(
    SkillCredentialToCreate value,
  ) async {
    final now = DateTime.now().toUtc();
    final id = const UuidV7().generate();
    final attributes = await _credentialAttributes(value);

    return (
      entity: _credentialFromCreate(id, value, attributes, now),
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

  SkillEntity _skillFromCreate(String id, SkillToCreate value, DateTime now) =>
      _skillCreateState(
        _skillCreateText(
          _skillCreateIdentity(
            _blankSkill.copyWith(
              source: SkillSource.user,
              id: id,
              workspaceId: workspaceId,
            ),
            value,
          ),
          value,
        ),
        value,
        now,
      );

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

  SkillTemplateToolEntity _toolFromCreate(
    String id,
    String skillId,
    SkillTemplateToolToCreate value,
    DateTime now,
  ) => _toolCreateState(
    _toolCreateText(
      _toolCreateIdentity(_blankTool.copyWith(id: id, skillId: skillId), value),
      value,
    ),
    value,
    now,
  );

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
      _addCredentialAttribute(entry, fields, secret, metadata);
    }

    return (secret: secret, metadata: metadata);
  }

  void _addCredentialAttribute(
    MapEntry<String, String> entry,
    Map<String, SkillCredentialAttributeDefinition> fields,
    Map<String, String> secret,
    Map<String, String> metadata,
  ) {
    (fields[entry.key]?.secret == false ? metadata : secret)[entry.key] =
        entry.value;
  }

  SkillCredentialEntity _credentialFromCreate(
    String id,
    SkillCredentialToCreate value,
    ({Map<String, String> secret, Map<String, String> metadata}) attributes,
    DateTime now,
  ) {
    return _credentialCreateState(
      _credentialCreateIdentity(id, value, attributes.metadata),
      attributes.secret,
      now,
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

  bool _isSkillCredential(WorkspaceResource item) =>
      _data(item)['kind'] == 'skillCredential';

  SkillCredentialForEdit _credentialForEdit(
    SkillCredentialEntity credential,
    Map<String, SkillCredentialAttributeDefinition> fields,
  ) {
    final edit = _blankCredentialForEdit.copyWith(
      id: credential.id,
      workspaceId: workspaceId,
      credentialDefinitionId: credential.credentialDefinitionId,
      name: credential.name,
      nonSecretAttributes: credential.attributes,
    );

    return edit.copyWith(
      secretAttributes: _secretStates(fields, credential),
      isEnabled: credential.isEnabled,
      keySuffix: credential.keySuffix,
    );
  }

  Map<String, SkillCredentialSecretState> _secretStates(
    Map<String, SkillCredentialAttributeDefinition> fields,
    SkillCredentialEntity credential,
  ) => {
    for (final entry in fields.entries.where((item) => item.value.secret))
      entry.key: SkillCredentialSecretState(
        hasValue: credential.keySuffix != null,
        keySuffix: credential.keySuffix,
      ),
  };

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
    String id,
    WorkspaceResource resource,
    SkillCredentialToUpdate value,
    SkillCredentialEntity updated,
  ) async {
    final secretRevision = _credentialSecretRevision(resource);
    if (!_writesCredentialSecret(value)) {
      await _updateCredentialMetadata(resource, updated, secretRevision);

      return updated;
    }

    return await _updateCredentialSecret(
      id,
      resource,
      value,
      updated,
      secretRevision,
    );
  }

  int? _credentialSecretRevision(WorkspaceResource resource) =>
      _data(resource)['secretRevision'] as int?;

  Future<SkillCredentialEntity> _updateCredentialSecret(
    String id,
    WorkspaceResource resource,
    SkillCredentialToUpdate value,
    SkillCredentialEntity updated,
    int? secretRevision,
  ) async {
    final response = await _updateCredentialResource(
      id: id,
      resource: resource,
      value: value,
      updated: updated,
      secretRevision: secretRevision,
    );

    return _credentialWithResponse(updated, response);
  }

  bool _writesCredentialSecret(SkillCredentialToUpdate value) =>
      value.secretAttributes.isNotEmpty ||
      value.clearSecretAttributeNames.isNotEmpty;

  Future<MutateWorkspaceCredentialResponse> _updateCredentialResource({
    required String id,
    required WorkspaceResource resource,
    required SkillCredentialToUpdate value,
    required SkillCredentialEntity updated,
    required int? secretRevision,
  }) => _store.mutateCredential(
    operation: .update,
    kind: .serviceConnection,
    id: id,
    data: _credentialData(updated, secretRevision: null),
    resourceRevision: resource.revision,
    secretKind: .skillCredential,
    scope: .workspace,
    secret: _updatedSecret(value),
    secretRevision: secretRevision,
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

  SkillEntity _appSkillFromValues({
    required String id,
    required bool enabled,
    required String? slug,
    required String? title,
    required String? description,
    required String? content,
    required DateTime now,
  }) {
    return _appSkillState(
      _appSkillIdentity(id: id, slug: slug, title: title),
      enabled: enabled,
      description: description,
      content: content,
      now: now,
    );
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
    SkillEntity skill, {
    required bool enabled,
    required String? description,
    required String? content,
    required DateTime now,
  }) => skill.copyWith(
    description: description ?? '',
    content: content ?? '',
    isEnabled: enabled,
    isCredentialOptional: true,
    createdAt: now,
    updatedAt: now,
  );

  Future<void> _createAppSkill({
    required String id,
    required bool enabled,
    required String? slug,
    required String? title,
    required String? description,
    required String? content,
  }) async {
    final appSkill = _appSkillFromValues(
      id: id,
      enabled: enabled,
      slug: slug,
      title: title,
      description: description,
      content: content,
      now: DateTime.now().toUtc(),
    );
    await _storeAppSkill(id, appSkill);
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

  Future<void> _createConversationSkill({
    required String id,
    required String conversationId,
    required String skillId,
    required bool isAppSkill,
  }) => _store.create(
    kind: .conversationSkillSelection,
    id: id,
    data: {
      'id': id,
      'conversationId': conversationId,
      'skillId': skillId,
      if (isAppSkill) 'source': 'app',
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
  }) => {
    'id': value.id,
    'skillId': value.skillId,
    'skillSlug': skillSlug,
    'toolSlug': value.slug,
    'templateType': value.templateType.name,
    'title': value.title,
    'description': value.description,
    'slug': value.slug,
    'templateJson': value.templateJson,
    'inputsJson': value.inputsJson,
    'isEnabled': value.isEnabled,
    'requiresCredential': value.requiresCredential,
  };

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
