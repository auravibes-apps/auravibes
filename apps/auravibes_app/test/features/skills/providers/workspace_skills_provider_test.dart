import 'dart:convert';

import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/providers/workspace_skills_provider.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

class _Gateway extends Mock implements CloudWorkspaceStateGateway;

void main() {
  const workspaceId = 'cloud-workspace';
  const session = WorkspaceSession(
    CloudWorkspaceRef(
      localWorkspaceId: workspaceId,
      serverUrl: 'https://example.com',
      accountId: 'account',
      cloudWorkspaceId: 7,
    ),
  );

  test(
    'merges the cloud snapshot with the app catalog without local storage',
    () async {
      final gateway = _Gateway();
      when(() => gateway.watchResources(any()))
          .thenAnswer((_) => Stream.value(const <WorkspaceResource>[]));
      final container = ProviderContainer(
        overrides: [
          workspaceSessionForRouteProvider.overrideWith(
            (_, _) async => session,
          ),
          cloudWorkspaceStateGatewayProvider.overrideWith(
            (_, _) async => gateway,
          ),
          skillsRepositoryProvider.overrideWith(
            (_) => throw StateError('local touched'),
          ),
          appSkillWorkspaceSettingsRepositoryProvider.overrideWith(
            (_) => throw StateError('local touched'),
          ),
        ],
      );
      addTearDown(container.dispose);

      final catalog = container.read(appSkillRegistryProvider).getAll();
      final skills = await container.read(
        workspaceSkillsProvider(workspaceId).future,
      );

      expect(skills, hasLength(catalog.length));
      expect(skills.every((skill) => !skill.isEnabled), isTrue);
    },
  );

  test('preserves a cloud-owned catalog ID collision', () async {
    final gateway = _Gateway();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final catalogSkill = container
        .read(appSkillRegistryProvider)
        .getAll()
        .first;
    when(() => gateway.watchResources(any())).thenAnswer(
      (_) => Stream.value([
        _resource(
          id: catalogSkill.identifier,
          data: jsonEncode({
            'slug': 'cloud-slug',
            'title': 'Cloud skill',
            'description': 'Cloud description',
            'kind': 'template',
            'content': 'Cloud content',
            'isEnabled': true,
          }),
        ),
      ]),
    );
    final cloudContainer = ProviderContainer(
      overrides: [
        workspaceSessionForRouteProvider.overrideWith((_, _) async => session),
        cloudWorkspaceStateGatewayProvider.overrideWith(
          (_, _) async => gateway,
        ),
        skillsRepositoryProvider.overrideWith(
          (_) => throw StateError('local touched'),
        ),
        appSkillWorkspaceSettingsRepositoryProvider.overrideWith(
          (_) => throw StateError('local touched'),
        ),
      ],
    );
    addTearDown(cloudContainer.dispose);

    final skill = (await cloudContainer.read(
      workspaceSkillsProvider(workspaceId).future,
    )).singleWhere((skill) => skill.id == catalogSkill.identifier);

    expect(skill.title, 'Cloud skill');
    expect(skill.isEnabled, isTrue);
  });
}

WorkspaceResource _resource({required String id, required String data}) {
  final now = DateTime.utc(2026);

  return WorkspaceResource(
    workspaceId: 7,
    resourceKind: WorkspaceResourceKind.skill,
    resourceId: id,
    data: data,
    revision: 1,
    createdAt: now,
    updatedAt: now,
  );
}
