import 'package:auravibes_app/features/service_connections/usecases/connector_command_usecase.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_connected_view_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_views_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  test(
    'disconnected cloud View never composes local Connector execution',
    () async {
      const session = WorkspaceSession(
        CloudWorkspaceRef(
          localWorkspaceId: 'mirror',
          serverUrl: 'https://example.invalid/',
          accountId: 'account',
          cloudWorkspaceId: 7,
        ),
      );
      var localCompositions = 0;
      final view = WorkspaceView.connectedDraft(name: 'Cloud source')
          .withConnected(
            const .new(
              toolId: 'connector/brave/web_search',
              revision: 'saved-contract',
              inputs: {'query': 'current'},
              connectionId: 'service:cloud',
            ),
          );
      final container = ProviderContainer(
        overrides: [
          workspaceSessionForRouteProvider('mirror')
              .overrideWith((ref) async => session),
          cloudWorkspaceStateGatewayProvider(session)
              .overrideWith((ref) async => null),
          workspaceConnectedAccessProvider('mirror')
              .overrideWith((ref) => Stream<Object?>.value(null)),
          workspaceViewDataProvider('mirror', view.id).overrideWith(
            (ref) async => WorkspaceViewData(
              view: view,
              table: const .new(
                id: '',
                name: 'Cloud source',
                labelColumnId: '',
                columns: [],
                revision: 1,
                schemaRevision: 0,
              ),
              records: [],
              needsRepair: false,
            ),
          ),
          connectorCommandUsecaseProvider.overrideWith((ref) {
            localCompositions++;
            throw StateError('Cloud read composed local execution');
          }),
        ],
      );
      addTearDown(container.dispose);
      final observed = <AsyncValue<WorkspaceConnectedResult>>[];
      final subscription = container.listen(
        workspaceConnectedViewProvider('mirror', view.id),
        (previous, next) => observed.add(next),
      );
      addTearDown(subscription.close);
      await expectLater(
        container.read(
          workspaceConnectedViewProvider('mirror', view.id).future,
        ),
        throwsA(
          isA<WorkspaceTableException>().having(
            (error) => error.denied,
            'denied',
            true,
          ),
        ),
      );
      expect(localCompositions, 0);
      expect(observed.any((state) => state.hasError), true);
    },
  );
}
