import 'dart:convert';

import 'package:auravibes_app/data/repositories/app_skill_workspace_settings_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_detail_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_resource_store.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  const workspaceId = 'workspace-1';

  test(
    'uses registry metadata for a cloud-native skill without a resource',
    () async {
      final container = ProviderContainer(
        overrides: [
          cloudSkillStoreProvider(workspaceId).overrideWithValue(
            _cloudStore(const []),
          ),
        ],
      );
      addTearDown(container.dispose);

      final detail = await container.read(
        skillDetailProvider(workspaceId, 'duckduckgo').future,
      );

      expect(detail, isNotNull);
      if (detail == null) fail('Expected a native skill detail.');
      expect(detail.source, SkillSource.app);
      expect(detail.kind, SkillKind.native);
      expect(detail.title, 'DuckDuckGo Search');
      expect(detail.description, isNotEmpty);
      expect(detail.appTools, isNotEmpty);
      expect(detail.appTools.map((tool) => tool.slug), contains('search'));
    },
  );

  test('keeps cloud-native metadata while exposing registry tools', () async {
    final container = ProviderContainer(
      overrides: [
        cloudSkillStoreProvider(workspaceId).overrideWithValue(
          _cloudStore([
            _resource(
              source: SkillSource.app,
              id: 'duckduckgo',
              kind: SkillKind.native,
              title: 'Workspace Search',
              slug: 'workspace_search',
              description: 'Workspace description.',
              content: 'Workspace instructions.',
              isEnabled: false,
            ),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);

    final detail = await container.read(
      skillDetailProvider(workspaceId, 'duckduckgo').future,
    );

    expect(detail, isNotNull);
    if (detail == null) fail('Expected a native skill detail.');
    expect(detail.title, 'Workspace Search');
    expect(detail.slug, 'workspace_search');
    expect(detail.description, 'Workspace description.');
    expect(detail.content, 'Workspace instructions.');
    expect(detail.isEnabled, isFalse);
    expect(detail.titleKey, isNull);
    expect(detail.appTools.map((tool) => tool.slug), contains('search'));
  });

  test(
    'keeps a cloud user-skill collision separate from native metadata',
    () async {
      final container = ProviderContainer(
        overrides: [
          cloudSkillStoreProvider(workspaceId).overrideWithValue(
            _cloudStore([
              _resource(
                source: SkillSource.user,
                id: 'duckduckgo',
                kind: SkillKind.template,
                title: 'My Search',
                slug: 'my_search',
                description: 'User description.',
                content: 'User instructions.',
                isEnabled: true,
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final detail = await container.read(
        skillDetailProvider(workspaceId, 'duckduckgo').future,
      );

      expect(detail, isNotNull);
      if (detail == null) fail('Expected a user skill detail.');
      expect(detail.source, SkillSource.user);
      expect(detail.kind, SkillKind.template);
      expect(detail.title, 'My Search');
      expect(detail.appTools, isEmpty);
    },
  );

  test('uses registry metadata with local enabled state', () async {
    final container = ProviderContainer(
      overrides: [
        cloudSkillStoreProvider(workspaceId).overrideWithValue(null),
        skillsRepositoryProvider.overrideWithValue(
          const _FakeSkillsRepository(),
        ),
        appSkillWorkspaceSettingsRepositoryProvider.overrideWithValue(
          const _FakeAppSkillWorkspaceSettingsRepository(enabled: false),
        ),
      ],
    );
    addTearDown(container.dispose);

    final detail = await container.read(
      skillDetailProvider(workspaceId, 'duckduckgo').future,
    );

    expect(detail, isNotNull);
    if (detail == null) fail('Expected a native skill detail.');
    expect(detail.source, SkillSource.app);
    expect(detail.isEnabled, isFalse);
    expect(detail.appTools, isNotEmpty);
  });

  test('returns null for an unknown cloud skill id', () async {
    final container = ProviderContainer(
      overrides: [
        cloudSkillStoreProvider(workspaceId).overrideWithValue(
          _cloudStore(const []),
        ),
      ],
    );
    addTearDown(container.dispose);

    final detail = await container.read(
      skillDetailProvider(workspaceId, 'unknown').future,
    );

    expect(detail, isNull);
  });
}

CloudSkillStore _cloudStore(List<WorkspaceResource> resources) {
  return CloudSkillStore(
    CloudWorkspaceResourceStore.forTesting(
      patch: ({required requestId, required operations}) =>
          throw UnimplementedError(),
      watch: (_) => Stream.value(resources),
      putSecret:
          ({
            required requestId,
            required secretKind,
            required scope,
            required resourceId,
            secret,
            expectedRevision,
          }) => throw UnimplementedError(),
      mutateCredential:
          ({
            required requestId,
            required resourceOperation,
            required secretKind,
            required scope,
            required secret,
            required clearSecret,
            expectedSecretRevision,
          }) => throw UnimplementedError(),
    ),
    'workspace-1',
  );
}

WorkspaceResource _resource({
  required String id,
  required SkillSource source,
  required SkillKind kind,
  required String title,
  required String slug,
  required String description,
  required String content,
  required bool isEnabled,
}) {
  final now = DateTime.utc(2026);

  return WorkspaceResource(
    workspaceId: 1,
    resourceKind: WorkspaceResourceKind.skill,
    resourceId: id,
    data: jsonEncode({
      'id': id,
      'source': source.name,
      'kind': kind.name,
      'title': title,
      'slug': slug,
      'description': description,
      'content': content,
      'isEnabled': isEnabled,
      'isCredentialOptional': false,
    }),
    revision: 1,
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeSkillsRepository implements SkillsRepository {
  const _FakeSkillsRepository();

  @override
  Future<SkillEntity?> getSkillById(String skillId) async => null;

  @override
  Future<SkillEntity?> getSkillBySlug(String workspaceId, String slug) =>
      throw UnimplementedError();

  @override
  Future<SkillEntity?> getSkillByTitle(String workspaceId, String title) =>
      throw UnimplementedError();

  @override
  Future<List<SkillEntity>> getWorkspaceSkills(String workspaceId) =>
      throw UnimplementedError();

  @override
  Future<SkillEntity> createSkill(String workspaceId, SkillToCreate skill) =>
      throw UnimplementedError();

  @override
  Future<SkillEntity> updateSkill(String skillId, SkillToUpdate skill) =>
      throw UnimplementedError();

  @override
  Future<bool> deleteSkill(String skillId) => throw UnimplementedError();
}

class _FakeAppSkillWorkspaceSettingsRepository
    implements AppSkillWorkspaceSettingsRepository {
  const _FakeAppSkillWorkspaceSettingsRepository({required this.enabled});

  final bool enabled;

  @override
  Future<bool> isAppSkillEnabled(
    String workspaceId,
    String appSkillIdentifier,
  ) async => enabled;

  @override
  Future<void> setAppSkillEnabled(
    String workspaceId,
    String appSkillIdentifier, {
    required bool isEnabled,
  }) => throw UnimplementedError();
}
