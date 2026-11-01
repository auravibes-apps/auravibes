import 'dart:async';

import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/notifiers/titles_streams_notifier.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

class _FakeConversationRepository implements ConversationRepository {
  ConversationEntity? conversationById;
  List<ConversationEntity> conversationsByWorkspace = const [];
  final Map<String, List<ConversationEntity>> childConversationsByParent = {};

  @override
  Stream<ConversationEntity?> watchConversationById(String id) =>
      Stream.value(conversationById);

  @override
  Stream<List<ConversationEntity>> watchConversationsByWorkspace(
    String workspaceId, {
    String? search,
    int? limit,
    int offset = 0,
  }) => Stream.value(conversationsByWorkspace);

  @override
  Stream<List<ConversationEntity>> watchChildConversations(
    String parentConversationId,
  ) => Stream.value(
    childConversationsByParent[parentConversationId] ?? const [],
  );

  @override
  Future<List<ConversationEntity>> getChildConversations(
    String parentConversationId,
  ) async => const [];

  @override
  Future<ConversationEntity> createConversation(
    ConversationToCreate conversation,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<ConversationEntity?> getConversationById(String id) {
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteConversation(String id) {
    throw UnimplementedError();
  }

  @override
  Future<ConversationEntity> patchConversation(
    String id,
    ConversationPatch conversation,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<ConversationEntity> forkConversation(
    String sourceConversationId, {
    String? throughMessageId,
  }) => throw UnimplementedError();
}

void main() {
  group('conversationByIdStreamProvider', () {
    final fixture = _ConversationProviderFixture();

    setUp(fixture.reset);

    tearDown(fixture.dispose);

    test('emits conversation from repository stream', () async {
      final conversation = ConversationEntity(
        id: 'c1',
        title: 'Test',
        workspaceId: 'ws1',
        isPinned: false,
        createdAt: .new(2026),
        updatedAt: .new(2026),
      );

      fixture.repository.conversationById = conversation;
      final provider = conversationByIdStreamProvider(
        'ws1',
        conversationId: 'c1',
      );
      final result = Completer<ConversationEntity?>();
      void completeConversation(
        AsyncValue<ConversationEntity?>? _,
        AsyncValue<ConversationEntity?> next,
      ) {
        if (next case AsyncData(:final value)) result.complete(value);
      }

      final subscription = fixture.container.listen(
        provider,
        completeConversation,
        fireImmediately: true,
      );
      final value = await result.future;
      subscription.close();

      expect(value, equals(conversation));
    });
  });

  group('conversationsStreamProvider', () {
    final fixture = _ConversationProviderFixture();

    setUp(fixture.reset);

    tearDown(fixture.dispose);

    test(
      'does not use Ref after listener disposal while session resolves',
      () async {
        final session = Completer<WorkspaceSession>();
        final sessionProviderStarted = Completer<void>();
        final container = ProviderContainer(
          overrides: [
            workspaceSessionForRouteProvider('ws1').overrideWith((_) {
              sessionProviderStarted.complete();

              return session.future;
            }),
            conversationRepositoryProvider.overrideWithValue(
              _FakeConversationRepository(),
            ),
          ],
        );
        addTearDown(container.dispose);

        final subscription = container.listen(
          conversationsStreamProvider(workspaceId: 'ws1'),
          (_, _) => fail('Unexpected emission before listener disposal'),
        );
        await sessionProviderStarted.future;
        expect(sessionProviderStarted.isCompleted, isTrue);
        subscription.close();
        container.dispose();

        session.complete(
          const WorkspaceSession(LocalWorkspaceRef(localWorkspaceId: 'ws1')),
        );
        await Future<void>.value();
      },
    );

    test('emits conversations list from repository stream', () async {
      final conversations = [
        ConversationEntity(
          id: 'c1',
          title: 'Chat 1',
          workspaceId: 'ws1',
          isPinned: false,
          createdAt: .new(2026),
          updatedAt: .new(2026),
        ),
      ];

      fixture.repository.conversationsByWorkspace = conversations;
      final provider = conversationsStreamProvider(workspaceId: 'ws1');
      final result = Completer<List<ConversationEntity>>();
      void completeConversations(
        AsyncValue<List<ConversationEntity>>? _,
        AsyncValue<List<ConversationEntity>> next,
      ) {
        if (next case AsyncData(:final value)) result.complete(value);
      }

      final subscription = fixture.container.listen(
        provider,
        completeConversations,
        fireImmediately: true,
      );
      final value = await result.future;
      subscription.close();

      expect(value, equals(conversations));
    });

    test('preserves repository ordering for database pagination', () async {
      final unpinnedFirst = ConversationEntity(
        id: 'unpinned-first',
        title: 'Unpinned first',
        workspaceId: 'ws1',
        isPinned: false,
        createdAt: .new(2026),
        updatedAt: .new(2026),
      );
      final pinnedFirst = unpinnedFirst.copyWith(
        id: 'pinned-first',
        title: 'Pinned first',
        isPinned: true,
      );
      final unpinnedSecond = unpinnedFirst.copyWith(
        id: 'unpinned-second',
        title: 'Unpinned second',
      );
      final pinnedSecond = unpinnedFirst.copyWith(
        id: 'pinned-second',
        title: 'Pinned second',
        isPinned: true,
      );
      fixture.repository.conversationsByWorkspace = [
        unpinnedFirst,
        pinnedFirst,
        unpinnedSecond,
        pinnedSecond,
      ];

      final result = Completer<List<ConversationEntity>>();
      void completeConversations(
        AsyncValue<List<ConversationEntity>>? _,
        AsyncValue<List<ConversationEntity>> next,
      ) {
        if (next case AsyncData(:final value)) result.complete(value);
      }

      final subscription = fixture.container.listen(
        conversationsStreamProvider(workspaceId: 'ws1'),
        completeConversations,
        fireImmediately: true,
      );
      final conversations = await result.future;
      subscription.close();

      expect(
        conversations,
        equals([unpinnedFirst, pinnedFirst, unpinnedSecond, pinnedSecond]),
      );
    });

    test('keeps regular cloud conversation listing to one page', () async {
      final endpoint = _TestConversationEndpoint([
        ConversationPage(
          conversations: [_cloudConversationSummary(id: 'first-page')],
          nextCursor: 'page-2',
        ),
        ConversationPage(
          conversations: [_cloudConversationSummary(id: 'second-page')],
        ),
      ]);
      final container = _cloudContainer(endpoint);
      addTearDown(container.dispose);
      final provider = conversationsStreamProvider(workspaceId: 'cloud');
      final subscription = container.listen(
        provider,
        (_, next) => next.toString(),
      );
      addTearDown(subscription.close);

      final conversations = await container.read(provider.future);

      expect(conversations.map((conversation) => conversation.id), [
        'first-page',
      ]);
      expect(endpoint.requests, hasLength(1));
      expect(endpoint.requests.single.cursor, isNull);
    });
  });

  group('childConversationsStreamProvider', () {
    final fixture = _ConversationProviderFixture();

    setUp(fixture.reset);

    tearDown(fixture.dispose);

    test('streams local child conversations from the repository', () async {
      final child = _conversation(
        id: 'local-child',
        workspaceId: 'ws1',
        parentConversationId: 'parent',
      );
      fixture.repository.childConversationsByParent['parent'] = [child];

      final children = await _readChildConversations(
        fixture.container,
        workspaceId: 'ws1',
        parentConversationId: 'parent',
      );

      expect(children, [child]);
    });

    test('paginates cloud children and filters other parents', () async {
      final endpoint = _TestConversationEndpoint([
        ConversationPage(
          conversations: .generate(
            100,
            (index) => _cloudConversationSummary(id: 'page-1-$index'),
          ),
          nextCursor: 'page-2',
        ),
        ConversationPage(
          conversations: [
            _cloudConversationSummary(
              id: 'requested-child',
              parentConversationId: 'parent',
            ),
            _cloudConversationSummary(
              id: 'other-parent-child',
              parentConversationId: 'other-parent',
            ),
          ],
        ),
      ]);
      final container = _cloudContainer(endpoint);
      addTearDown(container.dispose);

      final children = await _readChildConversations(
        container,
        workspaceId: 'cloud',
        parentConversationId: 'parent',
      );

      expect(children.map((conversation) => conversation.id), [
        'requested-child',
      ]);
      expect(endpoint.requests, hasLength(2));
      expect(endpoint.requests.map((request) => request.cursor), [
        null,
        'page-2',
      ]);
      expect(endpoint.requests.map((request) => request.limit), [100, 100]);
    });

    test('rejects a repeated cloud conversation cursor', () async {
      final endpoint = _TestConversationEndpoint([
        ConversationPage(
          conversations: [_cloudConversationSummary(id: 'page-1')],
          nextCursor: 'page-2',
        ),
        ConversationPage(
          conversations: [_cloudConversationSummary(id: 'page-2')],
          nextCursor: 'page-2',
        ),
      ]);
      final container = _cloudContainer(endpoint);
      addTearDown(container.dispose);

      await expectLater(
        _readChildConversations(
          container,
          workspaceId: 'cloud',
          parentConversationId: 'parent',
        ),
        throwsA(_invalidConversationCursorException()),
      );
      expect(endpoint.requests, hasLength(2));
    });

    test('rejects an empty cloud conversation cursor', () async {
      final endpoint = _TestConversationEndpoint([
        ConversationPage(
          conversations: [_cloudConversationSummary(id: 'page-1')],
          nextCursor: '',
        ),
      ]);
      final container = _cloudContainer(endpoint);
      addTearDown(container.dispose);

      await expectLater(
        _readChildConversations(
          container,
          workspaceId: 'cloud',
          parentConversationId: 'parent',
        ),
        throwsA(_invalidConversationCursorException()),
      );
      expect(endpoint.requests, hasLength(1));
    });
  });

  group('forkedConversationsStreamProvider', () {
    final fixture = _ConversationProviderFixture();

    setUp(fixture.reset);

    tearDown(fixture.dispose);

    test(
      'returns only direct visible forks of the requested conversation',
      () async {
        final source = ConversationEntity(
          id: 'source',
          title: 'Source',
          workspaceId: 'ws1',
          isPinned: false,
          createdAt: .new(2026),
          updatedAt: .new(2026),
        );
        final firstBranch = source.copyWith(
          id: 'branch-1',
          title: 'Branch 1',
          forkSourceConversationId: source.id,
        );
        final siblingBranch = source.copyWith(
          id: 'branch-2',
          title: 'Branch 2',
          forkSourceConversationId: source.id,
        );
        final nestedBranch = source.copyWith(
          id: 'nested-branch',
          title: 'Nested branch',
          forkSourceConversationId: firstBranch.id,
        );
        final subAgent = source.copyWith(
          id: 'sub-agent',
          title: 'Sub-agent',
          parentConversationId: source.id,
        );
        fixture.repository.conversationsByWorkspace = [
          firstBranch,
          siblingBranch,
          nestedBranch,
          subAgent,
        ];

        final provider = forkedConversationsStreamProvider((
          workspaceId: 'ws1',
          sourceConversationId: source.id,
        ));
        final subscription = fixture.container.listen(provider, (_, _) {});
        final branches = await fixture.container.read(provider.future);
        subscription.close();

        expect(branches, equals([firstBranch, siblingBranch]));
      },
    );
  });

  test(
    'reports whether a workspace can accept another pinned conversation',
    () {
      final conversation = ConversationEntity(
        id: 'c1',
        title: 'Chat',
        workspaceId: 'ws1',
        isPinned: true,
        createdAt: .new(2026),
        updatedAt: .new(2026),
      );
      final pinned = List.generate(
        ConversationLimits.maxPinnedPerWorkspace,
        (index) => conversation.copyWith(id: 'c$index'),
      );

      expect(ConversationLimits.hasPinnedCapacity(pinned), isFalse);
      expect(
        ConversationLimits.hasPinnedCapacity(pinned.take(pinned.length - 1)),
        isTrue,
      );
    },
  );

  group('streamingTitleProvider', () {
    test('returns null when no title for conversation', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(streamingTitleProvider('c1')), isNull);
    });

    test('returns title when set', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(titlesStreamsProvider.notifier).updateTitle('c1', 'New');
      expect(container.read(streamingTitleProvider('c1')), 'New');
    });
  });

