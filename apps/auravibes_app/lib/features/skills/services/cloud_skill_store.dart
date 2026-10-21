import 'dart:convert';

import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/entities/skill_resource_entity.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_resource_store.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:uuid/v7.dart';

typedef _ConversationSkillRequest = ({
  String id,
  String conversationId,
  String skillId,
  bool isAppSkill,
});

typedef _AppSkillEnabledRequest = ({
  String id,
  SkillKind kind,
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
  id: '',
  workspaceId: '',
  source: .user,
  kind: .template,
  title: '',
  slug: '',
  description: '',
  content: '',
  isEnabled: false,
  createdAt: .new(1970),
  updatedAt: .new(1970),
);

final _blankResource = SkillResourceEntity(
  id: '',
  skillId: '',
  title: '',
  slug: '',
  description: '',
  content: '',
  createdAt: .new(1970),
  updatedAt: .new(1970),
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

extension CloudSkillStoreResourceApi on CloudSkillStore {
  Future<List<SkillResourceEntity>> resources(String skillId) async {
    final api = await _resourceApi();
    final views = await api.client.skillResource.list(
      .new(workspaceId: api.workspaceId, skillId: skillId),
    );

    return views.map(_resource).toList();
  }

  Future<SkillResourceEntity?> resource(String resourceId) async {
    final api = await _resourceApi();
    final view = await api.client.skillResource.get(
      .new(workspaceId: api.workspaceId, resourceId: resourceId),
    );

    return view == null ? null : _resource(view);
  }

  Future<SkillResourceEntity> createResource(
    String skillId,
    SkillResourceToCreate value,
  ) async {
    final api = await _resourceApi();
    final view = await api.client.skillResource.create(
      .new(
        workspaceId: api.workspaceId,
        requestId: const UuidV7().generate(),
        skillId: skillId,
        resourceId: const UuidV7().generate(),
        title: value.title,
        description: value.description,
        content: value.content,
      ),
    );

    return _resource(view);
  }

  Future<SkillResourceEntity> updateResource(
    String resourceId,
    SkillResourceToUpdate value,
  ) async {
    final current = await resource(resourceId);
    if (current == null) {
      throw StateError('Skill resource not found: $resourceId');
    }
    final api = await _resourceApi();
    final view = await _updateResourceView(api, resourceId, value, current);

    return _resource(view);
  }

  Future<SkillResourceView> _updateResourceView(
    ({Client client, int workspaceId}) api,
    String resourceId,
    SkillResourceToUpdate value,
    SkillResourceEntity current,
  ) => api.client.skillResource.update(
    .new(
      workspaceId: api.workspaceId,
      requestId: const UuidV7().generate(),
      resourceId: resourceId,
      expectedRevision: currentRevision(current),
      title: value.title ?? current.title,
      description: value.description ?? current.description,
      content: value.content ?? current.content,
    ),
  );

  Future<bool> deleteResource(String resourceId) async {
    final current = await resource(resourceId);
    if (current == null) return false;
    final api = await _resourceApi();
    await api.client.skillResource.delete(
      .new(
        workspaceId: api.workspaceId,
        requestId: const UuidV7().generate(),
        resourceId: resourceId,
        expectedRevision: currentRevision(current),
      ),
    );

    return true;
  }
}

extension _CloudSkillStoreResourceOperations on CloudSkillStore {
  Future<({Client client, int workspaceId})> _resourceApi() async {
    final client = await _store.client;
    final id = await _store.cloudWorkspaceId;
    if (client == null) {
      throw StateError('Cloud skill resource store is unavailable');
    }
    if (id == null) throw StateError('Cloud workspace id is unavailable');

    return (client: client, workspaceId: id);
  }

  SkillResourceEntity _resource(SkillResourceView view) =>
      _blankResource.copyWith(
        id: view.id,
        skillId: view.skillId,
        title: view.title,
        slug: view.slug,
        description: view.description,
        content: view.content,
        revision: view.revision,
        createdAt: view.createdAt,
        updatedAt: view.updatedAt,
      );

  int currentRevision(SkillResourceEntity resource) => resource.revision;
}

extension CloudSkillStoreSkillOperations on CloudSkillStore {
  Future<List<SkillEntity>> _apiSkills() async =>
      (await _active(.skill)).map(_skill).toList();

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

extension CloudSkillStoreRuntimeOperations on CloudSkillStore {
  _SetAppSkillEnabled get setAppSkillEnabled => _appSkillEnabledHandler(this);

  Future<void> _setAppSkillEnabled(_AppSkillEnabledRequest request) =>
      _setAppSkillEnabledForRequest(this, request);

  Future<void> Function(
    String conversationId,
    String skillId, {
    required bool isAppSkill,
  })
  get setConversationSkill => _setConversationSkillHandler(this);

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
        connectorToolIds: value.connectorToolIds,
        isEnabled: value.isEnabled,
      );

  SkillEntity _skillCreateState(
    SkillEntity skill,
    SkillToCreate _,
    DateTime now,
  ) => skill.copyWith(createdAt: now, updatedAt: now);
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
        connectorToolIds: value.connectorToolIds ?? skill.connectorToolIds,
      );

  SkillEntity _skillUpdateState(SkillEntity skill, SkillToUpdate value) =>
      skill.copyWith(
        isEnabled: value.isEnabled ?? skill.isEnabled,
        updatedAt: DateTime.now().toUtc(),
      );
}

extension _CloudSkillStoreAppSkillMapping on CloudSkillStore {
  SkillEntity _appSkillFromValues(
    ({
      String id,
      SkillKind kind,
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
        kind: request.kind,
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
    required SkillKind kind,
    required String? slug,
    required String? title,
  }) => _blankSkill.copyWith(
    source: SkillSource.app,
    id: id,
    workspaceId: workspaceId,
    kind: kind,
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
    createdAt: request.now,
    updatedAt: request.now,
  );
}

extension _CloudSkillStoreAppSkillOperations on CloudSkillStore {
  Future<void> _createAppSkill(
    ({
      String id,
      SkillKind kind,
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
      kind: request.kind,
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

    return _skillState(text, value);
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
        connectorToolIds: _connectorToolIdsFromData(data),
        isEnabled: data['isEnabled'] as bool,
      );

  SkillEntity _skillState(SkillEntity skill, WorkspaceResource value) =>
      skill.copyWith(createdAt: value.createdAt, updatedAt: value.updatedAt);

  Map<String, Object?> _skillData(SkillEntity value) => {
    'id': value.id,
    'kind': value.kind.name,
    'title': value.title,
    'slug': value.slug,
    'description': value.description,
    'content': value.content,
    'connectorToolIds': _normalizedConnectorToolIds(value.connectorToolIds),
    'isEnabled': value.isEnabled,
  };
}

List<String> _connectorToolIdsFromData(Map<String, dynamic> data) =>
    _normalizedConnectorToolIds(
      (data['connectorToolIds'] as List? ?? const []).whereType<String>(),
    );

List<String> _normalizedConnectorToolIds(Iterable<String> values) =>
    values.map((id) => id.trim()).where((id) => id.isNotEmpty).toSet().toList()
      ..sort();

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
  required bool isAppSkill,
});

_SetConversationSkill _setConversationSkillHandler(CloudSkillStore store) =>
    (conversationId, skillId, {required isAppSkill}) =>
        _setConversationSkillForRequest(store, (
          id: '$conversationId:$skillId',
          conversationId: conversationId,
          skillId: skillId,
          isAppSkill: isAppSkill,
        ));

Future<void> _setConversationSkillForRequest(
  CloudSkillStore store,
  ({String id, String conversationId, String skillId, bool isAppSkill}) request,
) async {
  final existing = await store._conversationSkill(request.id);
  if (existing != null) return;

  await store._createConversationSkill(_conversationSkillRequest(request));
}

_ConversationSkillRequest _conversationSkillRequest(
  ({String id, String conversationId, String skillId, bool isAppSkill}) request,
) => (
  id: request.id,
  conversationId: request.conversationId,
  skillId: request.skillId,
  isAppSkill: request.isAppSkill,
);
