// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/data/repositories/app_skill_workspace_settings_repository_impl.dart';
import 'package:auravibes_app/data/repositories/conversation_skills_repository_impl.dart';
import 'package:auravibes_app/data/repositories/skill_credential_definitions_repository_impl.dart';
import 'package:auravibes_app/data/repositories/skill_credentials_repository_impl.dart';
import 'package:auravibes_app/data/repositories/skill_template_tools_repository_impl.dart';
import 'package:auravibes_app/data/repositories/skills_repository_impl.dart';
import 'package:auravibes_app/domain/repositories/app_skill_workspace_settings_repository.dart';
import 'package:auravibes_app/domain/repositories/conversation_skills_repository.dart';
import 'package:auravibes_app/domain/repositories/skill_credential_definitions_repository.dart';
import 'package:auravibes_app/domain/repositories/skill_credentials_repository.dart';
import 'package:auravibes_app/domain/repositories/skill_template_tools_repository.dart';
import 'package:auravibes_app/domain/repositories/skills_repository.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/services/encryption_service.dart';
import 'package:auravibes_app/services/skills/app_skill_registry.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'skill_repository_providers.g.dart';

@Riverpod(keepAlive: true)
SkillsRepository skillsRepository(Ref ref) {
  return SkillsRepositoryImpl(ref.watch(appDatabaseProvider));
}

@Riverpod(keepAlive: true)
SkillTemplateToolsRepository skillTemplateToolsRepository(Ref ref) {
  return SkillTemplateToolsRepositoryImpl(ref.watch(appDatabaseProvider));
}

@Riverpod(keepAlive: true)
SkillCredentialDefinitionsRepository skillCredentialDefinitionsRepository(
  Ref ref,
) {
  return SkillCredentialDefinitionsRepositoryImpl(
    ref.watch(appDatabaseProvider),
  );
}

@Riverpod(keepAlive: true)
SkillCredentialsRepository skillCredentialsRepository(Ref ref) {
  return SkillCredentialsRepositoryImpl(
    database: ref.watch(appDatabaseProvider),
    encryptionService: ref.watch(encryptionServiceProvider),
  );
}

@Riverpod(keepAlive: true)
ConversationSkillsRepository conversationSkillsRepository(Ref ref) {
  return ConversationSkillsRepositoryImpl(ref.watch(appDatabaseProvider));
}

@Riverpod(keepAlive: true)
AppSkillWorkspaceSettingsRepository appSkillWorkspaceSettingsRepository(
  Ref ref,
) {
  return AppSkillWorkspaceSettingsRepositoryImpl(
    ref.watch(appDatabaseProvider),
  );
}

@Riverpod(keepAlive: true)
AppSkillRegistry appSkillRegistry(Ref _) => const AppSkillRegistry();
