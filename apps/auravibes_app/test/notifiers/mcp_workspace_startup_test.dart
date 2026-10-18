import 'dart:async';

import 'package:auravibes_app/data/repositories/mcp_servers_repository.dart';
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/features/tools/data/cloud_tools_repository.dart';
import 'package:auravibes_app/features/tools/providers/mcp_repository_provider.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/notifiers/mcp_connection_status.dart';
import 'package:auravibes_app/providers/router_providers.dart';
import 'package:auravibes_app/services/mcp_service/mcp_manager_client.dart';
import 'package:auravibes_app/services/oauth_credential_service.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

const _benchmarkEnabled = bool.fromEnvironment('MCP_STARTUP_BENCHMARK');

void main() {
  setUpAll(() {
    registerFallbackValue(_server('local'));
    registerFallbackValue(_Client());
  });

  test('loading destination session invalidates old connections', () async {
    final session = Completer<WorkspaceSession>();
    final fixture = _Fixture(cloudSession: session.future);
    addTearDown(fixture.container.dispose);
    final client = Completer<McpManagerClient>();
    when(() => fixture.manager.connectMcp(any()))
        .thenAnswer((_) => client.future);
    final disconnected = Completer<void>();
    when(() => fixture.manager.disconnect(fixture.client)).thenAnswer((_) {
      disconnected.complete();

      return Future.value();
    });
    fixture.start();
    await fixture.container.pump();
    final switched = fixture.switchTo('cloud');
    await fixture.container.pump();
    client.complete(fixture.client);
    await disconnected.future.timeout(const Duration(seconds: 2));

    expect(fixture.connections, isEmpty);
    verify(() => fixture.manager.disconnect(fixture.client)).called(1);
    session.complete(
      const WorkspaceSession(LocalWorkspaceRef(localWorkspaceId: 'cloud')),
    );
    await switched;
    expect(fixture.connections.single.server.workspaceId, 'cloud');
  });

  test('disposed notifier ignores pending session completion', () async {
    final session = Completer<WorkspaceSession>();
    final fixture = _Fixture(initial: 'cloud', cloudSession: session.future);
    addTearDown(fixture.container.dispose);
    final sessionProvider = workspaceSessionForRouteProvider('cloud');
    final sessionSubscription = fixture.container.listen(
      sessionProvider,
      (_, next) => expect(next, isNotNull),
    );
    addTearDown(sessionSubscription.close);
    final connectionSubscription = fixture.container.listen(
      mcpConnectionProvider,
      (_, next) => expect(next, isEmpty),
    );
    await fixture.container.pump();
    connectionSubscription.close();
    fixture.container.invalidate(mcpConnectionProvider);
    session.complete(
      const WorkspaceSession(LocalWorkspaceRef(localWorkspaceId: 'cloud')),
    );
    final _ = await fixture.container.read(sessionProvider.future);
    await fixture.container.pump();

    final _ = verifyNever(
      () => fixture.cloud.getEnabledMcpServersForWorkspace('cloud'),
    );
  });

  test('stale session cannot replace returned workspace', () async {
    final session = Completer<WorkspaceSession>();
    final fixture = _Fixture(cloudSession: session.future);
    addTearDown(fixture.container.dispose);
    fixture.start();
    await fixture.container.pump();
    fixture.container.read(_routeProvider.notifier).changeWorkspace('cloud');
    await fixture.container.pump();
    await fixture.switchTo('local');
    session.complete(
      const WorkspaceSession(LocalWorkspaceRef(localWorkspaceId: 'cloud')),
    );
    await fixture.container.pump();

    expect(fixture.connections.single.server.workspaceId, 'local');
    expect(fixture.connections.single.client, same(fixture.client));
    final _ = verifyNever(
      () => fixture.cloud.getEnabledMcpServersForWorkspace('cloud'),
    );
  });

  test('queued startup does not replace manual reconnect', () async {
    final fixture = _Fixture();
    addTearDown(fixture.container.dispose);
    final servers = [
      for (var index = 0; index < 5; index++)
        _server('local').copyWith(id: 'server-$index', name: 'server-$index'),
    ];
    when(() => fixture.local.getEnabledMcpServersForWorkspace('local'))
        .thenAnswer((_) async => servers);
    final pending = <Completer<McpManagerClient>>[];
    final started = Completer<void>();
    var manualConnections = 0;
    when(() => fixture.manager.connectMcp(any())).thenAnswer((invocation) {
      final server = invocation.positionalArguments.first as McpServerToCreate;
      if (server.name == 'server-4') {
        manualConnections++;

        return Future.value(fixture.client);
      }
      final connection = Completer<McpManagerClient>();
      pending.add(connection);
      if (pending.length == 4) started.complete();

      return connection.future;
    });
    fixture.start();
    await started.future.timeout(const Duration(seconds: 2));
    await fixture.container
        .read(mcpConnectionProvider.notifier)
        .reconnectMcpServer('server-4');
    for (final connection in pending) {
      connection.complete(_Client());
    }
    await fixture.container.pump();

    expect(manualConnections, 1);
    expect(fixture.connections.last.client, same(fixture.client));
    final _ = verifyNever(() => fixture.manager.disconnect(fixture.client));
  });
  test('startup caps active work and stops stale queued servers', () async {
    final fixture = _Fixture();
    addTearDown(fixture.container.dispose);
    final servers = [
      for (var index = 0; index < 8; index++)
        _server('local').copyWith(id: 'server-$index'),
    ];
    when(() => fixture.local.getEnabledMcpServersForWorkspace('local'))
        .thenAnswer((_) async => servers);
    final pending = <Completer<McpManagerClient>>[];
    final firstWave = Completer<void>();
    final nextStarted = Completer<void>();
    when(() => fixture.manager.connectMcp(any())).thenAnswer((_) {
      final result = Completer<McpManagerClient>();
      pending.add(result);
      if (pending.length == 4) firstWave.complete();
      if (pending.length == 5) nextStarted.complete();

      return result.future;
    });
    fixture.start();
    await firstWave.future.timeout(const Duration(seconds: 2));
    expect(pending, hasLength(4));
    expect(fixture.connections, hasLength(8));
    expect(
      fixture.observed.where(
        (states) =>
            states.length == 8 &&
            states.every(
              (item) => item.status == McpConnectionStatus.connecting,
            ),
      ),
      hasLength(1),
    );
    pending.firstOrNull?.complete(fixture.client);
    await nextStarted.future.timeout(const Duration(seconds: 2));
    expect(pending, hasLength(5));
    await fixture.switchTo('cloud');
    for (final connection in pending.skip(1)) {
      connection.complete(_Client());
    }
    await fixture.container.pump();

    expect(pending, hasLength(5));
    expect(fixture.connections.map((item) => item.server.workspaceId), [
      'cloud',
    ]);
  });

  test('one connection failure does not block other startup servers', () async {
    final fixture = _Fixture();
    addTearDown(fixture.container.dispose);
    final servers = [
      for (var index = 0; index < 8; index++)
        _server('local').copyWith(id: 'server-$index', name: 'server-$index'),
    ];
    when(() => fixture.local.getEnabledMcpServersForWorkspace('local'))
        .thenAnswer((_) async => servers);
    when(() => fixture.manager.connectMcp(any())).thenAnswer((
      invocation,
    ) async {
      final server = invocation.positionalArguments.first as McpServerToCreate;
      if (server.name == 'server-0') throw Exception('Connection refused');

      return fixture.client;
    });
    final ready = Completer<void>();
    final subscription = fixture.container.listen(mcpConnectionProvider, (
      _,
      next,
    ) {
      if (next.length == 8 &&
          next.every((item) => item.status != McpConnectionStatus.connecting) &&
          !ready.isCompleted) {
        ready.complete();
      }
    });
    await ready.future.timeout(const Duration(seconds: 2));
    subscription.close();

    expect(
      fixture.connections.where(
        (item) => item.status == McpConnectionStatus.error,
      ),
      hasLength(1),
    );
    expect(
      fixture.connections.where(
        (item) => item.status == McpConnectionStatus.connected,
      ),
      hasLength(7),
    );
  });

  test('late stored reconnect cannot enter new workspace', () async {
    final fixture = _Fixture();
    addTearDown(fixture.container.dispose);
    final query = Completer<McpServerEntity?>();
    when(() => fixture.local.getMcpServerById('missing-server'))
        .thenAnswer((_) => query.future);
    fixture.start();
    await fixture.container.pump();
    final reconnect = fixture.container
        .read(mcpConnectionProvider.notifier)
        .reconnectMcpServer('missing-server');
    await fixture.switchTo('cloud');
    query.complete(_server('local'));
    await reconnect;

    expect(fixture.connections.map((item) => item.server.workspaceId), [
      'cloud',
    ]);
  });

  for (final phase in ['tools', 'sync']) {
    test('stale $phase cannot replace returned local workspace', () async {
      final fixture = _Fixture();
      addTearDown(fixture.container.dispose);
      final staleClient = _Client();
      final started = Completer<void>();
      final release = Completer<void>();
      var connects = 0;
      when(() => fixture.manager.connectMcp(any())).thenAnswer((_) async {
        connects++;

        return connects == 1 ? staleClient : fixture.client;
      });
      if (phase == 'tools') {
        when(() => fixture.manager.getTools(staleClient)).thenAnswer((_) async {
          started.complete();
          await release.future;

          return [];
        });
      } else {
        var syncs = 0;
        when(
          () => fixture.local.syncMcpTools(
            mcpServerId: any(named: 'mcpServerId'),
            currentTools: any(named: 'currentTools'),
          ),
        ).thenAnswer((_) async {
          syncs++;
          if (syncs != 1) return;
          started.complete();
          await release.future;
        });
      }
      fixture.start();
      await started.future.timeout(const Duration(seconds: 2));
      await fixture.switchTo('cloud');
      await fixture.switchTo('local');
      release.complete();
      await fixture.container.pump();

      expect(fixture.connections.single.client, same(fixture.client));
      verify(() => fixture.manager.disconnect(staleClient)).called(1);
      final _ = verifyNever(() => fixture.manager.disconnect(fixture.client));
    });
  }

  test('startup benchmark', _benchmarkStartup, skip: !_benchmarkEnabled);

  for (final staleFailure in [false, true]) {
    test(
      'stale cloud result failure=$staleFailure cannot replace return',
      () async {
        final fixture = _Fixture(initial: 'cloud');
        addTearDown(fixture.container.dispose);
        final discovery = Completer<DiscoverMcpServerResult>();
        var calls = 0;
        when(() => fixture.cloud.discoverMcpServer('cloud-server'))
            .thenAnswer((_) async {
              calls++;
              if (calls == 1) return await discovery.future;

              return DiscoverMcpServerResult(health: .healthy, tools: []);
            });
        fixture.start();
        await fixture.container.pump();
        await fixture.switchTo('local');
        await fixture.switchTo('cloud');
        if (staleFailure) {
          discovery.completeError(Exception('Discovery refused'));
        } else {
          discovery.complete(
            DiscoverMcpServerResult(health: .unhealthy, tools: []),
          );
        }
        await fixture.container.pump();

        expect(
          fixture.connections.single.status,
          McpConnectionStatus.connected,
        );
        expect(fixture.connections.single.errorMessage, isNull);
      },
    );
  }

  test('cloud discovery failure does not block sibling servers', () async {
    final fixture = _Fixture(initial: 'cloud');
    addTearDown(fixture.container.dispose);
    when(() => fixture.cloud.getEnabledMcpServersForWorkspace('cloud'))
        .thenAnswer(
          (_) async => [
            _server('cloud'),
            _server('cloud').copyWith(id: 'healthy-server'),
          ],
        );
    when(() => fixture.cloud.discoverMcpServer('cloud-server'))
        .thenThrow(Exception('Discovery refused'));
    fixture.start();
    await fixture.container.pump();

    expect(fixture.connections.map((item) => item.status), [
      McpConnectionStatus.error,
      McpConnectionStatus.connected,
    ]);
  });

  test('late local query cannot replace cloud workspace', () async {
    final fixture = _Fixture();
    addTearDown(fixture.container.dispose);
    final query = Completer<List<McpServerEntity>>();
    when(() => fixture.local.getEnabledMcpServersForWorkspace('local'))
        .thenAnswer((_) => query.future);
    fixture.start();
    await fixture.switchTo('cloud');
    query.complete([_server('local')]);
    await fixture.container.pump();

    expect(fixture.connections.map((item) => item.server.workspaceId), [
      'cloud',
    ]);
    final _ = verifyNever(() => fixture.manager.connectMcp(any()));
    final _ = verifyNever(
      () => fixture.cloud.discoverMcpServer('local-server'),
    );
  });

  test('late cloud discovery cannot replace local workspace', () async {
    final fixture = _Fixture(initial: 'cloud');
    addTearDown(fixture.container.dispose);
    final discovery = Completer<DiscoverMcpServerResult>();
    when(() => fixture.cloud.discoverMcpServer('cloud-server'))
        .thenAnswer((_) => discovery.future);
    fixture.start();
    await fixture.container.pump();
    await fixture.switchTo('local');
    discovery.complete(DiscoverMcpServerResult(health: .healthy, tools: []));
    await fixture.container.pump();

    expect(fixture.connections.map((item) => item.server.workspaceId), [
      'local',
    ]);
    expect(fixture.connections.single.status, McpConnectionStatus.connected);
    final _ = verifyNever(() => fixture.manager.disconnect(fixture.client));
  });

  test('late local client uses original manager for cleanup', () async {
    final fixture = _Fixture();
    addTearDown(fixture.container.dispose);
    final client = Completer<McpManagerClient>();
    when(() => fixture.manager.connectMcp(any()))
        .thenAnswer((_) => client.future);
    fixture.start();
    await fixture.container.pump();
    await fixture.switchTo('cloud');
    client.complete(fixture.client);
    await fixture.container.pump();

    expect(fixture.connections.map((item) => item.server.workspaceId), [
      'cloud',
    ]);
    verify(() => fixture.manager.disconnect(fixture.client)).called(1);
    final _ = verifyNever(() => fixture.manager.getTools(any()));
    final _ = verifyNever(
      () => fixture.local.syncMcpTools(
        mcpServerId: any(named: 'mcpServerId'),
        currentTools: any(named: 'currentTools'),
      ),
    );
  });
}

