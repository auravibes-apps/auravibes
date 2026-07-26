import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server/src/features/conversations/engine/conversation_engine_host.dart';
import 'package:auravibes_server/src/features/conversations/engine/conversation_host_effects.dart';
import 'package:auravibes_server/src/features/conversations/engine/server_tool_runtime.dart';
import 'package:auravibes_server/src/features/conversations/repositories/conversation_repository.dart'
    as conversation_repo;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:test/test.dart';

void main() {
  test('resumed jobs retain their originating execution ID', () {
    final payload = conversation_repo.conversationTurnJobPayload(
      'user-1',
      executionId: 'execution-1',
    );

    expect(
      conversation_repo.conversationExecutionIdForJob('decision-1', payload),
      'execution-1',
    );
    expect(
      conversation_repo.conversationExecutionIdForJob('initial-1', null),
      'initial-1',
    );
  });

  test('child jobs retain their originating parent turn ID', () {
    final payload = conversation_repo.conversationTurnJobPayload(
      'user-1',
      executionId: 'execution-1',
      parentTurnId: 42,
    );

    expect(conversation_repo.conversationParentTurnIdForJob(payload), 42);
    expect(
      conversation_repo.conversationParentTurnIdForExecutionSettings(
        '{"parentTurnId":42}',
      ),
      42,
    );
  });

  test('agent permission override cannot bypass a disabled workspace tool', () {
    expect(
      resolveCloudToolPermission(
        workspacePermission: AgentToolPermissionResult.disabledInWorkspace,
        agentPermissionMode: 'alwaysAllow',
      ),
      AgentToolPermissionResult.disabledInWorkspace,
    );
    expect(
      resolveCloudToolPermission(
        workspacePermission: AgentToolPermissionResult.needsConfirmation,
        agentPermissionMode: 'alwaysAllow',
      ),
      AgentToolPermissionResult.granted,
    );
    expect(
      resolveCloudToolPermission(
        workspacePermission: AgentToolPermissionResult.granted,
        agentPermissionMode: 'alwaysDeny',
      ),
      AgentToolPermissionResult.disabledInWorkspace,
    );
  });

  test('disabled cloud tools and tool groups are unavailable', () {
    expect(
      isCloudToolEnabled(
        toolData: const {'isEnabled': false},
        toolGroupData: const {'isEnabled': true},
      ),
      isFalse,
    );
    expect(
      isCloudToolEnabled(
        toolData: const {'isEnabled': true},
        toolGroupData: const {'isEnabled': false},
      ),
      isFalse,
    );
    expect(
      isCloudToolEnabled(
        toolData: const {'isEnabled': true},
        toolGroupData: const {'isEnabled': true},
      ),
      isTrue,
    );
  });

  test('conversation-selected skills provide context without an agent', () {
    expect(
      buildCloudSkillContextMessages(
        conversationSkills: const [
          AgentSkill(title: 'Research', content: 'Use primary sources.'),
        ],
        agentSkills: const [],
      ),
      [
        {
          'role': 'user',
          'content':
              '<skill><name>Research</name><content>Use primary sources.</content></skill>',
        },
      ],
    );
  });

  test('refresh retains all completed tool exchanges in order', () {
    final firstExchange = <Map<String, dynamic>>[
      {
        'role': 'assistant',
        'content': null,
        'tool_calls': const [
          {
            'id': 'call-1',
            'type': 'function',
            'function': {'name': 'first', 'arguments': '{}'},
          },
        ],
      },
      {'role': 'tool', 'tool_call_id': 'call-1', 'content': 'first-result'},
    ];
    final secondExchange = <Map<String, dynamic>>[
      {
        'role': 'assistant',
        'content': null,
        'tool_calls': const [
          {
            'id': 'call-2',
            'type': 'function',
            'function': {'name': 'second', 'arguments': '{}'},
          },
        ],
      },
      {'role': 'tool', 'tool_call_id': 'call-2', 'content': 'second-result'},
    ];

    expect(
      cloudRequestMessagesWithToolExchanges(
        baseMessages: const [
          {'role': 'user', 'content': 'Find both answers.'},
        ],
        toolExchanges: [...firstExchange, ...secondExchange],
      ),
      [
        {'role': 'user', 'content': 'Find both answers.'},
        ...firstExchange,
        ...secondExchange,
      ],
    );
  });

  test(
    'resume preserves provider tool-call batch order and assistant text',
    () {
      final now = DateTime(2026);
      final assistant = ConversationMessage(
        id: 1,
        workspaceId: 1,
        conversationId: 1,
        turnId: 1,
        stableId: 'assistant-1',
        role: 'assistant',
        kind: 'text',
        status: 'awaitingApproval',
        content: '',
        metadataJson:
            '{"providerToolBatches":['
            '{"assistant":{"role":"assistant","content":"A text",'
            '"tool_calls":[{"id":"call-a","type":"function",'
            '"function":{"name":"a","arguments":"{}"}}]},'
            '"toolCallIds":["call-a"]},'
            '{"assistant":{"role":"assistant","content":"B text",'
            '"tool_calls":[{"id":"call-b","type":"function",'
            '"function":{"name":"b","arguments":"{}"}}]},'
            '"toolCallIds":["call-b"]}]}',
        revision: 1,
        createdAt: now,
        updatedAt: now,
      );
      ConversationToolCall call(String id, String name, String result) =>
          ConversationToolCall(
            workspaceId: 1,
            conversationId: 1,
            turnId: 1,
            messageId: 1,
            stableId: id,
            name: name,
            argumentsJson: '{}',
            argumentsDigest: '$id-digest',
            status: 'success',
            resultJson: result,
            revision: 1,
            createdAt: now,
            updatedAt: now,
          );

      expect(
        persistedProviderToolExchanges(
          messages: [assistant],
          calls: [
            call('call-a', 'a', 'a-result'),
            // B has been approved and completed when the job resumes.
            call('call-b', 'b', 'b-result'),
          ],
        ),
        [
          {
            'role': 'assistant',
            'content': 'A text',
            'tool_calls': [
              {
                'id': 'tool_63_61_6c_6c_2d_61',
                'type': 'function',
                'function': {'name': 'a', 'arguments': '{}'},
              },
            ],
          },
          {
            'role': 'tool',
            'tool_call_id': 'tool_63_61_6c_6c_2d_61',
            'content': 'a-result',
          },
          {
            'role': 'assistant',
            'content': 'B text',
            'tool_calls': [
              {
                'id': 'tool_63_61_6c_6c_2d_62',
                'type': 'function',
                'function': {'name': 'b', 'arguments': '{}'},
              },
            ],
          },
          {
            'role': 'tool',
            'tool_call_id': 'tool_63_61_6c_6c_2d_62',
            'content': 'b-result',
          },
        ],
      );
    },
  );

  test(
    'all-denied continuation includes the original tool call and denial',
    () {
      const toolCall = {
        'id': 'call-denied',
        'type': 'function',
        'function': {'name': 'tool', 'arguments': '{}'},
      };

      expect(
        cloudRequestMessagesWithToolExchanges(
          baseMessages: const [
            {'role': 'user', 'content': 'Continue.'},
          ],
          toolExchanges: const [
            {
              'role': 'assistant',
              'content': null,
              'tool_calls': [toolCall],
            },
            {
              'role': 'tool',
              'tool_call_id': 'call-denied',
              'content': 'denied',
            },
          ],
        ),
        [
          {'role': 'user', 'content': 'Continue.'},
          {
            'role': 'assistant',
            'content': null,
            'tool_calls': [toolCall],
          },
          {
            'role': 'tool',
            'tool_call_id': 'call-denied',
            'content': 'denied',
          },
        ],
      );
    },
  );

  test('disabled app settings exclude selected app skill context', () {
    expect(
      cloudAppSkillEnabled(
        agentsSkillSlug,
        const [
          {'skillId': agentsSkillSlug, 'isEnabled': false},
        ],
      ),
      isFalse,
    );
    final service = serviceSkillDefinitions.first;
    expect(
      cloudServiceSkillReady(
        service,
        const [
          {
            'kind': 'appSkillCredential',
            'serviceId': 'unrelated',
            'isEnabled': true,
            'hasSecret': true,
          },
        ],
      ),
      service.nativeTools.every((tool) => !tool.requiresCredential),
    );
  });

  test('selected app skills contribute their declared context', () {
    final service = serviceSkillDefinitions.first;

    expect(
      cloudAppSkillsForIds([
        agentsSkillSlug,
        service.identifier,
      ]).map((skill) => (skill.title, skill.content, skill.identity)),
      [
        (agentsSkillTitle, agentsSkillContent, agentsSkillSlug),
        (service.title, service.content, service.identifier),
      ],
    );
  });

  test('configuration exception exposes only safe code', () {
    const error = ConversationEngineConfigurationException('provider_secret');

    expect(error.code, 'provider_secret');
    expect(error.toString(), isNot(contains('api')));
  });

  test('provider stream stops before yielding chunk after cancellation', () {
    var checks = 0;
    final stream = cancellationCheckedStream(
      Stream.fromIterable([1, 2, 3]),
      () async => ++checks == 2,
    );

    expect(
      stream,
      emitsInOrder([1, emitsError(isA<ConversationCancelledException>())]),
    );
  });

  test('fallback title is stable and bounded', () {
    expect(fallbackConversationTitle('  hello   world  '), 'hello world');
    expect(fallbackConversationTitle('a' * 40), '${'a' * 27}...');
  });

  test('Codex provider consumes OAuth access token JSON', () {
    expect(
      providerCredential('openai-codex', '{"access_token":"oauth-token"}'),
      'oauth-token',
    );
    expect(
      () => providerCredential('openai-codex', '{"refresh_token":"token"}'),
      throwsA(isA<ConversationEngineConfigurationException>()),
    );
  });

  test('provider request URI retains the configured API base path', () {
    expect(
      providerRequestUri('openai', Uri.parse('https://api.openai.com/v1')),
      Uri.parse('https://api.openai.com/v1/chat/completions'),
    );
    expect(
      providerRequestUri(
        'openai-codex',
        Uri.parse('https://chatgpt.com/backend-api/codex/'),
      ),
      Uri.parse('https://chatgpt.com/backend-api/codex/responses'),
    );
  });
}
