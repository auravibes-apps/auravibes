import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/model_usage_records.dart';
import 'package:auravibes_app/domain/entities/model_usage_record_input.dart';
import 'package:drift/drift.dart';

part 'model_usage_records_dao.g.dart';

@DriftAccessor(tables: [ModelUsageRecords])
class ModelUsageRecordsDao extends DatabaseAccessor<AppDatabase>
    with _$ModelUsageRecordsDaoMixin {
  new(super.attachedDatabase);

  Future<ModelUsageRecordsTable> recordRequest(ModelUsageRecordInput input) =>
      into(modelUsageRecords).insertReturning(
        ModelUsageRecordsCompanion.insert(
          conversationId: input.conversationId,
          providerId: input.providerId,
          modelId: input.modelId,
          requestKind: input.requestKind.name,
          outcome: input.outcome.name,
          usageReported: input.usage != null,
          promptTokens: .new(input.usage?.promptTokens),
          responseTokens: .new(input.usage?.responseTokens),
          totalTokens: .new(input.usage?.totalTokens),
          cacheReadInputTokens: .new(input.usage?.cacheReadInputTokens),
          cacheCreationInputTokens: .new(input.usage?.cacheCreationInputTokens),
          costStatus: input.costStatus.name,
          costUsd: .new(input.costUsd),
        ),
      );

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
