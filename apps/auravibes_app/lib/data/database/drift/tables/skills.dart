// coverage:ignore-file
// Required: Drift table DSL is unreachable at runtime.
// (See api_models.dart).
import 'package:auravibes_app/data/database/drift/tables/skill_credential_definitions.dart';
import 'package:auravibes_app/data/database/drift/tables/table_mixin.dart';
import 'package:auravibes_app/data/database/drift/tables/workspaces.dart';
import 'package:drift/drift.dart';

@DataClassName('SkillsTable')
class Skills extends Table with TableMixin {
  late final workspaceId = text().references(
    Workspaces,
    #id,
    onDelete: .cascade,
  )();

  late final source = textEnum<SkillSourceTable>()();

  late final kind = textEnum<SkillKindTable>()();

  late final title = text()();

  late final slug = text()();

  late final description = text()();

  late final content = text()();

  late final credentialDefinitionId = text().nullable().references(
    SkillCredentialDefinitions,
    #id,
    onDelete: .setNull,
  )();

  late final isCredentialOptional = boolean().withDefault(
    const Constant(false),
  )();

  late final isEnabled = boolean().withDefault(const Constant(true))();

  @override
  late final List<Set<Column<Object>>> uniqueKeys = [
    {workspaceId, title},
    {workspaceId, slug},
  ];
}

enum SkillSourceTable(final String value) {
  user('user'),
  app('app'),
}

enum SkillKindTable(final String value) {
  template('template'),
  native('native'),
}
