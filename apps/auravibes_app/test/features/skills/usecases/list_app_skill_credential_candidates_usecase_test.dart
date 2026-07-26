import 'package:auravibes_app/data/repositories/service_connection_repository.dart';
import 'package:auravibes_app/features/service_connections/models/cloud_service_connection.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connection_repository_provider.dart';
import 'package:auravibes_app/features/skills/usecases/list_app_skill_credential_candidates_usecase.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/services/skills/app_skill_registry.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

class _ServiceConnectionRepository extends Mock
    implements ServiceConnectionRepository {}

void main() {
  const skill = AppSkillDefinition(
    identifier: 'example-search',
    slug: 'example-search',
    title: 'Example Search',
    description: 'Search',
    content: 'Search',
    requiresCredential: true,
  );

  test(
    'does not fall back to local candidates when cloud loading fails',
    () async {
      final repository = _ServiceConnectionRepository();
      const session = WorkspaceSession(
        CloudWorkspaceRef(
          localWorkspaceId: 'cloud-workspace',
          serverUrl: 'https://example.com',
          accountId: 'account',
          cloudWorkspaceId: 1,
        ),
      );
      final container = ProviderContainer(
        overrides: [
          serviceConnectionRepositoryProvider.overrideWithValue(repository),
          workspaceSessionForRouteProvider('cloud-workspace').overrideWith(
            (_) async => session,
          ),
          cloudWorkspaceStateGatewayProvider(session).overrideWith(
            (_) async => throw StateError('cloud unavailable'),
          ),
        ],
      );
      addTearDown(container.dispose);
      final usecase = container.read(
        listAppSkillCredentialCandidatesUsecaseProvider,
      );

      await expectLater(
        usecase.call(workspaceId: 'cloud-workspace', skill: skill),
        throwsA(isA<StateError>()),
      );
      final _ = verifyNever(
        () => repository.listAppSkillCredentialCandidates(
          workspaceId: any(named: 'workspaceId'),
          appSkillServiceId: any(named: 'appSkillServiceId'),
          compatibleModelProviderIds: any(
            named: 'compatibleModelProviderIds',
          ),
        ),
      );
    },
  );

  test('lists only matching cloud app-skill credentials', () async {
    final repository = _ServiceConnectionRepository();
    when(
      () => repository.listAppSkillCredentialCandidates(
        workspaceId: 'workspace-1',
        appSkillServiceId: skill.identifier,
        compatibleModelProviderIds: skill.compatibleModelProviderIds,
      ),
    ).thenAnswer((_) async => []);
    final usecase = ListAppSkillCredentialCandidatesUsecase(
      repository,
      cloudServiceConnectionsReader: (_) async => const [
        CloudServiceConnection(
          id: 'matching',
          revision: 1,
          name: 'Example Search credential',
          serviceId: 'example-search',
          hasSecret: true,
          scope: WorkspaceSecretScope.workspace,
          kind: 'appSkillCredential',
        ),
        CloudServiceConnection(
          id: 'other-skill',
          revision: 1,
          name: 'Other skill credential',
          serviceId: 'other-skill',
          hasSecret: true,
          scope: WorkspaceSecretScope.workspace,
          kind: 'appSkillCredential',
        ),
        CloudServiceConnection(
          id: 'missing-secret',
          revision: 1,
          name: 'Missing secret',
          serviceId: 'example-search',
          hasSecret: false,
          scope: WorkspaceSecretScope.workspace,
          kind: 'appSkillCredential',
        ),
        CloudServiceConnection(
          id: 'disabled-secret',
          revision: 1,
          name: 'Disabled credential',
          serviceId: 'example-search',
          hasSecret: true,
          scope: WorkspaceSecretScope.workspace,
          kind: 'appSkillCredential',
          isEnabled: false,
        ),
        CloudServiceConnection(
          id: 'wrong-kind',
          revision: 1,
          name: 'Model provider',
          serviceId: 'example-search',
          hasSecret: true,
          scope: WorkspaceSecretScope.workspace,
          kind: 'modelProvider',
        ),
      ],
    );

    final candidates = await usecase.call(
      workspaceId: 'workspace-1',
      skill: skill,
    );

    expect(
      candidates.map(
        (candidate) => (id: candidate.id, name: candidate.name),
      ),
      [(id: 'service:matching', name: 'Example Search credential')],
    );
  });

  test(
    'cloud eligibility excludes local callbacks and keeps server tools',
    () async {
      final repository = _ServiceConnectionRepository();
      final usecase = ListAppSkillCredentialCandidatesUsecase(repository);
      const registry = AppSkillRegistry();
      final skillsManager =
          registry.getByIdentifier('skills_manager') ??
          (throw StateError('Skills Manager must be registered.'));
      final agents =
          registry.getByIdentifier(agentsSkillSlug) ??
          (throw StateError('Agents must be registered.'));
      final anthropic =
          registry.getByIdentifier('anthropic') ??
          (throw StateError('Anthropic must be registered.'));
      final jina =
          registry.getByIdentifier('jina') ??
          (throw StateError('Jina must be registered.'));

      expect(
        await usecase.hasUsableNativeTool(
          workspaceId: 'workspace-1',
          skill: skillsManager,
        ),
        isFalse,
      );
      expect(
        await usecase.hasUsableNativeTool(
          workspaceId: 'workspace-1',
          skill: agents,
        ),
        isTrue,
      );
      expect(
        await usecase.hasUsableNativeTool(
          workspaceId: 'workspace-1',
          skill: anthropic,
        ),
        isFalse,
      );
      expect(
        await usecase.hasUsableNativeTool(
          workspaceId: 'workspace-1',
          skill: jina,
        ),
        isTrue,
      );
    },
  );
}
