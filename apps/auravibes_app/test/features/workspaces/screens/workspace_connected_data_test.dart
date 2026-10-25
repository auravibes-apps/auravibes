import 'dart:async';

import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_connected_view_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_connected_data.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_app.dart';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  for (final width in [400.0, 1200.0]) {
    testWidgets(
      'connected result clears while rechecking and after denial at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var pending = Completer<WorkspaceConnectedResult>();
        await tester.runAsync(() async {
          await tester.pumpWidget(
            TestableApp(
              workspaceId: 'one',
              overrides: [
                workspaceConnectedViewProvider(
                  'one',
                  'view',
                ).overrideWith((ref) => pending.future),
              ],
              child: const WorkspaceConnectedData(
                workspaceId: 'one',
                viewId: 'view',
              ),
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 30));
        });
        await tester.runAsync(() async {
          await tester.pump();
          await Future<void>.delayed(const Duration(milliseconds: 30));
        });
        await tester.pump();
        expect(find.byType(WorkspaceConnectedData), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        pending.complete((
          value: {'private': 'allowed result'},
          fetchedAt: DateTime.utc(2026, 10, 24),
        ));
        await tester.pumpAndSettle();
        expect(find.textContaining('allowed result'), findsOneWidget);
        final container = ProviderScope.containerOf(
          tester.element(find.byType(WorkspaceConnectedData)),
        );
        pending = Completer<WorkspaceConnectedResult>();
        container.invalidate(workspaceConnectedViewProvider('one', 'view'));
        await tester.pump();
        expect(find.textContaining('allowed result'), findsNothing);
        pending.completeError(
          AgentToolExecutionFailure(
            failurePhase: 'connector.authorization',
            responseRaw: '{"error":{"code":"tool_access_denied"}}',
            error: StateError('denied'),
            stackTrace: StackTrace.current,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Access denied'), findsOneWidget);
        expect(find.textContaining('allowed result'), findsNothing);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
    testWidgets(
      'Connector-only response binds approved host surface at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final view = WorkspaceView.connectedDraft(name: 'Live').edited(
          name: 'Live',
          definition: .fromJson({
            'version': 1,
            'components': [
              {
                'id': 'root',
                'component': 'Text',
                'text': {'path': '/title'},
              },
            ],
          }),
          bindings: {'title': '/results/0/name'},
          columnTypes: {},
        );
        final data = WorkspaceViewData(
          view: view,
          table: const .new(
            id: '',
            name: 'Live',
            labelColumnId: '',
            columns: [],
            revision: 1,
            schemaRevision: 0,
          ),
          records: [],
          needsRepair: false,
        );
        await tester.runAsync(() async {
          await tester.pumpWidget(
            TestableApp(
              workspaceId: 'one',
              overrides: [
                workspaceConnectedViewProvider('one', 'view').overrideWith(
                  (ref) async => (
                    value: {
                      'results': [
                        {'name': 'Bound live source'},
                      ],
                    },
                    fetchedAt: DateTime.utc(2026, 10, 24),
                  ),
                ),
              ],
              child: WorkspaceConnectedData(
                workspaceId: 'one',
                viewId: 'view',
                data: data,
              ),
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 30));
        });
        await tester.pumpAndSettle();
        expect(find.text('Bound live source'), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
