import 'package:auravibes_server/src/features/workspace_state/domain/workspace_resource_validation.dart';
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:test/test.dart';

void main() {
  test(
    'rejects invalid payloads, foreign workspace identity, and dual truth',
    () {
      for (final data in ['[]', '{', '{"workspaceId":2}', '{"id":"other"}']) {
        expect(
          () => WorkspaceResourceValidation.decode(
            kind: WorkspaceResourceKind.agent,
            resourceId: 'agent-1',
            workspaceId: 1,
            data: data,
          ),
          throwsFormatException,
        );
      }
      for (final kind in WorkspaceResourceValidation.dedicatedKinds) {
        expect(
          () => WorkspaceResourceValidation.decode(
            kind: kind,
            resourceId: 'id-1',
            workspaceId: 1,
            data: '{}',
          ),
          throwsFormatException,
        );
      }
    },
  );

  test('rejects model metadata resources', () {
    for (final kind in [
      WorkspaceResourceKind.modelConnection,
      WorkspaceResourceKind.model,
      WorkspaceResourceKind.modelSelection,
    ]) {
      expect(
        () => WorkspaceResourceValidation.decode(
          kind: kind,
          resourceId: 'id-1',
          workspaceId: 1,
          data: '{}',
        ),
        throwsFormatException,
      );
    }
    expect(
      () => WorkspaceResourceValidation.references(
        WorkspaceResourceKind.modelSelection,
        {'modelId': 1},
      ),
      throwsFormatException,
    );
  });

  test('skill template tools reference their owning skill', () {
    final references = WorkspaceResourceValidation.references(
      WorkspaceResourceKind.skillTemplateTool,
      {'skillId': 'skill-1'},
    );

    expect(references.single.kind, WorkspaceResourceKind.skill);
    expect(references.single.id, 'skill-1');
  });

  test('agent skill associations reference agent and skill', () {
    final references = WorkspaceResourceValidation.references(
      WorkspaceResourceKind.agentAssociation,
      {'agentId': 'agent-1', 'skillId': 'skill-1'},
    );

    expect(
      references.map((reference) => (reference.kind, reference.id)),
      [
        (WorkspaceResourceKind.agent, 'agent-1'),
        (WorkspaceResourceKind.skill, 'skill-1'),
      ],
    );
  });

  test('agent tool associations reference agent and tool', () {
    final references = WorkspaceResourceValidation.references(
      WorkspaceResourceKind.agentAssociation,
      {
        'agentId': 'agent-1',
        'toolId': 'tool-1',
        'permissionMode': 'alwaysAllow',
      },
    );

    expect(
      references.map((reference) => (reference.kind, reference.id)),
      [
        (WorkspaceResourceKind.agent, 'agent-1'),
        (WorkspaceResourceKind.tool, 'tool-1'),
      ],
    );
  });

  test('agent associations require exactly one typed target', () {
    for (final data in [
      {'agentId': 'agent-1'},
      {'agentId': 'agent-1', 'toolId': 'tool-1'},
      {
        'agentId': 'agent-1',
        'toolId': 'tool-1',
        'permissionMode': 'invalid',
      },
      {
        'agentId': 'agent-1',
        'skillId': 'skill-1',
        'toolId': 'tool-1',
      },
      {'toolId': 'tool-1'},
    ]) {
      expect(
        () => WorkspaceResourceValidation.references(
          WorkspaceResourceKind.agentAssociation,
          data,
        ),
        throwsFormatException,
      );
    }
  });

  test('rejects missing or cross-workspace agent tool targets', () async {
    final checked = <(WorkspaceResourceKind, String)>[];

    await expectLater(
      WorkspaceResourceValidation.validateReferences(
        WorkspaceResourceKind.agentAssociation,
        {
          'agentId': 'agent-1',
          'toolId': 'foreign-tool',
          'permissionMode': 'alwaysAsk',
        },
        (reference) async {
          checked.add((reference.kind, reference.id));

          return reference.kind == WorkspaceResourceKind.agent;
        },
      ),
      throwsFormatException,
    );
    expect(checked, [
      (WorkspaceResourceKind.agent, 'agent-1'),
      (WorkspaceResourceKind.tool, 'foreign-tool'),
    ]);
  });

  test('secret identity is non-null and scope-specific', () {
    expect(
      WorkspaceResourceValidation.secretOwnerKey(
        WorkspaceSecretScope.workspace,
        'user-1',
      ),
      'workspace',
    );
    expect(
      WorkspaceResourceValidation.secretOwnerKey(
        WorkspaceSecretScope.user,
        'user-1',
      ),
      'user-1',
    );
  });

  test('receipt identity uses canonical workspace scope', () {
    expect(WorkspaceResourceValidation.receiptScopeKey(42), 'workspace:42');
  });

  test('every resource kind has an explicit ownership boundary', () {
    for (final kind in WorkspaceResourceKind.values) {
      if (WorkspaceResourceValidation.dedicatedKinds.contains(kind)) {
        expect(
          () => WorkspaceResourceValidation.decode(
            kind: kind,
            resourceId: 'resource-1',
            workspaceId: 1,
            data: '{}',
          ),
          throwsFormatException,
        );
        continue;
      }
      final data = WorkspaceResourceValidation.decode(
        kind: kind,
        resourceId: 'resource-1',
        workspaceId: 1,
        data: kind == WorkspaceResourceKind.agentAssociation
            ? '{"agentId":"agent-1","toolId":"tool-1",'
                  '"permissionMode":"alwaysAsk"}'
            : '{}',
      );
      expect(
        () => WorkspaceResourceValidation.references(kind, data),
        returnsNormally,
      );
    }
  });

  test('rejects unsupported masks', () {
    WorkspaceResourceValidation.validateFieldMask(const []);
    expect(
      () => WorkspaceResourceValidation.validateFieldMask(const ['name']),
      throwsFormatException,
    );
  });

  test('events carry actual changed kind and id', () {
    final event = WorkspaceResourceValidation.eventFor(
      WorkspaceResource(
        workspaceId: 1,
        resourceKind: WorkspaceResourceKind.agent,
        resourceId: 'agent-1',
        data: '{}',
        revision: 1,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
    );
    expect(event.kind, 'updated');
    expect(event.resourceKind, 'agent');
    expect(event.resourceId, 'agent-1');
  });
}
