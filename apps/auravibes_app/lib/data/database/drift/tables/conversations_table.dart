// coverage:ignore-file
// Required: Drift table DSL is unreachable at runtime
// (see api_model_table.dart).
import 'package:auravibes_app/data/database/drift/tables/common.dart';
import 'package:auravibes_app/data/database/drift/tables/workspace_model_selections_table.dart';
import 'package:auravibes_app/data/database/drift/tables/workspaces_table.dart';
import 'package:drift/drift.dart';

@DataClassName('ConversationsTable')
class Conversations extends Table with TableMixin {
  TextColumn get workspaceId => text().references(
    Workspaces,
    #id,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get title => text()();
  TextColumn get modelId =>
      text().nullable().references(WorkspaceModelSelections, #id)();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
}
