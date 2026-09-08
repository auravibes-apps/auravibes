import 'dart:async';

import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const workspace = CloudWorkspaceRef(
    localWorkspaceId: 'local',
    serverUrl: 'https://example.com',
    accountId: 'account',
    cloudWorkspaceId: 7,
  );

  test('turns a stalled state read into a typed cloud error', () async {
    final gateway = CloudWorkspaceStateGateway.forTesting(
      workspace: workspace,
      readState: (_) => Completer<ReadWorkspaceStateResponse>().future,
      subscribe: (_) => const Stream.empty(),
      readTimeout: Duration.zero,
    );

    await expectLater(
      gateway.read(
        pages: [
          WorkspaceResourcePageRequest(
            resourceKind: WorkspaceResourceKind.skill,
            limit: 1,
          ),
        ],
      ),
      throwsA(
        isA<CloudAppException>()
            .having(
              (error) => error.context,
              'context',
              CloudOperationContext.state,
            )
            .having((error) => error.code, 'code', isNull),
      ),
    );
  });

  test('does not overlap reads after a timeout', () async {
    final firstResponse = Completer<ReadWorkspaceStateResponse>();
    var reads = 0;
    final gateway = CloudWorkspaceStateGateway.forTesting(
      workspace: workspace,
      readState: (_) {
        reads++;

        return reads == 1
            ? firstResponse.future
            : Future.value(_response(sequence: 1));
      },
      subscribe: (_) => const Stream.empty(),
      readTimeout: Duration.zero,
    );

    final pages = [
      WorkspaceResourcePageRequest(
        resourceKind: WorkspaceResourceKind.skill,
        limit: 1,
      ),
    ];

    await expectLater(
      gateway.read(pages: pages),
      throwsA(isA<CloudAppException>()),
    );
    await expectLater(
      gateway.read(pages: pages),
      throwsA(isA<CloudAppException>()),
    );
    await Future<void>.delayed(Duration.zero);
    expect(reads, 1);

    firstResponse.complete(_response(sequence: 1));
    await Future<void>.delayed(Duration.zero);
    expect(reads, 2);
  });

  test('paginates to exhaustion and never requests over 100', () async {
    final requests = <ReadWorkspaceStateRequest>[];
    final gateway = CloudWorkspaceStateGateway.forTesting(
      workspace: workspace,
      readState: (request) async {
        requests.add(request);
        final cursor = request.pages.single.afterResourceId;

        return _response(
          sequence: 4,
          resources: [_resource(cursor == null ? 'a' : 'b')],
          nextResourceId: cursor == null ? 'a' : null,
        );
      },
      subscribe: (_) => const Stream.empty(),
      delay: (_) => Completer<void>().future,
    );

    final resources = await gateway.watchResources(const [
      WorkspaceResourceKind.workspaceSetting,
    ]).first;

    expect(resources.map((resource) => resource.resourceId), ['a', 'b']);
    expect(requests, hasLength(2));
    expect(
      requests.every((request) => request.pages.single.limit == 100),
      isTrue,
    );
    expect(requests.last.pages.single.afterResourceId, 'a');
  });

  test(
    'dedupes, recovers gaps, and resumes from last applied sequence',
    () async {
      final subscribeCursors = <int>[];
      var reads = 0;
      var subscriptions = 0;
      final gateway = CloudWorkspaceStateGateway.forTesting(
        workspace: workspace,
        readState: (_) async {
          reads++;

          return _response(
            sequence: reads == 1 ? 5 : 8,
            resources: [_resource(reads == 1 ? 'initial' : 'recovered')],
          );
        },
        subscribe: (request) {
          subscribeCursors.add(request.afterSequence);
          subscriptions++;
          if (subscriptions == 1) {
            return Stream.fromIterable([_event(5), _event(7)]);
          }

          return Stream.error(StateError('offline'));
        },
        delay: (_) => Future.value(),
      );

      final values = await gateway
          .watchResources(const [WorkspaceResourceKind.workspaceSetting])
          .take(2)
          .toList();

      expect(values.firstOrNull?.single.resourceId, 'initial');
      expect(values[1].single.resourceId, 'recovered');
      expect(subscribeCursors, [5]);
      expect(reads, 2);
    },
  );

  test('backs off with a cap and stops after disposal', () async {
    final delays = <Duration>[];
    void Function()? disposeGateway;
    final gateway = CloudWorkspaceStateGateway.forTesting(
      workspace: workspace,
      readState: (_) async => _response(sequence: 1),
      subscribe: (_) => Stream.error(StateError('offline')),
      delay: (duration) {
        delays.add(duration);
        if (delays.length == 7) disposeGateway?.call();

        return Future.value();
      },
    );
    disposeGateway = gateway.dispose;

    await gateway.watchResources(const [
      WorkspaceResourceKind.workspaceSetting,
    ]).drain<void>();

    expect(delays, [
      const Duration(milliseconds: 250),
      const Duration(milliseconds: 500),
      const Duration(seconds: 1),
      const Duration(seconds: 2),
      const Duration(seconds: 4),
      const Duration(seconds: 8),
      const Duration(seconds: 8),
    ]);
  });

  test('disposal cancels an idle active subscription', () async {
    final stream = StreamController<WorkspaceStreamEnvelope>();
    final gateway = CloudWorkspaceStateGateway.forTesting(
      workspace: workspace,
      readState: (_) async => _response(sequence: 1),
      subscribe: (_) => stream.stream,
    );
    final done = gateway.watchResources(const [
      WorkspaceResourceKind.workspaceSetting,
    ]).drain<void>();
    await Future<void>.delayed(Duration.zero);

    gateway.dispose();

    await done.timeout(const Duration(seconds: 1));
    expect(stream.hasListener, isFalse);
    await expectLater(stream.close(), completes);
  });

  test('does not reconnect after terminal membership error', () async {
    var subscriptions = 0;
    final gateway = CloudWorkspaceStateGateway.forTesting(
      workspace: workspace,
      readState: (_) async => _response(sequence: 1),
      subscribe: (_) {
        subscriptions++;

        return Stream.error(
          CloudWorkspaceException(
            code: CloudWorkspaceErrorCode.membershipRequired,
          ),
        );
      },
      delay: (_) => Future.value(),
    );

    await expectLater(
      gateway.watchResources(const [WorkspaceResourceKind.workspaceSetting]),
      emitsInOrder([
        isA<List<WorkspaceResource>>(),
        emitsError(
          isA<CloudAppException>().having(
            (error) => error.code,
            'code',
            CloudWorkspaceErrorCode.membershipRequired.name,
          ),
        ),
      ]),
    );
    expect(subscriptions, 1);
  });

  test(
    'reconnects to a replacement stream from the recovered sequence',
    () async {
      final cursors = <int>[];
      var reads = 0;
      final gateway = CloudWorkspaceStateGateway.forTesting(
        workspace: workspace,
        readState: (_) async => _response(
          sequence: ++reads == 1 ? 1 : 3,
          resources: [_resource('resource-$reads')],
        ),
        subscribe: (request) {
          cursors.add(request.afterSequence);
          if (cursors.length == 1) {
            return Stream.error(StateError('replacement'));
          }

          return Stream.fromIterable([_event(2)]);
        },
        delay: (_) => Future.value(),
      );

      final values = await gateway
          .watchResources(const [WorkspaceResourceKind.workspaceSetting])
          .take(2)
          .toList();

      expect(values.last.single.resourceId, 'resource-2');
      expect(cursors, [1, 1]);
    },
  );

  test('fails typed on a repeated cursor', () async {
    final gateway = CloudWorkspaceStateGateway.forTesting(
      workspace: workspace,
      readState: (_) async => _response(
        sequence: 1,
        resources: [_resource('a')],
        nextResourceId: 'a',
      ),
      subscribe: (_) => const Stream.empty(),
    );

    await expectLater(
      gateway.watchResources(const [WorkspaceResourceKind.workspaceSetting]),
      emitsError(
        isA<CloudAppException>().having(
          (error) => error.code,
          'code',
          'invalidCursor',
        ),
      ),
    );
  });

  test('deduplicates page-boundary resource IDs', () async {
    final gateway = CloudWorkspaceStateGateway.forTesting(
      workspace: workspace,
      readState: (request) async => _response(
        sequence: 1,
        resources: [
          _resource('a'),
          if (request.pages.single.afterResourceId == null) _resource('b'),
        ],
        nextResourceId: request.pages.single.afterResourceId == null
            ? 'b'
            : null,
      ),
      subscribe: (_) => const Stream.empty(),
    );

    final resources = await gateway.watchResources(const [
      WorkspaceResourceKind.workspaceSetting,
    ]).first;

    expect(resources.map((resource) => resource.resourceId), ['a', 'b']);
  });

  test('retries a mixed-watermark multi-kind snapshot', () async {
    var reads = 0;
    final gateway = CloudWorkspaceStateGateway.forTesting(
      workspace: workspace,
      readState: (request) async {
        reads++;

        return _response(
          sequence: reads < 3 ? reads : 3,
          resources: [
            _resource(
              request.pages.single.resourceKind.name,
              kind: request.pages.single.resourceKind,
            ),
          ],
          kind: request.pages.single.resourceKind,
        );
      },
      subscribe: (_) => const Stream.empty(),
    );

    final resources = await gateway.watchResources(const [
      WorkspaceResourceKind.workspaceSetting,
      WorkspaceResourceKind.compactionSetting,
    ]).first;

    expect(resources.map((resource) => resource.resourceId), [
      WorkspaceResourceKind.workspaceSetting.name,
      WorkspaceResourceKind.compactionSetting.name,
    ]);
    expect(reads, 4);
  });
}