  test(
    'conversation list resolves route session without scope override',
    () async {
      final repository = _FakeConversationRepository()
        ..conversationsByWorkspace = const [];
      final container = ProviderContainer(
        overrides: [
          workspaceSessionForRouteProvider('ws1').overrideWith(
            (_) async => const WorkspaceSession(
              LocalWorkspaceRef(localWorkspaceId: 'ws1'),
            ),
          ),
          conversationRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final subscription = container.listen(
        conversationsStreamProvider(workspaceId: 'ws1'),
        (_, next) => next.toString(),
      );
      addTearDown(subscription.close);

      await expectLater(
        container.read(conversationsStreamProvider(workspaceId: 'ws1').future),
        completes,
      );
    },
  );
}

class _ConversationProviderFixture {
  _FakeConversationRepository? _repository;
  ProviderContainer? _container;

  _FakeConversationRepository get repository =>
      _repository ?? fail('Fixture not initialized');

  ProviderContainer get container =>
      _container ?? fail('Fixture not initialized');

  void reset() {
    final repository = _FakeConversationRepository();
    _repository = repository;
    _container = .new(
      overrides: [
        workspaceSessionForRouteProvider('ws1').overrideWith(
          (_) async => const WorkspaceSession(
            LocalWorkspaceRef(localWorkspaceId: 'ws1'),
          ),
        ),
        workspaceSessionProvider(
          const WorkspaceSession(LocalWorkspaceRef(localWorkspaceId: 'ws1')),
        ).overrideWithValue(
          const WorkspaceSession(LocalWorkspaceRef(localWorkspaceId: 'ws1')),
        ),
        conversationRepositoryProvider.overrideWithValue(repository),
      ],
    );
  }

  void dispose() {
    container.dispose();
    _repository = null;
    _container = null;
  }
}

const _cloudWorkspace = CloudWorkspaceRef(
  localWorkspaceId: 'cloud',
  serverUrl: 'https://example.com',
  accountId: 'account',
  cloudWorkspaceId: 7,
);

ProviderContainer _cloudContainer(_TestConversationEndpoint endpoint) {
  final client = _TestClient(endpoint);
  final gateway = _TestCloudWorkspaceStateGateway(
    workspace: _cloudWorkspace,
    client: client,
  );

  return ProviderContainer(
    overrides: [
      workspaceSessionForRouteProvider(
        'cloud',
      ).overrideWithValue(const AsyncData(WorkspaceSession(_cloudWorkspace))),
      cloudWorkspaceStateGatewayForWorkspaceProvider.overrideWith(
        (_, _) async => gateway,
      ),
    ],
  );
}

Future<List<ConversationEntity>> _readChildConversations(
  ProviderContainer container, {
  required String workspaceId,
  required String parentConversationId,
}) async {
  final provider = childConversationsStreamProvider(
    workspaceId,
    parentConversationId: parentConversationId,
  );
  final subscription = container.listen(provider, (_, next) => next.toString());
  try {
    return await container.read(provider.future);
  } finally {
    subscription.close();
  }
}

class _TestClient extends Fake implements Client {
  new(this.conversation);

  @override
  final EndpointConversation conversation;
}

class _TestConversationEndpoint extends Fake implements EndpointConversation {
  new(this._pages);

  final requests = <ListConversationsRequest>[];
  final List<ConversationPage> _pages;

  @override
  Future<ConversationPage> listPage(ListConversationsRequest request) async {
    requests.add(request);
    if (requests.length > _pages.length) {
      throw StateError('Unexpected conversation page request.');
    }

    return _pages[requests.length - 1];
  }
}

class _TestCloudWorkspaceStateGateway extends Fake
    implements CloudWorkspaceStateGateway {
  new({required this.workspace, required this.client});

  @override
  final CloudWorkspaceRef workspace;

  @override
  final Client client;

  @override
  Future<ReadWorkspaceStateResponse> read({
    required List<WorkspaceResourcePageRequest> pages,
    int? afterSequence,
    int eventLimit = 100,
  }) async => ReadWorkspaceStateResponse(
    pages: const [],
    currentSequence: 1,
    events: const [],
    requiresSnapshot: false,
  );

  @override
  Stream<T> watch<T>(
    Set<String> resourceKinds,
    Future<({T value, int currentSequence})> Function() load,
  ) async* {
    yield (await load()).value;
  }
}

ConversationSummary _cloudConversationSummary({
  required String id,
  String? parentConversationId,
}) => ConversationSummary(
  id: id,
  title: id,
  isPinned: false,
  parentConversationId: parentConversationId,
  revision: 1,
  createdAt: .utc(2026),
  updatedAt: .utc(2026),
);

ConversationEntity _conversation({
  required String id,
  required String workspaceId,
  String? parentConversationId,
}) => .new(
  id: id,
  title: id,
  workspaceId: workspaceId,
  isPinned: false,
  createdAt: .utc(2026),
  updatedAt: .utc(2026),
  parentConversationId: parentConversationId,
);

Matcher _invalidConversationCursorException() => isA<CloudAppException>()
    .having(
      (exception) => exception.localizationKey,
      'localizationKey',
      LocaleKeys.cloud_errors_malformed_resource,
    )
    .having(
      (exception) => exception.context,
      'context',
      CloudOperationContext.conversation,
    )
    .having((exception) => exception.code, 'code', 'invalidCursor');
