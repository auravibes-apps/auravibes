import 'package:auravibes_app/features/service_connections/providers/mcp_catalog_provider.dart';
import 'package:auravibes_app/features/service_connections/widgets/mcp_catalog_browser.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('searches catalog and obscures selected secret fields', (
    tester,
  ) async {
    final listing = McpCatalogListing(
      id: 'catalog-1',
      name: 'Search',
      description: 'Finds web pages',
      url: 'https://example.com/mcp',
      transport: 'streamableHttp',
      options: [
        McpCatalogConnectionOption(
          key: 'team',
          name: 'Team',
          authType: 'apiKey',
          fields: [
            McpCatalogCredentialField(
              key: 'X-API-Key',
              isSecret: true,
              isRequired: true,
            ),
            McpCatalogCredentialField(
              key: 'X-Region',
              isSecret: false,
              isRequired: false,
            ),
          ],
        ),
      ],
    );
    await tester.runAsync(
      () => tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en')],
          path: 'assets/i18n',
          fallbackLocale: const Locale('en'),
          startLocale: const Locale('en'),
          child: ProviderScope(
            overrides: [
              mcpCatalogProvider('ws').overrideWithValue(AsyncData([listing])),
              workspaceSessionForRouteProvider('ws').overrideWithValue(
                const AsyncData(
                  WorkspaceSession(LocalWorkspaceRef(localWorkspaceId: 'ws')),
                ),
              ),
            ],
            child: Builder(
              builder: (context) => MaterialApp(
                locale: context.locale,
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
                home: const Scaffold(
                  body: McpCatalogBrowser(workspaceId: 'ws'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(
      find.text('Search · Team'),
      findsOneWidget,
      reason: tester
          .widgetList<Text>(find.byType(Text))
          .map((widget) => widget.data)
          .toList()
          .toString(),
    );
    await tester.enterText(find.byType(TextField).first, 'missing');
    await tester.pump();
    expect(find.text('No entries match these filters.'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'pages');
    await tester.pump();
    await tester.tap(find.text('Search · Team'));
    await tester.pump();

    final secret = tester.widget<TextField>(
      find.byKey(const ValueKey('mcp_catalog_field_X-API-Key')),
    );
    final region = tester.widget<TextField>(
      find.byKey(const ValueKey('mcp_catalog_field_X-Region')),
    );
    expect(secret.obscureText, isTrue);
    expect(region.obscureText, isFalse);
  });

  testWidgets('allows cloud SSE OAuth catalog choice', (tester) async {
    final listing = McpCatalogListing(
      id: 'sse-1',
      name: 'Event server',
      description: 'Uses SSE',
      url: 'https://example.com/sse',
      transport: 'sse',
      options: [
        McpCatalogConnectionOption(
          key: 'oauth',
          name: 'OAuth',
          authType: 'oauth',
          fields: [],
        ),
      ],
    );
    await tester.runAsync(
      () => tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en')],
          path: 'assets/i18n',
          fallbackLocale: const Locale('en'),
          startLocale: const Locale('en'),
          child: ProviderScope(
            overrides: [
              mcpCatalogProvider('ws').overrideWithValue(AsyncData([listing])),
              workspaceSessionForRouteProvider('ws').overrideWithValue(
                const AsyncData(
                  WorkspaceSession(
                    CloudWorkspaceRef(
                      localWorkspaceId: 'ws',
                      serverUrl: 'https://cloud.example.com',
                      accountId: 'account',
                      cloudWorkspaceId: 1,
                    ),
                  ),
                ),
              ),
            ],
            child: Builder(
              builder: (context) => MaterialApp(
                locale: context.locale,
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
                home: const Scaffold(
                  body: McpCatalogBrowser(workspaceId: 'ws'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('Event server · OAuth'), findsOneWidget);
    expect(find.textContaining('This option is unavailable'), findsNothing);
    final tile = tester.widget<ListTile>(find.byType(ListTile));
    expect(tile.onTap, isNotNull);
  });
}
