// coverage:ignore-file
// Required: Drift table DSL is unreachable at runtime.
// DCL cannot score Drift's generated table behavior from schema declarations.
// ignore_for_file: number-of-methods, weight-of-class
import 'package:auravibes_app/data/database/drift/tables/skills.dart';
import 'package:auravibes_app/data/database/drift/tables/table_mixin.dart';
import 'package:drift/drift.dart';

@DataClassName('SkillResourcesTable')
class SkillResources extends Table with TableMixin {
  TextColumn get skillId =>
      text().references(Skills, #id, onDelete: .cascade)();

  TextColumn get title => text()();

  TextColumn get slug => text()();

  TextColumn get description => text().withDefault(const Constant(''))();

  TextColumn get content => text()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {skillId, slug},
  ];
}
