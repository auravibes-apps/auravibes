// coverage:ignore-file
// Required: Drift table DSL is unreachable at runtime.
// (See api_models.dart).
import 'package:auravibes_app/data/database/drift/tables/conversations.dart';
import 'package:auravibes_app/data/database/drift/tables/table_mixin.dart';
import 'package:auravibes_app/data/database/drift/tables/tools.dart';
import 'package:drift/drift.dart';

export 'package:auravibes_app/data/database/drift/enums/permission_access.dart';

@DataClassName('ConversationToolsTable')
class ConversationTools extends Table with TableMixin {
  /// Reference to the conversation this tool setting belongs to.
  late final conversationId = text().references(
    Conversations,
    #id,
    onDelete: .cascade,
  )();

  late final toolId = text().references(Tools, #id, onDelete: .cascade)();

  /// Whether the tool is enabled for this workspace.
  late final isEnabled = boolean().withDefault(const Constant(false))();

  late final permissions = textEnum<PermissionAccess>().withDefault(
    Constant(PermissionAccess.ask.name),
  )();

  @override
  Set<Column> get primaryKey => {conversationId, toolId};

  @override
  bool isPrimaryKeyColumn(Column column) => primaryKey.contains(column);
}
