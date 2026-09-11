import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/app_skill_workspace_settings.dart';
import 'package:auravibes_engine/auravibes_engine.dart' as agent;
import 'package:drift/drift.dart';

part 'app_skill_workspace_settings_dao.g.dart';

@DriftAccessor(tables: [AppSkillWorkspaceSettings])
class AppSkillWorkspaceSettingsDao(super.attachedDatabase)
    extends DatabaseAccessor<AppDatabase>
    with _$AppSkillWorkspaceSettingsDaoMixin;

extension AppSkillWorkspaceSettingsDaoMethods on AppSkillWorkspaceSettingsDao {
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

    return setting?.isEnabled ??
        appSkillIdentifier == 'skills_manager' ||
            appSkillIdentifier == agent.agentsSkillSlug;
  }

  Future<AppSkillWorkspaceSettingsTable> setAppSkillEnabled(
    String workspaceId,
    String appSkillIdentifier, {
    required bool isEnabled,
  }) async {
    final existing = await getSetting(workspaceId, appSkillIdentifier);
    if (existing == null) {
      return await _insertSetting(workspaceId, appSkillIdentifier, isEnabled);
    }

    final key = (
      workspaceId: workspaceId,
      appSkillIdentifier: appSkillIdentifier,
    );

    return await _updateAndRead(existing.id, key, isEnabled);
  }

  Future<AppSkillWorkspaceSettingsTable> _updateAndRead(
    String id,
    ({String workspaceId, String appSkillIdentifier}) settingKey,
    bool isEnabled,
  ) async {
    final _ = await _updateSetting(id, isEnabled);
    final updated = await getSetting(
      settingKey.workspaceId,
      settingKey.appSkillIdentifier,
    );
    if (updated == null) {
      throw StateError('Updated app skill workspace setting was not found');
    }

    return updated;
  }

  Future<AppSkillWorkspaceSettingsTable> _insertSetting(
    String workspaceId,
    String appSkillIdentifier,
    bool isEnabled,
  ) => into(appSkillWorkspaceSettings).insertReturning(
    AppSkillWorkspaceSettingsCompanion(
      workspaceId: .new(workspaceId),
      appSkillIdentifier: .new(appSkillIdentifier),
      isEnabled: .new(isEnabled),
    ),
  );

  Future<int> _updateSetting(String id, bool isEnabled) =>
      (update(
        appSkillWorkspaceSettings,
      )..where((tbl) => tbl.id.equals(id))).write(
        AppSkillWorkspaceSettingsCompanion(
          updatedAt: .new(DateTime.now()),
          isEnabled: .new(isEnabled),
        ),
      );
}
