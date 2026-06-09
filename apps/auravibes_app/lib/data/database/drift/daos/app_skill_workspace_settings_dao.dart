// ignore_for_file: prefer-async-await
// Required: Existing Future chains preserve callback flow.
// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/app_skill_workspace_settings.dart';
import 'package:drift/drift.dart';

part 'app_skill_workspace_settings_dao.g.dart';

@DriftAccessor(tables: [AppSkillWorkspaceSettings])
class AppSkillWorkspaceSettingsDao extends DatabaseAccessor<AppDatabase>
    with _$AppSkillWorkspaceSettingsDaoMixin {
  AppSkillWorkspaceSettingsDao(super.attachedDatabase);

  Future<AppSkillWorkspaceSettingsTable?> getSetting(
    String workspaceId,
    String appSkillIdentifier,
  ) =>
      (select(appSkillWorkspaceSettings)..where(
            (tbl) =>
                tbl.workspaceId.equals(workspaceId) &
                tbl.appSkillIdentifier.equals(appSkillIdentifier),
          ))
          .getSingleOrNull();

  Future<bool> isAppSkillEnabled(
    String workspaceId,
    String appSkillIdentifier,
  ) async {
    final setting = await getSetting(workspaceId, appSkillIdentifier);

    return setting?.isEnabled ?? true;
  }

  Future<AppSkillWorkspaceSettingsTable> setAppSkillEnabled(
    String workspaceId,
    String appSkillIdentifier, {
    required bool isEnabled,
  }) async {
    final existing = await getSetting(workspaceId, appSkillIdentifier);
    if (existing == null) {
      return into(appSkillWorkspaceSettings).insertReturning(
        AppSkillWorkspaceSettingsCompanion(
          workspaceId: Value(workspaceId),
          appSkillIdentifier: Value(appSkillIdentifier),
          isEnabled: Value(isEnabled),
        ),
      );
    }

    final _ =
        await (update(appSkillWorkspaceSettings)..where(
              (tbl) => tbl.id.equals(existing.id),
            ))
            .write(
              AppSkillWorkspaceSettingsCompanion(
                updatedAt: Value(DateTime.now()),
                isEnabled: Value(isEnabled),
              ),
            );
    final updated = await getSetting(workspaceId, appSkillIdentifier);
    if (updated == null) {
      throw StateError('Updated app skill workspace setting was not found');
    }

    return updated;
  }
}
