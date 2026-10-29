import 'dart:async';
import 'dart:io';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/model_connection_repository.dart';
import 'package:auravibes_app/data/repositories/service_connection_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/mcp_connection_test_summary.dart';
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/domain/entities/service_connection_auth_status.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/models/providers/api_model_repository_providers.dart';
import 'package:auravibes_app/features/models/services/model_sync_service.dart';
import 'package:auravibes_app/features/models/usecases/sync_api_models_usecase.dart';
import 'package:auravibes_app/features/service_connections/models/connection_filter.dart';
import 'package:auravibes_app/features/service_connections/models/connector_capability_filter.dart';
import 'package:auravibes_app/features/service_connections/models/mcp_connection_test_result.dart';
import 'package:auravibes_app/features/service_connections/models/service_connection_list_item.dart';
import 'package:auravibes_app/features/service_connections/notifiers/connections_list_view_notifier.dart';
import 'package:auravibes_app/features/service_connections/providers/connector_catalog_provider.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connections_provider.dart';
import 'package:auravibes_app/features/service_connections/screens/service_connections_screen.dart';
import 'package:auravibes_app/features/service_connections/usecases/delete_service_connection_usecase.dart';
import 'package:auravibes_app/features/service_connections/usecases/service_connections_action_usecase.dart';
import 'package:auravibes_app/features/service_connections/usecases/test_mcp_connection_usecase.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_access_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/router/workspace_navigation.dart';
import 'package:auravibes_app/services/encryption_service.dart';
import 'package:auravibes_app/services/secret_key_manager.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    as flutter_localizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _syncWorkspaceId = 'sync-workspace';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/Inter.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader('Roboto')..addFont(_sdkRoboto())).load();
  });

  testWidgets('shows warning actions for risky connections', (tester) async {
    _addWidgetTearDown(tester);
    final container = _syncTestContainer(
      .new(syncApiModelsUseCase: _MockSyncApiModelsUseCase()),
      connections: [
        _mcpConnection(
          name: 'Expiring MCP',
          displayStatus: .expiringSoon,
          canRefresh: true,
          canReconnect: true,
        ),
        _mcpConnection(
          name: 'Expired MCP',
          displayStatus: .expired,
          canReconnect: true,
        ),
        _mcpConnection(
          name: 'Healthy MCP',
          displayStatus: .connected,
          canRefresh: true,
          canReconnect: true,
        ),
      ],
    );
    addTearDown(container.dispose);

    await _pumpScreen(tester, container, _syncWorkspaceId);

    expect(find.text('This connection expires soon.'), findsOneWidget);
    expect(find.text('This connection has expired.'), findsOneWidget);
    expect(find.text('Refresh token'), findsOneWidget);
    expect(find.text('Reconnect'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey<String>('service_connection_warning_Expiring MCP'),
      ),
      findsOneWidget,
    );
    expect(find.byType(AuraCallout), findsNWidgets(2));
    expect(
      find.text('Authentication failed for this connection.'),
      findsNothing,
    );
  });

  testWidgets('opens redacted details only for failed MCP connections', (
    tester,
  ) async {
    _addWidgetTearDown(tester);
    final container = _syncTestContainer(
      .new(syncApiModelsUseCase: _MockSyncApiModelsUseCase()),
      connections: [
        _mcpConnection(
          name: 'Failed MCP',
          displayStatus: .failed,
          canReconnect: true,
          lastAuthError: 'Authorization: Bearer replace-me',
        ),
        _mcpConnection(
          name: 'Healthy MCP',
          displayStatus: .connected,
          canReconnect: true,
        ),
      ],
    );
    addTearDown(container.dispose);

    await _pumpScreen(tester, container, _syncWorkspaceId);
    await _openConnectionMenu(tester, 'Failed MCP');

    expect(find.text('View details'), findsOneWidget);
    expect(find.text('Reconnect'), findsWidgets);

    await tester.tap(find.text('View details'));
    final _ = await tester.pumpAndSettle();

    expect(find.textContaining('Bearer [REDACTED]'), findsOneWidget);
    expect(find.textContaining('replace-me'), findsNothing);
    await tester.tap(find.text('Close'));
    final _ = await tester.pumpAndSettle();
    final healthyMenu = find.byKey(
      const ValueKey<String>('service_connection_menu_Healthy MCP'),
    );
    final _ = await tester.ensureVisible(healthyMenu);
    final _ = await tester.pumpAndSettle();
    await _openConnectionMenu(tester, 'Healthy MCP');

    expect(find.text('View details'), findsNothing);
    expect(find.text('Reconnect'), findsWidgets);
  });

  testWidgets('opens details for MCP connections needing authentication', (
    tester,
  ) async {
    _addWidgetTearDown(tester);
    final container = _syncTestContainer(
      .new(syncApiModelsUseCase: _MockSyncApiModelsUseCase()),
      connections: [
        _mcpConnection(
          name: 'Needs auth MCP',
          displayStatus: .needsReauth,
          lastAuthError: 'Authentication expired',
        ),
      ],
    );
    addTearDown(container.dispose);

    await _pumpScreen(tester, container, _syncWorkspaceId);
    await _openConnectionMenu(tester, 'Needs auth MCP');

    expect(find.text('View details'), findsOneWidget);
    await tester.tap(find.text('View details'));
    final _ = await tester.pumpAndSettle();
    expect(find.textContaining('Authentication expired'), findsOneWidget);
  });

  Future<void> renderRedactedMcpDiagnostics(WidgetTester tester) async {
    _addWidgetTearDown(tester);
    await tester.binding.setSurfaceSize(const Size(960, 1200));
    PackageInfo.setMockInitialValues(
      appName: 'AuraVibes',
      packageName: 'me.auravibes.app',
      version: '0.0.4',
      buildNumber: '1',
      buildSignature: '',
    );
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }

        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final testUsecase = _MockTestMcpConnectionUsecase();
    when(() => testUsecase('Failed MCP-server')).thenAnswer((_) async {
      return (
        status: McpConnectionTestStatus.network,
        testedAt: DateTime.utc(2026, 9, 27, 12, 30),
        transport: const McpTransportTypeStreamableHttp(),
        toolCount: 0,
        durationMilliseconds: 0,
        errorDetails:
            'https://mcp.example.test/mcp?api_key=fixture-secret '
            'Authorization: Bearer fixture-secret',
      );
    });
    final container = _syncTestContainer(
      .new(syncApiModelsUseCase: _MockSyncApiModelsUseCase()),
      connections: [
        _mcpConnection(
          name: 'Failed MCP',
          displayStatus: .failed,
          canReconnect: true,
          transport: const McpTransportTypeStreamableHttp(),
        ),
      ],
      testUsecase: testUsecase,
    );
    addTearDown(container.dispose);

    await _pumpScreen(tester, container, _syncWorkspaceId);
    await tester.tap(find.text('Test connection'));
    final _ = await tester.pumpAndSettle();

    expect(find.text('Could not reach this service'), findsOneWidget);
    expect(find.text('Retry test'), findsOneWidget);
    expect(find.textContaining('Tested '), findsOneWidget);
    await tester.tap(find.text('View details'));
    final _ = await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/service_connection_diagnostics.png'),
    );
    await tester.tap(find.text('Copy'));
    final _ = await tester.pumpAndSettle();

    expect(copied.single, contains('Transport: streamableHttp'));
    expect(copied.single, contains('Status category: network'));
    expect(copied.single, contains('Attempt time: 2026-09-27T12:30:00.000Z'));
    expect(copied.single, contains('App version: 0.0.4'));
    expect(copied.single, isNot(contains('mcp.example.test')));
    expect(copied.single, isNot(contains('secret')));
    verify(() => testUsecase('Failed MCP-server')).called(1);
  }

  testWidgets(
    'renders redacted MCP diagnostic output from fixtures',
    renderRedactedMcpDiagnostics,
    tags: ['golden'],
  );

  testWidgets('localizes authentication recovery and historic diagnostics', (
    tester,
  ) async {
    _addWidgetTearDown(tester);
    final testUsecase = _MockTestMcpConnectionUsecase();
    when(() => testUsecase('Needs auth MCP-server')).thenAnswer((_) async {
      return (
        status: McpConnectionTestStatus.authentication,
        testedAt: DateTime.utc(2026, 9, 27, 12, 30),
        transport: const McpTransportTypeSSE(),
        toolCount: 0,
        durationMilliseconds: 0,
        errorDetails: 'Authentication expired',
      );
    });
    final container = _syncTestContainer(
      .new(syncApiModelsUseCase: _MockSyncApiModelsUseCase()),
      connections: [
        _mcpConnection(
          name: 'Needs auth MCP',
          displayStatus: .needsReauth,
          canReconnect: true,
          lastAuthError: 'Authentication expired',
          transport: const McpTransportTypeSSE(),
        ),
      ],
      testUsecase: testUsecase,
    );
    addTearDown(container.dispose);

    await _pumpScreen(
      tester,
      container,
      _syncWorkspaceId,
      locale: const Locale('es'),
    );
    await tester.tap(find.textContaining('Probar conexi'));
    final _ = await tester.pumpAndSettle();

    expect(find.textContaining('No se pudo iniciar'), findsOneWidget);
    expect(
      find.text('Vuelve a conectar este servicio para recuperar el acceso.'),
      findsOneWidget,
    );
    expect(find.text('Reconectar'), findsWidgets);
    await _openConnectionMenu(tester, 'Needs auth MCP');
    await tester.tap(find.text('Ver detalles').last);
    final _ = await tester.pumpAndSettle();
    expect(find.text('Copiar'), findsOneWidget);
  });

  testWidgets('shows protocol guidance and keeps unknown failure details', (
    tester,
  ) async {
    _addWidgetTearDown(tester);
    final testUsecase = _MockTestMcpConnectionUsecase();
    var attempts = 0;
    when(() => testUsecase('Protocol MCP-server')).thenAnswer((_) async {
      attempts++;

      return (
        status: attempts == 1
            ? McpConnectionTestStatus.protocol
            : McpConnectionTestStatus.unknown,
        testedAt: DateTime.utc(2026, 9, 27),
        transport: const McpTransportTypeStreamableHttp(),
        toolCount: 0,
        durationMilliseconds: 0,
        errorDetails: 'Unexpected failure',
      );
    });
    final container = _syncTestContainer(
      .new(syncApiModelsUseCase: _MockSyncApiModelsUseCase()),
      connections: [
        _mcpConnection(name: 'Protocol MCP', displayStatus: .connected),
      ],
      testUsecase: testUsecase,
    );
    addTearDown(container.dispose);

    await _pumpScreen(tester, container, _syncWorkspaceId);
    final testButton = find.byKey(
      const ValueKey<String>('service_connection_test_Protocol MCP'),
    );
    await tester.tap(testButton);
    final _ = await tester.pumpAndSettle();
    expect(find.text('Service settings need attention'), findsOneWidget);
    expect(find.text('Open settings'), findsOneWidget);
    expect(find.textContaining('connection settings'), findsOneWidget);

    await tester.tap(testButton);
    final _ = await tester.pumpAndSettle();
    expect(find.text('Connection check failed'), findsOneWidget);
    expect(find.text('Open settings'), findsNothing);
    expect(find.text('Retry test'), findsNothing);
    expect(find.text('View details'), findsOneWidget);
  });

  testWidgets('shows a localized successful MCP connection check', (
    tester,
  ) async {
    _addWidgetTearDown(tester);
    final testUsecase = _MockTestMcpConnectionUsecase();
    when(() => testUsecase('Healthy MCP-server')).thenAnswer((_) async {
      return (
        status: McpConnectionTestStatus.success,
        testedAt: DateTime.utc(2026, 9, 27),
        transport: const McpTransportTypeSSE(),
        toolCount: 0,
        durationMilliseconds: 0,
        errorDetails: null,
      );
    });
    final container = _syncTestContainer(
      .new(syncApiModelsUseCase: _MockSyncApiModelsUseCase()),
      connections: [
        _mcpConnection(name: 'Healthy MCP', displayStatus: .connected),
      ],
      testUsecase: testUsecase,
    );
    addTearDown(container.dispose);

    await _pumpScreen(tester, container, _syncWorkspaceId);
    await tester.tap(
      find.byKey(const ValueKey<String>('service_connection_test_Healthy MCP')),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.text('Connection check passed'), findsOneWidget);
    expect(find.textContaining('Tested '), findsOneWidget);
    expect(find.text('Reconnect'), findsNothing);
    expect(find.text('Retry test'), findsNothing);
    expect(find.text('View details'), findsNothing);
  });

  testWidgets('restores normalized MCP test summary from connection state', (
    tester,
  ) async {
    _addWidgetTearDown(tester);
    final container = _syncTestContainer(
      .new(syncApiModelsUseCase: _MockSyncApiModelsUseCase()),
      connections: [
        _mcpConnection(
          name: 'Saved MCP',
          displayStatus: .connected,
          lastTestSummary: .new(
            status: 'success',
            testedAt: .utc(2026, 9, 27, 12, 30),
            transport: const McpTransportTypeSSE(),
            toolCount: 2,
            durationMilliseconds: 31,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await _pumpScreen(tester, container, _syncWorkspaceId);

    expect(find.text('Connection check passed'), findsOneWidget);
    expect(find.text('Found 2 tools in 31 ms'), findsOneWidget);
    expect(find.text('View details'), findsNothing);
  });

  testWidgets('opens details for restored MCP failures without error payload', (
    tester,
  ) async {
    _addWidgetTearDown(tester);
    final container = _syncTestContainer(
      .new(syncApiModelsUseCase: _MockSyncApiModelsUseCase()),
      connections: [
        _mcpConnection(
          name: 'Unknown MCP',
          displayStatus: .connected,
          lastTestSummary: .new(
            status: 'unknown',
            testedAt: .utc(2026, 9, 27, 12, 30),
            transport: const McpTransportTypeStreamableHttp(),
            toolCount: 0,
            durationMilliseconds: 12,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await _pumpScreen(tester, container, _syncWorkspaceId);

    expect(find.text('Connection check failed'), findsOneWidget);
    expect(find.text('View details'), findsOneWidget);
    expect(find.text('Retry test'), findsNothing);
    expect(find.text('Open settings'), findsNothing);

    await tester.tap(find.text('View details'));
    final _ = await tester.pumpAndSettle();

    expect(find.textContaining('Unknown error'), findsOneWidget);
  });

  for (final view in [
    ConnectionDestination.overview,
    ConnectionDestination.providers,
    ConnectionDestination.services,
    ConnectionDestination.credentials,
  ]) {
    testWidgets('shows only actual kinds in ${view.name}', (tester) async {
      _addWidgetTearDown(tester);
      final container = _syncTestContainer(
        .new(syncApiModelsUseCase: _MockSyncApiModelsUseCase()),
        connections: [
          _mcpConnection(name: 'Actual service', displayStatus: .connected),
          _kindConnection(.modelProvider, 'Actual provider'),
          _kindConnection(.connector, 'Saved Connector'),
        ],
      );
      addTearDown(container.dispose);
      await _pumpScreen(tester, container, _syncWorkspaceId, view: view);
      expect(
        find.text('Actual service'),
        view == .overview || view == .services ? findsOneWidget : findsNothing,
      );
      expect(
        find.text('Actual provider'),
        view == .overview || view == .providers ? findsOneWidget : findsNothing,
      );
      expect(
        find.text('Saved Connector'),
        view == .overview || view == .credentials
            ? findsOneWidget
            : findsNothing,
      );
    });
  }

  testWidgets('shows one catalog entry action in services view', (
    tester,
  ) async {
    _addWidgetTearDown(tester);
    final container = _syncTestContainer(
      .new(syncApiModelsUseCase: _MockSyncApiModelsUseCase()),
      connections: [_mcpConnection(name: 'Notion', displayStatus: .connected)],
    );
    addTearDown(container.dispose);

    await _pumpScreen(tester, container, _syncWorkspaceId, view: .services);

    expect(find.byTooltip('Browse service catalog'), findsNothing);
    expect(find.byTooltip('Add connection'), findsOneWidget);
  });

  testWidgets('shows catalog connectors and filters by offered tools', (
    tester,
  ) async {
    _addWidgetTearDown(tester);
    final container = _syncTestContainer(
      .new(syncApiModelsUseCase: _MockSyncApiModelsUseCase()),
      connections: [
        _kindConnection(
          .modelProvider,
          'OpenAI account',
          serviceName: 'openai',
          displayStatus: .connected,
        ),
      ],
      modelProviders: [
        const ApiModelProviderEntity(
          id: 'openai',
          name: 'OpenAI',
          type: .openai,
        ),
        const ApiModelProviderEntity(
          id: 'custom-models',
          name: 'Custom Models',
          type: .openai,
        ),
      ],
    );
    addTearDown(container.dispose);

    await _pumpScreen(tester, container, _syncWorkspaceId, view: .connectors);
    final catalog = await container.read(
      connectorCatalogProvider(_syncWorkspaceId).future,
    );
    expect(
      catalog.map((connector) => connector.id),
      containsAll(['custom-models', 'openai']),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.text('Custom Models'), findsOneWidget);
    expect(find.text('Connect'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('OpenAI'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('OpenAI'), findsOneWidget);
    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('Manage connections'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(AuraChoicePicker<ConnectorCapabilityFilter>),
        matching: find.text('Tools'),
      ),
    );
    final _ = await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView).first, const Offset(0, 2000));
    final _ = await tester.pumpAndSettle();
    expect(find.text('Custom Models'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('OpenAI'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('OpenAI'), findsOneWidget);
  });

  testWidgets('restores connection search after replacing the list', (
    tester,
  ) async {
    _addWidgetTearDown(tester);
    final container = _syncTestContainer(
      .new(syncApiModelsUseCase: _MockSyncApiModelsUseCase()),
      connections: [
        _mcpConnection(name: 'Notion', displayStatus: .connected),
        _mcpConnection(name: 'GitHub', displayStatus: .connected),
      ],
    );
    addTearDown(container.dispose);
    await _pumpScreen(tester, container, _syncWorkspaceId);
    await tester.enterText(find.byType(EditableText), 'notion');
    final _ = await tester.pumpAndSettle();
    await _pumpScreen(tester, container, _syncWorkspaceId, view: .services);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      '',
    );
    await _pumpScreen(tester, container, _syncWorkspaceId);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'notion',
    );
    expect(find.text('GitHub'), findsNothing);
  });

  for (final locale in [const Locale('en'), const Locale('es')]) {
    for (final width in [360.0, 960.0]) {
      testWidgets(
        'kind and health compose at $width in ${locale.languageCode}',
        (tester) async {
          _addWidgetTearDown(tester);
          final container = _syncTestContainer(
            .new(syncApiModelsUseCase: _MockSyncApiModelsUseCase()),
            connections: [
              _mcpConnection(
                name: 'Repair this service',
                displayStatus: .needsReauth,
              ),
              _mcpConnection(
                name: 'Healthy service',
                displayStatus: .connected,
              ),
              _kindConnection(.modelProvider, 'Healthy provider'),
            ],
          );
          addTearDown(container.dispose);
          await _pumpScreen(
            tester,
            container,
            _syncWorkspaceId,
            locale: locale,
          );
          await tester.binding.setSurfaceSize(.new(width, 1200));
          final _ = await tester.pumpAndSettle();
          final filterSheet = find.byKey(const ValueKey('app_filter_sheet'));
          if (filterSheet.evaluate().isNotEmpty) {
            expect(
              tester.widgetList<AuraDropdownSelector<ConnectionFilter>>(
                find.byType(AuraDropdownSelector<ConnectionFilter>),
              ),
              isEmpty,
            );
            await tester.tap(filterSheet.first);
            final _ = await tester.pumpAndSettle();
          }
          tester
              .widget<AuraDropdownSelector<ConnectionFilter>>(
                find.byType(AuraDropdownSelector<ConnectionFilter>).first,
              )
              .onChanged
              ?.call(.needsAuth);
          final _ = await tester.pumpAndSettle();
          tester
              .widget<AuraDropdownSelector<ConnectionFilter>>(
                find.byType(AuraDropdownSelector<ConnectionFilter>).last,
              )
              .onChanged
              ?.call(.mcpServers);
          final _ = await tester.pumpAndSettle();
          expect(find.text('Repair this service'), findsOneWidget);
          expect(find.text('Healthy service'), findsNothing);
          expect(find.text('Healthy provider'), findsNothing);
          expect(
            container
                .read(connectionsListViewProvider(_syncWorkspaceId, .overview))
                .filter,
            ConnectionFilter.needsAuth,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final locale in [const Locale('en'), const Locale('es')]) {
    testWidgets('filters restore and clear ${locale.languageCode}', (
      tester,
    ) async {
      _addWidgetTearDown(tester);
      final container = _syncTestContainer(
        .new(syncApiModelsUseCase: _MockSyncApiModelsUseCase()),
        connections: [
          _mcpConnection(name: 'Notion', displayStatus: .needsReauth),
        ],
      );
      addTearDown(container.dispose);
      await _pumpScreen(tester, container, _syncWorkspaceId, locale: locale);
      await tester.binding.setSurfaceSize(const Size(466, 700));
      final _ = await tester.pumpAndSettle();
      final provider = connectionsListViewProvider(_syncWorkspaceId, .overview);
      final notifier = container.read(provider.notifier);
      await tester.enterText(
        find.byKey(const ValueKey<String>('service_connections_search')),
        'Notion',
      );
      notifier
        ..setFilter(.needsAuth)
        ..setKind(.modelProviders)
        ..setOauthOnly(value: true);
      final _ = await tester.pumpAndSettle();

      expect(
        find.text(locale.languageCode == 'en' ? 'Filters (3)' : 'Filtros (3)'),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(AuraCard),
          matching: find.text('Notion'),
        ),
        findsNothing,
      );
      await tester.tap(find.byKey(const ValueKey('app_filter_sheet')).first);
      final _ = await tester.pumpAndSettle();
      final filters = tester.widgetList<AuraDropdownSelector<ConnectionFilter>>(
        find.byType(AuraDropdownSelector<ConnectionFilter>),
      );
      expect(filters.map((filter) => filter.value), [
        ConnectionFilter.needsAuth,
        ConnectionFilter.modelProviders,
      ]);
      expect(
        tester
            .widget<AuraCheckboxListTile>(find.byType(AuraCheckboxListTile))
            .value,
        isTrue,
      );
      expect(
        find.text(
          locale.languageCode == 'en' ? 'Clear filters' : 'Borrar filtros',
        ),
        findsOneWidget,
      );

      tester
          .widget<AuraDropdownSelector<ConnectionFilter>>(
            find.byType(AuraDropdownSelector<ConnectionFilter>).last,
          )
          .onChanged
          ?.call(.mcpServers);
      tester
          .widget<AuraCheckboxListTile>(find.byType(AuraCheckboxListTile))
          .onChanged
          ?.call(false);
      final _ = await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<AuraDropdownSelector<ConnectionFilter>>(
              find.byType(AuraDropdownSelector<ConnectionFilter>),
            )
            .map((filter) => filter.value),
        [ConnectionFilter.needsAuth, ConnectionFilter.mcpServers],
      );
      expect(
        tester
            .widget<AuraCheckboxListTile>(find.byType(AuraCheckboxListTile))
            .value,
        isFalse,
      );
      expect(
        find.descendant(
          of: find.byType(AuraCard),
          matching: find.text('Notion'),
        ),
        findsOneWidget,
      );
      expect(
        find.text(locale.languageCode == 'en' ? 'Filters (2)' : 'Filtros (2)'),
        findsOneWidget,
      );

      await tester.tap(
        find.text(
          locale.languageCode == 'en' ? 'Clear filters' : 'Borrar filtros',
        ),
      );
      final _ = await tester.pumpAndSettle();
      expect(
        find.text(locale.languageCode == 'en' ? 'Filters (0)' : 'Filtros (0)'),
        findsOneWidget,
      );
      await tester.tapAt(const Offset(20, 20));
      final _ = await tester.pumpAndSettle();

      expect(container.read(provider), (
        searchQuery: 'Notion',
        filter: ConnectionFilter.all,
        kind: ConnectionFilter.all,
        oauthOnly: false,
      ));
      expect(
        find.descendant(
          of: find.byType(AuraCard),
          matching: find.text('Notion'),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<EditableText>(
              find.descendant(
                of: find.byKey(
                  const ValueKey<String>('service_connections_search'),
                ),
                matching: find.byType(EditableText),
              ),
            )
            .controller
            .text,
        'Notion',
      );

      await tester.tap(find.byKey(const ValueKey('app_filter_sheet')).first);
      final _ = await tester.pumpAndSettle();
      final resetFilters = tester
          .widgetList<AuraDropdownSelector<ConnectionFilter>>(
            find.byType(AuraDropdownSelector<ConnectionFilter>),
          );
      expect(resetFilters.map((filter) => filter.value), [
        ConnectionFilter.all,
        ConnectionFilter.all,
      ]);
      expect(
        tester
            .widget<AuraCheckboxListTile>(find.byType(AuraCheckboxListTile))
            .value,
        isFalse,
      );
    });
  }

  testWidgets('list load failure retries without exposing the error', (
    tester,
  ) async {
    var fail = true;
    _addWidgetTearDown(tester);
    final container = _syncTestContainer(
      .new(syncApiModelsUseCase: _MockSyncApiModelsUseCase()),
      loadConnections: () => fail
          ? Stream.error(StateError('secret diagnostic'))
          : Stream.value([
              _mcpConnection(
                name: 'Recovered service',
                displayStatus: .unknown,
              ),
            ]),
    );
    addTearDown(container.dispose);
    await _pumpScreen(tester, container, _syncWorkspaceId);
    expect(find.textContaining('secret diagnostic'), findsNothing);
    expect(find.text('Retry'), findsOneWidget);
    fail = false;
    await tester.tap(find.text('Retry'));
    final _ = await tester.pumpAndSettle();
    expect(find.text('Recovered service'), findsOneWidget);
  });

  testWidgets('searches connection metadata and applies status filters', (
    tester,
  ) async {
    _addWidgetTearDown(tester);
    final container = _syncTestContainer(
      .new(syncApiModelsUseCase: _MockSyncApiModelsUseCase()),
      connections: [
        _mcpConnection(
          name: 'Notion',
          displayStatus: .needsReauth,
          serviceName: 'notion.example.com',
          metadataValues: const [
            ServiceConnectionMetadataValue(
              key: .issuer,
              value: 'https://issuer.example.com',
            ),
            ServiceConnectionMetadataValue(
              key: .scopes,
              value: 'read:pages write:pages',
            ),
          ],
        ),
        _mcpConnection(
          name: 'GitHub',
          displayStatus: .connected,
          serviceName: 'github.example.com',
          authenticationType: 'bearerToken',
        ),
      ],
    );
    addTearDown(container.dispose);

    await _pumpScreen(tester, container, _syncWorkspaceId);

    final searchField = find.descendant(
      of: find.byKey(const ValueKey<String>('service_connections_search')),
      matching: find.byType(EditableText),
    );
    expect(find.text('Notion'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('GitHub'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('GitHub'), findsOneWidget);

    final _ = await tester.enterText(searchField, 'notion');
    final _ = await tester.pumpAndSettle();
    expect(find.text('Notion'), findsOneWidget);
    expect(find.text('GitHub'), findsNothing);

    final _ = await tester.enterText(searchField, 'notion.example.com');
    final _ = await tester.pumpAndSettle();
    expect(find.text('Notion'), findsOneWidget);
    expect(find.text('GitHub'), findsNothing);

    final _ = await tester.enterText(searchField, 'issuer.example.com');
    final _ = await tester.pumpAndSettle();
    expect(find.text('Notion'), findsOneWidget);

    final _ = await tester.enterText(searchField, 'write:pages');
    final _ = await tester.pumpAndSettle();
    expect(find.text('Notion'), findsOneWidget);

    final _ = await tester.enterText(searchField, '');
    await tester.tap(find.byType(AuraDropdownSelector<ConnectionFilter>).first);
    final _ = await tester.pumpAndSettle();
    final needsAuthFilter = find.text('Needs auth');
    final _ = await tester.ensureVisible(needsAuthFilter);
    final _ = await tester.tap(needsAuthFilter);
    final _ = await tester.pumpAndSettle();
    expect(find.text('Notion'), findsOneWidget);
    expect(find.text('GitHub'), findsNothing);

    await tester.tap(find.byType(AuraDropdownSelector<ConnectionFilter>).first);
    final _ = await tester.pumpAndSettle();
    final allFilter = find.text('All').hitTestable().last;
    final _ = await tester.ensureVisible(allFilter);
    final _ = await tester.tap(allFilter);
    final _ = await tester.enterText(searchField, 'missing-connection');
    final _ = await tester.pumpAndSettle();
    expect(
      find.text('No connections match your search or filters.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.search_off), findsOneWidget);
    expect(find.text('Clear search'), findsOneWidget);
    expect(find.text('Add connection'), findsNothing);

    final _ = await tester.tap(find.text('Clear search'));
    final _ = await tester.pumpAndSettle();
    expect(tester.widget<EditableText>(searchField).controller.text, '');
    expect(find.text('Notion'), findsOneWidget);
  });

  testWidgets('syncs the local model catalog with visible progress', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    _addWidgetTearDown(tester);
    final completer = Completer<void>();
    final usecase = _MockSyncApiModelsUseCase();
    when(usecase.call).thenAnswer((_) => completer.future);
    final container = _syncTestContainer(.new(syncApiModelsUseCase: usecase));
    addTearDown(container.dispose);

    await _pumpScreen(tester, container, _syncWorkspaceId);
    final _ = await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('service_connections_sync')),
      findsOneWidget,
    );
    await tester.tap(
      find.bySemanticsIdentifier('service_connections_sync').hitTestable(),
    );
    await tester.pump();

    expect(find.byType(AuraSpinner), findsOneWidget);
    final syncButton = tester
        .widgetList<AuraIconButton>(find.byType(AuraIconButton))
        .singleWhere((button) => button.child is AuraSpinner);
    expect(syncButton.disabled, isTrue);
    verify(usecase.call).called(1);

    completer.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Model catalog synced'), findsOneWidget);
    expect(find.text('Last refreshed'), findsOneWidget);
    await _unmountScreen(tester);
    semantics.dispose();
  });

  testWidgets('shows sync failure and allows retry', (tester) async {
    _addWidgetTearDown(tester);
    final usecase = _MockSyncApiModelsUseCase();
    when(usecase.call).thenThrow(Exception('Network error'));
    final container = _syncTestContainer(.new(syncApiModelsUseCase: usecase));
    addTearDown(container.dispose);

    await _pumpScreen(tester, container, _syncWorkspaceId);
    final _ = await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.sync));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Could not sync model catalog'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.sync));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Could not sync model catalog'), findsOneWidget);
    verify(usecase.call).called(2);
    await _unmountScreen(tester);
  });

  testWidgets('hides local catalog sync for cloud workspaces', (tester) async {
    _addWidgetTearDown(tester);
    const session = WorkspaceSession(
      CloudWorkspaceRef(
        localWorkspaceId: _syncWorkspaceId,
        serverUrl: 'https://example.com',
        accountId: 'account',
        cloudWorkspaceId: 1,
      ),
    );
    final container = _syncTestContainer(
      .new(syncApiModelsUseCase: _MockSyncApiModelsUseCase()),
      session: session,
    );
    addTearDown(container.dispose);

    await _pumpScreen(tester, container, _syncWorkspaceId);
    final _ = await tester.pumpAndSettle();

    expect(find.byIcon(Icons.sync), findsNothing);
    await _unmountScreen(tester);
  });

  testWidgets('exposes distinct add selectors for empty and app bar actions', (
    tester,
  ) async {
    _addWidgetTearDown(tester);
    final container = _syncTestContainer(
      .new(syncApiModelsUseCase: _MockSyncApiModelsUseCase()),
    );
    addTearDown(container.dispose);

    await _pumpScreen(tester, container, _syncWorkspaceId);

    final appBarAddButton = find.byKey(
      const ValueKey<String>('service_connections_add'),
    );
    expect(appBarAddButton, findsOneWidget);
    expect(
      find.descendant(
        of: appBarAddButton,
        matching: find.text('Add connection'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('service_connections_empty_add')),
      findsOneWidget,
    );
  });

  testWidgets('deletes Connector Connections from row menu', (tester) async {
    _addWidgetTearDown(tester);
    final database = AppDatabase(
      connection: DatabaseConnection(NativeDatabase.memory()),
    );
    addTearDown(database.close);
    final encryptionService = EncryptionService(_FakeSecretKeyManager());
    final workspace = await WorkspaceRepository(database).createWorkspace(
      const WorkspaceToCreate(name: 'Test Workspace', type: .local),
    );
    final repository = ServiceConnectionRepository(database, encryptionService);
    final connection = await repository.createConnectorConnection((
      workspaceId: workspace.id,
      connectorId: 'notion',
      name: 'Notion work',
      apiKey: 'secret-value',
    ));
    final session = WorkspaceSession(
      LocalWorkspaceRef(localWorkspaceId: workspace.id),
    );
    final delete = DeleteServiceConnectionUsecase(
      modelConnectionRepository: ModelConnectionRepository(
        database: database,
        encryptionService: encryptionService,
      ),
      deleteConnectorConnection: (id) =>
          repository.deleteConnectorConnection(id, workspaceId: workspace.id),
    );
    final actions = ServiceConnectionsActionUsecase(
      (_) => Future<void>.value(),
      (_) async => throw UnimplementedError(),
      delete,
    );
    final container = ProviderContainer(
      overrides: [
        workspaceSessionProvider(session).overrideWithValue(session),
        appDatabaseProvider.overrideWithValue(database),
        encryptionServiceProvider.overrideWithValue(encryptionService),
        cloudWorkspaceStateGatewayProvider.overrideWith((_, _) async => null),
        cloudWorkspaceStateGatewayForWorkspaceProvider.overrideWith(
          (_, _) async => null,
        ),
        serviceConnectionsActionUsecaseProvider(workspace.id)
            .overrideWith((_) async => actions),
      ],
    );
    addTearDown(container.dispose);
    await _pumpScreen(tester, container, workspace.id);
    final _ = await tester.pumpAndSettle();

    expect(find.text('Notion work'), findsOneWidget);
    expect(find.text('secret-value'), findsNothing);
    expect(find.text('Connection kind'), findsOneWidget);
    expect(find.text('Connection health'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.more_vert).first);
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    final _ = await tester.pumpAndSettle();

    expect(find.text('Delete Connector'), findsOneWidget);
    expect(
      find.text(
        'Delete connection "Notion work"? This action cannot be undone.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Delete').last);
    await _pumpUntil(
      tester,
      () async => await repository.getById(connection.id) == null,
    );
    expect(find.text('Notion work'), findsNothing);
    final credential = await database
        .into(database.serviceConnections)
        .insertReturning(
          ServiceConnectionsCompanion.insert(
            name: 'Notion OAuth',
            serviceId: 'notion-mcp',
            kind: .mcpServer,
            authenticationType: .oauth2,
            encryptedAuthValue: const Value('{"access_token":"secret-token"}'),
            metadataJson: .new(
              ServiceConnectionAuthCodec.encodeMetadata(
                const ServiceConnectionMetadata(
                  clientId: 'notion-client-id',
                  issuer: 'https://api.notion.com',
                  scopes: ['read', 'write'],
                ),
              ),
            ),
            authStatus: const Value(ServiceConnectionAuthStatus.needsReauth),
            workspaceId: workspace.id,
          ),
        );
    final _ = await database.mcpServersDao.insertMcpServer(
      .insert(
        workspaceId: workspace.id,
        name: 'Notion',
        url: 'https://mcp.notion.com/mcp',
        transport: const McpTransportTypeStreamableHttp(),
        serviceConnectionId: Value(credential.id),
      ),
    );

    final _ = await tester.pumpAndSettle();

    expect(find.text('Notion'), findsOneWidget);
    expect(find.text('Needs reconnect'), findsOneWidget);
    expect(find.textContaining('mcp.notion.com'), findsOneWidget);
    expect(find.textContaining('oauth2'), findsNothing);
    expect(find.textContaining('notion-client-id'), findsOneWidget);
    expect(find.textContaining('read, write'), findsOneWidget);
    expect(find.textContaining('secret-token'), findsNothing);

    await tester.tap(find.byIcon(Icons.more_vert).first);
    final _ = await tester.pumpAndSettle();

    expect(find.text('Reconnect'), findsNWidgets(2));
    expect(find.text('Refresh token'), findsOneWidget);
    expect(find.text('Delete'), findsNothing);

    await _unmountScreen(tester);
  });

  for (final width in [420.0, 960.0]) {
    final layout = width == 420.0 ? 'compact' : 'wide';
    Future<void> renderConnectionStates(WidgetTester tester) async {
      _addWidgetTearDown(tester);
      final container = _syncTestContainer(
        .new(syncApiModelsUseCase: _MockSyncApiModelsUseCase()),
        connections: [
          _mcpConnection(
            name: 'Notion',
            displayStatus: .needsReauth,
            serviceName: 'mcp.notion.test',
            canReconnect: true,
          ),
          _mcpConnection(
            name: 'Linear',
            displayStatus: .connected,
            serviceName: 'mcp.linear.test',
            transport: const McpTransportTypeStreamableHttp(),
          ),
          _mcpConnection(
            name: 'Sentry',
            displayStatus: .failed,
            serviceName: 'mcp.sentry.test',
            canReconnect: true,
            lastAuthError: 'Fixture connection failed',
          ),
        ],
      );
      addTearDown(container.dispose);

      await _pumpScreen(
        tester,
        container,
        _syncWorkspaceId,
        view: .services,
        surfaceSize: .new(width, 1000),
      );

      if (width < 600) {
        await tester.scrollUntilVisible(
          find.text('Sentry'),
          180,
          scrollable: find.byType(Scrollable).last,
        );
      }

      await expectLater(
        find.byType(ServiceConnectionsScreen),
        matchesGoldenFile('goldens/service_connections_$layout.png'),
      );
      expect(find.text('Notion'), findsOneWidget);
      expect(find.text('Linear'), findsOneWidget);
      expect(find.text('Sentry'), findsOneWidget);
    }

    testWidgets(
      'renders $layout connection and authentication states',
      renderConnectionStates,
      tags: ['golden'],
    );
  }
}

ProviderContainer _syncTestContainer(
  ModelSyncService service, {
  WorkspaceSession? session,
  bool canManage = true,
  List<ServiceConnectionListItem> connections = const [],
  List<ApiModelProviderEntity>? modelProviders,
  TestMcpConnectionUsecase? testUsecase,
  Stream<List<ServiceConnectionListItem>> Function()? loadConnections,
}) {
  final workspaceSession =
      session ??
      const WorkspaceSession(
        LocalWorkspaceRef(localWorkspaceId: _syncWorkspaceId),
      );

  return ProviderContainer(
    overrides: [
      canManageWorkspaceProvider(_syncWorkspaceId).overrideWithValue(canManage),
      workspaceSessionForRouteProvider(_syncWorkspaceId)
          .overrideWithValue(AsyncData(workspaceSession)),
      serviceConnectionsProvider(_syncWorkspaceId).overrideWith(
        (_) => loadConnections?.call() ?? Stream.value(connections),
      ),
      if (modelProviders != null)
        apiModelProvidersProvider(workspaceId: _syncWorkspaceId)
            .overrideWith((_) async => modelProviders),
      modelSyncServiceProvider.overrideWithValue(service),
      if (testUsecase != null)
        testMcpConnectionUsecaseProvider(_syncWorkspaceId)
            .overrideWith((_) async => testUsecase),
    ],
  );
}

ServiceConnectionListItem _mcpConnection({
  required String name,
  required ServiceConnectionDisplayStatus displayStatus,
  String serviceName = 'mcp.example.com',
  String authenticationType = 'oauth2',
  List<ServiceConnectionMetadataValue> metadataValues = const [],
  bool canRefresh = false,
  bool canReconnect = false,
  String? lastAuthError,
  McpTransportType? transport,
  McpConnectionTestSummary? lastTestSummary,
}) => ServiceConnectionListItem(
  id: name,
  workspaceId: _syncWorkspaceId,
  name: name,
  serviceName: serviceName,
  kind: .mcpServer,
  keySuffix: null,
  mcpServerId: '$name-server',
  authenticationType: authenticationType,
  displayStatus: displayStatus,
  expiresAt: null,
  lastRefreshedAt: null,
  lastAuthError: lastAuthError,
  metadataValues: metadataValues,
  canRefresh: canRefresh,
  canReconnect: canReconnect,
  transport: transport,
  lastTestSummary: lastTestSummary,
);

Future<void> _pumpScreen(
  WidgetTester tester,
  ProviderContainer container,
  String workspaceId, {
  Locale locale = const Locale('en'),
  ConnectionDestination view = .overview,
  Size surfaceSize = const Size(1000, 1200),
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final _ = await tester.runAsync(() async {
    await tester.pumpWidget(
      EasyLocalization(
        key: UniqueKey(),
        child: Builder(
          builder: (context) {
            return UncontrolledProviderScope(
              container: container,
              child: Portal(
                child: MaterialApp(
                  home: ServiceConnectionsScreen(
                    workspaceId: workspaceId,
                    view: view,
                  ),
                  builder: (context, child) =>
                      AuraSnackBarHost(child: child ?? const SizedBox.shrink()),
                  theme: .new(fontFamily: 'Inter'),
                  locale: context.locale,
                  localizationsDelegates: [
                    ...GlobalMaterialLocalizations.delegates,
                    flutter_localizations.GlobalMaterialLocalizations.delegate,
                    ...context.localizationDelegates,
                  ],
                  supportedLocales: context.supportedLocales,
                ),
              ),
            );
          },
        ),
        supportedLocales: const [Locale('en'), Locale('es')],
        path: 'assets/i18n',
        fallbackLocale: const Locale('en'),
        startLocale: locale,
        useOnlyLangCode: true,
        useFallbackTranslations: true,
      ),
    );
    await Future<void>.delayed(.zero);
  });
  final _ = await tester.pumpAndSettle();
}

Future<ByteData> _sdkRoboto() async {
  for (
    var directory = File(Platform.resolvedExecutable).parent;
    directory.path != directory.parent.path;
    directory = directory.parent
  ) {
    final font = File('${directory.path}/material_fonts/Roboto-Regular.ttf');
    if (font.existsSync()) {
      return (await font.readAsBytes()).buffer.asByteData();
    }
  }
  throw StateError('Flutter SDK Roboto font unavailable for capture');
}

Future<void> _openConnectionMenu(WidgetTester tester, String name) async {
  await tester.tap(
    find.descendant(
      of: find.byKey(ValueKey<String>('service_connection_menu_$name')),
      matching: find.byIcon(Icons.more_vert),
    ),
  );
  final _ = await tester.pumpAndSettle();
}

void _addWidgetTearDown(WidgetTester tester) {
  addTearDown(() async {
    await _unmountScreen(tester);
  });
}

Future<void> _unmountScreen(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  final _ = await tester.pumpAndSettle();
}

Future<void> _pumpUntil(
  WidgetTester tester,
  Future<bool> Function() condition,
) async {
  for (var attempt = 0; attempt < 20 && !await condition(); attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  final _ = await tester.pumpAndSettle();
}

class _FakeSecretKeyManager extends SecretKeyManager {
  final SecretKey _key = .new(List<int>.filled(32, 7));

  @override
  Future<SecretKey> getOrCreateSecretKey() async => _key;
}

class _MockSyncApiModelsUseCase extends Mock implements SyncApiModelsUseCase;

class _MockTestMcpConnectionUsecase extends Mock
    implements TestMcpConnectionUsecase;

ServiceConnectionListItem _kindConnection(
  ServiceConnectionListItemKind kind,
  String name, {
  String? serviceName,
  ServiceConnectionDisplayStatus displayStatus = .unknown,
}) => ServiceConnectionListItem(
  id: name,
  workspaceId: _syncWorkspaceId,
  name: name,
  serviceName: serviceName,
  kind: kind,
  keySuffix: null,
  mcpServerId: null,
  authenticationType: null,
  displayStatus: displayStatus,
  expiresAt: null,
  lastRefreshedAt: null,
  lastAuthError: null,
  metadataValues: const [],
  canRefresh: false,
  canReconnect: false,
);
