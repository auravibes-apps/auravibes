import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/domain/entities/model_usage_aggregation.dart';
import 'package:auravibes_app/domain/entities/model_usage_record.dart';
import 'package:auravibes_app/domain/entities/model_usage_record_input.dart';
import 'package:auravibes_app/domain/entities/model_usage_totals.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

class const ModelUsageRepository(final AppDatabase _database) {
  Future<ModelUsageRecord> recordRequest(ModelUsageRecordInput input) async =>
      _mapRecord(await _database.modelUsageRecordsDao.recordRequest(input));

  Future<List<ModelUsageRecord>> getRecordsForConversation(
    String conversationId,
  ) async =>
      (await _database.modelUsageRecordsDao.getForConversation(conversationId))
          .map(_mapRecord)
          .toList();

  Future<ModelUsageTotals> getTotalsForConversation(
    String conversationId,
  ) async => ModelUsageAggregation.aggregate(
    await getRecordsForConversation(conversationId),
  );

  ModelUsageRecord _mapRecord(ModelUsageRecordsTable row) => ModelUsageRecord(
    id: row.id,
    conversationId: row.conversationId,
    providerId: row.providerId,
    modelId: row.modelId,
    requestKind: _requestKind(row.requestKind),
    outcome: _requestOutcome(row.outcome),
    usage: _reportedUsage(row),
    costStatus: _costStatus(row.costStatus),
    costUsd: row.costUsd,
    createdAt: row.createdAt,
  );
}

ModelUsageRequestKind _requestKind(String value) =>
    ModelUsageRequestKind.values.byName(value);

ModelUsageRequestOutcome _requestOutcome(String value) =>
    ModelUsageRequestOutcome.values.byName(value);

ModelUsageCostStatus _costStatus(String value) =>
    ModelUsageCostStatus.values.byName(value);

LanguageModelUsage? _reportedUsage(ModelUsageRecordsTable row) {
  if (!row.usageReported) return null;

  return LanguageModelUsage(
    promptTokens: row.promptTokens,
    responseTokens: row.responseTokens,
    totalTokens: row.totalTokens,
    cacheReadInputTokens: row.cacheReadInputTokens,
    cacheCreationInputTokens: row.cacheCreationInputTokens,
  );
}
