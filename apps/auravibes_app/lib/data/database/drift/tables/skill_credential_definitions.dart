// coverage:ignore-file
// Required: Drift table DSL is unreachable at runtime.
// (See api_models.dart).
// DCL cannot score Drift's generated table behavior from schema declarations.
// ignore_for_file: number-of-methods, weight-of-class
import 'package:auravibes_app/data/database/drift/tables/table_mixin.dart';
import 'package:auravibes_app/data/database/drift/tables/workspaces.dart';
import 'package:drift/drift.dart';

@DataClassName('SkillCredentialDefinitionsTable')
class SkillCredentialDefinitions extends Table with TableMixin {
  TextColumn get workspaceId =>
      text().references(Workspaces, #id, onDelete: .cascade)();

  TextColumn get title => text()();

  TextColumn get slug => text()();

  TextColumn get attributesJson => text()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {workspaceId, title},
    {workspaceId, slug},
  ];
}
