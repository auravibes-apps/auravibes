import 'dart:async';

import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/draft_exit_guard.dart';
import 'package:auravibes_app/router/workspace_navigation.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/adaptive_master_detail_layout.dart';
import 'package:auravibes_app/widgets/draft_exit_scope.dart';
import 'package:auravibes_app/widgets/feature_destination_app_bar.dart';
import 'package:auravibes_app/widgets/feature_destination_master.dart';
import 'package:auravibes_app/widgets/feature_destination_shell.dart';
import 'package:auravibes_app/widgets/feature_destination_shell_scope.dart';
import 'package:auravibes_app/widgets/feature_destinations.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    as sdk_localizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  for (final language in ['en', 'es']) {
    for (final width in [466.0, 671.0, 1280.0]) {
      testWidgets('$language destination navigation at width $width', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(.new(width, 700));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final groups = [
          FeatureDestinations.connections('A'),
          FeatureDestinations.agents('A'),
        ];
        final router = _router(
          FeatureDestinations.connectionLocation('A', .overview),
        );
        addTearDown(router.dispose);
        await _pumpRouter(tester, router, language);
        final isSplit =
            width >= FeatureDestinationShellLayout.masterDetailBreakpoint;

        for (final destinations in groups) {
          for (var index = 0; index < destinations.length; index++) {
            final destination = destinations[index];
            final masterLocation = FeatureDestinations.masterLocation(
              destination.location,
            );
            router.go(isSplit ? destination.location : masterLocation);
            final _ = await tester.pumpAndSettle();

            if (!isSplit) {
              expect(router.state.uri.toString(), masterLocation);
              expect(find.byType(FeatureDestinationMaster), findsOneWidget);
              expect(find.text('Feature details'), findsNothing);
              expect(find.byIcon(Icons.menu), findsOneWidget);
              await tester.tap(find.byKey(_destinationKey(destination)));
              final _ = await tester.pumpAndSettle();
            }

            expect(router.state.uri.toString(), destination.location);
            expect(
              find.descendant(
                of: find.byType(FeatureDestinationAppBar),
                matching: find.byIcon(Icons.menu),
              ),
              findsNothing,
            );

            final next = destinations[(index + 1) % destinations.length];
            if (isSplit) {
              expect(find.byType(FeatureDestinationMaster), findsOneWidget);
              expect(
                find.descendant(
                  of: find.byType(FeatureDestinationMaster),
                  matching: find.byIcon(Icons.menu),
                ),
                findsOneWidget,
              );
              expect(
                find.byKey(const ValueKey('feature_destination_picker')),
                findsWidgets,
              );
              expect(
                find.byKey(const ValueKey('app_navigation_back')),
                findsNothing,
              );
              expect(find.byIcon(Icons.arrow_back), findsNothing);
              expect(
                tester
                    .widget<AuraTile>(find.byKey(_destinationKey(destination)))
                    .variant,
                AuraTileVariant.selected,
              );
              expect(
                find.descendant(
                  of: find.byType(FeatureDestinationMaster),
                  matching: find.text(
                    _localizedLabel(destination.labelKey, language),
                  ),
                ),
                findsOneWidget,
              );
              await tester.tap(find.byKey(_destinationKey(next)));
            } else {
              expect(find.byType(FeatureDestinationMaster), findsNothing);
              expect(find.byIcon(Icons.menu), findsNothing);
              expect(find.byIcon(Icons.arrow_back), findsOneWidget);
              expect(
                find.byKey(const ValueKey('feature_destination_picker')),
                findsWidgets,
              );
              expect(
                find.text(_localizedLabel(destination.labelKey, language)),
                findsOneWidget,
              );
              await tester.tap(
                find.byKey(const ValueKey('app_navigation_back')),
              );
              final _ = await tester.pumpAndSettle();
              expect(router.state.uri.toString(), masterLocation);
              expect(find.byType(FeatureDestinationMaster), findsOneWidget);
              expect(find.text('Feature details'), findsNothing);
              expect(find.byIcon(Icons.arrow_back), findsNothing);
              await tester.tap(find.byKey(_destinationKey(next)));
            }

            final _ = await tester.pumpAndSettle();
            expect(router.state.uri.toString(), next.location);
            expect(router.canPop(), isTrue);
            expect(tester.takeException(), isNull);
          }
        }
      });
    }
  }

  testWidgets('wide master route has no selected destination or detail', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final groups = [
      FeatureDestinations.connections('A'),
      FeatureDestinations.agents('A'),
    ];
    final router = _router(
      FeatureDestinations.masterLocation(
        FeatureDestinations.connectionLocation('A', .overview),
      ),
    );
    addTearDown(router.dispose);
    await _pumpRouter(tester, router, 'en');

    for (final destinations in groups) {
      final firstDestination =
          destinations.firstOrNull ?? (throw StateError('Missing destination'));
      final masterLocation = FeatureDestinations.masterLocation(
        firstDestination.location,
      );
      router.go(masterLocation);
      final _ = await tester.pumpAndSettle();
      final masterTitleKey =
          firstDestination.labelKey == LocaleKeys.related_lists_agents
          ? LocaleKeys.navigation_agents_skills
          : LocaleKeys.navigation_connections;

      expect(router.state.uri.toString(), masterLocation);
      expect(find.byType(FeatureDestinationMaster), findsOneWidget);
      expect(find.text('Feature details'), findsNothing);
      expect(find.text(_localizedLabel(masterTitleKey, 'en')), findsOneWidget);
      expect(find.byKey(const ValueKey('feature-action')), findsNothing);
      for (final destination in destinations) {
        expect(
          tester
              .widget<AuraTile>(find.byKey(_destinationKey(destination)))
              .variant,
          AuraTileVariant.ghost,
        );
      }
      expect(find.byKey(const ValueKey('app_navigation_back')), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('nested credential routes select saved credentials', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final credentials = FeatureDestinations.connections('A').last;
    final router = _router(
      FeatureDestinations.masterLocation(credentials.location),
    );
    addTearDown(router.dispose);
    await _pumpRouter(tester, router, 'en');

    await tester.tap(find.byKey(_destinationKey(credentials)));
    final _ = await tester.pumpAndSettle();
    unawaited(
      router.push<void>('/workspaces/A/skill-credential-definitions/new'),
    );
    final _ = await tester.pumpAndSettle();

    expect(
      router.state.uri.path,
      '/workspaces/A/skill-credential-definitions/new',
    );
    expect(
      tester.widget<AuraTile>(find.byKey(_destinationKey(credentials))).variant,
      AuraTileVariant.selected,
    );
    expect(tester.takeException(), isNull);
  });

  for (final (:name, :initialLocation, :isAgents) in [
    (
      name: 'connection query route',
      initialLocation: '/workspaces/A/service-connections?view=providers',
      isAgents: false,
    ),
    (
      name: 'nested agent editor route',
      initialLocation: '/workspaces/A/agents/new',
      isAgents: true,
    ),
  ]) {
    testWidgets('$name restores without showing the master first', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final router = _directLinkRouter(initialLocation, isAgents: isAgents);
      addTearDown(router.dispose);

      await _pumpRouter(tester, router, 'en', settle: false);

      expect(find.byType(AuraSpinner), findsOneWidget);
      expect(find.byType(FeatureDestinationMaster), findsNothing);
      expect(find.text('Feature details'), findsNothing);

      final _ = await tester.pumpAndSettle();
      expect(router.state.uri.toString(), initialLocation);
      expect(find.byType(FeatureDestinationMaster), findsOneWidget);
      expect(find.text('Feature details'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final width in [466.0, 671.0]) {
    testWidgets('destination navigation respects a dirty draft at $width', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(.new(width, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final connections = FeatureDestinations.connections('A');
      final firstConnection =
          connections.firstOrNull ?? (throw StateError('Missing connection'));
      final masterLocation = FeatureDestinations.masterLocation(
        firstConnection.location,
      );
      final router = _router(
        masterLocation,
        buildPage: (state) => _GuardedFeatureDestinationPage(state: state),
      );
      addTearDown(router.dispose);
      await _pumpRouter(tester, router, 'en');

      await tester.tap(find.byKey(_destinationKey(firstConnection)));
      final _ = await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('draft-field')),
        'draft',
      );
      if (width < FeatureDestinationShellLayout.masterDetailBreakpoint) {
        await tester.tap(find.byKey(const ValueKey('app_navigation_back')));
      } else {
        await tester.tap(find.byKey(_destinationKey(connections[1])));
      }
      final _ = await tester.pumpAndSettle();

      expect(find.text('Keep editing'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      final _ = await tester.pumpAndSettle();
      expect(
        router.state.uri.toString(),
        connections.firstOrNull?.location ??
            FeatureDestinations.connectionLocation('A', .overview),
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('draft-field')))
            .controller
            ?.text,
        'draft',
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('compact destination supports iOS back swipe and back button', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(466, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final destinations = FeatureDestinations.agents('A');
    final masterLocation = FeatureDestinations.masterLocation(
      AgentsRoute(workspaceId: 'A').location,
    );
    final router = _router(masterLocation);
    addTearDown(router.dispose);
    await _pumpRouter(tester, router, 'en', platform: .iOS);

    await tester.tap(find.byKey(_destinationKey(destinations.last)));
    final _ = await tester.pumpAndSettle();
    expect(router.state.uri.toString(), destinations.last.location);
    expect(router.canPop(), isTrue);
    expect(
      ModalRoute.of(tester.element(find.text('Feature details')))
          ?.popGestureEnabled,
      isTrue,
    );

    await tester.dragFrom(const Offset(1, 350), const Offset(350, 0));
    final _ = await tester.pumpAndSettle();
    expect(router.state.uri.toString(), masterLocation);
    expect(find.byType(FeatureDestinationMaster), findsOneWidget);

    await tester.tap(find.byKey(_destinationKey(destinations.last)));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('app_navigation_back')));
    final _ = await tester.pumpAndSettle();
    expect(router.state.uri.toString(), masterLocation);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact Back pops to master and preserves route history', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(466, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final agentsLocation = AgentsRoute(workspaceId: 'A').location;
    final masterLocation = FeatureDestinations.masterLocation(agentsLocation);
    final router = _router('/previous');
    addTearDown(router.dispose);
    await _pumpRouter(tester, router, 'en', platform: .iOS);

    unawaited(router.push<void>(masterLocation));
    final _ = await tester.pumpAndSettle();
    expect(router.canPop(), isTrue);
    await tester.tap(
      find.byKey(_destinationKey(FeatureDestinations.agents('A').last)),
    );
    final _ = await tester.pumpAndSettle();
    expect(router.state.uri.path, '/workspaces/A/skills');

    await tester.tap(find.byKey(const ValueKey('app_navigation_back')));
    final _ = await tester.pumpAndSettle();

    expect(router.state.uri.toString(), masterLocation);
    expect(find.byType(FeatureDestinationMaster), findsOneWidget);
    expect(router.canPop(), isTrue);

    final _ = await tester.binding.handlePopRoute();
    final _ = await tester.pumpAndSettle();
    expect(router.state.uri.toString(), masterLocation);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wide destination changes leave the master pane stationary', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final destinations = FeatureDestinations.connections('A');
    final overview =
        destinations.firstOrNull ??
        (throw StateError('Missing connection overview destination'));
    final masterLocation = FeatureDestinations.masterLocation(
      overview.location,
    );
    final router = _router(masterLocation);
    addTearDown(router.dispose);
    await _pumpRouter(tester, router, 'en');

    final master = find.byType(FeatureDestinationMaster);
    final masterPosition = tester.getTopLeft(master);
    await tester.tap(find.byKey(_destinationKey(overview)));
    final _ = await tester.pump(const Duration(milliseconds: 80));
    expect(tester.getTopLeft(master), masterPosition);
    expect(find.byType(FeatureDestinationMaster), findsOneWidget);
    final _ = await tester.pumpAndSettle();

    await tester.tap(find.byKey(_destinationKey(destinations[1])));
    final _ = await tester.pump(const Duration(milliseconds: 80));
    expect(tester.getTopLeft(master), masterPosition);
    expect(router.state.uri.queryParameters['view'], 'providers');
    expect(find.byType(FeatureDestinationMaster), findsOneWidget);
    final _ = await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('nested detail Back returns to feature detail then master', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(466, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final destinations = FeatureDestinations.connections('A');
    final overview =
        destinations.firstOrNull ??
        (throw StateError('Missing connection overview destination'));
    final masterLocation = FeatureDestinations.masterLocation(
      overview.location,
    );
    final router = _router(masterLocation);
    addTearDown(router.dispose);
    await _pumpRouter(tester, router, 'en');

    await tester.tap(find.byKey(_destinationKey(overview)));
    final _ = await tester.pumpAndSettle();
    unawaited(router.push<void>('/workspaces/A/service-connections/new'));
    final _ = await tester.pumpAndSettle();
    expect(router.state.uri.path, '/workspaces/A/service-connections/new');
    expect(find.byIcon(Icons.menu), findsNothing);
    router.pop();
    final _ = await tester.pumpAndSettle();
    expect(router.state.uri.path, '/workspaces/A/service-connections');

    await tester.tap(find.byKey(const ValueKey('feature_destination_back')));
    final _ = await tester.pumpAndSettle();
    expect(router.state.uri.toString(), masterLocation);
    expect(find.byType(FeatureDestinationMaster), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpRouter(
  WidgetTester tester,
  GoRouter router,
  String language, {
  TargetPlatform? platform,
  bool settle = true,
}) async {
  await tester.runAsync(
    () => tester.pumpWidget(
      ProviderScope(
        child: EasyLocalization(
          child: Builder(
            builder: (context) => Portal(
              child: MaterialApp.router(
                routerConfig: router,
                theme: platform == null ? null : ThemeData(platform: platform),
                locale: context.locale,
                localizationsDelegates: [
                  ...GlobalMaterialLocalizations.delegates,
                  sdk_localizations.GlobalMaterialLocalizations.delegate,
                  ...context.localizationDelegates,
                ],
                supportedLocales: context.supportedLocales,
              ),
            ),
          ),
          supportedLocales: const [Locale('en'), Locale('es')],
          path: 'assets/i18n',
          startLocale: .new(language),
        ),
      ),
    ),
  );
  if (settle) {
    final _ = await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

GoRouter _directLinkRouter(String initialLocation, {required bool isAgents}) {
  final featureShell = isAgents
      ? const AgentsSkillsFeatureShellRouteData()
      : const ConnectionsFeatureShellRouteData();
  final featureNavigatorKey = isAgents
      ? AgentsSkillsFeatureShellRouteData.$navigatorKey
      : ConnectionsFeatureShellRouteData.$navigatorKey;
  MaterialPage<void> pageBuilder(BuildContext _, GoRouterState state) =>
      MaterialPage<void>(
        child: _FeatureDestinationPage(state: state),
        key: ValueKey(state.uri.toString()),
      );

  return GoRouter(
    routes: [
      GoRoute(
        path: '/workspaces/:workspaceId',
        builder: (_, _) => const SizedBox.shrink(),
        routes: [
          ShellRoute(
            redirect: featureShell.redirect,
            builder: featureShell.builder,
            routes: isAgents
                ? [
                    GoRoute(
                      path: 'agents',
                      pageBuilder: pageBuilder,
                      routes: [GoRoute(path: 'new', pageBuilder: pageBuilder)],
                    ),
                    GoRoute(path: 'skills', pageBuilder: pageBuilder),
                  ]
                : [
                    GoRoute(path: 'tools', pageBuilder: pageBuilder),
                    GoRoute(
                      path: 'service-connections',
                      pageBuilder: pageBuilder,
                    ),
                  ],
            navigatorKey: featureNavigatorKey,
          ),
        ],
      ),
    ],
    initialLocation: initialLocation,
    navigatorKey: workspaceFeatureNavigatorKey,
  );
}

GoRouter _router(
  String initialLocation, {
  Widget Function(GoRouterState state)? buildPage,
}) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final connectionsNavigatorKey = GlobalKey<NavigatorState>();
  final agentsNavigatorKey = GlobalKey<NavigatorState>();
  MaterialPage<void> pageBuilder(BuildContext _, GoRouterState state) =>
      MaterialPage<void>(
        child: buildPage?.call(state) ?? _FeatureDestinationPage(state: state),
        key: ValueKey(state.uri.toString()),
      );

  return GoRouter(
    routes: [
      GoRoute(path: '/previous', builder: (_, _) => const Text('Previous')),
      GoRoute(
        path: '/workspaces/:workspaceId',
        builder: (_, _) => const SizedBox.shrink(),
        routes: [
          ShellRoute(
            builder: (context, state, child) => FeatureDestinationShell(
              navigatorKey: connectionsNavigatorKey,
              parentNavigatorKey: rootNavigatorKey,
              destinations: FeatureDestinations.connections(
                state.pathParameters['workspaceId']!,
              ),
              child: child,
              initialLocation: null,
            ),
            routes: [
              GoRoute(path: 'tools', pageBuilder: pageBuilder),
              GoRoute(
                path: 'service-connections',
                pageBuilder: pageBuilder,
                routes: [GoRoute(path: 'new', pageBuilder: pageBuilder)],
              ),
              GoRoute(
                path: 'skill-credential-definitions',
                pageBuilder: pageBuilder,
                routes: [
                  GoRoute(path: 'new', pageBuilder: pageBuilder),
                  GoRoute(path: ':definitionId', pageBuilder: pageBuilder),
                ],
              ),
            ],
            navigatorKey: connectionsNavigatorKey,
          ),
          ShellRoute(
            builder: (context, state, child) => FeatureDestinationShell(
              navigatorKey: agentsNavigatorKey,
              parentNavigatorKey: rootNavigatorKey,
              destinations: FeatureDestinations.agents(
                state.pathParameters['workspaceId']!,
              ),
              child: child,
              initialLocation: null,
            ),
            routes: [
              GoRoute(path: 'agents', pageBuilder: pageBuilder),
              GoRoute(path: 'skills', pageBuilder: pageBuilder),
            ],
            navigatorKey: agentsNavigatorKey,
          ),
        ],
      ),
    ],
    initialLocation: initialLocation,
    navigatorKey: rootNavigatorKey,
  );
}

ValueKey<String> _destinationKey(FeatureNavigationDestination destination) =>
    ValueKey('feature-destination-${destination.location}');

String _localizedLabel(String key, String language) => switch (key) {
  'related_lists.agents' => language == 'en' ? 'Agents' : 'Agentes',
  'related_lists.skills' => language == 'en' ? 'Skills' : 'Habilidades',
  'related_lists.overview' => language == 'en' ? 'Overview' : 'Resumen',
  'related_lists.providers' =>
    language == 'en' ? 'AI providers' : 'Proveedores de IA',
  'related_lists.services' => language == 'en' ? 'Services' : 'Servicios',
  'related_lists.tools' => language == 'en' ? 'Tools' : 'Herramientas',
  'related_lists.credentials' =>
    language == 'en' ? 'Saved credentials' : 'Credenciales guardadas',
  'navigation.agents_skills' =>
    language == 'en' ? 'Agents & skills' : 'Agentes y habilidades',
  'navigation.connections' => language == 'en' ? 'Connections' : 'Conexiones',
  _ => throw ArgumentError.value(key, 'key'),
};

class const _FeatureDestinationPage({
  required final GoRouterState state,
  final TextEditingController? draftController,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final workspaceId = state.pathParameters['workspaceId'] ?? '';
    final section = state.uri.pathSegments.skip(2).firstOrNull;
    final isAgentFeature = section == 'agents' || section == 'skills';
    final destinations = isAgentFeature
        ? FeatureDestinations.agents(workspaceId)
        : FeatureDestinations.connections(workspaceId);
    final selectedLocation = switch (section) {
      'agents' => AgentsRoute(workspaceId: workspaceId).location,
      'skills' => SkillsRoute(workspaceId: workspaceId).location,
      'tools' => FeatureDestinations.connectionLocation(workspaceId, .tools),
      _ => FeatureDestinations.connectionLocation(
        workspaceId,
        WorkspaceNavigation.connectionView(state.uri.queryParameters['view']),
      ),
    };

    return Scaffold(
      appBar: FeatureDestinationAppBar(
        destinations: destinations,
        selectedLocation: selectedLocation,
        masterTitleKey: isAgentFeature
            ? LocaleKeys.navigation_agents_skills
            : LocaleKeys.navigation_connections,
        actions: const [Icon(Icons.more_vert, key: ValueKey('feature-action'))],
      ),
      body: AdaptiveMasterDetailLayout(
        destinations: destinations,
        selectedLocation: selectedLocation,
        child: Column(
          children: [
            const Text('Feature details'),
            if (draftController case final controller?)
              TextField(
                key: const ValueKey('draft-field'),
                controller: controller,
              ),
          ],
        ),
      ),
    );
  }
}

class _GuardedFeatureDestinationPage extends StatefulWidget {
  const new({required this.state});

  final GoRouterState state;

  @override
  State<_GuardedFeatureDestinationPage> createState() =>
      _GuardedFeatureDestinationPageState();
}

class _GuardedFeatureDestinationPageState
    extends State<_GuardedFeatureDestinationPage> {
  final _guard = DraftExitGuard();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    _guard.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _guard.bind(
      readers: (
        isDirty: () => _controller.text.isNotEmpty,
        isSaving: () => false,
      ),
    );

    return DraftExitScope(
      guard: _guard,
      child: _FeatureDestinationPage(
        state: widget.state,
        draftController: _controller,
      ),
    );
  }
}
