// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/data/repositories/app_skill_workspace_settings_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_skills_repository.dart';
import 'package:auravibes_app/data/repositories/skill_resources_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/services/skills/app_skill_registry.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'skill_repository_providers.g.dart';

@Riverpod(keepAlive: true)
SkillsRepository skillsRepository(Ref ref) {
  return SkillsRepository(ref.watch(appDatabaseProvider));
}

@Riverpod(keepAlive: true)
SkillResourcesRepository skillResourcesRepository(Ref ref) {
  return SkillResourcesRepository(ref.watch(appDatabaseProvider));
}

@Riverpod(keepAlive: true)
ConversationSkillsRepository conversationSkillsRepository(Ref ref) {
  return ConversationSkillsRepository(ref.watch(appDatabaseProvider));
}

@Riverpod(keepAlive: true)
AppSkillWorkspaceSettingsRepository appSkillWorkspaceSettingsRepository(
  Ref ref,
) {
  return AppSkillWorkspaceSettingsRepository(ref.watch(appDatabaseProvider));
}

@Riverpod(keepAlive: true)
AppSkillRegistry appSkillRegistry(Ref _) => const AppSkillRegistry();