McpServerEntity _server(String workspace) => McpServerEntity(
  id: '$workspace-server',
  workspaceId: workspace,
  name: workspace,
  url: 'https://example.com',
  transport: const McpTransportTypeSSE(),
  authenticationType: const McpAuthenticationTypeNone(),
  createdAt: .new(2026),
  updatedAt: .new(2026),
);

Future<void> _benchmarkStartup() async {
  for (final sequential in [true, false]) {
    final samples = <int>[];
    var peak = 0;
    for (var run = 0; run < 6; run++) {
      final result = await _measureStartup(sequential: sequential);
      if (run > 0) samples.add(result.milliseconds);
      peak = result.peak;
    }
    samples.sort();
    debugPrint(
      '${sequential ? 'sequential' : 'workspace'}: '
      'median=${samples[2]}ms range=${samples.firstOrNull}-${samples.last}ms '
      'peak=$peak',
    );
    expect(peak, sequential ? 1 : inInclusiveRange(1, 4));
  }
}

Future<({int milliseconds, int peak})> _measureStartup({
  required bool sequential,
}) async {
  final fixture = _Fixture();
  final servers = [
    for (var index = 0; index < 12; index++)
      _server('local').copyWith(id: 'server-$index'),
  ];
  when(() => fixture.local.getEnabledMcpServersForWorkspace('local'))
      .thenAnswer((_) async => sequential ? [] : servers);
  for (final server in servers) {
    when(() => fixture.local.getMcpServerById(server.id))
        .thenAnswer((_) async => server);
  }
  var active = 0;
  var peak = 0;
  when(() => fixture.manager.connectMcp(any())).thenAnswer((_) async {
    active++;
    if (active > peak) peak = active;
    await Future<void>.delayed(const Duration(milliseconds: 40));
    active--;

    return fixture.client;
  });
  final ready = Completer<void>();
  final watch = Stopwatch()..start();
  final subscription = fixture.container.listen(mcpConnectionProvider, (
    _,
    next,
  ) {
    if (next.length == servers.length &&
        next.every((item) => item.status == McpConnectionStatus.connected) &&
        !ready.isCompleted) {
      ready.complete();
    }
  });
  if (sequential) {
    final notifier = fixture.container.read(mcpConnectionProvider.notifier);
    for (final server in servers) {
      await notifier.reconnectMcpServer(server.id);
    }
  }
  await ready.future.timeout(const Duration(seconds: 5));
  watch.stop();
  subscription.close();
  fixture.container.dispose();

  return (milliseconds: watch.elapsedMilliseconds, peak: peak);
}

