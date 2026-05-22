// coverage:ignore-file
// Required: Drift table DSL is unreachable at runtime
// (see api_models.dart).
import 'package:auravibes_app/data/database/drift/enums/messages_table_type.dart';
import 'package:auravibes_app/data/database/drift/tables/conversations.dart';
import 'package:auravibes_app/data/database/drift/tables/table_mixin.dart';
import 'package:drift/drift.dart';

export 'package:auravibes_app/data/database/drift/enums/messages_table_type.dart';

@DataClassName('MessagesTable')
class Messages extends Table with TableMixin {
  TextColumn get conversationId => text().references(
    Conversations,
    #id,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get content => text()();
  TextColumn get messageType => textEnum<MessagesTableType>()();
  BoolColumn get isUser => boolean()();
  TextColumn get status => textEnum<MessageTableStatus>()();
  TextColumn get metadata => text().nullable()();
}
