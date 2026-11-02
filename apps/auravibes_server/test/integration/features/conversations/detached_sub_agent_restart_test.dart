import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server/src/features/conversations/domain/conversation_values.dart';
import 'package:auravibes_server/src/features/conversations/engine/server_tool_executor.dart';
import 'package:auravibes_server/src/features/conversations/engine/server_tool_runtime.dart';
import 'package:auravibes_server/src/features/conversations/workers/conversation_worker.dart';
import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('DetachedSubAgentRestart', (sessionBuilder, endpoints) {
    test('restart fails detached sub-agent once and stops its child', () async {
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
      final now = DateTime.now().toUtc();
      final workspace = await workspace_repo.CloudWorkspaceRepository()
          .createWorkspace(
            database,
            name: 'Workspace',
            ownerUserId: userId,
            now: now,
          );
      final conversation = await Conversation.db.insertRow(
        database,
        Conversation(
          workspaceId: workspace.id!,
          stableId: 'parent-conversation',
          title: 'Parent',
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
          requestId: 'queue-parent',
          conversationId: conversation.stableId,
          expectedProjectionRevision: 1,
          clientMessageId: 'parent-message',
          content: 'Continue.',
          attachmentIds: const [],
        ),
      );
      await endpoints.conversation.continueConversation(
        session,
        ContinueConversationRequest(
          workspaceId: workspace.id!,
          requestId: 'continue-parent',
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
      final parentJob = (await ConversationJob.db.findFirstRow(
        database,
        where: (table) => table.turnId.equals(turn.id),
      ))!;
      final messages = await ConversationMessage.db.find(
        database,
        where: (table) => table.conversationId.equals(conversation.id),
        orderBy: (table) => table.id,
      );
      await ConversationJob.db.updateRow(
        database,
        parentJob.copyWith(
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
          name: 'skill__app_native__agents__$runSubAgentToolName',
          description: '',
          inputJsonSchema: const {},
        ),
      );
      final launched = await const ServerToolExecutorService().call(
        database,
        turn,
        parentTool,
        const ServerToolRequest(
          id: 'detached-sub-agent-call',
          name: 'skill__app_native__agents__run_sub_agent',
          arguments: {'title': 'Child', 'prompt': 'Do the work.'},
        ),
      );
      final childLaunch = launched! as ServerToolAwaitingSubAgents;
      final childConversationId =
          childLaunch.children.single['conversationId']! as String;
      const workId = 'detached-sub-agent-work';
      final message = messages.first;
      final call = await ConversationToolCall.db.insertRow(
        database,
        ConversationToolCall(
          workspaceId: workspace.id!,
          conversationId: conversation.id!,
          turnId: turn.id!,
          messageId: message.id!,
          stableId: 'detached-sub-agent-call',
          name: 'skill__app_native__agents__run_sub_agent',
          argumentsJson: '{}',
          argumentsDigest: 'digest',
          backgroundEligible: true,
          backgroundWorkStableId: workId,
          childConversationStableId: childConversationId,
          status: 'runningInBackground',
          resultJson: jsonEncode({
            'status': 'running_in_background',
            'work_id': workId,
            'childConversationId': childConversationId,
            'children': childLaunch.children,
          }),
          revision: 2,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await BackgroundWorkRecord.db.insertRow(
        database,
        BackgroundWorkRecord(
          workspaceId: workspace.id!,
          conversationId: conversation.id!,
          conversationToolCallId: call.id!,
          originatingMessageId: message.id!,
          stableId: workId,
          toolCallId: call.stableId,
          toolKind: 'skillNative',
          runtimeServerId: database.serverpod.serverId,
          status: 'running',
          createdAt: now,
          updatedAt: now,
        ),
      );

      await ServerToolRuntime().reconcileInterruptedBackgroundWork(
        database,
        startedAt: now.add(const Duration(seconds: 1)),
      );
      await const ConversationWorker().runOnce(
        database,
        workerId: 'restart-sub-agent-test',
      );

      final work = await BackgroundWorkRecord.db.findFirstRow(
        database,
        where: (table) => table.stableId.equals(workId),
      );
      final child = (await Conversation.db.findFirstRow(
        database,
        where: (table) => table.stableId.equals(childConversationId),
      ))!;
      final childExecution = (await ConversationExecution.db.findFirstRow(
        database,
        where: (table) => table.conversationId.equals(child.id),
      ))!;
      final childJobs = await ConversationJob.db.find(
        database,
        where: (table) => table.conversationId.equals(child.id),
      );
      final completionEvents = await ConversationEvent.db.find(
        database,
        where: (table) =>
            table.workspaceId.equals(workspace.id) &
            table.conversationId.equals(conversation.id) &
            table.eventId.equals('background-work-completion:$workId'),
      );

      expect((work?.status, work?.errorCode), ('failed', 'outcome_unknown'));
      expect(child.activeExecutionId, isNull);
      expect(childExecution.status, ConversationStatuses.cancelled);
      expect(
        childJobs.map((job) => job.status),
        isNot(
          contains(
            anyOf(
              ConversationJobStatuses.queued,
              ConversationJobStatuses.leased,
            ),
          ),
        ),
      );
      expect(completionEvents, hasLength(1));
    });

    test('background and parent stops terminalize queued child work', () async {
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
      final now = DateTime.now().toUtc();
      final workspace = await workspace_repo.CloudWorkspaceRepository()
          .createWorkspace(
            database,
            name: 'Workspace',
            ownerUserId: userId,
            now: now,
          );
      final conversation = await Conversation.db.insertRow(
        database,
        Conversation(
          workspaceId: workspace.id!,
          stableId: 'parent-stop-conversation',
          title: 'Parent',
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
          requestId: 'queue-parent-stop',
          conversationId: conversation.stableId,
          expectedProjectionRevision: 1,
          clientMessageId: 'parent-stop-message',
          content: 'Continue.',
          attachmentIds: const [],
        ),
      );
      await endpoints.conversation.continueConversation(
        session,
        ContinueConversationRequest(
          workspaceId: workspace.id!,
          requestId: 'continue-parent-stop',
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
      final parentJob = (await ConversationJob.db.findFirstRow(
        database,
        where: (table) => table.turnId.equals(turn.id),
      ))!;
      await ConversationJob.db.updateRow(
        database,
        parentJob.copyWith(
          status: ConversationJobStatuses.completed,
          updatedAt: now,
        ),
      );
      final message = (await ConversationMessage.db.find(
        database,
        where: (table) => table.conversationId.equals(conversation.id),
      )).first;
      final parentTool = ServerResolvedTool(
        descriptor: AgentResolvedToolName.skillNative(
          tableId: runSubAgentToolName,
          skillSlug: agentsSkillSlug,
          toolIdentifier: runSubAgentToolName,
        ),
        spec: ToolSpec(
          name: 'skill__app_native__agents__$runSubAgentToolName',
          description: '',
          inputJsonSchema: const {},
        ),
      );

      Future<({String conversationId, String workId})> launchDetachedChild(
        String suffix,
      ) async {
        final toolCallId = 'detached-sub-agent-$suffix';
        final launched = await const ServerToolExecutorService().call(
          database,
          turn,
          parentTool,
          ServerToolRequest(
            id: toolCallId,
            name: 'skill__app_native__agents__run_sub_agent',
            arguments: {'title': 'Child', 'prompt': 'Do the work.'},
          ),
        );
        final childLaunch = launched! as ServerToolAwaitingSubAgents;
        final childConversationId =
            childLaunch.children.single['conversationId']! as String;
        final workId = 'background-work-$suffix';
        final call = await ConversationToolCall.db.insertRow(
          database,
          ConversationToolCall(
            workspaceId: workspace.id!,
            conversationId: conversation.id!,
            turnId: turn.id!,
            messageId: message.id!,
            stableId: toolCallId,
            name: 'skill__app_native__agents__run_sub_agent',
            argumentsJson: '{}',
            argumentsDigest: 'digest',
            backgroundEligible: true,
            backgroundWorkStableId: workId,
            childConversationStableId: childConversationId,
            status: 'runningInBackground',
            resultJson: jsonEncode({
              'status': 'running_in_background',
              'work_id': workId,
              'childConversationId': childConversationId,
              'children': childLaunch.children,
            }),
            revision: 2,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await BackgroundWorkRecord.db.insertRow(
          database,
          BackgroundWorkRecord(
            workspaceId: workspace.id!,
            conversationId: conversation.id!,
            conversationToolCallId: call.id!,
            originatingMessageId: message.id!,
            stableId: workId,
            toolCallId: toolCallId,
            toolKind: 'skillNative',
            runtimeServerId: database.serverpod.serverId,
            status: 'running',
            createdAt: now,
            updatedAt: now,
          ),
        );
        return (conversationId: childConversationId, workId: workId);
      }

      final explicitlyStopped = await launchDetachedChild('explicit-stop');
      final stopRequest = StopBackgroundWorkRequest(
        requestId: 'stop-background-sub-agent',
        workspaceId: workspace.id!,
        conversationId: conversation.stableId,
        workId: explicitlyStopped.workId,
      );
      final requested = await endpoints.conversation.stopBackgroundWork(
        session,
        stopRequest,
      );
      expect(requested.status, 'stopRequested');
      await const ConversationWorker().runOnce(
        database,
        workerId: 'background-stop-test',
      );

      final explicitlyStoppedWork = await BackgroundWorkRecord.db.findFirstRow(
        database,
        where: (table) => table.stableId.equals(explicitlyStopped.workId),
      );
      final explicitStopEvents = await ConversationEvent.db.find(
        database,
        where: (table) =>
            table.conversationId.equals(conversation.id) &
            table.eventId.equals(
              'background-work-completion:${explicitlyStopped.workId}',
            ),
      );
      expect(explicitlyStoppedWork?.status, 'cancelled');
      expect(explicitStopEvents, hasLength(1));

      final stoppedByParent = await launchDetachedChild('parent-stop');
      await endpoints.conversation.cancelTurn(
        session,
        CancelTurnRequest(
          requestId: 'cancel-parent-sub-agent',
          workspaceId: workspace.id!,
          turnId: turn.requestId,
          expectedTurnRevision: turn.revision,
        ),
      );
      await const ConversationWorker().runOnce(
        database,
        workerId: 'parent-stop-test',
      );
      final stoppedByParentWork = await BackgroundWorkRecord.db.findFirstRow(
        database,
        where: (table) => table.stableId.equals(stoppedByParent.workId),
      );
      final parentStopEvents = await ConversationEvent.db.find(
        database,
        where: (table) =>
            table.conversationId.equals(conversation.id) &
            table.eventId.equals(
              'background-work-completion:${stoppedByParent.workId}',
            ),
      );
      expect(stoppedByParentWork?.status, 'cancelled');
      expect(parentStopEvents, hasLength(1));
    });
    test(
      'completed child is reconciled when detached before parent reconciliation',
      () async {
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
        final now = DateTime.now().toUtc();
        final workspace = await workspace_repo.CloudWorkspaceRepository()
            .createWorkspace(
              database,
              name: 'Workspace',
              ownerUserId: userId,
              now: now,
            );
        final conversation = await Conversation.db.insertRow(
          database,
          Conversation(
            workspaceId: workspace.id!,
            stableId: 'completed-before-detach-parent',
            title: 'Parent',
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
            requestId: 'queue-completed-before-detach-parent',
            conversationId: conversation.stableId,
            expectedProjectionRevision: 1,
            clientMessageId: 'completed-before-detach-parent-message',
            content: 'Continue.',
            attachmentIds: const [],
            languageCode: 'es',
          ),
        );
        await endpoints.conversation.continueConversation(
          session,
          ContinueConversationRequest(
            workspaceId: workspace.id!,
            requestId: 'continue-completed-before-detach-parent',
            conversationId: conversation.stableId,
            expectedProjectionRevision: 2,
            languageCode: 'es',
          ),
        );
        final turn = (await ConversationTurn.db.findFirstRow(
          database,
          where: (table) =>
              table.workspaceId.equals(workspace.id) &
              table.conversationId.equals(conversation.id),
        ))!;
        final parentJob = (await ConversationJob.db.findFirstRow(
          database,
          where: (table) => table.turnId.equals(turn.id),
        ))!;
        await ConversationJob.db.updateRow(
          database,
          parentJob.copyWith(
            status: ConversationJobStatuses.completed,
            updatedAt: now,
          ),
        );
        final message = (await ConversationMessage.db.find(
          database,
          where: (table) => table.conversationId.equals(conversation.id),
        )).first;
        final parentTool = ServerResolvedTool(
          descriptor: AgentResolvedToolName.skillNative(
            tableId: runSubAgentToolName,
            skillSlug: agentsSkillSlug,
            toolIdentifier: runSubAgentToolName,
          ),
          spec: ToolSpec(
            name: 'skill__app_native__agents__$runSubAgentToolName',
            description: '',
            inputJsonSchema: const {},
          ),
        );
        final launched = await const ServerToolExecutorService().call(
          database,
          turn,
          parentTool,
          const ServerToolRequest(
            id: 'completed-before-detach-child-call',
            name: 'skill__app_native__agents__run_sub_agent',
            arguments: {'title': 'Child', 'prompt': 'Do the work.'},
          ),
        );
        final childLaunch = launched! as ServerToolAwaitingSubAgents;
        final childConversationId =
            childLaunch.children.single['conversationId']! as String;
        final childExecutionId =
            childLaunch.children.single['turnId']! as String;
        final childExecution = (await ConversationExecution.db.findFirstRow(
          database,
          where: (table) =>
              table.workspaceId.equals(workspace.id) &
              table.stableId.equals(childExecutionId),
        ))!;
        await ConversationExecution.db.updateRow(
          database,
          childExecution.copyWith(
            status: ConversationStatuses.completed,
            terminalAt: now,
          ),
        );
        final call = await ConversationToolCall.db.insertRow(
          database,
          ConversationToolCall(
            workspaceId: workspace.id!,
            conversationId: conversation.id!,
            turnId: turn.id!,
            messageId: message.id!,
            stableId: 'completed-before-detach-parent-call',
            name: 'skill__app_native__agents__run_sub_agent',
            argumentsJson: '{}',
            argumentsDigest: 'digest',
            backgroundEligible: true,
            childConversationStableId: childConversationId,
            status: 'awaitingSubAgents',
            resultJson: jsonEncode({'children': childLaunch.children}),
            revision: 2,
            createdAt: now,
            updatedAt: now,
          ),
        );

        final detached = await endpoints.conversation.detachToolCall(
          session,
          DetachToolCallRequest(
            requestId: 'detach-completed-before-parent-reconcile',
            workspaceId: workspace.id!,
            conversationId: conversation.stableId,
            toolCallId: call.stableId,
          ),
        );

        final work = await BackgroundWorkRecord.db.findFirstRow(
          database,
          where: (table) => table.stableId.equals(detached.id),
        );
        final completedCall = await ConversationToolCall.db.findById(
          database,
          call.id!,
        );
        final completionEvents = await ConversationEvent.db.find(
          database,
          where: (table) =>
              table.workspaceId.equals(workspace.id) &
              table.conversationId.equals(conversation.id) &
              table.eventId.equals('background-work-completion:${detached.id}'),
        );

        expect(detached.childConversationId, childConversationId);
        expect(work?.status, 'completed');
        expect(completedCall?.status, 'runningInBackground');
        expect(completionEvents, hasLength(1));
        expect(
          jsonDecode(completionEvents.single.payloadJson)['languageCode'],
          'es',
        );
      },
    );
  });
}
