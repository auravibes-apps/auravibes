import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/model_usage_records.dart';
import 'package:auravibes_app/domain/entities/model_usage_record_input.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:drift/drift.dart';

part 'model_usage_records_dao.g.dart';

@DriftAccessor(tables: [ModelUsageRecords])
class ModelUsageRecordsDao extends DatabaseAccessor<AppDatabase>
    with _$ModelUsageRecordsDaoMixin {
  new(super.attachedDatabase);

  Future<ModelUsageRecordsTable> recordRequest(ModelUsageRecordInput input) =>
      into(modelUsageRecords).insertReturning(_usageRecordCompanion(input));

  Future<List<ModelUsageRecordsTable>> getForConversation(
    String conversationId,
  ) =>
      (select(modelUsageRecords)
            ..where((record) => record.conversationId.equals(conversationId))
            ..orderBy([
              (record) => OrderingTerm.asc(record.createdAt),
              (record) => OrderingTerm.asc(record.id),
            ]))
          .get();
}

ModelUsageRecordsCompanion _usageRecordCompanion(ModelUsageRecordInput input) =>
    _withUsageCosts(
      _withCacheUsage(
        _withTokenUsage(_baseUsageCompanion(input), input.usage),
        input.usage,
      ),
      input.costUsd,
    );

ModelUsageRecordsCompanion _baseUsageCompanion(ModelUsageRecordInput input) =>
    ModelUsageRecordsCompanion.insert(
      conversationId: input.conversationId,
      providerId: input.providerId,
      modelId: input.modelId,
      requestKind: input.requestKind.name,
      outcome: input.outcome.name,
      usageReported: input.usage != null,
      costStatus: input.costStatus.name,
    );

ModelUsageRecordsCompanion _withTokenUsage(
  ModelUsageRecordsCompanion companion,
  LanguageModelUsage? usage,
) => companion.copyWith(
  promptTokens: .new(usage?.promptTokens),
  responseTokens: .new(usage?.responseTokens),
  totalTokens: .new(usage?.totalTokens),
);

ModelUsageRecordsCompanion _withCacheUsage(
  ModelUsageRecordsCompanion companion,
  LanguageModelUsage? usage,
) => companion.copyWith(
  cacheReadInputTokens: .new(usage?.cacheReadInputTokens),
  cacheCreationInputTokens: .new(usage?.cacheCreationInputTokens),
);

ModelUsageRecordsCompanion _withUsageCosts(
  ModelUsageRecordsCompanion companion,
  double? costUsd,
) => companion.copyWith(costUsd: .new(costUsd));
