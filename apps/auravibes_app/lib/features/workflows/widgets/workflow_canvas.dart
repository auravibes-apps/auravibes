import 'dart:math' as math;

import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workflows/models/workflow_editor_state.dart';
import 'package:auravibes_app/features/workflows/widgets/workflow_canvas_metrics.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';

typedef _WorkflowLinkDrag = ({
  String sourceNodeId,
  WorkflowConditionBranch? branch,
});

class WorkflowCanvas extends StatefulWidget {
  const WorkflowCanvas({
    required this.workflow,
    required this.editorState,
    required this.onSelectNode,
    required this.onClearSelection,
    required this.onMoveNode,
    required this.onAddNode,
    required this.onConnect,
    super.key,
  });

  final WorkspaceWorkflow workflow;
  final WorkflowEditorState editorState;
  final ValueChanged<String> onSelectNode;
  final VoidCallback onClearSelection;
  final void Function(String sourceNodeId, WorkflowConditionBranch? branch)
  onAddNode;
  final void Function(
    String sourceNodeId,
    String targetNodeId,
    WorkflowConditionBranch? branch,
  )
  onConnect;
  final void Function(String nodeId, double x, double y) onMoveNode;

  @override
  State<WorkflowCanvas> createState() => _WorkflowCanvasState();
}

class _WorkflowCanvasState extends State<WorkflowCanvas> {
  final TransformationController _transform = TransformationController();

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => InteractiveViewer(
    boundaryMargin: const EdgeInsets.all(320),
    constrained: false,
    maxScale: 1.8,
    minScale: 0.45,
    transformationController: _transform,
    child: _WorkflowCanvasScene(
      workflow: widget.workflow,
      editorState: widget.editorState,
      onSelectNode: widget.onSelectNode,
      onClearSelection: widget.onClearSelection,
      onMoveNode: widget.onMoveNode,
      onAddNode: widget.onAddNode,
      onConnect: widget.onConnect,
    ),
  );
}

class const _WorkflowCanvasScene({
  required final WorkspaceWorkflow workflow,
  required final WorkflowEditorState editorState,
  required final ValueChanged<String> onSelectNode,
  required final VoidCallback onClearSelection,
  required final void Function(String, WorkflowConditionBranch?) onAddNode,
  required final void Function(String, String, WorkflowConditionBranch?)
  onConnect,
  required final void Function(String, double, double) onMoveNode,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = WorkflowCanvasLayout.sizeFor(workflow);

    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onClearSelection,
              child: CustomPaint(
                painter: _WorkflowGridPainter(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _WorkflowConnectionPainter(
                workflow: workflow,
                color: context.auraColors.primary,
              ),
            ),
          ),
          for (final node in workflow.nodes)
            Positioned(
              left: WorkflowConnectionGeometry.boundedPosition(node.x),
              top: WorkflowConnectionGeometry.boundedPosition(node.y),
              child: _WorkflowCanvasNode(
                node: node,
                selected: editorState.selectedNodeId == node.id,
                canEdit: workflow.canManage,
                onSelect: () => onSelectNode(node.id),
                onMove: (delta) => onMoveNode(
                  node.id,
                  WorkflowConnectionGeometry.boundedPosition(node.x + delta.dx),
                  WorkflowConnectionGeometry.boundedPosition(node.y + delta.dy),
                ),
                onAddNode: (branch) => onAddNode(node.id, branch),
                onConnect: onConnect,
              ),
            ),
        ],
      ),
    );
  }
}

