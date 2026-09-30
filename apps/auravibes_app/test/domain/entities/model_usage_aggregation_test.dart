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
}
