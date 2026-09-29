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
  ) async => aggregateModelUsageRecords(
    await getRecordsForConversation(conversationId),
  );

  ModelUsageRecord _mapRecord(ModelUsageRecordsTable row) => ModelUsageRecord(
    id: row.id,
    conversationId: row.conversationId,
    providerId: row.providerId,
    modelId: row.modelId,
    requestKind: ModelUsageRequestKind.values.byName(row.requestKind),
    outcome: ModelUsageRequestOutcome.values.byName(row.outcome),
    usage: row.usageReported
        ? LanguageModelUsage(
            promptTokens: row.promptTokens,
            responseTokens: row.responseTokens,
            totalTokens: row.totalTokens,
            cacheReadInputTokens: row.cacheReadInputTokens,
            cacheCreationInputTokens: row.cacheCreationInputTokens,
          )
        : null,
    costStatus: ModelUsageCostStatus.values.byName(row.costStatus),
    costUsd: row.costUsd,
    createdAt: row.createdAt,
  );
}
