import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server/src/features/conversations/engine/conversation_engine_host.dart';
import 'package:auravibes_server/src/features/conversations/engine/conversation_host_effects.dart';
import 'package:auravibes_server/src/features/conversations/engine/server_tool_executor.dart';
import 'package:auravibes_server/src/features/conversations/engine/server_tool_runtime.dart';
import 'package:auravibes_server/src/features/conversations/domain/conversation_values.dart';
import 'package:auravibes_server/src/features/conversations/repositories/conversation_repository.dart'
    as conversation_repo;
import 'package:auravibes_server/src/features/conversations/usecases/conversation_usecases.dart';
import 'package:auravibes_server/src/features/conversations/workers/conversation_worker.dart';
import 'package:auravibes_server/src/features/model_connections/domain/virtual_workspace_model_selection.dart';
import 'package:auravibes_server/src/features/workspace_state/domain/workspace_resource_validation.dart';
import 'package:auravibes_server/src/features/workspace_state/workspace_secret_cipher.dart';
import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('ConversationEngineHostRegression', (
    sessionBuilder,
    endpoints,
  ) {
    Future<_Fixture> prepare() async {
      final userId = const Uuid().v4().toString();
      final session = sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          userId,
          const {},
        ),
      );
      final database = session.build();
      await AuthUser.db.insertRow(
        database,
        AuthUser(id: UuidValue.fromString(userId), scopeNames: const {}),
      );
      await EmailAccount.db.insertRow(
        database,
        EmailAccount(
          authUserId: UuidValue.fromString(userId),
          email: '$userId@example.com',
          passwordHash: 'unused',
        ),
      );
      final workspace = await workspace_repo.CloudWorkspaceRepository()
          .createWorkspace(
            database,
            name: 'Workspace',
            ownerUserId: userId,
            now: DateTime.now().toUtc(),
          );
      final now = DateTime.now().toUtc();
      final conversation = await Conversation.db.insertRow(
        database,
        Conversation(
          workspaceId: workspace.id!,
          stableId: 'conversation-1',
          title: 'Conversation',
          isPinned: false,
          revision: 1,
          projectionRevision: 1,
          eventSequence: 0,
          executionState: 'idle',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await endpoints.conversation.queueConversationMessage(
        session,
        QueueConversationMessageRequest(
          workspaceId: workspace.id!,
          requestId: 'queue-1',
          conversationId: conversation.stableId,
          expectedProjectionRevision: 1,
          clientMessageId: 'message-1',
          content: 'Continue.',
          attachmentIds: const [],
        ),
      );
      await endpoints.conversation.continueConversation(
        session,
        ContinueConversationRequest(
          workspaceId: workspace.id!,
          requestId: 'continue-1',
          conversationId: conversation.stableId,
          expectedProjectionRevision: 2,
        ),
      );
      final turn = (await ConversationTurn.db.findFirstRow(
        database,
        where: (table) =>
            table.workspaceId.equals(workspace.id) &
            table.conversationId.equals(conversation.id),
      ))!;
      final job = (await ConversationJob.db.findFirstRow(
        database,
        where: (table) => table.turnId.equals(turn.id),
      ))!;
      final messages = await ConversationMessage.db.find(
        database,
        where: (table) => table.conversationId.equals(conversation.id),
        orderBy: (table) => table.id,
      );
      return _Fixture(
        session: session,
        database: database,
        userId: userId,
        workspaceId: workspace.id!,
        conversationId: conversation.id!,
        turn: turn,
        job: job,
        messages: messages,
      );
    }

    Future<void> configureProvider(_Fixture fixture) async {
      final now = DateTime.now().toUtc();
      await WorkspaceModelConnection.db.insertRow(
        fixture.database,
        WorkspaceModelConnection(
          workspaceId: fixture.workspaceId,
          connectionId: 'connection-1',
          providerId: 'openai',
          name: 'Provider',
          url: 'https://provider.test/v1',
          hasSecret: true,
          revision: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await ApiModel.db.insertRow(
        fixture.database,
        ApiModel(
          providerId: 'openai',
          modelId: 'model-1',
          name: 'Model',
          limitContext: 1,
          limitOutput: 1,
          modalitiesInput: const ['text'],
          modalitiesOutput: const ['text'],
          costInput: 0,
          costCacheRead: 0,
          costOutput: 0,
          openWeights: false,
          supportsReasoning: false,
          isCanonical: true,
          supportsPriorityMode: false,
          supportsToolCalls: true,
          createdAt: now,
          updatedAt: now,
        ),
      );
      final encrypted = await const WorkspaceSecretCipher().encrypt(
        fixture.database,
        'test-secret',
        workspaceId: fixture.workspaceId,
        resourceId: 'connection-1',
      );
      await WorkspaceSecret.db.insertRow(
        fixture.database,
        WorkspaceSecret(
          workspaceId: fixture.workspaceId,
          secretKind: WorkspaceSecretKind.provider,
          scope: WorkspaceSecretScope.user,
          ownerUserId: WorkspaceResourceValidation.secretOwnerKey(
            WorkspaceSecretScope.user,
            fixture.userId,
          ),
          resourceId: 'connection-1',
          ciphertext: encrypted.ciphertext,
          nonce: encrypted.nonce,
          authenticationTag: encrypted.authenticationTag,
          algorithm: 'AES-256-GCM',
          keyVersion: 1,
          revision: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );
      final user = fixture.messages.singleWhere(
        (message) => message.role == 'user',
      );
      await ConversationMessage.db.updateRow(
        fixture.database,
        user.copyWith(
          metadataJson: jsonEncode({
            'modelSelectionId': VirtualWorkspaceModelSelectionId.encode(
              connectionId: 'connection-1',
              modelId: 'model-1',
            ),
          }),
        ),
      );
      fixture.messages = await ConversationMessage.db.find(
        fixture.database,
        where: (table) => table.conversationId.equals(fixture.conversationId),
        orderBy: (table) => table.id,
      );
    }

    test(
      'resumed all-denied calls are sent to the provider as a terminal exchange',
      () async {
        final fixture = await prepare();
        await configureProvider(fixture);
        final assistant = fixture.messages.singleWhere(
          (message) => message.id == fixture.turn.assistantMessageId,
        );
        final now = DateTime.now().toUtc();
        await ConversationToolCall.db.insertRow(
          fixture.database,
          ConversationToolCall(
            workspaceId: fixture.workspaceId,
            conversationId: fixture.conversationId,
            turnId: fixture.turn.id!,
            messageId: assistant.id!,
            stableId: 'call-denied',
            name: 'tool',
            argumentsJson: '{}',
            argumentsDigest: 'digest',
            status: 'denied',
            decision: 'deny',
            resultJson: '{"error":"Tool approval was denied."}',
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        final requests = <Map<String, dynamic>>[];
        final host = ServerConversationEngineHost(
          admissionGate: const _ImmediateAdmissionGate(),
          lookup: (_) async => [InternetAddress('8.8.8.8')],
          providerTransport: (body) async {
            requests.add(body);
            return ProviderTransportResponse(
              statusCode: 200,
              body: Stream.value(
                utf8.encode(
                  'data: {"id":"response","choices":[{"delta":{"content":"Done"},"finish_reason":"stop"}],"usage":{"prompt_tokens":1,"completion_tokens":1,"total_tokens":2}}\n\n'
                  'data: [DONE]\n\n',
                ),
              ),
            );
          },
        );

        await host.executeTurn(
          fixture.database,
          job: fixture.job,
          turn: fixture.turn,
          messages: fixture.messages,
          liveTurns: const _NoopProgressPublisher(),
        );

        final messages = requests.single['messages'] as List;
        expect(
          messages,
          contains(
            {
              'role': 'assistant',
              'content': null,
              'tool_calls': [
                {
                  'id': 'call-denied',
                  'type': 'function',
                  'function': {'name': 'tool', 'arguments': '{}'},
                },
              ],
            },
          ),
        );
        expect(
          messages,
          contains(
            {
              'role': 'tool',
              'tool_call_id': 'call-denied',
              'content': '{"error":"Tool approval was denied."}',
            },
          ),
        );
      },
    );

    test(
      'skill load state does not change provider tool schemas',
      () async {
        final fixture = await prepare();
        final now = DateTime.now().toUtc();
        await WorkspaceResource.db.insertRow(
          fixture.database,
          WorkspaceResource(
            workspaceId: fixture.workspaceId,
            resourceKind: WorkspaceResourceKind.skill,
            resourceId: 'research',
            data: jsonEncode({'slug': 'research', 'isEnabled': true}),
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await WorkspaceResource.db.insertRow(
          fixture.database,
          WorkspaceResource(
            workspaceId: fixture.workspaceId,
            resourceKind: WorkspaceResourceKind.skillTemplateTool,
            resourceId: 'research-search',
            data: jsonEncode({
              'skillId': 'research',
              'skillSlug': 'research',
              'toolSlug': 'search',
              'isEnabled': true,
              'requiresCredential': false,
              'inputsJson': '[]',
              'templateJson': '{}',
            }),
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        final runtime = ServerToolRuntime();
        final controls = await runtime.loadTools(
          fixture.database,
          workspaceId: fixture.workspaceId,
          conversationStableId: 'conversation-1',
        );
        final load = controls.singleWhere(
          (tool) => tool.spec.name == loadSkillToolName,
        );

        final beforeSpecs = [for (final tool in controls) tool.spec];
        final result = await const ServerToolExecutorService().call(
          fixture.database,
          fixture.turn,
          load,
          const ServerToolRequest(
            id: 'load-research',
            name: loadSkillToolName,
            arguments: {'slug': 'research'},
          ),
        );

        expect(result, {'skillId': 'research', 'selected': true});
        expect(
          await WorkspaceResource.db.findFirstRow(
            fixture.database,
            where: (table) =>
                table.workspaceId.equals(fixture.workspaceId) &
                table.resourceKind.equals(
                  WorkspaceResourceKind.conversationSkillSelection,
                ) &
                table.resourceId.equals('conversation-1:research'),
          ),
          isNotNull,
        );
        final selectedTools = await runtime.loadTools(
          fixture.database,
          workspaceId: fixture.workspaceId,
          conversationStableId: 'conversation-1',
        );
        expect([for (final tool in selectedTools) tool.spec], beforeSpecs);
        expect(
          selectedTools.map((tool) => tool.spec.name),
          containsAll(skillCommandToolNames),
        );
        expect(
          selectedTools.any((tool) => tool.spec.name.startsWith('skill__')),
          isFalse,
        );
      },
    );

    test(
      'historical direct skill call replays without exposing its schema',
      () async {
        final fixture = await prepare();
        final assistant = fixture.messages.singleWhere(
          (message) => message.id == fixture.turn.assistantMessageId,
        );
        final now = DateTime.now().toUtc();
        Future<void> insert(
          WorkspaceResourceKind kind,
          String id,
          Map<String, Object?> data,
        ) => WorkspaceResource.db
            .insertRow(
              fixture.database,
              WorkspaceResource(
                workspaceId: fixture.workspaceId,
                resourceKind: kind,
                resourceId: id,
                data: jsonEncode(data),
                revision: 1,
                createdAt: now,
                updatedAt: now,
              ),
            )
            .then((_) {});
        await insert(WorkspaceResourceKind.skill, 'research', const {
          'id': 'research',
          'slug': 'research',
          'title': 'Research',
          'content': 'Search primary sources.',
          'isEnabled': true,
        });
        await insert(
          WorkspaceResourceKind.skillTemplateTool,
          'research-search',
          const {
            'id': 'research-search',
            'skillId': 'research',
            'skillSlug': 'research',
            'toolSlug': 'search',
            'description': 'Search.',
            'isEnabled': true,
            'requiresCredential': false,
            'inputsJson': '[]',
            'templateJson': '{}',
          },
        );
        await insert(
          WorkspaceResourceKind.conversationSkillSelection,
          'conversation-1:research',
          const {'conversationId': 'conversation-1', 'skillId': 'research'},
        );
        await insert(
          WorkspaceResourceKind.toolPermission,
          'research-search-permission',
          const {
            'toolId': 'research-search',
            'permissionMode': 'alwaysAllow',
            'isEnabled': true,
          },
        );
        await ConversationToolCall.db.insertRow(
          fixture.database,
          ConversationToolCall(
            workspaceId: fixture.workspaceId,
            conversationId: fixture.conversationId,
            turnId: fixture.turn.id!,
            messageId: assistant.id!,
            stableId: 'historical-direct-call',
            name: 'skill__user__research__search',
            argumentsJson: '{}',
            argumentsDigest: 'historical',
            status: 'approved',
            decision: 'approve',
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        var executions = 0;
        final runtime = ServerToolRuntime(
          executor: (_, _, tool, request) async {
            executions++;
            expect(tool.descriptor.toolIdentifier, 'search');
            expect(request.id, 'historical-direct-call');
            return {'ok': true};
          },
        );

        final advertised = await runtime.loadTools(
          fixture.database,
          workspaceId: fixture.workspaceId,
          conversationStableId: 'conversation-1',
        );
        expect(
          advertised.any((tool) => tool.spec.name.startsWith('skill__')),
          isFalse,
        );
        await runtime.handle(
          fixture.database,
          turn: fixture.turn,
          messageId: assistant.id!,
          request: const ServerToolRequest(
            id: 'historical-direct-call',
            name: 'skill__user__research__search',
            arguments: {},
          ),
        );

        final persisted = await ConversationToolCall.db.findFirstRow(
          fixture.database,
          where: (table) => table.stableId.equals('historical-direct-call'),
        );
        expect(executions, 1);
        expect(persisted?.status, 'success');
        expect(persisted?.resultJson, contains('ok'));
      },
    );

    test(
      'unloaded tool is terminally unavailable before its stale descriptor executes',
      () async {
        final fixture = await prepare();
        final assistant = fixture.messages.singleWhere(
          (message) => message.id == fixture.turn.assistantMessageId,
        );
        final now = DateTime.now().toUtc();
        final call = await ConversationToolCall.db.insertRow(
          fixture.database,
          ConversationToolCall(
            workspaceId: fixture.workspaceId,
            conversationId: fixture.conversationId,
            turnId: fixture.turn.id!,
            messageId: assistant.id!,
            stableId: 'call-approved',
            name: 'tool',
            argumentsJson: '{}',
            argumentsDigest: 'digest',
            status: 'approved',
            decision: 'approve',
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        final tool = await WorkspaceResource.db.insertRow(
          fixture.database,
          WorkspaceResource(
            workspaceId: fixture.workspaceId,
            resourceKind: WorkspaceResourceKind.tool,
            resourceId: 'server-1',
            data: jsonEncode({
              'name': 'mcp_server-1_server_tool',
              'isEnabled': true,
            }),
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        final advertised = (await ServerToolRuntime().loadTools(
          fixture.database,
          workspaceId: fixture.workspaceId,
          conversationStableId: 'conversation-1',
        )).single;
        await WorkspaceResource.db.updateRow(
          fixture.database,
          tool.copyWith(deletedAt: DateTime.now().toUtc()),
        );
        var executions = 0;
        final runtime = ServerToolRuntime(
          executor: (_, _, _, _) async {
            executions++;
            return {'unexpected': true};
          },
        );

        await runtime.handle(
          fixture.database,
          turn: fixture.turn,
          messageId: assistant.id!,
          request: ServerToolRequest(
            id: 'call-approved',
            name: advertised.spec.name,
            arguments: {},
          ),
        );

        final resolved = (await ConversationToolCall.db.findById(
          fixture.database,
          call.id!,
        ))!;
        expect(executions, 0);
        expect(resolved.status, 'toolNotFound');
        expect(resolved.resultJson, contains('no longer available'));
      },
    );

    test(
      'unloaded dispatched skill is rejected before executor side effects',
      () async {
        final fixture = await prepare();
        final assistant = fixture.messages.singleWhere(
          (message) => message.id == fixture.turn.assistantMessageId,
        );
        var executions = 0;
        final runtime = ServerToolRuntime(
          executor: (_, _, _, _) async {
            executions++;
            return {'unexpected': true};
          },
        );

        expect(
          await runtime.handle(
            fixture.database,
            turn: fixture.turn,
            messageId: assistant.id!,
            request: const ServerToolRequest(
              id: 'call-unloaded-skill',
              name: callSkillToolName,
              arguments: {
                'skill': 'research',
                'tool': 'search',
                'args': <String, Object?>{},
                'revision': 'stale',
              },
            ),
          ),
          ServerToolDisposition.completed,
        );

        final call = await ConversationToolCall.db.findFirstRow(
          fixture.database,
          where: (table) => table.stableId.equals('call-unloaded-skill'),
        );
        expect(executions, 0);
        expect(call?.status, 'executionError');
        expect(call?.resultJson, contains('not loaded'));
      },
    );

    test(
      'dispatched skill uses underlying denied permission before execution',
      () async {
        final fixture = await prepare();
        final assistant = fixture.messages.singleWhere(
          (message) => message.id == fixture.turn.assistantMessageId,
        );
        final now = DateTime.now().toUtc();
        const skill = {
          'id': 'research',
          'slug': 'research',
          'title': 'Research',
          'content': 'Search primary sources.',
          'isEnabled': true,
        };
        const template = {
          'id': 'research-search',
          'skillId': 'research',
          'skillSlug': 'research',
          'toolSlug': 'search',
          'description': 'Search.',
          'isEnabled': true,
          'requiresCredential': false,
          'inputsJson': '[]',
          'templateJson': '{}',
        };
        Future<void> insert(
          WorkspaceResourceKind kind,
          String id,
          Map<String, Object?> data,
        ) => WorkspaceResource.db
            .insertRow(
              fixture.database,
              WorkspaceResource(
                workspaceId: fixture.workspaceId,
                resourceKind: kind,
                resourceId: id,
                data: jsonEncode(data),
                revision: 1,
                createdAt: now,
                updatedAt: now,
              ),
            )
            .then((_) {});
        await insert(WorkspaceResourceKind.skill, 'research', skill);
        await insert(
          WorkspaceResourceKind.skillTemplateTool,
          'research-search',
          template,
        );
        await insert(
          WorkspaceResourceKind.conversationSkillSelection,
          'conversation-1:research',
          const {'conversationId': 'conversation-1', 'skillId': 'research'},
        );
        await insert(
          WorkspaceResourceKind.toolPermission,
          'research-search-permission',
          const {
            'toolId': 'research-search',
            'permissionMode': 'alwaysDeny',
            'isEnabled': true,
          },
        );
        final tools = materializeCloudSkillTools(
          selectedSkillIds: const {'research'},
          userSkills: const [skill],
          templateTools: const [template],
          appSkillSettings: const [],
          isChildConversation: false,
        );
        final manifest = await buildCloudSkillManifest(
          slug: 'research',
          userSkills: const [skill],
          tools: tools,
        );
        var executions = 0;

        await ServerToolRuntime(
          executor: (_, _, _, _) async {
            executions++;
            return {'unexpected': true};
          },
        ).handle(
          fixture.database,
          turn: fixture.turn,
          messageId: assistant.id!,
          request: ServerToolRequest(
            id: 'call-denied-skill',
            name: callSkillToolName,
            arguments: {
              'skill': 'research',
              'tool': 'search',
              'args': <String, Object?>{},
              'revision': manifest!.revision,
            },
          ),
        );

        final call = await ConversationToolCall.db.findFirstRow(
          fixture.database,
          where: (table) => table.stableId.equals('call-denied-skill'),
        );
        expect(executions, 0);
        expect(
          call?.status,
          AgentToolPermissionResult.disabledInWorkspace.name,
        );
      },
    );

    test(
      'approved dispatched skill resumes with authoritative nested arguments',
      () async {
        final fixture = await prepare();
        final assistant = fixture.messages.singleWhere(
          (message) => message.id == fixture.turn.assistantMessageId,
        );
        final now = DateTime.now().toUtc();
        Future<void> insert(
          WorkspaceResourceKind kind,
          String id,
          Map<String, Object?> data,
        ) => WorkspaceResource.db
            .insertRow(
              fixture.database,
              WorkspaceResource(
                workspaceId: fixture.workspaceId,
                resourceKind: kind,
                resourceId: id,
                data: jsonEncode(data),
                revision: 1,
                createdAt: now,
                updatedAt: now,
              ),
            )
            .then((_) {});
        const skill = {
          'id': 'research',
          'slug': 'research',
          'title': 'Research',
          'content': 'Search primary sources.',
          'isEnabled': true,
        };
        const template = {
          'id': 'research-search',
          'skillId': 'research',
          'skillSlug': 'research',
          'toolSlug': 'search',
          'description': 'Search.',
          'isEnabled': true,
          'requiresCredential': false,
          'inputsJson': '[{"name":"query","type":"string","required":true}]',
          'templateJson': '{"url":"https://example.com?q={{query}}"}',
        };
        await insert(WorkspaceResourceKind.skill, 'research', skill);
        await insert(
          WorkspaceResourceKind.skillTemplateTool,
          'research-search',
          template,
        );
        await insert(
          WorkspaceResourceKind.conversationSkillSelection,
          'conversation-1:research',
          const {'conversationId': 'conversation-1', 'skillId': 'research'},
        );
        final tools = materializeCloudSkillTools(
          selectedSkillIds: const {'research'},
          userSkills: const [skill],
          templateTools: const [template],
          appSkillSettings: const [],
          isChildConversation: false,
        );
        final manifest = await buildCloudSkillManifest(
          slug: 'research',
          userSkills: const [skill],
          tools: tools,
        );
        final wrapperArguments = {
          'skill': 'research',
          'tool': 'search',
          'args': <String, Object?>{'query': 'nested query'},
          'revision': manifest!.revision,
        };
        Map<String, dynamic>? executedArguments;
        var executorInvocations = 0;
        final executorEntered = Completer<void>();
        final releaseExecutor = Completer<void>();
        final runtime = ServerToolRuntime(
          executor: (_, _, tool, request) async {
            executorInvocations++;
            expect(tool.descriptor.fullName, 'skill__user__research__search');
            executedArguments = request.arguments;
            if (!executorEntered.isCompleted) executorEntered.complete();
            await releaseExecutor.future;
            return {'ok': true};
          },
        );

        expect(
          await runtime.handle(
            fixture.database,
            turn: fixture.turn,
            messageId: assistant.id!,
            request: ServerToolRequest(
              id: 'approved-nested-args',
              name: callSkillToolName,
              arguments: wrapperArguments,
            ),
          ),
          ServerToolDisposition.awaitingApproval,
        );
        final pending = (await ConversationToolCall.db.findFirstRow(
          fixture.database,
          where: (table) => table.stableId.equals('approved-nested-args'),
        ))!;
        expect(pending.name, 'skill__user__research__search');
        expect(jsonDecode(pending.argumentsJson), wrapperArguments);
        await ConversationToolCall.db.updateRow(
          fixture.database,
          pending.copyWith(
            status: 'approved',
            decision: 'approve',
            updatedAt: DateTime.now().toUtc(),
          ),
        );

        final firstResume = runtime.handle(
          fixture.database,
          turn: fixture.turn,
          messageId: assistant.id!,
          request: ServerToolRequest(
            id: 'approved-nested-args',
            name: callSkillToolName,
            arguments: wrapperArguments,
          ),
        );
        await executorEntered.future;
        final losingResume = await runtime.handle(
          fixture.database,
          turn: fixture.turn,
          messageId: assistant.id!,
          request: ServerToolRequest(
            id: 'approved-nested-args',
            name: callSkillToolName,
            arguments: wrapperArguments,
          ),
        );
        expect(losingResume, ServerToolDisposition.completed);
        expect(executorInvocations, 1);
        releaseExecutor.complete();
        await firstResume;

        expect(executedArguments, {'query': 'nested query'});

        expect(executorInvocations, 1);
        final completed = await ConversationToolCall.db.findFirstRow(
          fixture.database,
          where: (table) => table.stableId.equals('approved-nested-args'),
        );
        expect(completed?.status, 'success');
      },
    );

    test(
      'durable cancellation before executor invocation prevents side effects',
      () async {
        final fixture = await prepare();
        final assistant = fixture.messages.singleWhere(
          (message) => message.id == fixture.turn.assistantMessageId,
        );
        final now = DateTime.now().toUtc();
        await WorkspaceResource.db.insertRow(
          fixture.database,
          WorkspaceResource(
            workspaceId: fixture.workspaceId,
            resourceKind: WorkspaceResourceKind.tool,
            resourceId: 'server-1',
            data: jsonEncode({
              'name': 'mcp_server-1_server_tool',
              'isEnabled': true,
            }),
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        final advertised = (await ServerToolRuntime().loadTools(
          fixture.database,
          workspaceId: fixture.workspaceId,
          conversationStableId: 'conversation-1',
        )).single;
        final cancellation = _BlockedCancellationProbe();
        var executions = 0;
        final runtime = ServerToolRuntime(
          cancellationProbe: cancellation,
          executor: (_, _, _, _) async {
            executions++;
            return {'unexpected': true};
          },
        );

        final handling = runtime.handle(
          fixture.database,
          turn: fixture.turn,
          messageId: assistant.id!,
          request: ServerToolRequest(
            id: 'cancelled-before-executor',
            name: advertised.spec.name,
            arguments: {},
          ),
        );
        await cancellation.entered.future.timeout(const Duration(seconds: 2));
        await ConversationTurn.db.updateRow(
          fixture.database,
          fixture.turn.copyWith(
            cancellationRequestedAt: DateTime.now().toUtc(),
          ),
        );
        cancellation.release.complete();

        await expectLater(
          handling,
          throwsA(isA<ConversationCancelledException>()),
        );
        expect(executions, 0);
      },
    );

    test(
      'cancellation while creating a child removes its queued child artifacts',
      () async {
        final fixture = await prepare();
        final entered = Completer<void>();
        final release = Completer<void>();
        final parentTool = ServerResolvedTool(
          descriptor: AgentResolvedToolName.skillNative(
            tableId: runSubAgentToolName,
            skillSlug: agentsSkillSlug,
            toolIdentifier: runSubAgentToolName,
          ),
          spec: ToolSpec(
            name: 'skill__app__agents__$runSubAgentToolName',
            description: '',
            inputJsonSchema: const {},
          ),
        );
        final handling =
            ServerToolExecutorService(
              beforeChildLaunch: () async {
                entered.complete();
                await release.future;
              },
            ).call(
              fixture.database,
              fixture.turn,
              parentTool,
              const ServerToolRequest(
                id: 'cancel-during-child-launch',
                name: 'skill__app__agents__run_sub_agent',
                arguments: {'title': 'Child', 'prompt': 'Do the work.'},
              ),
            );
        await entered.future.timeout(const Duration(seconds: 2));
        await ConversationUseCases(
          conversation_repo.ConversationRepository(),
          publishConversationJob: (_, _) async {},
        ).cancelTurn(
          fixture.database,
          userId: fixture.userId,
          request: CancelTurnRequest(
            workspaceId: fixture.workspaceId,
            requestId: 'cancel-parent-during-child-launch',
            turnId: fixture.turn.requestId,
            expectedTurnRevision: fixture.turn.revision,
          ),
        );
        release.complete();

        await expectLater(
          handling,
          throwsA(isA<ConversationCancelledException>()),
        );
        final child = (await Conversation.db.findFirstRow(
          fixture.database,
          where: (table) =>
              table.workspaceId.equals(fixture.workspaceId) &
              table.parentConversationStableId.equals('conversation-1'),
        ))!;
        expect(child.deletedAt, isNotNull);
        expect(
          await ConversationMessage.db.find(
            fixture.database,
            where: (table) => table.conversationId.equals(child.id),
          ),
          isEmpty,
        );
        expect(
          await ConversationJob.db.find(
            fixture.database,
            where: (table) => table.conversationId.equals(child.id),
          ),
          isEmpty,
        );
      },
    );

    test(
      'a second worker retires a continued child when its parent is cancelled',
      () async {
        final fixture = await prepare();
        final continued = Completer<void>();
        final release = Completer<void>();
        final parentTool = ServerResolvedTool(
          descriptor: AgentResolvedToolName.skillNative(
            tableId: runSubAgentToolName,
            skillSlug: agentsSkillSlug,
            toolIdentifier: runSubAgentToolName,
          ),
          spec: ToolSpec(
            name: 'skill__app__agents__$runSubAgentToolName',
            description: '',
            inputJsonSchema: const {},
          ),
        );
        final handling =
            ServerToolExecutorService(
              afterChildContinuation: () async {
                continued.complete();
                await release.future;
              },
            ).call(
              fixture.database,
              fixture.turn,
              parentTool,
              const ServerToolRequest(
                id: 'cancel-after-child-continuation',
                name: 'skill__app__agents__run_sub_agent',
                arguments: {'title': 'Child', 'prompt': 'Do the work.'},
              ),
            );
        await continued.future.timeout(const Duration(seconds: 2));
        await ConversationUseCases(
          conversation_repo.ConversationRepository(),
          publishConversationJob: (_, _) async {},
        ).cancelTurn(
          fixture.database,
          userId: fixture.userId,
          request: CancelTurnRequest(
            workspaceId: fixture.workspaceId,
            requestId: 'cancel-parent-after-child-continuation',
            turnId: fixture.turn.requestId,
            expectedTurnRevision: fixture.turn.revision,
          ),
        );

        final effects = _EffectTrackingHost();
        await runConversationWorker(
          fixture.database,
          isActive: () => true,
          worker: ConversationWorker(host: effects),
        );
        final child = (await Conversation.db.findFirstRow(
          fixture.database,
          where: (table) =>
              table.workspaceId.equals(fixture.workspaceId) &
              table.parentConversationStableId.equals('conversation-1'),
        ))!;
        final execution = (await ConversationExecution.db.findFirstRow(
          fixture.database,
          where: (table) => table.conversationId.equals(child.id),
        ))!;
        final childTurn = (await ConversationTurn.db.findFirstRow(
          fixture.database,
          where: (table) => table.requestId.equals(execution.stableId),
        ))!;
        final jobs = await ConversationJob.db.find(
          fixture.database,
          where: (table) => table.conversationId.equals(child.id),
        );

        expect(
          conversation_repo.conversationParentTurnIdForExecutionSettings(
            execution.settingsJson,
          ),
          fixture.turn.id,
        );
        expect(
          conversation_repo.conversationParentTurnIdForJob(
            jobs.single.payloadJson,
          ),
          fixture.turn.id,
        );
        expect(child.activeExecutionId, isNull);
        expect(execution.status, ConversationStatuses.cancelled);
        expect(childTurn.status, ConversationStatuses.cancelled);
        expect(
          jobs.map((job) => job.status),
          isNot(
            contains(
              anyOf(
                ConversationJobStatuses.queued,
                ConversationJobStatuses.leased,
              ),
            ),
          ),
        );
        expect(effects.calls, 0);

        release.complete();
        await expectLater(
          handling,
          throwsA(isA<ConversationCancelledException>()),
        );
      },
    );

    test(
      'cancellation before loading a skill leaves no selection or workspace event',
      () async {
        final fixture = await prepare();
        final now = DateTime.now().toUtc();
        await WorkspaceResource.db.insertRow(
          fixture.database,
          WorkspaceResource(
            workspaceId: fixture.workspaceId,
            resourceKind: WorkspaceResourceKind.skill,
            resourceId: 'research',
            data: jsonEncode({'slug': 'research', 'isEnabled': true}),
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await WorkspaceResource.db.insertRow(
          fixture.database,
          WorkspaceResource(
            workspaceId: fixture.workspaceId,
            resourceKind: WorkspaceResourceKind.skillTemplateTool,
            resourceId: 'research-search',
            data: jsonEncode({
              'skillId': 'research',
              'skillSlug': 'research',
              'toolSlug': 'search',
              'isEnabled': true,
              'requiresCredential': false,
              'inputsJson': '[]',
              'templateJson': '{}',
            }),
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        final load = (await ServerToolRuntime().loadTools(
          fixture.database,
          workspaceId: fixture.workspaceId,
          conversationStableId: 'conversation-1',
        )).singleWhere((tool) => tool.spec.name == loadSkillToolName);
        final eventCount = (await WorkspaceEvent.db.find(
          fixture.database,
          where: (table) => table.workspaceId.equals(fixture.workspaceId),
        )).length;
        final entered = Completer<void>();
        final release = Completer<void>();
        final handling =
            ServerToolExecutorService(
              beforeSkillSelectionMutation: () async {
                entered.complete();
                await release.future;
              },
            ).call(
              fixture.database,
              fixture.turn,
              load,
              const ServerToolRequest(
                id: 'cancel-during-load-skill',
                name: loadSkillToolName,
                arguments: {'slug': 'research'},
              ),
            );
        await entered.future.timeout(const Duration(seconds: 2));
        await ConversationUseCases(
          conversation_repo.ConversationRepository(),
          publishConversationJob: (_, _) async {},
        ).cancelTurn(
          fixture.database,
          userId: fixture.userId,
          request: CancelTurnRequest(
            workspaceId: fixture.workspaceId,
            requestId: 'cancel-parent-during-load-skill',
            turnId: fixture.turn.requestId,
            expectedTurnRevision: fixture.turn.revision,
          ),
        );
        release.complete();

        await expectLater(
          handling,
          throwsA(isA<ConversationCancelledException>()),
        );
        expect(
          await WorkspaceResource.db.find(
            fixture.database,
            where: (table) =>
                table.workspaceId.equals(fixture.workspaceId) &
                table.resourceKind.equals(
                  WorkspaceResourceKind.conversationSkillSelection,
                ),
          ),
          isEmpty,
        );
        expect(
          (await WorkspaceEvent.db.find(
            fixture.database,
            where: (table) => table.workspaceId.equals(fixture.workspaceId),
          )).length,
          eventCount,
        );
      },
    );

    test(
      'child carries its initiating parent turn model selection',
      () async {
        final fixture = await prepare();
        await configureProvider(fixture);
        final now = DateTime.now().toUtc();
        await ConversationJob.db.updateRow(
          fixture.database,
          fixture.job.copyWith(
            status: ConversationJobStatuses.completed,
            updatedAt: now,
          ),
        );
        final parentTool = ServerResolvedTool(
          descriptor: AgentResolvedToolName.skillNative(
            tableId: runSubAgentToolName,
            skillSlug: agentsSkillSlug,
            toolIdentifier: runSubAgentToolName,
          ),
          spec: ToolSpec(
            name: 'skill__app__agents__$runSubAgentToolName',
            description: '',
            inputJsonSchema: const {},
          ),
        );
        final childResult = await const ServerToolExecutorService().call(
          fixture.database,
          fixture.turn,
          parentTool,
          const ServerToolRequest(
            id: 'parent-approved-child',
            name: 'skill__app__agents__run_sub_agent',
            arguments: {'title': 'Child', 'prompt': 'Do the work.'},
          ),
        );
        final childId = (childResult! as Map)['conversationId']! as String;
        final child = (await Conversation.db.findFirstRow(
          fixture.database,
          where: (table) => table.stableId.equals(childId),
        ))!;
        final modelSelectionId = VirtualWorkspaceModelSelectionId.encode(
          connectionId: 'connection-1',
          modelId: 'model-1',
        );
        expect(child.modelId, modelSelectionId);
        final childExecution = (await ConversationExecution.db.findFirstRow(
          fixture.database,
          where: (table) => table.conversationId.equals(child.id),
        ))!;
        final childTurn = (await ConversationTurn.db.findFirstRow(
          fixture.database,
          where: (table) => table.requestId.equals(childExecution.stableId),
        ))!;
        final childUser = (await ConversationMessage.db.findById(
          fixture.database,
          childTurn.userMessageId!,
        ))!;
        expect(
          jsonDecode(childUser.metadataJson!)['modelSelectionId'],
          modelSelectionId,
        );
        await WorkspaceResource.db.insertRow(
          fixture.database,
          WorkspaceResource(
            workspaceId: fixture.workspaceId,
            resourceKind: WorkspaceResourceKind.tool,
            resourceId: 'child-server',
            data: jsonEncode({
              'name': 'mcp_child-server_demo_confirm',
              'isEnabled': true,
            }),
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await WorkspaceResource.db.insertRow(
          fixture.database,
          WorkspaceResource(
            workspaceId: fixture.workspaceId,
            resourceKind: WorkspaceResourceKind.toolPermission,
            resourceId: 'child-server-permission',
            data: jsonEncode({
              'toolId': 'child-server',
              'permissionMode': 'alwaysAsk',
              'isEnabled': true,
            }),
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        final childTool =
            (await ServerToolRuntime().loadTools(
              fixture.database,
              workspaceId: fixture.workspaceId,
              conversationStableId: childId,
            )).singleWhere(
              (tool) => tool.spec.name == 'mcp_child-server_demo_confirm',
            );
        final disposition = await ServerToolRuntime().handle(
          fixture.database,
          turn: childTurn,
          messageId: childExecution.assistantMessageId!,
          request: ServerToolRequest(
            id: 'child-confirmation',
            name: childTool.spec.name,
            arguments: const {},
          ),
        );
        expect(disposition, ServerToolDisposition.awaitingApproval);

        await runConversationWorker(
          fixture.database,
          isActive: () => true,
          worker: ConversationWorker(host: const _AwaitingApprovalHost()),
        );
        final pausedTurn = (await ConversationTurn.db.findById(
          fixture.database,
          childTurn.id!,
        ))!;
        final pausedExecution = (await ConversationExecution.db.findById(
          fixture.database,
          childExecution.id!,
        ))!;
        expect(pausedTurn.status, ConversationStatuses.awaitingApproval);
        expect(pausedExecution.status, ConversationStatuses.awaitingApproval);

        await ConversationUseCases(
          conversation_repo.ConversationRepository(),
          publishConversationJob: (_, _) async {},
        ).submitToolDecision(
          fixture.database,
          userId: fixture.userId,
          request: SubmitToolDecisionRequest(
            workspaceId: fixture.workspaceId,
            requestId: 'approve-child-confirmation',
            turnId: pausedTurn.requestId,
            toolCallId: 'child-confirmation',
            argumentsDigest: (await ConversationToolCall.db.findFirstRow(
              fixture.database,
              where: (table) => table.stableId.equals('child-confirmation'),
            ))!.argumentsDigest,
            expectedTurnRevision: pausedTurn.revision,
            decision: 'approve',
          ),
        );
        await runConversationWorker(
          fixture.database,
          isActive: () => true,
          worker: ConversationWorker(host: const _CompletingHost()),
        );
        final completedExecution = (await ConversationExecution.db.findById(
          fixture.database,
          childExecution.id!,
        ))!;
        expect(completedExecution.status, ConversationStatuses.completed);
      },
    );
  });
}

class _AwaitingApprovalHost implements ConversationEngineHost {
  const _AwaitingApprovalHost();

  @override
  Future<ConversationEngineResult> executeTurn(
    Session session, {
    required ConversationJob job,
    required ConversationTurn turn,
    required List<ConversationMessage> messages,
    required ConversationProgressPublisher liveTurns,
    Future<void>? leaseLost,
  }) async => const ConversationEngineResult(
    content: '',
    finishReason: 'awaiting_approval',
    inputTokens: 0,
    outputTokens: 0,
    totalTokens: 0,
    awaitingApproval: true,
  );

  @override
  Future<ConversationCompactionResult> compact(
    Session session, {
    required ConversationJob job,
    required List<ConversationMessage> messages,
    Future<void>? leaseLost,
  }) => throw UnimplementedError();
}

class _CompletingHost implements ConversationEngineHost {
  const _CompletingHost();

  @override
  Future<ConversationEngineResult> executeTurn(
    Session session, {
    required ConversationJob job,
    required ConversationTurn turn,
    required List<ConversationMessage> messages,
    required ConversationProgressPublisher liveTurns,
    Future<void>? leaseLost,
  }) async => const ConversationEngineResult(
    content: 'Child completed.',
    finishReason: 'stop',
    inputTokens: 0,
    outputTokens: 0,
    totalTokens: 0,
  );

  @override
  Future<ConversationCompactionResult> compact(
    Session session, {
    required ConversationJob job,
    required List<ConversationMessage> messages,
    Future<void>? leaseLost,
  }) => throw UnimplementedError();
}

class _EffectTrackingHost implements ConversationEngineHost {
  var calls = 0;

  @override
  Future<ConversationEngineResult> executeTurn(
    Session session, {
    required ConversationJob job,
    required ConversationTurn turn,
    required List<ConversationMessage> messages,
    required ConversationProgressPublisher liveTurns,
    Future<void>? leaseLost,
  }) async {
    calls++;
    return const ConversationEngineResult(
      content: 'Unexpected child execution.',
      finishReason: 'stop',
      inputTokens: 0,
      outputTokens: 0,
      totalTokens: 0,
    );
  }

  @override
  Future<ConversationCompactionResult> compact(
    Session session, {
    required ConversationJob job,
    required List<ConversationMessage> messages,
    Future<void>? leaseLost,
  }) => throw UnimplementedError();
}

class _BlockedCancellationProbe implements ConversationCancellationProbe {
  final entered = Completer<void>();
  final release = Completer<void>();

  @override
  Future<bool> isCancelled(Session session, int turnId) async {
    if (!entered.isCompleted) entered.complete();
    await release.future;
    return (await ConversationTurn.db.findById(
          session,
          turnId,
        ))!.cancellationRequestedAt !=
        null;
  }
}

class _Fixture {
  _Fixture({
    required this.session,
    required this.database,
    required this.userId,
    required this.workspaceId,
    required this.conversationId,
    required this.turn,
    required this.job,
    required this.messages,
  });

  final dynamic session;
  final Session database;
  final String userId;
  final int workspaceId;
  final int conversationId;
  final ConversationTurn turn;
  final ConversationJob job;
  List<ConversationMessage> messages;
}

class _ImmediateAdmissionGate implements ConversationAdmissionGate {
  const _ImmediateAdmissionGate();

  @override
  Future<T> run<T>(
    Session session, {
    required ConversationJob job,
    required String providerId,
    required Future<T> Function(Future<void> admissionLost) body,
  }) => body(Future<void>.value());
}

class _NoopProgressPublisher implements ConversationProgressPublisher {
  const _NoopProgressPublisher();

  @override
  Future<void> flush() async {}

  @override
  Future<void> queued() async {}

  @override
  Future<void> running() async {}

  @override
  Future<void> text(String text) async {}
}
