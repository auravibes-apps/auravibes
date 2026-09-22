import 'dart:async';
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

  test('does not infer an omitted cloud tool credentialId', () {
    expect(cloudToolCredentialId(null), isNull);
    expect(cloudToolCredentialId(' credential-1 '), 'credential-1');
  });

  test('builds audited cloud skill selection patches', () {
    final activation = cloudSkillSelectionPatchRequest(
      workspaceId: 7,
      turnRequestId: 'turn-1',
      conversationId: 'conversation-1',
      skillId: 'research',
      isAppSkill: false,
      toolCallId: 'call-activate-1',
    );
    expect(
      activation.requestId,
      'turn-1:call-activate-1:activate_skill:research',
    );
    expect(
      cloudSkillSelectionPatchRequest(
        workspaceId: 7,
        turnRequestId: 'turn-1',
        conversationId: 'conversation-1',
        skillId: 'research',
        isAppSkill: false,
        toolCallId: 'call-activate-2',
      ).requestId,
      isNot(activation.requestId),
    );
    expect(activation.operations.single.operation.name, 'create');
    expect(
      activation.operations.single.data,
      '{"id":"conversation-1:research","conversationId":"conversation-1","skillId":"research"}',
    );

    final appActivation = cloudSkillSelectionPatchRequest(
      workspaceId: 7,
      turnRequestId: 'turn-1',
      conversationId: 'conversation-1',
      skillId: agentsSkillSlug,
      isAppSkill: true,
      toolCallId: 'call-app-activate-1',
    );
    expect(
      appActivation.operations.single.data,
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

    expect(controls.map((tool) => tool.spec.name), [activateSkillToolName]);
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
      controls.first.spec.inputJsonSchema['properties'],
      containsPair('revision', {'type': 'string'}),
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
        'skill__app_native__agents__list_agents',
        'skill__app_native__agents__run_sub_agent',
        for (final tool in service.tools)
          'skill__app_template__${service.slug}__${tool.slug}',
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

  test('materializes root sub-agent execution without loading agents', () {
    final rootTools = materializeCloudSkillTools(
      selectedSkillIds: const {},
      userSkills: const [],
      templateTools: const [],
      appSkillSettings: const [],
      isChildConversation: false,
    );

    expect(
      rootTools.map((tool) => tool.spec.name),
      ['skill__app_native__agents__run_sub_agent'],
    );

    final disabledTools = materializeCloudSkillTools(
      selectedSkillIds: const {},
      userSkills: const [],
      templateTools: const [],
      appSkillSettings: const [
        {'skillId': agentsSkillSlug, 'isEnabled': false},
      ],
      isChildConversation: false,
    );
    expect(disabledTools, isEmpty);

    final childTools = materializeCloudSkillTools(
      selectedSkillIds: const {agentsSkillSlug},
      userSkills: const [],
      templateTools: const [],
      appSkillSettings: const [],
      isChildConversation: true,
    );
    expect(childTools, isEmpty);
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
          .firstWhere((tool) => tool.spec.name == activateSkillToolName)
          .spec
          .inputJsonSchema['properties'],
      isNot(
        containsPair(
          'slug',
          containsPair('enum', contains(service.identifier)),
        ),
      ),
    );
    expect(
      tools.map((tool) => tool.spec.name),
      ['skill__app_native__agents__run_sub_agent'],
    );
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

    expect(
      tools.map((tool) => tool.spec.name),
      ['skill__app_native__agents__run_sub_agent'],
    );
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
        [
          'skill__app_native__agents__run_sub_agent',
          'skill__app_template__jina__reader_fetch',
        ],
      );
      final jinaTool = tools.singleWhere(
        (tool) => tool.spec.name == 'skill__app_template__jina__reader_fetch',
      );
      expect(
        jinaTool.spec.inputJsonSchema['properties'],
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
          tableId: 'skill__app_native__agents__run_sub_agent',
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
  test('server executes declarative service template tools', () {
    final skill = serviceSkillDefinitions.first;
    final templateTool = skill.tools.first;

    expect(
      serverToolIsExecutable(
        AgentResolvedToolName.skillAppTemplate(
          tableId: templateTool.slug,
          skillSlug: skill.slug,
          toolIdentifier: templateTool.slug,
        ),
      ),
      isTrue,
    );
  });

  test('advertises compiled declarative service tools to cloud', () {
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

    expect(tools, hasLength(skill.tools.length + 1));
    expect(
      tools.map((tool) => tool.spec.name),
      contains('skill__app_native__agents__run_sub_agent'),
    );
    for (final templateTool in skill.tools) {
      expect(
        serverToolIsExecutable(
          AgentResolvedToolName.skillAppTemplate(
            tableId: templateTool.slug,
            skillSlug: skill.slug,
            toolIdentifier: templateTool.slug,
          ),
        ),
        isTrue,
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

  test(
    'approval pause resumes once and running waits for its owner',
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
      expect(serverToolReplayAction('running'), ServerToolReplayAction.skip);
    },
  );

  test('running recovery waits for configured stale threshold', () {
    final claimedAt = DateTime.utc(2026);

    expect(
      serverToolRunningIsStale(
        updatedAt: claimedAt,
        now: claimedAt.add(serverToolRunningRecoveryTimeout),
      ),
      isTrue,
    );
    expect(
      serverToolRunningIsStale(
        updatedAt: claimedAt,
        now: claimedAt
            .add(serverToolRunningRecoveryTimeout)
            .subtract(const Duration(microseconds: 1)),
      ),
      isFalse,
    );
  });

  test('one-time approval executes once while policy still asks', () {
    var executions = 0;
    for (final status in ['approved', 'success']) {
      if (serverToolReplayAction(status) == ServerToolReplayAction.execute &&
          serverToolPermissionAllowsExecution(
            permission: AgentToolPermissionResult.needsConfirmation,
            persistedStatus: status,
          )) {
        executions++;
      }
    }

    expect(executions, 1);
    expect(
      serverToolPermissionAllowsExecution(
        permission: AgentToolPermissionResult.needsConfirmation,
        persistedStatus: null,
      ),
      isFalse,
    );
    expect(
      serverToolPermissionAllowsExecution(
        permission: AgentToolPermissionResult.disabledInWorkspace,
        persistedStatus: 'approved',
      ),
      isFalse,
    );
  });

  test('running replay cannot overwrite owner success', () async {
    var status = 'running';
    var revision = 2;
    var executorInvocations = 1;
    final releaseWinner = Completer<void>();
    final winner = () async {
      await releaseWinner.future;
      if (serverToolCallCanTransition(
        currentStatus: status,
        currentRevision: revision,
        expectedStatus: 'running',
        expectedRevision: 2,
      )) {
        status = 'success';
        revision++;
      }
    }();

    expect(serverToolReplayAction(status), ServerToolReplayAction.skip);
    releaseWinner.complete();
    await winner;

    expect(executorInvocations, 1);
    expect(status, 'success');
    expect(
      serverToolCallCanTransition(
        currentStatus: status,
        currentRevision: revision,
        expectedStatus: 'running',
        expectedRevision: 2,
      ),
      isFalse,
    );
  });

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

  test('keeps the direct sub-agent tool out of the agents manifest', () async {
    final direct = ServerResolvedTool(
      descriptor: AgentResolvedToolName.skillNative(
        tableId: runSubAgentToolName,
        skillSlug: agentsSkillSlug,
        toolIdentifier: runSubAgentToolName,
      ),
      spec: runSubAgentToolSpec,
    );
    final list = ServerResolvedTool(
      descriptor: AgentResolvedToolName.skillNative(
        tableId: listAgentsToolName,
        skillSlug: agentsSkillSlug,
        toolIdentifier: listAgentsToolName,
      ),
      spec: listAgentsToolSpec,
    );

    final manifest = await buildCloudSkillManifest(
      slug: agentsSkillSlug,
      userSkills: const [],
      tools: [direct, list],
    );

    expect(manifest?.tools.map((tool) => tool.name), [listAgentsToolName]);
  });
}