class const _WorkflowCanvasNode({
  required final WorkflowNode node,
  required final bool selected,
  required final bool canEdit,
  required final VoidCallback onSelect,
  required final ValueChanged<Offset> onMove,
  required final ValueChanged<WorkflowConditionBranch?> onAddNode,
  required final void Function(String, String, WorkflowConditionBranch?)
  onConnect,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final handleExtent = switch (node.kind) {
      .outputs => 0.0,
      .condition when canEdit => 106.0,
      _ when canEdit => 42.0,
      _ => 0.0,
    };

    return DragTarget<_WorkflowLinkDrag>(
      onWillAcceptWithDetails: (details) =>
          canEdit &&
          node.kind != .inputs &&
          details.data.sourceNodeId != node.id,
      onAcceptWithDetails: (details) =>
          onConnect(details.data.sourceNodeId, node.id, details.data.branch),
      builder: (context, candidates, rejected) => Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            width: WorkflowCanvasMetrics.nodeWidth + handleExtent,
            height: WorkflowCanvasMetrics.nodeHeight,
          ),
          GestureDetector(
            onTap: onSelect,
            onPanUpdate: canEdit ? (details) => onMove(details.delta) : null,
            child: SizedBox(
              width: WorkflowCanvasMetrics.nodeWidth,
              height: WorkflowCanvasMetrics.nodeHeight,
              child: Card(
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: selected || candidates.isNotEmpty
                        ? context.auraColors.primary
                        : Theme.of(context).dividerColor,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: _WorkflowCanvasNodeContents(node: node),
              ),
            ),
          ),
          if (canEdit && node.kind != .outputs)
            if (node.kind == .condition)
              Positioned(
                right: 0,
                top: 28,
                child: Column(
                  children: [
                    _WorkflowNodeAddHandle(
                      node: node,
                      branch: .trueBranch,
                      labelKey: LocaleKeys.workflow_editor_true,
                      onTap: () => onAddNode(.trueBranch),
                    ),
                    const SizedBox(height: 8),
                    _WorkflowNodeAddHandle(
                      node: node,
                      branch: .falseBranch,
                      labelKey: LocaleKeys.workflow_editor_false,
                      onTap: () => onAddNode(.falseBranch),
                    ),
                  ],
                ),
              )
            else
              Positioned(
                right: 0,
                top: (WorkflowCanvasMetrics.nodeHeight - 42) / 2,
                child: _WorkflowNodeAddHandle(
                  node: node,
                  onTap: () => onAddNode(null),
                ),
              ),
        ],
      ),
    );
  }
}

class const _WorkflowCanvasNodeContents({required final WorkflowNode node})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final fields = node.inputFields.isNotEmpty
        ? node.inputFields
        : node.outputFields;
    final summary = fields.take(2).map((field) => field.name).join(', ');

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(WorkflowNodeIcon.forKind(node.kind), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  node.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            node.canonicalName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (summary.isNotEmpty) ...[
            const Spacer(),
            Text(
              summary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class const _WorkflowNodeAddHandle({
  required final WorkflowNode node,
  required final VoidCallback onTap,
  final WorkflowConditionBranch? branch,
  final String? labelKey,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final content = labelKey == null
        ? const Icon(Icons.add, size: 20)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextLocale(labelKey!),
              const SizedBox(width: 4),
              const Icon(Icons.add, size: 16),
            ],
          );
    final handle = Material(
      color: context.auraColors.surface,
      shape: const StadiumBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: labelKey == null ? 10 : 8,
            vertical: 8,
          ),
          child: content,
        ),
      ),
    );

    return Tooltip(
      message: LocaleKeys.workflow_editor_add_node.tr(),
      child: Draggable<_WorkflowLinkDrag>(
        data: (sourceNodeId: node.id, branch: branch),
        feedback: Material(
          color: Colors.transparent,
          child: Icon(Icons.add_circle, color: context.auraColors.primary),
        ),
        childWhenDragging: Opacity(opacity: 0.4, child: handle),
        child: handle,
      ),
    );
  }
}

class const _WorkflowGridPainter({required final Color color})
    extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.16)
      ..strokeWidth = WorkflowCanvasMetrics.gridStrokeWidth;
    for (var x = 0.0; x < size.width; x += WorkflowCanvasMetrics.gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += WorkflowCanvasMetrics.gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_WorkflowGridPainter oldDelegate) =>
      oldDelegate.color != color;
}

class const _WorkflowConnectionPainter({
  required final WorkspaceWorkflow workflow,
  required final Color color,
}) extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final nodes = {for (final node in workflow.nodes) node.id: node};
    for (final connection in workflow.connections) {
      final start = WorkflowConnectionGeometry.start(connection, nodes);
      final end = WorkflowConnectionGeometry.end(connection, nodes);
      if (start == null || end == null) continue;
      final control = math.max(
        WorkflowCanvasMetrics.minimumCurveOffset,
        (end.dx - start.dx).abs() / 2,
      );
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(
          start.dx + control,
          start.dy,
          end.dx - control,
          end.dy,
          end.dx,
          end.dy,
        );
      final paint = Paint()
        ..color = color
        ..strokeWidth = WorkflowCanvasMetrics.connectionStrokeWidth
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, paint);
      canvas.drawCircle(
        start,
        WorkflowCanvasMetrics.connectionEndpointRadius,
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_WorkflowConnectionPainter oldDelegate) =>
      oldDelegate.workflow != workflow || oldDelegate.color != color;
}

abstract final class WorkflowNodeIcon {
  static IconData forKind(WorkflowNodeKind kind) => switch (kind) {
    .inputs => Icons.play_arrow_outlined,
    .connectorTool => Icons.extension_outlined,
    .condition => Icons.call_split_outlined,
    .transform => Icons.transform_outlined,
    .workflow => Icons.account_tree_outlined,
    .outputs => Icons.stop_outlined,
  };
}
