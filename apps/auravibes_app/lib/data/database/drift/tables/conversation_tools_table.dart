import 'package:auravibes_app/data/database/drift/tables/common.dart';
import 'package:auravibes_app/data/database/drift/tables/conversations_table.dart';
import 'package:auravibes_app/data/database/drift/tables/tools_table.dart';
import 'package:drift/drift.dart';

export 'package:auravibes_app/data/database/drift/enums/permission_access.dart';

@DataClassName('ConversationToolsTable')
class ConversationTools extends Table with TableMixin {
  /// Reference to the conversation this tool setting belongs to
  TextColumn get conversationId => text().references(Conversations, #id)();

  TextColumn get toolId => text().references(Tools, #id)();

  /// Whether the tool is enabled for this workspace
  BoolColumn get isEnabled => boolean().withDefault(const Constant(false))();

  TextColumn get permissions => textEnum<PermissionAccess>().withDefault(
    Constant(PermissionAccess.ask.name),
  )();

  @override
  Set<Column> get primaryKey => {conversationId, toolId};
}
