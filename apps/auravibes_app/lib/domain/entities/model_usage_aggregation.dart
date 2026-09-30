import 'package:auravibes_app/domain/entities/model_usage_record.dart';
import 'package:auravibes_app/domain/entities/model_usage_totals.dart';
import 'package:auravibes_engine/auravibes_engine.dart' show LanguageModelUsage;

typedef _RequestCounts = ({int succeeded, int failed});

typedef _TokenTotals = ({
  int? prompt,
  int? response,
  int? total,
  int? cacheRead,
  int? cacheCreation,
});

typedef _CostTotals = ({ModelUsageCostStatus status, double? usd});

abstract final class ModelUsageAggregation {
  static ModelUsageTotals aggregate(List<ModelUsageRecord> records) {
    final counts = _requestCounts(records);
    final tokens = _tokenTotals(records);
    final costs = _costTotals(records);

    return ModelUsageTotals.fromAggregation(
      requestCount: records.length,
      requestCounts: counts,
      tokenTotals: tokens,
      costTotals: costs,
    );
  }
}

_RequestCounts _requestCounts(List<ModelUsageRecord> records) => (
  succeeded: records
      .where((record) => record.outcome == ModelUsageRequestOutcome.succeeded)
      .length,
  failed: records
      .where((record) => record.outcome == ModelUsageRequestOutcome.failed)
      .length,
);

_TokenTotals _tokenTotals(List<ModelUsageRecord> records) {
  final usages = records.map((record) => record.usage).toList();

  return (
    prompt: _sumUsageValues(usages, _promptTokens),
    response: _sumUsageValues(usages, _responseTokens),
    total: _sumUsageValues(usages, _totalTokens),
    cacheRead: _sumUsageValues(usages, _cacheReadTokens),
    cacheCreation: _sumUsageValues(usages, _cacheCreationTokens),
  );
}

int? _sumUsageValues(
  List<LanguageModelUsage?> usages,
  int? Function(LanguageModelUsage?) select,
) => _sumComplete(usages.map(select));

int? _promptTokens(LanguageModelUsage? usage) => usage?.promptTokens;

int? _responseTokens(LanguageModelUsage? usage) => usage?.responseTokens;

int? _totalTokens(LanguageModelUsage? usage) => usage?.totalTokens;

int? _cacheReadTokens(LanguageModelUsage? usage) => usage?.cacheReadInputTokens;

int? _cacheCreationTokens(LanguageModelUsage? usage) =>
    usage?.cacheCreationInputTokens;

_CostTotals _costTotals(List<ModelUsageRecord> records) {
  final known = _hasCompleteCosts(records);

  return (
    status: known ? ModelUsageCostStatus.known : ModelUsageCostStatus.unknown,
    usd: known ? _sumCosts(records) : null,
  );
}

bool _hasCompleteCosts(List<ModelUsageRecord> records) =>
    records.isNotEmpty &&
    records.every(
      (record) =>
          record.costStatus == ModelUsageCostStatus.known &&
          record.costUsd != null,
    );

double _sumCosts(List<ModelUsageRecord> records) =>
    records.fold<double>(0, (total, record) => total + (record.costUsd ?? 0));

int? _sumComplete(Iterable<int?> values) {
  var total = 0;
  var hasValue = false;
  for (final value in values) {
    if (value == null) return null;
    total += value;
    hasValue = true;
  }

  return hasValue ? total : null;
}
