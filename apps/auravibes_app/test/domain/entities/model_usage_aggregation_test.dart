import 'package:auravibes_app/domain/entities/model_usage_aggregation.dart';
import 'package:auravibes_app/domain/entities/model_usage_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('empty history keeps usage and cost unavailable', () {
    final totals = ModelUsageAggregation.aggregate([]);

    expect(totals.requestCount, 0);
    expect(totals.succeededRequestCount, 0);
    expect(totals.failedRequestCount, 0);
    expect(totals.promptTokens, isNull);
    expect(totals.responseTokens, isNull);
    expect(totals.totalTokens, isNull);
    expect(totals.cacheReadInputTokens, isNull);
    expect(totals.cacheCreationInputTokens, isNull);
    expect(totals.costStatus, ModelUsageCostStatus.unknown);
    expect(totals.costUsd, isNull);
  });

  test(
    'missing request values stay unknown instead of becoming partial totals',
    () {
      final totals = ModelUsageAggregation.aggregate([
        ModelUsageRecord(
          id: 'known',
          conversationId: 'conversation',
          providerId: 'provider',
          modelId: 'model',
          requestKind: .generation,
          outcome: .succeeded,
          usage: const .new(
            promptTokens: 10,
            responseTokens: 5,
            totalTokens: 15,
            cacheReadInputTokens: 2,
            cacheCreationInputTokens: 1,
          ),
          costStatus: .known,
          costUsd: 0.01,
          createdAt: .utc(2026),
        ),
        ModelUsageRecord(
          id: 'unknown',
          conversationId: 'conversation',
          providerId: 'provider',
          modelId: 'model',
          requestKind: .compaction,
          outcome: .failed,
          usage: null,
          costStatus: .unknown,
          costUsd: null,
          createdAt: .utc(2026, 1, 2),
        ),
      ]);

      expect(totals.requestCount, 2);
      expect(totals.promptTokens, isNull);
      expect(totals.responseTokens, isNull);
      expect(totals.totalTokens, isNull);
      expect(totals.cacheReadInputTokens, isNull);
      expect(totals.cacheCreationInputTokens, isNull);
      expect(totals.costStatus, ModelUsageCostStatus.unknown);
      expect(totals.costUsd, isNull);
    },
  );
}
