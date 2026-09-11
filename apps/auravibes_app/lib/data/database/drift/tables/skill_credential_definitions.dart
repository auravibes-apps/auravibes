// coverage:ignore-file
// Required: Drift table DSL is unreachable at runtime.
// (See api_models.dart).
import 'package:auravibes_app/data/database/drift/tables/table_mixin.dart';
import 'package:auravibes_app/data/database/drift/tables/workspaces.dart';
import 'package:drift/drift.dart';

@DataClassName('SkillCredentialDefinitionsTable')
class SkillCredentialDefinitions extends Table with TableMixin {
  late final workspaceId = text().references(
    Workspaces,
    #id,
    onDelete: .cascade,
  )();

  late final title = text()();

  late final slug = text()();

  late final attributesJson = text()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {workspaceId, title},
    {workspaceId, slug},
  ];

  bool isUniqueColumn(Column column) =>
      uniqueKeys.any((key) => key.contains(column));
}
