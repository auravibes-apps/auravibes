import 'package:auravibes_app/data/repositories/app_skill_workspace_settings_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_skills_repository.dart';
import 'package:auravibes_app/data/repositories/skill_credentials_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_skill_entity.dart';
import 'package:auravibes_app/domain/entities/skill_credential_entity.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/skills/usecases/check_skill_credential_readiness_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/list_available_skills_usecase.dart';
import 'package:auravibes_app/services/skills/app_skill_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ListAvailableSkillsUsecase', () {
    test(
      'hides unloaded required-credential skills without credentials',
      () async {
        final now = DateTime(2026);
        const workspaceId = 'workspace-1';
        const conversationId = 'conversation-1';
        final blockedSkill = _skill(
          id: 'blocked-skill',
          workspaceId: workspaceId,
          title: 'Blocked Skill',
          slug: 'blocked_skill',
          credentialDefinitionId: 'credential-definition-1',
          now: now,
        );
        final optionalSkill = _skill(
          id: 'optional-skill',
          workspaceId: workspaceId,
          title: 'Optional Skill',
          slug: 'optional_skill',
          credentialDefinitionId: 'credential-definition-1',
          isCredentialOptional: true,
          now: now,
        );
        final loadedSkill = _skill(
          id: 'loaded-skill',
          workspaceId: workspaceId,
          title: 'Loaded Skill',
          slug: 'loaded_skill',
          credentialDefinitionId: 'credential-definition-1',
          now: now,
        );
        final usecase = ListAvailableSkillsUsecase(
          _FakeSkillsRepository([blockedSkill, optionalSkill, loadedSkill]),
          _FakeConversationSkillsRepository([
            ConversationSkillEntity(
              id: 'conversation-skill-1',
              conversationId: conversationId,
              workspaceSkillId: loadedSkill.id,
              isLoaded: true,
              createdAt: now,
              updatedAt: now,
            ),
          ]),
          _FakeAppSkillWorkspaceSettingsRepository(),
          const AppSkillRegistry(),
          CheckSkillCredentialReadinessUsecase(
            _FakeSkillCredentialsRepository(),
          ),
        );

        final loadable = await usecase.call(
          conversationId: conversationId,
          workspaceId: workspaceId,
          filter: SkillLoadFilter.loadable,
        );
        final loaded = await usecase.call(
          conversationId: conversationId,
          workspaceId: workspaceId,
          filter: SkillLoadFilter.loaded,
        );

        expect(loadable.map((skill) => skill.id), [optionalSkill.id]);
        expect(loaded.map((skill) => skill.id), [loadedSkill.id]);
      },
    );
  });
}

SkillEntity _skill({
  required String id,
  required String workspaceId,
  required String title,
  required String slug,
  required DateTime now,
  bool isCredentialOptional = false,
  String? credentialDefinitionId,
}) {
  return SkillEntity(
    id: id,
    workspaceId: workspaceId,
    source: SkillSource.user,
    kind: SkillKind.template,
    title: title,
    slug: slug,
    description: '$title description',
    content: '$title content',
    isEnabled: true,
    isCredentialOptional: isCredentialOptional,
    credentialDefinitionId: credentialDefinitionId,
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeSkillsRepository implements SkillsRepository {
  const _FakeSkillsRepository(this.skills);

  final List<SkillEntity> skills;

  @override
  Future<List<SkillEntity>> getWorkspaceSkills(String workspaceId) async {
    return skills.where((skill) => skill.workspaceId == workspaceId).toList();
  }

  @override
  Future<SkillEntity?> getSkillById(String skillId) {
    throw UnsupportedError('Not needed by this test.');
  }

  @override
  Future<SkillEntity?> getSkillBySlug(String workspaceId, String slug) {
    throw UnsupportedError('Not needed by this test.');
  }

  @override
  Future<SkillEntity?> getSkillByTitle(String workspaceId, String title) {
    throw UnsupportedError('Not needed by this test.');
  }

  @override
  Future<SkillEntity> createSkill(String workspaceId, SkillToCreate skill) {
    throw UnsupportedError('Not needed by this test.');
  }

  @override
  Future<SkillEntity> updateSkill(String skillId, SkillToUpdate skill) {
    throw UnsupportedError('Not needed by this test.');
  }

  @override
  Future<bool> deleteSkill(String skillId) {
    throw UnsupportedError('Not needed by this test.');
  }
}

class _FakeConversationSkillsRepository
    implements ConversationSkillsRepository {
  const _FakeConversationSkillsRepository(this.skills);

  final List<ConversationSkillEntity> skills;

  @override
  Future<List<ConversationSkillEntity>> getConversationSkills(
    String conversationId,
  ) async {
    return skills
        .where((skill) => skill.conversationId == conversationId)
        .toList();
  }

  @override
  Future<ConversationSkillEntity> setWorkspaceSkillLoaded(
    String conversationId,
    String workspaceSkillId, {
    required bool isLoaded,
  }) {
    throw UnsupportedError('Not needed by this test.');
  }

  @override
  Future<ConversationSkillEntity> setAppSkillLoaded(
    String conversationId,
    String appSkillIdentifier, {
    required bool isLoaded,
  }) {
    throw UnsupportedError('Not needed by this test.');
  }
}

class _FakeAppSkillWorkspaceSettingsRepository
    implements AppSkillWorkspaceSettingsRepository {
  @override
  Future<bool> isAppSkillEnabled(
    String workspaceId,
    String appSkillIdentifier,
  ) async {
    return false;
  }

  @override
  Future<void> setAppSkillEnabled(
    String workspaceId,
    String appSkillIdentifier, {
    required bool isEnabled,
  }) {
    throw UnsupportedError('Not needed by this test.');
  }
}

class _FakeSkillCredentialsRepository implements SkillCredentialsRepository {
  @override
  Future<List<SkillCredentialEntity>> getCredentialsForDefinition({
    required String workspaceId,
    required String credentialDefinitionId,
  }) async {
    return const [];
  }

  @override
  Stream<List<SkillCredentialEntity>> watchCredentialsForWorkspace(
    String workspaceId,
  ) {
    throw UnsupportedError('Not needed by this test.');
  }

  @override
  Future<SkillCredentialEntity?> getCredentialById(String credentialId) {
    throw UnsupportedError('Not needed by this test.');
  }

  @override
  Future<SkillCredentialForEdit?> getCredentialForEdit(String credentialId) {
    throw UnsupportedError('Not needed by this test.');
  }

  @override
  Future<SkillCredentialEntity> createCredential(
    String workspaceId,
    SkillCredentialToCreate credential,
  ) {
    throw UnsupportedError('Not needed by this test.');
  }

  @override
  Future<SkillCredentialEntity> updateCredential(
    String credentialId,
    SkillCredentialToUpdate credential,
  ) {
    throw UnsupportedError('Not needed by this test.');
  }

  @override
  Future<void> deleteCredential(String credentialId) {
    throw UnsupportedError('Not needed by this test.');
  }
}
