import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workflows/widgets/workflow_canvas.dart';
import 'package:auravibes_app/features/workflows/widgets/workflow_canvas_metrics.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
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
              onRemoveConnection: (_) => fail('Unexpected edge removal'),
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
              onRemoveConnection: (_) => fail('Unexpected edge removal'),
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
        .ancestor(of: find.text(inputNode.label), matching: find.byType(Card))
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

  testWidgets('canvas pans without bounds and renders signed node positions', (
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
          id: 'inputs',
          kind: .inputs,
          targetId: 'inputs',
          label: 'Inputs',
          x: -10000,
          y: -8000,
        ),
        WorkflowNode(
          id: 'outputs',
          kind: .outputs,
          targetId: 'outputs',
          label: 'Outputs',
          x: 20000,
          y: 12000,
        ),
      ],
    );

    await tester.runAsync(() async {
      await tester.pumpWidget(
        TestableApp(
          child: Scaffold(
            body: WorkflowCanvas(
              workflow: workflow,
              editorState: .new(workflow: workflow),
              onSelectNode: (_) => fail('Unexpected node selection'),
              onClearSelection: () => fail('Unexpected selection clear'),
              onMoveNode: (_, _, _) => fail('Unexpected node move'),
              onAddNode: (_, _) => fail('Unexpected node addition'),
              onConnect: (_, _, _) => fail('Unexpected node connection'),
              onRemoveConnection: (_) => fail('Unexpected edge removal'),
            ),
          ),
        ),
      );
    });
    await tester.pumpAndSettle();

    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    expect(viewer.boundaryMargin.left, double.infinity);
    expect(viewer.boundaryMargin.right, double.infinity);
    final transform = viewer.transformationController!;
    transform.value = transform.value.clone()
      ..setEntry(0, 3, 10000)
      ..setEntry(1, 3, 8000);
    await tester.pumpAndSettle();
    expect(find.text('Inputs'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selecting an edge shows confirmed delete action', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 10, 31);
    final connection = const WorkflowConnection(
      fromNodeId: 'inputs',
      toNodeId: 'outputs',
    );
    final workflow = WorkspaceWorkflow.create(
      id: 'workflow',
      workspaceId: 'workspace',
      name: 'Workflow',
      description: '',
      createdAt: now,
      updatedAt: now,
      nodes: const [
        WorkflowNode(
          id: 'inputs',
          kind: .inputs,
          targetId: 'inputs',
          label: 'Inputs',
          x: 80,
          y: 160,
        ),
        WorkflowNode(
          id: 'outputs',
          kind: .outputs,
          targetId: 'outputs',
          label: 'Outputs',
          x: 600,
          y: 160,
        ),
      ],
      connections: [connection],
    );
    var clearCount = 0;
    final removed = <WorkflowConnection>[];

    await tester.runAsync(() async {
      await tester.pumpWidget(
        TestableApp(
          child: Scaffold(
            body: WorkflowCanvas(
              workflow: workflow,
              editorState: .new(workflow: workflow),
              onSelectNode: (_) => fail('Unexpected node selection'),
              onClearSelection: () => clearCount++,
              onMoveNode: (_, _, _) => fail('Unexpected node move'),
              onAddNode: (_, _) => fail('Unexpected node addition'),
              onConnect: (_, _, _) => fail('Unexpected node connection'),
              onRemoveConnection: removed.add,
            ),
          ),
        ),
      );
    });
    await tester.pumpAndSettle();

    final path = WorkflowConnectionGeometry.pathForConnection(connection, {
      for (final node in workflow.nodes) node.id: node,
    });
    final midpoint = WorkflowConnectionGeometry.midpoint(path!)!;
    await tester.tapAt(midpoint);
    await tester.pumpAndSettle();

    expect(clearCount, greaterThan(0));
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('Delete link'));
    await tester.pumpAndSettle();
    expect(removed, [connection]);
  });

  testWidgets(
    'dragging a Condition plus connects its branch and focuses target',
    (tester) async {
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
            id: 'inputs',
            kind: .inputs,
            targetId: 'inputs',
            label: 'Inputs',
            x: 80,
            y: 80,
          ),
          WorkflowNode(
            id: 'condition',
            kind: .condition,
            targetId: 'condition',
            label: 'Condition',
            x: 300,
            y: 80,
          ),
          WorkflowNode(
            id: 'outputs',
            kind: .outputs,
            targetId: 'outputs',
            label: 'Outputs',
            x: 600,
            y: 80,
          ),
        ],
      );
      final links = <WorkflowConnection>[];
      final selectedNodes = <String>[];

      await tester.runAsync(() async {
        await tester.pumpWidget(
          TestableApp(
            child: Scaffold(
              body: WorkflowCanvas(
                workflow: workflow,
                editorState: .new(workflow: workflow),
                onSelectNode: selectedNodes.add,
                onClearSelection: () {},
                onMoveNode: (_, _, _) => fail('Unexpected node move'),
                onAddNode: (_, _) => fail('Unexpected node addition'),
                onConnect: (source, target, branch) => links.add(
                  WorkflowConnection(
                    fromNodeId: source,
                    toNodeId: target,
                    conditionBranch: branch,
                  ),
                ),
                onRemoveConnection: (_) => fail('Unexpected edge removal'),
              ),
            ),
          ),
        );
      });
      await tester.pumpAndSettle();

      final trueHandle = find.ancestor(
        of: find.text('True'),
        matching: find.byType(InkWell),
      );
      final start = tester.getCenter(trueHandle);
      final targetCard = find.ancestor(
        of: find.text('Outputs'),
        matching: find.byType(Card),
      );
      final target = tester.getCenter(targetCard);
      await tester.dragFrom(start, target - start);
      await tester.pumpAndSettle();

      expect(links, hasLength(1));
      expect(links.single.fromNodeId, 'condition');
      expect(links.single.toNodeId, 'outputs');
      expect(links.single.conditionBranch, WorkflowConditionBranch.trueBranch);
      expect(selectedNodes, contains('outputs'));
    },
  );

  testWidgets('invalid plus drop explains why and cancels', (tester) async {
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
          id: 'inputs',
          kind: .inputs,
          targetId: 'inputs',
          label: 'Inputs',
          x: 80,
          y: 80,
        ),
        WorkflowNode(
          id: 'condition',
          kind: .condition,
          targetId: 'condition',
          label: 'Condition',
          x: 400,
          y: 80,
        ),
        WorkflowNode(
          id: 'outputs',
          kind: .outputs,
          targetId: 'outputs',
          label: 'Outputs',
          x: 700,
          y: 80,
        ),
      ],
    );
    final links = <WorkflowConnection>[];

    await tester.runAsync(() async {
      await tester.pumpWidget(
        TestableApp(
          child: Scaffold(
            body: WorkflowCanvas(
              workflow: workflow,
              editorState: .new(workflow: workflow),
              onSelectNode: (_) {},
              onClearSelection: () {},
              onMoveNode: (_, _, _) => fail('Unexpected node move'),
              onAddNode: (_, _) => fail('Unexpected node addition'),
              onConnect: (source, target, branch) => links.add(
                WorkflowConnection(
                  fromNodeId: source,
                  toNodeId: target,
                  conditionBranch: branch,
                ),
              ),
              onRemoveConnection: (_) => fail('Unexpected edge removal'),
            ),
          ),
        ),
      );
    });
    await tester.pumpAndSettle();

    final trueHandle = find.ancestor(
      of: find.text('True'),
      matching: find.byType(InkWell),
    );
    final drag = await tester.startGesture(tester.getCenter(trueHandle));
    final inputsCard = find.ancestor(
      of: find.text('Inputs'),
      matching: find.byType(Card),
    );
    await drag.moveTo(tester.getCenter(inputsCard));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Workflow Inputs cannot receive links.'), findsOneWidget);
    await drag.up();
    await tester.pumpAndSettle();

    expect(links, isEmpty);
  });

  testWidgets('Tab follows node-link order and Escape clears selection', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 10, 31);
    const connections = [
      WorkflowConnection(fromNodeId: 'inputs', toNodeId: 'condition'),
      WorkflowConnection(
        fromNodeId: 'condition',
        toNodeId: 'outputs',
        conditionBranch: WorkflowConditionBranch.trueBranch,
      ),
    ];
    final workflow = WorkspaceWorkflow.create(
      id: 'workflow',
      workspaceId: 'workspace',
      name: 'Workflow',
      description: '',
      createdAt: now,
      updatedAt: now,
      nodes: const [
        WorkflowNode(
          id: 'inputs',
          kind: .inputs,
          targetId: 'inputs',
          label: 'Inputs',
          x: 80,
          y: 80,
        ),
        WorkflowNode(
          id: 'condition',
          kind: .condition,
          targetId: 'condition',
          label: 'Condition',
          x: 400,
          y: 80,
        ),
        WorkflowNode(
          id: 'outputs',
          kind: .outputs,
          targetId: 'outputs',
          label: 'Outputs',
          x: 700,
          y: 80,
        ),
      ],
      connections: connections,
    );
    var clearCount = 0;

    await tester.runAsync(() async {
      await tester.pumpWidget(
        TestableApp(
          child: Scaffold(
            body: WorkflowCanvas(
              workflow: workflow,
              editorState: .new(workflow: workflow),
              onSelectNode: (_) {},
              onClearSelection: () => clearCount++,
              onMoveNode: (_, _, _) => fail('Unexpected node move'),
              onAddNode: (_, _) => fail('Unexpected node addition'),
              onConnect: (_, _, _) => fail('Unexpected node connection'),
              onRemoveConnection: (_) => fail('Unexpected edge removal'),
            ),
          ),
        ),
      );
    });
    await tester.pumpAndSettle();

    const expectedFocusOrder = [
      'Workflow node inputs',
      'Workflow link inputs to condition',
      'Workflow node condition',
      'Workflow link condition to outputs',
      'Workflow node outputs',
    ];
    for (final expected in expectedFocusOrder) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, expected);
    }

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(clearCount, greaterThan(0));
  });
}
