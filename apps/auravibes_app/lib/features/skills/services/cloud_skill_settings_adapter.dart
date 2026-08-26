import 'dart:convert';

import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/chats/services/cloud_chat_gateway.dart';
import 'package:auravibes_app/features/skills/models/workspace_skill.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_resource_mapper.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:uuid/v7.dart';

class CloudSkillSettingsAdapter {
  const CloudSkillSettingsAdapter(this._gateway);

  final CloudWorkspaceStateGateway _gateway;

  Stream<List<WorkspaceSkill>> watchSkills() {
    return _gateway
        .watchResources(const [
          WorkspaceResourceKind.skill,
          WorkspaceResourceKind.skillSetting,
        ])
        .map(_mapSkills);
  }

  Stream<({CompactionSettings settings, int? revision})>
  watchCompactionSettingsState() {
    return _gateway
        .watchResources(const [WorkspaceResourceKind.compactionSetting])
        .map((resources) {
          final active = resources.where((item) => item.deletedAt == null);
          if (active.isEmpty) {
            return (settings: CompactionSettings.defaults, revision: null);
          }
          final resource = active.single;

          return (
            settings: CompactionSettings.fromJson(_decode(resource)),
            revision: resource.revision,
          );
        });
  }

  Stream<CompactionSettings> watchCompactionSettings() =>
      watchCompactionSettingsState().map((state) => state.settings);

  Future<CompactionSettings> saveCompactionSettings(
    CompactionSettings settings, {
    int? expectedRevision,
  }) async {
    final _ = await _gateway.patch(
      requestId: const UuidV7().generate(),
      operations: [
        WorkspacePatchOperation(
          operation: expectedRevision == null
              ? WorkspacePatchOperationKind.create
              : WorkspacePatchOperationKind.update,
          resourceKind: WorkspaceResourceKind.compactionSetting,
          resourceId: 'workspace',
          data: jsonEncode(settings.toJson()),
          fieldMask: const [],
          expectedRevision: expectedRevision,
        ),
      ],
    );

    return settings;
  }

  Future<CompactionSettings> saveCurrentCompactionSettings(
    CompactionSettings settings,
  ) async {
    final state = await watchCompactionSettingsState().first;

    return await saveCompactionSettings(
      settings,
      expectedRevision: state.revision,
    );
  }

  Future<void> resetCompactionSettings() async {
    final state = await watchCompactionSettingsState().first;
    final revision = state.revision;
    if (revision == null) return;
    final _ = await _gateway.patch(
      requestId: const UuidV7().generate(),
      operations: [
        WorkspacePatchOperation(
          operation: WorkspacePatchOperationKind.delete,
          resourceKind: WorkspaceResourceKind.compactionSetting,
          resourceId: 'workspace',
          fieldMask: const [],
          expectedRevision: revision,
        ),
      ],
    );
  }

  Future<void> setConversationSkill({
    required String conversationId,
    required String skillId,
    required bool isAppSkill,
    required bool selected,
    int? expectedRevision,
  }) async {
    final resourceId = '$conversationId:$skillId';
    final WorkspacePatchOperationKind operation;
    if (!selected) {
      operation = WorkspacePatchOperationKind.delete;
    } else if (expectedRevision == null) {
      operation = WorkspacePatchOperationKind.create;
    } else {
      operation = WorkspacePatchOperationKind.update;
    }
    final _ = await _gateway.patch(
      requestId: const UuidV7().generate(),
      operations: [
        WorkspacePatchOperation(
          operation: operation,
          resourceKind: WorkspaceResourceKind.conversationSkillSelection,
          resourceId: resourceId,
          data: selected
              ? jsonEncode({
                  'id': resourceId,
                  'conversationId': conversationId,
                  'skillId': skillId,
                  if (isAppSkill) 'source': 'app',
                })
              : null,
          fieldMask: const [],
          expectedRevision: expectedRevision,
        ),
      ],
    );
  }

  Future<void> putCredentialSecret({
    required String credentialId,
    required String? secret,
    int? expectedRevision,
  }) async {
    final _ = await _gateway.putSecret(
      requestId: const UuidV7().generate(),
      secretKind: WorkspaceSecretKind.skillCredential,
      scope: WorkspaceSecretScope.workspace,
      resourceId: credentialId,
      secret: secret,
      expectedRevision: expectedRevision,
    );
  }

  Future<ConversationMutationResult> compactConversation({
    required String conversationId,
    required int expectedRevision,
  }) {
    return CloudChatGateway(_gateway).compactConversation(
      requestId: const UuidV7().generate(),
      conversationId: conversationId,
      expectedConversationRevision: expectedRevision,
    );
  }

  static List<WorkspaceSkill> _mapSkills(List<WorkspaceResource> resources) {
    final settings = <String, bool>{};
    for (final resource in resources.where(
      (item) =>
          item.deletedAt == null &&
          item.resourceKind == WorkspaceResourceKind.skillSetting,
    )) {
      final data = _decode(resource);
      settings[data['skillId'] as String] = data['isEnabled'] as bool;
    }

    return resources
        .where(
          (item) =>
              item.deletedAt == null &&
              item.resourceKind == WorkspaceResourceKind.skill,
        )
        .map((resource) {
          final data = _decode(resource);
          final kind = SkillKind.values.byName(data['kind'] as String);

          return WorkspaceSkill(
            source: SkillSource.values.byName(
              data['source'] as String? ?? SkillSource.user.name,
            ),
            id: resource.resourceId,
            slug: data['slug'] as String,
            title: data['title'] as String,
            description: data['description'] as String,
            kind: kind,
            isEnabled:
                settings[resource.resourceId] ?? data['isEnabled'] as bool,
          );
        })
        .toList()
      ..sort((a, b) => a.title.compareTo(b.title));
  }

  static Map<String, dynamic> _decode(WorkspaceResource resource) {
    return CloudResourceMapper.decode(resource);
  }
}
