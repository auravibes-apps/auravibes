import 'dart:math' as math;

import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workflows/models/workflow_editor_state.dart';
import 'package:auravibes_app/features/workflows/models/workflow_graph_validation.dart'
    show maxWorkflowNodePosition;
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:material_ui/material_ui.dart';

const _workflowCanvasWidth = 2500.0;
const _workflowCanvasHeight = 1500.0;
const _workflowBoundaryWidth = 260.0;
const _workflowNodeWidth = 260.0;
const _workflowPortHeight = 28.0;
const _workflowNodeHeaderHeight = 40.0;
const _workflowBoundaryHeaderHeight = 38.0;
const _workflowInputBoundaryLeft = 40.0;
const _workflowOutputBoundaryLeft = 2200.0;
const _workflowBoundaryTop = 60.0;
const _workflowCanvasPadding = 80.0;

Size workflowCanvasSizeFor(WorkflowDefinition workflow) {
  final maxNodeRight = workflow.nodes.fold<double>(
    _workflowOutputBoundaryLeft + _workflowBoundaryWidth,
    (right, node) {
      final nodeRight = _boundedCanvasPosition(node.x) + _workflowNodeWidth;

      return nodeRight > right ? nodeRight : right;
    },
  );
  final maxNodeBottom = workflow.nodes.fold<double>(0, (bottom, node) {
    final nodeTop = _boundedCanvasPosition(node.y);
    final portCount = math
        .max(node.inputs.length, node.outputs.length)
        .clamp(1, 100)
        .toDouble();
    final nodeBottom =
        nodeTop +
        _workflowNodeHeaderHeight +
        1 +
        portCount * _workflowPortHeight;

    return nodeBottom > bottom ? nodeBottom : bottom;
  });
  final boundaryPortCount = math
      .max(workflow.inputs.length, workflow.outputs.length)
      .clamp(1, 100)
      .toDouble();
  final boundaryBottom =
      _workflowBoundaryTop +
      _workflowBoundaryHeaderHeight +
      1 +
      boundaryPortCount * _workflowPortHeight;
  final width = math.max(
    _workflowCanvasWidth,
    maxNodeRight + _workflowCanvasPadding,
  );
  final height = math.max(
    _workflowCanvasHeight,
    math.max(maxNodeBottom, boundaryBottom) + _workflowCanvasPadding,
  );

  return Size(width, height);
}

double _boundedCanvasPosition(double value) =>
    value.isFinite ? value.clamp(0, maxWorkflowNodePosition).toDouble() : 0;

class WorkflowCanvas extends StatefulWidget {
  const new({
    required this.workflow,
    required this.editorState,
    required this.onSelectNode,
    required this.onMoveNode,
    required this.onSelectOutput,
    required this.onSelectInput,
    super.key,
  });

  final WorkflowDefinition workflow;
  final WorkflowEditorState editorState;
  final ValueChanged<String> onSelectNode;
  final void Function(String nodeId, double x, double y) onMoveNode;
  final void Function(String? nodeId, String portId) onSelectOutput;
  final void Function(String? nodeId, String portId) onSelectInput;

  @override
  State<WorkflowCanvas> createState() => _WorkflowCanvasState();
}

class _WorkflowCanvasState extends State<WorkflowCanvas> {
  final TransformationController _transform = .new();

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canvasSize = workflowCanvasSizeFor(widget.workflow);

