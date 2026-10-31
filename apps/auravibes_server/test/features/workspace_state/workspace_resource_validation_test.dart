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

  test('workflow resources validate node links and typed bindings', () {
    final query = _workflowField('query', 'string');
    final prompt = _workflowField('prompt', 'string');
    final text = _workflowField('text', 'string');
    final answer = _workflowField('answer', 'string');
    final data = _workflowResource(
      parentId: 'folder-1',
      description: 'Composed workflow',
      nodes: [
        _workflowNode(
          id: 'inputs-node',
          kind: 'inputs',
          targetId: 'inputs',
          outputFields: [query],
        ),
        _workflowNode(
          id: 'connector-node',
          kind: 'connectorTool',
          targetId: 'connector/example/search',
          inputFields: [prompt],
          outputFields: [text],
          inputBindings: {
            prompt['id']! as String: {
              'sourceNodeId': 'inputs-node',
              'jsonPointer': '/query',
            },
          },
          hasSampledOutputs: true,
        ),
        _workflowNode(
          id: 'outputs-node',
          kind: 'outputs',
          targetId: 'outputs',
          inputFields: [answer],
          inputBindings: {
            answer['id']! as String: {
              'sourceNodeId': 'connector-node',
              'jsonPointer': '/text',
            },
          },
        ),
      ],
      connections: [
        {'fromNodeId': 'inputs-node', 'toNodeId': 'connector-node'},
        {'fromNodeId': 'connector-node', 'toNodeId': 'outputs-node'},
      ],
    );

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
      [(WorkspaceResourceKind.folder, 'folder-1')],
    );
  });

  test('workflow resources reject node cycles and malformed references', () {
    final data = _workflowResource(
      nodes: [
        _workflowNode(id: 'inputs', kind: 'inputs', targetId: 'inputs'),
        _workflowNode(id: 'one', kind: 'connectorTool', targetId: 'tool-one'),
        _workflowNode(id: 'two', kind: 'connectorTool', targetId: 'tool-two'),
        _workflowNode(id: 'outputs', kind: 'outputs', targetId: 'outputs'),
      ],
      connections: [
        {'fromNodeId': 'one', 'toNodeId': 'two'},
        {'fromNodeId': 'two', 'toNodeId': 'one'},
      ],
    );

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
        _workflowResource(definition: {}),
      ),
      throwsFormatException,
    );
  });

  test('workflow resources reject node positions outside the canvas limit', () {
    final data = _workflowResource(
      nodes: [
        _workflowNode(id: 'inputs', kind: 'inputs', targetId: 'inputs'),
        _workflowNode(
          id: 'far',
          kind: 'connectorTool',
          targetId: 'tool',
          x: 10001,
        ),
        _workflowNode(id: 'outputs', kind: 'outputs', targetId: 'outputs'),
      ],
    );

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
          WorkspaceResourceKind.workflow => jsonEncode(_workflowResource()),
          _ => '{}',
        },
      );
      expect(
        () => WorkspaceResourceValidation.references(kind, data),
        returnsNormally,
      );
    }
  });

  test('requires current workflow node state and rejects Skill nodes', () {
    Map<String, Object?> workflowNode({
      String kind = 'connectorTool',
      bool? hasSampledOutputs = false,
    }) {
      final resource = _workflowResource(
        nodes: [
          _workflowNode(id: 'inputs', kind: 'inputs', targetId: 'inputs'),
          _workflowNode(
            id: 'node-1',
            kind: kind,
            targetId: 'connector/example/tool',
            hasSampledOutputs: hasSampledOutputs,
          ),
          _workflowNode(id: 'outputs', kind: 'outputs', targetId: 'outputs'),
        ],
      );
      return resource;
    }

    void validate(Map<String, Object?> data) =>
        WorkspaceResourceValidation.decode(
          kind: WorkspaceResourceKind.workflow,
          resourceId: 'workflow-1',
          workspaceId: 1,
          data: jsonEncode(data),
        );

    expect(
      () => validate(workflowNode(hasSampledOutputs: true)),
      returnsNormally,
    );
    for (final data in [
      workflowNode(hasSampledOutputs: null),
      workflowNode(kind: 'skill'),
      workflowNode(kind: 'systemTool', hasSampledOutputs: true),
      _workflowResource(definition: {'version': 1}),
    ]) {
      expect(() => validate(data), throwsFormatException);
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

Map<String, Object?> _workflowResource({
  String? parentId,
  String description = '',
  Map<String, Object?>? definition,
  List<Map<String, Object?>>? nodes,
  List<Map<String, Object?>> connections = const [],
}) => {
  'name': 'Workflow',
  'description': description,
  'parentId': parentId,
  'definition':
      definition ??
      {
        'version': 2,
        'localConnectorSchemas': <String, Object?>{},
        'nodes':
            nodes ??
            [
              _workflowNode(id: 'inputs', kind: 'inputs', targetId: 'inputs'),
              _workflowNode(
                id: 'outputs',
                kind: 'outputs',
                targetId: 'outputs',
              ),
            ],
        'connections': connections,
      },
};

Map<String, Object?> _workflowNode({
  required String id,
  required String kind,
  required String targetId,
  double x = 0,
  double y = 0,
  bool? hasSampledOutputs = false,
  List<Map<String, Object?>> inputFields = const [],
  List<Map<String, Object?>> outputFields = const [],
  Map<String, Object?> inputBindings = const {},
}) => {
  'id': id,
  'kind': kind,
  'targetId': targetId,
  'canonicalName': kind,
  'label': id,
  'hasSampledOutputs': ?hasSampledOutputs,
  'x': x,
  'y': y,
  'inputFields': inputFields,
  'outputFields': outputFields,
  'inputBindings': inputBindings,
  'conditionMode': 'all',
  'conditionRules': const [],
  'transformOutputs': const [],
};

Map<String, Object?> _workflowField(String id, String type) => {
  'id': id,
  'name': id,
  'type': type,
  'required': true,
  'description': '',
  'nullable': false,
  'hasDefault': false,
  'properties': const [],
};
