// coverage:ignore-file
// Required: Drift table DSL is unreachable at runtime.
// (See api_models.dart).
import 'package:auravibes_app/data/database/drift/tables/agents.dart';
import 'package:auravibes_app/data/database/drift/tables/table_mixin.dart';
import 'package:auravibes_app/data/database/drift/tables/workspace_model_selections.dart';
import 'package:auravibes_app/data/database/drift/tables/workspaces.dart';
import 'package:drift/drift.dart';

@DataClassName('ConversationsTable')
class Conversations extends Table with TableMixin {
  TextColumn get workspaceId =>
      text().references(Workspaces, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  TextColumn get modelId => text().nullable().references(
    WorkspaceModelSelections,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get agentId =>
      text().nullable().references(Agents, #id, onDelete: KeyAction.setNull)();
  TextColumn get parentConversationId => text().nullable().references(
    Conversations,
    #id,
    onDelete: KeyAction.cascade,
  )();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
}
