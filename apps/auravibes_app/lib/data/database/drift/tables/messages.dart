// coverage:ignore-file
// Required: Drift table DSL is unreachable at runtime.
// (See api_models.dart).
import 'package:auravibes_app/data/database/drift/enums/messages_table_type.dart';
import 'package:auravibes_app/data/database/drift/tables/conversations.dart';
import 'package:auravibes_app/data/database/drift/tables/table_mixin.dart';
import 'package:drift/drift.dart';

export 'package:auravibes_app/data/database/drift/enums/messages_table_type.dart';

@DataClassName('MessagesTable')
class Messages extends Table with TableMixin {
  late final conversationId = text().references(
    Conversations,
    #id,
    onDelete: .cascade,
  )();
  late final content = text()();
  late final messageType = textEnum<MessagesTableType>()();
  late final isUser = boolean()();
  late final status = textEnum<MessageTableStatus>()();
  late final metadata = text().nullable()();
}
