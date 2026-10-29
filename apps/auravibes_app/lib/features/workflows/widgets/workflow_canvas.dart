import 'dart:math' as math;

import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workflows/models/workflow_editor_state.dart';
import 'package:auravibes_app/features/workflows/widgets/workflow_canvas_metrics.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:material_ui/material_ui.dart';

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
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: _WorkflowCanvasViewport(
          workflow: widget.workflow,
          editorState: widget.editorState,
          transform: _transform,
          onSelectNode: widget.onSelectNode,
          onMoveNode: widget.onMoveNode,
          onSelectOutput: widget.onSelectOutput,
          onSelectInput: widget.onSelectInput,
        ),
      ),
      const _WorkflowConnectionHint(),
    ],
  );
}

class const _WorkflowCanvasViewport({
  required final WorkflowDefinition workflow,
  required final WorkflowEditorState editorState,
  required final TransformationController transform,
  required final ValueChanged<String> onSelectNode,
  required final void Function(String nodeId, double x, double y) onMoveNode,
  required final void Function(String? nodeId, String portId) onSelectOutput,
  required final void Function(String? nodeId, String portId) onSelectInput,
}) extends StatelessWidget {
  static const _boundaryMargin = 300.0;
  static const _minimumScale = 0.45;
  static const _maximumScale = 1.8;

  @override
  Widget build(BuildContext context) => InteractiveViewer(
    boundaryMargin: const EdgeInsets.all(_boundaryMargin),
    constrained: false,
    maxScale: _maximumScale,
    minScale: _minimumScale,
    transformationController: transform,
    child: _WorkflowCanvasScene(
      workflow: workflow,
      editorState: editorState,
      onSelectNode: onSelectNode,
      onMoveNode: onMoveNode,
      onSelectOutput: onSelectOutput,
      onSelectInput: onSelectInput,
    ),
  );
}

class const _WorkflowCanvasScene({
  required final WorkflowDefinition workflow,
  required final WorkflowEditorState editorState,
  required final ValueChanged<String> onSelectNode,
  required final void Function(String nodeId, double x, double y) onMoveNode,
  required final void Function(String? nodeId, String portId) onSelectOutput,
  required final void Function(String? nodeId, String portId) onSelectInput,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = WorkflowCanvasLayout.sizeFor(workflow);

    return SizedBox(
      width: size.width,
      height: size.height,
      child: _WorkflowCanvasSceneLayers(
        workflow: workflow,
        editorState: editorState,
        onSelectNode: onSelectNode,
        onMoveNode: onMoveNode,
        onSelectOutput: onSelectOutput,
        onSelectInput: onSelectInput,
      ),
    );
  }
}

class const _WorkflowCanvasSceneLayers({
  required final WorkflowDefinition workflow,
  required final WorkflowEditorState editorState,
  required final ValueChanged<String> onSelectNode,
  required final void Function(String nodeId, double x, double y) onMoveNode,
  required final void Function(String? nodeId, String portId) onSelectOutput,
  required final void Function(String? nodeId, String portId) onSelectInput,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      const _WorkflowGridLayer(),
      _WorkflowConnectionLayer(workflow: workflow),
      _WorkflowBoundaryPosition(
        workflow: workflow,
        editorState: editorState,
        onSelectOutput: onSelectOutput,
        onSelectInput: onSelectInput,
      ),
      _WorkflowCanvasNodes(
        workflow: workflow,
        editorState: editorState,
        onSelectNode: onSelectNode,
        onMoveNode: onMoveNode,
        onSelectOutput: onSelectOutput,
        onSelectInput: onSelectInput,
      ),
    ],
  );
}

class const _WorkflowGridLayer() extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const Positioned.fill(child: CustomPaint(painter: _GridPainter()));
}

class const _WorkflowConnectionLayer({
  required final WorkflowDefinition workflow,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: CustomPaint(
      painter: _ConnectionPainter(
        workflow: workflow,
        color: context.auraColors.primary,
      ),
    ),
  );
}

class const _WorkflowBoundaryPosition({
  required final WorkflowDefinition workflow,
  required final WorkflowEditorState editorState,
  required final void Function(String? nodeId, String portId) onSelectOutput,
  required final void Function(String? nodeId, String portId) onSelectInput,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      _WorkflowInputBoundary(
        ports: workflow.inputs,
        onPortTap: (portId) => onSelectOutput(null, portId),
        pendingPortId: editorState.pendingOutput?.nodeId == null
            ? editorState.pendingOutput?.portId
            : null,
      ),
      _WorkflowOutputBoundary(
        ports: workflow.outputs,
        onPortTap: (portId) => onSelectInput(null, portId),
      ),
    ],
  );
}

