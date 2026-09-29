import 'package:auravibes_app/domain/entities/model_usage_record.dart';
import 'package:auravibes_app/domain/entities/model_usage_totals.dart';

ModelUsageTotals aggregateModelUsageRecords(List<ModelUsageRecord> records) {
  final knownCosts = records.every(
    (record) =>
        record.costStatus == ModelUsageCostStatus.known &&
        record.costUsd != null,
  );
  final totalCost = knownCosts
      ? records.fold<double>(
          0,
          (total, record) => total + (record.costUsd ?? 0),
        )
      : null;

  return ModelUsageTotals(
    requestCount: records.length,
    succeededRequestCount: records
        .where((record) => record.outcome == ModelUsageRequestOutcome.succeeded)
        .length,
    failedRequestCount: records
        .where((record) => record.outcome == ModelUsageRequestOutcome.failed)
        .length,
    promptTokens: _sumComplete(
      records.map((record) => record.usage?.promptTokens),
    ),
    responseTokens: _sumComplete(
      records.map((record) => record.usage?.responseTokens),
    ),
    totalTokens: _sumComplete(
      records.map((record) => record.usage?.totalTokens),
    ),
    cacheReadInputTokens: _sumComplete(
      records.map((record) => record.usage?.cacheReadInputTokens),
    ),
    cacheCreationInputTokens: _sumComplete(
      records.map((record) => record.usage?.cacheCreationInputTokens),
    ),
    costStatus: knownCosts
        ? ModelUsageCostStatus.known
        : ModelUsageCostStatus.unknown,
    costUsd: totalCost,
  );
}

int? _sumComplete(Iterable<int?> values) {
  var total = 0;
  for (final value in values) {
    if (value == null) return null;
    total += value;
  }

  return total;
}
