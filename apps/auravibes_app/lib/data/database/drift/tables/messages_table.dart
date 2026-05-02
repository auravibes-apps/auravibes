// coverage:ignore-file
// Required: Drift table DSL is unreachable at runtime
// (see api_model_table.dart).
import 'package:auravibes_app/data/database/drift/enums/message_table_enums.dart';
import 'package:auravibes_app/data/database/drift/tables/common.dart';
import 'package:auravibes_app/data/database/drift/tables/conversations_table.dart';
import 'package:drift/drift.dart';

export 'package:auravibes_app/data/database/drift/enums/message_table_enums.dart';

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
