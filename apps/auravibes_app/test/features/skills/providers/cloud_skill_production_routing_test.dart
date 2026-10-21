import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connection_repository_provider.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/providers/workspace_skills_provider.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_settings_adapter.dart';
import 'package:auravibes_app/features/skills/usecases/create_skill_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/delete_cloud_routed_skill_usecases.dart';
import 'package:auravibes_app/features/skills/usecases/duplicate_skill_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/update_skill_usecase.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

class _Gateway extends Mock implements CloudWorkspaceStateGateway;
class _Client extends Mock implements Client;
class _SkillResourceEndpoint extends Mock implements EndpointSkillResource;

void main() {
  setUpAll(() {
    registerFallbackValue(
      WorkspacePatchOperation(
        operation: .create,
        resourceKind: .skill,
        resourceId: 'fallback',
        fieldMask: const [],
      ),
    );
    registerFallbackValue(
      ListSkillResourcesRequest(workspaceId: 7, skillId: 'fallback'),
    );
  });

  test(
    'cloud skill providers use cloud storage without local skill tables',
    () async {
      const workspaceId = 'local-cloud';
      const cloudWorkspace = CloudWorkspaceRef(
        localWorkspaceId: workspaceId,
        serverUrl: 'https://example.com',
        accountId: 'account',
        cloudWorkspaceId: 7,
      );
      const workspace = WorkspaceSession(cloudWorkspace);
      final gateway = _Gateway();
      final client = _Client();
      final skillResource = _SkillResourceEndpoint();
      final resources = <WorkspaceResource>[];

      when(() => gateway.client).thenReturn(client);
      when(() => gateway.workspace).thenReturn(cloudWorkspace);
      when(() => client.skillResource).thenReturn(skillResource);
      when(() => skillResource.list(any())).thenAnswer((_) async => const []);
      when(() => gateway.watchResources(any())).thenAnswer((invocation) {
        final kinds =
            invocation.positionalArguments.single
                as List<WorkspaceResourceKind>;

        return Stream.value(
          resources.where((item) => kinds.contains(item.resourceKind)).toList(),
        );
      });
      when(
        () => gateway.patch(
          requestId: any(named: 'requestId'),
          operations: any(named: 'operations'),
        ),
      ).thenAnswer((invocation) async {
        final operations =
            invocation.namedArguments[#operations]
                as List<WorkspacePatchOperation>;
        for (final operation in operations) {
          if (operation.operation == WorkspacePatchOperationKind.delete) {
            resources.removeWhere(
              (item) =>
                  item.resourceKind == operation.resourceKind &&
                  item.resourceId == operation.resourceId,
            );
            continue;
          }
          resources
            ..removeWhere(
              (item) =>
                  item.resourceKind == operation.resourceKind &&
                  item.resourceId == operation.resourceId,
            )
            ..add(
              WorkspaceResource(
                workspaceId: 7,
                resourceKind: operation.resourceKind,
                resourceId: operation.resourceId,
                data: operation.data ?? '{}',
                revision: (operation.expectedRevision ?? 0) + 1,
                createdAt: .utc(2026),
                updatedAt: .utc(2026),
              ),
            );
        }

        return PatchWorkspaceStateResponse(resources: const [], sequence: 1);
      });

      Never localStorage() => throw StateError('local skill storage touched');
      final container = ProviderContainer(
        overrides: [
          workspaceSessionProvider(workspace).overrideWithValue(workspace),
          workspaceSessionForRouteProvider(workspaceId)
              .overrideWith((_) async => workspace),
          cloudSkillStoreProvider(workspaceId)
              .overrideWithValue(.new(.new(gateway), workspaceId)),
          workspaceSkillsProvider(workspaceId).overrideWith(
            (_) => CloudSkillSettingsAdapter(gateway).watchSkills().first,
          ),
          serviceConnectionRepositoryProvider.overrideWith(
            (_) => localStorage(),
          ),
          skillsRepositoryProvider.overrideWith((_) => localStorage()),
          conversationSkillsRepositoryProvider.overrideWith(
            (_) => localStorage(),
          ),
          appSkillWorkspaceSettingsRepositoryProvider.overrideWith(
            (_) => localStorage(),
          ),
          skillResourcesRepositoryProvider.overrideWith((_) => localStorage()),
        ],
      );
      addTearDown(container.dispose);

      expect(
        await container.read(workspaceSkillsProvider(workspaceId).future),
        isEmpty,
      );
      final skill =
          await container.read(createSkillUsecaseProvider(workspaceId))(
            workspaceId,
            const SkillToCreate(
              kind: .template,
              title: 'Weather',
              description: 'Forecast',
              content: 'Use weather',
            ),
          );
      final updated = await container.read(
        updateSkillUsecaseProvider(workspaceId),
      )(skill.id, const SkillToUpdate(description: 'Updated forecast'));
      final duplicate = await container.read(
        duplicateSkillUsecaseProvider(workspaceId),
      )(skill.id);

      expect(updated.description, 'Updated forecast');
      expect(duplicate.title, 'Weather Copy');
      container.invalidate(workspaceSkillsProvider(workspaceId));
      expect(
        (await container.read(workspaceSkillsProvider(workspaceId).future))
            .map((item) => item.title),
        containsAll(['Weather', 'Weather Copy']),
      );

      await container.read(deleteSkillProvider(workspaceId))(duplicate.id);
      await container.read(deleteSkillProvider(workspaceId))(skill.id);
      expect(resources, isEmpty);
    },
  );
}
