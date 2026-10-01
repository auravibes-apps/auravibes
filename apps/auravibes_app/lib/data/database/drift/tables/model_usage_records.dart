// coverage:ignore-file
// Required: Drift table DSL is unreachable at runtime.
// (See api_models.dart).
// DCL cannot score Drift's generated table behavior from schema declarations.
// ignore_for_file: number-of-methods, weight-of-class
import 'package:auravibes_app/data/database/drift/tables/conversations.dart';
import 'package:auravibes_app/data/database/drift/tables/table_mixin.dart';
import 'package:drift/drift.dart';

@DataClassName('ModelUsageRecordsTable')
@TableIndex(
  name: 'model_usage_records_conversation_created_idx',
  columns: {#conversationId, #createdAt},
)
class ModelUsageRecords extends Table with TableMixin {
  TextColumn get conversationId =>
      text().references(Conversations, #id, onDelete: .cascade)();
  TextColumn get providerId => text()();
  TextColumn get modelId => text()();
  TextColumn get requestKind => text()();
  TextColumn get outcome => text()();
  BoolColumn get usageReported => boolean()();
  IntColumn get promptTokens => integer().nullable()();
  IntColumn get responseTokens => integer().nullable()();
  IntColumn get totalTokens => integer().nullable()();
  IntColumn get cacheReadInputTokens => integer().nullable()();
  IntColumn get cacheCreationInputTokens => integer().nullable()();
  TextColumn get costStatus => text()();
  RealColumn get costUsd => real().nullable()();
}
