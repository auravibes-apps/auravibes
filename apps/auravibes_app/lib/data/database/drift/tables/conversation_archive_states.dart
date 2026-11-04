// coverage:ignore-file
// Required: Drift table DSL is unreachable at runtime.
// Drift generates behavior for these schema getters.
// ignore_for_file: weight-of-class
import 'package:auravibes_app/data/database/drift/tables/workspaces.dart';
import 'package:drift/drift.dart';

@DataClassName('ConversationArchiveStateTable')
class ConversationArchiveStates extends Table {
  TextColumn get workspaceId =>
      text().references(Workspaces, #id, onDelete: .cascade)();
  TextColumn get conversationId => text()();
  DateTimeColumn get archivedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {workspaceId, conversationId};
}
