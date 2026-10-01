// Required: Existing test and UI helpers keep compact return flow.

import 'dart:async';

import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/router/draft_exit_guard.dart';
import 'package:auravibes_app/router/draft_exit_registry_provider.dart';
import 'package:auravibes_app/widgets/aura_sidebar_wrapper.dart';
import 'package:auravibes_app/widgets/draft_exit_scope.dart';
import 'package:auravibes_app/widgets/responsive_sliding_drawer_controller.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

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
        onNavigationTap: (_) {
          final _ = Object();
        },
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
        onNavigationTap: (_) {
          final _ = Object();
        },
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
        onNavigationTap: (_) {
          final _ = Object();
        },
        selectedIndex: 0,
        workspaceId: 'ws-1',
      );
      expect(widget, isA<StatefulWidget>());
    });
  });

  testWidgets('workspaceId is synchronous without Riverpod', (tester) async {
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

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    expect(capturedWorkspaceId, 'ws-test');

    final _ = await tester.pumpAndSettle();
    expect(find.text('workspaceId: ws-test'), findsOneWidget);
  });

  testWidgets('workspaceId available after async redirect from root', (
    tester,
  ) async {
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

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    expect(capturedWorkspaceId, 'ws-redirect-test');

    final _ = await tester.pumpAndSettle();
    expect(find.text('workspaceId: ws-redirect-test'), findsOneWidget);
  });

  testWidgets('specific chat route navigates to branch 0 alongside chat/new', (
    tester,
  ) async {
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
    expect(find.text('Chat screen'), findsOneWidget);
  });

  testWidgets('tools route navigates to branch 1', (tester) async {
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

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    final _ = await tester.pumpAndSettle();

    expect(capturedShellIndex, 1);
    expect(find.text('Tools screen'), findsOneWidget);
  });

  testWidgets('settings route navigates to branch 2', (tester) async {
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

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    final _ = await tester.pumpAndSettle();

    expect(capturedShellIndex, 2);
    expect(find.text('Settings screen'), findsOneWidget);
  });

  testWidgets('workspace shell blocks root pop', (tester) async {
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
              ],
              builder: (context, state, navigationShell) {
                final workspaceId = state.pathParameters['workspaceId'];

                if (workspaceId == null || workspaceId.isEmpty) {
                  throw StateError(
                    'workspaceId must be present in route pathParameters',
                  );
                }

                return PopScope(
                  child: Text('workspaceId: $workspaceId'),
                  canPop: false,
                );
              },
            ),
          ],
        ),
      ],
      initialLocation: '/workspaces/ws-test/chat/new',
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    final _ = await tester.pumpAndSettle();

    expect(find.text('workspaceId: ws-test'), findsOneWidget);

    final didPop = await Navigator.of(
      tester.element(find.text('workspaceId: ws-test')),
    ).maybePop();
    await tester.pump();

    expect(didPop, isTrue);
    expect(find.text('workspaceId: ws-test'), findsOneWidget);
    expect(
      router.routeInformationProvider.value.uri.path,
      '/workspaces/ws-test/chat/new',
    );
  });

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

                  return AuraThemeScope(
                    theme: .light,
                    child: Theme(
                      data: .new(),
                      child: Material(
                        child: Portal(
                          child: AuraSidebarWrapper(
                            navigationShell: navigationShell,
                            workspaceId: workspaceId,
                          ),
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
                      type: .local,
                      createdAt: .new(2020),
                      updatedAt: .new(2020),
                    ),
                  ]),
                ),
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

    testWidgets(
      'primary selection, remembered destinations and one guarded exit use '
      'actual routes',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final guard = DraftExitGuard();
        var confirmations = 0;
        var answer = Completer<bool>();
        final branches = [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: 'chat/new',
                builder: (_, _) => const Text('New draft'),
              ),
              GoRoute(
                path: 'chats/:chatId',
                builder: (_, _) => const Text('Saved conversation'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: 'more/agents',
                builder: (_, _) => const Text('Agents list'),
              ),
              GoRoute(
                path: 'more/skills',
                builder: (_, _) => const Text('Skills list'),
                routes: [
                  GoRoute(
                    path: ':skillId',
                    builder: (_, _) {
                      guard.bind(
                        isDirty: () => true,
                        isSaving: () => false,
                        confirm: (_) {
                          confirmations++;

                          return answer.future;
                        },
                      );

                      return DraftExitScope(
                        guard: guard,
                        child: const Text('Dirty skill'),
                      );
                    },
                    onExit: (context, state) => ProviderScope.containerOf(
                      context,
                      listen: false,
                    ).read(draftExitRegistryProvider).canExitRoute(state.uri),
                  ),
                ],
              ),
              GoRoute(
                path: 'more/service-connections',
                builder: (_, _) => const Text('Connections list'),
              ),
              GoRoute(
                path: 'more/cloud-accounts',
                builder: (_, _) => const Text('Accounts list'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: 'settings',
                builder: (_, _) => const Text('Appearance'),
              ),
            ],
          ),
        ];
        final (:app, :router) = _buildTestApp(
          initialLocation: '/workspaces/ws-test/chats/chat-A',
          branches: branches,
        );
        await tester.runAsync(() => tester.pumpWidget(app));
        final _ = await tester.pumpAndSettle();
        AuraSidebar sidebar() =>
            tester.widget<AuraSidebar>(find.byType(AuraSidebar));
        expect(sidebar().selectedIndex, -1);
        router.go('/workspaces/ws-test/more/skills');
        final _ = await tester.pumpAndSettle();
        expect(sidebar().selectedIndex, 1);
        router.go('/workspaces/ws-test/more/skills/skill-A');
        final _ = await tester.pumpAndSettle();
        sidebar().onNavigationTap.call(2);
        sidebar().onNavigationTap.call(3);
        await tester.pump();
        expect(confirmations, 1);
        expect(
          router.state.uri.path,
          '/workspaces/ws-test/more/skills/skill-A',
        );
        answer.complete(false);
        final _ = await tester.pumpAndSettle();
        expect(sidebar().selectedIndex, 1);
        answer = Completer<bool>();
        sidebar().onNavigationTap.call(2);
        await tester.pump();
        answer.complete(true);
        final _ = await tester.pumpAndSettle();
        expect(confirmations, 2);
        expect(
          router.state.uri.path,
          '/workspaces/ws-test/more/service-connections',
        );
        expect(sidebar().selectedIndex, 2);
        sidebar().onNavigationTap.call(1);
        final _ = await tester.pumpAndSettle();
        expect(router.state.uri.path, '/workspaces/ws-test/more/skills');
        sidebar().onNavigationTap.call(3);
        final _ = await tester.pumpAndSettle();
        expect(router.state.uri.path, '/workspaces/ws-test/settings');
        expect(sidebar().selectedIndex, 3);
        sidebar().onNavigationTap.call(4);
        final _ = await tester.pumpAndSettle();
        expect(
          router.state.uri.path,
          '/workspaces/ws-test/more/cloud-accounts',
        );
        expect(sidebar().selectedIndex, 4);
        sidebar().onNavigationTap.call(0);
        final _ = await tester.pumpAndSettle();
        expect(router.state.uri.path, '/workspaces/ws-test/chats/chat-A');
        expect(confirmations, 2);
        router.go('/workspaces/B/chat/new');
        final _ = await tester.pumpAndSettle();
        sidebar().onNavigationTap.call(1);
        final _ = await tester.pumpAndSettle();
        expect(router.state.uri.path, '/workspaces/B/more/agents');
        router.go('/workspaces/ws-test/chat/new');
        final _ = await tester.pumpAndSettle();
        sidebar().onNavigationTap.call(1);
        final _ = await tester.pumpAndSettle();
        expect(router.state.uri.path, '/workspaces/ws-test/more/skills');
        for (final width in [959.0, 960.0]) {
          tester.view.physicalSize = .new(width, 900);
          final _ = await tester.pumpAndSettle();
          final controller = ResponsiveSlidingDrawerProvider.of(
            tester.element(find.text('Skills list')),
          );
          expect(controller.isDesktop, width >= 960);
          expect(tester.takeException(), isNull);
        }
      },
    );

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
            GoRoute(path: 'tools', builder: (_, _) => const SizedBox.shrink()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: 'models', builder: (_, _) => const SizedBox.shrink()),
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
      await tester.runAsync(() async {
        await tester.pumpWidget(app);
      });
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

  @override
  Stream<List<ConversationEntity>> watchConversationsByWorkspace(
    String workspaceId, {
    String? search,
    int? limit,
    int offset = 0,
  }) {
    _processPendingRemovals();

    final controller = StreamController<List<ConversationEntity>>.broadcast();
    controller.onCancel = () => _pendingRemoval.add(controller);
    _controllers.add(controller);
    controller.onListen = () => controller.add(const []);

    return controller.stream;
  }

  @override
  Stream<List<ConversationEntity>> watchChildConversations(
    String parentConversationId,
  ) {
    return const Stream.empty();
  }

  @override
  Future<List<ConversationEntity>> getChildConversations(
    String parentConversationId,
  ) async {
    return const [];
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

  @override
  Future<ConversationEntity> forkConversation(
    String sourceConversationId, {
    String? throughMessageId,
  }) => throw UnimplementedError();

  void _processPendingRemovals() {
    if (_pendingRemoval.isNotEmpty) {
      _controllers.removeWhere(_pendingRemoval.contains);
      _pendingRemoval.clear();
    }
  }
}