    return Stack(
      children: [
        Positioned.fill(
          child: InteractiveViewer(
            boundaryMargin: const EdgeInsets.all(300),
            constrained: false,
            maxScale: 1.8,
            minScale: 0.45,
            transformationController: _transform,
            child: SizedBox(
              width: canvasSize.width,
              height: canvasSize.height,
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: CustomPaint(painter: _GridPainter()),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ConnectionPainter(
                        workflow: widget.workflow,
                        color: context.auraColors.primary,
                      ),
                    ),
                  ),
                  Positioned(
                    left: _workflowInputBoundaryLeft,
                    top: _workflowBoundaryTop,
                    child: _WorkflowBoundaryCard(
                      titleKey: LocaleKeys.workflow_editor_inputs,
                      ports: widget.workflow.inputs,
                      isOutputBoundary: false,
                      onPortTap: (portId) =>
                          widget.onSelectOutput(null, portId),
                      pendingPortId:
                          widget.editorState.pendingOutput?.nodeId == null
                          ? widget.editorState.pendingOutput?.portId
                          : null,
                    ),
                  ),
                  Positioned(
                    left: _workflowOutputBoundaryLeft,
                    top: _workflowBoundaryTop,
                    child: _WorkflowBoundaryCard(
                      titleKey: LocaleKeys.workflow_editor_outputs,
                      ports: widget.workflow.outputs,
                      isOutputBoundary: true,
                      onPortTap: (portId) => widget.onSelectInput(null, portId),
                    ),
                  ),
                  for (final node in widget.workflow.nodes)
                    Positioned(
                      left: _boundedCanvasPosition(node.x),
                      top: _boundedCanvasPosition(node.y),
                      child: _WorkflowCanvasNode(
                        node: node,
                        isSelected:
                            widget.editorState.selectedNodeId == node.id,
                        pendingOutputPortId:
                            widget.editorState.pendingOutput?.nodeId == node.id
                            ? widget.editorState.pendingOutput?.portId
                            : null,
                        onSelect: () => widget.onSelectNode(node.id),
                        onMove: (delta) => widget.onMoveNode(
                          node.id,
                          _boundedCanvasPosition(node.x) + delta.dx,
                          _boundedCanvasPosition(node.y) + delta.dy,
                        ),
                        onSelectOutput: (portId) =>
                            widget.onSelectOutput(node.id, portId),
                        onSelectInput: (portId) =>
                            widget.onSelectInput(node.id, portId),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const Positioned(
          left: 12,
          bottom: 12,
          child: Card(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: TextLocale(LocaleKeys.workflow_editor_connection_hint),
            ),
          ),
        ),
      ],
    );
  }
}

class const _WorkflowBoundaryCard({
  required final String titleKey,
  required final List<WorkflowPort> ports,
  required final bool isOutputBoundary,
  required final ValueChanged<String> onPortTap,
  final String? pendingPortId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _WorkflowCardSurface(
    width: _workflowBoundaryWidth,
    child: Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: [
        SizedBox(
          height: _workflowBoundaryHeaderHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Align(alignment: .centerLeft, child: TextLocale(titleKey)),
          ),
        ),
        const Divider(height: 1),
        for (final port in ports)
          SizedBox(
            height: _workflowPortHeight,
            child: _WorkflowPortHandle(
              port: port,
              isInput: isOutputBoundary,
              onTap: () => onPortTap(port.id),
              isActive: pendingPortId == port.id,
            ),
          ),
        if (ports.isEmpty)
          const Padding(
            padding: EdgeInsets.all(8),
            child: TextLocale(LocaleKeys.workflow_editor_empty_group),
          ),
      ],
    ),
  );
}

