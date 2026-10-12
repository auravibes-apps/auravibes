// coverage:ignore-file
// Required: Drift table DSL is unreachable at runtime.
// (See api_models.dart).
// DCL cannot score Drift's generated table behavior from schema declarations.
// ignore_for_file: number-of-methods, weight-of-class
import 'package:auravibes_app/data/database/drift/tables/conversations.dart';
import 'package:auravibes_app/data/database/drift/tables/messages.dart';
import 'package:auravibes_app/data/database/drift/tables/table_mixin.dart';
import 'package:auravibes_app/data/database/drift/tables/workspaces.dart';
import 'package:drift/drift.dart';

@DataClassName('BackgroundWorkTable')
@TableIndex(
  name: 'background_works_conversation_created_idx',
  columns: {#conversationId, #createdAt, #id},
)
class BackgroundWorks extends Table with TableMixin {
  TextColumn get workspaceId =>
      text().references(Workspaces, #id, onDelete: .cascade)();
  TextColumn get conversationId =>
      text().references(Conversations, #id, onDelete: .cascade)();
  TextColumn get originatingMessageId =>
      text().nullable().references(Messages, #id, onDelete: .setNull)();
  TextColumn get toolCallId => text()();
  TextColumn get toolKind => text()();
  TextColumn get status => text()();
  TextColumn get statusPreview => text().nullable().customConstraint('''
    CHECK(status_preview IS NULL OR
      length(CAST(status_preview AS BLOB)) <= 512)
  ''')();
  TextColumn get resultContent => text().nullable().customConstraint('''
    CHECK(result_content IS NULL OR
      length(CAST(result_content AS BLOB)) <= 262144)
  ''')();
  IntColumn get resultByteLength => integer().withDefault(const Constant(0))();
  TextColumn get errorCode => text().nullable()();
}
