// coverage:ignore-file
// Required: Drift table DSL is unreachable at runtime.
// (See api_models.dart).
import 'package:auravibes_app/data/database/drift/tables/skills.dart';
import 'package:auravibes_app/data/database/drift/tables/table_mixin.dart';
import 'package:drift/drift.dart';

@DataClassName('SkillTemplateToolsTable')
class SkillTemplateTools extends Table with TableMixin {
  TextColumn get skillId => text().references(
    Skills,
    #id,
    onDelete: KeyAction.cascade,
  )();

  TextColumn get templateType => textEnum<SkillTemplateToolTypeTable>()();

  TextColumn get title => text()();

  TextColumn get description => text().withDefault(const Constant(''))();

  TextColumn get slug => text()();

  TextColumn get templateJson => text()();

  TextColumn get inputsJson => text()();

  BoolColumn get requiresCredential =>
      boolean().withDefault(const Constant(false))();

  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {skillId, title},
    {skillId, slug},
  ];
}

enum SkillTemplateToolTypeTable {
  url('url');

  const SkillTemplateToolTypeTable(this.value);
  final String value;
}