class const _WorkflowInputBoundary({
  required final List<WorkflowPort> ports,
  required final ValueChanged<String> onPortTap,
  final String? pendingPortId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Positioned(
    left: WorkflowCanvasMetrics.inputBoundaryLeft,
    top: WorkflowCanvasMetrics.boundaryTop,
    child: _WorkflowBoundaryCard(
      titleKey: LocaleKeys.workflow_editor_inputs,
      ports: ports,
      isOutputBoundary: false,
      onPortTap: onPortTap,
      pendingPortId: pendingPortId,
    ),
  );
}

class const _WorkflowOutputBoundary({
  required final List<WorkflowPort> ports,
  required final ValueChanged<String> onPortTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Positioned(
    left: WorkflowCanvasMetrics.outputBoundaryLeft,
    top: WorkflowCanvasMetrics.boundaryTop,
    child: _WorkflowBoundaryCard(
      titleKey: LocaleKeys.workflow_editor_outputs,
      ports: ports,
      isOutputBoundary: true,
      onPortTap: onPortTap,
    ),
  );
}

class const _WorkflowCanvasNodes({
  required final WorkflowDefinition workflow,
  required final WorkflowEditorState editorState,
  required final ValueChanged<String> onSelectNode,
  required final void Function(String nodeId, double x, double y) onMoveNode,
  required final void Function(String? nodeId, String portId) onSelectOutput,
  required final void Function(String? nodeId, String portId) onSelectInput,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      for (final node in workflow.nodes)
        _WorkflowCanvasNodePosition(
          node: node,
          editorState: editorState,
          onSelectNode: onSelectNode,
          onMoveNode: onMoveNode,
          onSelectOutput: onSelectOutput,
          onSelectInput: onSelectInput,
        ),
    ],
  );
}

class const _WorkflowCanvasNodePosition({
  required final WorkflowNode node,
  required final WorkflowEditorState editorState,
  required final ValueChanged<String> onSelectNode,
  required final void Function(String nodeId, double x, double y) onMoveNode,
  required final void Function(String? nodeId, String portId) onSelectOutput,
  required final void Function(String? nodeId, String portId) onSelectInput,
}) extends StatelessWidget {
  String? get _pendingPortId => editorState.pendingOutput?.nodeId == node.id
      ? editorState.pendingOutput?.portId
      : null;

  Offset get _position => Offset(
    WorkflowConnectionGeometry.boundedPosition(node.x),
    WorkflowConnectionGeometry.boundedPosition(node.y),
  );

  @override
  Widget build(BuildContext context) {
    final position = _position;

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: _WorkflowCanvasNode(
        node: node,
        isSelected: editorState.selectedNodeId == node.id,
        pendingOutputPortId: _pendingPortId,
        actions: _actions(position),
      ),
    );
  }

  _WorkflowCanvasNodeActions _actions(Offset position) =>
      _WorkflowCanvasNodeActionFactory.create((
        node: node,
        position: position,
        onSelectNode: onSelectNode,
        onMoveNode: onMoveNode,
        onSelectOutput: onSelectOutput,
        onSelectInput: onSelectInput,
      ));
}

typedef _WorkflowCanvasNodeActions = ({
  VoidCallback select,
  ValueChanged<Offset> move,
  ValueChanged<String> selectOutput,
  ValueChanged<String> selectInput,
});
typedef _WorkflowCanvasNodeActionSource = ({
  WorkflowNode node,
  Offset position,
  ValueChanged<String> onSelectNode,
  void Function(String nodeId, double x, double y) onMoveNode,
  void Function(String? nodeId, String portId) onSelectOutput,
  void Function(String? nodeId, String portId) onSelectInput,
});

abstract final class _WorkflowCanvasNodeActionFactory {
  static _WorkflowCanvasNodeActions create(
    _WorkflowCanvasNodeActionSource source,
  ) => (
    select: _select(source),
    move: _move(source),
    selectOutput: _selectOutput(source),
    selectInput: _selectInput(source),
  );

  static VoidCallback _select(_WorkflowCanvasNodeActionSource source) =>
      () => source.onSelectNode(source.node.id);

