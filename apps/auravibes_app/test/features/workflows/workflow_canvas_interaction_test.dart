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

  testWidgets('node drag follows pointer at zoom and commits on release', (
    tester,
  ) async {
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
    final positions = <Offset>[];

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
              onMoveNode: (_, x, y) => positions.add(Offset(x, y)),
              onAddNode: (_, _) => fail('Unexpected node addition'),
              onConnect: (_, _, _) => fail('Unexpected node connection'),
            ),
          ),
        ),
      );
    });
    expect(await tester.pumpAndSettle(), greaterThan(0));
    final transform = tester
        .widget<InteractiveViewer>(find.byType(InteractiveViewer))
        .transformationController;
    if (transform == null) {
      fail('InteractiveViewer has no transform controller');
    }
    transform.value = transform.value.clone()
      ..setEntry(0, 0, 1.8)
      ..setEntry(1, 1, 1.8);
    await tester.pump();

    final inputCard = find
        .descendant(
          of: find.byType(WorkflowCanvas),
          matching: find.byType(Card),
        )
        .first;
    final initialPosition = tester.getTopLeft(inputCard);
    final gesture = await tester.startGesture(tester.getCenter(inputCard));
    await gesture.moveBy(
      const Offset(100, 80),
      timeStamp: const Duration(milliseconds: 20),
    );
    await gesture.moveBy(
      const Offset(260, 180),
      timeStamp: const Duration(milliseconds: 40),
    );
    expect(positions, isEmpty);
    await tester.pump();
    final draggedPosition = tester.getTopLeft(inputCard);
    expect(draggedPosition.dx, closeTo(initialPosition.dx + 360, 0.01));
    expect(draggedPosition.dy, closeTo(initialPosition.dy + 260, 0.01));
    await gesture.up(timeStamp: const Duration(milliseconds: 60));

    expect(positions, hasLength(1));
    expect(positions.single.dx, closeTo(inputNode.x + 360 / 1.8, 0.01));
    expect(positions.single.dy, closeTo(inputNode.y + 260 / 1.8, 0.01));
  });
}
