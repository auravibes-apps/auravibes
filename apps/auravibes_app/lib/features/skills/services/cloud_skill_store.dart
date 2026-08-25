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

class CloudSkillStore {
  CloudSkillStore(this._store, this.workspaceId);
  final String workspaceId;

  final CloudWorkspaceResourceStore _store;

  Future<List<SkillCredentialDefinitionEntity>> definitions() async =>
      (await _active(
        WorkspaceResourceKind.skillDefinition,
      )).map(_definition).toList();

  Future<SkillEntity?> skill(String id) async => (await _active(
    WorkspaceResourceKind.skill,
  )).where((item) => item.resourceId == id).map(_skill).firstOrNull;

  Future<SkillEntity> createSkill(SkillToCreate value) async {
    final now = DateTime.now().toUtc();
    final id = const UuidV7().generate();
    final entity = SkillEntity(
      source: SkillSource.user,
      id: id,
      workspaceId: workspaceId,
      kind: value.kind,
      title: value.title.trim(),
      slug: generateSkillSlug(value.title),
      description: value.description,
      content: value.content,
      isEnabled: value.isEnabled,
      isCredentialOptional: value.isCredentialOptional,
      createdAt: now,
      updatedAt: now,
      credentialDefinitionId: value.credentialDefinitionId,
    );
    await _store.create(
      kind: WorkspaceResourceKind.skill,
      id: id,
      data: _skillData(entity),
    );

    return entity;
  }

  Future<SkillEntity> updateSkill(String id, SkillToUpdate value) async {
    final resource = await _required(WorkspaceResourceKind.skill, id);
    final current = _skill(resource);
    final title = value.title;
    final updated = current.copyWith(
      title: title?.trim() ?? current.title,
      slug: title == null ? current.slug : generateSkillSlug(title),
      description: value.description ?? current.description,
      content: value.content ?? current.content,
      credentialDefinitionId: value.clearCredentialDefinition
          ? null
          : value.credentialDefinitionId ?? current.credentialDefinitionId,
      isCredentialOptional:
          value.isCredentialOptional ?? current.isCredentialOptional,
      isEnabled: value.isEnabled ?? current.isEnabled,
      updatedAt: DateTime.now().toUtc(),
    );
    await _store.update(
      kind: WorkspaceResourceKind.skill,
      id: id,
      revision: resource.revision,
      data: _skillData(updated),
    );

    return updated;
  }

  Future<void> deleteSkill(String id) =>
      _delete(WorkspaceResourceKind.skill, id);

  Future<List<SkillTemplateToolEntity>> tools(String skillId) async =>
      (await _active(
        WorkspaceResourceKind.skillTemplateTool,
      )).where((item) => _data(item)['skillId'] == skillId).map(_tool).toList();

  Future<SkillTemplateToolEntity?> tool(String id) async => (await _active(
    WorkspaceResourceKind.skillTemplateTool,
  )).where((item) => item.resourceId == id).map(_tool).firstOrNull;

  Future<SkillTemplateToolEntity> createTool(
    String skillId,
    SkillTemplateToolToCreate value,
  ) async {
    final skill = await _required(WorkspaceResourceKind.skill, skillId);
    final skillData = _data(skill);
    final now = DateTime.now().toUtc();
    final id = const UuidV7().generate();
    final entity = SkillTemplateToolEntity(
      id: id,
      skillId: skillId,
      templateType: value.templateType,
      title: value.title,
      description: value.description,
      slug: generateSkillSlug(value.title),
      templateJson: canonicalSkillUrlTemplateJson(value.templateJson),
      inputsJson: value.inputsJson,
      isEnabled: value.isEnabled,
      requiresCredential: value.requiresCredential,
      createdAt: now,
      updatedAt: now,
    );
    await _store.create(
      kind: WorkspaceResourceKind.skillTemplateTool,
      id: id,
      data: _toolData(entity, skillSlug: skillData['slug'] as String),
    );

    return entity;
  }