  static ValueChanged<Offset> _move(_WorkflowCanvasNodeActionSource source) =>
      (delta) => source.onMoveNode(
        source.node.id,
        source.position.dx + delta.dx,
        source.position.dy + delta.dy,
      );

  static ValueChanged<String> _selectOutput(
    _WorkflowCanvasNodeActionSource source,
  ) =>
      (portId) => source.onSelectOutput(source.node.id, portId);

  static ValueChanged<String> _selectInput(
    _WorkflowCanvasNodeActionSource source,
  ) =>
      (portId) => source.onSelectInput(source.node.id, portId);
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
    width: WorkflowCanvasMetrics.boundaryWidth,
    child: _WorkflowBoundaryContent(
      titleKey: titleKey,
      ports: ports,
      isOutputBoundary: isOutputBoundary,
      onPortTap: onPortTap,
      pendingPortId: pendingPortId,
    ),
  );
}

class const _WorkflowBoundaryContent({
  required final String titleKey,
  required final List<WorkflowPort> ports,
  required final bool isOutputBoundary,
  required final ValueChanged<String> onPortTap,
  final String? pendingPortId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    crossAxisAlignment: .stretch,
    children: [
      _WorkflowBoundaryHeader(titleKey: titleKey),
      const Divider(height: WorkflowCanvasMetrics.headerDividerHeight),
      _WorkflowBoundaryPorts(
        ports: ports,
        isOutputBoundary: isOutputBoundary,
        onPortTap: onPortTap,
        pendingPortId: pendingPortId,
      ),
    ],
  );
}

class const _WorkflowBoundaryHeader({required final String titleKey})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    height: WorkflowCanvasMetrics.boundaryHeaderHeight,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Align(alignment: .centerLeft, child: TextLocale(titleKey)),
    ),
  );
}

class const _WorkflowBoundaryPorts({
  required final List<WorkflowPort> ports,
  required final bool isOutputBoundary,
  required final ValueChanged<String> onPortTap,
  final String? pendingPortId,
}) extends StatelessWidget {
  static const _emptyGroupPadding = 8.0;

  @override
  Widget build(BuildContext context) => ports.isEmpty
      ? const _WorkflowEmptyPortGroup(padding: _emptyGroupPadding)
      : _WorkflowBoundaryPortList(
          ports: ports,
          isOutputBoundary: isOutputBoundary,
          onPortTap: onPortTap,
          pendingPortId: pendingPortId,
        );
}

class const _WorkflowEmptyPortGroup({required final double padding})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(padding),
    child: const TextLocale(LocaleKeys.workflow_editor_empty_group),
  );
}

class const _WorkflowBoundaryPortList({
  required final List<WorkflowPort> ports,
  required final bool isOutputBoundary,
  required final ValueChanged<String> onPortTap,
  required final String? pendingPortId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    children: [
      for (final port in ports)
        _WorkflowBoundaryPort(
          port: port,
          isInput: isOutputBoundary,
          isActive: pendingPortId == port.id,
          onTap: () => onPortTap(port.id),
        ),
    ],
  );
}

class const _WorkflowBoundaryPort({
  required final WorkflowPort port,
  required final bool isInput,
  required final bool isActive,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    height: WorkflowCanvasMetrics.portHeight,
    child: _WorkflowPortHandle(
      port: port,
      isInput: isInput,
      onTap: onTap,
      isActive: isActive,
    ),
  );
}

class const _WorkflowCanvasNode({
  required final WorkflowNode node,
  required final bool isSelected,
  required final String? pendingOutputPortId,
  required final _WorkflowCanvasNodeActions actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GestureDetector(
    child: _WorkflowCardSurface(
      width: WorkflowCanvasMetrics.nodeWidth,
      child: _WorkflowCanvasNodeContent(
        node: node,
        pendingOutputPortId: pendingOutputPortId,
        onSelectOutput: actions.selectOutput,
        onSelectInput: actions.selectInput,
      ),
      isSelected: isSelected,
    ),
    onTap: actions.select,
    onPanUpdate: (details) => actions.move(details.delta),
  );
}

class const _WorkflowCanvasNodeContent({
  required final WorkflowNode node,
  required final String? pendingOutputPortId,
  required final ValueChanged<String> onSelectOutput,
  required final ValueChanged<String> onSelectInput,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    crossAxisAlignment: .stretch,
    children: [
      _WorkflowCanvasNodeHeader(node: node),
      const Divider(height: WorkflowCanvasMetrics.headerDividerHeight),
      _WorkflowCanvasNodePorts(
        node: node,
        pendingOutputPortId: pendingOutputPortId,
        onSelectOutput: onSelectOutput,
        onSelectInput: onSelectInput,
      ),
    ],
  );
}

class const _WorkflowCanvasNodeHeader({required final WorkflowNode node})
    extends StatelessWidget {
  static const _iconSize = 18.0;
  static const _iconSpacing = 6.0;
  static const _headerPadding = 10.0;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: WorkflowCanvasMetrics.nodeHeaderHeight,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: _headerPadding),
      child: Row(
        children: [
          Icon(WorkflowNodeIcon.forKind(node.kind), size: _iconSize),
          const SizedBox(width: _iconSpacing),
          Expanded(child: _WorkflowCanvasNodeLabel(label: node.label)),
        ],
      ),
    ),
  );
}

