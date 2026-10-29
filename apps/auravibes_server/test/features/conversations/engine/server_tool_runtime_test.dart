import 'dart:async';
import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server/src/features/conversations/domain/conversation_values.dart';
import 'package:auravibes_server/src/features/conversations/engine/server_tool_executor.dart';
import 'package:auravibes_server/src/features/conversations/engine/server_tool_runtime.dart';
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:test/test.dart';

void main() {
  test('protocol serializes both named modes and nullable updates', () {
    final now = DateTime.utc(2026);
    for (final mode in ['default', 'allow_all']) {
      final create = CreateConversationRequest(
        workspaceId: 1,
        requestId: 'create',
        conversationId: 'conversation',
        title: 'Conversation',
        isPinned: false,
        toolAccessMode: mode,
      );
      expect(
        CreateConversationRequest.fromJson(create.toJson()).toolAccessMode,
        mode,
      );
      final summary = ConversationSummary(
        id: 'conversation',
        title: 'Conversation',
        isPinned: false,
        toolAccessMode: mode,
        revision: 1,
        createdAt: now,
        updatedAt: now,
      );
      expect(
        ConversationSummary.fromJson(summary.toJson()).toolAccessMode,
        mode,
      );
      final projection = ConversationProjectionView(
        id: 'conversation',
        workspaceId: 1,
        executionState: 'idle',
        projectionRevision: 1,
        sequence: 0,
        toolAccessMode: mode,
        updatedAt: now,
      );
      expect(
        ConversationProjectionView.fromJson(projection.toJson()).toolAccessMode,
        mode,
      );
      final update = UpdateConversationRequest(
        workspaceId: 1,
        requestId: 'update',
        conversationId: 'conversation',
        expectedRevision: 1,
        toolAccessMode: mode,
        clearModel: false,
        clearAgent: false,
        clearReasoningConfig: false,
        clearParent: false,
      );
      expect(
        UpdateConversationRequest.fromJson(update.toJson()).toolAccessMode,
        mode,
      );
      expect(update.toJson(), isNot(contains('title')));
      expect(
        update.copyWith(toolAccessMode: null).toJson(),
        isNot(contains('toolAccessMode')),
      );
    }
  });

  test('cloud mode decodes unknown strings before policy evaluation', () {
    for (final mode in ['default', 'future_mode', 'allowAll', '']) {
      expect(
        applyConversationToolAccessMode(
          AgentToolPermissionResult.needsConfirmation,
          mode: ConversationToolAccessModeStorage.decode(mode),
        ),
        AgentToolPermissionResult.needsConfirmation,
      );
    }
    for (final permission in AgentToolPermissionResult.values) {
      expect(
        applyConversationToolAccessMode(
          permission,
          mode: ConversationToolAccessModeStorage.decode('allow_all'),
        ),
        permission == AgentToolPermissionResult.needsConfirmation
            ? AgentToolPermissionResult.granted
            : permission,
      );
    }
  });

  test('conversation ask cannot mask agent or workspace denial', () {
    for (final workspace in [
      AgentToolPermissionResult.needsConfirmation,
      AgentToolPermissionResult.disabledInWorkspace,
    ]) {
      expect(
        applyConversationToolAccessMode(
          resolveCloudToolPermission(
            workspacePermission: workspace,
            agentPermissionMode: 'alwaysDeny',
            conversationPermissionMode: 'alwaysAsk',
          ),
          mode: ConversationToolAccessMode.allowAll,
        ),
        AgentToolPermissionResult.disabledInWorkspace,
      );
    }
    expect(
      resolveCloudToolPermission(
        workspacePermission: AgentToolPermissionResult.disabledInWorkspace,
        agentPermissionMode: 'alwaysDeny',
        conversationPermissionMode: 'alwaysAllow',
      ),
      AgentToolPermissionResult.disabledInWorkspace,
    );
    expect(
      resolveCloudToolPermission(
        workspacePermission: AgentToolPermissionResult.granted,
        conversationPermissionMode: 'alwaysDeny',
      ),
      AgentToolPermissionResult.disabledInWorkspace,
    );
  });

  test('conversation allow-all preserves each access denial and missing authorization', () {
    for (final permission in [
      AgentToolPermissionResult.disabledInWorkspace,
      AgentToolPermissionResult.disabledInConversation,
      AgentToolPermissionResult.disabledByAgent,
      AgentToolPermissionResult.notConfigured,
    ]) {
      expect(
        resolveCloudToolPermission(
          workspacePermission: permission,
          conversationPermissionMode: 'alwaysAllow',
        ),
        permission,
      );
    }
    expect(
      resolveCloudToolPermission(
        workspacePermission: AgentToolPermissionResult.granted,
        agentPermissionMode: 'alwaysDeny',
        conversationPermissionMode: 'alwaysAllow',
      ),
      AgentToolPermissionResult.disabledInWorkspace,
    );
  });

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

  test('only native skill tools are replayable', () {
    expect(
      serverToolIsReplayableSkillKind(AgentResolvedToolKind.skillNative),
      isTrue,
    );
    expect(
      AgentResolvedToolKind.values
          .where((kind) => kind != AgentResolvedToolKind.skillNative)
          .every((kind) => !serverToolIsReplayableSkillKind(kind)),
      isTrue,
    );
  });

  test('only native run_sub_agent can run in background', () {
    ServerResolvedTool tool(AgentResolvedToolName descriptor) =>
        ServerResolvedTool(
          descriptor: descriptor,
          spec: ToolSpec(
            name: descriptor.fullName,
            description: 'Test tool.',
            inputJsonSchema: const {'type': 'object'},
          ),
        );
    final runSubAgent = tool(
      AgentResolvedToolName.skillNative(
        tableId: runSubAgentToolName,
        skillSlug: agentsSkillSlug,
        toolIdentifier: runSubAgentToolName,
      ),
    );

    expect(
      serverToolCanRunInBackground(
        runSubAgent,
        isTopLevelConversation: true,
      ),
      isTrue,
    );
    expect(
      serverToolCanRunInBackground(
        runSubAgent,
        isTopLevelConversation: false,
      ),
      isFalse,
    );
    expect(
      serverToolCanRunInBackground(
        tool(
          AgentResolvedToolName.skillNative(
            tableId: 'guide',
            skillSlug: 'research',
            toolIdentifier: 'guide',
          ),
        ),
        isTopLevelConversation: true,
      ),
      isFalse,
    );
    expect(
      serverToolCanRunInBackground(
        tool(
          AgentResolvedToolName.connectorCommand(
            toolIdentifier: executeConnectorToolName,
          ),
        ),
        isTopLevelConversation: true,
      ),
      isFalse,
    );
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
          'kind': 'customHttp',
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

  test('offers content-only A2UI only to top-level conversations', () {
    final controls = materializeCloudSkillControlTools(
      selectedSkillIds: const {},
      userSkills: const [],
      appSkillSettings: const [],
      isChildConversation: false,
    );
    final slugs =
        (((controls.single.spec.inputJsonSchema['properties'] as Map)['slug']
                    as Map)['enum']
                as List)
            .cast<String>();

    expect(slugs, contains(a2uiSkillSlug));
    expect(
      materializeCloudSkillControlTools(
        selectedSkillIds: const {},
        userSkills: const [],
        appSkillSettings: const [],
        isChildConversation: true,
      ).single.spec.inputJsonSchema['properties'],
      isNot(
        containsPair(
          'slug',
          containsPair('enum', contains(a2uiSkillSlug)),
        ),
      ),
    );

    final optedOut = materializeCloudSkillControlTools(
      selectedSkillIds: const {},
      userSkills: const [],
      appSkillSettings: const [],
      isChildConversation: false,
      a2uiSupportedComponents: const {},
    );
    expect(
      optedOut.single.spec.inputJsonSchema['properties'],
      isNot(
        containsPair(
          'slug',
          containsPair('enum', contains(a2uiSkillSlug)),
        ),
      ),
    );
  });

  test(
    'content-only A2UI has no executable cloud tools or readiness inputs',
    () {
      expect(cloudServiceSkillReady(a2uiSkillDefinition, const []), isTrue);
      expect(
        materializeCloudSkillTools(
          selectedSkillIds: const {a2uiSkillSlug},
          appSkillSettings: const [],
          isChildConversation: false,
        ).where((tool) => tool.descriptor.skillSlug == a2uiSkillSlug),
        isEmpty,
      );
    },
  );

  test('builds a content-only A2UI manifest without tools', () async {
    final manifest = await buildCloudSkillManifest(
      slug: a2uiSkillSlug,
      userSkills: const [],
    );

    expect(manifest, isNotNull);
    expect(manifest!.title, a2uiSkillDefinition.title);
    expect(manifest.connectorToolIds, isEmpty);
  });

  test(
    'loads Connector references without Skill credentials or tool specs',
    () async {
      final connector = connectorDefinitions.firstWhere(
        (connector) => connector.tools.any((tool) => tool.requiresConnection),
      );
      final requiredTool = connector.tools.firstWhere(
        (tool) => tool.requiresConnection,
      );
      final toolId = connectorToolId(connector, requiredTool);
      final skill = {
        'id': 'crm-skill',
        'slug': 'crm',
        'title': 'CRM',
        'description': 'Manage CRM records.',
        'content': 'Use OpenAI web search.',
        'connectorToolIds': [toolId],
        'isEnabled': true,
      };

      expect(cloudUserSkillReady(skill, const []), isFalse);
      expect(
        cloudUserSkillReady(skill, [
          {
            'kind': 'customHttp',
            'serviceId': connector.identifier,
            'isEnabled': true,
            'hasSecret': true,
          },
        ]),
        isTrue,
      );
      final manifest = await buildCloudSkillManifest(
        slug: 'crm',
        userSkills: [skill],
      );

      expect(manifest?.connectorToolIds, [toolId]);
      expect(manifest?.toJson(), isNot(contains('tools')));
    },
  );

  test('loading a Skill does not materialize its Connector tools', () {
    final tools = materializeCloudSkillTools(
      selectedSkillIds: const {'crm'},
      appSkillSettings: const [
        {'skillId': agentsSkillSlug, 'isEnabled': false},
      ],
      isChildConversation: false,
    );

    expect(tools, isEmpty);
  });

  test('materializes root sub-agent execution without loading agents', () {
    final rootTools = materializeCloudSkillTools(
      selectedSkillIds: const {},
      appSkillSettings: const [],
      isChildConversation: false,
    );

    expect(
      rootTools.map((tool) => tool.spec.name),
      ['skill__app_native__agents__run_sub_agent'],
    );

    final disabledTools = materializeCloudSkillTools(
      selectedSkillIds: const {},
      appSkillSettings: const [
        {'skillId': agentsSkillSlug, 'isEnabled': false},
      ],
      isChildConversation: false,
    );
    expect(disabledTools, isEmpty);

    final childTools = materializeCloudSkillTools(
      selectedSkillIds: const {agentsSkillSlug},
      appSkillSettings: const [],
      isChildConversation: true,
    );
    expect(childTools, isEmpty);
  });

  test('materializes localized sub-agent guidance with stable schemas', () {
    final tools = materializeCloudSkillTools(
      selectedSkillIds: const {agentsSkillSlug},
      appSkillSettings: const [],
      isChildConversation: false,
      languageCode: 'es-MX',
    );
    final englishTools = materializeCloudSkillTools(
      selectedSkillIds: const {agentsSkillSlug},
      appSkillSettings: const [],
      isChildConversation: false,
      languageCode: 'en',
    );
    final listAgents = tools.singleWhere(
      (tool) => tool.descriptor.toolIdentifier == listAgentsToolName,
    );
    final englishListAgents = englishTools.singleWhere(
      (tool) => tool.descriptor.toolIdentifier == listAgentsToolName,
    );
    final runSubAgent = tools.singleWhere(
      (tool) => tool.descriptor.toolIdentifier == runSubAgentToolName,
    );
    final englishRunSubAgent = englishTools.singleWhere(
      (tool) => tool.descriptor.toolIdentifier == runSubAgentToolName,
    );

    expect(listAgents.spec.name, englishListAgents.spec.name);
    expect(listAgents.spec.description, contains('agentes configurados'));
    expect(
      listAgents.spec.inputJsonSchema,
      englishListAgents.spec.inputJsonSchema,
    );
    expect(runSubAgent.spec.name, englishRunSubAgent.spec.name);
    expect(runSubAgent.spec.description, contains('subagente'));
    expect(
      runSubAgent.spec.inputJsonSchema,
      englishRunSubAgent.spec.inputJsonSchema,
    );
  });

  test('localizes the agents skill manifest instructions', () async {
    final english = await buildCloudSkillManifest(
      slug: agentsSkillSlug,
      userSkills: const [],
      languageCode: 'en',
    );
    final spanish = await buildCloudSkillManifest(
      slug: agentsSkillSlug,
      userSkills: const [],
      languageCode: 'es-MX',
    );

    expect(english, isNotNull);
    expect(spanish, isNotNull);
    expect(spanish!.revision, isNot(english!.revision));
  });

  test('lists only ready user skills in cloud load controls', () {
    final connector = connectorDefinitions.firstWhere(
      (candidate) => candidate.tools.any((tool) => tool.requiresConnection),
    );
    final requiredTool = connector.tools.firstWhere(
      (tool) => tool.requiresConnection,
    );
    final requiredToolId = connectorToolId(connector, requiredTool);
    final controls = materializeCloudSkillControlTools(
      selectedSkillIds: const {},
      userSkills: [
        {'id': 'ready', 'slug': 'ready', 'isEnabled': true},
        {'id': 'disabled', 'slug': 'disabled', 'isEnabled': false},
        {
          'id': 'credentialed',
          'slug': 'credentialed',
          'connectorToolIds': [requiredToolId],
          'isEnabled': true,
        },
      ],
      serviceConnections: [
        {
          'kind': 'customHttp',
          'serviceId': connector.identifier,
          'isEnabled': true,
          'hasSecret': true,
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
    expect(slugs, contains('credentialed'));
  });

  test('does not expose unavailable service Skills', () {
    final service = serviceSkillDefinitions.firstWhere(
      (skill) => skill.connectorToolIds.isNotEmpty,
    );
    final controls = materializeCloudSkillControlTools(
      selectedSkillIds: const {},
      userSkills: const [],
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
    expect(cloudServiceSkillReady(service, const []), isFalse);
  });

  test('does not materialize disabled or child-only cloud skill tools', () {
    final tools = materializeCloudSkillTools(
      selectedSkillIds: {agentsSkillSlug, 'research'},
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
  test('server executes shared Connector commands', () {
    final commands = fixedCloudConnectorCommandTools();

    expect(commands, isNotEmpty);
    expect(
      commands.every(
        (tool) =>
            tool.descriptor.kind == AgentResolvedToolKind.connectorCommand &&
            serverToolIsExecutable(tool.descriptor),
      ),
      isTrue,
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
    final activateSkill = before.singleWhere(
      (tool) => tool.spec.name == activateSkillToolName,
    );
    expect(
      strictToolSchemaIssue(
        Map<String, dynamic>.from(activateSkill.spec.inputJsonSchema),
      ),
      isNull,
    );
  });

  test('cloud exposes Connector commands independently of Skills', () {
    final tools = fixedCloudConnectorCommandTools();

    expect(
      tools.map((tool) => tool.spec.name),
      orderedEquals(buildConnectorCommandToolSpecs().map((spec) => spec.name)),
    );
    expect(
      tools.every(
        (tool) =>
            tool.descriptor.kind == AgentResolvedToolKind.connectorCommand &&
            serverToolIsExecutable(tool.descriptor) &&
            defaultCloudToolPermission(tool.descriptor) ==
                AgentToolPermissionResult.needsConfirmation,
      ),
      isTrue,
    );
  });

  test('Skill references do not change fixed command schemas', () {
    final manifest = SkillManifest(
      slug: 'research',
      title: 'Research',
      description: 'Search sources.',
      revision: 'r1',
      connectorToolIds: const ['connector/openai/web_search'],
    );
    final before = fixedCloudSkillCommandTools();
    final after = fixedCloudSkillCommandTools();

    expect(
      before.map((tool) => tool.spec),
      orderedEquals(after.map((tool) => tool.spec)),
    );
    expect(
      manifest.toJson()['connectorToolIds'],
      ['connector/openai/web_search'],
    );
    expect(before.map((tool) => tool.spec.name), skillCommandToolNames);
    expect(
      before.map((tool) => tool.spec.name),
      isNot(contains('connector/openai/web_search')),
    );
  });
  test(
    'builds deterministic cloud manifest from Connector tool references',
    () async {
      const skills = [
        {
          'id': 'skill-1',
          'slug': 'research',
          'title': 'Research',
          'content': 'Use primary sources.',
          'connectorToolIds': ['connector/openai/web_search'],
          'isEnabled': true,
        },
      ];

      final first = await buildCloudSkillManifest(
        slug: 'research',
        userSkills: skills,
      );
      final second = await buildCloudSkillManifest(
        slug: 'research',
        userSkills: skills,
      );

      expect(first?.revision, second?.revision);
      expect(first?.connectorToolIds, ['connector/openai/web_search']);
      expect(first?.toJson(), isNot(contains('tools')));
    },
  );

  test('agents manifest contains guidance without tool definitions', () async {
    final manifest = await buildCloudSkillManifest(
      slug: agentsSkillSlug,
      userSkills: const [],
    );

    expect(manifest?.connectorToolIds, isEmpty);
    expect(manifest?.toJson(), isNot(contains('tools')));
  });
}
