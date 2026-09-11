import 'dart:convert';

import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/chats/services/cloud_chat_gateway.dart';
import 'package:auravibes_app/features/skills/models/workspace_skill.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_resource_mapper.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_resource_store.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:uuid/v7.dart';

class const CloudSkillSettingsAdapter(
  final CloudWorkspaceStateGateway _gateway,
) {
  CloudWorkspaceResourceStore get _store =>
      CloudWorkspaceResourceStore(_gateway);

  Stream<List<WorkspaceSkill>> watchSkills() => _store
      .watchResources(const [
        WorkspaceResourceKind.skill,
        WorkspaceResourceKind.skillSetting,
      ])
      .map(_mapSkills);
}

class const CloudConversationSkillSelection({
  required final String conversationId,
  required final String skillId,
  required final bool isAppSkill,
  required final bool selected,
  required final int? expectedRevision,
});

extension CloudSkillSettingsAdapterStreams on CloudSkillSettingsAdapter {
  Stream<({CompactionSettings settings, int? revision})>
  watchCompactionSettingsState() => _store
      .watchResources(const [WorkspaceResourceKind.compactionSetting])
      .map(_compactionSettingsState);

  Stream<CompactionSettings> watchCompactionSettings() =>
      watchCompactionSettingsState().map((state) => state.settings);

  Future<CompactionSettings> saveCompactionSettings(
    CompactionSettings settings, {
    int? expectedRevision,
  }) => _saveCompactionSettings(_store, settings, expectedRevision);

  Future<CompactionSettings> saveCurrentCompactionSettings(
    CompactionSettings settings,
  ) async {
    final state = await watchCompactionSettingsState().first;

    return await saveCompactionSettings(
      settings,
      expectedRevision: state.revision,
    );
  }
}

extension CloudSkillSettingsAdapterMutations on CloudSkillSettingsAdapter {
  Future<void> resetCompactionSettings() async {
    final revision = (await watchCompactionSettingsState().first).revision;
    if (revision == null) return;

    await _deleteCompactionSettings(_store, revision);
  }

  Future<void> setConversationSkill(
    CloudConversationSkillSelection selection,
  ) => _patchConversationSkill(_store, selection);

  Future<void> putCredentialSecret({
    required String credentialId,
    required String? secret,
    int? expectedRevision,
  }) async {
    final _ = await _store.putSecret(
      kind: .skillCredential,
      scope: .workspace,
      resourceId: credentialId,
      secret: secret,
      revision: expectedRevision,
    );
  }

  Future<ConversationMutationResult> compactConversation({
    required String conversationId,
    required int expectedRevision,
  }) => CloudChatGateway(_gateway).compactConversation(
    requestId: const UuidV7().generate(),
    conversationId: conversationId,
    expectedConversationRevision: expectedRevision,
  );
}

Future<CompactionSettings> _saveCompactionSettings(
  CloudWorkspaceResourceStore store,
  CompactionSettings settings,
  int? expectedRevision,
) async {
  final _ = await store.patch(
    requestId: const UuidV7().generate(),
    operations: [_compactionSettingsPatch(settings, expectedRevision)],
  );

  return settings;
}

WorkspacePatchOperation _compactionSettingsPatch(
  CompactionSettings settings,
  int? expectedRevision,
) => WorkspacePatchOperation(
  operation: expectedRevision == null
      ? WorkspacePatchOperationKind.create
      : WorkspacePatchOperationKind.update,
  resourceKind: .compactionSetting,
  resourceId: 'workspace',
  data: jsonEncode(settings.toJson()),
  fieldMask: const [],
  expectedRevision: expectedRevision,
);

Future<void> _deleteCompactionSettings(
  CloudWorkspaceResourceStore store,
  int revision,
) async {
  final _ = await store.patch(
    requestId: const UuidV7().generate(),
    operations: [_compactionSettingsDelete(revision)],
  );
}

