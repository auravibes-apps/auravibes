import 'dart:convert';

import 'package:auravibes_app/data/repositories/cloud_workspace_record_query_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_record_query.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart' as cloud;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  test(
    'cloud pages preserve restricted references and bound returned records',
    () async {
      final gateway = _Gateway();
      final client = _Client();
      final endpoint = _Endpoint();
      when(() => gateway.client).thenReturn(client);
      when(() => gateway.workspace).thenReturn(
        const CloudWorkspaceRef(
          localWorkspaceId: 'one',
          serverUrl: 'https://example.invalid',
          accountId: 'account',
          cloudWorkspaceId: 42,
        ),
      );
      when(() => client.workspaceState).thenReturn(endpoint);
      when(
        () => endpoint.queryRecords(42, 'source', any()),
      ).thenAnswer((_) async => [_resource('record'), _resource('sentinel')]);
      final page = await CloudWorkspaceRecordQueryRepository(gateway)
          .query('source', const WorkspaceRecordQuery(limit: 1));
      expect(page.hasMore, isTrue);
      expect(page.records.single.id, 'record');
      expect(page.records.single.restrictedReferenceColumns, ['link']);
      expect(page.records.single.values, {'label': 'Readable source'});
      final encoded =
          verify(() => endpoint.queryRecords(42, 'source', captureAny()))
                  .captured
                  .single
              as String;
      expect(jsonDecode(encoded), containsPair('limit', 1));
    },
  );
}

cloud.WorkspaceResource _resource(String id) => cloud.WorkspaceResource(
  workspaceId: 42,
  resourceKind: .tableRecord,
  resourceId: id,
  data: jsonEncode({
    'tableId': 'source',
    'values': {'label': 'Readable source'},
    'restrictedReferenceColumns': ['link'],
  }),
  revision: 1,
  createdAt: .utc(2026),
  updatedAt: .utc(2026),
);

class _Gateway extends Mock implements CloudWorkspaceStateGateway;

class _Client extends Mock implements cloud.Client;

class _Endpoint extends Mock implements cloud.EndpointWorkspaceState;
