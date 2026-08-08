import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server/src/features/conversations/engine/server_tool_executor.dart';
import 'package:auravibes_server/src/features/conversations/engine/server_tool_runtime.dart';
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:test/test.dart';

void main() {
  test('authorizes active agent-associated skills for execution', () {
    final now = DateTime.utc(2026);
    WorkspaceResource resource(
      WorkspaceResourceKind kind,
      String id,
      Map<String, Object?> data,
    ) => WorkspaceResource(
      workspaceId: 1,
      resourceKind: kind,
      resourceId: id,
      data: jsonEncode(data),
      revision: 1,
      createdAt: now,
      updatedAt: now,
    );
    final conversation = Conversation(
      workspaceId: 1,
      stableId: 'conversation-1',
      title: 'Conversation',
      agentId: 'agent-1',
      isPinned: false,
      revision: 1,
      projectionRevision: 1,
      eventSequence: 0,
      executionState: 'idle',
      createdAt: now,
      updatedAt: now,
    );
    final resources = [
      resource(WorkspaceResourceKind.agent, 'agent-1', {
        'isEnabled': true,
        'visibility': 'both',
      }),
      resource(WorkspaceResourceKind.agentAssociation, 'association-1', {
        'agentId': 'agent-1',
        'skillId': 'research',
      }),
    ];

    expect(
      cloudAuthorizedSkillIds(
        conversation: conversation,
        resources: resources,
      ),
      {'research'},
    );
    resources[0] = resource(WorkspaceResourceKind.agent, 'agent-1', {
      'isEnabled': false,
      'visibility': 'both',
    });
    expect(
      cloudAuthorizedSkillIds(
        conversation: conversation,
        resources: resources,
      ),
      isEmpty,
    );
  });

  test('sanitizes server tool failure codes for logs', () {
    expect(
      serverToolExecutionFailureCode(const FormatException('input details')),
      'invalid_request',
    );
    expect(serverToolExecutionFailureCode(StateError('secret')), 'unexpected');
  });

  test('builds audited cloud skill selection patches', () {
    final load = cloudSkillSelectionPatchRequest(
      workspaceId: 7,
      turnRequestId: 'turn-1',
      conversationId: 'conversation-1',
      skillId: 'research',
      isAppSkill: false,
      controlName: loadSkillToolName,
      toolCallId: 'call-load-1',
    );
    expect(load.requestId, 'turn-1:call-load-1:load_skill:research');
    expect(
      cloudSkillSelectionPatchRequest(
        workspaceId: 7,
        turnRequestId: 'turn-1',
        conversationId: 'conversation-1',
        skillId: 'research',
        isAppSkill: false,
        controlName: loadSkillToolName,
        toolCallId: 'call-load-2',
      ).requestId,
      isNot(load.requestId),
    );
    expect(load.operations.single.operation.name, 'create');
    expect(
      load.operations.single.data,
      '{"id":"conversation-1:research","conversationId":"conversation-1","skillId":"research"}',
    );

    final unload = cloudSkillSelectionPatchRequest(
      workspaceId: 7,
      turnRequestId: 'turn-1',
      conversationId: 'conversation-1',
      skillId: 'research',
      isAppSkill: false,
      controlName: unloadSkillToolName,
      toolCallId: 'call-unload-1',
      existingRevision: 3,
    );
    expect(unload.operations.single.operation.name, 'delete');
    expect(unload.operations.single.expectedRevision, 3);

    final appLoad = cloudSkillSelectionPatchRequest(
      workspaceId: 7,
      turnRequestId: 'turn-1',
      conversationId: 'conversation-1',
      skillId: agentsSkillSlug,
      isAppSkill: true,
      controlName: loadSkillToolName,
      toolCallId: 'call-app-load-1',
    );
    expect(
      appLoad.operations.single.data,
      '{"id":"conversation-1:agents","conversationId":"conversation-1","skillId":"agents","source":"app"}',
    );
  });

  test('materializes cloud skill controls from selection state', () {
    final service = serviceSkillDefinitions.first;
    final controls = materializeCloudSkillControlTools(
      selectedSkillIds: {'research'},
      userSkills: const [
        {'id': 'research', 'slug': 'research', 'isEnabled': true},
        {'id': 'disabled', 'slug': 'disabled', 'isEnabled': false},
      ],
      appSkillSettings: [
        {'skillId': service.identifier, 'isEnabled': true},
      ],
      serviceConnections: [
        {
          'id': 'service-credential',
          'kind': 'appSkillCredential',
          'serviceId': service.identifier,
          'isEnabled': true,
          'hasSecret': true,
        },
      ],
      isChildConversation: false,
    );

    expect(controls.map((tool) => tool.spec.name), [
      loadSkillToolName,
      unloadSkillToolName,
    ]);
    expect(
      controls.first.spec.inputJsonSchema['properties'],
      containsPair(
        'slug',
        containsPair(
          'enum',
          containsAll([agentsSkillSlug, service.identifier]),
        ),
      ),
    );
    expect(
      controls.last.spec.inputJsonSchema['properties'],
      {
        'slug': {
          'type': 'string',
          'enum': ['research'],
        },
      },
    );
    expect(
      defaultCloudToolPermission(controls.first.descriptor),
      AgentToolPermissionResult.needsConfirmation,
    );
  });

  test('materializes selected cloud skill tools only', () {
    final service = serviceSkillDefinitions.first;
    final tools = materializeCloudSkillTools(
      selectedSkillIds: {'research', agentsSkillSlug, service.identifier},
      userSkills: const [
        {
          'id': 'research',
          'slug': 'research',
          'credentialDefinitionId': 'definition-1',
          'isEnabled': true,
        },
      ],
      templateTools: const [
        {
          'skillId': 'research',
          'skillSlug': 'research',
          'toolSlug': 'search',
          'description': 'Search primary sources.',
          'isEnabled': true,
          'requiresCredential': true,
          'inputsJson': [
            {
              'name': 'query',
              'type': 'string',
              'description': 'Search query.',
              'isOptional': false,
            },
          ],
        },
        {
          'skillId': 'other',
          'skillSlug': 'other',
          'toolSlug': 'hidden',
          'description': 'Not selected.',
          'isEnabled': true,
          'inputsJson': [],
        },
      ],
      appSkillSettings: [
        {'skillId': service.identifier, 'isEnabled': true},
      ],
      serviceConnections: [
        {
          'id': 'template-credential',
          'kind': 'skillCredential',
          'credentialDefinitionId': 'definition-1',
          'isEnabled': true,
          'hasSecret': true,
        },
        {
          'id': 'service-credential',
          'kind': 'appSkillCredential',
          'serviceId': service.identifier,
          'isEnabled': true,
          'hasSecret': true,
        },
      ],
      isChildConversation: false,
    );

    expect(
      tools.map((tool) => tool.spec.name),
      containsAll([
        'skill__user__research__search',
        'skill__app__agents__list_agents',
        'skill__app__agents__run_sub_agent',
        for (final tool in service.nativeTools)
          'skill__app__${service.slug}__${tool.slug}',
      ]),
    );
    final template = tools.firstWhere(
      (tool) => tool.spec.name == 'skill__user__research__search',
    );
    expect(template.spec.inputJsonSchema, {
      'type': 'object',
      'properties': {
        'query': {
          'type': 'string',
          'description': 'Search query.',
        },
        'credentialId': {
          'type': 'string',
          'enum': ['template-credential'],
        },
      },
      'required': ['query'],
      'additionalProperties': false,
    });

    expect(tools.map((tool) => tool.spec.name), isNot(contains('hidden')));
  });

  test('lists only ready user skills in cloud load controls', () {
    final controls = materializeCloudSkillControlTools(
      selectedSkillIds: const {},
      userSkills: const [
        {'id': 'ready', 'slug': 'ready', 'isEnabled': true},
        {'id': 'disabled', 'slug': 'disabled', 'isEnabled': false},
        {'id': 'credentialed', 'slug': 'credentialed', 'isEnabled': true},
      ],
      templateTools: const [
        {'skillId': 'ready', 'isEnabled': true, 'requiresCredential': false},
        {
          'skillId': 'disabled',
          'isEnabled': false,
          'requiresCredential': false,
        },
        {
          'skillId': 'credentialed',
          'isEnabled': true,
          'requiresCredential': true,
        },
      ],
      appSkillSettings: const [],
      isChildConversation: false,
    );

    final slugs =
        ((controls.first.spec.inputJsonSchema['properties'] as Map)['slug']
                as Map)['enum']
            as List;
    expect(slugs, contains('ready'));
    expect(slugs, isNot(contains('disabled')));
    expect(slugs, isNot(contains('credentialed')));
  });

  test('does not expose service skills without enabled ready cloud state', () {
    final service = serviceSkillDefinitions.first;
    final controls = materializeCloudSkillControlTools(
      selectedSkillIds: const {},
      userSkills: const [],
      appSkillSettings: const [],
      isChildConversation: false,
    );
    final tools = materializeCloudSkillTools(
      selectedSkillIds: {service.identifier},
      userSkills: const [],
      templateTools: const [],
      appSkillSettings: const [],
      isChildConversation: false,
    );

    expect(
      controls
          .firstWhere((tool) => tool.spec.name == loadSkillToolName)
          .spec
          .inputJsonSchema['properties'],
      isNot(
        containsPair(
          'slug',
          containsPair('enum', contains(service.identifier)),
        ),
      ),
    );
    expect(tools, isEmpty);
  });

  test('native credential schemas offer opaque credential IDs', () {
    expect(
      cloudNativeInputSchema(
        const {
          'type': 'object',
          'properties': {
            'query': {'type': 'string'},
          },
          'required': ['query'],
        },
        requiresCredential: true,
        credentialIds: const ['credential-1'],
      ),
      {
        'type': 'object',
        'properties': {
          'query': {'type': 'string'},
          'credentialId': {
            'type': 'string',
            'enum': ['credential-1'],
          },
        },
        'required': ['query'],
      },
    );
  });

  test(
    'credential schemas require explicit selection only with multiple IDs',
    () {
      expect(
        cloudTemplateInputSchema(
          '[{"name":"query","type":"string"}]',
          requiresCredential: true,
          credentialIds: const ['credential-1'],
        ),
        containsPair(
          'properties',
          containsPair(
            'credentialId',
            {
              'type': 'string',
              'enum': ['credential-1'],
            },
          ),
        ),
      );
      expect(
        cloudTemplateInputSchema(
          '[{"name":"query","type":"string"}]',
          requiresCredential: true,
          credentialIds: const ['credential-1'],
        )['required'],
        ['query'],
      );
      expect(
        cloudNativeInputSchema(
          const {'type': 'object', 'properties': <String, Object?>{}},
          requiresCredential: true,
          credentialIds: const ['credential-1', 'credential-2'],
        )['required'],
        ['credentialId'],
      );
    },
  );

  test('malformed template inputs fail fast', () {
    expect(
      () => cloudTemplateInputSchema('{not-json', requiresCredential: false),
      throwsFormatException,
    );
  });

  test('does not materialize credentialed templates without candidates', () {
    final tools = materializeCloudSkillTools(
      selectedSkillIds: const {'research'},
      userSkills: const [
        {
          'id': 'research',
          'slug': 'research',
          'credentialDefinitionId': 'definition-1',
          'isEnabled': true,
        },
      ],
      templateTools: const [
        {
          'skillId': 'research',
          'skillSlug': 'research',
          'toolSlug': 'search',
          'isEnabled': true,
          'requiresCredential': true,
          'inputsJson': [],
        },
      ],
      appSkillSettings: const [],
      isChildConversation: false,
    );

    expect(tools, isEmpty);
  });

  test(
    'materializes only credential-eligible server-native service tools',
    () {
      final jina = serviceSkillDefinitions.singleWhere(
        (skill) => skill.identifier == 'jina',
      );
      final tools = materializeCloudSkillTools(
        selectedSkillIds: {jina.identifier},
        userSkills: const [],
        templateTools: const [],
        appSkillSettings: [
          {'skillId': jina.identifier, 'isEnabled': true},
        ],
        isChildConversation: false,
      );

      expect(
        tools.map((tool) => tool.spec.name),
        ['skill__app__jina__reader_fetch'],
      );
      expect(
        tools.single.spec.inputJsonSchema['properties'],
        isNot(contains('credentialId')),
      );
    },
  );

  test('does not materialize disabled or child-only cloud skill tools', () {
    final tools = materializeCloudSkillTools(
      selectedSkillIds: {agentsSkillSlug, 'research'},
      userSkills: const [
        {'id': 'research', 'slug': 'research', 'isEnabled': false},
      ],
      templateTools: const [],
      appSkillSettings: const [
        {'skillId': 'agents', 'isEnabled': false},
      ],
      isChildConversation: true,
    );

    expect(tools, isEmpty);
  });

  test('materialized skill tools default to approval when unconfigured', () {
    expect(
      defaultCloudToolPermission(
        AgentResolvedToolName.skillNative(
          tableId: 'skill__app__agents__run_sub_agent',
          skillSlug: agentsSkillSlug,
          toolIdentifier: runSubAgentToolName,
        ),
      ),
      AgentToolPermissionResult.needsConfirmation,
    );
  });

  test('server executes durable sub-agent tools', () {
    expect(
      serverToolIsExecutable(
        AgentResolvedToolName.skillNative(
          tableId: runSubAgentToolName,
          skillSlug: agentsSkillSlug,
          toolIdentifier: runSubAgentToolName,
        ),
      ),
      isTrue,
    );
  });
  test('server executes declarative service native tools', () {
    final skill = serviceSkillDefinitions.first;
    final nativeTool = skill.nativeTools.first;

    expect(
      serverToolIsExecutable(
        AgentResolvedToolName.skillNative(
          tableId: nativeTool.slug,
          skillSlug: skill.slug,
          toolIdentifier: nativeTool.slug,
        ),
      ),
      isTrue,
    );
  });

  test('does not advertise callback-backed service native tools to cloud', () {
    final skill = serviceSkillDefinitions.singleWhere(
      (candidate) => candidate.identifier == 'anthropic',
    );
    final tools = materializeCloudSkillTools(
      selectedSkillIds: {skill.identifier},
      userSkills: const [],
      templateTools: const [],
      appSkillSettings: [
        {'skillId': skill.identifier, 'isEnabled': true},
      ],
      serviceConnections: [
        {
          'id': 'anthropic-credential',
          'kind': 'appSkillCredential',
          'serviceId': skill.identifier,
          'isEnabled': true,
          'hasSecret': true,
        },
      ],
      isChildConversation: false,
    );

    expect(tools, isEmpty);
    for (final nativeTool in skill.nativeTools) {
      expect(
        serverToolIsExecutable(
          AgentResolvedToolName.skillNative(
            tableId: nativeTool.slug,
            skillSlug: skill.slug,
            toolIdentifier: nativeTool.slug,
          ),
        ),
        isFalse,
      );
    }
  });

  test('cloud native credentials require the matching service', () {
    expect(cloudServiceConnectionId('service:credential-1'), 'credential-1');
    expect(cloudServiceConnectionId('credential-1'), 'credential-1');
    expect(
      isCloudAppSkillCredential(
        const {
          'kind': 'appSkillCredential',
          'serviceId': 'search',
          'isEnabled': true,
          'hasSecret': true,
        },
        'search',
      ),
      isTrue,
    );
    expect(
      isCloudAppSkillCredential(
        const {'kind': 'appSkillCredential', 'serviceId': 'other'},
        'search',
      ),
      isFalse,
    );
    expect(
      isCloudAppSkillCredential(
        const {'kind': 'modelProvider', 'serviceId': 'search'},
        'search',
      ),
      isFalse,
    );
    expect(
      isCloudAppSkillCredential(
        const {
          'kind': 'appSkillCredential',
          'serviceId': 'search',
          'isEnabled': false,
          'hasSecret': true,
        },
        'search',
      ),
      isFalse,
    );
    expect(
      isCloudAppSkillCredential(
        const {
          'kind': 'appSkillCredential',
          'serviceId': 'search',
          'isEnabled': true,
          'hasSecret': false,
        },
        'search',
      ),
      isFalse,
    );
  });

  test('duplicate skill controls with distinct call IDs are no-ops', () {
    const requests = [
      (id: 'load-1', control: loadSkillToolName, selected: true),
      (id: 'load-2', control: loadSkillToolName, selected: true),
      (id: 'unload-1', control: unloadSkillToolName, selected: false),
      (id: 'unload-2', control: unloadSkillToolName, selected: false),
    ];

    expect(requests.map((request) => request.id).toSet(), hasLength(4));
    expect(
      requests
          .map(
            (request) => cloudSkillControlIsNoop(
              controlName: request.control,
              isSelected: request.selected,
            ),
          )
          .every((value) => value),
      isTrue,
    );
  });

  test(
    'approval pause resumes once and completed replay skips side effect',
    () {
      var sideEffects = 0;
      for (final status in [
        'pending',
        'approved',
        'running',
        'success',
        'denied',
      ]) {
        if (serverToolReplayAction(status) == ServerToolReplayAction.execute) {
          sideEffects++;
        }
      }

      expect(sideEffects, 1);
      expect(serverToolReplayAction('pending'), ServerToolReplayAction.pause);
      expect(
        serverToolReplayAction('running'),
        ServerToolReplayAction.recover,
      );
    },
  );

  test('cloud exposes only fixed skill command schemas', () {
    final before = fixedCloudSkillCommandTools();
    final after = fixedCloudSkillCommandTools();

    expect(
      before.map((tool) => tool.spec),
      orderedEquals(after.map((tool) => tool.spec)),
    );
    expect(
      before.map((tool) => tool.spec.name),
      orderedEquals(skillCommandToolNames),
    );
    expect(before.any((tool) => tool.spec.name.startsWith('skill__')), isFalse);
    expect(
      before.every((tool) => serverToolIsExecutable(tool.descriptor)),
      isTrue,
    );
  });

  test(
    'builds deterministic cloud manifest from authoritative target specs',
    () async {
      final descriptor = AgentResolvedToolName.skillTemplate(
        tableId: 'tool-1',
        skillSlug: 'research',
        toolIdentifier: 'search',
      );
      final targets = [
        ServerResolvedTool(
          descriptor: descriptor,
          spec: ToolSpec(
            name: descriptor.fullName,
            description: 'Search sources.',
            inputJsonSchema: const {
              'type': 'object',
              'properties': {
                'query': {'type': 'string'},
              },
            },
          ),
        ),
      ];
      const skills = [
        {
          'id': 'skill-1',
          'slug': 'research',
          'title': 'Research',
          'content': 'Use primary sources.',
          'isEnabled': true,
        },
      ];

      final first = await buildCloudSkillManifest(
        slug: 'research',
        userSkills: skills,
        tools: targets,
      );
      final second = await buildCloudSkillManifest(
        slug: 'research',
        userSkills: skills,
        tools: targets,
      );

      expect(first?.revision, second?.revision);
      expect(first?.tools.single.name, 'search');
      expect(first?.tools.single.inputJsonSchema['properties'], isNotNull);
    },
  );
}
