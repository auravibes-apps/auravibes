import 'dart:convert';

import 'package:auravibes_app/data/repositories/cloud_workspace_table_access_repository.dart';
import 'package:auravibes_app/data/repositories/cloud_workspace_table_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_record_query.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_record_query_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/screens/workspace_table_screen.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_table_access_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_app.dart';

class _Client extends Mock implements Client;

class _State extends Mock implements EndpointWorkspaceState;

class _Members extends Mock implements EndpointCloudWorkspace;

class _Stream extends Mock implements EndpointWorkspaceStream;

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    registerFallbackValue(
      ReadWorkspaceStateRequest(workspaceId: 1, pages: [], eventLimit: 0),
    );
    registerFallbackValue(
      PatchWorkspaceStateRequest(workspaceId: 1, requestId: '', operations: []),
    );
    registerFallbackValue(ListWorkspaceMembersRequest(workspaceId: 1));
  });
  testWidgets('owner inspects, grants and revokes table member access', (
    tester,
  ) async {
    final client = _Client();
    final state = _State();
    final members = _Members();
    when(() => client.workspaceState).thenReturn(state);
    when(() => client.workspaceStream).thenReturn(_Stream());
    when(() => client.cloudWorkspace).thenReturn(members);
    var data = <String, Object?>{
      'name': 'Shared',
      'labelColumnId': 'label',
      'schemaRevision': 1,
      'columns': [
        {'id': 'label', 'name': 'Title', 'type': 'text'},
      ],
    };
    var revision = 1;
    WorkspaceResource resource() => WorkspaceResource(
      workspaceId: 1,
      resourceKind: .table,
      resourceId: 'table',
      data: jsonEncode({
        ...data,
        'canManageTable': true,
        'canEditRecords': true,
      }),
      revision: revision,
      createdAt: .utc(2026),
      updatedAt: .utc(2026),
    );
    when(() => state.read(any())).thenAnswer((call) async {
      final request =
          call.positionalArguments.single as ReadWorkspaceStateRequest;

      return ReadWorkspaceStateResponse(
        pages: [
          for (final page in request.pages)
            WorkspaceResourcePage(
              resourceKind: page.resourceKind,
              resources: page.resourceKind == WorkspaceResourceKind.table
                  ? [resource()]
                  : [],
            ),
        ],
        currentSequence: revision,
        events: [],
        requiresSnapshot: false,
      );
    });
    when(() => state.patch(any())).thenAnswer((call) async {
      final operation =
          (call.positionalArguments.single as PatchWorkspaceStateRequest)
              .operations
              .single;
      expect(operation.expectedRevision, revision);
      data = jsonDecode(
        operation.data ?? (throw StateError('Missing payload')),
      ) as Map<String, dynamic>;
      revision++;

      return PatchWorkspaceStateResponse(
        resources: [resource()],
        sequence: revision,
      );
    });
    when(() => members.listMembers(any())).thenAnswer(
      (_) async => [
        CloudWorkspaceMemberSummary(
          userId: 'member',
          email: 'member@example.com',
          role: 'member',
          revision: 1,
          createdAt: .utc(2026),
        ),
      ],
    );
    final gateway = CloudWorkspaceStateGateway(
      client: client,
      workspace: const CloudWorkspaceRef(
        localWorkspaceId: 'one',
        serverUrl: 'https://example.com',
        accountId: 'account',
        cloudWorkspaceId: 1,
      ),
    );
    addTearDown(gateway.dispose);
    final usecase = OrganizeWorkspaceTablesUsecase(
      CloudWorkspaceTableRepository(.new(gateway)),
    );
    await tester.runAsync(() async {
      await tester.pumpWidget(
        TestableApp(
          child: WorkspaceTableScreen(
            workspaceId: 'one',
            tableId: 'table',
            onBack: () => fail('Unexpected back navigation'),
          ),
          overrides: [
            workspaceRecordQueryProvider.overrideWith(
              (ref, arguments) async =>
                  const WorkspaceRecordPage(records: [], hasMore: false),
            ),
            workspaceTableAccessUsecaseProvider('one').overrideWith(
              (ref) async => ManageWorkspaceTableAccessUsecase(
                CloudWorkspaceTableAccessRepository(.new(gateway)),
              ),
            ),
            workspaceTableUsecaseProvider('one')
                .overrideWith((ref) async => usecase),
          ],
          workspaceId: 'one',
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    Future<void> flush() async {
      for (var index = 0; index < 5; index++) {
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
      }
      final _ = await tester.pumpAndSettle();
    }

    await flush();
    await tester.tap(find.byType(AuraPopupMenuButton).last);
    await flush();
    await tester.tap(find.text('Table settings'));
    await flush();
    Finder button(String access) => find.byWidgetPredicate(
      (widget) =>
          widget is AuraButton &&
          widget.identifier == 'workspace_table_access_member_$access',
    );
    expect(find.text('member@example.com'), findsOneWidget);
    expect(tester.widget<AuraButton>(button('none')).disabled, true);
    await tester.runAsync(() => tester.tap(button('read')));
    await flush();
    expect(data['memberAccess'], {'member': 'read'});
    expect(tester.widget<AuraButton>(button('read')).disabled, true);
    await tester.runAsync(() => tester.tap(button('edit')));
    await flush();
    expect(data['memberAccess'], {'member': 'edit'});
    await tester.runAsync(() => tester.tap(button('none')));
    await flush();
    expect(data['memberAccess'], isEmpty);
  });
}
