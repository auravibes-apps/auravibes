import 'package:auravibes_app/domain/entities/skill_resource_entity.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_resource_store.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Gateway extends Mock implements CloudWorkspaceStateGateway;

class _Client extends Mock implements Client;

class _Endpoint extends Mock implements EndpointSkillResource;

void main() {
  setUpAll(() {
    registerFallbackValue(
      ListSkillResourcesRequest(workspaceId: 0, skillId: ''),
    );
    registerFallbackValue(
      GetSkillResourceRequest(workspaceId: 0, resourceId: ''),
    );
    registerFallbackValue(
      CreateSkillResourceRequest(
        workspaceId: 0,
        requestId: '',
        skillId: '',
        resourceId: '',
        title: '',
        description: '',
        content: '',
      ),
    );
    registerFallbackValue(
      UpdateSkillResourceRequest(
        workspaceId: 0,
        requestId: '',
        resourceId: '',
        expectedRevision: 0,
        title: '',
        description: '',
        content: '',
      ),
    );
    registerFallbackValue(
      DeleteSkillResourceRequest(
        workspaceId: 0,
        requestId: '',
        resourceId: '',
        expectedRevision: 0,
      ),
    );
  });

  test('maps resource list and get responses', () async {
    final endpoint = _Endpoint();
    final view = _view();
    when(() => endpoint.list(any())).thenAnswer((_) async => [view]);
    when(() => endpoint.get(any())).thenAnswer((_) async => view);
    final store = _cloudStore(endpoint);

    final resources = await store.resources('skill-1');
    final resource = await store.resource('resource-1');

    expect(resources.single, _entity());
    expect(resource, _entity());
    final listRequest =
        verify(() => endpoint.list(captureAny())).captured.single
            as ListSkillResourcesRequest;
    expect(listRequest.workspaceId, 7);
    expect(listRequest.skillId, 'skill-1');
    final getRequest =
        verify(() => endpoint.get(captureAny())).captured.single
            as GetSkillResourceRequest;
    expect(getRequest.workspaceId, 7);
    expect(getRequest.resourceId, 'resource-1');
  });

  test('creates, updates, and deletes cloud resources', () async {
    final endpoint = _Endpoint();
    final current = _view();
    final updated = current.copyWith(
      title: 'Updated policy',
      content: 'Updated content',
      revision: 4,
    );
    when(() => endpoint.create(any())).thenAnswer((_) async => current);
    when(() => endpoint.get(any())).thenAnswer((_) async => current);
    when(() => endpoint.update(any())).thenAnswer((_) async => updated);
    when(() => endpoint.delete(any())).thenAnswer((_) => Future.value());
    final store = _cloudStore(endpoint);

    final created = await store.createResource(
      'skill-1',
      const SkillResourceToCreate(
        title: 'Policy',
        description: 'Policy description',
        content: 'Policy content',
      ),
    );
    final changed = await store.updateResource(
      'resource-1',
      const SkillResourceToUpdate(title: 'Updated policy'),
    );
    final deleted = await store.deleteResource('resource-1');

    expect(created, _entity());
    expect(changed.title, 'Updated policy');
    expect(deleted, isTrue);
    final createRequest =
        verify(() => endpoint.create(captureAny())).captured.single
            as CreateSkillResourceRequest;
    expect(createRequest.workspaceId, 7);
    expect(createRequest.skillId, 'skill-1');
    expect(createRequest.title, 'Policy');
    final updateRequest =
        verify(() => endpoint.update(captureAny())).captured.single
            as UpdateSkillResourceRequest;
    expect(updateRequest.resourceId, 'resource-1');
    expect(updateRequest.expectedRevision, 3);
    expect(updateRequest.title, 'Updated policy');
    expect(updateRequest.description, 'Policy description');
    final deleteRequest =
        verify(() => endpoint.delete(captureAny())).captured.single
            as DeleteSkillResourceRequest;
    expect(deleteRequest.resourceId, 'resource-1');
    expect(deleteRequest.expectedRevision, 3);
  });

  test(
    'returns false for missing resources and rejects missing updates',
    () async {
      final endpoint = _Endpoint();
      when(() => endpoint.get(any())).thenAnswer((_) async => null);
      final store = _cloudStore(endpoint);

      expect(await store.resource('missing'), isNull);
      expect(await store.deleteResource('missing'), isFalse);
      await expectLater(
        store.updateResource('missing', const SkillResourceToUpdate()),
        throwsStateError,
      );
    },
  );

  test('reports unavailable cloud resource clients', () async {
    final store = CloudSkillStore(
      .forTesting(
        watch: (_) => const Stream.empty(),
        patch: ({required requestId, required operations}) async =>
            .new(resources: const [], sequence: 1),
        putSecret: (_) async => PutWorkspaceSecretResponse(
          configured: false,
          revision: 0,
          sequence: 1,
        ),
        mutateCredential: (_) async => MutateWorkspaceCredentialResponse(
          resource: .new(
            workspaceId: 0,
            resourceKind: .skill,
            resourceId: '',
            data: '{}',
            revision: 0,
            createdAt: .utc(2026),
            updatedAt: .utc(2026),
          ),
          configured: false,
          sequence: 1,
        ),
      ),
      'workspace-1',
    );

    await expectLater(store.resources('skill-1'), throwsStateError);
  });
}

CloudSkillStore _cloudStore(_Endpoint endpoint) {
  final gateway = _Gateway();
  final client = _Client();
  const workspace = CloudWorkspaceRef(
    localWorkspaceId: 'workspace-1',
    serverUrl: 'https://example.com',
    accountId: 'account-1',
    cloudWorkspaceId: 7,
  );
  when(() => gateway.client).thenReturn(client);
  when(() => gateway.workspace).thenReturn(workspace);
  when(() => client.skillResource).thenReturn(endpoint);
  when(() => gateway.watchResources(any()))
      .thenAnswer((_) => const Stream.empty());

  final resourceStore = _resourceStore(gateway);

  return .new(resourceStore, 'workspace-1');
}

CloudWorkspaceResourceStore _resourceStore(_Gateway gateway) => .new(gateway);

SkillResourceView _view() {
  final now = DateTime.utc(2026);

  return .new(
    id: 'resource-1',
    skillId: 'skill-1',
    title: 'Policy',
    slug: 'policy',
    description: 'Policy description',
    content: 'Policy content',
    revision: 3,
    createdAt: now,
    updatedAt: now,
  );
}

SkillResourceEntity _entity() => .new(
  id: 'resource-1',
  skillId: 'skill-1',
  title: 'Policy',
  slug: 'policy',
  description: 'Policy description',
  content: 'Policy content',
  revision: 3,
  createdAt: .utc(2026),
  updatedAt: .utc(2026),
);
