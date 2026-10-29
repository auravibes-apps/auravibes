import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/features/service_connections/models/connector_connection_candidate.dart';
import 'package:auravibes_app/features/service_connections/models/connector_tool_catalog_item.dart';
import 'package:auravibes_app/features/service_connections/providers/connector_tool_catalog_provider.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workflows/notifiers/workflow_editor_notifier.dart';
import 'package:auravibes_app/features/workflows/providers/workflow_providers.dart';
import 'package:auravibes_app/features/workflows/widgets/workflow_connector_tool_sample.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_connected_view_provider.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('connection lookup error can retry before sampling', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 10, 29);
    final workflow = WorkspaceWorkflow.create(
      id: 'flow',
      workspaceId: 'workspace',
      name: 'Read public pages',
      description: '',
      createdAt: now,
      updatedAt: now,
    );
    final tool = WorkspaceToolEntity(
      id: 'workspace-tool',
      workspaceId: 'workspace',
      toolId: 'connector/brave/web_search',
      isEnabled: true,
      permissionMode: ToolPermissionMode.alwaysAsk,
      createdAt: now,
      updatedAt: now,
    );
    const catalogItem = ConnectorToolCatalogItem(
      toolId: 'connector/brave/web_search',
      connectorName: 'Brave Search',
      title: 'Web search',
      description: 'Search the public web.',
      connectorId: 'brave',
      toolDefinition: ConnectorToolDefinition(
        slug: 'web_search',
        title: 'Web search',
        description: 'Search the public web.',
        requiresConnection: true,
        urlTemplate: ConnectorToolRequestTemplate(
          template: ConnectorRequestTemplate(url: 'https://example.com/search'),
          inputs: {},
        ),
      ),
      requiresConnection: true,
    );
    var connectionLookups = 0;
    await tester.runAsync(() async {
      await tester.pumpWidget(
        TestableApp(
          child: const _SampleHarness(),
          retry: (_, _) => null,
          overrides: [
            connectorToolCatalogProvider.overrideWith((ref) => [catalogItem]),
            workflowProvider(
              'workspace',
              'flow',
            ).overrideWith((ref) async => workflow),
            workspaceToolsProvider('workspace')
                .overrideWith(() => _EnabledTools(tool)),
            workspaceConnectedConnectionsProvider(
              'workspace',
              'brave',
            ).overrideWith((ref) async {
              connectionLookups++;
              if (connectionLookups == 1) {
                throw const WorkspaceTableException();
              }

              return const [
                ConnectorConnectionCandidate(
                  id: 'brave-account',
                  name: 'Brave Search account',
                ),
              ];
            }),
          ],
        ),
      );
    });
    await tester.pumpAndSettle();

    expect(find.byType(_SampleHarness), findsOneWidget);
    expect(find.byType(WorkflowConnectorToolSample), findsOneWidget);
    expect(connectionLookups, 1);
    expect(find.text('Try again'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(connectionLookups, 2);
    expect(find.text('Using Brave Search account'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class const _SampleHarness() extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: WorkflowConnectorToolSample(
      workspaceId: 'workspace',
      node: const WorkflowNode(
        id: 'search',
        kind: .connectorTool,
        targetId: 'connector/brave/web_search',
        label: 'Web search',
        x: 0,
        y: 0,
      ),
      editor: ref.watch(workflowEditorProvider('workspace', 'flow').notifier),
    ),
  );
}

class _EnabledTools(final WorkspaceToolEntity tool)
    extends WorkspaceToolsNotifier {
  @override
  Future<List<WorkspaceToolEntity>> build(String workspaceId) async => [tool];
}
