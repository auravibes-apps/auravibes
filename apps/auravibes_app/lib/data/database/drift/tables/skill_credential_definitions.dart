// ignore_for_file: format-comment
// Required: Existing comments use generated or domain-specific formatting.
// coverage:ignore-file
// Required: Drift table DSL is unreachable at runtime
// (see api_models.dart).
import 'package:auravibes_app/data/database/drift/tables/table_mixin.dart';
import 'package:auravibes_app/data/database/drift/tables/workspaces.dart';
import 'package:drift/drift.dart';

@DataClassName('SkillCredentialDefinitionsTable')
class SkillCredentialDefinitions extends Table with TableMixin {
  TextColumn get workspaceId => text().references(
    Workspaces,
    #id,
    onDelete: KeyAction.cascade,
  )();

  TextColumn get title => text()();

  TextColumn get slug => text()();

  TextColumn get attributesJson => text()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {workspaceId, title},
    {workspaceId, slug},
  ];
}
