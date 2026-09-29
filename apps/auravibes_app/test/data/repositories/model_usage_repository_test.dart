import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/model_usage_repository.dart';
import 'package:auravibes_app/domain/entities/model_usage_record.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

QueryExecutor _testConnection() => DatabaseConnection.delayed(
  Future(
    () => DatabaseConnection(LazyDatabase(() async => NativeDatabase.memory())),
  ),
);

void main() {
  final database = AppDatabase(connection: _testConnection());
  final repository = ModelUsageRepository(database);

  tearDownAll(() async {
    final _ = await database.close();
  });

  test(
    'round trips request usage and keeps fork records on their owner',
    () async {
      final workspace = await database.workspaceDao.insertWorkspace(
        .insert(name: 'Workspace', type: WorkspaceType.local),
      );
      final source = await database.conversationDao.insertConversation(
        .insert(workspaceId: workspace.id, title: 'Source'),
      );
      final fork = await database.conversationDao.insertConversation(
        .insert(
          workspaceId: workspace.id,
          title: 'Fork',
          forkSourceConversationId: .new(source.id),
        ),
      );

      final record = await repository.recordRequest(
        .new(
          conversationId: source.id,
          providerId: 'anthropic',
          modelId: 'claude-sonnet-5-5',
          requestKind: .generation,
          outcome: .succeeded,
          usage: const .new(
            promptTokens: 120,
            responseTokens: 30,
            totalTokens: 150,
            cacheReadInputTokens: 40,
          ),
          costStatus: .unknown,
        ),
      );
      final compactionRecord = await repository.recordRequest(
        .new(
          conversationId: source.id,
          providerId: 'anthropic',
          modelId: 'claude-sonnet-5-5',
          requestKind: .compaction,
          outcome: .succeeded,
          usage: const .new(
            promptTokens: 4,
            responseTokens: 2,
            totalTokens: 6,
            cacheReadInputTokens: 2,
            cacheCreationInputTokens: 1,
          ),
          costStatus: .known,
          costUsd: 0.02,
        ),
      );
      final forkRecord = await repository.recordRequest(
        .new(
          conversationId: fork.id,
          providerId: 'anthropic',
          modelId: 'claude-sonnet-5-5',
          requestKind: .generation,
          outcome: .succeeded,
          usage: const .new(
            promptTokens: 5,
            responseTokens: 3,
            totalTokens: 8,
            cacheReadInputTokens: 1,
            cacheCreationInputTokens: 0,
          ),
          costStatus: .known,
          costUsd: 0.01,
        ),
      );

      final restored = await repository.getRecordsForConversation(source.id);
      final totals = await repository.getTotalsForConversation(source.id);

      expect(record.requestKind, ModelUsageRequestKind.generation);
      expect(record.usage?.cacheReadInputTokens, 40);
      expect(record.usage?.cacheCreationInputTokens, isNull);
      expect(record.costStatus, ModelUsageCostStatus.unknown);
      expect(record.costUsd, isNull);
      expect(
        restored.map((row) => row.id),
        containsAll([record.id, compactionRecord.id]),
      );
      expect(restored.firstOrNull?.createdAt, isA<DateTime>());
      expect(totals.requestCount, 2);
      expect(totals.promptTokens, 124);
      expect(totals.cacheReadInputTokens, 42);
      expect(totals.cacheCreationInputTokens, isNull);
      expect(totals.costStatus, ModelUsageCostStatus.unknown);
      expect(totals.costUsd, isNull);
      final forkRecords = await repository.getRecordsForConversation(fork.id);
      final forkTotals = await repository.getTotalsForConversation(fork.id);
      expect(forkRecords.single.id, forkRecord.id);
      expect(forkTotals.requestCount, 1);
      expect(forkTotals.promptTokens, 5);
      expect(forkTotals.costUsd, 0.01);
    },
  );

  test('round trips failed request without reported usage', () async {
    final workspace = await database.workspaceDao.insertWorkspace(
      .insert(name: 'Workspace', type: WorkspaceType.local),
    );
    final conversation = await database.conversationDao.insertConversation(
      .insert(workspaceId: workspace.id, title: 'Conversation'),
    );

    final _ = await repository.recordRequest(
      .new(
        conversationId: conversation.id,
        providerId: 'anthropic',
        modelId: 'claude-sonnet-5-5',
        requestKind: .generation,
        outcome: .failed,
        usage: null,
        costStatus: .unknown,
      ),
    );

    final restored = await repository.getRecordsForConversation(
      conversation.id,
    );
    final totals = await repository.getTotalsForConversation(conversation.id);

    expect(restored.single.outcome, ModelUsageRequestOutcome.failed);
    expect(restored.single.usage, isNull);
    expect(restored.single.costUsd, isNull);
    expect(totals.failedRequestCount, 1);
    expect(totals.promptTokens, isNull);
  });
}