  Future<SkillTemplateToolEntity> updateTool(
    String id,
    SkillTemplateToolToUpdate value,
  ) async {
    final resource = await _required(
      WorkspaceResourceKind.skillTemplateTool,
      id,
    );
    final current = _tool(resource);
    final skill = await _required(WorkspaceResourceKind.skill, current.skillId);
    final title = value.title;
    final templateJson = value.templateJson;
    final updated = current.copyWith(
      title: title ?? current.title,
      slug: title == null ? current.slug : generateSkillSlug(title),
      description: value.description ?? current.description,
      templateJson: templateJson == null
          ? current.templateJson
          : canonicalSkillUrlTemplateJson(templateJson),
      inputsJson: value.inputsJson ?? current.inputsJson,
      isEnabled: value.isEnabled ?? current.isEnabled,
      requiresCredential:
          value.requiresCredential ?? current.requiresCredential,
      updatedAt: DateTime.now().toUtc(),
    );
    await _store.update(
      kind: WorkspaceResourceKind.skillTemplateTool,
      id: id,
      revision: resource.revision,
      data: _toolData(
        updated,
        skillSlug: _data(skill)['slug'] as String,
      ),
    );

    return updated;
  }

  Future<void> deleteTool(String id) =>
      _delete(WorkspaceResourceKind.skillTemplateTool, id);

  Future<List<SkillEntity>> skills() async =>
      (await _active(WorkspaceResourceKind.skill)).map(_skill).toList();

  Future<SkillCredentialDefinitionEntity?> definition(String id) async =>
      (await _active(
        WorkspaceResourceKind.skillDefinition,
      )).where((item) => item.resourceId == id).map(_definition).firstOrNull;

  Future<SkillCredentialDefinitionEntity> createDefinition(
    SkillCredentialDefinitionToCreate value,
  ) async {
    final now = DateTime.now().toUtc();
    final id = const UuidV7().generate();
    final entity = SkillCredentialDefinitionEntity(
      id: id,
      workspaceId: workspaceId,
      title: value.title.trim(),
      slug: generateSkillSlug(value.title),
      attributesJson: value.attributesJson,
      createdAt: now,
      updatedAt: now,
    );
    await _store.create(
      kind: WorkspaceResourceKind.skillDefinition,
      id: id,
      data: _definitionData(entity),
    );

    return entity;
  }

  Future<SkillCredentialDefinitionEntity> updateDefinition(
    String id,
    SkillCredentialDefinitionToUpdate value,
  ) async {
    final resource = await _required(WorkspaceResourceKind.skillDefinition, id);
    final current = _definition(resource);
    final title = value.title;
    final updated = current.copyWith(
      title: value.title?.trim() ?? current.title,
      slug: title == null ? current.slug : generateSkillSlug(title),
      attributesJson: value.attributesJson ?? current.attributesJson,
      updatedAt: DateTime.now().toUtc(),
    );
    await _store.update(
      kind: WorkspaceResourceKind.skillDefinition,
      id: id,
      revision: resource.revision,
      data: _definitionData(updated),
    );

    return updated;
  }

  Future<void> deleteDefinition(String id) =>
      _delete(WorkspaceResourceKind.skillDefinition, id);

  Future<List<SkillCredentialEntity>> credentials(String definitionId) async =>
      (await _active(WorkspaceResourceKind.serviceConnection))
          .where((item) {
            final data = _data(item);

            return data['kind'] == 'skillCredential' &&
                data['credentialDefinitionId'] == definitionId &&
                data['isEnabled'] == true &&
                data['hasSecret'] == true;
          })
          .map(_credential)
          .toList();

  Future<SkillCredentialEntity> createCredential(
    SkillCredentialToCreate value,
  ) async {
    final now = DateTime.now().toUtc();
    final id = const UuidV7().generate();
    final definition = await this.definition(value.credentialDefinitionId);
    if (definition == null) throw StateError('Credential definition not found');
    final fields = SkillCredentialAttributeDefinition.parseMap(
      definition.attributesJson,
    );
    final secret = <String, String>{};
    final metadata = <String, String>{};
    for (final entry in value.attributes.entries) {
      (fields[entry.key]?.secret == false ? metadata : secret)[entry.key] =
          entry.value;
    }
    final entity = SkillCredentialEntity(
      id: id,
      workspaceId: workspaceId,
      credentialDefinitionId: value.credentialDefinitionId,
      name: value.name,
      attributes: metadata,
      isEnabled: true,
      createdAt: now,
      updatedAt: now,
      keySuffix: _suffix(secret.values),
    );
    final response = await _store.mutateCredential(
      operation: WorkspacePatchOperationKind.create,
      kind: WorkspaceResourceKind.serviceConnection,
      id: id,
      data: _credentialData(entity, secretRevision: null),
      secretKind: WorkspaceSecretKind.skillCredential,
      scope: WorkspaceSecretScope.workspace,
      secret: secret.isEmpty ? null : jsonEncode(secret),
    );

    return entity.copyWith(
      keySuffix: response.displaySuffix,
      updatedAt: response.resource.updatedAt,
    );
  }

