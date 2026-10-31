import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workflows/widgets/workflow_canvas.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_app.dart';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('node add handle invokes its action when tapped', (tester) async {
    final now = DateTime.utc(2026, 10, 31);
    final workflow = WorkspaceWorkflow.create(
      id: 'workflow',
      workspaceId: 'workspace',
      name: 'Workflow',
      description: '',
      createdAt: now,
      updatedAt: now,
      nodes: const [
        WorkflowNode(
          id: 'condition',
          kind: .condition,
          targetId: 'condition',
          label: 'Condition',
          x: 0,
          y: 250,
        ),
      ],
    );
    final inputNode = workflow.nodes.firstWhere((node) => node.kind == .inputs);
    final additions = <({String nodeId, WorkflowConditionBranch? branch})>[];

    await tester.runAsync(() async {
      await tester.pumpWidget(
        TestableApp(
          child: Scaffold(
            body: WorkflowCanvas(
              workflow: workflow,
              editorState: .new(
                workflow: workflow,
                selectedNodeId: inputNode.id,
              ),
              onSelectNode: (_) => fail('Unexpected node selection'),
              onClearSelection: () => fail('Unexpected selection clear'),
              onMoveNode: (_, _, _) => fail('Unexpected node move'),
              onAddNode: (nodeId, branch) =>
                  additions.add((nodeId: nodeId, branch: branch)),
              onConnect: (_, _, _) => fail('Unexpected node connection'),
            ),
          ),
        ),
      );
    });
    expect(await tester.pumpAndSettle(), greaterThan(0));

    final addHandles = find.byType(InkWell);
    expect(addHandles, findsNWidgets(3));
    await tester.tap(addHandles.at(0));
    await tester.tap(addHandles.at(1));
    await tester.tap(addHandles.at(2));

    expect(additions, [
      (nodeId: inputNode.id, branch: null),
      (nodeId: 'condition', branch: WorkflowConditionBranch.trueBranch),
      (nodeId: 'condition', branch: WorkflowConditionBranch.falseBranch),
    ]);
  });
}