WorkspacePatchOperation _compactionSettingsDelete(int revision) =>
    WorkspacePatchOperation(
      operation: .delete,
      resourceKind: .compactionSetting,
      resourceId: 'workspace',
      fieldMask: const [],
      expectedRevision: revision,
    );

Future<void> _patchConversationSkill(
  CloudWorkspaceResourceStore store,
  CloudConversationSkillSelection selection,
) async {
  final _ = await store.patch(
    requestId: const UuidV7().generate(),
    operations: [_conversationSkillPatch(selection)],
  );
}

WorkspacePatchOperation _conversationSkillPatch(
  CloudConversationSkillSelection selection,
) => WorkspacePatchOperation(
  operation: _conversationSkillOperation(selection),
  resourceKind: .conversationSkillSelection,
  resourceId: '${selection.conversationId}:${selection.skillId}',
  data: _conversationSkillData(selection),
  fieldMask: const [],
  expectedRevision: selection.expectedRevision,
);

WorkspacePatchOperationKind _conversationSkillOperation(
  CloudConversationSkillSelection selection,
) {
  if (!selection.selected) return .delete;
  if (selection.expectedRevision == null) return .create;

  return .update;
}

String? _conversationSkillData(CloudConversationSkillSelection selection) =>
    selection.selected
    ? jsonEncode({
        'id': '${selection.conversationId}:${selection.skillId}',
        'conversationId': selection.conversationId,
        'skillId': selection.skillId,
        if (selection.isAppSkill) 'source': 'app',
      })
    : null;

({CompactionSettings settings, int? revision}) _compactionSettingsState(
  List<WorkspaceResource> resources,
) {
  final active = resources.where((item) => item.deletedAt == null);
  if (active.isEmpty) {
    return (settings: CompactionSettings.defaults, revision: null);
  }
  final resource = active.single;

  return (
    settings: CompactionSettings.fromJson(_decode(resource)),
    revision: resource.revision,
  );
}

List<WorkspaceSkill> _mapSkills(List<WorkspaceResource> resources) {
  final settings = _skillSettings(resources);

  return resources
      .where(_isActiveSkill)
      .map((resource) => _workspaceSkill(resource, settings))
      .toList()
    ..sort((a, b) => a.title.compareTo(b.title));
}

Map<String, bool> _skillSettings(List<WorkspaceResource> resources) {
  final settings = <String, bool>{};
  for (final resource in resources.where(_isActiveSkillSetting)) {
    final data = _decode(resource);
    settings[data['skillId'] as String] = data['isEnabled'] as bool;
  }

  return settings;
}

bool _isActiveSkillSetting(WorkspaceResource resource) =>
    resource.deletedAt == null &&
    resource.resourceKind == WorkspaceResourceKind.skillSetting;

bool _isActiveSkill(WorkspaceResource resource) =>
    resource.deletedAt == null &&
    resource.resourceKind == WorkspaceResourceKind.skill;

WorkspaceSkill _workspaceSkill(
  WorkspaceResource resource,
  Map<String, bool> settings,
) => _workspaceSkillFromData(resource, settings, _decode(resource));

WorkspaceSkill _workspaceSkillFromData(
  WorkspaceResource resource,
  Map<String, bool> settings,
  Map<String, dynamic> data,
) => WorkspaceSkill(
  source: _skillSource(data),
  id: resource.resourceId,
  slug: data['slug'] as String,
  title: data['title'] as String,
  description: data['description'] as String,
  kind: _skillKind(data),
  isEnabled: _skillEnabled(resource, settings, data),
);

SkillSource _skillSource(Map<String, dynamic> data) => SkillSource.values
    .byName(data['source'] as String? ?? SkillSource.user.name);

SkillKind _skillKind(Map<String, dynamic> data) =>
    SkillKind.values.byName(data['kind'] as String);

bool _skillEnabled(
  WorkspaceResource resource,
  Map<String, bool> settings,
  Map<String, dynamic> data,
) => settings[resource.resourceId] ?? data['isEnabled'] as bool;

Map<String, dynamic> _decode(WorkspaceResource resource) =>
    CloudResourceMapper.decode(resource);