  Future<SkillCredentialForEdit?> credentialForEdit(String id) async {
    final resource =
        (await _active(
          WorkspaceResourceKind.serviceConnection,
        )).where((item) {
          if (item.resourceId != id) return false;

          return _data(item)['kind'] == 'skillCredential';
        }).firstOrNull;
    if (resource == null) return null;
    final credential = _credential(resource);
    final definition = await this.definition(credential.credentialDefinitionId);
    if (definition == null) return null;
    final fields = SkillCredentialAttributeDefinition.parseMap(
      definition.attributesJson,
    );

    return SkillCredentialForEdit(
      id: credential.id,
      workspaceId: workspaceId,
      credentialDefinitionId: credential.credentialDefinitionId,
      name: credential.name,
      nonSecretAttributes: credential.attributes,
      secretAttributes: {
        for (final entry in fields.entries.where((item) => item.value.secret))
          entry.key: SkillCredentialSecretState(
            hasValue: credential.keySuffix != null,
            keySuffix: credential.keySuffix,
          ),
      },
      isEnabled: credential.isEnabled,
      keySuffix: credential.keySuffix,
    );
  }

  Future<SkillCredentialEntity> updateCredential(
    String id,
    SkillCredentialToUpdate value,
  ) async {
    final resource = await _required(
      WorkspaceResourceKind.serviceConnection,
      id,
    );
    final current = _credential(resource);
    final updated = current.copyWith(
      name: value.name ?? current.name,
      attributes: {...current.attributes, ...value.nonSecretAttributes},
      keySuffix: value.secretAttributes.isEmpty
          ? current.keySuffix
          : _suffix(value.secretAttributes.values),
      updatedAt: DateTime.now().toUtc(),
    );
    final data = _data(resource);
    final currentSecretRevision = data['secretRevision'] as int?;
    final writesSecret =
        value.secretAttributes.isNotEmpty ||
        value.clearSecretAttributeNames.isNotEmpty;
    if (writesSecret) {
      final response = await _store.mutateCredential(
        operation: WorkspacePatchOperationKind.update,
        kind: WorkspaceResourceKind.serviceConnection,
        id: id,
        data: _credentialData(updated, secretRevision: null),
        resourceRevision: resource.revision,
        secretKind: WorkspaceSecretKind.skillCredential,
        scope: WorkspaceSecretScope.workspace,
        secret: jsonEncode({
          'set': value.secretAttributes,
          'clear': value.clearSecretAttributeNames.toList(),
        }),
        secretRevision: currentSecretRevision,
      );

      return updated.copyWith(
        keySuffix: response.displaySuffix,
        updatedAt: response.resource.updatedAt,
      );
    } else {
      await _store.update(
        kind: WorkspaceResourceKind.serviceConnection,
        id: id,
        revision: resource.revision,
        data: _credentialData(updated, secretRevision: currentSecretRevision),
      );
    }

    return updated;
  }

