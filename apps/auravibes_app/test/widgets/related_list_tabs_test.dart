import 'package:auravibes_app/features/agents/widgets/agents_skills_tabs.dart';
import 'package:auravibes_app/features/service_connections/widgets/connections_tabs.dart';
import 'package:auravibes_app/router/workspace_navigation.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
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
    for (final width in [360.0, 959.0, 960.0]) {
      testWidgets('$language local list tabs navigate at width $width', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(.new(width, 700));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/workspaces/:workspaceId/more/:section',
              builder: (_, state) => _RelatedTabsPage(state: state),
            ),
          ],
          initialLocation:
              '/workspaces/A/more/service-connections?view=unknown',
        );
        addTearDown(router.dispose);
        await tester.runAsync(
          () => tester.pumpWidget(
            ProviderScope(
              child: EasyLocalization(
                child: Builder(
                  builder: (context) => MaterialApp.router(
                    routerConfig: router,
                    locale: context.locale,
                    localizationsDelegates: [
                      ...GlobalMaterialLocalizations.delegates,
                      sdk_localizations.GlobalMaterialLocalizations.delegate,
                      ...context.localizationDelegates,
                    ],
                    supportedLocales: context.supportedLocales,
                  ),
                ),
                supportedLocales: const [Locale('en'), Locale('es')],
                path: 'assets/i18n',
                startLocale: .new(language),
              ),
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();
        expect(
          tester
              .widget<AuraTabs<ConnectionDestination>>(
                find.byType(AuraTabs<ConnectionDestination>),
              )
              .value,
          ConnectionDestination.overview,
        );
        final serviceLabel = language == 'en' ? 'Services' : 'Servicios';
        await tester.ensureVisible(find.text(serviceLabel));
        await tester.tap(find.text(serviceLabel));
        final _ = await tester.pumpAndSettle();
        expect(
          router.routeInformationProvider.value.uri.queryParameters['view'],
          'services',
        );
        final toolsLabel = language == 'en' ? 'Tools' : 'Herramientas';
        await tester.ensureVisible(find.text(toolsLabel));
        await tester.tap(find.text(toolsLabel));
        final _ = await tester.pumpAndSettle();
        expect(
          router.routeInformationProvider.value.uri.path,
          '/workspaces/A/more/tools',
        );
        router.go('/workspaces/A/more/agents');
        final _ = await tester.pumpAndSettle();
        await tester.tap(
          find.text(language == 'en' ? 'Skills' : 'Habilidades'),
        );
        final _ = await tester.pumpAndSettle();
        expect(
          router.routeInformationProvider.value.uri.path,
          '/workspaces/A/more/skills',
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}

class const _RelatedTabsPage({required final GoRouterState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final section = state.pathParameters['section'];
    final workspaceId = state.pathParameters['workspaceId'] ?? '';
    final agents = section == 'agents'
        ? AgentDestination.agents
        : AgentDestination.skills;
    final connections = section == 'tools'
        ? ConnectionDestination.tools
        : WorkspaceNavigation.connectionView(state.uri.queryParameters['view']);

    return Scaffold(
      appBar: AuraAppBarWithDrawer(
        title: const Text('Related lists'),
        bottom: section == 'agents' || section == 'skills'
            ? AgentsSkillsTabs(workspaceId: workspaceId, value: agents)
            : ConnectionsTabs(workspaceId: workspaceId, value: connections),
      ),
    );
  }
}
