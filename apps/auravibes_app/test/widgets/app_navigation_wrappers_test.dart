// ignore_for_file: no-magic-number
// Required: Tests use numeric fixtures and dimensions.
// ignore_for_file: scoped_providers_should_specify_dependencies
// Required: widget tests override scoped providers directly.
// ignore_for_file: no-equal-arguments
// Required: Tests use repeated fixture values to assert equality semantics.
// ignore_for_file: no-empty-block
// Required: Tests use intentional no-op callbacks and fake hooks.
// ignore_for_file: format-comment
// Required: Existing comments use generated or domain-specific formatting.
// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
// ignore_for_file: newline-before-return
// Required: Existing test and UI helpers keep compact return flow.
// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.

import 'dart:async';

import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/domain/repositories/conversation_repository.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/providers/router_providers.dart';
import 'package:auravibes_app/widgets/aura_sidebar_wrapper.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../helpers/test_provider_scope.dart';

void main() {
  group('navigation shell index calculation', () {
    testWidgets('returns shellIndex for root workspace path', (tester) async {
      int? result;

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/workspaces/:workspaceId',
            builder: (context, state) => const SizedBox.shrink(),
            routes: [
              StatefulShellRoute.indexedStack(
                branches: [
                  StatefulShellBranch(
                    routes: [
                      GoRoute(
                        path: 'chat/new',
                        builder: (context, state) =>
                            const Text('New chat screen'),
                      ),
                    ],
                  ),
                  StatefulShellBranch(
                    routes: [
                      GoRoute(
                        path: 'tools',
                        builder: (context, state) => const Text('Tools screen'),
                      ),
                    ],
                  ),
                ],
                builder: (context, state, navigationShell) {
                  result = navigationShell.currentIndex;
                  return navigationShell;
                },
              ),
            ],
          ),
        ],
        initialLocation: '/workspaces/ws-test/tools',
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      final _ = await tester.pumpAndSettle();

      expect(result, 1);
    });

    testWidgets('returns 0 for specific chat route', (tester) async {
      int? capturedShellIndex;

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/workspaces/:workspaceId',
            builder: (context, state) => const SizedBox.shrink(),
            routes: [
              StatefulShellRoute.indexedStack(
                branches: [
                  StatefulShellBranch(
                    routes: [
                      GoRoute(
                        path: 'chat/new',
                        builder: (context, state) => const Text('New chat'),
                      ),
                      GoRoute(
                        path: 'chats/:chatId',
                        builder: (context, state) => const Text('Chat screen'),
                      ),
                    ],
                  ),
                  StatefulShellBranch(
                    routes: [
                      GoRoute(
                        path: 'tools',
                        builder: (context, state) => const Text('Tools screen'),
                      ),
                    ],
                  ),
                ],
                builder: (context, state, navigationShell) {
                  capturedShellIndex = navigationShell.currentIndex;
                  return navigationShell;
                },
              ),
            ],
          ),
        ],
        initialLocation: '/workspaces/ws-test/chats/chat-123',
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      final _ = await tester.pumpAndSettle();

      expect(capturedShellIndex, 0);
    });
  });

  group('AuraSidebarWrapper', () {
    test('constructor stores workspaceId', () {
      final shell = _FakeNavigationShell();
      final wrapper = AuraSidebarWrapper(
        navigationShell: shell,
        workspaceId: 'ws-1',
      );
      expect(wrapper.workspaceId, 'ws-1');
    });

    test('constructor accepts optional key', () {
      final shell = _FakeNavigationShell();
      final wrapper = AuraSidebarWrapper(
        navigationShell: shell,
        workspaceId: 'ws-1',
        key: const Key('test'),
      );
      expect(wrapper.key, const Key('test'));
    });

    test('is a ConsumerWidget', () {
      final shell = _FakeNavigationShell();
      final wrapper = AuraSidebarWrapper(
        navigationShell: shell,
        workspaceId: 'ws-1',
      );
      expect(wrapper, isA<ConsumerWidget>());
    });
  });

  group('AppWithResponsiveDrawer', () {
    test('constructor stores properties', () {
      final widget = AppWithResponsiveDrawer(
        child: const SizedBox(),
        navigationItems: const [],
        onNavigationTap: (_) {},
        selectedIndex: 0,
        workspaceId: 'ws-1',
      );
      expect(widget.workspaceId, 'ws-1');
      expect(widget.selectedIndex, 0);
    });

    test('constructor accepts optional key', () {
      final widget = AppWithResponsiveDrawer(
        child: const SizedBox(),
        navigationItems: const [],
        onNavigationTap: (_) {},
        selectedIndex: 0,
        workspaceId: 'ws-1',
        key: const Key('drawer-key'),
      );
      expect(widget.key, const Key('drawer-key'));
    });

    test('is a StatefulWidget', () {
      final widget = AppWithResponsiveDrawer(
        child: const SizedBox(),
        navigationItems: const [],
        onNavigationTap: (_) {},
        selectedIndex: 0,
        workspaceId: 'ws-1',
      );
      expect(widget, isA<StatefulWidget>());
    });
  });

  testWidgets(
    'workspaceId from route state is available synchronously:'
    ' no Riverpod dependency',
    (tester) async {
      String? capturedWorkspaceId;

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/workspaces/:workspaceId',
            builder: (context, state) => const SizedBox.shrink(),
            routes: [
              StatefulShellRoute.indexedStack(
                branches: [
                  StatefulShellBranch(
                    routes: [
                      GoRoute(
                        path: 'chat/new',
                        builder: (context, state) =>
                            const Text('New chat screen'),
                      ),
                    ],
                  ),
                  StatefulShellBranch(
                    routes: [
                      GoRoute(
                        path: 'tools',
                        builder: (context, state) => const Text('Tools screen'),
                      ),
                    ],
                  ),
                ],
                builder: (context, state, navigationShell) {
                  capturedWorkspaceId = state.pathParameters['workspaceId'];
                  return Text('workspaceId: $capturedWorkspaceId');
                },
              ),
            ],
          ),
        ],
        initialLocation: '/workspaces/ws-test/tools',
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );

      expect(capturedWorkspaceId, 'ws-test');

      final _ = await tester.pumpAndSettle();
      expect(find.text('workspaceId: ws-test'), findsOneWidget);
    },
  );

  testWidgets(
    'workspaceId available after async redirect from root',
    (tester) async {
      String? capturedWorkspaceId;

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/workspaces/:workspaceId',
            builder: (context, state) => const SizedBox.shrink(),
            routes: [
              StatefulShellRoute.indexedStack(
                branches: [
                  StatefulShellBranch(
                    routes: [
                      GoRoute(
                        path: 'chat/new',
                        builder: (context, state) =>
                            const Text('New chat screen'),
                      ),
                    ],
                  ),
                ],
                builder: (context, state, navigationShell) {
                  capturedWorkspaceId = state.pathParameters['workspaceId'];
                  return Text('workspaceId: $capturedWorkspaceId');
                },
              ),
            ],
          ),
        ],
        redirect: (context, state) {
          if (state.uri.toString() == '/') {
            return '/workspaces/ws-redirect-test/chat/new';
          }
          return null;
        },
        initialLocation: '/',
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );

      expect(capturedWorkspaceId, 'ws-redirect-test');

      final _ = await tester.pumpAndSettle();
      expect(find.text('workspaceId: ws-redirect-test'), findsOneWidget);
    },
  );

  testWidgets(
    'specific chat route navigates to branch 0 alongside chat/new',
    (tester) async {
      int? capturedShellIndex;

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/workspaces/:workspaceId',
            builder: (context, state) => const SizedBox.shrink(),
            routes: [
              StatefulShellRoute.indexedStack(
                branches: [
                  StatefulShellBranch(
                    routes: [
                      GoRoute(
                        path: 'chat/new',
                        builder: (context, state) => const Text('New chat'),
                      ),
                      GoRoute(
                        path: 'chats/:chatId',
                        builder: (context, state) => const Text('Chat screen'),
                      ),
                    ],
                  ),
                  StatefulShellBranch(
                    routes: [
                      GoRoute(
                        path: 'tools',
                        builder: (context, state) => const Text('Tools screen'),
                      ),
                    ],
                  ),
                ],
                builder: (context, state, navigationShell) {
                  capturedShellIndex = navigationShell.currentIndex;
                  return navigationShell;
                },
              ),
            ],
          ),
        ],
        initialLocation: '/workspaces/ws-test/chats/chat-123',
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );
      final _ = await tester.pumpAndSettle();

      expect(capturedShellIndex, 0);
      expect(find.text('Chat screen'), findsOneWidget);
    },
  );

  testWidgets(
    'tools route navigates to branch 1',
    (tester) async {
      int? capturedShellIndex;

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/workspaces/:workspaceId',
            builder: (context, state) => const SizedBox.shrink(),
            routes: [
              StatefulShellRoute.indexedStack(
                branches: [
                  StatefulShellBranch(
                    routes: [
                      GoRoute(
                        path: 'chat/new',
                        builder: (context, state) => const Text('New chat'),
                      ),
                    ],
                  ),
                  StatefulShellBranch(
                    routes: [
                      GoRoute(
                        path: 'tools',
                        builder: (context, state) => const Text('Tools screen'),
                      ),
                    ],
                  ),
                ],
                builder: (context, state, navigationShell) {
                  capturedShellIndex = navigationShell.currentIndex;
                  return navigationShell;
                },
              ),
            ],
          ),
        ],
        initialLocation: '/workspaces/ws-test/tools',
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );
      final _ = await tester.pumpAndSettle();

      expect(capturedShellIndex, 1);
      expect(find.text('Tools screen'), findsOneWidget);
    },
  );

  testWidgets(
    'settings route navigates to branch 2',
    (tester) async {
      int? capturedShellIndex;

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/workspaces/:workspaceId',
            builder: (context, state) => const SizedBox.shrink(),
            routes: [
              StatefulShellRoute.indexedStack(
                branches: [
                  StatefulShellBranch(
                    routes: [
                      GoRoute(
                        path: 'chat/new',
                        builder: (context, state) => const Text('New chat'),
                      ),
                    ],
                  ),
                  StatefulShellBranch(
                    routes: [
                      GoRoute(
                        path: 'tools',
                        builder: (context, state) => const Text('Tools screen'),
                      ),
                    ],
                  ),
                  StatefulShellBranch(
                    routes: [
                      GoRoute(
                        path: 'settings',
                        builder: (context, state) =>
                            const Text('Settings screen'),
                      ),
                    ],
                  ),
                ],
                builder: (context, state, navigationShell) {
                  capturedShellIndex = navigationShell.currentIndex;
                  return navigationShell;
                },
              ),
            ],
          ),
        ],
        initialLocation: '/workspaces/ws-test/settings',
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );
      final _ = await tester.pumpAndSettle();

      expect(capturedShellIndex, 2);
      expect(find.text('Settings screen'), findsOneWidget);
    },
  );

  group('AuraSidebarWrapper rendering', () {
    ({Widget app, GoRouter router}) _buildTestApp({
      required String initialLocation,
      required List<StatefulShellBranch> branches,
    }) {
      final repo = _FakeConversationRepository();
      addTearDown(() async {
        await repo.close();
      });
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/workspaces/:workspaceId',
            builder: (context, state) => const SizedBox.shrink(),
            routes: [
              StatefulShellRoute.indexedStack(
                branches: branches,
                builder: (context, state, navigationShell) {
                  final workspaceId = state.pathParameters['workspaceId'] ?? '';
                  return Theme(
                    data: ThemeData(extensions: [AuraTheme.light]),
                    child: Material(
                      child: Portal(
                        child: AuraSidebarWrapper(
                          navigationShell: navigationShell,
                          workspaceId: workspaceId,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
        initialLocation: initialLocation,
      );
      addTearDown(router.dispose);
      final app = EasyLocalization(
        child: Builder(
          builder: (context) {
            return TestProviderScope(
              overrides: [
                conversationRepositoryProvider.overrideWithValue(repo),
                allWorkspacesProvider.overrideWith(
                  (ref) => Stream.value([
                    WorkspaceEntity(
                      id: 'ws-test',
                      name: 'Test workspace',
                      type: WorkspaceType.local,
                      createdAt: DateTime(2020),
                      updatedAt: DateTime(2020),
                    ),
                  ]),
                ),
                routerPathSegmentsProvider.overrideWithValue(const []),
              ],
              child: MaterialApp.router(
                routerConfig: router,
                locale: context.locale,
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
              ),
            );
          },
        ),
        supportedLocales: const [Locale('en')],
        path: 'assets/i18n',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        useOnlyLangCode: true,
        useFallbackTranslations: true,
      );
      return (app: app, router: router);
    }

    testWidgets('renders sidebar for multiple routes', (tester) async {
      final branches = [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: 'chat/new',
              builder: (_, _) => const SizedBox.shrink(),
            ),
            GoRoute(
              path: 'chats/:chatId',
              builder: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: 'tools',
              builder: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: 'models',
              builder: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: 'settings',
              builder: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
      ];

      final (:app, :router) = _buildTestApp(
        initialLocation: '/workspaces/ws-test/tools',
        branches: branches,
      );
      await tester.pumpWidget(app);
      await tester.pump();

      expect(find.byType(AuraSidebarWrapper), findsOneWidget);

      router.go('/workspaces/ws-test/chat/new');
      await tester.pump();

      expect(find.byType(AuraSidebarWrapper), findsOneWidget);

      router.go('/workspaces/ws-test/chats/chat-123');
      await tester.pump();

      expect(find.byType(AuraSidebarWrapper), findsOneWidget);

      router.go('/workspaces/ws-test/models');
      await tester.pump();

      expect(find.byType(AuraSidebarWrapper), findsOneWidget);

      router.go('/workspaces/ws-test/settings');
      await tester.pump();

      expect(find.byType(AuraSidebarWrapper), findsOneWidget);
    });

    test(
      'fake conversation repository close clears tracked controllers',
      () async {
        final repo = _FakeConversationRepository()
          ..watchConversationsByWorkspace('ws-test');

        expect(repo._controllers, hasLength(1));

        await repo.close();

        expect(repo._controllers, isEmpty);
      },
    );
  });
}

class _FakeNavigationShell extends Fake implements StatefulNavigationShell {
  @override
  final int currentIndex = 0;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_FakeNavigationShell';
}

class _FakeConversationRepository implements ConversationRepository {
  final _controllers = <StreamController<List<ConversationEntity>>>[];
  final _pendingRemoval = <StreamController<List<ConversationEntity>>>{};

  void _processPendingRemovals() {
    if (_pendingRemoval.isNotEmpty) {
      _controllers.removeWhere(_pendingRemoval.contains);
      _pendingRemoval.clear();
    }
  }

  @override
  Stream<List<ConversationEntity>> watchConversationsByWorkspace(
    String workspaceId, {
    int? limit,
  }) {
    _processPendingRemovals();

    final controller = StreamController<List<ConversationEntity>>.broadcast();
    controller.onCancel = () => _pendingRemoval.add(controller);
    _controllers.add(controller);
    controller.add(const []);
    return controller.stream;
  }

  Future<void> close() async {
    _processPendingRemovals();

    final controllersSnapshot =
        List<StreamController<List<ConversationEntity>>>.of(_controllers);
    _controllers.clear();
    _pendingRemoval.clear();
    final _ = await Future.wait(
      controllersSnapshot.where((c) => !c.isClosed).map((c) => c.close()),
    );
  }

  @override
  Future<ConversationEntity> createConversation(
    ConversationToCreate conversation,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteConversation(String id) {
    throw UnimplementedError();
  }

  @override
  Future<ConversationEntity?> getConversationById(String id) {
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
  Stream<ConversationEntity?> watchConversationById(String id) {
    throw UnimplementedError();
  }
}
