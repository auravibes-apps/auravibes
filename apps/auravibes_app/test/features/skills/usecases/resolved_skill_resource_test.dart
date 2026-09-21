import 'dart:convert';

import 'package:auravibes_app/data/repositories/skill_resources_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/entities/skill_resource_entity.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:auravibes_app/features/skills/usecases/resolved_skill_resource.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_resource_store.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_app/services/skills/app_skill_registry.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _SkillsRepository extends Mock implements SkillsRepository;

class _ResourcesRepository extends Mock implements SkillResourcesRepository;

class _Gateway extends Mock implements CloudWorkspaceStateGateway;

class _Client extends Mock implements Client;

class _SkillResourceEndpoint extends Mock implements EndpointSkillResource;

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
    registerFallbackValue(
      const SkillResourceToCreate(title: '', description: '', content: ''),
    );
    registerFallbackValue(const SkillResourceToUpdate());
  });

  test('resolves built-in app resources', () async {
    const resolver = SkillResourceResolver(null, null, .new());

    final summaries = await resolver.list('workspace-1', 'brave');
    final resource = await resolver.get(
      'workspace-1',
      'brave',
      'query_operators_and_paging',
    );

    expect(summaries.single.slug, 'query_operators_and_paging');
    expect(resource?.summary.title, 'Query operators and paging');
    expect(resource?.content, contains('site:domain'));
    expect(await resolver.get('workspace-1', 'brave', 'missing'), isNull);
  });

  test('resolves local user resources and handles missing skills', () async {
    final skills = _SkillsRepository();
    final resources = _ResourcesRepository();
    final skill = _skill(slug: 'custom');
    final resource = _resource();
    when(() => skills.getSkillBySlug('workspace-1', 'custom'))
        .thenAnswer((_) async => skill);
    when(() => resources.getSkillResources(skill.id))
        .thenAnswer((_) async => [resource]);

    final resolver = SkillResourceResolver(
      skills,
      resources,
      const AppSkillRegistry(),
    );

    final summaries = await resolver.list('workspace-1', 'custom');
    expect(summaries, hasLength(1));
    expect(summaries.single.slug, 'policy');
    expect(summaries.single.title, 'Policy');
    expect(summaries.single.description, 'Policy description');
    final resolved = await resolver.get('workspace-1', 'custom', 'policy');
    expect(resolved?.content, 'Policy content');
    expect(await resolver.get('workspace-1', 'custom', 'missing'), isNull);

    when(() => skills.getSkillBySlug('workspace-1', 'missing'))
        .thenAnswer((_) async => null);
    expect(await resolver.list('workspace-1', 'missing'), isEmpty);
    expect(await resolver.get('workspace-1', 'missing', 'policy'), isNull);
  });

  test('resolves cloud user resources through the cloud skill store', () async {
    final endpoint = _SkillResourceEndpoint();
    final view = _view(skillId: 'skill-1', slug: 'policy');
    when(() => endpoint.list(any())).thenAnswer((_) async => [view]);
    final cloud = _cloudStore(
      endpoint,
      resources: [_skillWorkspaceResource(id: 'skill-1', slug: 'custom')],
    );
    final resolver = SkillResourceResolver(
      null,
      null,
      const AppSkillRegistry(),
      cloudStore: cloud,
    );

    final summaries = await resolver.list('workspace-1', 'custom');
    final resource = await resolver.get('workspace-1', 'custom', 'policy');

    expect(summaries.single.title, 'Policy');
    expect(resource?.content, 'Policy content');
    expect(await resolver.list('workspace-1', 'missing'), isEmpty);
  });

  test('creates, updates, and deletes local resources', () async {
    final resources = _ResourcesRepository();
    final resource = _resource();
    when(() => resources.getSkillResources('skill-1'))
        .thenAnswer((_) async => []);
    when(() => resources.createResource('skill-1', any()))
        .thenAnswer((_) async => resource);
    when(() => resources.updateResource('resource-1', any()))
        .thenAnswer((_) async => resource.copyWith(title: 'Updated'));
    when(() => resources.deleteResource('resource-1'))
        .thenAnswer((_) async => true);

    final created = await CreateSkillResourceUsecase(resources).call(
      'skill-1',
      const SkillResourceToCreate(
        title: 'Policy',
        description: 'Description',
        content: 'Content',
      ),
    );
    final updated = await UpdateSkillResourceUsecase(resources)
        .call('resource-1', const SkillResourceToUpdate(title: 'Updated'));
    final deleted = await SkillResourceOperations.delete(
      'resource-1',
      resourcesRepository: resources,
      cloudStore: null,
    );

    expect(created, resource);
    expect(updated.title, 'Updated');
    expect(deleted, isTrue);
  });

  test('enforces resource validation and capacity', () async {
    final resources = _ResourcesRepository();
    when(() => resources.getSkillResources('skill-1'))
        .thenAnswer((_) async => []);
    final create = CreateSkillResourceUsecase(resources);

    await expectLater(
      create.call(
        'skill-1',
        const SkillResourceToCreate(title: ' ', description: '', content: ''),
      ),
      throwsFormatException,
    );
    await expectLater(
      create.call(
        'skill-1',
        .new(
          title: 'Policy',
          description: List.filled(241, 'x').join(),
          content: '',
        ),
      ),
      throwsFormatException,
    );
    expect(
      () => UpdateSkillResourceUsecase(resources)
          .call('resource-1', .new(content: List.filled(50001, 'x').join())),
      throwsA(isA<FormatException>()),
    );

    when(() => resources.getSkillResources('full-skill'))
        .thenAnswer((_) async => List.generate(100, (_) => _resource()));
    await expectLater(
      create.call(
        'full-skill',
        const SkillResourceToCreate(
          title: 'Policy',
          description: '',
          content: '',
        ),
      ),
      throwsStateError,
    );
  });

  test('fails clearly when a resource store is unavailable', () async {
    await expectLater(
      const CreateSkillResourceUsecase(null).call(
        'skill-1',
        const SkillResourceToCreate(
          title: 'Policy',
          description: '',
          content: '',
        ),
      ),
      throwsStateError,
    );
    await expectLater(
      const UpdateSkillResourceUsecase(null)
          .call('resource-1', const SkillResourceToUpdate()),
      throwsStateError,
    );
    expect(
      () => SkillResourceOperations.delete(
        'resource-1',
        resourcesRepository: null,
        cloudStore: null,
      ),
      throwsA(isA<StateError>()),
    );
  });
}

