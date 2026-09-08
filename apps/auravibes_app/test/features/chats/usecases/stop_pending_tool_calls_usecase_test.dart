import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/features/chats/agent_adapters/agent_tool_execution_service.dart';
import 'package:auravibes_app/features/chats/agent_adapters/app_tool_call_actions_data_provider.dart';
import 'package:auravibes_app/features/chats/agent_adapters/resolved_tool_service.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/usecases/stop_pending_tool_calls_usecase.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

import '../../../test_mocks.dart';

void main() {
  final metadata = MessageMetadataEntity(
    toolCalls: [
      for (final status in [null, ...ToolCallResultStatus.values])
        MessageToolCallEntity(
          id: status?.name ?? 'approval',
          name: 'tool',
          argumentsRaw: '{}',
          responseRaw: 'preserved',
          resultStatus: status,
        ),
    ],
    thinking: 'preserved',
    modelMetadata: const {'custom': 'value'},
  );

  test('stopping changes only approval and running statuses', () {
    final stopped = stopPendingToolMetadata(metadata);
    expect(
      stopped,
      metadata.copyWith(
        toolCalls: [
          for (final tool in metadata.toolCalls)
            if (tool.resultStatus == null || tool.resultStatus == .running)
              tool.copyWith(resultStatus: .stoppedByUser)
            else
              tool,
        ],
      ),
    );
    expect(stopPendingToolMetadata(stopped), same(stopped));
    expect(stopPendingToolMetadata(null), isNull);
    const empty = MessageMetadataEntity();
    expect(stopPendingToolMetadata(empty), same(empty));
  });

  for (final actions in [true, false]) {
    test('SQLite stop workflow through actions=$actions', () async {
      final database = AppDatabase(
        connection: DatabaseConnection(NativeDatabase.memory()),
      );
      addTearDown(database.close);
      final repository = MessageRepository(database);
      final workspace = await database.workspaceDao.insertWorkspace(
        WorkspacesCompanion.insert(name: 'Test', type: WorkspaceType.local),
      );
      final conversation = await database.conversationDao.insertConversation(
        ConversationsCompanion.insert(workspaceId: workspace.id, title: 'Test'),
      );
      final message = await repository.createMessage(
        MessageToCreate(
          conversationId: conversation.id,
          content: 'assistant',
          messageType: MessageType.text,
          isUser: false,
          status: MessageStatus.sent,
          metadata: jsonEncode(metadata.toJson()),
        ),
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final runtime = container.read(activeSubAgentRuntimeProvider.notifier);
      final request = runtime.start(
        parentId: 'parent',
        childId: conversation.id,
      );
      var notifications = 0;
      final actionsProvider = AppToolCallActionsDataProvider(
        messageRepository: repository,
        agentToolResumeService: MockAgentToolResumeService(),
        onToolCallChanged: () => notifications++,
        activeSubAgents: runtime,
      );
      final executionProvider = AppAllowedToolsDataProvider(
        messageRepository: repository,
        loadLatestMessageToolCallsService: MockAgentToolCallLoader(),
        resolvedToolService: ResolvedToolService.cloud(),
        toolDecisionService: MockAgentToolDecisionService(),
        agentCancellationRuntime: AgentCancellationRuntime(),
      );
      final stop = actions
          ? actionsProvider.stopPendingToolCalls
          : executionProvider.stopPendingTools;

      await stop(messageId: message.id);
      final persisted = await repository.getMessageById(message.id);
      expect(persisted?.metadata, stopPendingToolMetadata(metadata));
      expect(persisted?.content, message.content);
      expect(notifications, actions ? 1 : 0);
      expect(request.isStopped, actions);
      await stop(messageId: message.id);
      await stop(messageId: 'missing');
      expect(notifications, actions ? 1 : 0);
      expect(
        await StopPendingToolCallsUsecase(repository)
            .call(messageId: message.id),
        isNull,
      );
      final emptyMessage = await repository.createMessage(
        MessageToCreate(
          conversationId: conversation.id,
          content: 'no metadata',
          messageType: MessageType.text,
          isUser: false,
          status: MessageStatus.sent,
        ),
      );
      await stop(messageId: emptyMessage.id);
      expect(
        (await repository.getMessageById(emptyMessage.id))?.metadata,
        isNull,
      );
      expect(notifications, actions ? 1 : 0);
    });
  }
}