class const _WorkflowCanvasNodeLabel({required final String label})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
    label,
    style: Theme.of(context).textTheme.titleSmall,
    overflow: .ellipsis,
    maxLines: 1,
  );
}

class const _WorkflowCanvasNodePorts({
  required final WorkflowNode node,
  required final String? pendingOutputPortId,
  required final ValueChanged<String> onSelectOutput,
  required final ValueChanged<String> onSelectInput,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _WorkflowCanvasNodePortRows(
    node: node,
    pendingOutputPortId: pendingOutputPortId,
    onSelectOutput: onSelectOutput,
    onSelectInput: onSelectInput,
  );
}

class const _WorkflowCanvasNodePortRows({
  required final WorkflowNode node,
  required final String? pendingOutputPortId,
  required final ValueChanged<String> onSelectOutput,
  required final ValueChanged<String> onSelectInput,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final rowCount = math.max(node.inputs.length, node.outputs.length);
    if (rowCount == 0) {
      return const SizedBox(height: WorkflowCanvasMetrics.portHeight);
    }

    return _WorkflowCanvasNodePortList(
      node: node,
      rowCount: rowCount,
      pendingOutputPortId: pendingOutputPortId,
      onSelectOutput: onSelectOutput,
      onSelectInput: onSelectInput,
    );
  }
}

class const _WorkflowCanvasNodePortList({
  required final WorkflowNode node,
  required final int rowCount,
  required final String? pendingOutputPortId,
  required final ValueChanged<String> onSelectOutput,
  required final ValueChanged<String> onSelectInput,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    children: [
      for (var index = 0; index < rowCount; index++)
        _WorkflowCanvasNodePortRow(
          node: node,
          index: index,
          pendingOutputPortId: pendingOutputPortId,
          onSelectOutput: onSelectOutput,
          onSelectInput: onSelectInput,
        ),
    ],
  );
}

class const _WorkflowCanvasNodePortRow({
  required final WorkflowNode node,
  required final int index,
  required final String? pendingOutputPortId,
  required final ValueChanged<String> onSelectOutput,
  required final ValueChanged<String> onSelectInput,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    height: WorkflowCanvasMetrics.portHeight,
    child: Row(
      children: [
        Expanded(
          child: _WorkflowOptionalNodePort(
            ports: node.inputs,
            index: index,
            isInput: true,
            onSelect: onSelectInput,
          ),
        ),
        Expanded(
          child: _WorkflowOptionalNodePort(
            ports: node.outputs,
            index: index,
            isInput: false,
            onSelect: onSelectOutput,
            activePortId: pendingOutputPortId,
          ),
        ),
      ],
    ),
  );
}

class const _WorkflowOptionalNodePort({
  required final List<WorkflowPort> ports,
  required final int index,
  required final bool isInput,
  required final ValueChanged<String> onSelect,
  final String? activePortId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (index >= ports.length) return const SizedBox.shrink();
    final port = ports[index];

    return _WorkflowPortHandle(
      port: port,
      isInput: isInput,
      onTap: () => onSelect(port.id),
      isActive: activePortId == port.id,
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
      child: _WorkflowPortBadge(port: port, isActive: isActive),
    ),
    onTap: onTap,
  );
}

class const _WorkflowPortBadge({
  required final WorkflowPort port,
  required final bool isActive,
}) extends StatelessWidget {
  static const _verticalPadding = 2.0;
  static const _horizontalPadding = 7.0;
  static const _maxWidth = 116.0;
  static const _verticalMargin = 4.0;
  static const _horizontalMargin = 6.0;
  static const _WorkflowPortBadgeLayout _layout = (
    padding: EdgeInsets.symmetric(
      vertical: _verticalPadding,
      horizontal: _horizontalPadding,
    ),
    constraints: BoxConstraints(maxWidth: _maxWidth),
    margin: EdgeInsets.symmetric(
      vertical: _verticalMargin,
      horizontal: _horizontalMargin,
    ),
  );

  @override
  Widget build(BuildContext context) => _WorkflowPortBadgeSurface(
    port: port,
    isActive: isActive,
    layout: _layout,
  );
}

typedef _WorkflowPortBadgeLayout = ({
  EdgeInsets padding,
  BoxConstraints constraints,
  EdgeInsets margin,
});

class const _WorkflowPortBadgeSurface({
  required final WorkflowPort port,
  required final bool isActive,
  required final _WorkflowPortBadgeLayout layout,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    decoration: WorkflowPortBadgeStyle.forState(context, active: isActive),
    margin: layout.margin,
    child: _WorkflowPortBadgeContent(port: port, layout: layout),
  );
}

class const _WorkflowPortBadgeContent({
  required final WorkflowPort port,
  required final _WorkflowPortBadgeLayout layout,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: layout.constraints,
    child: Padding(
      padding: layout.padding,
      child: _WorkflowPortBadgeLabel(label: port.name),
    ),
  );
}

class const _WorkflowPortBadgeLabel({required final String label})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
    label,
    style: Theme.of(context).textTheme.labelSmall,
    overflow: .ellipsis,
    maxLines: 1,
  );
}

