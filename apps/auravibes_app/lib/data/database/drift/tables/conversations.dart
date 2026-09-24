// coverage:ignore-file
// Required: Drift table DSL is unreachable at runtime.
// (See api_models.dart).
// DCL cannot score Drift's generated table behavior from schema declarations.
// ignore_for_file: number-of-methods, weight-of-class
import 'package:auravibes_app/data/database/drift/tables/agents.dart';
import 'package:auravibes_app/data/database/drift/tables/table_mixin.dart';
import 'package:auravibes_app/data/database/drift/tables/workspace_model_selections.dart';
import 'package:auravibes_app/data/database/drift/tables/workspaces.dart';
import 'package:drift/drift.dart';

@DataClassName('ConversationsTable')
@TableIndex.sql('''
CREATE INDEX conversations_workspace_parent_updated_id
ON conversations (
  workspace_id,
  parent_conversation_id,
  is_pinned DESC,
  updated_at DESC,
  id DESC
)
''')
@TableIndex(
  name: 'conversations_fork_source_idx',
  columns: {#forkSourceConversationId},
)
class Conversations extends Table with TableMixin {
  TextColumn get workspaceId =>
      text().references(Workspaces, #id, onDelete: .cascade)();
  TextColumn get title => text()();
  TextColumn get modelId => text().nullable().references(
    WorkspaceModelSelections,
    #id,
    onDelete: .setNull,
  )();
  TextColumn get agentId =>
      text().nullable().references(Agents, #id, onDelete: .setNull)();

  /// JSON-encoded conversation-scoped reasoning override.
  TextColumn get reasoningConfigJson => text().nullable()();
  TextColumn get parentConversationId =>
      text().nullable().references(Conversations, #id, onDelete: .cascade)();

  /// Stable id of the conversation this fork snapshots.
  ///
  /// This is intentionally not a foreign key. A source conversation can be
  /// purged after its history has been materialized while the fork keeps the
  /// provenance for display.
  TextColumn get forkSourceConversationId => text().nullable()();

  /// Source title captured when the fork is created.
  TextColumn get forkSourceTitle => text().nullable()();

  /// Inclusive terminal message boundary captured by the fork.
  TextColumn get forkThroughMessageId => text().nullable()();

  /// Non-null after the source history has been materialized into this fork.
  DateTimeColumn get forkMaterializedAt => dateTime().nullable()();

  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
}