final _routeProvider = NotifierProvider<_Route, String?>(_Route.new);

class _Route extends Notifier<String?> {
  @override
  String? build() => null;

  void changeWorkspace(String? workspace) {
    if (state == workspace) return;
    state = workspace;
  }
}

class _Fixture {
  factory({String initial = 'local', Future<WorkspaceSession>? cloudSession}) {
    final local = _LocalRepository();
    final cloud = _CloudRepository();
    final manager = _Manager();
    final oauth = _OAuth();
    final client = _Client();
    when(() => local.getEnabledMcpServersForWorkspace('local'))
        .thenAnswer((_) async => [_server('local')]);
    when(() => cloud.getEnabledMcpServersForWorkspace('cloud'))
        .thenAnswer((_) async => [_server('cloud')]);
    when(() => cloud.discoverMcpServer(any())).thenAnswer(
      (_) async => DiscoverMcpServerResult(health: .healthy, tools: []),
    );
    when(() => oauth.resolveMcpAuthentication(any()))
        .thenAnswer((_) async => const McpAuthenticationTypeNone());
    when(() => manager.connectMcp(any())).thenAnswer((_) async => client);
    when(() => manager.getTools(any())).thenAnswer((_) async => []);
    when(() => manager.disconnect(any()))
        .thenAnswer((_) => Future<void>.value());
    when(
      () => local.syncMcpTools(
        mcpServerId: any(named: 'mcpServerId'),
        currentTools: any(named: 'currentTools'),
      ),
    ).thenAnswer((_) => Future<void>.value());
    when(() => client.onTokenUpdate).thenReturn(null);
    final container = ProviderContainer(
      overrides: [
        currentRouteWorkspaceIdProvider.overrideWith(
          (ref) => ref.watch(_routeProvider),
        ),
        workspaceSessionForRouteProvider('local').overrideWithValue(
          const AsyncData(
            WorkspaceSession(LocalWorkspaceRef(localWorkspaceId: 'local')),
          ),
        ),
        workspaceSessionForRouteProvider('cloud').overrideWith(
          (_) =>
              cloudSession ??
              Future.value(
                const WorkspaceSession(
                  LocalWorkspaceRef(localWorkspaceId: 'cloud'),
                ),
              ),
        ),
        mcpServersRepositoryProvider.overrideWith(
          (_, session) =>
              session.workspace.localWorkspaceId == 'cloud' ? cloud : local,
        ),
        mcpManagerServiceProvider.overrideWithValue(manager),
        oauthCredentialServiceProvider.overrideWithValue(oauth),
      ],
    );
    container.read(_routeProvider.notifier).changeWorkspace(initial);

    return _Fixture._(local, cloud, manager, oauth, client, container);
  }

