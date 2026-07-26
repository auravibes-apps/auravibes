import 'dart:async';

import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_settings_adapter.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Gateway extends Mock implements CloudWorkspaceStateGateway {}

class _Client extends Mock implements Client {}

class _Conversation extends Mock implements EndpointConversation {}

void main() {
  var gateway = _Gateway();
  var adapter = CloudSkillSettingsAdapter(gateway);

  setUpAll(() {
    registerFallbackValue(WorkspaceSecretKind.skillCredential);
    registerFallbackValue(WorkspaceSecretScope.workspace);
    registerFallbackValue(
      CompactConversationRequest(
        workspaceId: 0,
        requestId: '',
        conversationId: '',
        expectedConversationRevision: 0,
      ),
    );
  });

  setUp(() {
    gateway = _Gateway();
    adapter = CloudSkillSettingsAdapter(gateway);
  });

  test('maps cloud skills and settings without local storage', () async {
    when(() => gateway.watchResources(any())).thenAnswer(
      (_) => Stream.value([
        _resource(
          kind: WorkspaceResourceKind.skill,
          id: 'skill-1',
          data:
              '{"slug":"weather","title":"Weather",'
              '"description":"Forecast","kind":"template",'
              '"content":"Instructions","isEnabled":true}',
        ),
        _resource(
          kind: WorkspaceResourceKind.skillSetting,
          id: 'setting-1',
          data: '{"skillId":"skill-1","isEnabled":false}',
        ),
      ]),
    );

    final skills = await adapter.watchSkills().first;

    expect(skills.single.slug, 'weather');
    expect(skills.single.isEnabled, isFalse);
  });

  test('preserves persisted app skill source', () async {
    when(() => gateway.watchResources(any())).thenAnswer(
      (_) => Stream.value([
        _resource(
          kind: WorkspaceResourceKind.skill,
          id: 'agents',
          data:
              '{"source":"app","slug":"agents","title":"Agents", '
              '"description":"Run agents","kind":"native", '
              '"content":"Instructions","isEnabled":true}',
        ),
      ]),
    );

    final skill = (await adapter.watchSkills().first).single;

    expect(skill.source.name, 'app');
    expect(skill.id, 'agents');
  });

  test('uses effective cloud compaction setting', () async {
    when(() => gateway.watchResources(any())).thenAnswer(
      (_) => Stream.value([
        _resource(
          kind: WorkspaceResourceKind.compactionSetting,
          id: 'workspace',
          data:
              '{"autoCompactionEnabled":false,'
              '"usagePercentageThreshold":70,'
              '"remainingTokenThreshold":3000}',
        ),
      ]),
    );

    final settings = await adapter.watchCompactionSettings().first;

    expect(settings.autoCompactionEnabled, isFalse);
    expect(settings.usagePercentageThreshold, 70);
  });

  test('saves settings with expected revision', () async {
    when(() => gateway.watchResources(any())).thenAnswer(
      (_) => Stream.value([
        _resource(
          kind: WorkspaceResourceKind.compactionSetting,
          id: 'workspace',
          data: '{}',
        ),
      ]),
    );
    when(
      () => gateway.patch(
        requestId: any(named: 'requestId'),
        operations: any(named: 'operations'),
      ),
    ).thenAnswer(
      (_) async => PatchWorkspaceStateResponse(
        resources: const [],
        sequence: 4,
      ),
    );

    final _ = await adapter.saveCompactionSettings(
      const CompactionSettings(usagePercentageThreshold: 70),
      expectedRevision: 3,
    );

    final operations =
        verify(
              () => gateway.patch(
                requestId: any(named: 'requestId'),
                operations: captureAny(named: 'operations'),
              ),
            ).captured.single
            as List<WorkspacePatchOperation>;
    expect(operations.single.operation, WorkspacePatchOperationKind.update);
    expect(operations.single.expectedRevision, 3);
  });

  test('reset deletes current override with expected revision', () async {
    when(() => gateway.watchResources(any())).thenAnswer(
      (_) => Stream.value([
        _resource(
          kind: WorkspaceResourceKind.compactionSetting,
          id: 'workspace',
          data: '{}',
        ),
      ]),
    );
    when(
      () => gateway.patch(
        requestId: any(named: 'requestId'),
        operations: any(named: 'operations'),
      ),
    ).thenAnswer(
      (_) async => PatchWorkspaceStateResponse(
        resources: const [],
        sequence: 2,
      ),
    );

    await adapter.resetCompactionSettings();

    final operations =
        verify(
              () => gateway.patch(
                requestId: any(named: 'requestId'),
                operations: captureAny(named: 'operations'),
              ),
            ).captured.single
            as List<WorkspacePatchOperation>;
    expect(operations.single.operation, WorkspacePatchOperationKind.delete);
    expect(operations.single.expectedRevision, 1);
  });

  test('marks app conversation skill selections with their source', () async {
    when(
      () => gateway.patch(
        requestId: any(named: 'requestId'),
        operations: any(named: 'operations'),
      ),
    ).thenAnswer(
      (_) async => PatchWorkspaceStateResponse(
        resources: const [],
        sequence: 2,
      ),
    );

    await adapter.setConversationSkill(
      conversationId: 'conversation-1',
      skillId: 'agents',
      isAppSkill: true,
      selected: true,
    );

    final operations =
        verify(
              () => gateway.patch(
                requestId: any(named: 'requestId'),
                operations: captureAny(named: 'operations'),
              ),
            ).captured.single
            as List<WorkspacePatchOperation>;
    expect(
      operations.single.data,
      '{"id":"conversation-1:agents","conversationId":"conversation-1",'
      '"skillId":"agents","source":"app"}',
    );
  });

  test('writes credential only through secret endpoint', () async {
    when(
      () => gateway.putSecret(
        requestId: any(named: 'requestId'),
        secretKind: any(named: 'secretKind'),
        scope: any(named: 'scope'),
        resourceId: any(named: 'resourceId'),
        secret: any(named: 'secret'),
        expectedRevision: any(named: 'expectedRevision'),
      ),
    ).thenAnswer(
      (_) async => PutWorkspaceSecretResponse(
        configured: true,
        revision: 2,
        sequence: 2,
      ),
    );

    await adapter.putCredentialSecret(
      credentialId: 'credential-1',
      secret: '{"token":"secret"}',
      expectedRevision: 1,
    );

    final submittedSecrets = verify(
      () => gateway.putSecret(
        requestId: any(named: 'requestId'),
        secretKind: WorkspaceSecretKind.skillCredential,
        scope: WorkspaceSecretScope.workspace,
        resourceId: 'credential-1',
        secret: captureAny(named: 'secret'),
        expectedRevision: 1,
      ),
    ).captured;
    expect(submittedSecrets, ['{"token":"secret"}']);
    final _ = verifyNever(
      () => gateway.patch(
        requestId: any(named: 'requestId'),
        operations: any(named: 'operations'),
      ),
    );
  });

  test('routes manual compaction with stale-write revision', () async {
    final client = _Client();
    final conversation = _Conversation();
    when(() => gateway.workspace).thenReturn(
      const CloudWorkspaceRef(
        localWorkspaceId: 'local',
        serverUrl: 'https://example.com',
        accountId: 'account',
        cloudWorkspaceId: 1,
      ),
    );
    when(() => gateway.client).thenReturn(client);
    when(() => client.conversation).thenReturn(conversation);
    when(
      () => conversation.compact(any()),
    ).thenAnswer(
      (_) async => ConversationMutationResult(
        conversationId: 'conversation-1',
        revision: 8,
        status: 'queued',
      ),
    );

    final result = await adapter.compactConversation(
      conversationId: 'conversation-1',
      expectedRevision: 7,
    );

    expect(result.status, 'queued');
  });
}

WorkspaceResource _resource({
  required WorkspaceResourceKind kind,
  required String id,
  required String data,
}) {
  final now = DateTime.utc(2026);

  return WorkspaceResource(
    workspaceId: 7,
    resourceKind: kind,
    resourceId: id,
    data: data,
    revision: 1,
    createdAt: now,
    updatedAt: now,
  );
}
