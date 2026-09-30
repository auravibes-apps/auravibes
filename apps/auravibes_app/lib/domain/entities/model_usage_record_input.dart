import 'package:auravibes_app/domain/entities/model_usage_record.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

class const ModelUsageRecordInput({
  required final String conversationId,
  required final String providerId,
  required final String modelId,
  required final ModelUsageRequestKind requestKind,
  required final ModelUsageRequestOutcome outcome,
  required final LanguageModelUsage? usage,
  required final ModelUsageCostStatus costStatus,
  final double? costUsd,
});