ReadWorkspaceStateResponse _response({
  required int sequence,
  List<WorkspaceResource> resources = const [],
  String? nextResourceId,
  WorkspaceResourceKind kind = WorkspaceResourceKind.workspaceSetting,
}) => ReadWorkspaceStateResponse(
  pages: [
    WorkspaceResourcePage(
      resourceKind: kind,
      resources: resources,
      nextResourceId: nextResourceId,
    ),
  ],
  currentSequence: sequence,
  events: const [],
  requiresSnapshot: false,
);

WorkspaceResource _resource(
  String id, {
  WorkspaceResourceKind kind = WorkspaceResourceKind.workspaceSetting,
}) {
  final now = DateTime.utc(2026);

  return WorkspaceResource(
    workspaceId: 7,
    resourceKind: kind,
    resourceId: id,
    data: '{}',
    revision: 1,
    createdAt: now,
    updatedAt: now,
  );
}

WorkspaceStreamEnvelope _event(int sequence) => WorkspaceStreamEnvelope(
  kind: WorkspaceStreamEnvelopeKind.workspaceInvalidated,
  workspaceId: 7,
  sequence: sequence,
  eventId: 'event-$sequence',
  eventKind: 'workspace.invalidated',
  resourceKind: WorkspaceResourceKind.workspaceSetting.name,
  createdAt: DateTime.utc(2026),
);
