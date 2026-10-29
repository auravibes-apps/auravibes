import 'dart:convert';

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

  test('rejects incomplete agent resources', () {
    for (final data in [
      '{"name":"","description":"Description","content":"Prompt","visibility":"both"}',
      '{"name":"Agent","description":"","content":"Prompt","visibility":"both"}',
      '{"name":"Agent","description":"Description","content":"","visibility":"both"}',
      '{"name":"Agent","description":"Description","content":"Prompt","visibility":"invalid"}',
      '{"name":"Agent","description":"Description","content":"Prompt",'
          '"visibility":"both","isEnabled":42}',
    ]) {
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
  });

  test('workflow resources validate typed workflow boundary connections', () {
    final data = {
      'name': 'Workflow',
      'description': 'Composed workflow',
      'definition': {
        'version': 1,
        'inputs': [
          {'id': 'workflow-input', 'name': 'query', 'type': 'string'},
        ],
        'outputs': [
          {'id': 'workflow-output', 'name': 'answer', 'type': 'string'},
        ],
        'nodes': [
          {
            'id': 'agent-node',
            'kind': 'agent',
            'targetId': 'agent-1',
            'label': 'Agent',
            'x': 300,
            'y': 100,
            'inputs': [
              {'id': 'agent-input', 'name': 'prompt', 'type': 'string'},
            ],
            'outputs': [
              {'id': 'agent-output', 'name': 'text', 'type': 'string'},
            ],
          },
        ],
        'connections': [
          {
            'fromNodeId': null,
            'fromPortId': 'workflow-input',
            'toNodeId': 'agent-node',
            'toPortId': 'agent-input',
          },
          {
            'fromNodeId': 'agent-node',
            'fromPortId': 'agent-output',
            'toNodeId': null,
            'toPortId': 'workflow-output',
          },
        ],
      },
    };

    expect(
      WorkspaceResourceValidation.decode(
        kind: WorkspaceResourceKind.workflow,
        resourceId: 'workflow-1',
        workspaceId: 1,
        data: jsonEncode(data),
      ),
      containsPair('name', 'Workflow'),
    );
    final references = WorkspaceResourceValidation.references(
      WorkspaceResourceKind.workflow,
      data,
    );
    expect(
      references.map((reference) => (reference.kind, reference.id)),
      [(WorkspaceResourceKind.agent, 'agent-1')],
    );
  });

  test('workflow resources reject node cycles and unknown references', () {
    final data = {
      'name': 'Workflow',
      'description': '',
      'definition': {
        'version': 1,
        'inputs': [],
        'outputs': [],
        'nodes': [
          for (final id in ['one', 'two'])
            {
              'id': id,
              'kind': 'agent',
              'targetId': '$id-agent',
              'label': id,
              'x': 0,
              'y': 0,
              'inputs': [
                {'id': '$id-input', 'name': 'input', 'type': 'any'},
              ],
              'outputs': [
                {'id': '$id-output', 'name': 'output', 'type': 'any'},
              ],
            },
        ],
        'connections': [
          {
            'fromNodeId': 'one',
            'fromPortId': 'one-output',
            'toNodeId': 'two',
            'toPortId': 'two-input',
          },
          {
            'fromNodeId': 'two',
            'fromPortId': 'two-output',
            'toNodeId': 'one',
            'toPortId': 'one-input',
          },
        ],
      },
    };

    expect(
      () => WorkspaceResourceValidation.decode(
        kind: WorkspaceResourceKind.workflow,
        resourceId: 'workflow-1',
        workspaceId: 1,
        data: jsonEncode(data),
      ),
      throwsFormatException,
    );
    expect(
      () => WorkspaceResourceValidation.references(
        WorkspaceResourceKind.workflow,
        {
          'name': 'Workflow',
          'description': '',
          'definition': {},
        },
      ),
      throwsFormatException,
    );
  });

  test('workflow resources reject node positions outside the canvas limit', () {
    final data = {
      'name': 'Workflow',
      'description': '',
      'definition': {
        'version': 1,
        'inputs': [],
        'outputs': [],
        'nodes': [
          {
            'id': 'node-1',
            'kind': 'agent',
            'targetId': 'agent-1',
            'label': 'Agent',
            'x': 10001,
            'y': 0,
            'inputs': [],
            'outputs': [],
          },
        ],
        'connections': [],
      },
    };

    expect(
      () => WorkspaceResourceValidation.decode(
        kind: WorkspaceResourceKind.workflow,
        resourceId: 'workflow-1',
        workspaceId: 1,
        data: jsonEncode(data),
      ),
      throwsFormatException,
    );
  });

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

  test('Skills and Connections do not reference Skill-owned credentials', () {
    expect(
      WorkspaceResourceValidation.references(
        WorkspaceResourceKind.skill,
        {
          'connectorToolIds': ['connector/notion/search'],
        },
      ),
      isEmpty,
    );
    expect(
      WorkspaceResourceValidation.references(
        WorkspaceResourceKind.serviceConnection,
        {'kind': 'customHttp', 'serviceId': 'notion'},
      ),
      isEmpty,
    );
  });

  test('app conversation skill selections do not reference user skills', () {
    expect(
      WorkspaceResourceValidation.references(
        WorkspaceResourceKind.conversationSkillSelection,
        {'skillId': 'agents', 'source': 'app'},
      ),
      isEmpty,
    );
    expect(
      WorkspaceResourceValidation.references(
        WorkspaceResourceKind.conversationSkillSelection,
        {'skillId': 'user-skill'},
      ).single.id,
      'user-skill',
    );
  });

  test('agent skill associations reference agent and skill', () {
    final references = WorkspaceResourceValidation.references(
      WorkspaceResourceKind.agentAssociation,
      {'agentId': 'agent-1', 'skillId': 'skill-1'},
    );

    expect(references.map((reference) => (reference.kind, reference.id)), [
      (WorkspaceResourceKind.agent, 'agent-1'),
      (WorkspaceResourceKind.skill, 'skill-1'),
    ]);
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

    expect(references.map((reference) => (reference.kind, reference.id)), [
      (WorkspaceResourceKind.agent, 'agent-1'),
      (WorkspaceResourceKind.tool, 'tool-1'),
    ]);
  });

  test('agent associations require exactly one typed target', () {
    for (final data in [
      {'agentId': 'agent-1'},
      {'agentId': 'agent-1', 'toolId': 'tool-1'},
      {'agentId': 'agent-1', 'toolId': 'tool-1', 'permissionMode': 'invalid'},
      {'agentId': 'agent-1', 'skillId': 'skill-1', 'toolId': 'tool-1'},
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
        data: switch (kind) {
          WorkspaceResourceKind.folder => '{"name":"Folder","parentId":null}',
          WorkspaceResourceKind.file =>
            '{"name":"File","parentId":null,"assetId":"1"}',
          WorkspaceResourceKind.table =>
            '{"name":"Table","parentId":null,'
                '"labelColumnId":"column-1","schemaRevision":1,'
                '"columns":[{"id":"column-1","name":"Name","type":"text"}]}',
          WorkspaceResourceKind.tableRecord =>
            '{"tableId":"table-1",'
                '"schemaRevision":1,"values":{"column-1":"Record"}}',
          WorkspaceResourceKind.agentAssociation =>
            '{"agentId":"agent-1","toolId":"tool-1",'
                '"permissionMode":"alwaysAsk"}',
          WorkspaceResourceKind.agent =>
            '{"name":"Agent","description":"Description",'
                '"content":"Prompt","visibility":"both"}',
          WorkspaceResourceKind.workflow =>
            '{"name":"Workflow","description":"",'
                '"definition":{"version":1,"inputs":[],"outputs":[],'
                '"nodes":[],"connections":[]}}',
          _ => '{}',
        },
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
