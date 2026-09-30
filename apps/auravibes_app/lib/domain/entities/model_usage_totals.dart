import 'package:auravibes_app/domain/entities/model_usage_record.dart';

class const ModelUsageTotals({
  required final int requestCount,
  required final int succeededRequestCount,
  required final int failedRequestCount,
  required final int? promptTokens,
  required final int? responseTokens,
  required final int? totalTokens,
  required final int? cacheReadInputTokens,
  required final int? cacheCreationInputTokens,
  required final ModelUsageCostStatus costStatus,
  required final double? costUsd,
}) {
  static ModelUsageTotals fromAggregation({
    required int requestCount,
    required ({int succeeded, int failed}) requestCounts,
    required ({
      int? prompt,
      int? response,
      int? total,
      int? cacheRead,
      int? cacheCreation,
    })
    tokenTotals,
    required ({ModelUsageCostStatus status, double? usd}) costTotals,
  }) => .new(
    requestCount: requestCount,
    succeededRequestCount: requestCounts.succeeded,
    failedRequestCount: requestCounts.failed,
    promptTokens: tokenTotals.prompt,
    responseTokens: tokenTotals.response,
    totalTokens: tokenTotals.total,
    cacheReadInputTokens: tokenTotals.cacheRead,
    cacheCreationInputTokens: tokenTotals.cacheCreation,
    costStatus: costTotals.status,
    costUsd: costTotals.usd,
  );
}
