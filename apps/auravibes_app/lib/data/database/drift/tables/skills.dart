// coverage:ignore-file
// Required: Drift table DSL is unreachable at runtime.
// (See api_models.dart).
import 'package:auravibes_app/data/database/drift/tables/skill_credential_definitions.dart';
import 'package:auravibes_app/data/database/drift/tables/table_mixin.dart';
import 'package:auravibes_app/data/database/drift/tables/workspaces.dart';
import 'package:drift/drift.dart';

@DataClassName('SkillsTable')
class Skills extends Table with TableMixin {
  TextColumn get workspaceId =>
      text().references(Workspaces, #id, onDelete: KeyAction.cascade)();

  TextColumn get source => textEnum<SkillSourceTable>()();

  TextColumn get kind => textEnum<SkillKindTable>()();

  TextColumn get title => text()();

  TextColumn get slug => text()();

  TextColumn get description => text()();

  TextColumn get content => text()();

  TextColumn get credentialDefinitionId => text().nullable().references(
    SkillCredentialDefinitions,
    #id,
    onDelete: KeyAction.setNull,
  )();

  BoolColumn get isCredentialOptional =>
      boolean().withDefault(const Constant(false))();

  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
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