class const _WorkflowCanvasNode({
  required final WorkflowNode node,
  required final bool isSelected,
  required final String? pendingOutputPortId,
  required final VoidCallback onSelect,
  required final ValueChanged<Offset> onMove,
  required final ValueChanged<String> onSelectOutput,
  required final ValueChanged<String> onSelectInput,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final rowCount = math.max(node.inputs.length, node.outputs.length);

    return GestureDetector(
      child: _WorkflowCardSurface(
        width: _workflowNodeWidth,
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          children: [
            SizedBox(
              height: _workflowNodeHeaderHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Icon(_nodeIcon(node.kind), size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        node.label,
                        style: Theme.of(context).textTheme.titleSmall,
                        overflow: .ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            for (var index = 0; index < rowCount; index++)
              SizedBox(
                height: _workflowPortHeight,
                child: Row(
                  children: [
                    Expanded(
                      child: index < node.inputs.length
                          ? _WorkflowPortHandle(
                              port: node.inputs[index],
                              isInput: true,
                              onTap: () => onSelectInput(node.inputs[index].id),
                            )
                          : const SizedBox.shrink(),
                    ),
                    Expanded(
                      child: index < node.outputs.length
                          ? _WorkflowPortHandle(
                              port: node.outputs[index],
                              isInput: false,
                              onTap: () =>
                                  onSelectOutput(node.outputs[index].id),
                              isActive:
                                  pendingOutputPortId == node.outputs[index].id,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            if (rowCount == 0) const SizedBox(height: _workflowPortHeight),
          ],
        ),
        isSelected: isSelected,
      ),
      onTap: onSelect,
      onPanUpdate: (details) => onMove(details.delta),
    );
  }
}

class const _WorkflowPortHandle({
  required final WorkflowPort port,
  required final bool isInput,
  required final VoidCallback onTap,
  final bool isActive = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => InkWell(
    child: Align(
      alignment: isInput ? .centerLeft : .centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 7),
        decoration: BoxDecoration(
          color: isActive
              ? context.auraColors.primary.withValues(alpha: 0.25)
              : context.auraColors.background,
          border: Border.all(
            color: isActive
                ? context.auraColors.primary
                : context.auraColors.outlineVariant,
          ),
          borderRadius: const .all(.circular(12)),
        ),
        constraints: const BoxConstraints(maxWidth: 116),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        child: Text(
          port.name,
          style: Theme.of(context).textTheme.labelSmall,
          overflow: .ellipsis,
          maxLines: 1,
        ),
      ),
    ),
    onTap: onTap,
  );
}

class const _WorkflowCardSurface({
  required final double width,
  required final Widget child,
  final bool isSelected = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: context.auraColors.surface,
      border: Border.all(
        color: isSelected
            ? context.auraColors.primary
            : context.auraColors.outlineVariant,
        width: isSelected ? 2 : 1,
      ),
      borderRadius: const .all(.circular(12)),
      boxShadow: const [
        BoxShadow(color: .new(0x22000000), offset: .new(0, 3), blurRadius: 8),
      ],
    ),
    width: width,
    child: ClipRRect(borderRadius: const .all(.circular(11)), child: child),
  );
}

class _GridPainter extends CustomPainter {
  const new();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x18000000)
      ..strokeWidth = 1;
    const gap = 40.0;
    for (var x = 0.0; x < size.width; x += gap) {
      canvas.drawLine(.new(x, 0), .new(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += gap) {
      canvas.drawLine(.new(0, y), .new(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => false;
}

class _ConnectionPainter extends CustomPainter {
  const new({required this.workflow, required this.color});

  final WorkflowDefinition workflow;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final nodes = {for (final node in workflow.nodes) node.id: node};
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = .stroke;
    for (final connection in workflow.connections) {
      final start = _connectionStart(connection, nodes, workflow.inputs);
      final end = _connectionEnd(connection, nodes, workflow.outputs);
      if (start == null || end == null) continue;
      final curveOffset = math.max(48, (end.dx - start.dx).abs() / 2);
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(
          start.dx + curveOffset,
          start.dy,
          end.dx - curveOffset,
          end.dy,
          end.dx,
          end.dy,
        );
      canvas
        ..drawPath(path, paint)
        ..drawCircle(start, 4, Paint()..color = color)
        ..drawCircle(end, 4, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectionPainter oldDelegate) =>
      oldDelegate.workflow != workflow || oldDelegate.color != color;
}

Offset? _connectionStart(
  WorkflowConnection connection,
  Map<String, WorkflowNode> nodes,
  List<WorkflowPort> workflowInputs,
) {
  if (connection.fromNodeId == null) {
    final index = workflowInputs.indexWhere(
      (port) => port.id == connection.fromPortId,
    );
    if (index < 0) return null;

    return Offset(
      _workflowInputBoundaryLeft + _workflowBoundaryWidth,
      _workflowBoundaryTop +
          _workflowBoundaryHeaderHeight +
          14 +
          _workflowPortHeight * index,
    );
  }
  final node = nodes[connection.fromNodeId];
  if (node == null) return null;
  final index = node.outputs.indexWhere(
    (port) => port.id == connection.fromPortId,
  );
  if (index < 0) return null;

  return Offset(
    _boundedCanvasPosition(node.x) + _workflowNodeWidth,
    _boundedCanvasPosition(node.y) +
        _workflowNodeHeaderHeight +
        15 +
        _workflowPortHeight * index,
  );
}

Offset? _connectionEnd(
  WorkflowConnection connection,
  Map<String, WorkflowNode> nodes,
  List<WorkflowPort> workflowOutputs,
) {
  if (connection.toNodeId == null) {
    final index = workflowOutputs.indexWhere(
      (port) => port.id == connection.toPortId,
    );
    if (index < 0) return null;

    return Offset(
      _workflowOutputBoundaryLeft,
      _workflowBoundaryTop +
          _workflowBoundaryHeaderHeight +
          14 +
          _workflowPortHeight * index,
    );
  }
  final node = nodes[connection.toNodeId];
  if (node == null) return null;
  final index = node.inputs.indexWhere(
    (port) => port.id == connection.toPortId,
  );
  if (index < 0) return null;

  return Offset(
    _boundedCanvasPosition(node.x),
    _boundedCanvasPosition(node.y) +
        _workflowNodeHeaderHeight +
        15 +
        _workflowPortHeight * index,
  );
}

IconData _nodeIcon(WorkflowNodeKind kind) => switch (kind) {
  .systemTool => Icons.build_outlined,
  .agent => Icons.smart_toy_outlined,
  .skill => Icons.psychology_alt_outlined,
  .workflow => Icons.account_tree_outlined,
};
