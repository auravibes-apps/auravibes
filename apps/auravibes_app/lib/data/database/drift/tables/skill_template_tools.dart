// coverage:ignore-file
// Required: Drift table DSL is unreachable at runtime.
// (See api_models.dart).
import 'package:auravibes_app/data/database/drift/tables/skills.dart';
import 'package:auravibes_app/data/database/drift/tables/table_mixin.dart';
import 'package:drift/drift.dart';

@DataClassName('SkillTemplateToolsTable')
class SkillTemplateTools extends Table with TableMixin {
  late final skillId = text().references(Skills, #id, onDelete: .cascade)();

  late final templateType = textEnum<SkillTemplateToolTypeTable>()();

  late final title = text()();

  late final description = text().withDefault(const Constant(''))();

  late final slug = text()();

  late final templateJson = text()();

  late final inputsJson = text()();

  late final requiresCredential = boolean().withDefault(
    const Constant(false),
  )();

  late final isEnabled = boolean().withDefault(const Constant(true))();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {skillId, title},
    {skillId, slug},
  ];

  bool isUniqueColumn(Column column) =>
      uniqueKeys.any((key) => key.contains(column));
}

enum SkillTemplateToolTypeTable(final String value) {
  url('url'),
}
