import 'package:auravibes_engine/auravibes_engine.dart';

class const ModelUsageRecord({
  required final String id,
  required final String conversationId,
  required final String providerId,
  required final String modelId,
  required final ModelUsageRequestKind requestKind,
  required final ModelUsageRequestOutcome outcome,
  required final LanguageModelUsage? usage,
  required final ModelUsageCostStatus costStatus,
  required final double? costUsd,
  required final DateTime createdAt,
});

enum ModelUsageRequestKind { generation, compaction, cacheWarm }

enum ModelUsageRequestOutcome { succeeded, failed }

enum ModelUsageCostStatus { known, unknown }