  Future<void> deleteCredential(String id) async {
    final resource = await _required(
      WorkspaceResourceKind.serviceConnection,
      id,
    );
    final secretRevision = _data(resource)['secretRevision'] as int?;
    if (secretRevision == null) {
      await _store.delete(
        kind: WorkspaceResourceKind.serviceConnection,
        id: id,
        revision: resource.revision,
      );

      return;
    }
    final _ = await _store.mutateCredential(
      operation: WorkspacePatchOperationKind.delete,
      kind: WorkspaceResourceKind.serviceConnection,
      id: id,
      resourceRevision: resource.revision,
      secretKind: WorkspaceSecretKind.skillCredential,
      scope: WorkspaceSecretScope.workspace,
      secret: null,
      clearSecret: true,
      secretRevision: secretRevision,
    );
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
      final now = DateTime.now().toUtc();
      final appSkill = SkillEntity(
        source: SkillSource.app,
        id: id,
        workspaceId: workspaceId,
        kind: SkillKind.native,
        title: title ?? id,
        slug: slug ?? id,
        description: description ?? '',
        content: content ?? '',
        isEnabled: enabled,
        isCredentialOptional: true,
        createdAt: now,
        updatedAt: now,
      );
      await _store.create(
        kind: WorkspaceResourceKind.skill,
        id: id,
        data: {..._skillData(appSkill), 'source': SkillSource.app.name},
      );
    }
    final resources = await _active(WorkspaceResourceKind.skillSetting);
    final existing = resources
        .where((item) => item.resourceId == id)
        .firstOrNull;
    final data = {'id': id, 'skillId': id, 'isEnabled': enabled};
    if (existing == null) {
      await _store.create(
        kind: WorkspaceResourceKind.skillSetting,
        id: id,
        data: data,
      );
    } else {
      await _store.update(
        kind: WorkspaceResourceKind.skillSetting,
        id: id,
        revision: existing.revision,
        data: data,
      );
    }
  }

  Future<void> setConversationSkill(
    String conversationId,
    String skillId, {
    required bool selected,
    required bool isAppSkill,
  }) async {
    final id = '$conversationId:$skillId';
    final existing = (await _active(
      WorkspaceResourceKind.conversationSkillSelection,
    )).where((item) => item.resourceId == id).firstOrNull;
    if (!selected) {
      if (existing != null) {
        await _store.delete(
          kind: WorkspaceResourceKind.conversationSkillSelection,
          id: id,
          revision: existing.revision,
        );
      }

      return;
    }
    if (existing == null) {
      await _store.create(
        kind: WorkspaceResourceKind.conversationSkillSelection,
        id: id,
        data: {
          'id': id,
          'conversationId': conversationId,
          'skillId': skillId,
          if (isAppSkill) 'source': 'app',
        },
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
    final credentialDefinitionId = skill.credentialDefinitionId;
    final hasCredential =
        credentialDefinitionId != null &&
        (await credentials(credentialDefinitionId)).isNotEmpty;

    return (await tools(skill.id)).any(
      (tool) => tool.isEnabled && (!tool.requiresCredential || hasCredential),
    );
  }

  Future<List<({String skillId})>> selectionResources(
    String conversationId,
  ) async => (await _active(WorkspaceResourceKind.conversationSkillSelection))
      .map(_data)
      .where((data) => data['conversationId'] == conversationId)
      .map((data) => (skillId: data['skillId'] as String))
      .toList();

  Future<bool> isAppSkillEnabled(String id) async {
    final setting = (await _active(
      WorkspaceResourceKind.skillSetting,
    )).where((item) => item.resourceId == id).firstOrNull;

    return setting == null
        ? id == 'skills_manager' || id == agentsSkillSlug
        : _data(setting)['isEnabled'] as bool;
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

    return SkillEntity(
      source: SkillSource.values.byName(
        data['source'] as String? ?? SkillSource.user.name,
      ),
      id: value.resourceId,
      workspaceId: workspaceId,
      kind: SkillKind.values.byName(data['kind'] as String),
      title: data['title'] as String,
      slug: data['slug'] as String,
      description: data['description'] as String,
      content: data['content'] as String,
      isEnabled: data['isEnabled'] as bool,
      isCredentialOptional: data['isCredentialOptional'] as bool? ?? false,
      createdAt: value.createdAt,
      updatedAt: value.updatedAt,
      credentialDefinitionId: data['credentialDefinitionId'] as String?,
    );
  }

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

    return SkillTemplateToolEntity(
      id: value.resourceId,
      skillId: data['skillId'] as String,
      templateType: SkillTemplateToolType.values.byName(
        data['templateType'] as String,
      ),
      title: data['title'] as String,
      description: data['description'] as String,
      slug: data['slug'] as String,
      templateJson: data['templateJson'] as String,
      inputsJson: data['inputsJson'] as String,
      isEnabled: data['isEnabled'] as bool,
      requiresCredential: data['requiresCredential'] as bool,
      createdAt: value.createdAt,
      updatedAt: value.updatedAt,
    );
  }

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

    return SkillCredentialDefinitionEntity(
      id: value.resourceId,
      workspaceId: workspaceId,
      title: data['title'] as String,
      slug: data['slug'] as String,
      attributesJson: data['attributesJson'] as String,
      createdAt: value.createdAt,
      updatedAt: value.updatedAt,
    );
  }

  Map<String, Object?> _definitionData(SkillCredentialDefinitionEntity value) =>
      {
        'id': value.id,
        'title': value.title,
        'slug': value.slug,
        'attributesJson': value.attributesJson,
      };

  SkillCredentialEntity _credential(WorkspaceResource value) {
    final data = _data(value);

    return SkillCredentialEntity(
      id: value.resourceId,
      workspaceId: workspaceId,
      credentialDefinitionId: data['credentialDefinitionId'] as String,
      name: data['name'] as String,
      attributes: Map<String, String>.from(data['attributes'] as Map),
      isEnabled: data['isEnabled'] as bool,
      createdAt: value.createdAt,
      updatedAt: value.updatedAt,
      keySuffix: data['keySuffix'] as String?,
    );
  }

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