abstract final class WorkflowPortBadgeStyle {
  static const _activeFillAlpha = 0.25;
  static const _borderRadius = 12.0;

  static BoxDecoration forState(BuildContext context, {required bool active}) =>
      BoxDecoration(
        color: _fillColor(context, active: active),
        border: _border(context, active: active),
        borderRadius: const .all(.circular(_borderRadius)),
      );

  static Color _fillColor(BuildContext context, {required bool active}) =>
      active
      ? context.auraColors.primary.withValues(alpha: _activeFillAlpha)
      : context.auraColors.background;

  static Border _border(BuildContext context, {required bool active}) =>
      Border.all(
        color: active
            ? context.auraColors.primary
            : context.auraColors.outlineVariant,
      );
}

class const _WorkflowCardSurface({
  required final double width,
  required final Widget child,
  final bool isSelected = false,
}) extends StatelessWidget {
  static const _clipRadius = 11.0;

  @override
  Widget build(BuildContext context) => Container(
    decoration: WorkflowCardDecoration.forState(context, selected: isSelected),
    width: width,
    child: ClipRRect(
      borderRadius: const .all(.circular(_clipRadius)),
      child: child,
    ),
  );
}

abstract final class WorkflowCardDecoration {
  static const _radius = 12.0;
  static const _selectedBorderWidth = 2.0;
  static const _defaultBorderWidth = 1.0;
  static const _shadowOffsetY = 3.0;
  static const _shadowBlurRadius = 8.0;

  static BoxDecoration forState(
    BuildContext context, {
    required bool selected,
  }) => BoxDecoration(
    color: context.auraColors.surface,
    border: _border(context, selected: selected),
    borderRadius: const .all(.circular(_radius)),
    boxShadow: const [
      BoxShadow(
        color: .new(0x22000000),
        offset: .new(0, _shadowOffsetY),
        blurRadius: _shadowBlurRadius,
      ),
    ],
  );

  static Border _border(BuildContext context, {required bool selected}) =>
      Border.all(
        color: selected
            ? context.auraColors.primary
            : context.auraColors.outlineVariant,
        width: selected ? _selectedBorderWidth : _defaultBorderWidth,
      );
}

class _GridPainter extends CustomPainter {
  const new();

  @override
  void paint(Canvas canvas, Size size) =>
      WorkflowCanvasGridPainter.paint(canvas, size);

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => false;
}

abstract final class WorkflowCanvasGridPainter {
  static const _gridColor = Color(0x18000000);

  static void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _gridColor
      ..strokeWidth = WorkflowCanvasMetrics.gridStrokeWidth;
    _drawVerticalLines(canvas, size, paint);
    _drawHorizontalLines(canvas, size, paint);
  }

  static void _drawVerticalLines(Canvas canvas, Size size, Paint paint) {
    for (var x = 0.0; x < size.width; x += WorkflowCanvasMetrics.gridSpacing) {
      canvas.drawLine(.new(x, 0), .new(x, size.height), paint);
    }
  }

  static void _drawHorizontalLines(Canvas canvas, Size size, Paint paint) {
    for (var y = 0.0; y < size.height; y += WorkflowCanvasMetrics.gridSpacing) {
      canvas.drawLine(.new(0, y), .new(size.width, y), paint);
    }
  }
}

