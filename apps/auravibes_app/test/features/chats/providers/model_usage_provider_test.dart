import 'package:auravibes_app/data/repositories/model_usage_repository.dart';
import 'package:auravibes_app/domain/entities/model_usage_aggregation.dart';
import 'package:auravibes_app/domain/entities/model_usage_record.dart';
import 'package:auravibes_app/domain/entities/model_usage_record_input.dart';
import 'package:auravibes_app/domain/entities/model_usage_totals.dart';
import 'package:auravibes_app/features/chats/providers/model_usage_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  test(
    'reuses a large loaded history for totals and keeps unknown costs',
    () async {
      final records = List<ModelUsageRecord>.generate(
        512,
        (index) => ModelUsageRecord(
          id: 'usage-$index',
          conversationId: 'conversation-1',
          providerId: 'provider',
          modelId: 'model',
          requestKind: index.isEven
              ? ModelUsageRequestKind.generation
              : ModelUsageRequestKind.compaction,
          outcome: index.isEven
              ? ModelUsageRequestOutcome.succeeded
              : ModelUsageRequestOutcome.failed,
          usage: const .new(
            promptTokens: 1,
            responseTokens: 2,
            totalTokens: 3,
            cacheReadInputTokens: 4,
            cacheCreationInputTokens: 5,
          ),
          costStatus: index == 511
              ? ModelUsageCostStatus.unknown
              : ModelUsageCostStatus.known,
          costUsd: index == 511 ? null : 0.001,
          createdAt: .utc(2026).add(.new(microseconds: index)),
        ),
      );
      final repository = _TrackingModelUsageRepository(records);
      final container = ProviderContainer(
        overrides: [modelUsageRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final details = await container.read(
        modelUsageDetailsForConversationProvider('conversation-1').future,
      );

      expect(details.records, same(records));
      expect(details.records.first.id, 'usage-0');
      expect(details.records.last.id, 'usage-511');
      expect(details.totals.requestCount, 512);
      expect(details.totals.succeededRequestCount, 256);
      expect(details.totals.failedRequestCount, 256);
      expect(details.totals.promptTokens, 512);
      expect(details.totals.responseTokens, 1024);
      expect(details.totals.totalTokens, 1536);
      expect(details.totals.cacheReadInputTokens, 2048);
      expect(details.totals.cacheCreationInputTokens, 2560);
      expect(details.totals.costStatus, ModelUsageCostStatus.unknown);
      expect(details.totals.costUsd, isNull);
      expect(repository.rowLoadCount, 1);
      expect(repository.totalsCallCount, 0);
    },
  );

  test('returns empty totals from one loaded record list', () async {
    final repository = _TrackingModelUsageRepository(const []);
    final container = ProviderContainer(
      overrides: [modelUsageRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final details = await container.read(
      modelUsageDetailsForConversationProvider('conversation-1').future,
    );

    expect(details.records, isEmpty);
    expect(details.totals.requestCount, 0);
    expect(details.totals.succeededRequestCount, 0);
    expect(details.totals.failedRequestCount, 0);
    expect(details.totals.promptTokens, isNull);
    expect(details.totals.responseTokens, isNull);
    expect(details.totals.totalTokens, isNull);
    expect(details.totals.cacheReadInputTokens, isNull);
    expect(details.totals.cacheCreationInputTokens, isNull);
    expect(details.totals.costStatus, ModelUsageCostStatus.unknown);
    expect(details.totals.costUsd, isNull);
    expect(repository.rowLoadCount, 1);
    expect(repository.totalsCallCount, 0);
  });
}

class _TrackingModelUsageRepository implements ModelUsageRepository {
  new(this._records);

  int rowLoadCount = 0;
  int totalsCallCount = 0;
  final List<ModelUsageRecord> _records;

  @override
  Future<ModelUsageRecord> recordRequest(ModelUsageRecordInput input) =>
      throw UnimplementedError();

  @override
  Future<List<ModelUsageRecord>> getRecordsForConversation(
    String conversationId,
  ) async {
    rowLoadCount++;

    return _records;
  }

  @override
  Future<ModelUsageTotals> getTotalsForConversation(
    String conversationId,
  ) async {
    totalsCallCount++;

    return ModelUsageAggregation.aggregate(
      await getRecordsForConversation(conversationId),
    );
  }
}
