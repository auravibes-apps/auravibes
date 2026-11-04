// coverage:ignore-file
// Required: Drift table DSL is unreachable at runtime.
// (See api_models.dart).
// DCL cannot score Drift's generated table behavior from schema declarations.
// ignore_for_file: number-of-methods, weight-of-class
import 'package:auravibes_app/data/database/drift/tables/conversation_labels.dart';
import 'package:auravibes_app/data/database/drift/tables/conversations.dart';
import 'package:auravibes_app/data/database/drift/tables/table_mixin.dart';
import 'package:auravibes_app/data/database/drift/tables/workspaces.dart';
import 'package:drift/drift.dart';

@DataClassName('ConversationLabelAssignmentsTable')
@TableIndex.sql('''
CREATE UNIQUE INDEX conversation_label_assignments_identity
ON conversation_label_assignments (workspace_id, conversation_id, label_id)
''')
@TableIndex.sql('''
CREATE INDEX conversation_label_assignments_by_label
ON conversation_label_assignments (workspace_id, label_id, conversation_id)
''')
class ConversationLabelAssignments extends Table with TableMixin {
  TextColumn get workspaceId =>
      text().references(Workspaces, #id, onDelete: .cascade)();

  TextColumn get conversationId =>
      text().references(Conversations, #id, onDelete: .cascade)();

  TextColumn get labelId =>
      text().references(ConversationLabels, #id, onDelete: .cascade)();
}