CloudSkillStore _cloudStore(
  EndpointSkillResource endpoint, {
  required List<WorkspaceResource> resources,
}) {
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
  when(() => gateway.watchResources(any())).thenAnswer((invocation) {
    final kinds =
        invocation.positionalArguments.single as List<WorkspaceResourceKind>;

    return Stream.value(
      resources
          .where((resource) => kinds.contains(resource.resourceKind))
          .toList(),
    );
  });

  final resourceStore = _resourceStore(gateway);

  return .new(resourceStore, 'workspace-1');
}

CloudWorkspaceResourceStore _resourceStore(_Gateway gateway) => .new(gateway);

WorkspaceResource _skillWorkspaceResource({
  required String id,
  required String slug,
}) {
  final now = DateTime.utc(2026);

  return WorkspaceResource(
    workspaceId: 7,
    resourceKind: .skill,
    resourceId: id,
    data: jsonEncode({
      'source': 'user',
      'kind': 'template',
      'title': 'Custom',
      'slug': slug,
      'description': 'Custom description',
      'content': 'Custom content',
      'isEnabled': true,
      'isCredentialOptional': false,
    }),
    revision: 1,
    createdAt: now,
    updatedAt: now,
  );
}

SkillEntity _skill({required String slug, String id = 'skill-1'}) =>
    SkillEntity(
      source: .user,
      id: id,
      workspaceId: 'workspace-1',
      kind: .template,
      title: 'Custom',
      slug: slug,
      description: 'Custom description',
      content: 'Custom content',
      isEnabled: true,
      isCredentialOptional: false,
      createdAt: .utc(2026),
      updatedAt: .utc(2026),
    );

SkillResourceEntity _resource({
  String id = 'resource-1',
  String skillId = 'skill-1',
  String slug = 'policy',
}) => SkillResourceEntity(
  id: id,
  skillId: skillId,
  title: 'Policy',
  slug: slug,
  description: 'Policy description',
  content: 'Policy content',
  createdAt: .utc(2026),
  updatedAt: .utc(2026),
);

SkillResourceView _view({required String skillId, required String slug}) {
  final now = DateTime.utc(2026);

  return SkillResourceView(
    id: 'resource-1',
    skillId: skillId,
    title: 'Policy',
    slug: slug,
    description: 'Policy description',
    content: 'Policy content',
    revision: 3,
    createdAt: now,
    updatedAt: now,
  );
}