  new _(
    this.local,
    this.cloud,
    this.manager,
    this.oauth,
    this.client,
    this.container,
  );

  final _LocalRepository local;
  final _CloudRepository cloud;
  final _Manager manager;
  final _OAuth oauth;
  final _Client client;
  final ProviderContainer container;
  final observed = <List<McpConnectionState>>[];

  List<McpConnectionState> get connections =>
      container.read(mcpConnectionProvider);

  void start() {
    final _ = container.listen(
      mcpConnectionProvider,
      (_, next) => observed.add(next),
    );
  }

  Future<void> switchTo(String? workspace) async {
    final ready = Completer<void>();
    final subscription = container.listen(mcpConnectionProvider, (_, next) {
      if (next.any(
            (item) =>
                item.server.workspaceId == workspace &&
                item.status == McpConnectionStatus.connected,
          ) &&
          !ready.isCompleted) {
        ready.complete();
      }
    });
    container.read(_routeProvider.notifier).changeWorkspace(workspace);
    await ready.future.timeout(const Duration(seconds: 5));
    subscription.close();
  }
}

class _LocalRepository extends Mock implements McpServersRepositoryContract;
class _CloudRepository extends Mock implements CloudToolsRepository;
class _Manager extends Mock implements McpManagerService;
class _OAuth extends Mock implements OAuthCredentialService;
class _Client extends Mock implements McpManagerClient;
