import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/enums/messages_table_type.dart';
import 'package:auravibes_app/data/repositories/background_work_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_history_redaction.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../database/drift/database_test_utils.dart';

void main() {
  final database = AppDatabase(
    connection: DatabaseConnection(NativeDatabase.memory()),
  );
  final repository = ConversationRepository(database);
  setUp(() => clearAppDatabase(database));
  tearDownAll(database.close);

  Future<void> insertSource({String? reasoningConfigJson}) async {
    final workspace = await database.workspaceDao.insertWorkspace(
      .insert(name: 'Test Workspace', type: .local),
    );
    final _ = await database.conversationDao.insertConversation(
      .new(
        id: const .new('source'),
        workspaceId: .new(workspace.id),
        title: const .new('Source'),
        reasoningConfigJson: .new(reasoningConfigJson),
      ),
    );
  }

  Future<MessagesTable> insertMessage({
    required String id,
    required DateTime createdAt,
    required bool isUser,
    required MessageTableStatus status,
    MessagesTableType messageType = .text,
    String? metadata,
  }) => database.messageDao.insertMessage(
    .new(
      id: .new(id),
      createdAt: .new(createdAt),
      updatedAt: .new(createdAt),
      conversationId: const .new('source'),
      content: .new(id),
      messageType: .new(messageType),
      isUser: .new(isUser),
      status: .new(status),
      metadata: .new(metadata),
    ),
  );

  test(
    'fork history redacts workspace results before and after materialization',
    () async {
      await insertSource();
      final _ = await insertMessage(
        id: 'user-before-tool',
        createdAt: .utc(2026),
        isUser: true,
        status: .sent,
      );
      final _ = await insertMessage(
        id: 'workspace-tool',
        createdAt: .utc(2026, 1, 1, 0, 0, 1),
        isUser: false,
        status: .sent,
        metadata: jsonEncode(
          const MessageMetadataEntity(
            toolCalls: [
              MessageToolCallEntity(
                id: 'read-table',
                name: 'workspace_read_table',
                argumentsRaw: '{"tableId":"private-table"}',
                responseRaw: '{"columns":[{"name":"private-schema"}]}',
                resultStatus: .success,
              ),
            ],
          ).toJson(),
        ),
      );
      final fork = await repository.forkConversation('source');
      final messages = MessageRepository(database);

      Future<void> expectRedacted() async {
        final history = await messages.getMessagesByConversation(fork.id);
        final projected = redactWorkspaceToolHistory(history);
        final calls = projected.expand(
          (message) => message.metadata?.toolCalls ?? <MessageToolCallEntity>[],
        );
        final call = calls.singleWhere((call) => call.id == 'read-table');
        expect(call.responseRaw, workspaceContextUnavailable);
        expect(call.argumentsRaw, isNot(contains('private-table')));
      }

      await expectRedacted();
      expect(await repository.deleteConversation('source'), isTrue);
      final materialized = await messages.getMessagesByConversation(fork.id);
      expect(materialized.every((message) => !message.isForkReference), isTrue);
      await expectRedacted();
    },
  );

  test(
    'local mode defaults off, persists create and patch, forks independently',
    () async {
      await insertSource();
      final source =
          await repository.getConversationById('source') ??
          fail('Expected source conversation');
      expect(source.toolAccessMode, ConversationToolAccessMode.defaultMode);
      final created = await repository.createConversation(
        .new(
          title: 'Auto',
          workspaceId: source.workspaceId,
          toolAccessMode: .allowAll,
        ),
      );
      expect(created.toolAccessMode, ConversationToolAccessMode.allowAll);
      final changed = await repository.patchConversation(
        'source',
        const .new(toolAccessMode: .allowAll),
      );
      expect(changed.toolAccessMode, ConversationToolAccessMode.allowAll);
      final _ = await insertMessage(
        id: 'mode-terminal',
        createdAt: .utc(2026),
        isUser: false,
        status: .sent,
      );
      final fork = await repository.forkConversation('source');
      expect(fork.toolAccessMode, ConversationToolAccessMode.allowAll);
      final off = await repository.patchConversation(
        'source',
        const .new(toolAccessMode: .defaultMode),
      );
      expect(off.toolAccessMode, ConversationToolAccessMode.defaultMode);
      expect(
        (await repository.getConversationById(fork.id) ??
                fail('Expected fork conversation'))
            .toolAccessMode,
        ConversationToolAccessMode.allowAll,
      );
    },
  );

  test(
    'child fork snapshots current root mode and then stays independent',
    () async {
      await insertSource();
      final root =
          await repository.getConversationById('source') ??
          fail('Expected root');
      final _ = await repository.patchConversation(
        root.id,
        const .new(toolAccessMode: .allowAll),
      );
      final child = await repository.createConversation(
        .new(
          title: 'Child',
          workspaceId: root.workspaceId,
          parentConversationId: root.id,
        ),
      );
      expect(child.toolAccessMode, ConversationToolAccessMode.defaultMode);
      final _ = await database.messageDao.insertMessage(
        .new(
          conversationId: Value(child.id),
          content: const Value('Terminal'),
          messageType: const Value(MessagesTableType.text),
          isUser: const Value(false),
          status: const Value(MessageTableStatus.sent),
        ),
      );
      final fork = await repository.forkConversation(child.id);
      expect(fork.toolAccessMode, ConversationToolAccessMode.allowAll);
      expect(fork.parentConversationId, isNull);
      final _ = await repository.patchConversation(
        root.id,
        const .new(toolAccessMode: .defaultMode),
      );
      expect(
        (await repository.getConversationById(fork.id) ?? fail('Expected fork'))
            .toolAccessMode,
        ConversationToolAccessMode.allowAll,
      );
    },
  );

  test(
    'unknown stored mode defaults safely in entity and root lookup',
    () async {
      await insertSource();
      final _ = await database.conversationDao.patchConversation(
        'source',
        const .new(toolAccessMode: Value('future_mode')),
      );
      expect(
        (await repository.getConversationById('source'))?.toolAccessMode,
        ConversationToolAccessMode.defaultMode,
      );
      expect(
        await database.conversationDao.getToolAccessMode('source'),
        ConversationToolAccessMode.defaultMode,
      );
    },
  );

  test('fork copies conversation reasoning configuration', () async {
    const configuration = ReasoningConfiguration(effort: 'high');
    await insertSource(reasoningConfigJson: configuration.encode());
    final now = DateTime.utc(2026);
    final _ = await insertMessage(
      id: 'user-1',
      createdAt: now,
      isUser: true,
      status: .sent,
    );
    final _ = await insertMessage(
      id: 'assistant-1',
      createdAt: now.add(const Duration(seconds: 1)),
      isUser: false,
      status: .sent,
    );

    final fork = await repository.forkConversation('source');

    expect(fork.reasoningConfiguration?.encode(), configuration.encode());
  });

  test('fork does not inherit detached work records', () async {
    await insertSource();
    final source = await repository.getConversationById('source');
    if (source == null) fail('Source conversation was not created.');
    final backgroundWork = BackgroundWorkRepository(database);
    const workId = 'source-only-background-work';
    const toolCallId = 'source-only-tool-call';
    const completedWorkId = 'source-only-completed-background-work';
    const completedToolCallId = 'source-only-completed-tool-call';
    final _ = await backgroundWork.create(
      .new(
        id: workId,
        workspaceId: source.workspaceId,
        conversationId: source.id,
        toolCallId: toolCallId,
        toolKind: 'skill.native',
      ),
    );
    final _ = await backgroundWork.create(
      .new(
        id: completedWorkId,
        workspaceId: source.workspaceId,
        conversationId: source.id,
        toolCallId: completedToolCallId,
        toolKind: 'skill.native',
      ),
    );
    const completedResult = 'completed result stays in the source record';
    final _ = await backgroundWork.finish(
      .new(
        conversationId: source.id,
        workId: completedWorkId,
        status: AgentBackgroundWorkStatus.completed,
        resultContent: completedResult,
        resultByteLength: utf8.encode(completedResult).length,
        statusPreview: 'Completed',
      ),
    );
    final now = DateTime.utc(2026);
    final _ = await insertMessage(
      id: 'user-before-active-work',
      createdAt: now,
      isUser: true,
      status: .sent,
    );
    final _ = await insertMessage(
      id: 'assistant-with-active-work',
      createdAt: now.add(const Duration(seconds: 1)),
      isUser: false,
      status: .sent,
      metadata: jsonEncode(
        const MessageMetadataEntity(
          toolCalls: [
            MessageToolCallEntity(
              id: toolCallId,
              name: 'research-search',
              argumentsRaw: '{"query":"still running"}',
              resultStatus: .success,
            ),
            MessageToolCallEntity(
              id: completedToolCallId,
              name: 'research-search',
              argumentsRaw: '{"query":"completed private query"}',
              resultStatus: .success,
            ),
          ],
        ).toJson(),
      ),
    );

    final fork = await repository.forkConversation(source.id);
    final forkMessages = await MessageRepository(database)
        .getMessagesByConversation(fork.id);

    expect(
      (await backgroundWork.watchConversation(source.id).first).map(
        (work) => work.identity.id,
      ),
      containsAll([workId, completedWorkId]),
    );
    expect(await backgroundWork.watchConversation(fork.id).first, isEmpty);
    expect(
      forkMessages.expand((message) => message.metadata?.toolCalls ?? []),
      isNot(
        contains(
          predicate<MessageToolCallEntity>(
            (call) =>
                call.id == toolCallId ||
                call.argumentsRaw.contains('still running') ||
                call.id == completedToolCallId ||
                call.argumentsRaw.contains('completed private query'),
          ),
        ),
      ),
    );

    final _ = await backgroundWork.finish(
      .new(
        conversationId: source.id,
        workId: workId,
        status: .cancelled,
        resultContent: null,
        resultByteLength: 0,
        statusPreview: 'Stopped',
      ),
    );
    final cancelledForkMessages = await MessageRepository(database)
        .getMessagesByConversation(fork.id);
    expect(
      cancelledForkMessages.expand(
        (message) => message.metadata?.toolCalls ?? [],
      ),
      isNot(
        contains(
          predicate<MessageToolCallEntity>(
            (call) =>
                call.id == toolCallId ||
                call.argumentsRaw.contains('still running') ||
                call.id == completedToolCallId ||
                call.argumentsRaw.contains('completed private query'),
          ),
        ),
      ),
    );

    final frozenBoundaries = await repository.captureForkBoundaries(source.id);
    expect(
      await repository.deleteConversationWithFrozenForkBoundaries(
        source.id,
        frozenForkBoundaries: frozenBoundaries,
      ),
      isTrue,
    );
    final materializedMessages = await MessageRepository(database)
        .getMessagesByConversation(fork.id);
    expect(
      materializedMessages.expand(
        (message) => message.metadata?.toolCalls ?? [],
      ),
      isNot(
        contains(
          predicate<MessageToolCallEntity>(
            (call) =>
                call.id == toolCallId ||
                call.argumentsRaw.contains('still running') ||
                call.id == completedToolCallId ||
                call.argumentsRaw.contains('completed private query'),
          ),
        ),
      ),
    );
  });

  test('fork preserves selected conversation skills', () async {
    await insertSource();
    final now = DateTime.utc(2026);
    final _ = await insertMessage(
      id: 'user-1',
      createdAt: now,
      isUser: true,
      status: .sent,
    );
    final _ = await insertMessage(
      id: 'assistant-1',
      createdAt: now.add(const Duration(seconds: 1)),
      isUser: false,
      status: .sent,
    );
    final _ = await database.conversationSkillsDao.setAppSkillLoaded(
      'source',
      'research',
      isLoaded: true,
    );

    final fork = await repository.forkConversation('source');
    final selected = await database.conversationSkillsDao.getConversationSkills(
      fork.id,
    );

    expect(selected.single.appSkillIdentifier, 'research');
    expect(selected.single.isLoaded, isTrue);
  });

  test('sidebar fork stops before an active approval turn', () async {
    final _ = await insertSource();
    final base = DateTime.utc(2026);
    final _ = await insertMessage(
      id: 'user-1',
      createdAt: base.subtract(const Duration(seconds: 1)),
      isUser: true,
      status: .sent,
    );
    final completedAssistant = await insertMessage(
      id: 'assistant-1',
      createdAt: base,
      isUser: false,
      status: .sent,
    );
    final _ = await insertMessage(
      id: 'user-2',
      createdAt: base.add(const Duration(seconds: 1)),
      isUser: true,
      status: .sent,
    );
    final pendingMetadata = jsonEncode(
      const MessageMetadataEntity(
        toolCalls: [
          MessageToolCallEntity(
            id: 'tool-1',
            name: 'calculator',
            argumentsRaw: '{}',
          ),
        ],
      ).toJson(),
    );
    final pendingAssistant = await insertMessage(
      id: 'assistant-2',
      createdAt: base.add(const Duration(seconds: 2)),
      isUser: false,
      status: .unfinished,
      metadata: pendingMetadata,
    );

    final fork = await repository.forkConversation('source');
    final messages = await MessageRepository(database)
        .getMessagesByConversation(fork.id);

    expect(fork.forkThroughMessageId, completedAssistant.id);
    expect(messages.map((message) => message.id), ['user-1', 'assistant-1']);
    expect(messages.every((message) => message.isForkReference), isTrue);
    final messageRepository = MessageRepository(database);
    await expectLater(
      messageRepository.patchMessage(
        pendingAssistant.id,
        const .new(content: 'fork mutation'),
        conversationId: fork.id,
      ),
      throwsA(isA<MessageValidationException>()),
    );
    final sourceMessage = await messageRepository.getMessageById(
      pendingAssistant.id,
    );
    final sourceMetadata = sourceMessage?.metadata;
    if (sourceMetadata == null) {
      throw StateError('Expected source tool-call metadata');
    }
    expect(sourceMetadata.toolCalls.single.isAwaitingApproval, isTrue);
    final approved = await messageRepository.patchMessage(
      pendingAssistant.id,
      .new(
        metadata: .new(
          toolCalls: [
            sourceMetadata.toolCalls.single.copyWith(resultStatus: .success),
          ],
        ),
        status: .sent,
      ),
      conversationId: 'source',
    );
    expect(approved.metadata?.toolCalls.single.isResolved, isTrue);
  });

  test('legacy sent approval rows are treated as active', () async {
    final _ = await insertSource();
    final base = DateTime.utc(2026);
    final completedAssistant = await insertMessage(
      id: 'assistant-1',
      createdAt: base,
      isUser: false,
      status: .sent,
    );
    final _ = await insertMessage(
      id: 'user-2',
      createdAt: base.add(const Duration(seconds: 1)),
      isUser: true,
      status: .sent,
    );
    final _ = await insertMessage(
      id: 'assistant-2',
      createdAt: base.add(const Duration(seconds: 2)),
      isUser: false,
      status: .sent,
      metadata: jsonEncode(
        const MessageMetadataEntity(
          toolCalls: [
            MessageToolCallEntity(
              id: 'tool-1',
              name: 'calculator',
              argumentsRaw: '{}',
            ),
          ],
        ).toJson(),
      ),
    );

    final fork = await repository.forkConversation('source');

    expect(fork.forkThroughMessageId, completedAssistant.id);
    await expectLater(
      repository.forkConversation('source', throughMessageId: 'assistant-2'),
      throwsA(isA<ConversationValidationException>()),
    );
  });

  test('nested forks do not inherit a later active turn', () async {
    final _ = await insertSource();
    final base = DateTime.utc(2026);
    final _ = await insertMessage(
      id: 'user-1',
      createdAt: base.subtract(const Duration(seconds: 2)),
      isUser: true,
      status: .sent,
    );
    final activeCheckpoint = await insertMessage(
      id: 'summary-1',
      createdAt: base.subtract(const Duration(seconds: 1)),
      isUser: false,
      status: .sent,
      messageType: .system,
      metadata: jsonEncode(
        const MessageMetadataEntity(isCompactionSummary: true).toJson(),
      ),
    );
    final _ = await database.conversationDao.patchConversation(
      'source',
      .new(activeCompactionCheckpointId: .new(activeCheckpoint.id)),
    );
    final completedAssistant = await insertMessage(
      id: 'assistant-1',
      createdAt: base,
      isUser: false,
      status: .sent,
    );
    final _ = await insertMessage(
      id: 'user-2',
      createdAt: base.add(const Duration(seconds: 1)),
      isUser: true,
      status: .sent,
    );

    final firstFork = await repository.forkConversation('source');
    expect(firstFork.activeCompactionCheckpointId, activeCheckpoint.id);
    final messageRepository = MessageRepository(database);
    final _ = await messageRepository.createMessage(
      .new(
        conversationId: firstFork.id,
        content: 'new prompt',
        messageType: .text,
        isUser: true,
        status: .sent,
      ),
    );
    final _ = await messageRepository.createMessage(
      .new(
        conversationId: firstFork.id,
        content: 'pending response',
        messageType: .text,
        isUser: false,
        status: .unfinished,
        metadata: jsonEncode(
          const MessageMetadataEntity(
            toolCalls: [
              MessageToolCallEntity(
                id: 'tool-2',
                name: 'calculator',
                argumentsRaw: '{}',
              ),
            ],
          ).toJson(),
        ),
      ),
    );

    final secondFork = await repository.forkConversation(firstFork.id);
    final messages = await messageRepository.getMessagesByConversation(
      secondFork.id,
    );

    expect(secondFork.forkThroughMessageId, completedAssistant.id);
    expect(messages.map((message) => message.id), [
      'user-1',
      'summary-1',
      'assistant-1',
    ]);
    expect(secondFork.activeCompactionCheckpointId, activeCheckpoint.id);
  });

  test('no completed response before an active turn is rejected', () async {
    final _ = await insertSource();
    final base = DateTime.utc(2026);
    final _ = await insertMessage(
      id: 'user-1',
      createdAt: base,
      isUser: true,
      status: .sent,
    );
    final _ = await insertMessage(
      id: 'assistant-1',
      createdAt: base.add(const Duration(seconds: 1)),
      isUser: false,
      status: .unfinished,
      metadata: jsonEncode(
        const MessageMetadataEntity(
          toolCalls: [
            MessageToolCallEntity(
              id: 'tool-1',
              name: 'calculator',
              argumentsRaw: '{}',
            ),
          ],
        ).toJson(),
      ),
    );

    await expectLater(
      repository.forkConversation('source'),
      throwsA(isA<ConversationValidationException>()),
    );
  });

  test(
    'deleting source materializes fork and keeps shared attachments',
    () async {
      final _ = await insertSource();
      final base = DateTime.utc(2026);
      final sourceMessage = await insertMessage(
        id: 'assistant-1',
        createdAt: base,
        isUser: false,
        status: .sent,
      );
      final _ = await database
          .into(database.messageAttachments)
          .insert(
            MessageAttachmentsCompanion(
              messageId: .new(sourceMessage.id),
              localPath: const Value('/shared/image.png'),
              fileName: const Value('image.png'),
              displayName: const Value('image.png'),
              mimeType: const Value('image/png'),
              modality: const Value('image'),
              sizeBytes: const Value(10),
            ),
          );

      final fork = await repository.forkConversation(
        'source',
        throughMessageId: sourceMessage.id,
      );
      final boundaries = await repository.captureForkBoundaries('source');
      expect(boundaries[fork.id], sourceMessage.id);

      expect(
        await repository.deleteConversationWithFrozenForkBoundaries(
          'source',
          frozenForkBoundaries: boundaries,
        ),
        isTrue,
      );
      expect(await repository.getConversationById('source'), isNull);

      final materialized = await repository.getConversationById(fork.id);
      expect(materialized?.isForkMaterialized, isTrue);
      final messages = await MessageRepository(database)
          .getMessagesByConversation(fork.id);
      expect(messages, hasLength(1));
      expect(messages.single.id, isNot(sourceMessage.id));
      expect(messages.single.isForkReference, isFalse);
      expect(messages.single.attachments.single.localPath, '/shared/image.png');
    },
  );
}
