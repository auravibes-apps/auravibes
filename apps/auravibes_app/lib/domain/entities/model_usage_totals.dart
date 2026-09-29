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
});
