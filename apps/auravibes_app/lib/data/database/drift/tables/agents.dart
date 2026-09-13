// coverage:ignore-file
// Required: Drift table DSL is unreachable at runtime.
// (See api_models.dart).
// DCL cannot score Drift's generated table behavior from schema declarations.
// ignore_for_file: number-of-methods, weight-of-class
import 'package:auravibes_app/data/database/drift/tables/table_mixin.dart';
import 'package:auravibes_app/data/database/drift/tables/workspaces.dart';
import 'package:drift/drift.dart';

@DataClassName('AgentsTable')
@TableIndex.sql('''
CREATE INDEX agents_workspace_name_id
ON agents (workspace_id, name COLLATE NOCASE, id)
''')
class Agents extends Table with TableMixin {
  TextColumn get workspaceId =>
      text().references(Workspaces, #id, onDelete: .cascade)();

  TextColumn get name => text()();

  TextColumn get description => text().withDefault(const Constant(''))();

  TextColumn get content => text()();

  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();

  TextColumn get visibility => text().withDefault(const Constant('both'))();
}
