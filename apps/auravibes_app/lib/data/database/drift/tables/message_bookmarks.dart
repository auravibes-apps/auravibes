// coverage:ignore-file
// Required: Drift table DSL is unreachable at runtime.
// DCL cannot score Drift's generated table behavior from schema declarations.
// ignore_for_file: number-of-methods, weight-of-class
import 'package:auravibes_app/data/database/drift/tables/conversations.dart';
import 'package:auravibes_app/data/database/drift/tables/table_mixin.dart';
import 'package:drift/drift.dart';

@DataClassName('MessageBookmarksTable')
class MessageBookmarks extends Table with TableMixin {
  TextColumn get conversationId =>
      text().references(Conversations, #id, onDelete: .cascade)();
  TextColumn get contentSnapshot => text()();
  BoolColumn get isUser => boolean()();
  DateTimeColumn get messageCreatedAt => dateTime()();
}
