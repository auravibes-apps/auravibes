// coverage:ignore-file
// Required: Drift table DSL is unreachable at runtime.
// (See api_models.dart).
import 'package:auravibes_app/data/database/drift/tables/table_mixin.dart';
import 'package:auravibes_app/data/database/drift/tables/workspaces.dart';
import 'package:drift/drift.dart';

@DataClassName('AppSkillWorkspaceSettingsTable')
@TableIndex(
  name: 'app_skill_workspace_settings_workspace_app_skill',
  columns: {#workspaceId, #appSkillIdentifier},
  unique: true,
)
class AppSkillWorkspaceSettings extends Table with TableMixin {
  TextColumn get workspaceId => text().references(
    Workspaces,
    #id,
    onDelete: KeyAction.cascade,
  )();

  TextColumn get appSkillIdentifier => text()();

  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
}
