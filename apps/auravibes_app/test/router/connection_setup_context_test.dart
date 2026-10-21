import 'package:auravibes_app/features/service_connections/screens/service_connection_create_screen.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets(
    'switching Connector route retains or discards connection draft',
    (tester) async {
      final connectorIds = connectorDefinitions
          .where(
            (connector) =>
                connector.compatibleModelProviderIds.isEmpty &&
                connector.tools.any((tool) => tool.urlTemplate != null),
          )
          .take(2)
          .map((connector) => connector.identifier)
          .toList();
      expect(connectorIds, hasLength(2));

      ServiceConnectionCreateRoute routeFor(GoRouterState state) =>
          ServiceConnectionCreateRoute(
            workspaceId: 'workspace',
            type: 'connector',
            connectorId: state.uri.queryParameters['connectorId'],
          );
      final firstConnectorId =
          connectorIds.firstOrNull ?? (throw StateError('No connectors found'));
      final firstLocation = '/draft-first?connectorId=$firstConnectorId';
      final secondLocation = '/draft-second?connectorId=${connectorIds.last}';
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/draft-first',
            builder: (context, state) => routeFor(state).build(context, state),
            onExit: (context, state) => routeFor(state).onExit(context, state),
          ),
          GoRoute(
            path: '/draft-second',
            builder: (context, state) => routeFor(state).build(context, state),
          ),
        ],
        initialLocation: firstLocation,
      );
      addTearDown(router.dispose);

      await tester.runAsync(
        () => tester.pumpWidget(
          TestableApp(
            child: Builder(
              builder: (context) => MaterialApp.router(
                routerConfig: router,
                builder: (_, child) => AuraThemeScope(
                  theme: .light,
                  child: child ?? const SizedBox.shrink(),
                ),
                locale: context.locale,
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
              ),
            ),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText).first, 'Retained name');
      await tester.enterText(
        find.byType(EditableText).last,
        'private-original',
      );

      router.go(secondLocation);
      final _ = await tester.pumpAndSettle();
      expect(find.text('Keep editing'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      final _ = await tester.pumpAndSettle();
      expect(router.state.uri.toString(), firstLocation);
      expect(find.text('Retained name'), findsOneWidget);
      expect(find.text('private-original'), findsOneWidget);

      router.go(secondLocation);
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text('Discard changes'));
      final _ = await tester.pumpAndSettle();
      expect(router.state.uri.toString(), secondLocation);
      expect(
        tester
            .widget<ServiceConnectionCreateScreen>(
              find.byType(ServiceConnectionCreateScreen),
            )
            .initialConnectorId,
        connectorIds.last,
      );
      expect(find.text('Retained name'), findsNothing);
      expect(find.text('private-original'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