class _ConnectionPainter extends CustomPainter {
  const new({required this.workflow, required this.color});

  final WorkflowDefinition workflow;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) =>
      WorkflowConnectionPainter.paint(canvas, workflow, color);

  @override
  bool shouldRepaint(covariant _ConnectionPainter oldDelegate) =>
      oldDelegate.workflow != workflow || oldDelegate.color != color;
}

typedef _WorkflowConnectionDrawingContext = ({
  Map<String, WorkflowNode> nodes,
  WorkflowDefinition workflow,
  Paint paint,
  Color color,
});
typedef _WorkflowConnectionSegment = ({
  Offset start,
  Offset end,
  Paint paint,
  Color color,
});

abstract final class WorkflowConnectionPainter {
  static const _curveOffsetDivisor = 2.0;
  static void paint(Canvas canvas, WorkflowDefinition workflow, Color color) {
    final nodes = {for (final node in workflow.nodes) node.id: node};
    final drawing = (
      nodes: nodes,
      workflow: workflow,
      paint: _connectionPaint(color),
      color: color,
    );
    for (final connection in workflow.connections) {
      _drawConnection(canvas, connection, drawing);
    }
  }

  static Paint _connectionPaint(Color color) => Paint()
    ..color = color
    ..strokeWidth = WorkflowCanvasMetrics.connectionStrokeWidth
    ..style = .stroke;

  static void _drawConnection(
    Canvas canvas,
    WorkflowConnection connection,
    _WorkflowConnectionDrawingContext drawing,
  ) {
    final start = WorkflowConnectionGeometry.start(
      connection,
      drawing.nodes,
      drawing.workflow.inputs,
    );
    final end = WorkflowConnectionGeometry.end(
      connection,
      drawing.nodes,
      drawing.workflow.outputs,
    );
    if (start == null || end == null) return;
    _drawPathAndEndpoints(canvas, (
      start: start,
      end: end,
      paint: drawing.paint,
      color: drawing.color,
    ));
  }

  static void _drawPathAndEndpoints(
    Canvas canvas,
    _WorkflowConnectionSegment segment,
  ) {
    final path = _connectionPath(segment.start, segment.end);
    canvas.drawPath(path, segment.paint);
    _drawEndpoints(canvas, segment);
  }

  static void _drawEndpoints(
    Canvas canvas,
    _WorkflowConnectionSegment segment,
  ) {
    _drawEndpoint(canvas, segment.start, segment.color);
    _drawEndpoint(canvas, segment.end, segment.color);
  }

  static void _drawEndpoint(Canvas canvas, Offset point, Color color) {
    final paint = Paint()..color = color;
    canvas.drawCircle(
      point,
      WorkflowCanvasMetrics.connectionEndpointRadius,
      paint,
    );
  }

  static Path _connectionPath(Offset start, Offset end) {
    final curveOffset = _curveOffset(start, end);

    return Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        start.dx + curveOffset,
        start.dy,
        end.dx - curveOffset,
        end.dy,
        end.dx,
        end.dy,
      );
  }

  static double _curveOffset(Offset start, Offset end) => math.max(
    WorkflowCanvasMetrics.minimumCurveOffset,
    (end.dx - start.dx).abs() / _curveOffsetDivisor,
  );
}

class const _WorkflowConnectionHint() extends StatelessWidget {
  static const _left = 12.0;
  static const _bottom = 12.0;
  static const _verticalPadding = 8.0;
  static const _horizontalPadding = 12.0;

  @override
  Widget build(BuildContext context) => const Positioned(
    left: _left,
    bottom: _bottom,
    child: Card(
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: _verticalPadding,
          horizontal: _horizontalPadding,
        ),
        child: TextLocale(LocaleKeys.workflow_editor_connection_hint),
      ),
    ),
  );
}

abstract final class WorkflowNodeIcon {
  static IconData forKind(WorkflowNodeKind kind) => switch (kind) {
    .systemTool => Icons.build_outlined,
    .agent => Icons.smart_toy_outlined,
    .connectorTool => Icons.extension_outlined,
    .workflow => Icons.account_tree_outlined,
  };
}
